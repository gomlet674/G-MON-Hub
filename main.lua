--[[
GMON Hub - Viral Garden Growth Script
Features:
- Garden growing mechanic with plant growth stages
- Auto hatch pets function
- Pet selection mechanism
- Inventory and pet data management
- Fully scripted, event-driven for Roblox game

Author: BLACKBOXAI
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remote Events Setup
local RemoteFolder = Instance.new("Folder", ReplicatedStorage)
RemoteFolder.Name = "GMONHubRemotes"

local RemoteEvents = {}
for _, eventName in pairs({"AutoHatchToggle", "SelectPet", "PlantSeed", "HarvestPlant", "RequestInventory"}) do
    local event = Instance.new("RemoteEvent", RemoteFolder)
    event.Name = eventName
    RemoteEvents[eventName] = event
end

-- Data Storage (simple in-memory for demo purpose, replace with DataStore in production)
local PlayerData = {}

-- Constants
local GROW_TIME = 30 -- Time in seconds for a seed to fully grow
local MAX_PETS = 5

-- Utility Functions
local function createNewPlant(seedName)
    return {
        SeedName = seedName,
        GrowthStartTime = tick(),
        IsReady = false
    }
end

local function createNewPet(petName)
    return {
        PetName = petName,
        Level = 1,
        Experience = 0,
        HatchTime = tick()
    }
end

-- Player Data Initialization
local function initializePlayerData(player)
    PlayerData[player.UserId] = {
        Garden = {}, -- list of plants
        Pets = {}, -- list of pets
        SelectedPet = nil,
        AutoHatchEnabled = false,
        Inventory = {
            Seeds = {
                ["BasicSeed"] = 5,
                ["RareSeed"] = 1
            },
            Pets = {}
        }
    }
end

local function savePlayerData(player)
    -- Placeholder for data saving logic (DataStore integration)
    -- For now, just keep in-memory
end

-- Growth Update Loop
local function updateGrowth(player)
    local data = PlayerData[player.UserId]
    if not data then return end
    local garden = data.Garden
    for i, plant in ipairs(garden) do
        if not plant.IsReady then
            local elapsed = tick() - plant.GrowthStartTime
            if elapsed >= GROW_TIME then
                plant.IsReady = true
            end
        end
    end
end

-- Auto Hatch Logic
local function autoHatchPets(player)
    local data = PlayerData[player.UserId]
    if not data then return end
    if not data.AutoHatchEnabled then return end
    local inventorySeeds = data.Inventory.Seeds
    if not inventorySeeds then return end

    -- Define hatch priority seeds list (could be all available seeds)
    local hatchableSeeds = {"BasicSeed", "RareSeed"}
    for _, seedName in ipairs(hatchableSeeds) do
        if inventorySeeds[seedName] and inventorySeeds[seedName] > 0 then
            -- Hatch a pet
            if #data.Pets < MAX_PETS then
                inventorySeeds[seedName] = inventorySeeds[seedName] - 1
                local newPet = createNewPet(seedName .. "Pet")
                table.insert(data.Pets, newPet)
                data.SelectedPet = newPet -- Auto select the new pet
                print(player.Name .. " auto hatched a pet: " .. newPet.PetName)
                break -- Hatch one pet per cycle
            end
        end
    end
end

-- Player Gardening Actions
local function plantSeed(player, seedName)
    local data = PlayerData[player.UserId]
    if not data then return false, "No player data" end

    local seeds = data.Inventory.Seeds
    if not seeds or not seeds[seedName] or seeds[seedName] <= 0 then
        return false, "No seeds available"
    end

    seeds[seedName] = seeds[seedName] - 1
    local newPlant = createNewPlant(seedName)
    table.insert(data.Garden, newPlant)
    return true, "Seed planted"
end

local function harvestPlant(player, plantIndex)
    local data = PlayerData[player.UserId]
    if not data then return false, "No player data" end
    local garden = data.Garden
    local plant = garden[plantIndex]
    if not plant then return false, "Plant does not exist" end
    if not plant.IsReady then return false, "Plant not ready" end

    -- Give player rewards (e.g., seeds, coins, pet experience)
    local seedName = plant.SeedName
    -- Reward: +1 coins (simple example) and +1 seed of the same type
    local coinReward = 10
    local inventory = data.Inventory
    inventory.Seeds[seedName] = (inventory.Seeds[seedName] or 0) + 1
    -- (In a full game, add player coins, experience, etc. here)

    table.remove(garden, plantIndex)
    return true, ("Plant harvested! You received 1 %s seed and %d coins"):format(seedName, coinReward)
end

-- Pet Selection
local function selectPet(player, petIndex)
    local data = PlayerData[player.UserId]
    if not data then return false, "No player data" end
    local pet = data.Pets[petIndex]
    if not pet then return false, "Pet does not exist" end
    data.SelectedPet = pet
    return true, ("Selected pet: %s"):format(pet.PetName)
end

-- Connection Handlers
local function onPlayerAdded(player)
    initializePlayerData(player)

    -- Auto hatch loop per player
    spawn(function()
        while player.Parent do
            autoHatchPets(player)
            wait(5) -- Auto hatch attempt every 5 seconds
        end
    end)

    -- Growth update loop
    spawn(function()
        while player.Parent do
            updateGrowth(player)
            wait(1)
        end
    end)
end

local function onPlayerRemoving(player)
    savePlayerData(player)
    PlayerData[player.UserId] = nil
end

-- Remote Event Bindings
RemoteEvents.AutoHatchToggle.OnServerEvent:Connect(function(player, enable)
    local data = PlayerData[player.UserId]
    if data then
        data.AutoHatchEnabled = enable and true or false
        print(player.Name .. " Auto Hatch toggled: " .. tostring(data.AutoHatchEnabled))
    end
end)

RemoteEvents.SelectPet.OnServerEvent:Connect(function(player, petIndex)
    local success, message = selectPet(player, petIndex)
    if not success then
        warn(message)
    else
        print(player.Name .. " " .. message)
    end
end)

RemoteEvents.PlantSeed.OnServerEvent:Connect(function(player, seedName)
    local success, message = plantSeed(player, seedName)
    if not success then
        warn(player.Name .. " failed to plant seed: " .. message)
    else
        print(player.Name .. " " .. message)
    end
end)

RemoteEvents.HarvestPlant.OnServerEvent:Connect(function(player, plantIndex)
    local success, message = harvestPlant(player, plantIndex)
    if not success then
        warn(player.Name .. " failed to harvest: " .. message)
    else
        print(player.Name .. " " .. message)
    end
end)

RemoteEvents.RequestInventory.OnServerEvent:Connect(function(player)
    local data = PlayerData[player.UserId]
    if data then
        RemoteEvents.RequestInventory:FireClient(player, data.Inventory, data.Garden, data.Pets, data.SelectedPet)
    end
end)

-- Connect player events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("GMON Hub main.lua script loaded successfully.")
