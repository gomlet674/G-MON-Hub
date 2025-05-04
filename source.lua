-- GMON Hub Source Logic for Roblox Blox Fruits
local TweenService = game:GetService("TweenService")
local player = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")

-- Variables for tracking the state of features
_G.AutoFarm = false
_G.AutoNextSea = false
_G.AutoEquipAccessory = false
_G.Weapon = nil
_G.AutoMelee = false
_G.AutoDefense = false
_G.AutoSword = false
_G.AutoGun = false
_G.AutoBloxFruit = false

local GMON = {}

function GMON:CreateWindow(title, subtitle, color, imageId)
	local Tabs = {}
	local ScreenGui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("GMON_MainUI")
if not ScreenGui then
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "GMON_MainUI"
    ScreenGui.Parent = game:GetService("Players").LocalPlayer.PlayerGui
	end
	
	local Holder = Instance.new("Frame")
	Holder.Name = "MainHolder"
	Holder.Size = UDim2.new(0, 460, 0, 300)
	Holder.Position = UDim2.new(0.5, -230, 0.5, -150)
	Holder.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	Holder.BorderSizePixel = 0
	Holder.Visible = true
	Holder.Parent = ScreenGui.Background

	local TabButtons = Instance.new("Frame", Holder)
	TabButtons.Name = "TabButtons"
	TabButtons.Size = UDim2.new(0, 100, 1, 0)
	TabButtons.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	TabButtons.BorderSizePixel = 0

	local Content = Instance.new("Frame", Holder)
	Content.Name = "Content"
	Content.Position = UDim2.new(0, 100, 0, 0)
	Content.Size = UDim2.new(1, -100, 1, 0)
	Content.BackgroundTransparency = 1

	function GMON:CreateTab(name)
		local tabFrame = Instance.new("ScrollingFrame", Content)
		tabFrame.Name = name
		tabFrame.Size = UDim2.new(1, 0, 1, 0)
		tabFrame.CanvasSize = UDim2.new(0, 0, 0, 500)
		tabFrame.BackgroundTransparency = 1
		tabFrame.Visible = false
		tabFrame.ScrollBarThickness = 6

		local button = Instance.new("TextButton", TabButtons)
		button.Name = name .. "_Btn"
		button.Size = UDim2.new(1, 0, 0, 30)
		button.Text = name
		button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		button.TextColor3 = Color3.new(1,1,1)
		button.Font = Enum.Font.SourceSansBold
		button.TextSize = 14

		button.MouseButton1Click:Connect(function()
			for _, child in pairs(Content:GetChildren()) do
				if child:IsA("ScrollingFrame") then
					child.Visible = false
				end
			end
			tabFrame.Visible = true
		end)

		local y = 10
		local function place(obj)
			obj.Position = UDim2.new(0, 10, 0, y)
			obj.Size = UDim2.new(1, -20, 0, 30)
			obj.Parent = tabFrame
			y = y + 35
		end

		return {
			CreateButton = function(text, callback)
				local btn = Instance.new("TextButton")
				btn.Text = text
				btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				btn.TextColor3 = Color3.new(1,1,1)
				btn.Font = Enum.Font.SourceSansBold
				btn.TextSize = 14
				btn.MouseButton1Click:Connect(callback)
				place(btn)
			end,

			CreateToggle = function(text, default, callback)
				local toggle = Instance.new("TextButton")
				toggle.Text = "[ OFF ] " .. text
				toggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				toggle.TextColor3 = Color3.new(1,1,1)
				toggle.Font = Enum.Font.SourceSansBold
				toggle.TextSize = 14
				local state = default or false
				toggle.MouseButton1Click:Connect(function()
					state = not state
					toggle.Text = (state and "[ ON ] " or "[ OFF ] ") .. text
					callback(state)
				end)
				place(toggle)
			end,

			CreateDropdown = function(text, list, callback)
				local dropdown = Instance.new("TextButton")
				dropdown.Text = text .. ": " .. list[1]
				dropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				dropdown.TextColor3 = Color3.new(1,1,1)
				dropdown.Font = Enum.Font.SourceSansBold
				dropdown.TextSize = 14
				local index = 1
				dropdown.MouseButton1Click:Connect(function()
					index = (index % #list) + 1
					dropdown.Text = text .. ": " .. list[index]
					callback(list[index])
				end)
				place(dropdown)
			end,

			CreateLabel = function(text)
				local lbl = Instance.new("TextLabel")
				lbl.Text = text
				lbl.BackgroundTransparency = 1
				lbl.TextColor3 = Color3.new(1,1,1)
				lbl.Font = Enum.Font.SourceSans
				lbl.TextSize = 14
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				place(lbl)
			end,
		}
	end

	return GMON
end

return GMON

-- Function to handle Auto Farm Logic
local function AutoFarmLogic()
    while _G.AutoFarm do
        local currentSea = GetPlayerSea(player)
        if currentSea == 1 then
            -- Auto Farm logic for Sea 1
            print("Farming in Sea 1")
        elseif currentSea == 2 then
            -- Auto Farm logic for Sea 2
            print("Farming in Sea 2")
        elseif currentSea == 3 then
            -- Auto Farm logic for Sea 3
            print("Farming in Sea 3")
        end
        wait(1)
    end
end

-- Function to handle Auto Equip Accessory
local function AutoEquipAccessoryLogic()
    while _G.AutoEquipAccessory do
        EquipHighestDamageAccessory()
        wait(1)
    end
end

-- Function to handle Auto Next Sea
local function AutoNextSeaLogic()
    while _G.AutoNextSea do
        local currentSea = GetPlayerSea(player)
        if currentSea == 1 then
            TeleportToSea(2)
        elseif currentSea == 2 then
            TeleportToSea(3)
        end
        wait(1)
    end
end

-- Function to handle Weapon Detection
local function AutoDetectWeapon()
    while true do
        if _G.AutoFarm then
            local bestWeapon = GetBestWeapon()
            EquipWeapon(bestWeapon)
        end
        wait(1)
    end
end

-- Function to handle Auto Blox Fruit
local function AutoBloxFruitLogic()
    while _G.AutoBloxFruit do
        UseBestBloxFruit()
        wait(1)
    end
end

-- Function to handle Auto Melee Logic
local function AutoMeleeLogic()
    while _G.AutoMelee do
        UseMelee()
        wait(1)
    end
end

-- Function to handle Auto Defense Logic
local function AutoDefenseLogic()
    while _G.AutoDefense do
        ActivateDefense()
        wait(1)
    end
end

-- Function to start all background tasks based on UI toggle states
local function StartBackgroundTasks()
    if _G.AutoFarm then
        coroutine.wrap(AutoFarmLogic)()
    end
    if _G.AutoEquipAccessory then
        coroutine.wrap(AutoEquipAccessoryLogic)()
    end
    if _G.AutoNextSea then
        coroutine.wrap(AutoNextSeaLogic)()
    end
    if _G.AutoBloxFruit then
        coroutine.wrap(AutoBloxFruitLogic)()
    end
    if _G.AutoMelee then
        coroutine.wrap(AutoMeleeLogic)()
    end
    if _G.AutoDefense then
        coroutine.wrap(AutoDefenseLogic)()
    end
end

-- Call the background tasks function to start
StartBackgroundTasks()

-- Placeholders for helper functions (These will need implementation)
function GetPlayerSea(player)
    -- Return current sea (1, 2, or 3)
    return 1  -- Example return
end

function TeleportToSea(seaNumber)
    -- Logic to teleport to the next sea
    print("Teleporting to Sea", seaNumber)
end

function EquipHighestDamageAccessory()
    -- Logic to equip the highest damage accessory
    print("Equipping highest damage accessory")
end

function GetBestWeapon()
    -- Logic to get the best weapon based on the current level and preferences
    return "BestWeapon"  -- Placeholder
end

function EquipWeapon(weapon)
    -- Logic to equip the weapon
    print("Equipping weapon:", weapon)
end

function UseBestBloxFruit()
    -- Logic to use the best Blox Fruit
    print("Using best Blox Fruit")
end

function UseMelee()
    -- Logic to use melee attacks
    print("Using melee attack")
end

function ActivateDefense()
    -- Logic to activate defense
    print("Activating defense")
end
