-- loader.lua
-- LocalScript in StarterPlayerScripts

-- Services
local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService       = game:GetService("TweenService")
local SoundService       = game:GetService("SoundService")

-- Wait until game is fully loaded
repeat task.wait() until game:IsLoaded()

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- === 1) Top‐Center Notification ===
local function notifyCenter(text, duration)
    duration = duration or 3
    local gui = Instance.new("ScreenGui", playerGui)
    gui.Name = "GMON_NotifyCenter"
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0,300,0,60)
    frame.Position = UDim2.new(0.5,-150,0,20)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.BackgroundTransparency = 0.1
    frame.ZIndex = 50
    Instance.new("UICorner",frame).CornerRadius = UDim.new(0,8)

    local label = Instance.new("TextLabel",frame)
    label.Size              = UDim2.new(1,-20,1,-20)
    label.Position          = UDim2.new(0,10,0,10)
    label.Text              = text
    label.Font              = Enum.Font.GothamSemibold
    label.TextSize          = 18
    label.TextColor3        = Color3.new(1,1,1)
    label.BackgroundTransparency = 1
    label.TextWrapped       = true

    -- tween fade out
    task.delay(duration, function()
        TweenService:Create(frame, TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
        TweenService:Create(label, TweenInfo.new(0.4), {TextTransparency=1}):Play()
        frame:TweenSize(UDim2.new(0,0,0,0), Enum.EasingDirection.In, Enum.EasingStyle.Quad,0.4,true, function()
            gui:Destroy()
        end)
    end)
end

-- Show detected game name and player count
local success, info = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Game)
end)
local name = success and info.Name or "Unknown Game"
local count = #Players:GetPlayers()
notifyCenter(("Game: %s  |  Players: %d"):format(name, count), 4)

-- === 2) Loader UI ===
local loaderGui = Instance.new("ScreenGui", playerGui)
loaderGui.Name = "GMON_LoaderUI"
loaderGui.ResetOnSpawn = false

-- UI Sound (open)
local openSound = Instance.new("Sound", SoundService)
openSound.SoundId = "rbxassetid://183763515" -- UI Click sound
openSound.Volume  = 0.5
openSound:Play()

-- dark overlay
local overlay = Instance.new("Frame", loaderGui)
overlay.Size = UDim2.new(1,0,1,0)
overlay.BackgroundColor3 = Color3.new(0,0,0)
overlay.BackgroundTransparency = 0.6
overlay.ZIndex = 1

-- container
local frame = Instance.new("Frame", loaderGui)
frame.Name  = "Container"
frame.Size  = UDim2.new(0,360,0,180)
frame.Position = UDim2.new(0.5,-180,0.5,-90)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.ZIndex = 2
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

-- title
local title = Instance.new("TextLabel", frame)
title.Size     = UDim2.new(1,0,0,36)
title.Position = UDim2.new(0,0,0,0)
title.Text     = "G-Mon Hub"
title.Font     = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1

-- close [×]
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size     = UDim2.new(0,32,0,32)
closeBtn.Position = UDim2.new(1,-36,0,4)
closeBtn.Text     = "×"
closeBtn.Font     = Enum.Font.GothamBold
closeBtn.TextSize = 24
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BackgroundTransparency = 1
closeBtn.ZIndex   = 3
closeBtn.MouseButton1Click:Connect(function()
    loaderGui:Destroy()
end)

-- key input
local keyBox = Instance.new("TextBox", frame)
keyBox.Size             = UDim2.new(0.9,0,0,32)
keyBox.Position         = UDim2.new(0.05,0,0,50)
keyBox.PlaceholderText  = "Enter your key..."
keyBox.ClearTextOnFocus = false
keyBox.Font             = Enum.Font.Gotham
keyBox.TextColor3       = Color3.new(1,1,1)
keyBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0,6)

-- get key button
local getBtn = Instance.new("TextButton", frame)
getBtn.Size     = UDim2.new(0.4,0,0,30)
getBtn.Position = UDim2.new(0.05,0,1,-50)
getBtn.Text     = "Get Key"
getBtn.Font     = Enum.Font.GothamSemibold
getBtn.TextSize = 16
getBtn.TextColor3 = Color3.new(1,1,1)
getBtn.BackgroundColor3 = Color3.fromRGB(255,85,0)
Instance.new("UICorner", getBtn).CornerRadius = UDim.new(0,6)
getBtn.MouseButton1Click:Connect(function()
    setclipboard("https://linkvertise.com/1209226/get-key-gmon-hub-script")
    notifyCenter("Link key telah disalin!", 2)
end)

-- submit button
local submitBtn = Instance.new("TextButton", frame)
submitBtn.Size     = UDim2.new(0.4,0,0,30)
submitBtn.Position = UDim2.new(0.55,0,1,-50)
submitBtn.Text     = "Submit"
submitBtn.Font     = Enum.Font.GothamSemibold
submitBtn.TextSize = 16
submitBtn.TextColor3 = Color3.new(1,1,1)
submitBtn.BackgroundColor3 = Color3.fromRGB(0,170,127)
Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0,6)

-- valid key constant
local VALID_KEY = "GmonHub311851f3c742a8f78dce99e56992555609d23497928e9b33802e7127610c2e"

-- on submit
submitBtn.MouseButton1Click:Connect(function()
    local entered = keyBox.Text:match("%S+") or ""
    if entered == "" then
        notifyCenter("Enter a key first!", 2)
        return
    end
    if entered == VALID_KEY then
        -- sound success
        local s = Instance.new("Sound", SoundService)
        s.SoundId = "rbxassetid://154965325" -- UI Accept sound
        s.Volume  = 0.6
        s:Play()

        notifyCenter("Roblox G-Mon Hub, wait a moment...", 3)
        task.delay(3, function()
            loaderGui:Destroy()
            -- load main script
            local mainURL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/main.lua"
            local ok, err = pcall(function()
                loadstring(game:HttpGet(mainURL, true))()
            end)
            if not ok then
                warn("[GMON Loader] Failed to load main.lua:", err)
            end
        end)
    else
        notifyCenter("Invalid Key!", 2)
    end
end)