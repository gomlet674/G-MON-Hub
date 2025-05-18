repeat task.wait() until game:IsLoaded()

local Players    = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local CoreGui    = game:GetService("CoreGui")

-- Setup
local VALID_KEY     = "GmonHub311851f3c742a8f78dce99e56992555609d23497928e9b33802e7127610c2e"
local SAVED_KEYFILE = "gmon_key.txt"
local GET_KEY_URL   = "https://linkvertise.com/1209226/get-key-gmon-hub-script"

-- Optional getgenv() key saving
getgenv().GMON_KEY = getgenv().GMON_KEY or nil

-- Simpan key jika didukung
local function saveKey(key)
    if writefile then
        writefile(SAVED_KEYFILE, key)
    else
        getgenv().GMON_KEY = key
    end
end

-- Baca key jika didukung
local function loadSavedKey()
    if isfile and readfile and isfile(SAVED_KEYFILE) then
        return readfile(SAVED_KEYFILE)
    elseif getgenv().GMON_KEY then
        return getgenv().GMON_KEY
    end
    return nil
end

-- Notifikasi aman
local function showNotification(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end)
end

-- Contoh daftar PlaceId
local GAME_SCRIPTS = {
    [2753915549] = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/main.lua",
    [537413528] = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/build.lua",
    [7449423635] = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Arena.lua"
}

local function loadGameScript()
    local url = GAME_SCRIPTS[game.PlaceId]
    if url then
        local success, result = pcall(function()
            loadstring(game:HttpGet(url, true))()
        end)
        if not success then
            warn("GMON Loader: Error executing script:", result)
        end
    else
        warn("GMON Loader: Unknown PlaceId:", game.PlaceId)
    end
end

-- GUI Setup
local loaderGui = Instance.new("ScreenGui")
loaderGui.Name = "GMON_Loader"
loaderGui.ResetOnSpawn = false
loaderGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
    loaderGui.Parent = CoreGui
end)

-- Background
local bg = Instance.new("ImageLabel", loaderGui)
bg.Name = "AnimeBackground"
bg.BackgroundTransparency = 1
bg.Size = UDim2.new(1, 0, 1, 0)
bg.Image = "rbxassetid://16790218639"
bg.ScaleType = Enum.ScaleType.Crop

-- Frame
local frame = Instance.new("Frame", loaderGui)
frame.Size = UDim2.new(0, 420, 0, 200)
frame.Position = UDim2.new(0.5, -210, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 15)

-- RGB Stroke
local stroke = Instance.new("UIStroke", frame)
stroke.Thickness = 2
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
task.spawn(function()
    local h = 0
    while frame and frame.Parent do
        h = (h + 0.01) % 1
        stroke.Color = Color3.fromHSV(h, 1, 1)
        task.wait(0.03)
    end
end)

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "GMON HUB KEY SYSTEM"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.new(1, 1, 1)

-- Key Box
local KeyBox = Instance.new("TextBox", frame)
KeyBox.PlaceholderText = "Enter Your Key..."
KeyBox.Size = UDim2.new(0.9, 0, 0, 35)
KeyBox.Position = UDim2.new(0.05, 0, 0.35, 0)
KeyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 8)

-- Submit Button
local Submit = Instance.new("TextButton", frame)
Submit.Text = "Submit"
Submit.Size = UDim2.new(0.42, 0, 0, 35)
Submit.Position = UDim2.new(0.05, 0, 0.65, 0)
Submit.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
Submit.Font = Enum.Font.GothamSemibold
Submit.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", Submit).CornerRadius = UDim.new(0, 8)

-- Get Key Button
local GetKey = Instance.new("TextButton", frame)
GetKey.Text = "Get Key"
GetKey.Size = UDim2.new(0.42, 0, 0, 35)
GetKey.Position = UDim2.new(0.53, 0, 0.65, 0)
GetKey.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
GetKey.Font = Enum.Font.GothamSemibold
GetKey.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", GetKey).CornerRadius = UDim.new(0, 8)

-- Submit Function
local function submitKey(key)
    if key == VALID_KEY then
        saveKey(key)
        showNotification("Key Valid", "Loading G-Mon Hub…", 2)
        task.wait(0.5)
        loaderGui:Destroy()
        loadGameScript()
        return true
    end
    return false
end

-- Auto Load Key
local auto = loadSavedKey()
if auto and submitKey(auto) then return end

-- Event GetKey
GetKey.MouseButton1Click:Connect(function()
    pcall(setclipboard, GET_KEY_URL)
    showNotification("G-Mon Hub", "Get Key link copied!", 2)
end)

-- Event Submit
Submit.MouseButton1Click:Connect(function()
    local k = KeyBox.Text or ""
    if k == "" then
        Submit.Text = "Enter Key"
        task.wait(1)
        Submit.Text = "Submit"
        return
    end
    if not submitKey(k) then
        Submit.Text = "Invalid!"
        task.wait(1)
        Submit.Text = "Submit"
    end
end)