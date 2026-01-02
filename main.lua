--==================================================
-- GMON HUB | FINAL ALL-IN-ONE + Panda Dev
-- Stable GUI • Safe HTTP • Executor Friendly
--==================================================

repeat task.wait() until game:IsLoaded()

--========================
-- GLOBAL CONFIG
--========================
getgenv().GMON_Config = {
    UseJunkie = true,
    JunkieApiKey = "362a06c5-ac47-4e8c-9a2d-c3280728c19b" -- API kamu
}

--========================
-- SERVICES
--========================
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

--========================
-- SAFE NOTIFY
--========================
local function Notify(title, text, time)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = time or 4
        })
    end)
end

Notify("GMON HUB", "Loading GMON HUB...", 3)

--========================
-- SAFE HTTP + LOADSTRING
--========================
local function SafeHttpGet(url)
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    return ok and res or nil
end

local function SafeLoadstring(code)
    if not code then return false end
    local ok, err = pcall(loadstring(code))
    if not ok then
        warn("[GMON HUB] Loadstring error:", err)
    end
    return ok
end

--========================
-- LOAD RAYFIELD UI
--========================
local RayfieldCode = SafeHttpGet(
    "https://raw.githubusercontent.com/shlexware/Rayfield/main/source"
)

if not RayfieldCode then
    Notify("GMON HUB ERROR", "Failed to load UI library", 6)
    return
end

local Rayfield = loadstring(RayfieldCode)()

local Window = Rayfield:CreateWindow({
    Name = "GMON HUB",
    LoadingTitle = "GMON HUB",
    LoadingSubtitle = "Universal",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GMON",
        FileName = "GMON_Config"
    }
})

--========================
-- INFO TAB (ALWAYS SHOW)
--========================
local InfoTab = Window:CreateTab("Info")
InfoTab:CreateSection("GMON HUB Status")

InfoTab:CreateParagraph({
    Title = "Status",
    Content = "GMON HUB Loaded Successfully\nGUI Active\nAPI Safe Mode Enabled"
})

InfoTab:CreateButton({
    Name = "Check API Status",
    Callback = function()
        if getgenv().GMON_Config.UseJunkie then
            Notify("GMON HUB", "Junkie API Enabled", 3)
        else
            Notify("GMON HUB", "Junkie API Disabled", 3)
        end
    end
})

--========================
-- GAME DETECTION
--========================
local PlaceId = game.PlaceId

--==================================================
-- BLOX FRUITS (Paling Atas)
--==================================================
if PlaceId == 2753915549 then
    Notify("GMON HUB", "Blox Fruits Detected", 3)

    local BF_Tab = Window:CreateTab("Blox Fruits")
    BF_Tab:CreateSection("Blox Fruits")

    BF_Tab:CreateButton({
        Name = "Load Blox Fruits Script",
        Callback = function()
            SafeLoadstring(SafeHttpGet("https://pandadevelopment.net/virtual/file/90b056ec53c4074d"))
        end
    })

--==================================================
-- CAR DEALERSHIP TYCOON (Tengah)
--==================================================
elseif PlaceId == 654732683 then
    Notify("GMON HUB", "Car Dealership Tycoon Detected", 3)

    local CDT_Tab = Window:CreateTab("CDT")
    CDT_Tab:CreateSection("Car Dealership Tycoon")

    CDT_Tab:CreateButton({
        Name = "Load CDT Module",
        Callback = function()
            SafeLoadstring(SafeHttpGet("https://pandadevelopment.net/virtual/file/13ccfd83b4a760c8"))
        end
    })

--==================================================
-- BUILD A BOAT (Paling Bawah)
--==================================================
elseif PlaceId == 537413528 then
    Notify("GMON HUB", "Build A Boat Detected", 3)

    local BAB_Tab = Window:CreateTab("Build A Boat")
    BAB_Tab:CreateSection("Build A Boat")

    BAB_Tab:CreateButton({
        Name = "Load Build A Boat Script",
        Callback = function()
            SafeLoadstring(SafeHttpGet("https://pandadevelopment.net/virtual/file/dace186f8425b825"))
        end
    })

--==================================================
-- UNSUPPORTED GAME
--==================================================
else
    Notify("GMON HUB", "Game not supported, GUI still active", 5)
end

--========================
-- FINAL NOTIFY
--========================
Notify("GMON HUB", "Ready to use", 3)