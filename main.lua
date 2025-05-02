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
local AutoFarm = Instance.new("TextButton", BG)
AutoFarm.Size = UDim2.new(0, 200, 0, 40)
AutoFarm.Position = UDim2.new(0, 20, 0, 60)
AutoFarm.Text = "Auto Farm"
AutoFarm.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
AutoFarm.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Setting Tab UI
local SettingFrame = Instance.new("Frame")
SettingFrame.Size = UDim2.new(0, 200, 0, 200)
SettingFrame.Position = UDim2.new(1, -210, 0, 60)
SettingFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
SettingFrame.Visible = true
SettingFrame.Parent = BG

local function createToggleButton(name, posY, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -10, 0, 30)
	btn.Position = UDim2.new(0, 5, 0, posY)
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = name .. ": OFF"
	btn.Parent = SettingFrame

	local enabled = false
	btn.MouseButton1Click:Connect(function()
		enabled = not enabled
		btn.Text = name .. (enabled and ": ON" or ": OFF")
		callback(enabled)
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

-- Toggle Skill X/Y/Z/V
createToggleButton("Use Skill X", 90, function(enabled)
	_G.UseSkillX = enabled
end)
createToggleButton("Use Skill Y", 130, function(enabled)
	_G.UseSkillY = enabled
end)
createToggleButton("Use Skill Z", 170, function(enabled)
	_G.UseSkillZ = enabled
end)
createToggleButton("Use Skill V", 210, function(enabled)
	_G.UseSkillV = enabled
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
							wait(1)
						end
						for _, mob in pairs(workspace.Enemies:GetChildren()) do
							if mob.Name == data.MobName and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
								repeat wait()
									char.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
									VIM:SendKeyEvent(true, "Z", false, game)
									char.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
									VIM:SendKeyEvent(true, "Y", false, game)
                                                                        char.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
									VIM:SendKeyEvent(true, "X", false, game)

								until mob.Humanoid.Health <= 0 or not farming
							end
						end
					end
				end)
			end
		end)
	end
end)
