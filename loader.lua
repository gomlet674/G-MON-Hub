-- GMON_Loader.lua (StarterPlayerScripts)

repeat task.wait() until game:IsLoaded()

-- Services
local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local UIS                = game:GetService("UserInputService")
local playerGui          = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Show Notification (Center Screen)
local function showCenterNotification(title, message, displayTime)
	displayTime = displayTime or 3

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CenterNotificationGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame", screenGui)
	frame.Size = UDim2.new(0, 300, 0, 100)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	frame.BackgroundTransparency = 0.4
	frame.BorderSizePixel = 0
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

	local titleLabel = Instance.new("TextLabel", frame)
	titleLabel.Size = UDim2.new(1, -20, 0, 30)
	titleLabel.Position = UDim2.new(0, 10, 0, 10)
	titleLabel.Text = title
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 18
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center

	local msgLabel = Instance.new("TextLabel", frame)
	msgLabel.Size = UDim2.new(1, -20, 0, 50)
	msgLabel.Position = UDim2.new(0, 10, 0, 40)
	msgLabel.Text = message
	msgLabel.Font = Enum.Font.Gotham
	msgLabel.TextSize = 14
	msgLabel.TextColor3 = Color3.new(1, 1, 1)
	msgLabel.BackgroundTransparency = 1
	msgLabel.TextWrapped = true
	msgLabel.TextXAlignment = Enum.TextXAlignment.Center

	frame.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 300, 0, 100)
	}):Play()

	task.delay(displayTime, function()
		TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1
		}):Play()
		task.wait(0.3)
		screenGui:Destroy()
	end)
end

-- Game Name Notification
local ok, info = pcall(function()
	return MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Place)
end)
local gameName = ok and info.Name or "Unknown Game"
showCenterNotification("[Game Detected]", gameName, 5)

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GMON_Loader"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- Background Image
local background = Instance.new("ImageLabel", ScreenGui)
background.Name = "AnimeBackground"
background.BackgroundTransparency = 1
background.Size = UDim2.new(1, 0, 1, 0)
background.Position = UDim2.new(0, 0, 0, 0)
background.Image = "rbxassetid://16790218639"
background.ScaleType = Enum.ScaleType.Crop
background.ZIndex = 0

-- Frame
local Frame = Instance.new("Frame", ScreenGui)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.Size = UDim2.new(0, 420, 0, 200)
Frame.Position = UDim2.new(0.5, -210, 0.5, -100)
Frame.Active = true
Frame.Draggable = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 15)

-- RGB Border
local RGBBorder = Instance.new("UIStroke", Frame)
RGBBorder.Thickness = 2
RGBBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

task.spawn(function()
	while true do
		for i = 0, 1, 0.01 do
			local r = math.sin(i * math.pi * 2) * 127 + 128
			local g = math.sin(i * math.pi * 2 + 2) * 127 + 128
			local b = math.sin(i * math.pi * 2 + 4) * 127 + 128
			RGBBorder.Color = Color3.fromRGB(r, g, b)
			task.wait(0.03)
		end
	end
end)

-- Title
local Title = Instance.new("TextLabel", Frame)
Title.Text = "GMON HUB KEY SYSTEM"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1

-- KeyBox
local KeyBox = Instance.new("TextBox", Frame)
KeyBox.PlaceholderText = "Enter Your Key..."
KeyBox.Size = UDim2.new(0.9, 0, 0, 35)
KeyBox.Position = UDim2.new(0.05, 0, 0.35, 0)
KeyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
KeyBox.Font = Enum.Font.Gotham
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 8)

-- Submit Button
local Submit = Instance.new("TextButton", Frame)
Submit.Text = "Submit"
Submit.Size = UDim2.new(0.42, 0, 0, 35)
Submit.Position = UDim2.new(0.05, 0, 0.65, 0)
Submit.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
Submit.Font = Enum.Font.GothamSemibold
Submit.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", Submit).CornerRadius = UDim.new(0, 8)

-- GetKey Button
local GetKey = Instance.new("TextButton", Frame)
GetKey.Text = "Get Key"
GetKey.Size = UDim2.new(0.42, 0, 0, 35)
GetKey.Position = UDim2.new(0.53, 0, 0.65, 0)
GetKey.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
GetKey.Font = Enum.Font.GothamSemibold
GetKey.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", GetKey).CornerRadius = UDim.new(0, 8)

-- Copy Link
GetKey.MouseButton1Click:Connect(function()
	setclipboard("https://linkvertise.com/1209226/get-key-gmon-hub-script")
end)

-- Valid Key & Saved Key
local VALID_KEY = "GmonHub311851f3c742a8f78dce99e56992555609d23497928e9b33802e7127610c2e"
local savedKeyPath = "gmon_key.txt"

-- Game Script Map
local GAME_SCRIPTS = {
	[4442272183] = "https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/main.lua",
	[3233893879] = "https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/main_arena.lua"
}

-- Load Game Script
local function loadGameScript()
	local url = GAME_SCRIPTS[game.PlaceId]
	if url then
		loadstring(game:HttpGet(url))()
	else
		warn("PlaceId tidak dikenali:", game.PlaceId)
	end
end

-- Validate Key
local function submitKey(key)
	if key == VALID_KEY then
		writefile(savedKeyPath, key)
		ScreenGui:Destroy()
		loadGameScript()
		return true
	end
	return false
end

-- Auto-load if saved key is valid
if isfile(savedKeyPath) then
	local savedKey = readfile(savedKeyPath)
	if submitKey(savedKey) then return end
end

-- Submit Button Click
Submit.MouseButton1Click:Connect(function()
	local inputKey = KeyBox.Text
	if inputKey == "" or not inputKey then
		Submit.Text = "Enter Key"
		task.wait(2)
		Submit.Text = "Submit"
		return
	end

	if not submitKey(inputKey) then
		Submit.Text = "Invalid!"
		task.wait(2)
		Submit.Text = "Submit"
	end
end)