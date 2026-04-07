-- [[ VALTRIX HUB - ULTRA STABLE LOADER (FINAL FIXED) ]] --

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- =========================
-- LOCK SYSTEM (ANTI DOUBLE LOAD)
-- =========================
if _G.__VALTRIX_LOADED then
    warn("[VALTRIX] Sudah dijalankan, skip.")
    return
end
_G.__VALTRIX_LOADED = true

-- =========================
-- CONFIG
-- =========================
local CONFIG = {
    ["BLOX"] = {
        Name = "Blox Fruits",
        UniverseId = {9098570654, 15302685710, 9014863586},
        URL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Blox-Fruit.lua"
    },
    ["SURVIVE"] = {
        Name = "Survive the Apocalypse",
        PlaceIds = {90148635862803},
        URL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Survive-the-apocalypse.lua"
    }
}

-- =========================
-- SAFE GUI
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
ScreenGui.Parent = GuiParent

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 160)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(15,15,18)
MainFrame.BackgroundTransparency = 1
Instance.new("UICorner", MainFrame)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1,0,0,40)
Title.Position = UDim2.new(0,0,0,10)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack
Title.Text = "VALTRIX"
Title.TextSize = 28
Title.TextTransparency = 1
Title.TextColor3 = Color3.fromRGB(138,43,226)

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1,0,0,30)
Status.Position = UDim2.new(0,0,0,80)
Status.BackgroundTransparency = 1
Status.Font = Enum.Font.Gotham
Status.Text = "Initializing..."
Status.TextSize = 14
Status.TextTransparency = 1

-- =========================
-- FADE
-- =========================
local function Fade(val)
    for _,v in pairs({MainFrame, Title, Status}) do
        pcall(function()
            TweenService:Create(v, TweenInfo.new(0.5), {
                TextTransparency = val,
                BackgroundTransparency = val
            }):Play()
        end)
    end
end

-- =========================
-- DETECT GAME (HARD LOCK)
-- =========================
local function DetectGame()
    -- PRIORITAS: Survive
    for _,id in ipairs(CONFIG.SURVIVE.PlaceIds) do
        if game.PlaceId == id then
            return CONFIG.SURVIVE
        end
    end

    -- Blox Fruits
    for _,id in ipairs(CONFIG.BLOX.UniverseId) do
        if game.GameId == id then
            return CONFIG.BLOX
        end
    end

    return nil
end

-- =========================
-- SAFE HTTP
-- =========================
local function SafeGet(url)
    for i = 1,3 do
        local ok,res = pcall(function()
            return game:HttpGet(url)
        end)

        if ok and type(res) == "string" then
            if #res > 100 and not res:lower():find("<html") then
                return res
            end
        end

        task.wait(1)
    end
    return nil
end

-- =========================
-- SAFE EXEC
-- =========================
local function Execute(source)
    if not source then
        return false, "Source kosong"
    end

    local fn, err = loadstring(source)
    if not fn then
        return false, "COMPILE:\n"..err
    end

    local ok, err2 = pcall(fn)
    if not ok then
        return false, "RUNTIME:\n"..err2
    end

    return true
end

-- =========================
-- MAIN
-- =========================
task.spawn(function()

    Fade(0.1)
    task.wait(1)

    local gameData = DetectGame()

    if not gameData then
        Status.Text = "Game tidak didukung"
        return
    end

    Status.Text = "Game: "..gameData.Name

    task.wait(0.5)

    Status.Text = "Mengambil script..."

    local src = SafeGet(gameData.URL)

    if not src then
        Status.Text = "Gagal koneksi"
        return
    end

    Status.Text = "Menjalankan..."

    local ok, err = Execute(src)

    if ok then
        Status.Text = "Berhasil!"
    else
        Status.Text = "Script Error"
        warn("[VALTRIX ERROR]:\n"..err)
    end

    task.wait(3)
    Fade(1)
    task.wait(0.5)

    pcall(function()
        ScreenGui:Destroy()
    end)

end)
