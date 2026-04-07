-- [[ VALTRIX HUB - PREMIUM LOADER FIXED 100% ANTI-ERROR ]] --

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- =========================
-- DATABASE GAME & SCRIPT
-- =========================
local CONFIG = {
    ["Blox Fruits"] = {
        UniverseId = {9098570654, 15302685710, 9014863586},
        ScriptURL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/refs/heads/main/Blox-Fruit.lua"
    },
    ["Survive the Apocalypse"] = {
        PlaceIds = {90148635862803}, 
        ScriptURL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/refs/heads/main/Survive-the-apocalypse.lua"
    }
}

-- =========================
-- SYSTEM & GUI PROTECTOR
-- =========================
local function GetGuiParent()
    local success, parent = pcall(function()
        return (gethui and gethui()) or game:GetService("CoreGui")
    end)
    return success and parent or LocalPlayer:WaitForChild("PlayerGui")
end

local GuiParent = GetGuiParent()
if GuiParent:FindFirstChild("ValtrixLoader") then
    GuiParent.ValtrixLoader:Destroy()
end

-- =========================
-- UI CONSTRUCTION
-- =========================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ValtrixLoader"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = GuiParent

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 160)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainFrame.BackgroundTransparency = 1
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
-- FUNCTIONS
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
    -- Cek Survive dulu (agar tidak salah jadi Blox Fruits)
    for _, id in ipairs(CONFIG["Survive the Apocalypse"].PlaceIds) do
        if game.PlaceId == id then
            return "Survive the Apocalypse", CONFIG["Survive the Apocalypse"].ScriptURL
        end
    end
    
    -- Cek Blox Fruits (fix table comparison)
    if table.find(CONFIG["Blox Fruits"].UniverseId, game.GameId) then
        return "Blox Fruits", CONFIG["Blox Fruits"].ScriptURL
    end
    return nil, nil
end

-- =========================
-- ANTI-ERROR + RETRY HTTPGET
-- =========================
local function SafeHttpGet(url)
    for attempt = 1, 3 do  -- retry 3 kali kalau gagal koneksi
        local success, result = pcall(function()
            return game:HttpGet(url)
        end)
        if success and result and #result > 100 then
            return true, result
        end
        task.wait(0.8) -- tunggu sebentar sebelum retry
    end
    return false, nil
end

-- =========================
-- EXECUTION (100% ANTI CRASH)
-- =========================
task.spawn(function()
    local successAll, errAll = pcall(function()
        FadeUI(0.1)
        task.wait(1)

        local gameName, scriptUrl = DetectGame()

        if gameName then
            DetectedLabel.Text = "Game Detected: " .. gameName
            DetectedLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
            StatusLabel.Text = "Menghubungi GitHub..."

            local httpSuccess, source = SafeHttpGet(scriptUrl)

            if httpSuccess and source then
                StatusLabel.Text = "Menjalankan loadstring..."
                task.wait(0.5)
                
                -- Loadstring paling stabil & anti-error
                local ok, executionError = pcall(function()
                    loadstring(game:HttpGet(scriptUrl))()
                end)

                if ok then
                    StatusLabel.Text = "Berhasil!"
                    StatusLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
                else
                    StatusLabel.Text = "Script Rusak (Cek F9)"
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
                    warn("[VALTRIX ERROR]: " .. tostring(executionError))
                end
            else
                StatusLabel.Text = "Gagal Koneksi GitHub (Coba Lagi)"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
            end
        else
            DetectedLabel.Text = "Game Tidak Terdaftar"
            StatusLabel.Text = "ID: " .. game.PlaceId
        end
    end)

    -- Anti-crash total: GUI tetap hilang meski ada error besar
    if not successAll then
        warn("[VALTRIX CRITICAL ERROR]: " .. tostring(errAll))
    end

    task.wait(3)
    FadeUI(1)
    task.wait(0.6)
    if ScreenGui and ScreenGui.Parent then
        ScreenGui:Destroy()
    end
end)
