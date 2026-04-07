-- [[ G-MON HUB UNIVERSAL LOADER - REFIXED ]] --

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- =========================
-- CONFIGURATION
-- =========================

-- Blox Fruits Universe ID (Satu ID untuk semua Sea)
local BLOX_FRUIT_UNIVERSE_ID = 110991616

-- ID Game Survive the Apocalypse (Gunakan angka, jangan string)
local SURVIVE_APOCALYPSE_IDS = {9098570654}

-- HANYA MASUKKAN LINK RAW SAJA DI SINI
local Scripts = {
    ["Blox Fruits"] = "loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Blox%20fruit.lua"))()",
    ["Survive the Apocalypse"] = "loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Survive%20the%20apocalypse.lua"))()"
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

local function safeHttpGet(url)
    local success, result
    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request
    
    if requestFunc then
        success, result = pcall(function()
            return requestFunc({Url = url, Method = "GET"}).Body
        end)
    end
    
    if not success or not result then
        success, result = pcall(function()
            return game:HttpGet(url)
        end)
    end
    
    return (success and result and #result > 0) and result or nil
end

-- =========================
-- DETECTION LOGIC
-- =========================

local function detectGame()
    -- Cek Blox Fruits via UniverseId
    if game.GameId == BLOX_FRUIT_UNIVERSE_ID then
        return "Blox Fruits"
    end
    
    -- Cek Survive the Apocalypse via PlaceId
    for _, id in ipairs(SURVIVE_APOCALYPSE_IDS) do
        if game.PlaceId == id then 
            return "Survive the Apocalypse" 
        end
    end
    
    return nil
end

-- =========================
-- MAIN EXECUTION
-- =========================

local detectedGameName = detectGame()

if detectedGameName then
    Notify("DETECTED!", "Game: " .. detectedGameName)
    
    local scriptUrl = Scripts[detectedGameName]
    local source = safeHttpGet(scriptUrl)
    
    if source then
        local load = loadstring or load
        if load then
            local success, err = pcall(function()
                local executed = load(source)
                if type(executed) == "function" then
                    task.spawn(executed)
                else
                    error("Script GitHub tidak valid.")
                end
            end)
            
            if success then
                Notify("SUCCESS", detectedGameName .. " Loaded!")
            else
                warn("Execution Error:", err)
                Notify("ERROR", "Script Error! Cek F9")
            end
        else
            Notify("ERROR", "Executor tidak support loadstring.")
        end
    else
        warn("[G-MON] Gagal mengambil data dari GitHub.")
        Notify("ERROR", "Gagal menyambung ke GitHub.")
    end
else
    -- Jika game tidak dikenal, tetap munculkan notifikasi agar kamu tahu script berjalan
    Notify("UNKNOWN GAME", "Game tidak terdaftar. ID: " .. game.PlaceId)
    print("DEBUG: PlaceId anda adalah " .. game.PlaceId)
end
