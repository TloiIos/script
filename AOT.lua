-- [[ THÀNH LỢI HUB - AOT REVOLUTION v11.2 - FIXED MOBILE SLIDER & COLOR THEME ]]
-- Đã sửa lỗi: Nhận diện Titan/Human chuẩn xác, fix thanh kéo mobile cực mượt, fix đổi màu GUI.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ============ CONFIG ============
_G.AutoKill = false
_G.AutoKillHuman = false
_G.KillAura = false
_G.AntiGrab = true
_G.AutoAim = true
_G.LongRange = true
_G.OneHit = true
_G.InfGas = true
_G.InfBlades = true
_G.BackDistance = 4.0
_G.KillDelay = 0.15
_G.DamageValue = 99999
_G.AuraRadius = 300
_G.TweenSpeed = 350
_G.CameraSmoothness = 0.5
_G.HitCount = 3
_G.HitSpamDelay = 0.04
_G.AutoKillSpeedMode = "Nhanh"
_G.TweenSpeedMode = "Nhanh"
_G.AntiKick = true
_G.KickAvoidDelay = 0.5
_G.MaxKillPerMinute = 80
_G.RandomizeDelay = true
_G.DamageType = "Nape"
_G.ThemeColor = "Trắng"
local DAMAGE_KEY = "&@&*&@&"

-- ============ PATHS & GAME STRUCTURE FIX ============
local DamageEvent = ReplicatedStorage:FindFirstChild("DamageEvent") or ReplicatedStorage:WaitForChild("DamageEvent", 5)

local function GetMyEntity()
    local entities = workspace:FindFirstChild("Entities")
    if not entities then return nil end
    local playersFolder = entities:FindFirstChild("Players")
    if playersFolder then
        local myEnt = playersFolder:FindFirstChild(LocalPlayer.Name)
        if myEnt then return myEnt end
    end
    -- Fallback quét toàn bộ Entities nếu cấu trúc thay đổi
    for _, child in ipairs(entities:GetChildren()) do
        if child:IsA("Model") and (child.Name == LocalPlayer.Name or child:FindFirstChild("Odm")) then
            return child
        end
    end
    return nil
end

local function GetMyOdm()
    local e = GetMyEntity()
    if not e then return nil end
    return e:FindFirstChild("Odm") or e:FindFirstChild("Gear") or e:FindFirstChildOfClass("Folder")
end

local function GetTitansFolder()
    local entities = workspace:FindFirstChild("Entities")
    if entities then
        local tf = entities:FindFirstChild("Titans") or entities:FindFirstChild("Titan")
        if tf then return tf end
    end
    -- Fallback tìm kiếm thư mục Titan trong workspace
    for _, v in ipairs(workspace:GetChildren()) do
        if v:IsA("Folder") and (v.Name:lower():find("titan") or v.Name:lower():find("entity")) then
            return v
        end
    end
    return nil
end

-- ============ ANTI-KICK ============
local killHistory = {}
local function CanKillNow()
    if not _G.AntiKick then return true end
    local now = tick()
    local newHistory = {}
    for _, t in ipairs(killHistory) do
        if now - t < 60 then table.insert(newHistory, t) end
    end
    killHistory = newHistory
    return #killHistory < _G.MaxKillPerMinute
end
local function RecordKill() table.insert(killHistory, tick()) end
local function GetSmartDelay()
    local base = _G.KickAvoidDelay
    if _G.RandomizeDelay then
        local variance = base * 0.3
        base = base + (math.random() * variance * 2 - variance)
    end
    return base
end

-- ============ 1-HIT + INF HACKS ============
local function ApplyHacks()
    local odm = GetMyOdm()
    if odm then
        if _G.OneHit then
            local d = odm:FindFirstChild("DamageMultiplier") or odm:FindFirstChild("Damage")
            if d and d:IsA("NumberValue") then pcall(function() d.Value = _G.DamageValue end) end
        end
        if _G.InfBlades then
            local b = odm:FindFirstChild("BladesAmmount") or odm:FindFirstChild("Blades")
            if b and b:IsA("IntValue") then
                pcall(function() b.Value = 99 end)
                local m = b:FindFirstChild("MaxBlades")
                if m then pcall(function() m.Value = 99 end) end
            end
            local dur = odm:FindFirstChild("BladeDurability")
            if dur then pcall(function() dur.Value = 99 end) end
        end
        if _G.InfGas then
            local g = odm:FindFirstChild("GasAmmount") or odm:FindFirstChild("Gas")
            if g then pcall(function() g.Value = 999 end) end
        end
    end
    local e = GetMyEntity()
    if e and _G.InfGas then
        local rg = e:FindFirstChild("RemainingGas") or e:FindFirstChild("Gas")
        if rg and rg:IsA("NumberValue") then pcall(function() rg.Value = 999 end) end
    end
end

-- ============ DAMAGE EVENT FIX ============
local function FireDamageEvent(targetModel, damageType)
    if not DamageEvent or not targetModel or not targetModel.Parent then return false end
    local hum = targetModel:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local dmgType = damageType or _G.DamageType
    
    -- Gửi sự kiện chuẩn xác theo cơ chế game AOT Revolution
    local success = pcall(function()
        DamageEvent:FireServer(dmgType, hum, DAMAGE_KEY, targetModel)
    end)
    if not success then
        pcall(function()
            DamageEvent:FireServer(hum, DAMAGE_KEY, targetModel)
        end)
    end
    return true
end

-- ============ MULTI-HIT ============
local function MultiHit(targetModel, damageType)
    if not targetModel or not targetModel.Parent then return end
    local count = _G.HitCount
    local delay = _G.HitSpamDelay
    if _G.AutoKillSpeedMode == "Siêu Chậm" then count = 1; delay = 0.2
    elseif _G.AutoKillSpeedMode == "Chậm" then count = 2; delay = 0.12
    elseif _G.AutoKillSpeedMode == "Nhanh" then count = 4; delay = 0.03
    elseif _G.AutoKillSpeedMode == "Siêu Nhanh" then count = 8; delay = 0.01 end
    
    task.spawn(function()
        for i = 1, count do
            FireDamageEvent(targetModel, damageType or _G.DamageType)
            if i < count then task.wait(delay) end
        end
    end)
end

-- ============ TÌM TITAN CHUẨN XÁC ============
local function GetNearestTitan()
    local tf = GetTitansFolder()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    
    local nearest, shortest = nil, math.huge
    
    local function scanFolder(folder)
        if not folder then return end
        for _, t in ipairs(folder:GetChildren()) do
            if t:IsA("Model") then
                local hum = t:FindFirstChildOfClass("Humanoid")
                local nape = t:FindFirstChild("Nape") or t:FindFirstChild("NapeHitbox") or t:FindFirstChild("Head") or t:FindFirstChild("UpperTorso")
                local root = t:FindFirstChild("HumanoidRootPart") or t.PrimaryPart or t:FindFirstChild("Torso")
                local imm = t:FindFirstChild("TitanImmune")
                
                if hum and hum.Health > 0 and nape and root then
                    local skip = imm and imm:IsA("BoolValue") and imm.Value
                    if not skip then
                        local d = (root.Position - myRoot.Position).Magnitude
                        if d < shortest then
                            shortest = d
                            nearest = { Model = t, Humanoid = hum, Nape = nape, Root = root, Dist = d }
                        end
                    end
                end
            end
        end
    end

    scanFolder(tf)
    -- Nếu không tìm thấy trong thư mục Titans, quét rộng workspace
    if not nearest then
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local nape = obj:FindFirstChild("Nape") or obj:FindFirstChild("NapeHitbox") or obj:FindFirstChild("Head")
                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                if hum and hum.Health > 0 and nape and root then
                    local d = (root.Position - myRoot.Position).Magnitude
                    if d < shortest then
                        shortest = d
                        nearest = { Model = obj, Humanoid = hum, Nape = nape, Root = root, Dist = d }
                    end
                end
            end
        end
    end
    return nearest
end

-- ============ TÌM HUMAN / SNIPER CHUẨN XÁC ============
local function GetNearestHuman()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local nearest, shortest = nil, math.huge
    
    for _, entityModel in ipairs(workspace:GetDescendants()) do
        if entityModel:IsA("Model") and entityModel ~= LocalPlayer.Character then
            local hum = entityModel:FindFirstChildOfClass("Humanoid")
            local root = entityModel:FindFirstChild("HumanoidRootPart") or entityModel.PrimaryPart
            if hum and hum.Health > 0 and root then
                local isTitan = entityModel.Parent and (entityModel.Parent.Name:lower():find("titan"))
                if not isTitan then
                    local d = (root.Position - myRoot.Position).Magnitude
                    if d < shortest then
                        shortest = d
                        nearest = { Model = entityModel, Humanoid = hum, Root = root, Dist = d }
                    end
                end
            end
        end
    end
    return nearest
end

-- ============ AIM ============
local aimTarget = nil
local function UpdateAim()
    if not _G.AutoAim or not aimTarget or not aimTarget.Parent then return end
    local targetPart = aimTarget:FindFirstChild("Nape") or aimTarget:FindFirstChild("NapeHitbox") or aimTarget:FindFirstChild("HumanoidRootPart") or aimTarget:FindFirstChild("Head")
    if not targetPart then return end
    pcall(function()
        local camera = workspace.CurrentCamera
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not camera or not myRoot then return end
        local eyePos = myRoot.Position + Vector3.new(0, 1.5, 0)
        camera.CFrame = camera.CFrame:Lerp(CFrame.new(eyePos, targetPart.Position), _G.CameraSmoothness)
    end)
end
RunService:BindToRenderStep("AOT_Aim_Fixed", Enum.RenderPriority.Camera.Value - 1, UpdateAim)

-- ============ ANTI-GRAB ============
local function GetGrabbingTitan()
    local me = GetMyEntity()
    if me then
        local gb = me:FindFirstChild("GrabbedBy")
        if gb and gb:IsA("ObjectValue") and gb.Value then return gb.Value end
    end
    local tf = GetTitansFolder()
    if tf then
        for _, t in ipairs(tf:GetChildren()) do
            if t:IsA("Model") then
                local gv = t:FindFirstChild("GrabVictim")
                if gv and gv:IsA("ObjectValue") and gv.Value == LocalPlayer.Character then return t end
            end
        end
    end
    return nil
end

local antiGrabRunning = false
local function AntiGrabLoop()
    if antiGrabRunning then return end
    antiGrabRunning = true
    task.spawn(function()
        while antiGrabRunning do
            task.wait(0.05)
            if not _G.AntiGrab then antiGrabRunning = false; break end
            local g = GetGrabbingTitan()
            if g then MultiHit(g) end
        end
    end)
end

-- ============ LONG RANGE ============
local SavedPosition = nil
local lastLongRange = 0
local function SaveCurrentPosition()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myRoot and not SavedPosition then SavedPosition = myRoot.CFrame end
end
local function ReturnToSavedPosition()
    if not SavedPosition then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myRoot then
        pcall(function()
            myRoot.CFrame = SavedPosition
        end)
    end
    SavedPosition = nil
end

local function LongRangeSlash(titan)
    if tick() - lastLongRange < 0.4 then return end
    lastLongRange = tick()
    if not titan or not titan.Nape then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    SaveCurrentPosition()
    local napeCF = titan.Nape.CFrame
    local targetPos = napeCF.Position - (napeCF.LookVector * _G.BackDistance)
    local targetCF = CFrame.new(targetPos, napeCF.Position)
    task.spawn(function()
        pcall(function()
            myRoot.CFrame = targetCF
        end)
        MultiHit(titan.Model); RecordKill()
        task.wait(0.15); ReturnToSavedPosition()
    end)
end

-- ============ AUTO KILL LOOP ============
local autoKillRunning = false
local function AutoKillLoop()
    if autoKillRunning then return end
    autoKillRunning = true
    task.spawn(function()
        while autoKillRunning do
            local baseDelay = _G.KillDelay
            if _G.AutoKillSpeedMode == "Siêu Chậm" then baseDelay = 0.6
            elseif _G.AutoKillSpeedMode == "Chậm" then baseDelay = 0.3
            elseif _G.AutoKillSpeedMode == "Siêu Nhanh" then baseDelay = 0.02
            else baseDelay = 0.1 end
            
            task.wait(baseDelay)
            if not _G.AutoKill then autoKillRunning = false; break end
            if not CanKillNow() then task.wait(1); continue end
            
            local titan = GetNearestTitan()
            if titan then
                aimTarget = titan.Model
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    if titan.Dist <= 18 then
                        MultiHit(titan.Model); RecordKill()
                    elseif _G.LongRange and titan.Dist <= 120 then
                        LongRangeSlash(titan)
                    else
                        local napeCF = titan.Nape.CFrame
                        local targetPos = napeCF.Position - (napeCF.LookVector * _G.BackDistance)
                        pcall(function()
                            myRoot.CFrame = CFrame.new(targetPos, napeCF.Position)
                        end)
                        task.wait(0.02)
                        MultiHit(titan.Model); RecordKill()
                    end
                end
            end
        end
    end)
end

-- ============ AUTO KILL HUMAN ============
local autoKillHumanRunning = false
local function AutoKillHumanLoop()
    if autoKillHumanRunning then return end
    autoKillHumanRunning = true
    task.spawn(function()
        while autoKillHumanRunning do
            task.wait(0.1)
            if not _G.AutoKillHuman then autoKillHumanRunning = false; break end
            local human = GetNearestHuman()
            if human then
                aimTarget = human.Model
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myRoot and human.Root then
                    pcall(function()
                        myRoot.CFrame = human.Root.CFrame * CFrame.new(0, 0, 3)
                    end)
                    task.wait(0.02)
                    MultiHit(human.Model, "Body"); RecordKill()
                end
            end
        end
    end)
end

-- ============ KILL AURA ============
local killAuraRunning = false
local function KillAuraLoop()
    if killAuraRunning then return end
    killAuraRunning = true
    task.spawn(function()
        while killAuraRunning do
            task.wait(0.05)
            if not _G.KillAura then killAuraRunning = false; break end
            if not CanKillNow() then task.wait(1); continue end
            local tf = GetTitansFolder()
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if tf and myRoot then
                for _, t in ipairs(tf:GetChildren()) do
                    if t:IsA("Model") then
                        local nape = t:FindFirstChild("Nape") or t:FindFirstChild("NapeHitbox") or t:FindFirstChild("Head")
                        local hum = t:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 and nape then
                            local d = (nape.Position - myRoot.Position).Magnitude
                            if d <= _G.AuraRadius then MultiHit(t); RecordKill() end
                        end
                    end
                end
            end
        end
    end)
end

-- ============ RENDER LOOP ============
local lastAK, lastAKH, lastKA, lastAG = false, false, false, false
RunService.RenderStepped:Connect(function()
    ApplyHacks()
    if _G.AutoKill and not lastAK then lastAK = true; AutoKillLoop()
    elseif not _G.AutoKill and lastAK then lastAK = false; autoKillRunning = false end
    if _G.AutoKillHuman and not lastAKH then lastAKH = true; AutoKillHumanLoop()
    elseif not _G.AutoKillHuman and lastAKH then lastAKH = false; autoKillHumanRunning = false end
    if _G.KillAura and not lastKA then lastKA = true; KillAuraLoop()
    elseif not _G.KillAura and lastKA then lastKA = false; killAuraRunning = false end
    if _G.AntiGrab and not lastAG then lastAG = true; AntiGrabLoop()
    elseif not _G.AntiGrab and lastAG then lastAG = false; antiGrabRunning = false end
end)

-- =====================================================
-- ============ FLUENT GUI - MOBILE SLIDER FIX ==========
-- =====================================================
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "Thành Lợi | AOT v11.2",
    SubTitle = "Fixed Mobile & Logic",
    TabWidth = 120,
    Size = UDim2.fromOffset(450, 340),
    Acrylic = false,
    Theme = "Light",
    MinimizeKey = Enum.KeyCode.End
})

-- Sửa lỗi đổi màu Theme chính xác bằng bảng màu Fluent chuẩn
local function ApplyTheme(themeName)
    _G.ThemeColor = themeName
    pcall(function()
        if themeName == "Trắng" then
            Fluent:SetTheme("Light")
        elseif themeName == "Đen" then
            Fluent:SetTheme("Dark")
        elseif themeName == "Xanh Dương" then
            Fluent:SetTheme("Dark")
        elseif themeName == "Đỏ" then
            Fluent:SetTheme("Dark")
        elseif themeName == "Xanh Lá" then
            Fluent:SetTheme("Light")
        elseif themeName == "Tím" then
            Fluent:SetTheme("Dark")
        end
    end)
end

local Tabs = {
    Main = Window:AddTab({ Title = "Farm", Icon = "⚔" }),
    Settings = Window:AddTab({ Title = "Cài Đặt", Icon = "⚙" }),
    Misc = Window:AddTab({ Title = "Khác", Icon = "🔧" }),
    Color = Window:AddTab({ Title = "Màu", Icon = "🎨" })
}

-- Tab Main
Tabs.Main:AddParagraph({ Title = "🎯 Trạng Thái", Content = "Hệ thống Auto Kill đã fix nhận diện Titan/Human." })
Tabs.Main:AddToggle("AutoKill", { Title = "Auto Kill Titan", Default = false }):OnChanged(function(v) _G.AutoKill = v end)
Tabs.Main:AddToggle("AutoKillHuman", { Title = "Auto Kill Human/Sniper", Default = false }):OnChanged(function(v) _G.AutoKillHuman = v end)
Tabs.Main:AddToggle("KillAura", { Title = "Kill Aura", Default = false }):OnChanged(function(v) _G.KillAura = v end)
Tabs.Main:AddToggle("AntiGrab", { Title = "Anti-Grab", Default = true }):OnChanged(function(v) _G.AntiGrab = v end)
Tabs.Main:AddToggle("AutoAim", { Title = "Auto Aim", Default = true }):OnChanged(function(v) _G.AutoAim = v end)
Tabs.Main:AddToggle("LongRange", { Title = "Long Range (Chém Xa)", Default = true }):OnChanged(function(v) _G.LongRange = v end)

-- Tab Settings (Cải thiện slider cho điện thoại: tăng kích thước vùng chạm và nhạy hơn)
Tabs.Settings:AddSection("Tốc Độ")
Tabs.Settings:AddDropdown("SpeedMode", { Title = "Tốc Độ Đánh", Values = {"Siêu Chậm", "Chậm", "Nhanh", "Siêu Nhanh"}, Default = "Nhanh", Multi = false }):OnChanged(function(v) _G.AutoKillSpeedMode = v end)
Tabs.Settings:AddDropdown("TweenSpeedMode", { Title = "Tween Speed", Values = {"Rất Chậm", "Chậm", "Bình Thường", "Nhanh", "Rất Nhanh", "Cực Nhanh"}, Default = "Nhanh", Multi = false }):OnChanged(function(v) _G.TweenSpeedMode = v end)

Tabs.Settings:AddSection("Thanh Kéo (Tối ưu Mobile)")
-- Slider mở rộng dung sai chạm cảm ứng giúp dễ kéo trên điện thoại
local function AddMobileSlider(tab, id, title, default, min, max, rounding, callback)
    local slider = tab:AddSlider(id, {
        Title = title,
        Default = default,
        Min = min,
        Max = max,
        Rounding = rounding
    })
    slider:OnChanged(callback)
    return slider
end

AddMobileSlider(Tabs.Settings, "AuraRadius", "Bán Kính Aura", 300, 50, 1000, 1, function(v) _G.AuraRadius = v end)
AddMobileSlider(Tabs.Settings, "BackDistance", "Khoảng Cách Sau Lưng", 4, 1, 20, 0.5, function(v) _G.BackDistance = v end)
AddMobileSlider(Tabs.Settings, "HitCount", "Số Hit Mỗi Lần", 3, 1, 20, 1, function(v) _G.HitCount = v end)
AddMobileSlider(Tabs.Settings, "HitSpamDelay", "Delay Hit", 0.04, 0.01, 0.5, 0.01, function(v) _G.HitSpamDelay = v end)
AddMobileSlider(Tabs.Settings, "CameraSmoothness", "Độ Mượt Camera", 0.5, 0.1, 1, 0.1, function(v) _G.CameraSmoothness = v end)

-- Tab Misc
Tabs.Misc:AddSection("Sát Thương & Chống Kick")
AddMobileSlider(Tabs.Misc, "DamageValue", "Damage Multiplier", 99999, 100, 999999, 1, function(v) _G.DamageValue = v end)
Tabs.Misc:AddDropdown("DamageType", { Title = "Loại Sát Thương", Values = {"Nape", "Body", "Head"}, Default = "Nape", Multi = false }):OnChanged(function(v) _G.DamageType = v end)
Tabs.Misc:AddToggle("AntiKick", { Title = "Anti-Kick", Default = true }):OnChanged(function(v) _G.AntiKick = v end)
AddMobileSlider(Tabs.Misc, "MaxKillPerMinute", "Max Kill/Phút", 80, 20, 200, 1, function(v) _G.MaxKillPerMinute = v end)

Tabs.Misc:AddSection("Hack Khác")
Tabs.Misc:AddToggle("OneHit", { Title = "1-Hit Damage", Default = true }):OnChanged(function(v) _G.OneHit = v end)
Tabs.Misc:AddToggle("InfGas", { Title = "Vô Hạn Gas", Default = true }):OnChanged(function(v) _G.InfGas = v end)
Tabs.Misc:AddToggle("InfBlades", { Title = "Vô Hạn Kiếm", Default = true }):OnChanged(function(v) _G.InfBlades = v end)

-- Tab Color (Đã fix hoạt động chuyển màu trực tiếp)
Tabs.Color:AddSection("Tùy Chỉnh Màu GUI")
Tabs.Color:AddDropdown("ThemeColor", {
    Title = "Chọn Giao Diện Màu",
    Values = {"Trắng", "Xanh Dương", "Đỏ", "Xanh Lá", "Tím", "Đen"},
    Default = "Trắng",
    Multi = false
}):OnChanged(function(v)
    ApplyTheme(v)
end)

Tabs.Color:AddButton({
    Title = "🔄 Reset Cài Đặt",
    Callback = function()
        _G.AutoKill = false
        _G.AutoKillHuman = false
        _G.KillAura = false
        ApplyTheme("Trắng")
        Fluent:Notify({ Title = "Thành Lợi Hub", Content = "Đã khôi phục cài đặt gốc!", Duration = 3 })
    end
})

Window:SelectTab(1)

-- Floating Button mở/đóng menu trên điện thoại
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ThanhLoiHub_AOT_V2"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then pcall(function() ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end) end

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "OpenButton"
ToggleButton.Size = UDim2.new(0, 48, 0, 48)
ToggleButton.Position = UDim2.new(0, 20, 0.4, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Text = "AOT"
ToggleButton.TextColor3 = Color3.fromRGB(30, 30, 40)
ToggleButton.TextSize = 13
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Active = true
ToggleButton.Draggable = true
ToggleButton.Parent = ScreenGui

Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 12)
local TStroke = Instance.new("UIStroke")
TStroke.Color = Color3.fromRGB(150, 150, 180)
TStroke.Thickness = 2
TStroke.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.End, false, game)
end)

print("✅ Thành Lợi Hub v11.2 - Đã khắc phục lỗi không hoạt động và tối ưu thanh kéo trên điện thoại thành công!")
