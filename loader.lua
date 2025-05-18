-- loader.lua 
-- LocalScript di StarterPlayerScripts

-- Debug print untuk line error
 print("[GMON Loader] Script mulai dieksekusi")

-- Tunggu game siap (loop universal)
 repeat task.wait() until game:IsLoaded() print("[GMON Loader] Game loaded, PlaceId =", game.PlaceId)

-- Services 
local Players = game:GetService("Players") local MarketplaceService = game:GetService("MarketplaceService") local TweenService = game:GetService("TweenService") local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer local playerGui = player:WaitForChild("PlayerGui")

-- Notifikasi di tengah layar
 local function showCenterNotification(text, duration) duration = duration or 3 local screenGui = Instance.new("ScreenGui") screenGui.Name = "GMONNotification" screenGui.ResetOnSpawn = false screenGui.Parent = playerGui

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 250, 0, 50)
frame.Position = UDim2.new(0.5, -125, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.ZIndex = 10

Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)
local label = Instance.new("TextLabel", frame)
label.Size = UDim2.new(1,0,1,0)
label.BackgroundTransparency = 1
label.Text = text
label.Font = Enum.Font.GothamSemibold
label.TextSize = 16
label.TextColor3 = Color3.new(1,1,1)
label.TextWrapped = true

-- Tween in/out
TweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
delay(duration, function()
    TweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    TweenService:Create(label, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    task.delay(0.35, function() screenGui:Destroy() end)
end)

end

-- Tampilkan deteksi game local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Game) end) local gameName = ok and info.Name or "Unknown" showCenterNotification("Detected Game: " .. gameName, 4) print("[GMON Loader] Detected game:", gameName)

-- Loader GUI via CoreGui (pertama kali) atau PlayerGui local guiRoot = CoreGui or playerGui

-- UI Elements local loaderGui = Instance.new("ScreenGui") loaderGui.Name = "GMON_LoaderGui" loaderGui.ResetOnSpawn = false loaderGui.Parent = guiRoot

-- Background semi dark local bg = Instance.new("Frame", loaderGui) bg.Size = UDim2.new(1,0,1,0) bg.BackgroundColor3 = Color3.fromRGB(0,0,0) bg.BackgroundTransparency = 0.6 bg.ZIndex = 1

-- Main container local frame = Instance.new("Frame", loaderGui) frame.Name = "Container" frame.Size = UDim2.new(0, 350, 0, 150) frame.Position = UDim2.new(0.5, -175, 0.5, -75) frame.BackgroundColor3 = Color3.fromRGB(20,20,20) frame.ZIndex = 2 frame.Active = true

-- Rounded corners Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)

-- Title local title = Instance.new("TextLabel", frame) title.Size = UDim2.new(1,0,0,30) title.Position = UDim2.new(0,0,0,5) title.Text = "GMON Hub Key" title.Font = Enum.Font.GothamBold title.TextSize = 18 title.TextColor3 = Color3.new(1,1,1) title.BackgroundTransparency = 1

-- Key input local keyBox = Instance.new("TextBox", frame) keyBox.Size = UDim2.new(0.9,0,0,30) keyBox.Position = UDim2.new(0.05,0,0,50) keyBox.PlaceholderText = "Enter your key..." keyBox.Font = Enum.Font.Gotham tkeyBox.TextColor3 = Color3.new(1,1,1) keyBox.BackgroundColor3 = Color3.fromRGB(40,40,40) Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0,5)

-- Submit button local submitBtn = Instance.new("TextButton", frame) submitBtn.Size = UDim2.new(0.4,0,0,30) submitBtn.Position = UDim2.new(0.05,0,1, -40) submitBtn.Text = "Submit" submitBtn.Font = Enum.Font.GothamSemibold submitBtn.TextSize = 16 submitBtn.TextColor3 = Color3.new(1,1,1) submitBtn.BackgroundColor3 = Color3.fromRGB(0,170,127) Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0,5)

-- Map PlaceId to scripts local GAME_SCRIPTS = { [4442272183] = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/main.lua", [3233893879] = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/main_arena.lua", [537413528]  = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/build.lua", }

local VALID_KEY = "GmonHub311851f3c742a8f78dce99e56992555609d23497928e9b33802e7127610c2e" local keyFile = "gmon_key.txt"

-- Function load game script local function loadGameScript() local url = GAME_SCRIPTS[game.PlaceId] if not url then warn("[GMON Loader] Game tidak dikenali: " .. tostring(game.PlaceId)) showCenterNotification("Game not supported!", 3) return end showCenterNotification("Loading script...", 2) print("[GMON Loader] Loading URL: "..url) local ok, err = pcall(function() loadstring(game:HttpGet(url, true))() end) if not ok then warn("[GMON Loader] Error load script:", err) end end

-- Handle submit submitBtn.MouseButton1Click:Connect(function() local key = keyBox.Text:match("%S+") or "" if key == "" then showCenterNotification("Please enter a key!", 2) return end if key == VALID_KEY then writefile(keyFile, key) loaderGui:Destroy() loadGameScript() else showCenterNotification("Invalid Key!", 2) print("[GMON Loader] Invalid key entered:", key) end end)

-- Auto-check saved key if isfile(keyFile) then local saved = readfile(keyFile) if saved == VALID_KEY then loaderGui:Destroy() loadGameScript() else print("[GMON Loader] Saved key invalid, removing file.") delfile(keyFile) end end

print("[GMON Loader] Script siap digunakan")

