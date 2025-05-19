local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DiscordInviteUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
pcall(function()
	screenGui.Parent = CoreGui
end)

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(1, 1)
mainFrame.Position = UDim2.new(1, -30, 1, -80)
mainFrame.Size = UDim2.new(0, 220, 0, 56)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Thickness = 1.2
stroke.Transparency = 0.6
stroke.Parent = mainFrame

local icon = Instance.new("ImageLabel")
icon.Name = "Icon"
icon.Image = "rbxassetid://95183678717613"
icon.Size = UDim2.new(0, 24, 0, 24)
icon.Position = UDim2.new(0, 14, 0.5, -12)
icon.BackgroundTransparency = 1
icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
icon.Parent = mainFrame

local btn = Instance.new("TextButton")
btn.Name = "DiscordButton"
btn.AnchorPoint = Vector2.new(0, 0.5)
btn.Position = UDim2.new(0, 50, 0.5, 0)
btn.Size = UDim2.new(1, -60, 1, -20)
btn.Text = "Join Skull Hub Discord"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.TextSize = 16
btn.Font = Enum.Font.GothamSemibold
btn.BackgroundTransparency = 1
btn.Parent = mainFrame

btn.MouseEnter:Connect(function()
	TweenService:Create(mainFrame, TweenInfo.new(0.25), {
		BackgroundColor3 = Color3.fromRGB(64, 64, 64)
	}):Play()
end)

btn.MouseLeave:Connect(function()
	TweenService:Create(mainFrame, TweenInfo.new(0.25), {
		BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	}):Play()
end)

local LoaderData = {
	DiscordInvite = "https://discord.gg/VGW4gkmnBa"
}

local function exists(func)
	return pcall(function() return func and type(func) == "function" end)
end

local detectedExecutor = "Unknown"
local environmentData = {
	["Identify Executor"] = exists(identifyexecutor) and identifyexecutor(),
	["Get Executor Name"] = exists(getexecutorname) and getexecutorname(),
	["Check Synapse"] = exists(syn) and "Synapse",
	["Check Set Clipboard"] = exists(setclipboard) and "Has setclipboard",
	["Check Websocket"] = exists(websocket) and "Has websocket",
}

for _, value in pairs(environmentData) do
	if value and value ~= true then
		detectedExecutor = value
		break
	end
end

if environmentData["Identify Executor"] then
	detectedExecutor = environmentData["Identify Executor"]
elseif environmentData["Get Executor Name"] then
	detectedExecutor = environmentData["Get Executor Name"]
end

local function detectMobile()
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled then
        return true -- Mobile detected
    end
end

btn.MouseButton1Click:Connect(function()
	if detectedExecutor:lower():find("swift") or detectedExecutor:lower():find("velocity") or detectedExecutor:lower():find("ronix") or detectedExecutor:lower():find("atlantis") or detectedExecutor:lower():find("awp") or detectedExecutor:lower():find("wave") or detectedExecutor:lower():find("potassium") then
		pcall(function()
			request({
				Url = 'http://127.0.0.1:6463/rpc?v=1',
				Method = 'POST',
				Headers = {
					['Content-Type'] = 'application/json',
					Origin = 'https://discord.com'
				},
				Body = HttpService:JSONEncode({
					cmd = 'INVITE_BROWSER',
					nonce = HttpService:GenerateGUID(false),
					args = {code = string.match(LoaderData.DiscordInvite, "discord%.gg/(%w+)")}
				})
			})
		end)
	else
		setclipboard(LoaderData.DiscordInvite)
	end
end)

mainFrame.Position = UDim2.new(1, 300, 1, -80)
mainFrame.BackgroundTransparency = 1
icon.ImageTransparency = 1
btn.TextTransparency = 1

TweenService:Create(mainFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {
	Position = UDim2.new(1, -30, 1, -80),
	BackgroundTransparency = 0.15
}):Play()

TweenService:Create(icon, TweenInfo.new(0.6), {ImageTransparency = 0}):Play()
TweenService:Create(btn, TweenInfo.new(0.6), {TextTransparency = 0}):Play()

task.delay(20, function()
	TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {
		Position = UDim2.new(1, 300, 1, -80),
		BackgroundTransparency = 1
	}):Play()
	TweenService:Create(icon, TweenInfo.new(0.6), {ImageTransparency = 1}):Play()
	TweenService:Create(btn, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
end)
