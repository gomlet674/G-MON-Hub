
local player = game:GetService("Players").LocalPlayer
local playergui = player:WaitForChild("PlayerGui")
local roguelikeselect = playergui:WaitForChild("RoguelikeSelect")
roguelikeselect.Enabled = true
roguelikeselect.Enabled = false
local wavenum = playergui:WaitForChild("Waves"):WaitForChild("HealthBar"):WaitForChild("WaveNumber")

if wavenum.Text == "0" or wavenum.Text == nil or not wavenum then
repeat task.wait() until wavenum.Text >= "1" and wavenum
end

local positiontable = {}
local newoptions = {}
local args = {}

local wavenumber
wavenum:GetPropertyChangedSignal("Text"):Connect(function()
    wavenumber = wavenum.Text
end)

game.StarterGui:SetCore("SendNotification", {
    Title = "Skull Hub",
    Text = "Auto card picker executed successfully!",
    Duration = 5,
    Icon = "rbxassetid://137212456917215"
})

print(cards[1])

playergui:FindFirstChild("RoguelikeSelect"):GetPropertyChangedSignal("Enabled"):Connect(function()
wait()
local optionframe = playergui.RoguelikeSelect.Main.Main.Items:WaitForChild("OptionFrame")
optionframe.Active = true
optionframe.Active = false
wait(1)
    local options = playergui:WaitForChild("RoguelikeSelect").Main.Main.Items:GetChildren()
    positiontable = {}
    for i,v in pairs(options) do
        if v.Name == "OptionFrame" and v:IsA("Frame") and v:FindFirstChild("bg") then
            table.insert(positiontable,v.AbsolutePosition.X)
        end
    end

table.sort(positiontable)

newoptions = {}

for i,v in pairs(options) do
    if v.Name == "OptionFrame" and v:IsA("Frame") and v:FindFirstChild("bg") and v.AbsolutePosition.X == positiontable[1] then
        table.insert(newoptions,v.bg.Main.Title.TextLabel)
    end
    if newoptions[1] ~= nil then
        if v.Name == "OptionFrame" and v:IsA("Frame") and v:FindFirstChild("bg") and v.AbsolutePosition.X == positiontable[2] then
        table.insert(newoptions,v.bg.Main.Title.TextLabel)
        end
    end
    if newoptions[2] ~= nil then
        if v.Name == "OptionFrame" and v:IsA("Frame") and v:FindFirstChild("bg") and v.AbsolutePosition.X == positiontable[3] then
        table.insert(newoptions,v.bg.Main.Title.TextLabel)
        end
    end
end

    for i=1,#cards,1 do
        if newoptions[1].Text == cards[i] then
        args = {[1]="1"}
        elseif newoptions[2].Text == cards[i] then   
        args = {[1]="3"}
     	elseif newoptions[3].Text == cards[i] then   
        args = {[1]="2"}
        end
    end
	wait(0.5)
    game:GetService("ReplicatedStorage").endpoints.client_to_server.select_roguelike_option:InvokeServer(unpack(args))
end)

playergui.RoguelikeSelect.Enabled = true
playergui.RoguelikeSelect.Enabled = false
