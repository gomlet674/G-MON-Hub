--==================== SERVICES ====================--
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

--==================== GMON LOADER ====================--
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "GMON_Loader"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromScale(0.32, 0.08)
frame.Position = UDim2.fromScale(0.34, 0.46)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.AnchorPoint = Vector2.new(0.5,0.5)

local bar = Instance.new("Frame", frame)
bar.Size = UDim2.fromScale(0,1)
bar.BackgroundColor3 = Color3.fromRGB(0,170,255)
bar.BorderSizePixel = 0

local txt = Instance.new("TextLabel", frame)
txt.Size = UDim2.fromScale(1,1)
txt.BackgroundTransparency = 1
txt.TextColor3 = Color3.new(1,1,1)
txt.TextScaled = true
txt.Font = Enum.Font.GothamBold
txt.Text = "GMON Loading 0%"

for i = 1, 100 do
    bar:TweenSize(UDim2.fromScale(i/100,1), "Out", "Linear", 0.015, true)
    txt.Text = "GMON Loading "..i.."%"
    task.wait(0.015)
end

task.wait(0.2)
gui:Destroy()

--==================== NOTIFICATION ====================--
StarterGui:SetCore("SendNotification", {
    Title = "GMON Hub",
    Text = "Loaded Successfully",
    Duration = 5
})

--==================== RAYFIELD ====================--
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "GMON Hub",
    LoadingTitle = "GMON",
    LoadingSubtitle = "Universal Game Loader",
    ConfigurationSaving = { Enabled = false }
})

--==================== PLAYER INFO TAB ====================--
local InfoTab = Window:CreateTab("Player Info", 4483362458)

local function UpdatePlayerInfo()
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")

    InfoTab:CreateLabel("Name : "..player.Name)
    InfoTab:CreateLabel("UserId : "..player.UserId)

    if humanoid then
        InfoTab:CreateLabel("Health : "..math.floor(humanoid.Health))
        InfoTab:CreateLabel("WalkSpeed : "..humanoid.WalkSpeed)
    else
        InfoTab:CreateLabel("Character not loaded")
    end
end

UpdatePlayerInfo()

--==================== GAME LOGIC TABLE ====================--
local Game = {}
local PlaceId = game.PlaceId

--========================================================--
--==================== BLOX FRUIT ========================--
--========================================================--

Game.Blox = {}

function Game.Blox.CreateGUI()
    local Tab = Window:CreateTab("Blox Fruit", 4483362458)

    Tab:CreateToggle({
        Name = "Auto Farm",
        CurrentValue = false,
        Callback = function(v)
            Game.Blox.AutoFarm(v)
        end
    })

    Tab:CreateToggle({
        Name = "Auto Quest",
        CurrentValue = false,
        Callback = function(v)
            Game.Blox.AutoQuest(v)
        end
    })

    Tab:CreateLabel("Status: Ready")
end

-- LOGIC PLACEHOLDER (ISI NANTI)
function Game.Blox.AutoFarm(state)
    print("[Blox] AutoFarm:", state)
end

function Game.Blox.AutoQuest(state)
    print("[Blox] AutoQuest:", state)
end

--========================================================--
--==================== BUILD A BOAT ======================--
--========================================================--

Game.Build = {}

function Game.Build.CreateGUI()
    local Tab = Window:CreateTab("Build A Boat", 4483362458)

    Tab:CreateButton({
        Name = "Auto Farm Gold",
        Callback = function()
            print("[Build] Auto Farm Gold")
        end
    })
end

--========================================================--
--==================== GAME PICKER =======================--
--========================================================--

if PlaceId == 2753915549 or PlaceId == 4442272183 or PlaceId == 7449423635 then
    -- BLOX FRUIT
    Game.Blox.CreateGUI()

elseif PlaceId == 537413528 then
    -- BUILD A BOAT
    Game.Build.CreateGUI()

else
    local Tab = Window:CreateTab("Universal", 4483362458)
    Tab:CreateLabel("Game Not Supported")
end