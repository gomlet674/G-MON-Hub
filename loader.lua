repeat wait() until game:IsLoaded()

-- GUI Elements
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local RGBBorder = Instance.new("UIStroke")
local Title = Instance.new("TextLabel")
local KeyBox = Instance.new("TextBox")
local Submit = Instance.new("TextButton")
local GetKey = Instance.new("TextButton")
local background = Instance.new("ImageLabel")

-- GUI Parent
ScreenGui.Name = "GMON_Loader"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- Background Image
background.Name = "AnimeBackground"
background.Parent = ScreenGui
background.BackgroundTransparency = 1
background.Size = UDim2.new(1, 0, 1, 0)
background.Position = UDim2.new(0, 0, 0, 0)
background.Image = "rbxassetid://16790218639"
background.ImageColor3 = Color3.new(1, 1, 1)
background.ScaleType = Enum.ScaleType.Crop
background.ZIndex = 0

-- Main Frame
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.Size = UDim2.new(0, 420, 0, 200)
Frame.Position = UDim2.new(0.5, -210, 0.5, -100)
Frame.Active = true
Frame.Draggable = true

UICorner.CornerRadius = UDim.new(0, 15)
UICorner.Parent = Frame

-- RGB Border Effect
RGBBorder.Parent = Frame
RGBBorder.Thickness = 2
RGBBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

task.spawn(function()
	while true do
		for i = 0, 1, 0.01 do
			local r = math.sin(i * math.pi * 2) * 127 + 128
			local g = math.sin(i * math.pi * 2 + 2) * 127 + 128
			local b = math.sin(i * math.pi * 2 + 4) * 127 + 128
			RGBBorder.Color = Color3.fromRGB(r, g, b)
			wait(0.03)
		end
	end
end)

-- Title
Title.Parent = Frame
Title.Text = "GMON HUB KEY SYSTEM"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1

-- Key Input
KeyBox.Parent = Frame
KeyBox.PlaceholderText = "Enter Your Key..."
KeyBox.Size = UDim2.new(0.9, 0, 0, 35)
KeyBox.Position = UDim2.new(0.05, 0, 0.35, 0)
KeyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
KeyBox.Font = Enum.Font.Gotham
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.new(1, 1, 1)

Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 8)

-- Submit
Submit.Parent = Frame
Submit.Text = "Submit"
Submit.Size = UDim2.new(0.42, 0, 0, 35)
Submit.Position = UDim2.new(0.05, 0, 0.65, 0)
Submit.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
Submit.Font = Enum.Font.GothamSemibold
Submit.TextColor3 = Color3.new(1, 1, 1)

Instance.new("UICorner", Submit).CornerRadius = UDim.new(0, 8)

-- Get Key
GetKey.Parent = Frame
GetKey.Text = "Get Key"
GetKey.Size = UDim2.new(0.42, 0, 0, 35)
GetKey.Position = UDim2.new(0.53, 0, 0.65, 0)
GetKey.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
GetKey.Font = Enum.Font.GothamSemibold
GetKey.TextColor3 = Color3.new(1, 1, 1)

Instance.new("UICorner", GetKey).CornerRadius = UDim.new(0, 8)

-- Key File Path
local savedKeyPath = "gmon_key.txt"

-- Valid Key (bisa kamu ganti sesuai sistemmu)
local validKey = "GmonHub311851f3c742a8f78dce99e56992555609d23497928e9b33802e7127610c2e"

-- Fungsi submit otomatis
local function submitKey(key)
    if key == validKey then
        writefile(savedKeyPath, key)
        ScreenGui:Destroy()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/main.lua"))()
        return true
    end
    return false
end

-- Cek apakah key sudah tersimpan dan valid
if isfile(savedKeyPath) then
    local savedKey = readfile(savedKeyPath)
    if submitKey(savedKey) then
        return -- Hentikan eksekusi lanjutan karena sudah berhasil auto-submit
    end
end

-- Jika belum berhasil auto-submit, lanjut tampilkan UI dan event handler
GetKey.MouseButton1Click:Connect(function()
    setclipboard("https://link-target.net/1209226/get-key-gmon-hub-script")
end)

Submit.MouseButton1Click:Connect(function()
    local inputKey = KeyBox.Text

    if inputKey == nil or inputKey == "" then
        Submit.Text = "Enter Key"
        task.wait(2)
        Submit.Text = "Submit"
        return
    end

    if submitKey(inputKey) then
        -- Berhasil, tidak perlu apa-apa lagi di sini
    else
        Submit.Text = "Invalid!"
        task.wait(2)
        Submit.Text = "Submit"
    end
end)

-- Drag Functionality
local UIS = game:GetService("UserInputService")
local dragging, dragInput, dragStart, startPos

local function updateInput(input)
	local delta = input.Position - dragStart
	Frame.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end

Frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

Frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		updateInput(input)
	end
end)
