-- loader.lua
-- LocalScript in StarterPlayerScripts

-- 1) Tunggu game benar-benar siap
repeat task.wait() until game:IsLoaded()

-- Services
local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService       = game:GetService("TweenService")
local SoundService       = game:GetService("SoundService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Util: notifikasi tengah layar
local function notifyCenter(text, duration)
    duration = duration or 3
    local gui = Instance.new("ScreenGui")
    gui.Name = "GMonNotify"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 300, 0, 60)
    frame.Position = UDim2.new(0.5, -150, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.BackgroundTransparency = 0.2
    frame.ZIndex = 50
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1,-20,1,-20)
    label.Position = UDim2.new(0,10,0,10)
    label.Text = text
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 18
    label.TextColor3 = Color3.new(1,1,1)
    label.BackgroundTransparency = 1
    label.TextWrapped = true

    -- tween keluar
    task.delay(duration, function()
        TweenService:Create(frame, TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
        TweenService:Create(label, TweenInfo.new(0.4), {TextTransparency=1}):Play()
        frame:TweenSize(UDim2.new(0,0,0,0), "In", "Quad", 0.4, true, function()
            gui:Destroy()
        end)
    end)
end

-- 2) Tampilkan notifikasi game & player count
local ok, info = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Game)
end)
local gameName = ok and info.Name or "Unknown Game"
local playerCount = #Players:GetPlayers()
notifyCenter(("Game: %s  |  Players: %d"):format(gameName, playerCount), 4)

-- 3) Siapkan UI Loader
local loaderGui = Instance.new("ScreenGui")
loaderGui.Name = "GMonLoaderUI"
loaderGui.ResetOnSpawn = false
loaderGui.Parent = playerGui

-- suara buka UI
local sOpen = Instance.new("Sound", SoundService)
sOpen.SoundId = "rbxassetid://183763515" -- UI click
sOpen.Volume  = 0.5
sOpen:Play()

-- overlay gelap
local overlay = Instance.new("Frame", loaderGui)
overlay.Size = UDim2.new(1,0,1,0)
overlay.BackgroundColor3 = Color3.new(0,0,0)
overlay.BackgroundTransparency = 0.6
overlay.ZIndex = 1

-- container utama
local frameUI = Instance.new("Frame", loaderGui)
frameUI.Name = "Container"
frameUI.Size = UDim2.new(0,360,0,180)
frameUI.Position = UDim2.new(0.5,-180,0.5,-90)
frameUI.BackgroundColor3 = Color3.fromRGB(25,25,25)
frameUI.ZIndex = 2
Instance.new("UICorner", frameUI).CornerRadius = UDim.new(0,10)

-- Title
local title = Instance.new("TextLabel", frameUI)
title.Size = UDim2.new(1,0,0,36)
title.Position = UDim2.new(0,0,0,0)
title.Text = "G-Mon Hub"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1

-- Tombol [×] close
local closeBtn = Instance.new("TextButton", frameUI)
closeBtn.Size = UDim2.new(0,32,0,32)
closeBtn.Position = UDim2.new(1,-36,0,4)
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 24
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BackgroundTransparency = 1
closeBtn.ZIndex = 3
closeBtn.MouseButton1Click:Connect(function()
    loaderGui:Destroy()
end)

-- TextBox enter key
local keyBox = Instance.new("TextBox", frameUI)
keyBox.Size = UDim2.new(0.9,0,0,32)
keyBox.Position = UDim2.new(0.05,0,0,50)
keyBox.PlaceholderText = "Enter your key..."
keyBox.ClearTextOnFocus = false
keyBox.Font = Enum.Font.Gotham
keyBox.TextColor3 = Color3.new(1,1,1)
keyBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0,6)

-- Tombol Get Key
local getBtn = Instance.new("TextButton", frameUI)
getBtn.Size = UDim2.new(0.4,0,0,30)
getBtn.Position = UDim2.new(0.05,0,1,-50)
getBtn.Text = "Get Key"
getBtn.Font = Enum.Font.GothamSemibold
getBtn.TextSize = 16
getBtn.TextColor3 = Color3.new(1,1,1)
getBtn.BackgroundColor3 = Color3.fromRGB(255,85,0)
Instance.new("UICorner", getBtn).CornerRadius = UDim.new(0,6)
getBtn.MouseButton1Click:Connect(function()
    setclipboard("https://linkvertise.com/1209226/get-key-gmon-hub-script")
    notifyCenter("Link key disalin!",2)
end)

-- Tombol Submit
local submitBtn = Instance.new("TextButton", frameUI)
submitBtn.Size = UDim2.new(0.4,0,0,30)
submitBtn.Position = UDim2.new(0.55,0,1,-50)
submitBtn.Text = "Submit"
submitBtn.Font = Enum.Font.GothamSemibold
submitBtn.TextSize = 16
submitBtn.TextColor3 = Color3.new(1,1,1)
submitBtn.BackgroundColor3 = Color3.fromRGB(0,170,127)
Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0,6)

-- Constant valid key
local VALID_KEY = "GmonHub311851f3c742a8f78dce99e56992555609d23497928e9b33802e7127610c2e"

-- Ketika tekan submit
submitBtn.MouseButton1Click:Connect(function()
    local entered = keyBox.Text:match("%S+") or ""
    if entered == "" then
        notifyCenter("Please enter a key!",2)
        return
    end
    if entered == VALID_KEY then
        -- suara success
        local sOK = Instance.new("Sound", SoundService)
        sOK.SoundId = "rbxassetid://154965325"
        sOK.Volume  = 0.6
        sOK:Play()

        notifyCenter("Roblox G-Mon Hub, wait a moment...",3)
        -- delay sebelum load
        task.delay(3, function()
            loaderGui:Destroy()
            local mainURL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/main.lua"
            local ok2, err = pcall(function()
                loadstring(game:HttpGet(mainURL, true))()
            end)
            if not ok2 then warn("[GMON Loader] load main.lua error:", err) end
        end)
    else
        notifyCenter("Invalid Key!",2)
    end
end)