-- Rayfield GUI Controller (ON/OFF WORKING)
-- FOR YOUR OWN GAMES ONLY

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Remote setup
local Remote = ReplicatedStorage:FindFirstChild("HubRemote")
if not Remote then
    Remote = Instance.new("RemoteEvent")
    Remote.Name = "HubRemote"
    Remote.Parent = ReplicatedStorage
end

-- GAME DETECTION (ubah PlaceId sesuai game kamu)
local GAME_TYPE = "UNKNOWN"
if game.PlaceId == 2753915549 then
    GAME_TYPE = "BLOX_FRUIT"
elseif game.PlaceId == 1554960397 then
    GAME_TYPE = "CAR_TYCOON"
elseif game.PlaceId == 537413528 then
    GAME_TYPE = "BUILD_A_BOAT_FOR_TREASURE"
end

-- GUI
local Window = Rayfield:CreateWindow({
    Name = "GMON",
    LoadingTitle = "GMON Script",
    LoadingSubtitle = "Logic ON/OFF Aktif",
})

local MainTab = Window:CreateTab("Main")

MainTab:CreateLabel("Game Terdeteksi: "..GAME_TYPE)

-- ===== BLOX FRUIT LOGIC =====
if GAME_TYPE == "BLOX_FRUIT" then
    MainTab:CreateToggle({
        Name = "Auto Farm Nearest Enemy",
        CurrentValue = false,
        Callback = function(v)
            Remote:FireServer("BF_AUTO_FARM", v)
        end
    })
end

-- ===== CAR DEALERSHIP TYCOON LOGIC =====
if GAME_TYPE == "CAR_Dealershil_TYCOON" then
    MainTab:CreateToggle({
        Name = "Auto Farm Money (Car Run)",
        CurrentValue = false,
        Callback = function(v)
            Remote:FireServer("CAR_AUTO_FARM", v)
        end
    })
end

Rayfield:CreateNotification({
    Title = "Ready",
    Content = "Toggle ON/OFF bekerja",
    Duration = 4
})
