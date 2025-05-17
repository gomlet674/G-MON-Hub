-- GMON Hub Build A Boat For Treasure
-- https://www.roblox.com/games/537413528

local GuiLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/libs/ui.lua"))()

local Window = GuiLibrary:CreateWindow("GMON - Build A Boat", "Build A Boat Script | gomlet674", "rbxassetid://14237311836")
local Tab = Window:CreateTab("Main")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Auto Farm Function
local AutoFarmEnabled = false
Tab:AddToggle("Auto Farm Chest", false, function(state)
    AutoFarmEnabled = state
    if state then
        while AutoFarmEnabled and task.wait(1) do
            local boat = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if boat then
                boat.Anchored = false
                local goal = CFrame.new(9620, -10, -75) -- posisi chest
                local tween = TweenService:Create(boat, TweenInfo.new(10, Enum.EasingStyle.Linear), {CFrame = goal})
                tween:Play()
            end
        end
    end
end)

-- Copy Build Function
Tab:AddButton("Copy Build from Player", function()
    local targetPlayer = nil
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            targetPlayer = player
            break
        end
    end

    if targetPlayer then
        local function cloneBuild(targetModel)
            local clone = targetModel:Clone()
            clone.Parent = workspace
            clone:SetPrimaryPartCFrame(LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 10, 0))
        end

        local builds = workspace:FindFirstChild(targetPlayer.Name)
        if builds then
            for _, part in pairs(builds:GetChildren()) do
                if part:IsA("Model") then
                    cloneBuild(part)
                end
            end
        end
    else
        game.StarterGui:SetCore("SendNotification", {
            Title = "GMON",
            Text = "Tidak ada pemain lain untuk dicopy.",
            Duration = 5
        })
    end
end)

-- Setting Tab
local SettingTab = Window:CreateTab("Settings")
SettingTab:AddButton("Destroy UI", function()
    GuiLibrary:Destroy()
end)