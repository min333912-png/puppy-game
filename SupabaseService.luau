-- ============================================================================
-- 🐶 해피 멍멍이 타운 - Supabase DB 연동 모듈 (ServerScriptService.SupabaseService)
-- 역할:
--   1. 플레이어 프로필 클라우드 세이브 / 로드 (player_profiles Upsert & Select)
--   2. 유기견 보호소 전 세계 누적 구조 통계 & 로그 기록 (RPC: record_shelter_activity)
--   3. 글로벌 실시간 랭킹 조회 (코인 랭킹 / 유기견 봉사왕 / 레이싱 최단 기록)
--   4. 강아지 스피드 레이싱 랩타임 기록 (race_records)
--   5. 실시간 라이브 쿠폰 코드 검증 및 보상 지급 (promo_codes & code_redemptions)
-- ============================================================================

local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")

local SupabaseService = {}

-- [설정 방법]
-- 아래 SUPABASE_URL 과 SUPABASE_KEY 에 본인 프로젝트의 값을 입력하거나,
-- ServerScriptService 의 Attribute ("SupabaseUrl", "SupabaseKey")에 설정하면 즉시 연동됩니다!
local DEFAULT_SUPABASE_URL = "" -- 예: "https://xxxxxxxxxxxx.supabase.co"
local DEFAULT_SUPABASE_KEY = "" -- 예: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

local function getConfig()
	local attrUrl = ServerScriptService:GetAttribute("SupabaseUrl")
	local attrKey = ServerScriptService:GetAttribute("SupabaseKey")
	local url = (type(attrUrl) == "string" and #attrUrl > 5) and attrUrl or DEFAULT_SUPABASE_URL
	local key = (type(attrKey) == "string" and #attrKey > 10) and attrKey or DEFAULT_SUPABASE_KEY
	-- 끝 슬래시 제거
	if string.sub(url, -1) == "/" then
		url = string.sub(url, 1, -2)
	end
	return url, key
end

function SupabaseService.isConfigured(): boolean
	local url, key = getConfig()
	return (#url > 8 and string.find(url, "supabase.co") ~= nil and #key > 15)
end

-- ============================================================================
-- 로컬 하이브리드 캐시 (Supabase URL 미설정 시에도 모든 랭킹/쿠폰/통계 즉시 작동 보장)
-- ============================================================================
local localProfiles = {
	[900001] = { username = "멍멍이대장_민준", coins = 12800, love = 950, dog_level = 18, rebirths = 3, volunteer_count = 42, active_breed = "GoldenDoge" },
	[900002] = { username = "유기견천사_서연", coins = 8400, love = 1420, dog_level = 14, rebirths = 2, volunteer_count = 67, active_breed = "Samoyed" },
	[900003] = { username = "시바견러버_도윤", coins = 6200, love = 530, dog_level = 11, rebirths = 1, volunteer_count = 29, active_breed = "ShibaInu" },
	[900004] = { username = "네온질주_하은", coins = 5100, love = 410, dog_level = 9, rebirths = 1, volunteer_count = 18, active_breed = "NeonHusky" },
}

local localGlobalShelter = {
	total_rescues = 156,
	total_donated_coins = 14820,
	goal_tier = 8,
}

local localRaceRecords = {
	{ username = "네온질주_하은", dog_breed = "NeonHusky", lap_time_ms = 6420, is_riding = true },
	{ username = "멍멍이대장_민준", dog_breed = "GoldenDoge", lap_time_ms = 7150, is_riding = true },
	{ username = "유기견천사_서연", dog_breed = "Husky", lap_time_ms = 8390, is_riding = true },
}

local defaultPromoCodes = {
	["HAPPYDOG2026"] = {
		code = "HAPPYDOG2026",
		reward_coins = 500,
		reward_love = 100,
		reward_dog = nil,
		description = "해피 멍멍이 타운 오픈 기념 500 코인 & 100 사랑도!",
		is_active = true,
	},
	["SHELTERHERO"] = {
		code = "SHELTERHERO",
		reward_coins = 800,
		reward_love = 200,
		reward_dog = nil,
		description = "유기견 구조 영웅 응원 지원금 800 코인 & 200 사랑도!",
		is_active = true,
	},
	["SUPABASE"] = {
		code = "SUPABASE",
		reward_coins = 1500,
		reward_love = 300,
		reward_dog = "NeonHusky",
		description = "Supabase DB 연동 기념 1,500 코인 & 네온 허스키 지급!",
		is_active = true,
	},
}

local localRedemptions = {} -- [userId .. "_" .. code] = true

-- ============================================================================
-- 공통 Supabase REST API 호출 헬퍼
-- ============================================================================
local function supabaseRequest(method: string, endpoint: string, bodyTable: any?, extraHeaders: {[string]: string}?): (boolean, any)
	local baseUrl, apiKey = getConfig()
	if not SupabaseService.isConfigured() then
		return false, "NOT_CONFIGURED"
	end

	local headers = {
		["apikey"] = apiKey,
		["Authorization"] = "Bearer " .. apiKey,
		["Content-Type"] = "application/json",
	}
	if extraHeaders then
		for k, v in pairs(extraHeaders) do
			headers[k] = v
		end
	end

	local requestOptions = {
		Url = baseUrl .. endpoint,
		Method = method,
		Headers = headers,
	}
	if bodyTable ~= nil then
		requestOptions.Body = HttpService:JSONEncode(bodyTable)
	end

	local ok, response = pcall(function()
		return HttpService:RequestAsync(requestOptions)
	end)

	if not ok or not response then
		warn("[SupabaseService] HTTP 요청 실패:", endpoint, response)
		return false, response
	end

	if response.StatusCode >= 200 and response.StatusCode < 300 then
		if response.Body and #response.Body > 0 then
			local decodeOk, decoded = pcall(function()
				return HttpService:JSONDecode(response.Body)
			end)
			if decodeOk then
				return true, decoded
			end
		end
		return true, nil
	else
		warn(string.format("[SupabaseService] HTTP %d (%s): %s", response.StatusCode, endpoint, tostring(response.Body)))
		return false, response.Body
	end
end

-- ============================================================================
-- 1. 플레이어 프로필 불러오기 (Load Player Profile)
-- ============================================================================
function SupabaseService.loadPlayerProfile(userId: number, username: string): {[string]: any}?
	if SupabaseService.isConfigured() then
		local ok, rows = supabaseRequest(
			"GET",
			string.format("/rest/v1/player_profiles?user_id=eq.%d&select=*&limit=1", userId),
			nil,
			nil
		)
		if ok and type(rows) == "table" and #rows > 0 then
			local row = rows[1]
			localProfiles[userId] = row
			return row
		end
	end
	return localProfiles[userId]
end

-- ============================================================================
-- 2. 플레이어 프로필 클라우드 저장 (Upsert Player Profile)
-- ============================================================================
function SupabaseService.savePlayerProfile(userId: number, username: string, displayName: string, data: {[string]: any}): boolean
	local payload = {
		user_id = userId,
		username = username,
		display_name = displayName,
		coins = data.coins or 50,
		love = data.love or 0,
		dog_level = data.dogLevel or 1,
		rebirths = data.rebirths or 0,
		volunteer_count = data.volunteerCount or 0,
		yard_tier = data.yardTier or 0,
		active_breed = data.activeBreed or "GoldenRetriever",
		active_accessory = data.activeAccessory or "",
		owned_dogs = data.ownedDogs or { "GoldenRetriever" },
		owned_accessories = data.ownedAccessories or {},
		updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}

	-- 로컬 캐시 항상 최신화
	localProfiles[userId] = payload

	if SupabaseService.isConfigured() then
		local ok, _ = supabaseRequest(
			"POST",
			"/rest/v1/player_profiles?on_conflict=user_id",
			payload,
			{
				["Prefer"] = "resolution=merge-duplicates,return=minimal",
			}
		)
		return ok
	end
	return true
end

-- ============================================================================
-- 3. 유기견 보호소 봉사/구조 기록 및 전 세계 누적 카운터 증가
-- ============================================================================
function SupabaseService.recordShelterActivity(userId: number, username: string, activityType: string, rewardCoins: number): {[string]: any}
	-- 로컬 통계 즉시 증가
	localGlobalShelter.total_rescues += 1
	localGlobalShelter.total_donated_coins += rewardCoins
	localGlobalShelter.goal_tier = math.max(1, math.floor(localGlobalShelter.total_rescues / 20) + 1)

	if SupabaseService.isConfigured() then
		local ok, rpcResult = supabaseRequest(
			"POST",
			"/rest/v1/rpc/record_shelter_activity",
			{
				p_user_id = userId,
				p_username = username,
				p_activity_type = activityType,
				p_reward_coins = rewardCoins,
			},
			nil
		)
		if ok and type(rpcResult) == "table" then
			localGlobalShelter.total_rescues = rpcResult.total_rescues or localGlobalShelter.total_rescues
			localGlobalShelter.total_donated_coins = rpcResult.total_donated_coins or localGlobalShelter.total_donated_coins
			localGlobalShelter.goal_tier = rpcResult.goal_tier or localGlobalShelter.goal_tier
		end
	end

	return localGlobalShelter
end

-- ============================================================================
-- 4. 강아지 스피드 레이싱 랩타임 기록 (Race Record Insert)
-- ============================================================================
function SupabaseService.recordRaceLap(userId: number, username: string, dogBreed: string, lapTimeMs: number, isRiding: boolean)
	table.insert(localRaceRecords, {
		user_id = userId,
		username = username,
		dog_breed = dogBreed,
		lap_time_ms = lapTimeMs,
		is_riding = isRiding,
	})
	table.sort(localRaceRecords, function(a, b)
		return a.lap_time_ms < b.lap_time_ms
	end)
	while #localRaceRecords > 10 do
		table.remove(localRaceRecords)
	end

	if SupabaseService.isConfigured() then
		supabaseRequest(
			"POST",
			"/rest/v1/race_records",
			{
				user_id = userId,
				username = username,
				dog_breed = dogBreed,
				lap_time_ms = lapTimeMs,
				is_riding = isRiding,
			},
			{ ["Prefer"] = "return=minimal" }
		)
	end
end

-- ============================================================================
-- 5. 글로벌 리더보드 & 전 세계 보호소 통계 조회
-- ============================================================================
function SupabaseService.getLeaderboards(): {[string]: any}
	local topCoins = {}
	local topVolunteers = {}
	local topRacers = {}
	local shelterStats = localGlobalShelter

	if SupabaseService.isConfigured() then
		local ok1, rowsCoins = supabaseRequest(
			"GET",
			"/rest/v1/player_profiles?select=username,coins,dog_level,rebirths&order=coins.desc&limit=5",
			nil,
			nil
		)
		if ok1 and type(rowsCoins) == "table" then
			topCoins = rowsCoins
		end

		local ok2, rowsVol = supabaseRequest(
			"GET",
			"/rest/v1/player_profiles?select=username,volunteer_count,active_breed&order=volunteer_count.desc&limit=5",
			nil,
			nil
		)
		if ok2 and type(rowsVol) == "table" then
			topVolunteers = rowsVol
		end

		local ok3, rowsRace = supabaseRequest(
			"GET",
			"/rest/v1/race_records?select=username,dog_breed,lap_time_ms,is_riding&order=lap_time_ms.asc&limit=5",
			nil,
			nil
		)
		if ok3 and type(rowsRace) == "table" then
			topRacers = rowsRace
		end

		local ok4, rowsShelter = supabaseRequest(
			"GET",
			"/rest/v1/global_shelter_stats?id=eq.1&select=*",
			nil,
			nil
		)
		if ok4 and type(rowsShelter) == "table" and #rowsShelter > 0 then
			shelterStats = rowsShelter[1]
			localGlobalShelter = shelterStats
		end
	end

	-- 로컬 폴백 정렬
	if #topCoins == 0 then
		local all = {}
		for _, p in pairs(localProfiles) do
			table.insert(all, p)
		end
		table.sort(all, function(a, b)
			return (a.coins or 0) > (b.coins or 0)
		end)
		for i = 1, math.min(5, #all) do
			table.insert(topCoins, all[i])
		end
	end

	if #topVolunteers == 0 then
		local all = {}
		for _, p in pairs(localProfiles) do
			table.insert(all, p)
		end
		table.sort(all, function(a, b)
			return (a.volunteer_count or 0) > (b.volunteer_count or 0)
		end)
		for i = 1, math.min(5, #all) do
			table.insert(topVolunteers, all[i])
		end
	end

	if #topRacers == 0 then
		for i = 1, math.min(5, #localRaceRecords) do
			table.insert(topRacers, localRaceRecords[i])
		end
	end

	return {
		isLiveSupabase = SupabaseService.isConfigured(),
		topCoins = topCoins,
		topVolunteers = topVolunteers,
		topRacers = topRacers,
		shelterStats = shelterStats,
	}
end

-- ============================================================================
-- 6. 프로모션 쿠폰 코드 검증 및 사용 기록 (Redeem Promo Code)
-- ============================================================================
function SupabaseService.redeemPromoCode(userId: number, rawCode: string): (boolean, string, {[string]: any}?)
	if type(rawCode) ~= "string" then
		return false, "유효하지 않은 코드입니다.", nil
	end
	local code = string.upper(string.gsub(rawCode, "%s+", ""))
	if #code == 0 then
		return false, "쿠폰 코드를 입력해 주세요!", nil
	end

	local redemptionKey = tostring(userId) .. "_" .. code
	if localRedemptions[redemptionKey] then
		return false, "이미 사용한 쿠폰 코드입니다! (" .. code .. ")", nil
	end

	local promoData = defaultPromoCodes[code]

	if SupabaseService.isConfigured() then
		-- 1) promo_codes 테이블에서 조회
		local okCode, rows = supabaseRequest(
			"GET",
			string.format("/rest/v1/promo_codes?code=eq.%s&is_active=eq.true&select=*&limit=1", HttpService:UrlEncode(code)),
			nil,
			nil
		)
		if okCode and type(rows) == "table" and #rows > 0 then
			promoData = rows[1]
		end

		if not promoData then
			return false, "존재하지 않거나 만료된 쿠폰 코드입니다: " .. code, nil
		end

		-- 2) 이미 사용했는지 확인
		local okCheck, redRows = supabaseRequest(
			"GET",
			string.format("/rest/v1/code_redemptions?code=eq.%s&user_id=eq.%d&select=id&limit=1", HttpService:UrlEncode(code), userId),
			nil,
			nil
		)
		if okCheck and type(redRows) == "table" and #redRows > 0 then
			localRedemptions[redemptionKey] = true
			return false, "이미 사용한 쿠폰 코드입니다! (" .. code .. ")", nil
		end

		-- 3) 사용 내역 기록
		supabaseRequest(
			"POST",
			"/rest/v1/code_redemptions",
			{
				code = code,
				user_id = userId,
			},
			{ ["Prefer"] = "return=minimal" }
		)
	end

	if not promoData then
		return false, "존재하지 않는 쿠폰 코드입니다! (추천: HAPPYDOG2026, SHELTERHERO, SUPABASE)", nil
	end

	localRedemptions[redemptionKey] = true
	return true, promoData.description or "쿠폰 보상이 지급되었습니다!", promoData
end

return SupabaseService
