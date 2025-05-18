-- GMON_Loader.lua (StarterPlayerScripts)

repeat task.wait() until game:IsLoaded()

-- Layanan Roblox
local Players    = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- Pengaturan
local VALID_KEY     = "GmonHub311851f3c742a8f78dce99e56992555609d23497928e9b33802e7127610c2e"
local SAVED_KEYFILE = "gmon_key.txt"
local GET_KEY_URL   = "https://linkvertise.com/1209226/get-key-gmon-hub-script"

-- **Hanya satu URL main.lua** untuk semua game
local MAIN_URL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/main.lua"

-- Fungsi notifikasi
local function showNotification(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title    = title,
        Text     = text,
        Duration = duration or 3,
    })
end

-- Fungsi load main.lua
local function loadGameScript()
    local ok, err = pcall(function()
        loadstring(game:HttpGet(MAIN_URL, true))()
    end)
    if not ok then
        warn("GMON Loader: Gagal memuat main.lua:", err)
    end
end

-- Bikin GUI
local loaderGui = Instance.new("ScreenGui")
loaderGui.Name           = "GMON_Loader"
loaderGui.ResetOnSpawn   = false
loaderGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
loaderGui.Parent         = game:GetService("CoreGui")

local frame = Instance.new("Frame", loaderGui)
frame.Size             = UDim2.new(0,420,0,200)
frame.Position         = UDim2.new(0.5,-210,0.5,-100)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.Active           = true
frame.Draggable        = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,15)

local title = Instance.new("TextLabel", frame)
title.Size                   = UDim2.new(1,0,0,40)
title.Position               = UDim2.new(0,0,0,0)
title.BackgroundTransparency = 1
title.Text                   = "GMON HUB KEY SYSTEM"
title.Font                   = Enum.Font.GothamBold
title.TextSize               = 20
title.TextColor3             = Color3.new(1,1,1)

local KeyBox = Instance.new("TextBox", frame)
KeyBox.PlaceholderText  = "Enter Your Key..."
KeyBox.Size             = UDim2.new(0.9,0,0,35)
KeyBox.Position         = UDim2.new(0.05,0,0.35,0)
KeyBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
KeyBox.Font             = Enum.Font.Gotham
KeyBox.TextColor3       = Color3.new(1,1,1)
Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0,8)

local Submit = Instance.new("TextButton", frame)
Submit.Text             = "Submit"
Submit.Size             = UDim2.new(0.42,0,0,35)
Submit.Position         = UDim2.new(0.05,0,0.65,0)
Submit.BackgroundColor3 = Color3.fromRGB(0,170,127)
Submit.Font             = Enum.Font.GothamSemibold
Submit.TextColor3       = Color3.new(1,1,1)
Instance.new("UICorner", Submit).CornerRadius = UDim.new(0,8)

local GetKey = Instance.new("TextButton", frame)
GetKey.Text             = "Get Key"
GetKey.Size             = UDim2.new(0.42,0,0,35)
GetKey.Position         = UDim2.new(0.53,0,0.65,0)
GetKey.BackgroundColor3 = Color3.fromRGB(255,85,0)
GetKey.Font             = Enum.Font.GothamSemibold
GetKey.TextColor3       = Color3.new(1,1,1)
Instance.new("UICorner", GetKey).CornerRadius = UDim.new(0,8)

-- Fungsi submitKey
local function submitKey(key)
    if key == VALID_KEY then
        writefile(SAVED_KEYFILE, key)
        showNotification("Key Valid", "Loading…", 2)
        task.wait(0.5)
        loaderGui:Destroy()
        loadGameScript()
        return true
    end
    return false
end

-- Auto-submit jika key sudah tersimpan
if isfile(SAVED_KEYFILE) then
    local saved = readfile(SAVED_KEYFILE)
    if submitKey(saved) then return end
end

-- Tombol Get Key
GetKey.MouseButton1Click:Connect(function()
    setclipboard(GET_KEY_URL)
    showNotification("G-Mon Hub", "Link Get Key disalin!", 2)
end)

-- Tombol Submit
Submit.MouseButton1Click:Connect(function()
    local k = KeyBox.Text or ""
    if k == "" then
        Submit.Text = "Enter Key"
        task.wait(2)
        Submit.Text = "Submit"
        return
    end
    if not submitKey(k) then
        Submit.Text = "Invalid!"
        task.wait(2)
        Submit.Text = "Submit"
    end
end)