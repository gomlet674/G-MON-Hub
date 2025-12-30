--[[ 
    TANAKA HUB - CLIENT ONLY
    Rayfield GUI
    Fly + Y Axis Slider
    Anti AFK
    Safe pcall
    No Remote / No Server
]]

-- ================= SERVICES =================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

-- ================= ANTI AFK =================
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- ================= GAME DETECTION =================
local GAME = "UNKNOWN"
local PlaceId = game.PlaceId

if PlaceId == 2753915549 then
    GAME = "BLOX FRUIT"
elseif PlaceId == 1554960397 then
    GAME = "CAR DEALERSHIP"
elseif PlaceId == 537413528 then
    GAME = "BUILD A BOAT"
end

-- ================= LOAD RAYFIELD =================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "G-MON",
    LoadingTitle = "G-MON HUB",
    LoadingSubtitle = GAME,
    ConfigurationSaving = {
        Enabled = false
    }
})

local MainTab = Window:CreateTab("Main")
local MoveTab = Window:CreateTab("Movement")

MainTab:CreateLabel("Game: "..GAME)

-- ================= CHARACTER SAFE GET =================
local function GetChar()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
        return char
    end
    return nil
end

-- ================= FLY SYSTEM =================
local Fly = false
local FlySpeed = 50
local FlyY = 0

MoveTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(v)
        Fly = v
    end
})

MoveTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 150},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(v)
        FlySpeed = v
    end
})

MoveTab:CreateSlider({
    Name = "Fly Y Axis (Up / Down)",
    Range = {-50, 50},
    Increment = 1,
    CurrentValue = 0,
    Callback = function(v)
        FlyY = v
    end
})

-- ================= FLY LOOP =================
RunService.RenderStepped:Connect(function()
    if not Fly then return end

    pcall(function()
        local char = GetChar()
        if not char then return end

        local hrp = char.HumanoidRootPart
        local cam = workspace.CurrentCamera

        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end

        hrp.Velocity = Vector3.new(
            dir.X * FlySpeed,
            FlyY,
            dir.Z * FlySpeed
        )
    end)
end)

-- ================= BLOX FRUIT AUTO FARM =================
local AutoFarm = false

if GAME == "BLOX FRUIT" then
    MainTab:CreateToggle({
        Name = "Auto Farm Enemy",
        CurrentValue = false,
        Callback = function(v)
            AutoFarm = v
        end
    })

    task.spawn(function()
        while task.wait() do
            if not AutoFarm then continue end

            pcall(function()
                local char = GetChar()
                if not char then return end

                for _, mob in pairs(workspace.Enemies:GetChildren()) do
                    if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid")
                        and mob.Humanoid.Health > 0 then
                        char.HumanoidRootPart.CFrame =
                            mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                        break
                    end
                end
            end)
        end
    end)
end

-- ================= BUILD A BOAT AUTO GOLD =================
if GAME == "BUILD A BOAT" then
    local AutoGold = false

    MainTab:CreateToggle({
        Name = "Auto Gold",
        CurrentValue = false,
        Callback = function(v)
            AutoGold = v
        end
    })

    task.spawn(function()
        while task.wait(1) do
            if not AutoGold then continue end

            pcall(function()
                local char = GetChar()
                if not char then return end

                char.HumanoidRootPart.CFrame =
                    workspace.BoatStages.NormalStages.TheEnd.GoldenChest.Trigger.CFrame
            end)
        end
    end)
end

-- ================= NOTIFICATION =================
Rayfield:CreateNotification({
    Title = "G-MON Hub",
    Content = "Loaded Successfully",
    Duration = 4
})
