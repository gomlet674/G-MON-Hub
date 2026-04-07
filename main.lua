-- [[ VALTRIX HUB / G-MON HUB - ULTIMATE STABLE BUILD ]] --
-- Fix: Ultra Safe-Load (Blox Fruits Sea 2/3), Anti-Crash, Support All Executors

-- =========================
-- SYSTEM WAIT (CRITICAL FIX)
-- =========================
-- Jangan lakukan apapun sebelum game benar-benar termuat 100%
if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(2) -- Jeda ekstra untuk memastikan aset game berat (seperti Sea 2) selesai dimuat

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Pastikan LocalPlayer sudah ada sebelum melanjutkan
while not LocalPlayer do
    Players.PlayerAdded:Wait()
    LocalPlayer = Players.LocalPlayer
end

local Main = {} -- Tabel wajib agar terhubung dengan Loader

-- =========================
-- CONFIG (Database Game ID)
-- =========================
local CONFIG = {
    ["Blox Fruits"] = {
        Ids = {2753915549, 4442272183, 7449423635, 15302685710}, 
        Type = "PlaceId",
        ScriptURL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Blox-Fruit.lua"
    },
    ["Survive the Apocalypse"] = {
        Ids = {90148635862803, 106132712},
        Type = "PlaceId",
        ScriptURL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Survive-the-apocalypse.lua"
    },
    ["War Tycoon"] = {
        Ids = {6796222220}, 
        Type = "PlaceId",
        ScriptURL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/War-Tycoon.lua"
    },
    ["Build A Boat For Treasure"] = {
        Ids = {537413528}, 
        Type = "PlaceId",
        ScriptURL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Build-A-Boat.lua"
    }
}

-- =========================
-- CORE UTILS
-- =========================
local function GetGuiParent()
    local success, res = pcall(function()
        return (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
    end)
    return success and res or LocalPlayer:WaitForChild("PlayerGui")
end

local function Fade(obj, target)
    if not obj then return end -- Anti-Crash jika UI tiba-tiba hilang
    local prop = obj:IsA("Frame") and "BackgroundTransparency" or (obj:IsA("UIStroke") and "Transparency" or "TextTransparency")
    local tween = TweenService:Create(obj, TweenInfo.new(0.6), {[prop] = target})
    tween:Play()
end

local function IdentifyGame()
    for name, data in pairs(CONFIG) do
        if data.Type == "UniverseId" then
            if table.find(data.Ids, game.GameId) then return name, data.ScriptURL end
        elseif data.Type == "PlaceId" then
            if table.find(data.Ids, game.PlaceId) then return name, data.ScriptURL end
        end
    end
    return nil, nil
end

-- =========================
-- MAIN EXECUTION (DIPANGGIL LOADER)
-- =========================
function Main.Start()
    -- Cleanup UI Lama dengan aman
    local guiParent = GetGuiParent()
    local oldUI = guiParent:FindFirstChild("ValtrixLoader")
    if oldUI then oldUI:Destroy() end

    -- =========================
    -- UI CONSTRUCTION
    -- =========================
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ValtrixLoader"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ResetOnSpawn = false -- Jangan reset saat karakter mati
    ScreenGui.Parent = guiParent

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 320, 0, 160)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    MainFrame.BorderSizePixel = 0
    MainFrame.BackgroundTransparency = 1 

    local Corner = Instance.new("UICorner", MainFrame)
    Corner.CornerRadius = UDim.new(0, 12)

    local Stroke = Instance.new("UIStroke", MainFrame)
    Stroke.Color = Color3.fromRGB(138, 43, 226)
    Stroke.Thickness = 2
    Stroke.Transparency = 1 

    local Title = Instance.new("TextLabel", MainFrame)
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Position = UDim2.new(0, 0, 0, 15)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBlack
    Title.Text = "VALTRIX HUB"
    Title.TextColor3 = Color3.fromRGB(138, 43, 226)
    Title.TextSize = 26
    Title.TextTransparency = 1 

    local StatusLabel = Instance.new("TextLabel", MainFrame)
    StatusLabel.Size = UDim2.new(1, -40, 0, 20)
    StatusLabel.Position = UDim2.new(0, 20, 0, 70)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.GothamMedium
    StatusLabel.Text = "Verifying Environment..."
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatusLabel.TextSize = 14
    StatusLabel.TextTransparency = 1 

    local ProgressBar = Instance.new("Frame", MainFrame)
    ProgressBar.Size = UDim2.new(0, 0, 0, 4)
    ProgressBar.Position = UDim2.new(0, 20, 0, 105)
    ProgressBar.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    ProgressBar.BorderSizePixel = 0
    ProgressBar.BackgroundTransparency = 1 
    Instance.new("UICorner", ProgressBar)

    local function UpdateStatus(txt, color)
        if not StatusLabel then return end
        StatusLabel.Text = txt
        if color then StatusLabel.TextColor3 = color end
    end

    -- =========================
    -- DOWNLOADER ENGINE
    -- =========================
    local function DownloadScript(url)
        local finalURL = url .. "?t=" .. os.time()
        local success, result
        
        for i = 1, 3 do
            UpdateStatus("Fetching Script (" .. i .. "/3)...", Color3.fromRGB(200, 200, 200))
            success, result = pcall(function()
                return game:HttpGet(finalURL)
            end)
            
            -- Pastikan bukan error 404 dari github
            if success and result and #result > 100 and not string.find(result, "404: Not Found") then
                return true, result
            end
            task.wait(2)
        end
        return false, "Failed to download script. Cek koneksi atau link GitHub."
    end

    -- =========================
    -- BOOTSTRAPPER PROCESS
    -- =========================
    task.spawn(function()
        -- Start Intro Animation
        Fade(MainFrame, 0.05)
        Fade(Stroke, 0)
        Fade(Title, 0)
        Fade(StatusLabel, 0)
        TweenService:Create(ProgressBar, TweenInfo.new(0.6), {BackgroundTransparency = 0}):Play()
        task.wait(1)

        -- Step 1: Detect Game
        UpdateStatus("Detecting Game...", nil)
        local gameName, scriptURL = IdentifyGame()
        task.wait(0.5)

        if not gameName then
            UpdateStatus("Game Not Supported!", Color3.fromRGB(255, 80, 80))
            task.wait(3)
        else
            UpdateStatus("Target: " .. gameName, Color3.fromRGB(80, 255, 150))
            TweenService:Create(ProgressBar, TweenInfo.new(1.5), {Size = UDim2.new(0, 280, 0, 4)}):Play()
            task.wait(1.5)

            -- Step 2: Download
            local ok, content = DownloadScript(scriptURL)
            
            if ok then
                UpdateStatus("Executing...", Color3.fromRGB(138, 43, 226))
                task.wait(0.5)
                
                -- Step 3: Run Script (Safe Execution)
                local func, err = loadstring(content)
                if func then
                    -- Bungkus eksekusi dengan pcall untuk mencegah crash di executor
                    local runOk, runErr = pcall(function()
                        func()
                    end)
                    
                    if runOk then
                        UpdateStatus("Success! Enjoy.", Color3.fromRGB(80, 255, 150))
                    else
                        UpdateStatus("Runtime Error!", Color3.fromRGB(255, 80, 80))
                        warn("[G-MON HUB] Target Script Error: " .. tostring(runErr))
                        -- Jika error di sini, masalahnya ada di dalam file Blox-Fruit.lua kamu
                    end
                else
                    UpdateStatus("Compile Error!", Color3.fromRGB(255, 80, 80))
                    warn("[G-MON HUB] Kode GitHub Error: " .. tostring(err))
                end
            else
                UpdateStatus("Download Failed!", Color3.fromRGB(255, 80, 80))
            end
        end

        -- Exit Animation
        task.wait(2.5)
        Fade(MainFrame, 1)
        Fade(Stroke, 1)
        Fade(Title, 1)
        Fade(StatusLabel, 1)
        if ProgressBar then
            TweenService:Create(ProgressBar, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        end
        
        task.wait(0.6)
        if ScreenGui then ScreenGui:Destroy() end
    end)
end

return Main
