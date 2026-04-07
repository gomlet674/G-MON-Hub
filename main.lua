-- [[ G-MON HUB | UNIVERSAL DISPATCHER V2 ]] --
-- Update: April 7, 2026
-- Fokus: Sinkronisasi Loader, Anti-Cache, & UI Bootstrapper

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local Main = {} -- Tabel yang dikirim kembali ke Loader

-- =========================
-- CONFIG (Database ID Game)
-- =========================
local CONFIG = {
    ["Blox Fruits"] = {
        Ids = {944707959, 15302685710, 9014863586}, 
        Type = "UniverseId",
        ScriptURL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Blox-Fruit.lua"
    },
    ["Survive the Apocalypse"] = {
        Ids = {90148635862803, 106132712}, -- Pastikan PlaceId ini sesuai dengan game
        Type = "PlaceId",
        ScriptURL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Survive-the-apocalypse.lua"
    }
}

-- =========================
-- UTILS
-- =========================
local function GetGuiParent()
    local success, res = pcall(function()
        return (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
    end)
    return success and res or LocalPlayer:WaitForChild("PlayerGui")
end

local function Fade(obj, target)
    local prop = obj:IsA("Frame") and "BackgroundTransparency" or (obj:IsA("UIStroke") and "Transparency" or "TextTransparency")
    TweenService:Create(obj, TweenInfo.new(0.6), {[prop] = target}):Play()
end

-- =========================
-- GAME DETECTION LOGIC
-- =========================
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
-- MAIN START (DIPANGGIL LOADER)
-- =========================
function Main.Start()
    -- Cleanup UI Lama
    local oldUI = GetGuiParent():FindFirstChild("ValtrixLoader")
    if oldUI then oldUI:Destroy() end

    -- [1] UI CONSTRUCTION
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ValtrixLoader"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = GetGuiParent()

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 320, 0, 160)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    MainFrame.BorderSizePixel = 0
    MainFrame.BackgroundTransparency = 1 -- Start Hidden
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

    local Stroke = Instance.new("UIStroke", MainFrame)
    Stroke.Color = Color3.fromRGB(138, 43, 226)
    Stroke.Thickness = 2
    Stroke.Transparency = 1 -- Start Hidden

    local Title = Instance.new("TextLabel", MainFrame)
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Position = UDim2.new(0, 0, 0, 15)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBlack
    Title.Text = "G-MON HUB"
    Title.TextColor3 = Color3.fromRGB(138, 43, 226)
    Title.TextSize = 26
    Title.TextTransparency = 1

    local StatusLabel = Instance.new("TextLabel", MainFrame)
    StatusLabel.Size = UDim2.new(1, -40, 0, 20)
    StatusLabel.Position = UDim2.new(0, 20, 0, 70)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.GothamMedium
    StatusLabel.Text = "Initializing..."
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatusLabel.TextSize = 14
    StatusLabel.TextTransparency = 1

    local ProgressBar = Instance.new("Frame", MainFrame)
    ProgressBar.Size = UDim2.new(0, 0, 0, 4)
    ProgressBar.Position = UDim2.new(0, 20, 0, 105)
    ProgressBar.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    ProgressBar.BorderSizePixel = 0
    Instance.new("UICorner", ProgressBar)

    -- [2] BOOTSTRAPPER PROCESS
    task.spawn(function()
        -- Intro Animation
        Fade(MainFrame, 0)
        Fade(Stroke, 0)
        Fade(Title, 0)
        Fade(StatusLabel, 0)
        task.wait(0.8)

        -- Step 1: Detect Game
        StatusLabel.Text = "Detecting Game..."
        local gameName, scriptURL = IdentifyGame()
        task.wait(0.6)

        if not gameName then
            StatusLabel.Text = "Game Not Supported!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            task.wait(2)
        else
            StatusLabel.Text = "Target: " .. gameName
            StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 150)
            TweenService:Create(ProgressBar, TweenInfo.new(1.2), {Size = UDim2.new(0, 280, 0, 4)}):Play()
            task.wait(1.4)

            -- Step 2: Download Script
            StatusLabel.Text = "Fetching Script..."
            local finalURL = scriptURL .. "?t=" .. os.time()
            local success, content = pcall(function() return game:HttpGet(finalURL) end)

            if success and content and #content > 100 then
                StatusLabel.Text = "Executing..."
                StatusLabel.TextColor3 = Color3.fromRGB(138, 43, 226)
                task.wait(0.5)

                -- Step 3: Final Execution
                local func, err = loadstring(content)
                if func then
                    local runOk, runErr = pcall(func)
                    if not runOk then warn("RUNTIME ERR: " .. tostring(runErr)) end
                else
                    warn("COMPILE ERR: " .. tostring(err))
                end
            else
                StatusLabel.Text = "Download Failed!"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
        end

        -- Exit Animation
        task.wait(1.5)
        Fade(MainFrame, 1)
        Fade(Stroke, 1)
        Fade(Title, 1)
        Fade(StatusLabel, 1)
        TweenService:Create(ProgressBar, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        
        task.wait(0.6)
        ScreenGui:Destroy()
    end)
end

return Main -- Mengembalikan table ke Loader untuk dijalankan
