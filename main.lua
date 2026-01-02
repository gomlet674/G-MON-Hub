--=====================================================
-- GMON HUB | Main Loader
-- Deobfuscated & Rebuilt
--=====================================================

repeat task.wait() until game:IsLoaded()

--==================== SERVICES ====================--
local StarterGui = game:GetService("StarterGui")

--==================== NOTIFICATION ====================--
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "GMON HUB",
        Text = "GMON Hub Loaded",
        Icon = "http://www.roblox.com/asset/?id=84519376661277",
        Duration = 8
    })
end)

--==================== GLOBAL CONFIG ====================--
getgenv().GMON_Config = {
    api = "2735e64346625feb685b33b9f52f7d7d7b2743934d52f569bf20e0ed96249920"
}

--==================== SAFE LOAD FUNCTION ====================--
local function SafeLoad(url)
    local ok, err = pcall(function()
        loadstring(game:HttpGet(url))()
    end)
    if not ok then
        warn("[GMON HUB] Failed to load:", url)
        warn(err)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "GMON HUB - Error",
                Text = "Failed to load module",
                Duration = 6
            })
        end)
    end
end

--==================== PLACE ID ====================--
local PlaceId = game.PlaceId

--==================== GAME ROUTER ====================--

-- ===== GROUP 1 =====
if PlaceId == 130818724007978
or PlaceId == 12360882630
or PlaceId == 10449761463
or PlaceId == 131048399685555 then

    SafeLoad("https://api.junkie-development.de/api/v1/luascripts/public/85619e1c4554cbee0a1324f5510eedde5a7a38dc0f1d55d60a9b26f4fbb23a9d/download")

-- ===== GROUP 2 =====
elseif PlaceId == 142823291
or PlaceId == 71915429981056
or PlaceId == 88471917710381 then

    SafeLoad("https://api.junkie-development.de/api/v1/luascripts/public/4e35c43acd744802047a041c304bd57275548c0b5b913d206032590337e2d4ed/download")

-- ===== GROUP 3 =====
elseif PlaceId == 9015014224
or PlaceId == 11520107397
or PlaceId == 6403373529
or PlaceId == 124596094333302 then

    SafeLoad("https://pandadevelopment.net/virtual/file/40e75ef02a3f6ed9")

-- ===== WAR TYCOON =====
elseif PlaceId == 4639625707 then

    SafeLoad("https://raw.githubusercontent.com/HeeditZ/muye-hub/refs/heads/main/muyehub-wartycoon")

-- ===== BUILD A BOAT =====
elseif PlaceId == 537413528 then

    SafeLoad("https://pandadevelopment.net/virtual/file/d9b061887be17192")

-- ===== MISC =====
elseif PlaceId == 189707 then

    SafeLoad("https://pandadevelopment.net/virtual/file/af8f56f8c5f85179")

elseif PlaceId == 76558904092080
or PlaceId == 129009554587176 then

    SafeLoad("https://api.junkie-development.de/api/v1/luascripts/public/834553be00018741e606bcde0d7f9b13b5b9c0f9854f7e7db1d6a121cd995734/download")

elseif PlaceId == 3956818381 then

    SafeLoad("https://pandadevelopment.net/virtual/file/f7d076b0f9452913")

elseif PlaceId == 18687417158 then

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "GMON HUB",
            Text = "Module down, loading universal",
            Duration = 8
        })
    end)

    SafeLoad("https://pandadevelopment.net/virtual/file/df4d50aa689f0fc8")

elseif PlaceId == 9391468976 then

    SafeLoad("https://api.junkie-development.de/api/v1/luascripts/public/69de86eca233ff49a2340f4d6d51a2fee991dc86f6af8d979a01a1a3b7bce183/download")

elseif PlaceId == 1537690962 then

    SafeLoad("https://pandadevelopment.net/virtual/file/df4d50aa689f0fc8")

elseif PlaceId == 126509999114328
or PlaceId == 79546208627805 then

    SafeLoad("https://api.junkie-development.de/api/v1/luascripts/public/9da6e21b25cda379726d27a2afa429843b36b1ff165a8d62dd21b92da9079d20/download")

elseif PlaceId == 4924922222 then

    SafeLoad("https://api.junkie-development.de/api/v1/luascripts/public/7c9b01fe4315a4eafc27006e7872d91a01b93bfac771fb27039c3e3fda77c797/download")

elseif PlaceId == 109983668079237
or PlaceId == 96342491571673 then

    SafeLoad("https://pandadevelopment.net/virtual/file/1a676f54b72bb3f0")

elseif PlaceId == 70876832253163
or PlaceId == 116495829188952 then

    SafeLoad("https://pandadevelopment.net/virtual/file/de973c845922198d")

-- ===== DEFAULT / UNIVERSAL =====
else
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "GMON HUB",
            Text = "Game not supported, loading Universal",
            Duration = 8
        })
    end)

    SafeLoad("https://pandadevelopment.net/virtual/file/df4d50aa689f0fc8")
end

--==================== TRACKING (OPTIONAL) ====================--
SafeLoad("https://rbxhook.cc/lua/track.lua")

--=====================================================
-- GMON HUB | Main.lua finished
--=====================================================