-- GMON HUB - MAIN LOADER
-- UI by Rayfield | Background anime | Load source.lua

local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"))()

local Window = Rayfield:CreateWindow({
	Name = "GMON HUB | Blox Fruits",
	LoadingTitle = "Loading GMON HUB...",
	LoadingSubtitle = "by gomlet674",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "GMONHub",
		FileName = "GMONConfig"
	},
	KeySystem = false,
	Discord = {
		Enabled = false
	}
})

-- Toggle Button UI (kanan atas)
local ToggleUI = Instance.new("ScreenGui", game.CoreGui)
ToggleUI.Name = "GMON_Toggle"
ToggleUI.ResetOnSpawn = false

local Button = Instance.new("TextButton", ToggleUI)
Button.Size = UDim2.new(0, 110, 0, 30)
Button.Position = UDim2.new(1, -120, 0, 100)
Button.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
Button.Text = "Toggle GMON"
Button.TextSize = 14

local gmonVisible = true
Button.MouseButton1Click:Connect(function()
	gmonVisible = not gmonVisible
	for _, gui in pairs(game.CoreGui:GetChildren()) do
		if gui.Name == "Rayfield" then
			gui.Enabled = gmonVisible
		end
	end
end)

-- Load Source
local GMON = loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/source.lua"))()

-- UI Library (contoh sederhana)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Moon/main/source.lua"))()
local Window = Library:CreateWindow("GMON Hub - Farm Chest")

-- Tab & Section
local Tab = Window:CreateTab("Main", 4483362458) -- ID icon bebas
local Section = Tab:CreateSection("Chest & Chalice")

-- Toggle: ESP God Chalice
Tab:CreateToggle("ESP God Chalice", nil, function(state)
    if state then
        GMON.ESPGodChalice()
    end
end)

-- Button: Start Farm Chest
Tab:CreateButton("Start Farm Chest", function()
    GMON.FarmChest()
end)

-- Button: Stop Farm Chest
Tab:CreateButton("Stop Farm Chest", function()
    GMON.StopFarmChest()
end)