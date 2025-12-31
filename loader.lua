-- loader.lua (UPGRADED NOTIFICATION)

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===============================
-- SMART NOTIFICATION UI
-- ===============================
local function showSmartNotification(text, duration)
    duration = duration or 4

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GMonSmartNotify"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui

    -- Hitung ukuran teks
    local textSize = TextService:GetTextSize(
        text,
        16,
        Enum.Font.GothamBold,
        Vector2.new(600, math.huge)
    )

    local paddingX = 40
    local paddingY = 24

    local frameWidth = math.clamp(textSize.X + paddingX, 220, 520)
    local frameHeight = math.clamp(textSize.Y + paddingY, 60, 140)

    local frame = Instance.new("Frame")
    frame.Parent = screenGui
    frame.Size = UDim2.new(0, frameWidth, 0, frameHeight)
    frame.Position = UDim2.new(0.5, -frameWidth/2, 0, -frameHeight - 20)
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.BackgroundTransparency = 0.45
    frame.BorderSizePixel = 0

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 24)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Thickness = 2

    -- RGB Border animasi
    task.spawn(function()
        local h = 0
        while frame.Parent do
            h = (h + 0.005) % 1
            stroke.Color = Color3.fromHSV(h, 1, 1)
            task.wait(0.03)
        end
    end)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Size = UDim2.new(1, -20, 1, -16)
    label.Position = UDim2.new(0, 10, 0, 8)
    label.BackgroundTransparency = 1
    label.TextWrapped = true
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Text = text
    label.TextColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16

    -- ===============================
    -- ANIMASI MASUK (CURVE HALUS)
    -- ===============================
    local tweenIn = TweenService:Create(
        frame,
        TweenInfo.new(
            0.9,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        ),
        {
            Position = UDim2.new(0.5, -frameWidth/2, 0.12, 0)
        }
    )

    tweenIn:Play()
    tweenIn.Completed:Wait()

    task.wait(duration)

    -- ===============================
    -- ANIMASI KELUAR (NAIK KE ATAS LAYAR)
    -- ===============================
    local tweenOut = TweenService:Create(
        frame,
        TweenInfo.new(
            0.9,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.In
        ),
        {
            Position = UDim2.new(0.5, -frameWidth/2, 0, -frameHeight - 60)
        }
    )

    tweenOut:Play()
    tweenOut.Completed:Wait()

    screenGui:Destroy()
end

-- ===============================
-- INFO GAME
-- ===============================
local success, info = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId)
end)

local gameName = success and info.Name or "Unknown Game"
local playerCount = #Players:GetPlayers()

showSmartNotification(
    gameName .. "  |  Players: " .. playerCount,
    4.5
)

task.wait(5)

-- ===============================
-- LOAD KEY SYSTEM
-- ===============================
local ok, err = pcall(function()
    loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/G-Mon-Key.lua"
    ))()
end)

if not ok then
    warn("GMonKey error:", err)
end
