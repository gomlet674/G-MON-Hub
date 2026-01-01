repeat task.wait() until game:IsLoaded()

--==================== SERVICES =====================--
local TweenService = game:GetService("TweenService")

--==================== LOAD RAYFIELD =====================--
local Rayfield = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/shlexware/Rayfield/main/source"
))()

--==================== WINDOW =====================--
local Window = Rayfield:CreateWindow({
    Name = "GMON HUB",
    LoadingTitle = "GMON HUB",
    LoadingSubtitle = "Auto Game Detector",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GMON",
        FileName = "GMON_Config"
    }
})

local PlaceId = game.PlaceId

--==================== SAFE UNIVERSAL LOADER =====================--
local function safeLoad(url)
    local ok, module = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)

    if ok and type(module) == "table" and type(module.Start) == "function" then
        module.Start(Window)
    else
        Rayfield:Notify({
            Title = "GMON HUB",
            Content = "Module gagal dimuat",
            Duration = 6
        })
    end
end

--==================== GAME DATABASE =====================--
local Games = {
    -- Car Dealership Tycoon
    [654732683] = {
        Name = "Car Dealership Tycoon",
        Short = "CDT",
        Url = "https://pandadevelopment.net/virtual/file/fef83e33e7275173"
    },

    -- Build A Boat For Treasure
    [537413528] = {
        Name = "Build A Boat",
        Short = "BABFT",
        Url = "https://pandadevelopment.net/virtual/file/dace186f8425b825"
    },

    -- Blox Fruits
    [2753915549] = {
        Name = "Blox Fruits",
        Short = "Blox",
        Url = "https://pandadevelopment.net/virtual/file/f2e45fc211ee862d"
    },

    -- War Tycoon
    [4639625707] = {
        Name = "War Tycoon",
        Short = "War",
        Url = "https://yourdomain.com/war_tycoon.lua"
    },

    -- 99 Nights in the Forest
    [10449761463] = {
        Name = "99 Nights in the Forest",
        Short = "99 Nights",
        Url = "https://yourdomain.com/99_nights.lua"
    }
}

--==================== RAYFIELD FADE-IN (UNIVERSAL) =====================--
task.spawn(function()
    task.wait(0.25)
    local gui = game:GetService("CoreGui"):FindFirstChild("Rayfield")
    if not gui then return end

    for _,v in ipairs(gui:GetDescendants()) do
        if v:IsA("Frame") then
            v.BackgroundTransparency = 1
            TweenService:Create(
                v,
                TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 0.3}
            ):Play()
        end
    end
end)

--==================== AUTO GAME DETECT & LOAD =====================--
local gameInfo = Games[PlaceId]

if gameInfo then
    Rayfield:Notify({
        Title = "GMON HUB",
        Content = "🎮 Game Detected: "..gameInfo.Name,
        Duration = 4
    })

    -- info tab (opsional, hanya info)
    local GameTab = Window:CreateTab("Game", 4483362458)
    GameTab:CreateParagraph({
        Title = "Game Detected",
        Content = gameInfo.Name .. " (" .. gameInfo.Short .. ")\nAuto loading..."
    })

    -- AUTO LOAD TANPA TOMBOL
    task.delay(0.5, function()
        safeLoad(gameInfo.Url)
    end)

else
    Rayfield:Notify({
        Title = "GMON HUB",
        Content = "Game tidak didukung",
        Duration = 5
    })

    local GameTab = Window:CreateTab("Game", 4483362458)
    GameTab:CreateParagraph({
        Title = "Unsupported Game",
        Content = "Game ini belum tersedia di GMON HUB"
    })
end