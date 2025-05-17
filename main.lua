-- main.lua - GMON Hub UI Final
repeat task.wait() until game:IsLoaded()

-- Source utama
local success, sourceScript = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/source.lua")
end)

if success then
    loadstring(sourceScript)()
else
    warn("GMON Hub: Gagal memuat source.lua!")
end

-- Services
local Players   = game:GetService("Players")
local UserInput = game:GetService("UserInputService")

-- Config Global
_G.Flags  = _G.Flags  or {}
_G.Config = _G.Config or { FarmInterval = 0.5 }

-- 1) Daftar boss per Sea
local firstSeaBosses = {
    "Gorilla King","Bobby","Saw","Yeti","Mob Leader",
    "Vice Admiral","Warden","Saber Expert","Chief Warden",
    "Swan","Magma Admiral","Fishman Lord","Wysper",
    "Thunder God","Cyborg","Ice Admiral"
}
local secondSeaBosses = {
    "Diamond","Jeremy","Fajita","Don Swan",
    "Smoke Admiral","Awakened Ice Admiral","Tide Keeper"
}
local thirdSeaBosses = {
    "Stone","Island Empress","Kilo Admiral",
    "Captain Elephant","Beautiful Pirate","Longma","Cake Queen"
}

-- UI Helpers
local function New(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

-- Tambahkan fungsi AddSwitch setelah helper New:
local function AddSwitch(page, text, flag)
    -- Container
    local container = New("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = page
    })
    -- Label
    New("TextLabel", {
        Text = text,
        Size = UDim2.new(0.7, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1,1,1),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    -- Switch frame (background)
    local sw = New("Frame", {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -50, 0, 5),
        BackgroundColor3 = Color3.new(1,1,1), -- off is white
        Parent = container
    })
    New("UICorner", { CornerRadius = UDim.new(0,10) }, sw)
    -- Knob
    local knob = New("Frame", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Color3.new(0.2,0.2,0.2),
        Parent = sw
    })
    New("UICorner", { CornerRadius = UDim.new(0,9) }, knob)

    -- Initial state
    _G.Flags[flag] = _G.Flags[flag] or false
    local function update()
        if _G.Flags[flag] then
            sw.BackgroundColor3 = Color3.fromRGB(0,170,0)  -- green
            knob.Position = UDim2.new(1, -19, 0, 1)
        else
            sw.BackgroundColor3 = Color3.new(1,1,1)        -- white
            knob.Position = UDim2.new(0, 1, 0, 1)
        end
    end
    update()

    -- Toggle on click
    sw.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            _G.Flags[flag] = not _G.Flags[flag]
            update()
        end
    end)
end

-- Ganti semua AddToggle(...) dengan AddSwitch(...), misalnya:
-- Dari:
-- AddToggle(pages[2],"Auto Farm","AutoFarm")
-- Ke:
AddSwitch(pages[2], "Auto Farm", "AutoFarm")
-- Dan seterusnya untuk setiap toggle yang kamu inginkan.

-- Terakhir: panggil source.lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/source.lua"))()

local function AddDropdown(page, title, list, callback)
    New("TextLabel", {
        Text = title,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1,1,1),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = page
    })
    local dropdown = New("TextButton", {
        Text = list[1] or "Select",
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(50,50,50),
        TextColor3 = Color3.new(1,1,1),
        Parent = page
    })
    New("UICorner", {}, dropdown)

    dropdown.MouseButton1Click:Connect(function()
        local menu = New("Frame", {
            Size     = UDim2.new(0, dropdown.AbsoluteSize.X, 0, #list * 25),
            Position = UDim2.new(0, dropdown.AbsolutePosition.X, 0, dropdown.AbsolutePosition.Y + dropdown.AbsoluteSize.Y),
            BackgroundColor3 = Color3.fromRGB(35,35,35),
            Parent = dropdown
        })
        New("UICorner", {}, menu)
        for i, item in ipairs(list) do
            local btn = New("TextButton", {
                Text = item,
                Size = UDim2.new(1,0,0,25),
                BackgroundTransparency = 1,
                TextColor3 = Color3.new(1,1,1),
                Parent = menu
            })
            btn.Position = UDim2.new(0,0,0,(i-1)*25)
            btn.MouseButton1Click:Connect(function()
                dropdown.Text = item
                menu:Destroy()
                callback(item)
            end)
        end
    end)
end

local function AddToggle(page, text, flag)
    local t = New("TextButton", {
        Text = text,
        Size = UDim2.new(1,0,0,30),
        BackgroundColor3 = Color3.fromRGB(60,60,60),
        TextColor3 = Color3.new(1,1,1),
        Parent = page
    })
    New("UICorner", {}, t)
    t.MouseButton1Click:Connect(function()
        _G.Flags[flag] = not _G.Flags[flag]
        t.BackgroundColor3 = _G.Flags[flag] and Color3.fromRGB(0,170,0) or Color3.fromRGB(60,60,60)
    end)
end

local function AddText(page, text)
    New("TextLabel", {
        Text = text,
        Size = UDim2.new(1,0,0,20),
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1,1,1),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = page
    })
end

local function AddInput(page, placeholder, callback)
    local box = New("TextBox", {
        PlaceholderText = placeholder,
        Size = UDim2.new(1,0,0,30),
        BackgroundColor3 = Color3.fromRGB(50,50,50),
        TextColor3 = Color3.new(1,1,1),
        Parent = page
    })
    New("UICorner", {}, box)
    box.FocusLost:Connect(function(enter)
        if enter and box.Text ~= "" then
            callback(box.Text)
        end
    end)
end

-- Main GUI
local gui = New("ScreenGui", { Name = "GMONHub_UI", ResetOnSpawn = false },
    Players.LocalPlayer:WaitForChild("PlayerGui"))

-- Background Anime
New("ImageLabel", {
    Image = "rbxassetid://16790218639",
    Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    ZIndex = 0
}, gui)

-- Main Frame + RGB Stroke
local frame = New("Frame", {
    Size  = UDim2.new(0,580,0,420),
    Position = UDim2.new(0.5,-290,0.5,-160),
    BackgroundColor3 = Color3.fromRGB(25,25,25),
    BackgroundTransparency = 0.2,
    Draggable = true, Active = true, Visible = true,
    Name = "MainFrame"
}, gui)
New("UICorner", { CornerRadius = UDim.new(0,12) }, frame)
local stroke = New("UIStroke", { Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, frame)
task.spawn(function()
    local hue = 0
    while true do
        hue = (hue + 0.01) % 1
        stroke.Color = Color3.fromHSV(hue,1,1)
        task.wait(0.03)
    end
end)

-- Toggle UI Button
local toggleBtn = New("TextButton", {
    Text = "GMON", Size = UDim2.new(0,60,0,30),
    Position = UDim2.new(0,20,0.5,-15),
    BackgroundColor3 = Color3.fromRGB(40,40,40),
    TextColor3 = Color3.new(1,1,1),
    Active = true, Draggable = true, Parent = gui
})
New("UICorner", {}, toggleBtn)
toggleBtn.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

-- Tabs & Pages
local tabNames = {
    "Info","Main","Item","Sea","Prehistoric",
    "Kitsune","Leviathan","DevilFruit","ESP","Misc","Setting"
}
local tabs, pages = {}, {}

local tabScroll = New("ScrollingFrame", {
    Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,0,0),
    BackgroundTransparency=1,
    ScrollBarThickness=4,
    ScrollingDirection=Enum.ScrollingDirection.X,
    CanvasSize=UDim2.new(0,#tabNames*105,0,30),
    Parent=frame
})
New("UIListLayout", {
    Parent=tabScroll,
    FillDirection=Enum.FillDirection.Horizontal,
    SortOrder=Enum.SortOrder.LayoutOrder,
    Padding=UDim.new(0,5)
})

for i,name in ipairs(tabNames) do
    local btn = New("TextButton", {
        Text=name, Size=UDim2.new(0,100,0,30),
        BackgroundTransparency=0.5,
        BackgroundColor3=Color3.fromRGB(40,40,40),
        TextColor3=Color3.new(1,1,1), Parent=tabScroll
    })
    New("UICorner", {}, btn)
    local page = New("ScrollingFrame", {
        Size=UDim2.new(1,-20,1,-50),
        Position=UDim2.new(0,10,0,40),
        BackgroundTransparency=1, Visible=false,
        ScrollBarThickness=4, Parent=frame
    })
    New("UIListLayout", {
        Parent=page,
        SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,5)
    })
    table.insert(tabs,btn)
    table.insert(pages,page)
    btn.MouseButton1Click:Connect(function()
        for _,p in ipairs(pages) do p.Visible=false end
        page.Visible=true
    end)
    if i==1 then page.Visible=true end
end

-- Populate Tabs
-- Info (pages[1])
AddText(pages[1], "Toggle GUI: Press M or click GMON")

-- Tambahkan label untuk masing‐masing status:
local moonLabel = New("TextLabel", {
    Text = "Moon Phase: Loading...",
    Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1,
    TextColor3 = Color3.new(1,1,1),
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = pages[1]
})

local kitsuneLabel = New("TextLabel", {
    Text = "Kitsune Island: Loading...",
    Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1,
    TextColor3 = Color3.new(1,1,1),
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = pages[1]
})

local prehistLabel = New("TextLabel", {
    Text = "Prehistoric: Loading...",
    Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1,
    TextColor3 = Color3.new(1,1,1),
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = pages[1]
})

local frozenLabel = New("TextLabel", {
    Text = "Frozen Dimension: Loading...",
    Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1,
    TextColor3 = Color3.new(1,1,1),
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = pages[1]
})

local mirageLabel = New("TextLabel", {
    Text = "Mirage Island: Loading...",
    Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1,
    TextColor3 = Color3.new(1,1,1),
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = pages[1]
})

-- Update loop setiap 10 detik
task.spawn(function()
    while task.wait(10) do
        -- 1) Moon phase
        local minute = os.date("*t").min % 8
        local phases = {
          [0] = "🌑 0/4", [1] = "🌒 -1/4", [2] = "🌓 -2/4", [3] = "🌔 -3/4",
          [4] = "🌕 4/4", [5] = "🌖 3/4", [6] = "🌗 2/4", [7] = "🌘 1/4"
        }
        moonLabel.Text = "Moon Phase: " .. (phases[minute] or "Unknown")

        -- 2) Kitsune Island (cek spawn di third sea folder)
        local kitsuneSpawned = workspace:FindFirstChild("KitsuneIsland") ~= nil
        kitsuneLabel.Text = "Kitsune Island: " .. (kitsuneSpawned and "✅ Spawned" or "❌ Not Spawned")

        -- 3) Prehistoric Island (cek nama folder/objek di third sea)
        local preSpawned = workspace:FindFirstChild("PrehistoricIsland") ~= nil
        prehistLabel.Text = "Prehistoric: " .. (preSpawned and "✅ Spawned" or "❌ Not Found")

        -- 4) Frozen Dimension (cek objek)
        local frozenSpawned = workspace:FindFirstChild("FrozenDimension") ~= nil
        frozenLabel.Text = "Frozen Dimension: " .. (frozenSpawned and "✅ Spawned" or "❌ Not Found")

        -- 5) Mirage Island (cek despawn 15 menit)
        local mirage = workspace:FindFirstChild("MirageIsland")
        if mirage then
            -- misal: simpan waktu spawn di attribute "SpawnTime" (os.time())
            local spawnTime = mirage:GetAttribute("SpawnTime") or 0
            local elapsed = os.time() - spawnTime
            mirageLabel.Text = elapsed < 900
              and "Mirage Island: ✅ Spawned"
              or "Mirage Island: ❌ Despawned"
        else
            mirageLabel.Text = "Mirage Island: ❌ Not Found"
        end
    end
end)

-- Ganti ini:
-- AddToggle(pages[2],"Auto Farm","AutoFarm")
-- AddToggle(pages[2],"Farm All Boss","FarmAllBoss")
-- …
-- Menjadi:
AddSwitch(pages[2], "Auto Farm", "AutoFarm")
AddSwitch(pages[2], "Farm Boss Selected", "FarmBossSelected")
AddSwitch(pages[2], "Farm All Boss", "FarmAllBoss")
AddSwitch(pages[2], "Mastery Fruit", "MasteryFruit")
AddSwitch(pages[2], "Aimbot", "Aimbot")

-- Item
AddToggle(pages[3],"Auto CDK","AutoCDK")
AddToggle(pages[3],"Auto Yama","AutoYama")
AddToggle(pages[3],"Auto Tushita","AutoTushita")
AddToggle(pages[3],"Auto Soul Guitar","AutoSoulGuitar")

-- Sea
AddToggle(pages[4],"Kill Sea Beast","KillSeaBeast")
AddToggle(pages[4],"Auto Sail","AutoSail")
-- Prehistoric
AddToggle(pages[5],"Kill Golem","KillGolem")
AddToggle(pages[5],"Defend Volcano","DefendVolcano")
AddToggle(pages[5],"Collect Dragon Egg","CollectDragonEgg")
AddToggle(pages[5],"Collect Bones","CollectBones")

-- Kitsune
AddToggle(pages[6],"Collect Azure Ember","CollectAzure")
AddToggle(pages[6],"Trade Azure Ember","TradeAzure")

-- Leviathan
AddToggle(pages[7],"Attack Leviathan","AttackLeviathan")

-- DevilFruit
AddToggle(pages[8],"Gacha Fruit","GachaFruit")
AddInput(pages[8],"Fruit Target", function(txt) _G.Flags.FruitTarget=txt end)

-- ESP
AddToggle(pages[9],"ESP Fruit","ESPFruit")
AddToggle(pages[9],"ESP Player","ESPPlayer")
AddToggle(pages[9],"ESP Chest","ESPChest")
AddToggle(pages[9],"ESP Flower","ESPFlower")

-- Misc
AddToggle(pages[10],"Server Hop","ServerHop")
AddToggle(pages[10],"Redeem All Codes","RedeemCodes")
AddToggle(pages[10],"FPS Booster","FPSBooster")
AddToggle(pages[10],"Auto Awaken Fruit","AutoAwaken")

-- Setting
AddToggle(pages[11],"Fast Attack","FastAttack")
AddText(pages[11],"Toggle GUI: Press M or click GMON")

-- M Key toggle
UserInput.InputBegan:Connect(function(input,gameProcessed)
    if not gameProcessed and input.KeyCode==Enum.KeyCode.M then
        frame.Visible=not frame.Visible
    end
end)

-- Load source logic
loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/source.lua"))()

print("GMON Hub UI Loaded")