--[[========================================================
    GMON HUB - CORE FOUNDATION
    Part 1 / Modular Architecture
    Author: GMON
    Status: STABLE | NO GAME CALL | ALL EXECUTOR SAFE
==========================================================]]

--// WAIT GAME
repeat task.wait() until game:IsLoaded()

--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer

--// SAFE CALL
local function SAFE(fn)
    local ok, err = pcall(fn)
    if not ok then
        warn("[GMON SAFE]", err)
    end
end

--// STATE
local GMON = {
    StartTime = os.clock(),
    Game = "Unknown",
    Tabs = {},
    Flags = {},
    Modules = {}
}

--// GAME DETECTION (SAFE)
local function DetectGame()
    local pid = game.PlaceId
    if pid == 2753915549 or pid == 4442272183 or pid == 7449423635 then
        return "Blox Fruits"
    elseif pid == 1554960397 then
        return "Car Dealership Tycoon"
    elseif pid == 537413528 then
        return "Build A Boat"
    end
    return "Unknown"
end

GMON.Game = DetectGame()

--// LOAD RAYFIELD (SAFE)
local Rayfield
SAFE(function()
    Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not Rayfield then
    error("Rayfield failed to load")
end

--// WINDOW
local Window = Rayfield:CreateWindow({
    Name = "GMON HUB | CORE",
    LoadingTitle = "GMON HUB",
    LoadingSubtitle = "Initializing Core",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GMON",
        FileName = "Profile_" .. GMON.Game
    }
})

--// TABS
GMON.Tabs.Main   = Window:CreateTab("Main", 4483362458)
GMON.Tabs.Blox   = Window:CreateTab("Blox Fruits", 4483362458)
GMON.Tabs.Car    = Window:CreateTab("Car Tycoon", 4483362458)
GMON.Tabs.Boat   = Window:CreateTab("Build A Boat", 4483362458)
GMON.Tabs.System = Window:CreateTab("System", 4483362458)

--========================================================
-- STATUS PANEL (DRAGGABLE)
--========================================================
local StatusGui = Instance.new("ScreenGui", LP:WaitForChild("PlayerGui"))
StatusGui.Name = "GMON_Status"
StatusGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", StatusGui)
Frame.Size = UDim2.new(0, 260, 0, 120)
Frame.Position = UDim2.new(0, 20, 0, 200)
Frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0,10)

local function makeLabel(y,text)
    local l = Instance.new("TextLabel", Frame)
    l.Size = UDim2.new(1, -20, 0, 20)
    l.Position = UDim2.new(0, 10, 0, y)
    l.BackgroundTransparency = 1
    l.TextXAlignment = Left
    l.TextColor3 = Color3.new(1,1,1)
    l.Font = Enum.Font.Gotham
    l.TextSize = 13
    l.Text = text
    return l
end

local lblTitle = makeLabel(10, "GMON HUB STATUS")
local lblGame  = makeLabel(35, "Game: " .. GMON.Game)
local lblTime  = makeLabel(60, "Runtime: 00:00")
local lblInfo  = makeLabel(85, "Status: Idle")

--// RUNTIME FIX
task.spawn(function()
    while task.wait(1) do
        local t = math.floor(os.clock() - GMON.StartTime)
        local m = math.floor(t/60)
        local s = t%60
        lblTime.Text = string.format("Runtime: %02d:%02d", m, s)
    end
end)

--========================================================
-- MAIN TAB
--========================================================
GMON.Tabs.Main:CreateParagraph({
    Title = "GMON HUB CORE",
    Content = "Core loaded successfully.\nAll modules will be activated based on detected game."
})

GMON.Tabs.Main:CreateLabel("Detected Game: " .. GMON.Game)

GMON.Tabs.Main:CreateButton({
    Name = "Re-Detect Game",
    Callback = function()
        GMON.Game = DetectGame()
        lblGame.Text = "Game: " .. GMON.Game
        Rayfield:Notify({
            Title = "GMON",
            Content = "Detected: " .. GMON.Game,
            Duration = 3
        })
    end
})

--========================================================
-- SYSTEM TAB (GLOBAL SAFE)
--========================================================
GMON.Tabs.System:CreateSection("System Utilities")

GMON.Tabs.System:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LP)
    end
})

GMON.Tabs.System:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local servers = HttpService:JSONDecode(
            game:HttpGet(
                "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
            )
        )
        for _,v in pairs(servers.data) do
            if v.playing < v.maxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, LP)
                break
            end
        end
    end
})

GMON.Tabs.System:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = true,
    Callback = function(v)
        GMON.Flags.AntiAFK = v
    end
})

LP.Idled:Connect(function()
    if GMON.Flags.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

--========================================================
-- PLACEHOLDER TABS (NO LOGIC YET)
--========================================================
GMON.Tabs.Blox:CreateLabel("Blox Fruits Module - Not Loaded")
GMON.Tabs.Car:CreateLabel("Car Dealership Module - Not Loaded")
GMON.Tabs.Boat:CreateLabel("Build A Boat Module - Not Loaded")

--========================================================
-- INIT DONE
--========================================================
Rayfield:Notify({
    Title = "GMON HUB",
    Content = "Core Loaded Successfully",
    Duration = 4
})

print("[GMON] CORE LOADED OK")

--========================================================
-- GMON HUB - PART 2 : BLOX FRUITS MODULE
-- Style: Isnahamzah-like (Readable, Non-Obfuscated)
--========================================================

if GMON.Game ~= "Blox Fruits" then
    GMON.Tabs.Blox:CreateParagraph({
        Title = "Blox Fruits",
        Content = "This module only loads in Blox Fruits."
    })
    return
end

--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

--// REMOTES (SAFE)
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local CommF = Remotes and Remotes:FindFirstChild("CommF_")

--// CHARACTER
local function GetChar()
    return LP.Character or LP.CharacterAdded:Wait()
end

local function GetHRP()
    local c = GetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

--========================================================
-- BLOX STATE
--========================================================
GMON.Modules.Blox = {
    AutoFarm = false,
    AutoStats = false,
    AutoHaki = true,
    FastAttack = true,
    SelectedMob = nil,
    SelectedWeapon = "Melee",
    FarmDistance = 35,
    Stat = "Melee"
}

local Blox = GMON.Modules.Blox

--========================================================
-- UTILS
--========================================================
local function TweenTo(cf)
    local hrp = GetHRP()
    if not hrp then return end

    local dist = (hrp.Position - cf.Position).Magnitude
    local speed = math.clamp(dist / 300, 0.1, 2)

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(speed, Enum.EasingStyle.Linear),
        {CFrame = cf}
    )
    tween:Play()
end

local function EquipWeapon()
    local char = GetChar()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    for _,tool in pairs(LP.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            if Blox.SelectedWeapon == "Melee" and tool.ToolTip == "Melee" then
                hum:EquipTool(tool)
                return
            elseif tool.ToolTip == Blox.SelectedWeapon then
                hum:EquipTool(tool)
                return
            end
        end
    end
end

local function Click()
    if not Blox.FastAttack then return end
    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,0)
    task.wait()
    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,0)
end

local function EnableHaki()
    if not Blox.AutoHaki then return end
    if CommF then
        pcall(function()
            CommF:InvokeServer("Buso")
        end)
    end
end

local function AddStat()
    if not CommF then return end
    pcall(function()
        CommF:InvokeServer("AddPoint", Blox.Stat, 1)
    end)
end

--========================================================
-- MOB SCAN
--========================================================
local function GetMob()
    if not Blox.SelectedMob then return nil end
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end

    for _,v in pairs(enemies:GetChildren()) do
        if v.Name == Blox.SelectedMob
        and v:FindFirstChild("Humanoid")
        and v.Humanoid.Health > 0
        and v:FindFirstChild("HumanoidRootPart") then
            return v
        end
    end
    return nil
end

--========================================================
-- MAIN FARM LOOP
--========================================================
task.spawn(function()
    while task.wait() do
        if not Blox.AutoFarm then continue end

        local mob = GetMob()
        if mob then
            local hrp = GetHRP()
            if hrp then
                TweenTo(mob.HumanoidRootPart.CFrame * CFrame.new(0, Blox.FarmDistance, 0))
                EquipWeapon()
                EnableHaki()

                if (hrp.Position - mob.HumanoidRootPart.Position).Magnitude < 60 then
                    Click()
                end
            end
        end
    end
end)

--========================================================
-- AUTO STATS LOOP
--========================================================
task.spawn(function()
    while task.wait(0.25) do
        if Blox.AutoStats then
            AddStat()
        end
    end
end)

--========================================================
-- UI : BLOX TAB
--========================================================
local BloxTab = GMON.Tabs.Blox

BloxTab:CreateSection("Auto Farm")

-- MOB LIST
local MobList = {}
if Workspace:FindFirstChild("Enemies") then
    for _,v in pairs(Workspace.Enemies:GetChildren()) do
        if not table.find(MobList, v.Name) then
            table.insert(MobList, v.Name)
        end
    end
end
table.sort(MobList)

BloxTab:CreateDropdown({
    Name = "Select Mob",
    Options = MobList,
    CurrentOption = "",
    Callback = function(v)
        Blox.SelectedMob = v
    end
})

BloxTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Callback = function(v)
        Blox.AutoFarm = v
    end
})

BloxTab:CreateToggle({
    Name = "Fast Attack",
    CurrentValue = true,
    Callback = function(v)
        Blox.FastAttack = v
    end
})

BloxTab:CreateToggle({
    Name = "Auto Haki",
    CurrentValue = true,
    Callback = function(v)
        Blox.AutoHaki = v
    end
})

BloxTab:CreateSlider({
    Name = "Farm Distance",
    Range = {10, 60},
    Increment = 1,
    CurrentValue = 35,
    Callback = function(v)
        Blox.FarmDistance = v
    end
})

--========================================================
-- STATS
--========================================================
BloxTab:CreateSection("Stats")

BloxTab:CreateDropdown({
    Name = "Select Stat",
    Options = {"Melee","Defense","Sword","Gun","Demon Fruit"},
    CurrentOption = "Melee",
    Callback = function(v)
        Blox.Stat = v
    end
})

BloxTab:CreateToggle({
    Name = "Auto Stats",
    CurrentValue = false,
    Callback = function(v)
        Blox.AutoStats = v
    end
})

--========================================================
-- TELEPORT
--========================================================
BloxTab:CreateSection("Teleport")

BloxTab:CreateButton({
    Name = "Teleport Sea 1",
    Callback = function()
        if CommF then CommF:InvokeServer("TravelMain") end
    end
})

BloxTab:CreateButton({
    Name = "Teleport Sea 2",
    Callback = function()
        if CommF then CommF:InvokeServer("TravelDressrosa") end
    end
})

BloxTab:CreateButton({
    Name = "Teleport Sea 3",
    Callback = function()
        if CommF then CommF:InvokeServer("TravelZou") end
    end
})

--========================================================
-- STATUS UPDATE
--========================================================
lblInfo.Text = "Status: Blox Fruits Loaded"

print("[GMON] Blox Fruits module loaded successfully")

--========================================================
-- GMON HUB - PART 3 : CAR DEALERSHIP TYCOON MODULE
--========================================================

if GMON.Game ~= "Car Dealership Tycoon" then
    GMON.Tabs.Car:CreateParagraph({
        Title = "Car Dealership Tycoon",
        Content = "This module only loads in Car Dealership Tycoon."
    })
    return
end

--========================================================
-- SERVICES
--========================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--========================================================
-- PLAYER / CHARACTER
--========================================================
local function GetChar()
    return LP.Character or LP.CharacterAdded:Wait()
end

--========================================================
-- REMOTES (SAFE FIND)
--========================================================
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local BuyRemote = Remotes and Remotes:FindFirstChild("BuyCar")
local DriveRemote = Remotes and Remotes:FindFirstChild("DriveCar")

--========================================================
-- MODULE STATE
--========================================================
GMON.Modules.Car = {
    AutoBuyLimited = false,
    AutoDrive = false,
    SelectedCar = nil,
    DriveSpeed = 60,
    LoopDelay = 1
}

local Car = GMON.Modules.Car

--========================================================
-- CAR LIST SCAN
--========================================================
local CarsFolder = ReplicatedStorage:FindFirstChild("Cars")
local CarList = {}

if CarsFolder then
    for _,v in pairs(CarsFolder:GetChildren()) do
        table.insert(CarList, v.Name)
    end
end
table.sort(CarList)

--========================================================
-- UTIL FUNCTIONS
--========================================================
local function OwnsCar(carName)
    local owned = LP:FindFirstChild("OwnedCars")
    if not owned then return false end
    return owned:FindFirstChild(carName) ~= nil
end

local function GetCarPrice(carName)
    if not CarsFolder then return "N/A" end
    local car = CarsFolder:FindFirstChild(carName)
    if car then
        return car:GetAttribute("Price") or "N/A"
    end
    return "N/A"
end

local function BuyCar(carName)
    if not BuyRemote then return end
    pcall(function()
        BuyRemote:FireServer(carName)
    end)
end

--========================================================
-- AUTO BUY LIMITED LOOP
--========================================================
task.spawn(function()
    while task.wait(Car.LoopDelay) do
        if not Car.AutoBuyLimited then continue end
        if not CarsFolder then continue end

        for _,car in pairs(CarsFolder:GetChildren()) do
            if car:GetAttribute("IsLimited") == true then
                if not OwnsCar(car.Name) then
                    BuyCar(car.Name)
                end
            end
        end
    end
end)

--========================================================
-- AUTO DRIVE LOOP (SAFE)
--========================================================
task.spawn(function()
    while task.wait() do
        if not Car.AutoDrive then continue end

        local char = GetChar()
        local hum = char:FindFirstChildOfClass("Humanoid")

        if hum and hum.SeatPart then
            local seat = hum.SeatPart
            local model = seat:FindFirstAncestorOfClass("Model")

            if model and model.PrimaryPart then
                model:SetPrimaryPartCFrame(
                    model.PrimaryPart.CFrame * CFrame.new(0, 0, -Car.DriveSpeed * 0.01)
                )
            end
        end
    end
end)

--========================================================
-- UI : CAR TAB
--========================================================
local CarTab = GMON.Tabs.Car

CarTab:CreateSection("Auto Buy")

CarTab:CreateToggle({
    Name = "Auto Buy Limited Cars",
    CurrentValue = false,
    Callback = function(v)
        Car.AutoBuyLimited = v
    end
})

CarTab:CreateSection("Car Selector")

CarTab:CreateDropdown({
    Name = "Select Car",
    Options = CarList,
    CurrentOption = "",
    Callback = function(v)
        Car.SelectedCar = v
    end
})

CarTab:CreateButton({
    Name = "Check Car Price",
    Callback = function()
        if not Car.SelectedCar then return end
        local price = GetCarPrice(Car.SelectedCar)
        Rayfield:Notify({
            Title = "Car Info",
            Content = Car.SelectedCar .. " price: $" .. tostring(price),
            Duration = 4
        })
    end
})

CarTab:CreateButton({
    Name = "Buy Selected Car",
    Callback = function()
        if Car.SelectedCar then
            BuyCar(Car.SelectedCar)
        end
    end
})

--========================================================
-- AUTO DRIVE
--========================================================
CarTab:CreateSection("Auto Drive")

CarTab:CreateToggle({
    Name = "Auto Drive",
    CurrentValue = false,
    Callback = function(v)
        Car.AutoDrive = v
    end
})

CarTab:CreateSlider({
    Name = "Drive Speed",
    Range = {20, 200},
    Increment = 5,
    CurrentValue = 60,
    Callback = function(v)
        Car.DriveSpeed = v
    end
})

--========================================================
-- STATUS
--========================================================
lblInfo.Text = "Status: Car Dealership Tycoon Loaded"

print("[GMON] Car Dealership Tycoon module loaded successfully")

--========================================================
-- GMON HUB - PART 4 : BUILD A BOAT FOR TREASURE MODULE
--========================================================

if GMON.Game ~= "Build A Boat For Treasure" then
    GMON.Tabs.Boat:CreateParagraph({
        Title = "Build A Boat For Treasure",
        Content = "This module only loads in Build A Boat For Treasure."
    })
    return
end

--========================================================
-- SERVICES
--========================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

local LP = Players.LocalPlayer

--========================================================
-- STATE
--========================================================
GMON.Modules.Boat = {
    AutoFarm = false,
    AutoStage = false,
    AutoChest = false,
    AntiWater = false,
    NoCollision = false,
    WalkSpeed = 16,
    JumpPower = 50,
    LoopDelay = 0.5
}

local Boat = GMON.Modules.Boat

--========================================================
-- CHARACTER UTILS
--========================================================
local function GetChar()
    return LP.Character or LP.CharacterAdded:Wait()
end

local function GetHRP()
    local char = GetChar()
    return char:WaitForChild("HumanoidRootPart")
end

local function GetHumanoid()
    return GetChar():WaitForChild("Humanoid")
end

--========================================================
-- SAFE TELEPORT
--========================================================
local function SafeTP(cf)
    local hrp = GetHRP()
    hrp.Velocity = Vector3.zero
    hrp.CFrame = cf
end

--========================================================
-- STAGE REFERENCES (SAFE)
--========================================================
local StagesFolder = Workspace:FindFirstChild("BoatStages")
    and Workspace.BoatStages:FindFirstChild("NormalStages")

local EndChest = StagesFolder
    and StagesFolder:FindFirstChild("TheEnd")
    and StagesFolder.TheEnd:FindFirstChild("GoldenChest")
    and StagesFolder.TheEnd.GoldenChest:FindFirstChild("Trigger")

--========================================================
-- AUTO FARM GOLD (STAGES)
--========================================================
task.spawn(function()
    while task.wait(Boat.LoopDelay) do
        if not Boat.AutoFarm then continue end
        if not StagesFolder then continue end

        local hrp = GetHRP()

        -- Disable collision for safety
        if Boat.NoCollision then
            for _,v in pairs(GetChar():GetChildren()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end

        -- Go through all stages safely
        for i = 1, 10 do
            if not Boat.AutoFarm then break end
            local stage = StagesFolder:FindFirstChild("CaveStage"..i)
            if stage and stage:FindFirstChild("DarknessPart") then
                SafeTP(stage.DarknessPart.CFrame + Vector3.new(0,5,0))
                task.wait(0.35)
            end
        end

        -- Go to chest
        if Boat.AutoFarm and EndChest then
            SafeTP(EndChest.CFrame + Vector3.new(0,3,0))
            task.wait(2.5)
        end
    end
end)

--========================================================
-- ANTI WATER
--========================================================
task.spawn(function()
    while task.wait(1) do
        if not Boat.AntiWater then continue end
        if Workspace:FindFirstChild("Water") then
            pcall(function()
                Workspace.Water.CanTouch = false
                Workspace.Water.CanCollide = false
            end)
        end
    end
end)

--========================================================
-- PLAYER MODIFIERS LOOP
--========================================================
task.spawn(function()
    while task.wait() do
        local hum = GetHumanoid()
        hum.WalkSpeed = Boat.WalkSpeed
        hum.JumpPower = Boat.JumpPower
    end
end)

--========================================================
-- ANTI AFK
--========================================================
LP.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

--========================================================
-- UI : BOAT TAB
--========================================================
local BoatTab = GMON.Tabs.Boat

BoatTab:CreateSection("Auto Farm")

BoatTab:CreateToggle({
    Name = "Auto Farm Gold (Full Stages)",
    CurrentValue = false,
    Callback = function(v)
        Boat.AutoFarm = v
    end
})

BoatTab:CreateToggle({
    Name = "No Collision (Safe)",
    CurrentValue = false,
    Callback = function(v)
        Boat.NoCollision = v
    end
})

BoatTab:CreateToggle({
    Name = "Anti Water (God Mode)",
    CurrentValue = false,
    Callback = function(v)
        Boat.AntiWater = v
    end
})

BoatTab:CreateSection("Player")

BoatTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 300},
    Increment = 5,
    CurrentValue = 16,
    Callback = function(v)
        Boat.WalkSpeed = v
    end
})

BoatTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 300},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(v)
        Boat.JumpPower = v
    end
})

BoatTab:CreateSection("World")

BoatTab:CreateButton({
    Name = "Clear Trees & Rocks",
    Callback = function()
        for _,v in pairs(Workspace:GetChildren()) do
            if v.Name == "Tree" or v.Name == "Rock" then
                v:Destroy()
            end
        end
    end
})

BoatTab:CreateButton({
    Name = "Full Bright",
    Callback = function()
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end
})

--========================================================
-- STATUS
--========================================================
lblInfo.Text = "Status: Build A Boat Loaded"
print("[GMON] Build A Boat module loaded successfully")

--========================================================
-- GMON HUB - PART 5 FINAL SYSTEM CORE
--========================================================

--========================================================
-- CORE STATE
--========================================================
GMON.Core = {}
GMON.Runtime = {}
GMON.Profile = {}

GMON.Runtime.Tasks = {}
GMON.Runtime.Alive = true

--========================================================
-- GAME DETECTION (FIXED & SAFE)
--========================================================
local PLACE_ID = game.PlaceId

GMON.GameIdMap = {
    [2753915549] = "Blox Fruits",
    [4442272183] = "Blox Fruits",
    [7449423635] = "Blox Fruits",
    [142823291]  = "Build A Boat For Treasure",
    [654732683]  = "Car Dealership Tycoon"
}

GMON.Game = GMON.GameIdMap[PLACE_ID] or "Unknown"

--========================================================
-- CREATE TABS SAFELY (FIX TAB BLANK)
--========================================================
GMON.Tabs = GMON.Tabs or {}

local function SafeCreateTab(name, icon)
    if GMON.Tabs[name] then return GMON.Tabs[name] end
    local tab = Window:CreateTab(name, icon or 4483362458)
    GMON.Tabs[name] = tab
    return tab
end

SafeCreateTab("System", 4483362458)
SafeCreateTab("Blox Fruits", 4483362458)
SafeCreateTab("Car Dealership", 4483362458)
SafeCreateTab("Build A Boat", 4483362458)

--========================================================
-- SYSTEM TAB
--========================================================
local SystemTab = GMON.Tabs.System

SystemTab:CreateSection("GMON HUB STATUS")

local lblGame = SystemTab:CreateParagraph({
    Title = "Detected Game",
    Content = GMON.Game
})

lblInfo = SystemTab:CreateParagraph({
    Title = "GMON Status",
    Content = "Running"
})

SystemTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
    end
})

SystemTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local Http = game:GetService("HttpService")
        local TPS = game:GetService("TeleportService")
        local Servers = Http:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=Asc&limit=100"
        ))
        for _,s in pairs(Servers.data) do
            if s.playing < s.maxPlayers then
                TPS:TeleportToPlaceInstance(PLACE_ID, s.id)
                break
            end
        end
    end
})

SystemTab:CreateToggle({
    Name = "Anti AFK (Global)",
    CurrentValue = true,
    Callback = function(v)
        GMON.Profile.AntiAFK = v
    end
})

--========================================================
-- GLOBAL ANTI AFK
--========================================================
task.spawn(function()
    local vu = game:GetService("VirtualUser")
    while task.wait(30) do
        if GMON.Profile.AntiAFK then
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end
    end
end)

--========================================================
-- PROFILE SAVE SYSTEM (PER GAME)
--========================================================
local HttpService = game:GetService("HttpService")

local PROFILE_FOLDER = "GMON_HUB"
local PROFILE_FILE = PROFILE_FOLDER.."/"..GMON.Game..".json"

-- create folder
pcall(function()
    if not isfolder(PROFILE_FOLDER) then
        makefolder(PROFILE_FOLDER)
    end
end)

-- SAVE
function GMON.Core:SaveProfile()
    local data = {
        Game = GMON.Game,
        Blox = GMON.Modules.Blox,
        Car = GMON.Modules.Car,
        Boat = GMON.Modules.Boat
    }
    pcall(function()
        writefile(PROFILE_FILE, HttpService:JSONEncode(data))
    end)
end

-- LOAD
function GMON.Core:LoadProfile()
    if not isfile(PROFILE_FILE) then return end
    local raw = readfile(PROFILE_FILE)
    local data = HttpService:JSONDecode(raw)

    if data.Blox and GMON.Modules.Blox then
        for k,v in pairs(data.Blox) do
            GMON.Modules.Blox[k] = v
        end
    end

    if data.Car and GMON.Modules.Car then
        for k,v in pairs(data.Car) do
            GMON.Modules.Car[k] = v
        end
    end

    if data.Boat and GMON.Modules.Boat then
        for k,v in pairs(data.Boat) do
            GMON.Modules.Boat[k] = v
        end
    end
end

-- AUTO SAVE LOOP
task.spawn(function()
    while task.wait(10) do
        GMON.Core:SaveProfile()
    end
end)

-- LOAD AT START
GMON.Core:LoadProfile()

--========================================================
-- RUNTIME TASK MANAGER (FIX LOOP BUG)
--========================================================
function GMON.Runtime:AddTask(name, fn)
    if GMON.Runtime.Tasks[name] then return end
    GMON.Runtime.Tasks[name] = task.spawn(function()
        while GMON.Runtime.Alive do
            local ok,err = pcall(fn)
            if not ok then
                warn("[GMON TASK ERROR]", name, err)
            end
            task.wait()
        end
    end)
end

function GMON.Runtime:StopAll()
    GMON.Runtime.Alive = false
    for _,t in pairs(GMON.Runtime.Tasks) do
        pcall(task.cancel, t)
    end
end

--========================================================
-- GAME MODULE VISIBILITY CONTROL
--========================================================
if GMON.Game ~= "Blox Fruits" then
    GMON.Tabs["Blox Fruits"]:CreateParagraph({
        Title = "Disabled",
        Content = "This tab only works in Blox Fruits."
    })
end

if GMON.Game ~= "Car Dealership Tycoon" then
    GMON.Tabs["Car Dealership"]:CreateParagraph({
        Title = "Disabled",
        Content = "This tab only works in Car Dealership Tycoon."
    })
end

if GMON.Game ~= "Build A Boat For Treasure" then
    GMON.Tabs["Build A Boat"]:CreateParagraph({
        Title = "Disabled",
        Content = "This tab only works in Build A Boat For Treasure."
    })
end

--========================================================
-- SAFE SHUTDOWN
--========================================================
game:BindToClose(function()
    GMON.Core:SaveProfile()
    GMON.Runtime:StopAll()
end)

--========================================================
-- FINAL STATUS
--========================================================
lblInfo.Text = "Status: GMON HUB FULLY LOADED"
print("===================================")
print(" GMON HUB FINAL LOADED SUCCESSFULLY ")
print(" Game:", GMON.Game)
print("===================================")