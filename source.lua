-- GMON HUB - source.lua

local Players = game:GetService("Players") local LocalPlayer = Players.LocalPlayer local RunService = game:GetService("RunService") local Camera = workspace.CurrentCamera

-- Auto Farm Logic spawn(function() while task.wait() do if _G.AutoFarm then -- Auto Farm logic placeholder end end end)

-- Auto Next Sea spawn(function() while task.wait() do if _G.AutoNextSea then -- Auto travel to next sea logic end end end)

-- Auto Equip Accessory spawn(function() while task.wait(1) do if _G.AutoEquipAccessory then -- Auto equip best accessory logic end end end)

-- Aimbot Logic RunService.RenderStepped:Connect(function() if _G.AimbotEnabled then local closest = nil local shortest = math.huge for _, player in ipairs(Players:GetPlayers()) do if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then local pos, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position) if onScreen then local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude if dist < shortest then shortest = dist closest = player end end end end if closest and closest.Character and closest.Character:FindFirstChild("Head") then Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Character.Head.Position) end end end)

-- Auto Enchant / Craft spawn(function() while task.wait() do if _G.AutoEnchant then -- Enchanting logic placeholder end if _G.AutoCraft then -- Crafting logic placeholder end end end)

-- Fast Attack spawn(function() while task.wait() do if _G.FastAttack then -- Fast attack logic placeholder end end end)

-- Auto Click spawn(function() while task.wait() do if _G.AutoClick then local VirtualUser = game:GetService("VirtualUser") VirtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame) end end end)

-- Auto Buy / Store Fruit spawn(function() while task.wait() do if _G.AutoBuyFruit then -- Buy fruit logic placeholder end if _G.AutoStoreFruit then -- Store fruit logic placeholder end end end)

-- Additional Logic for future features -- Include more loops as needed for additional features like ESP, Sea Events, Leviathan, etc.

