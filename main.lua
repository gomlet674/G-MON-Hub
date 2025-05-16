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

local Tab = Window:CreateTab("Main", 4483362458)
local Section = Tab:CreateSection("Farm & ESP")

-- Contoh toggle ESP God Chalice
Tab:CreateToggle("ESP God Chalice", nil, function(state)
    if state then
        -- Panggil fungsi ESP dari source.lua
        if GMON and GMON.ESPGodChalice then
            GMON.ESPGodChalice()
        end
    else
        -- Matikan ESP jika ada fungsi stop
        if GMON and GMON.StopESPGodChalice then
            GMON.StopESPGodChalice()
        end
    end
end)

-- Contoh tombol Start Farm Chest
Tab:CreateButton("Start Farm Chest", function()
    if GMON and GMON.FarmChest then
        GMON.FarmChest()
    end
end)

-- Contoh tombol Stop Farm Chest
Tab:CreateButton("Stop Farm Chest", function()
    if GMON and GMON.StopFarmChest then
        GMON.StopFarmChest()
    end
end)