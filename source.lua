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