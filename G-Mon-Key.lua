-- G-MON Modern Loader
repeat task.wait() until game:IsLoaded()

if getgenv().GmonLoaded then return end
getgenv().GmonLoaded = true

local Players     = game:GetService("Players")
local StarterGui  = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local CoreGui     = game:GetService("CoreGui")

local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

-- CONFIG
local SAVED_KEYFILE   = "gmon_hub_key.txt"
local GET_KEY_URL     = "https://lootdest.org/s?Rz0xk547"
local VERIFY_KEY_URL  = "https://key-system-production-5986.up.railway.app/verify"
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/main.lua"

local function showNotification(title, text, duration)
    pcall(function() StarterGui:SetCore("SendNotification", {Title=title, Text=text, Duration=duration or 3}) end)
end

if not httprequest then return game.Players.LocalPlayer:Kick("Executor Not Supported.") end

local function loadMainScript()
    local ok, Main = pcall(function() return loadstring(game:HttpGet(MAIN_SCRIPT_URL, true))() end)
    if ok and type(Main) == "table" and type(Main.Start) == "function" then
        Main.Start()
    else
        warn("G-MON: Failed to load main script.")
    end
end

-- ===================== MODERN GUI BUILDER =====================
local loaderGui = Instance.new("ScreenGui")
loaderGui.Name = "GMON_Modern_Auth"
loaderGui.ResetOnSpawn = false
loaderGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    if gethui then loaderGui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(loaderGui); loaderGui.Parent = CoreGui
    else loaderGui.Parent = CoreGui end
end)

local frame = Instance.new("Frame", loaderGui)
frame.Size = UDim2.new(0, 380, 0, 200)
frame.Position = UDim2.new(0.5, -190, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(24, 24, 27) -- Dark Gray (Zinc-900)
frame.Active = true; frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

-- Drop Shadow Effect
local shadow = Instance.new("ImageLabel", frame)
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
shadow.Size = UDim2.new(1, 40, 1, 40)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.4
shadow.ZIndex = 0

local border = Instance.new("UIStroke", frame)
border.Color = Color3.fromRGB(99, 102, 241) -- Indigo-500
border.Thickness = 1.5

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "G-MON HUB"
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(255, 255, 255)

local KeyBox = Instance.new("TextBox", frame)
KeyBox.Size = UDim2.new(0.85, 0, 0, 40)
KeyBox.Position = UDim2.new(0.075, 0, 0.35, 0)
KeyBox.BackgroundColor3 = Color3.fromRGB(9, 9, 11) -- Blacker Gray
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextSize = 14
KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyBox.TextXAlignment = Enum.TextXAlignment.Center
KeyBox.PlaceholderText = "Paste your key here..."
KeyBox.Text = "" -- BERSIH
Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 8)

local boxBorder = Instance.new("UIStroke", KeyBox)
boxBorder.Color = Color3.fromRGB(63, 63, 70)
boxBorder.Thickness = 1

local Submit = Instance.new("TextButton", frame)
Submit.Text = "VERIFY"
Submit.Size = UDim2.new(0.4, 0, 0, 40)
Submit.Position = UDim2.new(0.075, 0, 0.65, 0)
Submit.BackgroundColor3 = Color3.fromRGB(99, 102, 241) -- Indigo-500
Submit.Font = Enum.Font.GothamBold; Submit.TextSize = 13
Submit.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", Submit).CornerRadius = UDim.new(0, 8)

local GetKey = Instance.new("TextButton", frame)
GetKey.Text = "GET KEY"
GetKey.Size = UDim2.new(0.4, 0, 0, 40)
GetKey.Position = UDim2.new(0.525, 0, 0.65, 0)
GetKey.BackgroundColor3 = Color3.fromRGB(39, 39, 42) -- Zinc-800
GetKey.Font = Enum.Font.GothamBold; GetKey.TextSize = 13
GetKey.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", GetKey).CornerRadius = UDim.new(0, 8)

-- ===================== LOGIC =====================
local function verifyKeyServer(keyStr)
    local success, response = pcall(function()
        return httprequest({
            Url = VERIFY_KEY_URL, Method = "POST",
            Headers = { 
                ["Content-Type"] = "application/json",
                ["identifier"] = game:GetService("RbxAnalyticsService"):GetClientId() 
            },
            Body = HttpService:JSONEncode({key = keyStr})
        })
    end)
    if success and response.StatusCode == 200 then
        local data = HttpService:JSONDecode(response.Body)
        return data.valid, data.msg
    end
    return false, "Connection Error"
end

local function onKeyValid(keyStr)
    writefile(SAVED_KEYFILE, keyStr)
    Submit.Text = "SUCCESS"
    Submit.BackgroundColor3 = Color3.fromRGB(16, 185, 129) -- Emerald Green
    task.wait(0.5)
    loaderGui:Destroy()
    loadMainScript()
end

if isfile(SAVED_KEYFILE) then
    local savedKey = readfile(SAVED_KEYFILE)
    if savedKey and savedKey ~= "" then
        Submit.Text = "CHECKING..."
        local isValid = verifyKeyServer(savedKey)
        if isValid then
            onKeyValid(savedKey)
            return
        else
            Submit.Text = "VERIFY"
        end
    end
end

GetKey.MouseButton1Click:Connect(function()
    setclipboard(GET_KEY_URL)
    showNotification("G-MON", "Link copied to clipboard!", 2)
end)

Submit.MouseButton1Click:Connect(function()
    local inputKey = KeyBox.Text:gsub("%s+", "")
    if inputKey == "" then return end
    Submit.Text = "..."
    
    local isValid, msg = verifyKeyServer(inputKey)
    if isValid then
        onKeyValid(inputKey)
    else
        KeyBox.Text = ""
        KeyBox.PlaceholderText = msg or "INVALID"
        Submit.Text = "FAILED"
        Submit.BackgroundColor3 = Color3.fromRGB(239, 68, 68) -- Red
        task.wait(1.5)
        Submit.Text = "VERIFY"
        Submit.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
        KeyBox.PlaceholderText = "Paste your key here..."
    end
end)
