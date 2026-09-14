-- [[ THÀNH LỢI HUB - AOT REVOLUTION v16 - DARK GUI + KILL AURA v9 LOGIC ]]
-- GUI đen custom, Kill Aura độc lập (Titan + Sniper), Anti-Kick

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

-- ============ TWEEN SPEED CONFIG ============
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

-- ============ 1-HIT + INF ============
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

-- ============ DAMAGE EVENT ============
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

-- ============ TÌM TITAN ============
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

-- ============ TÌM HUMAN ============
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

-- ============ KILL AURA - LOGIC v9 (ĐỘC LẬP, ĐÁNH CẢ TITAN + SNIPER) ============
local killAuraRunning = false

local function KillAuraLoop()
    if killAuraRunning then return end
    killAuraRunning = true
    task.spawn(function()
        while killAuraRunning do
            -- Delay động theo speed mode
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
-- ============ CUSTOM DARK GUI =======================
-- =====================================================

-- Bảng màu Dark
local Theme = {
    Background = Color3.fromRGB(18, 18, 24),
    BackgroundSecondary = Color3.fromRGB(28, 28, 38),
    BackgroundTertiary = Color3.fromRGB(38, 38, 52),
    Text = Color3.fromRGB(240, 240, 250),
    SubText = Color3.fromRGB(150, 150, 170),
    Accent = Color3.fromRGB(140, 90, 220),
    AccentSecondary = Color3.fromRGB(180, 130, 255),
    Success = Color3.fromRGB(0, 200, 100),
    Danger = Color3.fromRGB(220, 60, 60),
    Warning = Color3.fromRGB(220, 180, 50),
    Outline = Color3.fromRGB(60, 60, 80),
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ThanhLoiHub_AOT_v16"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 9999

local parented = false
pcall(function() ScreenGui.Parent = game:GetService("CoreGui"); parented = true end)
if not parented then
    pcall(function() ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
end

-- ============ MAIN FRAME ============
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 420, 0, 520)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -260)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.Accent
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- ============ TITLE BAR ============
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Theme.BackgroundSecondary
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

-- Che phần dưới của title bar để không bo góc
local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 12)
TitleFix.Position = UDim2.new(0, 0, 1, -12)
TitleFix.BackgroundColor3 = Theme.BackgroundSecondary
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -120, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚔️ THÀNH LỢI | AOT v16"
Title.TextColor3 = Theme.AccentSecondary
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Status indicator
local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.Position = UDim2.new(1, -100, 0.5, -4)
StatusDot.BackgroundColor3 = Theme.Success
StatusDot.BorderSizePixel = 0
StatusDot.Parent = TitleBar
local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(1, 0)
StatusCorner.Parent = StatusDot

-- Minimize button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -75, 0, 8)
MinimizeBtn.BackgroundColor3 = Theme.Warning
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 16
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Parent = TitleBar
local MCorner = Instance.new("UICorner")
MCorner.CornerRadius = UDim.new(0, 8)
MCorner.Parent = MinimizeBtn

-- Hide/Show button
local HideBtn = Instance.new("TextButton")
HideBtn.Size = UDim2.new(0, 30, 0, 30)
HideBtn.Position = UDim2.new(1, -40, 0, 8)
HideBtn.BackgroundColor3 = Theme.Danger
HideBtn.Text = "✕"
HideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HideBtn.TextSize = 14
HideBtn.Font = Enum.Font.GothamBold
HideBtn.BorderSizePixel = 0
HideBtn.Parent = TitleBar
local HCorner = Instance.new("UICorner")
HCorner.CornerRadius = UDim.new(0, 8)
HCorner.Parent = HideBtn

-- ============ TAB BAR ============
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 35)
TabBar.Position = UDim2.new(0, 10, 0, 55)
TabBar.BackgroundColor3 = Theme.BackgroundSecondary
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame
local TabBarCorner = Instance.new("UICorner")
TabBarCorner.CornerRadius = UDim.new(0, 8)
TabBarCorner.Parent = TabBar

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 4)
TabLayout.Parent = TabBar

local TabPadding = Instance.new("UIPadding")
TabPadding.PaddingLeft = UDim.new(0, 4)
TabPadding.PaddingTop = UDim.new(0, 4)
TabPadding.PaddingBottom = UDim.new(0, 4)
TabPadding.Parent = TabBar

-- ============ CONTENT ============
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -20, 1, -155)
Content.Position = UDim2.new(0, 10, 0, 100)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = Theme.Accent
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.Parent = Content

-- ============ HELPER FUNCTIONS ============
local function CreateSection(text)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 28)
    section.BackgroundTransparency = 1
    section.Parent = Content
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "▸ " .. text
    label.TextColor3 = Theme.AccentSecondary
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = section
    
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 1, -1)
    line.BackgroundColor3 = Theme.Outline
    line.BorderSizePixel = 0
    line.Parent = section
end

local function CreateToggle(name, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Theme.BackgroundSecondary
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.Parent = Content
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn
    
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 40, 0, 22)
    indicator.Position = UDim2.new(1, -52, 0.5, -11)
    indicator.BackgroundColor3 = default and Theme.Success or Theme.BackgroundTertiary
    indicator.BorderSizePixel = 0
    indicator.Parent = btn
    local iCorner = Instance.new("UICorner")
    iCorner.CornerRadius = UDim.new(1, 0)
    iCorner.Parent = indicator
    
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 18, 0, 18)
    dot.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    dot.Parent = indicator
    local dCorner = Instance.new("UICorner")
    dCorner.CornerRadius = UDim.new(1, 0)
    dCorner.Parent = dot
    
    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        indicator.BackgroundColor3 = state and Theme.Success or Theme.BackgroundTertiary
        dot.Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        if callback then callback(state) end
    end)
end

local function CreateSlider(name, min, max, default, suffix, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 58)
    frame.BackgroundColor3 = Theme.BackgroundSecondary
    frame.BorderSizePixel = 0
    frame.Parent = Content
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 12, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. tostring(default) .. (suffix or "")
    label.TextColor3 = Theme.Text
    label.TextSize = 12
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    -- Hitbox lớn hơn cho mobile
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -24, 0, 14)
    sliderBg.Position = UDim2.new(0, 12, 0, 34)
    sliderBg.BackgroundColor3 = Theme.BackgroundTertiary
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = frame
    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(1, 0)
    sCorner.Parent = sliderBg
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = sliderBg
    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(1, 0)
    fCorner.Parent = fill
    
    -- Knob
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new((default - min) / (max - min), -10, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 5
    knob.Parent = sliderBg
    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent = knob
    local kStroke = Instance.new("UIStroke")
    kStroke.Color = Theme.Accent
    kStroke.Thickness = 2
    kStroke.Parent = knob
    
    local dragging = false
    
    local function updateFromPos(x)
        local rel = math.clamp((x - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local value = min + (max - min) * rel
        local step = (max - min) / 100
        value = math.floor(value / step + 0.5) * step
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, -10, 0.5, -10)
        label.Text = name .. ": " .. tostring(math.floor(value * 100) / 100) .. (suffix or "")
        if callback then callback(math.floor(value * 100) / 100) end
    end
    
    -- FIX: Slider dễ kéo trên mobile - dùng cả sliderBg và knob
    local function startDrag(input)
        dragging = true
        updateFromPos(input.Position.X)
    end
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
            or input.UserInputType == Enum.UserInputType.Touch then
            startDrag(input)
        end
    end)
    
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
            or input.UserInputType == Enum.UserInputType.Touch then
            startDrag(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement 
            or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromPos(input.Position.X)
        end
    end)
end

local function CreateDropdown(name, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 38)
    frame.BackgroundColor3 = Theme.BackgroundSecondary
    frame.BorderSizePixel = 0
    frame.Parent = Content
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -120, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local currentBtn = Instance.new("TextButton")
    currentBtn.Size = UDim2.new(0, 100, 0, 26)
    currentBtn.Position = UDim2.new(1, -110, 0.5, -13)
    currentBtn.BackgroundColor3 = Theme.BackgroundTertiary
    currentBtn.Text = default
    currentBtn.TextColor3 = Theme.AccentSecondary
    currentBtn.TextSize = 12
    currentBtn.Font = Enum.Font.GothamMedium
    currentBtn.BorderSizePixel = 0
    currentBtn.Parent = frame
    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 6)
    cCorner.Parent = currentBtn
    
    -- Dropdown list (tạo sẵn, ẩn)
    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(1, 0, 0, #options * 32 + 8)
    listFrame.BackgroundColor3 = Theme.BackgroundTertiary
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.ZIndex = 10
    listFrame.Parent = frame
    local lCorner = Instance.new("UICorner")
    lCorner.CornerRadius = UDim.new(0, 8)
    lCorner.Parent = listFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = listFrame
    local listPadding = Instance.new("UIPadding")
    listPadding.PaddingTop = UDim.new(0, 4)
    listPadding.PaddingLeft = UDim.new(0, 4)
    listPadding.PaddingRight = UDim.new(0, 4)
    listPadding.Parent = listFrame
    
    local open = false
    currentBtn.MouseButton1Click:Connect(function()
        open = not open
        listFrame.Visible = open
        if open then
            listFrame.Position = UDim2.new(0, 0, 1, 4)
        end
    end)
    
    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 28)
        optBtn.BackgroundColor3 = Theme.BackgroundSecondary
        optBtn.Text = opt
        optBtn.TextColor3 = Theme.Text
        optBtn.TextSize = 12
        optBtn.Font = Enum.Font.GothamMedium
        optBtn.BorderSizePixel = 0
        optBtn.ZIndex = 11
        optBtn.Parent = listFrame
        local oCorner = Instance.new("UICorner")
        oCorner.CornerRadius = UDim.new(0, 6)
        oCorner.Parent = optBtn
        
        optBtn.MouseButton1Click:Connect(function()
            currentBtn.Text = opt
            open = false
            listFrame.Visible = false
            if callback then callback(opt) end
        end)
    end
end

local function CreateButton(name, callback, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = color or Theme.Accent
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = Content
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
end

-- ============ TAB SYSTEM ============
local Tabs = {}
local currentTab = nil

local function CreateTab(tabName, icon)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 90, 1, -8)
    tabBtn.BackgroundColor3 = Theme.BackgroundTertiary
    tabBtn.Text = icon .. " " .. tabName
    tabBtn.TextColor3 = Theme.Text
    tabBtn.TextSize = 12
    tabBtn.Font = Enum.Font.GothamMedium
    tabBtn.BorderSizePixel = 0
    tabBtn.Parent = TabBar
    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 6)
    tCorner.Parent = tabBtn
    
    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = Content
    
    local pageLayout = Instance.new("UIListLayout")
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Padding = UDim.new(0, 6)
    pageLayout.Parent = page
    
    Tabs[tabName] = {Button = tabBtn, Page = page, Layout = pageLayout}
    
    tabBtn.MouseButton1Click:Connect(function()
        -- Ẩn tất cả
        for _, t in pairs(Tabs) do
            t.Page.Visible = false
            t.Button.BackgroundColor3 = Theme.BackgroundTertiary
            t.Button.TextColor3 = Theme.Text
        end
        -- Hiện tab này
        page.Visible = true
        tabBtn.BackgroundColor3 = Theme.Accent
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        currentTab = tabName
    end)
    
    return page
end

-- Tạo tabs
local FarmPage = CreateTab("Farm", "⚔")
local SettingsPage = CreateTab("Cài Đặt", "⚙")
local MiscPage = CreateTab("Khác", "🔧")

-- Override helper để thêm vào page cụ thể
local function AddToPage(page, createFunc, ...)
    local oldParent = Content
    -- Tạm thời đổi parent
    local args = {...}
    -- Gọi hàm tạo với parent là page
    local frame = createFunc(table.unpack(args))
    return frame
end

-- Đơn giản hơn: tạo helper riêng cho từng page
local function CreateSectionIn(page, text)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 28)
    section.BackgroundTransparency = 1
    section.Parent = page
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "▸ " .. text
    label.TextColor3 = Theme.AccentSecondary
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = section
    
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 1, -1)
    line.BackgroundColor3 = Theme.Outline
    line.BorderSizePixel = 0
    line.Parent = section
end

local function CreateToggleIn(page, name, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Theme.BackgroundSecondary
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.Parent = page
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn
    
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 40, 0, 22)
    indicator.Position = UDim2.new(1, -52, 0.5, -11)
    indicator.BackgroundColor3 = default and Theme.Success or Theme.BackgroundTertiary
    indicator.BorderSizePixel = 0
    indicator.Parent = btn
    local iCorner = Instance.new("UICorner")
    iCorner.CornerRadius = UDim.new(1, 0)
    iCorner.Parent = indicator
    
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 18, 0, 18)
    dot.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    dot.Parent = indicator
    local dCorner = Instance.new("UICorner")
    dCorner.CornerRadius = UDim.new(1, 0)
    dCorner.Parent = dot
    
    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        indicator.BackgroundColor3 = state and Theme.Success or Theme.BackgroundTertiary
        dot.Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        if callback then callback(state) end
    end)
end

local function CreateSliderIn(page, name, min, max, default, suffix, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 58)
    frame.BackgroundColor3 = Theme.BackgroundSecondary
    frame.BorderSizePixel = 0
    frame.Parent = page
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 12, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. tostring(default) .. (suffix or "")
    label.TextColor3 = Theme.Text
    label.TextSize = 12
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -24, 0, 14)
    sliderBg.Position = UDim2.new(0, 12, 0, 34)
    sliderBg.BackgroundColor3 = Theme.BackgroundTertiary
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = frame
    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(1, 0)
    sCorner.Parent = sliderBg
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = sliderBg
    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(1, 0)
    fCorner.Parent = fill
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new((default - min) / (max - min), -10, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 5
    knob.Parent = sliderBg
    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent = knob
    local kStroke = Instance.new("UIStroke")
    kStroke.Color = Theme.Accent
    kStroke.Thickness = 2
    kStroke.Parent = knob
    
    local dragging = false
    
    local function updateFromPos(x)
        local rel = math.clamp((x - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local value = min + (max - min) * rel
        local step = (max - min) / 100
        value = math.floor(value / step + 0.5) * step
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, -10, 0.5, -10)
        label.Text = name .. ": " .. tostring(math.floor(value * 100) / 100) .. (suffix or "")
        if callback then callback(math.floor(value * 100) / 100) end
    end
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromPos(input.Position.X)
        end
    end)
    
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromPos(input.Position.X)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement 
            or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromPos(input.Position.X)
        end
    end)
end

local function CreateDropdownIn(page, name, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 38)
    frame.BackgroundColor3 = Theme.BackgroundSecondary
    frame.BorderSizePixel = 0
    frame.Parent = page
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -120, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local currentBtn = Instance.new("TextButton")
    currentBtn.Size = UDim2.new(0, 100, 0, 26)
    currentBtn.Position = UDim2.new(1, -110, 0.5, -13)
    currentBtn.BackgroundColor3 = Theme.BackgroundTertiary
    currentBtn.Text = default
    currentBtn.TextColor3 = Theme.AccentSecondary
    currentBtn.TextSize = 12
    currentBtn.Font = Enum.Font.GothamMedium
    currentBtn.BorderSizePixel = 0
    currentBtn.Parent = frame
    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 6)
    cCorner.Parent = currentBtn
    
    -- Dropdown list (tạo sẵn bên ngoài frame, dùng ZIndex cao)
    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(1, 0, 0, #options * 32 + 8)
    listFrame.BackgroundColor3 = Theme.BackgroundTertiary
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.ZIndex = 20
    listFrame.Parent = MainFrame  -- Parent vào MainFrame để không bị cắt
    
    local lCorner = Instance.new("UICorner")
    lCorner.CornerRadius = UDim.new(0, 8)
    lCorner.Parent = listFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = listFrame
    local listPadding = Instance.new("UIPadding")
    listPadding.PaddingTop = UDim.new(0, 4)
    listPadding.PaddingLeft = UDim.new(0, 4)
    listPadding.PaddingRight = UDim.new(0, 4)
    listPadding.Parent = listFrame
    
    local open = false
    currentBtn.MouseButton1Click:Connect(function()
        open = not open
        listFrame.Visible = open
        if open then
            -- Đặt vị trí ngay dưới button
            listFrame.Position = UDim2.new(
                0, 
                frame.AbsolutePosition.X - MainFrame.AbsolutePosition.X,
                0, 
                frame.AbsolutePosition.Y - MainFrame.AbsolutePosition.Y + 40
            )
            listFrame.Size = UDim2.new(0, frame.AbsoluteSize.X, 0, #options * 32 + 8)
        end
    end)
    
    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 28)
        optBtn.BackgroundColor3 = Theme.BackgroundSecondary
        optBtn.Text = opt
        optBtn.TextColor3 = Theme.Text
        optBtn.TextSize = 12
        optBtn.Font = Enum.Font.GothamMedium
        optBtn.BorderSizePixel = 0
        optBtn.ZIndex = 21
        optBtn.Parent = listFrame
        local oCorner = Instance.new("UICorner")
        oCorner.CornerRadius = UDim.new(0, 6)
        oCorner.Parent = optBtn
        
        optBtn.MouseButton1Click:Connect(function()
            currentBtn.Text = opt
            open = false
            listFrame.Visible = false
            if callback then callback(opt) end
        end)
    end
end

local function CreateButtonIn(page, name, callback, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = color or Theme.Accent
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = page
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
end

-- ============ BUILD FARM TAB ============
CreateSectionIn(FarmPage, "AUTO KILL")
CreateToggleIn(FarmPage, "Auto Kill Titan", false, function(v) _G.AutoKill = v end)
CreateToggleIn(FarmPage, "Auto Kill Human/Sniper", false, function(v) _G.AutoKillHuman = v end)
CreateToggleIn(FarmPage, "⚡ Kill Aura (Titan + Sniper)", false, function(v) _G.KillAura = v end)
CreateToggleIn(FarmPage, "Kill Aura Đánh Sniper", true, function(v) _G.KillAuraHitHuman = v end)
CreateToggleIn(FarmPage, "Anti-Grab", true, function(v) _G.AntiGrab = v end)
CreateToggleIn(FarmPage, "Auto Aim", true, function(v) _G.AutoAim = v end)
CreateToggleIn(FarmPage, "Chém Xa (Long Range)", true, function(v) _G.LongRange = v end)

-- ============ BUILD SETTINGS TAB ============
CreateSectionIn(SettingsPage, "TỐC ĐỘ")
CreateDropdownIn(SettingsPage, "Tốc độ đánh", {"Siêu Chậm", "Chậm", "Nhanh", "Siêu Nhanh"}, "Nhanh", function(v) _G.AutoKillSpeedMode = v end)
CreateDropdownIn(SettingsPage, "Tween Speed", {"Rất Chậm", "Chậm", "Bình Thường", "Nhanh", "Rất Nhanh", "Cực Nhanh"}, "Nhanh", function(v) _G.TweenSpeedMode = v end)

CreateSectionIn(SettingsPage, "CHỈ SỐ")
CreateSliderIn(SettingsPage, "Bán kính Aura", 50, 1000, 300, " studs", function(v) _G.AuraRadius = v end)
CreateSliderIn(SettingsPage, "Khoảng cách sau lưng", 1, 20, 4, " studs", function(v) _G.BackDistance = v end)
CreateSliderIn(SettingsPage, "Số hits", 1, 20, 3, "", function(v) _G.HitCount = v end)
CreateSliderIn(SettingsPage, "Delay giữa hits", 0.01, 0.5, 0.04, "s", function(v) _G.HitSpamDelay = v end)
CreateSliderIn(SettingsPage, "Độ mượt camera", 0.1, 1, 0.5, "", function(v) _G.CameraSmoothness = v end)

-- ============ BUILD MISC TAB ============
CreateSectionIn(MiscPage, "DAMAGE")
CreateSliderIn(MiscPage, "Damage Multiplier", 100, 999999, 99999, "x", function(v) _G.DamageValue = v end)
CreateDropdownIn(MiscPage, "Loại sát thương", {"Nape", "Body", "Head"}, "Nape", function(v) _G.DamageType = v end)

CreateSectionIn(MiscPage, "ANTI-KICK")
CreateToggleIn(MiscPage, "Anti-Kick", true, function(v) _G.AntiKick = v end)
CreateSliderIn(MiscPage, "Max Kill/Phút (AutoKill)", 20, 200, 80, "", function(v) _G.MaxKillPerMinute = v end)
CreateSliderIn(MiscPage, "Max Kill/Phút (Aura)", 20, 500, 160, "", function(v) _G.MaxKillAuraPerMinute = v end)
CreateSliderIn(MiscPage, "Kick Avoid Delay", 0.1, 3, 0.5, "s", function(v) _G.KickAvoidDelay = v end)
CreateToggleIn(MiscPage, "Random Delay", true, function(v) _G.RandomizeDelay = v end)

CreateSectionIn(MiscPage, "HACK")
CreateToggleIn(MiscPage, "1-Hit Damage", true, function(v) _G.OneHit = v end)
CreateToggleIn(MiscPage, "Vô hạn Gas", true, function(v) _G.InfGas = v end)
CreateToggleIn(MiscPage, "Vô hạn Kiếm", true, function(v) _G.InfBlades = v end)

CreateSectionIn(MiscPage, "ACTIONS")
CreateButtonIn(MiscPage, "🔄 Reset Kill History", function()
    killHistory = {}
    auraHistory = {}
    print("✅ Đã reset kill history")
end, Theme.Warning)

CreateButtonIn(MiscPage, "🎯 Test Damage", function()
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
end, Theme.Success)

-- ============ SELECT DEFAULT TAB ============
Tabs["Farm"].Button.BackgroundColor3 = Theme.Accent
Tabs["Farm"].Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Tabs["Farm"].Page.Visible = true
currentTab = "Farm"

-- ============ UPDATE CANVAS SIZE ============
local function UpdateCanvas()
    for name, tab in pairs(Tabs) do
        local layout = tab.Page:FindFirstChildOfClass("UIListLayout")
        if layout then
            tab.Page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end
    end
end

for _, tab in pairs(Tabs) do
    local layout = tab.Page:FindFirstChildOfClass("UIListLayout")
    if layout then
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
    end
end

-- ============ MINIMIZE / HIDE ============
local minimized = false
local hidden = false

MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame.Size = UDim2.new(0, 420, 0, 45)
        TabBar.Visible = false
        Content.Visible = false
    else
        MainFrame.Size = UDim2.new(0, 420, 0, 520)
        TabBar.Visible = true
        Content.Visible = true
    end
end)

HideBtn.MouseButton1Click:Connect(function()
    hidden = true
    MainFrame.Visible = false
    -- Hiện floating button
    if FloatingBtn then
        FloatingBtn.Visible = true
    end
end)

-- ============ FLOATING BUTTON (MỞ LẠI GUI) ============
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Name = "FloatingBtn"
FloatingBtn.Size = UDim2.new(0, 55, 0, 55)
FloatingBtn.Position = UDim2.new(0, 20, 0.4, 0)
FloatingBtn.BackgroundColor3 = Theme.Accent
FloatingBtn.Text = "AOT"
FloatingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingBtn.TextSize = 14
FloatingBtn.Font = Enum.Font.GothamBold
FloatingBtn.BorderSizePixel = 0
FloatingBtn.Active = true
FloatingBtn.Draggable = true
FloatingBtn.Visible = false
FloatingBtn.Parent = ScreenGui

local FCorner = Instance.new("UICorner")
FCorner.CornerRadius = UDim.new(1, 0)
FCorner.Parent = FloatingBtn

local FStroke = Instance.new("UIStroke")
FStroke.Color = Theme.AccentSecondary
FStroke.Thickness = 3
FStroke.Parent = FloatingBtn

FloatingBtn.MouseButton1Click:Connect(function()
    hidden = false
    MainFrame.Visible = true
    FloatingBtn.Visible = false
end)

print("✅ Thành Lợi Hub - AOT Revolution v16")
print("📌 GUI đen - Kill Aura độc lập (Titan + Sniper)")
print("📌 Nhấn ✕ để ẩn, nút AOT để mở lại")
