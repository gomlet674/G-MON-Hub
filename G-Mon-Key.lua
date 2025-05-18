-- G-Mon-key.lua
-- Menampilkan UI get key dan tombol Submit

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Build UI
local gui = Instance.new("ScreenGui", playerGui)
-- (buat Frame, KeyBox, GetKey, Submit, Close)
-- Copy kode dari implementasi terakhir
dofile("rbxassetid://<PATH>/KeyUIBuilder.lua")

-- Submit logic
Submit.MouseButton1Click:Connect(function()
    local key = KeyBox.Text:match("%S+") or ""
    if key == "GmonHub3118..." then
        gui:Destroy()
        -- panggil main.lua
        local main = Instance.new("LocalScript")
        main.Source = HttpService:GetAsync("https://raw.githubusercontent.com/.../main.lua")
        main.Parent = playerGui
    else
        Submit.Text = "Invalid!"
        task.wait(2)
        Submit.Text = "Submit"
    end
end)