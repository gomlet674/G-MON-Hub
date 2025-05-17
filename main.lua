-- main.lua
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- UI Library Basic (Buat UI sendiri tanpa dependensi)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GMONHub"
ScreenGui.Parent = game.CoreGui

-- Background Frame with 50% transparency & black color
local Background = Instance.new("Frame")
Background.Size = UDim2.new(1, 0, 1, 0)
Background.BackgroundColor3 = Color3.new(0, 0, 0)
Background.BackgroundTransparency = 0.5
Background.Parent = ScreenGui

-- Main Frame (Dragable)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 450, 0, 550)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -275)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- RGB Border effect
local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Color = Color3.fromHSV(0,1,1)
UIStroke.Parent = MainFrame

-- RGB Effect for border (loop color change)
spawn(function()
    while true do
        for hue = 0, 1, 0.01 do
            UIStroke.Color = Color3.fromHSV(hue, 1, 1)
            task.wait(0.03)
        end
    end
end)

-- Drag function for MainFrame
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

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
        update(input)
    end
end)

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "GMON Hub - Roblox Blox Fruits"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 22
Title.Parent = MainFrame

-- Container for buttons/toggles
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = MainFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    MainFrame.Size = UDim2.new(0, 450, 0, math.clamp(UIListLayout.AbsoluteContentSize.Y + 60, 550, 800))
end)

-- Create a function to make toggle buttons
local function createToggle(text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 420, 0, 40)
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    button.BorderSizePixel = 0
    button.Text = text.." : OFF"
    button.TextColor3 = Color3.fromRGB(200, 200, 200)
    button.Font = Enum.Font.Gotham
    button.TextSize = 18
    button.Parent = MainFrame

    local toggled = false

    button.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
            button.Text = text.." : ON"
            button.BackgroundColor3 = Color3.fromRGB(45, 130, 45)
        else
            button.Text = text.." : OFF"
            button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        end
        callback(toggled)
    end)
    return button
end

-- Create a dropdown (select weapon)
local function createDropdown(label, options, callback)
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(0, 420, 0, 40)
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    dropdownFrame.BorderSizePixel = 0
    dropdownFrame.Parent = MainFrame

    local dropdownLabel = Instance.new("TextLabel")
    dropdownLabel.Text = label
    dropdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdownLabel.Font = Enum.Font.Gotham
    dropdownLabel.TextSize = 18
    dropdownLabel.Size = UDim2.new(0.5, 0, 1, 0)
    dropdownLabel.BackgroundTransparency = 1
    dropdownLabel.Parent = dropdownFrame

    local selected = Instance.new("TextLabel")
    selected.Text = options[1]
    selected.TextColor3 = Color3.fromRGB(180, 180, 180)
    selected.Font = Enum.Font.Gotham
    selected.TextSize = 18
    selected.Size = UDim2.new(0.5, -10, 1, 0)
    selected.Position = UDim2.new(0.5, 10, 0, 0)
    selected.BackgroundTransparency = 1
    selected.TextXAlignment = Enum.TextXAlignment.Right
    selected.Parent = dropdownFrame

    local open = false

    dropdownFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            open = not open
            if open then
                -- create dropdown menu
                local menu = Instance.new("Frame")
                menu.Name = "DropdownMenu"
                menu.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                menu.Size = UDim2.new(0, 420, 0, 40 * #options)
                menu.Position = UDim2.new(0, 0, 1, 5)
                menu.Parent = dropdownFrame
                menu.ClipsDescendants = true

                for i, v in pairs(options) do
                    local option = Instance.new("TextButton")
                    option.Size = UDim2.new(1, 0, 0, 40)
                    option.Position = UDim2.new(0, 0, 0, 40 * (i - 1))
                    option.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                    option.BorderSizePixel = 0
                    option.Text = v
                    option.TextColor3 = Color3.fromRGB(220, 220, 220)
                    option.Font = Enum.Font.Gotham
                    option.TextSize = 18
                    option.Parent = menu

                    option.MouseButton1Click:Connect(function()
                        selected.Text = v
                        callback(v)
                        open = false
                        menu:Destroy()
                    end)
                end
            else
                if dropdownFrame:FindFirstChild("DropdownMenu") then
                    dropdownFrame.DropdownMenu:Destroy()
                end
            end
        end
    end)
end

-- Variabel fitur
local AutoFarmEnabled = false
local AutoChestEnabled = false
local AimbotEnabled = false
local SelectedWeapon = "Melee"

-- Fungsi Tween ke posisi (dipakai di source.lua nanti)
local function tweenTo(pos, speed)
    speed = speed or 250
    local HRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if HRP then
        local dist = (HRP.Position - pos).Magnitude
        local tweenInfo = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(HRP, tweenInfo, {CFrame = CFrame.new(pos)})
        tween:Play()
        tween.Completed:Wait()
    end
end

-- Toggle callbacks
local function onAutoFarmToggle(state)
    AutoFarmEnabled = state
    if state then
        task.spawn(function()
            while AutoFarmEnabled do
                -- contoh farming mob "Bandit"
                local mobName = "Bandit"
                for _, mob in pairs(workspace.Enemies:GetChildren()) do
                    if mob.Name == mobName and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                        tweenTo(mob.HumanoidRootPart.Position + Vector3.new(0,3,0), 250)
                        repeat task.wait()
                            if not AutoFarmEnabled then break end
                            pcall(function()
                                Player.Character.HumanoidRootPart.CFrame = CFrame.new(mob.HumanoidRootPart.Position + Vector3.new(0,3,0))
                            end)
                        until mob.Humanoid.Health <= 0
                    end
                    if not AutoFarmEnabled then break end
                end
                task.wait(1)
            end
        end)
    end
end

local function onAutoChestToggle(state)
    AutoChestEnabled = state
    if state then
        task.spawn(function()
            while AutoChestEnabled do
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("TouchTransmitter") and v.Parent and v.Parent:IsA("Part") and v.Parent.Name:lower():find("chest") then
                        tweenTo(v.Parent.Position + Vector3.new(0,3,0), 250)
                        wait(1.5)
                    end
                end
                wait(5)
            end
        end)
    end
end

local function onAimbotToggle(state)
    AimbotEnabled = state
    -- Implementasi aimbot logic ada di source.lua
end

local function onSelectWeapon(weapon)
    SelectedWeapon = weapon
    print("Selected Weapon:", weapon)
    -- Logic di source.lua untuk ganti weapon sesuai pilihan
end

-- UI Components
createToggle("Auto Farm", onAutoFarmToggle)
createToggle("Auto Chest", onAutoChestToggle)
createToggle("Aimbot", onAimbotToggle)
createDropdown("Select Weapon", {"Melee", "Fruit", "Sword", "Gun"}, onSelectWeapon)

-- Tambahan UI atau tombol lain bisa dibuat di sini sesuai kebutuhan

return {
    -- Meng-expose var & fungsi jika diperlukan source.lua
    AutoFarmEnabled = function() return AutoFarmEnabled end,
    AutoChestEnabled = function() return AutoChestEnabled end,
    AimbotEnabled = function() return AimbotEnabled end,
    SelectedWeapon = function() return SelectedWeapon end,
    TweenTo = tweenTo,
}