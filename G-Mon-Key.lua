-- G-Mon-Key.lua (StarterPlayerScripts / CoreGui)

-- Tunggu hingga game benar-benar ter-load
repeat wait() until game:IsLoaded()

-- SETTINGS
local VALID_KEY = "GmonHub311851f3c742a8f78dce99e56992555609d23497928e9b33802e7127610c2e"
local rgbSpeed  = 0.5

-- SERVICES
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService        = game:GetService("RunService")
local StarterGui        = game:GetService("StarterGui")

-- GUI PARENT (CoreGui untuk executor, PlayerGui untuk Studio)
local parentGui = (RunService:IsStudio() and
    game.Players.LocalPlayer:WaitForChild("PlayerGui")) or
    game:GetService("CoreGui")

-- UTILS: Safe fetch + compile + execute
local function safeLoad(url)
    local ok, src = pcall(game.HttpGet, game, url, true)
    if not ok or type(src) ~= "string" or src:match("^%s*$") then
        warn("G-Mon Loader: Gagal fetch script dari", url, ":", src)
        return false
    end

    local fn, err = loadstring(src)
    if not fn then
        warn("G-Mon Loader: Gagal compile script:", err)
        return false
    end

    local suc, execErr = pcall(fn)
    if not suc then
        warn("G-Mon Loader: Error saat eksekusi script:", execErr)
        return false
    end

    return true
end

-- UTILS: Center-Screen Notification
local function showCenterNotification(title, message, displayTime)
    displayTime = displayTime or 3

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CenterNotificationGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame", screenGui)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position    = UDim2.new(0.5, 0, 0.5, 0)
    frame.Size        = UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3    = Color3.fromRGB(25, 25, 25)
    frame.BackgroundTransparency = 0.4
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    local tl = Instance.new("TextLabel", frame)
    tl.Size               = UDim2.new(1, -20, 0, 30)
    tl.Position           = UDim2.new(0, 10, 0, 10)
    tl.Text               = title
    tl.Font               = Enum.Font.GothamBold
    tl.TextSize           = 18
    tl.TextColor3         = Color3.new(1,1,1)
    tl.BackgroundTransparency = 1
    tl.TextXAlignment     = Enum.TextXAlignment.Center

    local ml = Instance.new("TextLabel", frame)
    ml.Size               = UDim2.new(1, -20, 0, 50)
    ml.Position           = UDim2.new(0, 10, 0, 40)
    ml.Text               = message
    ml.Font               = Enum.Font.Gotham
    ml.TextSize           = 14
    ml.TextColor3         = Color3.new(1,1,1)
    ml.BackgroundTransparency = 1
    ml.TextWrapped        = true
    ml.TextXAlignment     = Enum.TextXAlignment.Center

    -- Tween muncul
    TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 300, 0, 100)
    }):Play()

    -- Tween hilang
    task.delay(displayTime, function()
        local tw = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        })
        tw:Play()
        tw.Completed:Wait()
        screenGui:Destroy()
    end)
end

-- Tampilkan notifikasi deteksi game
local ok, info = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Game)
end)
local gameName = ok and info.Name or "Unknown Game"
showCenterNotification("[Game Detected]", gameName, 5)

-- === BUILD KEY UI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GMon_KeyUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = parentGui

local frame = Instance.new("Frame", screenGui)
frame.AnchorPoint          = Vector2.new(0.5, 0.5)
frame.Position             = UDim2.new(0.5, 0, 0.5, -20)
frame.Size                 = UDim2.new(0, 400, 0, 160)
frame.BackgroundColor3     = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.1
frame.ClipsDescendants     = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local border = Instance.new("UIStroke", frame)
border.Thickness         = 2
border.ApplyStrokeMode   = Enum.ApplyStrokeMode.Border
task.spawn(function()
    while frame.Parent do
        for hue = 0, 1, 0.01 do
            border.Color = Color3.fromHSV(hue, 1, 1)
            task.wait(rgbSpeed)
        end
    end
end)

local title = Instance.new("TextLabel", frame)
title.Size               = UDim2.new(1, -20, 0, 30)
title.Position           = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Text               = "G-Mon Hub Key"
title.Font               = Enum.Font.GothamBold
title.TextSize           = 18
title.TextColor3         = Color3.new(1,1,1)
title.TextXAlignment     = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size            = UDim2.new(0, 24, 0, 24)
closeBtn.Position        = UDim2.new(1, -30, 0, 8)
closeBtn.BackgroundTransparency = 1
closeBtn.Text            = "✕"
closeBtn.Font            = Enum.Font.GothamBold
closeBtn.TextSize        = 18
closeBtn.TextColor3      = Color3.new(1,1,1)
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Input Box (hanya muncul saat di-focus)
local input = Instance.new("TextBox", frame)
input.Size               = UDim2.new(0.8, 0, 0, 28)
input.Position           = UDim2.new(0.1, 0, 0.4, 0)
input.PlaceholderText    = "Enter Key..."
input.ClearTextOnFocus   = true
input.BackgroundColor3   = Color3.fromRGB(30,30,30)
input.TextColor3         = Color3.new(1,1,1)
input.Font               = Enum.Font.Gotham
input.TextSize           = 14
Instance.new("UICorner", input).CornerRadius = UDim.new(0,6)

-- Mulai dengan textbox transparan
input.TextTransparency           = 1
input.PlaceholderTextTransparency = 0.5
input.Focused:Connect(function()
    input.TextTransparency           = 0
    input.PlaceholderTextTransparency = 0
end)
input.FocusLost:Connect(function()
    if input.Text == "" then
        input.TextTransparency           = 1
        input.PlaceholderTextTransparency = 0.5
    end
end)

local checkBtn = Instance.new("TextButton", frame)
checkBtn.Size            = UDim2.new(0.35,0,0,28)
checkBtn.Position        = UDim2.new(0.1,0,0.75,0)
checkBtn.Text            = "Check Key"
checkBtn.Font            = Enum.Font.GothamBold
checkBtn.TextSize        = 14
checkBtn.TextColor3      = Color3.new(1,1,1)
checkBtn.BackgroundColor3= Color3.fromRGB(50,100,50)
Instance.new("UICorner", checkBtn).CornerRadius = UDim.new(0,6)

local getKeyBtn = Instance.new("TextButton", frame)
getKeyBtn.Size           = UDim2.new(0.35,0,0,28)
getKeyBtn.Position       = UDim2.new(0.55,0,0.75,0)
getKeyBtn.Text           = "Get Key"
getKeyBtn.Font           = Enum.Font.GothamBold
getKeyBtn.TextSize       = 14
getKeyBtn.TextColor3     = Color3.new(1,1,1)
getKeyBtn.BackgroundColor3 = Color3.fromRGB(50,50,100)
Instance.new("UICorner", getKeyBtn).CornerRadius = UDim.new(0,6)

getKeyBtn.MouseButton1Click:Connect(function()
    pcall(function()
        setclipboard("https://linkvertise.com/1209226/get-key-gmon-hub-script")
    end)
    StarterGui:SetCore("SendNotification", {
        Title = "G-Mon Hub",
        Text  = "Link key copied!",
        Duration = 3
    })
end)

checkBtn.MouseButton1Click:Connect(function()
    if input.Text == VALID_KEY then
        StarterGui:SetCore("SendNotification", {
            Title = "Key Valid",
            Text  = "Loading G-Mon Hub…",
            Duration = 2
        })
        task.wait(0.5)
        screenGui:Destroy()
        safeLoad("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/main.lua")
    else
        StarterGui:SetCore("SendNotification", {
            Title = "Invalid Key",
            Text  = "Please get a valid key.",
            Duration = 3
        })
        input.Text = ""
    end
end)

-- Dragging
do
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = inp.Position
            startPos = frame.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = inp
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp == dragInput then
            local delta = inp.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end