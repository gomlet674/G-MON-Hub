--[[
    BUILD A BOAT FOR TREASURE - FULL SCRIPT
    Fitur: Auto Farm Gold, Anti-Water, Player Hacks
    Interface: Orion Library
]]

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "BABFT - Ultimate Farm | Gemini", HidePremium = false, SaveConfig = true, ConfigFolder = "BABFT_Config"})

--// Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

--// Variables
_G.AutoFarm = false
_G.AntiWater = false
_G.WalkSpeed = 16
_G.JumpPower = 50

--// Functions
local function GetGold()
    spawn(function()
        while _G.AutoFarm do
            task.wait(0.1)
            pcall(function()
                local Char = LocalPlayer.Character
                if Char and Char:FindFirstChild("HumanoidRootPart") then
                    -- Matikan Collision agar tidak tersangkut
                    for _, v in pairs(Char:GetChildren()) do
                        if v:IsA("BasePart") then v.CanCollide = false end
                    end
                    
                    -- Melewati setiap Stage (1-10) secara berurutan agar Gold maksimal
                    for i = 1, 10 do
                        if not _G.AutoFarm then break end
                        local Stage = Workspace.BoatStages.NormalStages["CaveStage" .. i].DarknessPart
                        Char.HumanoidRootPart.CFrame = Stage.CFrame
                        task.wait(0.5) -- Jeda antar stage
                    end
                    
                    -- Teleport ke Chest (Peti Akhir)
                    if _G.AutoFarm then
                        local Chest = Workspace.BoatStages.NormalStages.TheEnd.GoldenChest.Trigger
                        Char.HumanoidRootPart.CFrame = Chest.CFrame
                        task.wait(2) -- Menunggu sampai peti terbuka dan reset otomatis
                    end
                end
            end)
        end
    end)
end

--// UI TABS
local MainTab = Window:MakeTab({
	Name = "Auto Farm",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local PlayerTab = Window:MakeTab({
	Name = "Player",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local WorldTab = Window:MakeTab({
	Name = "World",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

--// AUTO FARM SECTION
MainTab:AddSection({
	Name = "Gold Farming"
})

MainTab:AddToggle({
	Name = "Auto Farm Gold",
	Default = false,
	Callback = function(Value)
		_G.AutoFarm = Value
        if Value then GetGold() end
	end    
})

MainTab:AddLabel("Info: Tunggu di stage akhir sampai karakter reset.")

--// PLAYER SECTION
PlayerTab:AddSlider({
	Name = "Walkspeed",
	Min = 16,
	Max = 250,
	Default = 16,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	ValueName = "Speed",
	Callback = function(Value)
		LocalPlayer.Character.Humanoid.WalkSpeed = Value
	end    
})

PlayerTab:AddToggle({
	Name = "Anti-Water (God Mode)",
	Default = false,
	Callback = function(Value)
		_G.AntiWater = Value
        if Value then
            if Workspace:FindFirstChild("Water") then
                Workspace.Water.CanTouch = false
            end
        else
            if Workspace:FindFirstChild("Water") then
                Workspace.Water.CanTouch = true
            end
        end
	end    
})

--// WORLD SECTION
WorldTab:AddButton({
	Name = "Clear All Trees & Rocks",
	Callback = function()
        for _, v in pairs(Workspace:GetChildren()) do
            if v.Name == "Tree" or v.Name == "Rock" then
                v:Destroy()
            end
        end
  	end    
})

WorldTab:AddButton({
	Name = "Day Time (Full Bright)",
	Callback = function()
        game:GetService("Lighting").ClockTime = 14
        game:GetService("Lighting").Brightness = 2
        game:GetService("Lighting").GlobalShadows = false
  	end    
})

--// Anti-AFK (Agar tidak disconnect)
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

OrionLib:Init()
