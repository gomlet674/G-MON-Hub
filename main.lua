repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until game.Players.LocalPlayer.Character

local plr = game.Players.LocalPlayer

-- Cek jika GUI sudah ada
if game:GetService("CoreGui"):FindFirstChild("GMON HUB") then
    game:GetService("CoreGui"):FindFirstChild("GMON HUB"):Destroy()
elseif plr:FindFirstChild("PlayerGui"):FindFirstChild("GMON HUB") then
    plr:FindFirstChild("PlayerGui"):FindFirstChild("GMON HUB"):Destroy()
end

-- Load library
local uilib = loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/source.lua"))()
local ui = uilib:Window("GMON HUB", "Blox Fruits", Color3.fromRGB(0, 255, 140), "rbxassetid://16517042371")

-- Tab & Section
local mainTab = ui:Tab("Main")
local infoTab = ui:Tab("Info")
local autofarmSection = mainTab:Section("Auto Farm")
local settingsSection = mainTab:Section("Settings")

-- Membuat tab dan section yang tidak terganggu
infoTab:Section("Discord", function()
    -- Isi dari tab Info
    -- Contoh: TextLabel atau lainnya
    local label = Instance.new("TextLabel")
    label.Text = "Discord: discord.gg/GMON"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Size = UDim2.new(0, 200, 0, 50)
    label.Parent = infoTab
end)

autofarmSection:Toggle("Auto Farm", false, function(v)
    getgenv().AutoFarm = v
end)

settingsSection:Toggle("Enable Feature X", false, function(v)
    getgenv().FeatureX = v
end)

-- Tombol (-) dan (X)
spawn(function()
    local UI = game:GetService("CoreGui"):FindFirstChild("GMON HUB") or plr:WaitForChild("PlayerGui"):FindFirstChild("GMON HUB")
    if UI then
        local frame = UI:FindFirstChildOfClass("Frame") or UI:FindFirstChildWhichIsA("Frame", true)
        if frame then
            -- Tombol Frame
            local btnFrame = Instance.new("Frame")
            btnFrame.Size = UDim2.new(0, 60, 0, 20)
            btnFrame.Position = UDim2.new(1, -70, 0, 5)
            btnFrame.BackgroundTransparency = 1
            btnFrame.Parent = frame

            -- Tombol Minimize
            local minBtn = Instance.new("TextButton")
            minBtn.Size = UDim2.new(0, 25, 1, 0)
            minBtn.Position = UDim2.new(0, 0, 0, 0)
            minBtn.Text = "-"
            minBtn.TextColor3 = Color3.new(1, 1, 1)
            minBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            minBtn.BorderSizePixel = 0
            minBtn.Parent = btnFrame

            -- Tombol Close
            local closeBtn = Instance.new("TextButton")
            closeBtn.Size = UDim2.new(0, 25, 1, 0)
            closeBtn.Position = UDim2.new(0, 30, 0, 0)
            closeBtn.Text = "X"
            closeBtn.TextColor3 = Color3.new(1, 1, 1)
            closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            closeBtn.BorderSizePixel = 0
            closeBtn.Parent = btnFrame

            -- Fungsi toggle UI
            local visible = true
            minBtn.MouseButton1Click:Connect(function()
                visible = not visible
                -- Hanya sembunyikan bagian konten, tab tetap terlihat
                for _, v in pairs(frame:GetChildren()) do
                    if v.Name ~= "Tabs" and v ~= btnFrame then
                        v.Visible = visible
                    end
                end
            end)

            -- Konfirmasi Hapus UI
            closeBtn.MouseButton1Click:Connect(function()
                if UI:FindFirstChild("ConfirmDelete") then return end

                local confirmFrame = Instance.new("Frame", UI)
                confirmFrame.Name = "ConfirmDelete"
                confirmFrame.Size = UDim2.new(1, 0, 1, 0)
                confirmFrame.BackgroundColor3 = Color3.new(0, 0, 0)
                confirmFrame.BackgroundTransparency = 0.4
                confirmFrame.ZIndex = 100

                local box = Instance.new("Frame", confirmFrame)
                box.Size = UDim2.new(0, 250, 0, 120)
                box.Position = UDim2.new(0.5, -125, 0.5, -60)
                box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                box.BorderSizePixel = 0
                box.ZIndex = 101

                local label = Instance.new("TextLabel", box)
                label.Size = UDim2.new(1, 0, 0, 40)
                label.Position = UDim2.new(0, 0, 0, 0)
                label.Text = "Are you sure to delete?"
                label.TextColor3 = Color3.new(1, 1, 1)
                label.BackgroundTransparency = 1
                label.ZIndex = 102
                label.Font = Enum.Font.SourceSansBold
                label.TextSize = 18

                local yesBtn = Instance.new("TextButton", box)
                yesBtn.Size = UDim2.new(0.4, 0, 0, 30)
                yesBtn.Position = UDim2.new(0.05, 0, 1, -40)
                yesBtn.Text = "Yes"
                yesBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                yesBtn.TextColor3 = Color3.new(1, 1, 1)
                yesBtn.ZIndex = 102
                yesBtn.Font = Enum.Font.SourceSansBold
                yesBtn.TextSize = 16

                local noBtn = Instance.new("TextButton", box)
                noBtn.Size = UDim2.new(0.4, 0, 0, 30)
                noBtn.Position = UDim2.new(0.55, 0, 1, -40)
                noBtn.Text = "No"
                noBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
                noBtn.TextColor3 = Color3.new(1, 1, 1)
                noBtn.ZIndex = 102
                noBtn.Font = Enum.Font.SourceSansBold
                noBtn.TextSize = 16

                noBtn.MouseButton1Click:Connect(function()
                    confirmFrame:Destroy()
                end)

                yesBtn.MouseButton1Click:Connect(function()
                    UI:Destroy()
                end)
            end)
        end
    end
end)
