
-- GMON Hub Loader Script
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "GMON_KeyUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 250)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
MainFrame.BackgroundTransparency = 1

local BG = Instance.new("ImageLabel", MainFrame)
BG.Size = UDim2.new(1, 0, 1, 0)
BG.BackgroundTransparency = 1
BG.Image = "rbxassetid://94747801090737"

local Logo = Instance.new("TextLabel", MainFrame)
Logo.Size = UDim2.new(1, 0, 0, 50)
Logo.Position = UDim2.new(0, 0, 0, 0)
Logo.BackgroundTransparency = 1
Logo.Text = "GMON Hub"
Logo.TextColor3 = Color3.fromRGB(255, 255, 255)
Logo.Font = Enum.Font.GothamBold
Logo.TextSize = 28

local KeyBox = Instance.new("TextBox", MainFrame)
KeyBox.Size = UDim2.new(0.8, 0, 0, 40)
KeyBox.Position = UDim2.new(0.1, 0, 0.4, 0)
KeyBox.PlaceholderText = "Enter Key Here"
KeyBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
KeyBox.TextColor3 = Color3.fromRGB(0, 0, 0)
KeyBox.Font = Enum.Font.SourceSansBold
KeyBox.TextSize = 20

local CheckKey = Instance.new("TextButton", MainFrame)
CheckKey.Size = UDim2.new(0.35, 0, 0, 35)
CheckKey.Position = UDim2.new(0.1, 0, 0.65, 0)
CheckKey.Text = "Check Key"
CheckKey.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
CheckKey.TextColor3 = Color3.fromRGB(255, 255, 255)
CheckKey.Font = Enum.Font.SourceSansBold
CheckKey.TextSize = 20

local GetKey = Instance.new("TextButton", MainFrame)
GetKey.Size = UDim2.new(0.35, 0, 0, 35)
GetKey.Position = UDim2.new(0.55, 0, 0.65, 0)
GetKey.Text = "Get Key"
GetKey.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
GetKey.TextColor3 = Color3.fromRGB(0, 0, 0)
GetKey.Font = Enum.Font.SourceSansBold
GetKey.TextSize = 20

local function Notify(text)
    game.StarterGui:SetCore("SendNotification", {
        Title = "GMON Hub",
        Text = text,
        Duration = 3
    })
end

local ValidKey = "Bcd127aLt94dcp"
CheckKey.MouseButton1Click:Connect(function()
    if KeyBox.Text == ValidKey then
        Notify("Valid Key!")
        wait(1)
        ScreenGui:Destroy() -- Hapus UI get key

        if not _G.GMON_UI_Loaded then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/main.lua"))()
            _G.GMON_UI_Loaded = true
        end
    else
        Notify("Wrong Key!")
    end
end)

GetKey.MouseButton1Click:Connect(function()
    setclipboard("https://link-target.net/1209226/g-mon-hub-op-script-in-rb")
    Notify("Link copied! Open browser to get your key.")
end)
