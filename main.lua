-- main.lua for SkullHub (Main UI only, no key system)
-- Entry point: build main UI and load individual modules

-- Load Kavo UI Library
local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/RobloxHacking/Kavo-UI-Library/main/Kavo.lua', true))() local Window = Library.CreateLib("SkullHub", "Ocean")

-- CORE Tab: Central loader
local CoreTab = Window:NewTab("Core") local CoreSection = CoreTab:NewSection("Core Functions")

-- Button: Reload all modules
CoreSection:NewButton("Reload Modules", "Fetches and reloads all SkullHub modules", function()
    -- List of module scripts 
    local modules = { {name = "AutoCardPicker", path = "AutoCardPicker.lua"}, {name = "DiscordJoiner", path = "discordjoiner.lua"}, {name = "LoadingScreen", path = "Loading.lua"}, {name = "Other", path = "OtherModule.lua"}, } for _, mod in ipairs(modules) do spawn(function() local url = string.format("https://raw.githubusercontent.com/hungquan99/SkullHub/main/%s", mod.path) local ok, code = pcall(function() return game:HttpGet(url, true) end) if ok and code and #code > 0 then pcall(loadstring(code)) print("[SkullHub] Loaded module: " .. mod.name) else warn("[SkullHub] Failed to load module: " .. mod.name) end end) end end)

-- AutoCardPicker Tab
    local CardTab = Window:NewTab("AutoCardPicker") local CardSection = CardTab:NewSection("Card Picker Settings") CardSection:NewToggle("Enable AutoCardPicker", "Automatically pick optimal cards", function(state) getgenv().AutoCardPickerEnabled = state end) CardSection:NewSlider("Pick Interval (sec)", "Interval between picks", 10, 1, function(val) getgenv().AutoCardPickerInterval = val end)

-- DiscordJoiner Tab
    local DiscordTab = Window:NewTab("Discord") local DiscordSection = DiscordTab:NewSection("Discord Utilities") DiscordSection:NewButton("Open Discord Invite", "Opens SkullHub Discord invite link", function() setclipboard("https://discord.gg/skullhub") game.StarterGui:SetCore("SendNotification", {Title = "SkullHub", Text = "Discord link copied to clipboard!"}) end)

-- LoadingScreen Tab 
    local LoadTab = Window:NewTab("Loading") local LoadSection = LoadTab:NewSection("Loading Effects") LoadSection:NewButton("Play Loading Animation", "Triggers custom loading animation", function()
    -- Example: fade in/out GUI 
    local screenGui = Instance.new("ScreenGui", game.CoreGui) local frame = Instance.new("Frame", screenGui) frame.Size = UDim2.new(1,0,1,0) frame.BackgroundColor3 = Color3.new(0,0,0) frame.BackgroundTransparency = 1 for i = 1, 10 do frame.BackgroundTransparency = frame.BackgroundTransparency - 0.1 wait(0.05) end wait(1) for i = 1, 10 do frame.BackgroundTransparency = frame.BackgroundTransparency + 0.1 wait(0.05) end screenGui:Destroy() end)

-- Settings Tab
        local SettingsTab = Window:NewTab("Settings") local SettingsSection = SettingsTab:NewSection("UI Settings") SettingsSection:NewKeyBind("Toggle UI", "Shows or hides the UI", Enum.KeyCode.RightControl, function() Library:ToggleUI() end) SettingsSection:NewSlider("UI Transparency", "Adjust UI window transparency", 100, 0, function(val) Library:SetLibraryTransparency(val / 100) end)

-- Version display in Info Tab
        local InfoTab = Window:NewTab("Info") local InfoSection = InfoTab:NewSection("About SkullHub") InfoSection:NewLabel("Version: 1.0") InfoSection:NewLabel("Author: hungquan99")

-- Initialization: 
        Print ready print("[SkullHub] Main UI loaded. Use the tabs to access features.")

