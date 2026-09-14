-- [[ THÀNH LỢI HUB - AOT REVOLUTION v16.8 - MOBILE OPTIMIZED ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local env = getgenv and getgenv() or _G
env.AutoKill = false
env.AutoKillHuman = false
env.KillAura = false
env.KillAuraHitHuman = true
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
env.MaxKillAuraPerMinute = 160
env.RandomizeDelay = true
env.DamageType = "Nape"
env.MobileMode = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local DAMAGE_KEY = "&@&*&@&"

-- ============ TWEEN SPEED CONFIG ============
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

local function CanKillAuraNow()
    if not env.AntiKick then return true end
    local now = tick()
    local newHistory = {}
    for _, t in ipairs(auraHistory) do
        if now - t < 60 then table.insert(newHistory, t) end
    end
    auraHistory = newHistory
    return #auraHistory < (env.MaxKillAuraPerMinute or 160)
end
local function RecordAuraKill() table.insert(auraHistory, tick()) end

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

-- ============ DAMAGE ENGINE ============
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

-- ============ TARGET FINDERS ============
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

-- ============ AUTO AIM ============
local aimTarget = nil
local function UpdateAim()
    if not env.AutoAim or not aimTarget or not aimTarget.Parent then return end
    pcall(function()
        local camera = workspace.CurrentCamera
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not camera or not myRoot then return end
        local p = aimTarget:FindFirstChild("Nape") or aimTarget:FindFirstChild("NapeHitbox") or aimTarget:FindFirstChild("HumanoidRootPart") or aimTarget:FindFirstChild("Head")
        if p then
            local eyePos = myRoot.Position + Vector3.new(0, 1.5, 0)
            camera.CFrame = camera.CFrame:Lerp(CFrame.new(eyePos, p.Position), env.CameraSmoothness)
        end
    end)
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

-- ============ LONG RANGE TELEPORT ============
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

-- ============ AUTO KILL LOOPS ============
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

local autoKillHumanRunning = false
local function AutoKillHumanLoop()
    if autoKillHumanRunning then return end
    autoKillHumanRunning = true
    task.spawn(function()
        while autoKillHumanRunning do
            task.wait(0.15)
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
            local auraDelay = (env.AutoKillSpeedMode == "Siêu Nhanh") and 0.02 or (env.AutoKillSpeedMode == "Nhanh" and 0.05 or 0.15)
            task.wait(auraDelay)
            if not env.KillAura then killAuraRunning = false; break end
            if not CanKillAuraNow() then task.wait(1); continue end
            
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myRoot then continue end
            
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
                                if (root.Position - myRoot.Position).Magnitude <= env.AuraRadius then
                                    MultiHit(t, "Nape"); RecordAuraKill()
                                end
                            end
                        end
                    end
                end
            end
            
            if env.KillAuraHitHuman then
                for _, m in ipairs(workspace:GetDescendants()) do
                    if m:IsA("Model") and m ~= LocalPlayer.Character then
                        local hum = m:FindFirstChildOfClass("Humanoid")
                        local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
                        if hum and hum.Health > 0 and root then
                            if not (m.Parent and m.Parent.Name == "Titans") then
                                local hasMark = m:FindFirstChild("Sniper") or m:FindFirstChild("SoldierDamageHitbox") or m:FindFirstChildOfClass("Player")
                                if hasMark or (m.Parent and m.Parent.Name == "Players") or m.Name == "Sniper" then
                                    if (root.Position - myRoot.Position).Magnitude <= env.AuraRadius then
                                        MultiHit(m, "Body"); RecordAuraKill()
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

-- ============ MAIN RUNSERVICE ============
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
end)

-- =====================================================
-- ============ FLUENT UI - MOBILE OPTIMIZED ==========
-- =====================================================
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Mobile: cửa sổ nhỏ hơn, chữ to hơn, nút dễ bấm
local windowSize
if env.MobileMode then
    windowSize = UDim2.fromOffset(340, 300)
else
    windowSize = UDim2.fromOffset(520, 420)
end

local Window = Fluent:CreateWindow({
    Title = "Thành Lợi Hub",
    SubTitle = "v16.8 Mobile",
    TabWidth = env.MobileMode and 110 or 160,
    Size = windowSize,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.End
})

local Tabs = {
    Main = Window:AddTab({ Title = "Farm", Icon = "sword" }),
    Hacks = Window:AddTab({ Title = "Hacks", Icon = "flame" }),
    Settings = Window:AddTab({ Title = "Cài Đặt", Icon = "settings" })
}

-- ===== TAB 1: FARM =====
Tabs.Main:AddSection("Auto Farm")
Tabs.Main:AddToggle("AutoKill", { Title = "Auto Kill Titan", Default = false }):OnChanged(function(v) env.AutoKill = v end)
Tabs.Main:AddToggle("AutoKillHuman", { Title = "Auto Kill Human/Sniper", Default = false }):OnChanged(function(v) env.AutoKillHuman = v end)
Tabs.Main:AddToggle("LongRange", { Title = "Long Range Slash", Default = true }):OnChanged(function(v) env.LongRange = v end)
Tabs.Main:AddToggle("AutoAim", { Title = "Auto Aim Nape/Head", Default = true }):OnChanged(function(v) env.AutoAim = v end)

Tabs.Main:AddSection("Kill Aura")
Tabs.Main:AddToggle("KillAura", { Title = "Bật Kill Aura", Default = false }):OnChanged(function(v) env.KillAura = v end)
Tabs.Main:AddToggle("KillAuraHitHuman", { Title = "Đánh Cả Sniper/Human", Default = true }):OnChanged(function(v) env.KillAuraHitHuman = v end)
Tabs.Main:AddSlider("AuraRadius", { Title = "Bán Kính Aura", Default = 300, Min = 50, Max = 1000, Increment = 10 }):OnChanged(function(v) env.AuraRadius = v end)
Tabs.Main:AddToggle("AntiGrab", { Title = "Anti-Grab", Default = true }):OnChanged(function(v) env.AntiGrab = v end)

-- ===== TAB 2: HACKS =====
Tabs.Hacks:AddSection("Damage")
Tabs.Hacks:AddToggle("OneHit", { Title = "One Hit K.O", Default = true }):OnChanged(function(v) env.OneHit = v end)
Tabs.Hacks:AddToggle("InfGas", { Title = "Gas Vô Hạn", Default = true }):OnChanged(function(v) env.InfGas = v end)
Tabs.Hacks:AddToggle("InfBlades", { Title = "Blade Vô Hạn", Default = true }):OnChanged(function(v) env.InfBlades = v end)

Tabs.Hacks:AddSection("Tốc Độ")
Tabs.Hacks:AddDropdown("AutoKillSpeedMode", { Title = "Tốc Độ Farm", Values = {"Siêu Chậm", "Chậm", "Nhanh", "Siêu Nhanh"}, Default = "Nhanh" }):OnChanged(function(v) env.AutoKillSpeedMode = v end)
Tabs.Hacks:AddDropdown("TweenSpeedMode", { Title = "Tốc Độ Bay", Values = {"Rất Chậm", "Chậm", "Bình Thường", "Nhanh", "Rất Nhanh", "Cực Nhanh"}, Default = "Nhanh" }):OnChanged(function(v) env.TweenSpeedMode = v end)

-- ===== TAB 3: CÀI ĐẶT =====
Tabs.Settings:AddSection("Anti-Kick")
Tabs.Settings:AddToggle("AntiKick", { Title = "Chống Kick / Safe Mode", Default = true }):OnChanged(function(v) env.AntiKick = v end)
Tabs.Settings:AddSlider("MaxKillPerMinute", { Title = "Giới Hạn Kill/Phút", Default = 80, Min = 20, Max = 150, Increment = 5 }):OnChanged(function(v) env.MaxKillPerMinute = v end)
Tabs.Settings:AddSlider("MaxKillAuraPerMinute", { Title = "Giới Hạn Aura/Phút", Default = 160, Min = 40, Max = 300, Increment = 10 }):OnChanged(function(v) env.MaxKillAuraPerMinute = v end)

-- =====================================================
-- ============ NÚT ẨN/HIỆN GUI CHO MOBILE ============
-- =====================================================
local guiParent = gethui and gethui() or game:GetService("CoreGui")
local toggleGui = Instance.new("ScreenGui")
toggleGui.Name = "ThanhLoiToggle_" .. tostring(math.random(1, 999999))
toggleGui.ResetOnSpawn = false
toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() toggleGui.Parent = guiParent end)

-- Nút tròn nhỏ ở góc phải trên
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
toggleBtn.Size = UDim2.fromOffset(env.MobileMode and 55 or 45, env.MobileMode and 55 or 45)
toggleBtn.Position = UDim2.new(1, -70, 0, 60)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
toggleBtn.BackgroundTransparency = 0.1
toggleBtn.Text = "TL"
toggleBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.AutoButtonColor = true
toggleBtn.Parent = toggleGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(1, 0)
btnCorner.Parent = toggleBtn

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(0, 200, 255)
btnStroke.Thickness = 2
btnStroke.Parent = toggleBtn

-- Kéo thả nút bằng cảm ứng / chuột
local dragging = false
local dragStart, startPos
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = toggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
toggleBtn.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Ẩn/hiện toàn bộ GUI Fluent
local guiVisible = true
local function ToggleFluentGUI()
    guiVisible = not guiVisible
    -- Tìm ScreenGui của Fluent trong CoreGui
    for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if gui:IsA("ScreenGui") and (gui.Name:find("Fluent") or gui.Name:find("fluent")) then
            gui.Enabled = guiVisible
        end
    end
    -- Fallback: tìm trong PlayerGui
    for _, gui in ipairs(LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do
        if gui:IsA("ScreenGui") and (gui.Name:find("Fluent") or gui.Name:find("fluent")) then
            gui.Enabled = guiVisible
        end
    end
    toggleBtn.Text = guiVisible and "TL" or "X"
    toggleBtn.TextColor3 = guiVisible and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(255, 80, 80)
    btnStroke.Color = guiVisible and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(255, 80, 80)
end

toggleBtn.MouseButton1Click:Connect(ToggleFluentGUI)
toggleBtn.TouchTap:Connect(ToggleFluentGUI)

-- =====================================================
-- Save & Interface
-- =====================================================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("ThanhLoiHub")
SaveManager:SetFolder("ThanhLoiHub/Configs")
SaveManager:BuildConfigSection(Tabs.Settings)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

Window:SelectTab(1)
Fluent:Notify({
    Title = "Thành Lợi Hub",
    Content = "v16.8 Mobile - Nhấn nút TL góc phải để ẩn/hiện GUI!",
    Duration = 6
})
