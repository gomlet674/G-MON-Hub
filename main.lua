-- GMON HUB | MAIN.LUA | FINAL
-- Auto Detect | Auto Load | Retry | Loading Bar | Auto Hide

repeat task.wait() until game:IsLoaded()

-- SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local GameId = game.GameId

-- ================= GAME DATABASE =================
-- Gunakan GameId (AMAN untuk semua map)
local Games = {
    [1554960397] = { -- Car Dealership Tycoon
        Name = "Car Dealership Tycoon",
        Url  = "loadstring(game:HttpGet("https://pandadevelopment.net/virtual/file/13ccfd83b4a760c8"))()"
    },

    [2753915549] = { -- Blox Fruits
        Name = "Blox Fruits",
        Url  = "loadstring(game:HttpGet("https://pandadevelopment.net/virtual/file/90b056ec53c4074d"))()"
    },

    [537413528] = { -- Build A Boat For Treasure
        Name = "Build A Boat",
        Url  = "loadstring(game:HttpGet("https://pandadevelopment.net/virtual/file/dace186f8425b825"))()"
    },

    [4639625707] = { -- War Tycoon
        Name = "War Tycoon",
        Url  = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/WarTycoon.lua"
        -- ganti URL jika kamu punya script sendiri
    },

    [9872472334] = { -- 99 Nights in the Forest
        Name = "99 Nights in the Forest",
        Url  = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/99Nights.lua"
        -- ganti URL jika kamu punya script sendiri
    }
}

-- ================= SAFE HTTP =================
local function safeHttpGet(url)
    local ok, res = pcall(function()
        return game:HttpGet(url, true)
    end)
    return ok and res or nil
end

-- ================= UI =================
local gui = Instance.new("ScreenGui")
gui.Name = "GMON_AUTO_LOADER"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local frame = Instance.new("Frame", gui)
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.Position = UDim2.new(0.5, 0, 0.1, 0)
frame.Size = UDim2.new(0, 520, 0, 120)
frame.BackgroundColor3 = Color3.fromRGB(15,15,15)
frame.BackgroundTransparency = 0.35
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 20)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Text = "GMON HUB — Auto Loader"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, -20, 0, 26)
status.Position = UDim2.new(0, 10, 0, 42)
status.BackgroundTransparency = 1
status.Text = "Detecting game..."
status.TextColor3 = Color3.fromRGB(220,220,220)
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.TextXAlignment = Enum.TextXAlignment.Left

local barBg = Instance.new("Frame", frame)
barBg.Position = UDim2.new(0, 10, 0, 78)
barBg.Size = UDim2.new(1, -20, 0, 10)
barBg.BackgroundColor3 = Color3.fromRGB(40,40,40)
barBg.BorderSizePixel = 0
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1,0)

local bar = Instance.new("Frame", barBg)
bar.Size = UDim2.new(0, 0, 1, 0)
bar.BackgroundColor3 = Color3.fromRGB(0,170,255)
bar.BorderSizePixel = 0
Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

-- ================= PROGRESS =================
local function setProgress(v)
    TweenService:Create(
        bar,
        TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = UDim2.new(v, 0, 1, 0) }
    ):Play()
end

-- ================= LOADER =================
local function loadScript(gameData)
    setProgress(0.1)
    status.Text = "Detected: " .. gameData.Name

    task.wait(0.6)
    status.Text = "Downloading script..."
    setProgress(0.3)

    local src = safeHttpGet(gameData.Url)
    if not src then
        status.Text = "Download failed — retrying..."
        setProgress(0)
        task.wait(1)
        return loadScript(gameData)
    end

    status.Text = "Compiling..."
    setProgress(0.55)

    local fn = loadstring(src)
    if not fn then
        status.Text = "Compile error — retrying..."
        setProgress(0)
        task.wait(1)
        return loadScript(gameData)
    end

    status.Text = "Executing..."
    setProgress(0.85)

    local ok = pcall(fn)
    if not ok then
        status.Text = "Runtime error — retrying..."
        setProgress(0)
        task.wait(1)
        return loadScript(gameData)
    end

    status.Text = "Loaded successfully"
    setProgress(1)

    task.wait(0.6)
    gui:Destroy()
end

-- ================= START =================
local selectedGame = Games[GameId]
if selectedGame then
    loadScript(selectedGame)
else
    status.Text = "Game not supported"
    setProgress(1)
end

return {
    Start = function()
        -- main.lua sudah auto-run
    end
}