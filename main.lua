-- [[ VALTRIX HUB ]] --

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- =========================
-- CONFIG
-- =========================
local CONFIG = {
    ["Blox Fruits"] = {
        UniverseId = {9014863586, 15302685710, 9098570654},
        ScriptURL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Blox-Fruit.lua"
    },
    ["Survive the Apocalypse"] = {
        PlaceIds = {90148635862803},
        ScriptURL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Survive-the-apocalypse.lua"
    }
}

-- =========================
-- SAFE GUI PARENT
-- =========================
local function GetGuiParent()
    if typeof(gethui) == "function" then
        local ok, res = pcall(gethui)
        if ok and res then return res end
    end

    local ok, core = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok then return core end

    return LocalPlayer:WaitForChild("PlayerGui")
end

local GuiParent = GetGuiParent()

pcall(function()
    local old = GuiParent:FindFirstChild("ValtrixLoader")
    if old then old:Destroy() end
end)

-- =========================
-- UI
-- =========================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ValtrixLoader"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = GuiParent

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 160)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(15,15,18)
MainFrame.BackgroundTransparency = 1
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,12)

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(138,43,226)
UIStroke.Thickness = 2
UIStroke.Transparency = 1

local function NewLabel(text, y, size, font)
    local L = Instance.new("TextLabel", MainFrame)
    L.Size = UDim2.new(1,0,0,size)
    L.Position = UDim2.new(0,0,0,y)
    L.BackgroundTransparency = 1
    L.Font = font
    L.Text = text
    L.TextSize = size
    L.TextColor3 = Color3.fromRGB(255,255,255)
    L.TextTransparency = 1
    return L
end

local TitleLabel = NewLabel("VALTRIX", 10, 28, Enum.Font.GothamBlack)
TitleLabel.TextColor3 = Color3.fromRGB(138,43,226)

local DetectedLabel = NewLabel("Detecting Game...", 55, 16, Enum.Font.GothamMedium)
local StatusLabel = NewLabel("Memulai sistem...", 110, 14, Enum.Font.Gotham)

-- =========================
-- FADE
-- =========================
local function FadeUI(target)
    local info = TweenInfo.new(0.5)
    for _, obj in ipairs({MainFrame, UIStroke, TitleLabel, DetectedLabel, StatusLabel}) do
        pcall(function()
            if obj:IsA("Frame") then
                TweenService:Create(obj, info, {BackgroundTransparency = target}):Play()
            elseif obj:IsA("UIStroke") then
                TweenService:Create(obj, info, {Transparency = target}):Play()
            else
                TweenService:Create(obj, info, {TextTransparency = target}):Play()
            end
        end)
    end
end

-- =========================
-- DETECT GAME
-- =========================
local function DetectGame()
    for _, id in ipairs(CONFIG["Survive the Apocalypse"].PlaceIds) do
        if game.PlaceId == id then
            return "Survive the Apocalypse", CONFIG["Survive the Apocalypse"].ScriptURL
        end
    end

    if table.find(CONFIG["Blox Fruits"].UniverseId, game.GameId) then
        return "Blox Fruits", CONFIG["Blox Fruits"].ScriptURL
    end

    return nil, nil
end

-- =========================
-- SAFE HTTP
-- =========================
local function SafeHttpGet(url)
    for i = 1, 3 do
        local ok, res = pcall(function()
            return game:HttpGet(url)
        end)

        if ok and type(res) == "string" then
            if #res > 50 and not res:lower():find("<html") then
                return true, res
            end
        end

        task.wait(1)
    end

    return false, nil
end

-- =========================
-- SAFE COMPILE + RUN
-- =========================
local function SafeCompileAndRun(source)
    if type(source) ~= "string" then
        return false, "Source bukan string"
    end

    local clean = source:match("^%s*(.*)$") or source

    if clean == "" then
        return false, "Source kosong"
    end

    if clean:sub(1,1) == "<" then
        return false, "HTML terdeteksi (bukan Lua)"
    end

    local fn, compileErr = loadstring(source)
    if not fn then
        return false, "COMPILE ERROR:\n"..tostring(compileErr)
    end

    local ok, runtimeErr = pcall(fn)
    if not ok then
        return false, "RUNTIME ERROR:\n"..tostring(runtimeErr)
    end

    return true
end

-- =========================
-- MAIN EXECUTION
-- =========================
task.spawn(function()

    local okMain, errMain = pcall(function()

        FadeUI(0.1)
        task.wait(1)

        local gameName, scriptUrl = DetectGame()

        if not gameName then
            DetectedLabel.Text = "Game Tidak Terdaftar"
            StatusLabel.Text = "PlaceId: "..game.PlaceId
            return
        end

        DetectedLabel.Text = "Game: "..gameName
        DetectedLabel.TextColor3 = Color3.fromRGB(85,255,127)
        StatusLabel.Text = "Mengambil script..."

        local okHttp, source = SafeHttpGet(scriptUrl)

        if not okHttp then
            StatusLabel.Text = "Gagal ambil script"
            StatusLabel.TextColor3 = Color3.fromRGB(255,85,85)
            return
        end

        StatusLabel.Text = "Compile & Execute..."

        local okExec, result = SafeCompileAndRun(source)

        if okExec then
            StatusLabel.Text = "Berhasil!"
            StatusLabel.TextColor3 = Color3.fromRGB(85,255,127)
        else
            StatusLabel.Text = "Error Script"
            StatusLabel.TextColor3 = Color3.fromRGB(255,85,85)
            warn("[VALTRIX DEBUG]: "..tostring(result))
        end

    end)

    if not okMain then
        warn("[VALTRIX FATAL]: "..tostring(errMain))
    end

    task.wait(3)
    FadeUI(1)
    task.wait(0.6)

    pcall(function()
        ScreenGui:Destroy()
    end)

end)
