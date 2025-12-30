-- Fly GUI (Custom, scrollable panels)
-- Place as LocalScript in StarterPlayer > StarterPlayerScripts
-- AUTHOR: (you) - edit as needed
-- WARNING: For educational/testing in your own game only.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- CONFIG DEFAULTS
local defaultKeybind = Enum.KeyCode.F
local defaultSpeed = 80
local minSpeed, maxSpeed = 10, 200
local defaultSmooth = 0.18 -- lower = snappier

-- state
local flying = false
local speed = defaultSpeed
local smooth = defaultSmooth
local keybind = defaultKeybind
local bodyGyro, bodyVelocity
local control = {F=0,B=0,L=0,R=0,U=0,D=0}

-- Helper: create UI
local function new(class, props)
	local obj = Instance.new(class)
	for k,v in pairs(props or {}) do
		if k == "Parent" then
			obj.Parent = v
		else
			obj[k] = v
		end
	end
	return obj
end

-- prevent duplicate GUI
local existing = playerGui:FindFirstChild("FlyControlGui")
if existing then existing:Destroy() end

local screenGui = new("ScreenGui", {Name="FlyControlGui", Parent=playerGui, ZIndexBehavior=Enum.ZIndexBehavior.Sibling})

-- Main window
local window = new("Frame", {
	Parent = screenGui,
	Name = "Window",
	AnchorPoint = Vector2.new(0.5,0.5),
	Position = UDim2.new(0.5,0.5,0.5,0),
	Size = UDim2.new(0.72,0,0.72,0),
	BackgroundColor3 = Color3.fromRGB(30,30,30),
	BackgroundTransparency = 0.06,
	BorderSizePixel = 0,
})
new("UICorner", {Parent = window, CornerRadius = UDim.new(0,12)})

-- Left menu
local leftPanel = new("Frame", {
	Parent = window,
	Name = "LeftPanel",
	Size = UDim2.new(0,260,1,0),
	Position = UDim2.new(0,0,0,0),
	BackgroundColor3 = Color3.fromRGB(22,22,22),
})
new("UICorner", {Parent = leftPanel, CornerRadius = UDim.new(0,12)})
local leftTitle = new("TextLabel", {
	Parent = leftPanel,
	Size = UDim2.new(1,0,0,48),
	BackgroundTransparency = 1,
	Text = "Ganteng Hub",
	TextColor3 = Color3.fromRGB(240,240,240),
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextStrokeTransparency = 0.8,
	Padding = Enum.PaddingSettings.new(),
})
leftTitle.Position = UDim2.new(0,18,0,10)

-- Left scrolling list
local leftScroll = new("ScrollingFrame", {
	Parent = leftPanel,
	Name = "MenuList",
	Position = UDim2.new(0,8,0,64),
	Size = UDim2.new(1,-16,1,-72),
	CanvasSize = UDim2.new(0,0,0,0),
	BackgroundTransparency = 1,
	ScrollBarThickness = 6,
})
local leftUIList = new("UIListLayout", {Parent = leftScroll, Padding = UDim.new(0,6), FillDirection = Enum.FillDirection.Vertical})
leftUIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
leftUIList.SortOrder = Enum.SortOrder.LayoutOrder

-- function to create left menu button
local function createMenuButton(text, index)
	local f = new("Frame", {Parent = leftScroll, Size = UDim2.new(1, -12, 0, 46), BackgroundTransparency = 1})
	local btn = new("TextButton", {
		Parent = f,
		Size = UDim2.new(1,0,1,0),
		Text = text,
		BackgroundColor3 = Color3.fromRGB(42,42,42),
		TextColor3 = Color3.fromRGB(240,240,240),
		Font = Enum.Font.Gotham,
		TextSize = 16,
		BorderSizePixel = 0,
		Name = "MenuBtn_"..tostring(index),
		AutoButtonColor = true,
	})
	new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,8)})
	return btn
end

local menus = {"Main", "Settings", "Controls", "About"}
local leftButtons = {}
for i,m in ipairs(menus) do
	local b = createMenuButton(m, i)
	leftButtons[m] = b
end

-- Update canvas size dynamically
leftScroll.ChildAdded:Connect(function()
	leftScroll.CanvasSize = UDim2.new(0,0,0,leftUIList.AbsoluteContentSize + 8)
end)

-- Right panel
local rightPanel = new("Frame", {
	Parent = window,
	Name = "RightPanel",
	Position = UDim2.new(0,260,0,0),
	Size = UDim2.new(1,-260,1,0),
	BackgroundTransparency = 1
})
local rightHeader = new("Frame", {Parent = rightPanel, Size = UDim2.new(1,0,0,62), BackgroundColor3 = Color3.fromRGB(24,24,24)})
new("UICorner", {Parent = rightHeader, CornerRadius = UDim.new(0,10)})
local headerText = new("TextLabel", {
	Parent = rightHeader,
	Size = UDim2.new(1,-44,1,0),
	Position = UDim2.new(0,18,0,0),
	Text = "Main",
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(245,245,245),
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
})
-- Close button
local closeBtn = new("TextButton", {
	Parent = rightHeader,
	Size = UDim2.new(0,36,0,36),
	Position = UDim2.new(1,-44,0,12),
	Text = "X",
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	BackgroundColor3 = Color3.fromRGB(50,50,50),
	TextColor3 = Color3.fromRGB(255,255,255),
})
new("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(0,8)})

-- Right scroll area for options
local rightScroll = new("ScrollingFrame", {
	Parent = rightPanel,
	Position = UDim2.new(0,12,0,72),
	Size = UDim2.new(1,-24,1,-84),
	CanvasSize = UDim2.new(0,0,0,0),
	BackgroundTransparency = 1,
	ScrollBarThickness = 10,
})
local rightList = new("UIListLayout", {Parent = rightScroll, Padding = UDim.new(0,10)})
rightList.SortOrder = Enum.SortOrder.LayoutOrder
rightScroll.ChildAdded:Connect(function()
	rightScroll.CanvasSize = UDim2.new(0,0,0,rightList.AbsoluteContentSize + 12)
end)

-- UI helpers for option rows
local function createSectionTitle(text)
	local lbl = new("TextLabel", {
		Parent = rightScroll,
		Size = UDim2.new(1,0,0,30),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Color3.fromRGB(220,220,220),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	return lbl
end

local function createToggleRow(text, initial, callback)
	local row = new("Frame", {Parent = rightScroll, Size = UDim2.new(1,0,0,46), BackgroundTransparency = 1})
	local label = new("TextLabel", {
		Parent = row, Size = UDim2.new(0.7,0,1,0), BackgroundTransparency = 1,
		Text = text, TextColor3 = Color3.fromRGB(230,230,230), Font = Enum.Font.Gotham, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left
	})
	local tbtn = new("TextButton", {
		Parent = row, Size = UDim2.new(0,72,0,32), Position = UDim2.new(1,-76,0.5,-16),
		Text = (initial and "ON" or "OFF"), BackgroundColor3 = (initial and Color3.fromRGB(30,150,70) or Color3.fromRGB(60,60,60)),
		TextColor3 = Color3.fromRGB(240,240,240), Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0
	})
	new("UICorner", {Parent = tbtn, CornerRadius = UDim.new(0,8)})
	tbtn.MouseButton1Click:Connect(function()
		local newv = not (tbtn.Text == "ON")
		tbtn.Text = (newv and "ON" or "OFF")
		tbtn.BackgroundColor3 = (newv and Color3.fromRGB(30,150,70) or Color3.fromRGB(60,60,60))
		callback(newv)
	end)
	return row, tbtn
end

local function createSliderRow(text, min, max, init, callback)
	local row = new("Frame", {Parent = rightScroll, Size = UDim2.new(1,0,0,66), BackgroundTransparency = 1})
	new("TextLabel", {
		Parent = row, Size = UDim2.new(1,0,0,18), Position = UDim2.new(0,0,0,0),
		Text = text, BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(230,230,230), Font = Enum.Font.Gotham, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left
	})
	local sliderFrame = new("Frame", {Parent = row, Size = UDim2.new(1,0,0,36), Position = UDim2.new(0,0,0,26), BackgroundColor3 = Color3.fromRGB(40,40,40), BorderSizePixel=0})
	new("UICorner", {Parent = sliderFrame, CornerRadius = UDim.new(0,8)})
	local fill = new("Frame", {Parent = sliderFrame, Size = UDim2.new( (init-min)/(max-min), 0, 1,0), BackgroundColor3 = Color3.fromRGB(100,150,255)})
	new("UICorner", {Parent = fill, CornerRadius = UDim.new(0,8)})
	local knob = new("ImageButton", {Parent = sliderFrame, Size = UDim2.new(0,0,1,0), Image = "", BackgroundColor3 = Color3.fromRGB(230,230,230), BorderSizePixel=0})
	new("UICorner", {Parent = knob, CornerRadius = UDim.new(0,16)})
	knob.Size = UDim2.new(0,18,0,18)
	knob.Position = UDim2.new(fill.Size.X.Scale, -9, 0.5, -9)
	local valueLabel = new("TextLabel", {Parent = row, Size = UDim2.new(0,80,0,18), Position = UDim2.new(1,-84,0,2), BackgroundTransparency = 1, Text = tostring(init), TextColor3 = Color3.fromRGB(230,230,230), Font = Enum.Font.GothamBold, TextSize = 14})
	-- drag logic
	local dragging = false
	local function updateFromX(x)
		local rel = math.clamp((x - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
		fill.Size = UDim2.new(rel,0,1,0)
		knob.Position = UDim2.new(rel, -9, 0.5, -9)
		local val = (min + (max-min)*rel)
		if typeof(init) == "number" then
			local rounded = math.floor(val + 0.5)
			valueLabel.Text = tostring(rounded)
			callback(rounded)
		else
			valueLabel.Text = string.format("%.2f", val)
			callback(val)
		end
	end
	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateFromX(input.Position.X)
		end
	end)
	sliderFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			updateFromX(input.Position.X)
		end
	end)
	-- init
	updateFromX(sliderFrame.AbsolutePosition.X + sliderFrame.AbsoluteSize.X * ((init-min)/(max-min)))
	return row, valueLabel
end

-- Create option rows for each menu
local function buildMainOptions()
	rightScroll:ClearAllChildren()
	rightList = new("UIListLayout", {Parent = rightScroll, Padding = UDim.new(0,10)})
	rightList.SortOrder = Enum.SortOrder.LayoutOrder

	createSectionTitle("Fly Controls")
	local toggleRow, toggleBtn = createToggleRow("Enable Fly (Key: F)", false, function(v)
		-- toggle fly from UI
		if v then
			flying = true
			startFly()
		else
			flying = false
			stopFly()
		end
	end)
	-- sync toggle text later
	local sliderRow, speedValue = createSliderRow("Speed", minSpeed, maxSpeed, speed, function(v)
		speed = v
	end)
	local smoothRow, smoothValue = createSliderRow("Smoothness (lower = snappier)", 0.02, 0.6, smooth, function(v)
		smooth = v
	end)
	-- small spacing UI
	local info = new("TextLabel", {Parent = rightScroll, Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1, Text = "Use key F to toggle fly. WASD to move, Space to go up, LeftCtrl to go down.", TextColor3 = Color3.fromRGB(200,200,200), Font = Enum.Font.Gotham, TextSize = 14, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left})
	-- ensure toggle reflects current state
	spawn(function()
		wait(0.05)
		toggleBtn.Text = (flying and "ON" or "OFF")
		toggleBtn.BackgroundColor3 = (flying and Color3.fromRGB(30,150,70) or Color3.fromRGB(60,60,60))
	end)
end

local function buildSettingsOptions()
	rightScroll:ClearAllChildren()
	rightList = new("UIListLayout", {Parent = rightScroll, Padding = UDim.new(0,10)})
	rightList.SortOrder = Enum.SortOrder.LayoutOrder
	createSectionTitle("Settings")
	createSectionTitle("UI")
	local row = new("Frame", {Parent = rightScroll, Size = UDim2.new(1,0,0,46), BackgroundTransparency = 1})
	new("TextLabel", {Parent = row, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "Window can be dragged from header. Close button on top right.", TextColor3 = Color3.fromRGB(200,200,200), Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
	createSectionTitle("Advanced")
	local _, v1 = createSliderRow("Max Speed", minSpeed, maxSpeed, speed, function(v) speed = v end)
	local _, v2 = createSliderRow("Smoothness", 0.02, 0.6, smooth, function(v) smooth = v end)
end

local function buildControlsOptions()
	rightScroll:ClearAllChildren()
	rightList = new("UIListLayout", {Parent = rightScroll, Padding = UDim.new(0,10)})
	rightList.SortOrder = Enum.SortOrder.LayoutOrder
	createSectionTitle("Controls")
	local keysText = "Toggle Key: F\nMove: W A S D\nUp: Space\nDown: LeftCtrl"
	local lbl = new("TextLabel", {Parent = rightScroll, Size = UDim2.new(1,0,0,96), BackgroundTransparency = 1, Text = keysText, TextColor3 = Color3.fromRGB(220,220,220), Font = Enum.Font.Gotham, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left})
end

local function buildAboutOptions()
	rightScroll:ClearAllChildren()
	rightList = new("UIListLayout", {Parent = rightScroll, Padding = UDim.new(0,10)})
	rightList.SortOrder = Enum.SortOrder.LayoutOrder
	createSectionTitle("About")
	local aboutTxt = "Fly Controller GUI\nFor educational/testing only. Author: You.\nDo not use to cheat in other people's games."
	local lbl = new("TextLabel", {Parent = rightScroll, Size = UDim2.new(1,0,0,120), BackgroundTransparency = 1, Text = aboutTxt, TextWrapped = true, TextColor3 = Color3.fromRGB(220,220,220), Font = Enum.Font.Gotham, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left})
end

-- menu click logic
local function setActiveMenu(name)
	headerText.Text = name
	if name == "Main" then
		buildMainOptions()
	elseif name == "Settings" then
		buildSettingsOptions()
	elseif name == "Controls" then
		buildControlsOptions()
	elseif name == "About" then
		buildAboutOptions()
	end
end

for name,btn in pairs(leftButtons) do
	btn.MouseButton1Click:Connect(function()
		setActiveMenu(btn.Text)
	end)
end

setActiveMenu("Main")

-- close button
closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

-- dragging the main window from header
do
	local dragging = false
	local dragInput, dragStart, startPos
	local function update(input)
		local delta = input.Position - dragStart
		window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	rightHeader.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = window.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	rightHeader.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

-- FLY LOGIC
local function startFly()
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- cleanup if existing
	if bodyGyro then bodyGyro:Destroy() end
	if bodyVelocity then bodyVelocity:Destroy() end

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.P = 9e4
	bodyGyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
	bodyGyro.CFrame = hrp.CFrame
	bodyGyro.Parent = hrp

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(9e9,9e9,9e9)
	bodyVelocity.Velocity = Vector3.new(0,0,0)
	bodyVelocity.Parent = hrp
end

local function stopFly()
	if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
	if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
end

-- movement loop
local lastCameraCFrame = nil
RunService.RenderStepped:Connect(function(dt)
	if flying and bodyVelocity and bodyGyro then
		local character = player.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then return end
		local hrp = character.HumanoidRootPart
		local cam = workspace.CurrentCamera
		if not cam then return end

		-- build move vector from camera orientation
		local moveDir = (cam.CFrame.LookVector * (control.F + control.B))
			+ (cam.CFrame.RightVector * (control.R + control.L))
			+ (cam.CFrame.UpVector * (control.U + control.D))

		-- ensure we have some minimal up to avoid zero
		local targetVel = moveDir.Unit == moveDir.Unit and moveDir * speed or Vector3.new(0,0,0)
		-- smooth interpolation
		local current = bodyVelocity.Velocity
		local lerpVal = math.clamp(1 - smooth, 0, 1)
		local newVel = current:Lerp(targetVel, lerpVal)
		bodyVelocity.Velocity = newVel

		-- orient gyro to camera for natural facing
		if cam and bodyGyro then
			bodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
		end
	end
end)

-- input handlers
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		local key = input.KeyCode
		if key == keybind then
			flying = not flying
			if flying then startFly() else stopFly() end
			-- update toggle button text if present (try find)
			local btn = rightScroll:FindFirstChildWhichIsA("TextButton", true)
		end
		if key == Enum.KeyCode.W then control.F = 1 end
		if key == Enum.KeyCode.S then control.B = -1 end
		if key == Enum.KeyCode.A then control.L = -1 end
		if key == Enum.KeyCode.D then control.R = 1 end
		if key == Enum.KeyCode.Space then control.U = 1 end
		if key == Enum.KeyCode.LeftControl or key == Enum.KeyCode.RightControl then control.D = -1 end
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		local key = input.KeyCode
		if key == Enum.KeyCode.W then control.F = 0 end
		if key == Enum.KeyCode.S then control.B = 0 end
		if key == Enum.KeyCode.A then control.L = 0 end
		if key == Enum.KeyCode.D then control.R = 0 end
		if key == Enum.KeyCode.Space then control.U = 0 end
		if key == Enum.KeyCode.LeftControl or key == Enum.KeyCode.RightControl then control.D = 0 end
	end
end)

-- cleanup on respawn
player.CharacterAdded:Connect(function(char)
	wait(0.5)
	if flying then
		-- try reapply
		startFly()
	end
end)

-- initial UI build done earlier

-- final note: keep these functions accessible for debugging
_G.FlyController = {
	Start = function() flying = true startFly() end,
	Stop = function() flying = false stopFly() end,
	SetSpeed = function(v) speed = v end,
	IsFlying = function() return flying end,
}

print("FlyControlGui loaded. Toggle fly with key F (default).")
