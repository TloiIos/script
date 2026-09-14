-- [[ THÀNH LỢI HUB - AOT REVOLUTION v16 - FLUENT DARK GUI ]]
-- Kill Aura độc lập (Titan + Sniper), Anti-Kick, Fluent Dark Theme

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============ CONFIG ============
_G.AutoKill = false
_G.AutoKillHuman = false
_G.KillAura = false
_G.KillAuraHitHuman = true
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

_G.AntiKick = true
_G.KickAvoidDelay = 0.5
_G.MaxKillPerMinute = 80
_G.MaxKillAuraPerMinute = 160
_G.RandomizeDelay = true

_G.AutoKillSpeedMode = "Nhanh"
_G.TweenSpeedMode = "Nhanh"
_G.DamageType = "Nape"

local DAMAGE_KEY = "&@&*&@&"

-- ============ TWEEN SPEED (FIX) ============
local TweenSpeedConfig = {
    ["Rất Chậm"]   = 60,
    ["Chậm"]       = 130,
    ["Bình Thường"]= 280,
    ["Nhanh"]      = 500,
    ["Rất Nhanh"]  = 900,
    ["Cực Nhanh"]  = 1800,
}
local TweenMinTime = {
    ["Rất Chậm"]   = 0.18,
    ["Chậm"]       = 0.12,
    ["Bình Thường"]= 0.08,
    ["Nhanh"]      = 0.05,
    ["Rất Nhanh"]  = 0.03,
    ["Cực Nhanh"]  = 0.015,
}
local function GetTweenTime(dist)
    local speed = TweenSpeedConfig[_G.TweenSpeedMode] or 500
    local minT = TweenMinTime[_G.TweenSpeedMode] or 0.05
    local t = dist / speed
    if t < minT then t = minT end
    if t > 0.6 then t = 0.6 end
    return t
end

-- ============ PATHS ============
local DamageEvent = ReplicatedStorage:FindFirstChild("DamageEvent")

local function GetMyEntity()
    local e = workspace:FindFirstChild("Entities")
    local p = e and e:FindFirstChild("Players")
    return p and p:FindFirstChild(LocalPlayer.Name)
end
local function GetMyOdm()
    local e = GetMyEntity()
    return e and e:FindFirstChild("Odm")
end
local function GetTitansFolder()
    local entities = workspace:FindFirstChild("Entities")
    return entities and entities:FindFirstChild("Titans")
end

-- ============ ANTI-KICK ============
local killHistory = {}
local auraHistory = {}

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

local function CanKillAuraNow()
    if not _G.AntiKick then return true end
    local now = tick()
    local newHistory = {}
    for _, t in ipairs(auraHistory) do
        if now - t < 60 then table.insert(newHistory, t) end
    end
    auraHistory = newHistory
    return #auraHistory < (_G.MaxKillAuraPerMinute or 160)
end
local function RecordAuraKill() table.insert(auraHistory, tick()) end

local function GetSmartDelay()
    local base = _G.KickAvoidDelay
    if _G.RandomizeDelay then
        local variance = base * 0.3
        base = base + (math.random() * variance * 2 - variance)
    end
    return base
end

-- ============ HACKS ============
local function ApplyHacks()
    local odm = GetMyOdm()
    if odm then
        if _G.OneHit then
            local d = odm:FindFirstChild("DamageMultiplier")
            if d and d:IsA("NumberValue") then pcall(function() d.Value = _G.DamageValue end) end
        end
        if _G.InfBlades then
            local b = odm:FindFirstChild("BladesAmmount")
            if b and b:IsA("IntValue") then
                pcall(function() b.Value = 99 end)
                local m = b:FindFirstChild("MaxBlades")
                if m then pcall(function() m.Value = 99 end) end
            end
            local dur = odm:FindFirstChild("BladeDurability")
            if dur then pcall(function() dur.Value = 99 end) end
        end
        if _G.InfGas then
            local g = odm:FindFirstChild("GasAmmount")
            if g then pcall(function() g.Value = 999 end) end
        end
    end
    if _G.InfGas then
        local e = GetMyEntity()
        if e then
            local rg = e:FindFirstChild("RemainingGas")
            if rg then pcall(function() rg.Value = 999 end) end
        end
    end
end

-- ============ DAMAGE ============
local function FireDamageEvent(targetModel, damageType)
    if not DamageEvent then return false end
    if not targetModel or not targetModel.Parent then return false end
    local hum = targetModel:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local imm = targetModel:FindFirstChild("TitanImmune")
    if imm and imm:IsA("BoolValue") and imm.Value then return false end
    local dmgType = damageType or _G.DamageType
    return pcall(function()
        DamageEvent:FireServer(dmgType, hum, DAMAGE_KEY, targetModel)
    end)
end

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

-- ============ FIND TITAN ============
local function GetNearestTitan()
    local tf = GetTitansFolder()
    if not tf then return nil end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local nearest, shortest = nil, math.huge
    for _, t in ipairs(tf:GetChildren()) do
        if t:IsA("Model") then
            local hum = t:FindFirstChildOfClass("Humanoid")
            local nape = t:FindFirstChild("Nape") or t:FindFirstChild("NapeHitbox") or t:FindFirstChild("Head")
            local root = t:FindFirstChild("HumanoidRootPart") or t.PrimaryPart
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
    return nearest
end

-- ============ FIND HUMAN ============
local function GetNearestHuman()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local nearest, shortest = nil, math.huge
    for _, m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") and m ~= LocalPlayer.Character then
            local hum = m:FindFirstChildOfClass("Humanoid")
            local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
            if hum and hum.Health > 0 and root then
                local isTitan = m.Parent and m.Parent.Name == "Titans"
                if not isTitan then
                    local hasMark = m:FindFirstChild("Sniper") or m:FindFirstChild("SoldierDamageHitbox") or m:FindFirstChildOfClass("Player")
                    if hasMark or (m.Parent and m.Parent.Name == "Players") or m.Name == "Sniper" then
                        local d = (root.Position - myRoot.Position).Magnitude
                        if d < shortest then
                            shortest = d
                            nearest = { Model = m, Humanoid = hum, Root = root, Dist = d }
                        end
                    end
                end
            end
        end
    end
    return nearest
end

-- ============ AIM ============
local aimTarget = nil
local function AimAtPart(part)
    if not part then return end
    pcall(function()
        local camera = workspace.CurrentCamera
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not camera or not myRoot then return end
        local eyePos = myRoot.Position + Vector3.new(0, 1.5, 0)
        local targetCF = CFrame.new(eyePos, part.Position)
        camera.CFrame = camera.CFrame:Lerp(targetCF, _G.CameraSmoothness)
    end)
end
local function UpdateAim()
    if not _G.AutoAim or not aimTarget or not aimTarget.Parent then return end
    local p = aimTarget:FindFirstChild("Nape") or aimTarget:FindFirstChild("NapeHitbox") or aimTarget:FindFirstChild("HumanoidRootPart") or aimTarget:FindFirstChild("Head")
    if p then AimAtPart(p) end
end
RunService:BindToRenderStep("AOT_Aim_v16", Enum.RenderPriority.Camera.Value - 1, UpdateAim)

-- ============ ANTI-GRAB ============
local function GetGrabbingTitan()
    local me = GetMyEntity()
    if not me then return nil end
    local gg = me:FindFirstChild("GettingGrabbed")
    local gb = me:FindFirstChild("GrabbedBy")
    if gg and gg:IsA("BoolValue") and gg.Value then
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
            if g then MultiHit(g, "Nape") end
        end
    end)
end

-- ============ LONG RANGE ============
local SavedPosition = nil
local lastLongRange = 0
local function SaveCurrentPosition()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myRoot then SavedPosition = myRoot.CFrame end
end
local function ReturnToSavedPosition()
    if not SavedPosition then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    pcall(function()
        local tw = TweenService:Create(myRoot, TweenInfo.new(0.15, Enum.EasingStyle.Linear), {CFrame = SavedPosition})
        tw:Play(); tw.Completed:Wait()
    end)
    SavedPosition = nil
end
local function LongRangeSlash(titan)
    if tick() - lastLongRange < 0.5 then return end
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
            local dist = (myRoot.Position - targetCF.Position).Magnitude
            local time = GetTweenTime(dist)
            local tw = TweenService:Create(myRoot, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = targetCF})
            tw:Play(); tw.Completed:Wait()
        end)
        MultiHit(titan.Model, "Nape"); RecordKill()
        task.wait(0.25); ReturnToSavedPosition()
    end)
end

-- ============ AUTO KILL TITAN ============
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
            if _G.AntiKick then
                local mul = (_G.AutoKillSpeedMode == "Siêu Nhanh") and 0.1 or 0.3
                baseDelay = math.max(baseDelay, GetSmartDelay() * mul)
            end
            task.wait(baseDelay)
            if not _G.AutoKill then autoKillRunning = false; break end
            if not CanKillNow() then task.wait(1); continue end
            local me = GetMyEntity()
            if me then
                local mg = me:FindFirstChild("GettingGrabbed")
                if mg and mg:IsA("BoolValue") and mg.Value then continue end
            end
            local titan = GetNearestTitan()
            if titan then
                aimTarget = titan.Model
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myRoot and titan.Dist <= 15 then
                    MultiHit(titan.Model, "Nape"); RecordKill()
                elseif _G.LongRange and titan.Dist <= 80 then
                    LongRangeSlash(titan)
                else
                    if myRoot then
                        local napeCF = titan.Nape.CFrame
                        local targetPos = napeCF.Position - (napeCF.LookVector * _G.BackDistance)
                        pcall(function()
                            local dist = (myRoot.Position - targetPos).Magnitude
                            local time = GetTweenTime(dist)
                            local tw = TweenService:Create(myRoot, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos, napeCF.Position)})
                            tw:Play(); tw.Completed:Wait()
                        end)
                        task.wait(0.02)
                        MultiHit(titan.Model, "Nape"); RecordKill()
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
            local baseDelay = 0.15
            if _G.AutoKillSpeedMode == "Siêu Chậm" then baseDelay = 0.6
            elseif _G.AutoKillSpeedMode == "Chậm" then baseDelay = 0.3
            elseif _G.AutoKillSpeedMode == "Siêu Nhanh" then baseDelay = 0.02 end
            task.wait(baseDelay)
            if not _G.AutoKillHuman then autoKillHumanRunning = false; break end
            local human = GetNearestHuman()
            if human then
                aimTarget = human.Model
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myRoot and human.Root then
                    local targetCF = human.Root.CFrame * CFrame.new(0, 0, 3)
                    pcall(function()
                        local dist = (myRoot.Position - targetCF.Position).Magnitude
                        if dist > 15 then
                            local time = GetTweenTime(dist)
                            local tw = TweenService:Create(myRoot, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = targetCF})
                            tw:Play(); tw.Completed:Wait()
                        else myRoot.CFrame = targetCF end
                    end)
                    task.wait(0.02)
                    MultiHit(human.Model, "Body"); RecordKill()
                end
            end
        end
    end)
end

-- ============ KILL AURA - LOGIC v9 (ĐỘC LẬP) ============
local killAuraRunning = false
local function KillAuraLoop()
    if killAuraRunning then return end
    killAuraRunning = true
    task.spawn(function()
        while killAuraRunning do
            local auraDelay
            if _G.AutoKillSpeedMode == "Siêu Nhanh" then auraDelay = 0.02
            elseif _G.AutoKillSpeedMode == "Nhanh" then auraDelay = 0.05
            elseif _G.AutoKillSpeedMode == "Chậm" then auraDelay = 0.15
            else auraDelay = 0.25 end
            
            task.wait(auraDelay)
            if not _G.KillAura then killAuraRunning = false; break end
            if not CanKillAuraNow() then task.wait(1); continue end
            
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myRoot then continue end
            
            -- 1. ĐÁNH TITAN TRONG BÁN KÍNH
            local tf = GetTitansFolder()
            if tf then
                for _, t in ipairs(tf:GetChildren()) do
                    if t:IsA("Model") then
                        local hum = t:FindFirstChildOfClass("Humanoid")
                        local nape = t:FindFirstChild("Nape") or t:FindFirstChild("NapeHitbox") or t:FindFirstChild("Head")
                        local root = t:FindFirstChild("HumanoidRootPart") or t.PrimaryPart
                        local imm = t:FindFirstChild("TitanImmune")
                        if hum and hum.Health > 0 and nape and root then
                            local skip = imm and imm:IsA("BoolValue") and imm.Value
                            if not skip then
                                local d = (root.Position - myRoot.Position).Magnitude
                                if d <= _G.AuraRadius then
                                    MultiHit(t, "Nape")
                                    RecordAuraKill()
                                end
                            end
                        end
                    end
                end
            end
            
            -- 2. ĐÁNH SNIPER/HUMAN TRONG BÁN KÍNH
            if _G.KillAuraHitHuman then
                for _, m in ipairs(workspace:GetDescendants()) do
                    if m:IsA("Model") and m ~= LocalPlayer.Character then
                        local hum = m:FindFirstChildOfClass("Humanoid")
                        local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
                        if hum and hum.Health > 0 and root then
                            local isTitan = m.Parent and m.Parent.Name == "Titans"
                            if not isTitan then
                                local hasMark = m:FindFirstChild("Sniper") 
                                    or m:FindFirstChild("SoldierDamageHitbox") 
                                    or m:FindFirstChildOfClass("Player")
                                local isPlayer = m.Parent and m.Parent.Name == "Players"
                                if hasMark or isPlayer or m.Name == "Sniper" then
                                    local d = (root.Position - myRoot.Position).Magnitude
                                    if d <= _G.AuraRadius then
                                        MultiHit(m, "Body")
                                        RecordAuraKill()
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- ============ MAIN LOOP ============
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
    
    if _G.AutoAim and not _G.AutoKill and not _G.AutoKillHuman and not _G.KillAura then
        local t = GetNearestTitan()
        aimTarget = t and t.Model or nil
    end
end)

-- =====================================================
-- ============ FLUENT GUI - DARK THEME ================
-- =====================================================
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Thành Lợi | AOT",
    SubTitle = "v16 Dark",
    TabWidth = 130,
    Size = UDim2.fromOffset(460, 360),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.End
})

-- Lưu reference ScreenGui của Fluent
local FluentScreenGui = nil

local function FindFluentScreenGui()
    local searchIn = {}
    pcall(function() table.insert(searchIn, CoreGui) end)
    pcall(function() table.insert(searchIn, LocalPlayer:WaitForChild("PlayerGui", 5)) end)
    for _, parent in ipairs(searchIn) do
        if parent then
            for _, gui in ipairs(parent:GetChildren()) do
                if gui:IsA("ScreenGui") then
                    local n = gui.Name:lower()
                    if n:find("fluent") or n:find("window") then
                        if #gui:GetChildren() > 0 then
                            return gui
                        end
                    end
                end
            end
        end
    end
    return nil
end

task.wait(0.8)
FluentScreenGui = FindFluentScreenGui()
if not FluentScreenGui then
    for i = 1, 10 do
        task.wait(0.3)
        FluentScreenGui = FindFluentScreenGui()
        if FluentScreenGui then break end
    end
end

local Tabs = {
    Main = Window:AddTab({ Title = "Farm", Icon = "⚔" }),
    Settings = Window:AddTab({ Title = "Cài Đặt", Icon = "⚙" }),
    Misc = Window:AddTab({ Title = "Khác", Icon = "🔧" })
}

-- ============ TAB MAIN ============
Tabs.Main:AddParagraph({
    Title = "🎯 AOT Revolution v16",
    Content = "Kill Aura độc lập - Đánh cả Titan + Sniper"
})

Tabs.Main:AddToggle("AutoKill", {
    Title = "Auto Kill Titan",
    Default = false
}):OnChanged(function(v) _G.AutoKill = v end)

Tabs.Main:AddToggle("AutoKillHuman", {
    Title = "Auto Kill Human/Sniper",
    Default = false
}):OnChanged(function(v) _G.AutoKillHuman = v end)

Tabs.Main:AddToggle("KillAura", {
    Title = "⚡ Kill Aura (Titan + Sniper)",
    Default = false
}):OnChanged(function(v) _G.KillAura = v end)

Tabs.Main:AddToggle("KillAuraHuman", {
    Title = "Kill Aura Đánh Sniper",
    Default = true
}):OnChanged(function(v) _G.KillAuraHitHuman = v end)

Tabs.Main:AddToggle("AntiGrab", {
    Title = "Anti-Grab",
    Default = true
}):OnChanged(function(v) _G.AntiGrab = v end)

Tabs.Main:AddToggle("AutoAim", {
    Title = "Auto Aim",
    Default = true
}):OnChanged(function(v) _G.AutoAim = v end)

Tabs.Main:AddToggle("LongRange", {
    Title = "Chém Xa (Long Range)",
    Default = true
}):OnChanged(function(v) _G.LongRange = v end)

-- ============ TAB SETTINGS ============
Tabs.Settings:AddSection("Combo Tốc Độ Tấn Công")
Tabs.Settings:AddDropdown("SpeedMode", {
    Title = "Tốc Độ Đánh",
    Values = {"Siêu Chậm", "Chậm", "Nhanh", "Siêu Nhanh"},
    Default = "Nhanh",
    Multi = false
}):OnChanged(function(v) _G.AutoKillSpeedMode = v end)

Tabs.Settings:AddSection("Combo Tốc Độ Bay (Tween)")
Tabs.Settings:AddDropdown("TweenSpeedMode", {
    Title = "Tween Speed",
    Description = "Chậm = bay chậm thật | Cực Nhanh = gần teleport",
    Values = {"Rất Chậm", "Chậm", "Bình Thường", "Nhanh", "Rất Nhanh", "Cực Nhanh"},
    Default = "Nhanh",
    Multi = false
}):OnChanged(function(v) _G.TweenSpeedMode = v end)

Tabs.Settings:AddSection("Chỉ Số")
Tabs.Settings:AddSlider("AuraRadius", {
    Title = "Bán Kính Aura",
    Default = 300, Min = 50, Max = 1000, Rounding = 1
}):OnChanged(function(v) _G.AuraRadius = v end)

Tabs.Settings:AddSlider("BackDistance", {
    Title = "Khoảng Cách Sau Lưng",
    Default = 4, Min = 1, Max = 20, Rounding = 0.5
}):OnChanged(function(v) _G.BackDistance = v end)

Tabs.Settings:AddSlider("HitCount", {
    Title = "Số Hit Mỗi Lần",
    Default = 3, Min = 1, Max = 20, Rounding = 1
}):OnChanged(function(v) _G.HitCount = v end)

Tabs.Settings:AddSlider("HitSpamDelay", {
    Title = "Delay Hit",
    Default = 0.04, Min = 0.01, Max = 0.5, Rounding = 0.01
}):OnChanged(function(v) _G.HitSpamDelay = v end)

Tabs.Settings:AddSlider("CameraSmoothness", {
    Title = "Độ Mượt Camera",
    Default = 0.5, Min = 0.1, Max = 1, Rounding = 0.1
}):OnChanged(function(v) _G.CameraSmoothness = v end)

-- ============ TAB MISC ============
Tabs.Misc:AddSection("Damage")
Tabs.Misc:AddSlider("DamageValue", {
    Title = "Damage Multiplier",
    Default = 99999, Min = 100, Max = 999999, Rounding = 1
}):OnChanged(function(v) _G.DamageValue = v end)

Tabs.Misc:AddDropdown("DamageType", {
    Title = "Loại Sát Thương",
    Values = {"Nape", "Body", "Head"},
    Default = "Nape",
    Multi = false
}):OnChanged(function(v) _G.DamageType = v end)

Tabs.Misc:AddSection("Anti-Kick")
Tabs.Misc:AddToggle("AntiKick", {
    Title = "Anti-Kick",
    Default = true
}):OnChanged(function(v) _G.AntiKick = v end)

Tabs.Misc:AddSlider("MaxKillPerMinute", {
    Title = "Max AutoKill/Phút",
    Default = 80, Min = 20, Max = 200, Rounding = 1
}):OnChanged(function(v) _G.MaxKillPerMinute = v end)

Tabs.Misc:AddSlider("MaxKillAura", {
    Title = "Max Kill Aura/Phút",
    Default = 160, Min = 20, Max = 500, Rounding = 1
}):OnChanged(function(v) _G.MaxKillAuraPerMinute = v end)

Tabs.Misc:AddSlider("KickAvoidDelay", {
    Title = "Kick Avoid Delay",
    Default = 0.5, Min = 0.1, Max = 3, Rounding = 0.1
}):OnChanged(function(v) _G.KickAvoidDelay = v end)

Tabs.Misc:AddToggle("RandomizeDelay", {
    Title = "Random Delay",
    Default = true
}):OnChanged(function(v) _G.RandomizeDelay = v end)

Tabs.Misc:AddSection("Hack")
Tabs.Misc:AddToggle("OneHit", {
    Title = "1-Hit Damage",
    Default = true
}):OnChanged(function(v) _G.OneHit = v end)

Tabs.Misc:AddToggle("InfGas", {
    Title = "Vô Hạn Gas",
    Default = true
}):OnChanged(function(v) _G.InfGas = v end)

Tabs.Misc:AddToggle("InfBlades", {
    Title = "Vô Hạn Kiếm",
    Default = true
}):OnChanged(function(v) _G.InfBlades = v end)

Tabs.Misc:AddSection("Actions")
Tabs.Misc:AddButton({
    Title = "🔄 Reset Kill History",
    Description = "Xóa lịch sử kill",
    Callback = function()
        killHistory = {}
        auraHistory = {}
        Fluent:Notify({ Title = "Thành Lợi Hub", Content = "Đã reset kill history!", Duration = 3 })
    end
})

Tabs.Misc:AddButton({
    Title = "🎯 Test Damage",
    Description = "Test damage lên titan gần nhất",
    Callback = function()
        local t = GetNearestTitan()
        if t then
            local hp1 = t.Humanoid.Health
            FireDamageEvent(t.Model)
            task.wait(0.2)
            local hp2 = t.Humanoid.Health
            print(string.format("Test '%s': HP %.1f → %.1f (dmg: %.1f)", _G.DamageType, hp1, hp2, hp1 - hp2))
        else
            print("Không có Titan")
        end
    end
})

Window:SelectTab(1)

-- =====================================================
-- ============ FLOATING BUTTON ========================
-- =====================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ThanhLoiHub_AOT_v16"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 9999
ScreenGui.IgnoreGuiInset = true

local parented = false
pcall(function() ScreenGui.Parent = CoreGui; parented = true end)
if not parented then
    pcall(function() ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
end

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "OpenButton"
ToggleButton.Size = UDim2.new(0, 55, 0, 55)
ToggleButton.Position = UDim2.new(0, 20, 0.4, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(140, 90, 220)
ToggleButton.Text = "AOT"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Active = true
ToggleButton.Draggable = true
ToggleButton.Parent = ScreenGui

local TCorner = Instance.new("UICorner")
TCorner.CornerRadius = UDim.new(1, 0)
TCorner.Parent = ToggleButton

local TStroke = Instance.new("UIStroke")
TStroke.Color = Color3.fromRGB(180, 130, 255)
TStroke.Thickness = 3
TStroke.Parent = ToggleButton

-- ============ FIX ẨN MENU ============
local guiVisible = true

local function ToggleFluentGUI()
    guiVisible = not guiVisible
    
    if not FluentScreenGui or not FluentScreenGui.Parent then
        FluentScreenGui = FindFluentScreenGui()
    end
    
    if FluentScreenGui then
        FluentScreenGui.Enabled = guiVisible
    else
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.End, false, game)
    end
    
    if guiVisible then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(140, 90, 220)
        ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        ToggleButton.Text = "AOT"
        TStroke.Color = Color3.fromRGB(180, 130, 255)
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        ToggleButton.TextColor3 = Color3.fromRGB(150, 150, 170)
        ToggleButton.Text = "❌"
        TStroke.Color = Color3.fromRGB(100, 100, 130)
    end
end

ToggleButton.MouseButton1Click:Connect(ToggleFluentGUI)

-- Đồng bộ khi dùng phím End
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.End then
        task.wait(0.1)
        if FluentScreenGui then
            guiVisible = FluentScreenGui.Enabled
            if guiVisible then
                ToggleButton.BackgroundColor3 = Color3.fromRGB(140, 90, 220)
                ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                ToggleButton.Text = "AOT"
                TStroke.Color = Color3.fromRGB(180, 130, 255)
            else
                ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
                ToggleButton.TextColor3 = Color3.fromRGB(150, 150, 170)
                ToggleButton.Text = "❌"
                TStroke.Color = Color3.fromRGB(100, 100, 130)
            end
        end
    end
end)

-- Auto-detect Fluent GUI
task.spawn(function()
    while task.wait(2) do
        if not FluentScreenGui or not FluentScreenGui.Parent then
            local found = FindFluentScreenGui()
            if found then
                FluentScreenGui = found
                FluentScreenGui.Enabled = guiVisible
            end
        end
    end
end)

print("✅ Thành Lợi Hub - AOT Revolution v16 - FLUENT DARK")
print("📌 GUI Dark Theme")
print("📌 Kill Aura độc lập (Titan + Sniper)")
print("📌 Nhấn nút AOT để bật/tắt GUI")
