--==============================
-- GMON SIMPLE HUB (NO RAYFIELD)
-- Stable Version
--==============================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==============================
-- GAME DETECTION
--==============================
local GAME_ID = game.PlaceId

local GAME = "UNKNOWN"
if GAME_ID == 654732683 then
    GAME = "CDT" -- Car Dealership Tycoon
elseif GAME_ID == 537413528 then
    GAME = "BABFT" -- Build A Boat
end

--==============================
-- GUI BASE
--==============================
local gui = Instance.new("ScreenGui")
gui.Name = "GMON_SIMPLE"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 320, 0, 260)
main.Position = UDim2.new(0.05, 0, 0.25, 0)
main.BackgroundColor3 = Color3.fromRGB(20,20,20)
main.Active = true
main.Draggable = true

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1,0,0,35)
title.Text = "GMON SIMPLE HUB"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 15

--==============================
-- UI LAYOUT
--==============================
local layout = Instance.new("UIListLayout", main)
layout.Padding = UDim.new(0,6)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Top

title.LayoutOrder = 0

--==============================
-- NOTIFY
--==============================
local function notify(txt)
    pcall(function()
        game.StarterGui:SetCore("SendNotification",{
            Title = "GMON",
            Text = txt,
            Duration = 4
        })
    end)
end

--==============================
-- CDT SECTION
--==============================
if GAME == "CDT" then
    notify("Car Dealership Tycoon Detected")

    local Cars = {
        ["Hyperluxe Balle"] = {
            keyword = "bugatti5",
            price = 37500000
        },
        ["Hyperluxe 300+/SS+"] = {
            keyword = "ss",
            price = 35000000
        },
        ["Hyperluxe Vision GT"] = {
            keyword = "vision",
            price = 30000000
        }
    }

    local selectedCar = nil

    local selectBtn = Instance.new("TextButton", main)
    selectBtn.Size = UDim2.new(0.9,0,0,40)
    selectBtn.Text = "Select Car"
    selectBtn.Font = Enum.Font.Gotham
    selectBtn.TextColor3 = Color3.new(1,1,1)
    selectBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)

    local priceLabel = Instance.new("TextLabel", main)
    priceLabel.Size = UDim2.new(0.9,0,0,30)
    priceLabel.Text = "Price: -"
    priceLabel.TextColor3 = Color3.new(1,1,1)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Font = Enum.Font.Gotham

    local buyBtn = Instance.new("TextButton", main)
    buyBtn.Size = UDim2.new(0.9,0,0,40)
    buyBtn.Text = "Buy Car Limited"
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.TextColor3 = Color3.new(1,1,1)
    buyBtn.BackgroundColor3 = Color3.fromRGB(60,120,60)

    -- Dropdown logic (simple)
    selectBtn.MouseButton1Click:Connect(function()
        for name,data in pairs(Cars) do
            selectedCar = name
            priceLabel.Text = "Price: $"..string.format("%d",data.price):reverse():gsub("(%d%d%d)","%1."):reverse():gsub("^%.","")
            notify("Selected: "..name)
            break
        end
    end)

    local function getMoney()
        local stats = LocalPlayer:FindFirstChild("leaderstats")
        if stats and stats:FindFirstChild("Cash") then
            return stats.Cash.Value
        end
        return 0
    end

    buyBtn.MouseButton1Click:Connect(function()
        if not selectedCar then
            notify("Select car first")
            return
        end

        local car = Cars[selectedCar]
        if getMoney() < car.price then
            notify("Not enough money")
            return
        end

        -- UI Button Finder (Safe)
        for _,v in pairs(PlayerGui:GetDescendants()) do
            if v:IsA("TextButton") then
                local txt = string.lower(v.Text)
                if string.find(txt, car.keyword) then
                    pcall(function()
                        firesignal(v.MouseButton1Click)
                    end)
                    notify("Successfully bought "..selectedCar)
                    return
                end
            end
        end

        notify("Buy button not found")
    end)
end

--==============================
-- BUILD A BOAT SECTION
--==============================
if GAME == "BABFT" then
    notify("Build A Boat Detected")

    local autoFarm = false

    local farmBtn = Instance.new("TextButton", main)
    farmBtn.Size = UDim2.new(0.9,0,0,40)
    farmBtn.Text = "Auto Farm: OFF"
    farmBtn.Font = Enum.Font.GothamBold
    farmBtn.TextColor3 = Color3.new(1,1,1)
    farmBtn.BackgroundColor3 = Color3.fromRGB(120,60,60)

    farmBtn.MouseButton1Click:Connect(function()
        autoFarm = not autoFarm
        farmBtn.Text = autoFarm and "Auto Farm: ON" or "Auto Farm: OFF"
        farmBtn.BackgroundColor3 = autoFarm and Color3.fromRGB(60,120,60) or Color3.fromRGB(120,60,60)

        task.spawn(function()
            while autoFarm do
                pcall(function()
                    LocalPlayer.Character:MoveTo(Vector3.new(0,5,10000))
                end)
                task.wait(1)
            end
        end)
    end)
end

--==============================
-- UNKNOWN GAME
--==============================
if GAME == "UNKNOWN" then
    notify("Game not supported")
end