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
								until mob.Humanoid.Health <= 0 or not farming
							end
						end
					end
				end)
			end
		end)
	end
end)

-- GMON Hub Lanjutan: Menambahkan Semua Tab 
local Tabs = {
    {"Info", {
            "Full Moon Time",
            "Join Discord" }}, 
    {"Main", { 
            "Auto Farm", 
            "Farm Nearest",
            "Auto Chest", 
            "Auto Boss" }},
    {"Item", {
            "Auto CDK",
            "Farm Material",
            "Auto Enchant" }}, 
    {"Prehistoric Island", {
            "Auto Farm Dino", 
            "Auto Kill Boss", 
            "Auto Collect Item" }},
    {"Kitsune Island", { 
            "Auto Blaze Ember Hunt", 
            "Auto Craft Kitsune Key" }},
    {"Mirage Island", {
            "Auto Mirage Search",
            "Auto Moon Check" }},
    {"Leviathan", { 
            "Auto Kill Leviathan", 
            "Auto Draco Race", 
            "Attack Body Parts" }}, 
    {"Misc", { 
            "Redeem All Codes", 
            "FPS Booster", 
            "Server Hop" }}, 
    {"Setting", { 
            "Fast Attack", 
            "Use Skill X", 
            "Use Skill Y",
            "Use Skill Z" 
        }}, 
}

local currentY = 120 for _, tab in pairs(Tabs) do local section = Instance.new("TextLabel", BG) section.Size = UDim2.new(0, 200, 0, 30) section.Position = UDim2.new(0, 20, 0, currentY) section.Text = tab[1] section.TextColor3 = Color3.fromRGB(255, 255, 255) section.BackgroundTransparency = 1 section.Font = Enum.Font.GothamSemibold section.TextXAlignment = Enum.TextXAlignment.Left currentY = currentY + 30

for _, feature in pairs(tab[2]) do
	local toggle = Instance.new("TextButton", BG)
	toggle.Size = UDim2.new(0, 200, 0, 25)
	toggle.Position = UDim2.new(0, 20, 0, currentY)
	toggle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggle.Text = feature .. ": OFF"
	toggle.Font = Enum.Font.Gotham
	toggle.TextSize = 14
	local active = false
	toggle.MouseButton1Click:Connect(function()
		active = not active
		toggle.Text = feature .. (active and ": ON" or ": OFF")
	end)
	currentY = currentY + 28
end

currentY = currentY + 10

end

-- GMON Hub Tabs and Features Integration local Tabs = { {Name = "Info", Buttons = { {Text = "Show Full Moon Time", Callback = function() local fullMoon = require(ReplicatedStorage.Util.FullMoon) local nextFullMoon = fullMoon:GetNextFullMoon() warn("Next Full Moon:", nextFullMoon) end}, {Text = "Join Discord", Callback = function() setclipboard("https://discord.gg/yourserver") warn("Discord link copied to clipboard!") end} }},

{Name = "Main", Buttons = {
    {Text = "Auto Farm", Toggle = true, Callback = function(state)
        farming = state
    end},
    {Text = "Farm Nearest", Toggle = true, Callback = function(state)
        -- Insert logic to farm nearest mobs
    end}
}},

{Name = "Item", Buttons = {
    {Text = "Auto CDK", Toggle = true, Callback = function(state)
        -- Auto CDK logic
    end},
    {Text = "Farm Materials", Toggle = true, Callback = function(state)
        -- Material farming logic
    end}
}},

{Name = "Prehistoric Island", Buttons = {
    {Text = "Auto Blaze Ember", Toggle = true, Callback = function(state)
        -- Blaze Ember logic
    end},
    {Text = "Auto Draco Race", Toggle = true, Callback = function(state)
        -- Draco Race logic
    end}
}},

{Name = "Kitsune Island", Buttons = {
    {Text = "Auto Kitsune Raid", Toggle = true, Callback = function(state)
        -- Kitsune logic
    end}
}},

{Name = "Mirage Island", Buttons = {
    {Text = "Auto Mirage Chest", Toggle = true, Callback = function(state)
        -- Mirage logic
    end}
}},

{Name = "Leviathan", Buttons = {
    {Text = "Auto Kill Leviathan", Toggle = true, Callback = function(state)
        -- Leviathan kill logic
    end},
    {Text = "Auto Take Heart", Toggle = true, Callback = function(state)
        -- Heart collect logic
    end}
}},

{Name = "Misc", Buttons = {
    {Text = "Redeem All Codes", Callback = function()
        local codes = {"CODE1", "CODE2", "CODE3"}
        for _, code in ipairs(codes) do
            ReplicatedStorage.Remotes.CommF_:InvokeServer("RedeemCode", code)
        end
    end}
}},

{Name = "Setting", Buttons = {
    {Text = "Fast Attack", Toggle = true, Callback = function(state)
        -- Fast attack logic
    end},
    {Text = "Skill X", Toggle = true, Callback = function(state)
        -- Skill X logic
    end},
    {Text = "Skill Y", Toggle = true, Callback = function(state)
        -- Skill Y logic
    end},
    {Text = "Skill Z", Toggle = true, Callback = function(state)
        -- Skill Z logic
    end}
}}

}

-- Generate UI Tabs and Buttons table.foreach(Tabs, function(_, tab) local tabButton = Instance.new("TextButton", BG) tabButton.Size = UDim2.new(0, 100, 0, 30) tabButton.Text = tab.Name tabButton.TextColor3 = Color3.fromRGB(255, 255, 255) tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local function showButtons()
    for _, btn in ipairs(tab.Buttons) do
        local button = Instance.new("TextButton", BG)
        button.Size = UDim2.new(0, 160, 0, 30)
        button.Text = btn.Text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

        if btn.Toggle then
            local state = false
            button.MouseButton1Click:Connect(function()
                state = not state
                button.Text = btn.Text .. ": " .. (state and "ON" or "OFF")
                if btn.Callback then btn.Callback(state) end
            end)
        else
            button.MouseButton1Click:Connect(function()
                if btn.Callback then btn.Callback() end
            end)
        end
    end
end

tabButton.MouseButton1Click:Connect(showButtons)

end)
 
