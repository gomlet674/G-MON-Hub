-- GMON Hub Main Script
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GMON_MainUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

-- Toggle Button
local Toggle = Instance.new("ImageButton")
Toggle.Size = UDim2.new(0, 40, 0, 40)
Toggle.Position = UDim2.new(0, 10, 0.5, -100)
Toggle.BackgroundTransparency = 1
Toggle.Image = "rbxassetid://94747801090737"
Toggle.Name = "GMON_Toggle"
Toggle.Parent = ScreenGui

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
local BG = Instance.new("ImageLabel")
BG.Name = "Background"
BG.Size = UDim2.new(0, 480, 0, 320)
BG.Position = UDim2.new(0.5, -240, 0.5, -160)
BG.BackgroundTransparency = 1
BG.Image = "rbxassetid://88817335071002"
BG.Visible = true
BG.Parent = ScreenGui

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
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "GMON Hub"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 24
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Parent = BG

-- Auto Farm Button
local AutoFarm = Instance.new("TextButton")
AutoFarm.Size = UDim2.new(0, 200, 0, 40)
AutoFarm.Position = UDim2.new(0, 20, 0, 60)
AutoFarm.Text = "Auto Farm"
AutoFarm.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
AutoFarm.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoFarm.Parent = BG

-- Tombol Prehistoric Island
local Tab_Prehistoric = Instance.new("TextButton")
Tab_Prehistoric.Size = UDim2.new(0, 200, 0, 40)
Tab_Prehistoric.Position = UDim2.new(0, 20, 0, 110)
Tab_Prehistoric.Text = "Prehistoric Island"
Tab_Prehistoric.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
Tab_Prehistoric.TextColor3 = Color3.fromRGB(255, 255, 255)
Tab_Prehistoric.Parent = BG

local PrehistoricPanel = Instance.new("Frame")
PrehistoricPanel.Size = UDim2.new(0, 440, 0, 180)
PrehistoricPanel.Position = UDim2.new(0, 20, 0, 160)
PrehistoricPanel.BackgroundTransparency = 0.2
PrehistoricPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
PrehistoricPanel.Visible = false
PrehistoricPanel.Parent = BG

-- Tombol toggle visibility
Tab_Prehistoric.MouseButton1Click:Connect(function()
    PrehistoricPanel.Visible = not PrehistoricPanel.Visible
end)

-- Checkbox Style Function
local function createToggleButton(text, posY)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 200, 0, 30)
	button.Position = UDim2.new(0, 10, 0, posY)
	button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.Gotham
	button.TextSize = 14
	button.Text = text .. ": OFF"
	button.Parent = PrehistoricPanel

	local state = false
	button.MouseButton1Click:Connect(function()
		state = not state
		button.Text = text .. ": " .. (state and "ON" or "OFF")
	end)

	return function() return state end
end

-- Toggle Buttons
local isAutoDefense = createToggleButton("Auto Defense", 10)
local isAutoEgg = createToggleButton("Collect Egg", 45)
local isAutoBone = createToggleButton("Collect Bone", 80)
local isAutoTeleport = createToggleButton("Auto TP to Island", 115)

-- Tab Setting
local SettingFrame = Instance.new("Frame")
SettingFrame.Name = "SettingFrame"
SettingFrame.Size = UDim2.new(0, 200, 0, 220)
SettingFrame.Position = UDim2.new(0, 260, 0, 60)
SettingFrame.BackgroundTransparency = 0.3
SettingFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SettingFrame.Visible = false
SettingFrame.Parent = BG

-- Toggle visibility (optional, if using tab buttons)
local TabSetting = Instance.new("TextButton")
TabSetting.Size = UDim2.new(0, 200, 0, 40)
TabSetting.Position = UDim2.new(0, 20, 0, 110)
TabSetting.Text = "Setting"
TabSetting.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
TabSetting.TextColor3 = Color3.fromRGB(255, 255, 255)
TabSetting.Parent = BG
TabSetting.MouseButton1Click:Connect(function()
	SettingFrame.Visible = not SettingFrame.Visible
end)

-- Template toggle function
local function CreateToggle(name, yPos)
	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(1, -20, 0, 30)
	toggle.Position = UDim2.new(0, 10, 0, yPos)
	toggle.Text = name .. ": OFF"
	toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggle.Parent = SettingFrame

	local enabled = false
	toggle.MouseButton1Click:Connect(function()
		enabled = not enabled
		toggle.Text = name .. ": " .. (enabled and "ON" or "OFF")
		-- Tambahkan logic aktifkan skill di sini
			if enabled then
	VIM:SendKeyEvent(true, "X", false, game)
			end
			if enabled then
	VIM:SendKeyEvent(true, "Y", false, game)
			end
                        if enabled then
	VIM:SendKeyEvent(true, "Z", false, game)
			end
                        if enabled then
	VIM:SendKeyEvent(true, "V", false, game)
			end
	end)
	return toggle
end

-- Buat toggle untuk setiap skill dan fitur
local toggleX = CreateToggle("Skill X", 10)
local toggleY = CreateToggle("Skill Y", 45)
local toggleZ = CreateToggle("Skill Z", 80)
local toggleV = CreateToggle("Skill V", 115)
local toggleFastAttack = CreateToggle("Fast Attack", 150)
local toggleAutoClick = CreateToggle("Auto Click", 185)

-- Auto Farm Logic
local farming = false
AutoFarm.MouseButton1Click:Connect(function()
	farming = not farming
	AutoFarm.Text = farming and "Auto Farm: ON" or "Auto Farm: OFF"

	if farming then
		task.spawn(function()
			while farming and task.wait(1) do
				pcall(function()
					local char = player.Character
					local lvl = player:FindFirstChild("Data") and player.Data:FindFirstChild("Level") and player.Data.Level.Value or 1
					local questData = {
						[1] = {
							QuestName = "BanditQuest1",
							MobName = "Bandit",
							MobPos = CFrame.new(1039, 17, 1560)
						},
					}
					local data = questData[1]
					if data then
						if not player.PlayerGui:FindFirstChild("QuestTitle") then
							ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", data.QuestName, 1)
							task.wait(1)
						end
						for _, mob in pairs(workspace.Enemies:GetChildren()) do
							if mob.Name == data.MobName and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
								repeat task.wait()
									char.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
									VIM:SendKeyEvent(true, "Z", false, game)
								until mob.Humanoid.Health <= 0 or not farming
							end, 
						end) 
                                                        
-- Logic utama
task.spawn(function()
	while task.wait(3) do
		local island = workspace:FindFirstChild("PrehistoricIsland")

		-- Auto Teleport
		if isAutoTeleport() and island then
			game.StarterGui:SetCore("SendNotification", {
				Title = "GMON Hub",
				Text = "Prehistoric Island Ditemukan!",
				Duration = 5
			})
			player.Character.HumanoidRootPart.CFrame = island.CFrame + Vector3.new(0, 10, 0)
		end

		-- Auto Defense
		if isAutoDefense() and island then
			for _, golem in pairs(workspace.Enemies:GetChildren()) do
				if golem.Name == "Lava Golem" and golem:FindFirstChild("Humanoid") and golem.Humanoid.Health > 0 then
					player.Character.HumanoidRootPart.CFrame = golem.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
					VIM:SendKeyEvent(true, "Z", false, game)
				end
			end
		end

		-- Auto Collect Egg/Bone
		for _, item in pairs(workspace:GetChildren()) do
			if (item.Name == "DragonEgg" and isAutoEgg()) or (item.Name == "DinosaurBone" and isAutoBone()) then
				player.Character.HumanoidRootPart.CFrame = item.CFrame + Vector3.new(0, 2, 0)
				task.wait(0.5)
			end
		end
	end
end)										
