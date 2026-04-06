-- [[ G-MON HUB UNIVERSAL LOADER ]] --
-- Auto Detect: Blox Fruits & Survive the Apocalypse

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

-- =========================
-- CONFIGURATION
-- =========================

-- ID Game Blox Fruits (Sea 1, 2, 3, dan Pro)
local BloxFruitsIDs = {275391552, 4442272183, 7449925010, 15302685710} 
-- ID Game Survive the Apocalypse
local SurviveApocalypseIDs = {15302685710} -- Ganti/Tambah ID jika ada map lain

local Scripts = {
    ["Blox Fruits"] = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Blox%20fruit.lua",
    ["Survive the Apocalypse"] = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Survive%20the%20apocalypse.lua"
}

-- =========================
-- HELPER FUNCTIONS
-- =========================

local function Notify(title, text)
    print("[G-MON HUB] " .. title .. ": " .. text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 5
        })
    end)
end

local function getHttpRequest()
    return (syn and syn.request) or (http and http.request) or http_request or request or (game and game.HttpGet)
end

local function safeHttpGet(url)
    local req = getHttpRequest()
    if not req then return nil end
    
    local success, result
    if type(req) == "function" and req == game.HttpGet then
        success, result = pcall(function() return game:HttpGet(url) end)
    else
        success, result = pcall(function()
            local res = req({Url = url, Method = "GET"})
            return res.Body
        end)
    end
    return success and result or nil
end

-- =========================
-- DETECTION LOGIC
-- =========================

local function detectGame()
    local currentId = game.PlaceId
    
    -- Cek Blox Fruits
    for _, id in ipairs(BloxFruitsIDs) do
        if currentId == id then return "Blox Fruits" end
    end
    
    -- Cek Survive the Apocalypse
    for _, id in ipairs(SurviveApocalypseIDs) do
        if currentId == id then return "Survive the Apocalypse" end
    end
    
    return nil
end

-- =========================
-- MAIN EXECUTION
-- =========================

local detectedGameName = detectGame()

if detectedGameName then
    Notify("DETECTED!", "Game: " .. detectedGameName)
    Notify("LOADING", "Tunggu sebentar, sedang mengambil script...")
    
    local scriptUrl = Scripts[detectedGameName]
    local source = safeHttpGet(scriptUrl)
    
    if source then
        local load = loadstring or load
        if load then
            local success, err = pcall(function()
                local executed = load(source)
                if type(executed) == "function" then
                    executed()
                end
            end)
            
            if success then
                Notify("SUCCESS", detectedGameName .. " Script Loaded!")
            else
                warn("Error executing script:", err)
                Notify("ERROR", "Gagal menjalankan script.")
            end
        else
            Notify("ERROR", "Executor tidak mendukung loadstring.")
        end
    else
        Notify("ERROR", "Gagal mengambil data dari GitHub.")
    end
else
    Notify("UNKNOWN GAME", "Game tidak terdaftar di G-MON Hub.")
    print("PlaceId Anda:", game.PlaceId)
end
