-- [[ VALTRIX HUB - PREMIUM LOADER OPTIMIZED FOR ALL EXECUTORS 2026 ]] --
-- Super compatible dengan Delta (Mobile/PC), Solara, Wave, Fluxus, Xeno, Madium, Velocity, dll.
-- GUI lebih stabil, HttpGet paling aman, loadstring universal, tidak ada fitur experimental.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- =========================
-- DATABASE GAME (SCALABLE & PRIORITAS BENAR)
-- =========================
local CONFIG = {
    ["Survive the Apocalypse"] = {  -- Dicek pertama (hindari bentrok UniverseId)
        DetectionType = "PlaceId",
        Ids = {90148635862803},
        ScriptURL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Survive-the-apocalypse.lua"
    },
    ["Blox Fruits"] = {
        DetectionType = "UniverseId",
        Ids = {9098570654, 15302685710, 9014863586},
        ScriptURL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Blox-Fruit.lua"
    }
}

-- =========================
-- GUI PROTECTOR (MAX COMPATIBILITY)
-- =========================
local function GetGuiParent()
    -- Prioritas: gethui (paling aman di semua executor) → CoreGui → PlayerGui
    local success, parent = pcall(function()
        if gethui then
            return gethui()
        end
        return game:GetService("CoreGui")
    end)
    
    if success and parent then
        return parent
    end
    
    return LocalPlayer:WaitForChild("PlayerGui")
end

local GuiParent = GetGuiParent()
if GuiParent:FindFirstChild("ValtrixLoader") then
    GuiParent.ValtrixLoader:Destroy()
end

-- =========================
-- UI CONSTRUCTION (RINGKAS & STABIL)
-- =========================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ValtrixLoader"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = GuiParent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 160)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainFrame.BackgroundTransparency = 1
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(138, 43, 226)
UIStroke.Thickness = 2
UIStroke.Transparency = 1

local TitleLabel = Instance.new("TextLabel", MainFrame)
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.Position = UDim2.new(0, 0, 0, 10)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.Text = "VALTRIX"
TitleLabel.TextColor3 = Color3.fromRGB(138, 43, 226)
TitleLabel.TextSize = 28
TitleLabel.TextTransparency = 1

local DetectedLabel = Instance.new("TextLabel", MainFrame)
DetectedLabel.Size = UDim2.new(1, 0, 0, 30)
DetectedLabel.Position = UDim2.new(0, 0, 0, 55)
DetectedLabel.BackgroundTransparency = 1
DetectedLabel.Font = Enum.Font.GothamMedium
DetectedLabel.Text = "Detecting Game..."
DetectedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DetectedLabel.TextSize = 16
DetectedLabel.TextTransparency = 1

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Position = UDim2.new(0, 0, 0, 110)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Memulai sistem..."
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLabel.TextSize = 14
StatusLabel.TextTransparency = 1

-- =========================
-- FUNCTIONS (OPTIMIZED)
-- =========================
local function FadeUI(target)
    local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(MainFrame, info, {BackgroundTransparency = target}):Play()
    TweenService:Create(UIStroke, info, {Transparency = target}):Play()
    TweenService:Create(TitleLabel, info, {TextTransparency = target}):Play()
    TweenService:Create(DetectedLabel, info, {TextTransparency = target}):Play()
    TweenService:Create(StatusLabel, info, {TextTransparency = target}):Play()
end

local function DetectGame()
    for gameName, data in pairs(CONFIG) do
        if data.DetectionType == "PlaceId" then
            for _, id in ipairs(data.Ids) do
                if game.PlaceId == id then
                    return gameName, data.ScriptURL
                end
            end
        elseif data.DetectionType == "UniverseId" then
            if table.find(data.Ids, game.GameId) then
                return gameName, data.ScriptURL
            end
        end
    end
    return nil, nil
end

-- =========================
-- EXECUTION (ULTRA STABIL DI SEMUA EXECUTOR)
-- =========================
task.spawn(function()
    FadeUI(0.1)
    task.wait(1)

    local gameName, scriptUrl = DetectGame()

    if gameName then
        DetectedLabel.Text = "Game Detected: " .. gameName
        DetectedLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
        StatusLabel.Text = "Menghubungi GitHub..."

        -- HttpGet paling aman & compatible di semua executor 2026
        local success, source = pcall(function()
            return game:HttpGet(scriptUrl)  -- Tanpa cache flag (paling stabil)
        end)

        if success and source and #source > 100 then
            StatusLabel.Text = "Menjalankan script..."
            task.wait(0.3)

            -- Loadstring paling universal (support Delta, Solara, Wave, Fluxus, dll)
            local ok, executionError = pcall(function()
                loadstring(game:HttpGet(scriptUrl))()
            end)

            if ok then
                StatusLabel.Text = "Berhasil! ✓"
                StatusLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
            else
                StatusLabel.Text = "Script Rusak (Cek F9)"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
                warn("[VALTRIX ERROR]: " .. tostring(executionError))
            end
        else
            StatusLabel.Text = "Gagal mengambil script dari GitHub"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
        end
    else
        DetectedLabel.Text = "Game Tidak Terdaftar"
        StatusLabel.Text = "PlaceId: " .. game.PlaceId
    end

    task.wait(3)
    FadeUI(1)
    task.wait(0.6)
    ScreenGui:Destroy()
end)
