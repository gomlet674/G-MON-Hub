-- GMON_Loader.lua (Universal)

repeat task.wait() until game:IsLoaded()

-- Layanan Roblox & Executor HTTP
local Players     = game:GetService("Players")
local StarterGui  = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

-- Mendukung berbagai macam Executor (Delta, Fluxus, Synapse, Krnl, dll)
local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

-- Pengaturan Sistem
local SAVED_KEYFILE   = "gmon_key.txt"
local GET_KEY_URL     = "https://key-system-production-5986.up.railway.app/start"
local VERIFY_KEY_URL  = "https://key-system-production-5986.up.railway.app/verify"
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/main.lua"

-- Notifikasi
local function showNotification(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3,
        })
    end)
end

if not httprequest then
    showNotification("GMON Hub", "Executor Anda tidak support HTTP Request!", 5)
    return
end

-- Fungsi load script utama
local function loadMainScript()
    local ok, Main = pcall(function()
        return loadstring(game:HttpGet(MAIN_SCRIPT_URL, true))()
    end)

    if not ok then
        warn("GMON Loader: gagal load main.lua")
        showNotification("Error", "Gagal memuat script utama.", 3)
        return
    end

    if type(Main) ~= "table" or type(Main.Start) ~= "function" then
        warn("GMON Loader: Struktur main.lua tidak valid")
        return
    end

    Main.Start()
end

-- GUI Key System
local CoreGui = game:GetService("CoreGui")
local loaderGui = Instance.new("ScreenGui")
loaderGui.Name           = "GMON_Loader_Secure"
loaderGui.ResetOnSpawn   = false
loaderGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Proteksi agar tidak mudah dideteksi anticheat
if gethui then
    loaderGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(loaderGui)
    loaderGui.Parent = CoreGui
else
    loaderGui.Parent = CoreGui
end

-- Background anime
local bg = Instance.new("ImageLabel", loaderGui)
bg.Name                   = "AnimeBackground"
bg.BackgroundTransparency = 1
bg.Size                   = UDim2.new(1,0,1,0)
bg.Image                  = "rbxassetid://16790218639"
bg.ScaleType              = Enum.ScaleType.Crop

-- Frame utama
local frame = Instance.new("Frame", loaderGui)
frame.Size              = UDim2.new(0,420,0,200)
frame.Position          = UDim2.new(0.5,-210,0.5,-100)
frame.BackgroundColor3  = Color3.fromRGB(20,20,20)
frame.Active            = true
frame.Draggable         = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,15)

-- Border RGB
local stroke = Instance.new("UIStroke", frame)
stroke.Thickness       = 2
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
task.spawn(function()
    local hue = 0
    while frame.Parent do
        hue = (hue + 0.01) % 1
        stroke.Color = Color3.fromHSV(hue,1,1)
        task.wait(0.03)
    end
end)

-- Judul
local title = Instance.new("TextLabel", frame)
title.Size                   = UDim2.new(1,0,0,40)
title.Position               = UDim2.new(0,0,0,0)
title.BackgroundTransparency = 1
title.Text                   = "GMON HUB KEY SYSTEM"
title.Font                   = Enum.Font.GothamBold
title.TextSize               = 20
title.TextColor3             = Color3.new(1,1,1)

-- Kotak input
local KeyBox = Instance.new("TextBox", frame)
KeyBox.PlaceholderText  = "Enter Your Key..."
KeyBox.Size             = UDim2.new(0.9,0,0,35)
KeyBox.Position         = UDim2.new(0.05,0,0.35,0)
KeyBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
KeyBox.Font             = Enum.Font.Gotham
KeyBox.TextColor3       = Color3.new(1,1,1)
KeyBox.TextXAlignment   = Enum.TextXAlignment.Center
KeyBox.ClearTextOnFocus = false
Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0,8)

-- Tombol Submit
local Submit = Instance.new("TextButton", frame)
Submit.Text             = "Submit"
Submit.Size             = UDim2.new(0.42,0,0,35)
Submit.Position         = UDim2.new(0.05,0,0.65,0)
Submit.BackgroundColor3 = Color3.fromRGB(0,170,127)
Submit.Font             = Enum.Font.GothamSemibold
Submit.TextColor3       = Color3.new(1,1,1)
Instance.new("UICorner", Submit).CornerRadius = UDim.new(0,8)

-- Tombol Get Key
local GetKey = Instance.new("TextButton", frame)
GetKey.Text             = "Get Key"
GetKey.Size             = UDim2.new(0.42,0,0,35)
GetKey.Position         = UDim2.new(0.53,0,0.65,0)
GetKey.BackgroundColor3 = Color3.fromRGB(255,85,0)
GetKey.Font             = Enum.Font.GothamSemibold
GetKey.TextColor3       = Color3.new(1,1,1)
Instance.new("UICorner", GetKey).CornerRadius = UDim.new(0,8)

-- Fungsi Verifikasi ke API Server
local function verifyKeyServer(key)
    if key == "" then return false end
    
    local success, response = pcall(function()
        return httprequest({
            Url = VERIFY_KEY_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({key = key})
        })
    end)

    if success and response.StatusCode == 200 then
        local data = HttpService:JSONDecode(response.Body)
        return data.valid == true
    end
    
    return false
end

-- Fungsi eksekusi setelah valid
local function onKeyValid(key)
    writefile(SAVED_KEYFILE, key)
    showNotification("Key Valid", "Loading G-Mon Hub…", 2)
    Submit.Text = "Verified!"
    Submit.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    task.wait(0.5)
    loaderGui:Destroy()
    loadMainScript()
end

-- Auto-submit jika key tersimpan
if isfile(SAVED_KEYFILE) then
    local savedKey = readfile(SAVED_KEYFILE)
    if savedKey and savedKey ~= "" then
        Submit.Text = "Checking Saved Key..."
        if verifyKeyServer(savedKey) then
            onKeyValid(savedKey)
            return -- Hentikan eksekusi UI lebih lanjut karena sudah valid
        else
            Submit.Text = "Saved Key Expired"
            task.wait(1.5)
            Submit.Text = "Submit"
        end
    end
end

-- Event tombol Get Key
GetKey.MouseButton1Click:Connect(function()
    setclipboard(GET_KEY_URL)
    showNotification("G-Mon Hub", "Link Get Key disalin ke clipboard!", 3)
end)

-- Event tombol Submit
Submit.MouseButton1Click:Connect(function()
    local inputKey = KeyBox.Text:gsub("%s+", "") -- Hapus spasi
    
    if inputKey == "" then
        Submit.Text = "Key cannot be empty!"
        Submit.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        task.wait(1.5)
        Submit.Text = "Submit"
        Submit.BackgroundColor3 = Color3.fromRGB(0,170,127)
        return
    end

    Submit.Text = "Verifying..."
    
    if verifyKeyServer(inputKey) then
        onKeyValid(inputKey)
    else
        Submit.Text = "Invalid / Expired!"
        Submit.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        task.wait(1.5)
        Submit.Text = "Submit"
        Submit.BackgroundColor3 = Color3.fromRGB(0,170,127)
    end
end)
