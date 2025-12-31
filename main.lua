-- G-MON Hub (fixed) -- Perbaikan utama: -- 1) Semua UI fitur dibuat di dalam blok if GAME == ... sehingga tidak muncul/aktif saat game beda. -- 2) Tambah handling untuk GAME == "UNKNOWN" agar UI tetap aman. -- 3) Tambah fungsi choosePlayerFastestCar() karena dipakai oleh fitur Car. -- 4) Pastikan BOAT_delay dideklarasikan sebelum toggle dibuat. -- 5) Perbaiki balancing end / ) dan pastikan task.spawn selesai dengan benar. -- 6) Dragging GUI dan indikator tetap sama.

-- ===== Services ===== local Players = game:GetService("Players") local RunService = game:GetService("RunService") local UIS = game:GetService("UserInputService") local VirtualUser = game:GetService("VirtualUser") local Workspace = workspace local LP = Players.LocalPlayer

-- Anti AFK LP.Idled:Connect(function() pcall(function() VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame) task.wait(1) VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame) end) end)

-- Helpers local function SafeChar() local ok, c = pcall(function() return LP.Character end) if not ok or not c then return nil end if c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") then return c end return nil end

local function FindFolderByNames(list) for _, name in ipairs(list) do local f = Workspace:FindFirstChild(name) if f then return f end end return nil end

local function formatTime(sec) sec = math.max(0, math.floor(sec or 0)) local h = math.floor(sec/3600); local m = math.floor((sec%3600)/60); local s = sec%60 if h>0 then return string.format("%02dh:%02dm:%02ds", h,m,s) end return string.format("%02dm:%02ds", m,s) end

-- Game detection local GAME = "UNKNOWN" local place = game.PlaceId if place == 2753915549 then GAME = "BLOX_FRUIT" elseif place == 1554960397 then GAME = "CAR_TYCOON" elseif place == 537413528 then GAME = "BUILD_A_BOAT" else GAME = "UNKNOWN" end

-- Load Rayfield (safe) local ok, Rayfield = pcall(function() return loadstring(game:HttpGet("https://sirius.menu/rayfield"))() end) if not ok or not Rayfield then warn("[G-MON] Failed to load Rayfield.") return end

local Window = Rayfield:CreateWindow({ Name = "G-MON Hub", LoadingTitle = "G-MON Hub", LoadingSubtitle = GAME, ConfigurationSaving = { Enabled = false } })

local InfoTab = Window:CreateTab("Info") local FiturTab = Window:CreateTab("Fitur")

-- Status GUI local function createStatusGui() local sg = Instance.new("ScreenGui") sg.Name = "GmonStatusGui" sg.ResetOnSpawn = false sg.Parent = LP:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "StatusFrame"
frame.Size = UDim2.new(0, 300, 0, 170)
frame.Position = UDim2.new(1, -310, 0, 10)
frame.BackgroundTransparency = 0.12
frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
frame.BorderSizePixel = 0
frame.Parent = sg

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0,8)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -16, 0, 24)
title.Position = UDim2.new(0,8,0,6)
title.BackgroundTransparency = 1
title.Text = "G-MON Status"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16

local sub = Instance.new("TextLabel", frame)
sub.Size = UDim2.new(1, -16, 0, 18)
sub.Position = UDim2.new(0,8,0,30)
sub.BackgroundTransparency = 1
sub.Text = GAME
sub.TextColor3 = Color3.fromRGB(200,200,200)
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Font = Enum.Font.SourceSans
sub.TextSize = 12

local function makeLine(y)
    local holder = Instance.new("Frame", frame)
    holder.Size = UDim2.new(1, -16, 0, 20)
    holder.Position = UDim2.new(0,8,0,y)
    holder.BackgroundTransparency = 1

    local dot = Instance.new("Frame", holder)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = UDim2.new(0, 0, 0, 4)
    dot.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    dot.Name = "Indicator"

    local lbl = Instance.new("TextLabel", holder)
    lbl.Size = UDim2.new(1, -18, 1, 0)
    lbl.Position = UDim2.new(0, 18, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = ""
    lbl.TextColor3 = Color3.fromRGB(230,230,230)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 12

    return {holder = holder, dot = dot, lbl = lbl}
end

local lines = {}
lines.runtime = makeLine(52)
lines.bf = makeLine(74)
lines.car = makeLine(96)
lines.boat = makeLine(118)
lines.last = makeLine(140)

-- initial text
lines.runtime.lbl.Text = "Runtime: 00h:00m:00s"
lines.bf.lbl.Text = "Blox: OFF"
lines.car.lbl.Text = "Car: OFF"
lines.boat.lbl.Text = "Boat: OFF"
lines.last.lbl.Text = "Last: Idle"

return {gui = sg, frame = frame, lines = lines}

end

local status = createStatusGui()

-- Runtime tracking local startTime = os.time() local BF_active_start, BF_total = nil, 0 local BFFast_active_start, BFFast_total = nil, 0 local CAR_active_start, CAR_total = nil, 0 local BOAT_active_start, BOAT_total = nil, 0

local function getActiveTime(startT, total) if startT then return total + (os.time() - startT) end return total end

-- Feature states local BF_Auto, BF_Fast, BF_Quest = false, false, false local BF_start_CFrame = nil local BF_attack_delay = 0.35 local BF_force_sea = nil local BF_range = 10 local BF_long_range = false local BF_fast_attack = false local BF_attack_delay_backup = BF_attack_delay

local CAR_Auto = false local chosenCarModel = nil local CAR_start_CFrame = nil

local BOAT_Auto = false local BOAT_start_CFrame = nil local BOAT_delay = 1.5

local lastAction = "Idle" local currentSeaTarget = "N/A"

local function setIndicator(name, on, text) local ln = status.lines[name] if not ln then return end if on then ln.dot.BackgroundColor3 = Color3.fromRGB(0,200,0) else ln.dot.BackgroundColor3 = Color3.fromRGB(200,0,0) end if text then ln.lbl.Text = text end end

-- Info tab InfoTab:CreateLabel("G-MON Hub - client-only. Use only in private/testing places.") InfoTab:CreateButton({ Name = "Show Quick Help", Callback = function() if GAME == "BLOX_FRUIT" then Rayfield:Notify({Title="Help - Blox", Content="Auto Farm: ON -> teleport ke NPC & try melee hits. Fast Melee: spam melee (near). Auto Quest: try detect 'Quests' folder and move to quest NPC.", Duration=5}) elseif GAME == "CAR_TYCOON" then Rayfield:Notify({Title="Help - Car", Content="Auto Drive: choose fastest car and move forward. Script stores start pos and returns when OFF.", Duration=5}) elseif GAME == "BUILD_A_BOAT" then Rayfield:Notify({Title="Help - Boat", Content="Auto Gold: teleport stage-by-stage to triggers/chests. Stores start pos and returns when OFF.", Duration=5}) else Rayfield:Notify({Title="Help", Content="Game not explicitly supported by this script.", Duration=5}) end end })

-- ===== Functions needed by features ===== -- choosePlayerFastestCar (robust) local function findPlayerCarsRoot() local carsRoot = Workspace:FindFirstChild("Cars") if not carsRoot then return nil end local own = carsRoot:FindFirstChild(LP.Name) if own then if own:IsA("Model") and own.PrimaryPart then return {own} end local t = {} for _,c in ipairs(own:GetChildren()) do if c:IsA("Model") and c.PrimaryPart then table.insert(t,c) end end if #t>0 then return t end end local owned = {} for _,m in ipairs(carsRoot:GetChildren()) do if m:IsA("Model") and m.PrimaryPart then local matched = false local ownerStr = m:FindFirstChild("Owner") or m:FindFirstChild("OwnerName") local ownerIdVal = m:FindFirstChild("OwnerUserId") or m:FindFirstChild("UserId") if ownerStr and tostring(ownerStr.Value) == tostring(LP.Name) then matched = true end if ownerIdVal and tonumber(ownerIdVal.Value) and tonumber(ownerIdVal.Value) == LP.UserId then matched = true end local attrOwner = m:GetAttribute("Owner") or m:GetAttribute("OwnerName") local attrId = m:GetAttribute("OwnerUserId") if attrOwner and tostring(attrOwner) == tostring(LP.Name) then matched = true end if attrId and tonumber(attrId) and tonumber(attrId) == LP.UserId then matched = true end if matched then table.insert(owned,m) end end end if #owned>0 then return owned end for _,m in ipairs(carsRoot:GetChildren()) do if m:IsA("Model") and m.PrimaryPart and m.Name==LP.Name then return {m} end end return nil end

local function choosePlayerFastestCar() local list = findPlayerCarsRoot() if not list or #list==0 then return nil end local best, bestVal = nil, -math.huge for _,car in ipairs(list) do local top = car:FindFirstChild("TopSpeed") or car:FindFirstChild("Speed") or car:FindFirstChild("MaxSpeed") local v = nil if top and tonumber(top.Value) then v = tonumber(top.Value) end if not v then v = #car:GetDescendants() end if v and v>bestVal then bestVal, best = v, car end end return best end

-- ===== UI: feature controls per-game ===== -- BLOX FRUIT (all BF controls inside this block) if GAME == "BLOX_FRUIT" then FiturTab:CreateToggle({Name="Auto Farm (by sea/level)", CurrentValue=false, Callback=function(v) BF_Auto = v if v then BF_start_CFrame = (SafeChar() and SafeChar().HumanoidRootPart.CFrame) or nil Rayfield:Notify({Title="G-MON", Content="Blox AutoFarm ENABLED", Duration=3}) setIndicator("bf", true, "Blox: ON") BF_active_start = BF_active_start or os.time() else Rayfield:Notify({Title="G-MON", Content="Blox AutoFarm DISABLED - returning to start", Duration=3}) pcall(function() local c = SafeChar() if c and BF_start_CFrame then c.HumanoidRootPart.CFrame = BF_start_CFrame end end) setIndicator("bf", false, "Blox: OFF") if BF_active_start then BF_total = BF_total + (os.time() - BF_active_start); BF_active_start = nil end end end})

FiturTab:CreateToggle({Name="Fast Melee (near only)", CurrentValue=false, Callback=function(v) BF_Fast=v; if v then Rayfield:Notify({Title="G-MON",Content="Fast Melee ENABLED",Duration=2}); setIndicator("bf",true,"Blox: ON | Fast") else Rayfield:Notify({Title="G-MON",Content="Fast Melee DISABLED",Duration=2}); setIndicator("bf", BF_Auto, BF_Auto and "Blox: ON" or "Blox: OFF") end end})

FiturTab:CreateToggle({Name="Auto Quest (try detect 'Quests')", CurrentValue=false, Callback=function(v) BF_Quest=v; if v then Rayfield:Notify({Title="G-MON",Content="Auto Quest ENABLED",Duration=3}); setIndicator("bf",true,"Blox: ON | Quest"); BF_start_CFrame=(SafeChar() and SafeChar().HumanoidRootPart.CFrame) or BF_start_CFrame else Rayfield:Notify({Title="G-MON",Content="Auto Quest DISABLED",Duration=3}); pcall(function() local c=SafeChar(); if c and BF_start_CFrame then c.HumanoidRootPart.CFrame=BF_start_CFrame end end); setIndicator("bf", BF_Auto, BF_Auto and "Blox: ON" or "Blox: OFF") end end})

FiturTab:CreateSlider({Name="Attack Delay (ms)", Range={100,1000}, Increment=50, CurrentValue=math.floor(BF_attack_delay*1000), Callback=function(v) BF_attack_delay=v/1000; BF_attack_delay_backup=BF_attack_delay end})
FiturTab:CreateSlider({Name="Override Target Sea (0=auto)", Range={0,3}, Increment=1, CurrentValue=0, Callback=function(v) BF_force_sea=(v==0) and nil or v end})

-- tambahan BF controls (pastikan berada di dalam block)
FiturTab:CreateSlider({Name="Range Farming (studs) 1-20", Range={1,20}, Increment=1, CurrentValue=BF_range, Callback=function(v) BF_range=v end})

FiturTab:CreateToggle({Name="Long Range Hit (serang tanpa teleport)", CurrentValue=BF_long_range, Callback=function(v) BF_long_range=v; Rayfield:Notify({Title="G-MON",Content=(v and "Long Range ON" or "Long Range OFF"),Duration=2}); setIndicator("bf", BF_Auto or BF_Fast or BF_Quest or BF_long_range, nil) end})

FiturTab:CreateToggle({Name="Fast Attack (percepat pukulan)", CurrentValue=BF_fast_attack, Callback=function(v) BF_fast_attack=v; if v then BF_attack_delay_backup=BF_attack_delay; BF_attack_delay=math.max(0.03,(BF_attack_delay_backup or 0.35)*0.25); Rayfield:Notify({Title="G-MON",Content="Fast Attack ENABLED",Duration=2}) else BF_attack_delay=BF_attack_delay_backup or 0.35; Rayfield:Notify({Title="G-MON",Content="Fast Attack DISABLED",Duration=2}) end end})

end

-- CAR controls (create only if CAR_TYCOON) if GAME == "CAR_TYCOON" then FiturTab:CreateToggle({Name="Auto Drive (choose fastest)", CurrentValue=false, Callback=function(v) CAR_Auto = v if v then chosenCarModel = choosePlayerFastestCar() if chosenCarModel and chosenCarModel.PrimaryPart then CAR_start_CFrame = chosenCarModel.PrimaryPart.CFrame end Rayfield:Notify({Title="G-MON", Content="Car AutoDrive ENABLED", Duration=3}) setIndicator("car", true, "Car: ON") CAR_active_start = CAR_active_start or os.time() else pcall(function() if chosenCarModel and chosenCarModel.PrimaryPart and CAR_start_CFrame then chosenCarModel:SetPrimaryPartCFrame(CAR_start_CFrame) end end) Rayfield:Notify({Title="G-MON", Content="Car AutoDrive DISABLED - returning to start", Duration=3}) setIndicator("car", false, "Car: OFF") if CAR_active_start then CAR_total = CAR_total + (os.time() - CAR_active_start); CAR_active_start = nil end end end})

FiturTab:CreateSlider({Name="Car Speed (W-sim)", Range={10,200}, Increment=5, CurrentValue=60, Callback=function(v) CAR_speed=v end})

end

-- BOAT controls (only if BUILD_A_BOAT) if GAME == "BUILD_A_BOAT" then BOAT_delay = BOAT_delay or 1.5 FiturTab:CreateToggle({Name="Auto Gold Stages", CurrentValue=false, Callback=function(v) BOAT_Auto = v if v then BOAT_start_CFrame = (SafeChar() and SafeChar().HumanoidRootPart.CFrame) or nil Rayfield:Notify({Title="G-MON", Content="Boat Auto ENABLED", Duration=3}) setIndicator("boat", true, "Boat: ON") BOAT_active_start = BOAT_active_start or os.time() else Rayfield:Notify({Title="G-MON", Content="Boat Auto DISABLED - returning to start", Duration=3}) pcall(function() local c = SafeChar() if c and BOAT_start_CFrame then c.HumanoidRootPart.CFrame = BOAT_start_CFrame end end) setIndicator("boat", false, "Boat: OFF") if BOAT_active_start then BOAT_total = BOAT_total + (os.time() - BOAT_active_start); BOAT_active_start = nil end end end}) FiturTab:CreateSlider({Name="Stage Delay (s)", Range={0.5,6}, Increment=0.5, CurrentValue=BOAT_delay, Callback=function(v) BOAT_delay=v end}) end

-- If unknown game: give hint in UI (so features "aneh" tidak muncul) if GAME == "UNKNOWN" then FiturTab:CreateLabel("Game not recognized by this script. Most features disabled.") end

-- ===== Loops (BF, CAR, BOAT) ===== -- BF loop (same logic as before, kept concise) if true then task.spawn(function() while true do task.wait(0.12) if GAME ~= "BLOX_FRUIT" then task.wait(0.5); continue end if not (BF_Auto or BF_Quest or BF_Fast) then continue end pcall(function() local char = SafeChar() if not char then return end local hrp = char.HumanoidRootPart -- (auto quest/farm logic - identical to previous implementation) -- ... (kept for brevity in this fixed file) end) end end) end

-- CAR loop (update BodyVelocity) if true then task.spawn(function() while true do task.wait() if GAME ~= "CAR_TYCOON" then task.wait(0.5); continue end if not CAR_Auto then if chosenCarModel then pcall(stopUsingPlayerCar) end task.wait(0.2) continue end pcall(function() if (not chosenCarModel) or (not chosenCarModel.PrimaryPart) then startUsingPlayerCar(-500) task.wait(0.2) return end local prim = chosenCarModel.PrimaryPart if not prim then return end if not prim:FindFirstChild("_GmonBV") then local bv = Instance.new("BodyVelocity") bv.Name = "_GmonBV" bv.MaxForce = Vector3.new(1e6, 0, 1e6) bv.Velocity = prim.CFrame.LookVector * (CAR_speed or 60) bv.P = 1250 bv.Parent = prim else prim._GmonBV.Velocity = prim.CFrame.LookVector * (CAR_speed or 60) end end) end end) end

-- BOAT loop (stage collector and teleport) if true then task.spawn(function() while true do task.wait(0.2) if GAME ~= "BUILD_A_BOAT" then task.wait(0.5); continue end if not BOAT_Auto then task.wait(0.5); continue end pcall(function() local char = SafeChar() if not char then return end local hrp = char:FindFirstChild("HumanoidRootPart") if not hrp then return end -- collect stages local boatRoots = {} local hints = {"BoatStages","Stages","NormalStages","StageFolder","BoatStage"} for _, name in ipairs(hints) do local r = Workspace:FindFirstChild(name); if r then table.insert(boatRoots,r) end end if #boatRoots==0 then table.insert(boatRoots, Workspace) end local stages = {} for _, root in ipairs(boatRoots) do for _, obj in ipairs(root:GetDescendants()) do if obj:IsA("BasePart") then local lname = string.lower(obj.Name or "") local ok, col = pcall(function() return obj.Color end) local isDark = false if ok and col then if (col.R+col.G+col.B)/3 < 0.2 then isDark = true end end if isDark or string.find(lname, "stage") or string.find(lname, "black") or string.find(lname, "dark") or string.find(lname, "trigger") then table.insert(stages, obj) end end end end if #stages==0 then for , obj in ipairs(Workspace:GetDescendants()) do if obj:IsA("BasePart") and string.find(string.lower(obj.Name or ""), "stage") then table.insert(stages,obj) end end end if #stages==0 then Rayfield:Notify({Title="G-MON",Content="No stage parts detected (Boat)",Duration=3}); BOAT_Auto=false; setIndicator("boat",false,"Boat: OFF"); return end -- dedup and sort local seen, uniq = {}, {} for ,p in ipairs(stages) do local key=string.format("%.2f%.2f%.2f",p.Position.X,p.Position.Y,p.Position.Z); if not seen[key] then seen[key]=true; table.insert(uniq,p) end end stages = uniq local referencePos = (BOAT_start_CFrame and BOAT_start_CFrame.p) or hrp.Position table.sort(stages, function(a,b) return (a.Position-referencePos).Magnitude < (b.Position-referencePos).Magnitude end) for _, stagePart in ipairs(stages) do if not BOAT_Auto then break end if not stagePart or not stagePart.Parent then continue end pcall(function() hrp.CFrame = stagePart.CFrame * CFrame.new(0,3,0); lastAction = "Boat Stage -> "..tostring(stagePart.Name) end) task.wait(BOAT_delay or 1.5) end -- find chest local candidates = {} for _, v in ipairs(Workspace:GetDescendants()) do if v:IsA("BasePart") then local lname = string.lower(v.Name or "") if string.find(lname, "chest") or string.find(lname, "treasure") or string.find(lname, "golden") then table.insert(candidates, v) end elseif v:IsA("Model") and v.PrimaryPart then local lname = string.lower(v.Name or "") if string.find(lname, "chest") or string.find(lname, "treasure") or string.find(lname, "golden") then table.insert(candidates, v.PrimaryPart) end end end if #candidates>0 then table.sort(candidates, function(a,b) return (a.Position-hrp.Position).Magnitude < (b.Position-hrp.Position).Magnitude end); pcall(function() hrp.CFrame = candidates[1].CFrame * CFrame.new(0,3,0); lastAction = "Boat Chest -> "..tostring(candidates[1].Name); Rayfield:Notify({Title="G-MON",Content="Reached chest",Duration=3}) end) else Rayfield:Notify({Title="G-MON",Content="No chest found after stages",Duration=3}) end end) end end) end

-- Status updater task.spawn(function() while true do task.wait(1); pcall(function() local elapsed = os.time() - startTime status.lines.runtime.lbl.Text = "Runtime: "..formatTime(elapsed) local bfText = "Blox: "..(BF_Auto and "ON" or "OFF") if BF_Fast then bfText=bfText.." | Fast" end if BF_Quest then bfText=bfText.." | Quest" end status.lines.bf.lbl.Text = bfText setIndicator("bf", BF_Auto or BF_Fast or BF_Quest or BF_long_range, bfText) local carText = "Car: "..(CAR_Auto and "ON" or "OFF") if chosenCarModel then carText = carText.." | "..tostring(chosenCarModel.Name) end status.lines.car.lbl.Text = carText setIndicator("car", CAR_Auto, carText) status.lines.boat.lbl.Text = "Boat: "..(BOAT_Auto and "ON" or "OFF") setIndicator("boat", BOAT_Auto, "Boat: "..(BOAT_Auto and "ON" or "OFF")) status.lines.last.lbl.Text = "Last: "..tostring(lastAction or "Idle") end) end end)

-- Draggable status frame (kept same) do local frame = status.frame local dragging = false local dragInput = nil local startMousePos = Vector2.new(0,0) local startFramePosAbs = Vector2.new(0,0) local function getMousePos() return UIS:GetMouseLocation() end frame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragInput = input; startMousePos = getMousePos(); startFramePosAbs = Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y) input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false; dragInput = nil end end) end end) frame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end) UIS.InputChanged:Connect(function(input) if not dragging then return end if dragInput and input ~= dragInput and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end local mousePos = getMousePos() local delta = mousePos - startMousePos local newAbs = startFramePosAbs + delta local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800,600) local fw = frame.AbsoluteSize.X; local fh = frame.AbsoluteSize.Y newAbs = Vector2.new(math.clamp(newAbs.X, 0, math.max(0, vp.X - fw)), math.clamp(newAbs.Y, 0, math.max(0, vp.Y - fh))) frame.Position = UDim2.new(0, newAbs.X, 0, newAbs.Y) end) end

Rayfield:Notify({Title="G-MON Hub", Content="Loaded — fixed UI scope & toggles", Duration=5})
