local StatsTab = Window:CreateTab("Stats", 4483362458)

local StatsPointOptions = {"Melee", "Defense", "Sword", "Gun", "Blox Fruit"}

StatsTab:CreateDropdown({
	Name = "Select Stat Type",
	Options = StatsPointOptions,
	CurrentOption = "Melee",
	Flag = "SelectedStat",
	Callback = function(Option)
		_G.SelectedStat = Option
	end,
})

StatsTab:CreateToggle({
	Name = "Auto Stats",
	CurrentValue = false,
	Flag = "AutoStats",
	Callback = function(Value)
		_G.AutoStats = Value
		while _G.AutoStats do
			pcall(function()
				local args = {
					[1] = _G.SelectedStat,
					[2] = 1 -- jumlah point yang dibagikan
				}
				game:GetService("ReplicatedStorage").Remotes.Comm:InvokeServer("AddPoint", unpack(args))
			end)
			task.wait(1.5)
		end
	end,
})

local GMON = {}

local RunService = game:GetService("RunService")
local ChestFarmRunning = false
local ESPGodChaliceAdded = false

-- === Fungsi ESP God Chalice ===
function GMON.ESPGodChalice()
    if ESPGodChaliceAdded then return end
    ESPGodChaliceAdded = true

    local function highlight(obj)
        local esp = Instance.new("Highlight", obj)
        esp.Name = "GMON_ChaliceESP"
        esp.FillColor = Color3.fromRGB(255, 215, 0) -- emas
        esp.OutlineColor = Color3.fromRGB(255, 255, 255)
        esp.FillTransparency = 0.3
        esp.OutlineTransparency = 0
    end

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Tool") and v.Name == "God's Chalice" then
            highlight(v)
        end
    end

    workspace.DescendantAdded:Connect(function(v)
        if v:IsA("Tool") and v.Name == "God's Chalice" and not v:FindFirstChild("GMON_ChaliceESP") then
            highlight(v)
        end
    end)
end

-- === Fungsi Farm Chest (berhenti jika menemukan God Chalice) ===
function GMON.FarmChest()
    if ChestFarmRunning then return end
    ChestFarmRunning = true

    task.spawn(function()
        while ChestFarmRunning do
            -- Cek apakah ada God's Chalice di workspace
            for _, item in pairs(workspace:GetDescendants()) do
                if item:IsA("Tool") and item.Name == "God's Chalice" then
                    warn("God's Chalice ditemukan! Farm Chest dihentikan.")
                    ChestFarmRunning = false
                    return
                end
            end

            -- Ambil semua chest
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and string.find(obj.Name, "Chest") and obj:FindFirstChild("TouchInterest") then
                    local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = obj:GetModelCFrame()
                        wait(0.3)
                    end
                end
            end

            task.wait(3) -- jeda antar loop
        end
    end)
end

-- === Fungsi Stop Farm Chest Manual ===
function GMON.StopFarmChest()
    ChestFarmRunning = false
end

return GMON