-- [[ VALTRIX HUB - PREMIUM LOADER ]] --
-- Support: All Executors (PC & Mobile)
-- Fitur: Center UI, Auto-Detect, Smooth Animations

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- =========================
-- DATABASE GAME & SCRIPT
-- =========================
local CONFIG = {
    ["Blox Fruits"] = {
        UniverseId = {15302685710}, -- Berlaku untuk Sea 1, 2, 3
        ScriptURL = "loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Blox%20fruit.lua"))()"
    },
    ["Survive the Apocalypse"] = {
        PlaceIds = {90148635862803}, -- ID Game Bertahan dari kiamat
        ScriptURL = "loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Survive%20the%20apocalypse.lua"))()"
    }
}

-- =========================
-- SYSTEM & GUI PROTECTOR
-- =========================
-- Mencari tempat teraman untuk menaruh UI agar tidak terhapus oleh game
local function GetGuiParent()
    local success, parent = pcall(function()
        return (gethui and gethui()) or game:GetService("CoreGui")
    end)
    if not success or not parent then
        parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    return parent
end

-- Menghapus UI Valtrix lama jika script dijalankan ulang
local GuiParent = GetGuiParent()
if GuiParent:FindFirstChild("ValtrixLoader") then
    GuiParent.ValtrixLoader:Destroy()
end

-- =========================
-- MEMBUAT UI (Tengah Layar)
-- =========================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ValtrixLoader"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = GuiParent

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 160)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainFrame.BackgroundTransparency = 1 -- Mulai dengan transparan untuk animasi
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(138, 43, 226) -- Warna ungu Valtrix
UIStroke.Thickness = 2
UIStroke.Transparency = 1
UIStroke.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.Position = UDim2.new(0, 0, 0, 10)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.Text = "VALTRIX"
TitleLabel.TextColor3 = Color3.fromRGB(138, 43, 226)
TitleLabel.TextSize = 28
TitleLabel.TextTransparency = 1
TitleLabel.Parent = MainFrame

local DetectedLabel = Instance.new("TextLabel")
DetectedLabel.Size = UDim2.new(1, 0, 0, 30)
DetectedLabel.Position = UDim2.new(0, 0, 0, 55)
DetectedLabel.BackgroundTransparency = 1
DetectedLabel.Font = Enum.Font.GothamMedium
DetectedLabel.Text = "Detecting Game..."
DetectedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DetectedLabel.TextSize = 16
DetectedLabel.TextTransparency = 1
DetectedLabel.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Position = UDim2.new(0, 0, 0, 110)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Memulai sistem..."
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLabel.TextSize = 14
StatusLabel.TextTransparency = 1
StatusLabel.Parent = MainFrame

-- =========================
-- FUNGSI ANIMASI UI
-- =========================
local function FadeUI(targetTransparency, duration)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(MainFrame, tweenInfo, {BackgroundTransparency = targetTransparency}):Play()
    TweenService:Create(UIStroke, tweenInfo, {Transparency = targetTransparency}):Play()
    TweenService:Create(TitleLabel, tweenInfo, {TextTransparency = targetTransparency}):Play()
    TweenService:Create(DetectedLabel, tweenInfo, {TextTransparency = targetTransparency}):Play()
    TweenService:Create(StatusLabel, tweenInfo, {TextTransparency = targetTransparency}):Play()
    task.wait(duration)
end

-- =========================
-- LOGIKA DETEKSI GAME
-- =========================
local function DetectGame()
    -- Cek Blox Fruits
    if game.GameId == CONFIG["Blox Fruits"].UniverseId then
        return "Blox Fruits", CONFIG["Blox Fruits"].ScriptURL
    end
    
    -- Cek Survive the Apocalypse
    for _, id in ipairs(CONFIG["Survive the Apocalypse"].PlaceIds) do
        if game.PlaceId == id then
            return "Survive the Apocalypse", CONFIG["Survive the Apocalypse"].ScriptURL
        end
    end
    
    return nil, nil
end

-- =========================
-- MAIN EXECUTION
-- =========================
task.spawn(function()
    -- Munculkan UI
    FadeUI(0.1, 0.5)
    task.wait(1)

    local gameName, scriptUrl = DetectGame()

    if gameName then
        -- Game Terdeteksi
        DetectedLabel.Text = "Game Detected: " .. gameName
        DetectedLabel.TextColor3 = Color3.fromRGB(85, 255, 127) -- Hijau
        StatusLabel.Text = "Mengambil script dari server..."
        task.wait(1.5)

        StatusLabel.Text = "Loading " .. gameName .. "..."
        
        -- Mengambil dan Menjalankan Script
        local success, source = pcall(function()
            return game:HttpGet(scriptUrl)
        end)

        if success and source and #source > 0 then
            local loadSuccess, loadError = pcall(function()
                loadstring(source)()
            end)

            if loadSuccess then
                StatusLabel.Text = "Berhasil dimuat!"
                StatusLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
            else
                StatusLabel.Text = "Error: Script Rusak!"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
                warn("[VALTRIX] Execution Error: " .. tostring(loadError))
            end
        else
            StatusLabel.Text = "Gagal mengambil data GitHub!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
        end
    else
        -- Game Tidak Dikenal
        DetectedLabel.Text = "Unknown Game"
        DetectedLabel.TextColor3 = Color3.fromRGB(255, 85, 85) -- Merah
        StatusLabel.Text = "ID: " .. game.PlaceId .. " tidak terdaftar."
        print("[VALTRIX] Game ID belum didaftarkan: " .. game.PlaceId)
    end

    -- Menutup UI perlahan
    task.wait(3)
    FadeUI(1, 0.5)
    ScreenGui:Destroy()
end)
