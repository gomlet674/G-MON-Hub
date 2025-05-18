repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Notifikasi tengah layar
local success, _ = pcall(function()
    dofile("rbxassetid://<PATH>/CenterNotifier.lua")  -- ganti <PATH> sesuai ID asset
end)

local function notify(text, dur)
    if typeof(showCenterNotification) == "function" then
        showCenterNotification("Detected", text, dur)
    else
        print("[Notify] " .. text)
    end
end

-- Deteksi info game
local ok, info = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Game)
end)
local name = ok and info.Name or MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Place).Name
local count = #Players:GetPlayers()
notify(name .. " | Players: " .. count, 4)

-- Tambahkan UI Deteksi RGB animasi
local function createDetectUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DetectUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 150, 0, 150)
    frame.Position = UDim2.new(0.5, -75, -1, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame

    local rgbOutline = Instance.new("UIStroke")
    rgbOutline.Thickness = 4
    rgbOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    rgbOutline.Parent = frame

    -- RGB animasi
    local hue = 0
    task.spawn(function()
        while frame.Parent do
            rgbOutline.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV((hue + 0.2) % 1, 1, 1))
            }
            hue = (hue + 0.01) % 1
            task.wait(0.05)
        end
    end)

    -- Tween masuk (slide dari atas)
    local tweenIn = TweenService:Create(frame, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -75, 0.2, 0)
    })
    tweenIn:Play()
    tweenIn.Completed:Wait()

    -- Tunggu 5 detik
    task.wait(5)

    -- Tween keluar (naik ke atas lagi)
    local tweenOut = TweenService:Create(frame, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -75, -1, 0)
    })
    tweenOut:Play()
    tweenOut.Completed:Wait()

    screenGui:Destroy()
end

createDetectUI()

-- Tunggu animasi selesai total
task.wait(0.2)

-- Panggil key UI dari GitHub (raw link)
local url = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/G-Mon-Key.lua"
local keyScript = Instance.new("LocalScript")
keyScript.Source = game:HttpGet(url, true)
keyScript.Name = "GMonKeyScript"
keyScript.Parent = playerGui