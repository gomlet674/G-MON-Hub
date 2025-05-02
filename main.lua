-- GMON Hub Main Script
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

-- UI Setup
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "GMON_MainUI"
ScreenGui.ResetOnSpawn = false

-- Toggle Button
local Toggle = Instance.new("ImageButton", ScreenGui)
Toggle.Size = UDim2.new(0, 40, 0, 40)
Toggle.Position = UDim2.new(0, 10, 0.5, -100)
Toggle.BackgroundTransparency = 1
Toggle.Image = "rbxassetid://94747801090737"
Toggle.Name = "GMON_Toggle"

-- Drag toggle
local dragging, dragInput, dragStart, startPos
Toggle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = Toggle.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)
Toggle.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)
RunService.Heartbeat:Connect(function()
	if dragging and dragInput then
		local delta = dragInput.Position - dragStart
		Toggle.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Background Panel
local BG = Instance.new("ImageLabel", ScreenGui)
BG.Name = "Background"
BG.Size = UDim2.new(0, 480, 0, 320)
BG.Position = UDim2.new(0.5, -240, 0.5, -160)
BG.BackgroundTransparency = 1
BG.Image = "rbxassetid://88817335071002"
BG.Visible = true

Toggle.MouseButton1Click:Connect(function()
	BG.Visible = not BG.Visible
end)

-- Tambahkan ke atas sebelum Title GMON Hub
local RGBFrame = Instance.new("Frame", BG)
RGBFrame.Size = UDim2.new(1, 0, 1, 0)
RGBFrame.Position = UDim2.new(0, 0, 0, 0)
RGBFrame.BackgroundTransparency = 1
RGBFrame.BorderSizePixel = 4
RGBFrame.ZIndex = 2

-- Ubah properti untuk efek RGB
local border = Instance.new("UIStroke", RGBFrame)
border.Thickness = 4
border.Transparency = 0
border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
border.LineJoinMode = Enum.LineJoinMode.Round
border.Color = Color3.fromRGB(255, 0, 0)

-- Efek Rainbow RGB
spawn(function()
	local hue = 0
	while wait(0.03) do
		hue = hue + 1
		if hue >= 360 then hue = 0 end
		local color = Color3.fromHSV(hue / 360, 1, 1)
		pcall(function()
			border.Color = color
		end)
	end
end)

-- Label GMON Hub
local Title = Instance.new("TextLabel", BG)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "GMON Hub"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 24
Title.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Tombol Auto Farm
_G.AutoFarm = false
local AutoFarm = Instance.new("TextButton", BG)
AutoFarm.Size = UDim2.new(0, 200, 0, 40)
AutoFarm.Position = UDim2.new(0, 20, 0, 60)
AutoFarm.BackgroundTransparency = 0.4
AutoFarm.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
AutoFarm.TextColor3 = Color3.fromRGB(0, 0, 0)
AutoFarm.Font = Enum.Font.SourceSansBold
AutoFarm.TextSize = 20
AutoFarm.Text = "Auto Farm: OFF"

AutoFarm.MouseButton1Click:Connect(function()
	_G.AutoFarm = not _G.AutoFarm
	AutoFarm.Text = _G.AutoFarm and "Auto Farm: ON" or "Auto Farm: OFF"
end)

--===[ GMON Sea Events Tab Mentahan Berdasarkan Gambar ]===--

local seaEventsTab = Instance.new("Frame")
seaEventsTab.Name = "SeaEventsTab"
seaEventsTab.Size = UDim2.new(1, 0, 1, 0)
seaEventsTab.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
seaEventsTab.BackgroundTransparency = 0.4
seaEventsTab.BorderSizePixel = 0
seaEventsTab.Visible = true
seaEventsTab.Parent = Tabcontent -- Ganti sesuai parent kamu

local title = Instance.new("TextLabel", seaEventsTab)
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "Sea Events"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1

local function createToggleRow(parent, yPos, labelText)
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1, -20, 0, 35)
	row.Position = UDim2.new(0, 10, 0, yPos)
	row.BackgroundTransparency = 1

	local label = Instance.new("TextLabel", row)
	label.Size = UDim2.new(1, -50, 1, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.Text = labelText
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left

	local toggle = Instance.new("TextButton", row)
	toggle.Size = UDim2.new(0, 40, 0, 22)
	toggle.Position = UDim2.new(1, -45, 0.5, -11)
	toggle.BackgroundColor3 = Color3.fromRGB(70, 170, 255)
	toggle.Text = ""
	toggle.BorderSizePixel = 0
	toggle.AutoButtonColor = false

	local enabled = false
	local function updateColor()
		toggle.BackgroundColor3 = enabled and Color3.fromRGB(70, 170, 255) or Color3.fromRGB(100, 100, 100)
	end
	toggle.MouseButton1Click:Connect(function()
		enabled = not enabled
		updateColor()
		print(labelText .. ": " .. (enabled and "ON" or "OFF"))
	end)
	updateColor()
end

local y = 50
createToggleRow(seaEventsTab, y, "View Sea Events") y += 40
createToggleRow(seaEventsTab, y, "Auto Sea Beast") y += 40
createToggleRow(seaEventsTab, y, "Auto Sink Ship") y += 40
createToggleRow(seaEventsTab, y, "Ignore Sea Beast") y += 40
createToggleRow(seaEventsTab, y, "Ignore Ship") y += 40
createToggleRow(seaEventsTab, y, "Custom Distance") y += 40
createToggleRow(seaEventsTab, y, "Auto Target")

-- Setting Tab UI
local SettingFrame = Instance.new("Frame")
SettingFrame.Size = UDim2.new(0, 200, 0, 200)
SettingFrame.Position = UDim2.new(1, -210, 0, 60)
SettingFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- putih
SettingFrame.BackgroundTransparency = 0.4 -- transparansi 60%
SettingFrame.Visible = true
SettingFrame.Parent = BG

local function createToggleButton(name, posY, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -10, 0, 30)
	btn.Position = UDim2.new(0, 5, 0, posY)
	btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	btn.BackgroundTransparency = 0.4
	btn.TextColor3 = Color3.fromRGB(0, 0, 0) -- teks jadi hitam agar kontras
	btn.Text = name .. ": OFF"
	btn.Parent = SettingFrame

	local state = false
	btn.MouseButton1Click:Connect(function()
		state = not state
		btn.Text = name .. ": " .. (state and "ON" or "OFF")
		if callback then callback(state) end
	end)
end

-- Toggle Fast Attack
createToggleButton("Fast Attack", 10, function(enabled)
	_G.FastAttack = enabled
end)

-- Toggle Auto Click
createToggleButton("Auto Click", 50, function(enabled)
	_G.AutoClick = enabled
end)

-- Toggle Skill X/C/Z/V/F
createToggleButton("Use Skill X", 90, function(enabled)
	_G.UseSkillX = enabled
end)
createToggleButton("Use Skill C", 130, function(enabled)
	_G.UseSkillC = enabled
end)
createToggleButton("Use Skill Z", 170, function(enabled)
	_G.UseSkillZ = enabled
end)
createToggleButton("Use Skill V", 190, function(enabled)
	_G.UseSkillV = enabled
end)
createToggleButton("Use Skill F", 210, function(enabled)
	_G.UseSkillF = enabled
end)

local isMeleeEnabled = false

--===[ Auto Farm Logic GMON ]===--
local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")

-- Skill default toggle
_G.UseSkillZ = true
_G.UseSkillX = true
_G.UseSkillC = false
_G.UseSkillV = false
_G.UseSkillF = false

-- GMON Hub AutoFarm Full QuestData (Level 5 - 2650) local player = game.Players.LocalPlayer local ReplicatedStorage = game:GetService("ReplicatedStorage") local VIM = game:GetService("VirtualInputManager")

spawn(function()
	while true do wait(1)
		if _G.AutoFarm then
			pcall(function()
				local char = player.Character
				local lvl = player.Data.Level.Value

				local bestMatch = nil
				for levelReq, quest in pairs(questData) do
					if lvl >= levelReq and (not bestMatch or levelReq > bestMatch.LevelReq) then
						bestMatch = { LevelReq = levelReq, Data = quest }
					end
				end

				if not bestMatch then return end
				local data = bestMatch.Data

				-- Ambil quest jika belum
				if not player.PlayerGui:FindFirstChild("QuestTitle") then
					ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", data.QuestName, 1)
					wait(1)
				end

				-- Teleport ke lokasi umum (kalau ingin, kamu bisa tambah data.IslandPos)
				if char and char:FindFirstChild("HumanoidRootPart") then
					char.HumanoidRootPart.CFrame = data.MobPos + Vector3.new(0, 10, 0)
					wait(1)
				end

				-- Serang mob
				for _, mob in pairs(workspace.Enemies:GetChildren()) do
					if mob.Name == data.MobName and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
						repeat wait()
							if char and char:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("HumanoidRootPart") then
								char.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
							end
							if _G.UseSkillZ then VIM:SendKeyEvent(true, "Z", false, game) end
							if _G.UseSkillX then VIM:SendKeyEvent(true, "X", false, game) end
							if _G.UseSkillC then VIM:SendKeyEvent(true, "C", false, game) end
							if _G.UseSkillV then VIM:SendKeyEvent(true, "V", false, game) end
							if _G.UseSkillF then VIM:SendKeyEvent(true, "F", false, game) end
						until mob.Humanoid.Health <= 0 or not _G.AutoFarm
					end
				end
			end)
		end
	end
end)
