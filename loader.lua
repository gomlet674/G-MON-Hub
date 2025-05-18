-- loader.lua
-- Menunggu game loaded, deteksi nama + player count, lalu panggil G‑Mon‑key.lua
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Notifikasi tengah layar
dofile("rbxassetid://<PATH>/CenterNotifier.lua")  -- optional include

local function notify(text,dur)
    -- bisa panggil fungsi showCenterNotification
    showCenterNotification("Detected", text, dur)
end

-- deteksi game
local ok, info = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Game)
end)
local name = ok and info.Name or MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Place).Name
local count = #Players:GetPlayers()
notify(name .. " | Players: " .. count, 4)

-- tunggu animasi notifikasi selesai
task.wait(4.4)

-- panggil key UI
local keyScript = Instance.new("LocalScript")
keyScript.Source = game:HttpGet("https://raw.githubusercontent.com/.../G-Mon-key.lua", true)
keyScript.Parent = playerGui