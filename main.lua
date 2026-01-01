-- main.lua (GMON FINAL + RETRY)

repeat task.wait() until game:IsLoaded()

-- SERVICES
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local PlaceId = game.PlaceId
local Player = Players.LocalPlayer

-- ================= CONFIG =================
local Games = {
    [2753915549] = { Key="BloxFruits", Name="Blox Fruits", Url="https://pandadevelopment.net/virtual/file/f2e45fc211ee862d" },
    [654732683]  = { Key="CarDealership", Name="Car Dealership", Url="https://pandadevelopment.net/virtual/file/fef83e33e7275173" },
    [537413528]  = { Key="BuildABoat", Name="Build A Boat", Url="https://pandadevelopment.net/virtual/file/dace186f8425b825" }
}

local Tabs = {
    {Key="BloxFruits", Label="Blox Fruits"},
    {Key="CarDealership", Label="Car Dealership"},
    {Key="BuildABoat", Label="Build A Boat"}
}

-- ================= UTIL =================
local function safeGet(url)
    local ok, res = pcall(function()
        return game:HttpGet(url, true)
    end)
    return ok and res or nil
end

-- ================= UI =================
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "GMON_GUI"
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.AnchorPoint = Vector2.new(0.5,0)
main.Position = UDim2.fromScale(0.5,0.12)
main.Size = UDim2.fromOffset(560,140)
main.BackgroundColor3 = Color3.fromRGB(20,20,20)
main.BackgroundTransparency = 0.3
main.BorderSizePixel = 0
Instance.new("UICorner", main).CornerRadius = UDim.new(0,18)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1,-20,0,30)
title.Position = UDim2.fromOffset(10,8)
title.BackgroundTransparency = 1
title.Text = "GMON HUB — Auto Loader"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Left

-- ================= PANEL =================
local function createPanel(name)
    local panel = Instance.new("Frame", main)
    panel.Position = UDim2.fromOffset(10,48)
    panel.Size = UDim2.new(1,-20,1,-58)
    panel.BackgroundTransparency = 1

    local info = Instance.new("TextLabel", panel)
    info.Size = UDim2.new(1,0,0,26)
    info.BackgroundTransparency = 1
    info.Text = "Idle"
    info.TextColor3 = Color3.new(1,1,1)
    info.Font = Enum.Font.Gotham
    info.TextSize = 15

    local barBg = Instance.new("Frame", panel)
    barBg.Position = UDim2.fromOffset(0,32)
    barBg.Size = UDim2.new(1,0,0,10)
    barBg.BackgroundColor3 = Color3.fromRGB(40,40,40)
    Instance.new("UICorner", barBg)

    local bar = Instance.new("Frame", barBg)
    bar.Size = UDim2.fromScale(0,1)
    bar.BackgroundColor3 = Color3.fromRGB(0,170,255)
    Instance.new("UICorner", bar)

    local retry = Instance.new("TextButton", panel)
    retry.Position = UDim2.fromOffset(0,50)
    retry.Size = UDim2.fromOffset(120,32)
    retry.Text = "Retry"
    retry.Visible = false
    retry.Font = Enum.Font.GothamBold
    retry.TextSize = 14
    retry.TextColor3 = Color3.new(1,1,1)
    retry.BackgroundColor3 = Color3.fromRGB(255,80,80)
    Instance.new("UICorner", retry)

    return panel, info, bar, retry
end

-- ================= LOADER =================
local function loadModule(url, info, bar, retryBtn)
    retryBtn.Visible = false

    local function set(p)
        TweenService:Create(bar, TweenInfo.new(0.25), {
            Size = UDim2.fromScale(p,1)
        }):Play()
    end

    info.Text = "Downloading..."
    set(0.25)
    local src = safeGet(url)
    if not src then
        info.Text = "Download failed"
        retryBtn.Visible = true
        return
    end

    info.Text = "Compiling..."
    set(0.55)
    local fn = loadstring(src)
    if not fn then
        info.Text = "Compile error"
        retryBtn.Visible = true
        return
    end

    info.Text = "Executing..."
    set(0.85)
    local ok = pcall(fn)
    if not ok then
        info.Text = "Runtime error"
        retryBtn.Visible = true
        return
    end

    info.Text = "Loaded successfully"
    set(1)

    task.delay(0.5,function()
        gui:Destroy()
    end)
end

-- ================= INIT =================
local panel, info, bar, retry = createPanel("Main")

local autoGame = Games[PlaceId]
if autoGame then
    info.Text = "Detected: "..autoGame.Name
    task.wait(0.6)
    loadModule(autoGame.Url, info, bar, retry)

    retry.MouseButton1Click:Connect(function()
        bar.Size = UDim2.fromScale(0,1)
        loadModule(autoGame.Url, info, bar, retry)
    end)
else
    info.Text = "Game not supported"
end