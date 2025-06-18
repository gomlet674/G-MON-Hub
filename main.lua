-- Samaran Ganteng Hub v1
local _GANTENG = loadstring(game:HttpGet(("https://raw.githubusercontent.com/shlexware/Rayfield/main/source"):reverse():reverse()))()

local _0xwindow = _GANTENG:CreateWindow({
    Name = "💻 Ganteng Hub UI",
    LoadingTitle = "Memuat Komponen...",
    LoadingSubtitle = "Dibuat oleh ✨",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "gHubX",
        FileName = "sistemkonfig"
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

local function fakeFunc(f) f() end

local a, b = "🏠", "⚙️"

local _mainTab = _0xwindow:CreateTab(a .. " Main", nil)
local _settingTab = _0xwindow:CreateTab(b .. " Setting", nil)

_settingTab:CreateParagraph({
    Title = "🕒 Delay Fast Attack",
    Content = "[Default: Normal]"
})

local __autoclick = false

_settingTab:CreateToggle({
    Name = "🤖 Auto Click",
    CurrentValue = false,
    Callback = function(val)
        __autoclick = val
        while __autoclick do
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):FindFirstChild("Click"):FireServer()
            end)
            task.wait(0.1)
        end
    end
})

_settingTab:CreateToggle({
    Name = "❌ Sembunyikan Notifikasi",
    CurrentValue = false,
    Callback = function(val)
        if val then
            for _,v in pairs(game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):GetDescendants()) do
                if v:IsA("TextLabel") and v.Text:lower():match("level up") then
                    v:Destroy()
                end
            end
        end
    end
})

_settingTab:CreateToggle({
    Name = "🔇 Hilangkan Suara Hit / Level",
    CurrentValue = false,
    Callback = function(v)
        if v then
            for _,obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Sound") and (obj.Name:lower():find("hit") or obj.Name:lower():find("level")) then
                    obj:Destroy()
                end
            end
        end
    end
})

_settingTab:CreateToggle({
    Name = "🖥️ Layar Putih",
    CurrentValue = false,
    Callback = function(set)
        local lighting = game:GetService("Lighting")
        lighting.Brightness = set and 5 or 2
        lighting.Ambient = set and Color3.new(1,1,1) or Color3.new(0.5,0.5,0.5)
    end
})
