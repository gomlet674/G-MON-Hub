-- GMON Hub Main Script 
local CoreGui = game:GetService("CoreGui") local Players = game:GetService("Players") local RunService = game:GetService("RunService") local ReplicatedStorage = game:GetService("ReplicatedStorage") local VIM = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

-- UI Setup
local ScreenGui = Instance.new("ScreenGui") ScreenGui.Name = "GMON_MainUI" ScreenGui.ResetOnSpawn = false ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Toggle Button 
local Toggle = Instance.new("ImageButton") Toggle.Size = UDim2.new(0, 40, 0, 40) Toggle.Position = UDim2.new(0, 10, 0.5, -100) Toggle.BackgroundTransparency = 1 Toggle.Image = "rbxassetid://94747801090737" Toggle.Name = "GMON_Toggle" Toggle.Parent = ScreenGui

-- Drag toggle 
local dragging, dragInput, dragStart, startPos Toggle.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true dragStart = input.Position startPos = Toggle.Position

input.Changed:Connect(function()
		if input.UserInputState == Enum.UserInputState.End then
			dragging = false
		end
	end)
end

end) Toggle.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end) RunService.Heartbeat:Connect(function() if dragging and dragInput then local delta = dragInput.Position - dragStart Toggle.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)

-- Background Panel 
local BG = Instance.new("ImageLabel") BG.Name = "Background" BG.Size = UDim2.new(0, 480, 0, 320) BG.Position = UDim2.new(0.5, -240, 0.5, -160) BG.BackgroundTransparency = 1 BG.Image = "rbxassetid://88817335071002" BG.Visible = true BG.Parent = ScreenGui

Toggle.MouseButton1Click:Connect(function() BG.Visible = not BG.Visible end)

-- RGB Border Effect 
local RGBFrame = Instance.new("Frame", BG) RGBFrame.Size = UDim2.new(1, 0, 1, 0) RGBFrame.Position = UDim2.new(0, 0, 0, 0) RGBFrame.BackgroundTransparency = 1 RGBFrame.BorderSizePixel = 4 RGBFrame.ZIndex = 2

local border = Instance.new("UIStroke", RGBFrame) border.Thickness = 4 border.Transparency = 0 border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border border.LineJoinMode = Enum.LineJoinMode.Round border.Color = Color3.fromRGB(255, 0, 0)

-- Rainbow effect loop
spawn(function() local hue = 0 while wait(0.03) do hue = (hue + 1) % 360 local color = Color3.fromHSV(hue / 360, 1, 1) pcall(function() border.Color = color end) end end)

-- Tab Sidebar (Vertical Scroll)
local tabFrame = Instance.new("ScrollingFrame")
tabFrame.Name = "TabFrame"
tabFrame.Size = UDim2.new(0, 120, 1, -20)
tabFrame.Position = UDim2.new(0, 10, 0, 10)
tabFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
tabFrame.BorderSizePixel = 0
tabFrame.ScrollBarThickness = 6
tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
tabFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
tabFrame.ScrollingDirection = Enum.ScrollingDirection.Y
tabFrame.ZIndex = 3
tabFrame.Parent = BG

-- UIListLayout for Tab Buttons
local listLayout = Instance.new("UIListLayout")
listLayout.Parent = tabFrame
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)

-- Function to create tab buttons
local function createTabButton(name, onClick)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -10, 0, 30)
	button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	button.BorderSizePixel = 0
	button.Text = name
	button.Font = Enum.Font.Gotham
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 14
	button.ZIndex = 4
	button.Parent = tabFrame

	button.MouseButton1Click:Connect(function()
		onClick()
	end)

	return button
end

-- Tab container (content appears here)
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -140, 1, -20)
contentFrame.Position = UDim2.new(0, 130, 0, 10)
contentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
contentFrame.BorderSizePixel = 0
contentFrame.ZIndex = 3
contentFrame.Parent = BG

-- Example Tab Logic
local tabs = {
	"Main", "Stats", "Teleport", "Players",
	"DevilFruit", "ESP-Raid", "Buy Item", "Setting"
}

local function clearContent()
	for _, child in pairs(contentFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

local tabPages = {}
for _, tabName in pairs(tabs) do
	local page = Instance.new("Frame")
	page.Name = tabName
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = contentFrame
	tabPages[tabName] = page
end

-- Tab: Setting
local SettingTab = Window:Tab("Setting", "rbxassetid://settings_icon")
SettingTab:Toggle("Fast Attack", GMON.Settings.FastAttack, function(val)
    GMON.Settings.FastAttack = val
end)
SettingTab:Toggle("Auto Click", GMON.Settings.AutoClick, function(val)
    GMON.Settings.AutoClick = val
end)
SettingTab:Label("Skill Usage:")
SettingTab:Toggle("Use Skill Z", GMON.Settings.UseSkillZ, function(val)
    GMON.Settings.UseSkillZ = val
end)
SettingTab:Toggle("Use Skill X", GMON.Settings.UseSkillX, function(val)
    GMON.Settings.UseSkillX = val
end)
SettingTab:Toggle("Use Skill C", GMON.Settings.UseSkillC, function(val)
    GMON.Settings.UseSkillC = val
end)
SettingTab:Toggle("Use Skill V", GMON.Settings.UseSkillV, function(val)
    GMON.Settings.UseSkillV = val
end)
SettingTab:Dropdown("Skill Mode", {"Sniper", "Closest", "Spam"}, function(option)
    GMON.Settings.SkillMode = option
end)

-- Tab: Prehistoric
local PreTab = Window:Tab("Prehistoric Island", "rbxassetid://prehistoric_icon")
PreTab:Toggle("Auto Farm", GMON.Prehistoric.AutoFarm, function(v)
    GMON.Prehistoric.AutoFarm = v
end)
PreTab:Toggle("Auto Kill Boss", GMON.Prehistoric.AutoBoss, function(v)
    GMON.Prehistoric.AutoBoss = v
end)
PreTab:Toggle("Auto Collect Item", GMON.Prehistoric.AutoItem, function(v)
    GMON.Prehistoric.AutoItem = v
end)
PreTab:Toggle("Auto Take Heart", GMON.Prehistoric.AutoHeart, function(v)
    GMON.Prehistoric.AutoHeart = v
end)
PreTab:Toggle("Auto Draco Race v1–v4", GMON.Prehistoric.AutoDraco, function(v)
    GMON.Prehistoric.AutoDraco = v
end)
PreTab:Toggle("Auto Blaze Ember Hunt", GMON.Prehistoric.AutoBlaze, function(v)
    GMON.Prehistoric.AutoBlaze = v
end)
PreTab:Toggle("Craft Prehistoric Weapon", GMON.Prehistoric.AutoCraft, function(v)
    GMON.Prehistoric.AutoCraft = v
end)
PreTab:Toggle("Auto Leviathan Attack", GMON.Prehistoric.AutoLeviathan, function(v)
    GMON.Prehistoric.AutoLeviathan = v
end)
PreTab:Toggle("Auto Teleport to Island", GMON.Prehistoric.AutoTPIsland, function(v)
    GMON.Prehistoric.AutoTPIsland = v
end)

-- Isi konten tab Main (Auto Farm)
if tabName == "Main" then
	local page = tabPages[tabName]

	-- Select Weapon Label
	local weaponLabel = Instance.new("TextLabel", page)
	weaponLabel.Size = UDim2.new(0, 200, 0, 25)
	weaponLabel.Position = UDim2.new(0, 10, 0, 10)
	weaponLabel.Text = "Select Weapon"
	weaponLabel.TextColor3 = Color3.new(1,1,1)
	weaponLabel.BackgroundTransparency = 1
	weaponLabel.Font = Enum.Font.Gotham
	weaponLabel.TextSize = 14

	-- Dropdown Weapon
	local weaponDropdown = Instance.new("TextButton", page)
	weaponDropdown.Size = UDim2.new(0, 200, 0, 30)
	weaponDropdown.Position = UDim2.new(0, 10, 0, 40)
	weaponDropdown.Text = "Click to select"
	weaponDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	weaponDropdown.TextColor3 = Color3.new(1,1,1)
	weaponDropdown.Font = Enum.Font.Gotham
	weaponDropdown.TextSize = 14

	-- Refresh Weapon Button
	local refreshBtn = Instance.new("TextButton", page)
	refreshBtn.Size = UDim2.new(0, 100, 0, 30)
	refreshBtn.Position = UDim2.new(0, 220, 0, 40)
	refreshBtn.Text = "Refresh"
	refreshBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	refreshBtn.TextColor3 = Color3.new(1,1,1)
	refreshBtn.Font = Enum.Font.Gotham
	refreshBtn.TextSize = 14

	-- Method Dropdown
	local methodLabel = Instance.new("TextLabel", page)
	methodLabel.Size = UDim2.new(0, 200, 0, 25)
	methodLabel.Position = UDim2.new(0, 10, 0, 80)
	methodLabel.Text = "Method"
	methodLabel.TextColor3 = Color3.new(1,1,1)
	methodLabel.BackgroundTransparency = 1
	methodLabel.Font = Enum.Font.Gotham
	methodLabel.TextSize = 14

	local methodDropdown = Instance.new("TextButton", page)
	methodDropdown.Size = UDim2.new(0, 200, 0, 30)
	methodDropdown.Position = UDim2.new(0, 10, 0, 110)
	methodDropdown.Text = "Level"
	methodDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	methodDropdown.TextColor3 = Color3.new(1,1,1)
	methodDropdown.Font = Enum.Font.Gotham
	methodDropdown.TextSize = 14

	-- Fast Attack Toggle
	local fastAttack = Instance.new("TextButton", page)
	fastAttack.Size = UDim2.new(0, 200, 0, 30)
	fastAttack.Position = UDim2.new(0, 10, 0, 150)
	fastAttack.Text = "Fast Attack: OFF"
	fastAttack.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	fastAttack.TextColor3 = Color3.new(1,1,1)
	fastAttack.Font = Enum.Font.Gotham
	fastAttack.TextSize = 14

	local fastAttackEnabled = false
	fastAttack.MouseButton1Click:Connect(function()
		fastAttackEnabled = not fastAttackEnabled
		fastAttack.Text = "Fast Attack: " .. (fastAttackEnabled and "ON" or "OFF")
	end)

	-- Auto Farm Toggle
	local autoFarmBtn = Instance.new("TextButton", page)
	autoFarmBtn.Size = UDim2.new(0, 200, 0, 40)
	autoFarmBtn.Position = UDim2.new(0, 10, 0, 200)
	autoFarmBtn.Text = "Auto Farm: OFF"
	autoFarmBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
	autoFarmBtn.TextColor3 = Color3.new(1,1,1)
	autoFarmBtn.Font = Enum.Font.GothamBold
	autoFarmBtn.TextSize = 16

	local autoFarmEnabled = false
	autoFarmBtn.MouseButton1Click:Connect(function()
		autoFarmEnabled = not autoFarmEnabled
		autoFarmBtn.Text = "Auto Farm: " .. (autoFarmEnabled and "ON" or "OFF")
	end)
end
-- Clear all tab pages
local function showTab(tabName)
	for name, page in pairs(tabPages) do
		page.Visible = (name == tabName)
	end
end

for _, tabName in pairs(tabs) do
	createTabButton(tabName, function()
		showTab(tabName)
	end)
end

-- Create Tabs 
local function createTab(name, pos) local tab = Instance.new("TextButton") tab.Text = name tab.Size = UDim2.new(0, 100, 0, 30) tab.Position = UDim2.new(0, 10 + (pos * 110), 0, 10) tab.BackgroundColor3 = Color3.fromRGB(25, 25, 25) tab.TextColor3 = Color3.new(1,1,1) tab.Parent = BG return tab end

local tabPages = {}

-- Buat container tiap tab (panel isi)
for _, tabName in pairs(tabs) do
	local page = Instance.new("Frame")
	page.Name = tabName .. "_Page"
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = contentFrame
	tabPages[tabName] = page

	-- Contoh isi awal tab (nanti diganti dengan fitur real)
	local label = Instance.new("TextLabel", page)
	label.Size = UDim2.new(1, 0, 0, 30)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 20
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = "Kamu membuka tab: " .. tabName
end

-- Fungsi show tab
local function showTab(tabName)
	for name, page in pairs(tabPages) do
		page.Visible = (name == tabName)
	end
end

-- Ubah callback button
for _, button in ipairs(tabFrame:GetChildren()) do
	if button:IsA("TextButton") then
		local tabName = button.Text
		button.MouseButton1Click:Connect(function()
			showTab(tabName)
		end)
	end
end

-- Aktifkan default tab pertama
showTab(tabs[1])

-- Create Tabs and Pages
local Tabs = {
	"Main", "Stats", "Teleport", "Players",
	"DevilFruit", "ESP-Raid", "Buy Item",
	"Prehistoric Island", "Kitsune Island",
	"Mirage Island", "Leviathan",
	"Item", "Misc", "Setting"
}

local Pages = {}
local ActivePage = nil

local function createTab(name, pos)
	local tab = Instance.new("TextButton")
	tab.Text = name
	tab.Size = UDim2.new(0, 100, 0, 30)
	tab.Position = UDim2.new(0, 10 + (pos * 110), 0, 10)
	tab.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	tab.TextColor3 = Color3.new(1,1,1)
	tab.Parent = BG

	-- Create corresponding page
	local page = Instance.new("Frame")
	page.Name = name .. "Page"
	page.Size = UDim2.new(1, -20, 1, -50)
	page.Position = UDim2.new(0, 10, 0, 50)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = BG
	Pages[name] = page

	-- Tab click event
	tab.MouseButton1Click:Connect(function()
		if ActivePage then
			ActivePage.Visible = false
		end
		page.Visible = true
		ActivePage = page
	end)

	return tab
end

for i, tabName in ipairs(Tabs) do
	createTab(tabName, i-1)
end
