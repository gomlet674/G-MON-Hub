local Library = {}
local Players = game:GetService("Players")
local plr = Players.LocalPlayer

function Library:Window(title, subtitle, color, icon)
    local g = Instance.new("ScreenGui", game:GetService("CoreGui"))
    g.Name = "GMON HUB"

    -- Main Frame
    local main = Instance.new("Frame", g)
    main.Size = UDim2.new(0, 600, 0, 400)
    main.Position = UDim2.new(0.5, -300, 0.5, -200)
    main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    main.BackgroundTransparency = 0.4
    main.BorderSizePixel = 0
    main.Name = "MainFrame"

    -- Draggable Functionality
    local dragToggle = nil
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    -- Enable dragging
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragToggle = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)

    main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragToggle then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    main.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragToggle = false
        end
    end)

    -- Set Anime Background
    local bg = Instance.new("ImageLabel", main)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundTransparency = 1
    bg.Image = "rbxassetid://88817335071002"  -- Background anime image
    bg.ZIndex = -1

    -- Tabs and Pages
    local tabsHolder = Instance.new("Frame", main)
    tabsHolder.Name = "Tabs"
    tabsHolder.Size = UDim2.new(0, 120, 1, 0)
    tabsHolder.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    tabsHolder.BorderSizePixel = 0

    local pagesHolder = Instance.new("Frame", main)
    pagesHolder.Name = "Pages"
    pagesHolder.Position = UDim2.new(0, 120, 0, 0)
    pagesHolder.Size = UDim2.new(1, -120, 1, 0)
    pagesHolder.BackgroundTransparency = 1

    local ui = {
        Tabs = {},
        Main = main
    }

    function ui:Tab(name)
        local tabBtn = Instance.new("TextButton", tabsHolder)
        tabBtn.Size = UDim2.new(1, 0, 0, 40)
        tabBtn.Text = name
        tabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        tabBtn.TextColor3 = Color3.new(1,1,1)
        tabBtn.BorderSizePixel = 0

        local page = Instance.new("ScrollingFrame", pagesHolder)
        page.Size = UDim2.new(1, 0, 1, 0)
        page.ScrollBarThickness = 4
        page.Visible = false
        page.Name = name
        page.CanvasSize = UDim2.new(0,0,10,0)
        page.BackgroundTransparency = 1

        tabBtn.MouseButton1Click:Connect(function()
            for _, v in pairs(pagesHolder:GetChildren()) do
                if v:IsA("ScrollingFrame") then
                    v.Visible = false
                end
            end
            page.Visible = true
        end)

        if #pagesHolder:GetChildren() == 1 then
            page.Visible = true
        end

        local tab = {}

        function tab:Section(sectionName)
            local section = Instance.new("Frame", page)
            section.Size = UDim2.new(1, -10, 0, 30)
            section.Position = UDim2.new(0, 5, 0, #page:GetChildren()*40)
            section.BackgroundTransparency = 1

            local label = Instance.new("TextLabel", section)
            label.Size = UDim2.new(1, 0, 0, 20)
            label.Text = sectionName
            label.TextColor3 = Color3.new(1,1,1)
            label.BackgroundTransparency = 1
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = 16

            local sec = {}

            function sec:Toggle(txt, default, callback)
                local toggleBtn = Instance.new("TextButton", page)
                toggleBtn.Size = UDim2.new(1, -10, 0, 30)
                toggleBtn.Position = UDim2.new(0, 5, 0, #page:GetChildren()*35)
                toggleBtn.Text = txt
                toggleBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
                toggleBtn.TextColor3 = Color3.new(1,1,1)
                toggleBtn.BorderSizePixel = 0

                local state = default
                toggleBtn.MouseButton1Click:Connect(function()
                    state = not state
                    callback(state)
                    toggleBtn.Text = txt.." ["..(state and "ON" or "OFF").."]"
                end)
            end

            return sec
        end

        return tab
    end

    return ui
end

return Library
