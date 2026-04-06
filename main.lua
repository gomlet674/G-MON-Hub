-- [[ G-MON HUB UNIVERSAL LOADER - FIXED ]] --

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- =========================
-- CONFIGURATION
-- =========================

-- Menggunakan UniverseId lebih stabil karena tidak berubah antar Sea
local BLOX_FRUIT_UNIVERSE_ID = {"275391552, 4442272183, 7449925010"}
-- ID Game Survive the Apocalypse
local SURVIVE_APOCALYPSE_IDS = {"90148635862803"}

local Scripts = {
    ["Blox Fruits"] = "loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Blox fruit.lua"))()",
    ["Survive the Apocalypse"] = "loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Survive the apocalypse.lua"))()"
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

-- Fungsi HTTP yang lebih kuat
local function safeHttpGet(url)
    local success, result
    
    -- Coba berbagai metode request yang didukung executor
    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request
    
    if requestFunc then
        success, result = pcall(function()
            local response = requestFunc({
                Url = url,
                Method = "GET"
            })
            return response.Body
        end)
    end
    
    -- Jika gagal atau bukan executor premium, gunakan game:HttpGet
    if not success or not result then
        success, result = pcall(function()
            return game:HttpGet(url)
        end)
    end
    
    -- Validasi hasil (Cek jika 404 atau kosong)
    if success and result and not result:find("404: Not Found") and #result > 0 then
        return result
    end
    
    return nil
end

-- =========================
-- DETECTION LOGIC
-- =========================

local function detectGame()
    -- Cek via UniverseId (Sangat Akurat untuk Blox Fruits)
    if game.GameId == BLOX_FRUIT_UNIVERSE_ID then
        return "Blox Fruits"
    end
    
    -- Cek via PlaceId (Untuk Survive the Apocalypse)
    local currentId = game.PlaceId
    for _, id in ipairs(SURVIVE_APOCALYPSE_IDS) do
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
    
    local scriptUrl = Scripts[detectedGameName]
    print("[DEBUG] Fetching URL: " .. scriptUrl) -- Muncul di pencet F9 (Console)
    
    local source = safeHttpGet(scriptUrl)
    
    if source then
        local load = loadstring or load
        if load then
            local success, err = pcall(function()
                local executed = load(source)
                if type(executed) == "function" then
                    -- Jalankan script di thread baru agar tidak mengganggu loader
                    task.spawn(executed)
                else
                    error("Script GitHub tidak mengembalikan fungsi yang valid.")
                end
            end)
            
            if success then
                Notify("SUCCESS", detectedGameName .. " Loaded!")
            else
                warn("Execution Error:", err)
                Notify("ERROR", "Gagal menjalankan script: " .. tostring(err))
            end
        else
            Notify("ERROR", "Executor Anda tidak mendukung Loadstring.")
        end
    else
        -- Jika gagal ambil data
        warn("[Valtrix] Failed to acces the game.")
        Notify("ERROR", "failed connect with GitHub (Check Console/F9)")
    end
else
    Notify("UNKNOWN GAME", "Game not Added. ID: " .. game.PlaceId)
end
