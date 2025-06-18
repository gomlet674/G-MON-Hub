-- ✅ SERVICE SETUP
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer

-- ✅ GLOBAL FLAG
getgenv()._G = _G or {}
_G.Flags = {
    auto_hatch_antibee = false
}

-- ✅ UI SIMPLE (Tab ESP saja)
local function CreateUI()
    local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
    ScreenGui.Name = "GrowAGardenUI"

    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Size = UDim2.new(0, 200, 0, 120)
    Frame.Position = UDim2.new(0, 20, 0, 100)
    Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Frame.BorderSizePixel = 0

    local Toggle = Instance.new("TextButton", Frame)
    Toggle.Size = UDim2.new(1, -20, 0, 50)
    Toggle.Position = UDim2.new(0, 10, 0, 10)
    Toggle.BackgroundColor3 = Color3.fromRGB(80, 160, 80)
    Toggle.Text = "Auto Hatch (Anti Bee Egg): OFF"
    Toggle.TextColor3 = Color3.new(1,1,1)

    Toggle.MouseButton1Click:Connect(function()
        _G.Flags.auto_hatch_antibee = not _G.Flags.auto_hatch_antibee
        Toggle.Text = "Auto Hatch (Anti Bee Egg): " .. (_G.Flags.auto_hatch_antibee and "ON" or "OFF")
    end)
end

CreateUI()

-- ✅ PET ESP (highlight pet bagus)
local goodPets = {
    ["Raccoon"] = true,
    ["Red Fox"] = true,
    ["Dragon Fly"] = true,
    ["Disco Bee"] = true,
}

local function highlightPet(petModel)
    if not petModel:FindFirstChild("Highlight") then
        local hl = Instance.new("Highlight", petModel)
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 0)
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end
end

task.spawn(function()
    while true do
        for _, model in pairs(Workspace:GetDescendants()) do
            if model:IsA("Model") and goodPets[model.Name] then
                highlightPet(model)
            end
        end
        task.wait(2)
    end
end)

-- ✅ AUTO HATCH + SERVER HOP
task.spawn(function()
    while true do
        if _G.Flags.auto_hatch_antibee then
            local selectedPet = nil

            -- Coba ambil pet dari player
            if player:FindFirstChild("CurrentPet") then
                selectedPet = player.CurrentPet
            elseif player.Character and player.Character:FindFirstChild("Pet") then
                selectedPet = player.Character.Pet
            end

            if selectedPet and selectedPet.Name then
                local petName = selectedPet.Name
                if goodPets[petName] then
                    -- Pet bagus → Hatch
                    pcall(function()
                        Replicated.Remotes.HatchEgg:InvokeServer("BasicEgg")
                    end)
                else
                    -- Pet jelek → Server hop
                    TeleportService:Teleport(game.PlaceId, player)
                end
            end
        end
        task.wait(1)
    end
end)
