-- [[ G-MON HUB | MAIN DISPATCHER V2 ]] --
-- Update: April 7, 2026
-- Fokus: Stabilitas, Anti-Error, dan Sinkronisasi Loader

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Main = {} -- Table yang akan dipanggil oleh Loader

-- =========================
-- DATABASE LINK SCRIPT
-- =========================
local CONFIG = {
    ["Survive the Apocalypse"] = {
        -- Ganti angka di bawah ini dengan PlaceId yang benar dari game-nya
        PlaceIds = {106132712, 9014863586}, 
        URL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Survive-the-apocalypse.lua"
    },
    ["Blox Fruits"] = {
        PlaceIds = {2753915549, 4442272183, 7449423635}, -- Sea 1, 2, 3
        URL = "https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/Blox-Fruit.lua"
    }
}

-- =========================
-- INTERNAL UTILS
-- =========================
local function GetGuiParent()
    return (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
end

local function CreateNotification(msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "G-MON HUB",
            Text = msg,
            Duration = 5
        })
    end)
end

-- =========================
-- MAIN EXECUTION LOGIC
-- =========================
function Main.Start()
    print("[G-MON] Dispatcher Started...")
    
    -- 1. Deteksi Game
    local targetURL = nil
    local detectedName = "Unknown"
    
    for gameName, data in pairs(CONFIG) do
        if table.find(data.PlaceIds, game.PlaceId) then
            targetURL = data.URL
            detectedName = gameName
            break
        end
    end

    if not targetURL then
        warn("[G-MON] Game not supported. ID: " .. game.PlaceId)
        CreateNotification("Game tidak terdaftar di G-MON Hub!")
        return
    end

    -- 2. Munculkan UI Loading Sederhana
    local sg = Instance.new("ScreenGui", GetGuiParent())
    sg.Name = "GmonDispatcherUI"
    
    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 250, 0, 80)
    frame.Position = UDim2.new(0.5, -125, 0.5, -40)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame)
    
    local line = Instance.new("Frame", frame)
    line.Size = UDim2.new(0, 0, 0, 2)
    line.Position = UDim2.new(0, 0, 1, -2)
    line.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
    line.BorderSizePixel = 0

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "Loading: " .. detectedName
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14

    -- 3. Animasi Progress & Download
    TweenService:Create(line, TweenInfo.new(1.5), {Size = UDim2.new(1, 0, 0, 2)}):Play()
    
    task.spawn(function()
        local success, content = pcall(function()
            -- Anti-Cache: Menambahkan os.time agar selalu ambil versi terbaru dari GitHub
            return game:HttpGet(targetURL .. "?t=" .. os.time())
        end)

        task.wait(1.5) -- Memberi waktu animasi line

        if success and content then
            label.Text = "Executing..."
            task.wait(0.5)
            sg:Destroy()
            
            -- Eksekusi Script Game (Survive the Apocalypse / Blox Fruit)
            local func, err = loadstring(content)
            if func then
                pcall(func)
            else
                warn("[G-MON] Compile Error: " .. tostring(err))
                CreateNotification("Gagal memproses script!")
            end
        else
            label.Text = "Download Failed!"
            label.TextColor3 = Color3.new(1, 0, 0)
            task.wait(2)
            sg:Destroy()
        end
    end)
end

return Main -- INI WAJIB: Supaya Loader bisa menjalankan fungsi .Start()
