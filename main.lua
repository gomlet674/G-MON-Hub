--=====================================================
-- GMON HUB Loader (Clean & Readable)
-- Reworked from VexonHub Loader
--=====================================================

repeat task.wait() until game:IsLoaded()

--==================== SERVICES ====================--
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

--==================== NOTIFICATION ====================--
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "GMON HUB",
        Text = "Loader initialized",
        Icon = "http://www.roblox.com/asset/?id=101718004843670",
        Duration = 6
    })
end)

--==================== GLOBAL CONFIG ====================--
-- API KEY digunakan oleh script dari:
-- • Panda Development
-- • Junkie Development
-- • Script analytics / key system internal
getgenv().GMON_Config = {
    api = "362a06c5-ac47-4e8c-9a2d-c3280728c19b", -- Junkie API KEY kamu
    hub_name = "GMON HUB"
}

--==================== SAFE SCRIPT LOADER ====================--
local function LoadScript(url)
    local ok, err = pcall(function()
        loadstring(game:HttpGet(url))()
    end)
    if not ok then
        warn("[GMON HUB] Failed to load:", url)
        warn(err)
    end
end

--==================== GAME DETECTION ====================--
local PlaceId = game.PlaceId

--=====================================================
-- SUPPORTED GAMES
--=====================================================

-- ===== GAME GROUP 1 =====
if PlaceId == 130818724007978
or PlaceId == 12360882630
or PlaceId == 10449761463
or PlaceId == 131048399685555 then

    LoadScript("https://api.junkie-development.de/api/v1/luascripts/public/85619e1c4554cbee0a1324f5510eedde5a7a38dc0f1d55d60a9b26f4fbb23a9d/download")

-- ===== GAME GROUP 2 =====
elseif PlaceId == 142823291
or PlaceId == 71915429981056
or PlaceId == 88471917710381 then

    LoadScript("https://api.junkie-development.de/api/v1/luascripts/public/4e35c43acd744802047a041c304bd57275548c0b5b913d206032590337e2d4ed/download")

-- ===== GAME GROUP 3 =====
elseif PlaceId == 9015014224
or PlaceId == 11520107397
or PlaceId == 6403373529
or PlaceId == 124596094333302 then

    LoadScript("https://pandadevelopment.net/virtual/file/40e75ef02a3f6ed9")

-- ===== WARTYCOON =====
elseif PlaceId == 4639625707 then

    LoadScript("https://raw.githubusercontent.com/HeeditZ/muye-hub/refs/heads/main/muyehub-wartycoon")

-- ===== BUILD A BOAT =====
elseif PlaceId == 537413528 then

    LoadScript("https://pandadevelopment.net/virtual/file/d9b061887be17192")

-- ===== OTHER GAMES =====
elseif PlaceId == 189707 then
    LoadScript("https://pandadevelopment.net/virtual/file/af8f56f8c5f85179")

elseif PlaceId == 76558904092080
or PlaceId == 129009554587176 then

    LoadScript("https://api.junkie-development.de/api/v1/luascripts/public/834553be00018741e606bcde0d7f9b13b5b9c0f9854f7e7db1d6a121cd995734/download")

elseif PlaceId == 3956818381 then
    LoadScript("https://pandadevelopment.net/virtual/file/f7d076b0f9452913")

elseif PlaceId == 18687417158 then
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "GMON HUB",
            Text = "Script temporarily down, loading Universal",
            Duration = 6
        })
    end)
    LoadScript("https://pandadevelopment.net/virtual/file/df4d50aa689f0fc8")

elseif PlaceId == 9391468976 then
    LoadScript("https://api.junkie-development.de/api/v1/luascripts/public/69de86eca233ff49a2340f4d6d51a2fee991dc86f6af8d979a01a1a3b7bce183/download")

elseif PlaceId == 1537690962 then
    LoadScript("https://pandadevelopment.net/virtual/file/df4d50aa689f0fc8")

elseif PlaceId == 126509999114328
or PlaceId == 79546208627805 then

    LoadScript("https://api.junkie-development.de/api/v1/luascripts/public/9da6e21b25cda379726d27a2afa429843b36b1ff165a8d62dd21b92da9079d20/download")

elseif PlaceId == 4924922222 then
    LoadScript("https://api.junkie-development.de/api/v1/luascripts/public/7c9b01fe4315a4eafc27006e7872d91a01b93bfac771fb27039c3e3fda77c797/download")

elseif PlaceId == 109983668079237
or PlaceId == 96342491571673 then

    LoadScript("https://pandadevelopment.net/virtual/file/1a676f54b72bb3f0")

elseif PlaceId == 70876832253163
or PlaceId == 116495829188952 then

    LoadScript("https://pandadevelopment.net/virtual/file/de973c845922198d")

-- ===== UNIVERSAL FALLBACK =====
else
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "GMON HUB",
            Text = "Game not supported, loading Universal GMON HUB",
            Duration = 6
        })
    end)

    LoadScript("https://pandadevelopment.net/virtual/file/df4d50aa689f0fc8")
end

--=====================================================
-- GMON HUB Loader Finished
--=====================================================