-- [[ VALTRIX HUB - ALL EXECUTOR SUPPORT ]] --
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until game.Players.LocalPlayer.Character

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "VALTRIX HUB 🚀 | Blox Fruits", HidePremium = false, SaveConfig = true, ConfigFolder = "ValtrixConfig"})

-- [[ GLOBAL SETTINGS ]] --
_G.AutoFarm = false
_G.FastAttack = false
_G.AutoStats = false
_G.SelectedStat = "Melee"
_G.AutoBuso = false
_G.WalkSpeed = 16
_G.JumpPower = 50
_G.ESP_Enabled = false

-- [[ FUNCTIONS ]] --
function Notify(title, text)
    OrionLib:MakeNotification({Name = title, Content = text, Time = 3})
end

-- [[ 1. TAB INFO ]] --
local InfoTab = Window:MakeTab({Name = "Info", Icon = "rbxassetid://4483345998"})
InfoTab:AddLabel("Status: Active")
InfoTab:AddLabel("Version: 1.0 (Stable)")
InfoTab:AddLabel("Support: All Executors")
InfoTab:AddButton({Name = "Copy Discord Link", Callback = function() setclipboard("https://discord.gg/valtrix") Notify("Success", "Link Copied!") end})

-- [[ 2. TAB MAIN ]] --
local MainTab = Window:MakeTab({Name = "Main", Icon = "rbxassetid://4483345998"})
MainTab:AddToggle({Name = "Auto Farm Level", Default = false, Callback = function(Value) _G.AutoFarm = Value end})
MainTab:AddToggle({Name = "Fast Attack", Default = false, Callback = function(Value) _G.FastAttack = Value end})
MainTab:AddToggle({Name = "Auto Buso Haki", Default = false, Callback = function(Value) _G.AutoBuso = Value end})

-- [[ 3. TAB STATS ]] --
local StatsTab = Window:MakeTab({Name = "Stats", Icon = "rbxassetid://4483345998"})
StatsTab:AddDropdown({Name = "Select Stat", Default = "Melee", Options = {"Melee", "Defense", "Sword", "Blox Fruit"}, Callback = function(Value) _G.SelectedStat = Value end})
StatsTab:AddToggle({Name = "Auto Add Stats", Default = false, Callback = function(Value) _G.AutoStats = Value end})

-- [[ 4. TAB ITEM ]] --
local ItemTab = Window:MakeTab({Name = "Item", Icon = "rbxassetid://4483345998"})
ItemTab:AddButton({Name = "Auto Buy Random Fruit", Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Cousin","Buy") end})
ItemTab:AddButton({Name = "Bring All Fruit (Inventory)", Callback = function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("GetInventory") end})

-- [[ 5. TAB PVP ]] --
local PvpTab = Window:MakeTab({Name = "PvP", Icon = "rbxassetid://4483345998"})
PvpTab:AddSlider({Name = "WalkSpeed", Min = 16, Max = 250, Default = 16, Color = Color3.fromRGB(255,255,255), Increment = 1, ValueName = "Speed", Callback = function(Value) _G.WalkSpeed = Value end})
PvpTab:AddSlider({Name = "JumpPower", Min = 50, Max = 500, Default = 50, Color = Color3.fromRGB(255,255,255), Increment = 1, ValueName = "Power", Callback = function(Value) _G.JumpPower = Value end})

-- [[ 6. TAB ESP ]] --
local EspTab = Window:MakeTab({Name = "ESP", Icon = "rbxassetid://4483345998"})
EspTab:AddToggle({Name = "Player ESP", Default = false, Callback = function(Value) _G.ESP_Enabled = Value end})
EspTab:AddLabel("ESP akan menampilkan kotak di sekitar musuh")

-- [[ 7. TAB MISC ]] --
local MiscTab = Window:MakeTab({Name = "Misc", Icon = "rbxassetid://4483345998"})
MiscTab:AddButton({Name = "Server Hop", Callback = function() 
    local PlaceID = game.PlaceId
    local AllIDs = {}
    local function GetServers(cursor)
        local url = "https://games.roblox.com/v1/games/" .. PlaceID .. "/servers/Public?sortOrder=Desc&limit=100"
        if cursor then url = url .. "&cursor=" .. cursor end
        return game:GetService("HttpService"):JSONDecode(game:HttpGet(url))
    end
    local Servers = GetServers()
    game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceID, Servers.data[math.random(1, #Servers.data)].id)
end})
MiscTab:AddButton({Name = "Rejoin Server", Callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer) end})
MiscTab:AddToggle({Name = "Anti-AFK", Default = true, Callback = function(v) _G.AntiAFK = v end})

-- [[ LOGIC LOOP - ANTI CRASH ]] --
spawn(function()
    while task.wait() do
        pcall(function()
            -- Auto Farm Logic
            if _G.AutoFarm then
                game:GetService("VirtualUser"):CaptureController()
                game:GetService("VirtualUser"):Button1Down(Vector2.new(1280, 672))
            end
            -- Auto Stats Logic
            if _G.AutoStats then
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("AddPoint", _G.SelectedStat, 1)
            end
            -- Auto Haki
            if _G.AutoBuso then
                if not game.Players.LocalPlayer.Character:FindFirstChild("HasBuso") then
                    game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Buso")
                end
            end
            -- Movement
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = _G.WalkSpeed
            game.Players.LocalPlayer.Character.Humanoid.JumpPower = _G.JumpPower
        end)
    end
end)

OrionLib:Init()
