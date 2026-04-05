-- ==========================================================
-- VALTRIX CHEVION - SURVIVE THE APOCALYPSE SCRIPT
-- Support: Delta, Arceus X, Fluxus, Codex, dll.
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local guiParent = (pcall(function() return gethui() end) and gethui()) or CoreGui

-- Cleanup UI Lama jika di-execute ulang
if guiParent:FindFirstChild("ValtrixChevionUI") then
    guiParent.ValtrixChevionUI:Destroy()
end

-- Variables Global
local Toggles = {
    AutoFarmGen = false,
    AutoFarmItem = false,
    ESPItem = false,
    ESPZombie = false,
    ESPPlayer = false
}
local Values = {
    Speed = 100,
    Jump = 50
}
local Connections = {}
local Highlights = {}

-- ==========================================================
-- UI CREATION
-- ==========================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ValtrixChevionUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

-- Toggle Button (Anime Image)
local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Name = "AnimeToggle"
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0.1, 0, 0.1, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleBtn.Image = "rbxassetid://7373335525" -- Gambar Anime Default (Bisa diganti ID-nya)
ToggleBtn.Parent = ScreenGui
local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn
local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(0, 255, 255)
ToggleStroke.Thickness = 2
ToggleStroke.Parent = ToggleBtn

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 550, 0, 350)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = true -- Membuat UI bisa digeser

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

-- RGB Border (Pinggiran)
local RGBStroke = Instance.new("UIStroke")
RGBStroke.Thickness = 2
RGBStroke.Parent = MainFrame
local RGBGradient = Instance.new("UIGradient")
RGBGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
})
RGBGradient.Parent = RGBStroke

table.insert(Connections, RunService.RenderStepped:Connect(function()
    RGBGradient.Rotation = (RGBGradient.Rotation + 1) % 360
end))

-- Header Section
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 60)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local Title1 = Instance.new("TextLabel")
Title1.Size = UDim2.new(0, 100, 1, 0)
Title1.Position = UDim2.new(0, 20, 0, 0)
Title1.BackgroundTransparency = 1
Title1.Text = "Valtrix"
Title1.TextColor3 = Color3.fromRGB(255, 80, 80)
Title1.Font = Enum.Font.GothamBold
Title1.TextSize = 28
Title1.TextXAlignment = Enum.TextXAlignment.Left
Title1.Parent = Header

local Title2 = Instance.new("TextLabel")
Title2.Size = UDim2.new(0, 150, 1, 0)
Title2.Position = UDim2.new(0, 120, 0, 0)
Title2.BackgroundTransparency = 1
Title2.Text = "Chevion"
Title2.TextColor3 = Color3.fromRGB(80, 200, 255)
Title2.Font = Enum.Font.GothamBold
Title2.TextSize = 28
Title2.TextXAlignment = Enum.TextXAlignment.Left
Title2.Parent = Header

-- Player Profile (Nama & Avatar)
local PlayerName = Instance.new("TextLabel")
PlayerName.Size = UDim2.new(0, 150, 1, 0)
PlayerName.Position = UDim2.new(1, -220, 0, 0)
PlayerName.BackgroundTransparency = 1
PlayerName.Text = LocalPlayer.DisplayName
PlayerName.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerName.Font = Enum.Font.GothamSemibold
PlayerName.TextSize = 16
PlayerName.TextXAlignment = Enum.TextXAlignment.Right
PlayerName.Parent = Header

local Avatar = Instance.new("ImageLabel")
Avatar.Size = UDim2.new(0, 40, 0, 40)
Avatar.Position = UDim2.new(1, -60, 0.5, -20)
Avatar.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
Avatar.Parent = Header
local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(1, 0)
AvatarCorner.Parent = Avatar

-- Mengambil Foto Profil Asli Player
task.spawn(function()
    local userId = LocalPlayer.UserId
    local thumbType = Enum.ThumbnailType.HeadShot
    local thumbSize = Enum.ThumbnailSize.Size420x420
    local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
    if isReady then
        Avatar.Image = content
    end
end)

-- Separator Line
local Line = Instance.new("Frame")
Line.Size = UDim2.new(1, 0, 0, 1)
Line.Position = UDim2.new(0, 0, 0, 60)
Line.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
Line.BorderSizePixel = 0
Line.Parent = MainFrame

-- Tabs Bar
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 35)
TabBar.Position = UDim2.new(0, 0, 0, 61)
TabBar.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -20, 1, -106)
TabContainer.Position = UDim2.new(0, 10, 0, 106)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainFrame

local Pages = {}
local TabButtons = {}

local function CreateTab(name, isFirst)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 100, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text = name
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 14
    Btn.TextColor3 = isFirst and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
    Btn.Parent = TabBar

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 4
    Page.Visible = isFirst
    Page.Parent = TabContainer

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 10)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Page

    Pages[name] = Page
    table.insert(TabButtons, Btn)

    -- Tab Switch Logic
    Btn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        for _, b in pairs(TabButtons) do b.TextColor3 = Color3.fromRGB(150, 150, 150) end
        Page.Visible = true
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    return Page
end

local MainLayout = Instance.new("UIListLayout")
MainLayout.FillDirection = Enum.FillDirection.Horizontal
MainLayout.SortOrder = Enum.SortOrder.LayoutOrder
MainLayout.Parent = TabBar

local PageMain = CreateTab("Main", true)
local PageVisual = CreateTab("Visual", false)
local PageSpeed = CreateTab("Speed", false)
local PageMisc = CreateTab("Misc", false)

-- ==========================================================
-- UI COMPONENTS UTILITY
-- ==========================================================
local function CreateToggle(parent, text, flag)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 40)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    Frame.Parent = parent
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local ToggleBG = Instance.new("TextButton")
    ToggleBG.Size = UDim2.new(0, 45, 0, 22)
    ToggleBG.Position = UDim2.new(1, -60, 0.5, -11)
    ToggleBG.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
    ToggleBG.Text = ""
    ToggleBG.Parent = Frame
    Instance.new("UICorner", ToggleBG).CornerRadius = UDim.new(1, 0)

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 18, 0, 18)
    Circle.Position = UDim2.new(0, 2, 0.5, -9)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.Parent = ToggleBG
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

    ToggleBG.MouseButton1Click:Connect(function()
        Toggles[flag] = not Toggles[flag]
        if Toggles[flag] then
            TweenService:Create(Circle, TweenInfo.new(0.2), {Position = UDim2.new(1, -20, 0.5, -9)}):Play()
            TweenService:Create(ToggleBG, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 170, 0)}):Play()
        else
            TweenService:Create(Circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -9)}):Play()
            TweenService:Create(ToggleBG, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 55, 65)}):Play()
        end
    end)
end

local function CreateInputWithButtons(parent, text, flag, defaultVal)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 40)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    Frame.Parent = parent
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 100, 1, 0)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local InputBox = Instance.new("TextBox")
    InputBox.Size = UDim2.new(0, 80, 0, 26)
    InputBox.Position = UDim2.new(0, 120, 0.5, -13)
    InputBox.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
    InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    InputBox.Font = Enum.Font.Gotham
    InputBox.TextSize = 14
    InputBox.Text = tostring(defaultVal)
    InputBox.Parent = Frame
    Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 4)
    local Stroke = Instance.new("UIStroke", InputBox)
    Stroke.Color = Color3.fromRGB(60, 65, 75)

    local SetBtn = Instance.new("TextButton")
    SetBtn.Size = UDim2.new(0, 60, 0, 26)
    SetBtn.Position = UDim2.new(0, 210, 0.5, -13)
    SetBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 120)
    SetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SetBtn.Font = Enum.Font.GothamSemibold
    SetBtn.TextSize = 13
    SetBtn.Text = "Set"
    SetBtn.Parent = Frame
    Instance.new("UICorner", SetBtn).CornerRadius = UDim.new(0, 4)

    local ResetBtn = Instance.new("TextButton")
    ResetBtn.Size = UDim2.new(0, 60, 0, 26)
    ResetBtn.Position = UDim2.new(0, 280, 0.5, -13)
    ResetBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 120)
    ResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ResetBtn.Font = Enum.Font.GothamSemibold
    ResetBtn.TextSize = 13
    ResetBtn.Text = "Reset"
    ResetBtn.Parent = Frame
    Instance.new("UICorner", ResetBtn).CornerRadius = UDim.new(0, 4)

    SetBtn.MouseButton1Click:Connect(function()
        local num = tonumber(InputBox.Text)
        if num then Values[flag] = num end
    end)

    ResetBtn.MouseButton1Click:Connect(function()
        if flag == "Speed" then
            Values.Speed = 16
            InputBox.Text = "16"
        elseif flag == "Jump" then
            Values.Jump = 50
            InputBox.Text = "50"
        end
    end)
end

local function CreateButton(parent, text, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 40)
    Btn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 14
    Btn.Text = text
    Btn.Parent = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    Btn.MouseButton1Click:Connect(callback)
end

-- ==========================================================
-- ADDING CONTROLS TO TABS
-- ==========================================================
-- Main Tab
CreateToggle(PageMain, "Auto Farm Generator", "AutoFarmGen")
CreateToggle(PageMain, "Auto Farm Item", "AutoFarmItem")

-- Visual Tab
CreateToggle(PageVisual, "ESP Item", "ESPItem")
CreateToggle(PageVisual, "ESP Zombie", "ESPZombie")
CreateToggle(PageVisual, "ESP Player", "ESPPlayer")

-- Speed Tab
CreateInputWithButtons(PageSpeed, "Speed", "Speed", 100)
CreateInputWithButtons(PageSpeed, "Jump", "Jump", 50)

-- Misc Tab
CreateButton(PageMisc, "Unload Script", function()
    -- Disconnect semua loop dan hapus UI
    for _, conn in pairs(Connections) do
        if conn then conn:Disconnect() end
    end
    for _, hl in pairs(Highlights) do
        if hl then hl:Destroy() end
    end
    ScreenGui:Destroy()
end)

-- Toggle Logic (Anime Button)
local uiVisible = true
ToggleBtn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    MainFrame.Visible = uiVisible
end)
ToggleBtn.Draggable = true

-- ==========================================================
-- SCRIPT LOGIC / FEATURES
-- ==========================================================

-- Helper untuk ESP (Highlight)
local function CreateESP(instance, color)
    if not instance then return end
    local hl = Instance.new("Highlight")
    hl.FillColor = color
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.FillTransparency = 0.5
    hl.Parent = instance
    table.insert(Highlights, hl)
    return hl
end

-- Loop Utama (Berjalan terus menerus)
table.insert(Connections, RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if hum then
        -- Enforce Speed & Jump (Memaksa speed agar tidak di-reset game)
        if Values.Speed ~= 16 then
            hum.WalkSpeed = Values.Speed
        end
        if Values.Jump ~= 50 then
            hum.JumpPower = Values.Jump
            hum.UseJumpPower = true
        end
    end

    -- AUTO FARM LOGIC
    if Toggles.AutoFarmGen and root then
        -- Contoh Logic: Mencari part bernama "Generator" di Workspace
        for _, v in pairs(Workspace:GetDescendants()) do
            if v.Name == "Generator" and v:IsA("BasePart") then
                root.CFrame = v.CFrame * CFrame.new(0, 3, 0)
                task.wait(0.5) -- Delay agar tidak lag
            end
        end
    end

    if Toggles.AutoFarmItem and root then
        -- Contoh Logic: Mencari part bernama "Item"
        for _, v in pairs(Workspace:GetDescendants()) do
            if v.Name == "Item" and v:IsA("BasePart") then
                root.CFrame = v.CFrame
                task.wait(0.1)
            end
        end
    end
end))

-- ESP LOGIC (Dibuat terpisah agar performa lebih baik)
table.insert(Connections, RunService.RenderStepped:Connect(function()
    -- Bersihkan ESP lama
    for i, hl in pairs(Highlights) do
        if hl then hl:Destroy() end
    end
    Highlights = {}

    -- ESP Player
    if Toggles.ESPPlayer then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                CreateESP(p.Character, Color3.fromRGB(0, 255, 0)) -- Hijau untuk Player
            end
        end
    end

    -- ESP Zombie & Item (Asumsi nama/lokasi di Workspace)
    if Toggles.ESPZombie or Toggles.ESPItem then
        for _, v in pairs(Workspace:GetDescendants()) do
            if Toggles.ESPZombie and v:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(v) then
                CreateESP(v, Color3.fromRGB(255, 0, 0)) -- Merah untuk Zombie
            end
            if Toggles.ESPItem and v.Name == "Item" and v:IsA("BasePart") then
                CreateESP(v, Color3.fromRGB(255, 255, 0)) -- Kuning untuk Item
            end
        end
    end
end))

print("Valtrix Chevion Script Loaded Successfully!")
