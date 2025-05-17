-- main.lua | GMON-Redz Style Hub UI

local Players         = game:GetService("Players")
local UserInput       = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local CoreGui         = game:GetService("CoreGui")

local LocalPlayer     = Players.LocalPlayer
local ScreenGui       = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name        = "GMONRedzHub"

-- Drag bar
local DraggableFrame  = Instance.new("Frame", ScreenGui)
DraggableFrame.Name   = "Draggable"
DraggableFrame.Size   = UDim2.new(0,700,0,50)
DraggableFrame.Position = UDim2.new(0.5,-350,0,20)
DraggableFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
DraggableFrame.Active = true
DraggableFrame.Draggable = true

-- RGB border
local Border = Instance.new("UIStroke", DraggableFrame)
Border.Thickness = 3
Border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
spawn(function()
    local t=0
    while true do
        t = (t+1)%360
        Border.Color = Color3.fromHSV(t/360,1,1)
        wait(0.03)
    end
end)

-- Title
local Title = Instance.new("TextLabel", DraggableFrame)
Title.Size = UDim2.new(0.3,0,1,0)
Title.Position = UDim2.new(0,10,0,0)
Title.BackgroundTransparency = 1
Title.Text = "GMON • Redz Style"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextColor3 = Color3.new(1,1,1)
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Container for toggles / buttons
local Container = Instance.new("Frame", DraggableFrame)
Container.Size = UDim2.new(1, -20, 1, -60)
Container.Position = UDim2.new(0,10,0,60)
Container.BackgroundTransparency = 1

-- UIListLayout horizontal
local List = Instance.new("UIListLayout", Container)
List.FillDirection = Enum.FillDirection.Horizontal
List.HorizontalAlignment = Enum.HorizontalAlignment.Left
List.SortOrder = Enum.SortOrder.LayoutOrder
List.Padding = UDim.new(0,8)

-- Feature factory
local function NewToggle(text, callback)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(0,130,0,40)
    btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    btn.TextColor3 = Color3.fromRGB(200,200,200)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 16
    btn.Text = text.." OFF"
    local on = false
    btn.MouseButton1Click:Connect(function()
        on = not on
        btn.Text = text..(on and " ON" or " OFF")
        btn.BackgroundColor3 = on and Color3.fromRGB(50,120,50) or Color3.fromRGB(30,30,30)
        callback(on)
    end)
    return btn
end

local function NewDropdown(label, options, callback)
    local frame = Instance.new("Frame", Container)
    frame.Size = UDim2.new(0,150,0,40)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    local lbl = Instance.new("TextLabel",frame)
    lbl.Size = UDim2.new(0.5,0,1,0)
    lbl.BackgroundTransparency=1
    lbl.Text=label
    lbl.Font=Enum.Font.Gotham
    lbl.TextSize=16
    lbl.TextColor3=Color3.new(1,1,1)
    lbl.TextXAlignment=Enum.TextXAlignment.Left

    local sel = Instance.new("TextLabel",frame)
    sel.Size=UDim2.new(0.5,-5,1,0)
    sel.Position=UDim2.new(0.5,5,0,0)
    sel.BackgroundTransparency=1
    sel.Text=options[1]
    sel.Font=Enum.Font.Gotham
    sel.TextSize=16
    sel.TextColor3=Color3.new(0.7,0.7,0.7)
    sel.TextXAlignment=Enum.TextXAlignment.Right

    local open=false
    frame.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            open=not open
            if open then
                local menu=Instance.new("Frame",frame)
                menu.Name="Menu"; menu.BackgroundColor3=Color3.fromRGB(25,25,25)
                menu.Size=UDim2.new(1,0,0,#options*25); menu.Position=UDim2.new(0,0,1,5)
                for idx,opt in ipairs(options) do
                    local b=Instance.new("TextButton",menu)
                    b.Size=UDim2.new(1,0,0,25); b.Position=UDim2.new(0,0,0,(idx-1)*25)
                    b.BackgroundColor3=Color3.fromRGB(40,40,40); b.Text=opt; b.Font=Enum.Font.Gotham; b.TextSize=16; b.TextColor3=Color3.new(1,1,1)
                    b.MouseButton1Click:Connect(function()
                        sel.Text=opt; callback(opt)
                        open=false; menu:Destroy()
                    end)
                end
            else
                local m=frame:FindFirstChild("Menu")
                if m then m:Destroy() end
            end
        end
    end)
    return frame
end

-- Feature Toggles and Dropdown
NewToggle("Auto Farm",       function(v) _G.AutoFarm=v end)
NewToggle("Auto Chest",      function(v) _G.AutoChest=v end)
NewToggle("Fruit Mastery",   function(v) _G.FruitMastery=v end)
NewToggle("Fast Attack",     function(v) _G.FastAttack=v end)
NewToggle("Auto Click",      function(v) _G.AutoClick=v end)
NewToggle("Auto Accessory",  function(v) _G.AutoEquipAccessory=v end)
NewToggle("Aimbot",          function(v) _G.Aimbot=v end)
NewDropdown("Weapon",{"Melee","Fruit","Sword","Gun"}, function(opt) _G.SelectedWeapon=opt end)

-- Load logic
loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/GMONHub/main/source.lua"))()