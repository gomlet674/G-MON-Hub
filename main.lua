-- main.lua (GUI + menu structure)
repeat task.wait() until game:IsLoaded()

local Http    = game:GetService("HttpService")
local Players = game:GetService("Players")

-- load UI lib (misal Rayfield, Kavo, etc.)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/yourrepo/gmonhub/assets/library.lua",true))()
local Window  = Library:CreateWindow({Title="G-Mon Hub | Blox Fruits", Rounded=true, Drag=true})

-- Tabs sesuai IsnaHamzah + Redz
local T = {
    Main        = Window:CreateTab("Main"),
    Kitsune     = Window:CreateTab("Kitsune"),
    Prehistoric = Window:CreateTab("Prehistoric"),
    SeaEvent    = Window:CreateTab("Sea Event"),
    DragonDojo  = Window:CreateTab("Dragon Dojo"),
    RaceV4      = Window:CreateTab("Race V4"),
    Stats       = Window:CreateTab("Stats Player"),
    Misc        = Window:CreateTab("Misc"),
    Settings    = Window:CreateTab("Settings"),
}

-- MAIN
T.Main:Toggle({Text="Auto Farm", Flag="AutoFarm"})
T.Main:Toggle({Text="Auto Chest", Flag="AutoChest"})
T.Main:Dropdown({Text="Select Weapon", List={"Melee","Sword","Fruit"}, Callback=function(v) _G.WeaponMode=v end})
T.Main:Button({Text="Stop All Tween", Callback=function() game.TweenService:CancelAll() end})

-- KITSUNE
T.Kitsune:Toggle({Text="Auto Kitsune", Flag="AutoKitsune"})
-- (…logic di source.lua…)

-- PREHISTORIC
T.Prehistoric:Toggle({Text="Auto Prehistoric", Flag="AutoPrehistoric"})
T.Prehistoric:Toggle({Text="Auto Boss Prehistoric", Flag="AutoBossPrehistoric"})
T.Prehistoric:Toggle({Text="Auto Collect Items", Flag="AutoCollectPrehistoric"})

-- SEA EVENT
T.SeaEvent:Label({Text="Temporary Sea Event Only In Third Sea"})
T.SeaEvent:Label({Text="Sea Event Sementara Hanya Di Third Sea"})
T.SeaEvent:Slider({Text="Speed Boat",min=10,max=200,Default=100,Callback=function(v) _G.BoatSpeed=v end})
T.SeaEvent:Button({Text="Boost Speed Boat",Callback=function()
    local boat = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Boat")
    if boat then boat.MaxSpeed = _G.BoatSpeed end
end})

-- DRAGON DOJO
T.DragonDojo:Toggle({Text="Auto Dragon Dojo", Flag="AutoDragonDojo"})

-- RACE V4
T.RaceV4:Toggle({Text="Auto Draco Race v4", Flag="AutoRaceV4"})

-- STATS PLAYER
T.Stats:Button({Text="Refresh Stats", Callback=function()
    local d = Players.LocalPlayer:FindFirstChild("Data")
    if d then
        T.Stats:Bullet({Text="Level: "..d.Level.Value})
        T.Stats:Bullet({Text="Health: "..d.Health.Value})
    end
end})

-- MISC
T.Misc:Button({Text="Redeem All Codes", Callback=function()
    for _,c in ipairs({"Sub2OfficialNoob","ILoveBloxFruit"}) do
        game:GetService("ReplicatedStorage").RF:InvokeServer("RedeemCode",c)
        task.wait(0.5)
    end
end})
T.Misc:Button({Text="Server Hop", Callback=function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/yourrepo/gmonhub/source/serverhop.lua",true))()
end})

-- SETTINGS
T.Settings:Slider({Text="Farm Interval",min=0.1,max=1,Default=0.5,Callback=function(v) _G.FarmInterval=v end})
T.Settings:Toggle({Text="Fast Attack", Flag="FastAttack"})
T.Settings:Dropdown({Text="Toggle UI Key",List={"M","K","L"},Callback=function(k) Library.ToggleKey=Enum.KeyCode[k] end})
T.Settings:Slider({Text="UI Transparency",min=0,max=1,Default=0.3,Callback=function(v) Library.MainFrame.BackgroundTransparency=v end})

-- finally init
Library:Init()
print("G-Mon Hub GUI loaded!")