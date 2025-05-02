local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local HRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart") or player.CharacterAdded:Wait():WaitForChild("HumanoidRootPart")

-- UI
local ScreenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
ScreenGui.Name = "GMON_MainUI"
ScreenGui.ResetOnSpawn = false

-- Toggle
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

-- Border RGB
local RGBFrame = Instance.new("Frame", BG)
RGBFrame.Size = UDim2.new(1, 0, 1, 0)
RGBFrame.BackgroundTransparency = 1
local border = Instance.new("UIStroke", RGBFrame)
border.Thickness = 4
border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

spawn(function()
	local hue = 0
	while wait(0.03) do
		hue = (hue + 1) % 360
		border.Color = Color3.fromHSV(hue / 360, 1, 1)
	end
end)

-- Title
local Title = Instance.new("TextLabel", BG)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "GMON Hub"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 24
Title.TextColor3 = Color3.new(1, 1, 1)

-- Auto Farm Button
local AutoFarmBtn = Instance.new("TextButton", BG)
AutoFarmBtn.Size = UDim2.new(0, 200, 0, 40)
AutoFarmBtn.Position = UDim2.new(0, 20, 0, 60)
AutoFarmBtn.Text = "Auto Farm"
AutoFarmBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
AutoFarmBtn.TextColor3 = Color3.new(1, 1, 1)

-- Farm Data
local FarmData = {
	{Level = 5, Max = 14, Quest = "BanditQuest1", Mob = "Bandit", Pos = CFrame.new(1039, 17, 1560)},
	{Level = 15, Max = 29, Quest = "MonkeyQuest", Mob = "Monkey", Pos = CFrame.new(-1602, 39, 152)},
	{Level = 30, Max = 59, Quest = "GorillaQuest", Mob = "Gorilla", Pos = CFrame.new(-1220, 60, -545)},
	-- Tambahkan lebih banyak data level hingga 2650
}

local function getCurrentFarmData(level)
	for _, data in ipairs(FarmData) do
		if level >= data.Level and level <= data.Max then
			return data
		end
	end
	return nil
end

local farming = false

AutoFarmBtn.MouseButton1Click:Connect(function()
	farming = not farming
	AutoFarmBtn.Text = farming and "Farming..." or "Auto Farm"
	if farming then
		spawn(function()
			while farming do
				pcall(function()
					local level = player.Data.Level.Value
					local data = getCurrentFarmData(level)
					if not data then return end

					if not player.PlayerGui:FindFirstChild("QuestTitle") then
						ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", data.Quest, 1)
						wait(1)
					end

					for _, mob in pairs(Workspace.Enemies:GetChildren()) do
						if mob.Name == data.Mob and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
							repeat
								HRP.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 15, 12)
								VIM:SendKeyEvent(true, "Z", false, game)
								wait()
							until mob.Humanoid.Health <= 0 or not farming
						end
					end
				end)
				wait(1)
			end
		end)
	end
end)
