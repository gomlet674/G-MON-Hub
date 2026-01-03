-- main.lua
-- GMON-STYLE MULTI-HUB (CLEAN, MODULAR)
-- Contains modules: BloxFruit, BuildAboat, CarDealership
-- Author: Generated (adapt & test on your environment)
-- IMPORTANT: Test in private server first. Adjust game-specific names/paths in CONFIG sections.

-- ===========================
-- Services & quick helpers
-- ===========================
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:FindFirstChildOfClass("Humanoid")

local function safeNotify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text or "", Duration = dur or 5})
    end)
end

local function getCFrame(part)
    if not part then return nil end
    return part.CFrame
end

local function tweenTo(part, targetCFrame, duration)
    if not part or not targetCFrame then return end
    local start = part.CFrame
    local info = TweenInfo.new(duration or 0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local proxy = Instance.new("Part")
    proxy.Transparency = 1
    proxy.Anchored = true
    proxy.CanCollide = false
    proxy.Size = Vector3.new(1,1,1)
    proxy.CFrame = start
    proxy.Parent = workspace
    local t = TweenService:Create(proxy, info, {CFrame = targetCFrame})
    t:Play()
    t.Completed:Wait()
    part.CFrame = proxy.CFrame
    proxy:Destroy()
end

-- quick wait
local function waitForChild(parent, name, timeout)
    timeout = timeout or 10
    local t0 = tick()
    while tick() - t0 < timeout do
        local v = parent:FindFirstChild(name)
        if v then return v end
        task.wait(0.05)
    end
    return nil
end

-- ===========================
-- Config (ubah sesuai kebutuhan)
-- ===========================
local Config = {
    api = "", -- optional
    RayfieldUrl = "https://raw.githubusercontent.com/ghostxsmoke/rayfield/main/source.lua", -- ganti jika ada rayfield lain
    UseRayfield = true, -- jika false akan pakai fallback GUI sederhana
    -- Game-specific hooks (sesuaikan jika game berbeda)
    BloxFruit = {
        NPC_NAMES = {"Trainer","Merchant","Sea Dog","Boss"}, -- contoh, sesuaikan
        QUEST_REMOTE = nil, -- jika Anda tahu RemoteEvent name, masukkan string
    },
    BuildABoat = {
        TREASURE_NAME = "Treasure", -- nama object treasure
    },
    CarDealership = {
        CAR_ROOT = workspace:FindFirstChild("Cars") or workspace, -- coba sesuaikan
        CAR_PRICE_ATTRIBUTE = "Price", -- atau gunakan child "Price" tipe Value
        BUY_REMOTE_PATH = nil, -- contoh: game.ReplicatedStorage:WaitForChild("BuyCar")
    }
}

-- ===========================
-- Anti AFK & Anti Kick (safeguard)
-- ===========================
local function disableConnections(t)
    for _, conn in pairs(t) do
        if typeof(conn) == "Instance" then
            -- skip
        else
            pcall(function() conn:Disable() end)
        end
    end
end

-- disable idle (roblox idled signal)
pcall(function()
    for _, c in pairs(getconnections or function() return {} end)(LocalPlayer.Idled) do
        pcall(function() c:Disable() end)
    end
end)

-- Minimal anti-kick: wrap Kick to print (can't fully override server-initiated kicks)
do
    local ok, oldKick = pcall(function() return LocalPlayer.Kick end)
    -- we won't override Kick function for safety; just notify when Kick called (client side)
end

-- ===========================
-- GUI Loader (Rayfield or Fallback)
-- ===========================
local Rayfield = nil
local okRay = false
if Config.UseRayfield then
    local suc, ret = pcall(function()
        return loadstring(game:HttpGet(Config.RayfieldUrl, true))()
    end)
    if suc and type(ret) == "table" then
        Rayfield = ret
        okRay = true
    else
        okRay = false
    end
end

-- Fallback small GUI builder (very simple)
local FallbackGUI = {}
function FallbackGUI:CreateWindow(opts)
    local win = {}
    win.Tabs = {}
    function win:CreateTab(name) 
        local t = {Name = name, Elements = {}}
        function t:CreateLabel(text) print("[GUI] "..(text or "")) end
        function t:CreateButton(params) print("[GUI][Button] "..(params and params.Name or "Button")) end
        function t:CreateToggle(params) print("[GUI][Toggle] "..(params and params.Name or "Toggle")) end
        function t:CreateSlider(params) print("[GUI][Slider] "..(params and params.Name or "Slider")) end
        function t:CreateSection(name) print("[GUI][Section] "..(name or "")) end
        function t:CreateList(params) print("[GUI][List] "..(params and params.Name or "List")) end
        self.Elements[#self.Elements+1] = t
        return t
    end
    return win
end

local Window = nil
if okRay then
    Window = Rayfield:CreateWindow({
        Name = "GMON HUB",
        LoadingTitle = "GMON HUB",
        LoadingSubtitle = "Universal Script",
        ConfigurationSaving = { Enabled = true, FolderName = "GMON", FileName = "GMONHub" }
    })
else
    Window = FallbackGUI:CreateWindow({Name="GMON HUB"})
    safeNotify("GMON", "Rayfield not found, using fallback GUI", 5)
end

-- ===========================
-- Info Tab
-- ===========================
local InfoTab = Window:CreateTab and Window:CreateTab("Info") or Window:CreateTab("Info")
if InfoTab.CreateLabel then
    InfoTab:CreateLabel("Player: "..tostring(LocalPlayer.Name))
    InfoTab:CreateLabel("UserId: "..tostring(LocalPlayer.UserId))
    InfoTab:CreateLabel("PlaceId: "..tostring(game.PlaceId))
end

-- ===========================
-- Detect Game Type by PlaceId (edit arrays as needed)
-- ===========================
local PlaceId = game.PlaceId
local GameType = "Universal"

local BLOX_PLACES = {2753915549, 4442272183} -- contoh, edit
local BABFT_PLACES = {537413528}
local CDT_PLACES = {3351674303}

local function inList(tab, val)
    for _,v in ipairs(tab) do if v == val then return true end end
    return false
end

if inList(BLOX_PLACES, PlaceId) then GameType = "BloxFruit"
elseif inList(BABFT_PLACES, PlaceId) then GameType = "BuildAboat"
elseif inList(CDT_PLACES, PlaceId) then GameType = "CarDealership" end

if InfoTab.CreateLabel then InfoTab:CreateLabel("Detected: "..GameType) end

-- ===========================
-- Module: Utilities (common)
-- ===========================
local Utilities = {}

function Utilities:teleportTo(cframe)
    if not cframe then return false end
    pcall(function()
        HRP.CFrame = cframe + Vector3.new(0, 3, 0)
    end)
    return true
end

function Utilities:walkTo(part, speed)
    speed = speed or 60
    local target = part
    if not target then return false end
    pcall(function()
        local dest = target.Position
        -- simple movement: tween the HRP CFrame to destination
        tweenTo(HRP, CFrame.new(dest + Vector3.new(0,3,0)), math.clamp((HRP.Position - dest).Magnitude / speed, 0.2, 3))
    end)
    return true
end

function Utilities:clickTool()
    local tool = Character:FindFirstChildOfClass("Tool")
    if tool and tool.Parent == Character then
        pcall(function() tool:Activate() end)
        return true
    end
    return false
end

-- Anti-AFK simulate
do
    spawn(function()
        while true do
            -- small simulated input
            pcall(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame + Vector3.new(0,0.01,0)
                end
            end)
            task.wait(20)
        end
    end)
end

-- ===========================
-- Module: Blox Fruit (IMPLEMENTASI GENERIK)
-- Note: sesuaikan NPC names / remotes per versi game
-- ===========================
local BloxModule = {}
BloxModule.Enabled = false
BloxModule.Config = Config.BloxFruit

function BloxModule:findNearestNPC(names)
    local best, bestDist = nil, math.huge
    for _, npcName in ipairs(names) do
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == npcName and obj:IsA("Model") then
                local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj.PrimaryPart
                if root then
                    local dist = (HRP.Position - root.Position).Magnitude
                    if dist < bestDist then bestDist, best = dist, root end
                end
            end
        end
    end
    return best
end

function BloxModule:autoFarmStep()
    -- find nearest quest NPC or enemy
    local target = self:findNearestNPC(self.Config.NPC_NAMES)
    if not target then return false, "No NPC found" end
    -- approach
    Utilities:walkTo(target, 120)
    task.wait(0.2)
    -- attempt attack / interact: try click tool repeatedly
    for i=1,5 do
        Utilities:clickTool()
        task.wait(0.2)
    end
    return true
end

function BloxModule:startAutoFarm(loopDelay)
    if self.Enabled then return end
    self.Enabled = true
    spawn(function()
        safeNotify("BloxModule", "Auto Farm started", 4)
        while self.Enabled do
            local ok, msg = pcall(function() return self:autoFarmStep() end)
            if not ok then warn("Blox autoFarm step error:", msg) end
            task.wait(loopDelay or 0.5)
        end
        safeNotify("BloxModule", "Auto Farm stopped", 3)
    end)
end

function BloxModule:stopAutoFarm()
    self.Enabled = false
end

-- ===========================
-- Module: Build A Boat For Treasure (simplified)
-- ===========================
local BABModule = {}
BABModule.Enabled = false
BABModule.Config = Config.BuildABoat

function BABModule:findTreasure()
    -- search workspace for object name TREASURE_NAME
    local root = nil
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == self.Config.TREASURE_NAME then
            if obj:IsA("BasePart") then return obj end
            if obj:IsA("Model") then
                local p = obj:FindFirstChildWhichIsA("BasePart")
                if p then return p end
            end
        end
    end
    return nil
end

function BABModule:goClaimTreasure()
    local tr = self:findTreasure()
    if not tr then return false, "no treasure in workspace" end
    -- teleport near treasure
    local targetPos = tr.Position + Vector3.new(0, 5, 0)
    tweenTo(HRP, CFrame.new(targetPos), 0.4)
    -- small wait to ensure triggering
    task.wait(0.3)
    -- optionally: try to touch (just setting CFrame near the treasure usually claims)
    return true
end

function BABModule:startAutoFarm(loopDelay)
    if self.Enabled then return end
    self.Enabled = true
    spawn(function()
        safeNotify("BABFT", "Auto Farm started", 4)
        while self.Enabled do
            local ok, msg = pcall(function() return self:goClaimTreasure() end)
            if not ok then warn("BAB autoFarm error:", msg) end
            task.wait(loopDelay or 0.6)
        end
        safeNotify("BABFT", "Auto Farm stopped", 3)
    end)
end

function BABModule:stopAutoFarm()
    self.Enabled = false
end

-- ===========================
-- Module: Car Dealership Tycoon (generic)
-- ===========================
local CarModule = {}
CarModule.Config = Config.CarDealership
CarModule.CarList = {} -- runtime cache

-- utility: scan cars under configured CAR_ROOT and build info list
function CarModule:scanCars()
    self.CarList = {}
    local root = self.Config.CAR_ROOT or workspace
    for _, obj in pairs(root:GetDescendants()) do
        -- quick heuristics: Model with primary part and a Price value or attribute
        if obj:IsA("Model") and obj.PrimaryPart then
            local price = nil
            -- check attribute
            if obj:GetAttribute(self.Config.CAR_PRICE_ATTRIBUTE) then
                price = obj:GetAttribute(self.Config.CAR_PRICE_ATTRIBUTE)
            end
            -- check child IntValue / NumberValue named Price
            local pv = obj:FindFirstChild(self.Config.CAR_PRICE_ATTRIBUTE)
            if pv and (pv:IsA("IntValue") or pv:IsA("NumberValue") or pv:IsA("StringValue")) then
                price = tonumber(tostring(pv.Value)) or price
            end
            if price then
                table.insert(self.CarList, {Model = obj, Price = price, Name = obj.Name})
            end
        end
    end
    table.sort(self.CarList, function(a,b) return (a.Price or 0) < (b.Price or 0) end)
    return self.CarList
end

-- generic buy function (best effort)
function CarModule:buyCar(carInfo)
    if not carInfo then return false, "no car selected" end
    -- Two approaches: if BUY_REMOTE_PATH provided, try to use it,
    -- else attempt to touch the buy-trigger area near car model.
    if self.Config.BUY_REMOTE_PATH then
        -- BUY_REMOTE_PATH expected like: "game.ReplicatedStorage.BuyCar"
        local suc, remote = pcall(function()
            local env = load("return " .. self.Config.BUY_REMOTE_PATH)()
            return env
        end)
        if suc and remote and remote.FireServer then
            pcall(function() remote:FireServer(carInfo.Model) end)
            return true
        end
    end
    -- fallback: move to car and attempt interact (if there's a ClickDetector)
    local clicks = {}
    for _, v in pairs(carInfo.Model:GetDescendants()) do
        if v:IsA("ClickDetector") then table.insert(clicks, v) end
    end
    if #clicks > 0 then
        local cd = clicks[1]
        -- simulate clicking: move to click position
        if cd.Parent and cd.Parent:IsA("BasePart") then
            Utilities:walkTo(cd.Parent, 120)
            task.wait(0.3)
            -- attempt to trigger detector via fire (works only if clickdetector bound server)
            pcall(function() cd:FireClick(LocalPlayer) end)
            return true
        end
    end
    return false, "no remote or clickable found; set BUY_REMOTE_PATH in config"
end

-- ===========================
-- GUI: Features Tab & Controls
-- ===========================
local FeaturesTab = Window:CreateTab and Window:CreateTab("Features") or Window:CreateTab("Features")

-- Blox UI
if GameType == "BloxFruit" then
    FeaturesTab:CreateSection("Blox Fruits")
    local afToggle, questToggle
    afToggle = FeaturesTab:CreateToggle({
        Name = "Auto Farm (Blox)",
        CurrentValue = false,
        Callback = function(v)
            if v then BloxModule:startAutoFarm(0.6) else BloxModule:stopAutoFarm() end
        end
    })
    questToggle = FeaturesTab:CreateToggle({
        Name = "Auto Quest (Stub)",
        CurrentValue = false,
        Callback = function(v)
            -- implement quest logic if you know quest remotes
            if v then safeNotify("Blox", "Auto Quest enabled (stub)") end
        end
    })
    FeaturesTab:CreateButton({
        Name = "Scan NPCs",
        Callback = function()
            local t = BloxModule:findNearestNPC(BloxModule.Config.NPC_NAMES)
            if t then safeNotify("Blox", "Found NPC at "..t.Position.X..","..t.Position.Y,4) end
        end
    })
end

-- Build a Boat UI
if GameType == "BuildAboat" then
    FeaturesTab:CreateSection("Build A Boat")
    local babToggle
    babToggle = FeaturesTab:CreateToggle({
        Name = "Auto Farm Treasure",
        CurrentValue = false,
        Callback = function(v)
            if v then BABModule:startAutoFarm(0.8) else BABModule:stopAutoFarm() end
        end
    })
    FeaturesTab:CreateButton({
        Name = "Find Treasure (Debug)",
        Callback = function()
            local t = BABModule:findTreasure()
            if t then safeNotify("BABFT", "Treasure at: "..t.Position.X..","..t.Position.Z, 5)
            else safeNotify("BABFT", "Treasure not found (check config)", 5) end
        end
    })
end

-- Car Dealership UI
if GameType == "CarDealership" then
    FeaturesTab:CreateSection("Car Dealership")
    local scanBtn = FeaturesTab:CreateButton({
        Name = "Scan Cars",
        Callback = function()
            local list = CarModule:scanCars()
            if #list == 0 then safeNotify("Car", "No cars found. Adjust CAR_ROOT or Price attribute.", 6) return end
            safeNotify("Car", "Found "..#list.." car(s). See console for details.", 5)
            for i,ci in ipairs(list) do
                print(("CAR [%d] %s - %s"):format(i, tostring(ci.Name), tostring(ci.Price)))
            end
        end
    })
    FeaturesTab:CreateButton({
        Name = "Buy Cheapest Car",
        Callback = function()
            local list = CarModule:scanCars()
            if #list == 0 then safeNotify("Car", "No cars found", 5); return end
            local ok, err = CarModule:buyCar(list[1])
            if ok then safeNotify("Car", "Buy attempt sent", 4) else safeNotify("Car", "Buy failed: "..tostring(err), 6) end
        end
    })
end

-- Settings Tab
local SettingsTab = Window:CreateTab and Window:CreateTab("Settings") or Window:CreateTab("Settings")
SettingsTab:CreateSection("General")
SettingsTab:CreateButton({
    Name = "Destroy UI",
    Callback = function() 
        if okRay and Rayfield and Rayfield:Destroy then 
            pcall(function() Rayfield:Destroy() end) 
        end 
        safeNotify("GMON","UI destroyed",3)
    end
})
SettingsTab:CreateButton({
    Name = "Print Config (console)",
    Callback = function()
        print("CONFIG Dump:", HttpService:JSONEncode(Config))
    end
})

-- ===========================
-- Final: Auto init & safety reminders
-- ===========================
safeNotify("GMON", "Initialized - "..tostring(GameType), 5)
print("GMON HUB initialized. Detected game:", GameType)
print("Notes: Adjust Config at top to match the game instance (NPC names, remotes, attributes).")

-- End of main.lua