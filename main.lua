-- main.lua
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GMONHub"
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 700, 0, 60)
MainFrame.Position = UDim2.new(0.5, -350, 0, 30)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.5
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UIStroke = Instance.new("UIStroke")
UIStroke.Parent = MainFrame
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(255, 0, 0)

-- RGB Effect Tween Loop
spawn(function()
    local colors = {Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255)}
    local index = 1
    while true do
        UIStroke.Color = colors[index]
        index = (index % #colors) + 1
        wait(1)
    end
end)

-- Make UI draggable horizontally only
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        local newX = math.clamp(startPos.X.Offset + delta.X, 0, workspace.CurrentCamera.ViewportSize.X - MainFrame.AbsoluteSize.X)
        MainFrame.Position = UDim2.new(0, newX, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset)
    end
end)

-- Toggle UI Button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 60, 1, 0)
ToggleBtn.Position = UDim2.new(0, 0, 0, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
ToggleBtn.Text = "Toggle"
ToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
ToggleBtn.Parent = MainFrame

local UIVisible = true
ToggleBtn.MouseButton1Click:Connect(function()
    UIVisible = not UIVisible
    for _, v in pairs(MainFrame:GetChildren()) do
        if v ~= ToggleBtn then
            v.Visible = UIVisible
        end
    end
end)

-- Weapon Selector Dropdown
local Weapons = {"Melee", "Fruit", "Sword", "Gun"}
local SelectedWeapon = "Melee"

local Dropdown = Instance.new("TextButton")
Dropdown.Name = "Dropdown"
Dropdown.Size = UDim2.new(0, 120, 1, 0)
Dropdown.Position = UDim2.new(0, 70, 0, 0)
Dropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Dropdown.Text = "Weapon: Melee"
Dropdown.TextColor3 = Color3.fromRGB(255,255,255)
Dropdown.Parent = MainFrame

local DropdownList = Instance.new("Frame")
DropdownList.Name = "DropdownList"
DropdownList.Size = UDim2.new(0, 120, 0, #Weapons*25)
DropdownList.Position = UDim2.new(0, 70, 1, 0)
DropdownList.BackgroundColor3 = Color3.fromRGB(40,40,40)
DropdownList.Visible = false
DropdownList.Parent = MainFrame

for i, weapon in ipairs(Weapons) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 25)
    btn.Position = UDim2.new(0, 0, 0, (i-1)*25)
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Text = weapon
    btn.Parent = DropdownList
    btn.MouseButton1Click:Connect(function()
        SelectedWeapon = weapon
        Dropdown.Text = "Weapon: "..weapon
        DropdownList.Visible = false
    end)
end

Dropdown.MouseButton1Click:Connect(function()
    DropdownList.Visible = not DropdownList.Visible
end)

-- Buttons: AutoFarm Toggle
local AutoFarmBtn = Instance.new("TextButton")
AutoFarmBtn.Name = "AutoFarmBtn"
AutoFarmBtn.Size = UDim2.new(0, 120, 1, 0)
AutoFarmBtn.Position = UDim2.new(0, 200, 0, 0)
AutoFarmBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
AutoFarmBtn.TextColor3 = Color3.fromRGB(255,255,255)
AutoFarmBtn.Text = "Auto Farm: OFF"
AutoFarmBtn.Parent = MainFrame

local AutoFarmEnabled = false
AutoFarmBtn.MouseButton1Click:Connect(function()
    AutoFarmEnabled = not AutoFarmEnabled
    AutoFarmBtn.Text = "Auto Farm: "..(AutoFarmEnabled and "ON" or "OFF")
end)

-- Buttons: Aimbot Toggle
local AimbotBtn = Instance.new("TextButton")
AimbotBtn.Name = "AimbotBtn"
AimbotBtn.Size = UDim2.new(0, 120, 1, 0)
AimbotBtn.Position = UDim2.new(0, 330, 0, 0)
AimbotBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
AimbotBtn.TextColor3 = Color3.fromRGB(255,255,255)
AimbotBtn.Text = "Aimbot: OFF"
AimbotBtn.Parent = MainFrame

local AimbotEnabled = false
AimbotBtn.MouseButton1Click:Connect(function()
    AimbotEnabled = not AimbotEnabled
    AimbotBtn.Text = "Aimbot: "..(AimbotEnabled and "ON" or "OFF")
end)

-- Send Data to source.lua
_G.GMONHub = {
    AutoFarmEnabled = function() return AutoFarmEnabled end,
    SelectedWeapon = function() return SelectedWeapon end,
    AimbotEnabled = function() return AimbotEnabled end,
    TweenService = TweenService,
    LocalPlayer = LocalPlayer,
}