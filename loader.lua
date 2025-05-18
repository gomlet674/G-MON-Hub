-- loader.lua
-- LocalScript di StarterPlayerScripts

-- 1) Tunggu sampai game benar-benar loaded
repeat task.wait() until game:IsLoaded()

-- 2) Services
local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService       = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 3) Center-Screen Notification
local function showCenterNotification(title, message, displayTime)
    displayTime = displayTime or 3

    local gui = Instance.new("ScreenGui", playerGui)
    gui.Name = "CenterNotificationGui"
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame", gui)
    frame.Size               = UDim2.new(0,300,0,100)
    frame.AnchorPoint        = Vector2.new(0.5,0.5)
    frame.Position           = UDim2.new(0.5,0.5,0.3,0)
    frame.BackgroundColor3   = Color3.fromRGB(25,25,25)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel    = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

    local titleLabel = Instance.new("TextLabel", frame)
    titleLabel.Size               = UDim2.new(1,-20,0,30)
    titleLabel.Position           = UDim2.new(0,10,0,10)
    titleLabel.Text               = title
    titleLabel.Font               = Enum.Font.GothamBold
    titleLabel.TextSize           = 18
    titleLabel.TextColor3         = Color3.new(1,1,1)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment     = Enum.TextXAlignment.Center

    local msgLabel = Instance.new("TextLabel", frame)
    msgLabel.Size               = UDim2.new(1,-20,0,50)
    msgLabel.Position           = UDim2.new(0,10,0,40)
    msgLabel.Text               = message
    msgLabel.Font               = Enum.Font.Gotham
    msgLabel.TextSize           = 14
    msgLabel.TextColor3         = Color3.new(1,1,1)
    msgLabel.BackgroundTransparency = 1
    msgLabel.TextWrapped        = true
    msgLabel.TextXAlignment     = Enum.TextXAlignment.Center

    -- animasi masuk
    frame.Size = UDim2.new(0,0,0,0)
    TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0,300,0,100)
    }):Play()

    -- animasi keluar setelah delay
    delay(displayTime, function()
        TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size               = UDim2.new(0,0,0,0),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.35)
        gui:Destroy()
    end)
end

-- 4) Deteksi game & player count
local ok, info = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Game)
end)
local gameName   = ok and info.Name or "Unknown Game"
local playerCount = #Players:GetPlayers()
showCenterNotification("Game Detected", gameName .. "  |  Players: " .. playerCount, 4)

-- tunggu sampai notif benar-benar hilang (4s + 0.4s animasi)
task.wait(4.4)

-- 5) Buat Key-Entry UI
local loaderGui = Instance.new("ScreenGui")
loaderGui.Name = "GMON_Loader"
loaderGui.ResetOnSpawn = false
loaderGui.Parent = playerGui

-- Main Frame
local Frame = Instance.new("Frame", loaderGui)
Frame.Size               = UDim2.new(0,420,0,200)
Frame.Position           = UDim2.new(0.5,-210,0.5,-100)
Frame.BackgroundColor3   = Color3.fromRGB(20,20,20)
Frame.Active             = true
Frame.Draggable          = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0,15)

-- RGB Border Effect
local border = Instance.new("UIStroke", Frame)
border.Thickness = 3
border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
-- animasi RGB
task.spawn(function()
    while Frame.Parent do
        for i = 0,1,0.01 do
            border.Color = Color3.fromHSV(i,1,1)
            task.wait(0.02)
        end
    end
end)

-- Title
local Title = Instance.new("TextLabel", Frame)
Title.Size                 = UDim2.new(1,0,0,40)
Title.Position             = UDim2.new(0,0,0,0)
Title.Text                 = "G-Mon Hub"
Title.Font                 = Enum.Font.GothamBold
Title.TextSize             = 22
Title.TextColor3           = Color3.new(1,1,1)
Title.BackgroundTransparency = 1

-- Close [×]
local CloseBtn = Instance.new("TextButton", Frame)
CloseBtn.Size       = UDim2.new(0,32,0,32)
CloseBtn.Position   = UDim2.new(1,-36,0,4)
CloseBtn.Text        = "×"
CloseBtn.Font        = Enum.Font.GothamBold
CloseBtn.TextSize    = 24
CloseBtn.TextColor3  = Color3.new(1,1,1)
CloseBtn.BackgroundTransparency = 1
CloseBtn.MouseButton1Click:Connect(function()
    loaderGui:Destroy()
end)

-- KeyBox
local KeyBox = Instance.new("TextBox", Frame)
KeyBox.Size               = UDim2.new(0.9,0,0,35)
KeyBox.Position           = UDim2.new(0.05,0,0.35,0)
KeyBox.PlaceholderText    = "Enter Your Key..."
KeyBox.Font               = Enum.Font.Gotham
KeyBox.TextColor3         = Color3.new(1,1,1)
KeyBox.BackgroundColor3   = Color3.fromRGB(40,40,40)
Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0,8)

-- GetKey Button
local GetKey = Instance.new("TextButton", Frame)
GetKey.Size               = UDim2.new(0.42,0,0,35)
GetKey.Position           = UDim2.new(0.05,0,0.65,0)
GetKey.Text               = "Get Key"
GetKey.Font               = Enum.Font.GothamSemibold
GetKey.TextColor3         = Color3.new(1,1,1)
GetKey.BackgroundColor3   = Color3.fromRGB(255,85,0)
Instance.new("UICorner", GetKey).CornerRadius = UDim.new(0,8)
GetKey.MouseButton1Click:Connect(function()
    setclipboard("https://linkvertise.com/1209226/get-key-gmon-hub-script")
    showCenterNotification("", "Link key disalin!", 2)
end)

-- Submit Button
local Submit = Instance.new("TextButton", Frame)
Submit.Size               = UDim2.new(0.42,0,0,35)
Submit.Position           = UDim2.new(0.53,0,0.65,0)
Submit.Text               = "Submit"
Submit.Font               = Enum.Font.GothamSemibold
Submit.TextColor3         = Color3.new(1,1,1)
Submit.BackgroundColor3   = Color3.fromRGB(0,170,127)
Instance.new("UICorner", Submit).CornerRadius = UDim.new(0,8)

-- Key file
local savedKeyPath = "gmon_key.txt"

-- Game scripts mapping (support “all games” via fallback to main.lua)
local GAME_SCRIPTS = {
    [4442272183] = "https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/main.lua",
    [537413528] = "https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/build.lua",
    [116495829188952] = "https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/Rail.lua",
}
local DEFAULT_URL = "https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/main.lua"

local function loadGameScript()
    local url = GAME_SCRIPTS[game.PlaceId] or DEFAULT_URL
    loadstring(game:HttpGet(url, true))()
end

-- Valid key
local VALID_KEY = "GmonHub311851f3c742a8f78dce99e56992555609d23497928e9b33802e7127610c2e"

-- Submit logic
Submit.MouseButton1Click:Connect(function()
    local key = KeyBox.Text:match("%S+") or ""
    if key == "" then
        Submit.Text = "Enter Key"
        task.wait(2)
        Submit.Text = "Submit"
        return
    end
    if key == VALID_KEY then
        -- success
        Submit.Text = "✔"
        task.wait(0.5)
        loaderGui:Destroy()
        loadGameScript()
    else
        Submit.Text = "Invalid!"
        task.wait(2)
        Submit.Text = "Submit"
    end
end)

-- Auto-load saved key
if isfile(savedKeyPath) then
    local saved = readfile(savedKeyPath)
    if saved == VALID_KEY then
        loaderGui:Destroy()
        loadGameScript()
    else
        delfile(savedKeyPath)
    end
end