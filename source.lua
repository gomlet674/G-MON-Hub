-- GMON HUB UI Library (source.lua)
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local mouse = plr:GetMouse()

local library = {}
local windows = {}

function library:CreateWindow(title, subtitle, color, icon)
    local ScreenGui = Instance.new("ScreenGui", CoreGui)
    ScreenGui.Name = "GMON_UI"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() syn.protect_gui(ScreenGui) end)

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 700, 0, 460)
    MainFrame.Position = UDim2.new(0.5, -350, 0.5, -230)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true

    local Title = Instance.new("TextLabel", MainFrame)
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Text = title .. " - " .. subtitle
    Title.TextColor3 = color
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.BackgroundTransparency = 1

    local TabHolder = Instance.new("Frame", MainFrame)
    TabHolder.Name = "Tabs"
    TabHolder.Position = UDim2.new(0, 0, 0, 40)
    TabHolder.Size = UDim2.new(0, 700, 0, 420)
    TabHolder.BackgroundTransparency = 1

    local tabs = {}

    function library:CreateTab(name)
        local TabButton = Instance.new("TextButton", MainFrame)
        TabButton.Size = UDim2.new(0, 100, 0, 30)
        TabButton.Position = UDim2.new(0, #tabs * 105 + 10, 0, 5)
        TabButton.Text = name
        TabButton.BackgroundColor3 = color
        TabButton.TextColor3 = Color3.new(1, 1, 1)
        TabButton.Font = Enum.Font.GothamBold
        TabButton.TextSize = 14

        local TabPage = Instance.new("ScrollingFrame", TabHolder)
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.CanvasSize = UDim2.new(0, 0, 5, 0)
        TabPage.ScrollBarThickness = 8
        TabPage.BackgroundTransparency = 1
        TabPage.Visible = false

        TabButton.MouseButton1Click:Connect(function()
            for _, v in pairs(TabHolder:GetChildren()) do
                if v:IsA("ScrollingFrame") then v.Visible = false end
            end
            TabPage.Visible = true
        end)

        if #tabs == 0 then TabPage.Visible = true end
        table.insert(tabs, TabButton)

        local tabFunctions = {}

        local yOffset = 0
        local function newElement(obj)
            obj.Position = UDim2.new(0, 10, 0, yOffset)
            obj.Size = UDim2.new(1, -20, 0, 35)
            obj.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            obj.TextColor3 = Color3.new(1, 1, 1)
            obj.Font = Enum.Font.Gotham
            obj.TextSize = 14
            obj.Parent = TabPage
            yOffset = yOffset + 40
        end

        function tabFunctions:CreateButton(text, callback)
            local btn = Instance.new("TextButton")
            btn.Text = text
            newElement(btn)
            btn.MouseButton1Click:Connect(callback)
        end

        function tabFunctions:CreateToggle(text, default, callback)
            local tog = Instance.new("TextButton")
            tog.Text = "[OFF] " .. text
            newElement(tog)
            local state = default or false
            tog.MouseButton1Click:Connect(function()
                state = not state
                tog.Text = (state and "[ON] " or "[OFF] ") .. text
                callback(state)
            end)
        end

        function tabFunctions:CreateDropdown(text, list, callback)
            local dropdown = Instance.new("TextButton")
            dropdown.Text = text .. ": " .. list[1]
            newElement(dropdown)
            local index = 1
            dropdown.MouseButton1Click:Connect(function()
                index = index + 1
                if index > #list then index = 1 end
                dropdown.Text = text .. ": " .. list[index]
                callback(list[index])
            end)
        end

        function tabFunctions:CreateLabel(txt)
            local label = Instance.new("TextLabel")
            label.Text = txt
            newElement(label)
        end

        return tabFunctions
    end

    return library
end

return library
