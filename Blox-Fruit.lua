-- [[ VALTRIX HUB | BLOX FRUITS YOUTUBE EDITION ]] --
-- Support: Delta, Fluxus, Arceus X, Codex, Evon, dll.
-- Status: 100% Undetected & Anti-Crash

-- [1] INITIALIZATION & ANTI-CRASH
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
repeat task.wait() until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

-- [2] ORION UI LIBRARY
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "VALTRIX HUB 🚀 | Premium Blox Fruits", HidePremium = false, SaveConfig = true, ConfigFolder = "ValtrixHub"})

-- [3] GLOBAL VARIABLES
_G.AutoFarm = false
_G.SelectMonster = ""
_G.AutoHaki = true
_G.AutoEquip = true
_G.FastAttack = false
_G.FarmDistance = 3.5

_G.AutoStats = false
_G.SelectStat = "Melee"
_G.StatAmount = 1

_G.ESPPlayer = false
_G.ESPChest = false

-- [4] CORE FUNCTIONS (TWEEN & COMBAT)
-- Smooth Tween (Terbang anti-kick)
local function TweenTo(targetCFrame)
    pcall(function()
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local distance = (hrp.Position - targetCFrame.Position).Magnitude
        local speed = 300 -- Kecepatan terbang (sesuaikan agar tidak kena kick)
        local tweenInfo = TweenInfo.new(distance / speed, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
        tween:Play()
    end)
end

-- Otomatis Pegang Senjata
local function EquipWeapon()
    pcall(function()
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool.ToolTip == "Melee" or tool.ToolTip == "Sword") then
                LocalPlayer.Character.Humanoid:EquipTool(tool)
            end
        end
    end)
end

-- Auto Haki / Buso
local function EnableHaki()
    pcall(function()
        if not LocalPlayer.Character:FindFirstChild("HasBuso") then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
        end
    end)
end

-- Cari Musuh Terdekat
local function GetNearestEnemy()
    local nearestDist = math.huge
    local nearestEnemy = nil
    pcall(function()
        for _, v in pairs(workspace.Enemies:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
                if _G.SelectMonster == "" or v.Name == _G.SelectMonster then
                    local dist = (LocalPlayer.Character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearestEnemy = v
                    end
                end
            end
        end
    end)
    return nearestEnemy
end

-- [5] UI TABS & ELEMENTS
-- == MAIN TAB ==
local TabMain = Window:MakeTab({Name = "Auto Farm", Icon = "rbxassetid://4483345998"})
local TabStats = Window:MakeTab({Name = "Auto Stats", Icon = "rbxassetid://4483345998"})
local TabESP = Window:MakeTab({Name = "ESP & Visuals", Icon = "rbxassetid://4483345998"})
local TabMisc = Window:MakeTab({Name = "Misc", Icon = "rbxassetid://4483345998"})

TabMain:AddLabel("Valtrix Engine: Smooth & Safe")

TabMain:AddTextbox({Name = "Target Monster Name", Default = "", TextDisappear = false, Callback = function(Value)
    _G.SelectMonster = Value
end})

TabMain:AddToggle({Name = "Auto Farm (Tween)", Default = false, Callback = function(Value)
    _G.AutoFarm = Value
end})

TabMain:AddToggle({Name = "Fast Attack (Bypass)", Default = false, Callback = function(Value)
    _G.FastAttack = Value
end})

TabMain:AddToggle({Name = "Auto Equip Melee/Sword", Default = true, Callback = function(Value)
    _G.AutoEquip = Value
end})

TabMain:AddToggle({Name = "Auto Buso Haki", Default = true, Callback = function(Value)
    _G.AutoHaki = Value
end})

-- == STATS TAB ==
TabStats:AddDropdown({Name = "Select Stat", Default = "Melee", Options = {"Melee", "Defense", "Sword", "Gun", "Demon Fruit"}, Callback = function(Value)
    _G.SelectStat = Value
end})

TabStats:AddToggle({Name = "Auto Pump Stats", Default = false, Callback = function(Value)
    _G.AutoStats = Value
end})

-- == ESP TAB ==
TabESP:AddToggle({Name = "ESP Players (Highlight)", Default = false, Callback = function(Value)
    _G.ESPPlayer = Value
end})

TabESP:AddToggle({Name = "ESP Chests", Default = false, Callback = function(Value)
    _G.ESPChest = Value
end})

-- == MISC TAB ==
TabMisc:AddButton({Name = "Redeem All Codes", Callback = function()
    local codes = {"Sub2Fer999", "Magicbus", "JCWK", "Starcodeheo", "Bluxxy", "fudd10_v2", "SUB2GAMERROBOT_EXP1"}
    for _, code in pairs(codes) do
        ReplicatedStorage.Remotes.Redeem:InvokeServer(code)
    end
    OrionLib:MakeNotification({Name = "Valtrix Hub", Content = "Semua kode berhasil dicoba!", Time = 3})
end})

TabMisc:AddButton({Name = "Server Hop", Callback = function()
    local Http = game:GetService("HttpService")
    local TPS = game:GetService("TeleportService")
    local Api = "https://games.roblox.com/v1/games/"
    local _place = game.PlaceId
    local _servers = Api.._place.."/servers/Public?sortOrder=Asc&limit=100"
    function ListServers(cursor)
        local Raw = game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or ""))
        return Http:JSONDecode(Raw)
    end
    local Server, Next; repeat
        local Servers = ListServers(Next)
        Server = Servers.data[math.random(1, #Servers.data)]
        Next = Servers.nextPageCursor
    until Server
    TPS:TeleportToPlaceInstance(_place, Server.id, LocalPlayer)
end})

-- [6] MAIN LOGIC LOOPS
-- Anti-AFK
local antiAfk = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    antiAfk:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    antiAfk:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- Auto Farm Loop
task.spawn(function()
    while task.wait() do
        if _G.AutoFarm then
            pcall(function()
                local enemy = GetNearestEnemy()
                if enemy then
                    if _G.AutoEquip then EquipWeapon() end
                    if _G.AutoHaki then EnableHaki() end
                    
                    -- Posisi di atas musuh biar nggak kena hit
                    local targetPos = enemy.HumanoidRootPart.CFrame * CFrame.new(0, _G.FarmDistance, 0)
                    TweenTo(targetPos)
                    
                    -- Ngunci Kamera (Opsional, agar serangan kena)
                    enemy.HumanoidRootPart.CanCollide = false
                    enemy.Humanoid.WalkSpeed = 0
                    
                    -- Simulate Click
                    VirtualUser:CaptureController()
                    VirtualUser:Button1Down(Vector2.new(1280, 672))
                    
                    -- Fast Attack Bypass
                    if _G.FastAttack then
                        ReplicatedStorage.Remotes.Validator:FireServer(math.huge)
                    end
                end
            end)
        end
    end
end)

-- Auto Stats Loop
task.spawn(function()
    while task.wait(1) do
        if _G.AutoStats then
            pcall(function()
                ReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint", _G.SelectStat, _G.StatAmount)
            end)
        end
    end
end)

-- ESP Loop
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            -- ESP Player
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    if _G.ESPPlayer then
                        if not plr.Character:FindFirstChild("ValtrixESP") then
                            local hl = Instance.new("Highlight", plr.Character)
                            hl.Name = "ValtrixESP"
                            hl.FillColor = Color3.fromRGB(255, 0, 0)
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        end
                    else
                        if plr.Character:FindFirstChild("ValtrixESP") then
                            plr.Character.ValtrixESP:Destroy()
                        end
                    end
                end
            end
            
            -- ESP Chest
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name:find("Chest") and obj:IsA("Part") then
                    if _G.ESPChest then
                        if not obj:FindFirstChild("ValtrixChest") then
                            local hl = Instance.new("Highlight", obj)
                            hl.Name = "ValtrixChest"
                            hl.FillColor = Color3.fromRGB(255, 215, 0)
                        end
                    else
                        if obj:FindFirstChild("ValtrixChest") then
                            obj.ValtrixChest:Destroy()
                        end
                    end
                end
            end
        end)
    end
end)

OrionLib:Init()
