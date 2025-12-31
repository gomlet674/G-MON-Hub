-- =====================================================
-- G-MON HUB | SINGLE FILE | ANTI NIL VALUE
-- =====================================================

print("MAIN START")

-- ================= SERVICES =================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-- ================= FLAGS =================
local Flags = {
    AutoFarm = false,
    AutoCar  = false,
    AutoBoat = false
}

-- ================= SAFE EMPTY FUNCTIONS =================
-- (ANTI NIL, AKAN DI-OVERRIDE JIKA GAME COCOK)

local GameFunctions = {
    AutoFarm = function(v) end,
    AutoCar  = function(v) end,
    AutoBoat = function(v) end,
}

-- ================= GAME DETECTION =================
local function LoadGameFunctions()
    print("Detecting game:", PlaceId)

    -- ===== BLOX FRUITS =====
    if PlaceId == 2753915549 or PlaceId == 4442272183 then
        print("Loaded: BLOX FRUITS")

        GameFunctions.AutoFarm = function(v)
            Flags.AutoFarm = v
            print("Blox Fruits AutoFarm:", v)
        end

    -- ===== CAR GAME =====
    elseif PlaceId == 123456789 then
        print("Loaded: CAR GAME")

        GameFunctions.AutoCar = function(v)
            Flags.AutoCar = v
            print("Car Auto:", v)
        end

    -- ===== BOAT GAME =====
    elseif PlaceId == 987654321 then
        print("Loaded: BOAT GAME")

        GameFunctions.AutoBoat = function(v)
            Flags.AutoBoat = v
            print("Boat Auto:", v)
        end

    else
        print("Game not supported, using safe empty functions")
    end
end

LoadGameFunctions()

-- ================= RAYFIELD =================
local Rayfield = loadstring(game:HttpGet(
    "https://sirius.menu/rayfield"
))()

local Window = Rayfield:CreateWindow({
    Name = "G-MON Hub",
    LoadingTitle = "G-MON Hub",
    LoadingSubtitle = "Loaded",
    ConfigurationSaving = {
        Enabled = false
    }
})

print("UI LOADED")

-- ================= TABS =================
local MainTab = Window:CreateTab("Main")

-- ================= UI (AMAN 100%) =================
MainTab:CreateToggle({
    Name = "Auto Farm",
    Callback = function(v)
        pcall(function()
            GameFunctions.AutoFarm(v)
        end)
    end
})

MainTab:CreateToggle({
    Name = "Auto Car",
    Callback = function(v)
        pcall(function()
            GameFunctions.AutoCar(v)
        end)
    end
})

MainTab:CreateToggle({
    Name = "Auto Boat",
    Callback = function(v)
        pcall(function()
            GameFunctions.AutoBoat(v)
        end)
    end
})

-- ================= MAIN LOOP =================
task.spawn(function()
    while task.wait(1) do
        if Flags.AutoFarm then
            -- logic autofarm
        end
        if Flags.AutoCar then
            -- logic autocar
        end
        if Flags.AutoBoat then
            -- logic autoboat
        end
    end
end)