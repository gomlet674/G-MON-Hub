-- loader.lua
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Fungsi untuk menampilkan notifikasi dengan animasi
local function showCenterNotification(title, message, displayTime)
    displayTime = displayTime or 3
    local gui = Instance.new("ScreenGui", playerGui)
    gui.Name = "CenterNotificationGui"
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 300, 0, 100)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0, -100)
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 50)

    local border = Instance.new("UIStroke", frame)
    border.Thickness = 3
    border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    task.spawn(function()
        while frame.Parent do
            for i = 0, 1, 0.01 do
                border.Color = Color3.fromHSV(i, 1, 1)
                task.wait(0.02)
            end
        end
    end)

    local titleLabel = Instance.new("TextLabel", frame)
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 18
    titleLabel.TextColor3 = Color3.new(0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center

    local msgLabel = Instance.new("TextLabel", frame)
    msgLabel.Size = UDim2.new(1, -20, 0, 50)
    msgLabel.Position = UDim2.new(0, 10, 0, 40)
    msgLabel.Text = message
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 14
    msgLabel.TextColor3 = Color3.new(0, 0, 0)
    msgLabel.BackgroundTransparency = 1
    msgLabel.TextWrapped = true
    msgLabel.TextXAlignment = Enum.TextXAlignment.Center

    -- Animasi masuk
    TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.3, 0)
    }):Play()

    -- Animasi keluar setelah displayTime detik
    delay(displayTime, function()
        TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 0, -100),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.35)
        gui:Destroy()
    end)
end

-- Deteksi nama game dan jumlah pemain
local ok, info = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Game)
end)
local name = ok and info.Name or MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Place).Name
local count = #Players:GetPlayers()
showCenterNotification("Detected", name .. " | Players: " .. count, 5)

-- Tunggu animasi notifikasi selesai
task.wait(5.4)

-- Panggil UI key
local keyScript = Instance.new("LocalScript")
keyScript.Source = game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/G-Mon-Key.lua", true)
keyScript.Parent = playerGui