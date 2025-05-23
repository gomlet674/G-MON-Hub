-- loader.lua
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI Notifikasi putih transparan dengan RGB border + animasi
local function showCustomNotification(text, duration)
    local screenGui = Instance.new("ScreenGui", playerGui)
    screenGui.Name = "CustomNotify"
    screenGui.ResetOnSpawn = false

    local frame = Instance.new("Frame", screenGui)
    frame.Size = UDim2.new(0, 300, 0, 80)
    frame.Position = UDim2.new(0.5, -150, 0, -100)
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0

    local uiStroke = Instance.new("UIStroke", frame)
    uiStroke.Thickness = 2
    uiStroke.Color = Color3.fromRGB(255, 0, 0)

    task.spawn(function()
        while frame.Parent do
            for i = 0, 1, 0.01 do
                uiStroke.Color = Color3.fromHSV(i, 1, 1)
                task.wait()
            end
        end
    end)

    local uicorner = Instance.new("UICorner", frame)
    uicorner.CornerRadius = UDim.new(1, 999)

    local textLabel = Instance.new("TextLabel", frame)
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextScaled = false
    textLabel.TextSize = 16
    textLabel.Font = Enum.Font.GothamBold

    local tweenIn = TweenService:Create(frame, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
        Position = UDim2.new(0.5, -150, 0.15, 0)
    })
    tweenIn:Play()
    tweenIn.Completed:Wait()

    task.wait(duration or 5)

    local tweenOut = TweenService:Create(frame, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
        Position = UDim2.new(0.5, -150, -0.2, 0)
    })
    tweenOut:Play()
    tweenOut.Completed:Wait()

    screenGui:Destroy()
end

-- Ambil nama game
local success, info = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId)
end)

local gameName = success and info.Name or "Unknown Game"
local playerCount = #Players:GetPlayers()
showCustomNotification(gameName .. " | Players: " .. playerCount, 5)

task.wait(5.5)

-- Jalankan G-Mon-Key.lua
local success, err = pcall(function()
    local keySource = game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/G-Mon-Key.lua")
    loadstring(keySource)()
end)

if not success then
    warn("GMonKey error:", err)
end