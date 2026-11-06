local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local saveStore = nil
pcall(function()
	saveStore = DataStoreService:GetDataStore("HappyDogTownSave_v3")
end)

local dogTemplates = ReplicatedStorage:WaitForChild("DogTemplates")
local accTemplates = ReplicatedStorage:WaitForChild("AccessoryTemplates")
local extraAssets = ReplicatedStorage:WaitForChild("ExtraAssets")
local yardTemplates = ReplicatedStorage:WaitForChild("YardUpgradeTemplates")
local remotes = ReplicatedStorage:WaitForChild("DogRemotes")
local actionRemote = remotes:WaitForChild("DogAction")
local notifyRemote = remotes:WaitForChild("DogNotify")

local activePetsFolder = workspace:FindFirstChild("ActivePets") or Instance.new("Folder")
activePetsFolder.Name = "ActivePets"
activePetsFolder.Parent = workspace

local world = workspace:WaitForChild("DogParkWorld")
local stations = world:WaitForChild("Stations")
local pedestals = world:WaitForChild("AdoptionPedestals")
local activeYard = world:WaitForChild("ActiveYardUpgrades")
local treasuresFolder = world:WaitForChild("Treasures")
local poopsFolder = world:WaitForChild("Poops")
local starsFolder = world:WaitForChild("ShootingStars")
local npcFolder = world:WaitForChild("TownNPCs")

local BREED_DATA = {
	Puppy = { name = "아기 강아지", price = 0, coinMult = 1.0, yawOffset = 0, rarity = "일반" },
	ShibaDoge = { name = "시바견 (도지)", price = 50, coinMult = 1.2, yawOffset = 0, rarity = "일반" },
	Pug = { name = "귀염둥이 퍼그", price = 80, coinMult = 1.35, yawOffset = 0, rarity = "희귀" },
	Corgi = { name = "웰시코기", price = 120, coinMult = 1.5, yawOffset = 0, rarity = "희귀" },
	Husky = { name = "시베리안 허스키", price = 180, coinMult = 1.8, yawOffset = 0, rarity = "영웅" },
	GermanShepherd = { name = "저먼 셰퍼드", price = 250, coinMult = 2.2, yawOffset = 0, rarity = "영웅" },
	GoldenRetriever = { name = "골든 리트리버", price = 350, coinMult = 3.0, yawOffset = 0, rarity = "전설" },
	GoldenDoge = { name = "✨황금 시바견", price = 999, coinMult = 4.0, yawOffset = 0, rarity = "전설(뽑기)" },
	NeonHusky = { name = "🌈네온 허스키", price = 999, coinMult = 5.0, yawOffset = 0, rarity = "신화(뽑기)" },
}

local ACCESSORY_DATA = {
	None = { name = "장착 안 함", price = 0, bonus = 0 },
	RoyalCrown = { name = "👑 왕실 황금 왕관", price = 60, bonus = 0.15 },
	WizardHat = { name = "🧙 대마법사 모자", price = 90, bonus = 0.25 },
	AngelWings = { name = "👼 순백의 천사 날개", price = 150, bonus = 0.40 },
	StarHalo = { name = "🌟 네온 스타 헤일로", price = 220, bonus = 0.60 },
}

local EVO_COSTS = { [1] = 150, [2] = 300, [3] = 500 }
local EVO_MULT = { [0] = 1.0, [1] = 1.5, [2] = 2.2, [3] = 3.5 }
local EVO_NAMES = {
	[0] = "기본",
	[1] = "🔥플레임 각성",
	[2] = "⚡썬더골드 각성",
	[3] = "🌈코스믹 레인보우",
}

local QUEST_POOL = {
	{ id = "FeedStation", title = "🍖 급식소에서 사료 & 물 주기" },
	{ id = "BathStation", title = "🛁 거품 욕조에서 목욕시키기" },
	{ id = "SleepStation", title = "🏠 강아지 침대에서 낮잠 재우기" },
	{ id = "AgilityStation", title = "🏆 어질리티 장애물 훈련하기" },
	{ id = "WalkStation", title = "🌸 벚꽃 공원 산책하기" },
	{ id = "RaceStartStation", title = "🏁 도그 스피드 레이싱 참가하기" },
	{ id = "ThrowBall", title = "🎾 공 던지기 놀이해주기" },
}

local YARD_COSTS = { [1] = 100, [2] = 200, [3] = 350 }
local YARD_NAMES = {
	[1] = "1단계: 아늑한 나무 울타리 정원 (+15% 코인)",
	[2] = "2단계: 로블록스 럭셔리 분수대 (+35% 코인)",
	[3] = "3단계: 황금 강아지 조각상 게이트 (+60% 코인)",
}

local playerPetState = {}

local function sendNotify(player, msg, color)
	notifyRemote:FireClient(player, msg, color or Color3.fromRGB(255, 225, 100))
end

local function decodeList(raw, defaultItem)
	local ok, decoded = pcall(function() return HttpService:JSONDecode(raw or "") end)
	if ok and type(decoded) == "table" and #decoded > 0 then
		return decoded
	end
	return defaultItem and { defaultItem } or {}
end

local function getOwnedBreeds(player)
	return decodeList(player:GetAttribute("OwnedBreeds"), "Puppy")
end

local function ownsBreed(player, breedId)
	for _, b in ipairs(getOwnedBreeds(player)) do
		if b == breedId then return true end
	end
	return false
end

local function addOwnedBreed(player, breedId)
	local list = getOwnedBreeds(player)
	for _, b in ipairs(list) do
		if b == breedId then return end
	end
	table.insert(list, breedId)
	player:SetAttribute("OwnedBreeds", HttpService:JSONEncode(list))
end

local function getOwnedAccessories(player)
	return decodeList(player:GetAttribute("OwnedAccessories"), "None")
end

local function ownsAccessory(player, accId)
	for _, a in ipairs(getOwnedAccessories(player)) do
		if a == accId then return true end
	end
	return false
end

local function addOwnedAccessory(player, accId)
	local list = getOwnedAccessories(player)
	for _, a in ipairs(list) do
		if a == accId then return end
	end
	table.insert(list, accId)
	player:SetAttribute("OwnedAccessories", HttpService:JSONEncode(list))
end

local function assignNewQuest(player)
	local q = QUEST_POOL[math.random(1, #QUEST_POOL)]
	player:SetAttribute("QuestId", q.id)
	player:SetAttribute("QuestTitle", q.title)
end

local function refreshYardVisuals(tier)
	for i = 1, tier do
		local tName = "Tier" .. tostring(i)
		if not activeYard:FindFirstChild(tName) then
			local src = yardTemplates:FindFirstChild(tName)
			if src then
				src:Clone().Parent = activeYard
			end
		end
	end
end

local function updatePlayerTitleBadge(player)
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head then return end

	local rebates = player:GetAttribute("RebirthCount") or 0
	local evo = player:GetAttribute("EvolutionTier") or 0
	if rebates <= 0 and evo <= 0 then return end

	local bg = head:FindFirstChild("BreederBadge") or Instance.new("BillboardGui")
	bg.Name = "BreederBadge"
	bg.Size = UDim2.new(3.6, 0, 0.75, 0)
	bg.StudsOffset = Vector3.new(0, 2.2, 0)
	bg.AlwaysOnTop = false
	bg.MaxDistance = 32
	bg.Parent = head

	local lbl = bg:FindFirstChild("BadgeText") or Instance.new("TextLabel")
	lbl.Name = "BadgeText"
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 0.25
	lbl.BackgroundColor3 = Color3.fromRGB(28, 24, 45)
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextColor3 = Color3.fromRGB(255, 225, 75)
	lbl.TextScaled = true
	lbl.Text = string.format("👑 명예 브리더 ★%d | %s", rebates, EVO_NAMES[evo] or "기본")
	lbl.Parent = bg
	if not lbl:FindFirstChildOfClass("UICorner") then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = lbl
	end
end

local function getEquippedSquad(player)
	local mainBreed = player:GetAttribute("CurrentBreed") or "Puppy"
	local owned = getOwnedBreeds(player)
	local maxPets = player:GetAttribute("MaxPetsEquipped") or 3

	table.sort(owned, function(a, b)
		local ma = (BREED_DATA[a] and BREED_DATA[a].coinMult) or 1
		local mb = (BREED_DATA[b] and BREED_DATA[b].coinMult) or 1
		return ma > mb
	end)

	local squad = { mainBreed }
	for _, b in ipairs(owned) do
		if #squad >= maxPets then break end
		if b ~= mainBreed then
			table.insert(squad, b)
		end
	end
	return squad
end

local function updatePetBillboard(player)
	local st = playerPetState[player]
	if not st or not st.models or not st.models[1] then return end
	local leadDog = st.models[1]
	if not leadDog.PrimaryPart then return end
	local bg = leadDog.PrimaryPart:FindFirstChild("PetBillboard")
	if not bg then return end
	local frame = bg:FindFirstChild("MainFrame")
	if not frame then return end

	local breedId = player:GetAttribute("CurrentBreed") or "Puppy"
	local breedInfo = BREED_DATA[breedId] or BREED_DATA.Puppy
	local customName = player:GetAttribute("DogCustomName") or "초코"
	local level = player:GetAttribute("DogLevel") or 1
	local evoTier = player:GetAttribute("EvolutionTier") or 0
	local questTitle = player:GetAttribute("QuestTitle") or ""

	local nameLabel = frame:FindFirstChild("NameLabel")
	local moodLabel = frame:FindFirstChild("MoodLabel")
	if nameLabel then
		local evoTag = evoTier > 0 and (" [" .. EVO_NAMES[evoTier] .. "]") or ""
		nameLabel.Text = string.format("🐾 [Lv.%d] %s (%s)%s", level, customName, breedInfo.name, evoTag)
	end
	if moodLabel then
		moodLabel.Text = "🎯 " .. questTitle
	end
end

local function emitHeartBurst(player, count)
	local st = playerPetState[player]
	if not st or not st.models then return end
	for _, dog in ipairs(st.models) do
		if dog.PrimaryPart then
			local emitter = dog.PrimaryPart:FindFirstChild("LoveEmitter")
			if emitter then emitter:Emit(count or 10) end
		end
	end
end

local function getTotalCoinMultiplier(player)
	local squad = getEquippedSquad(player)
	local squadMult = 0
	for i, bId in ipairs(squad) do
		local info = BREED_DATA[bId] or BREED_DATA.Puppy
		if i == 1 then
			squadMult += info.coinMult
		else
			squadMult += (info.coinMult * 0.5)
		end
	end

	local accId = player:GetAttribute("EquippedAccessory") or "None"
	local accBonus = (ACCESSORY_DATA[accId] and ACCESSORY_DATA[accId].bonus) or 0

	local yardTier = player:GetAttribute("YardTier") or 0
	local yardBonus = (yardTier == 1 and 0.15) or (yardTier == 2 and 0.35) or (yardTier >= 3 and 0.60) or 0

	local evoTier = player:GetAttribute("EvolutionTier") or 0
	local evoMult = EVO_MULT[evoTier] or 1.0

	local rebirths = player:GetAttribute("RebirthCount") or 0
	local rebirthMult = 1 + rebirths * 1.0

	local level = player:GetAttribute("DogLevel") or 1
	local levelBonus = (level - 1) * 0.1

	return squadMult * evoMult * rebirthMult * (1 + accBonus + yardBonus + levelBonus)
end

local function addExpAndCoins(player, expAmount, baseCoinAmount, reason, actionKey)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end
	local coinsVal = ls:FindFirstChild("Coins")
	local levelVal = ls:FindFirstChild("DogLevel")

	local curQuest = player:GetAttribute("QuestId")
	local questBonusMult = 1
	local completedQuest = false
	if actionKey and curQuest == actionKey then
		questBonusMult = 2
		completedQuest = true
	end

	local totalMult = getTotalCoinMultiplier(player)
	local finalCoins = math.floor(baseCoinAmount * totalMult * questBonusMult)
	if coinsVal then
		coinsVal.Value += finalCoins
	end

	local finalExp = expAmount * questBonusMult
	local exp = (player:GetAttribute("Exp") or 0) + finalExp
	local maxExp = player:GetAttribute("MaxExp") or 100
	local level = player:GetAttribute("DogLevel") or 1

	local leveledUp = false
	while exp >= maxExp do
		exp -= maxExp
		level += 1
		maxExp = math.floor(100 * (1.25 ^ (level - 1)))
		leveledUp = true
	end

	player:SetAttribute("Exp", exp)
	player:SetAttribute("MaxExp", maxExp)
	player:SetAttribute("DogLevel", level)
	if levelVal then levelVal.Value = level end

	emitHeartBurst(player, leveledUp and 25 or 10)

	if completedQuest then
		if coinsVal then coinsVal.Value += 50 end
		assignNewQuest(player)
		sendNotify(player, string.format("🌟 소원 미션 달성! +50 보너스 코인! (%s)", reason or ""), Color3.fromRGB(255, 215, 60))
	elseif reason then
		sendNotify(player, string.format("%s (+%d 코인, +%d EXP)", reason, finalCoins, finalExp), Color3.fromRGB(120, 255, 140))
	end

	if leveledUp then
		local bonus = level * 40
		if coinsVal then coinsVal.Value += bonus end
		sendNotify(player, string.format("🎉 강아지 레벨 업! Lv.%d 달성! (보너스 +%d 코인)", level, bonus), Color3.fromRGB(255, 225, 70))
	end

	updatePetBillboard(player)
end

local function attachAccessoryAndAura(dog, accId, evoTier)
	if not dog.PrimaryPart then return end

	-- Evolution Aura Effect
	if evoTier and evoTier > 0 then
		local aura = Instance.new("ParticleEmitter")
		aura.Name = "EvolutionAura"
		aura.Texture = "rbxassetid://243660364"
		if evoTier == 1 then
			aura.Color = ColorSequence.new(Color3.fromRGB(255, 110, 40), Color3.fromRGB(255, 210, 60))
		elseif evoTier == 2 then
			aura.Color = ColorSequence.new(Color3.fromRGB(255, 235, 60), Color3.fromRGB(100, 225, 255))
		else
			aura.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 180)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 255, 220)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 235, 80)),
			})
		end
		aura.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
		aura.Lifetime = NumberRange.new(0.6, 1.2)
		aura.Rate = 18
		aura.Speed = NumberRange.new(2, 4.5)
		aura.SpreadAngle = Vector2.new(50, 50)
		aura.Parent = dog.PrimaryPart
	end

	if not accId or accId == "None" then return end
	local accSrc = accTemplates:FindFirstChild(accId)
	if not accSrc then return end

	local accClone = accSrc:Clone()
	accClone.Name = "AttachedAccessory"
	local _, dogSize = dog:GetBoundingBox()
	local topOffset = Vector3.new(0, (dogSize.Y / 2) + 0.25, 0)
	if accId == "AngelWings" then
		topOffset = Vector3.new(0, (dogSize.Y * 0.22), 0)
	end

	accClone:PivotTo(dog.PrimaryPart.CFrame * CFrame.new(topOffset))
	for _, p in ipairs(accClone:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = false
			p.Massless = true
			local w = Instance.new("WeldConstraint")
			w.Part0 = dog.PrimaryPart
			w.Part1 = p
			w.Parent = dog.PrimaryPart
		end
	end
	accClone.Parent = dog
end

local function spawnPlayerDogs(player)
	local st = playerPetState[player]
	if not st then return end
	if st.models then
		for _, m in ipairs(st.models) do m:Destroy() end
	end
	st.models = {}
	st.breeds = {}

	local squad = getEquippedSquad(player)
	local accId = player:GetAttribute("EquippedAccessory") or "None"
	local evoTier = player:GetAttribute("EvolutionTier") or 0
	local isRiding = player:GetAttribute("IsRiding") == true
	local level = player:GetAttribute("DogLevel") or 1
	local growthScale = math.clamp(1 + (level - 1) * 0.03, 1, 1.35)

	for idx, breedId in ipairs(squad) do
		local template = dogTemplates:FindFirstChild(breedId) or dogTemplates:FindFirstChild("Puppy")
		if template then
			local dog = template:Clone()
			dog.Name = string.format("%s_Dog_%d", player.Name, idx)

			local scaleMult = idx == 1 and (isRiding and growthScale * 1.55 or growthScale) or (growthScale * 0.85)
			if scaleMult > 1.01 then
				dog:ScaleTo(dog:GetScale() * scaleMult)
			end

			for _, p in ipairs(dog:GetDescendants()) do
				if p:IsA("BasePart") then
					p.CanCollide = false
					p.Anchored = (p == dog.PrimaryPart)
				end
			end

			attachAccessoryAndAura(dog, accId, evoTier)

			local root = dog.PrimaryPart
			if root then
				local emitter = Instance.new("ParticleEmitter")
				emitter.Name = "LoveEmitter"
				emitter.Texture = "rbxassetid://243660364"
				emitter.Color = ColorSequence.new(Color3.fromRGB(255, 120, 170), Color3.fromRGB(255, 220, 100))
				emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0)})
				emitter.Lifetime = NumberRange.new(0.8, 1.3)
				emitter.Rate = 0
				emitter.Speed = NumberRange.new(4, 7)
				emitter.SpreadAngle = Vector2.new(60, 60)
				emitter.Parent = root

				if idx == 1 then
					local bg = Instance.new("BillboardGui")
					bg.Name = "PetBillboard"
					bg.Size = UDim2.new(3.8, 0, 0.95, 0) -- Compact 3D Stud size!
					bg.StudsOffset = Vector3.new(0, 2.6, 0)
					bg.AlwaysOnTop = false
					bg.MaxDistance = 30
					bg.Parent = root

					local frame = Instance.new("Frame")
					frame.Name = "MainFrame"
					frame.Size = UDim2.new(1, 0, 1, 0)
					frame.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
					frame.BackgroundTransparency = 0.2
					frame.Parent = bg
					local corner = Instance.new("UICorner")
					corner.CornerRadius = UDim.new(0, 8)
					corner.Parent = frame
					local stroke = Instance.new("UIStroke")
					stroke.Color = Color3.fromRGB(255, 205, 85)
					stroke.Thickness = 1.5
					stroke.Parent = frame

					local nameLabel = Instance.new("TextLabel")
					nameLabel.Name = "NameLabel"
					nameLabel.Size = UDim2.new(1, -6, 0.54, 0)
					nameLabel.Position = UDim2.new(0, 3, 0, 2)
					nameLabel.BackgroundTransparency = 1
					nameLabel.Font = Enum.Font.FredokaOne
					nameLabel.TextColor3 = Color3.fromRGB(255, 230, 110)
					nameLabel.TextScaled = true
					nameLabel.Parent = frame

					local moodLabel = Instance.new("TextLabel")
					moodLabel.Name = "MoodLabel"
					moodLabel.Size = UDim2.new(1, -6, 0.42, 0)
					moodLabel.Position = UDim2.new(0, 3, 0.54, 0)
					moodLabel.BackgroundTransparency = 1
					moodLabel.Font = Enum.Font.GothamBold
					moodLabel.TextColor3 = Color3.fromRGB(160, 235, 255)
					moodLabel.TextScaled = true
					moodLabel.Parent = frame
				end
			end

			dog.Parent = activePetsFolder
			if idx == 1 and isRiding and root then
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					root.Anchored = false
					root.Massless = true
					local _, dSize = dog:GetBoundingBox()
					local yOff = -(dSize.Y * 0.52)
					dog:PivotTo(hrp.CFrame * CFrame.new(0, yOff, 0))
					local rw = Instance.new("Weld")
					rw.Name = "RideWeld"
					rw.Part0 = hrp
					rw.Part1 = root
					rw.C0 = CFrame.new(0, yOff, 0)
					rw.C1 = CFrame.new()
					rw.Parent = root
					rw:SetAttribute("BaseY", yOff)
				end
			end
			table.insert(st.models, dog)
			table.insert(st.breeds, breedId)
		end
	end

	player:SetAttribute("ActivePetCount", #st.models)
	updatePetBillboard(player)
	updatePlayerTitleBadge(player)
end

local function applyRideSpeed(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hum then return end
	if hum:GetAttribute("BaseHipHeight") == nil then
		hum:SetAttribute("BaseHipHeight", hum.HipHeight)
	end
	local baseHip = hum:GetAttribute("BaseHipHeight") or 2.0
	local isRiding = player:GetAttribute("IsRiding") == true
	hum.WalkSpeed = isRiding and 36 or 16
	if isRiding then
		hum.HipHeight = baseHip + 2.1
		if hrp then
			hrp.CFrame = hrp.CFrame + Vector3.new(0, 2.1, 0)
		end
	else
		hum.HipHeight = baseHip
	end
end

local function savePlayerData(player)
	if not saveStore then return end
	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end
	local data = {
		Coins = ls.Coins.Value,
		DogLevel = player:GetAttribute("DogLevel") or 1,
		Exp = player:GetAttribute("Exp") or 0,
		MaxExp = player:GetAttribute("MaxExp") or 100,
		CurrentBreed = player:GetAttribute("CurrentBreed") or "Puppy",
		DogCustomName = player:GetAttribute("DogCustomName") or "초코",
		OwnedBreeds = player:GetAttribute("OwnedBreeds") or '["Puppy"]',
		EquippedAccessory = player:GetAttribute("EquippedAccessory") or "None",
		OwnedAccessories = player:GetAttribute("OwnedAccessories") or '["None"]',
		YardTier = player:GetAttribute("YardTier") or 0,
		EvolutionTier = player:GetAttribute("EvolutionTier") or 0,
		RebirthCount = player:GetAttribute("RebirthCount") or 0,
	}
	pcall(function()
		saveStore:SetAsync("Player_" .. tostring(player.UserId), data)
	end)
end

local function setupPlayer(player)
	local saved = nil
	if saveStore then
		pcall(function()
			saved = saveStore:GetAsync("Player_" .. tostring(player.UserId))
		end)
	end

	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = (saved and saved.Coins) or 160
	coins.Parent = ls

	local dogLevel = Instance.new("IntValue")
	dogLevel.Name = "DogLevel"
	dogLevel.Value = (saved and saved.DogLevel) or 1
	dogLevel.Parent = ls

	player:SetAttribute("CurrentBreed", (saved and saved.CurrentBreed) or "Puppy")
	player:SetAttribute("DogCustomName", (saved and saved.DogCustomName) or "초코")
	player:SetAttribute("DogLevel", (saved and saved.DogLevel) or 1)
	player:SetAttribute("Exp", (saved and saved.Exp) or 0)
	player:SetAttribute("MaxExp", (saved and saved.MaxExp) or 100)
	player:SetAttribute("Hunger", 85)
	player:SetAttribute("Cleanliness", 85)
	player:SetAttribute("Happiness", 90)
	player:SetAttribute("OwnedBreeds", (saved and saved.OwnedBreeds) or HttpService:JSONEncode({ "Puppy" }))
	player:SetAttribute("EquippedAccessory", (saved and saved.EquippedAccessory) or "None")
	player:SetAttribute("OwnedAccessories", (saved and saved.OwnedAccessories) or HttpService:JSONEncode({ "None" }))
	player:SetAttribute("YardTier", (saved and saved.YardTier) or 0)
	player:SetAttribute("EvolutionTier", (saved and saved.EvolutionTier) or 0)
	player:SetAttribute("RebirthCount", (saved and saved.RebirthCount) or 0)
	player:SetAttribute("IsRiding", false)
	player:SetAttribute("MaxPetsEquipped", 3)

	assignNewQuest(player)
	refreshYardVisuals(player:GetAttribute("YardTier") or 0)

	playerPetState[player] = {
		models = {},
		breeds = {},
		walkDist = 0,
		lastPos = nil,
		targetOverride = nil,
		bobTime = 0,
		cooldowns = {},
		isRacing = false,
	}

	player.CharacterAdded:Connect(function()
		task.wait(0.4)
		applyRideSpeed(player)
		spawnPlayerDogs(player)
	end)
	if player.Character then
		task.spawn(function()
			task.wait(0.3)
			applyRideSpeed(player)
			spawnPlayerDogs(player)
		end)
	end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	setupPlayer(p)
end

Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
	local st = playerPetState[player]
	if st and st.models then
		for _, m in ipairs(st.models) do m:Destroy() end
	end
	playerPetState[player] = nil
end)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do
		savePlayerData(p)
	end
end)

-- 1. Toggle Dog Riding
local function toggleRideDog(player)
	local cur = player:GetAttribute("IsRiding") == true
	local nextState = not cur
	player:SetAttribute("IsRiding", nextState)
	applyRideSpeed(player)
	spawnPlayerDogs(player)
	if nextState then
		sendNotify(player, "🏇 대장 강아지 라이딩 모드 ON! (이동속도 2배 질주!)", Color3.fromRGB(120, 235, 255))
	else
		sendNotify(player, "🐾 강아지 라이딩에서 내렸어요.", Color3.fromRGB(220, 230, 255))
	end
end

-- 2. Evolution Altar Function
local function evolveDog(player)
	local curEvo = player:GetAttribute("EvolutionTier") or 0
	if curEvo >= 3 then
		sendNotify(player, "🌈 이미 최고 단계 [코스믹 레인보우] 각성을 완료했어요!", Color3.fromRGB(255, 210, 90))
		return
	end
	local nxt = curEvo + 1
	local cost = EVO_COSTS[nxt]
	local ls = player:FindFirstChild("leaderstats")
	local coinsVal = ls and ls:FindFirstChild("Coins")
	if not coinsVal or coinsVal.Value < cost then
		sendNotify(player, string.format("✨ [%s] 진화에 %d 코인이 필요해요!", EVO_NAMES[nxt], cost), Color3.fromRGB(255, 115, 115))
		return
	end

	coinsVal.Value -= cost
	player:SetAttribute("EvolutionTier", nxt)
	spawnPlayerDogs(player)
	addExpAndCoins(player, 60 * nxt, 0, string.format("✨ 대성공! 강아지가 [%s](코인 x%.1f배) 단계로 각성했어요!", EVO_NAMES[nxt], EVO_MULT[nxt]))
end

-- 3. Rebirth Function
local function rebirthPlayer(player)
	local level = player:GetAttribute("DogLevel") or 1
	if level < 5 then
		sendNotify(player, string.format("👑 명예 브리더 승급(환생)은 강아지 Lv.5부터 가능해요! (현재 Lv.%d)", level), Color3.fromRGB(255, 140, 110))
		return
	end

	local rebates = (player:GetAttribute("RebirthCount") or 0) + 1
	player:SetAttribute("RebirthCount", rebates)
	player:SetAttribute("DogLevel", 1)
	player:SetAttribute("Exp", 0)
	player:SetAttribute("MaxExp", 100)
	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("DogLevel") then
		ls.DogLevel.Value = 1
	end
	if ls and ls:FindFirstChild("Coins") then
		ls.Coins.Value += rebates * 150
	end
	spawnPlayerDogs(player)
	sendNotify(player, string.format("👑 축하합니다! [명예 브리더 ★%d] 승급 완료! (영구 코인 배율 +%d%% & 축하금 +%d 코인)", rebates, rebates * 100, rebates * 150), Color3.fromRGB(255, 225, 65))
end

-- 4. Dog Speed Race Minigame
local raceInProgress = false
local function startDogRace(player)
	local st = playerPetState[player]
	if not st or st.isRacing or raceInProgress then
		sendNotify(player, "🏁 현재 경주가 진행 중이에요! 잠시만 기다려주세요!", Color3.fromRGB(255, 200, 100))
		return
	end
	raceInProgress = true
	st.isRacing = true
	player:SetAttribute("IsRiding", false)
	applyRideSpeed(player)

	sendNotify(player, "🏁 도그 스피드 레이싱 출발!! 내 강아지가 달립니다!", Color3.fromRGB(255, 215, 70))

	-- Spawn 2 Rival NPC Dogs on Lane 1 (X=30) & Lane 3 (X=38.4)
	local npc1 = dogTemplates:FindFirstChild("Corgi"):Clone()
	local npc2 = dogTemplates:FindFirstChild("Husky"):Clone()
	npc1.Parent = workspace
	npc2.Parent = workspace

	task.spawn(function()
		local startZ = -20
		local endZ = -66
		local duration = 3.2
		local elapsed = 0

		while elapsed < duration do
			local dt = task.wait()
			elapsed += dt
			local alpha = math.clamp(elapsed / duration, 0, 1)
			local bounce = math.abs(math.sin(elapsed * 18)) * 0.7

			-- Player's dog surges ahead in the second half!
			local pZ = startZ + (endZ - startZ) * math.clamp(alpha * 1.06, 0, 1)
			local n1Z = startZ + (endZ - startZ) * (alpha * 0.92)
			local n2Z = startZ + (endZ - startZ) * (alpha * 0.96)

			st.targetOverride = Vector3.new(34.2, 1.5 + bounce, pZ)
			npc1:PivotTo(CFrame.new(30.0, 1.8 + bounce, n1Z))
			npc2:PivotTo(CFrame.new(38.4, 2.0 + bounce, n2Z))
		end

		npc1:Destroy()
		npc2:Destroy()
		st.targetOverride = nil
		st.isRacing = false
		raceInProgress = false

		addExpAndCoins(player, 80, 90, "🏆 도그 레이싱 1등 우승!! 트로피 상금 획득!", "RaceStartStation")
	end)
end

-- Egg Gacha Roll Function
local GACHA_WEIGHTS = {
	{ id = "ShibaDoge", weight = 28 },
	{ id = "Pug", weight = 24 },
	{ id = "Corgi", weight = 18 },
	{ id = "Husky", weight = 12 },
	{ id = "GermanShepherd", weight = 8 },
	{ id = "GoldenRetriever", weight = 5 },
	{ id = "GoldenDoge", weight = 3.5 },
	{ id = "NeonHusky", weight = 1.5 },
}

local function hatchRandomEgg(player)
	local ls = player:FindFirstChild("leaderstats")
	local coinsVal = ls and ls:FindFirstChild("Coins")
	if not coinsVal or coinsVal.Value < 100 then
		sendNotify(player, "🥚 알 부화에는 100 코인이 필요해요!", Color3.fromRGB(255, 110, 110))
		return
	end
	coinsVal.Value -= 100

	local totalW = 0
	for _, item in ipairs(GACHA_WEIGHTS) do totalW += item.weight end
	local roll = math.random() * totalW
	local chosen = "ShibaDoge"
	local accum = 0
	for _, item in ipairs(GACHA_WEIGHTS) do
		accum += item.weight
		if roll <= accum then
			chosen = item.id
			break
		end
	end

	local info = BREED_DATA[chosen]
	local alreadyOwned = ownsBreed(player, chosen)
	addOwnedBreed(player, chosen)
	player:SetAttribute("CurrentBreed", chosen)
	spawnPlayerDogs(player)

	if alreadyOwned then
		addExpAndCoins(player, 65, 25, string.format("🥚 알에서 [%s](%s) 등장! (중복 보너스 EXP 획득!)", info.name, info.rarity))
	else
		emitHeartBurst(player, 30)
		sendNotify(player, string.format("🎊 대박! 알에서 [%s] 등급 [%s] 부화 성공!! (코인 x%.1f배)", info.rarity, info.name, info.coinMult), Color3.fromRGB(255, 225, 65))
	end
end

local function upgradeYard(player)
	local curTier = player:GetAttribute("YardTier") or 0
	if curTier >= 3 then
		sendNotify(player, "🏡 이미 최고 단계(3단계) 마당 업그레이드를 완료했어요!", Color3.fromRGB(130, 240, 170))
		return
	end
	local nextTier = curTier + 1
	local cost = YARD_COSTS[nextTier]
	local ls = player:FindFirstChild("leaderstats")
	local coinsVal = ls and ls:FindFirstChild("Coins")
	if not coinsVal or coinsVal.Value < cost then
		sendNotify(player, string.format("🏡 마당 %d단계 업그레이드에 %d 코인이 필요해요!", nextTier, cost), Color3.fromRGB(255, 115, 115))
		return
	end

	coinsVal.Value -= cost
	player:SetAttribute("YardTier", nextTier)
	refreshYardVisuals(nextTier)
	addExpAndCoins(player, 50 * nextTier, 0, "🏡 축하합니다! " .. YARD_NAMES[nextTier] .. " 설치 완료!")
end

local function handleAccessory(player, accId)
	local info = ACCESSORY_DATA[accId]
	if not info then return end

	if accId == "None" or ownsAccessory(player, accId) then
		player:SetAttribute("EquippedAccessory", accId)
		spawnPlayerDogs(player)
		sendNotify(player, string.format("🎩 강아지 악세서리 [%s] 장착 완료!", info.name), Color3.fromRGB(150, 230, 255))
		return
	end

	local ls = player:FindFirstChild("leaderstats")
	local coinsVal = ls and ls:FindFirstChild("Coins")
	if not coinsVal or coinsVal.Value < info.price then
		sendNotify(player, string.format("🎩 [%s] 구매에 %d 코인이 필요해요!", info.name, info.price), Color3.fromRGB(255, 115, 115))
		return
	end

	coinsVal.Value -= info.price
	addOwnedAccessory(player, accId)
	player:SetAttribute("EquippedAccessory", accId)
	spawnPlayerDogs(player)
	sendNotify(player, string.format("✨ [%s] 구매 & 장착 완료! (모든 코인 획득 +%d%%)", info.name, math.floor(info.bonus * 100)), Color3.fromRGB(255, 220, 80))
end

-- Connect Station Prompts
local STATION_REWARDS = {
	FeedStation = { stat = "Hunger", add = 45, happy = 10, exp = 25, coins = 15, msg = "🍖 강아지들이 맛있는 사료와 물을 먹었어요!" },
	BathStation = { stat = "Cleanliness", add = 55, happy = 15, exp = 30, coins = 20, msg = "🛁 뽀득뽀득! 향기로운 거품 목욕을 마쳤어요!" },
	SleepStation = { stat = "Happiness", add = 40, happy = 0, exp = 25, coins = 15, msg = "💤 쿨쿨~ 푹신한 침대에서 기분 좋게 쉬었어요!" },
	AgilityStation = { stat = "Happiness", add = 30, happy = 0, exp = 45, coins = 35, msg = "🏆 영차! 어질리티 장애물 훈련을 완벽히 성공했어요!" },
	WalkStation = { stat = "Happiness", add = 35, happy = 0, exp = 35, coins = 25, msg = "🌸 벚꽃나무 아래에서 행복한 산책을 즐겼어요!" },
	HydrantStation = { stat = "Happiness", add = 20, happy = 0, exp = 20, coins = 20, msg = "🚒 킁킁! 소화전 산책 체크포인트를 완료했어요!" },
	ToyStation = { stat = "Happiness", add = 30, happy = 0, exp = 25, coins = 20, msg = "🦴 뼈다귀 장난감을 신나게 가지고 놀았어요!" },
}

for _, stationPart in ipairs(stations:GetChildren()) do
	local prompt = stationPart:FindFirstChildOfClass("ProximityPrompt")
	local stType = stationPart:GetAttribute("StationType") or stationPart.Name
	if prompt then
		if STATION_REWARDS[stType] then
			prompt.Triggered:Connect(function(player)
				local st = playerPetState[player]
				if not st then return end
				local now = os.clock()
				if (st.cooldowns[stType] or 0) > now then return end
				st.cooldowns[stType] = now + 1.5

				local reward = STATION_REWARDS[stType]
				st.targetOverride = stationPart.Position + Vector3.new(0, 1.5, 0)
				task.delay(1.4, function()
					if playerPetState[player] and not playerPetState[player].isRacing then
						playerPetState[player].targetOverride = nil
					end
				end)

				local curVal = player:GetAttribute(reward.stat) or 80
				player:SetAttribute(reward.stat, math.clamp(curVal + reward.add, 0, 100))
				if reward.happy > 0 then
					local curH = player:GetAttribute("Happiness") or 80
					player:SetAttribute("Happiness", math.clamp(curH + reward.happy, 0, 100))
				end
				addExpAndCoins(player, reward.exp, reward.coins, reward.msg, stType)
			end)
		elseif stType == "EggGachaStation" then
			prompt.Triggered:Connect(hatchRandomEgg)
		elseif stType == "YardUpgradeStation" then
			prompt.Triggered:Connect(upgradeYard)
		elseif stType == "EvolutionStation" then
			prompt.Triggered:Connect(evolveDog)
		elseif stType == "RebirthStation" then
			prompt.Triggered:Connect(rebirthPlayer)
		elseif stType == "RaceStartStation" then
			prompt.Triggered:Connect(startDogRace)
		end
	end
end

-- Connect Town NPC Prompts
for _, npc in ipairs(npcFolder:GetChildren()) do
	local trig = npc:FindFirstChild("NPCTrigger")
	local prompt = trig and trig:FindFirstChildOfClass("ProximityPrompt")
	if trig and prompt then
		prompt.Triggered:Connect(function(player)
			local st = playerPetState[player]
			if not st then return end
			local now = os.clock()
			local key = "NPC_" .. npc.Name
			if (st.cooldowns[key] or 0) > now then
				sendNotify(player, "🙋 주민에게 방금 용돈을 받았어요! 다른 주민도 만나보세요~", Color3.fromRGB(255, 200, 110))
				return
			end
			st.cooldowns[key] = now + 10
			local quote = trig:GetAttribute("NPCQuote") or "귀여운 강아지네요!"
			local npcName = trig:GetAttribute("NPCName") or "이웃 주민"
			addExpAndCoins(player, 30, 35, string.format("🙋 [%s]: \"%s\"", npcName, quote))
		end)
	end
end

local function handleAdoptOrEquip(player, breedId)
	local info = BREED_DATA[breedId]
	if not info then return end

	if ownsBreed(player, breedId) then
		player:SetAttribute("CurrentBreed", breedId)
		spawnPlayerDogs(player)
		sendNotify(player, string.format("🐶 [%s] 강아지를 대장 강아지로 설정했어요!", info.name), Color3.fromRGB(130, 230, 255))
		return
	end

	if info.price >= 999 then
		sendNotify(player, "🥚 이 강아지는 [랜덤 알 뽑기]에서 획득할 수 있어요!", Color3.fromRGB(255, 215, 70))
		return
	end

	local ls = player:FindFirstChild("leaderstats")
	local coinsVal = ls and ls:FindFirstChild("Coins")
	if not coinsVal or coinsVal.Value < info.price then
		sendNotify(player, string.format("💰 코인이 부족해요! (%s 입양 비용: %d 코인)", info.name, info.price), Color3.fromRGB(255, 110, 110))
		return
	end

	coinsVal.Value -= info.price
	addOwnedBreed(player, breedId)
	player:SetAttribute("CurrentBreed", breedId)
	spawnPlayerDogs(player)
	sendNotify(player, string.format("🎊 새로운 가족 [%s] 입양 완료!", info.name), Color3.fromRGB(255, 220, 70))
end

for _, ped in ipairs(pedestals:GetChildren()) do
	local prompt = ped:FindFirstChildOfClass("ProximityPrompt")
	local breedId = ped:GetAttribute("BreedId")
	if prompt and breedId then
		prompt.Triggered:Connect(function(player)
			handleAdoptOrEquip(player, breedId)
		end)
	end
end

-- Spawn Hidden Treasures, Shooting Stars & Poop Events
local TREASURE_SPOTS = {
	Vector3.new(22, 0.5, -26),
	Vector3.new(-22, 0.5, -28),
	Vector3.new(28, 0.5, 22),
	Vector3.new(-26, 0.5, 26),
	Vector3.new(12, 0.5, -58),
	Vector3.new(-15, 0.5, -62),
	Vector3.new(45, 0.5, -18),
	Vector3.new(45, 0.5, 18),
}

local function spawnTreasure()
	if #treasuresFolder:GetChildren() >= 4 then return end
	local spot = TREASURE_SPOTS[math.random(1, #TREASURE_SPOTS)]
	local isChest = math.random() < 0.55
	local src = extraAssets:FindFirstChild(isChest and "DogeTreasureChest" or "GoldCoinModel")
	if not src then return end

	local tModel = src:Clone()
	tModel.Name = isChest and "TreasureChest" or "GoldenCoin"
	local cf, sz = tModel:GetBoundingBox()
	local pivotToCenter = cf.Position - tModel:GetPivot().Position
	tModel:PivotTo(CFrame.new(Vector3.new(spot.X + math.random(-5, 5), sz.Y / 2, spot.Z + math.random(-5, 5))) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0) * CFrame.new(-pivotToCenter))
	tModel.Parent = treasuresFolder

	local hitPart = Instance.new("Part")
	hitPart.Name = "TriggerPart"
	hitPart.Size = Vector3.new(3, 3, 3)
	hitPart.Position = tModel:GetPivot().Position
	hitPart.Anchored = true
	hitPart.CanCollide = false
	hitPart.Transparency = 1
	hitPart.Parent = tModel

	local sp = Instance.new("Sparkles")
	sp.SparkleColor = Color3.fromRGB(255, 225, 60)
	sp.Parent = hitPart

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = isChest and "💎 숨겨진 도지 보물상자" or "🪙 반짝이는 황금 코인"
	prompt.ActionText = "강아지와 보물 캐기"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 15
	prompt.RequiresLineOfSight = false
	prompt.Parent = hitPart

	local collected = false
	prompt.Triggered:Connect(function(player)
		if collected then return end
		collected = true
		addExpAndCoins(player, isChest and 40 or 25, isChest and 45 or 25, isChest and "💎 강아지가 도지 보물상자를 파냈어요!" or "🪙 강아지가 반짝이는 황금 코인을 물어왔어요!")
		tModel:Destroy()
	end)
end

for _ = 1, 4 do spawnTreasure() end

local function spawnShootingStar()
	if #starsFolder:GetChildren() >= 3 then return end
	local spot = TREASURE_SPOTS[math.random(1, #TREASURE_SPOTS)]
	local star = Instance.new("Part")
	star.Name = "ShootingStar"
	star.Shape = Enum.PartType.Ball
	star.Size = Vector3.new(2.2, 2.2, 2.2)
	star.Position = Vector3.new(spot.X + math.random(-8, 8), 1.4, spot.Z + math.random(-8, 8))
	star.Anchored = true
	star.CanCollide = false
	star.Color = Color3.fromRGB(255, 240, 95)
	star.Material = Enum.Material.Neon
	star.Parent = starsFolder

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 235, 100)
	light.Range = 18
	light.Brightness = 2
	light.Parent = star

	local sp = Instance.new("Sparkles")
	sp.SparkleColor = Color3.fromRGB(140, 245, 255)
	sp.Parent = star

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "🌠 밤하늘 별똥별 조각"
	prompt.ActionText = "별똥별 줍기 (+60 코인)"
	prompt.HoldDuration = 0.15
	prompt.MaxActivationDistance = 15
	prompt.RequiresLineOfSight = false
	prompt.Parent = star

	prompt.Triggered:Connect(function(player)
		if not star.Parent then return end
		star:Destroy()
		addExpAndCoins(player, 55, 60, "🌠 반짝이는 밤하늘 별똥별을 발견했어요! 대박 행운!")
	end)
	Debris:AddItem(star, 45)
end

local function spawnPoopNearPlayer(player)
	if #poopsFolder:GetChildren() >= 4 then return end
	local st = playerPetState[player]
	if not st or not st.models or not st.models[1] then return end
	local dogPos = st.models[1]:GetPivot().Position

	local poopPart = Instance.new("Part")
	poopPart.Name = "DogPoop"
	poopPart.Shape = Enum.PartType.Ball
	poopPart.Size = Vector3.new(1.3, 1.0, 1.3)
	poopPart.Position = Vector3.new(dogPos.X, 0.5, dogPos.Z)
	poopPart.Anchored = true
	poopPart.CanCollide = false
	poopPart.Color = Color3.fromRGB(115, 75, 40)
	poopPart.Material = Enum.Material.SmoothPlastic
	poopPart.Parent = poopsFolder

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "💩 강아지 응가"
	prompt.ActionText = "응가 치우기 (+25 코인)"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = poopPart

	prompt.Triggered:Connect(function(plr)
		if not poopPart.Parent then return end
		poopPart:Destroy()
		local c = plr:GetAttribute("Cleanliness") or 80
		plr:SetAttribute("Cleanliness", math.clamp(c + 20, 0, 100))
		addExpAndCoins(plr, 25, 25, "🧹 응가를 깨끗하게 치웠어요! 환경 미화 보너스!")
	end)
	Debris:AddItem(poopPart, 50)
end

-- Client UI Actions
local ZONE_CF = {
	Plaza = CFrame.new(0, 4, 0),
	Care = CFrame.new(-48, 4, 0),
	Park = CFrame.new(0, 4, -44),
	Agility = CFrame.new(44, 4, 0),
	PetShop = CFrame.new(0, 4, 36),
	Race = CFrame.new(34, 4, -15),
	Shelter = CFrame.new(-42, 4, -42),
}

actionRemote.OnServerEvent:Connect(function(player, actionType, arg1)
	local st = playerPetState[player]
	if not st then return end
	local now = os.clock()

	if actionType == "PetDog" then
		if (st.cooldowns.PetDog or 0) > now then return end
		st.cooldowns.PetDog = now + 1.0
		local curH = player:GetAttribute("Happiness") or 80
		player:SetAttribute("Happiness", math.clamp(curH + 15, 0, 100))
		addExpAndCoins(player, 15, 10, "💕 강아지들을 쓰다듬어 주었어요!")

	elseif actionType == "ToggleRide" then
		toggleRideDog(player)

	elseif actionType == "EvolveDog" then
		evolveDog(player)

	elseif actionType == "Rebirth" then
		rebirthPlayer(player)

	elseif actionType == "StartRace" then
		startDogRace(player)

	elseif actionType == "QuickTreat" then
		if (st.cooldowns.QuickTreat or 0) > now then return end
		st.cooldowns.QuickTreat = now + 1.2
		local ls = player:FindFirstChild("leaderstats")
		local coinsVal = ls and ls:FindFirstChild("Coins")
		if not coinsVal or coinsVal.Value < 10 then
			sendNotify(player, "💰 간식 구매에 10 코인이 필요해요!", Color3.fromRGB(255, 120, 120))
			return
		end
		coinsVal.Value -= 10
		local curHunger = player:GetAttribute("Hunger") or 80
		player:SetAttribute("Hunger", math.clamp(curHunger + 35, 0, 100))
		addExpAndCoins(player, 20, 0, "🦴 수제 간식을 주었어요! (배고픔 +35)", "FeedStation")

	elseif actionType == "ThrowBall" then
		if (st.cooldowns.ThrowBall or 0) > now then return end
		st.cooldowns.ThrowBall = now + 2.5
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local targetPos = hrp.Position + (hrp.CFrame.LookVector * 20)
		targetPos = Vector3.new(targetPos.X, 1.2, targetPos.Z)

		local ballTemp = ReplicatedStorage:FindFirstChild("DogBallToyTemplate")
		if ballTemp then
			local ballObj = ballTemp:Clone()
			for _, p in ipairs(ballObj:GetDescendants()) do
				if p:IsA("BasePart") then p.Anchored = true; p.CanCollide = false end
			end
			ballObj:PivotTo(CFrame.new(targetPos))
			ballObj.Parent = workspace
			Debris:AddItem(ballObj, 2.2)
		end

		st.targetOverride = targetPos + Vector3.new(0, 1.2, 0)
		sendNotify(player, "🎾 장난감을 던졌어요! 강아지 군단이 달려갑니다!", Color3.fromRGB(130, 230, 255))

		task.delay(1.4, function()
			if playerPetState[player] and not playerPetState[player].isRacing then
				playerPetState[player].targetOverride = nil
				local curH = player:GetAttribute("Happiness") or 80
				player:SetAttribute("Happiness", math.clamp(curH + 25, 0, 100))
				addExpAndCoins(player, 30, 22, "🎾 강아지들이 장난감을 물어왔어요!", "ThrowBall")
			end
		end)

	elseif actionType == "HatchEgg" then
		hatchRandomEgg(player)

	elseif actionType == "UpgradeYard" then
		upgradeYard(player)

	elseif actionType == "EquipAccessory" and type(arg1) == "string" then
		handleAccessory(player, arg1)

	elseif actionType == "AdoptBreed" and type(arg1) == "string" then
		handleAdoptOrEquip(player, arg1)

	elseif actionType == "RenameDog" and type(arg1) == "string" then
		local cleanName = string.sub(arg1, 1, 20)
		if #cleanName > 0 then
			player:SetAttribute("DogCustomName", cleanName)
			updatePetBillboard(player)
			sendNotify(player, "🏷️ 강아지 이름이 [" .. cleanName .. "](으)로 변경되었어요!", Color3.fromRGB(255, 225, 110))
		end

	elseif actionType == "TeleportZone" and type(arg1) == "string" then
		local targetCF = ZONE_CF[arg1]
		local char = player.Character
		if targetCF and char then
			char:PivotTo(targetCF)
		end
	end
end)

local FORMATION_OFFSETS = {
	[1] = CFrame.new(3.8, 0, 2.8),
	[2] = CFrame.new(-3.8, 0, 2.8),
	[3] = CFrame.new(0, 0, 5.2),
}

local decayTimer = 0
local treasureTimer = 0
RunService.Heartbeat:Connect(function(dt)
	decayTimer += dt
	treasureTimer += dt

	-- Gentle Day/Night Cycle (1 full cycle every ~3 minutes)
	Lighting.ClockTime = (Lighting.ClockTime + dt * 0.12) % 24
	local isNight = (Lighting.ClockTime >= 18 or Lighting.ClockTime <= 6)

	if treasureTimer >= 9 then
		treasureTimer = 0
		spawnTreasure()
		if isNight then
			spawnShootingStar()
		end
	end

	local doDecay = false
	if decayTimer >= 16 then
		decayTimer = 0
		doDecay = true
	end

	for player, st in pairs(playerPetState) do
		if doDecay then
			local h = math.max(15, (player:GetAttribute("Hunger") or 80) - 2)
			local c = math.max(15, (player:GetAttribute("Cleanliness") or 80) - 2)
			local hap = math.max(20, (player:GetAttribute("Happiness") or 80) - 1)
			player:SetAttribute("Hunger", h)
			player:SetAttribute("Cleanliness", c)
			player:SetAttribute("Happiness", hap)
			if math.random() < 0.4 then
				spawnPoopNearPlayer(player)
			end
			updatePetBillboard(player)
		end

		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and st.models then
			-- Auto-collect nearby Treasures & Shooting Stars
			for _, tModel in ipairs(treasuresFolder:GetChildren()) do
				local trig = tModel:FindFirstChild("TriggerPart")
				if trig and (trig.Position - hrp.Position).Magnitude < 13 then
					local isChest = (tModel.Name == "TreasureChest")
					tModel:Destroy()
					addExpAndCoins(player, isChest and 40 or 25, isChest and 45 or 25, isChest and "🐕‍🦺 강아지가 냄새를 맡아 도지 보물상자를 파냈어요!" or "🐕‍🦺 강아지가 황금 코인을 자동으로 주워왔어요!")
					break
				end
			end

			for _, star in ipairs(starsFolder:GetChildren()) do
				if star:IsA("BasePart") and (star.Position - hrp.Position).Magnitude < 13 then
					star:Destroy()
					addExpAndCoins(player, 55, 60, "🌠 강아지가 밤하늘 별똥별 조각을 물어왔어요!")
					break
				end
			end

			local isRiding = player:GetAttribute("IsRiding") == true
			st.bobTime += dt * (isRiding and 16 or 11)

			for idx, dog in ipairs(st.models) do
				if dog and dog.PrimaryPart then
					local _, dogSize = dog:GetBoundingBox()
					local groundY = (dogSize.Y / 2)

					if idx == 1 and isRiding and not st.targetOverride then
						-- Handled by 60FPS physical RideWeld on HumanoidRootPart!
						if not dog.PrimaryPart:FindFirstChild("RideWeld") then
							dog.PrimaryPart.Anchored = false
							local yOff = -(dogSize.Y * 0.52)
							local rw = Instance.new("Weld")
							rw.Name = "RideWeld"
							rw.Part0 = hrp
							rw.Part1 = dog.PrimaryPart
							rw.C0 = CFrame.new(0, yOff, 0)
							rw.Parent = dog.PrimaryPart
							rw:SetAttribute("BaseY", yOff)
						end
					else
						local formOffset = FORMATION_OFFSETS[idx] or CFrame.new(3.5 * idx, 0, 3)
						local goalPos
						if st.targetOverride then
							local spread = Vector3.new((idx - 1) * 2.5, 0, 0)
							goalPos = Vector3.new(st.targetOverride.X, groundY + 0.4, st.targetOverride.Z) + spread
						else
							local followWorld = (hrp.CFrame * formOffset).Position
							goalPos = Vector3.new(followWorld.X, groundY, followWorld.Z)
						end

						local curPos = dog:GetPivot().Position
						local flatVec = Vector3.new(goalPos.X - curPos.X, 0, goalPos.Z - curPos.Z)
						local dist = flatVec.Magnitude

						local newPos = curPos:Lerp(goalPos, math.clamp(dt * 8.5, 0, 1))
						local bobY = 0
						local rollTilt = 0
						if dist > 0.35 then
							bobY = math.abs(math.sin(st.bobTime + idx)) * 0.55
							rollTilt = math.sin(st.bobTime + idx) * math.rad(7)
						end

						local lookDir = flatVec.Magnitude > 0.2 and flatVec.Unit or hrp.CFrame.LookVector
						local baseLook = CFrame.lookAt(Vector3.zero, Vector3.new(lookDir.X, 0, lookDir.Z))
						local tiltCF = CFrame.Angles(0, 0, rollTilt)

						dog:PivotTo(CFrame.new(newPos.X, goalPos.Y + bobY, newPos.Z) * baseLook * tiltCF)
					end
				end
			end

			if st.lastPos then
				local step = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - st.lastPos).Magnitude
				if step > 0.1 and step < 18 then
					st.walkDist += step
					if st.walkDist >= 80 then
						st.walkDist = 0
						addExpAndCoins(player, 18, 15, "🐾 강아지 군단과 신나는 산책 보너스!", "WalkStation")
					end
				end
			end
			st.lastPos = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
		end
	end
end)


-- === Animal Shelter & Stray Dog Rescue Volunteer System ===
local strayFolder = world:WaitForChild("StrayDogs")

local function addVolunteerPoint(player, expGain, coinGain, msg, stationKey)
	local vCount = (player:GetAttribute("VolunteerCount") or 0) + 1
	player:SetAttribute("VolunteerCount", vCount)
	addExpAndCoins(player, expGain, coinGain, string.format("%s (봉사 누적 %d회)", msg, vCount), stationKey)

	if vCount % 3 == 0 then
		local ls = player:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("Coins") then
			ls.Coins.Value += 120
		end
		sendNotify(player, string.format("💌 [유기견 보호소] 봉사 %d회 달성! 특별 봉사 장학금 +120 코인 지급!!", vCount), Color3.fromRGB(255, 145, 205))
	end
end

local VOLUNTEER_STATIONS = {
	ShelterFeedStation = { exp = 40, coins = 45, msg = "🍲 유기견 친구들에게 따뜻한 특식 사료를 배식했어요!" },
	ShelterMedStation = { exp = 45, coins = 55, msg = "🩺 다친 유기견을 정성껏 치료하고 건강검진을 마쳤어요!" },
	ShelterCleanStation = { exp = 40, coins = 50, msg = "🧹 유기견 보호소 견사와 이불을 포근하고 깨끗하게 청소했어요!" },
}

for sName, vInfo in pairs(VOLUNTEER_STATIONS) do
	local stPart = stations:FindFirstChild(sName)
	local prompt = stPart and stPart:FindFirstChildOfClass("ProximityPrompt")
	if stPart and prompt then
		prompt.Triggered:Connect(function(player)
			local st = playerPetState[player]
			if not st then return end
			local now = os.clock()
			if (st.cooldowns[sName] or 0) > now then
				sendNotify(player, "⏳ 방금 해당 봉사를 마쳤어요! 옆의 다른 봉사대나 구조 활동을 해보세요!", Color3.fromRGB(255, 195, 110))
				return
			end
			st.cooldowns[sName] = now + 2.0
			addVolunteerPoint(player, vInfo.exp, vInfo.coins, vInfo.msg, sName)
		end)
	end
end

-- Spawn Lost Stray Dogs around the Town for Rescue Volunteer Work
local STRAY_SPOTS = {
	Vector3.new(-20, 0, -32),
	Vector3.new(20, 0, -20),
	Vector3.new(-28, 0, 18),
	Vector3.new(24, 0, 26),
	Vector3.new(-14, 0, -58),
}
local STRAY_BREEDS = { "Puppy", "ShibaDoge", "Pug", "Corgi" }

local function spawnStrayDog()
	if #strayFolder:GetChildren() >= 3 then return end
	local spot = STRAY_SPOTS[math.random(1, #STRAY_SPOTS)]
	local bName = STRAY_BREEDS[math.random(1, #STRAY_BREEDS)]
	local template = dogTemplates:FindFirstChild(bName)
	if not template then return end

	local stray = template:Clone()
	stray.Name = "StrayDog_" .. bName
	for _, p in ipairs(stray:GetDescendants()) do
		if p:IsA("BasePart") then p.Anchored = true; p.CanCollide = false end
	end

	local cf, sz = stray:GetBoundingBox()
	local pivotToCenter = cf.Position - stray:GetPivot().Position
	local pos = Vector3.new(spot.X + math.random(-4, 4), sz.Y / 2, spot.Z + math.random(-4, 4))
	stray:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0) * CFrame.new(-pivotToCenter))
	stray.Parent = strayFolder

	local root = stray.PrimaryPart
	if root then
		local bg = Instance.new("BillboardGui")
		bg.Size = UDim2.new(3.8, 0, 0.9, 0)
		bg.StudsOffset = Vector3.new(0, 2.5, 0)
		bg.AlwaysOnTop = false
		bg.MaxDistance = 32
		bg.Parent = root

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundColor3 = Color3.fromRGB(45, 30, 40)
		lbl.BackgroundTransparency = 0.2
		lbl.Font = Enum.Font.FredokaOne
		lbl.TextColor3 = Color3.fromRGB(255, 190, 210)
		lbl.TextScaled = true
		lbl.Text = "🥺 길 잃은 유기견 (구조하기 +65코인)"
		lbl.Parent = bg
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = lbl

		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "🥺 길 잃은 아기 유기견"
		prompt.ActionText = "💖 안아주고 보호소로 구조하기 (+65 코인)"
		prompt.HoldDuration = 0.25
		prompt.MaxActivationDistance = 13
		prompt.RequiresLineOfSight = false
		prompt.Parent = root

		local rescued = false
		prompt.Triggered:Connect(function(player)
			if rescued then return end
			rescued = true
			addVolunteerPoint(player, 50, 65, "💖 길 잃은 유기견을 따뜻하게 안아 구조했어요!")
			stray:Destroy()
		end)
	end
end

for _ = 1, 3 do spawnStrayDog() end
task.spawn(function()
	while task.wait(12) do
		spawnStrayDog()
	end
end)

