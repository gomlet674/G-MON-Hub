-- [[ VALTRIX HUB - PREMIUM LOADER FIXED ]] --

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- =========================
-- DATABASE GAME & SCRIPT
-- =========================
local CONFIG = {
    ["Blox Fruits"] = {
        UniverseId = {9098570654, 15302685710, 9014863586}, -- Universe ID asli Blox Fruits (Semua Sea)
        ScriptURL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Blox-Fruit.lua"
    },
    ["Survive the Apocalypse"] = {
        -- Masukkan semua ID yang mungkin (PlaceId)
        PlaceIds = {90148635862803}, 
        ScriptURL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Survive-the-apocalypse.lua"
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
-- EXECUTION
-- =========================
task.spawn(function()
    FadeUI(0.1)
    task.wait(1)

    local gameName, scriptUrl = DetectGame()

    if gameName then
        DetectedLabel.Text = "Game Detected: " .. gameName
        DetectedLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
        StatusLabel.Text = "Menghubungi GitHub..."
        
        local success, source = pcall(function()
            return game:HttpGet(scriptUrl)
        end)

        if success and source and #source > 50 then
            StatusLabel.Text = "Menjalankan loadstring..."
            task.wait(0.5)
            
            -- INI ADALAH BAGIAN LOADSTRING NYA
            local function RunScript()
                local loaded, err = loadstring(source)
                if loaded then
                    loaded() -- Menjalankan script yang sudah di-load
                else
                    error(err)
                end
            end

            local ok, executionError = pcall(RunScript)

            if ok then
                StatusLabel.Text = "Berhasil!"
                StatusLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
            else
                StatusLabel.Text = "Script Rusak (Cek F9)!"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
                warn("[VALTRIX ERROR]: " .. tostring(executionError))
            end
        else
            StatusLabel.Text = "File GitHub Tidak Ditemukan!"
        end
    else
        DetectedLabel.Text = "Game Tidak Terdaftar"
        StatusLabel.Text = "ID: " .. game.PlaceId
    end

    task.wait(3)
    FadeUI(1)
    task.wait(0.6)
    ScreenGui:Destroy()
end)
