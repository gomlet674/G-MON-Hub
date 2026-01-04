--====================================================
-- GMON HUB - FINAL CORE
-- Executor: Fluxus | Delta | Arceus | Codex
-- UI: Rayfield
--====================================================

print("[GMON] Core loading...")

--================ SAFE SERVICE ======================
local function Svc(name)
    local ok, s = pcall(game.GetService, game, name)
    if not ok then
        warn("[GMON] Missing Service:", name)
        return nil
    end
    return s
end

local Players = Svc("Players")
local ReplicatedStorage = Svc("ReplicatedStorage")
local TweenService = Svc("TweenService")
local RunService = Svc("RunService")
local HttpService = Svc("HttpService")

if not Players then return end
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

--================ GAME DETECT =======================
local PlaceId = game.PlaceId

local GameMap = {
    BloxFruits = {
        2753915549,
        4442272183,
        7449423635
    },
    CarDealership = {654732683},
    BuildABoat = {537413528}
}

local CurrentGame = "Unknown"

local function DetectGame()
    for name, ids in pairs(GameMap) do
        for _, id in pairs(ids) do
            if PlaceId == id then
                return name
            end
        end
    end
    return "Unknown"
end

CurrentGame = DetectGame()
print("[GMON] Game Detected:", CurrentGame)

--================ GLOBAL STATE ======================
_G.GMON = {
    Game = CurrentGame,
    Loaded = true,
    Flags = {},
    Settings = {}
}

--================ LOAD RAYFIELD ====================
local Rayfield
local ok, err = pcall(function()
    Rayfield = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/shlexware/Rayfield/main/source"
    ))()
end)

if not ok then
    warn("[GMON] UI Load Failed")
    warn(err)
    return
end

--================ WINDOW ===========================
local Window = Rayfield:CreateWindow({
    Name = "GMON HUB | FINAL",
    LoadingTitle = "GMON HUB",
    LoadingSubtitle = "Universal Script",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GMON_HUB",
        FileName = "Profile_" .. CurrentGame
    },
    KeySystem = false
})

--================ TABS =============================
local InfoTab = Window:CreateTab("Info", 4483362458)
local GameTab = Window:CreateTab("Game", 4483362458)
local SystemTab = Window:CreateTab("System", 4483362458)

InfoTab:CreateParagraph({
    Title = "GMON HUB",
    Content = "Status: Loaded\nGame: "..CurrentGame..
    "\nExecutor: Universal\nUI: Rayfield"
})

SystemTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(
            PlaceId, LocalPlayer
        )
    end
})

SystemTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = true,
    Callback = function(v)
        _G.GMON.Flags.AntiAFK = v
    end
})

--================ ANTI AFK =========================
LocalPlayer.Idled:Connect(function()
    if _G.GMON.Flags.AntiAFK then
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end
end)

print("[GMON] Core loaded successfully")

--====================================================
-- GMON HUB | BLOX FRUITS MODULE
--====================================================

if _G.GMON.Game ~= "BloxFruits" then
    warn("[GMON] Blox Fruits module skipped")
    return
end

print("[GMON] Loading Blox Fruits module...")

--================ SERVICES ==========================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

--================ SAFE CHARACTER ====================
local function GetChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function GetHRP()
    local c = GetChar()
    return c:WaitForChild("HumanoidRootPart")
end

--================ SETTINGS ==========================
_G.GMON.Settings.BloxFruits = {
    AutoFarm = false,
    FastAttack = true,
    AutoHaki = true,
    AutoStats = false,
    StatType = "Melee",
    WeaponType = "Melee",
    SelectedMob = nil,
    FarmDistance = 30
}

local BF = _G.GMON.Settings.BloxFruits

--================ HELPERS ===========================
local function TweenTo(cf)
    local hrp = GetHRP()
    local dist = (hrp.Position - cf.Position).Magnitude
    local speed = dist / 300
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(speed, Enum.EasingStyle.Linear),
        {CFrame = cf}
    )
    tween:Play()
end

local function EquipWeapon()
    local char = GetChar()
    local backpack = LocalPlayer.Backpack

    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            char.Humanoid:EquipTool(tool)
            break
        end
    end
end

local function Attack()
    if BF.FastAttack then
        VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,0)
        task.wait()
        VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,0)
    end
end

local function EnableHaki()
    if BF.AutoHaki then
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
        end)
    end
end

local function UpgradeStats()
    if not BF.AutoStats then return end
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer(
            "AddPoint",
            BF.StatType,
            1
        )
    end)
end

--================ MOB FIND ==========================
local function FindMob()
    if not BF.SelectedMob then return nil end
    for _, v in pairs(Workspace.Enemies:GetChildren()) do
        if v.Name == BF.SelectedMob
        and v:FindFirstChild("Humanoid")
        and v.Humanoid.Health > 0 then
            return v
        end
    end
end

--================ FARM LOOP =========================
task.spawn(function()
    while task.wait(0.1) do
        if not BF.AutoFarm then continue end

        local mob = FindMob()
        if mob and mob:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local pos = mob.HumanoidRootPart.CFrame * CFrame.new(0, BF.FarmDistance, 0)
                TweenTo(pos)
                EquipWeapon()
                EnableHaki()
                Attack()
            end)
        end

        UpgradeStats()
    end
end)

--================ UI ================================
local BloxTab = GameTab:CreateSection("Blox Fruits | Main")

GameTab:CreateToggle({
    Name = "Auto Farm Mob",
    CurrentValue = false,
    Callback = function(v)
        BF.AutoFarm = v
    end
})

GameTab:CreateToggle({
    Name = "Fast Attack",
    CurrentValue = true,
    Callback = function(v)
        BF.FastAttack = v
    end
})

GameTab:CreateToggle({
    Name = "Auto Haki",
    CurrentValue = true,
    Callback = function(v)
        BF.AutoHaki = v
    end
})

--================ MOB LIST ==========================
local MobList = {}
pcall(function()
    for _, v in pairs(Workspace.Enemies:GetChildren()) do
        if not table.find(MobList, v.Name) then
            table.insert(MobList, v.Name)
        end
    end
end)

GameTab:CreateDropdown({
    Name = "Select Mob",
    Options = MobList,
    CurrentOption = nil,
    Callback = function(v)
        BF.SelectedMob = v
    end
})

--================ STATS =============================
GameTab:CreateToggle({
    Name = "Auto Stats",
    CurrentValue = false,
    Callback = function(v)
        BF.AutoStats = v
    end
})

GameTab:CreateDropdown({
    Name = "Stat Type",
    Options = {"Melee","Defense","Sword","Demon Fruit","Gun"},
    CurrentOption = "Melee",
    Callback = function(v)
        BF.StatType = v
    end
})

print("[GMON] Blox Fruits module loaded")

--====================================================
-- GMON HUB | CAR DEALERSHIP TYCOON MODULE
--====================================================

if _G.GMON.Game ~= "CarDealershipTycoon" then
    warn("[GMON] CDT module skipped")
    return
end

print("[GMON] Loading Car Dealership Tycoon module...")

--================ SERVICES ==========================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

--================ SETTINGS ==========================
_G.GMON.Settings.CDT = {
    AutoBuyLimited = false,
    AutoDrive = false,
    SelectedCar = nil
}

local CDT = _G.GMON.Settings.CDT

--================ SAFE CHECK ========================
if not Remotes then
    warn("[GMON][CDT] Remotes not found")
    return
end

--================ HELPERS ===========================
local function GetCarsFolder()
    return ReplicatedStorage:FindFirstChild("Cars")
end

local function BuyCar(name)
    pcall(function()
        Remotes:WaitForChild("BuyCar"):FireServer(name)
    end)
end

local function IsOwned(carName)
    local owned = LocalPlayer:FindFirstChild("OwnedCars")
    return owned and owned:FindFirstChild(carName)
end

local function GetCarPrice(car)
    return car:GetAttribute("Price") or "Unknown"
end

--================ AUTO BUY LIMITED ==================
task.spawn(function()
    while task.wait(1) do
        if not CDT.AutoBuyLimited then continue end

        local cars = GetCarsFolder()
        if not cars then continue end

        for _, car in pairs(cars:GetChildren()) do
            if car:GetAttribute("IsLimited") == true and not IsOwned(car.Name) then
                BuyCar(car.Name)
            end
        end
    end
end)

--================ AUTO DRIVE ========================
task.spawn(function()
    while task.wait() do
        if not CDT.AutoDrive then continue end
        pcall(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart then
                local vehicle = char.Humanoid.SeatPart.Parent
                if vehicle and vehicle.PrimaryPart then
                    vehicle:SetPrimaryPartCFrame(
                        vehicle.PrimaryPart.CFrame * CFrame.new(0, 0, 10)
                    )
                end
            end
        end)
    end
end)

--================ UI ================================
local CDTTab = GameTab:CreateSection("Car Dealership Tycoon")

GameTab:CreateToggle({
    Name = "Auto Buy Limited Cars",
    CurrentValue = false,
    Callback = function(v)
        CDT.AutoBuyLimited = v
    end
})

--================ CAR LIST ==========================
local CarList = {}
pcall(function()
    local cars = GetCarsFolder()
    if cars then
        for _, car in pairs(cars:GetChildren()) do
            table.insert(CarList, car.Name)
        end
        table.sort(CarList)
    end
end)

GameTab:CreateDropdown({
    Name = "Select Car",
    Options = CarList,
    CurrentOption = nil,
    Callback = function(v)
        CDT.SelectedCar = v
        local cars = GetCarsFolder()
        if cars and cars:FindFirstChild(v) then
            local price = GetCarPrice(cars[v])
            Rayfield:Notify({
                Title = "Car Selected",
                Content = v .. " | Price: $" .. tostring(price),
                Duration = 4
            })
        end
    end
})

GameTab:CreateButton({
    Name = "Buy Selected Car",
    Callback = function()
        if CDT.SelectedCar then
            BuyCar(CDT.SelectedCar)
        end
    end
})

GameTab:CreateToggle({
    Name = "Auto Drive (Money Farm)",
    CurrentValue = false,
    Callback = function(v)
        CDT.AutoDrive = v
    end
})

print("[GMON] Car Dealership Tycoon module loaded")

--====================================================
-- GMON HUB | BUILD A BOAT FOR TREASURE MODULE
--====================================================

if _G.GMON.Game ~= "BuildABoat" then
    warn("[GMON] BABFT module skipped")
    return
end

print("[GMON] Loading Build A Boat module...")

--================ SERVICES ==========================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer

--================ SETTINGS ==========================
_G.GMON.Settings.BABFT = {
    AutoFarm = false,
    GodMode = false,
    Speed = 60
}

local BABFT = _G.GMON.Settings.BABFT

--================ HELPERS ===========================
local function GetChar()
    return LP.Character
end

local function GetHRP()
    local c = GetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local c = GetChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function GetStages()
    local stages = {}
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = string.lower(v.Name)
            if string.find(n, "stage") or string.find(n, "black") then
                table.insert(stages, v)
            end
        end
    end
    return stages
end

local function GetChest()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = string.lower(v.Name)
            if string.find(n, "chest") or string.find(n, "treasure") then
                return v
            end
        end
    end
end

--================ GOD MODE ==========================
task.spawn(function()
    while task.wait(1) do
        if not BABFT.GodMode then continue end
        pcall(function()
            local hum = GetHumanoid()
            if hum then
                hum.MaxHealth = math.huge
                hum.Health = hum.MaxHealth
            end
        end)
    end
end)

--================ AUTO FARM =========================
task.spawn(function()
    while task.wait(0.3) do
        if not BABFT.AutoFarm then continue end
        pcall(function()
            local hrp = GetHRP()
            if not hrp then return end

            local stages = GetStages()
            table.sort(stages, function(a, b)
                return (a.Position - hrp.Position).Magnitude <
                       (b.Position - hrp.Position).Magnitude
            end)

            for _, stage in pairs(stages) do
                if not BABFT.AutoFarm then break end
                hrp.CFrame = stage.CFrame + Vector3.new(0, 5, 0)
                task.wait(0.15)
            end

            local chest = GetChest()
            if chest then
                hrp.CFrame = chest.CFrame + Vector3.new(0, 5, 0)
            end
        end)
    end
end)

--================ SPEED =============================
RunService.Heartbeat:Connect(function()
    if BABFT.AutoFarm then
        local hrp = GetHRP()
        if hrp then
            hrp.Velocity = hrp.CFrame.LookVector * BABFT.Speed
        end
    end
end)

--================ UI ================================
local BABFTTab = GameTab:CreateSection("Build A Boat")

GameTab:CreateToggle({
    Name = "Auto Farm Treasure",
    CurrentValue = false,
    Callback = function(v)
        BABFT.AutoFarm = v
    end
})

GameTab:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Callback = function(v)
        BABFT.GodMode = v
    end
})

GameTab:CreateSlider({
    Name = "Move Speed",
    Range = {20, 150},
    Increment = 5,
    CurrentValue = 60,
    Callback = function(v)
        BABFT.Speed = v
    end
})

print("[GMON] Build A Boat module loaded")

--====================================================
-- GMON HUB FINAL CORE
-- Executor Safe: Fluxus | Delta | Arceus | Codex
--====================================================

print("[GMON] Booting GMON HUB...")

--================ SAFE EXECUTOR CHECK ===============
local function SafePrint(...)
    pcall(function() print(...) end)
end

local function SafeWarn(...)
    pcall(function() warn(...) end)
end

--================ GLOBAL INIT =======================
_G.GMON = _G.GMON or {}
_G.GMON.Settings = _G.GMON.Settings or {}
_G.GMON.Game = "Unknown"

--================ SERVICES ==========================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local LP = Players.LocalPlayer

--================ GAME DETECT =======================
local PlaceId = game.PlaceId

local GameMap = {
    BloxFruits = {2753915549, 4442272183, 7449423635},
    BuildABoat = {537413528, 6872265039},
    CarTycoon = {1554960397, 654732683}
}

local function DetectGame()
    for name, ids in pairs(GameMap) do
        for _, id in pairs(ids) do
            if id == PlaceId then
                return name
            end
        end
    end

    -- Fallback by workspace scan
    if Workspace:FindFirstChild("Enemies") then
        return "BloxFruits"
    end
    if Workspace:FindFirstChild("BoatStages") then
        return "BuildABoat"
    end
    if Workspace:FindFirstChild("Cars") then
        return "CarTycoon"
    end

    return "Unknown"
end

_G.GMON.Game = DetectGame()
SafePrint("[GMON] Detected Game:", _G.GMON.Game)

--================ BASIC UI (RAYFIELD-LIKE) ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GMON_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LP:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.fromScale(0.45, 0.6)
MainFrame.Position = UDim2.fromScale(0.275, 0.2)
MainFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
MainFrame.Active = true
MainFrame.Draggable = true

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1,0,0,40)
Title.BackgroundTransparency = 1
Title.Text = "GMON HUB FINAL"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20

--================ SCROLL CONTENT ====================
local Content = Instance.new("ScrollingFrame", MainFrame)
Content.Position = UDim2.new(0,10,0,50)
Content.Size = UDim2.new(1,-20,1,-60)
Content.CanvasSize = UDim2.new(0,0,2,0)
Content.ScrollBarImageTransparency = 0
Content.ScrollBarThickness = 6
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y

local UIList = Instance.new("UIListLayout", Content)
UIList.Padding = UDim.new(0,8)

--================ UI HELPERS ========================
local function CreateToggle(text, callback)
    local Btn = Instance.new("TextButton", Content)
    Btn.Size = UDim2.new(1,0,0,36)
    Btn.Text = "[ OFF ] "..text
    Btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    Btn.TextColor3 = Color3.new(1,1,1)
    Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 14

    local on = false
    Btn.MouseButton1Click:Connect(function()
        on = not on
        Btn.Text = (on and "[ ON ] " or "[ OFF ] ")..text
        pcall(callback, on)
    end)
end

local function CreateButton(text, callback)
    local Btn = Instance.new("TextButton", Content)
    Btn.Size = UDim2.new(1,0,0,36)
    Btn.Text = text
    Btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    Btn.TextColor3 = Color3.new(1,1,1)
    Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 14

    Btn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)
end

--================ UNIVERSAL BUTTONS =================
CreateButton("Rejoin Server", function()
    TeleportService:Teleport(game.PlaceId, LP)
end)

CreateButton("Destroy UI", function()
    ScreenGui:Destroy()
end)

--================ GAME SPECIFIC =====================
if _G.GMON.Game == "BloxFruits" then
    SafePrint("[GMON] Loading Blox Fruits features...")
    CreateToggle("Auto Farm (Blox Fruits)", function(v)
        _G.GMON.Settings.Blox.AutoFarm = v
    end)
end

if _G.GMON.Game == "BuildABoat" then
    SafePrint("[GMON] Loading Build A Boat features...")
    CreateToggle("Auto Farm Treasure", function(v)
        _G.GMON.Settings.BABFT.AutoFarm = v
    end)
    CreateToggle("God Mode", function(v)
        _G.GMON.Settings.BABFT.GodMode = v
    end)
end

if _G.GMON.Game == "CarTycoon" then
    SafePrint("[GMON] Loading Car Tycoon features...")
    CreateToggle("Auto Drive Car", function(v)
        _G.GMON.Settings.Car.AutoDrive = v
    end)
end

--================ HEARTBEAT SAFETY ==================
RunService.Heartbeat:Connect(function()
    -- prevent idle kick
    pcall(function()
        if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
            LP.Character:FindFirstChildOfClass("Humanoid"):ChangeState(11)
        end
    end)
end)

SafePrint("[GMON] GMON HUB FINAL LOADED SUCCESSFULLY")