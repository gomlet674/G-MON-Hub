-- [[ VALTRIX HUB / G-MON HUB - ULTIMATE STABLE BUILD ]] --
-- Fix: Sea 2 Teleport, Safe-Load, & Runtime Protection

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local Main = {}

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
    if not obj then return end
    local prop = obj:IsA("Frame") and "BackgroundTransparency" or (obj:IsA("UIStroke") and "Transparency" or "TextTransparency")
    TweenService:Create(obj, TweenInfo.new(0.6), {[prop] = target}):Play()
end

local function IdentifyGame()
    for name, data in pairs(CONFIG) do
        if table.find(data.Ids, game.PlaceId) then return name, data.ScriptURL end
    end
    return nil, nil
end

-- =========================
-- MAIN START
-- =========================
function Main.Start()
    -- Tunggu Game Load Sempurna (Penting untuk Sea 2)
    if not game:IsLoaded() then game.Loaded:Wait() end
    
    local oldUI = GetGuiParent():FindFirstChild("ValtrixLoader")
    if oldUI then oldUI:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ValtrixLoader"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = GetGuiParent()

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 320, 0, 160)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    MainFrame.BackgroundTransparency = 1
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

    local Stroke = Instance.new("UIStroke", MainFrame)
    Stroke.Color = Color3.fromRGB(138, 43, 226)
    Stroke.Thickness = 2
    Stroke.Transparency = 1

    local StatusLabel = Instance.new("TextLabel", MainFrame)
    StatusLabel.Size = UDim2.new(1, -40, 0, 20)
    StatusLabel.Position = UDim2.new(0, 20, 0, 70)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.GothamMedium
    StatusLabel.Text = "Waiting for Game..."
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatusLabel.TextSize = 14
    StatusLabel.TextTransparency = 1

    local ProgressBar = Instance.new("Frame", MainFrame)
    ProgressBar.Size = UDim2.new(0, 0, 0, 4)
    ProgressBar.Position = UDim2.new(0, 20, 0, 105)
    ProgressBar.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    ProgressBar.BackgroundTransparency = 1
    Instance.new("UICorner", ProgressBar)

    task.spawn(function()
        Fade(MainFrame, 0.05)
        Fade(Stroke, 0)
        Fade(StatusLabel, 0)
        TweenService:Create(ProgressBar, TweenInfo.new(0.6), {BackgroundTransparency = 0}):Play()
        
        task.wait(1)
        StatusLabel.Text = "Identifying Location..."
        local gameName, scriptURL = IdentifyGame()
        
        if gameName then
            StatusLabel.Text = "Loading " .. gameName .. "..."
            StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 150)
            TweenService:Create(ProgressBar, TweenInfo.new(1.5), {Size = UDim2.new(0, 280, 0, 4)}):Play()
            
            -- Download with Cache Buster
            local success, content = pcall(function()
                return game:HttpGet(scriptURL .. "?t=" .. os.time())
            end)

            if success and content then
                StatusLabel.Text = "Finalizing..."
                task.wait(0.5)
                
                -- SAFE EXECUTION WRAPPER
                local func, err = loadstring(content)
                if func then
                    local runSuccess, runError = pcall(func)
                    if not runSuccess then
                        StatusLabel.Text = "Script Error!"
                        warn("[G-MON] Script Runtime Error: " .. tostring(runError))
                    end
                else
                    StatusLabel.Text = "Compile Error!"
                    warn("[G-MON] Compile Error: " .. tostring(err))
                end
            else
                StatusLabel.Text = "Download Failed!"
            end
        else
            StatusLabel.Text = "Game Not Supported!"
        end

        task.wait(2)
        Fade(MainFrame, 1)
        Fade(Stroke, 1)
        Fade(StatusLabel, 1)
        ScreenGui:Destroy()
    end)
end

return Main
