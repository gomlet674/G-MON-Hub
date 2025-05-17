-- GMON Hub Loader with Tabbed UI and Draggable Frame -- Place this LocalScript in StarterPlayerScripts

repeat task.wait() until game:IsLoaded()

local Players            = game:GetService("Players") local MarketplaceService = game:GetService("MarketplaceService") local TweenService       = game:GetService("TweenService") local UIS                = game:GetService("UserInputService")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Center Notification Function (unchanged) ----------------------------------- local function showCenterNotification(title, message, displayTime) displayTime = displayTime or 3 local screenGui = Instance.new("ScreenGui") screenGui.Name = "CenterNotificationGui" screenGui.ResetOnSpawn = false screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 0, 0, 0)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.BackgroundTransparency = 0.4
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0,12) corner.Parent = frame
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -20, 0, 30)
titleLabel.Position = UDim2.new(0, 10, 0, 10)
titleLabel.Text = title
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.TextColor3 = Color3.new(1,1,1)
titleLabel.BackgroundTransparency = 1
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.Parent = frame

local msgLabel = Instance.new("TextLabel")
msgLabel.Size = UDim2.new(1, -20, 0, 50)
msgLabel.Position = UDim2.new(0, 10, 0, 40)
msgLabel.Text = message
msgLabel.Font = Enum.Font.Gotham
msgLabel.TextSize = 14
msgLabel.TextWrapped = true
msgLabel.TextXAlignment = Enum.TextXAlignment.Center
msgLabel.TextColor3 = Color3.new(1,1,1)
msgLabel.BackgroundTransparency = 1
msgLabel.Parent = frame

TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 300, 0, 100)
}):Play()

delay(displayTime, function()
    local tween = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    })
    tween:Play()
    tween.Completed:Connect(function()
        screenGui:Destroy()
    end)
end)

end

-- Show detected game name ---------------------------------------------------- local success, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Game) end) local gameName = success and info.Name or "Unknown Game" showCenterNotification("[Game Detected]", gameName, 4)

-- Main GUI --------------------------------------------------------------------- local ScreenGui = Instance.new("ScreenGui") ScreenGui.Name = "GMON_Hub" ScreenGui.ResetOnSpawn = false ScreenGui.Parent = game:GetService("CoreGui")

-- Draggable Frame -------------------------------------------------------------- local MainFrame = Instance.new("Frame") MainFrame.Name = "MainFrame" MainFrame.Size = UDim2.new(0, 450, 0, 300) MainFrame.Position = UDim2.new(0.5, -225, 0.5, -150) MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20) MainFrame.Active = true MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", MainFrame) UICorner.CornerRadius = UDim.new(0, 12)

-- Drag functionality local dragging, dragInput, dragStart, startPos local function update(input) local delta = input.Position - dragStart MainFrame.Position = UDim2.new( startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y ) end MainFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true dragStart = input.Position startPos = MainFrame.Position input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end) MainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end) UIS.InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end)

-- Tab Buttons Container ------------------------------------------------------- local TabBar = Instance.new("Frame") TabBar.Name = "TabBar" TabBar.Parent = MainFrame TabBar.Size = UDim2.new(1, 0, 0, 40) TabBar.BackgroundTransparency = 1

local function createTabButton(name, index) local btn = Instance.new("TextButton") btn.Name = name .. "Tab" btn.Parent = TabBar btn.Size = UDim2.new(0, 100, 1, 0) btn.Position = UDim2.new(0, (index-1)*100, 0, 0) btn.Text = name btn.Font = Enum.Font.GothamBold btn.TextSize = 16 btn.TextColor3 = Color3.new(1,1,1) btn.BackgroundTransparency = 1 return btn end

-- Create tabs: Home, Console, Settings ------------------------------------------------ local tabs = {"Home","Console","Settings"} local contentFrames = {} for i, tName in ipairs(tabs) do -- Button local btn = createTabButton(tName, i) -- Content Frame local content = Instance.new("Frame") content.Name = tName .. "Content" content.Parent = MainFrame content.Size = UDim2.new(1, -20, 1, -60) content.Position = UDim2.new(0, 10, 0, 50) content.BackgroundTransparency = 1 content.Visible = (i == 1) -- only first tab visible initially contentFrames[tName] = content

-- Connect button click
btn.MouseButton1Click:Connect(function()
    for _, f in pairs(contentFrames) do f.Visible = false end
    content.Visible = true
end)

end

-- Placeholder: Home Tab -------------------------------------------------------- local homeLabel = Instance.new("TextLabel") homeLabel.Parent = contentFrames["Home"] homeLabel.Size = UDim2.new(1,0,0,30) homeLabel.Position = UDim2.new(0,0,0,0) homeLabel.BackgroundTransparency = 1 homeLabel.Font = Enum.Font.GothamBold homeLabel.TextSize = 18 homeLabel.TextColor3 = Color3.new(1,1,1) homeLabel.Text = "Welcome to GMON Hub"

-- Placeholder: Console Tab (you can insert your console GUI here) ---------------- --[[ contentFrames["Console"]:Add your Console UI elements, e.g. a ScrollingFrame, TextLabels, SearchBox, etc. ]]

-- Placeholder: Settings Tab --------------------------------------------------- --[[ contentFrames["Settings"]:Add toggles, sliders, keybind inputs, etc. ]]

-- End of Script ----------------------------------------------------------------

