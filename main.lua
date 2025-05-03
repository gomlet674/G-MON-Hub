-- GMON Hub Main Script
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- UI Setup
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "GMON_MainUI"
ScreenGui.ResetOnSpawn = false

-- Toggle Button
local Toggle = Instance.new("ImageButton", ScreenGui)
Toggle.Size = UDim2.new(0, 40, 0, 40)
Toggle.Position = UDim2.new(0, 10, 0.5, -100)
Toggle.BackgroundTransparency = 1
Toggle.Image = "rbxassetid://94747801090737"
Toggle.Name = "GMON_Toggle"

-- Drag toggle
local dragging, dragInput, dragStart, startPos
Toggle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = Toggle.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)
Toggle.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)
RunService.Heartbeat:Connect(function()
	if dragging and dragInput then
		local delta = dragInput.Position - dragStart
		Toggle.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Background Panel
local BG = Instance.new("ImageLabel", ScreenGui)
BG.Name = "Background"
BG.Size = UDim2.new(0, 480, 0, 320)
BG.Position = UDim2.new(0.5, -240, 0.5, -160)
BG.BackgroundTransparency = 1
BG.Image = "rbxassetid://88817335071002"
BG.Visible = true

Toggle.MouseButton1Click:Connect(function()
	BG.Visible = not BG.Visible
end)

-- Tambahkan ke atas sebelum Title GMON Hub
local RGBFrame = Instance.new("Frame", BG)
RGBFrame.Size = UDim2.new(1, 0, 1, 0)
RGBFrame.Position = UDim2.new(0, 0, 0, 0)
RGBFrame.BackgroundTransparency = 1
RGBFrame.BorderSizePixel = 4
RGBFrame.ZIndex = 2

-- Ubah properti untuk efek RGB
local border = Instance.new("UIStroke", RGBFrame)
border.Thickness = 4
border.Transparency = 0
border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
border.LineJoinMode = Enum.LineJoinMode.Round
border.Color = Color3.fromRGB(255, 0, 0)

-- Efek Rainbow RGB
spawn(function()
	local hue = 0
	while wait(0.03) do
		hue = hue + 1
		if hue >= 360 then hue = 0 end
		local color = Color3.fromHSV(hue / 360, 1, 1)
		pcall(function()
			border.Color = color
		end)
	end
end)

-- Label GMON Hub
local Title = Instance.new("TextLabel", BG)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "GMON Hub"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 24
Title.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Tombol Auto Farm
_G.AutoFarm = false
local AutoFarm = Instance.new("TextButton", BG)
AutoFarm.Size = UDim2.new(0, 200, 0, 40)
AutoFarm.Position = UDim2.new(0, 20, 0, 60)
AutoFarm.BackgroundTransparency = 0.4
AutoFarm.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
AutoFarm.TextColor3 = Color3.fromRGB(0, 0, 0)
AutoFarm.Font = Enum.Font.SourceSansBold
AutoFarm.TextSize = 20
AutoFarm.Text = "Auto Farm: OFF"

AutoFarm.MouseButton1Click:Connect(function()
	_G.AutoFarm = not _G.AutoFarm
	AutoFarm.Text = _G.AutoFarm and "Auto Farm: ON" or "Auto Farm: OFF"
end)

--===[ GMON Sea Events Tab Mentahan Berdasarkan Gambar ]===--

local seaEventsTab = Instance.new("Frame")
seaEventsTab.Name = "SeaEventsTab"
seaEventsTab.Size = UDim2.new(1, 0, 1, 0)
seaEventsTab.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
seaEventsTab.BackgroundTransparency = 0.4
seaEventsTab.BorderSizePixel = 0
seaEventsTab.Visible = true
seaEventsTab.Parent = SettingTab -- Ganti sesuai parent kamu

local title = Instance.new("TextLabel", seaEventsTab)
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "Sea Events"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1

local function createToggleRow(parent, yPos, labelText)
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1, -20, 0, 35)
	row.Position = UDim2.new(0, 10, 0, yPos)
	row.BackgroundTransparency = 1

	local label = Instance.new("TextLabel", row)
	label.Size = UDim2.new(1, -50, 1, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.Text = labelText
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left

	local toggle = Instance.new("TextButton", row)
	toggle.Size = UDim2.new(0, 40, 0, 22)
	toggle.Position = UDim2.new(1, -45, 0.5, -11)
	toggle.BackgroundColor3 = Color3.fromRGB(70, 170, 255)
	toggle.Text = ""
	toggle.BorderSizePixel = 0
	toggle.AutoButtonColor = false

	local enabled = false
	local function updateColor()
		toggle.BackgroundColor3 = enabled and Color3.fromRGB(70, 170, 255) or Color3.fromRGB(100, 100, 100)
	end
	toggle.MouseButton1Click:Connect(function()
		enabled = not enabled
		updateColor()
		print(labelText .. ": " .. (enabled and "ON" or "OFF"))
	end)
	updateColor()
end

local y = 50
createToggleRow(seaEventsTab, y, "View Sea Events") y += 40
createToggleRow(seaEventsTab, y, "Auto Sea Beast") y += 40
createToggleRow(seaEventsTab, y, "Auto Sink Ship") y += 40
createToggleRow(seaEventsTab, y, "Ignore Sea Beast") y += 40
createToggleRow(seaEventsTab, y, "Ignore Ship") y += 40
createToggleRow(seaEventsTab, y, "Custom Distance") y += 40
createToggleRow(seaEventsTab, y, "Auto Target")

-- Setting Tab UI
local SettingFrame = Instance.new("Frame")
SettingFrame.Size = UDim2.new(0, 200, 0, 200)
SettingFrame.Position = UDim2.new(1, -210, 0, 60)
SettingFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- putih
SettingFrame.BackgroundTransparency = 0.4 -- transparansi 60%
SettingFrame.Visible = true
SettingFrame.Parent = BG

local function createToggleButton(name, posY, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -10, 0, 30)
	btn.Position = UDim2.new(0, 5, 0, posY)
	btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	btn.BackgroundTransparency = 0.4
	btn.TextColor3 = Color3.fromRGB(0, 0, 0) -- teks jadi hitam agar kontras
	btn.Text = name .. ": OFF"
	btn.Parent = SettingFrame

	local state = false
	btn.MouseButton1Click:Connect(function()
		state = not state
		btn.Text = name .. ": " .. (state and "ON" or "OFF")
		if callback then callback(state) end
	end)
end

-- Toggle Fast Attack
createToggleButton("Fast Attack", 10, function(enabled)
	_G.FastAttack = enabled
end)

-- Toggle Auto Click
createToggleButton("Auto Click", 40, function(enabled)
	_G.AutoClick = enabled
end)

-- Toggle Skill X/C/Z/V/F
createToggleButton("Use Skill X", 80, function(enabled)
	_G.UseSkillX = enabled
end)
createToggleButton("Use Skill C", 120, function(enabled)
	_G.UseSkillC = enabled
end)
createToggleButton("Use Skill Z", 150, function(enabled)
	_G.UseSkillZ = enabled
end)
createToggleButton("Use Skill V", 180, function(enabled)
	_G.UseSkillV = enabled
end)
createToggleButton("Use Skill F", 220, function(enabled)
	_G.UseSkillF = enabled
end)

local isMeleeEnabled = false

--===[ Auto Farm Logic GMON ]===--
local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")

-- Skill default toggle
_G.UseSkillZ = true
_G.UseSkillX = true
_G.UseSkillC = false
_G.UseSkillV = false
_G.UseSkillF = false

-- GMON Hub AutoFarm Full QuestData (Level 5 - 2650) local player = game.Players.LocalPlayer local ReplicatedStorage = game:GetService("ReplicatedStorage") local VIM = game:GetService("VirtualInputManager")

local function tweenToPosition(part, targetPos, duration)
    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.InOut
    )
    local goal = { CFrame = targetPos }
    local tween = TweenService:Create(part, tweenInfo, goal)
    tween:Play()
    tween.Completed:Wait()
end

spawn(function() while true do wait(1) 
			if _G.AutoFarm then
				pcall(function() 
						local char = player.Character
						local lvl = player.Data.Level.Value

                                                local questData = {
				-- First Sea (Level 5 - 700)
				[5] = {QuestName = "BanditQuest1", MobName = "Bandit", MobPos = CFrame.new(1039, 17, 1560)},
				[10] = {QuestName = "JungleQuest", MobName = "Monkey", MobPos = CFrame.new(-1611, 36, 152)},
				[15] = {QuestName = "JungleQuest", MobName = "Gorilla", MobPos = CFrame.new(-1237, 6, -530)},
				[30] = {QuestName = "BuggyQuest1", MobName = "Pirate", MobPos = CFrame.new(-1120, 14, 3850)},
				[40] = {QuestName = "BuggyQuest1", MobName = "Brute", MobPos = CFrame.new(-1193, 14, 4275)},
				[60] = {QuestName = "BuggyQuest2", MobName = "Desert Bandit", MobPos = CFrame.new(933, 7, 4482)},
				[75] = {QuestName = "DesertQuest", MobName = "Desert Officer", MobPos = CFrame.new(1572, 10, 4373)},
				[90] = {QuestName = "SnowQuest", MobName = "Snow Bandit", MobPos = CFrame.new(1389, 87, -1297)},
				[105] = {QuestName = "SnowQuest", MobName = "Snowman", MobPos = CFrame.new(1355, 87, -1410)},
				[120] = {QuestName = "MarineQuest1", MobName = "Chief Petty Officer", MobPos = CFrame.new(-4855, 20, 4326)},
				[150] = {QuestName = "SkyQuest", MobName = "Sky Bandit", MobPos = CFrame.new(-4951, 295, -2723)},
				[175] = {QuestName = "SkyQuest", MobName = "Dark Master", MobPos = CFrame.new(-5250, 389, -2293)},
				[190] = {QuestName = "PrisonerQuest", MobName = "Prisoner", MobPos = CFrame.new(4943, 42, -3123)},
				[210] = {QuestName = "PrisonerQuest", MobName = "Dangerous Prisoner", MobPos = CFrame.new(5011, 42, -3025)},
				[250] = {QuestName = "ColosseumQuest", MobName = "Toga Warrior", MobPos = CFrame.new(-1772, 7, -2742)},
				[275] = {QuestName = "ColosseumQuest", MobName = "Gladiator", MobPos = CFrame.new(-1501, 7, -2832)},
				[300] = {QuestName = "MagmaQuest", MobName = "Military Soldier", MobPos = CFrame.new(-5428, 78, -2890)},
				[325] = {QuestName = "MagmaQuest", MobName = "Military Spy", MobPos = CFrame.new(-5802, 78, -2914)},
				[375] = {QuestName = "FishmanQuest", MobName = "Fishman Warrior", MobPos = CFrame.new(61163, 19, 1569)},
				[400] = {QuestName = "FishmanQuest", MobName = "Fishman Commando", MobPos = CFrame.new(61753, 19, 1442)},
				[450] = {QuestName = "SkyExpQuest", MobName = "God's Guard", MobPos = CFrame.new(-4700, 900, -1912)},
				[475] = {QuestName = "SkyExpQuest", MobName = "Shanda", MobPos = CFrame.new(-4560, 875, -2025)},
				[500] = {QuestName = "SkyExpQuest", MobName = "Royal Squad", MobPos = CFrame.new(-4372, 755, -2126)},
				[525] = {QuestName = "SkyExpQuest", MobName = "Royal Soldier", MobPos = CFrame.new(-4472, 785, -2176)},
				[550] = {QuestName = "FountainQuest", MobName = "Galley Pirate", MobPos = CFrame.new(5550, 77, 3933)},
				[625] = {QuestName = "FountainQuest", MobName = "Galley Captain", MobPos = CFrame.new(5700, 77, 4200)},

				-- Second Sea (Level 700 - 1450)
				[700] = {QuestName = "Area1Quest", MobName = "Raider", MobPos = CFrame.new(-4984, 314, -2831)},
				[725] = {QuestName = "Area1Quest", MobName = "Mercenary", MobPos = CFrame.new(-4900, 314, -2820)},
				[775] = {QuestName = "Area2Quest", MobName = "Swan Pirate", MobPos = CFrame.new(878, 122, 1235)},
				[800] = {QuestName = "Area2Quest", MobName = "Factory Staff", MobPos = CFrame.new(295, 73, 1360)},
				[875] = {QuestName = "ZombieQuest", MobName = "Zombie", MobPos = CFrame.new(-5736, 94, -6937)},
				[900] = {QuestName = "ZombieQuest", MobName = "Vampire", MobPos = CFrame.new(-5775, 94, -7038)},
				[950] = {QuestName = "SnowMountainQuest", MobName = "Snow Trooper", MobPos = CFrame.new(5804, 50, -5386)},
				[975] = {QuestName = "SnowMountainQuest", MobName = "Winter Warrior", MobPos = CFrame.new(6020, 50, -5500)},
				[1000] = {QuestName = "ShipQuest1", MobName = "Ship Deckhand", MobPos = CFrame.new(1217, 125, 33020)},
				[1050] = {QuestName = "ShipQuest1", MobName = "Ship Engineer", MobPos = CFrame.new(1257, 125, 33260)},
				[1100] = {QuestName = "ShipQuest2", MobName = "Ship Steward", MobPos = CFrame.new(1449, 125, 33460)},
				[1125] = {QuestName = "ShipQuest2", MobName = "Ship Officer", MobPos = CFrame.new(1520, 125, 33790)},
				[1150] = {QuestName = "FogQuest", MobName = "Arctic Warrior", MobPos = CFrame.new(-6500, 70, -9200)},
				[1175] = {QuestName = "FogQuest", MobName = "Snow Lurker", MobPos = CFrame.new(-6700, 70, -9400)},
				[1200] = {QuestName = "GhostShipQuest", MobName = "Shipwright", MobPos = CFrame.new(-5900, 150, -7500)},
				[1250] = {QuestName = "GhostShipQuest", MobName = "Arctic Ensign", MobPos = CFrame.new(-6000, 150, -7600)},
				[1300] = {QuestName = "CursedShipQuest", MobName = "Living Zombie", MobPos = CFrame.new(-6125, 90, -7920)},
				[1325] = {QuestName = "CursedShipQuest", MobName = "Demonic Soul", MobPos = CFrame.new(-6200, 90, -8025)},
				[1350] = {QuestName = "IceQuest", MobName = "Arctic Admiral", MobPos = CFrame.new(-6400, 100, -8600)},
				[1400] = {QuestName = "IslandQuest", MobName = "Jungle Pirate", MobPos = CFrame.new(-6800, 100, -8800)},
				[1450] = {QuestName = "IslandQuest", MobName = "Musketeer Pirate", MobPos = CFrame.new(-6900, 100, -8900)},

				-- Third Sea up to 2650 (sudah tersedia di versi sebelumnya)
				[1500] = {QuestName = "PiratePortQuest", MobName = "Pirate Millionaire", MobPos = CFrame.new(-289, 44, 5589)},
				[1575] = {QuestName = "GreatTreeQuest", MobName = "Marine Commodore", MobPos = CFrame.new(2364, 25, -6864)},
				[1650] = {QuestName = "GreatTreeQuest", MobName = "Marine Rear Admiral", MobPos = CFrame.new(2354, 25, -6984)},
				[1700] = {QuestName = "HydraQuest", MobName = "Water Fighter", MobPos = CFrame.new(5229, 66, -11354)},
				[1750] = {QuestName = "HydraQuest", MobName = "Sea Soldier", MobPos = CFrame.new(5130, 66, -11454)},
				[2300] = {QuestName = "TikiQuest1", MobName = "Island Boy", MobPos = CFrame.new(-14540, 334, -7630)},
				[2400] = {QuestName = "TikiQuest2", MobName = "Shark Tooth", MobPos = CFrame.new(-14590, 334, -7900)},
				[2500] = {QuestName = "TikiQuest3", MobName = "Sun-kissed Warrior", MobPos = CFrame.new(-14620, 334, -8100)},
				[2625] = {QuestName = "GravityQuest", MobName = "Gravity Bandit", MobPos = CFrame.new(-14700, 334, -8400)},
				[2650] = {QuestName = "GravityQuest", MobName = "Gravity Warrior", MobPos = CFrame.new(-14750, 334, -8500)}
				}

				local maxLevelPerSea = {
    FirstSea = 700,
    SecondSea = 1500,
    ThirdSea = 2450
}

local questData = {
    FirstSea = {
        {Level = 625, QuestName = "GalleyCaptainQuest", MobName = "Galley Captain", MobPos = Vector3.new(5552, 72, 4932)},
    },
    SecondSea = {
        {Level = 1425, QuestName = "WaterFighterQuest", MobName = "Water Fighter", MobPos = Vector3.new(5689, 92, -7174)},
    },
    ThirdSea = {
        {Level = 2650, QuestName = "SerpentHunterQuest", MobName = "Serpent Hunter", MobPos = Vector3.new(-9500, 94, 6200)},
    }
}

local function getCurrentSea()
    local placeId = game.PlaceId
    if placeId == 2753915549 then
        return "FirstSea"
    elseif placeId == 4442272183 then
        return "SecondSea"
    elseif placeId == 7449423635 then
        return "ThirdSea"
    else
        return nil
    end
end

local function getTargetQuest(level)
    local sea = getCurrentSea()
    if not sea then return nil end

    local availableQuests = questData[sea]
    if not availableQuests then return nil end

    local target = nil
    for _, quest in ipairs(availableQuests) do
        if level >= quest.Level then
            target = quest
        end
    end
    return target
	end
    -- return { QuestName = "BanditQuest1", MobName = "Bandit", MobPos = Vector3.new(...) }
end

spawn(function()
    while wait(1) do
        if _G.AutoFarm then
            local level = player.Data.Level.Value
            local quest = getTargetQuest(level)
            if quest then
                -- Ambil quest jika belum
                if not player.PlayerGui:FindFirstChild("QuestTitle") then
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", quest.QuestName, 1)
                    wait(1)
                end

                -- Teleport ke mob
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local targetCFrame = quest.MobPos + Vector3.new(0, 10, 0)
                    tweenToPosition(char.HumanoidRootPart, targetCFrame, 40)
                end

                -- Serang mob
                for _, mob in pairs(workspace.Enemies:GetChildren()) do
                    if mob.Name == quest.MobName and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                        repeat wait()
                            if char and char:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("HumanoidRootPart") then
                                char.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                            end
                            if _G.UseSkillZ then VIM:SendKeyEvent(true, "Z", false, game) end
                            if _G.UseSkillX then VIM:SendKeyEvent(true, "X", false, game) end
                            if _G.UseSkillC then VIM:SendKeyEvent(true, "C", false, game) end
                            if _G.UseSkillV then VIM:SendKeyEvent(true, "V", false, game) end
                            if _G.UseSkillF then VIM:SendKeyEvent(true, "F", false, game) end
                        until mob.Humanoid.Health <= 0 or not _G.AutoFarm
                    end
                end
            end
        end
    end
end)
