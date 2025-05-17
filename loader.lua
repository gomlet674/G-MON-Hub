-- Center‐Screen Notification
-- Letakkan ini di StarterPlayerScripts sebagai LocalScript

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Fungsi untuk memunculkan notifikasi
local function showCenterNotification(title, message, displayTime)
    displayTime = displayTime or 3

    -- Buat ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CenterNotificationGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- Container Frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 100)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0.5, 0.5, 0)  -- tengah layar
    frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    -- Title Label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 18
    titleLabel.TextColor3 = Color3.new(1,1,1)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.Parent = frame

    -- Message Label
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -20, 0, 50)
    msgLabel.Position = UDim2.new(0, 10, 0, 40)
    msgLabel.Text = message
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 14
    msgLabel.TextColor3 = Color3.new(1,1,1)
    msgLabel.BackgroundTransparency = 1
    msgLabel.TextWrapped = true
    msgLabel.TextXAlignment = Enum.TextXAlignment.Center
    msgLabel.Parent = frame

    -- Mulai dengan scale kecil (menghilang)
    frame.Size = UDim2.new(0, 0, 0, 0)

    -- Tween untuk muncul
    game:GetService("TweenService"):Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 300, 0, 100)
    }):Play()

    -- Setelah beberapa detik, tween keluar dan hapus
    delay(displayTime, function()
    local tween = game:GetService("TweenService"):Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    })
    tween:Play()
    tween.Completed:Connect(function()
        screenGui:Destroy()
    end)
end)

-- Contoh penggunaan:
showCenterNotification("[Game Detected]", game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId, Enum.InfoType.Game).Name, 5)

-- Main
local placeId = game.PlaceId
local gameName = getGameName(placeId)

-- Show a notification at the top center
notify("[Game Detected]", gameName, 7)

-- GUI Elements
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local RGBBorder = Instance.new("UIStroke")
local Title = Instance.new("TextLabel")
local KeyBox = Instance.new("TextBox")
local Submit = Instance.new("TextButton")
local GetKey = Instance.new("TextButton")
local background = Instance.new("ImageLabel")

-- GUI Parent
ScreenGui.Name = "GMON_Loader"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- Background Image
background.Name = "AnimeBackground"
background.Parent = ScreenGui
background.BackgroundTransparency = 1
background.Size = UDim2.new(1, 0, 1, 0)
background.Position = UDim2.new(0, 0, 0, 0)
background.Image = "rbxassetid://16790218639"
background.ImageColor3 = Color3.new(1, 1, 1)
background.ScaleType = Enum.ScaleType.Crop
background.ZIndex = 0

-- Main Frame
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.Size = UDim2.new(0, 420, 0, 200)
Frame.Position = UDim2.new(0.5, -210, 0.5, -100)
Frame.Active = true
Frame.Draggable = true

UICorner.CornerRadius = UDim.new(0, 15)
UICorner.Parent = Frame

-- RGB Border Effect
RGBBorder.Parent = Frame
RGBBorder.Thickness = 2
RGBBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

task.spawn(function()
	while true do
		for i = 0, 1, 0.01 do
			local r = math.sin(i * math.pi * 2) * 127 + 128
			local g = math.sin(i * math.pi * 2 + 2) * 127 + 128
			local b = math.sin(i * math.pi * 2 + 4) * 127 + 128
			RGBBorder.Color = Color3.fromRGB(r, g, b)
			wait(0.03)
		end
	end
end)

-- Title
Title.Parent = Frame
Title.Text = "GMON HUB KEY SYSTEM"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1

-- Key Input
KeyBox.Parent = Frame
KeyBox.PlaceholderText = "Enter Your Key..."
KeyBox.Size = UDim2.new(0.9, 0, 0, 35)
KeyBox.Position = UDim2.new(0.05, 0, 0.35, 0)
KeyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
KeyBox.Font = Enum.Font.Gotham
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.new(1, 1, 1)

Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 8)

-- Submit
Submit.Parent = Frame
Submit.Text = "Submit"
Submit.Size = UDim2.new(0.42, 0, 0, 35)
Submit.Position = UDim2.new(0.05, 0, 0.65, 0)
Submit.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
Submit.Font = Enum.Font.GothamSemibold
Submit.TextColor3 = Color3.new(1, 1, 1)

Instance.new("UICorner", Submit).CornerRadius = UDim.new(0, 8)

-- Get Key
GetKey.Parent = Frame
GetKey.Text = "Get Key"
GetKey.Size = UDim2.new(0.42, 0, 0, 35)
GetKey.Position = UDim2.new(0.53, 0, 0.65, 0)
GetKey.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
GetKey.Font = Enum.Font.GothamSemibold
GetKey.TextColor3 = Color3.new(1, 1, 1)

Instance.new("UICorner", GetKey).CornerRadius = UDim.new(0, 8)

GetKey.MouseButton1Click:Connect(function()
    setclipboard("https://linkvertise.com/1209226/get-key-gmon-hub-script")
end)

-- Key File Path
local savedKeyPath = "gmon_key.txt"

local GAME_SCRIPTS = {
    [4442272183] = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/main.lua",         -- Blox Fruits
    [3233893879] = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/main_arena.lua",   -- Arena
    [537413528]  = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/build.lua",        -- Build A Boat
}

-- Fungsi untuk memuat skrip sesuai game
local function loadGameScript()
    local url = GAME_SCRIPTS[game.PlaceId]
    if not url then
        warn("GMON Loader: Game PlaceId tidak dikenali:", game.PlaceId)
        return
    end
    loadstring(game:HttpGet(url, true))()
end

-- Key yang valid
local VALID_KEY = "GmonHub311851f3c742a8f78dce99e56992555609d23497928e9b33802e7127610c2e"

local function submitKey(key)
    if key == VALID_KEY then
        writefile(savedKeyPath, key)
        ScreenGui:Destroy()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/main.lua"))()
        return true
    end
    return false
end

-- Cek apakah key sudah tersimpan dan valid
if isfile(savedKeyPath) then
    local savedKey = readfile(savedKeyPath)
    if submitKey(savedKey) then
        return -- Berhenti eksekusi loader jika key valid
    end
end

-- Event Handlers jika belum ada key valid
Submit.MouseButton1Click:Connect(function()
    local inputKey = KeyBox.Text

    if inputKey == nil or inputKey == "" then
        Submit.Text = "Enter Key"
        task.wait(2)
        Submit.Text = "Submit"
        return
    end

    if submitKey(inputKey) then
        -- berhasil submit
    else
        Submit.Text = "Invalid!"
        task.wait(2)
        Submit.Text = "Submit"
    end
end)

-- Drag Functionality
local UIS = game:GetService("UserInputService")
local dragging, dragInput, dragStart, startPos

local function updateInput(input)
	local delta = input.Position - dragStart
	Frame.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end

Frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

Frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		updateInput(input)
	end
end)