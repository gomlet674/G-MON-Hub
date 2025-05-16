-- GMON HUB - MAIN.LUA (RGB UI + TOGGLE MELINGKAR)

-- Load Rayfield UI local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"))()

-- Load Source (GMON Logic) local GMON = loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/source.lua"))()

-- Window Utama local Window = Rayfield:CreateWindow({ Name = "GMON HUB | Blox Fruits", LoadingTitle = "Loading GMON HUB...", LoadingSubtitle = "by gomlet674", ConfigurationSaving = { Enabled = true, FolderName = "GMONHub", FileName = "GMONConfig" }, Discord = { Enabled = false } })

-- Tambahan: UI Toggle Melayang & RGB local CoreGui = game:GetService("CoreGui") local TweenService = game:GetService("TweenService") local ToggleGUI = Instance.new("ScreenGui", CoreGui) ToggleGUI.Name = "GMON_ToggleGUI" ToggleGUI.ResetOnSpawn = false

local ToggleFrame = Instance.new("Frame", ToggleGUI) ToggleFrame.Size = UDim2.new(0, 60, 0, 60) ToggleFrame.Position = UDim2.new(0, 50, 0.2, 0) ToggleFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255) ToggleFrame.BackgroundTransparency = 0.2 ToggleFrame.BorderSizePixel = 0 ToggleFrame.Draggable = true ToggleFrame.Active = true ToggleFrame.AnchorPoint = Vector2.new(0.5, 0.5) ToggleFrame.ZIndex = 2

local UICorner = Instance.new("UICorner", ToggleFrame) UICorner.CornerRadius = UDim.new(1, 0)

local UIGradient = Instance.new("UIGradient", ToggleFrame) UIGradient.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)) }

-- Rainbow effect spawn(function() while task.wait(0.03) do local tick = tick() % 5 / 5 UIGradient.Rotation = UIGradient.Rotation + 1 end end)

local ToggleText = Instance.new("TextLabel", ToggleFrame) ToggleText.Size = UDim2.new(1, 0, 1, 0) ToggleText.Text = "GMON" ToggleText.BackgroundTransparency = 1 ToggleText.TextScaled = true ToggleText.TextColor3 = Color3.new(1, 1, 1)

local gmonVisible = true ToggleFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then gmonVisible = not gmonVisible for _, v in pairs(CoreGui:GetChildren()) do if v.Name == "Rayfield" then v.Enabled = gmonVisible end end end end)

-- UI Tabs & Logic local Tab = Window:CreateTab("Main", 4483362458) Tab:CreateSection("Chest & Chalice")

Tab:CreateToggle("ESP God Chalice", nil, function(state) if GMON and GMON.ESPGodChalice then GMON.ESPGodChalice(state) end end)

Tab:CreateButton("Start Farm Chest", function() if GMON and GMON.FarmChest then GMON.FarmChest() end end)

Tab:CreateButton("Stop Farm Chest", function() if GMON and GMON.StopFarmChest then GMON.StopFarmChest() end end)

-- Tambahkan GUI latar belakang anime jika diperlukan di loader.lua

