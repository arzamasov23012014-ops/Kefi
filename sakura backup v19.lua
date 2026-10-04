-- SAKURA V19 — новый дизайн меню, загрузочный экран, новые функции
-- Исправлено: синтаксис, tostring в Text, TeamCheck, респавн, ESP, Triggerbot,
-- предсказание, BunnyHop, FullReset (теперь Unload), Teleport, FPS, лаги и т.д.

-- Защита от двойного запуска: при повторном loadstring старая копия выгружается
local env = (getgenv and getgenv()) or _G
if env.SakuraUnload then
    pcall(env.SakuraUnload)
    env.SakuraUnload = nil
    task.wait(0.3)
end

local Players  = game:GetService("Players")
local RS       = game:GetService("RunService")
local UIS      = game:GetService("UserInputService")
local VU       = game:GetService("VirtualUser")
local Http     = game:GetService("HttpService")
local TeleportSvc = game:GetService("TeleportService")
local Stats    = game:GetService("Stats")
local GuiService = game:GetService("GuiService")
local TS       = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local WS       = game:GetService("Workspace")

local player = Players.LocalPlayer
local Camera = WS.CurrentCamera
local origFOV = Camera.FieldOfView
local char, hum, root
local Running = true

-- ============ УТИЛИТЫ ============
local errLog, ErrorHook = {}, nil
local lastErrMsg, lastErrTime = "", 0
local function SafeCall(f, fallback)
    local ok, res = pcall(f)
    if not ok then
        local msg = tostring(res)
        warn("🌸 SAKURA: " .. msg)
        if msg ~= lastErrMsg then
            errLog[#errLog + 1] = os.date("%H:%M:%S") .. "  " .. msg
            if #errLog > 60 then table.remove(errLog, 1) end
        end
        if ErrorHook and (msg ~= lastErrMsg or tick() - lastErrTime > 10) then ErrorHook(msg) end
        lastErrMsg, lastErrTime = msg, tick()
        return fallback
    end
    return res
end

local function New(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then
        o.Parent = parent
        local lay = parent:FindFirstChildOfClass("UIListLayout") or parent:FindFirstChildOfClass("UIGridLayout")
        if lay and o ~= lay and not o:IsA("UIBase") then o.LayoutOrder = #parent:GetChildren() end
    end
    return o
end

local function Round(o, r) New("UICorner", {CornerRadius = UDim.new(0, r)}, o) end

local function RainbowColor(speed) return Color3.fromHSV((tick() * speed) % 1, 1, 1) end

local function HealthColor(f)
    if f > 0.6 then return Color3.new(0, 1, 0) elseif f > 0.3 then return Color3.new(1, 1, 0) end
    return Color3.new(1, 0, 0)
end

-- ============ ЗАГРУЗОЧНЫЙ ЭКРАН ============
local Loader = {}
pcall(function()
    local pg = player:WaitForChild("PlayerGui", 10)
    local gui = Instance.new("ScreenGui")
    gui.Name = "SakuraLoading"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.Parent = pg
    local bg = New("CanvasGroup", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(14, 4, 26),
        BorderSizePixel = 0, GroupTransparency = 1}, gui)
    New("UIGradient", {Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(.45, .35, .6)), Rotation = 90}, bg)
    local function label(y, w, h, text, size, font, color)
        return New("TextLabel", {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, 0, .5, y),
            Size = UDim2.new(0, w, 0, h), BackgroundTransparency = 1, Text = text, TextSize = size, Font = font,
            TextColor3 = color}, bg)
    end
    label(-78, 200, 70, "🌸", 60, Enum.Font.GothamBold, Color3.new(1, 1, 1))
    label(-18, 300, 40, "SAKURA", 34, Enum.Font.GothamBlack, Color3.fromRGB(255, 120, 185))
    label(14, 300, 18, "V19", 12, Enum.Font.Gotham, Color3.fromRGB(200, 180, 220))
    local barBg = New("Frame", {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, 0, .5, 52),
        Size = UDim2.new(0, 260, 0, 8), BackgroundColor3 = Color3.fromRGB(40, 20, 60), BorderSizePixel = 0}, bg)
    Round(barBg, 4)
    local fill = New("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 102, 178),
        BorderSizePixel = 0}, barBg)
    Round(fill, 4)
    local status = label(78, 300, 18, "Запуск...", 12, Enum.Font.Gotham, Color3.fromRGB(210, 190, 230))
    TS:Create(bg, TweenInfo.new(0.35), {GroupTransparency = 0}):Play()
    Loader.gui, Loader.bg, Loader.fill, Loader.status = gui, bg, fill, status
    task.spawn(function()
        local rng = Random.new()
        while Loader.gui == gui do
            local x = rng:NextNumber()
            local petal = New("TextLabel", {BackgroundTransparency = 1, Text = "🌸", TextSize = rng:NextInteger(14, 26),
                TextTransparency = 0.35, Position = UDim2.new(x, 0, 0, -30), Size = UDim2.new(0, 30, 0, 30),
                Rotation = rng:NextInteger(0, 360)}, bg)
            local tw = TS:Create(petal, TweenInfo.new(rng:NextNumber(3, 5), Enum.EasingStyle.Sine),
                {Position = UDim2.new(x + rng:NextNumber(-0.1, 0.1), 0, 1, 30), Rotation = petal.Rotation + rng:NextInteger(-180, 180)})
            tw:Play()
            tw.Completed:Connect(function() petal:Destroy() end)
            task.wait(0.22)
        end
    end)
    task.delay(25, function() if Loader.gui == gui then Loader.Done() end end)
end)

function Loader.Step(text, pct)
    if not Loader.gui then return end
    pcall(function()
        Loader.status.Text = text
        TS:Create(Loader.fill, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
    end)
    task.wait(0.18)
end

function Loader.Done()
    local gui, bg = Loader.gui, Loader.bg
    Loader.gui = nil
    if not gui then return end
    pcall(function()
        Loader.status.Text = "Готово! 🌸"
        task.wait(0.25)
        local tw = TS:Create(bg, TweenInfo.new(0.5), {GroupTransparency = 1})
        tw:Play()
        tw.Completed:Wait()
    end)
    gui:Destroy()
end

-- ============ ПЕРСОНАЖ (обновляется при респавне) ============
local charCallbacks = {}
local origChar = {WalkSpeed = 16, UseJumpPower = true, JumpPower = 50, JumpHeight = 7.2}
local function BindChar(c)
    char = c
    hum = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
    origChar = {WalkSpeed = hum.WalkSpeed, UseJumpPower = hum.UseJumpPower,
        JumpPower = hum.JumpPower, JumpHeight = hum.JumpHeight}
    for _, cb in ipairs(charCallbacks) do task.spawn(SafeCall, cb) end
end
BindChar(player.Character or player.CharacterAdded:Wait())

Loader.Step("Загрузка конфигурации", 0.12)

-- ============ КОНФИГ ============
local Config = {
    ESP = {
        Enabled = false, Color = Color3.new(1, 0, 0), ColorMode = 0, -- 0 здоровье, 1 радуга, 2 фикс.
        TeamCheck = true, MaxDistance = 100000000, MinDistance = 0, UpdateRate = 0.1,
        Box = false, ShowName = true, ShowHealth = true, ShowDistance = true, ShowFriends = true,
        Lines = false, LineThickness = 2, LineOrigin = 1,
        Tracers = false, Arrow = false, HeadDot = false, Glow = false, Chams = false, Skeleton = false,
        Transparency = 0.6, OutlineTransparency = 0.2,
    },
    Aimbot = {
        Enabled = false, Mode = "Head", FOV = 200, Smoothness = 0.15,
        Prediction = true, PredictionMultiplier = 0.3,
        TeamCheck = true, Triggerbot = false, TriggerDelay = 0.1, AimLock = false, IgnoreWalls = true,
        TargetHUD = false,
    },
    Movement = {
        Speed = 16, JumpPower = 50, Noclip = false, Fly = false, FlySpeed = 60, InfJump = false,
        NoFall = false, AntiAFK = false, WaterWalk = false, AntiVoid = false,
        Freecam = false, FreecamSpeed = 40, Gravity = false, GravityValue = 100,
        BunnyHop = false, BunnyHopSpeed = 1.08, BunnyHopMax = 500,
    },
    Visuals = {
        FullBright = false, NoFog = false, XRay = false, NoShadows = false, ThirdPerson = false,
        ThirdPersonDistance = 15, NoRecoil = false, NoSpread = false, NoCameraShake = false,
        LowGraphics = false, Watermark = false, FPS = false, RainbowUI = false, NoEffects = false,
        CustomFOV = false, FOVValue = 70, Crosshair = false, TimeLock = false, TimeValue = 12,
        Radar = false, RadarRange = 200,
        NoPostFX = false, RainbowBody = false, Trail = false, Flashlight = false,
    },
    Ultra = {
        GodMode = false, Invisible = false, HitboxExtender = false, HitboxSize = 2.5,
        NoStun = false, NoKnockback = false, NoSound = false, Teleport = false, AntiFling = false,
        SpeedHack = false, SpeedHackMultiplier = 2,
    },
    Misc = {Notify = true, AutoSave = true, AutoRejoin = false},
}

local origLighting = {
    Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient, ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart, GlobalShadows = Lighting.GlobalShadows,
}

-- ============ STATE MANAGER ============
local SM = {connections = {}, objects = {}}
function SM:AddConnection(name, conn)
    self:RemoveConnection(name)
    self.connections[name] = conn
end
function SM:RemoveConnection(name)
    local c = self.connections[name]
    if c then SafeCall(function() c:Disconnect() end) self.connections[name] = nil end
end
function SM:Cleanup()
    for name in pairs(self.connections) do self:RemoveConnection(name) end
    for _, o in ipairs(self.objects) do SafeCall(function() o:Destroy() end) end
    self.objects = {}
end

-- ============ ТЕМА И ФИЧИ ============
local uiColors = {
    Color3.new(1, .4, .7), Color3.new(0, .8, 1), Color3.new(0, 1, 0), Color3.new(1, 1, 0),
    Color3.new(1, 0, 0), Color3.new(1, 0, 1), Color3.new(1, .5, 0), Color3.new(0, 1, 1),
    Color3.new(.3, .3, 1), Color3.new(1, .3, .3), Color3.new(.3, 1, .3), Color3.new(1, .8, .2),
}
local Themes = {
    {"Sakura", Color3.fromRGB(255, 102, 178), Color3.fromRGB(13, 3, 26)},
    {"Ocean",  Color3.fromRGB(0, 170, 255),   Color3.fromRGB(3, 10, 25)},
    {"Toxic",  Color3.fromRGB(80, 255, 80),   Color3.fromRGB(5, 15, 5)},
    {"Blood",  Color3.fromRGB(230, 40, 60),   Color3.fromRGB(20, 3, 5)},
    {"Gold",   Color3.fromRGB(255, 200, 50),  Color3.fromRGB(18, 14, 3)},
    {"Mono",   Color3.fromRGB(200, 200, 200), Color3.fromRGB(10, 10, 10)},
}
local themeIdx, uiColorIndex = 1, 0 -- uiColorIndex 0 = цвет темы
local bgColor, uiAlpha = Themes[1][3], 0.1
local function BaseAccent() return uiColorIndex > 0 and uiColors[uiColorIndex] or Themes[themeIdx][2] end
local uiColor = BaseAccent()
local ON_COLOR = Color3.new(0, .8, 0)

local themed, uiRefreshers = {}, {}
local mainFrame
local function Themed(o, prop) themed[#themed + 1] = {o, prop} end
local function AddRefresher(owner, fn) uiRefreshers[#uiRefreshers + 1] = {owner = owner, fn = fn} end
local function RefreshUI()
    for i = #uiRefreshers, 1, -1 do
        local r = uiRefreshers[i]
        if r.owner:IsDescendantOf(game) then SafeCall(r.fn) else table.remove(uiRefreshers, i) end
    end
end
local function ApplyTheme()
    for i = #themed, 1, -1 do
        local t = themed[i]
        if t[1]:IsDescendantOf(game) then t[1][t[2]] = uiColor else table.remove(themed, i) end
    end
    if mainFrame and mainFrame.Parent then
        mainFrame.BackgroundColor3, mainFrame.BackgroundTransparency = bgColor, uiAlpha
    end
    RefreshUI()
end

local function BindCam(name, fn)
    RS:BindToRenderStep("Sakura_" .. name, Enum.RenderPriority.Camera.Value + 1, fn)
    SM:AddConnection(name, {Disconnect = function() RS:UnbindFromRenderStep("Sakura_" .. name) end})
end

local toastGui, toastLbl, toastToken = nil, nil, 0
local function Toast(text)
    if not Running then return end
    SafeCall(function()
        if not toastGui or not toastGui.Parent then
            toastGui = New("ScreenGui", {Name = "SakuraToast", ResetOnSpawn = false, IgnoreGuiInset = true}, player.PlayerGui)
            toastLbl = New("TextLabel", {AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 8),
                Size = UDim2.new(0, 0, 0, 26), AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = Color3.new(.05, .01, .1), BackgroundTransparency = 0.2,
                TextColor3 = Color3.new(1, 1, 1), TextSize = 13, Font = Enum.Font.GothamBold,
                BorderSizePixel = 0, Visible = false}, toastGui)
            Round(toastLbl, 8)
            New("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, toastLbl)
            SM.objects[#SM.objects + 1] = toastGui
        end
        toastToken += 1
        local my = toastToken
        toastLbl.Text = text
        toastLbl.Visible = true
        task.delay(1.8, function() if my == toastToken and toastLbl then toastLbl.Visible = false end end)
    end)
end

ErrorHook = function(msg) Toast("⚠️ " .. msg:sub(1, 70)) end

local F, Features = {}, {}
local featureKeys = {}
local Loading = false
local MarkDirty = function() end
local function Feature(id, label, tbl, key, apply)
    local f = {Id = id, Label = label, Tbl = tbl, Key = key}
    featureKeys[tbl] = featureKeys[tbl] or {}
    featureKeys[tbl][key] = true
    function f.Set(state)
        state = state and true or false
        if tbl[key] == state then return end
        tbl[key] = state
        SafeCall(function() if apply then apply(state) end end)
        if Config.Misc.Notify and not Loading then Toast((state and "✅ " or "❌ ") .. label) end
        RefreshUI()
        MarkDirty()
    end
    function f.Toggle() f.Set(not tbl[key]) end
    F[id] = f
    Features[#Features + 1] = f
    return f
end

-- ============ ИГРОКИ / ЦЕЛИ ============
local function IsAlive(plr)
    local c = plr and plr.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h ~= nil and h.Health > 0
end

local friends = {}   -- [UserId] = true
local spectating
local function IsEnemy(plr, teamCheck)
    if plr == player then return false end
    if friends[plr.UserId] then return false end
    if teamCheck and player.Team and plr.Team == player.Team then return false end
    return true
end

local function GetPart(c, mode)
    if not c then return nil end
    if mode == "Head" then return c:FindFirstChild("Head") end
    if mode == "Torso" then return c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso") end
    return c:FindFirstChild("HumanoidRootPart")
end

Loader.Step("Модули движения", 0.28)

-- ============ ДВИЖЕНИЕ ============
local M = Config.Movement
local speedTouched, jumpTouched = false, false

local function ApplySpeed()
    if not hum or M.BunnyHop or not speedTouched then return end
    hum.WalkSpeed = M.Speed * (Config.Ultra.SpeedHack and Config.Ultra.SpeedHackMultiplier or 1)
end
local function ApplyJump()
    if hum and jumpTouched then hum.UseJumpPower = true hum.JumpPower = M.JumpPower end
end

local ncSaved = {}
Feature("Noclip", "Noclip (N)", M, "Noclip", function(on)
    if on then
        SM:AddConnection("Noclip", RS.Stepped:Connect(function()
            if not char then return end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then ncSaved[p] = true p.CanCollide = false end
            end
        end))
    else
        SM:RemoveConnection("Noclip")
        for p in pairs(ncSaved) do if p.Parent then p.CanCollide = true end end
        ncSaved = {}
    end
end)

Feature("InfJump", "InfJump", M, "InfJump", function(on)
    if on then
        SM:AddConnection("InfJump", UIS.JumpRequest:Connect(function()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end))
    else SM:RemoveConnection("InfJump") end
end)

local flyBV
Feature("Fly", "Fly (F)", M, "Fly", function(on)
    if on then
        SM:AddConnection("Fly", RS.RenderStepped:Connect(function()
            if not root or not hum then return end
            if not flyBV or flyBV.Parent ~= root then
                if flyBV then flyBV:Destroy() end
                flyBV = New("BodyVelocity", {MaxForce = Vector3.new(1e5, 1e5, 1e5), Velocity = Vector3.zero}, root)
            end
            hum.PlatformStand = true
            local move = hum.MoveDirection
            if move.Magnitude > 0 then
                local look = Camera.CFrame.LookVector
                local flat = Vector3.new(look.X, 0, look.Z)
                local sign = (flat.Magnitude > 0 and move:Dot(flat.Unit) < 0) and -1 or 1
                flyBV.Velocity = Vector3.new(move.X, look.Y * sign, move.Z) * M.FlySpeed
            else
                flyBV.Velocity = Vector3.zero
            end
        end))
    else
        SM:RemoveConnection("Fly")
        if flyBV then flyBV:Destroy() flyBV = nil end
        if hum then hum.PlatformStand = false end
    end
end)

Feature("AntiAFK", "AntiAFK", M, "AntiAFK", function(on)
    if on then
        SM:AddConnection("AntiAFK", player.Idled:Connect(function()
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
        end))
    else SM:RemoveConnection("AntiAFK") end
end)

local waterPlat
Feature("WaterWalk", "WaterWalk", M, "WaterWalk", function(on)
    if on then
        waterPlat = New("Part", {Size = Vector3.new(10, 1, 10), Anchored = true, Transparency = 1,
            CFrame = CFrame.new(0, -1e4, 0)}, WS)
        SM:AddConnection("WaterWalk", RS.Heartbeat:Connect(function()
            if not root or not waterPlat then return end
            local p = RaycastParams.new()
            p.FilterType = Enum.RaycastFilterType.Exclude
            p.FilterDescendantsInstances = {char, waterPlat}
            p.IgnoreWater = false
            local r = WS:Raycast(root.Position, Vector3.new(0, -8, 0), p)
            if r and r.Material == Enum.Material.Water then
                waterPlat.CFrame = CFrame.new(root.Position.X, r.Position.Y - 0.5, root.Position.Z)
            else
                waterPlat.CFrame = CFrame.new(0, -1e4, 0)
            end
        end))
    else
        SM:RemoveConnection("WaterWalk")
        if waterPlat then waterPlat:Destroy() waterPlat = nil end
    end
end)

Feature("NoFall", "NoFall", M, "NoFall", function(on)
    if on then
        SM:AddConnection("NoFall", RS.Stepped:Connect(function()
            if root then
                local v = root.AssemblyLinearVelocity
                if v.Y < -50 then root.AssemblyLinearVelocity = Vector3.new(v.X, -30, v.Z) end
            end
        end))
    else SM:RemoveConnection("NoFall") end
end)

-- ---------- BunnyHop ----------
local bhopSpeed, bhopHeld, lastJump = 16, false, 0
local bhopGui, bhopLabel

local function CreateBhopGui()
    bhopGui = New("ScreenGui", {Name = "SakuraBhop", ResetOnSpawn = false}, player.PlayerGui)
    local frame = New("Frame", {Size = UDim2.new(0, 160, 0, 40), Position = UDim2.new(0.5, -80, 0, 60),
        BackgroundColor3 = Color3.fromRGB(255, 80, 180), BackgroundTransparency = 0.2, BorderSizePixel = 0}, bhopGui)
    Round(frame, 10)
    bhopLabel = New("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "🐰 BHOP: 16",
        TextColor3 = Color3.new(1, 1, 1), TextSize = 16, Font = Enum.Font.GothamBold}, frame)
    local btn = New("TextButton", {Size = UDim2.new(0, 70, 0, 70), Position = UDim2.new(1, -180, 1, -180),
        BackgroundColor3 = Color3.fromRGB(255, 80, 180), BackgroundTransparency = 0.2, Text = "🐰",
        TextSize = 32, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1), ZIndex = 100}, bhopGui)
    Round(btn, 35)
    local function isPress(i) return i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 end
    btn.InputBegan:Connect(function(i) if isPress(i) then bhopHeld = true btn.BackgroundTransparency = 0.5 end end)
    btn.InputEnded:Connect(function(i) if isPress(i) then bhopHeld = false btn.BackgroundTransparency = 0.2 end end)
end

Feature("BunnyHop", "🐰 BunnyHop (B)", M, "BunnyHop", function(on)
    if on then
        if Config.Ultra.SpeedHack then F.SpeedHack.Set(false) end
        bhopSpeed = M.Speed
        CreateBhopGui()
        SM:AddConnection("Bhop", RS.Heartbeat:Connect(function()
            if not hum then return end
            local grounded = hum.FloorMaterial ~= Enum.Material.Air
            local want = UIS:IsKeyDown(Enum.KeyCode.Space) or bhopHeld
            if grounded and tick() - lastJump > 0.2 then
                if want then
                    hum.Jump = true
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    bhopSpeed = math.min(bhopSpeed * M.BunnyHopSpeed, M.BunnyHopMax)
                    hum.WalkSpeed = bhopSpeed
                    lastJump = tick()
                else
                    bhopSpeed = M.Speed
                    hum.WalkSpeed = M.Speed
                end
                if bhopLabel then bhopLabel.Text = "🐰 BHOP: " .. math.floor(bhopSpeed) end
            end
        end))
    else
        SM:RemoveConnection("Bhop")
        bhopHeld = false
        if bhopGui then bhopGui:Destroy() bhopGui, bhopLabel = nil, nil end
        if hum then hum.WalkSpeed = M.Speed end
        ApplySpeed()
    end
end)

Feature("AntiVoid", "🕳 Anti-Void", M, "AntiVoid", function(on)
    if on then
        local lastSafe
        SM:AddConnection("AntiVoid", RS.Heartbeat:Connect(function()
            if not root or not hum then return end
            if hum.FloorMaterial ~= Enum.Material.Air then lastSafe = root.CFrame end
            if lastSafe and root.Position.Y < WS.FallenPartsDestroyHeight + 80 then
                root.AssemblyLinearVelocity = Vector3.zero
                root.CFrame = lastSafe + Vector3.new(0, 5, 0)
            end
        end))
    else SM:RemoveConnection("AntiVoid") end
end)

local fcCF, fcYaw, fcPitch = CFrame.new(), 0, 0
Feature("Freecam", "🎥 Freecam", M, "Freecam", function(on)
    if on then
        if M.Fly then F.Fly.Set(false) end
        fcCF = Camera.CFrame
        fcPitch, fcYaw = fcCF:ToEulerAnglesYXZ()
        if root then root.Anchored = true end
        Camera.CameraType = Enum.CameraType.Scriptable
        SM:AddConnection("FreecamLook", UIS.InputChanged:Connect(function(i, gp)
            if gp then return end
            if i.UserInputType == Enum.UserInputType.Touch
                or (i.UserInputType == Enum.UserInputType.MouseMovement and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) then
                fcYaw = fcYaw - i.Delta.X * 0.005
                fcPitch = math.clamp(fcPitch - i.Delta.Y * 0.005, -1.5, 1.5)
            end
        end))
        BindCam("Freecam", function(dt)
            local rot = CFrame.fromEulerAnglesYXZ(fcPitch, fcYaw, 0)
            local move = hum and hum.MoveDirection or Vector3.zero
            local pos = fcCF.Position
            if move.Magnitude > 0 then
                local lv = rot.LookVector
                local flat = Vector3.new(lv.X, 0, lv.Z)
                local sign = (flat.Magnitude > 0 and move:Dot(flat.Unit) < 0) and -1 or 1
                pos = pos + Vector3.new(move.X, lv.Y * sign, move.Z) * M.FreecamSpeed * dt
            end
            fcCF = CFrame.new(pos) * rot
            Camera.CFrame = fcCF
        end)
    else
        SM:RemoveConnection("FreecamLook")
        SM:RemoveConnection("Freecam")
        if root then root.Anchored = false end
        Camera.CameraType = Enum.CameraType.Custom
        if hum then Camera.CameraSubject = hum end
    end
end)

local gravSaved
Feature("Gravity", "🪐 Гравитация", M, "Gravity", function(on)
    if on then
        gravSaved = WS.Gravity
        SM:AddConnection("Gravity", RS.Heartbeat:Connect(function() WS.Gravity = M.GravityValue end))
    else
        SM:RemoveConnection("Gravity")
        if gravSaved then WS.Gravity = gravSaved gravSaved = nil end
    end
end)

-- ============ ULTRA ============
local U = Config.Ultra

local invSaved = {}
Feature("Invisible", "👻 Invisible (I)", U, "Invisible", function(on)
    if on then
        SM:AddConnection("Invisible", RS.Stepped:Connect(function()
            if not char then return end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") or p:IsA("Decal") then
                    if invSaved[p] == nil then invSaved[p] = p.Transparency end
                    p.Transparency = 1
                end
            end
        end))
    else
        SM:RemoveConnection("Invisible")
        for p, t in pairs(invSaved) do if p.Parent then p.Transparency = t end end
        invSaved = {}
    end
end)

Feature("GodMode", "🛡️ God Mode (G)", U, "GodMode", function(on)
    if on then
        SM:AddConnection("GodMode", RS.Heartbeat:Connect(function()
            if hum then hum.Health = hum.MaxHealth end
        end))
    else SM:RemoveConnection("GodMode") end
end)

Feature("NoKnockback", "🚫 Anti Knockback", U, "NoKnockback", function(on)
    if on then
        SM:AddConnection("AntiKB", RS.Heartbeat:Connect(function()
            if not hum or not root then return end
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.Ragdoll
                or st == Enum.HumanoidStateType.Physics then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            -- гасим толчки только когда стоим на месте (иначе сломаем ходьбу)
            if hum.MoveDirection.Magnitude == 0 and hum.FloorMaterial ~= Enum.Material.Air then
                local v = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
            end
        end))
    else SM:RemoveConnection("AntiKB") end
end)

local sndSaved = {}
Feature("NoSound", "🔇 No Sound", U, "NoSound", function(on)
    if on then
        for _, s in ipairs(WS:GetDescendants()) do
            if s:IsA("Sound") then sndSaved[s] = s.Volume s.Volume = 0 end
        end
        SM:AddConnection("NoSound", WS.DescendantAdded:Connect(function(s)
            if s:IsA("Sound") then sndSaved[s] = s.Volume s.Volume = 0 end
        end))
    else
        SM:RemoveConnection("NoSound")
        for s, v in pairs(sndSaved) do if s.Parent then s.Volume = v end end
        sndSaved = {}
    end
end)

local stunStates = {Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.FallingDown,
    Enum.HumanoidStateType.PlatformStanding}
local function SetStunStates(enabled)
    if not hum then return end
    for _, s in ipairs(stunStates) do hum:SetStateEnabled(s, enabled) end
end
Feature("NoStun", "⛔ No Stun", U, "NoStun", function(on) SetStunStates(not on) end)

Feature("SpeedHack", "⚡ Волчек (X)", U, "SpeedHack", function(on)
    if on then
        if M.BunnyHop then F.BunnyHop.Set(false) end
        speedTouched = true
        SM:AddConnection("SpeedHack", RS.Stepped:Connect(ApplySpeed))
    else
        SM:RemoveConnection("SpeedHack")
        ApplySpeed()
    end
end)

local function TeleportTo(pos)
    if root and pos then root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
end
Feature("Teleport", "🌀 Teleport", U, "Teleport", function(on)
    if on then
        local mouse = player:GetMouse()
        SM:AddConnection("TeleportPC", UIS.InputBegan:Connect(function(input, gp)
            if gp or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) and mouse.Hit then TeleportTo(mouse.Hit.Position) end
        end))
        SM:AddConnection("TeleportTouch", UIS.TouchTapInWorld:Connect(function(pos, processed)
            if processed then return end
            local ray = Camera:ViewportPointToRay(pos.X, pos.Y)
            local p = RaycastParams.new()
            p.FilterType = Enum.RaycastFilterType.Exclude
            p.FilterDescendantsInstances = {char}
            local r = WS:Raycast(ray.Origin, ray.Direction * 1000, p)
            if r then TeleportTo(r.Position) end
        end))
    else
        SM:RemoveConnection("TeleportPC")
        SM:RemoveConnection("TeleportTouch")
    end
end)

local flingSaved = {}
Feature("AntiFling", "🛡 Анти-флинг", U, "AntiFling", function(on)
    if on then
        SM:AddConnection("AntiFling", RS.Stepped:Connect(function()
            for _, plr in ipairs(Players:GetPlayers()) do
                local c = plr ~= player and plr.Character
                if c then
                    for _, p in ipairs(c:GetChildren()) do
                        if p:IsA("BasePart") and p.CanCollide then flingSaved[p] = true p.CanCollide = false end
                    end
                end
            end
            if root and not M.Fly and not M.BunnyHop and root.AssemblyLinearVelocity.Magnitude > 300 then
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end))
    else
        SM:RemoveConnection("AntiFling")
        for p in pairs(flingSaved) do if p.Parent then p.CanCollide = true end end
        flingSaved = {}
    end
end)

-- Hitbox
local hbSaved = setmetatable({}, {__mode = "k"})
local function HitboxApply()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            for _, part in ipairs(plr.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    if not hbSaved[part] then hbSaved[part] = part.Size end
                    part.Size = hbSaved[part] * U.HitboxSize
                end
            end
        end
    end
end
Feature("Hitbox", "Hitbox Extender", U, "HitboxExtender", function(on)
    if on then
        HitboxApply()
        local last = 0
        SM:AddConnection("Hitbox", RS.Heartbeat:Connect(function()
            if tick() - last > 1 then last = tick() HitboxApply() end
        end))
    else
        SM:RemoveConnection("Hitbox")
        for part, size in pairs(hbSaved) do if part.Parent then part.Size = size end end
        hbSaved = setmetatable({}, {__mode = "k"})
    end
end)

Loader.Step("Визуальные эффекты", 0.44)

-- ============ ВИЗУАЛЫ ============
local V = Config.Visuals

local xraySaved = {}
local function XrayPart(o)
    if o:IsA("BasePart") and not o:IsA("Terrain") and o.Transparency < 0.3
        and not (o.Parent and o.Parent:FindFirstChildOfClass("Humanoid")) then
        xraySaved[o] = o.Transparency
        o.Transparency = 0.3
    end
end
Feature("XRay", "👀 X-Ray", V, "XRay", function(on)
    if on then
        for _, o in ipairs(WS:GetDescendants()) do XrayPart(o) end
        SM:AddConnection("XRay", WS.DescendantAdded:Connect(XrayPart))
    else
        SM:RemoveConnection("XRay")
        for o, t in pairs(xraySaved) do if o.Parent then o.Transparency = t end end
        xraySaved = {}
    end
end)

local fbSaved
Feature("FullBright", "☀️ Full Bright", V, "FullBright", function(on)
    if on then
        fbSaved = {Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient, ClockTime = Lighting.ClockTime}
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.ClockTime = 12
    elseif fbSaved then
        for k, v in pairs(fbSaved) do Lighting[k] = v end
        fbSaved = nil
    end
end)

local fogSaved
Feature("NoFog", "🌫️ No Fog", V, "NoFog", function(on)
    if on then
        fogSaved = {FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart, atm = {}}
        Lighting.FogEnd, Lighting.FogStart = 1e6, 0
        for _, a in ipairs(Lighting:GetChildren()) do
            if a:IsA("Atmosphere") then fogSaved.atm[a] = a.Density a.Density = 0 end
        end
    elseif fogSaved then
        Lighting.FogEnd, Lighting.FogStart = fogSaved.FogEnd, fogSaved.FogStart
        for a, d in pairs(fogSaved.atm) do if a.Parent then a.Density = d end end
        fogSaved = nil
    end
end)

Feature("RainbowUI", "🌈 Радужный UI", V, "RainbowUI", function(on)
    if on then
        SM:AddConnection("RainbowUI", RS.RenderStepped:Connect(function()
            uiColor = RainbowColor(0.3)
            ApplyTheme()
        end))
    else
        SM:RemoveConnection("RainbowUI")
        uiColor = BaseAccent()
        ApplyTheme()
    end
end)

local wmGui
Feature("Watermark", "💧 Watermark", V, "Watermark", function(on)
    if on then
        wmGui = New("ScreenGui", {Name = "SakuraWatermark", ResetOnSpawn = false}, player.PlayerGui)
        local l = New("TextLabel", {Size = UDim2.new(0, 220, 0, 28), Position = UDim2.new(0.5, -110, 0, 10),
            BackgroundColor3 = Color3.new(.05, .01, .1), BackgroundTransparency = 0.2, BorderSizePixel = 0,
            Text = "🌸 SAKURA V19", TextColor3 = Color3.new(1, 1, 1), TextSize = 14, Font = Enum.Font.GothamBold}, wmGui)
        Round(l, 10)
    elseif wmGui then wmGui:Destroy() wmGui = nil end
end)

local shadowSaved = {}
local function NoShadowPart(o)
    if o:IsA("BasePart") and o.CastShadow then shadowSaved[o] = true o.CastShadow = false end
end
Feature("NoShadows", "🌑 No Shadow", V, "NoShadows", function(on)
    if on then
        for _, o in ipairs(WS:GetDescendants()) do NoShadowPart(o) end
        SM:AddConnection("NoShadow", WS.DescendantAdded:Connect(NoShadowPart))
    else
        SM:RemoveConnection("NoShadow")
        for o in pairs(shadowSaved) do if o.Parent then o.CastShadow = true end end
        shadowSaved = {}
    end
end)

Feature("NoCameraShake", "📷 No Camera Shake", V, "NoCameraShake", function(on)
    if on then
        BindCam("NoShake", function()
            if hum then hum.CameraOffset = Vector3.zero end
        end)
    else SM:RemoveConnection("NoShake") end
end)

Feature("NoRecoil", "🔫 No Recoil", V, "NoRecoil", function(on)
    if on then
        SM:AddConnection("NoRecoil", RS.Heartbeat:Connect(function()
            local tool = char and char:FindFirstChildOfClass("Tool")
            local r = tool and tool:FindFirstChild("Recoil")
            if r then r:Destroy() end
        end))
    else SM:RemoveConnection("NoRecoil") end
end)

Feature("NoSpread", "🎯 No Spread", V, "NoSpread", function(on)
    if on then
        local last = 0
        SM:AddConnection("NoSpread", RS.Heartbeat:Connect(function()
            if tick() - last < 0.5 then return end
            last = tick()
            local tool = char and char:FindFirstChildOfClass("Tool")
            if not tool then return end
            for _, o in ipairs(tool:GetDescendants()) do
                if o:IsA("NumberValue") and o.Name:find("Spread") then o.Value = 0 end
            end
        end))
    else SM:RemoveConnection("NoSpread") end
end)

local tpSaved
Feature("ThirdPerson", "👤 Third Person", V, "ThirdPerson", function(on)
    if on then
        tpSaved = {min = player.CameraMinZoomDistance, max = player.CameraMaxZoomDistance}
        player.CameraMaxZoomDistance = V.ThirdPersonDistance
        player.CameraMinZoomDistance = V.ThirdPersonDistance
    elseif tpSaved then
        player.CameraMinZoomDistance, player.CameraMaxZoomDistance = tpSaved.min, tpSaved.max
        tpSaved = nil
    end
end)

local lowSaved, lowShadows = {}, nil
Feature("LowGraphics", "💻 Low Graphics", V, "LowGraphics", function(on)
    if on then
        lowShadows = Lighting.GlobalShadows
        Lighting.GlobalShadows = false
        for _, o in ipairs(WS:GetDescendants()) do
            if o:IsA("BasePart") and not o:IsA("Terrain") then lowSaved[o] = o.Material o.Material = Enum.Material.SmoothPlastic end
        end
    else
        Lighting.GlobalShadows = lowShadows ~= nil and lowShadows or origLighting.GlobalShadows
        for o, m in pairs(lowSaved) do if o.Parent then o.Material = m end end
        lowSaved = {}
    end
end)

local effSaved = {}
local function IsEffect(o)
    return o:IsA("ParticleEmitter") or o:IsA("Fire") or o:IsA("Smoke") or o:IsA("Sparkles")
        or o:IsA("Trail") or o:IsA("Beam")
end
local function KillEffect(o) if IsEffect(o) and o.Enabled then effSaved[o] = true o.Enabled = false end end
Feature("NoEffects", "🚫 No Effects", V, "NoEffects", function(on)
    if on then
        for _, o in ipairs(WS:GetDescendants()) do KillEffect(o) end
        SM:AddConnection("NoEffects", WS.DescendantAdded:Connect(KillEffect))
    else
        SM:RemoveConnection("NoEffects")
        for o in pairs(effSaved) do if o.Parent then o.Enabled = true end end
        effSaved = {}
    end
end)

local fpsGui
Feature("FPS", "⚡ FPS HUD", V, "FPS", function(on)
    if on then
        fpsGui = New("ScreenGui", {Name = "SakuraFPS", ResetOnSpawn = false}, player.PlayerGui)
        local fr = New("Frame", {Size = UDim2.new(0, 140, 0, 32), Position = UDim2.new(0, 10, 1, -42),
            BackgroundColor3 = Color3.new(.08, .02, .12), BackgroundTransparency = 0.2, BorderSizePixel = 0}, fpsGui)
        Round(fr, 8)
        local lbl = New("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "⚡ 0",
            TextColor3 = Color3.new(0, 1, 0), TextSize = 16, Font = Enum.Font.GothamBold}, fr)
        local acc, frames = 0, 0
        SM:AddConnection("FPS", RS.Heartbeat:Connect(function(dt)
            acc += dt frames += 1
            if acc >= 0.5 then
                local fps = math.round(frames / acc)
                acc, frames = 0, 0
                local ping = SafeCall(function() return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end, 0)
                lbl.Text = "⚡ " .. fps .. " · " .. ping .. "ms"
                lbl.TextColor3 = HealthColor(fps / 60)
            end
        end))
    else
        SM:RemoveConnection("FPS")
        if fpsGui then fpsGui:Destroy() fpsGui = nil end
    end
end)

local pfxSaved = {}
local function KillPFX(o)
    if (o:IsA("BlurEffect") or o:IsA("ColorCorrectionEffect") or o:IsA("BloomEffect")
        or o:IsA("DepthOfFieldEffect") or o:IsA("SunRaysEffect")) and o.Enabled then
        pfxSaved[o] = true o.Enabled = false
    end
end
Feature("NoPostFX", "✨ Без пост-эффектов", V, "NoPostFX", function(on)
    if on then
        for _, o in ipairs(Lighting:GetChildren()) do KillPFX(o) end
        for _, o in ipairs(Camera:GetChildren()) do KillPFX(o) end
        SM:AddConnection("NoPostFX", Lighting.ChildAdded:Connect(KillPFX))
    else
        SM:RemoveConnection("NoPostFX")
        for o in pairs(pfxSaved) do if o.Parent then o.Enabled = true end end
        pfxSaved = {}
    end
end)

local rbSaved = {}
Feature("RainbowBody", "🌈 Радужное тело", V, "RainbowBody", function(on)
    if on then
        SM:AddConnection("RainbowBody", RS.Heartbeat:Connect(function()
            if not char then return end
            local col = Color3.fromHSV((tick() * 0.4) % 1, 0.8, 1)
            for _, p in ipairs(char:GetChildren()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    if rbSaved[p] == nil then rbSaved[p] = p.Color end
                    p.Color = col
                end
            end
        end))
    else
        SM:RemoveConnection("RainbowBody")
        for p, c in pairs(rbSaved) do if p.Parent then p.Color = c end end
        rbSaved = {}
    end
end)

Feature("Trail", "💫 След", V, "Trail", function(on)
    local function clear()
        if root then
            for _, n in ipairs({"SakuraTrail", "SakuraA0", "SakuraA1"}) do
                local o = root:FindFirstChild(n)
                if o then o:Destroy() end
            end
        end
    end
    if on then
        local last = 0
        SM:AddConnection("Trail", RS.Heartbeat:Connect(function()
            if tick() - last < 0.5 or not root then return end
            last = tick()
            if not root:FindFirstChild("SakuraTrail") then
                local a0 = New("Attachment", {Name = "SakuraA0", Position = Vector3.new(0, 1, 0)}, root)
                local a1 = New("Attachment", {Name = "SakuraA1", Position = Vector3.new(0, -1, 0)}, root)
                New("Trail", {Name = "SakuraTrail", Attachment0 = a0, Attachment1 = a1, Lifetime = 0.7,
                    LightEmission = 1, Color = ColorSequence.new(uiColor, Color3.new(1, 1, 1)),
                    Transparency = NumberSequence.new(0.2, 1)}, root)
            end
        end))
    else
        SM:RemoveConnection("Trail")
        clear()
    end
end)

Feature("Flashlight", "💡 Фонарик", V, "Flashlight", function(on)
    if on then
        SM:AddConnection("Flashlight", RS.Heartbeat:Connect(function()
            local head = char and char:FindFirstChild("Head")
            if head and not head:FindFirstChild("SakuraLight") then
                New("PointLight", {Name = "SakuraLight", Range = 40, Brightness = 2}, head)
            end
        end))
    else
        SM:RemoveConnection("Flashlight")
        local head = char and char:FindFirstChild("Head")
        local l = head and head:FindFirstChild("SakuraLight")
        if l then l:Destroy() end
    end
end)

local radarGui
local radarDots = {}
Feature("Radar", "📡 Радар", V, "Radar", function(on)
    if on then
        radarGui = New("ScreenGui", {Name = "SakuraRadar", ResetOnSpawn = false}, player.PlayerGui)
        local rf = New("Frame", {Size = UDim2.new(0, 130, 0, 130), Position = UDim2.new(1, -140, 0, 60),
            BackgroundColor3 = Color3.new(.05, .01, .1), BackgroundTransparency = 0.3, BorderSizePixel = 0,
            ClipsDescendants = true}, radarGui)
        Round(rf, 65)
        New("UIStroke", {Color = uiColor, Thickness = 2}, rf)
        New("Frame", {Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(.5, -3, .5, -3),
            BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, rf)
        radarDots = {}
        SM:AddConnection("Radar", RS.RenderStepped:Connect(function()
            if not root then return end
            local look = Camera.CFrame.LookVector
            local flat = Vector3.new(look.X, 0, look.Z)
            if flat.Magnitude < 0.01 then return end
            local cf = CFrame.lookAt(Vector3.zero, flat.Unit)
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player then
                    local c = plr.Character
                    local r = c and c:FindFirstChild("HumanoidRootPart")
                    local dot = radarDots[plr]
                    if r and IsAlive(plr) then
                        if not dot then
                            dot = New("Frame", {Size = UDim2.new(0, 6, 0, 6), BorderSizePixel = 0}, rf)
                            Round(dot, 3)
                            radarDots[plr] = dot
                        end
                        local rel = r.Position - root.Position
                        local o = cf:VectorToObjectSpace(Vector3.new(rel.X, 0, rel.Z)) / V.RadarRange * 60
                        local v = Vector2.new(o.X, o.Z)
                        if v.Magnitude > 60 then v = v.Unit * 60 end
                        dot.Position = UDim2.new(0.5, v.X - 3, 0.5, v.Y - 3)
                        dot.BackgroundColor3 = friends[plr.UserId] and Color3.fromRGB(60, 255, 120)
                            or ((player.Team and plr.Team == player.Team) and Color3.fromRGB(80, 160, 255)
                            or Color3.fromRGB(255, 60, 60))
                        dot.Visible = true
                    elseif dot then dot.Visible = false end
                end
            end
            for plr, dot in pairs(radarDots) do
                if not plr.Parent then dot:Destroy() radarDots[plr] = nil end
            end
        end))
    else
        SM:RemoveConnection("Radar")
        if radarGui then radarGui:Destroy() radarGui = nil end
        radarDots = {}
    end
end)

local fovSaved
Feature("CustomFOV", "🔭 FOV", V, "CustomFOV", function(on)
    if on then
        fovSaved = Camera.FieldOfView
        BindCam("CustomFOV", function() Camera.FieldOfView = V.FOVValue end)
    else
        SM:RemoveConnection("CustomFOV")
        if fovSaved then Camera.FieldOfView = fovSaved fovSaved = nil end
    end
end)

local chGui
Feature("Crosshair", "➕ Прицел", V, "Crosshair", function(on)
    if on then
        chGui = New("ScreenGui", {Name = "SakuraCrosshair", ResetOnSpawn = false, IgnoreGuiInset = true}, player.PlayerGui)
        local function bar(w, h)
            New("Frame", {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, 0, .5, 0),
                Size = UDim2.new(0, w, 0, h), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, chGui)
        end
        bar(14, 2) bar(2, 14)
    elseif chGui then chGui:Destroy() chGui = nil end
end)

local timeSaved
Feature("TimeLock", "🕐 Фикс. время", V, "TimeLock", function(on)
    if on then
        timeSaved = Lighting.ClockTime
        SM:AddConnection("TimeLock", RS.Heartbeat:Connect(function() Lighting.ClockTime = V.TimeValue end))
    else
        SM:RemoveConnection("TimeLock")
        if timeSaved then Lighting.ClockTime = timeSaved timeSaved = nil end
    end
end)

-- Точки, респавн, реджойн
local waypoints = {}
local function RespawnHere()
    if not root or not char then return end
    local cf = root.CFrame
    local conn
    conn = player.CharacterAdded:Connect(function(c)
        conn:Disconnect()
        local r = c:WaitForChild("HumanoidRootPart", 5)
        if r then task.wait(0.15) r.CFrame = cf end
    end)
    char:BreakJoints()
end
local function Rejoin(sameServer)
    if sameServer and game.JobId ~= "" then
        TeleportSvc:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    else
        TeleportSvc:Teleport(game.PlaceId, player)
    end
end
Feature("AutoRejoin", "🔁 Авто-реджойн", Config.Misc, "AutoRejoin", function(on)
    if on then
        SM:AddConnection("AutoRejoin", GuiService.ErrorMessageChanged:Connect(function(msg)
            if msg and msg ~= "" then task.wait(3) SafeCall(function() Rejoin(true) end) end
        end))
    else SM:RemoveConnection("AutoRejoin") end
end)

Loader.Step("ESP система", 0.58)

-- ============ ESP ============
local E = Config.ESP
local hasDrawing = type(Drawing) == "table" or type(Drawing) == "userdata"

local R15 = {{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"}}
local R6 = {{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}}

local function NewDraw(kind, props)
    if not hasDrawing then return nil end
    return SafeCall(function()
        local d = Drawing.new(kind)
        for k, v in pairs(props) do d[k] = v end
        return d
    end)
end
local function KillDraw(o)
    if not o then return end
    SafeCall(function() if o.Remove then o:Remove() else o:Destroy() end end)
end

local ESP = {data = {}, last = 0}

function ESP:Remove(plr)
    local d = self.data[plr]
    if not d then return end
    self.data[plr] = nil
    for _, k in ipairs({"Highlight", "Gui", "Dot", "Box", "Line"}) do
        if d[k] then SafeCall(function() d[k]:Destroy() end) end
    end
    for part, m in pairs(d.Mats) do SafeCall(function() if part.Parent then part.Material = m end end) end
    KillDraw(d.Tracer) KillDraw(d.Arrow)
    for _, l in ipairs(d.Lines) do KillDraw(l.line) end
end

function ESP:Clear()
    for plr in pairs(self.data) do self:Remove(plr) end
    if self.linesGui then self.linesGui:Destroy() self.linesGui = nil end
end

-- Линии до игроков (рисуются обычными GUI-рамками, Drawing не нужен)
function ESP:UpdateLines()
    if not E.Lines then return end
    if not self.linesGui or not self.linesGui.Parent then
        self.linesGui = New("ScreenGui", {Name = "SakuraLines", ResetOnSpawn = false, IgnoreGuiInset = true,
            DisplayOrder = -1}, player.PlayerGui)
    end
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local origin = E.LineOrigin == 1 and Vector2.new(vp.X / 2, vp.Y)
        or (E.LineOrigin == 3 and Vector2.new(vp.X / 2, 0) or center)
    for _, d in pairs(self.data) do
        local fr = d.Line
        local target = d.Show and d.Char and d.Char:FindFirstChild("HumanoidRootPart")
        if target then
            if not fr then
                fr = New("Frame", {AnchorPoint = Vector2.new(.5, .5), BorderSizePixel = 0,
                    BackgroundTransparency = 0.15}, self.linesGui)
                d.Line = fr
            end
            local p = Camera:WorldToViewportPoint(target.Position)
            local pt = Vector2.new(p.X, p.Y)
            if p.Z < 0 then pt = center - (pt - center) end
            local v = pt - origin
            if v.Magnitude > 4000 then pt = origin + v.Unit * 4000 v = pt - origin end
            fr.BackgroundColor3 = d.Color or E.Color
            fr.Size = UDim2.new(0, v.Magnitude, 0, E.LineThickness)
            fr.Position = UDim2.new(0, (origin.X + pt.X) / 2, 0, (origin.Y + pt.Y) / 2)
            fr.Rotation = math.deg(math.atan2(v.Y, v.X))
            fr.Visible = true
        elseif fr then
            fr.Visible = false
        end
    end
end

function ESP:Create(plr)
    local c = plr.Character
    if not c then return end
    local d = self.data[plr]
    if d and d.Char == c then return end
    if d then self:Remove(plr) end
    local head, h = c:FindFirstChild("Head"), c:FindFirstChildOfClass("Humanoid")
    if not head or not h then return end

    d = {Char = c, Mats = {}, Lines = {}}
    d.Highlight = New("Highlight", {Name = "ESP_HL", Adornee = c, FillColor = E.Color, OutlineColor = E.Color,
        FillTransparency = E.Chams and 0.1 or E.Transparency, OutlineTransparency = E.OutlineTransparency,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop}, c)

    d.Gui = New("BillboardGui", {Name = "ESP_GUI", Size = UDim2.new(0, 160, 0, 44), Adornee = head,
        AlwaysOnTop = true, StudsOffset = Vector3.new(0, 3, 0)}, c)
    local function lbl(y, h2, size, x, w)
        return New("TextLabel", {Size = UDim2.new(w or 1, 0, 0, h2), Position = UDim2.new(x or 0, 0, 0, y),
            BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1), TextSize = size, Font = Enum.Font.GothamBold,
            TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.3, Text = ""}, d.Gui)
    end
    d.NameLbl = lbl(0, 16, 12)
    d.NameLbl.Text = plr.Name
    local bg = New("Frame", {Size = UDim2.new(0.7, 0, 0, 5), Position = UDim2.new(0.05, 0, 0, 20),
        BackgroundColor3 = Color3.new(.2, .2, .2), BorderSizePixel = 0}, d.Gui)
    d.HealthBar = New("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 1, 0), BorderSizePixel = 0}, bg)
    d.HealthBg = bg
    d.HealthLbl = lbl(16, 14, 10, 0.77, 0.2)
    d.DistLbl = lbl(28, 14, 10)

    if E.HeadDot then
        d.Dot = New("BillboardGui", {Name = "ESP_Dot", Size = UDim2.new(0, 10, 0, 10), Adornee = head, AlwaysOnTop = true}, c)
        local f = New("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = E.Color, BorderSizePixel = 0}, d.Dot)
        Round(f, 5)
    end
    if E.Box then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then
            d.Box = New("BillboardGui", {Name = "ESP_Box", Adornee = hrp, Size = UDim2.new(4, 0, 5.5, 0), AlwaysOnTop = true}, c)
            local bf = New("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1}, d.Box)
            d.BoxStroke = New("UIStroke", {Thickness = 1.5, Color = E.Color}, bf)
        end
    end
    if E.Glow then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then d.Mats[p] = p.Material p.Material = Enum.Material.Neon end
        end
    end
    if E.Tracers then d.Tracer = NewDraw("Line", {Thickness = 2, Transparency = 0.7, Visible = false}) end
    if E.Arrow then d.Arrow = NewDraw("Triangle", {Thickness = 2, Filled = true, Transparency = 0.7, Visible = false}) end
    if E.Skeleton and hasDrawing then
        for _, pair in ipairs(h.RigType == Enum.HumanoidRigType.R15 and R15 or R6) do
            local line = NewDraw("Line", {Thickness = 2, Visible = false})
            if line then d.Lines[#d.Lines + 1] = {line = line, a = pair[1], b = pair[2]} end
        end
    end
    self.data[plr] = d
end

function ESP:Update()
    self:UpdateLines()
    if tick() - self.last < E.UpdateRate then return end
    self.last = tick()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then self:Create(plr) end
    end
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local rainbow = RainbowColor(0.5)

    for plr, d in pairs(self.data) do
        local c = d.Char
        local head, h = c:FindFirstChild("Head"), c:FindFirstChildOfClass("Humanoid")
        local friend = friends[plr.UserId]
        local show = (IsAlive(plr) and plr.Character == c and (IsEnemy(plr, E.TeamCheck) or (friend and E.ShowFriends))
            and head ~= nil and h ~= nil) and true or false
        local dist = 0
        if show then
            dist = (Camera.CFrame.Position - head.Position).Magnitude
            if dist > E.MaxDistance or dist < E.MinDistance then show = false end
        end
        d.Show = show
        d.Highlight.Enabled, d.Gui.Enabled = show, show
        if d.Dot then d.Dot.Enabled = show end
        if d.Box then d.Box.Enabled = show end

        if not show then
            if d.Tracer then d.Tracer.Visible = false end
            if d.Arrow then d.Arrow.Visible = false end
            for _, l in ipairs(d.Lines) do l.line.Visible = false end
        else
            local frac = math.clamp(h.Health / math.max(h.MaxHealth, 1), 0, 1)
            local color = E.ColorMode == 0 and HealthColor(frac) or (E.ColorMode == 1 and rainbow or E.Color)
            if friend then color = Color3.fromRGB(60, 255, 120) end
            d.Color = color
            d.Highlight.FillColor, d.Highlight.OutlineColor = color, color
            d.Highlight.FillTransparency = E.Chams and 0.1 or E.Transparency
            d.HealthBar.Size = UDim2.new(frac, 0, 1, 0)
            d.HealthBar.BackgroundColor3 = HealthColor(frac)
            d.HealthLbl.Text = tostring(math.floor(frac * 100))
            d.HealthLbl.TextColor3 = HealthColor(frac)
            d.DistLbl.Text = math.round(dist) .. "m"
            d.NameLbl.Text = plr.Name .. (friend and " ⭐" or "")
            d.NameLbl.Visible, d.HealthBg.Visible = E.ShowName, E.ShowHealth
            d.HealthLbl.Visible, d.DistLbl.Visible = E.ShowHealth, E.ShowDistance
            if d.BoxStroke then d.BoxStroke.Color = color end
            if d.Dot then d.Dot.Frame.BackgroundColor3 = color end

            local target = c:FindFirstChild("HumanoidRootPart") or head
            local p, on = Camera:WorldToViewportPoint(target.Position)
            if d.Tracer then
                d.Tracer.Visible = on
                if on then d.Tracer.From = Vector2.new(center.X, 10) d.Tracer.To = Vector2.new(p.X, p.Y) d.Tracer.Color = color end
            end
            if d.Arrow then
                if on then d.Arrow.Visible = false else
                    local dir = Vector2.new(p.X, p.Y) - center
                    if p.Z < 0 then dir = -dir end
                    dir = dir.Magnitude > 1 and dir.Unit or Vector2.new(0, 1)
                    local radius = math.min(vp.X, vp.Y) / 2 - 50
                    local pos = center + dir * radius
                    local ang, s = math.atan2(dir.Y, dir.X), 15
                    d.Arrow.PointA = pos + Vector2.new(math.cos(ang + 2.5), math.sin(ang + 2.5)) * s
                    d.Arrow.PointB = pos + Vector2.new(math.cos(ang - 2.5), math.sin(ang - 2.5)) * s
                    d.Arrow.PointC = pos + Vector2.new(math.cos(ang), math.sin(ang)) * s * 1.5
                    d.Arrow.Color = color
                    d.Arrow.Visible = true
                end
            end
            for _, l in ipairs(d.Lines) do
                local pa, pb = c:FindFirstChild(l.a), c:FindFirstChild(l.b)
                if pa and pb then
                    local a, oa = Camera:WorldToViewportPoint(pa.Position)
                    local b, ob = Camera:WorldToViewportPoint(pb.Position)
                    l.line.Visible = oa and ob
                    if oa and ob then l.line.From = Vector2.new(a.X, a.Y) l.line.To = Vector2.new(b.X, b.Y) l.line.Color = color end
                else l.line.Visible = false end
            end
        end
    end
end

function ESP:RefreshAll() self:Clear() end -- пересоздастся в Update

Feature("ESP", "👁 ESP", E, "Enabled", function(on)
    if on then
        ESP.last = 0
        SM:AddConnection("ESPUpdate", RS.RenderStepped:Connect(function() ESP:Update() end))
        SM:AddConnection("ESPLeave", Players.PlayerRemoving:Connect(function(p) ESP:Remove(p) end))
    else
        SM:RemoveConnection("ESPUpdate")
        SM:RemoveConnection("ESPLeave")
        ESP:Clear()
    end
end)

Loader.Step("Модуль прицеливания", 0.72)

-- ============ AIMBOT ============
local A = Config.Aimbot
local Aim = {target = nil, clicking = false}

local function Click()
    if mouse1click then mouse1click() else VU:ClickButton1(Vector2.new()) end
end

function Aim:Score(plr, center)
    local part = GetPart(plr.Character, A.Mode)
    if not part then return nil end
    local pos, on = Camera:WorldToViewportPoint(part.Position)
    if not on then return nil end
    if not A.IgnoreWalls then
        local p = RaycastParams.new()
        p.FilterType = Enum.RaycastFilterType.Exclude
        p.FilterDescendantsInstances = {char, plr.Character}
        p.IgnoreWater = true
        if WS:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, p) then return nil end
    end
    return (Vector2.new(pos.X, pos.Y) - center).Magnitude, part
end

function Aim:Find()
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    if A.AimLock and self.target and IsEnemy(self.target, A.TeamCheck) and IsAlive(self.target) then
        local d = self:Score(self.target, center)
        if d then return self.target end
    end
    local best, bestDist = nil, A.FOV
    for _, plr in ipairs(Players:GetPlayers()) do
        if IsEnemy(plr, A.TeamCheck) and IsAlive(plr) then
            local d = self:Score(plr, center)
            if d and d < bestDist then best, bestDist = plr, d end
        end
    end
    return best
end

function Aim:Update()
    if not A.Enabled or spectating or M.Freecam then self.target = nil return end
    local target = self:Find()
    self.target = target
    if not target then return end
    local part = GetPart(target.Character, A.Mode)
    if not part then return end

    local pos = part.Position
    if A.Prediction then pos += part.AssemblyLinearVelocity * A.PredictionMultiplier end
    local cur = Camera.CFrame
    local goal = CFrame.new(cur.Position, pos)
    Camera.CFrame = A.Smoothness > 0 and cur:Lerp(goal, A.Smoothness) or goal

    if A.Triggerbot and not self.clicking then
        local p, on = Camera:WorldToViewportPoint(part.Position)
        local vp = Camera.ViewportSize
        if on and (Vector2.new(p.X, p.Y) - Vector2.new(vp.X / 2, vp.Y / 2)).Magnitude < 50 then
            self.clicking = true
            SafeCall(Click)
            task.delay(A.TriggerDelay, function() self.clicking = false end)
        end
    end
end

-- FOV круг
local fovGui, fovCircle
local function UpdateFOV()
    if not fovCircle then return end
    fovCircle.Visible = A.Enabled
    fovCircle.Size = UDim2.new(0, A.FOV * 2, 0, A.FOV * 2)
end
local function CreateFOV()
    fovGui = New("ScreenGui", {Name = "SakuraFOV", ResetOnSpawn = false, IgnoreGuiInset = true}, player.PlayerGui)
    fovCircle = New("Frame", {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, 0, .5, 0),
        BackgroundTransparency = 0.9, BackgroundColor3 = Color3.fromRGB(0, 255, 0), Visible = false, ZIndex = 999}, fovGui)
    New("UIStroke", {Color = Color3.fromRGB(0, 255, 0), Thickness = 2}, fovCircle)
    Round(fovCircle, 1000)
    SM.objects[#SM.objects + 1] = fovGui
    UpdateFOV()
end

Feature("Aimbot", "🎯 Aimbot (Q)", A, "Enabled", UpdateFOV)
Feature("Triggerbot", "Triggerbot (T)", A, "Triggerbot")
Feature("AimLock", "Aim Lock", A, "AimLock")
Feature("Prediction", "Prediction", A, "Prediction")
Feature("AimTeam", "Team Check", A, "TeamCheck")
Feature("IgnoreWalls", "Ignore Walls", A, "IgnoreWalls")
local thGui, thLbl
Feature("TargetHUD", "📋 Инфо о цели", A, "TargetHUD", function(on)
    if on then
        thGui = New("ScreenGui", {Name = "SakuraTargetHUD", ResetOnSpawn = false}, player.PlayerGui)
        thLbl = New("TextLabel", {Size = UDim2.new(0, 190, 0, 40), Position = UDim2.new(0.5, -95, 0, 100),
            BackgroundColor3 = Color3.new(.05, .01, .1), BackgroundTransparency = 0.2, TextColor3 = Color3.new(1, 1, 1),
            TextSize = 12, Font = Enum.Font.GothamBold, BorderSizePixel = 0, Visible = false}, thGui)
        Round(thLbl, 8)
        SM:AddConnection("TargetHUD", RS.Heartbeat:Connect(function()
            local t = Aim.target
            local c = t and t.Character
            local h2 = c and c:FindFirstChildOfClass("Humanoid")
            local r = c and c:FindFirstChild("HumanoidRootPart")
            if h2 and r and root then
                thLbl.Visible = true
                thLbl.Text = t.DisplayName .. "\n❤ " .. math.floor(h2.Health) .. " | " .. math.floor((r.Position - root.Position).Magnitude) .. "m"
            else thLbl.Visible = false end
        end))
    else
        SM:RemoveConnection("TargetHUD")
        if thGui then thGui:Destroy() thGui = nil end
    end
end)

for _, id in ipairs({"Tracers", "Arrow", "HeadDot", "Glow", "Chams", "Skeleton", "Box"}) do
    Feature("ESP_" .. id, id, E, id, function() ESP:RefreshAll() end)
end
Feature("ESPTeam", "Team Check", E, "TeamCheck")
Feature("ESP_Lines", "📏 Линии", E, "Lines", function() ESP:RefreshAll() end)
Feature("ESP_Name", "Имя", E, "ShowName")
Feature("ESP_Health", "Здоровье", E, "ShowHealth")
Feature("ESP_Dist", "Дистанция", E, "ShowDistance")
Feature("ESP_Friends", "Друзья (зелёные)", E, "ShowFriends")
Feature("Notify", "🔔 Уведомления", Config.Misc, "Notify")
Feature("AutoSave", "💾 Автосохранение", Config.Misc, "AutoSave")

Loader.Step("Профили и настройки", 0.82)

-- ============ ПРОФИЛЬ (сохранение настроек) ============
local canFile = (writefile ~= nil and readfile ~= nil and isfile ~= nil)
local profileStatus = canFile and "Готово к работе" or "⚠️ Executor не поддерживает файлы"
local function ProfilePath() return "Sakura_" .. game.PlaceId .. ".json" end

local function Ser(v)
    if typeof(v) == "Color3" then return {__c = {v.R, v.G, v.B}} end
    if type(v) == "table" then
        local o = {}
        for k, x in pairs(v) do o[k] = Ser(x) end
        return o
    end
    return v
end
local function Deser(v)
    if type(v) == "table" then
        if v.__c then return Color3.new(v.__c[1], v.__c[2], v.__c[3]) end
        local o = {}
        for k, x in pairs(v) do o[k] = Deser(x) end
        return o
    end
    return v
end

local function BuildProfile()
    local values = {}
    for section, tbl in pairs(Config) do
        local o = {}
        for k, v in pairs(tbl) do
            if not (featureKeys[tbl] and featureKeys[tbl][k]) then o[k] = Ser(v) end
        end
        values[section] = o
    end
    local feats, fr = {}, {}
    for _, f in ipairs(Features) do feats[f.Id] = f.Tbl[f.Key] end
    for uid in pairs(friends) do fr[#fr + 1] = uid end
    return {version = 14, values = values, features = feats, friends = fr,
        theme = {idx = themeIdx, accent = uiColorIndex, alpha = uiAlpha},
        touched = {speed = speedTouched, jump = jumpTouched}}
end

local function SaveConfig()
    if not canFile then return false, "файлы не поддерживаются" end
    local ok, err = pcall(function() writefile(ProfilePath(), Http:JSONEncode(BuildProfile())) end)
    return ok, err
end

local function LoadConfig()
    if not (canFile and isfile(ProfilePath())) then return false, "профиль не найден" end
    local ok, data = pcall(function() return Http:JSONDecode(readfile(ProfilePath())) end)
    if not ok or type(data) ~= "table" then return false, "файл повреждён" end
    Loading = true
    for section, vals in pairs(data.values or {}) do
        local tbl = Config[section]
        if tbl and type(vals) == "table" then
            for k, v in pairs(vals) do
                v = Deser(v)
                if tbl[k] ~= nil and typeof(v) == typeof(tbl[k]) and not (featureKeys[tbl] and featureKeys[tbl][k]) then
                    tbl[k] = v
                end
            end
        end
    end
    local th = data.theme
    if type(th) == "table" then
        if Themes[th.idx] then themeIdx = th.idx end
        if type(th.accent) == "number" and th.accent >= 0 and th.accent <= #uiColors then uiColorIndex = th.accent end
        if type(th.alpha) == "number" then uiAlpha = math.clamp(th.alpha, 0, 0.9) end
        bgColor = Themes[themeIdx][3]
        if not Config.Visuals.RainbowUI then uiColor = BaseAccent() end
    end
    if type(data.touched) == "table" then
        speedTouched, jumpTouched = data.touched.speed == true, data.touched.jump == true
    end
    friends = {}
    for _, uid in ipairs(data.friends or {}) do friends[uid] = true end
    for id, st in pairs(data.features or {}) do
        local f = F[id]
        if f and type(st) == "boolean" then f.Set(st) end
    end
    ApplySpeed() ApplyJump()
    Loading = false
    ApplyTheme()
    return true
end

local dirtyPending = false
MarkDirty = function()
    if not Running or Loading or not Config.Misc.AutoSave or dirtyPending then return end
    dirtyPending = true
    task.delay(3, function()
        dirtyPending = false
        if Running and Config.Misc.AutoSave then SaveConfig() end
    end)
end

-- ============ НАБЛЮДЕНИЕ ЗА ИГРОКОМ ============
local function StopSpectate()
    SM:RemoveConnection("Spectate")
    spectating = nil
    if hum then Camera.CameraSubject = hum end
end
local function SetSpectate(plr)
    if spectating == plr then StopSpectate() RefreshUI() return end
    spectating = plr
    SM:AddConnection("Spectate", RS.RenderStepped:Connect(function()
        local c = spectating and spectating.Character
        local h2 = c and c:FindFirstChildOfClass("Humanoid")
        if h2 then Camera.CameraSubject = h2 else StopSpectate() RefreshUI() end
    end))
    RefreshUI()
end

-- ============ UI ============
local mainGui
-- Возврат персонажа и камеры в обычное состояние
local function ResetCharacter()
    speedTouched, jumpTouched = false, false
    if hum and hum.Parent then
        hum.WalkSpeed = origChar.WalkSpeed
        hum.UseJumpPower = origChar.UseJumpPower
        hum.JumpPower = origChar.JumpPower
        hum.JumpHeight = origChar.JumpHeight
        hum.PlatformStand = false
        hum.AutoRotate = true
        hum.CameraOffset = Vector3.zero
        hum.BreakJointsOnDeath = true
        SetStunStates(true)
    end
    if root and root.Parent then
        root.Anchored = false
        root.AssemblyAngularVelocity = Vector3.zero
    end
    Camera.CameraType = Enum.CameraType.Custom
    Camera.FieldOfView = origFOV
    if hum then Camera.CameraSubject = hum end
    for _, plr in ipairs(Players:GetPlayers()) do
        local c = plr.Character
        if c then
            for _, o in ipairs(c:GetChildren()) do
                if o.Name:find("^ESP_") then SafeCall(function() o:Destroy() end) end
            end
        end
    end
end

-- Выключить всё и вернуть в норму, не закрывая меню
local function ResetAll()
    StopSpectate()
    for _, f in ipairs(Features) do if f.Tbl[f.Key] and f.Tbl ~= Config.Misc then f.Set(false) end end
    ESP:Clear()
    ResetCharacter()
    Toast("🔄 Всё возвращено в норму")
end

local function Unload()
    if Config.Misc.AutoSave then SaveConfig() end
    Running = false
    StopSpectate()
    for _, f in ipairs(Features) do if f.Tbl[f.Key] then f.Set(false) end end
    ESP:Clear()
    ResetCharacter()
    SM:Cleanup()
    for _, g in ipairs(player.PlayerGui:GetChildren()) do
        if g.Name:find("^Sakura") or g.Name:find("^SAKURA") then SafeCall(function() g:Destroy() end) end
    end
    if mainGui then mainGui:Destroy() mainGui = nil end
    print("🌸 SAKURA V19 — выгружена, всё в норме")
end
env.SakuraUnload = Unload

-- Анимация кнопки: наведение, «вдавливание» при нажатии с пружинкой и вспышка при клике.
-- Кнопка должна иметь AnchorPoint (0.5, 0.5), чтобы масштабироваться от центра.
local TW_FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TW_BOUNCE = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local function Animate(btn, corner)
    local sc = New("UIScale", {Scale = 1}, btn)
    local hover = false
    btn.MouseEnter:Connect(function() hover = true TS:Create(sc, TW_FAST, {Scale = 1.05}):Play() end)
    btn.MouseLeave:Connect(function() hover = false TS:Create(sc, TW_BOUNCE, {Scale = 1}):Play() end)
    btn.MouseButton1Down:Connect(function() TS:Create(sc, TW_FAST, {Scale = 0.9}):Play() end)
    btn.MouseButton1Up:Connect(function() TS:Create(sc, TW_BOUNCE, {Scale = hover and 1.05 or 1}):Play() end)
    btn.MouseButton1Click:Connect(function()
        local fl = New("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 20}, btn)
        Round(fl, corner or 8)
        local tw = TS:Create(fl, TweenInfo.new(0.35), {BackgroundTransparency = 1})
        tw.Completed:Connect(function() fl:Destroy() end)
        tw:Play()
    end)
end

local function Button(parent, text, size, pos)
    local holder = New("Frame", {Size = size, Position = pos or UDim2.new(), BackgroundTransparency = 1}, parent)
    local b = New("TextButton", {Size = UDim2.new(1, 0, 1, 0), AnchorPoint = Vector2.new(.5, .5),
        Position = UDim2.new(.5, 0, .5, 0), BackgroundColor3 = uiColor, BackgroundTransparency = 0.3, Text = text,
        TextColor3 = Color3.new(1, 1, 1), TextSize = 11, Font = Enum.Font.GothamBold, BorderSizePixel = 0,
        TextWrapped = true, AutoButtonColor = false}, holder)
    Round(b, 6)
    Themed(b, "BackgroundColor3")
    Animate(b, 6)
    return b
end

local function CreateUI()
    local vp = Camera.ViewportSize
    local w, h = math.min(420, vp.X - 20), math.min(520, vp.Y - 20)
    mainGui = New("ScreenGui", {Name = "SAKURA_V19", ResetOnSpawn = false}, player.PlayerGui)

    local main = New("Frame", {Size = UDim2.new(0, w, 0, h), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = bgColor, BackgroundTransparency = uiAlpha,
        BorderSizePixel = 0, ClipsDescendants = true}, mainGui)
    Round(main, 16)
    mainFrame = main
    local mainStroke = New("UIStroke", {Color = uiColor, Thickness = 2, Transparency = 0.1}, main)
    Themed(mainStroke, "Color")
    New("UIGradient", {Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(.55, .55, .65)), Rotation = 90}, main)

    local title = New("Frame", {Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = uiColor,
        BackgroundTransparency = 0.35, BorderSizePixel = 0}, main)
    Round(title, 16)
    Themed(title, "BackgroundColor3")
    New("UIGradient", {Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(.6, .6, .7)), Rotation = 0}, title)
    New("TextLabel", {Size = UDim2.new(0.55, 0, 0, 24), Position = UDim2.new(0, 14, 0, 4), BackgroundTransparency = 1,
        Text = "🌸 SAKURA", TextColor3 = Color3.new(1, 1, 1), TextSize = 17, Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Left}, title)
    local titleTab = New("TextLabel", {Size = UDim2.new(0.55, 0, 0, 14), Position = UDim2.new(0, 14, 0, 27),
        BackgroundTransparency = 1, Text = "V19 · ГЛАВНАЯ", TextColor3 = Color3.new(1, .92, .96), TextTransparency = 0.15,
        TextSize = 10, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left}, title)

    -- перетаскивание
    local dragging, dragStart, startPos
    title.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, i.Position, main.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    SM:AddConnection("Drag", UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))

    local toggleBtn = New("TextButton", {Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -51, 0.5, 0), AnchorPoint = Vector2.new(.5, .5),
        BackgroundColor3 = Color3.new(.2, .6, 1), Text = "▼", TextColor3 = Color3.new(1, 1, 1), TextSize = 14,
        Font = Enum.Font.GothamBold, BorderSizePixel = 0}, title)
    Round(toggleBtn, 6)
    Animate(toggleBtn, 6)
    local closeBtn = New("TextButton", {Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -18, 0.5, 0), AnchorPoint = Vector2.new(.5, .5),
        BackgroundColor3 = Color3.fromRGB(255, 70, 100), Text = "✕", TextColor3 = Color3.new(1, 1, 1), TextSize = 14,
        Font = Enum.Font.GothamBold, BorderSizePixel = 0}, title)
    Round(closeBtn, 6)
    Animate(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(Unload)

    local content = New("Frame", {Size = UDim2.new(1, 0, 1, -44), Position = UDim2.new(0, 0, 0, 44),
        BackgroundTransparency = 1, ClipsDescendants = true}, main)
    local collapsed = false
    toggleBtn.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        local newH = collapsed and 44 or h
        local curH = main.Size.Y.Offset
        local pos = main.Position
        TS:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = UDim2.new(0, w, 0, newH),
            Position = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset + (newH - curH) / 2)}):Play()
        toggleBtn.Text = collapsed and "▲" or "▼"
    end)

    -- вкладки
    local tabNames = {"ГЛАВНАЯ", "ESP", "AIM", "УЛЬТРА", "ВИЗУАЛ", "ИГРОКИ", "НАСТР"}
    local tabIcons = {"🏠", "👁", "🎯", "🔥", "🌈", "👥", "⚙️"}
    local searchBox, SwitchTab, currentTab = nil, nil, "ГЛАВНАЯ"
    local tabBar = New("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1}, content)
    searchBox = New("TextBox", {Size = UDim2.new(1, -12, 0, 26), Position = UDim2.new(0, 6, 0, 38),
        BackgroundColor3 = Color3.new(.1, .05, .15), BackgroundTransparency = 0.2, Text = "",
        PlaceholderText = "🔍 Поиск функций...", PlaceholderColor3 = Color3.new(.6, .5, .6),
        TextColor3 = Color3.new(1, 1, 1), TextSize = 12, Font = Enum.Font.Gotham, ClearTextOnFocus = false,
        BorderSizePixel = 0}, content)
    Round(searchBox, 8)
    New("UIStroke", {Color = Color3.new(.35, .25, .45), Thickness = 1}, searchBox)
    local area = New("Frame", {Size = UDim2.new(1, 0, 1, -70), Position = UDim2.new(0, 0, 0, 70),
        BackgroundTransparency = 1}, content)

    local pages, tabBtns = {}, {}
    local function Page(name)
        local sf = New("ScrollingFrame", {Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5),
            BackgroundTransparency = 1, ScrollBarThickness = 3, CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false}, area)
        New("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, sf)
        Themed(sf, "ScrollBarImageColor3")
        pages[name] = sf
        return sf
    end
    local function Header(parent, text)
        local l = New("TextLabel", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = text,
            TextColor3 = uiColor, TextSize = 12, Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left}, parent)
        Themed(l, "TextColor3")
        return l
    end
    local function Grid(parent, cellW, cellH)
        local g = New("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1}, parent)
        New("UIGridLayout", {CellSize = UDim2.new(cellW or 0.5, -4, 0, cellH or 28), CellPadding = UDim2.new(0, 6, 0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder}, g)
        return g
    end
    local OFF_TRACK = Color3.new(.3, .3, .36)
    local function FeatureButton(parent, f)
        local holder = New("Frame", {BackgroundTransparency = 1}, parent)
        local b = New("TextButton", {Size = UDim2.new(1, 0, 1, 0), AnchorPoint = Vector2.new(.5, .5),
            Position = UDim2.new(.5, 0, .5, 0), BackgroundColor3 = Color3.new(.13, .08, .2), BackgroundTransparency = 0.1,
            Text = "", AutoButtonColor = false, BorderSizePixel = 0}, holder)
        Round(b, 8)
        Animate(b, 8)
        local lbl = New("TextLabel", {Size = UDim2.new(1, -52, 1, 0), Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1, Text = f.Label, TextColor3 = Color3.new(1, 1, 1), TextSize = 11,
            Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd}, b)
        local track = New("Frame", {Size = UDim2.new(0, 30, 0, 16), Position = UDim2.new(1, -38, 0.5, -8),
            BackgroundColor3 = OFF_TRACK, BorderSizePixel = 0}, b)
        Round(track, 8)
        local knob = New("Frame", {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 2, 0.5, -6),
            BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, track)
        Round(knob, 6)
        local last
        local function refresh()
            local on = f.Tbl[f.Key] and true or false
            local col = on and uiColor or OFF_TRACK
            if on ~= last then
                local goal = {Position = on and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}
                if last == nil then
                    knob.Position = goal.Position
                    track.BackgroundColor3 = col
                else
                    TS:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), goal):Play()
                    TS:Create(track, TweenInfo.new(0.18), {BackgroundColor3 = col}):Play()
                end
                lbl.TextColor3 = on and Color3.new(1, 1, 1) or Color3.new(.72, .68, .78)
                last = on
            elseif on then
                track.BackgroundColor3 = col
            end
        end
        AddRefresher(b, refresh)
        b.MouseButton1Click:Connect(f.Toggle)
        refresh()
        return b
    end
    local function Stepper(parent, text, get, fmt, onStep)
        local row = New("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1}, parent)
        local lbl = New("TextLabel", {Size = UDim2.new(0.55, 0, 1, 0), BackgroundTransparency = 1,
            TextColor3 = Color3.new(1, .8, .9), TextSize = 11, Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left, Text = text .. ": " .. fmt(get())}, row)
        local function step(txt, x, dir)
            Button(row, txt, UDim2.new(0, 36, 0, 26), UDim2.new(x, 0, 0, 1)).MouseButton1Click:Connect(function()
                onStep(dir) MarkDirty()
                lbl.Text = text .. ": " .. fmt(get())
            end)
        end
        step("−", 0.62, -1) step("+", 0.82, 1)
    end
    local function Presets(parent, text, values, onPick)
        local lbl = Header(parent, text)
        local g = Grid(parent, 1 / #values, 26)
        for _, v in ipairs(values) do
            Button(g, tostring(v), UDim2.new()).MouseButton1Click:Connect(function()
                onPick(v) MarkDirty()
                lbl.Text = text:match("^[^:]+") .. ": " .. v
            end)
        end
    end

    -- ГЛАВНАЯ
    local pMain = Page("ГЛАВНАЯ")
    Presets(pMain, "🏃 Скорость: " .. M.Speed, {16, 50, 100, 150, 200, 300}, function(v)
        M.Speed = v speedTouched = true ApplySpeed()
    end)
    Presets(pMain, "🦘 Прыжок: " .. M.JumpPower, {50, 75, 100, 125, 150, 200}, function(v)
        M.JumpPower = v jumpTouched = true ApplyJump()
    end)
    Header(pMain, "⚙️ ПЕРЕКЛЮЧАТЕЛИ")
    local gm = Grid(pMain)
    for _, id in ipairs({"Noclip", "InfJump", "Fly", "Freecam", "AntiAFK", "WaterWalk", "NoFall", "AntiVoid", "Gravity", "BunnyHop"}) do
        FeatureButton(gm, F[id])
    end

    -- ESP
    local pEsp = Page("ESP")
    local g1 = Grid(pEsp, 1, 32)
    FeatureButton(g1, F.ESP)
    local g2 = Grid(pEsp)
    for _, id in ipairs({"ESP_Box", "ESP_Lines", "ESP_Tracers", "ESP_Arrow", "ESP_HeadDot", "ESP_Glow", "ESP_Chams", "ESP_Skeleton", "ESPTeam",
        "ESP_Name", "ESP_Health", "ESP_Dist", "ESP_Friends"}) do
        FeatureButton(g2, F[id])
    end
    local espColors = {Color3.new(1, 0, 0), Color3.new(0, 1, 0), Color3.new(0, 0, 1), Color3.new(1, 1, 0),
        Color3.new(1, 0, 1), Color3.new(0, 1, 1), Color3.new(1, .5, 0), Color3.new(1, 1, 1)}
    local espIdx = 1
    local g3 = Grid(pEsp)
    local colorBtn = New("TextButton", {Text = "🎨 Цвет ESP", BackgroundColor3 = E.Color, TextColor3 = Color3.new(1, 1, 1),
        TextSize = 11, Font = Enum.Font.GothamBold, BorderSizePixel = 0}, g3)
    Round(colorBtn, 6)
    local modeNames = {[0] = "Режим: здоровье", [1] = "Режим: радуга 🌈", [2] = "Режим: фикс. цвет"}
    local modeBtn = Button(g3, modeNames[E.ColorMode], UDim2.new())
    colorBtn.MouseButton1Click:Connect(function()
        espIdx = espIdx % #espColors + 1
        E.Color = espColors[espIdx] E.ColorMode = 2
        colorBtn.BackgroundColor3 = E.Color
        modeBtn.Text = modeNames[2]
    end)
    modeBtn.MouseButton1Click:Connect(function()
        E.ColorMode = (E.ColorMode + 1) % 3
        modeBtn.Text = modeNames[E.ColorMode]
    end)

    Presets(pEsp, "📏 Макс. дистанция: " .. (E.MaxDistance >= 1e7 and "∞" or E.MaxDistance),
        {250, 500, 1000, 2500, "∞"}, function(v) E.MaxDistance = (v == "∞") and 100000000 or v end)
    Stepper(pEsp, "📏 Мин. дистанция", function() return E.MinDistance end, tostring, function(dir)
        E.MinDistance = math.clamp(E.MinDistance + dir * 25, 0, 1000)
    end)
    Stepper(pEsp, "🎨 Прозрачность заливки", function() return E.Transparency end,
        function(v) return string.format("%.1f", v) end, function(dir)
            E.Transparency = math.clamp(E.Transparency + dir * 0.1, 0, 1)
        end)

    Stepper(pEsp, "📏 Толщина линий", function() return E.LineThickness end, tostring, function(dir)
        E.LineThickness = math.clamp(E.LineThickness + dir, 1, 6)
    end)
    local originNames = {"Низ экрана", "Центр", "Верх экрана"}
    local originBtn = Button(pEsp, "Начало линий: " .. originNames[E.LineOrigin], UDim2.new(1, 0, 0, 28))
    originBtn.MouseButton1Click:Connect(function()
        E.LineOrigin = E.LineOrigin % 3 + 1
        originBtn.Text = "Начало линий: " .. originNames[E.LineOrigin]
        MarkDirty()
    end)

    -- AIM
    local pAim = Page("AIM")
    Header(pAim, "🎯 НАСТРОЙКИ AIMBOT")
    local ga = Grid(pAim)
    for _, id in ipairs({"Aimbot", "Triggerbot", "AimLock", "Prediction", "AimTeam", "IgnoreWalls", "TargetHUD"}) do
        FeatureButton(ga, F[id])
    end
    Stepper(pAim, "📏 FOV", function() return A.FOV end, tostring, function(dir)
        A.FOV = math.clamp(A.FOV + dir * 10, 50, 500) UpdateFOV()
    end)
    Stepper(pAim, "🎯 Плавность", function() return A.Smoothness end, function(v) return string.format("%.2f", v) end,
        function(dir) A.Smoothness = math.clamp(A.Smoothness + dir * 0.05, 0.05, 0.9) end)
    local modeAim = Button(pAim, "Цель: " .. A.Mode, UDim2.new(1, 0, 0, 28))
    modeAim.MouseButton1Click:Connect(function()
        A.Mode = A.Mode == "Head" and "Torso" or (A.Mode == "Torso" and "Root" or "Head")
        modeAim.Text = "Цель: " .. A.Mode
    end)

    -- УЛЬТРА
    local pUltra = Page("УЛЬТРА")
    Stepper(pUltra, "💀 Hitbox", function() return U.HitboxSize end, tostring, function(dir)
        U.HitboxSize = math.clamp(U.HitboxSize + dir * 0.5, 1, 10)
        if U.HitboxExtender then HitboxApply() end
    end)
    local gu = Grid(pUltra)
    for _, id in ipairs({"Hitbox", "Invisible", "GodMode", "NoKnockback", "NoSound", "NoStun", "SpeedHack", "Teleport", "AntiFling"}) do
        FeatureButton(gu, F[id])
    end

    -- ВИЗУАЛ
    local pVis = Page("ВИЗУАЛ")
    local gv = Grid(pVis)
    for _, id in ipairs({"XRay", "FullBright", "NoFog", "RainbowUI", "Watermark", "NoShadows", "NoCameraShake",
        "NoRecoil", "NoSpread", "ThirdPerson", "LowGraphics", "NoEffects", "FPS", "CustomFOV", "Crosshair", "TimeLock", "Radar", "NoPostFX", "RainbowBody", "Trail", "Flashlight"}) do
        FeatureButton(gv, F[id])
    end

    -- доп. настройки ГЛАВНАЯ
    Stepper(pMain, "🪽 Скорость полёта", function() return M.FlySpeed end, tostring, function(dir)
        M.FlySpeed = math.clamp(M.FlySpeed + dir * 10, 10, 300)
    end)
    Stepper(pMain, "🎥 Скорость Freecam", function() return M.FreecamSpeed end, tostring, function(dir)
        M.FreecamSpeed = math.clamp(M.FreecamSpeed + dir * 10, 10, 300)
    end)
    Stepper(pMain, "🪐 Значение гравитации", function() return M.GravityValue end, tostring, function(dir)
        M.GravityValue = math.clamp(M.GravityValue + dir * 10, 10, 400)
    end)
    Header(pMain, "📍 ТОЧКИ И СЕРВЕР")
    local gw = Grid(pMain, 0.5, 28)
    for i = 1, 3 do
        local sb = Button(gw, "💾 Точка " .. i, UDim2.new())
        sb.MouseButton1Click:Connect(function()
            if root then waypoints[i] = root.CFrame sb.Text = "💾 Точка " .. i .. " ✓" end
        end)
        Button(gw, "🌀 К точке " .. i, UDim2.new()).MouseButton1Click:Connect(function()
            if root and waypoints[i] then root.CFrame = waypoints[i] end
        end)
    end
    local gx = Grid(pMain, 1 / 3, 34)
    Button(gx, "♻️ Респавн на месте", UDim2.new()).MouseButton1Click:Connect(RespawnHere)
    Button(gx, "🔁 Реджойн", UDim2.new()).MouseButton1Click:Connect(function() Rejoin(true) end)
    Button(gx, "🆕 Др. сервер", UDim2.new()).MouseButton1Click:Connect(function() Rejoin(false) end)

    -- доп. настройки ВИЗУАЛ
    Stepper(pVis, "🔭 Значение FOV", function() return V.FOVValue end, tostring, function(dir)
        V.FOVValue = math.clamp(V.FOVValue + dir * 5, 30, 120)
    end)
    Stepper(pVis, "🕐 Время суток", function() return V.TimeValue end, tostring, function(dir)
        V.TimeValue = (V.TimeValue + dir) % 24
    end)
    Stepper(pVis, "📡 Радиус радара", function() return V.RadarRange end, tostring, function(dir)
        V.RadarRange = math.clamp(V.RadarRange + dir * 50, 50, 1000)
    end)

    -- ИГРОКИ
    local pPl = Page("ИГРОКИ")
    local plHeader = Header(pPl, "👥 Игроки")
    local plRows = {}
    local function RemoveRow(plr)
        if plRows[plr] then plRows[plr].frame:Destroy() plRows[plr] = nil end
    end
    local function AddRow(plr)
        if plr == player or plRows[plr] then return end
        local fr = New("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Color3.new(.1, .05, .15),
            BackgroundTransparency = 0.3, BorderSizePixel = 0}, pPl)
        Round(fr, 6)
        New("TextLabel", {Size = UDim2.new(0.34, 0, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1,
            Text = plr.DisplayName, TextColor3 = Color3.new(1, 1, 1), TextSize = 11, Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, fr)
        local info = New("TextLabel", {Size = UDim2.new(0.22, 0, 1, 0), Position = UDim2.new(0.35, 0, 0, 0),
            BackgroundTransparency = 1, Text = "", TextColor3 = Color3.new(.8, .8, 1), TextSize = 10,
            Font = Enum.Font.Gotham}, fr)
        local function mini(txt, x)
            local b = Button(fr, txt, UDim2.new(0.12, 0, 0, 26), UDim2.new(x, 0, 0, 4))
            b.TextSize = 14
            return b
        end
        local bSpec, bTp, bFr = mini("👁", 0.58), mini("🌀", 0.71), mini("⭐", 0.84)
        AddRefresher(bSpec, function() bSpec.BackgroundColor3 = (spectating == plr) and ON_COLOR or uiColor end)
        AddRefresher(bFr, function() bFr.BackgroundColor3 = friends[plr.UserId] and ON_COLOR or uiColor end)
        bSpec.MouseButton1Click:Connect(function() SetSpectate(plr) end)
        bTp.MouseButton1Click:Connect(function()
            local c = plr.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            if r and root then root.CFrame = r.CFrame * CFrame.new(0, 0, 3) end
        end)
        bFr.MouseButton1Click:Connect(function()
            friends[plr.UserId] = (not friends[plr.UserId]) or nil
            MarkDirty() RefreshUI()
        end)
        plRows[plr] = {frame = fr, info = info}
    end
    local function UpdateRows()
        local n = 0
        for plr, row in pairs(plRows) do
            n += 1
            local c = plr.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            local h2 = c and c:FindFirstChildOfClass("Humanoid")
            if r and root and h2 then
                local d = (r.Position - root.Position).Magnitude
                row.info.Text = math.floor(d) .. "m\n❤" .. math.floor(h2.Health)
                row.frame.LayoutOrder = 100 + math.floor(d)
            else
                row.info.Text = "—"
                row.frame.LayoutOrder = 99999
            end
        end
        plHeader.Text = "👥 Игроков: " .. n .. "   (👁 смотреть · 🌀 ТП · ⭐ друг)"
    end
    local lastPl = 0
    SM:AddConnection("PlayerList", RS.Heartbeat:Connect(function()
        if pPl.Visible and tick() - lastPl > 0.5 then lastPl = tick() UpdateRows() end
    end))
    SM:AddConnection("PL_Add", Players.PlayerAdded:Connect(AddRow))
    SM:AddConnection("PL_Rem", Players.PlayerRemoving:Connect(RemoveRow))
    for _, p in ipairs(Players:GetPlayers()) do AddRow(p) end

    -- НАСТРОЙКИ
    local pSet = Page("НАСТР")
    Header(pSet, "🎨 ТЕМА")
    local gt = Grid(pSet, 1 / 3, 28)
    for i, th in ipairs(Themes) do
        local b = New("TextButton", {Text = th[1], BackgroundColor3 = th[2], TextColor3 = Color3.new(0, 0, 0),
            TextSize = 11, Font = Enum.Font.GothamBold, BorderSizePixel = 0}, gt)
        Round(b, 6)
        b.MouseButton1Click:Connect(function()
            themeIdx, uiColorIndex, bgColor = i, 0, th[3]
            if not V.RainbowUI then uiColor = BaseAccent() end
            ApplyTheme() MarkDirty()
        end)
    end
    local accBtn = Button(pSet, "", UDim2.new(1, 0, 0, 28))
    local function accText()
        accBtn.Text = uiColorIndex == 0 and "Акцент: цвет темы (нажми — сменить)" or ("Акцент: #" .. uiColorIndex)
    end
    accText()
    accBtn.MouseButton1Click:Connect(function()
        uiColorIndex = (uiColorIndex + 1) % (#uiColors + 1)
        if not V.RainbowUI then uiColor = BaseAccent() end
        accText() ApplyTheme() MarkDirty()
    end)
    Stepper(pSet, "🪟 Прозрачность окна", function() return uiAlpha end,
        function(v) return string.format("%.1f", v) end, function(dir)
            uiAlpha = math.clamp(uiAlpha + dir * 0.1, 0, 0.9) ApplyTheme()
        end)
    local gs = Grid(pSet)
    for _, id in ipairs({"RainbowUI", "Notify", "AutoSave", "AutoRejoin"}) do FeatureButton(gs, F[id]) end

    Header(pSet, "💾 ПРОФИЛЬ (эта игра)")
    local status = New("TextLabel", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = profileStatus,
        TextColor3 = Color3.new(.8, .9, 1), TextSize = 10, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true}, pSet)
    local gp = Grid(pSet, 1 / 3, 28)
    local bSave = Button(gp, "💾 Сохранить", UDim2.new())
    local bLoad = Button(gp, "📂 Загрузить", UDim2.new())
    local bDel = Button(gp, "🗑 Удалить", UDim2.new())
    bSave.MouseButton1Click:Connect(function()
        local ok, err = SaveConfig()
        profileStatus = ok and "✅ Сохранено" or ("❌ " .. tostring(err))
        status.Text = profileStatus
    end)
    bDel.MouseButton1Click:Connect(function()
        if canFile and delfile and isfile(ProfilePath()) then delfile(ProfilePath()) profileStatus = "🗑 Профиль удалён"
        else profileStatus = "❌ Нечего удалять" end
        status.Text = profileStatus
    end)
    bLoad.MouseButton1Click:Connect(function()
        local ok, err = LoadConfig()
        profileStatus = ok and "✅ Загружено" or ("❌ " .. tostring(err))
        status.Text = profileStatus
        if ok then
            local pos = mainFrame.Position
            task.defer(function()
                if mainGui then mainGui:Destroy() mainGui = nil end
                CreateUI()
                if mainFrame then mainFrame.Position = pos end
            end)
        end
    end)
    Header(pSet, "🧪 ДИАГНОСТИКА")
    local caps = {
        {"Drawing: трейсеры, стрелки, скелет", hasDrawing},
        {"Файлы: сохранение профиля", canFile},
        {"mouse1click: Triggerbot", mouse1click ~= nil},
        {"setclipboard: копирование лога", setclipboard ~= nil},
    }
    local capText = {}
    for _, c in ipairs(caps) do capText[#capText + 1] = (c[2] and "✅ " or "❌ ") .. c[1] end
    New("TextLabel", {Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 1, Text = table.concat(capText, "\n"),
        TextColor3 = Color3.new(.8, .9, 1), TextSize = 10, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top}, pSet)
    Button(pSet, "📋 Копировать лог ошибок", UDim2.new(1, 0, 0, 28)).MouseButton1Click:Connect(function()
        local text = #errLog > 0 and table.concat(errLog, "\n") or "Ошибок нет"
        if setclipboard then setclipboard(text) Toast("📋 Скопировано (" .. #errLog .. ")")
        else print(text) Toast("Лог выведен в консоль (" .. #errLog .. ")") end
    end)
    Button(pSet, "🔄 Вернуть всё в норму", UDim2.new(1, 0, 0, 28)).MouseButton1Click:Connect(ResetAll)
    Button(pSet, "⏏ Выгрузить скрипт (End)", UDim2.new(1, 0, 0, 28)).MouseButton1Click:Connect(Unload)

    -- ПОИСК
    local pSearch = Page("ПОИСК")
    local aliases = {
        Noclip = "сквозь стены ноуклип", Fly = "полет полёт летать", SpeedHack = "скорость волчек быстро",
        BunnyHop = "бхоп прыжки банихоп", GodMode = "бессмертие год", Invisible = "невидимка невидимость",
        InfJump = "бесконечный прыжок", ESP = "есп вх подсветка", Aimbot = "аим аимбот прицел",
        Teleport = "телепорт тп", NoFall = "падение урон", XRay = "рентген", FullBright = "яркость свет",
        Hitbox = "хитбокс", ESP_Box = "бокс рамка box", ESP_Friends = "друзья", NoSound = "звук тишина",
        FPS = "фпс", Watermark = "ватермарк", LowGraphics = "графика лаги", ThirdPerson = "третье лицо",
        AntiVoid = "бездна пустота падение", CustomFOV = "поле зрения фов", Crosshair = "прицел перекрестие",
        TimeLock = "время ночь день", Freecam = "свободная камера фрикам", AntiFling = "флинг защита",
        ESP_Lines = "линии полоски трейсеры лучи", Radar = "радар карта миникарта", TargetHUD = "цель инфо худ",
        Gravity = "гравитация луна низкая", NoPostFX = "блюр эффекты размытие", RainbowBody = "радуга тело цвет",
        Trail = "след шлейф хвост", Flashlight = "фонарик свет лампа",
    }
    local function Hay(f) return (f.Label .. " " .. f.Id .. " " .. (aliases[f.Id] or "")):lower() end
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = (searchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", ""))
        if q == "" then SwitchTab(currentTab) return end
        for n, p in pairs(pages) do p.Visible = (n == "ПОИСК") end
        for _, c in ipairs(pSearch:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        local hdr = Header(pSearch, "")
        local g = Grid(pSearch)
        local n = 0
        for _, f in ipairs(Features) do
            if Hay(f):find(q, 1, true) then FeatureButton(g, f) n += 1 end
        end
        hdr.Text = "🔍 Найдено: " .. n
    end)

    -- переключение вкладок
    SwitchTab = function(name)
        currentTab = name
        for n, p in pairs(pages) do p.Visible = (n == name) end
        for n, b in pairs(tabBtns) do b.BackgroundTransparency = (n == name) and 0.05 or 0.72 end
        titleTab.Text = "V19 · " .. name
        local pg = pages[name]
        if pg then
            pg.Position = UDim2.new(0, 5, 0, 18)
            TS:Create(pg, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = UDim2.new(0, 5, 0, 5)}):Play()
        end
    end
    for i, name in ipairs(tabNames) do
        local b = Button(tabBar, tabIcons[i], UDim2.new(1 / #tabNames, -4, 1, -4),
            UDim2.new((i - 1) / #tabNames, 2, 0, 2))
        b.TextSize = 17
        tabBtns[name] = b
        b.MouseButton1Click:Connect(function() searchBox.Text = "" SwitchTab(name) end)
    end
    SwitchTab("ГЛАВНАЯ")
    RefreshUI()
    local sc = New("UIScale", {Scale = 0.85}, main)
    TS:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

local function ToggleMenu() if mainGui then mainGui.Enabled = not mainGui.Enabled end end
local function CreateMenuButton()
    local gui = New("ScreenGui", {Name = "SakuraMenuButton", ResetOnSpawn = false}, player.PlayerGui)
    local btn = New("TextButton", {Size = UDim2.new(0, 55, 0, 35), Position = UDim2.new(0, 38, 0, 118), AnchorPoint = Vector2.new(.5, .5),
        BackgroundColor3 = uiColor, Text = "🌸", TextSize = 18, Font = Enum.Font.GothamBold,
        TextColor3 = Color3.new(1, 1, 1)}, gui)
    Round(btn, 10)
    Animate(btn, 10)
    Themed(btn, "BackgroundColor3")
    btn.MouseButton1Click:Connect(ToggleMenu)
    SM.objects[#SM.objects + 1] = gui
end

-- Кнопка 🍆 Aimbot
local function CreateAimbotButton()
    local gui = New("ScreenGui", {Name = "SakuraAimbotBtn", ResetOnSpawn = false}, player.PlayerGui)
    local btn = New("TextButton", {Size = UDim2.new(0, 55, 0, 35), Position = UDim2.new(0, 38, 0, 73), AnchorPoint = Vector2.new(.5, .5),
        BackgroundColor3 = Color3.fromRGB(200, 50, 50), Text = "🍆", TextSize = 18, Font = Enum.Font.GothamBold,
        TextColor3 = Color3.new(1, 1, 1)}, gui)
    Round(btn, 10)
    Animate(btn, 10)
    btn.MouseButton1Click:Connect(F.Aimbot.Toggle)
    AddRefresher(btn, function()
        btn.BackgroundColor3 = A.Enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    end)
    SM.objects[#SM.objects + 1] = gui
end

-- ============ ХОТКЕИ ============
SM:AddConnection("Hotkeys", UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    local k = input.KeyCode
    if k == Enum.KeyCode.Q then F.Aimbot.Toggle()
    elseif k == Enum.KeyCode.T then F.Triggerbot.Toggle()
    elseif k == Enum.KeyCode.N then F.Noclip.Toggle()
    elseif k == Enum.KeyCode.F then F.Fly.Toggle()
    elseif k == Enum.KeyCode.I then F.Invisible.Toggle()
    elseif k == Enum.KeyCode.G then F.GodMode.Toggle()
    elseif k == Enum.KeyCode.B then F.BunnyHop.Toggle()
    elseif k == Enum.KeyCode.X then F.SpeedHack.Toggle()
    elseif k == Enum.KeyCode.RightShift then ToggleMenu()
    elseif k == Enum.KeyCode.End then Unload()
    end
end))

-- ============ ЦИКЛ И РЕСПАВН ============
BindCam("Main", function()
    if Running then Aim:Update() end
end)

SM:AddConnection("CharBind", player.CharacterAdded:Connect(BindChar))

charCallbacks[#charCallbacks + 1] = function()
    ApplySpeed()
    ApplyJump()
    if U.NoStun then SetStunStates(false) end
end

-- ============ ЗАПУСК ============
Loader.Step("Загрузка профиля", 0.9)
SafeCall(function()
    local ok, msg = LoadConfig()
    profileStatus = ok and "✅ Профиль загружен" or ("ℹ️ " .. tostring(msg))
end)
Loader.Step("Построение меню", 0.96)
SafeCall(function()
    CreateUI()
    CreateFOV()
    CreateAimbotButton()
    CreateMenuButton()
end)
Loader.Step("Готово!", 1)
Loader.Done()

print("🌸 SAKURA V19 загружена")
print("Хоткеи: Q Aimbot | T Triggerbot | N Noclip | F Fly | I Invisible | G God | B BunnyHop | X Волчек")
print("Teleport: Ctrl+ЛКМ на ПК, тап по миру на телефоне (включить в УЛЬТРА)")
