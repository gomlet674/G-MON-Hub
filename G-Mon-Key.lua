-- G-Mon-Key.lua
repeat task.wait() until game:IsLoaded()

local UserInputService = game:GetService("UserInputService")
local StarterGui       = game:GetService("StarterGui")
local RunService       = game:GetService("RunService")

-- load fallback
local loader = loadstring or load

local VALID_KEY = "GmonHub311851f3c742a8f78dce99e56992555609d23497928e9b33802e7127610c2e"
local rgbSpeed  = 0.5

-- Parent ke CoreGui (atau PlayerGui di Studio)
local parentGui = (RunService:IsStudio() and
    game.Players.LocalPlayer:WaitForChild("PlayerGui")) or
    game:GetService("CoreGui")

-- SCREEN GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name         = "GMon_KeyUI"
screenGui.ResetOnSpawn = false
screenGui.Parent       = parentGui

-- FRAME
local frame = Instance.new("Frame", screenGui)
frame.AnchorPoint            = Vector2.new(0.5,0.5)
frame.Position               = UDim2.new(0.5,0,0.5,-20)
frame.Size                   = UDim2.new(0,400,0,160)
frame.BackgroundColor3       = Color3.fromRGB(20,20,20)
frame.BackgroundTransparency = 0.1
frame.ClipsDescendants       = true
frame.Active                 = true
frame.Selectable             = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

-- RGB BORDER
local border = Instance.new("UIStroke", frame)
border.Thickness       = 2
border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
task.spawn(function()
    while frame.Parent do
        for h=0,1,0.01 do
            border.Color = Color3.fromHSV(h,1,1)
            task.wait(rgbSpeed)
        end
    end
end)

-- TITLE
local title = Instance.new("TextLabel", frame)
title.Size                  = UDim2.new(1,-20,0,30)
title.Position              = UDim2.new(0,10,0,10)
title.BackgroundTransparency= 1
title.Font                  = Enum.Font.GothamBold
title.TextSize              = 18
title.TextColor3            = Color3.new(1,1,1)
title.TextXAlignment        = Enum.TextXAlignment.Left
title.Text                  = "G-Mon Hub Key"

-- CLOSE
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size                 = UDim2.new(0,24,0,24)
closeBtn.Position             = UDim2.new(1,-30,0,8)
closeBtn.BackgroundTransparency=1
closeBtn.Font                 = Enum.Font.GothamBold
closeBtn.TextSize             = 18
closeBtn.TextColor3           = Color3.new(1,1,1)
closeBtn.Text                 = "X"
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- TEXTBOX (gunakan Text, bukan PlaceholderText)
local input = Instance.new("TextBox", frame)
input.Size             = UDim2.new(0.7,0,0,28)
input.Position         = UDim2.new(0.15,0,0.4,0)
input.Text             = "Enter Key"
input.ClearTextOnFocus = true
input.BackgroundColor3 = Color3.fromRGB(30,30,30)
input.TextColor3       = Color3.new(1,1,1)
input.Font             = Enum.Font.Gotham
input.TextSize         = 14
Instance.new("UICorner", input).CornerRadius = UDim.new(0,6)

-- BUTTONS
local function newBtn(parent, txt, col, posX)
    local b = Instance.new("TextButton", parent)
    b.Size             = UDim2.new(0.35,0,0,28)
    b.Position         = UDim2.new(posX,0,0.75,0)
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 14
    b.TextColor3       = Color3.new(1,1,1)
    b.Text             = txt
    b.BackgroundColor3 = col
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    return b
end

local checkBtn = newBtn(frame, "Check Key", Color3.fromRGB(50,100,50), 0.1)
local getKeyBtn = newBtn(frame, "Get Key", Color3.fromRGB(50,50,100), 0.55)

-- LOGIC
getKeyBtn.MouseButton1Click:Connect(function()
    pcall(function()
        setclipboard("https://linkvertise.com/1209226/get-key-gmon-hub-script")
    end)
    StarterGui:SetCore("SendNotification", {
        Title="G-Mon Hub", Text="Link key copied!", Duration=2
    })
end)

checkBtn.MouseButton1Click:Connect(function()
    local key = input.Text or ""
    if key == VALID_KEY then
        StarterGui:SetCore("SendNotification", {
            Title="Key Valid", Text="Loading…", Duration=2
        })
        task.wait(0.5)
        screenGui:Destroy()
        if loader then
            local ok,err = pcall(function()
                loader(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/main.lua",true))()
            end)
            if not ok then warn("Load main.lua gagal:",err) end
        end
    else
        StarterGui:SetCore("SendNotification", {
            Title="Invalid Key", Text="Please get a valid key.", Duration=2
        })
        input.Text = ""
    end
end)

-- DRAGGABLE
do
    local dragging,dragInput,dragStart,startPos
    frame.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dragStart=i.Position; startPos=frame.Position
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement then dragInput=i end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i==dragInput then
            local delta=i.Position-dragStart
            frame.Position=UDim2.new(
                startPos.X.Scale, startPos.X.Offset+delta.X,
                startPos.Y.Scale, startPos.Y.Offset+delta.Y
            )
        end
    end)
end