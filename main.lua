-- [[ G-MON HUB DEBUG LOADER ]] --
print("Checking G-MON Loader...") -- Ini akan muncul di F9 jika script jalan

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- =========================
-- CONFIGURATION
-- =========================

-- Blox Fruits Universe ID
local BLOX_FRUIT_UNIVERSE = 110991616

-- Daftar Place ID untuk Survive the Apocalypse (Gunakan angka asli)
local SURVIVE_IDS = {
    [90148635862803] = true, -- Pastikan ID ini benar
    [15302685710] = true,
    [9098570654] = true
}

-- URL Script (HANYA URL, jangan pakai loadstring di dalam sini)
local SCRIPTS_URL = {
    ["Blox Fruits"] = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Blox fruit.lua",
    ["Survive the Apocalypse"] = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Survive the apocalypse.lua"
}

-- =========================
-- SYSTEM FUNCTIONS
-- =========================

local function SendNotification(title, msg)
    print("[G-MON] " .. title .. ": " .. msg)
    -- Tunggu sampai game siap kirim notifikasi
    task.spawn(function()
        local success = false
        local retry = 0
        while not success and retry < 5 do
            success = pcall(function()
                StarterGui:SetCore("SendNotification", {
                    Title = title,
                    Text = msg,
                    Duration = 5
                })
            end)
            if not success then 
                retry = retry + 1
                task.wait(1) 
            end
        end
    end)
end

local function GetSource(url)
    print("Attempting to download: " .. url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    if success and result and #result > 0 and not result:find("404") then
        return result
    end
    return nil
end

-- =========================
-- MAIN LOGIC
-- =========================

print("Detecting Game...")

local gameName = nil

-- Cek Blox Fruits
if game.GameId == BLOX_FRUIT_UNIVERSE then
    gameName = "Blox Fruits"
-- Cek Survive the Apocalypse
elseif SURVIVE_IDS[game.PlaceId] then
    gameName = "Survive the Apocalypse"
end

if gameName then
    SendNotification("DETECTED", "Game: " .. gameName)
    
    local source = GetSource(SCRIPTS_URL[gameName])
    
    if source then
        SendNotification("LOADING", "Menjalankan Lua...")
        local load = loadstring or load
        local func, err = load(source)
        
        if func then
            task.spawn(func)
            SendNotification("SUCCESS", "Script Berhasil Terbuka!")
        else
            warn("Load Error: " .. tostring(err))
            SendNotification("ERROR", "Script di GitHub ada yang salah (Syntax Error)")
        end
    else
        SendNotification("ERROR", "Link GitHub salah atau File tidak ada!")
    end
else
    -- Jika game tidak ada di daftar
    SendNotification("UNKNOWN", "ID Tidak Terdaftar: " .. tostring(game.PlaceId))
    print("Salin ID ini ke script: " .. tostring(game.PlaceId))
end
