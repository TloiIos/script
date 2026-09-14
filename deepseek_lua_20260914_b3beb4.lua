-- [[ THÀNH LỢI HUB - AOT REVOLUTION v11.1 - FLUENT WHITE THEME ]]
-- GUI nhỏ gọn, theme trắng, combo tween speed, slider kéo mượt

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
_G.TweenSpeedMode = "Nhanh"  -- Combo tween speed
_G.AntiKick = true
_G.KickAvoidDelay = 0.5
_G.MaxKillPerMinute = 80
_G.RandomizeDelay = true
_G.DamageType = "Nape"
_G.ThemeColor = "Trắng"  -- Màu chủ đạo
local DAMAGE_KEY = "&@&*&@&"

-- Bảng màu
local ColorThemes = {
    ["Trắng"] = {Primary = Color3.fromRGB(240, 240, 245), Secondary = Color3.fromRGB(255, 255, 255), Text = Color3.fromRGB(30, 30, 40), Accent = Color3.fromRGB(180, 180, 200)},
    ["Xanh Dương"] = {Primary = Color3.fromRGB(30, 100, 200), Secondary = Color3.fromRGB(45, 120, 230), Text = Color3.fromRGB(255, 255, 255), Accent = Color3.fromRGB(100, 180, 255)},
    ["Đỏ"] = {Primary = Color3.fromRGB(200, 40, 40), Secondary = Color3.fromRGB(230, 60, 60), Text = Color3.fromRGB(255, 255, 255), Accent = Color3.fromRGB(255, 120, 120)},
    ["Xanh Lá"] = {Primary = Color3.fromRGB(40, 180, 80), Secondary = Color3.fromRGB(60, 210, 100), Text = Color3.fromRGB(255, 255, 255), Accent = Color3.fromRGB(120, 255, 150)},
    ["Tím"] = {Primary = Color3.fromRGB(130, 60, 200), Secondary = Color3.fromRGB(150, 80, 230), Text = Color3.fromRGB(255, 255, 255), Accent = Color3.fromRGB(200, 140, 255)},
    ["Đen"] = {Primary = Color3.fromRGB(20, 20, 30), Secondary = Color3.fromRGB(35, 35, 50), Text = Color3.fromRGB(240, 240, 250), Accent = Color3.fromRGB(80, 80, 120)},
}

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
    if not DamageEvent or not targetModel or not targetModel.Parent then return false end
    local hum = targetModel:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
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

-- ============ TÌM HUMAN / SNIPER ============
local function GetNearestHuman()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local nearest, shortest = nil, math.huge
    for _, entityModel in ipairs(workspace:GetDescendants()) do
        if entityModel:IsA("Model") and entityModel ~= LocalPlayer.Character then
            local hum = entityModel:FindFirstChildOfClass("Humanoid")
            local root = entityModel:FindFirstChild("HumanoidRootPart") or entityModel.PrimaryPart
            if hum and hum.Health > 0 and root then
                local isTitan = entityModel.Parent and entityModel.Parent.Name == "Titans"
                if not isTitan then
                    local hasSniperMark = entityModel:FindFirstChild("Sniper") or entityModel:FindFirstChild("SoldierDamageHitbox") or entityModel:FindFirstChildOfClass("Player")
                    if hasSniperMark or entityModel.Parent.Name == "Players" or entityModel.Name == "Sniper" then
                        local d = (root.Position - myRoot.Position).Magnitude
                        if d < shortest then
                            shortest = d
                            nearest = { Model = entityModel, Humanoid = hum, Root = root, Dist = d }
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
    local targetPart = aimTarget:FindFirstChild("Nape") or aimTarget:FindFirstChild("NapeHitbox") or aimTarget:FindFirstChild("HumanoidRootPart") or aimTarget:FindFirstChild("Head")
    if not targetPart then return end
    AimAtPart(targetPart)
end
RunService:BindToRenderStep("AOT_Aim_Mobile", Enum.RenderPriority.Camera.Value - 1, UpdateAim)

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
            if g then MultiHit(g) end
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
            local time = math.clamp(dist / _G.TweenSpeed, 0.05, 0.15)
            local tw = TweenService:Create(myRoot, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = targetCF})
            tw:Play(); tw.Completed:Wait()
        end)
        MultiHit(titan.Model); RecordKill()
        task.wait(0.25); ReturnToSavedPosition()
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
            if _G.AntiKick then
                local multiplier = (_G.AutoKillSpeedMode == "Siêu Nhanh") and 0.1 or 0.3
                baseDelay = math.max(baseDelay, GetSmartDelay() * multiplier)
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
                local activeTweenSpeed = _G.TweenSpeed
                -- Tween speed dựa trên combo riêng
                if _G.TweenSpeedMode == "Rất Chậm" then activeTweenSpeed = 50
                elseif _G.TweenSpeedMode == "Chậm" then activeTweenSpeed = 120
                elseif _G.TweenSpeedMode == "Bình Thường" then activeTweenSpeed = 250
                elseif _G.TweenSpeedMode == "Nhanh" then activeTweenSpeed = 450
                elseif _G.TweenSpeedMode == "Rất Nhanh" then activeTweenSpeed = 700
                elseif _G.TweenSpeedMode == "Cực Nhanh" then activeTweenSpeed = 1000 end
                if myRoot and titan.Dist <= 15 then
                    MultiHit(titan.Model); RecordKill()
                elseif _G.LongRange and titan.Dist <= 80 then
                    LongRangeSlash(titan)
                else
                    if myRoot then
                        local napeCF = titan.Nape.CFrame
                        local targetPos = napeCF.Position - (napeCF.LookVector * _G.BackDistance)
                        pcall(function()
                            local dist = (myRoot.Position - targetPos).Magnitude
                            local maxTime = (_G.TweenSpeedMode == "Cực Nhanh") and 0.1 or 0.3
                            local time = math.clamp(dist / activeTweenSpeed, 0.05, maxTime)
                            local tw = TweenService:Create(myRoot, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos, napeCF.Position)})
                            tw:Play(); tw.Completed:Wait()
                        end)
                        local postWait = (_G.TweenSpeedMode == "Cực Nhanh") and 0.01 or 0.05
                        task.wait(postWait)
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
                    local activeTweenSpeed = _G.TweenSpeed
                    if _G.TweenSpeedMode == "Rất Chậm" then activeTweenSpeed = 50
                    elseif _G.TweenSpeedMode == "Chậm" then activeTweenSpeed = 120
                    elseif _G.TweenSpeedMode == "Bình Thường" then activeTweenSpeed = 250
                    elseif _G.TweenSpeedMode == "Nhanh" then activeTweenSpeed = 450
                    elseif _G.TweenSpeedMode == "Rất Nhanh" then activeTweenSpeed = 700
                    elseif _G.TweenSpeedMode == "Cực Nhanh" then activeTweenSpeed = 1000 end
                    pcall(function()
                        local dist = (myRoot.Position - targetCF.Position).Magnitude
                        if dist > 15 then
                            local maxTime = (_G.TweenSpeedMode == "Cực Nhanh") and 0.08 or 0.25
                            local time = math.clamp(dist / activeTweenSpeed, 0.04, maxTime)
                            local tw = TweenService:Create(myRoot, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = targetCF})
                            tw:Play(); tw.Completed:Wait()
                        else myRoot.CFrame = targetCF end
                    end)
                    local postWait = (_G.TweenSpeedMode == "Cực Nhanh") and 0.01 or 0.05
                    task.wait(postWait)
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
            local auraDelay = (_G.AutoKillSpeedMode == "Siêu Nhanh") and 0.02 or 0.1
            task.wait(auraDelay)
            if not _G.KillAura then killAuraRunning = false; break end
            if not CanKillNow() then task.wait(1); continue end
            local tf = GetTitansFolder()
            if tf then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    for _, t in ipairs(tf:GetChildren()) do
                        if t:IsA("Model") then
                            local hum = t:FindFirstChildOfClass("Humanoid")
                            local nape = t:FindFirstChild("Nape") or t:FindFirstChild("NapeHitbox") or t:FindFirstChild("Head")
                            local imm = t:FindFirstChild("TitanImmune")
                            if hum and hum.Health > 0 and nape then
                                local skip = imm and imm:IsA("BoolValue") and imm.Value
                                if not skip then
                                    local d = (nape.Position - myRoot.Position).Magnitude
                                    if d <= _G.AuraRadius then MultiHit(t); RecordKill() end
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
-- ============ FLUENT GUI - SMALL WHITE THEME ===============
-- =====================================================
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "Thành Lợi | AOT",
    SubTitle = "v11.1",
    TabWidth = 120,        -- Nhỏ hơn
    Size = UDim2.fromOffset(420, 320),  -- Nhỏ hơn
    Acrylic = false,
    Theme = "Light",       -- Theme sáng (trắng)
    MinimizeKey = Enum.KeyCode.End
})

-- Áp dụng màu chủ đạo
local function ApplyTheme(themeName)
    local theme = ColorThemes[themeName] or ColorThemes["Trắng"]
    _G.ThemeColor = themeName
    pcall(function()
        Fluent:SetTheme({
            [1] = theme.Primary,
            [2] = theme.Secondary,
            [3] = theme.Text,
            [4] = theme.Accent,
            [5] = theme.Accent,
            [6] = theme.Secondary,
            [7] = theme.Text,
        })
    end)
end

local Tabs = {
    Main = Window:AddTab({ Title = "Farm", Icon = "⚔" }),
    Settings = Window:AddTab({ Title = "Cài Đặt", Icon = "⚙" }),
    Misc = Window:AddTab({ Title = "Khác", Icon = "🔧" }),
    Color = Window:AddTab({ Title = "Màu", Icon = "🎨" })
}

-- ============ TAB MAIN ============
Tabs.Main:AddParagraph({
    Title = "🎯 AOT Revolution",
    Content = "Auto Kill / Kill Aura / Anti-Grab / Aim"
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
    Title = "Kill Aura",
    Default = false
}):OnChanged(function(v) _G.KillAura = v end)

Tabs.Main:AddToggle("AntiGrab", {
    Title = "Anti-Grab",
    Default = true
}):OnChanged(function(v) _G.AntiGrab = v end)

Tabs.Main:AddToggle("AutoAim", {
    Title = "Auto Aim",
    Default = true
}):OnChanged(function(v) _G.AutoAim = v end)

Tabs.Main:AddToggle("LongRange", {
    Title = "Long Range",
    Default = true
}):OnChanged(function(v) _G.LongRange = v end)

-- ============ TAB SETTINGS ============
Tabs.Settings:AddSection("Combo Tốc Độ Tấn Công")

Tabs.Settings:AddDropdown("SpeedMode", {
    Title = "Tốc Độ Đánh",
    Values = {"Siêu Chậm", "Chậm", "Nhanh", "Siêu Nhanh"},
    Default = "Nhanh",
    Multi = false
}):OnChanged(function(v)
    _G.AutoKillSpeedMode = v
end)

Tabs.Settings:AddSection("Combo Tốc Độ Bay (Tween)")

Tabs.Settings:AddDropdown("TweenSpeedMode", {
    Title = "Tween Speed",
    Description = "Tốc độ bay tới Titan",
    Values = {"Rất Chậm", "Chậm", "Bình Thường", "Nhanh", "Rất Nhanh", "Cực Nhanh"},
    Default = "Nhanh",
    Multi = false
}):OnChanged(function(v)
    _G.TweenSpeedMode = v
end)

Tabs.Settings:AddSection("Chỉ Số")

Tabs.Settings:AddSlider("AuraRadius", {
    Title = "Bán Kính Aura",
    Default = 300,
    Min = 50,
    Max = 1000,
    Rounding = 1
}):OnChanged(function(v) _G.AuraRadius = v end)

Tabs.Settings:AddSlider("BackDistance", {
    Title = "Khoảng Cách Sau Lưng",
    Default = 4,
    Min = 1,
    Max = 20,
    Rounding = 0.5
}):OnChanged(function(v) _G.BackDistance = v end)

Tabs.Settings:AddSlider("HitCount", {
    Title = "Số Hit Mỗi Lần",
    Default = 3,
    Min = 1,
    Max = 20,
    Rounding = 1
}):OnChanged(function(v) _G.HitCount = v end)

Tabs.Settings:AddSlider("HitSpamDelay", {
    Title = "Delay Hit",
    Default = 0.04,
    Min = 0.01,
    Max = 0.5,
    Rounding = 0.01
}):OnChanged(function(v) _G.HitSpamDelay = v end)

Tabs.Settings:AddSlider("CameraSmoothness", {
    Title = "Độ Mượt Camera",
    Default = 0.5,
    Min = 0.1,
    Max = 1,
    Rounding = 0.1
}):OnChanged(function(v) _G.CameraSmoothness = v end)

-- ============ TAB MISC ============
Tabs.Misc:AddSection("Damage")

Tabs.Misc:AddSlider("DamageValue", {
    Title = "Damage Multiplier",
    Default = 99999,
    Min = 100,
    Max = 999999,
    Rounding = 1
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
    Title = "Max Kill/Phút",
    Default = 80,
    Min = 20,
    Max = 200,
    Rounding = 1
}):OnChanged(function(v) _G.MaxKillPerMinute = v end)

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

-- ============ TAB COLOR ============
Tabs.Color:AddSection("Chỉnh Màu GUI")

Tabs.Color:AddDropdown("ThemeColor", {
    Title = "Chọn Màu Chủ Đạo",
    Description = "Đổi màu toàn bộ GUI",
    Values = {"Trắng", "Xanh Dương", "Đỏ", "Xanh Lá", "Tím", "Đen"},
    Default = "Trắng",
    Multi = false
}):OnChanged(function(v)
    ApplyTheme(v)
end)

Tabs.Color:AddButton({
    Title = "🔄 Reset Về Màu Trắng",
    Description = "Khôi phục màu mặc định",
    Callback = function()
        ApplyTheme("Trắng")
    end
})

Tabs.Color:AddButton({
    Title = "🔄 Reset Tất Cả Cài Đặt",
    Callback = function()
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
        _G.DamageValue = 99999
        _G.AuraRadius = 300
        _G.CameraSmoothness = 0.5
        _G.HitCount = 3
        _G.HitSpamDelay = 0.04
        _G.AutoKillSpeedMode = "Nhanh"
        _G.TweenSpeedMode = "Nhanh"
        _G.AntiKick = true
        _G.MaxKillPerMinute = 80
        _G.RandomizeDelay = true
        _G.DamageType = "Nape"
        ApplyTheme("Trắng")
        Fluent:Notify({
            Title = "Thành Lợi Hub",
            Content = "Đã reset tất cả!",
            Duration = 3
        })
    end
})

Window:SelectTab(1)

-- =====================================================
-- ============ FLOATING BUTTON ===============
-- =====================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ThanhLoiHub_AOT"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local guiSuccess = pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not guiSuccess then
    pcall(function()
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end)
end

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "OpenButton"
ToggleButton.Size = UDim2.new(0, 44, 0, 44)
ToggleButton.Position = UDim2.new(0, 20, 0.4, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Text = "AOT"
ToggleButton.TextColor3 = Color3.fromRGB(40, 40, 50)
ToggleButton.TextSize = 12
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Active = true
ToggleButton.Draggable = true
ToggleButton.Parent = ScreenGui

local TCorner = Instance.new("UICorner")
TCorner.CornerRadius = UDim.new(0, 10)
TCorner.Parent = ToggleButton
local TStroke = Instance.new("UIStroke")
TStroke.Color = Color3.fromRGB(180, 180, 200)
TStroke.Thickness = 2
TStroke.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.End, false, game)
end)

print("✅ Thành Lợi Hub - AOT Revolution v11.1 (Small White Theme)")
print("📌 Nhấn END hoặc nút AOT để mở menu")
