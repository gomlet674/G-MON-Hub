-- Load Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"))()

-- Buat window utama
local Window = Rayfield:CreateWindow({
	Name = "GMON HUB | Blox Fruits",
	LoadingTitle = "Loading GMON HUB...",
	LoadingSubtitle = "by gomlet674",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "GMONHub",
		FileName = "GMONConfig"
	},
	KeySystem = false
})

-- Tab & Section
local Tab = Window:CreateTab("Main", 4483362458)
Tab:CreateSection("Chest & Chalice")

-- Load GMON Source
local GMON = loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/source.lua"))()

Tab:CreateToggle("ESP God Chalice", nil, function(state)
	if GMON and GMON.ESPGodChalice then
		GMON.ESPGodChalice(state)
	end
end)

Tab:CreateButton("Start Farm Chest", function()
	if GMON and GMON.FarmChest then
		GMON.FarmChest()
	end
end)

Tab:CreateButton("Stop Farm Chest", function()
	if GMON and GMON.StopFarmChest then
		GMON.StopFarmChest()
	end
end)