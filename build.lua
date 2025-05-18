-- GMON Hub Build A Boat For Treasure
-- Game: https://www.roblox.com/games/537413528

-- UI Library: Kavo
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("GMON - Build A Boat", "Ocean")

local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Features")

local SettingsTab = Window:NewTab("Settings")
local SettingsSection = SettingsTab:NewSection("UI Options")

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")

-- Auto Farm Chest
local AutoFarmEnabled = false
MainSection:NewToggle("Auto Farm Chest", "Teleport ke chest otomatis", function(state)
    AutoFarmEnabled = state

    task.spawn(function()
        while AutoFarmEnabled do
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                hrp.CFrame = CFrame.new(9620, -10, -75) -- posisi chest
            end
            repeat wait(1) until not AutoFarmEnabled
        end
    end)
end)

-- Copy Build
MainSection:NewButton("Copy Build from Player", "Salin build dari pemain lain", function()
    local targetPlayer = nil
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            targetPlayer = player
            break
        end
    end

    if targetPlayer then
        local builds = workspace:FindFirstChild(targetPlayer.Name)
        if builds then
            for _, item in pairs(builds:GetChildren()) do
                if item:IsA("Model") or item:IsA("Part") then
                    local clone = item:Clone()
                    clone.Parent = workspace

                    if clone:IsA("Model") and clone.PrimaryPart then
                        clone:SetPrimaryPartCFrame(LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 10, 0))
                    elseif clone:IsA("Part") then
                        clone.Position = LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 10, 0)
                    end
                end
            end
        else
            StarterGui:SetCore("SendNotification", {
                Title = "GMON",
                Text = "Build dari player tidak ditemukan.",
                Duration = 5
            })
        end
    else
        StarterGui:SetCore("SendNotification", {
            Title = "GMON",
            Text = "Tidak ada pemain lain untuk dicopy.",
            Duration = 5
        })
    end
end)

-- Destroy UI
SettingsSection:NewButton("Destroy UI", "Menutup GMON GUI", function()
    Library:ToggleUI()
end)