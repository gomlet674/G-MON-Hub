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

-- Create Tabs 
local function createTab(name, pos) local tab = Instance.new("TextButton") tab.Text = name tab.Size = UDim2.new(0, 100, 0, 30) tab.Position = UDim2.new(0, 10 + (pos * 110), 0, 10) tab.BackgroundColor3 = Color3.fromRGB(25, 25, 25) tab.TextColor3 = Color3.new(1,1,1) tab.Parent = BG return tab end

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
