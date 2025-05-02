-- GMON Hub Main Script local CoreGui = game:GetService("CoreGui") local Players = game:GetService("Players") local RunService = game:GetService("RunService") local ReplicatedStorage = game:GetService("ReplicatedStorage") local VIM = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

-- UI Setup 
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GMON_MainUI" 
ScreenGui.ResetOnSpawn = false 
ScreenGui.Parent = CoreGui

-- Toggle Button 
local Toggle = Instance.new("ImageButton")
Toggle.Size = UDim2.new(0, 40, 0, 40) T
oggle.Position = UDim2.new(0, 10, 0.5, -100) 
Toggle.BackgroundTransparency = 1
Toggle.Image = "rbxassetid://94747801090737" 
Toggle.Name = "GMON_Toggle"
Toggle.Parent = ScreenGui

-- Drag toggle 
local dragging, dragInput, dragStart, startPos Toggle.InputBegan:Connect(function(input) if 
			input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true dragStart = input.Position startPos = Toggle.Position

input.Changed:Connect(function()
		if input.UserInputState == Enum.UserInputState.End then
			dragging = false
		end
	end)
end

end) Toggle.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end) RunService.Heartbeat:Connect(function() if dragging and dragInput then local delta = dragInput.Position - dragStart Toggle.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)

-- Background Panel 
local BG = Instance.new("ImageLabel") 
BG.Name = "Background" 
BG.Size = UDim2.new(0, 600, 0, 400) 
BG.Position = UDim2.new(0.5, -300, 0.5, -200) 
BG.BackgroundColor3 = Color3.fromRGB(15, 15, 15) 
BG.ImageTransparency = 1 BG.Visible = true 
BG.Parent = ScreenGui

Toggle.MouseButton1Click:Connect(function() BG.Visible = not BG.Visible end)

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

-- Tabs
local TabContainer = Instance.new("Frame") 
TabContainer.Size = UDim2.new(0, 120, 1, -40) 
TabContainer.Position = UDim2.new(0, 0, 0, 40) 
TabContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20) 
TabContainer.Parent = BG

local Tabs = {"Main", "Prehistoric", "Leviathan", "Setting"} local Pages = {}

for i, name in ipairs(Tabs) do local btn = Instance.new("TextButton") btn.Size = UDim2.new(1, 0, 0, 30) btn.Position = UDim2.new(0, 0, 0, (i - 1) * 32) btn.Text = name btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) btn.TextColor3 = Color3.fromRGB(255, 255, 255) btn.Parent = TabContainer

local page = Instance.new("Frame")
page.Size = UDim2.new(1, -120, 1, -40)
page.Position = UDim2.new(0, 120, 0, 40)
page.BackgroundTransparency = 1
page.Visible = i == 1
page.Parent = BG
Pages[name] = page

btn.MouseButton1Click:Connect(function()
	for _, pg in pairs(Pages) do pg.Visible = false end
	page.Visible = true
end)

end

-- MAIN TAB 
local MainTab = Pages["Main"] local AutoFarmBtn = Instance.new("TextButton") AutoFarmBtn.Size = UDim2.new(0, 180, 0, 40) AutoFarmBtn.Position = UDim2.new(0, 20, 0, 20) AutoFarmBtn.Text = "Auto Farm" AutoFarmBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255) AutoFarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255) AutoFarmBtn.Parent = MainTab

local farming = false AutoFarmBtn.MouseButton1Click:Connect(function() farming = not farming AutoFarmBtn.Text = farming and "Auto Farm: ON" or "Auto Farm: OFF" if farming then task.spawn(function() while farming and task.wait(1) do pcall(function() local char = player.Character local lvl = player:FindFirstChild("Data") and player.Data:FindFirstChild("Level") and player.Data.Level.Value or 1 local questData = { [1] = { QuestName = "BanditQuest1", MobName = "Bandit", MobPos = CFrame.new(1039, 17, 1560) }, } local data = questData[1] if data then if not player.PlayerGui:FindFirstChild("QuestTitle") then ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", data.QuestName, 1) task.wait(1) end for _, mob in pairs(workspace.Enemies:GetChildren()) do if mob.Name == data.MobName and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then repeat task.wait() char.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3) VIM:SendKeyEvent(true, "Z", false, game) until mob.Humanoid.Health <= 0 or not farming end end end end) end) end end)

-- PREHISTORIC TAB 
local PreTab = Pages["Prehistoric"] local AutoPreFarm = Instance.new("TextButton") AutoPreFarm.Size = UDim2.new(0, 180, 0, 40) AutoPreFarm.Position = UDim2.new(0, 20, 0, 20) AutoPreFarm.Text = "Auto Prehistoric Farm" AutoPreFarm.BackgroundColor3 = Color3.fromRGB(255, 170, 0) AutoPreFarm.TextColor3 = Color3.fromRGB(255, 255, 255) AutoPreFarm.Parent = PreTab

local AutoPreBoss = AutoPreFarm:Clone() AutoPreBoss.Position = UDim2.new(0, 20, 0, 70) AutoPreBoss.Text = "Auto Prehistoric Boss" AutoPreBoss.Parent = PreTab

local AutoPreItem = AutoPreFarm:Clone() AutoPreItem.Position = UDim2.new(0, 20, 0, 120) AutoPreItem.Text = "Auto Collect Items" AutoPreItem.Parent = PreTab

-- LEVIATHAN TAB 
local LeviTab = Pages["Leviathan"] local AutoLevi = Instance.new("TextButton") AutoLevi.Size = UDim2.new(0, 180, 0, 40) AutoLevi.Position = UDim2.new(0, 20, 0, 20) AutoLevi.Text = "Auto Kill Leviathan" AutoLevi.BackgroundColor3 = Color3.fromRGB(255, 80, 80) AutoLevi.TextColor3 = Color3.fromRGB(255, 255, 255) AutoLevi.Parent = LeviTab

local AutoHeart = AutoLevi:Clone() AutoHeart.Position = UDim2.new(0, 20, 0, 70) AutoHeart.Text = "Auto Take Heart" AutoHeart.Parent = LeviTab

local BodyAttack = AutoLevi:Clone() BodyAttack.Position = UDim2.new(0, 20, 0, 120) BodyAttack.Text = "Body Part Attack" BodyAttack.Parent = LeviTab

-- SETTING TAB 
local SetTab = Pages["Setting"] local FastAttack = Instance.new("TextButton") FastAttack.Size = UDim2.new(0, 180, 0, 40) FastAttack.Position = UDim2.new(0, 20, 0, 20) FastAttack.Text = "Fast Attack: OFF" FastAttack.BackgroundColor3 = Color3.fromRGB(50, 200, 120) FastAttack.TextColor3 = Color3.fromRGB(255, 255, 255) FastAttack.Parent = SetTab

local SkillToggle = Instance.new("TextLabel") 
	SkillToggle.Size = UDim2.new(0, 250, 0, 25) 
	SkillToggle.Position = UDim2.new(0, 20, 0, 70)
	SkillToggle.Text = "Skill Active: [Z, X, C]" 
	SkillToggle.TextColor3 = Color3.fromRGB(255, 255, 255) 
	SkillToggle.BackgroundTransparency = 1 
	SkillToggle.Parent = SetTab

