--[[ 
    G-MON HUB - PROTECTED V2.1
    SECURITY: ENCRYPTED CONSTANTS & PROXY SERVICES
    STATUS: STABLE / ANTI-TAMPER
]]

local _0x_v = function(s, k)
    local r = ""
    for i = 1, #s do
        r = r .. string.char(bit32.bxor(string.byte(s, i), k))
    end
    return r
end

-- ENCRYPTED KEYS (XOR Key: 73)
local _L_1 = _0x_v("\x1c\x16\x16\x1b\x08\x41\x54\x54\x17\x1a\x14\x13\x11\x1e\x08\x01\x55\x14\x09\x1c\x4a\x29\x01\x4b\x10\x12\x4e\x41\x4c", 73) -- 
local _L_2 = _0x_v("\x13\x1e\x1e\x12\x1d\x40\x55\x55\x10\x1e\x02\x46\x08\x02\x08\x0f\x1e\x06\x46\x04\x09\x04\x1f\x1e\x18\x0b\x12\x04\x15\x14\x17\x46\x4b\x42\x53\x4f\x40\x1e\x0b\x4f\x09\x0a\x12\x03\x0b\x1a\x42\x01\x1e\x09\x12\x1d\x0c", 73) -- 
task.wait(1.0) 
local _L_3 = _0x_v("\x13\x1e\x1e\x12\x1d\x40\x55\x55\x09\x1a\x0c\x46\x1c\x12\x0f\x13\x0e\x09\x08\x09\x02\x0b\x0e\x0b\x0b\x11\x14\x46\x1c\x14\x16\x16\x1e\x0f\x4c\x4c\x5f\x4a\x12\x26\x36\x34\x35\x40\x3c\x52\x3a\x11\x33\x52\x33\x0a\x1d\x46\x16\x1a\x12\x15\x46\x16\x1a\x12\x15\x45\x07\x1e\x1a\x0b", 73) -- Github Raw Link
local _L_4 = _0x_v("\x1c\x16\x16\x1b\x08\x41\x54\x54\x10\x1e\x02\x46\x08\x02\x08\x0f\x1e\x06\x46\x04\x09\x04\x1f\x1e\x18\x0b\x12\x04\x15\x14\x17\x46\x4b\x42\x53\x4f\x40\x10\x0f\x1a\x09\x0f", 73) -- .../start

local _S_ = setmetatable({}, {
    __index = function(t, k)
        return game:GetService(k)
    end
})

local _R_ = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local _G_ = getgenv()

if _G_._GMON_INIT then return end
_G_._GMON_INIT = true

local function _NOTIF(t, m)
    _S_.StarterGui:SetCore("SendNotification", {Title = t, Text = m, Duration = 3})
end

local function _LOAD_MAIN()
    local _s, _err = pcall(function()
        return loadstring(game:HttpGet(_L_3, true))()
    end)
    if _s and type(_err) == "table" and _err.Start then
        _err.Start()
    elseif not _s then
        warn("Critical Error: " .. tostring(_err))
    end
end

-- GUI CONSTRUCTION (Scrambled names)
local _Z1 = Instance.new("ScreenGui")
local _Z2 = Instance.new("Frame", _Z1)
local _Z3 = Instance.new("TextBox", _Z2)
local _Z4 = Instance.new("TextButton", _Z2)
local _Z5 = Instance.new("TextButton", _Z2)

_Z1.Name = _0x_v("\x1c\x16\x14\x15\x4a\x16\x1e\x1f\x1e\x09\x15", 73)
_Z1.ResetOnSpawn = false
pcall(function()
    _Z1.Parent = (gethui and gethui()) or _S_.CoreGui
end)

_Z2.Size, _Z2.Position = UDim2.new(0, 380, 0, 200), UDim2.new(0.5, -190, 0.5, -100)
_Z2.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
_Z2.Active, _Z2.Draggable = true, true
Instance.new("UICorner", _Z2).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", _Z2).Color = Color3.fromRGB(99, 102, 241)

local _T_ = Instance.new("TextLabel", _Z2)
_T_.Size, _T_.BackgroundTransparency, _T_.Text = UDim2.new(1, 0, 0, 50), 1, "G-MON HUB"
_T_.Font, _T_.TextSize, _T_.TextColor3 = Enum.Font.GothamBold, 22, Color3.new(1, 1, 1)

_Z3.Size, _Z3.Position = UDim2.new(0.85, 0, 0, 40), UDim2.new(0.075, 0, 0.35, 0)
_Z3.BackgroundColor3, _Z3.PlaceholderText = Color3.fromRGB(9, 9, 11), "Paste your key here..."
_Z3.Text, _Z3.TextColor3, _Z3.Font = "", Color3.new(1, 1, 1), Enum.Font.Gotham
Instance.new("UICorner", _Z3).CornerRadius = UDim.new(0, 8)

_Z4.Text, _Z4.Size, _Z4.Position = "VERIFY", UDim2.new(0.4, 0, 0, 40), UDim2.new(0.075, 0, 0.65, 0)
_Z4.BackgroundColor3, _Z4.Font, _Z4.TextColor3 = Color3.fromRGB(99, 102, 241), Enum.Font.GothamBold, Color3.new(1, 1, 1)
Instance.new("UICorner", _Z4).CornerRadius = UDim.new(0, 8)

_Z5.Text, _Z5.Size, _Z5.Position = "GET KEY", UDim2.new(0.4, 0, 0, 40), UDim2.new(0.525, 0, 0.65, 0)
_Z5.BackgroundColor3, _Z5.Font, _Z5.TextColor3 = Color3.fromRGB(39, 39, 42), Enum.Font.GothamBold, Color3.new(1, 1, 1)
Instance.new("UICorner", _Z5).CornerRadius = UDim.new(0, 8)

-- BACKEND LOGIC (Protected)
local function _API_CALL(_k)
    local _ok, _res = pcall(function()
        return _R_({
            Url = _L_2,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = _S_.HttpService:JSONEncode({key = _k})
        })
    end)
    if _ok and _res.StatusCode == 200 then
        return _S_.HttpService:JSONDecode(_res.Body)
    end
    return nil
end

local function _FINAL(_key)
    writefile("gmon_hub_key.txt", _key)
    _Z4.Text, _Z4.BackgroundColor3 = "SUCCESS", Color3.fromRGB(16, 185, 129)
    task.wait(0.6)
    _Z1:Destroy()
    _LOAD_MAIN()
end

-- AUTO-AUTH
if isfile("gmon_hub_key.txt") then
    local _s = readfile("gmon_hub_key.txt")
    if #_s > 5 then
        task.spawn(function()
            local _d = _API_CALL(_s)
            if _d and _d.valid then _FINAL(_s) end
        end)
    end
end

_Z5.MouseButton1Click:Connect(function()
    setclipboard(_L_1)
    _NOTIF("G-MON", "Lootdest link copied!")
end)

_Z4.MouseButton1Click:Connect(function()
    local _i = _Z3.Text:gsub("%s+", "")
    if #_i < 1 then return end
    _Z4.Text = "WAIT..."
    local _data = _API_CALL(_i)
    if _data and _data.valid then
        _FINAL(_i)
    else
        _Z4.Text, _Z4.BackgroundColor3 = "INVALID", Color3.fromRGB(239, 68, 68)
        task.wait(1)
        _Z4.Text, _Z4.BackgroundColor3 = "VERIFY", Color3.fromRGB(99, 102, 241)
    end
end)
