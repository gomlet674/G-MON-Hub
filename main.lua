-- ==========================================================
-- VALTRIX CHEVION - SURVIVE THE APOCALYPSE (V3 - STABLE)
-- 100% Executor Support (Delta, Arceus, Fluxus, Codex, Mac/PC)
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- [1] SAFE GUI PARENTING (Mencegah Error di Executor Mobile)
local guiParent
local success, result = pcall(function() return gethui() end)
if success and result then
    guiParent = result
else
    local success2, result2 = pcall(function() return CoreGui end)
    guiParent = success2 and result2 or LocalPlayer:WaitForChild("PlayerGui")
end

-- Cleanup UI Lama
for _, gui in pairs(guiParent:GetChildren()) do
    if gui.Name == "ValtrixChevionUI" then gui:Destroy() end
end

-- Variables Global
local Toggles = {
    AutoFarmGen = false, AutoFarmItem = false, AutoFarmAirdrop = false, AutoKillZombie = false,
    ESPItem = false, ESPZombie = false, ESPPlayer = false, AutoRevive = false
}
local Values = { Speed = 16, Jump = 50, FarmCount = 0 }
local Connections = {}
local ActiveESP = {}
local IsScriptRunning = true

local ValidItems = {"fuel", "scrap", "battery", "bandage", "medkit", "gun", "airdrop"}
local MeleeWeapons = {"knife", "axe", "hammer", "bat", "fire axe", "machete", "katana", "sword"}

-- ==========================================================
-- UI CREATION
-- ==========================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ValtrixChevionUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiParent

local ToggleBtn = Instance.new("ImageButton", ScreenGui)
ToggleBtn.Name = "AnimeToggle"
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0.1, 0, 0.1, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleBtn.Image = "rbxassetid://7373335525" 
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
ToggleStroke.Color = Color3.fromRGB(0, 255, 255)
ToggleStroke.Thickness = 2
ToggleBtn.Draggable = true
ToggleBtn.Active = true

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 550, 0, 380)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local RGBStroke = Instance.new("UIStroke", MainFrame)
RGBStroke.Thickness = 2
local RGBGradient = Instance.new("UIGradient", RGBStroke)
RGBGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
})
table.insert(Connections, RunService.RenderStepped:Connect(function()
    if IsScriptRunning then RGBGradient.Rotation = (RGBGradient.Rotation + 1) % 360 end
end))

local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 60)
Header.BackgroundTransparency = 1

local function CreateText(parent, text, color, pos, size, align)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = size
    lbl.Position = pos
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 24
    lbl.TextXAlignment = align
    return lbl
end

CreateText(Header, "Valtrix", Color3.fromRGB(255, 80, 80), UDim2.new(0, 20, 0, 0), UDim2.new(0, 90, 1, 0), Enum.TextXAlignment.Left)
CreateText(Header, "Chevion", Color3.fromRGB(80, 200, 255), UDim2.new(0, 110, 0, 0), UDim2.new(0, 120, 1, 0), Enum.TextXAlignment.Left)

local PlayerName = Instance.new("TextLabel", Header)
PlayerName.Size = UDim2.new(0, 150, 1, 0)
PlayerName.Position = UDim2.new(1, -220, 0, 0)
PlayerName.BackgroundTransparency = 1
PlayerName.Text = LocalPlayer.DisplayName
PlayerName.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerName.Font = Enum.Font.GothamSemibold
PlayerName.TextSize = 16
PlayerName.TextXAlignment = Enum.TextXAlignment.Right

local Avatar = Instance.new("ImageLabel", Header)
Avatar.Size = UDim2.new(0, 40, 0, 40)
Avatar.Position = UDim2.new(1, -60, 0.5, -20)
Avatar.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
Instance.new("UICorner", Avatar).CornerRadius = UDim.new(1, 0)

task.spawn(function()
    pcall(function()
        local content = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        Avatar.Image = content
    end)
end)

local Line = Instance.new("Frame", MainFrame)
Line.Size = UDim2.new(1, 0, 0, 1)
Line.Position = UDim2.new(0, 0, 0, 60)
Line.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
Line.BorderSizePixel = 0

-- Tab System
local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size = UDim2.new(1, 0, 0, 35)
TabBar.Position = UDim2.new(0, 0, 0, 61)
TabBar.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
TabBar.BorderSizePixel = 0
local MainLayout = Instance.new("UIListLayout", TabBar)
MainLayout.FillDirection = Enum.FillDirection.Horizontal
MainLayout.SortOrder = Enum.SortOrder.LayoutOrder

local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Size = UDim2.new(1, -20, 1, -106)
TabContainer.Position = UDim2.new(0, 10, 0, 106)
TabContainer.BackgroundTransparency = 1

local Pages, TabButtons = {}, {}

local function CreateTab(name, isFirst)
    local Btn = Instance.new("TextButton", TabBar)
    Btn.Size = UDim2.new(0, 95, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text = name
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.TextColor3 = isFirst and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)

    local Page = Instance.new("ScrollingFrame", TabContainer)
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 3
    Page.Visible = isFirst

    local Layout = Instance.new("UIListLayout", Page)
    Layout.Padding = UDim.new(0, 8)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder

    Pages[name] = Page
    table.insert(TabButtons, Btn)

    Btn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        for _, b in pairs(TabButtons) do b.TextColor3 = Color3.fromRGB(150, 150, 150) end
        Page.Visible = true
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    return Page
end

local PageMain = CreateTab("Main", true)
local PageVisual = CreateTab("Visual", false)
local PagePlayer = CreateTab("Player", false)
local PageSpeed = CreateTab("Speed", false)
local PageMisc = CreateTab("Misc", false)

-- ==========================================================
-- UI COMPONENTS UTILITY
-- ==========================================================
local function CreateToggle(parent, text, flag)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, 0, 0, 36)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local ToggleBG = Instance.new("TextButton", Frame)
    ToggleBG.Size = UDim2.new(0, 40, 0, 20)
    ToggleBG.Position = UDim2.new(1, -55, 0.5, -10)
    ToggleBG.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
    ToggleBG.Text = ""
    Instance.new("UICorner", ToggleBG).CornerRadius = UDim.new(1, 0)

    local Circle = Instance.new("Frame", ToggleBG)
    Circle.Size = UDim2.new(0, 16, 0, 16)
    Circle.Position = UDim2.new(0, 2, 0.5, -8)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

    ToggleBG.MouseButton1Click:Connect(function()
        Toggles[flag] = not Toggles[flag]
        if Toggles[flag] then
            TweenService:Create(Circle, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
            TweenService:Create(ToggleBG, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 170, 0)}):Play()
        else
            TweenService:Create(Circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
            TweenService:Create(ToggleBG, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 55, 65)}):Play()
        end
    end)
end

local function CreateInput(parent, text, flag, placeholder)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, 0, 0, 40)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(0, 100, 1, 0)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local InputBox = Instance.new("TextBox", Frame)
    InputBox.Size = UDim2.new(0, 70, 0, 26)
    InputBox.Position = UDim2.new(0, 120, 0.5, -13)
    InputBox.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
    InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    InputBox.Font = Enum.Font.Gotham
    InputBox.TextSize = 13
    InputBox.Text = tostring(placeholder)
    Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", InputBox).Color = Color3.fromRGB(60, 65, 75)

    local SetBtn = Instance.new("TextButton", Frame)
    SetBtn.Size = UDim2.new(0, 60, 0, 26)
    SetBtn.Position = UDim2.new(0, 200, 0.5, -13)
    SetBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 120)
    SetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SetBtn.Font = Enum.Font.GothamSemibold
    SetBtn.TextSize = 13
    SetBtn.Text = "Set"
    Instance.new("UICorner", SetBtn).CornerRadius = UDim.new(0, 4)

    local ResetBtn = Instance.new("TextButton", Frame)
    ResetBtn.Size = UDim2.new(0, 60, 0, 26)
    ResetBtn.Position = UDim2.new(0, 270, 0.5, -13)
    ResetBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 120)
    ResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ResetBtn.Font = Enum.Font.GothamSemibold
    ResetBtn.TextSize = 13
    ResetBtn.Text = "Reset"
    Instance.new("UICorner", ResetBtn).CornerRadius = UDim.new(0, 4)

    SetBtn.MouseButton1Click:Connect(function()
        local num = tonumber(InputBox.Text)
        if num then Values[flag] = num end
    end)

    ResetBtn.MouseButton1Click:Connect(function()
        if flag == "Speed" then Values.Speed = 16 InputBox.Text = "16" end
        if flag == "Jump" then Values.Jump = 50 InputBox.Text = "50" end
    end)
end

local function CreatePlayerActionUI(parent)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, 0, 0, 40)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local InputBox = Instance.new("TextBox", Frame)
    InputBox.Size = UDim2.new(0, 180, 0, 26)
    InputBox.Position = UDim2.new(0, 10, 0.5, -13)
    InputBox.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
    InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    InputBox.PlaceholderText = "Input Player Name..."
    InputBox.Font = Enum.Font.Gotham
    InputBox.TextSize = 13
    Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 4)

    local SpecBtn = Instance.new("TextButton", Frame)
    SpecBtn.Size = UDim2.new(0, 80, 0, 26)
    SpecBtn.Position = UDim2.new(0, 200, 0.5, -13)
    SpecBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 180)
    SpecBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SpecBtn.Font = Enum.Font.GothamSemibold
    SpecBtn.TextSize = 12
    SpecBtn.Text = "Spectate"
    Instance.new("UICorner", SpecBtn).CornerRadius = UDim.new(0, 4)

    local TPBtn = Instance.new("TextButton", Frame)
    TPBtn.Size = UDim2.new(0, 80, 0, 26)
    TPBtn.Position = UDim2.new(0, 290, 0.5, -13)
    TPBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 80)
    TPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TPBtn.Font = Enum.Font.GothamSemibold
    TPBtn.TextSize = 12
    TPBtn.Text = "Teleport"
    Instance.new("UICorner", TPBtn).CornerRadius = UDim.new(0, 4)

    local isSpectating = false
    SpecBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if isSpectating then
                Camera.CameraSubject = LocalPlayer.Character.Humanoid
                SpecBtn.Text = "Spectate"
                isSpectating = false
            else
                for _, p in pairs(Players:GetPlayers()) do
                    if string.lower(string.sub(p.Name, 1, #InputBox.Text)) == string.lower(InputBox.Text) and p.Character then
                        Camera.CameraSubject = p.Character.Humanoid
                        SpecBtn.Text = "Unspectate"
                        isSpectating = true
                        break
                    end
                end
            end
        end)
    end)

    TPBtn.MouseButton1Click:Connect(function()
        pcall(function()
            for _, p in pairs(Players:GetPlayers()) do
                if string.lower(string.sub(p.Name, 1, #InputBox.Text)) == string.lower(InputBox.Text) and p.Character then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2)
                    break
                end
            end
        end)
    end)
end

-- Toggles
CreateToggle(PageMain, "Auto Farm Generator (Fuel)", "AutoFarmGen")
CreateToggle(PageMain, "Auto Farm Item (Crafting)", "AutoFarmItem")
CreateToggle(PageMain, "Auto Farm Airdrop", "AutoFarmAirdrop")
CreateToggle(PageMain, "Auto Kill Zombie", "AutoKillZombie")

CreateToggle(PageVisual, "ESP Item (Box & Jarak)", "ESPItem")
CreateToggle(PageVisual, "ESP Zombie (Health & Jarak)", "ESPZombie")
CreateToggle(PageVisual, "ESP Player (Health & Jarak)", "ESPPlayer")

CreateToggle(PagePlayer, "Auto Revive All Player", "AutoRevive")
CreatePlayerActionUI(PagePlayer)

CreateInput(PageSpeed, "Speed", "Speed", 16)
CreateInput(PageSpeed, "Jump", "Jump", 50)

-- Unload Button
local UnloadBtn = Instance.new("TextButton", PageMisc)
UnloadBtn.Size = UDim2.new(1, 0, 0, 36)
UnloadBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
UnloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UnloadBtn.Font = Enum.Font.GothamBold
UnloadBtn.TextSize = 13
UnloadBtn.Text = "Unload Script"
Instance.new("UICorner", UnloadBtn).CornerRadius = UDim.new(0, 6)

UnloadBtn.MouseButton1Click:Connect(function()
    IsScriptRunning = false
    for _, conn in pairs(Connections) do pcall(function() conn:Disconnect() end) end
    for _, esp in pairs(ActiveESP) do
        pcall(function()
            if esp.BillBoard then esp.BillBoard:Destroy() end
            if esp.Highlight then esp.Highlight:Destroy() end
            if esp.Box then esp.Box:Destroy() end
        end)
    end
    ScreenGui:Destroy()
end)

-- Menu Toggle Logic
local uiVisible = true
ToggleBtn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    MainFrame.Visible = uiVisible
end)

-- ==========================================================
-- LOGIC HELPER FUNCTIONS
-- ==========================================================

local function EquipItem(itemName)
    local char = LocalPlayer.Character
    if not char then return nil end
    
    local foundTool = nil
    pcall(function()
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, item in pairs(backpack:GetChildren()) do
                if item:IsA("Tool") and string.find(string.lower(item.Name), itemName) then
                    char.Humanoid:EquipTool(item)
                    foundTool = item
                    return
                end
            end
        end
        for _, item in pairs(char:GetChildren()) do
            if item:IsA("Tool") and string.find(string.lower(item.Name), itemName) then
                foundTool = item
                return
            end
        end
    end)
    return foundTool
end

local function CreateESP(targetPart, model, textName, color, isItem)
    if not targetPart or not model then return end
    
    local espData = { Model = model, TargetPart = targetPart, IsItem = isItem }
    
    pcall(function()
        local bg = Instance.new("BillboardGui", targetPart)
        bg.Name = "ValtrixESP"
        bg.Size = UDim2.new(0, 200, 0, 50)
        bg.AlwaysOnTop = true
        bg.StudsOffset = Vector3.new(0, isItem and 1.5 or 3.5, 0)
        
        local txt = Instance.new("TextLabel", bg)
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.TextStrokeTransparency = 0.5
        txt.TextColor3 = color
        txt.Font = Enum.Font.GothamBold
        txt.TextSize = 11
        espData.BillBoard = bg
        espData.TextLabel = txt

        if isItem then
            local box = Instance.new("BoxHandleAdornment", targetPart)
            box.Adornee = targetPart
            box.Size = targetPart.Size + Vector3.new(0.1, 0.1, 0.1)
            box.ZIndex = 10
            box.AlwaysOnTop = true
            box.Transparency = 0.6
            box.Color3 = color
            espData.Box = box
        else
            local hl = Instance.new("Highlight", model)
            hl.FillColor = color
            hl.OutlineColor = Color3.new(1, 1, 1)
            hl.FillTransparency = 0.7
            espData.Highlight = hl
        end
        table.insert(ActiveESP, espData)
    end)
end

-- ==========================================================
-- MAIN LOOPS (Aman dari Crash)
-- ==========================================================

-- Heartbeat Loop (Logika Fisik)
table.insert(Connections, RunService.Heartbeat:Connect(function()
    if not IsScriptRunning then return end
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if not char or not root or not hum then return end

        if Values.Speed ~= 16 then hum.WalkSpeed = Values.Speed end
        if Values.Jump ~= 50 then hum.JumpPower = Values.Jump hum.UseJumpPower = true end

        -- Auto Revive
        if Toggles.AutoRevive then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") then
                    local phum = p.Character.Humanoid
                    if phum.Health > 0 and phum.Health < 15 then 
                        local med = EquipItem("bandage") or EquipItem("medkit")
                        if med then
                            root.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1)
                            med:Activate() -- Lebih aman dari mouse1click
                        end
                    end
                end
            end
        end

        -- Auto Kill Zombie
        if Toggles.AutoKillZombie then
            local weapon = nil
            for _, wName in pairs(MeleeWeapons) do
                weapon = EquipItem(wName)
                if weapon then break end
            end
            if weapon then
                for _, z in pairs(Workspace:GetDescendants()) do
                    if z:FindFirstChild("Humanoid") and z:FindFirstChild("HumanoidRootPart") and not Players:GetPlayerFromCharacter(z) then
                        if z.Humanoid.Health > 0 then
                            root.CFrame = z.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                            weapon:Activate()
                            break
                        end
                    end
                end
            end
        end
    end)
end))

-- Task Spawn lambat untuk Farm & Pemindaian ESP (Mencegah Lag/Crash)
task.spawn(function()
    while task.wait(0.5) do
        if not IsScriptRunning then break end
        pcall(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            -- Auto Farm Gen
            if Toggles.AutoFarmGen then
                EquipItem("backpack") or EquipItem("ransel")
                if Values.FarmCount < 5 then
                    for _, v in pairs(Workspace:GetDescendants()) do
                        if v:IsA("BasePart") and string.find(string.lower(v.Name), "fuel") then
                            root.CFrame = v.CFrame
                            Values.FarmCount = Values.FarmCount + 1
                            break
                        end
                    end
                else
                    for _, v in pairs(Workspace:GetDescendants()) do
                        if string.find(string.lower(v.Name), "generator") then
                            root.CFrame = v.CFrame * CFrame.new(0, 3, 0)
                            for _, tool in pairs(char:GetChildren()) do if tool:IsA("Tool") then tool.Parent = Workspace end end
                            Values.FarmCount = 0
                            break
                        end
                    end
                end
            end

            -- Auto Farm Airdrop
            if Toggles.AutoFarmAirdrop then
                for _, v in pairs(Workspace:GetDescendants()) do
                    if string.find(string.lower(v.Name), "airdrop") or string.find(string.lower(v.Name), "crate") then
                        root.CFrame = v.CFrame * CFrame.new(0, 2, 0)
                        break
                    end
                end
            end
        end)
    end
end)

-- Task Spawn untuk Scan ESP (Terpisah dari RenderStepped)
task.spawn(function()
    while task.wait(1) do
        if not IsScriptRunning then break end
        pcall(function()
            local currentESPModels = {}
            for i = #ActiveESP, 1, -1 do
                local esp = ActiveESP[i]
                if not esp.Model or not esp.Model.Parent then
                    if esp.BillBoard then esp.BillBoard:Destroy() end
                    if esp.Highlight then esp.Highlight:Destroy() end
                    if esp.Box then esp.Box:Destroy() end
                    table.remove(ActiveESP, i)
                else
                    currentESPModels[esp.Model] = true
                end
            end

            if Toggles.ESPPlayer then
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and not currentESPModels[p.Character] then
                        CreateESP(p.Character.Head, p.Character, p.Name, Color3.fromRGB(0, 255, 0), false)
                    end
                end
            end

            if Toggles.ESPZombie or Toggles.ESPItem then
                for _, v in pairs(Workspace:GetDescendants()) do
                    if Toggles.ESPItem and v:IsA("BasePart") and not currentESPModels[v] then
                        local nameL = string.lower(v.Name)
                        for _, valid in pairs(ValidItems) do
                            if string.find(nameL, valid) then
                                CreateESP(v, v, v.Name, Color3.fromRGB(255, 255, 0), true)
                                break
                            end
                        end
                    end
                    if Toggles.ESPZombie and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") and not Players:GetPlayerFromCharacter(v) and not currentESPModels[v] then
                        CreateESP(v.Head, v, "Zombie", Color3.fromRGB(255, 0, 0), false)
                    end
                end
            end
        end)
    end
end)

-- RenderStepped HANYA untuk update Text ESP (Sangat Ringan)
table.insert(Connections, RunService.RenderStepped:Connect(function()
    if not IsScriptRunning then return end
    pcall(function()
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        for _, esp in pairs(ActiveESP) do
            if esp.TargetPart and esp.TargetPart.Parent then
                local dist = math.floor((myRoot.Position - esp.TargetPart.Position).Magnitude)
                if esp.IsItem then
                    esp.TextLabel.Text = string.upper(esp.Model.Name) .. "\n[" .. dist .. "m]"
                else
                    local hum = esp.Model:FindFirstChild("Humanoid")
                    local hp = hum and math.floor(hum.Health) or 0
                    esp.TextLabel.Text = (esp.Model.Name == "Zombie" and "ZOMBIE" or string.upper(esp.Model.Name)) .. "\nHP: " .. hp .. " | [" .. dist .. "m]"
                end
            end
        end
    end)
end))

print("Valtrix Chevion V3 - Executor Safe Version Loaded!")
