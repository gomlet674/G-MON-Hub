-- Main.lua (Client GUI) - Rayfield
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Remote setup (pastikan HubRemote sudah dibuat di server)
local Remote = ReplicatedStorage:WaitForChild("HubRemote")

-- GAME DETECTION
local GAME_TYPE = "UNKNOWN"
if game.PlaceId == 2753915549 then
    GAME_TYPE = "BLOX_FRUIT"
elseif game.PlaceId == 1554960397 then
    GAME_TYPE = "CAR_DEALERSHIP_TYCOON"
elseif game.PlaceId == 537413528 then
    GAME_TYPE = "BUILD_A_BOAT_FOR_TREASURE"
end

-- GUI
local Window = Rayfield:CreateWindow({
    Name = "G-MON",
    LoadingTitle = "G-MON Script",
    LoadingSubtitle = "Welcome To G-MON",
})

local MainTab = Window:CreateTab("Main")

MainTab:CreateLabel("Game Terdeteksi: "..GAME_TYPE)

-- BLOX FRUIT
if GAME_TYPE == "BLOX_FRUIT" then
    MainTab:CreateToggle({
        Name = "Auto Farm Nearest Enemy",
        CurrentValue = false,
        Callback = function(v)
            Remote:FireServer("BF_AUTO_FARM", v)
        end
    })
end

-- CAR DEALERSHIP TYCOON
if GAME_TYPE == "CAR_DEALERSHIP_TYCOON" then
    MainTab:CreateToggle({
        Name = "Auto Farm Money (Car Run)",
        CurrentValue = false,
        Callback = function(v)
            Remote:FireServer("CAR_AUTO_FARM", v)
        end
    })
end

-- BUILD A BOAT FOR TREASURE
if GAME_TYPE == "BUILD_A_BOAT_FOR_TREASURE" then
    MainTab:CreateToggle({
        Name = "Auto Farm Gold", 
        CurrentValue = false, 
        Callback = function(v)
            Remote:FireServer("BOAT_GOLD_FARM", v)
        end
    })
end

-- Notification
Rayfield:CreateNotification({
    Title = "Ready",
    Content = "Toggle ON/OFF bekerja",
    Duration = 4
})
