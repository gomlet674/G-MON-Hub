-- [[ UNIVERSAL SCRIPT PICKER & LOADER ]] --
-- Optimizer: Gemini
-- Support: Synapse, Script-Ware, Krnl, Fluxus, Delta, etc.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- =========================
-- CONFIG & REMOTE REPO
-- =========================
-- Kamu bisa menyimpan daftar script di GitHub gist/repo dalam format JSON
local REMOTE_CONFIG_URL = "https://raw.githubusercontent.com/user/repo/main/scripts_list.json" 

local InternalModeMap = {
    [1234567890] = {type = "local", name = "Mode1"},
    [2234567890] = {type = "remote", url = "https://raw.githubusercontent.com/user/repo/main/mode3.lua"},
}

local DefaultMode = { type = "local", name = "Default" }

-- =========================
-- UNIVERSAL HTTP GET
-- =========================
local function getHttpRequest()
    -- Deteksi fungsi request terbaik yang tersedia di executor
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
-- DYNAMIC CODE EXECUTION
-- =========================
local function executeCode(source, identity)
    local load = loadstring or load
    if not load then 
        warn("[!] Executor tidak mendukung loadstring.")
        return nil 
    end
    
    local f, err = load(source)
    if not f then 
        warn("[!] Syntax Error:", err)
        return nil 
    end
    
    local success, response = pcall(f)
    if success then
        return response
    else
        warn("[!] Execution Error:", response)
        return nil
    end
end

-- =========================
-- MODE RESOLVER (The Picker)
-- =========================
local function getTargetConfig()
    -- 1. Cek Remote Config (JSON) jika ada
    local remoteData = safeHttpGet(REMOTE_CONFIG_URL)
    if remoteData then
        local ok, decoded = pcall(function() return HttpService:JSONDecode(remoteData) end)
        if ok and decoded[tostring(game.PlaceId)] then
            return decoded[tostring(game.PlaceId)]
        end
    end

    -- 2. Attribute Override (Untuk Testing)
    local attrMode = workspace:GetAttribute("ForceMode")
    if attrMode then
        return {type = "local", name = attrMode}
    end

    -- 3. Local Mapping
    return InternalModeMap[game.PlaceId] or DefaultMode
end

-- =========================
-- CORE LOADER
-- =========================
local function initialize()
    local config = getTargetConfig()
    local Mode = nil

    print("[+] Memuat Mode:", config.name or "Remote Script")

    if config.type == "local" then
        local ModesFolder = ReplicatedStorage:WaitForChild("UniversalModes", 5)
        local module = ModesFolder and ModesFolder:FindFirstChild(config.name)
        if module and module:IsA("ModuleScript") then
            local ok, res = pcall(require, module)
            Mode = ok and res or nil
        end
    elseif config.type == "remote" then
        local code = safeHttpGet(config.url)
        if code then
            Mode = executeCode(code)
        end
    end

    -- Fallback ke Default jika gagal
    if not Mode then
        warn("[-] Gagal memuat mode utama. Mencoba Default...")
        local defModule = ReplicatedStorage:WaitForChild("UniversalModes"):FindFirstChild("Default")
        if defModule then Mode = require(defModule) end
    end

    return Mode
end

-- =========================
-- EXECUTION & EVENTS
-- =========================
local ActiveMode = initialize()

if type(ActiveMode) == "table" then
    -- Jalankan Start logic
    if ActiveMode.Start then
        task.spawn(function()
            local ok, err = pcall(ActiveMode.Start)
            if not ok then warn("Start Error:", err) end
        end)
    end

    -- Handle Player Join secara otomatis
    local function onPlayerAdded(player)
        if ActiveMode.Init then
            pcall(function() ActiveMode.Init(player) end)
        end
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end
else
    warn("[!] Mode berhasil dimuat tapi tidak mengembalikan Table/Module.")
end
