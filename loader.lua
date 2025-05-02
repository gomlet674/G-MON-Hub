-- GMON Loader GUI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "GMONLoader"

-- Background Anime
local bg = Instance.new("ImageLabel", ScreenGui)
bg.Size = UDim2.new(0, 450, 0, 300)
bg.Position = UDim2.new(0.5, -225, 0.5, -150)
bg.Image = "rbxassetid://94747801090737"
bg.BackgroundTransparency = 1

-- Logo
local logo = Instance.new("TextLabel", bg)
logo.Text = "GMON Hub"
logo.Size = UDim2.new(1, 0, 0, 50)
logo.Position = UDim2.new(0, 0, 0, 10)
logo.TextColor3 = Color3.new(1, 1, 1)
logo.TextScaled = true
logo.BackgroundTransparency = 1

-- Key input
local keyBox = Instance.new("TextBox", bg)
keyBox.PlaceholderText = "Enter Key"
keyBox.Size = UDim2.new(0.6, 0, 0, 40)
keyBox.Position = UDim2.new(0.2, 0, 0.5, -20)
keyBox.TextScaled = true

-- Check Button
local checkBtn = Instance.new("TextButton", bg)
checkBtn.Text = "Check Key"
checkBtn.Size = UDim2.new(0.4, 0, 0, 40)
checkBtn.Position = UDim2.new(0.3, 0, 0.7, 0)
checkBtn.TextScaled = true

-- Notification
local notif = Instance.new("TextLabel", bg)
notif.Size = UDim2.new(1, 0, 0, 30)
notif.Position = UDim2.new(0, 0, 0.9, 0)
notif.BackgroundTransparency = 1
notif.TextScaled = true
notif.TextColor3 = Color3.new(1, 0, 0)
notif.Text = ""

-- Key System
local validKey = "Bcd127aLt94dcp"
local mainScriptURL = "https://raw.githubusercontent.com/gomlet674/gmonhub-script/main/main.lua"

checkBtn.MouseButton1Click:Connect(function()
    if keyBox.Text == validKey then
        notif.TextColor3 = Color3.new(0, 1, 0)
        notif.Text = "Valid Key! Loading script..."
        wait(1)
        ScreenGui:Destroy()
        loadstring(game:HttpGet(mainScriptURL))()
    else
        notif.TextColor3 = Color3.new(1, 0, 0)
        notif.Text = "Wrong Key!"
    end
end)
