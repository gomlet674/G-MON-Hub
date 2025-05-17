-- GMON Loader - Letakkan sebagai LocalScript di StarterPlayerScripts

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local HttpService = game:GetService("HttpService")

-- Notifikasi tengah layar
local function showCenterNotification(title, message, displayTime)
	displayTime = displayTime or 3
	local screenGui = Instance.new("ScreenGui", playerGui)
	screenGui.Name = "CenterNotificationGui"
	screenGui.ResetOnSpawn = false

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
	TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Size = UDim2.new(0, 300, 0, 100) }):Play()

	delay(displayTime, function()
		TweenService:Create(frame, TweenInfo.new(0.3), { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }):Play()
		wait(0.3)
		screenGui:Destroy()
	end)
end

-- Tampilkan nama game saat masuk
local info = MarketplaceService:GetProductInfo(game.PlaceId)
showCenterNotification("[Game Detected]", info.Name, 5)

--=== SETUP KEY SYSTEM ===--
local VALID_KEY = "GmonHub311851f3c742a8f78dce99e56992555609d23497928e9b33802e7127610c2e"
local savedKeyPath = "GMON_HUB_KEY.txt"
local PlaceId = tostring(game.PlaceId)
local baseUrl = "https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/"
local fileName = "main_" .. PlaceId .. ".lua"
local url = baseUrl .. fileName

local function fallback()
	local defaultScript = game:HttpGet(baseUrl .. "main.lua")
	loadstring(defaultScript)()
end

-- Jika key sudah tersimpan
if isfile and readfile and isfile(savedKeyPath) then
	local savedKey = readfile(savedKeyPath)
	if savedKey == VALID_KEY then
		showCenterNotification("Welcome Back", "Key Auto Loaded", 3)
		local success, result = pcall(function() return game:HttpGet(url) end)
		if success and result and #result > 0 then
			loadstring(result)()
		else
			fallback()
		end
		return
	end
end

-- Buat GUI
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "GMON_Loader"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local background = Instance.new("ImageLabel", ScreenGui)
background.Size = UDim2.new(1, 0, 1, 0)
background.Image = "rbxassetid://16790218639"
background.ScaleType = Enum.ScaleType.Crop
background.BackgroundTransparency = 1
background.ZIndex = 0

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 420, 0, 200)
Frame.Position = UDim2.new(0.5, -210, 0.5, -100)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.Active, Frame.Draggable = true, true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 15)

local stroke = Instance.new("UIStroke", Frame)
stroke.Thickness = 2
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
task.spawn(function()
	while true do
		for i = 0, 1, 0.01 do
			local r = math.sin(i * math.pi * 2) * 127 + 128
			local g = math.sin(i * math.pi * 2 + 2) * 127 + 128
			local b = math.sin(i * math.pi * 2 + 4) * 127 + 128
			stroke.Color = Color3.fromRGB(r, g, b)
			wait(0.03)
		end
	end
end)

local Title = Instance.new("TextLabel", Frame)
Title.Text = "GMON HUB KEY SYSTEM"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1

local KeyBox = Instance.new("TextBox", Frame)
KeyBox.PlaceholderText = "Enter Your Key..."
KeyBox.Size = UDim2.new(0.9, 0, 0, 35)
KeyBox.Position = UDim2.new(0.05, 0, 0.35, 0)
KeyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
KeyBox.Font = Enum.Font.Gotham
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 8)

local Submit = Instance.new("TextButton", Frame)
Submit.Text = "Submit"
Submit.Size = UDim2.new(0.42, 0, 0, 35)
Submit.Position = UDim2.new(0.05, 0, 0.65, 0)
Submit.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
Submit.Font = Enum.Font.GothamSemibold
Submit.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", Submit).CornerRadius = UDim.new(0, 8)

local GetKey = Instance.new("TextButton", Frame)
GetKey.Text = "Get Key"
GetKey.Size = UDim2.new(0.42, 0, 0, 35)
GetKey.Position = UDim2.new(0.53, 0, 0.65, 0)
GetKey.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
GetKey.Font = Enum.Font.GothamSemibold
GetKey.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", GetKey).CornerRadius = UDim.new(0, 8)

GetKey.MouseButton1Click:Connect(function()
	if setclipboard then
		setclipboard("https://linkvertise.com/1209226/get-key-gmon-hub-script")
		showCenterNotification("Key Copied", "Link has been copied to clipboard!", 3)
	end
end)

Submit.MouseButton1Click:Connect(function()
	local key = KeyBox.Text
	if key == VALID_KEY then
		if writefile then writefile(savedKeyPath, key) end
		showCenterNotification("Success", "Valid key. Loading script...", 3)
		ScreenGui:Destroy()
		local success, result = pcall(function() return game:HttpGet(url) end)
		if success and result and #result > 0 then
			loadstring(result)()
		else
			fallback()
		end
	else
		showCenterNotification("Invalid Key", "Please get a valid key.", 3)
	end
end)