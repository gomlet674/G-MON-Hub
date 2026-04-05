-- ==========================================================
-- VALTRIX CHEVION ULTIMATE - ALL IN ONE SYSTEM
-- Farming + Combat + Survival + AI + UI
-- ==========================================================

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- GLOBALS
_G.Toggles = {
    AutoFarmGen = false,
    AutoFarmItem = false,
    ESPPlayer = false,
    ESPZombie = false,
    ESPItem = false
}

_G.Settings = {
    MaxCarry = 5,
    FarmDelay = 0.25
}

_G.God = {
    AutoHeal = true,
    PanicHP = 40
}

_G.War = {
    Enabled = true,
    Aggressive = false,
    AttackRange = 10,
    RetreatHP = 35
}

-- ==========================================================
-- UI SIMPLE (BISA KAMU GANTI KE UI KAMU SENDIRI)
-- ==========================================================

local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "ValtrixUltimate"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,300,0,300)
frame.Position = UDim2.new(0,50,0,50)
frame.BackgroundColor3 = Color3.fromRGB(20,20,25)
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame)

local layout = Instance.new("UIListLayout", frame)

local function AddToggle(text, key)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1,0,0,35)
    btn.Text = text.." : OFF"
    btn.BackgroundColor3 = Color3.fromRGB(30,30,35)

    btn.MouseButton1Click:Connect(function()
        _G.Toggles[key] = not _G.Toggles[key]
        btn.Text = text.." : "..(_G.Toggles[key] and "ON" or "OFF")
    end)
end

AddToggle("Auto Farm Generator","AutoFarmGen")
AddToggle("Auto Farm Item","AutoFarmItem")
AddToggle("ESP Player","ESPPlayer")
AddToggle("ESP Zombie","ESPZombie")
AddToggle("ESP Item","ESPItem")

-- ==========================================================
-- SMART FARM SYSTEM
-- ==========================================================

local Priority = {"fuel","gas","scrap","part","battery","medkit"}

local function GetPriority(name)
    for i,v in ipairs(Priority) do
        if name:lower():find(v) then return i end
    end
    return 999
end

local function GetBestItem(root)
    local best,score = nil,math.huge

    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local pr = GetPriority(v.Name)
            if pr < 999 then
                local dist = (root.Position - v.Position).Magnitude
                local s = dist + pr*20
                if s < score then
                    score = s
                    best = v
                end
            end
        end
    end
    return best
end

local function GetItemCount(char)
    local c=0
    for _,v in pairs(char:GetChildren()) do
        if v:IsA("Tool") then c+=1 end
    end
    return c
end

local function Pickup(root,item)
    root.CFrame = item.CFrame + Vector3.new(0,2,0)
    pcall(function()
        firetouchinterest(root,item,0)
        firetouchinterest(root,item,1)
    end)
end

local function DropAll(char)
    for _,v in pairs(char:GetChildren()) do
        if v:IsA("Tool") then
            v.Parent = Workspace
        end
    end
end

local function GetTarget()
    for _,v in pairs(Workspace:GetDescendants()) do
        local n = v.Name:lower()
        if _G.Toggles.AutoFarmGen and n:find("generator") then return v end
        if _G.Toggles.AutoFarmItem and n:find("craft") then return v end
    end
end

-- ==========================================================
-- GOD SYSTEM
-- ==========================================================

local function AutoHeal()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if not hum then return end

    if hum.Health <= _G.God.PanicHP then
        for _,tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find("medkit") then
                tool:Activate()
            end
        end
    end
end

-- ==========================================================
-- COMBAT SYSTEM
-- ==========================================================

local function GetClosestZombie(root)
    local best,dist=nil,math.huge
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(v) then
            local hrp=v:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d=(root.Position-hrp.Position).Magnitude
                if d<dist then dist=d best=v end
            end
        end
    end
    return best,dist
end

local function Attack(root)
    local z,dist = GetClosestZombie(root)
    if not z then return end

    local hrp = z:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if dist <= _G.War.AttackRange then
        root.CFrame = hrp.CFrame * CFrame.new(0,0,-3)
        for _,tool in pairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then
                tool:Activate()
            end
        end
    end
end

-- ==========================================================
-- ESP SYSTEM
-- ==========================================================

local ESPs = {}

local function CreateESP(obj,color)
    local hl = Instance.new("Highlight")
    hl.FillColor = color
    hl.Parent = obj
    table.insert(ESPs,hl)
end

RunService.RenderStepped:Connect(function()
    for _,v in pairs(ESPs) do v:Destroy() end
    ESPs = {}

    if _G.Toggles.ESPPlayer then
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character then
                CreateESP(p.Character,Color3.new(0,1,0))
            end
        end
    end
end)

-- ==========================================================
-- MAIN LOOP (AI CORE)
-- ==========================================================

task.spawn(function()
    while task.wait(_G.Settings.FarmDelay) do
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        -- FARM
        if _G.Toggles.AutoFarmGen or _G.Toggles.AutoFarmItem then
            local count = GetItemCount(char)

            if count < _G.Settings.MaxCarry then
                local item = GetBestItem(root)
                if item then Pickup(root,item) end
            else
                local target = GetTarget()
                if target then
                    root.CFrame = target.CFrame + Vector3.new(0,4,0)
                    DropAll(char)
                end
            end
        end

        -- GOD
        AutoHeal()

        -- COMBAT
        if _G.War.Enabled then
            Attack(root)
        end
    end
end)

print("VALTRIX ULTIMATE LOADED 🔥")
