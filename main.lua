--[[
    CAR DEALERSHIP TYCOON - PREMIUM REBUILD
    Features: Auto Buy Limited, CWR Selector, Price Checker
    Interface: Orion Lib
]]

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "CDT - Norepinephrine CWR Edition", HidePremium = false, SaveConfig = true, ConfigFolder = "CDT_Gemini"})

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--// Variables
local SelectedCar = ""
local CarPrice = 0
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

--// Functions
local function GetCarPrice(carName)
    -- Logika mengambil harga dari DataStore game
    local carData = ReplicatedStorage:WaitForChild("Cars"):FindFirstChild(carName)
    if carData then
        return carData:GetAttribute("Price") or "N/A"
    end
    return "N/A"
end

local function BuyCar(carName)
    -- Remote untuk membeli mobil (Remote ini disesuaikan dengan struktur CDT)
    Remotes:WaitForChild("BuyCar"):FireServer(carName)
end

--// UI TABS
local MainTab = Window:MakeTab({
	Name = "Auto Buy Limited",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local CwrTab = Window:MakeTab({
	Name = "CWR / Select Car",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

--// TAB 1: AUTO BUY LIMITED
MainTab:AddToggle({
	Name = "Auto Buy NEW Limited",
	Default = false,
	Callback = function(Value)
		_G.AutoLimited = Value
        spawn(function()
            while _G.AutoLimited do
                task.wait(1)
                -- Scan mobil dengan tag "Limited" di ReplicatedStorage
                for _, car in pairs(ReplicatedStorage.Cars:GetChildren()) do
                    if car:GetAttribute("IsLimited") == true and not LocalPlayer.OwnedCars:FindFirstChild(car.Name) then
                        OrionLib:MakeNotification({
                            Name = "Limited Found!",
                            Content = "Buying: " .. car.Name,
                            Time = 5
                        })
                        BuyCar(car.Name)
                    end
                end
            end
        end)
	end    
})

--// TAB 2: CWR SELECTOR & PRICE
CwrTab:AddSection({
	Name = "Select Car to Buy"
})

-- List mobil (Ambil otomatis dari game)
local CarList = {}
for _, v in pairs(ReplicatedStorage.Cars:GetChildren()) do
    table.insert(CarList, v.Name)
end
table.sort(CarList)

CwrTab:AddDropdown({
	Name = "Select Car (CWR)",
	Default = "None",
	Options = CarList,
	Callback = function(Value)
		SelectedCar = Value
        CarPrice = GetCarPrice(Value)
        
        -- Update Info Harga
        OrionLib:MakeNotification({
            Name = "Car Selected",
            Content = "Name: " .. SelectedCar .. "\nPrice: $" .. tostring(CarPrice),
            Time = 3
        })
	end    
})

CwrTab:AddLabel("Current Selection: None") -- Akan diupdate lewat button

CwrTab:AddButton({
	Name = "Check Price & Info",
	Callback = function()
        if SelectedCar ~= "" then
            local price = GetCarPrice(SelectedCar)
            OrionLib:MakeNotification({
                Name = "Price Info",
                Content = "The " .. SelectedCar .. " costs $" .. tostring(price),
                Time = 5
            })
        else
            OrionLib:MakeNotification({Name = "Error", Content = "Please select a car first!", Time = 3})
        end
	end    
})

CwrTab:AddButton({
	Name = "BUY SELECTED CAR NOW",
	Callback = function()
        if SelectedCar ~= "" then
            BuyCar(SelectedCar)
        else
            OrionLib:MakeNotification({Name = "Error", Content = "No car selected!", Time = 3})
        end
	end    
})

--// TAB 3: AUTO FARM (Driving)
local FarmTab = Window:MakeTab({
	Name = "Auto Farm",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

FarmTab:AddToggle({
	Name = "Auto Drive (Infinite Money)",
	Default = false,
	Callback = function(Value)
		_G.AutoDrive = Value
        spawn(function()
            while _G.AutoDrive do
                task.wait()
                pcall(function()
                    if LocalPlayer.Character.Humanoid.SeatPart then
                        local Car = LocalPlayer.Character.Humanoid.SeatPart.Parent
                        Car:MoveTo(Vector3.new(Car.PrimaryPart.Position.X + 10, Car.PrimaryPart.Position.Y, Car.PrimaryPart.Position.Z))
                    end
                end)
            end
        end)
	end    
})

OrionLib:Init()
