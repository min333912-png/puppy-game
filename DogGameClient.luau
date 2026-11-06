local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("DogRemotes")
local actionRemote = remotes:WaitForChild("DogAction")
local notifyRemote = remotes:WaitForChild("DogNotify")

local BREEDS = {
	{ id = "Puppy", name = "아기 강아지", price = 0, desc = "일반 | 코인 x1.0배 (기본)" },
	{ id = "ShibaDoge", name = "시바견 (도지)", price = 50, desc = "일반 | 코인 x1.2배" },
	{ id = "Pug", name = "귀염둥이 퍼그", price = 80, desc = "희귀 | 코인 x1.35배" },
	{ id = "Corgi", name = "웰시코기", price = 120, desc = "희귀 | 코인 x1.5배" },
	{ id = "Husky", name = "시베리안 허스키", price = 180, desc = "영웅 | 코인 x1.8배" },
	{ id = "GermanShepherd", name = "저먼 셰퍼드", price = 250, desc = "영웅 | 코인 x2.2배" },
	{ id = "GoldenRetriever", name = "골든 리트리버", price = 350, desc = "전설 | 코인 x3.0배" },
	{ id = "GoldenDoge", name = "✨황금 시바견", price = 999, desc = "전설(알뽑기) | 코인 x4.0배" },
	{ id = "NeonHusky", name = "🌈네온 허스키", price = 999, desc = "신화(알뽑기) | 코인 x5.0배" },
}

local ACCESSORIES = {
	{ id = "None", name = "장착 해제", price = 0, desc = "기본 상태" },
	{ id = "RoyalCrown", name = "👑 왕실 황금 왕관", price = 60, desc = "모든 코인 +15% 보너스" },
	{ id = "WizardHat", name = "🧙 대마법사 모자", price = 90, desc = "모든 코인 +25% 보너스" },
	{ id = "AngelWings", name = "👼 순백의 천사 날개", price = 150, desc = "모든 코인 +40% 보너스" },
	{ id = "StarHalo", name = "🌟 네온 스타 헤일로", price = 220, desc = "모든 코인 +60% 보너스" },
}

local BREED_NAMES = {}
for _, b in ipairs(BREEDS) do BREED_NAMES[b.id] = b.name end

local oldGui = playerGui:FindFirstChild("DogRaisingGui")
if oldGui then oldGui:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "DogRaisingGui"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = false
sg.Parent = playerGui

local function addCorner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = inst
	return c
end

local function addStroke(inst, color, thick)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(255, 210, 90)
	s.Thickness = thick or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

-- 1. Compact Top-Left Status Panel (210 x 154, collapsible)
local statusCard = Instance.new("Frame")
statusCard.Name = "StatusCard"
statusCard.Size = UDim2.new(0, 210, 0, 154)
statusCard.Position = UDim2.new(0, 10, 0, 8)
statusCard.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
statusCard.BackgroundTransparency = 0.22
statusCard.ClipsDescendants = true
statusCard.Parent = sg
addCorner(statusCard, 10)
addStroke(statusCard, Color3.fromRGB(255, 205, 85), 1.5)

local headerLabel = Instance.new("TextLabel")
headerLabel.Size = UDim2.new(1, -32, 0, 18)
headerLabel.Position = UDim2.new(0, 6, 0, 4)
headerLabel.BackgroundTransparency = 1
headerLabel.Font = Enum.Font.FredokaOne
headerLabel.TextColor3 = Color3.fromRGB(255, 225, 100)
headerLabel.TextScaled = true
headerLabel.TextXAlignment = Enum.TextXAlignment.Left
headerLabel.Text = "🐾 [Lv.1] 초코 (1/3)"
headerLabel.Parent = statusCard

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 20, 0, 18)
minBtn.Position = UDim2.new(1, -24, 0, 4)
minBtn.BackgroundColor3 = Color3.fromRGB(55, 65, 90)
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextScaled = true
minBtn.Text = "-"
minBtn.Parent = statusCard
addCorner(minBtn, 5)

local isMinimized = false
minBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	statusCard.Size = isMinimized and UDim2.new(0, 210, 0, 26) or UDim2.new(0, 210, 0, 154)
	minBtn.Text = isMinimized and "+" or "-"
end)

local coinLabel = Instance.new("TextLabel")
coinLabel.Size = UDim2.new(0.55, 0, 0, 16)
coinLabel.Position = UDim2.new(0, 6, 0, 24)
coinLabel.BackgroundTransparency = 1
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextColor3 = Color3.fromRGB(255, 235, 130)
coinLabel.TextScaled = true
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.Text = "💰 160 코인"
coinLabel.Parent = statusCard

local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.new(0, 54, 0, 16)
nameBox.Position = UDim2.new(1, -92, 0, 24)
nameBox.BackgroundColor3 = Color3.fromRGB(45, 50, 68)
nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
nameBox.PlaceholderText = "이름"
nameBox.Text = ""
nameBox.Font = Enum.Font.GothamBold
nameBox.TextScaled = true
nameBox.Parent = statusCard
addCorner(nameBox, 4)

local renameBtn = Instance.new("TextButton")
renameBtn.Size = UDim2.new(0, 32, 0, 16)
renameBtn.Position = UDim2.new(1, -36, 0, 24)
renameBtn.BackgroundColor3 = Color3.fromRGB(90, 165, 255)
renameBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
renameBtn.Font = Enum.Font.GothamBold
renameBtn.TextScaled = true
renameBtn.Text = "변경"
renameBtn.Parent = statusCard
addCorner(renameBtn, 4)

renameBtn.MouseButton1Click:Connect(function()
	if #nameBox.Text > 0 then
		actionRemote:FireServer("RenameDog", nameBox.Text)
		nameBox.Text = ""
	end
end)

local questBanner = Instance.new("Frame")
questBanner.Size = UDim2.new(1, -12, 0, 18)
questBanner.Position = UDim2.new(0, 6, 0, 43)
questBanner.BackgroundColor3 = Color3.fromRGB(42, 52, 78)
questBanner.Parent = statusCard
addCorner(questBanner, 5)

local questLabel = Instance.new("TextLabel")
questLabel.Size = UDim2.new(1, -8, 1, -2)
questLabel.Position = UDim2.new(0, 4, 0, 1)
questLabel.BackgroundTransparency = 1
questLabel.Font = Enum.Font.GothamBold
questLabel.TextColor3 = Color3.fromRGB(145, 235, 255)
questLabel.TextScaled = true
questLabel.TextXAlignment = Enum.TextXAlignment.Left
questLabel.Text = "🎯 소원: 급식소 밥 주기 (x2)"
questLabel.Parent = questBanner

local function createStatBar(labelText, yPos, barColor)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -12, 0, 20)
	container.Position = UDim2.new(0, 6, 0, yPos)
	container.BackgroundTransparency = 1
	container.Parent = statusCard

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 11)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextColor3 = Color3.fromRGB(235, 240, 255)
	lbl.TextScaled = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = labelText
	lbl.Parent = container

	local bgBar = Instance.new("Frame")
	bgBar.Size = UDim2.new(1, 0, 0, 7)
	bgBar.Position = UDim2.new(0, 0, 0, 12)
	bgBar.BackgroundColor3 = Color3.fromRGB(48, 54, 72)
	bgBar.Parent = container
	addCorner(bgBar, 4)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0.8, 0, 1, 0)
	fill.BackgroundColor3 = barColor
	fill.Parent = bgBar
	addCorner(fill, 4)

	return fill, lbl
end

local expFill, expLbl = createStatBar("⭐ EXP (0/100)", 64, Color3.fromRGB(255, 210, 70))
local hungerFill, hungerLbl = createStatBar("🍖 배고픔 (85%)", 86, Color3.fromRGB(255, 145, 65))
local cleanFill, cleanLbl = createStatBar("🛁 청결도 (85%)", 108, Color3.fromRGB(85, 205, 255))
local happyFill, happyLbl = createStatBar("💕 행복도 (90%)", 130, Color3.fromRGB(255, 115, 175))

-- 2. Compact Bottom Action Dock (550 x 38, 7 sleek buttons)
local dock = Instance.new("Frame")
dock.Name = "ActionDock"
dock.Size = UDim2.new(0, 550, 0, 38)
dock.Position = UDim2.new(0.5, -275, 1, -44)
dock.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
dock.BackgroundTransparency = 0.2
dock.Parent = sg
addCorner(dock, 10)
addStroke(dock, Color3.fromRGB(255, 205, 85), 1.5)

local dockLayout = Instance.new("UIListLayout")
dockLayout.FillDirection = Enum.FillDirection.Horizontal
dockLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
dockLayout.VerticalAlignment = Enum.VerticalAlignment.Center
dockLayout.Padding = UDim.new(0, 4)
dockLayout.Parent = dock

local function makeDockBtn(text, color, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 73, 0, 28)
	btn.BackgroundColor3 = color
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.Text = text
	btn.Parent = dock
	addCorner(btn, 6)
	btn.MouseButton1Click:Connect(callback)
	return btn
end

-- 3. Dog Shop / Catalog Modal (Compact 380 x 280)
local shopModal = Instance.new("Frame")
shopModal.Name = "ShopModal"
shopModal.Size = UDim2.new(0, 380, 0, 280)
shopModal.Position = UDim2.new(0.5, -190, 0.5, -140)
shopModal.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
shopModal.Visible = false
shopModal.Parent = sg
addCorner(shopModal, 12)
addStroke(shopModal, Color3.fromRGB(255, 215, 85), 2)

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, -48, 0, 26)
shopTitle.Position = UDim2.new(0, 12, 0, 6)
shopTitle.BackgroundTransparency = 1
shopTitle.Font = Enum.Font.FredokaOne
shopTitle.TextColor3 = Color3.fromRGB(255, 225, 95)
shopTitle.TextScaled = true
shopTitle.TextXAlignment = Enum.TextXAlignment.Left
shopTitle.Text = "🐕‍🦺 강아지 도감 (최대 3마리 자동 동행!)"
shopTitle.Parent = shopModal

local closeShop = Instance.new("TextButton")
closeShop.Size = UDim2.new(0, 26, 0, 26)
closeShop.Position = UDim2.new(1, -34, 0, 6)
closeShop.BackgroundColor3 = Color3.fromRGB(235, 85, 85)
closeShop.TextColor3 = Color3.fromRGB(255, 255, 255)
closeShop.Font = Enum.Font.FredokaOne
closeShop.TextScaled = true
closeShop.Text = "X"
closeShop.Parent = shopModal
addCorner(closeShop, 6)
closeShop.MouseButton1Click:Connect(function() shopModal.Visible = false end)

local breedList = Instance.new("ScrollingFrame")
breedList.Size = UDim2.new(1, -20, 1, -44)
breedList.Position = UDim2.new(0, 10, 0, 36)
breedList.BackgroundTransparency = 1
breedList.ScrollBarThickness = 5
breedList.CanvasSize = UDim2.new(0, 0, 0, #BREEDS * 40)
breedList.Parent = shopModal

local breedLayout = Instance.new("UIListLayout")
breedLayout.Padding = UDim.new(0, 5)
breedLayout.Parent = breedList

local breedButtons = {}
for _, b in ipairs(BREEDS) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 34)
	row.BackgroundColor3 = Color3.fromRGB(38, 44, 62)
	row.Parent = breedList
	addCorner(row, 8)

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(0.64, 0, 1, -6)
	nameLbl.Position = UDim2.new(0, 8, 0, 3)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextColor3 = Color3.fromRGB(245, 248, 255)
	nameLbl.TextScaled = true
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Text = string.format("🐾 %s (%s)", b.name, b.desc)
	nameLbl.Parent = row

	local actBtn = Instance.new("TextButton")
	actBtn.Size = UDim2.new(0.30, 0, 0, 24)
	actBtn.Position = UDim2.new(0.68, 0, 0.5, -12)
	actBtn.BackgroundColor3 = Color3.fromRGB(85, 195, 115)
	actBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	actBtn.Font = Enum.Font.GothamBold
	actBtn.TextScaled = true
	actBtn.Parent = row
	addCorner(actBtn, 6)

	actBtn.MouseButton1Click:Connect(function()
		if b.price >= 999 and not actBtn:GetAttribute("IsOwned") then
			actionRemote:FireServer("HatchEgg")
		else
			actionRemote:FireServer("AdoptBreed", b.id)
		end
	end)
	breedButtons[b.id] = { btn = actBtn, price = b.price }
end

-- 4. Costume, Evolution, Yard & Rebirth Modal (Compact 390 x 300)
local accModal = Instance.new("Frame")
accModal.Name = "AccModal"
accModal.Size = UDim2.new(0, 390, 0, 300)
accModal.Position = UDim2.new(0.5, -195, 0.5, -150)
accModal.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
accModal.Visible = false
accModal.Parent = sg
addCorner(accModal, 12)
addStroke(accModal, Color3.fromRGB(160, 225, 255), 2)

local accTitle = Instance.new("TextLabel")
accTitle.Size = UDim2.new(1, -48, 0, 24)
accTitle.Position = UDim2.new(0, 12, 0, 5)
accTitle.BackgroundTransparency = 1
accTitle.Font = Enum.Font.FredokaOne
accTitle.TextColor3 = Color3.fromRGB(160, 230, 255)
accTitle.TextScaled = true
accTitle.TextXAlignment = Enum.TextXAlignment.Left
accTitle.Text = "✨ 진화 / 👑 승급 / 🏡 마당 / 🎩 코스튬"
accTitle.Parent = accModal

local closeAcc = Instance.new("TextButton")
closeAcc.Size = UDim2.new(0, 24, 0, 24)
closeAcc.Position = UDim2.new(1, -32, 0, 5)
closeAcc.BackgroundColor3 = Color3.fromRGB(235, 85, 85)
closeAcc.TextColor3 = Color3.fromRGB(255, 255, 255)
closeAcc.Font = Enum.Font.FredokaOne
closeAcc.TextScaled = true
closeAcc.Text = "X"
closeAcc.Parent = accModal
addCorner(closeAcc, 6)
closeAcc.MouseButton1Click:Connect(function() accModal.Visible = false end)

local evoBtn = Instance.new("TextButton")
evoBtn.Size = UDim2.new(0.47, 0, 0, 28)
evoBtn.Position = UDim2.new(0, 10, 0, 33)
evoBtn.BackgroundColor3 = Color3.fromRGB(175, 95, 245)
evoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
evoBtn.Font = Enum.Font.GothamBold
evoBtn.TextScaled = true
evoBtn.Text = "✨ 오라 진화 (150코인)"
evoBtn.Parent = accModal
addCorner(evoBtn, 7)
evoBtn.MouseButton1Click:Connect(function() actionRemote:FireServer("EvolveDog") end)

local rebBtn = Instance.new("TextButton")
rebBtn.Size = UDim2.new(0.47, 0, 0, 28)
rebBtn.Position = UDim2.new(0.51, 0, 0, 33)
rebBtn.BackgroundColor3 = Color3.fromRGB(240, 180, 45)
rebBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rebBtn.Font = Enum.Font.GothamBold
rebBtn.TextScaled = true
rebBtn.Text = "👑 명예 승급 (Lv.5+)"
rebBtn.Parent = accModal
addCorner(rebBtn, 7)
rebBtn.MouseButton1Click:Connect(function() actionRemote:FireServer("Rebirth") end)

local yardUpgradeBtn = Instance.new("TextButton")
yardUpgradeBtn.Size = UDim2.new(1, -20, 0, 26)
yardUpgradeBtn.Position = UDim2.new(0, 10, 0, 65)
yardUpgradeBtn.BackgroundColor3 = Color3.fromRGB(70, 190, 120)
yardUpgradeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
yardUpgradeBtn.Font = Enum.Font.GothamBold
yardUpgradeBtn.TextScaled = true
yardUpgradeBtn.Text = "🏡 케어존 마당 업그레이드"
yardUpgradeBtn.Parent = accModal
addCorner(yardUpgradeBtn, 7)
yardUpgradeBtn.MouseButton1Click:Connect(function() actionRemote:FireServer("UpgradeYard") end)

local accList = Instance.new("ScrollingFrame")
accList.Size = UDim2.new(1, -20, 1, -102)
accList.Position = UDim2.new(0, 10, 0, 96)
accList.BackgroundTransparency = 1
accList.ScrollBarThickness = 5
accList.CanvasSize = UDim2.new(0, 0, 0, #ACCESSORIES * 38)
accList.Parent = accModal

local accLayout = Instance.new("UIListLayout")
accLayout.Padding = UDim.new(0, 5)
accLayout.Parent = accList

local accButtons = {}
for _, a in ipairs(ACCESSORIES) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 32)
	row.BackgroundColor3 = Color3.fromRGB(38, 44, 62)
	row.Parent = accList
	addCorner(row, 8)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.64, 0, 1, -6)
	lbl.Position = UDim2.new(0, 8, 0, 3)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextColor3 = Color3.fromRGB(245, 248, 255)
	lbl.TextScaled = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = string.format("%s (%s)", a.name, a.desc)
	lbl.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.30, 0, 0, 22)
	btn.Position = UDim2.new(0.68, 0, 0.5, -11)
	btn.BackgroundColor3 = Color3.fromRGB(90, 175, 245)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.Parent = row
	addCorner(btn, 6)

	btn.MouseButton1Click:Connect(function()
		actionRemote:FireServer("EquipAccessory", a.id)
	end)
	accButtons[a.id] = { btn = btn, price = a.price }
end

local rideBtn = makeDockBtn("🏇 타기(R)", Color3.fromRGB(65, 195, 225), function()
	actionRemote:FireServer("ToggleRide")
end)
makeDockBtn("💕 쓰다듬기", Color3.fromRGB(240, 105, 160), function() actionRemote:FireServer("PetDog") end)
makeDockBtn("🦴 간식(10)", Color3.fromRGB(240, 150, 65), function() actionRemote:FireServer("QuickTreat") end)
makeDockBtn("🎾 공던지기", Color3.fromRGB(75, 185, 245), function() actionRemote:FireServer("ThrowBall") end)
makeDockBtn("🥚 알뽑기", Color3.fromRGB(245, 190, 50), function() actionRemote:FireServer("HatchEgg") end)
makeDockBtn("🐶 도감", Color3.fromRGB(145, 110, 245), function()
	accModal.Visible = false
	shopModal.Visible = not shopModal.Visible
end)
makeDockBtn("✨ 성장/옷", Color3.fromRGB(70, 195, 150), function()
	shopModal.Visible = false
	accModal.Visible = not accModal.Visible
end)

-- Keyboard Shortcut 'R' for Dog Riding
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.R then
		actionRemote:FireServer("ToggleRide")
	end
end)

-- 5. Compact Right-Side Teleport Bar (108 x 168, collapsible)
local teleBar = Instance.new("Frame")
teleBar.Name = "TeleportBar"
teleBar.Size = UDim2.new(0, 108, 0, 190)
teleBar.Position = UDim2.new(1, -116, 0, 8)
teleBar.BackgroundColor3 = Color3.fromRGB(26, 30, 42)
teleBar.BackgroundTransparency = 0.22
teleBar.ClipsDescendants = true
teleBar.Parent = sg
addCorner(teleBar, 10)
addStroke(teleBar, Color3.fromRGB(130, 215, 255), 1.5)

local teleTitle = Instance.new("TextButton")
teleTitle.Size = UDim2.new(1, 0, 0, 20)
teleTitle.Position = UDim2.new(0, 0, 0, 2)
teleTitle.BackgroundTransparency = 1
teleTitle.Font = Enum.Font.FredokaOne
teleTitle.TextColor3 = Color3.fromRGB(150, 225, 255)
teleTitle.TextScaled = true
teleTitle.Text = "🗺️ 구역 이동 ▾"
teleTitle.Parent = teleBar

local teleMin = false
teleTitle.MouseButton1Click:Connect(function()
	teleMin = not teleMin
	teleBar.Size = teleMin and UDim2.new(0, 108, 0, 24) or UDim2.new(0, 108, 0, 190)
	teleTitle.Text = teleMin and "🗺️ 구역 이동 ▸" or "🗺️ 구역 이동 ▾"
end)

local zones = {
	{ id = "Shelter", label = "🏥 유기견 보호소" },
	{ id = "Care", label = "🏠 홈 케어존" },
	{ id = "Park", label = "🌸 벚꽃 공원" },
	{ id = "Race", label = "🏁 레이싱 트랙" },
	{ id = "Agility", label = "🏆 어질리티" },
	{ id = "PetShop", label = "🏪 펫샵 분양" },
	{ id = "Plaza", label = "🥚 중앙 광장" },
}

for i, z in ipairs(zones) do
	local zBtn = Instance.new("TextButton")
	zBtn.Size = UDim2.new(1, -10, 0, 20)
	zBtn.Position = UDim2.new(0, 5, 0, 24 + (i - 1) * 23)
	zBtn.BackgroundColor3 = Color3.fromRGB(48, 60, 88)
	zBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
	zBtn.Font = Enum.Font.GothamBold
	zBtn.TextScaled = true
	zBtn.Text = z.label
	zBtn.Parent = teleBar
	addCorner(zBtn, 6)
	zBtn.MouseButton1Click:Connect(function()
		actionRemote:FireServer("TeleportZone", z.id)
	end)
end

-- 6. Compact Top-Center Toast Notification (320 x 28)
local toastFrame = Instance.new("Frame")
toastFrame.Size = UDim2.new(0, 320, 0, 28)
toastFrame.Position = UDim2.new(0.5, -160, 0, 8)
toastFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
toastFrame.BackgroundTransparency = 0.15
toastFrame.Visible = false
toastFrame.Parent = sg
addCorner(toastFrame, 8)
local toastStroke = addStroke(toastFrame, Color3.fromRGB(255, 220, 90), 1.5)

local toastLabel = Instance.new("TextLabel")
toastLabel.Size = UDim2.new(1, -12, 1, -4)
toastLabel.Position = UDim2.new(0, 6, 0, 2)
toastLabel.BackgroundTransparency = 1
toastLabel.Font = Enum.Font.GothamBold
toastLabel.TextColor3 = Color3.fromRGB(255, 240, 150)
toastLabel.TextScaled = true
toastLabel.Text = ""
toastLabel.Parent = toastFrame

local function playSFX(name)
	local s = SoundService:FindFirstChild(name)
	if s and s:IsA("Sound") then s:Play() end
end

local toastToken = 0
notifyRemote.OnClientEvent:Connect(function(msg, color)
	toastToken += 1
	local myToken = toastToken
	toastLabel.Text = msg
	toastLabel.TextColor3 = color or Color3.fromRGB(255, 235, 130)
	toastStroke.Color = color or Color3.fromRGB(255, 220, 90)
	toastFrame.Visible = true

	if string.find(msg, "레벨 업") or string.find(msg, "미션 달성") or string.find(msg, "부화 성공") or string.find(msg, "승급") or string.find(msg, "우승") or string.find(msg, "각성") then
		playSFX("FanfareSFX")
		playSFX("BarkSFX")
	elseif string.find(msg, "쓰다듬어") or string.find(msg, "장난감") or string.find(msg, "라이딩") then
		playSFX("BarkSFX")
	else
		playSFX("CoinSFX")
	end

	task.delay(2.8, function()
		if toastToken == myToken then toastFrame.Visible = false end
	end)
end)

local function refreshUI()
	local breedId = player:GetAttribute("CurrentBreed") or "Puppy"
	local customName = player:GetAttribute("DogCustomName") or "초코"
	local level = player:GetAttribute("DogLevel") or 1
	local exp = player:GetAttribute("Exp") or 0
	local maxExp = math.max(1, player:GetAttribute("MaxExp") or 100)
	local hunger = player:GetAttribute("Hunger") or 85
	local clean = player:GetAttribute("Cleanliness") or 85
	local happy = player:GetAttribute("Happiness") or 90
	local activeCount = player:GetAttribute("ActivePetCount") or 1
	local questTitle = player:GetAttribute("QuestTitle") or "급식소에서 밥 주기"
	local yardTier = player:GetAttribute("YardTier") or 0
	local evoTier = player:GetAttribute("EvolutionTier") or 0
	local rebates = player:GetAttribute("RebirthCount") or 0
	local isRiding = player:GetAttribute("IsRiding") == true
	local eqAcc = player:GetAttribute("EquippedAccessory") or "None"

	headerLabel.Text = string.format("🐾 [Lv.%d] %s (%d/3) ★%d", level, customName, activeCount, rebates)
	questLabel.Text = "🎯 " .. questTitle
	rideBtn.Text = isRiding and "🏇 내리기(R)" or "🏇 타기(R)"
	rideBtn.BackgroundColor3 = isRiding and Color3.fromRGB(240, 95, 95) or Color3.fromRGB(65, 195, 225)

	local ls = player:FindFirstChild("leaderstats")
	local coinsVal = ls and ls:FindFirstChild("Coins")
	if coinsVal then
		coinLabel.Text = string.format("💰 %d | 🏡%d ✨%d", coinsVal.Value, yardTier, evoTier)
	end

	expFill.Size = UDim2.new(math.clamp(exp / maxExp, 0, 1), 0, 1, 0)
	expLbl.Text = string.format("⭐ EXP (%d/%d)", exp, maxExp)
	hungerFill.Size = UDim2.new(math.clamp(hunger / 100, 0, 1), 0, 1, 0)
	hungerLbl.Text = string.format("🍖 배고픔 (%d%%)", hunger)
	cleanFill.Size = UDim2.new(math.clamp(clean / 100, 0, 1), 0, 1, 0)
	cleanLbl.Text = string.format("🛁 청결도 (%d%%)", clean)
	happyFill.Size = UDim2.new(math.clamp(happy / 100, 0, 1), 0, 1, 0)
	happyLbl.Text = string.format("💕 행복도 (%d%%)", happy)

	local ownedRaw = player:GetAttribute("OwnedBreeds") or '["Puppy"]'
	local ok, ownedList = pcall(function() return HttpService:JSONDecode(ownedRaw) end)
	local ownedMap = {}
	if ok and type(ownedList) == "table" then
		for _, id in ipairs(ownedList) do ownedMap[id] = true end
	end

	for id, info in pairs(breedButtons) do
		info.btn:SetAttribute("IsOwned", ownedMap[id] == true)
		if id == breedId then
			info.btn.Text = "대장 동행 ✓"
			info.btn.BackgroundColor3 = Color3.fromRGB(70, 160, 245)
		elseif ownedMap[id] then
			info.btn.Text = "대장 선택"
			info.btn.BackgroundColor3 = Color3.fromRGB(95, 195, 120)
		elseif info.price >= 999 then
			info.btn.Text = "🥚 알뽑기(100)"
			info.btn.BackgroundColor3 = Color3.fromRGB(235, 180, 50)
		else
			info.btn.Text = info.price .. " 코인"
			info.btn.BackgroundColor3 = Color3.fromRGB(235, 145, 60)
		end
	end

	local accRaw = player:GetAttribute("OwnedAccessories") or '["None"]'
	local ok2, accListDecoded = pcall(function() return HttpService:JSONDecode(accRaw) end)
	local accMap = { None = true }
	if ok2 and type(accListDecoded) == "table" then
		for _, id in ipairs(accListDecoded) do accMap[id] = true end
	end

	for id, info in pairs(accButtons) do
		if id == eqAcc then
			info.btn.Text = "장착 중 ✓"
			info.btn.BackgroundColor3 = Color3.fromRGB(70, 160, 245)
		elseif accMap[id] then
			info.btn.Text = "장착하기"
			info.btn.BackgroundColor3 = Color3.fromRGB(95, 195, 120)
		else
			info.btn.Text = info.price .. " 코인"
			info.btn.BackgroundColor3 = Color3.fromRGB(235, 150, 60)
		end
	end

	local evoCosts = { [1] = 150, [2] = 300, [3] = 500 }
	local evoNames = { [1] = "🔥플레임(150)", [2] = "⚡썬더골드(300)", [3] = "🌈레인보우(500)" }
	if evoTier >= 3 then
		evoBtn.Text = "🌈 최종 오라 각성 완료!"
	else
		evoBtn.Text = "✨ 진화: " .. evoNames[evoTier + 1]
	end
	rebBtn.Text = string.format("👑 명예 승급 ★%d (Lv.5+)", rebates)

	local costs = { [1] = 100, [2] = 200, [3] = 350 }
	local names = { [1] = "1단계: 울타리 정원", [2] = "2단계: 럭셔리 분수대", [3] = "3단계: 황금 조각상" }
	if yardTier >= 3 then
		yardUpgradeBtn.Text = "🏡 마당 3단계 완료! (+60% 보너스)"
		yardUpgradeBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 240)
	else
		local nxt = yardTier + 1
		yardUpgradeBtn.Text = string.format("🏡 마당 업그레이드 [%s] (%d 코인)", names[nxt], costs[nxt])
	end
end

player.AttributeChanged:Connect(refreshUI)
task.spawn(function()
	local ls = player:WaitForChild("leaderstats", 10)
	if ls then
		local c = ls:WaitForChild("Coins", 10)
		if c then c.Changed:Connect(refreshUI) end
	end
	refreshUI()
end)

-- Golden Navigation Beam to Current Quest Station
local guideFolder = workspace:FindFirstChild("ClientQuestGuide") or Instance.new("Folder")
guideFolder.Name = "ClientQuestGuide"
guideFolder.Parent = workspace
guideFolder:ClearAllChildren()

local targetAnchor = Instance.new("Part")
targetAnchor.Name = "QuestTargetAnchor"
targetAnchor.Size = Vector3.new(1, 1, 1)
targetAnchor.Anchored = true
targetAnchor.CanCollide = false
targetAnchor.Transparency = 1
targetAnchor.Parent = guideFolder

local att1 = Instance.new("Attachment")
att1.Parent = targetAnchor

local charAtt = nil
local guideBeam = Instance.new("Beam")
guideBeam.Name = "QuestGuideBeam"
guideBeam.Color = ColorSequence.new(Color3.fromRGB(255, 225, 70), Color3.fromRGB(100, 240, 255))
guideBeam.Width0 = 0.8
guideBeam.Width1 = 0.8
guideBeam.FaceCamera = true
guideBeam.Transparency = NumberSequence.new(0.35)
guideBeam.Attachment1 = att1
guideBeam.Enabled = false
guideBeam.Parent = guideFolder

RunService.RenderStepped:Connect(function()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		guideBeam.Enabled = false
		return
	end
	if not charAtt or charAtt.Parent ~= hrp then
		charAtt = hrp:FindFirstChild("QuestCharAtt") or Instance.new("Attachment")
		charAtt.Name = "QuestCharAtt"
		charAtt.Position = Vector3.new(0, -2, 0)
		charAtt.Parent = hrp
		guideBeam.Attachment0 = charAtt
	end

	local qId = player:GetAttribute("QuestId")
	local world = workspace:FindFirstChild("DogParkWorld")
	local stations = world and world:FindFirstChild("Stations")
	local stPart = stations and qId and stations:FindFirstChild(qId)
	if stPart and stPart:IsA("BasePart") then
		targetAnchor.Position = stPart.Position + Vector3.new(0, 1.2, 0)
		guideBeam.Enabled = true
	else
		guideBeam.Enabled = false
	end
end)


-- Riding Saddle Pose & Smooth Gallop Bounce
local gallopClock = 0
RunService.Stepped:Connect(function(_, dt)
	local isRiding = player:GetAttribute("IsRiding") == true
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	if isRiding then
		-- Put character legs into a riding saddle pose (works for both R15 and R6!)
		local rHip = char:FindFirstChild("RightUpperLeg") and char.RightUpperLeg:FindFirstChild("RightHip")
		local lHip = char:FindFirstChild("LeftUpperLeg") and char.LeftUpperLeg:FindFirstChild("LeftHip")
		local rKnee = char:FindFirstChild("RightLowerLeg") and char.RightLowerLeg:FindFirstChild("RightKnee")
		local lKnee = char:FindFirstChild("LeftLowerLeg") and char.LeftLowerLeg:FindFirstChild("LeftKnee")

		if rHip and lHip then
			-- R15 Saddle Pose
			rHip.Transform = CFrame.Angles(math.rad(65), math.rad(-22), math.rad(18))
			lHip.Transform = CFrame.Angles(math.rad(65), math.rad(22), math.rad(-18))
			if rKnee then rKnee.Transform = CFrame.Angles(math.rad(-45), 0, 0) end
			if lKnee then lKnee.Transform = CFrame.Angles(math.rad(-45), 0, 0) end
		else
			-- R6 Saddle Pose
			local torso = char:FindFirstChild("Torso")
			local r6RHip = torso and torso:FindFirstChild("Right Hip")
			local r6LHip = torso and torso:FindFirstChild("Left Hip")
			if r6RHip and r6LHip then
				r6RHip.Transform = CFrame.Angles(0, 0, math.rad(75))
				r6LHip.Transform = CFrame.Angles(0, 0, math.rad(-75))
			end
		end

		-- Animate Gallop Bounce on RideWeld
		local activePets = workspace:FindFirstChild("ActivePets")
		local myDog = activePets and activePets:FindFirstChild(player.Name .. "_Dog_1")
		local root = myDog and myDog.PrimaryPart
		local rw = root and root:FindFirstChild("RideWeld")
		if rw then
			local baseY = rw:GetAttribute("BaseY") or -2.0
			local moving = hum.MoveDirection.Magnitude > 0.05
			if moving then
				gallopClock += dt * 16
				local bounceY = math.abs(math.sin(gallopClock)) * 0.45
				local pitch = math.cos(gallopClock) * math.rad(9)
				rw.C0 = CFrame.new(0, baseY + bounceY, 0) * CFrame.Angles(pitch, 0, 0)
			else
				rw.C0 = CFrame.new(0, baseY, 0)
			end
		end
	end
end)

