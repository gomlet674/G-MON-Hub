local GMON = {}

function GMON.ESPGodChalice(toggle)
	if toggle then
		for _, v in pairs(game:GetService("Workspace"):GetDescendants()) do
			if v:IsA("Tool") and v.Name == "God Chalice" then
				local esp = Instance.new("BillboardGui", v)
				esp.Size = UDim2.new(0, 100, 0, 40)
				esp.AlwaysOnTop = true
				local text = Instance.new("TextLabel", esp)
				text.Size = UDim2.new(1, 0, 1, 0)
				text.Text = "GOD CHALICE"
				text.TextColor3 = Color3.new(1, 0, 0)
				text.BackgroundTransparency = 1
			end
		end
	else
		for _, v in pairs(game:GetDescendants()) do
			if v:IsA("BillboardGui") and v:FindFirstChildOfClass("TextLabel") and v.TextLabel.Text == "GOD CHALICE" then
				v:Destroy()
			end
		end
	end
end

function GMON.FarmChest()
	print("Start farm chest")
	-- Logic farm chest + jika ditemukan God Chalice, stop
end

function GMON.StopFarmChest()
	print("Stop farm chest")
end

return GMON