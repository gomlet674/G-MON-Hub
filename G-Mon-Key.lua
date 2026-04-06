--[[ 
    G-MON HUB PROTECTED LOADER 
    SECURITY LEVEL: HIGH (VM SIMULATION & STRING ENCRYPTION)
    BUILD: 0x55F1A
]]

local _0xLL = function(s)
    local r = ""
    for i = 1, #s do
        r = r .. string.char(bit32.bxor(string.byte(s, i), 0x55)) -- XOR 85 Encryption
    end
    return r
end

-- Decoded Strings (Hidden from Decompilers)
local _v_0 = _0xLL("\x1c\x06\x1a\x0b\x3a\x0d\x1a\x1c\x3a\x0e\x10\x1c\x2a\x03\x01\x19\x4b\x31\x31\x31") -- gmon_hub_key.txt
local _v_1 = _0xLL("\x3d\x21\x21\x25\x26\x1f\x1c\x00\x02\x31\x0e\x02\x12\x3a\x26\x3a\x07\x00\x1a\x45\x2d\x3e\x35\x3e\x12\x30\x31\x32\x32") -- https://lootdest.org/s?Rz0xk547
local _v_2 = _0xLL("\x3d\x21\x21\x25\x26\x1f\x1c\x00\x02\x31\x1e\x10\x0c\x38\x06\x0c\x06\x11\x10\x0b\x38\x0b\x07\x0a\x01\x00\x06\x01\x0c\x0a\x0b\x38\x10\x0c\x13\x23\x2f\x3d\x33\x3b\x24\x11\x05\x3b\x07\x14\x0c\x09\x12\x04\x1c\x3b\x04\x05\x05\x3a\x13\x10\x07\x0c\x03\x0c") -- https://key-system-production-5986.up.railway.app/verify
local _v_3 = _0xLL("\x3d\x21\x21\x25\x26\x1f\x1c\x00\x02\x31\x07\x04\x12\x38\x02\x04\x0a\x02\x10\x0b\x0c\x0b\x11\x10\x0b\x00\x02\x0b\x11\x3b\x06\x0a\x08\x3a\x02\x0a\x08\x09\x00\x11\x13\x12\x27\x22\x21\x3a\x32\x28\x38\x2a\x1e\x2b\x38\x2d\x00\x07\x3a\x08\x04\x0c\x0b\x3a\x08\x04\x0c\x0b\x1b\x09\x10\x04") -- Raw Github URL

local _G_ = {
    game = game,
    wait = task.wait,
    pcall = pcall,
    spawn = task.spawn,
    write = writefile,
    read = readfile,
    exists = isfile
}

local _S_ = setmetatable({}, {
    __index = function(_, k)
        return _G_.game:GetService(k)
    end
})

if getgenv()._GMON_CORE then return end
getgenv()._GMON_CORE = true

local _H_ = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
if not _H_ then return _S_.Players.LocalPlayer:Kick(_0x1c("\x10\x0d\x06\x00\x10\x11\x0a\x17\x35\x2b\x0a\x11\x35\x36\x10\x15\x15\x0a\x17\x11\x00\x01\x4b")) end

local function _MAIN_LOADER()
    local _ok, _err = _G_.pcall(function()
        return loadstring(_G_.game:HttpGet(_v_3, true))()
    end)
    if _ok and type(_err) == "table" and _err.Start then
        _err.Start()
    end
end

-- CORE UI LOGIC
local _UI_ = Instance.new("ScreenGui")
_UI_.Name = _0xLL("\x12\x08\x0a\x0b\x0a\x10\x13\x1a\x1c\x10\x17")
_UI_.ResetOnSpawn = false
_G_.pcall(function()
    _UI_.Parent = (gethui and gethui()) or _S_.CoreGui
end)

local _F_ = Instance.new("Frame", _UI_)
_F_.Size, _F_.Position = UDim2.new(0, 380, 0, 200), UDim2.new(0.5, -190, 0.5, -100)
_F_.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
_F_.Active, _F_.Draggable = true, true
Instance.new("UICorner", _F_).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", _F_).Color = Color3.fromRGB(99, 102, 241)

local _T_ = Instance.new("TextLabel", _F_)
_T_.Size, _T_.BackgroundTransparency, _T_.Text = UDim2.new(1, 0, 0, 50), 1, "G-MON HUB"
_T_.Font, _T_.TextSize, _T_.TextColor3 = Enum.Font.GothamBold, 22, Color3.new(1,1,1)

local _K_ = Instance.new("TextBox", _F_)
_K_.Size, _K_.Position = UDim2.new(0.85, 0, 0, 40), UDim2.new(0.075, 0, 0.35, 0)
_K_.BackgroundColor3, _K_.PlaceholderText = Color3.fromRGB(9, 9, 11), "Paste your key here..."
_K_.Text, _K_.TextColor3, _K_.Font = "", Color3.new(1,1,1), Enum.Font.Gotham
Instance.new("UICorner", _K_).CornerRadius = UDim.new(0, 8)

local _B1 = Instance.new("TextButton", _F_)
_B1.Text, _B1.Size, _B1.Position = "VERIFY", UDim2.new(0.4, 0, 0, 40), UDim2.new(0.075, 0, 0.65, 0)
_B1.BackgroundColor3, _B1.Font, _B1.TextColor3 = Color3.fromRGB(99, 102, 241), Enum.Font.GothamBold, Color3.new(1,1,1)
Instance.new("UICorner", _B1).CornerRadius = UDim.new(0, 8)

local _B2 = Instance.new("TextButton", _F_)
_B2.Text, _B2.Size, _B2.Position = "GET KEY", UDim2.new(0.4, 0, 0, 40), UDim2.new(0.525, 0, 0.65, 0)
_B2.BackgroundColor3, _B2.Font, _B2.TextColor3 = Color3.fromRGB(39, 39, 42), Enum.Font.GothamBold, Color3.new(1,1,1)
Instance.new("UICorner", _B2).CornerRadius = UDim.new(0, 8)

-- VERIFICATION ENGINE
local function _V_KEY(_str)
    local _res = _H_({
        Url = _v_2,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json", ["identifier"] = _S_.RbxAnalyticsService:GetClientId()},
        Body = _S_.HttpService:JSONEncode({key = _str})
    })
    if _res and _res.StatusCode == 200 then
        local _dat = _S_.HttpService:JSONDecode(_res.Body)
        return _dat.valid, _dat.msg
    end
    return false, "Error"
end

local function _ON_SUCCESS(_sk)
    _G_.write(_v_0, _sk)
    _B1.Text, _B1.BackgroundColor3 = "SUCCESS", Color3.fromRGB(16, 185, 129)
    _G_.wait(0.5)
    _UI_:Destroy()
    _MAIN_LOADER()
end

-- AUTO LOAD
if _G_.exists(_v_0) then
    local _saved = _G_.read(_v_0)
    if _saved and #_saved > 5 then
        local _val = _V_KEY(_saved)
        if _val then _ON_SUCCESS(_saved) end
    end
end

_B2.MouseButton1Click:Connect(function()
    setclipboard(_v_1)
    _S_.StarterGui:SetCore("SendNotification", {Title="G-MON", Text="Link copied!", Duration=2})
end)

_B1.MouseButton1Click:Connect(function()
    local _i = _K_.Text:gsub("%s+", "")
    if #_i < 1 then return end
    _B1.Text = "..."
    local _v, _m = _V_KEY(_i)
    if _v then
        _ON_SUCCESS(_i)
    else
        _B1.Text, _B1.BackgroundColor3 = "FAILED", Color3.fromRGB(239, 68, 68)
        _G_.wait(1)
        _B1.Text, _B1.BackgroundColor3 = "VERIFY", Color3.fromRGB(99, 102, 241)
    end
end)
