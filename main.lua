repeat task.wait() until game:IsLoaded()

--==================== SERVICES =====================--
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

--==================== GAME DATABASE =====================--
local Games = {
    [2753915549] = {
        Name = "Blox Fruits",
        Url = "https://pandadevelopment.net/virtual/file/f2e45fc211ee862d"
    }
}

local GameInfo = Games[game.PlaceId]

--==================== GUI =====================--
local function CreateGUI(text)
    local gui = Instance.new("ScreenGui")
    gui.Name = "GMON_Detector"
    gui.IgnoreGuiInset = false
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui

    local frame = Instance.new("Frame", gui)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromScale(0.5, 0.15)
    frame.Size = UDim2.fromOffset(380, 80)
    frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    frame.BackgroundTransparency = 1
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,16)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Transparency = 0.4

    local label = Instance.new("TextLabel", frame)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1,-20,0,30)
    label.Position = UDim2.fromOffset(10,8)
    label.Font = Enum.Font.SourceSans -- FONT AMAN
    label.TextSize = 18
    label.TextColor3 = Color3.new(1,1,1)
    label.TextXAlignment = Left
    label.Text = text

    local barBg = Instance.new("Frame", frame)
    barBg.Position = UDim2.fromOffset(12,52)
    barBg.Size = UDim2.new(1,-24,0,8)
    barBg.BackgroundColor3 = Color3.fromRGB(40,40,40)
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1,0)

    local bar = Instance.new("Frame", barBg)
    bar.Size = UDim2.fromScale(0,1)
    bar.BackgroundColor3 = Color3.fromRGB(0,170,255)
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

    TweenService:Create(frame, TweenInfo.new(0.4), {
        BackgroundTransparency = 0.25
    }):Play()

    return gui, frame, bar, label
end

--==================== PROGRESS =====================--
local function setProgress(bar, value)
    TweenService:Create(bar, TweenInfo.new(0.25), {
        Size = UDim2.fromScale(value,1)
    }):Play()
end

--==================== AUTO HIDE =====================--
local function autoHide(gui, frame)
    task.delay(0.8, function()
        TweenService:Create(frame, TweenInfo.new(0.4), {
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.45)
        gui:Destroy()
    end)
end

--==================== REAL EXECUTION =====================--
local function LoadScript(url, bar, label, onFinish)
    label.Text = "Downloading..."
    setProgress(bar, 0.3)

    local source
    local ok = pcall(function()
        source = game:HttpGet(url)
    end)

    if not ok or not source then
        label.Text = "Download failed"
        setProgress(bar,1)
        return
    end

    label.Text = "Executing..."
    setProgress(bar,0.8)

    local func
    ok = pcall(function()
        func = loadstring(source)
    end)

    if ok and func then
        pcall(func) -- 🔥 EKSEKUSI BENAR
    end

    label.Text = "Done"
    setProgress(bar,1)
    task.wait(0.3)

    if onFinish then onFinish() end
end

--==================== MAIN =====================--
if GameInfo then
    local gui, frame, bar, label =
        CreateGUI("🎮 Game Detected: "..GameInfo.Name)

    task.spawn(function()
        LoadScript(GameInfo.Url, bar, label, function()
            autoHide(gui, frame)
        end)
    end)
else
    local gui, frame, bar, label =
        CreateGUI("❌ Unsupported Game")
    setProgress(bar,1)
    autoHide(gui, frame)
end