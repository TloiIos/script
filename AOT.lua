-- [[ THÀNH LỢI HUB - AOT REVOLUTION v20.6 - DROPDOWN FIX & FULL OPTIONS ]]

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
env.KillAuraHitHuman = true
env.AntiGrab = true
env.AutoAim = true
env.LongRange = true
env.OneHit = true
env.InfGas = true
env.InfBlades = true

env.InfiniteJump = false
env.NoClip = false
env.SpeedEnabled = false
env.WalkSpeedValue = 24
env.ESPEnabled = false
env.AutoClicker = false
env.AutoClickerDelay = 0.05
env.AutoOpenChest = false

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

    if env.SpeedEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = env.WalkSpeedValue
        end
    end
end

UserInputService.JumpRequest:Connect(function()
    if env.InfiniteJump then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

RunService.Stepped:Connect(function()
    if env.NoClip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(env.AutoClickerDelay)
        if env.AutoClicker then
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.01)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if env.AutoOpenChest then
            pcall(function()
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Model") or obj:IsA("BasePart") then
                        local name = obj.Name:lower()
                        if name:find("chest") or name:find("box") or name:find("loot") or name:find("gift") then
                            local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                            if prompt and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                local root = LocalPlayer.Character.HumanoidRootPart
                                local part = obj:IsA("Model") and obj.PrimaryPart or obj
                                if part and (root.Position - part.Position).Magnitude <= 20 then
                                    fireproximityprompt(prompt)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

local espFolder = Instance.new("Folder")
espFolder.Name = "ThanhLoi_ESP"
espFolder.Parent = CoreGui

local function UpdateESP()
    if not env.ESPEnabled then
        espFolder:ClearAllChildren()
        return
    end
    for _, h in ipairs(espFolder:GetChildren()) do
        local target = h.Adornee
        if not target or not target.Parent then h:Destroy() end
    end
    local tf = GetTitansFolder()
    if tf then
        for _, t in ipairs(tf:GetChildren()) do
            if t:IsA("Model") and not espFolder:FindFirstChild(t.Name..t.GetFullName()) then
                pcall(function()
                    local hl = Instance.new("Highlight")
                    hl.Name = t.Name
                    hl.Adornee = t
                    hl.FillColor = Color3.fromRGB(255, 50, 50)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency = 0.5
                    hl.Parent = espFolder
                end)
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        if env.ESPEnabled then
            UpdateESP()
        else
            espFolder:ClearAllChildren()
        end
    end
end)

-- ============ DAMAGE & COMBAT LOOPS ============
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
    if env.AutoKillSpeedMode == "Siêu Chậm" then
        count = 1
        delay = 0.2
    elseif env.AutoKillSpeedMode == "Chậm" then
        count = 2
        delay = 0.12
    elseif env.AutoKillSpeedMode == "Nhanh" then
        count = 4
        delay = 0.03
    elseif env.AutoKillSpeedMode == "Siêu Nhanh" then
        count = 8
        delay = 0.01
    end
    task.spawn(function()
        for i = 1, count do
            FireDamageEvent(targetModel, damageType or env.DamageType)
            if i < count then task.wait(delay) end
        end
    end)
end

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
            if not env.AntiGrab then
                antiGrabRunning = false
                break
            end
            local g = GetGrabbingTitan()
            if g then MultiHit(g) end
        end
    end)
end

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
        tw:Play()
        tw.Completed:Wait()
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
            tw:Play()
            tw.Completed:Wait()
        end)
        MultiHit(titan.Model)
        RecordKill()
        task.wait(0.25)
        ReturnToSavedPosition()
    end)
end

local autoKillRunning = false
local function AutoKillLoop()
    if autoKillRunning then return end
    autoKillRunning = true
    task.spawn(function()
        while autoKillRunning do
            local baseDelay = env.KillDelay
            if env.AutoKillSpeedMode == "Siêu Chậm" then
                baseDelay = 0.6
            elseif env.AutoKillSpeedMode == "Chậm" then
                baseDelay = 0.3
            elseif env.AutoKillSpeedMode == "Siêu Nhanh" then
                baseDelay = 0.02
            else
                baseDelay = 0.1
            end
            if env.AntiKick then
                local mul = (env.AutoKillSpeedMode == "Siêu Nhanh") and 0.1 or 0.3
                baseDelay = math.max(baseDelay, GetSmartDelay() * mul)
            end
            task.wait(baseDelay)
            if not env.AutoKill then
                autoKillRunning = false
                break
            end
            if not CanKillNow() then
                task.wait(1)
                continue
            end
            
            local titan = GetNearestTitan()
            if titan then
                aimTarget = titan.Model
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myRoot and titan.Dist <= 15 then
                    MultiHit(titan.Model)
                    RecordKill()
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
                            tw:Play()
                            tw.Completed:Wait()
                        end)
                        task.wait(0.02)
                        MultiHit(titan.Model)
                        RecordKill()
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
            if not env.AutoKillHuman then
                autoKillHumanRunning = false
                break
            end
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
                            tw:Play()
                            tw.Completed:Wait()
                        else
                            myRoot.CFrame = targetCF
                        end
                    end)
                    task.wait(0.02)
                    MultiHit(human.Model, "Body")
                    RecordKill()
                end
            end
        end
    end)
end

local killAuraRunning = false
local function KillAuraLoop()
    if killAuraRunning then return end
    killAuraRunning = true
    task.spawn(function()
        while killAuraRunning do
            local auraDelay = (env.AutoKillSpeedMode == "Siêu Nhanh") and 0.02 or (env.AutoKillSpeedMode == "Nhanh" and 0.05 or 0.15)
            task.wait(auraDelay)
            if not env.KillAura then
                killAuraRunning = false
                break
            end
            if not CanKillAuraNow() then
                task.wait(1)
                continue
            end
            
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
                                    MultiHit(t, "Nape")
                                    RecordAuraKill()
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

local lastAG = false
RunService.RenderStepped:Connect(function()
    ApplyHacks()
    if env.AntiGrab and not lastAG then
        lastAG = true
        AntiGrabLoop()
    elseif not env.AntiGrab and lastAG then
        lastAG = false
        antiGrabRunning = false
    end
    if env.AutoAim and not env.AutoKill and not env.AutoKillHuman and not env.KillAura then
        local t = GetNearestTitan()
        aimTarget = t and t.Model or nil
    end
end)

-- =====================================================
-- ============ MSPAINT THEME GUI (FIXED DROPDOWN) ======
-- =====================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ThanhLoiHub_MspaintFixed"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999
ScreenGui.IgnoreGuiInset = true

local success = pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not success then
    pcall(function()
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end)
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 560, 0, 370)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -185)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MFStroke = Instance.new("UIStroke")
MFStroke.Color = Color3.fromRGB(50, 50, 60)
MFStroke.Thickness = 1.5
MFStroke.Parent = MainFrame

local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 28)
Topbar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Topbar.BorderSizePixel = 0
Topbar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "mspaint v2 - Thành Lợi AOT Hub"
TitleLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.Code
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Topbar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -28, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
CloseBtn.TextSize = 13
CloseBtn.Font = Enum.Font.Code
CloseBtn.Parent = Topbar

local TabsBar = Instance.new("Frame")
TabsBar.Name = "TabsBar"
TabsBar.Size = UDim2.new(1, -12, 0, 26)
TabsBar.Position = UDim2.new(0, 6, 0, 32)
TabsBar.BackgroundTransparency = 1
TabsBar.Parent = MainFrame

local UIListTabs = Instance.new("UIListLayout")
UIListTabs.FillDirection = Enum.FillDirection.Horizontal
UIListTabs.SortOrder = Enum.SortOrder.LayoutOrder
UIListTabs.Padding = UDim.new(0, 4)
UIListTabs.Parent = TabsBar

local PagesContainer = Instance.new("Frame")
PagesContainer.Name = "PagesContainer"
PagesContainer.Size = UDim2.new(1, -12, 1, -68)
PagesContainer.Position = UDim2.new(0, 6, 0, 62)
PagesContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
PagesContainer.BorderSizePixel = 0
PagesContainer.Parent = MainFrame

local PCStroke = Instance.new("UIStroke")
PCStroke.Color = Color3.fromRGB(40, 40, 50)
PCStroke.Thickness = 1
PCStroke.Parent = PagesContainer

local pages = {}
local tabButtons = {}

local function CreateMspaintTab(name)
    local tBtn = Instance.new("TextButton")
    tBtn.Size = UDim2.new(0, 85, 1, 0)
    tBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    tBtn.Text = name
    tBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
    tBtn.TextSize = 12
    tBtn.Font = Enum.Font.Code
    tBtn.Parent = TabsBar
    
    local tbStroke = Instance.new("UIStroke")
    tbStroke.Color = Color3.fromRGB(45, 45, 55)
    tbStroke.Thickness = 1
    tbStroke.Parent = tBtn
    
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.CanvasSize = UDim2.new(0, 0, 0, 450)
    page.ScrollBarThickness = 3
    page.Visible = false
    page.Parent = PagesContainer
    
    table.insert(pages, page)
    table.insert(tabButtons, {Button = tBtn, Page = page})
    
    tBtn.MouseButton1Click:Connect(function()
        for _, p in ipairs(pages) do p.Visible = false end
        for _, tb in ipairs(tabButtons) do
            tb.Button.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
            tb.Button.TextColor3 = Color3.fromRGB(140, 140, 150)
        end
        page.Visible = true
        tBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        tBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    
    if #pages == 1 then
        page.Visible = true
        tBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        tBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    
    return page
end

local TabMain = CreateMspaintTab("Main")
local TabExploits = CreateMspaintTab("Exploits")
local TabVisuals = CreateMspaintTab("Visuals")
local TabSettings = CreateMspaintTab("UI Settings")

local function CreateGroupBox(parent, title, size, pos)
    local box = Instance.new("Frame")
    box.Size = size
    box.Position = pos
    box.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    box.BorderSizePixel = 0
    box.Parent = parent
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(45, 45, 55)
    stroke.Thickness = 1
    stroke.Parent = box
    
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -12, 0, 18)
    titleLbl.Position = UDim2.new(0, 8, 0, -8)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "  " .. title .. "  "
    titleLbl.TextColor3 = Color3.fromRGB(160, 160, 175)
    titleLbl.TextSize = 11
    titleLbl.Font = Enum.Font.Code
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = box
    
    local cover = Instance.new("Frame")
    cover.Size = UDim2.new(0, titleLbl.TextBounds.X + 4, 0, 2)
    cover.Position = UDim2.new(0, 8, 0, 0)
    cover.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    cover.BorderSizePixel = 0
    cover.ZIndex = 2
    cover.Parent = box
    
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -10, 1, -18)
    content.Position = UDim2.new(0, 5, 0, 14)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.CanvasSize = UDim2.new(0, 0, 0, 300)
    content.ScrollBarThickness = 2
    content.Parent = box
    
    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 6)
    list.Parent = content
    
    return content
end

local function AddMspaintToggle(parent, title, default, callback)
    local f = Instance.new("TextButton")
    f.Size = UDim2.new(1, -4, 0, 24)
    f.BackgroundTransparency = 1
    f.Text = ""
    f.Parent = parent
    
    local cb = Instance.new("Frame")
    cb.Size = UDim2.new(0, 14, 0, 14)
    cb.Position = UDim2.new(0, 4, 0.5, -7)
    cb.BackgroundColor3 = default and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(25, 25, 32)
    cb.BorderSizePixel = 0
    cb.Parent = f
    
    local cbs = Instance.new("UIStroke")
    cbs.Color = default and Color3.fromRGB(50, 150, 255) or Color3.fromRGB(60, 60, 75)
    cbs.Thickness = 1
    cbs.Parent = cb
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -26, 1, 0)
    lbl.Position = UDim2.new(0, 24, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Color3.fromRGB(190, 190, 200)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Code
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f
    
    local state = default
    f.MouseButton1Click:Connect(function()
        state = not state
        cb.BackgroundColor3 = state and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(25, 25, 32)
        cbs.Color = state and Color3.fromRGB(50, 150, 255) or Color3.fromRGB(60, 60, 75)
        pcall(function() callback(state) end)
    end)
end

local function AddMspaintSlider(parent, title, default, min, max, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -4, 0, 36)
    f.BackgroundTransparency = 1
    f.Parent = parent
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title .. ": " .. tostring(default)
    lbl.TextColor3 = Color3.fromRGB(190, 190, 200)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Code
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f
    
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -8, 0, 12)
    bar.Position = UDim2.new(0, 4, 0, 18)
    bar.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    bar.BorderSizePixel = 0
    bar.Parent = f
    
    local bs = Instance.new("UIStroke")
    bs.Color = Color3.fromRGB(60, 60, 75)
    bs.Thickness = 1
    bs.Parent = bar
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    
    local dragging = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * pos + 0.5)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            lbl.Text = title .. ": " .. tostring(val)
            pcall(function() callback(val) end)
        end
    end)
end

-- ĐÃ FIX LỖI DROPDOWN TRONG SUỐT / KHÔNG THẤY GÌ BẰNG CÁCH GÁN NỀN ĐẶC (RGB 18, 18, 24) VÀ ZINDEX CAO
local function AddMspaintDropdown(parent, title, options, default, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -4, 0, 38)
    f.BackgroundTransparency = 1
    f.ZIndex = 5
    f.Parent = parent
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 14)
    lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Color3.fromRGB(190, 190, 200)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Code
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 5
    lbl.Parent = f
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 20)
    btn.Position = UDim2.new(0, 4, 0, 16)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    btn.Text = "  " .. tostring(default) .. " ▼"
    btn.TextColor3 = Color3.fromRGB(220, 220, 230)
    btn.TextSize = 11
    btn.Font = Enum.Font.Code
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 6
    btn.Parent = f
    
    local bs = Instance.new("UIStroke")
    bs.Color = Color3.fromRGB(60, 60, 75)
    bs.Thickness = 1
    bs.Parent = btn
    
    local dropdownList = Instance.new("Frame")
    dropdownList.Size = UDim2.new(1, 0, 0, #options * 22)
    dropdownList.Position = UDim2.new(0, 0, 1, 2)
    dropdownList.BackgroundColor3 = Color3.fromRGB(18, 18, 24) -- Đảm bảo nền đặc không bị trong suốt
    dropdownList.BackgroundTransparency = 0
    dropdownList.BorderSizePixel = 0
    dropdownList.Visible = false
    dropdownList.ZIndex = 20
    dropdownList.Parent = btn
    
    local dls = Instance.new("UIStroke")
    dls.Color = Color3.fromRGB(80, 80, 100)
    dls.Thickness = 1.5
    dls.Parent = dropdownList
    
    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 22)
        optBtn.Position = UDim2.new(0, 0, 0, (i-1)*22)
        optBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
        optBtn.BackgroundTransparency = 0
        optBtn.Text = "  " .. opt
        optBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
        optBtn.TextSize = 11
        optBtn.Font = Enum.Font.Code
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.ZIndex = 21
        optBtn.Parent = dropdownList
        
        optBtn.MouseButton1Click:Connect(function()
            btn.Text = "  " .. opt .. " ▼"
            dropdownList.Visible = false
            pcall(function() callback(opt) end)
        end)
    end
    
    btn.MouseButton1Click:Connect(function()
        dropdownList.Visible = not dropdownList.Visible
    end)
end

local function AddMspaintButton(parent, title, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 24)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    btn.Text = title
    btn.TextColor3 = Color3.fromRGB(200, 200, 210)
    btn.TextSize = 11
    btn.Font = Enum.Font.Code
    btn.Parent = parent
    
    local bs = Instance.new("UIStroke")
    bs.Color = Color3.fromRGB(60, 60, 75)
    bs.Thickness = 1
    bs.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)
end

-- KHAI BÁO TOGGLEBUTTON
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "OpenButton"
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0, 20, 0.4, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ToggleButton.Text = "msp"
ToggleButton.TextColor3 = Color3.fromRGB(0, 120, 255)
ToggleButton.TextSize = 13
ToggleButton.Font = Enum.Font.Code
ToggleButton.Active = true
ToggleButton.Draggable = true
ToggleButton.Parent = ScreenGui

local TBStroke = Instance.new("UIStroke")
TBStroke.Color = Color3.fromRGB(60, 60, 75)
TBStroke.Thickness = 1.5
TBStroke.Parent = ToggleButton

-- Tab Main
local BoxSpeed = CreateGroupBox(TabMain, "Speed & Movement", UDim2.new(0, 260, 0, 180), UDim2.new(0, 6, 0, 10))
AddMspaintSlider(BoxSpeed, "WalkSpeed", 24, 16, 100, function(v) env.WalkSpeedValue = v end)
AddMspaintToggle(BoxSpeed, "Bật WalkSpeed", false, function(v) env.SpeedEnabled = v end)
AddMspaintToggle(BoxSpeed, "Nhảy Vô Hạn (Infinite Jump)", false, function(v) env.InfiniteJump = v end)
AddMspaintToggle(BoxSpeed, "Xuyên Tường (No-Clip)", false, function(v) env.NoClip = v end)

local BoxReach = CreateGroupBox(TabMain, "Combat & Reach", UDim2.new(0, 260, 0, 160), UDim2.new(0, 6, 0, 200))
AddMspaintSlider(BoxReach, "Bán Kính Aura", 300, 50, 1000, function(v) env.AuraRadius = v end)
AddMspaintSlider(BoxReach, "Khoảng Cách Sau Lưng", 4, 1, 20, function(v) env.BackDistance = v end)
AddMspaintToggle(BoxReach, "Auto Aim", true, function(v) env.AutoAim = v end)
AddMspaintToggle(BoxReach, "Long Range Slash", true, function(v) env.LongRange = v end)

local BoxAutomation = CreateGroupBox(TabMain, "Automation", UDim2.new(0, 260, 0, 160), UDim2.new(0, 276, 0, 10))
AddMspaintToggle(BoxAutomation, "Auto Kill Titan", false, function(v)
    env.AutoKill = v
    if v then AutoKillLoop() end
end)
AddMspaintToggle(BoxAutomation, "Auto Kill Human/Sniper", false, function(v)
    env.AutoKillHuman = v
    if v then AutoKillHumanLoop() end
end)
AddMspaintToggle(BoxAutomation, "Kill Aura", false, function(v)
    env.KillAura = v
    if v then KillAuraLoop() end
end)
AddMspaintToggle(BoxAutomation, "Anti-Grab", true, function(v) env.AntiGrab = v end)

local BoxMisc = CreateGroupBox(TabMain, "Misc / Utils", UDim2.new(0, 260, 0, 140), UDim2.new(0, 276, 0, 180))
AddMspaintToggle(BoxMisc, "ESP Titan", false, function(v) env.ESPEnabled = v end)
AddMspaintToggle(BoxMisc, "Auto Clicker Chuột", false, function(v) env.AutoClicker = v end)
AddMspaintToggle(BoxMisc, "Tự Động Mở Rương", false, function(v) env.AutoOpenChest = v end)
AddMspaintButton(BoxMisc, "Reset Kill History", function()
    killHistory = {}
    auraHistory = {}
end)

-- Tab Exploits
local BoxExploits = CreateGroupBox(TabExploits, "Combat Speed Settings", UDim2.new(0, 530, 0, 180), UDim2.new(0, 6, 0, 10))
AddMspaintDropdown(BoxExploits, "Tốc Độ Đánh (AutoKill Speed)", {"Siêu Chậm", "Chậm", "Nhanh", "Siêu Nhanh"}, "Nhanh", function(opt)
    env.AutoKillSpeedMode = opt
end)
AddMspaintDropdown(BoxExploits, "Tốc Độ Bay Tween (Tween Speed)", {"Rất Chậm", "Chậm", "Bình Thường", "Nhanh", "Rất Nhanh", "Cực Nhanh"}, "Nhanh", function(opt)
    env.TweenSpeedMode = opt
end)
AddMspaintSlider(BoxExploits, "Số Hit Mỗi Lần (Hit Count)", 3, 1, 20, function(v) env.HitCount = v end)

local BoxHacks = CreateGroupBox(TabExploits, "Server Exploits", UDim2.new(0, 530, 0, 150), UDim2.new(0, 6, 0, 200))
AddMspaintToggle(BoxHacks, "Anti-Kick", true, function(v) env.AntiKick = v end)
AddMspaintToggle(BoxHacks, "1-Hit Damage", true, function(v) env.OneHit = v end)
AddMspaintToggle(BoxHacks, "Vô Hạn Gas", true, function(v) env.InfGas = v end)
AddMspaintToggle(BoxHacks, "Vô Hạn Kiếm", true, function(v) env.InfBlades = v end)

-- Tab Visuals
local BoxVisuals = CreateGroupBox(TabVisuals, "Visual Customization", UDim2.new(0, 530, 0, 150), UDim2.new(0, 6, 0, 10))
AddMspaintToggle(BoxVisuals, "ESP Titans", false, function(v) env.ESPEnabled = v end)
AddMspaintSlider(BoxVisuals, "Độ Mượt Camera (Smoothness)", 0.5, 0.1, 1, function(v) env.CameraSmoothness = v end)

-- Tab UI Settings
local BoxTheme = CreateGroupBox(TabSettings, "UI Appearance & Colors", UDim2.new(0, 530, 0, 160), UDim2.new(0, 6, 0, 10))

local accentColors = {
    ["Xanh Dương (Cyber)"] = Color3.fromRGB(0, 120, 255),
    ["Tím Neon"]          = Color3.fromRGB(180, 0, 255),
    ["Hồng Cyberpunk"]    = Color3.fromRGB(255, 0, 128),
    ["Cyan Sáng"]         = Color3.fromRGB(0, 229, 255),
    ["Xanh Lá Neon"]      = Color3.fromRGB(0, 255, 100),
    ["Vàng Gold"]         = Color3.fromRGB(255, 180, 0),
}

local function UpdateThemeColor(newColor)
    pcall(function()
        ToggleButton.TextColor3 = newColor
        for _, descendant in ipairs(ScreenGui:GetDescendants()) do
            if descendant:IsA("Frame") and descendant.BackgroundColor3 == Color3.fromRGB(0, 120, 255) then
                descendant.BackgroundColor3 = newColor
            elseif descendant:IsA("UIStroke") and descendant.Color == Color3.fromRGB(50, 150, 255) then
                descendant.Color = newColor
            end
        end
    end)
end

AddMspaintDropdown(BoxTheme, "Màu Chủ Đạo (Accent Color)", {"Xanh Dương (Cyber)", "Tím Neon", "Hồng Cyberpunk", "Cyan Sáng", "Xanh Lá Neon", "Vàng Gold"}, "Xanh Dương (Cyber)", function(opt)
    local selectedColor = accentColors[opt]
    if selectedColor then
        UpdateThemeColor(selectedColor)
    end
end)

-- Sự kiện ẩn/hiện menu
local guiVisible = true
local function ToggleGUI()
    guiVisible = not guiVisible
    MainFrame.Visible = guiVisible
    ToggleButton.Text = guiVisible and "msp" or "❌"
end

CloseBtn.MouseButton1Click:Connect(ToggleGUI)
ToggleButton.MouseButton1Click:Connect(ToggleGUI)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.End then
        ToggleGUI()
    end
end)

print("✅ Thành Lợi Hub - AOT Revolution v20.6 (Dropdown Fixed) Loaded Successfully!")
