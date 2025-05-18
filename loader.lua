-- GMON Hub Loader 
-- LocalScript in StarterPlayerScripts

-- Tunggu game siap
 if game:IsLoaded then game.Loaded:Wait() else repeat task.wait() until (game.IsLoaded and game:IsLoaded()) 
end

local Players = game:GetService("Players") local MarketplaceService = game:GetService("MarketplaceService") local TweenService = game:GetService("TweenService") local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer local playerGui = player:WaitForChild("PlayerGui")

-- Notification fungsi local function showCenterNotification(title, message, displayTime) displayTime = displayTime or 3 local screenGui = Instance.new("ScreenGui") screenGui.Name = "CenterNotificationGui" screenGui.ResetOnSpawn = false screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 0, 0, 0)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.4
frame.BorderSizePixel = 0
frame.ZIndex = 5
frame.Parent = screenGui

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 12)

local titleLabel = Instance.new("TextLabel", frame)
titleLabel.Size = UDim2.new(1, -20, 0, 30)
titleLabel.Position = UDim2.new(0, 10, 0, 10)
titleLabel.Text = title
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.BackgroundTransparency = 1
titleLabel.TextXAlignment = Enum.TextXAlignment.Center

local msgLabel = Instance.new("TextLabel", frame)
msgLabel.Size = UDim2.new(1, -20, 0, 50)
msgLabel.Position = UDim2.new(0, 10, 0, 40)
msgLabel.Text = message
msgLabel.Font = Enum.Font.Gotham
msgLabel.TextSize = 14
msgLabel.TextColor3 = Color3.new(1, 1, 1)
msgLabel.BackgroundTransparency = 1
msgLabel.TextWrapped = true
msgLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Tween in
TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 300, 0, 100)
}):Play()

-- Delay and tween out
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

-- Mendeteksi game name local success, productInfo = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Game) end) local gameName = (success and productInfo.Name) or "Unknown Game" showCenterNotification("[Game Detected] ", gameName, 4)

-- GUI Loader local loaderGui = Instance.new("ScreenGui") loaderGui.Name = "GMON_LoaderGui" loaderGui.ResetOnSpawn = false loaderGui.Parent = playerGui

local background = Instance.new("ImageLabel", loaderGui) background.Name = "BG" background.Size = UDim2.new(1,0,1,0) background.Position = UDim2.new(0,0,0,0) background.BackgroundTransparency = 1 background.Image = "rbxassetid://16790218639" background.ScaleType = Enum.ScaleType.Crop background.ZIndex = 1

local frame = Instance.new("Frame", loaderGui) frame.Name = "MainFrame" frame.Size = UDim2.new(0, 420, 0, 200) frame.Position = UDim2.new(0.5, -210, 0.5, -100) frame.BackgroundColor3 = Color3.fromRGB(20,20,20) frame.ZIndex = 2 frame.Active = true frame.Parent = loaderGui

local uiCorner = Instance.new("UICorner", frame) uiCorner.CornerRadius = UDim.new(0,15)

local uiStroke = Instance.new("UIStroke", frame) uiStroke.Thickness = 2 uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Title local title = Instance.new("TextLabel", frame) title.Text = "GMON HUB KEY SYSTEM" title.Font = Enum.Font.GothamBold title.TextSize = 20 title.TextColor3 = Color3.new(1,1,1) title.BackgroundTransparency = 1 title.Size = UDim2.new(1,0,0,40) title.Position = UDim2.new(0,0,0,0) -- KeyBox local keyBox = Instance.new("TextBox", frame) keyBox.PlaceholderText = "Enter Your Key..." keyBox.Size = UDim2.new(0.9,0,0,35) keyBox.Position = UDim2.new(0.05,0,0.4,0) keyBox.BackgroundColor3 = Color3.fromRGB(40,40,40) keyBox.Font = Enum.Font.Gotham keyBox.TextColor3 = Color3.new(1,1,1) Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0,8)

-- Submit Button local submitBtn = Instance.new("TextButton", frame) submitBtn.Text = "Submit" submitBtn.Size = UDim2.new(0.42,0,0,35) submitBtn.Position = UDim2.new(0.05,0,0.7,0) submitBtn.BackgroundColor3 = Color3.fromRGB(0,170,127) submitBtn.Font = Enum.Font.GothamSemibold submitBtn.TextColor3 = Color3.new(1,1,1) Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0,8)

-- GetKey Button local getKeyBtn = Instance.new("TextButton", frame) getKeyBtn.Text = "Get Key" getKeyBtn.Size = UDim2.new(0.42,0,0,35) getKeyBtn.Position = UDim2.new(0.53,0,0.7,0) getKeyBtn.BackgroundColor3 = Color3.fromRGB(255,85,0) getKeyBtn.Font = Enum.Font.GothamSemibold getKeyBtn.TextColor3 = Color3.new(1,1,1) Instance.new("UICorner", getKeyBtn).CornerRadius = UDim.new(0,8) getKeyBtn.MouseButton1Click:Connect(function() setclipboard("https://linkvertise.com/1209226/get-key-gmon-hub-script") end)

-- Dragging local dragging, dragInput, dragStart, startPos local function update(input) local delta = input.Position - dragStart frame.Position = UDim2.new( startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y ) end\ nframe.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType.Touch then dragging = true\ n        dragStart = input.Position startPos = frame.Position input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end) frame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end) UIS.InputChanged:Connect(function(input) if dragging and input == dragInput then update(input) end end)

-- Game scripts mapping local GAME_SCRIPTS = { [4442272183] = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/main.lua",         -- Blox Fruits [3233893879] = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/main_arena.lua",   -- Arena [537413528]  = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/build.lua",        -- Build A Boat }

-- Valid key constant local VALID_KEY = "GmonHub311851f3c742a8f78dce99e56992555609d23497928e9b33802e7127610c2e" local keyFile = "gmon_key.txt"

-- Load script function local function loadGameScript() local url = GAME_SCRIPTS[game.PlaceId] if not url and success and productInfo and string.find(productInfo.Name, "Build A Boat") then url = GAME_SCRIPTS[537413528] end if not url then warn("GMON Loader: Game tidak dikenali", game.PlaceId) return end loadstring(game:HttpGet(url, true))() end

-- Submit key handler local function submitKey(key) if key == VALID_KEY then writefile(keyFile, key) loaderGui:Destroy() loadGameScript() return true end return false end

-- Auto-check saved key if isfile(keyFile) then local saved = readfile(keyFile) if submitKey(saved) then return end end

-- Button event\ nsubmitBtn.MouseButton1Click:Connect(function() local input = keyBox.Text if input == "" then submitBtn.Text = "Enter Key" task.wait(2) submitBtn.Text = "Submit" return end if submitKey(input) then -- success handled else submitBtn.Text = "Invalid!" task.wait(2) submitBtn.Text = "Submit" end end)

