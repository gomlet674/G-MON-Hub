--[[ 
    G-MON HUB
    Client Only Exploit
    Rayfield GUI
    Anti AFK
    Safe pcall
    Fly + Y Axis
    Auto Farm (No Aimbot)
]]

-- ================= SERVICES =================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local LP = Players.LocalPlayer

-- ================= ANTI AFK =================
LP.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- ================= SAFE CHAR =================
local function Char()
    local c = LP.Character
    if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") then
        return c
    end
end

-- ================= GAME DETECTION =================
local GAME = "UNKNOWN"
if game.PlaceId == 2753915549 then
    GAME = "BLOX FRUITS"
elseif game.PlaceId == 1554960397 then
    GAME = "CAR DEALERSHIP TYCOON"
elseif game.PlaceId == 537413528 then
    GAME = "BUILD A BOAT"
end

-- ================= LOAD RAYFIELD =================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "G-MON Hub",
    LoadingTitle = "G-MON Hub",
    LoadingSubtitle = GAME,
    ConfigurationSaving = {Enabled = false}
})

local InfoTab = Window:CreateTab("Info")
local MainTab = Window:CreateTab("Main")
local MoveTab = Window:CreateTab("Movement")

-- ================= INFO =================
InfoTab:CreateParagraph({
    Title = GAME,
    Content =
    GAME == "BLOX FRUITS" and
    "Game RPG farming. Naik level dengan quest, lawan NPC, pindah Sea otomatis."
    or GAME == "CAR DEALERSHIP TYCOON" and
    "Game tycoon mobil. Beli mobil tercepat dan farming money otomatis."
    or GAME == "BUILD A BOAT" and
    "Bangun kapal dan ambil gold dari stage ke stage."
})

-- ================= FLY =================
local Fly, FlySpeed, FlyY = false, 60, 0

MoveTab:CreateToggle({
    Name = "Fly",
    Callback = function(v) Fly = v end
})

MoveTab:CreateSlider({
    Name = "Fly Speed",
    Range = {20,150},
    CurrentValue = 60,
    Callback = function(v) FlySpeed = v end
})

MoveTab:CreateSlider({
    Name = "Y Axis",
    Range = {-60,60},
    CurrentValue = 0,
    Callback = function(v) FlyY = v end
})

RunService.RenderStepped:Connect(function()
    if not Fly then return end
    pcall(function()
        local c = Char()
        if not c then return end
        local cam = workspace.CurrentCamera
        local dir = Vector3.zero

        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end

        c.HumanoidRootPart.Velocity = Vector3.new(
            dir.X * FlySpeed,
            FlyY,
            dir.Z * FlySpeed
        )
    end)
end)

-- ================= BLOX FRUITS =================
if GAME == "BLOX FRUITS" then
    local AutoFarm, FastAttack = false, false

    MainTab:CreateToggle({
        Name = "Auto Farm Quest",
        Callback = function(v) AutoFarm = v end
    })

    MainTab:CreateToggle({
        Name = "Fast Melee Attack",
        Callback = function(v) FastAttack = v end
    })

    task.spawn(function()
        while task.wait(0.3) do
            if not AutoFarm then continue end
            pcall(function()
                local c = Char()
                if not c then return end

                for _, mob in pairs(workspace.Enemies:GetChildren()) do
                    if mob:FindFirstChild("HumanoidRootPart")
                    and mob:FindFirstChild("Humanoid")
                    and mob.Humanoid.Health > 0 then

                        c.HumanoidRootPart.CFrame =
                            mob.HumanoidRootPart.CFrame * CFrame.new(0,0,3)

                        if FastAttack then
                            for i=1,3 do
                                c.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
                            end
                        end
                        break
                    end
                end
            end)
        end
    end)
end

-- ================= CAR DEALERSHIP =================
if GAME == "CAR DEALERSHIP TYCOON" then
    local AutoMoney = false

    MainTab:CreateToggle({
        Name = "Auto Farm Money",
        Callback = function(v) AutoMoney = v end
    })

    task.spawn(function()
        while task.wait(0.2) do
            if not AutoMoney then continue end
            pcall(function()
                local c = Char()
                if not c then return end

                c.HumanoidRootPart.CFrame =
                    CFrame.new(0,-500,0) -- bawah map aman
            end)
        end
    end)
end

-- ================= BUILD A BOAT =================
if GAME == "BUILD A BOAT" then
    local AutoGold = false

    MainTab:CreateToggle({
        Name = "Auto Gold (Stage to Stage)",
        Callback = function(v) AutoGold = v end
    })

    task.spawn(function()
        while task.wait(1) do
            if not AutoGold then continue end
            pcall(function()
                local c = Char()
                if not c then return end

                for _,stage in pairs(workspace.BoatStages:GetChildren()) do
                    if stage:FindFirstChild("Chest") then
                        c.HumanoidRootPart.CFrame =
                            stage.Chest.CFrame * CFrame.new(0,3,0)
                        task.wait(0.3)
                    end
                end
            end)
        end
    end)
end

-- ================= NOTIFY =================
Rayfield:CreateNotification({
    Title = "G-MON Hub",
    Content = "Loaded | Client Only | Safe",
    Duration = 5
})
