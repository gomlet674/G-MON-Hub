--[[
    CDT TOKEN SPAMMER & AUTO REDEEM
    Logic: Spam Redeem Request (Max Safe Speed) + Map Token Collector
    Note: Code hanya work 1x per akun. Script ini akan terus mencoba claim.
]]

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "CDT Token Spammer", HidePremium = false, SaveConfig = false, ConfigFolder = "CDT_Token"})

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

--// Variables
local RemoteName = "PromocodesRequest" -- Nama remote CDT (bisa berubah sewaktu-waktu)
local TargetCode = "FOXZIE" -- Kode yang ingin di spam
_G.SpamFoxzie = false
_G.AutoCollectTokens = false

--// Fungsi Mencari Remote yang Benar
local function GetPromoRemote()
    local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Events")
    if Remotes then
        return Remotes:FindFirstChild(RemoteName) or Remotes:FindFirstChild("RedeemCode")
    end
    return nil
end

--// Logic 1: Spam Redeem Code (Logic yang Anda Minta)
-- PERINGATAN: Saya kasih delay 0.1 detik. Jangan 0 (instant) atau Anda akan kena KICK.
local function StartSpamCode()
    spawn(function()
        local Remote = GetPromoRemote()
        if not Remote then 
            OrionLib:MakeNotification({Name = "Error", Content = "Remote tidak ditemukan!", Time = 3})
            return 
        end

        while _G.SpamFoxzie do
            -- Mengirim request redeem
            Remote:FireServer(TargetCode)
            
            -- Jika ingin mencoba kode lain juga:
            Remote:FireServer("Foxzie") -- Coba variasi huruf besar/kecil
            
            -- Wait sangat penting agar tidak disconnect
            task.wait(0.1) 
        end
    end)
end

--// Logic 2: Auto Collect Token di Map (Jika ada event token fisik)
-- Ini akan mentrigger "Touch" pada semua item bernama "Token" atau "Egg" di map
local function StartAutoCollect()
    spawn(function()
        while _G.AutoCollectTokens do
            pcall(function()
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v.Name == "Token" or v.Name == "Collect" or v:FindFirstChild("TouchInterest") then
                        -- Cek apakah itu item event
                        if v.Parent:IsA("Model") and (v.Name == "HumanoidRootPart" or v.Name == "Head") then
                            -- Abaikan player
                        else
                            -- Teleport & FireTouch
                            firetouchinterest(Players.LocalPlayer.Character.HumanoidRootPart, v, 0)
                            firetouchinterest(Players.LocalPlayer.Character.HumanoidRootPart, v, 1)
                        end
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end

--// UI SETUP (Simple On/Off)

local MainTab = Window:MakeTab({
	Name = "Token Tools",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

MainTab:AddSection({
	Name = "Code Spammer"
})

MainTab:AddToggle({
	Name = "Spam Redeem Code 'FOXZIE'",
	Default = false,
	Callback = function(Value)
		_G.SpamFoxzie = Value
        if Value then
            OrionLib:MakeNotification({Name = "Active", Content = "Spamming Code 'FOXZIE'...", Time = 3})
            StartSpamCode()
        end
	end    
})

MainTab:AddLabel("Info: Hanya memberikan token jika kode belum pernah dipakai.")

MainTab:AddSection({
	Name = "Event Token Collector"
})

MainTab:AddToggle({
	Name = "Auto Collect Map Tokens (Event)",
	Default = false,
	Callback = function(Value)
		_G.AutoCollectTokens = Value
        if Value then StartAutoCollect() end
	end    
})

OrionLib:Init()
