-- GMON Hub Main Script
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")

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

-- Tab Auto Farm Button
_G.AutoFarm = false

local AutoFarm = Instance.new("TextButton", BG)
AutoFarm.Size = UDim2.new(0, 200, 0, 40)
AutoFarm.Position = UDim2.new(0, 20, 0, 60)
AutoFarm.BackgroundTransparency = 0.5 -- 0.0 (tidak transparan) s/d 1.0 (benar-benar transparan)
AutoFarm.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
AutoFarm.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoFarm.Font = Enum.Font.SourceSansBold
AutoFarm.TextSize = 20
AutoFarm.Text = "Auto Farm: OFF"

AutoFarm.MouseButton1Click:Connect(function()
	_G.AutoFarm = not _G.AutoFarm
	AutoFarm.Text = _G.AutoFarm and "Auto Farm: ON" or "Auto Farm: OFF"
end)

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
createToggleButton("Auto Click", 50, function(enabled)
	_G.AutoClick = enabled
end)

-- Toggle Skill X/C/Z/V/F
createToggleButton("Use Skill X", 90, function(enabled)
	_G.UseSkillX = enabled
end)
createToggleButton("Use Skill C", 130, function(enabled)
	_G.UseSkillC = enabled
end)
createToggleButton("Use Skill Z", 170, function(enabled)
	_G.UseSkillZ = enabled
end)
createToggleButton("Use Skill V", 190, function(enabled)
	_G.UseSkillV = enabled
end)
createToggleButton("Use Skill F", 210, function(enabled)
	_G.UseSkillF = enabled
end)

local isMeleeEnabled = false

-- Buat tombol toggle
local meleeButton = Instance.new("TextButton")
meleeButton.Size = UDim2.new(0, 200, 0, 40)
meleeButton.Position = UDim2.new(0, 20, 0, 120)
meleeButton.Text = "Use Melee: OFF"
meleeButton.Parent = yourGuiFrame -- ganti dengan frame kamu
meleeButton.BackgroundColor3 = Color3.fromRGB(170, 85, 255)

-- Fungsi equip melee
local function equipMelee()
    local player = game.Players.LocalPlayer
    local Backpack = player:WaitForChild("Backpack")
    local Character = player.Character or player.CharacterAdded:Wait()

    for _, tool in pairs(Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == "Melee" then
            tool.Parent = Character
            break
        end
    end
end

-- Tombol Auto Farm (asumsi kamu sudah punya ini)
local autoFarmButton = Instance.new("TextButton")
autoFarmButton.Size = UDim2.new(0, 200, 0, 40)
autoFarmButton.Position = UDim2.new(0, 20, 0, 60)
autoFarmButton.Text = "Auto Farm: OFF"
autoFarmButton.Parent = yourGuiFrame
autoFarmButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)

-- Tombol Use Melee
local isMeleeEnabled = false
local meleeButton = Instance.new("TextButton")
meleeButton.Size = UDim2.new(0, 200, 0, 40)
meleeButton.Position = UDim2.new(0, 20, 0, 110) -- tepat di bawah Auto Farm
meleeButton.Text = "Use Melee: OFF"
meleeButton.Parent = yourGuiFrame
meleeButton.BackgroundColor3 = Color3.fromRGB(170, 85, 255)

-- Fungsi equip Melee
local function equipMelee()
    local player = game.Players.LocalPlayer
    local Backpack = player:WaitForChild("Backpack")
    local Character = player.Character or player.CharacterAdded:Wait()

    for _, tool in pairs(Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == "Melee" then
            tool.Parent = Character
            break
        end
    end
end

-- Toggle Melee
meleeButton.MouseButton1Click:Connect(function()
    isMeleeEnabled = not isMeleeEnabled
    meleeButton.Text = isMeleeEnabled and "Use Melee: ON" or "Use Melee: OFF"
    if isMeleeEnabled then
        equipMelee()
    end
end)

-- Auto Farm Logic
local farming = false
AutoFarm.MouseButton1Click:Connect(function()
	farming = not farming
	AutoFarm.Text = farming and "Auto Farm: ON" or "Auto Farm: OFF"

	if farming then
		spawn(function()
			while farming and wait(1) do
				pcall(function()
					local char = player.Character
					local lvl = player.Data.Level.Value
					local questData = {
    [5] = {
        QuestName = "BanditQuest1",
        MobName = "Bandit",
        MobPos = CFrame.new(1039, 17, 1560)
    },
    [10] = {
        QuestName = "MonkeyQuest",
        MobName = "Monkey",
        MobPos = CFrame.new(-1601, 8, 145)
    },
    [15] = {
        QuestName = "GorillaQuest",
        MobName = "Gorilla",
        MobPos = CFrame.new(-1322, 6, -511)
    },
    [30] = {
        QuestName = "BuggyQuest1",
        MobName = "Pirate",
        MobPos = CFrame.new(-1122, 5, 3850)
    },
    [40] = {
        QuestName = "BuggyQuest2",
        MobName = "Brute",
        MobPos = CFrame.new(-1144, 14, 4320)
    },
    [60] = {
        QuestName = "BuggyQuest3",
        MobName = "Bobby",
        MobPos = CFrame.new(-1155, 18, 4305)
    },
    [75] = {
        QuestName = "DesertQuest",
        MobName = "Desert Bandit",
        MobPos = CFrame.new(932, 6, 4480)
    },
    [90] = {
        QuestName = "DesertQuest2",
        MobName = "Desert Officer",
        MobPos = CFrame.new(1593, 6, 4363)
    },
    [120] = {
        QuestName = "SnowQuest",
        MobName = "Snow Bandit",
        MobPos = CFrame.new(1358, 87, -1290)
    },
    [150] = {
        QuestName = "MarineQuest3",
        MobName = "Vice Admiral",
        MobPos = CFrame.new(-5105, 88, 3961)
    },
    [190] = {
        QuestName = "SkyQuest1",
        MobName = "Sky Bandit",
        MobPos = CFrame.new(-4960, 278, -2626)
    },
    [250] = {
        QuestName = "SkyQuest3",
        MobName = "Dark Master",
        MobPos = CFrame.new(-5254, 389, -2359)
    },
    [375] = {
        QuestName = "MagmaQuest",
        MobName = "Military Soldier",
        MobPos = CFrame.new(-5422, 11, 8467)
    },
    [625] = {
        QuestName = "FishmanQuest",
        MobName = "Fishman Warrior",
        MobPos = CFrame.new(61123, 19, 1500)
    },
    [950] = {
        QuestName = "ZombieQuest",
        MobName = "Zombie",
        MobPos = CFrame.new(-5566, 102, -7155)
    },
    [1250] = {
        QuestName = "FactoryStaffQuest",
        MobName = "Factory Staff",
        MobPos = CFrame.new(2950, 84, -6990)
    },
    [1500] = {
        QuestName = "PiratePortQuest",
        MobName = "Pirate",
        MobPos = CFrame.new(-4682, 845, 8723)
    },
    [1750] = {
        QuestName = "HauntedQuest1",
        MobName = "Reborn Skeleton",
        MobPos = CFrame.new(-9492, 142, 6064)
    },
    [2000] = {
        QuestName = "IceCreamQuest1",
        MobName = "Snow Demon",
        MobPos = CFrame.new(-899, 65, -11063)
    },
    [2250] = {
        QuestName = "PeanutQuest1",
        MobName = "Peanut Scout",
        MobPos = CFrame.new(-2060, 90, -10368)
    },
    [2450] = {
        QuestName = "MansionQuest",
        MobName = "Island Empress",
        MobPos = CFrame.new(-11865, 334, -8761)
    },
    [2650] = {
        QuestName = "TikiQuest1",
        MobName = "Tiki Warrior",
        MobPos = CFrame.new(-14493, 334, -7262)
    },
								}
					local data
                                              for levelReq, quest in pairs(questData) do
                                                  if lvl >= levelReq then
                                                    data = quest
                                               end
					end
					if data then
						if not player.PlayerGui:FindFirstChild("QuestTitle") then
							ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", data.QuestName, 1)
							wait(1)
						end
						for _, mob in pairs(workspace.Enemies:GetChildren()) do
							if mob.Name == data.MobName and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
								repeat wait()
									char.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)

									if _G.UseSkillZ then
										VIM:SendKeyEvent(true, "Z", false, game)
									end
									if _G.UseSkillX then
										VIM:SendKeyEvent(true, "X", false, game)
									end
									if _G.UseSkillC then
										VIM:SendKeyEvent(true, "C", false, game)
									end
									if _G.UseSkillV then
										VIM:SendKeyEvent(true, "V", false, game)
									end
									if _G.UseSkillF then
										VIM:SendKeyEvent(true, "F", false, game)
									end			
                                                                        
								until mob.Humanoid.Health <= 0 or not farming
							end
						end
					end
				end)
			end
		end)
	end
end)
