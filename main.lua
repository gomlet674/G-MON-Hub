repeat task.wait() until game:IsLoaded()

local Rayfield = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/shlexware/Rayfield/main/source"
))()

local Window = Rayfield:CreateWindow({
    Name = "GMON HUB",
    LoadingTitle = "GMON HUB",
    LoadingSubtitle = "Universal",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GMON",
        FileName = "GMON_Config"
    }
})

local PlaceId = game.PlaceId
local Modules = {}

local function safeLoad(url)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if ok and type(result) == "table" and type(result.Start) == "function" then
        result.Start(Window)
    else
        Rayfield:Notify({
            Title = "GMON Error",
            Content = "Module gagal load",
            Duration = 6
        })
    end
end

-- Car Dealership Tycoon
if PlaceId == 654732683 then
    safeLoad("https://pandadevelopment.net/virtual/file/fef83e33e7275173"))()")

-- Build A Boat
elseif PlaceId == 537413528 then
    safeLoad("https://pandadevelopment.net/virtual/file/dace186f8425b825"))()")

-- Blox Fruits
elseif PlaceId == 2753915549 then
    safeLoad("https://pandadevelopment.net/virtual/file/f2e45fc211ee862d"))()")

else
    Rayfield:Notify({
        Title = "GMON HUB",
        Content = "Game tidak didukung",
        Duration = 5
    })
end