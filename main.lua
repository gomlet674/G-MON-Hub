-- LocalScript di StarterGui
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "GantengHub"
gui.ResetOnSpawn = false

-- Utility: buat instance dengan properti
local function New(class, props, parent)
    local inst = Instance.new(class)
    for k,v in pairs(props or {}) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

-- Main Window
local main = New("Frame", {
    Name = "MainWindow",
    Size = UDim2.new(0,600,0,350),
    Position = UDim2.new(0.5,-300,0.5,-175),
    BackgroundColor3 = Color3.fromRGB(25,25,25),
    BorderSizePixel = 0,
}, gui)

-- Close & Minimize
local header = New("Frame", {
    Size = UDim2.new(1,0,0,32),
    BackgroundColor3 = Color3.fromRGB(20,20,20),
    BorderSizePixel = 0,
}, main)
New("UICorner",{CornerRadius=UDim.new(0,6)}, header)

local btnClose = New("TextButton", {
    Text = "✕", Font = Enum.Font.GothamBold, TextSize = 18,
    Size = UDim2.new(0,32,0,32), Position = UDim2.new(1,-32,0,0),
    BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1),
}, header)
local btnMin  = New("TextButton", {
    Text = "─", Font = Enum.Font.GothamBold, TextSize = 18,
    Size = UDim2.new(0,32,0,32), Position = UDim2.new(1,-64,0,0),
    BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1),
}, header)

btnClose.MouseButton1Click:Connect(function() main:Destroy() end)
btnMin.MouseButton1Click:Connect(function()
    main.Visible = false
end)

-- Sidebar
local sidebar = New("Frame", {
    Size = UDim2.new(0,120,1,0),
    Position = UDim2.new(0,0,0,0),
    BackgroundColor3 = Color3.fromRGB(30,30,30),
    BorderSizePixel = 0,
}, main)
New("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder}, sidebar)

local pages = {
    {Name="Kitsune", Icon="🦊"},
    {Name="Prehistoric", Icon="🦕"},
    {Name="Sea Event", Icon="🐬"},
    {Name="Dragon Dojo", Icon="🐉"},
    {Name="RaceV4", Icon="🏁"},
    {Name="Stats Player", Icon="📊"},
    {Name="Stop All Tween", Icon="⏹️"},
}

-- Content container
local content = New("Frame", {
    Size = UDim2.new(1,-120,1,-32),
    Position = UDim2.new(0,120,0,32),
    BackgroundColor3 = Color3.fromRGB(35,35,35),
    BorderSizePixel = 0,
}, main)
New("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder}, content)

-- Header Right (Back + Icon + Title)
local hdrR = New("Frame", {
    Size = UDim2.new(1,0,0,32),
    BackgroundTransparency = 1,
}, content)
New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,8)}, hdrR)

local btnBack = New("TextButton", {
    Text = "< Back", Font = Enum.Font.Gotham, TextSize = 16,
    Size = UDim2.new(0,70,0,32), BackgroundTransparency=1, TextColor3=Color3.new(1,1,1),
}, hdrR)
local pageIcon = New("TextLabel", {
    Text = "", Font = Enum.Font.GothamBold, TextSize = 20,
    Size = UDim2.new(0,32,0,32), BackgroundTransparency=1, TextColor3=Color3.new(1,1,1),
}, hdrR)
local pageTitle = New("TextLabel", {
    Text = "", Font = Enum.Font.GothamBold, TextSize = 18,
    Size = UDim2.new(0,150,0,32), BackgroundTransparency=1, TextColor3=Color3.new(1,1,1),
}, hdrR)

-- Spacer
local spacer = Instance.new("Frame", hdrR)
spacer.Size = UDim2.new(1,0,1,0); spacer.BackgroundTransparency=1

-- Pages store
local pageFrames = {}

-- Function untuk switch page
local function showPage(name)
    for k,v in pairs(pageFrames) do
        v.Visible = (k == name)
    end
    -- update header
    for _,p in ipairs(pages) do
        if p.Name == name then
            pageIcon.Text = p.Icon
            pageTitle.Text = p.Name
        end
    end
end

-- Buat setiap page frame
for _,p in ipairs(pages) do
    local pf = New("Frame", {
        Size = UDim2.new(1,0,1,-32),
        BackgroundTransparency = 1,
        Visible = false,
    }, content)
    New("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder}, pf)
    pageFrames[p.Name] = pf

    -- contohnya: jika Sea Event maka isi tombol khusus
    if p.Name == "Sea Event" then
        local btn1 = New("TextButton", {
            Text = "Temporary Sea Event Only In Third Sea",
            Font = Enum.Font.Gotham, TextSize = 14,
            Size = UDim2.new(1,-16,0,30), BackgroundColor3=Color3.fromRGB(45,45,45),
            TextColor3=Color3.new(1,1,1), BorderSizePixel=0,
        }, pf)
        btn1.MouseButton1Click:Connect(function()
            -- contoh aksi
            print("Aktifkan Temporary Sea Event Only In Third Sea")
        end)

        local btn2 = btn1:Clone()
        btn2.Parent = pf
        btn2.Text = "Sea Event Sementara Hanya Di Third Sea"
        btn2.MouseButton1Click:Connect(function()
            print("Aktifkan Sea Event Sementara Hanya Di Third Sea")
        end)

        -- Slider label
        local lbl = New("TextLabel", {
            Text = "Setting Speed Boat",
            Font = Enum.Font.GothamBold, TextSize = 14,
            Size = UDim2.new(1,-16,0,20), BackgroundTransparency=1, TextColor3=Color3.new(1,1,1),
        }, pf)

        -- Boost button
        local boost = New("TextButton", {
            Text = "Boost Speed Boat For Ur Boat",
            Font = Enum.Font.Gotham, TextSize = 14,
            Size = UDim2.new(1,-16,0,30), BackgroundColor3=Color3.fromRGB(60,60,60),
            TextColor3=Color3.new(1,1,1), BorderSizePixel=0,
        }, pf)
        boost.MouseButton1Click:Connect(function()
            print("Boosting your boat speed…")
        end)
    else
        -- halaman lain: placeholder
        local placeholder = New("TextLabel", {
            Text = p.Name.." page coming soon…",
            Font = Enum.Font.GothamItalic, TextSize = 16,
            Size = UDim2.new(1,-16,0,30), BackgroundTransparency=1, TextColor3=Color3.fromRGB(150,150,150),
        }, pf)
    end
end

-- Buat button sidebar dan koneksi
for _,p in ipairs(pages) do
    local btn = New("TextButton", {
        Text = p.Icon.."  "..p.Name,
        Font = Enum.Font.Gotham, TextSize = 14,
        Size = UDim2.new(1,-8,0,30), BackgroundColor3=Color3.fromRGB(40,40,40),
        TextColor3=Color3.new(1,1,1), BorderSizePixel=0,
    }, sidebar)
    btn.LayoutOrder = _  -- agar berurutan
    btn.MouseButton1Click:Connect(function()
        showPage(p.Name)
    end)
end

-- Back button: kembali ke “Sea Event” misalnya
btnBack.MouseButton1Click:Connect(function()
    showPage("Sea Event")
    main.Visible = true  -- jika di-minimize
end)

-- Inisialisasi: tampilkan Sea Event
showPage("Sea Event")
