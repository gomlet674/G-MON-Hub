--[[
    CDT ULTIMATE - SMART EDITION
    Fitur: Smart Buy Logic, Safe Limited Sniper, Human-Like Farm
    Rebuilt by: Gemini AI
]]

--// Load Library
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "CDT Ultimate | Smart & Safe", HidePremium = false, SaveConfig = true, ConfigFolder = "CDT_Gemini_v2"})

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

--// Variables & Paths
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes") -- Sesuaikan path ini jika game update
local CarsFolder = ReplicatedStorage:WaitForChild("Cars")

--// Global Settings
_G.Settings = {
    AutoFarm = false,
    AutoLimited = false,
    SelectedCar = nil,
    FarmSpeed = 300, -- Kecepatan Farm
    SafeMode = true -- Jeda antar pembelian
}

local BoughtLimiteds = {} -- Cache untuk mobil limited yang sudah dibeli sesi ini

--// --- [ SYSTEM FUNCTIONS ] --- //--

-- 1. Cek Uang Player
local function GetMyCash()
    -- CDT biasanya menyimpan uang di leaderstats atau Data
    if LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Cash") then
        return LocalPlayer.leaderstats.Cash.Value
    end
    return 0
end

-- 2. Cek Apakah Mobil Sudah Dimiliki
local function IsCarOwned(CarName)
    -- Cek folder OwnedCars di player
    if LocalPlayer:FindFirstChild("OwnedCars") then
        if LocalPlayer.OwnedCars:FindFirstChild(CarName) then
            return true
        end
    end
    return false
end

-- 3. Ambil Harga Mobil
local function GetCarPrice(CarName)
    local CarData = CarsFolder:FindFirstChild(CarName)
    if CarData then
        local Price = CarData:GetAttribute("Price") or CarData:FindFirstChild("Price") and CarData.Price.Value
        return Price or 0
    end
    return 0
end

-- 4. Logika Pembelian Pintar (Smart Buy)
local function AttemptBuyCar(CarName)
    if not CarName then return end

    local Price = GetCarPrice(CarName)
    local MyCash = GetMyCash()
    local Owned = IsCarOwned(CarName)

    -- Logic Checks
    if Owned then
        OrionLib:MakeNotification({
            Name = "Failed",
            Content = "Anda sudah memiliki mobil: " .. CarName,
            Image = "rbxassetid://4483345998",
            Time = 3
        })
        return false
    end

    if MyCash < Price then
        OrionLib:MakeNotification({
            Name = "Not Enough Money",
            Content = "Uang kurang! Butuh: $" .. tostring(Price) .. "\nSaldo: $" .. tostring(MyCash),
            Image = "rbxassetid://4483345998",
            Time = 5
        })
        return false
    end

    -- Eksekusi Beli (Safe Mode)
    pcall(function()
        -- Remote Event CDT (Contoh: BuyCar)
        -- Jika nama remote berubah, ubah string "BuyCar" di bawah
        local BuyEvent = Remotes:FindFirstChild("BuyCar") or Remotes:FindFirstChild("PurchaseCar")
        
        if BuyEvent then
            BuyEvent:FireServer(CarName)
            
            OrionLib:MakeNotification({
                Name = "Success!",
                Content = "Berhasil membeli: " .. CarName,
                Time = 3
            })
            task.wait(1) -- Cooldown server
        else
            OrionLib:MakeNotification({Name = "Error", Content = "Remote tidak ditemukan (Patch Game?)", Time = 3})
        end
    end)
    return true
end

--// --- [ UI SETUP ] --- //--

local ShopTab = Window:MakeTab({
	Name = "Shop & Limited",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local FarmTab = Window:MakeTab({
	Name = "Auto Farm",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

--// TAB 1: SHOP & LIMITED SNIPER

ShopTab:AddSection({
	Name = "Limited Sniper (Anti-Fail)"
})

ShopTab:AddToggle({
	Name = "Auto Buy NEW Limited",
	Default = false,
	Callback = function(Value)
		_G.AutoLimited = Value
        if Value then
            spawn(function()
                while _G.AutoLimited do
                    task.wait(0.5) -- Cek setiap 0.5 detik (Safe)
                    pcall(function()
                        for _, car in pairs(CarsFolder:GetChildren()) do
                            local isLimited = car:GetAttribute("Limited") or car:GetAttribute("IsLimited")
                            
                            -- Cek: Limited + Belum Punya + Belum Dibeli di Sesi Ini
                            if isLimited and not IsCarOwned(car.Name) and not BoughtLimiteds[car.Name] then
                                local Price = GetCarPrice(car.Name)
                                local Cash = GetMyCash()

                                if Cash >= Price then
                                    local success = AttemptBuyCar(car.Name)
                                    if success then
                                        BoughtLimiteds[car.Name] = true -- Tandai sudah dibeli
                                        OrionLib:MakeNotification({Name = "SNIPER", Content = "Limited Secured: "..car.Name, Time = 10})
                                    end
                                end
                            end
                        end
                    end)
                end
            end)
        end
	end    
})

ShopTab:AddLabel("Status: Menunggu Limited Car baru rilis...")

ShopTab:AddSection({
	Name = "Manual Car Selector"
})

-- Generate Car List
local CarList = {}
for _, v in pairs(CarsFolder:GetChildren()) do
    table.insert(CarList, v.Name)
end
table.sort(CarList)

ShopTab:AddDropdown({
	Name = "Select Car",
	Default = "None",
	Options = CarList,
	Callback = function(Value)
		_G.SelectedCar = Value
        
        -- Tampilkan Info Langsung saat dipilih
        local Price = GetCarPrice(Value)
        local Status = IsCarOwned(Value) and "Dimiliki ✅" or "Belum Punya ❌"
        
        OrionLib:MakeNotification({
            Name = "Car Info",
            Content = "Nama: " .. Value .. "\nHarga: $" .. Price .. "\nStatus: " .. Status,
            Time = 4
        })
	end    
})

ShopTab:AddButton({
	Name = "BUY SELECTED CAR",
	Callback = function()
        if _G.SelectedCar then
            AttemptBuyCar(_G.SelectedCar)
        else
            OrionLib:MakeNotification({Name = "Warning", Content = "Pilih mobil dulu!", Time = 2})
        end
  	end    
})

--// TAB 2: HUMAN-LIKE AUTO FARM

FarmTab:AddSection({
	Name = "Legit Driving Farm"
})

FarmTab:AddToggle({
	Name = "Enable Human-Like Farm",
	Default = false,
	Callback = function(Value)
		_G.AutoFarm = Value
        
        spawn(function()
            while _G.AutoFarm do
                task.wait()
                pcall(function()
                    local Char = LocalPlayer.Character
                    if Char and Char:FindFirstChild("Humanoid") and Char.Humanoid.SeatPart then
                        local Vehicle = Char.Humanoid.SeatPart.Parent
                        if Vehicle and Vehicle.PrimaryPart then
                            -- Metode Farm: Mendorong mobil ke depan secara fisik (Velocity)
                            -- Ini lebih aman daripada CFrame Teleport murni
                            
                            local LookVector = Vehicle.PrimaryPart.CFrame.LookVector
                            Vehicle.PrimaryPart.Velocity = LookVector * _G.Settings.FarmSpeed
                            
                            -- Sedikit CFrame move untuk memastikan game mendeteksi pergerakan
                            Vehicle:SetPrimaryPartCFrame(Vehicle.PrimaryPart.CFrame * CFrame.new(0, 0, -2))
                            
                            -- Agar mobil tidak terbalik
                            local Gyro = Vehicle.PrimaryPart:FindFirstChild("FarmGyro") or Instance.new("BodyGyro")
                            Gyro.Name = "FarmGyro"
                            Gyro.Parent = Vehicle.PrimaryPart
                            Gyro.MaxTorque = Vector3.new(10000, 0, 10000) -- Stabilkan X dan Z
                            Gyro.CFrame = Vehicle.PrimaryPart.CFrame
                        end
                    end
                end)
            end
            
            -- Bersihkan Gyro saat mati
            pcall(function()
                local Char = LocalPlayer.Character
                if Char and Char.Humanoid.SeatPart then
                     local Vehicle = Char.Humanoid.SeatPart.Parent
                     if Vehicle.PrimaryPart:FindFirstChild("FarmGyro") then
                        Vehicle.PrimaryPart.FarmGyro:Destroy()
                     end
                end
            end)
        end)
	end    
})

FarmTab:AddSlider({
	Name = "Farm Speed",
	Min = 50,
	Max = 500,
	Default = 200,
	Color = Color3.fromRGB(255,165,0),
	Increment = 10,
	ValueName = "Speed",
	Callback = function(Value)
		_G.Settings.FarmSpeed = Value
	end    
})

FarmTab:AddLabel("Tips: Gunakan di jalan tol lurus (Highway).")

--// Anti-Kick & Init
local vu = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    wait(1)
    vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)

OrionLib:Init()
