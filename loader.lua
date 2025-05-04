repeat wait() until game:IsLoaded()

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local RGBBorder = Instance.new("UIStroke")
local Title = Instance.new("TextLabel")
local KeyBox = Instance.new("TextBox")
local Submit = Instance.new("TextButton")
local GetKey = Instance.new("TextButton")
local background = Instance.new("ImageLabel")

-- Parent ke CoreGui
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.Name = "GMON_Loader"

-- Background Anime
background.Name = "AnimeBackground"
background.Parent = ScreenGui
background.BackgroundTransparency = 1
background.Size = UDim2.new(1, 0, 1, 0)
background.Position = UDim2.new(0, 0, 0, 0)
background.Image = "rbxassetid://16790218639" -- GMON background anime
background.ImageColor3 = Color3.new(1, 1, 1)
background.ScaleType = Enum.ScaleType.Crop
background.ZIndex = 0

-- Main Frame
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.Size = UDim2.new(0, 420, 0, 200)
Frame.Position = UDim2.new(0.5, -210, 0.5, -100)

UICorner.CornerRadius = UDim.new(0, 15)
UICorner.Parent = Frame

-- RGB Border
RGBBorder.Parent = Frame
RGBBorder.Color = Color3.fromRGB(255, 0, 0)
RGBBorder.Thickness = 2
RGBBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- RGB Animation
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
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1

-- Key Box
KeyBox.Parent = Frame
KeyBox.PlaceholderText = "Enter Your Key..."
KeyBox.Text = ""
KeyBox.Size = UDim2.new(0.9, 0, 0, 35)
KeyBox.Position = UDim2.new(0.05, 0, 0.35, 0)
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local KeyCorner = Instance.new("UICorner", KeyBox)
KeyCorner.CornerRadius = UDim.new(0, 8)

-- Submit Button
Submit.Parent = Frame
Submit.Text = "Submit"
Submit.Size = UDim2.new(0.42, 0, 0, 35)
Submit.Position = UDim2.new(0.05, 0, 0.65, 0)
Submit.Font = Enum.Font.GothamSemibold
Submit.TextColor3 = Color3.fromRGB(255, 255, 255)
Submit.BackgroundColor3 = Color3.fromRGB(0, 170, 127)

local SubmitCorner = Instance.new("UICorner", Submit)
SubmitCorner.CornerRadius = UDim.new(0, 8)

-- Get Key Button
GetKey.Parent = Frame
GetKey.Text = "Get Key"
GetKey.Size = UDim2.new(0.42, 0, 0, 35)
GetKey.Position = UDim2.new(0.53, 0, 0.65, 0)
GetKey.Font = Enum.Font.GothamSemibold
GetKey.TextColor3 = Color3.fromRGB(255, 255, 255)
GetKey.BackgroundColor3 = Color3.fromRGB(255, 85, 0)

local GetKeyCorner = Instance.new("UICorner", GetKey)
GetKeyCorner.CornerRadius = UDim.new(0, 8)

-- Get Key Click
GetKey.MouseButton1Click:Connect(function()
    setclipboard("https://pandadevelopment.net/")
end)

-- Submit Check
Submit.MouseButton1Click:Connect(function()
    local inputKey = KeyBox.Text
    local verify = loadstring(game:HttpGet("https://pandadevelopment.net/api/key-system/verify.lua?identifier=gmon_hub&key="..inputKey))()
    
    if verify then
        ScreenGui:Destroy()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/main.lua"))()
    else
        Submit.Text = "Invalid!"
        wait(2)
        Submit.Text = "Submit"
    end
end)
