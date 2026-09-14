-- [[ THÀNH LỢI HUB - AOT REVOLUTION v11.3 - FIX HIDE + COLOR ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local env = getgenv and getgenv() or _G
env.AutoKill = false
env.AutoKillHuman = false
env.KillAura = false
env.AntiGrab = true
env.AutoAim = true
env.LongRange = true
env.OneHit = true
env.InfGas = true
env.InfBlades = true
env.BackDistance = 4.0
env.KillDelay = 0.15
env.DamageValue = 99999
env.AuraRadius = 300
env.TweenSpeed = 350
env.CameraSmoothness = 0.5
env.HitCount = 3
env.HitSpamDelay = 0.04
env.AutoKillSpeedMode = "Nhanh"
env.TweenSpeedMode = "Nhanh"
env.AntiKick = true
env.KickAvoidDelay = 0.5
env.MaxKillPerMinute = 80
env.RandomizeDelay = true
env.DamageType = "Nape"
env.ThemeColor = "Trắng"

local DAMAGE_KEY = "&@&*&@&"

-- ============ TWEEN SPEED ============
local TweenSpeedConfig = {
    ["Rất Chậm"]   = 80,
    ["Chậm"]       = 150,
    ["Bình Thường"]= 280,
    ["Nhanh"]      = 500,
    ["Rất Nhanh"]  = 800,
    ["Cực Nhanh"]  = 1500,
}
local TweenMinTime = {
    ["Rất Chậm"]   = 0.15,
    ["Chậm"]       = 0.10,
    ["Bình Thường"]= 0.07,
    ["Nhanh"]      = 0.05,
    ["Rất Nhanh"]  = 0.03,
    ["Cực Nhanh"]  = 0.02,
}
local function GetTweenTime(dist)
    local speed = TweenSpeedConfig[env.TweenSpeedMode] or 500
    local minT = TweenMinTime[env.TweenSpeedMode] or 0.05
    local t = dist / speed
    if t < minT then t = minT end
    if t > 0.5 then t = 0.5 end
    return t
end

-- ============ COLOR THEMES ============
local ColorThemes = {
    ["Trắng"]      = {Primary = Color3.fromRGB(245,245,250), Secondary = Color3.fromRGB(255,255,255), Text = Color3.fromRGB(25,25,35), Accent = Color3.fromRGB(120,120,180)},
    ["Xanh Dương"] = {Primary = Color3.fromRGB(30,100,200), Secondary = Color3.fromRGB(45,120,230), Text = Color3.fromRGB(255,255,255), Accent = Color3.fromRGB(100,180,255)},
    ["Đỏ"]         = {Primary = Color3.fromRGB(200,40,40), Secondary = Color3.fromRGB(230,60,60), Text = Color3.fromRGB(255,255,255), Accent = Color3.fromRGB(255,120,120)},
    ["Xanh Lá"]    = {Primary = Color3.fromRGB(40,180,80), Secondary = Color3.fromRGB(60,210,100), Text = Color3.fromRGB(255,255,255), Accent = Color3.fromRGB(120,255,150)},
    ["Tím"]        = {Primary = Color3.fromRGB(130,60,200), Secondary = Color3.fromRGB(150,80,230), Text = Color3.fromRGB(255,255,255), Accent = Color3.fromRGB(200,140,255)},
    ["Đen"]        = {Primary = Color3.fromRGB(20,20,30), Secondary = Color3.fromRGB(35,35,50), Text = Color3.fromRGB(240,240,250), Accent = Color3.fromRGB(80,80,120)},
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
    if not env.AntiKick then return true end
    local now = tick()
    local newHistory = {}
    for _, t in ipairs(killHistory) do
        if now - t < 60 then table.insert(newHistory, t) end
    end
    killHistory = newHistory
    return #killHistory < env.MaxKillPerMinute
end
local function RecordKill() table.insert(killHistory, tick()) end
local function GetSmartDelay()
    local base = env.KickAvoidDelay
    if env.RandomizeDelay then
        local v = base * 0.3
        base = base + (math.random() * v * 2 - v)
    end
    return base
end

-- ============ HACKS ============
local function ApplyHacks()
    local odm = GetMyOdm()
    if odm then
        if env.OneHit then
            local d = odm:FindFirstChild("DamageMultiplier")
            if d and d:IsA("NumberValue") then pcall(function() d.Value = env.DamageValue end) end
        end
        if env.InfBlades then
            local b = odm:FindFirstChild("BladesAmmount")
            if b and b:IsA("IntValue") then
                pcall(function() b.Value = 99 end)
                local m = b:FindFirstChild("MaxBlades")
                if m then pcall(function() m.Value = 99 end) end
            end
            local dur = odm:FindFirstChild("BladeDurability")
            if dur then pcall(function() dur.Value = 99 end) end
        end
        if env.InfGas then
            local g = odm:FindFirstChild("GasAmmount")
            if g then pcall(function() g.Value = 999 end) end
        end
    end
    if env.InfGas then
        local e = GetMyEntity()
        if e then
            local rg = e:FindFirstChild("RemainingGas")
            if rg then pcall(function() rg.Value = 999 end) end
        end
    end
end

-- ============ DAMAGE ============
local function FireDamageEvent(targetModel, damageType)
    if not DamageEvent or not targetModel or not targetModel.Parent then return false end
    local hum = targetModel:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local dmgType = damageType or env.DamageType
    return pcall(function()
        DamageEvent:FireServer(dmgType, hum, DAMAGE_KEY, targetModel)
    end)
end

local function MultiHit(targetModel, damageType)
    if not targetModel or not targetModel.Parent then return end
    local count = env.HitCount
    local delay = env.HitSpamDelay
    if env.AutoKillSpeedMode == "Siêu Chậm" then count = 1; delay = 0.2
    elseif env.AutoKillSpeedMode == "Chậm" then count = 2; delay = 0.12
    elseif env.AutoKillSpeedMode == "Nhanh" then count = 4; delay = 0.03
    elseif env.AutoKillSpeedMode == "Siêu Nhanh" then count = 8; delay = 0.01 end
    task.spawn(function()
        for i = 1, count do
            FireDamageEvent(targetModel, damageType or env.DamageType)
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
        camera.CFrame = camera.CFrame:Lerp(targetCF, env.CameraSmoothness)
    end)
end
local function UpdateAim()
    if not env.AutoAim or not aimTarget or not aimTarget.Parent then return end
    local p = aimTarget:FindFirstChild("Nape") or aimTarget:FindFirstChild("NapeHitbox") or aimTarget:FindFirstChild("HumanoidRootPart") or aimTarget:FindFirstChild("Head")
    if p then AimAtPart(p) end
end
RunService:BindToRenderStep("AOT_Aim_Fix", Enum.RenderPriority.Camera.Value - 1, UpdateAim)

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
            if not env.AntiGrab then antiGrabRunning = false; break end
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
    local targetPos = napeCF.Position - (napeCF.LookVector * env.BackDistance)
    local targetCF = CFrame.new(targetPos, napeCF.Position)
    task.spawn(function()
        pcall(function()
            local dist = (myRoot.Position - targetCF.Position).Magnitude
            local time = GetTweenTime(dist)
            local tw = TweenService:Create(myRoot, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = targetCF})
            tw:Play(); tw.Completed:Wait()
        end)
        MultiHit(titan.Model); RecordKill()
        task.wait(0.25); ReturnToSavedPosition()
    end)
end

-- ============ AUTO KILL ============
local autoKillRunning = false
local function AutoKillLoop()
    if autoKillRunning then return end
    autoKillRunning = true
    task.spawn(function()
        while autoKillRunning do
            local baseDelay = env.KillDelay
            if env.AutoKillSpeedMode == "Siêu Chậm" then baseDelay = 0.6
            elseif env.AutoKillSpeedMode == "Chậm" then baseDelay = 0.3
            elseif env.AutoKillSpeedMode == "Siêu Nhanh" then baseDelay = 0.02
            else baseDelay = 0.1 end
            if env.AntiKick then
                local mul = (env.AutoKillSpeedMode == "Siêu Nhanh") and 0.1 or 0.3
                baseDelay = math.max(baseDelay, GetSmartDelay() * mul)
            end
            task.wait(baseDelay)
            if not env.AutoKill then autoKillRunning = false; break end
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
                    MultiHit(titan.Model); RecordKill()
                elseif env.LongRange and titan.Dist <= 80 then
                    LongRangeSlash(titan)
                else
                    if myRoot then
                        local napeCF = titan.Nape.CFrame
                        local targetPos = napeCF.Position - (napeCF.LookVector * env.BackDistance)
                        pcall(function()
                            local dist = (myRoot.Position - targetPos).Magnitude
                            local time = GetTweenTime(dist)
                            local tw = TweenService:Create(myRoot, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos, napeCF.Position)})
                            tw:Play(); tw.Completed:Wait()
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
            local baseDelay = 0.15
            if env.AutoKillSpeedMode == "Siêu Chậm" then baseDelay = 0.6
            elseif env.AutoKillSpeedMode == "Chậm" then baseDelay = 0.3
            elseif env.AutoKillSpeedMode == "Siêu Nhanh" then baseDelay = 0.02 end
            task.wait(baseDelay)
            if not env.AutoKillHuman then autoKillHumanRunning = false; break end
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

-- ============ KILL AURA ============
local killAuraRunning = false
local function KillAuraLoop()
    if killAuraRunning then return end
    killAuraRunning = true
    task.spawn(function()
        while killAuraRunning do
            local auraDelay = (env.AutoKillSpeedMode == "Siêu Nhanh") and 0.02 or 0.1
            task.wait(auraDelay)
            if not env.KillAura then killAuraRunning = false; break end
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
                                    if d <= env.AuraRadius then MultiHit(t); RecordKill() end
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
    if env.AutoKill and not lastAK then lastAK = true; AutoKillLoop()
    elseif not env.AutoKill and lastAK then lastAK = false; autoKillRunning = false end
    if env.AutoKillHuman and not lastAKH then lastAKH = true; AutoKillHumanLoop()
    elseif not env.AutoKillHuman and lastAKH then lastAKH = false; autoKillHumanRunning = false end
    if env.KillAura and not lastKA then lastKA = true; KillAuraLoop()
    elseif not env.KillAura and lastKA then lastKA = false; killAuraRunning = false end
    if env.AntiGrab and not lastAG then lastAG = true; AntiGrabLoop()
    elseif not env.AntiGrab and lastAG then lastAG = false; antiGrabRunning = false end
    if env.AutoAim and not env.AutoKill and not env.AutoKillHuman and not env.KillAura then
        local t = GetNearestTitan()
        aimTarget = t and t.Model or nil
    end
end)

-- =====================================================
-- ============ FLUENT GUI =============================
-- =====================================================
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Lưu reference đến ScreenGui của Fluent
local FluentScreenGui = nil

local Window = Fluent:CreateWindow({
    Title = "Thành Lợi | AOT",
    SubTitle = "v11.3 FIXED",
    TabWidth = 130,
    Size = UDim2.fromOffset(440, 340),
    Acrylic = false,
    Theme = "Light",
    MinimizeKey = Enum.KeyCode.End
})

-- FIX: Tìm ScreenGui của Fluent sau khi tạo
local function FindFluentScreenGui()
    local searchIn = {CoreGui, LocalPlayer:WaitForChild("PlayerGui")}
    for _, parent in ipairs(searchIn) do
        for _, gui in ipairs(parent:GetChildren()) do
            if gui:IsA("ScreenGui") then
                -- Fluent thường đặt tên là "Fluent" hoặc có chứa "Fluent"
                if gui.Name:lower():find("fluent") then
                    return gui
                end
            end
        end
    end
    return nil
end

task.wait(0.5)
FluentScreenGui = FindFluentScreenGui()

-- ============ FIX ĐỔI MÀU ============
local function ApplyTheme(themeName)
    local t = ColorThemes[themeName] or ColorThemes["Trắng"]
    env.ThemeColor = themeName
    
    -- Cách 1: Thử SetTheme của Fluent
    pcall(function()
        Fluent:SetTheme({
            Background = t.Primary,
            BackgroundSecondary = t.Secondary,
            BackgroundTertiary = t.Secondary,
            Text = t.Text,
            SubText = t.Accent,
            Element = t.Secondary,
            ElementSecondary = t.Primary,
            ElementTertiary = t.Primary,
            Accent = t.Accent,
            AccentSecondary = t.Accent,
            Outline = t.Accent,
            OutlineSecondary = t.Accent,
            Button = t.Secondary,
            ButtonSecondary = t.Primary,
            ButtonTertiary = t.Primary,
            ButtonAccent = t.Accent,
            Toggle = t.Secondary,
            ToggleAccent = t.Accent,
            Slider = t.Secondary,
            SliderAccent = t.Accent,
            Dropdown = t.Secondary,
            DropdownAccent = t.Accent,
            Tab = t.Primary,
            TabSecondary = t.Secondary,
            TabAccent = t.Accent,
            Dialog = t.Secondary,
            DialogAccent = t.Accent,
            Notification = t.Secondary,
            NotificationAccent = t.Accent,
            Border = t.Accent,
            BorderSecondary = t.Accent,
        })
    end)
    
    -- Cách 2: Force recolor trực tiếp (fallback chắc chắn)
    task.spawn(function()
        task.wait(0.1)
        if not FluentScreenGui then FluentScreenGui = FindFluentScreenGui() end
        if not FluentScreenGui then return end
        
        for _, obj in ipairs(FluentScreenGui:GetDescendants()) do
            pcall(function()
                -- Frames nền tối → đổi sang theme
                if obj:IsA("Frame") or obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    local bg = obj.BackgroundColor3
                    -- Nếu là nền tối (dark) thì đổi
                    if bg.R < 0.35 and bg.G < 0.35 and bg.B < 0.35 then
                        obj.BackgroundColor3 = t.Secondary
                    -- Nếu là nền sáng nhẹ thì đổi sang primary
                    elseif bg.R > 0.85 and bg.G > 0.85 and bg.B > 0.85 then
                        obj.BackgroundColor3 = t.Primary
                    end
                end
                
                -- Text sáng → đổi sang text theme
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    local tc = obj.TextColor3
                    if tc.R > 0.7 and tc.G > 0.7 and tc.B > 0.7 then
                        obj.TextColor3 = t.Text
                    end
                end
                
                -- UIStroke → accent
                if obj:IsA("UIStroke") then
                    obj.Color = t.Accent
                end
            end)
        end
    end)
end

local Tabs = {
    Main = Window:AddTab({ Title = "Farm", Icon = "⚔" }),
    Settings = Window:AddTab({ Title = "Cài Đặt", Icon = "⚙" }),
    Misc = Window:AddTab({ Title = "Khác", Icon = "🔧" }),
    Color = Window:AddTab({ Title = "Màu", Icon = "🎨" })
}

-- ============ TAB MAIN ============
Tabs.Main:AddParagraph({ Title = "🎯 AOT Revolution v11.3", Content = "Auto Kill / Kill Aura / Anti-Grab / Aim" })

Tabs.Main:AddToggle("AutoKill", { Title = "Auto Kill Titan", Default = false }):OnChanged(function(v) env.AutoKill = v end)
Tabs.Main:AddToggle("AutoKillHuman", { Title = "Auto Kill Human/Sniper", Default = false }):OnChanged(function(v) env.AutoKillHuman = v end)
Tabs.Main:AddToggle("KillAura", { Title = "Kill Aura", Default = false }):OnChanged(function(v) env.KillAura = v end)
Tabs.Main:AddToggle("AntiGrab", { Title = "Anti-Grab", Default = true }):OnChanged(function(v) env.AntiGrab = v end)
Tabs.Main:AddToggle("AutoAim", { Title = "Auto Aim", Default = true }):OnChanged(function(v) env.AutoAim = v end)
Tabs.Main:AddToggle("LongRange", { Title = "Long Range", Default = true }):OnChanged(function(v) env.LongRange = v end)

-- ============ TAB SETTINGS ============
Tabs.Settings:AddSection("Combo Tốc Độ Tấn Công")
Tabs.Settings:AddDropdown("SpeedMode", {
    Title = "Tốc Độ Đánh",
    Values = {"Siêu Chậm", "Chậm", "Nhanh", "Siêu Nhanh"},
    Default = "Nhanh", Multi = false
}):OnChanged(function(v) env.AutoKillSpeedMode = v end)

Tabs.Settings:AddSection("Combo Tốc Độ Bay (Tween)")
Tabs.Settings:AddDropdown("TweenSpeedMode", {
    Title = "Tween Speed",
    Description = "Chậm = bay chậm thật | Cực Nhanh = gần teleport",
    Values = {"Rất Chậm", "Chậm", "Bình Thường", "Nhanh", "Rất Nhanh", "Cực Nhanh"},
    Default = "Nhanh", Multi = false
}):OnChanged(function(v) env.TweenSpeedMode = v end)

Tabs.Settings:AddSection("Chỉ Số")
Tabs.Settings:AddSlider("AuraRadius", { Title = "Bán Kính Aura", Default = 300, Min = 50, Max = 1000, Rounding = 1 }):OnChanged(function(v) env.AuraRadius = v end)
Tabs.Settings:AddSlider("BackDistance", { Title = "Khoảng Cách Sau Lưng", Default = 4, Min = 1, Max = 20, Rounding = 0.5 }):OnChanged(function(v) env.BackDistance = v end)
Tabs.Settings:AddSlider("HitCount", { Title = "Số Hit Mỗi Lần", Default = 3, Min = 1, Max = 20, Rounding = 1 }):OnChanged(function(v) env.HitCount = v end)
Tabs.Settings:AddSlider("HitSpamDelay", { Title = "Delay Hit", Default = 0.04, Min = 0.01, Max = 0.5, Rounding = 0.01 }):OnChanged(function(v) env.HitSpamDelay = v end)
Tabs.Settings:AddSlider("CameraSmoothness", { Title = "Độ Mượt Camera", Default = 0.5, Min = 0.1, Max = 1, Rounding = 0.1 }):OnChanged(function(v) env.CameraSmoothness = v end)

-- ============ TAB MISC ============
Tabs.Misc:AddSection("Damage")
Tabs.Misc:AddSlider("DamageValue", { Title = "Damage Multiplier", Default = 99999, Min = 100, Max = 999999, Rounding = 1 }):OnChanged(function(v) env.DamageValue = v end)
Tabs.Misc:AddDropdown("DamageType", { Title = "Loại Sát Thương", Values = {"Nape", "Body", "Head"}, Default = "Nape", Multi = false }):OnChanged(function(v) env.DamageType = v end)

Tabs.Misc:AddSection("Anti-Kick")
Tabs.Misc:AddToggle("AntiKick", { Title = "Anti-Kick", Default = true }):OnChanged(function(v) env.AntiKick = v end)
Tabs.Misc:AddSlider("MaxKillPerMinute", { Title = "Max Kill/Phút", Default = 80, Min = 20, Max = 200, Rounding = 1 }):OnChanged(function(v) env.MaxKillPerMinute = v end)
Tabs.Misc:AddToggle("RandomizeDelay", { Title = "Random Delay", Default = true }):OnChanged(function(v) env.RandomizeDelay = v end)

Tabs.Misc:AddSection("Hack")
Tabs.Misc:AddToggle("OneHit", { Title = "1-Hit Damage", Default = true }):OnChanged(function(v) env.OneHit = v end)
Tabs.Misc:AddToggle("InfGas", { Title = "Vô Hạn Gas", Default = true }):OnChanged(function(v) env.InfGas = v end)
Tabs.Misc:AddToggle("InfBlades", { Title = "Vô Hạn Kiếm", Default = true }):OnChanged(function(v) env.InfBlades = v end)

-- ============ TAB COLOR ============
Tabs.Color:AddSection("Chỉnh Màu GUI")
Tabs.Color:AddDropdown("ThemeColor", {
    Title = "Chọn Màu Chủ Đạo",
    Description = "Đổi màu toàn bộ GUI",
    Values = {"Trắng", "Xanh Dương", "Đỏ", "Xanh Lá", "Tím", "Đen"},
    Default = "Trắng", Multi = false
}):OnChanged(function(v) ApplyTheme(v) end)

Tabs.Color:AddButton({
    Title = "🔄 Reset Về Màu Trắng",
    Description = "Khôi phục màu mặc định",
    Callback = function() ApplyTheme("Trắng") end
})

Tabs.Color:AddButton({
    Title = "🔄 Reset Tất Cả Cài Đặt",
    Callback = function()
        env.AutoKill = false; env.AutoKillHuman = false; env.KillAura = false
        env.AntiGrab = true; env.AutoAim = true; env.LongRange = true
        env.OneHit = true; env.InfGas = true; env.InfBlades = true
        env.BackDistance = 4.0; env.DamageValue = 99999; env.AuraRadius = 300
        env.CameraSmoothness = 0.5; env.HitCount = 3; env.HitSpamDelay = 0.04
        env.AutoKillSpeedMode = "Nhanh"; env.TweenSpeedMode = "Nhanh"
        env.AntiKick = true; env.MaxKillPerMinute = 80; env.RandomizeDelay = true
        env.DamageType = "Nape"; ApplyTheme("Trắng")
        Fluent:Notify({ Title = "Thành Lợi Hub", Content = "Đã reset tất cả!", Duration = 3 })
    end
})

Window:SelectTab(1)

-- =====================================================
-- ============ FLOATING BUTTON - FIXED ================
-- =====================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ThanhLoiHub_AOT"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999  -- Luôn trên cùng
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then
    pcall(function() ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
end

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "OpenButton"
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0, 20, 0.4, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Text = "AOT"
ToggleButton.TextColor3 = Color3.fromRGB(40, 40, 50)
ToggleButton.TextSize = 13
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Active = true
ToggleButton.Draggable = true
ToggleButton.Parent = ScreenGui

local TCorner = Instance.new("UICorner")
TCorner.CornerRadius = UDim.new(0, 12)
TCorner.Parent = ToggleButton
local TStroke = Instance.new("UIStroke")
TStroke.Color = Color3.fromRGB(180, 180, 200)
TStroke.Thickness = 2
TStroke.Parent = ToggleButton

-- ============ FIX TOGGLE GUI ============
local guiVisible = true

local function ToggleFluentGUI()
    guiVisible = not guiVisible
    
    -- Tìm lại ScreenGui mỗi lần (đề phòng Fluent tạo lại)
    if not FluentScreenGui or not FluentScreenGui.Parent then
        FluentScreenGui = FindFluentScreenGui()
    end
    
    if FluentScreenGui then
        FluentScreenGui.Enabled = guiVisible
        -- Đổi màu nút để biết trạng thái
        if guiVisible then
            ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ToggleButton.TextColor3 = Color3.fromRGB(40, 40, 50)
            ToggleButton.Text = "AOT"
        else
            ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
            ToggleButton.TextColor3 = Color3.fromRGB(120, 120, 130)
            ToggleButton.Text = "❌"
        end
    else
        -- Fallback: gửi key End
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.End, false, game)
    end
end

ToggleButton.MouseButton1Click:Connect(ToggleFluentGUI)

-- Cũng có thể dùng phím End để toggle
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.End then
        -- Fluent đã xử lý, không cần làm gì
    end
end)

print("✅ Thành Lợi Hub - AOT Revolution v11.3 FIXED")
print("📌 Nhấn nút AOT để bật/tắt GUI")
print("📌 Nút chuyển thành ❌ khi GUI đang ẩn")
