repeat task.wait() until game:IsLoaded()

--==================== SERVICES =====================--
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

--==================== GAME DATABASE =====================--
local Games = {
    [654732683] = {
        Name = "Car Dealership Tycoon",
        Url = "https://pandadevelopment.net/virtual/file/fef83e33e7275173"
    },
    [537413528] = {
        Name = "Build A Boat For Treasure",
        Url = "https://pandadevelopment.net/virtual/file/dace186f8425b825"
    },
    [2753915549] = {
        Name = "Blox Fruits",
        Url = "https://pandadevelopment.net/virtual/file/f2e45fc211ee862d"
    },
    [4639625707] = {
        Name = "War Tycoon",
        Url = "https://yourdomain.com/war_tycoon.lua"
    },
    [10449761463] = {
        Name = "99 Nights in the Forest",
        Url = "https://yourdomain.com/99_nights.lua"
    }
}

local PlaceId = game.PlaceId
local GameInfo = Games[PlaceId]

--==================== CUSTOM GUI =====================--
local function CreateGUI(title)
    local gui = Instance.new("ScreenGui")
    gui.Name = "GMON_Detector"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui

    local frame = Instance.new("Frame", gui)
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.Position = UDim2.fromScale(0.5, 0.05)
    frame.Size = UDim2.fromOffset(380, 80)
    frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    frame.BackgroundTransparency = 1
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Thickness = 1
    stroke.Transparency = 0.5

    local label = Instance.new("TextLabel", frame)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -20, 0, 30)
    label.Position = UDim2.fromOffset(10, 6)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 16
    label.TextColor3 = Color3.new(1,1,1)
    label.TextXAlignment = Left
    label.Text = title

    local barBg = Instance.new("Frame", frame)
    barBg.Position = UDim2.fromOffset(12, 50)
    barBg.Size = UDim2.new(1, -24, 0, 8)
    barBg.BackgroundColor3 = Color3.fromRGB(40,40,40)
    barBg.BackgroundTransparency = 0.2
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local bar = Instance.new("Frame", barBg)
    bar.Size = UDim2.fromScale(0,1)
    bar.BackgroundColor3 = Color3.fromRGB(0,170,255)
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    TweenService:Create(frame, TweenInfo.new(0.4), {
        BackgroundTransparency = 0.3
    }):Play()

    return gui, frame, bar, label
end

--==================== PROGRESS UPDATE =====================--
local function setProgress(bar, value)
    TweenService:Create(
        bar,
        TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.fromScale(value, 1)}
    ):Play()
end

--==================== AUTO HIDE =====================--
local function autoHide(gui, frame)
    task.delay(0.6, function()
        TweenService:Create(frame, TweenInfo.new(0.4), {
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.45)
        gui:Destroy()
    end)
end

--==================== REAL-TIME LOAD =====================--
local function RealTimeLoad(url, bar, label, onFinish)
    -- Step 1: init
    label.Text = "Initializing..."
    setProgress(bar, 0.1)
    task.wait(0.1)

    -- Step 2: http download
    label.Text = "Downloading script..."
    setProgress(bar, 0.35)

    local source
    local ok = pcall(function()
        source = game:HttpGet(url)
    end)

    if not ok then
        label.Text = "Download failed"
        setProgress(bar, 1)
        return
    end

    -- Step 3: compile
    label.Text = "Compiling..."
    setProgress(bar, 0.65)
    task.wait(0.1)

    local func
    ok = pcall(function()
        func = loadstring(source)
    end)

    if not ok then
        label.Text = "Compile error"
        setProgress(bar, 1)
        return
    end

    -- Step 4: execute
    label.Text = "Executing..."
    setProgress(bar, 0.9)
    task.wait(0.1)

    pcall(func)

    -- Step 5: done
    label.Text = "Done"
    setProgress(bar, 1)
    task.wait(0.3)

    if onFinish then onFinish() end
end

--==================== MAIN =====================--
if GameInfo then
    local gui, frame, bar, label = CreateGUI("🎮 Game Detected: "..GameInfo.Name)

    task.spawn(function()
        RealTimeLoad(GameInfo.Url, bar, label, function()
            autoHide(gui, frame)
        end)
    end)
else
    local gui, frame, bar, label = CreateGUI("❌ Unsupported Game")
    setProgress(bar, 1)
    autoHide(gui, frame)
end