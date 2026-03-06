--[[
    ╔══════════════════════════════════════╗
    ║           HmD GUI v1.1               ║
    ║   Para usar no Roblox Studio         ║
    ║   Coloque em: StarterPlayerScripts   ║
    ║   Tipo: LocalScript                  ║
    ╚══════════════════════════════════════╝

    FIXES v1.1:
    - Sombra agora acompanha a janela ao arrastar (sem quadrado)
    - Neblina, chuva e neve corrigidos
    - Shaders corrigidos
    - Ctrl+Click para teleportar ao ponto clicado
]]

-- ============================================================
-- RELOAD GUARD
-- ============================================================
local existing = game.CoreGui:FindFirstChild("HmD")
if existing then
    existing:Destroy()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "HmD", Text = "GUI reiniciada! ♻️", Duration = 3
    })
    task.wait(0.2)
end

-- ============================================================
-- SERVIÇOS
-- ============================================================
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local RunService       = game:GetService("RunService")
local TeleportService  = game:GetService("TeleportService")

local plr  = Players.LocalPlayer
local mouse = plr:GetMouse()
local char = plr.Character or plr.CharacterAdded:Wait()
local hum  = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

-- ============================================================
-- CARGOS
-- ============================================================

local RED      = Color3.fromRGB(220, 50, 50)
local BLUE_JOE = Color3.fromRGB(50, 120, 255)

-- IDs com acesso VIP/Owner
local ROLES = {
    [2456483034] = { role = "Owner",   emoji = "👑", color = RED,      vip = true },  -- deathtd_ / Humild
    [2371198017] = { role = "Joestar", emoji = "⭐", color = BLUE_JOE, vip = true },  -- Joestar
    [3558095796] = { role = "Joestar", emoji = "⭐", color = BLUE_JOE, vip = true },  -- Joestar 2
}

-- IDs com tag VIP (mas não Owner)
local VIP_IDS = {
    -- ex: [123456789] = true,
}

local function GetRole(p)
    if ROLES[p.UserId] then
        return ROLES[p.UserId]
    elseif VIP_IDS[p.UserId] then
        return { role = "VIP", emoji = "💎", color = Color3.fromRGB(130, 80, 255), vip = true }
    end
    return { role = "HmD User", emoji = "👤", color = Color3.fromRGB(180, 180, 180), vip = false }
end

local function GetRoleColor(p) return GetRole(p).color end
local function HasVIP(p)       return GetRole(p).vip   end

local myRole = GetRole(plr)
local isOwner = myRole.role == "Owner"

plr.CharacterAdded:Connect(function(c)
    char = c
    hum  = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
end)

-- ============================================================
-- CORES
-- ============================================================
local GRAY_DARK  = Color3.fromRGB(30,  30,  30)
local GRAY_MID   = Color3.fromRGB(55,  55,  55)
local GRAY_BTN   = Color3.fromRGB(75,  75,  75)
local GRAY_LIGHT = Color3.fromRGB(200, 200, 200)
local WHITE      = Color3.fromRGB(220, 220, 220)
local GREEN_ON   = Color3.fromRGB(60,  210, 60)
local RED_OFF    = Color3.fromRGB(210, 60,  60)

-- ============================================================
-- FUNÇÕES AUXILIARES
-- ============================================================

local function SendNotify(title, text, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title, Text = text, Duration = duration or 4
    })
end

local function AddCorner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = obj
end

local function CreateButton(parent, name, text, posX, posY, width, height)
    local btn = Instance.new("TextButton")
    btn.Name                   = name
    btn.Parent                 = parent
    btn.BackgroundColor3       = GRAY_BTN
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel        = 0
    btn.Position               = UDim2.new(0, posX, 0, posY)
    btn.Size                   = UDim2.new(0, width or 150, 0, height or 30)
    btn.Font                   = Enum.Font.Oswald
    btn.Text                   = text
    btn.TextColor3             = WHITE
    btn.TextScaled             = true
    btn.TextWrapped            = true
    btn.ZIndex                 = 11
    AddCorner(btn, 5)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15),
            {BackgroundColor3 = Color3.fromRGB(100,100,100)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15),
            {BackgroundColor3 = GRAY_BTN}):Play()
    end)
    return btn
end

local function CreateInput(parent, name, placeholder, posX, posY, width)
    local input = Instance.new("TextBox")
    input.Name                   = name
    input.Parent                 = parent
    input.BackgroundColor3       = GRAY_DARK
    input.BackgroundTransparency = 0.1
    input.BorderSizePixel        = 0
    input.Position               = UDim2.new(0, posX, 0, posY)
    input.Size                   = UDim2.new(0, width or 155, 0, 30)
    input.Font                   = Enum.Font.Gotham
    input.PlaceholderColor3      = Color3.fromRGB(120, 120, 120)
    input.PlaceholderText        = placeholder
    input.Text                   = ""
    input.TextColor3             = WHITE
    input.TextSize               = 14
    input.TextWrapped            = true
    input.ZIndex                 = 11
    AddCorner(input, 5)
    return input
end

local function CreateLabel(parent, text, posX, posY, width, height, size)
    local lbl = Instance.new("TextLabel")
    lbl.Parent                 = parent
    lbl.BackgroundTransparency = 1
    lbl.Position               = UDim2.new(0, posX, 0, posY)
    lbl.Size                   = UDim2.new(0, width or 350, 0, height or 22)
    lbl.Font                   = Enum.Font.GothamBold
    lbl.Text                   = text
    lbl.TextColor3             = GRAY_LIGHT
    lbl.TextSize               = size or 13
    lbl.TextWrapped            = true
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.ZIndex                 = 11
    return lbl
end

local function AddToggleLED(button)
    local led = Instance.new("ImageLabel")
    led.Name                   = "LED"
    led.Parent                 = button
    led.AnchorPoint            = Vector2.new(0, 0.5)
    led.BackgroundTransparency = 1
    led.Position               = UDim2.new(1, 6, 0.5, 0)
    led.Size                   = UDim2.new(0, 16, 0, 16)
    led.Image                  = "rbxassetid://3926305904"
    led.ImageColor3            = RED_OFF
    led.ImageRectOffset        = Vector2.new(424, 4)
    led.ImageRectSize          = Vector2.new(36, 36)
    led.ZIndex                 = 12
    return led
end

local function ToggleColor(btn)
    local led = btn:FindFirstChild("LED")
    if not led then return end
    led.ImageColor3 = (led.ImageColor3 == RED_OFF) and GREEN_ON or RED_OFF
end

local function IsOn(btn)
    local led = btn:FindFirstChild("LED")
    return led ~= nil and led.ImageColor3 == GREEN_ON
end

-- ============================================================
-- JANELA PRINCIPAL
-- ============================================================

local HmD = Instance.new("ScreenGui")
HmD.Name           = "HmD"
HmD.Parent         = game.CoreGui
HmD.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HmD.ResetOnSpawn   = false

-- ── FIX SOMBRA ──────────────────────────────────────────────
-- A sombra fica DENTRO do Background para acompanhar o drag
local Background = Instance.new("Frame")
Background.Name             = "Background"
Background.Parent           = HmD
Background.AnchorPoint      = Vector2.new(0.5, 0.5)
Background.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
Background.BorderSizePixel  = 0
Background.Position         = UDim2.new(0.5, 0, 0.5, 0)
Background.Size             = UDim2.new(0, 510, 0, 355)
Background.Active           = true
Background.Draggable        = true
Background.ZIndex           = 9
AddCorner(Background, 8)

-- Sombra como filho do Background → move junto ao arrastar
local Shadow = Instance.new("Frame")
Shadow.Name                   = "Shadow"
Shadow.Parent                 = Background       -- filho, não irmão!
Shadow.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.55
Shadow.BorderSizePixel        = 0
Shadow.Position               = UDim2.new(0, 6, 0, 6)   -- offset leve
Shadow.Size                   = UDim2.new(1, 0, 1, 0)
Shadow.ZIndex                 = 8                        -- atrás do Background
AddCorner(Shadow, 10)

-- Título
local TitleBar = Instance.new("Frame")
TitleBar.Name             = "TitleBar"
TitleBar.Parent           = Background
TitleBar.BackgroundColor3 = GRAY_DARK
TitleBar.BorderSizePixel  = 0
TitleBar.Size             = UDim2.new(1, 0, 0, 32)
TitleBar.ZIndex           = 10
AddCorner(TitleBar, 8)

-- patch para cantos inferiores retos
local TitlePatch = Instance.new("Frame")
TitlePatch.Parent           = TitleBar
TitlePatch.BackgroundColor3 = GRAY_DARK
TitlePatch.BorderSizePixel  = 0
TitlePatch.Position         = UDim2.new(0, 0, 0.5, 0)
TitlePatch.Size             = UDim2.new(1, 0, 0.5, 0)
TitlePatch.ZIndex           = 10

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent                 = TitleBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size                   = UDim2.new(1, -10, 1, 0)
TitleLabel.Position               = UDim2.new(0, 12, 0, 0)
TitleLabel.Font                   = Enum.Font.GothamBold
TitleLabel.Text = myRole.emoji .. "  HmD  —  " .. myRole.role
TitleLabel.TextColor3             = WHITE
TitleLabel.TextSize               = 15
TitleLabel.TextXAlignment         = Enum.TextXAlignment.Left
TitleLabel.ZIndex                 = 11

-- ============================================================
-- BARRA LATERAL
-- ============================================================

local SideBar = Instance.new("Frame")
SideBar.Name             = "SideBar"
SideBar.Parent           = Background
SideBar.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
SideBar.BorderSizePixel  = 0
SideBar.Position         = UDim2.new(0, 0, 0, 32)
SideBar.Size             = UDim2.new(0, 108, 0, 323)
SideBar.ZIndex           = 10
SideBar.ClipsDescendants = true

local sectionDefs = {
    { name = "Home",      icon = "🏠", y = 4   },
    { name = "Game",      icon = "🎮", y = 44  },
    { name = "Character", icon = "🧍", y = 84  },
    { name = "Target",    icon = "🎯", y = 124 },
    { name = "Anims",     icon = "🕺", y = 164 },
    { name = "VIP",       icon = "👑", y = 204 },
    { name = "Admin",     icon = "🔧", y = 244 },
    { name = "Credits",   icon = "⭐", y = 284 },
}

local sectionBtns = {}
for _, def in ipairs(sectionDefs) do
    local btn = Instance.new("TextButton")
    btn.Name                   = def.name .. "_SBtn"
    btn.Parent                 = SideBar
    btn.BackgroundColor3       = GRAY_MID
    btn.BackgroundTransparency = 0.6
    btn.BorderSizePixel        = 0
    btn.Position               = UDim2.new(0, 6, 0, def.y)
    btn.Size                   = UDim2.new(0, 96, 0, 38)
    btn.Font                   = Enum.Font.GothamBold
    btn.Text                   = def.icon .. "  " .. def.name
    btn.TextColor3             = GRAY_LIGHT
    btn.TextSize               = 13
    btn.TextXAlignment         = Enum.TextXAlignment.Left
    btn.ZIndex                 = 11
    AddCorner(btn, 5)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.Parent = btn
    sectionBtns[def.name] = btn
end

-- ============================================================
-- PAINÉIS
-- ============================================================

local function MakePanel(canvasY)
    local f = Instance.new("ScrollingFrame")
    f.Parent                 = Background
    f.Active                 = true
    f.BackgroundTransparency = 1
    f.BorderSizePixel        = 0
    f.Position               = UDim2.new(0, 112, 0, 36)
    f.Size                   = UDim2.new(0, 390, 0, 315)
    f.Visible                = false
    f.CanvasSize             = UDim2.new(0, 0, canvasY or 1, 0)
    f.ScrollBarThickness     = 4
    f.ScrollBarImageColor3   = GRAY_LIGHT
    f.ZIndex                 = 10
    return f
end

-- ─── HOME ─────────────────────────────────────────────────
local HomePanel = MakePanel(1.5)

local ProfileImg = Instance.new("ImageLabel")
ProfileImg.Parent           = HomePanel
ProfileImg.BackgroundColor3 = GRAY_DARK
ProfileImg.BorderSizePixel  = 0
ProfileImg.Position         = UDim2.new(0, 10, 0, 15)
ProfileImg.Size             = UDim2.new(0, 88, 0, 88)
ProfileImg.ZIndex           = 11
AddCorner(ProfileImg, 6)
pcall(function()
    ProfileImg.Image = Players:GetUserThumbnailAsync(
        plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
end)

local WelcomeLabel = Instance.new("TextLabel")
WelcomeLabel.Parent                 = HomePanel
WelcomeLabel.BackgroundTransparency = 1
WelcomeLabel.Position               = UDim2.new(0, 112, 0, 15)
WelcomeLabel.Size                   = UDim2.new(0, 268, 0, 88)
WelcomeLabel.Font                   = Enum.Font.GothamBold
WelcomeLabel.Text                   = "Olá, @" .. plr.Name .. "!\n\nPressione [B] para\nabrir ou fechar.\nCtrl+Click para teleportar."
WelcomeLabel.TextColor3             = WHITE
WelcomeLabel.TextSize               = 15
WelcomeLabel.TextWrapped            = true
WelcomeLabel.TextXAlignment         = Enum.TextXAlignment.Left
WelcomeLabel.TextYAlignment         = Enum.TextYAlignment.Top
WelcomeLabel.ZIndex                 = 11

local AnnounceBox = Instance.new("Frame")
AnnounceBox.Parent           = HomePanel
AnnounceBox.BackgroundColor3 = GRAY_DARK
AnnounceBox.BorderSizePixel  = 0
AnnounceBox.Position         = UDim2.new(0, 10, 0, 118)
AnnounceBox.Size             = UDim2.new(0, 370, 0, 68)
AnnounceBox.ZIndex           = 11
AddCorner(AnnounceBox, 6)

local AnnounceText = Instance.new("TextLabel")
AnnounceText.Parent                 = AnnounceBox
AnnounceText.BackgroundTransparency = 1
AnnounceText.Position               = UDim2.new(0, 10, 0, 6)
AnnounceText.Size                   = UDim2.new(1, -20, 1, -12)
AnnounceText.Font                   = Enum.Font.Gotham
AnnounceText.Text                   = "📢  Edite o campo AnnounceText.Text no script para colocar seus avisos aqui."
AnnounceText.TextColor3             = GRAY_LIGHT
AnnounceText.TextSize               = 13
AnnounceText.TextWrapped            = true
AnnounceText.TextXAlignment         = Enum.TextXAlignment.Left
AnnounceText.TextYAlignment         = Enum.TextYAlignment.Top
AnnounceText.ZIndex                 = 12

local StatsBox = Instance.new("Frame")
StatsBox.Parent           = HomePanel
StatsBox.BackgroundColor3 = GRAY_DARK
StatsBox.BorderSizePixel  = 0
StatsBox.Position         = UDim2.new(0, 10, 0, 200)
StatsBox.Size             = UDim2.new(0, 370, 0, 44)
StatsBox.ZIndex           = 11
AddCorner(StatsBox, 6)

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Parent                 = StatsBox
StatsLabel.BackgroundTransparency = 1
StatsLabel.Position               = UDim2.new(0, 10, 0, 5)
StatsLabel.Size                   = UDim2.new(1, -20, 1, -10)
StatsLabel.Font                   = Enum.Font.Gotham
StatsLabel.TextColor3             = GRAY_LIGHT
StatsLabel.TextSize               = 13
StatsLabel.TextWrapped            = true
StatsLabel.TextXAlignment         = Enum.TextXAlignment.Left
StatsLabel.ZIndex                 = 12

RunService.Heartbeat:Connect(function()
    pcall(function()
        local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        StatsLabel.Text = string.format("⚡ Ping: %dms   🏃 Speed: %d   🦘 Jump: %d",
            ping, math.floor(hum.WalkSpeed), math.floor(hum.JumpPower))
    end)
end)

-- ── USUÁRIOS CONECTADOS ──────────────────────────────────────
local UsersBox = Instance.new("Frame")
UsersBox.Parent           = HomePanel
UsersBox.BackgroundColor3 = GRAY_DARK
UsersBox.BorderSizePixel  = 0
UsersBox.Position         = UDim2.new(0, 10, 0, 258)
UsersBox.Size             = UDim2.new(0, 370, 0, 180)
UsersBox.ZIndex           = 11
AddCorner(UsersBox, 6)

local UsersTitle = Instance.new("TextLabel")
UsersTitle.Parent                 = UsersBox
UsersTitle.BackgroundTransparency = 1
UsersTitle.Position               = UDim2.new(0, 10, 0, 6)
UsersTitle.Size                   = UDim2.new(1, -20, 0, 22)
UsersTitle.Font                   = Enum.Font.GothamBold
UsersTitle.Text                   = "🔗  Usuários com HmD neste servidor"
UsersTitle.TextColor3             = Color3.fromRGB(255, 210, 60)
UsersTitle.TextSize               = 13
UsersTitle.TextXAlignment         = Enum.TextXAlignment.Left
UsersTitle.ZIndex                 = 12

-- Linha separadora
local UsersDivider = Instance.new("Frame")
UsersDivider.Parent           = UsersBox
UsersDivider.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
UsersDivider.BorderSizePixel  = 0
UsersDivider.Position         = UDim2.new(0, 10, 0, 30)
UsersDivider.Size             = UDim2.new(1, -20, 0, 1)
UsersDivider.ZIndex           = 12

-- Lista scrollável
local UsersList = Instance.new("ScrollingFrame")
UsersList.Parent                 = UsersBox
UsersList.BackgroundTransparency = 1
UsersList.BorderSizePixel        = 0
UsersList.Position               = UDim2.new(0, 6, 0, 34)
UsersList.Size                   = UDim2.new(1, -12, 1, -38)
UsersList.CanvasSize             = UDim2.new(0, 0, 0, 0)
UsersList.ScrollBarThickness     = 3
UsersList.ScrollBarImageColor3   = Color3.fromRGB(255, 210, 60)
UsersList.ZIndex                 = 12

local UsersListLayout = Instance.new("UIListLayout")
UsersListLayout.Parent          = UsersList
UsersListLayout.Padding         = UDim.new(0, 4)
UsersListLayout.SortOrder       = Enum.SortOrder.LayoutOrder
UsersListLayout.FillDirection   = Enum.FillDirection.Vertical

-- ─── GAME ─────────────────────────────────────────────────
local GamePanel = MakePanel(0.6)

CreateLabel(GamePanel, "🌤  Horário",         10, 10,  200, 20, 14)
local DayBtn   = CreateButton(GamePanel, "Day_Btn",   "☀️  Dia",   10,  34, 178, 34)
local NightBtn = CreateButton(GamePanel, "Night_Btn", "🌙  Noite", 202, 34, 178, 34)

CreateLabel(GamePanel, "✨  Efeitos visuais", 10, 84,  200, 20, 14)
local ShadersBtn = CreateButton(GamePanel, "Shaders_Btn", "✨  Shaders", 10, 108, 368, 34)
AddToggleLED(ShadersBtn)

-- ─── CHARACTER ────────────────────────────────────────────
local CharPanel = MakePanel(1.35)

CreateLabel(CharPanel, "🏃  Walk Speed",  10, 10, 200, 20, 14)
local SpeedInput = CreateInput(CharPanel, "Speed_Input", "Ex: 32",  10, 34, 175)
local SpeedBtn   = CreateButton(CharPanel, "Speed_Btn", "✔  Aplicar", 200, 34, 178, 30)

CreateLabel(CharPanel, "🦘  Jump Power",  10, 78, 200, 20, 14)
local JumpInput  = CreateInput(CharPanel, "Jump_Input", "Ex: 75",  10, 102, 175)
local JumpBtn    = CreateButton(CharPanel, "Jump_Btn", "✔  Aplicar", 200, 102, 178, 30)

CreateLabel(CharPanel, "✈️  Voo  (W/A/S/D para mover)", 10, 146, 300, 20, 14)
local FlyBtn = CreateButton(CharPanel, "Fly_Btn", "✈️  Voar (toggle)", 10, 170, 368, 34)
AddToggleLED(FlyBtn)

CreateLabel(CharPanel, "🖱️  Ctrl+Click TP", 10, 218, 300, 20, 14)
local CtrlTPBtn = CreateButton(CharPanel, "CtrlTP_Btn", "🖱️  Ctrl+Click TP (toggle)", 10, 242, 368, 34)
AddToggleLED(CtrlTPBtn)

CreateLabel(CharPanel, "🛡  Misc", 10, 292, 200, 20, 14)
local RespawnBtn = CreateButton(CharPanel, "Respawn_Btn", "🔄  Respawn",  10,  316, 175, 34)
local GodModeBtn = CreateButton(CharPanel, "GodMode_Btn", "🛡  God Mode", 202, 316, 175, 34)
AddToggleLED(GodModeBtn)

local InvisBtn  = CreateButton(CharPanel, "Invis_Btn",  "👻  Invisível", 10,  360, 175, 34)
AddToggleLED(InvisBtn)
local NoClipBtn = CreateButton(CharPanel, "NoClip_Btn", "🔮  NoClip",    202, 360, 175, 34)
AddToggleLED(NoClipBtn)

-- ─── TARGET ───────────────────────────────────────────────
local TargetPanel = MakePanel(2.8)

-- Foto + info do target
local TargetImg = Instance.new("ImageLabel")
TargetImg.Parent           = TargetPanel
TargetImg.BackgroundColor3 = GRAY_DARK
TargetImg.BorderSizePixel  = 0
TargetImg.Position         = UDim2.new(0, 10, 0, 10)
TargetImg.Size             = UDim2.new(0, 80, 0, 80)
TargetImg.ZIndex           = 11
TargetImg.Image            = "rbxassetid://10818605405"
AddCorner(TargetImg, 6)

local TargetInput = CreateInput(TargetPanel, "Target_Input", "@username...", 100, 10, 280)

local TargetIDLabel = Instance.new("TextLabel")
TargetIDLabel.Parent                 = TargetPanel
TargetIDLabel.BackgroundTransparency = 1
TargetIDLabel.Position               = UDim2.new(0, 100, 0, 46)
TargetIDLabel.Size                   = UDim2.new(0, 280, 0, 50)
TargetIDLabel.Font                   = Enum.Font.Gotham
TargetIDLabel.Text                   = "UserID:\nDisplay:\nCreated:"
TargetIDLabel.TextColor3             = GRAY_LIGHT
TargetIDLabel.TextSize               = 13
TargetIDLabel.TextWrapped            = true
TargetIDLabel.TextXAlignment         = Enum.TextXAlignment.Left
TargetIDLabel.TextYAlignment         = Enum.TextYAlignment.Top
TargetIDLabel.ZIndex                 = 11

-- Linha 1
local ViewTargetBtn   = CreateButton(TargetPanel, "ViewTarget_Btn",   "👁  View",    10,  105, 175, 34)
AddToggleLED(ViewTargetBtn)
local CopyIDBtn       = CreateButton(TargetPanel, "CopyID_Btn",       "📋  Copy ID", 202, 105, 175, 34)

-- Linha 2
local FocusTargetBtn  = CreateButton(TargetPanel, "FocusTarget_Btn",  "🔍  Focus",   10,  149, 175, 34)
AddToggleLED(FocusTargetBtn)
local FollowTargetBtn = CreateButton(TargetPanel, "FollowTarget_Btn", "🚶  Follow",  202, 149, 175, 34)
AddToggleLED(FollowTargetBtn)

-- Linha 3
local StandTargetBtn  = CreateButton(TargetPanel, "StandTarget_Btn",  "🧍  Stand",   10,  193, 175, 34)
AddToggleLED(StandTargetBtn)
local BangTargetBtn   = CreateButton(TargetPanel, "BangTarget_Btn",   "💥  Bang",    202, 193, 175, 34)
AddToggleLED(BangTargetBtn)

-- Linha 4
local DragTargetBtn   = CreateButton(TargetPanel, "DragTarget_Btn",   "✋  Drag",    10,  237, 175, 34)
AddToggleLED(DragTargetBtn)
local HeadsitTargetBtn= CreateButton(TargetPanel, "HeadsitTarget_Btn","🪑  Headsit", 202, 237, 175, 34)
AddToggleLED(HeadsitTargetBtn)

-- Linha 5
local TpTargetBtn     = CreateButton(TargetPanel, "TpTarget_Btn",     "📍  Teleport",10,  281, 175, 34)
local PushTargetBtn   = CreateButton(TargetPanel, "PushTarget_Btn",   "👊  Push",    202, 281, 175, 34)

-- Linha 6
local CopyAnimBtn     = CreateButton(TargetPanel, "CopyAnim_Btn",     "🎭  Copiar Anim",   10,  325, 175, 34)
AddToggleLED(CopyAnimBtn)
local ESPTargetBtn    = CreateButton(TargetPanel, "ESPTarget_Btn",    "🔴  ESP Target",   202, 325, 175, 34)
AddToggleLED(ESPTargetBtn)

-- Linha 7 — ESP geral (todos jogadores)
CreateLabel(TargetPanel, "👁  ESP — Todos os jogadores", 10, 372, 370, 20, 13)
local ESPAllBtn       = CreateButton(TargetPanel, "ESPAll_Btn",       "👁  ESP Global ON/OFF", 10, 396, 368, 34)
AddToggleLED(ESPAllBtn)

-- ─── ANIMS ────────────────────────────────────────────────
local AnimsPanel = MakePanel(4.0)

CreateLabel(AnimsPanel, "🕺  Animações — clique para tocar, clique novamente para parar", 10, 8, 370, 20, 12)

-- Campo de busca por ID customizado
local AnimSearchInput = CreateInput(AnimsPanel, "AnimSearch_Input", "ID personalizado (ex: 507770239)", 10, 34, 260)
local AnimPlayBtn     = CreateButton(AnimsPanel, "AnimPlay_Btn", "▶ Tocar", 280, 34, 100, 30)
local AnimStopBtn     = CreateButton(AnimsPanel, "AnimStop_Btn", "⏹ Parar", 280, 34, 100, 30)
AnimStopBtn.Visible   = false

-- Separador
CreateLabel(AnimsPanel, "─────────────────────────────────────────", 10, 72, 370, 14, 11)

-- Lista de animações por categoria
-- Cada entrada: { nome, id, emoji }
local ANIM_LIST = {
    -- IDLE / POSES
    { cat = "🧍 Idle & Poses",    name = "Idle Normal",        id = "180435571"  },
    { cat = "🧍 Idle & Poses",    name = "Idle Lookout",       id = "180435792"  },
    { cat = "🧍 Idle & Poses",    name = "Idle Crouch",        id = "182436935"  },
    { cat = "🧍 Idle & Poses",    name = "Pose Militar",       id = "507770239"  },
    { cat = "🧍 Idle & Poses",    name = "Pose Thinker",       id = "507770186"  },
    { cat = "🧍 Idle & Poses",    name = "Pose Point",         id = "507770453"  },
    { cat = "🧍 Idle & Poses",    name = "Pose Salute",        id = "3544773498" },
    -- DANÇAS
    { cat = "💃 Danças",          name = "Default Dance",      id = "507771019"  },
    { cat = "💃 Danças",          name = "Shuffle",            id = "507771525"  },
    { cat = "💃 Danças",          name = "Robot",              id = "507766388"  },
    { cat = "💃 Danças",          name = "Tilt",               id = "507767714"  },
    { cat = "💃 Danças",          name = "Breakdance",         id = "507777826"  },
    { cat = "💃 Danças",          name = "Wave",               id = "507770239"  },
    { cat = "💃 Danças",          name = "Samba",              id = "507776043"  },
    { cat = "💃 Danças",          name = "Twist",              id = "507776524"  },
    -- EMOÇÕES
    { cat = "😂 Emoções",         name = "Laugh",              id = "3544772775" },
    { cat = "😂 Emoções",         name = "Cheer",              id = "507770677"  },
    { cat = "😂 Emoções",         name = "Point",              id = "507770453"  },
    { cat = "😂 Emoções",         name = "Clap",               id = "507770561"  },
    { cat = "😂 Emoções",         name = "Shrug",              id = "3544773360" },
    { cat = "😂 Emoções",         name = "Facepalm",           id = "3338668822" },
    { cat = "😂 Emoções",         name = "Wave Hello",         id = "507770239"  },
    -- COMBATE
    { cat = "⚔️ Combate",         name = "Kick",               id = "3544773912" },
    { cat = "⚔️ Combate",         name = "Punch",              id = "3338668849" },
    { cat = "⚔️ Combate",         name = "Block",              id = "616163682"  },
    { cat = "⚔️ Combate",         name = "Roll",               id = "616158929"  },
    -- MISC
    { cat = "🎭 Misc",            name = "Sit Floor",          id = "2506281703" },
    { cat = "🎭 Misc",            name = "Sleep",              id = "3544771283" },
    { cat = "🎭 Misc",            name = "Swim",               id = "3544772665" },
    { cat = "🎭 Misc",            name = "Climb",              id = "180436334"  },
    { cat = "🎭 Misc",            name = "Fall",               id = "180436148"  },
}

-- Renderiza os botões agrupados por categoria
local currentCat   = ""
local currentY     = 86
local animBtnList  = {}   -- { btn, id } para lógica

for _, anim in ipairs(ANIM_LIST) do
    -- Cabeçalho de categoria
    if anim.cat ~= currentCat then
        currentCat = anim.cat
        local catLbl = CreateLabel(AnimsPanel, currentCat, 10, currentY, 370, 18, 13)
        catLbl.TextColor3 = Color3.fromRGB(255, 210, 60)
        currentY = currentY + 22
    end

    -- Botão da animação (dois por linha)
    local col = (#animBtnList % 2 == 0) and 10 or 196
    if col == 10 and #animBtnList > 0 then
        -- já avançou na linha anterior
    end

    local btn = CreateButton(AnimsPanel, "Anim_" .. anim.id, "▶  " .. anim.name, col, currentY, 175, 30)
    AddToggleLED(btn)
    table.insert(animBtnList, { btn = btn, id = anim.id, name = anim.name })

    if col == 196 then
        currentY = currentY + 38
    end
end
-- Garante que a última linha avançou
if #animBtnList % 2 ~= 0 then
    currentY = currentY + 38
end

-- Ajusta canvas ao conteúdo real
AnimsPanel.CanvasSize = UDim2.new(0, 0, 0, currentY + 10)

-- ─── VIP ──────────────────────────────────────────────────
local VIPPanel = MakePanel(2.0)

-- Cabeçalho dourado
local VIPHeader = Instance.new("Frame")
VIPHeader.Parent           = VIPPanel
VIPHeader.BackgroundColor3 = Color3.fromRGB(40, 30, 10)
VIPHeader.BorderSizePixel  = 0
VIPHeader.Position         = UDim2.new(0, 10, 0, 8)
VIPHeader.Size             = UDim2.new(0, 370, 0, 44)
VIPHeader.ZIndex           = 11
AddCorner(VIPHeader, 7)

local VIPHeaderLabel = Instance.new("TextLabel")
VIPHeaderLabel.Parent                 = VIPHeader
VIPHeaderLabel.BackgroundTransparency = 1
VIPHeaderLabel.Size                   = UDim2.new(1, 0, 1, 0)
VIPHeaderLabel.Font                   = Enum.Font.GothamBold
VIPHeaderLabel.Text                   = "👑  VIP  —  Funcionalidades Exclusivas"
VIPHeaderLabel.TextColor3             = Color3.fromRGB(255, 210, 60)
VIPHeaderLabel.TextSize               = 15
VIPHeaderLabel.ZIndex                 = 12

-- ── Aparência ──
CreateLabel(VIPPanel, "🎨  Aparência do personagem", 10, 64, 370, 20, 14)

local BunnyBtn    = CreateButton(VIPPanel, "Bunny_Btn",   "🐰  Bunny Hop",      10,  88, 175, 34)
AddToggleLED(BunnyBtn)
local SpinBtn     = CreateButton(VIPPanel, "Spin_Btn",    "🌀  Spin",            202, 88, 175, 34)
AddToggleLED(SpinBtn)

local FloatBtn    = CreateButton(VIPPanel, "Float_Btn",   "🫧  Flutuar",         10,  132, 175, 34)
AddToggleLED(FloatBtn)
local GlowBtn     = CreateButton(VIPPanel, "Glow_Btn",    "✨  Brilho no char",  202, 132, 175, 34)
AddToggleLED(GlowBtn)

-- ── Chat & Nome ──
CreateLabel(VIPPanel, "💬  Chat & Nome", 10, 180, 370, 20, 14)

local ChatColorInput = CreateInput(VIPPanel, "ChatColor_Input", "Cor hex ex: ff0000", 10, 204, 200)
local ChatColorBtn   = CreateButton(VIPPanel, "ChatColor_Btn", "🎨  Cor Chat", 220, 204, 158, 30)

local FakeMsgInput   = CreateInput(VIPPanel, "FakeMsg_Input", "Mensagem...", 10, 248, 255)
local FakeMsgBtn     = CreateButton(VIPPanel, "FakeMsg_Btn",  "📨  Enviar",  275, 248, 103, 30)

-- ── Efeitos visuais ──
CreateLabel(VIPPanel, "🌈  Efeitos visuais", 10, 292, 370, 20, 14)

local RainbowCharBtn = CreateButton(VIPPanel, "RainbowChar_Btn", "🌈  Rainbow Body",   10,  316, 175, 34)
AddToggleLED(RainbowCharBtn)
local TrailBtn       = CreateButton(VIPPanel, "Trail_Btn",       "💫  Trail",          202, 316, 175, 34)
AddToggleLED(TrailBtn)

local BigHeadBtn     = CreateButton(VIPPanel, "BigHead_Btn",     "🗿  Big Head",        10,  360, 175, 34)
AddToggleLED(BigHeadBtn)
local TinyBtn        = CreateButton(VIPPanel, "Tiny_Btn",        "🐜  Tiny Mode",       202, 360, 175, 34)
AddToggleLED(TinyBtn)

local FlatBtn        = CreateButton(VIPPanel, "Flat_Btn",        "📄  Flat Mode",       10,  404, 175, 34)
AddToggleLED(FlatBtn)
local GiantBtn       = CreateButton(VIPPanel, "Giant_Btn",       "🗼  Giant Mode",      202, 404, 175, 34)
AddToggleLED(GiantBtn)

-- ─── ADMIN ────────────────────────────────────────────────
local AdminPanel = MakePanel(1.5)

CreateLabel(AdminPanel, "📍  Teleporte  (digite o nome do jogador)", 10, 8,  370, 20, 13)
local TpInput    = CreateInput(AdminPanel, "Tp_Input", "Nome do jogador...", 10, 32, 235)
local TpBtn      = CreateButton(AdminPanel, "Tp_Btn",      "Ir até",    255, 32, 115, 30)
local TpBringBtn = CreateButton(AdminPanel, "TpBring_Btn", "⬇️  Trazer", 10,  74, 175, 34)
local TpSpawnBtn = CreateButton(AdminPanel, "TpSpawn_Btn", "🏁  Spawn",  202, 74, 175, 34)

CreateLabel(AdminPanel, "🎯  Pontuação  (leaderstats)", 10, 124, 370, 20, 13)
local ScoreInput    = CreateInput(AdminPanel, "Score_Input", "Valor...", 10, 150, 115)
local ScoreAddBtn   = CreateButton(AdminPanel, "ScoreAdd_Btn",   "➕ Add",   135, 150, 110, 30)
local ScoreResetBtn = CreateButton(AdminPanel, "ScoreReset_Btn", "🔁 Zerar", 255, 150, 110, 30)

CreateLabel(AdminPanel, "🌐  Servidor", 10, 196, 370, 20, 13)
local RejoinBtn    = CreateButton(AdminPanel, "Rejoin_Btn", "🔄  Rejoin",     10,  220, 175, 34)
local ServerHopBtn = CreateButton(AdminPanel, "SrvHop_Btn", "🔀  Server Hop", 202, 220, 175, 34)

CreateLabel(AdminPanel, "💬  Chat rápido", 10, 270, 370, 20, 13)
local ChatInput   = CreateInput(AdminPanel, "Chat_Input", "Digite a mensagem...", 10, 296, 255)
local ChatSendBtn = CreateButton(AdminPanel, "ChatSend_Btn", "📨 Enviar", 275, 296, 105, 30)

-- ─── CREDITS ──────────────────────────────────────────────
local CreditsPanel = MakePanel(0.7)

local CredBox = Instance.new("Frame")
CredBox.Parent           = CreditsPanel
CredBox.BackgroundColor3 = GRAY_DARK
CredBox.BorderSizePixel  = 0
CredBox.Position         = UDim2.new(0, 10, 0, 15)
CredBox.Size             = UDim2.new(0, 370, 0, 160)
CredBox.ZIndex           = 11
AddCorner(CredBox, 8)

local CredLabel = Instance.new("TextLabel")
CredLabel.Parent                 = CredBox
CredLabel.BackgroundTransparency = 1
CredLabel.Position               = UDim2.new(0, 16, 0, 14)
CredLabel.Size                   = UDim2.new(1, -32, 1, -28)
CredLabel.Font                   = Enum.Font.Gotham
CredLabel.Text = "HmD GUI  •  v1.2\n\nCriador / Owner: Humild  (deathtd_)\nDiscord: deathtd_\n\nSeu cargo: " .. myRole.emoji .. " " .. myRole.role
CredLabel.TextColor3             = GRAY_LIGHT
CredLabel.TextSize               = 15
CredLabel.TextWrapped            = true
CredLabel.TextXAlignment         = Enum.TextXAlignment.Left
CredLabel.TextYAlignment         = Enum.TextYAlignment.Top
CredLabel.ZIndex                 = 12

-- ============================================================
-- BOTÃO ABRIR/FECHAR
-- ============================================================

local OpenCloseBtn = Instance.new("TextButton")
OpenCloseBtn.Name             = "OpenClose"
OpenCloseBtn.Parent           = HmD
OpenCloseBtn.BackgroundColor3 = GRAY_DARK
OpenCloseBtn.BorderSizePixel  = 0
OpenCloseBtn.Position         = UDim2.new(0, 5, 0.5, -15)
OpenCloseBtn.Size             = UDim2.new(0, 30, 0, 30)
OpenCloseBtn.Font             = Enum.Font.GothamBold
OpenCloseBtn.Text             = "H"
OpenCloseBtn.TextColor3       = WHITE
OpenCloseBtn.TextScaled       = true
OpenCloseBtn.ZIndex           = 20
AddCorner(OpenCloseBtn, 15)

-- ============================================================
-- NAVEGAÇÃO
-- ============================================================

local panels = {
    Home      = HomePanel,
    Game      = GamePanel,
    Character = CharPanel,
    Target    = TargetPanel,
    Anims     = AnimsPanel,
    VIP       = VIPPanel,
    Admin     = AdminPanel,
    Credits   = CreditsPanel,
}

local function ShowSection(name)
    for k, panel in pairs(panels) do
        panel.Visible = (k == name)
    end
    for k, btn in pairs(sectionBtns) do
        if k == name then
            btn.BackgroundTransparency = 0
            btn.TextColor3             = WHITE
        else
            btn.BackgroundTransparency = 0.6
            btn.TextColor3             = GRAY_LIGHT
        end
    end
end

for name, btn in pairs(sectionBtns) do
    btn.MouseButton1Click:Connect(function()
        if name == "VIP" and not HasVIP(plr) then
            SendNotify("HmD", "🔒 Acesso negado! Apenas VIP e Owner.", 4)
            return
        end
        ShowSection(name)
    end)
end

-- Visual: deixa botão VIP bloqueado para não-VIP
if not HasVIP(plr) then
    local vipBtn = sectionBtns["VIP"]
    if vipBtn then
        vipBtn.Text       = "🔒  VIP"
        vipBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
        vipBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end

ShowSection("Home")

-- ============================================================
-- LÓGICA — ANIMAÇÕES
-- ============================================================

local activeAnimTrack = nil   -- track atual tocando
local activeAnimBtn   = nil   -- botão ativo atual

local function StopCurrentAnim()
    if activeAnimTrack then
        pcall(function() activeAnimTrack:Stop(0.2) end)
        activeAnimTrack = nil
    end
    if activeAnimBtn then
        pcall(function()
            local led = activeAnimBtn:FindFirstChild("LED")
            if led then led.ImageColor3 = RED_OFF end
            activeAnimBtn.Text = activeAnimBtn.Text:gsub("^⏹", "▶")
        end)
        activeAnimBtn = nil
    end
    -- Reativa o script Animate padrão
    pcall(function()
        local animate = char:FindFirstChild("Animate")
        if animate then animate.Disabled = false end
    end)
end

local function PlayAnimById(id, btn, btnName)
    -- Se clicou no mesmo botão que está tocando → para
    if activeAnimBtn == btn then
        StopCurrentAnim()
        return
    end
    -- Para a animação anterior
    StopCurrentAnim()

    pcall(function()
        local animate = char:FindFirstChild("Animate")
        if animate then animate.Disabled = true end

        local aObj = Instance.new("Animation")
        aObj.AnimationId = "rbxassetid://" .. tostring(id)
        local track = hum:LoadAnimation(aObj)
        track.Priority = Enum.AnimationPriority.Action
        track:Play(0.1)

        activeAnimTrack = track
        activeAnimBtn   = btn

        -- LED verde e texto ⏹
        local led = btn:FindFirstChild("LED")
        if led then led.ImageColor3 = GREEN_ON end
        btn.Text = "⏹  " .. btnName

        -- Quando terminar naturalmente, limpa estado
        track.Stopped:Connect(function()
            if activeAnimTrack == track then
                StopCurrentAnim()
            end
        end)

        SendNotify("HmD", "🎭 " .. btnName)
    end)
end

-- Conecta cada botão da lista
for _, entry in ipairs(animBtnList) do
    local e = entry
    e.btn.MouseButton1Click:Connect(function()
        PlayAnimById(e.id, e.btn, e.name)
    end)
end

-- Botão ID personalizado
AnimPlayBtn.MouseButton1Click:Connect(function()
    local id = AnimSearchInput.Text:match("%d+")
    if not id then SendNotify("HmD", "ID inválido."); return end
    PlayAnimById(id, AnimPlayBtn, "Custom " .. id)
    AnimPlayBtn.Visible = false
    AnimStopBtn.Visible = true
end)

AnimStopBtn.MouseButton1Click:Connect(function()
    StopCurrentAnim()
    AnimPlayBtn.Visible = true
    AnimStopBtn.Visible = false
end)

-- Para animação ao respawnar
plr.CharacterAdded:Connect(function(c)
    char = c
    hum  = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
    activeAnimTrack = nil
    activeAnimBtn   = nil
end)

-- ============================================================
-- LÓGICA — GAME
-- ============================================================

DayBtn.MouseButton1Click:Connect(function()
    Lighting.ClockTime = 14
    SendNotify("HmD", "Horário: Dia ☀️")
end)

NightBtn.MouseButton1Click:Connect(function()
    Lighting.ClockTime = 20
    SendNotify("HmD", "Horário: Noite 🌙")
end)

-- ── FIX SHADERS ─────────────────────────────────────────────
-- Salva os efeitos por referência para poder destruir corretamente
local shaderObjects = {}

ShadersBtn.MouseButton1Click:Connect(function()
    ToggleColor(ShadersBtn)
    if IsOn(ShadersBtn) then
        -- Remove qualquer efeito anterior antes de criar novos
        for _, obj in ipairs(shaderObjects) do
            pcall(function() obj:Destroy() end)
        end
        shaderObjects = {}

        local bloom = Instance.new("BloomEffect")
        bloom.Intensity  = 0.5
        bloom.Size       = 14
        bloom.Threshold  = 0.85
        bloom.Parent     = Lighting

        local cc = Instance.new("ColorCorrectionEffect")
        cc.Contrast   = 0.12
        cc.Saturation = 0.22
        cc.Brightness = 0.02
        cc.Parent     = Lighting

        local sr = Instance.new("SunRaysEffect")
        sr.Intensity = 0.12
        sr.Spread    = 0.85
        sr.Parent    = Lighting

        shaderObjects = {bloom, cc, sr}
        SendNotify("HmD", "Shaders ativados ✨")
    else
        for _, obj in ipairs(shaderObjects) do
            pcall(function() obj:Destroy() end)
        end
        shaderObjects = {}
        SendNotify("HmD", "Shaders desativados")
    end
end)

-- ============================================================
-- LÓGICA — VIP
-- ============================================================

-- ── BUNNY HOP ───────────────────────────────────────────────
local bunnyConn = nil
BunnyBtn.MouseButton1Click:Connect(function()
    ToggleColor(BunnyBtn)
    if IsOn(BunnyBtn) then
        bunnyConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                if hum.FloorMaterial ~= Enum.Material.Air then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end)
        SendNotify("HmD", "Bunny Hop ON 🐰")
    else
        if bunnyConn then bunnyConn:Disconnect(); bunnyConn = nil end
        SendNotify("HmD", "Bunny Hop OFF")
    end
end)

-- ── SPIN ────────────────────────────────────────────────────
local spinConn  = nil
local spinAngle = 0
SpinBtn.MouseButton1Click:Connect(function()
    ToggleColor(SpinBtn)
    if IsOn(SpinBtn) then
        spinConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                spinAngle = (spinAngle + 5) % 360
                root.CFrame = CFrame.new(root.Position)
                    * CFrame.Angles(0, math.rad(spinAngle), 0)
            end)
        end)
        SendNotify("HmD", "Spin ON 🌀")
    else
        if spinConn then spinConn:Disconnect(); spinConn = nil end
        SendNotify("HmD", "Spin OFF")
    end
end)

-- ── FLUTUAR ─────────────────────────────────────────────────
local floatBV   = nil
local floatConn = nil
FloatBtn.MouseButton1Click:Connect(function()
    ToggleColor(FloatBtn)
    if IsOn(FloatBtn) then
        floatBV = Instance.new("BodyVelocity", root)
        floatBV.MaxForce = Vector3.new(0, 9e9, 0)
        floatBV.Velocity = Vector3.new(0, 0, 0)
        floatConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                -- Flutua 4 studs acima do chão
                local ray = Ray.new(root.Position, Vector3.new(0, -10, 0))
                local hit, pos = game.Workspace:FindPartOnRay(ray, char)
                if hit then
                    local targetY = pos.Y + 4
                    local diff    = targetY - root.Position.Y
                    floatBV.Velocity = Vector3.new(0, diff * 12, 0)
                end
            end)
        end)
        hum.PlatformStand = true
        SendNotify("HmD", "Flutuar ON 🫧")
    else
        if floatConn then floatConn:Disconnect(); floatConn = nil end
        if floatBV   then floatBV:Destroy();      floatBV   = nil end
        hum.PlatformStand = false
        SendNotify("HmD", "Flutuar OFF")
    end
end)

-- ── BRILHO NO CHAR ──────────────────────────────────────────
local glowParts = {}
GlowBtn.MouseButton1Click:Connect(function()
    ToggleColor(GlowBtn)
    if IsOn(GlowBtn) then
        pcall(function()
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    local light = Instance.new("PointLight", p)
                    light.Brightness = 3
                    light.Range      = 12
                    light.Color      = Color3.fromRGB(255, 220, 80)
                    table.insert(glowParts, light)
                end
            end
        end)
        SendNotify("HmD", "Brilho ON ✨")
    else
        for _, l in ipairs(glowParts) do pcall(function() l:Destroy() end) end
        glowParts = {}
        SendNotify("HmD", "Brilho OFF")
    end
end)

-- ── COR DO CHAT ─────────────────────────────────────────────
ChatColorBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local hex = ChatColorInput.Text:gsub("#", "")
        if #hex ~= 6 then SendNotify("HmD", "Digite um hex válido ex: ff0000"); return end
        local r = tonumber(hex:sub(1,2), 16)
        local g = tonumber(hex:sub(3,4), 16)
        local b = tonumber(hex:sub(5,6), 16)
        if not (r and g and b) then SendNotify("HmD", "Hex inválido."); return end
        -- Aplica cor no BubbleChat
        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[HmD] Cor definida! Use o chat normalmente.",
            Color = Color3.fromRGB(r, g, b),
            Font = Enum.Font.GothamBold,
            FontSize = Enum.FontSize.Size18,
        })
        SendNotify("HmD", "Cor do chat aplicada!")
    end)
end)

-- ── FAKE MESSAGE ────────────────────────────────────────────
FakeMsgBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local msg = FakeMsgInput.Text
        if msg == "" then return end
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text     = "[" .. plr.Name .. "]: " .. msg,
            Color    = Color3.fromRGB(255, 210, 60),
            Font     = Enum.Font.Gotham,
            FontSize = Enum.FontSize.Size14,
        })
        FakeMsgInput.Text = ""
        SendNotify("HmD", "Mensagem enviada! 📨")
    end)
end)

-- ── RAINBOW BODY ────────────────────────────────────────────
local rainbowConn = nil
local rainbowHue  = 0
RainbowCharBtn.MouseButton1Click:Connect(function()
    ToggleColor(RainbowCharBtn)
    if IsOn(RainbowCharBtn) then
        rainbowConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                rainbowHue = (rainbowHue + 0.5) % 360
                local col = Color3.fromHSV(rainbowHue / 360, 1, 1)
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.Color = col
                    end
                end
            end)
        end)
        SendNotify("HmD", "Rainbow ON 🌈")
    else
        if rainbowConn then rainbowConn:Disconnect(); rainbowConn = nil end
        -- Restaura cor original
        pcall(function()
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.Color = Color3.fromRGB(163, 162, 165)
                end
            end
        end)
        SendNotify("HmD", "Rainbow OFF")
    end
end)

-- ── TRAIL ───────────────────────────────────────────────────
local trailPart0 = nil
local trailPart1 = nil
local trailObj   = nil
TrailBtn.MouseButton1Click:Connect(function()
    ToggleColor(TrailBtn)
    if IsOn(TrailBtn) then
        pcall(function()
            local hrp  = root
            local head = char:FindFirstChild("Head")
            if not head then return end

            trailPart0 = Instance.new("Attachment", hrp)
            trailPart0.Position = Vector3.new(0, 1, 0)
            trailPart1 = Instance.new("Attachment", hrp)
            trailPart1.Position = Vector3.new(0, -1, 0)

            trailObj = Instance.new("Trail")
            trailObj.Attachment0     = trailPart0
            trailObj.Attachment1     = trailPart1
            trailObj.Lifetime        = 0.6
            trailObj.MinLength       = 0
            trailObj.FaceCamera      = true
            trailObj.Color           = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 80,  80)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(80,  255, 80)),
                ColorSequenceKeypoint.new(0.66, Color3.fromRGB(80,  80,  255)),
                ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 80,  80)),
            })
            trailObj.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            })
            trailObj.WidthScale = NumberSequence.new(1)
            trailObj.Parent = hrp
        end)
        SendNotify("HmD", "Trail ON 💫")
    else
        if trailObj   then trailObj:Destroy();   trailObj   = nil end
        if trailPart0 then trailPart0:Destroy(); trailPart0 = nil end
        if trailPart1 then trailPart1:Destroy(); trailPart1 = nil end
        SendNotify("HmD", "Trail OFF")
    end
end)

-- ── ESCALAS DO PERSONAGEM ───────────────────────────────────
local originalScales = {}

local function SaveScales()
    pcall(function()
        local humanoidDesc = hum:GetAppliedDescription()
        originalScales = {
            BodyDepthScale  = humanoidDesc.DepthScale,
            BodyHeightScale = humanoidDesc.HeightScale,
            BodyWidthScale  = humanoidDesc.WidthScale,
            HeadScale       = humanoidDesc.HeadScale,
        }
    end)
end

local function ApplyScale(depth, height, width, head)
    pcall(function()
        local desc = hum:GetAppliedDescription()
        desc.DepthScale  = depth
        desc.HeightScale = height
        desc.WidthScale  = width
        desc.HeadScale   = head
        hum:ApplyDescription(desc)
    end)
end

local function RestoreScales()
    if next(originalScales) then
        ApplyScale(
            originalScales.BodyDepthScale,
            originalScales.BodyHeightScale,
            originalScales.BodyWidthScale,
            originalScales.HeadScale
        )
    end
end

SaveScales()

-- Big Head
BigHeadBtn.MouseButton1Click:Connect(function()
    ToggleColor(BigHeadBtn)
    if IsOn(BigHeadBtn) then
        ApplyScale(1, 1, 1, 3.5)
        SendNotify("HmD", "Big Head ON 🗿")
    else
        RestoreScales()
        SendNotify("HmD", "Big Head OFF")
    end
end)

-- Tiny Mode
TinyBtn.MouseButton1Click:Connect(function()
    ToggleColor(TinyBtn)
    if IsOn(TinyBtn) then
        ApplyScale(0.3, 0.3, 0.3, 0.3)
        SendNotify("HmD", "Tiny ON 🐜")
    else
        RestoreScales()
        SendNotify("HmD", "Tiny OFF")
    end
end)

-- Flat Mode
FlatBtn.MouseButton1Click:Connect(function()
    ToggleColor(FlatBtn)
    if IsOn(FlatBtn) then
        ApplyScale(0.1, 1, 1, 0.5)
        SendNotify("HmD", "Flat ON 📄")
    else
        RestoreScales()
        SendNotify("HmD", "Flat OFF")
    end
end)

-- Giant Mode
GiantBtn.MouseButton1Click:Connect(function()
    ToggleColor(GiantBtn)
    if IsOn(GiantBtn) then
        ApplyScale(3, 3, 3, 3)
        SendNotify("HmD", "Giant ON 🗼")
    else
        RestoreScales()
        SendNotify("HmD", "Giant OFF")
    end
end)

-- ============================================================
-- LÓGICA — CHARACTER
-- ============================================================

SpeedBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local v = tonumber(SpeedInput.Text)
        if v then hum.WalkSpeed = v; SendNotify("HmD", "Speed → " .. v) end
    end)
end)

JumpBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local v = tonumber(JumpInput.Text)
        if v then hum.JumpPower = v; SendNotify("HmD", "Jump → " .. v) end
    end)
end)

RespawnBtn.MouseButton1Click:Connect(function()
    pcall(function() hum.Health = 0 end)
    SendNotify("HmD", "Respawnando...")
end)

-- God Mode
local godConn = nil
GodModeBtn.MouseButton1Click:Connect(function()
    ToggleColor(GodModeBtn)
    if IsOn(GodModeBtn) then
        godConn = RunService.Heartbeat:Connect(function()
            pcall(function() hum.Health = hum.MaxHealth end)
        end)
        SendNotify("HmD", "God Mode ON 🛡")
    else
        if godConn then godConn:Disconnect(); godConn = nil end
        SendNotify("HmD", "God Mode OFF")
    end
end)

-- Invisível
InvisBtn.MouseButton1Click:Connect(function()
    ToggleColor(InvisBtn)
    local t = IsOn(InvisBtn) and 1 or 0
    pcall(function()
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.Transparency = t
            end
        end
    end)
    SendNotify("HmD", IsOn(InvisBtn) and "Invisível ON 👻" or "Invisível OFF")
end)

-- NoClip
local noClipConn = nil
NoClipBtn.MouseButton1Click:Connect(function()
    ToggleColor(NoClipBtn)
    if IsOn(NoClipBtn) then
        noClipConn = RunService.Stepped:Connect(function()
            pcall(function()
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end)
        end)
        SendNotify("HmD", "NoClip ON 🔮")
    else
        if noClipConn then noClipConn:Disconnect(); noClipConn = nil end
        SendNotify("HmD", "NoClip OFF")
    end
end)

-- Voo
local flying    = false
local flyConn   = nil
local bodyGyro  = nil
local bodyVel   = nil
local flyCtrl   = {f=0, b=0, l=0, r=0}
local FLY_SPEED = 45

local function StartFly()
    flying = true
    hum.PlatformStand = true
    bodyGyro = Instance.new("BodyGyro", root)
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.P         = 9e4
    bodyGyro.CFrame    = root.CFrame
    bodyVel = Instance.new("BodyVelocity", root)
    bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVel.Velocity = Vector3.new(0, 0.1, 0)
    local cam = game.Workspace.CurrentCamera
    flyConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            local dir = (cam.CFrame.LookVector  * flyCtrl.f)
                      - (cam.CFrame.LookVector  * flyCtrl.b)
                      - (cam.CFrame.RightVector * flyCtrl.l)
                      + (cam.CFrame.RightVector * flyCtrl.r)
            bodyVel.Velocity = dir.Magnitude > 0 and dir.Unit * FLY_SPEED or Vector3.new(0, 0.1, 0)
            bodyGyro.CFrame  = cam.CFrame
        end)
    end)
end

local function StopFly()
    flying = false
    hum.PlatformStand = false
    if flyConn  then flyConn:Disconnect();  flyConn  = nil end
    if bodyGyro then bodyGyro:Destroy();    bodyGyro = nil end
    if bodyVel  then bodyVel:Destroy();     bodyVel  = nil end
end

FlyBtn.MouseButton1Click:Connect(function()
    ToggleColor(FlyBtn)
    if IsOn(FlyBtn) then StartFly(); SendNotify("HmD", "Voo ON ✈️  (W/A/S/D)")
    else StopFly();                  SendNotify("HmD", "Voo OFF") end
end)

-- ── CTRL+CLICK TP ───────────────────────────────────────────
-- Ao segurar Ctrl e clicar no chão/objeto, teleporta até lá
local ctrlTPEnabled = false
local ctrlTPConn    = nil

CtrlTPBtn.MouseButton1Click:Connect(function()
    ToggleColor(CtrlTPBtn)
    ctrlTPEnabled = IsOn(CtrlTPBtn)

    if ctrlTPEnabled then
        ctrlTPConn = mouse.Button1Down:Connect(function()
            -- Só age se Ctrl estiver pressionado
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
            or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
                pcall(function()
                    local target = mouse.Hit
                    if target then
                        -- Teleporta 3 studs acima do ponto clicado para não ficar preso
                        root.CFrame = CFrame.new(
                            target.Position + Vector3.new(0, 3, 0)
                        )
                        SendNotify("HmD", string.format(
                            "TP → (%.0f, %.0f, %.0f)",
                            target.Position.X,
                            target.Position.Y,
                            target.Position.Z
                        ))
                    end
                end)
            end
        end)
        SendNotify("HmD", "Ctrl+Click TP ON 🖱️")
    else
        if ctrlTPConn then ctrlTPConn:Disconnect(); ctrlTPConn = nil end
        SendNotify("HmD", "Ctrl+Click TP OFF")
    end
end)

-- ============================================================
-- LÓGICA — TARGET
-- ============================================================

local targetedPlayer = nil  -- Nome do jogador alvo atual

local function GetTargetPlayer()
    if not targetedPlayer then return nil end
    return Players:FindFirstChild(targetedPlayer)
end

local function GetTargetRoot()
    local p = GetTargetPlayer()
    if p and p.Character then
        return p.Character:FindFirstChild("HumanoidRootPart")
    end
end

-- ── ANIMAÇÕES ───────────────────────────────────────────────
-- IDs de animações públicas do catálogo Roblox
local ANIMS = {
    follow   = "180426354",   -- caminhada
    bang     = "608820338",   -- dança (pose atrás)
    stand    = "507770239",   -- idle olhando pra cima
    drag     = "507779738",   -- carregar algo
    headsit  = "2506281703",  -- sentado no chão
    focus    = "180436148",   -- idle assustado (olha pra frente)
}

local currentAnimTrack = nil

local function PlayAnim(animId, timePos, speed)
    pcall(function()
        -- Para qualquer animação atual primeiro
        if currentAnimTrack then
            pcall(function() currentAnimTrack:Stop() end)
            currentAnimTrack = nil
        end
        local animate = char:FindFirstChild("Animate")
        if animate then animate.Disabled = true end

        local animObj = Instance.new("Animation")
        animObj.AnimationId = "rbxassetid://" .. tostring(animId)
        local track = hum:LoadAnimation(animObj)
        track:Play()
        track.TimePosition = timePos or 0
        track:AdjustSpeed(speed or 1)
        currentAnimTrack = track

        track.Stopped:Connect(function()
            if animate then animate.Disabled = false end
        end)
    end)
end

local function StopAnim()
    pcall(function()
        if currentAnimTrack then
            currentAnimTrack:Stop()
            currentAnimTrack = nil
        end
        local animate = char:FindFirstChild("Animate")
        if animate then
            animate.Disabled = false
        end
        for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
            t:Stop()
        end
    end)
end

local function UpdateTargetUI(player)
    if player then
        targetedPlayer = player.Name
        TargetInput.Text = player.Name
        TargetIDLabel.Text = "UserID: " .. player.UserId ..
            "\nDisplay: " .. player.DisplayName ..
            "\nCreated: " .. os.date("%d/%m/%Y", os.time() - player.AccountAge * 86400)
        pcall(function()
            TargetImg.Image = Players:GetUserThumbnailAsync(
                player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        end)
    else
        targetedPlayer = nil
        TargetInput.Text = ""
        TargetIDLabel.Text = "UserID:\nDisplay:\nCreated:"
        TargetImg.Image = "rbxassetid://10818605405"
    end
end

-- Busca ao perder foco do input
TargetInput.FocusLost:Connect(function()
    local name = TargetInput.Text:lower()
    if name == "" then UpdateTargetUI(nil); return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(name) or p.DisplayName:lower():find(name) then
            UpdateTargetUI(p)
            return
        end
    end
    SendNotify("HmD", "Jogador não encontrado.")
end)

-- Limpa target se sair do servidor
Players.PlayerRemoving:Connect(function(p)
    if p.Name == targetedPlayer then
        UpdateTargetUI(nil)
        SendNotify("HmD", "Target saiu do servidor.")
    end
end)

-- VIEW — câmera segue o target
local viewConn = nil
ViewTargetBtn.MouseButton1Click:Connect(function()
    if not targetedPlayer then SendNotify("HmD", "Selecione um target primeiro."); return end
    ToggleColor(ViewTargetBtn)
    if IsOn(ViewTargetBtn) then
        viewConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local p = GetTargetPlayer()
                if p and p.Character then
                    game.Workspace.CurrentCamera.CameraSubject = p.Character.Humanoid
                end
            end)
        end)
        SendNotify("HmD", "View ON 👁")
    else
        if viewConn then viewConn:Disconnect(); viewConn = nil end
        game.Workspace.CurrentCamera.CameraSubject = plr.Character.Humanoid
        SendNotify("HmD", "View OFF")
    end
end)

-- COPY ID
CopyIDBtn.MouseButton1Click:Connect(function()
    local p = GetTargetPlayer()
    if not p then SendNotify("HmD", "Selecione um target primeiro."); return end
    -- setclipboard só funciona em executores; no Studio use print
    pcall(function() setclipboard(tostring(p.UserId)) end)
    print("[HmD] UserID copiado: " .. p.UserId)
    SendNotify("HmD", "UserID copiado: " .. p.UserId)
end)

-- FOCUS — gruda na frente do target olhando pra ele
local focusConn = nil
FocusTargetBtn.MouseButton1Click:Connect(function()
    if not targetedPlayer then SendNotify("HmD", "Selecione um target primeiro."); return end
    ToggleColor(FocusTargetBtn)
    if IsOn(FocusTargetBtn) then
        PlayAnim(ANIMS.focus, 0, 1)
        focusConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local tRoot = GetTargetRoot()
                if tRoot then
                    root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 2.5)
                    root.Velocity = Vector3.new(0, 0, 0)
                end
            end)
        end)
        SendNotify("HmD", "Focus ON 🔍")
    else
        if focusConn then focusConn:Disconnect(); focusConn = nil end
        StopAnim()
        SendNotify("HmD", "Focus OFF")
    end
end)

-- FOLLOW — segue o target mantendo distância
local followConn = nil
FollowTargetBtn.MouseButton1Click:Connect(function()
    if not targetedPlayer then SendNotify("HmD", "Selecione um target primeiro."); return end
    ToggleColor(FollowTargetBtn)
    if IsOn(FollowTargetBtn) then
        PlayAnim(ANIMS.follow, 0, 1)
        followConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local tRoot = GetTargetRoot()
                if tRoot then
                    local dist = (root.Position - tRoot.Position).Magnitude
                    if dist > 6 then
                        root.CFrame = CFrame.new(root.Position, tRoot.Position)
                        hum:MoveTo(tRoot.Position)
                    end
                end
            end)
        end)
        SendNotify("HmD", "Follow ON 🚶")
    else
        if followConn then followConn:Disconnect(); followConn = nil end
        StopAnim()
        SendNotify("HmD", "Follow OFF")
    end
end)

-- STAND — fica em pé ao lado do target com BodyVelocity
local standConn = nil
local standBV   = nil
StandTargetBtn.MouseButton1Click:Connect(function()
    if not targetedPlayer then SendNotify("HmD", "Selecione um target primeiro."); return end
    ToggleColor(StandTargetBtn)
    if IsOn(StandTargetBtn) then
        PlayAnim(ANIMS.stand, 4, 0)
        standBV = Instance.new("BodyVelocity", root)
        standBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        standBV.Velocity = Vector3.new(0, 0, 0)
        standConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local tRoot = GetTargetRoot()
                if tRoot then
                    root.CFrame = tRoot.CFrame * CFrame.new(2, 0, 0)
                    root.Velocity = Vector3.new(0, 0, 0)
                end
            end)
        end)
        SendNotify("HmD", "Stand ON 🧍")
    else
        if standConn then standConn:Disconnect(); standConn = nil end
        if standBV   then standBV:Destroy();     standBV   = nil end
        StopAnim()
        SendNotify("HmD", "Stand OFF")
    end
end)

-- BANG — fica atrás do target
local bangConn = nil
local bangBV   = nil
BangTargetBtn.MouseButton1Click:Connect(function()
    if not targetedPlayer then SendNotify("HmD", "Selecione um target primeiro."); return end
    ToggleColor(BangTargetBtn)
    if IsOn(BangTargetBtn) then
        PlayAnim(ANIMS.bang, 0, 1)
        bangBV = Instance.new("BodyVelocity", root)
        bangBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bangBV.Velocity = Vector3.new(0, 0, 0)
        bangConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local tRoot = GetTargetRoot()
                if tRoot then
                    root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 1.2)
                    root.Velocity = Vector3.new(0, 0, 0)
                end
            end)
        end)
        SendNotify("HmD", "Bang ON 💥")
    else
        if bangConn then bangConn:Disconnect(); bangConn = nil end
        if bangBV   then bangBV:Destroy();     bangBV   = nil end
        StopAnim()
        SendNotify("HmD", "Bang OFF")
    end
end)

-- DRAG — arrasta o target pela mão
local dragConn = nil
local dragBV   = nil
DragTargetBtn.MouseButton1Click:Connect(function()
    if not targetedPlayer then SendNotify("HmD", "Selecione um target primeiro."); return end
    ToggleColor(DragTargetBtn)
    if IsOn(DragTargetBtn) then
        PlayAnim(ANIMS.drag, 0.5, 0)
        dragBV = Instance.new("BodyVelocity", root)
        dragBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        dragBV.Velocity = Vector3.new(0, 0, 0)
        dragConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local p = GetTargetPlayer()
                if p and p.Character then
                    local hand = p.Character:FindFirstChild("RightHand")
                        or p.Character:FindFirstChild("Right Arm")
                    if hand then
                        root.CFrame = hand.CFrame * CFrame.new(0, -2.5, 1)
                                    * CFrame.Angles(-2, -3, 0)
                        root.Velocity = Vector3.new(0, 0, 0)
                    end
                end
            end)
        end)
        SendNotify("HmD", "Drag ON ✋")
    else
        if dragConn then dragConn:Disconnect(); dragConn = nil end
        if dragBV   then dragBV:Destroy();     dragBV   = nil end
        StopAnim()
        SendNotify("HmD", "Drag OFF")
    end
end)

-- HEADSIT — senta na cabeça do target
local headsitConn = nil
local headsitBV   = nil
HeadsitTargetBtn.MouseButton1Click:Connect(function()
    if not targetedPlayer then SendNotify("HmD", "Selecione um target primeiro."); return end
    ToggleColor(HeadsitTargetBtn)
    if IsOn(HeadsitTargetBtn) then
        PlayAnim(ANIMS.headsit, 0, 1)
        headsitBV = Instance.new("BodyVelocity", root)
        headsitBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        headsitBV.Velocity = Vector3.new(0, 0, 0)
        headsitConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local p = GetTargetPlayer()
                if p and p.Character then
                    local head = p.Character:FindFirstChild("Head")
                    if head then
                        hum.Sit = true
                        root.CFrame = head.CFrame * CFrame.new(0, 2.2, 0)
                        root.Velocity = Vector3.new(0, 0, 0)
                    end
                end
            end)
        end)
        SendNotify("HmD", "Headsit ON 🪑")
    else
        if headsitConn then headsitConn:Disconnect(); headsitConn = nil end
        if headsitBV   then headsitBV:Destroy();     headsitBV   = nil end
        StopAnim()
        SendNotify("HmD", "Headsit OFF")
    end
end)

-- TELEPORT TO TARGET
TpTargetBtn.MouseButton1Click:Connect(function()
    local tRoot = GetTargetRoot()
    if tRoot then
        root.CFrame = tRoot.CFrame + Vector3.new(0, 3, 0)
        SendNotify("HmD", "Teleportado até " .. (targetedPlayer or "?"))
    else
        SendNotify("HmD", "Selecione um target primeiro.")
    end
end)

-- PUSH TARGET
PushTargetBtn.MouseButton1Click:Connect(function()
    local tRoot = GetTargetRoot()
    if tRoot then
        pcall(function()
            local bv = Instance.new("BodyVelocity", tRoot)
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = (tRoot.CFrame.LookVector + Vector3.new(0, 0.5, 0)) * 120
            game:GetService("Debris"):AddItem(bv, 0.15)
        end)
        SendNotify("HmD", "Push! 👊")
    else
        SendNotify("HmD", "Selecione um target primeiro.")
    end
end)

-- ── COPIAR ANIMAÇÃO ─────────────────────────────────────────
-- Lê todas as AnimationTracks tocando no target e replica no local
local copyAnimConn = nil

CopyAnimBtn.MouseButton1Click:Connect(function()
    if not targetedPlayer then SendNotify("HmD", "Selecione um target primeiro."); return end
    ToggleColor(CopyAnimBtn)
    if IsOn(CopyAnimBtn) then
        copyAnimConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local p = GetTargetPlayer()
                if not (p and p.Character) then return end
                local tHum = p.Character:FindFirstChildOfClass("Humanoid")
                if not tHum then return end

                local tracks = tHum:GetPlayingAnimationTracks()
                if #tracks == 0 then return end

                -- Pega a animação principal (maior peso)
                local best = tracks[1]
                for _, t in ipairs(tracks) do
                    if t.WeightCurrent > best.WeightCurrent then best = t end
                end

                local animId = best.Animation.AnimationId
                -- Só recarrega se mudou de animação
                if currentAnimTrack
                   and currentAnimTrack.Animation
                   and currentAnimTrack.Animation.AnimationId == animId
                   and currentAnimTrack.IsPlaying then
                    -- Sincroniza TimePosition para ficar igual ao target
                    pcall(function()
                        currentAnimTrack.TimePosition = best.TimePosition
                    end)
                    return
                end

                -- Carrega e toca a nova animação
                pcall(function()
                    if currentAnimTrack then
                        currentAnimTrack:Stop(0)
                        currentAnimTrack = nil
                    end
                    local aObj = Instance.new("Animation")
                    aObj.AnimationId = animId
                    local newTrack = hum:LoadAnimation(aObj)
                    newTrack:Play(0)
                    newTrack.TimePosition = best.TimePosition
                    newTrack:AdjustSpeed(best.Speed)
                    currentAnimTrack = newTrack
                end)
            end)
        end)
        SendNotify("HmD", "Copiando animação de " .. targetedPlayer .. " 🎭")
    else
        if copyAnimConn then copyAnimConn:Disconnect(); copyAnimConn = nil end
        StopAnim()
        SendNotify("HmD", "Cópia de animação OFF")
    end
end)

-- ── ESP TARGET (highlight no jogador selecionado) ───────────
local espTargetHL  = nil  -- SelectionBox do target

ESPTargetBtn.MouseButton1Click:Connect(function()
    if not targetedPlayer then SendNotify("HmD", "Selecione um target primeiro."); return end
    ToggleColor(ESPTargetBtn)
    if IsOn(ESPTargetBtn) then
        pcall(function()
            local p = GetTargetPlayer()
            if not (p and p.Character) then return end
            espTargetHL = Instance.new("SelectionBox")
            espTargetHL.Adornee         = p.Character
            espTargetHL.Color3          = Color3.fromRGB(255, 50, 50)
            espTargetHL.LineThickness   = 0.06
            espTargetHL.SurfaceTransparency = 0.7
            espTargetHL.SurfaceColor3   = Color3.fromRGB(255, 50, 50)
            espTargetHL.Parent          = game.CoreGui
        end)
        SendNotify("HmD", "ESP Target ON 🔴")
    else
        if espTargetHL then espTargetHL:Destroy(); espTargetHL = nil end
        SendNotify("HmD", "ESP Target OFF")
    end
end)

-- Remove ESP target se o jogador sair ou respawnar
Players.PlayerRemoving:Connect(function(p)
    if p.Name == targetedPlayer and espTargetHL then
        espTargetHL:Destroy(); espTargetHL = nil
    end
end)

-- ── ESP GLOBAL (todos os jogadores) ─────────────────────────
local espBoxes   = {}   -- { [playerName] = SelectionBox }
local espLabels  = {}   -- { [playerName] = BillboardGui }
local espAllConn = nil

local function CreateESPForPlayer(p)
    if not (p and p.Character) then return end
    if espBoxes[p.Name] then return end

    -- SelectionBox (outline)
    local box = Instance.new("SelectionBox")
    box.Adornee             = p.Character
    box.Color3              = Color3.fromRGB(0, 200, 255)
    box.LineThickness       = 0.04
    box.SurfaceTransparency = 0.85
    box.SurfaceColor3       = Color3.fromRGB(0, 200, 255)
    box.Parent              = game.CoreGui
    espBoxes[p.Name]        = box

    -- BillboardGui com nome e vida acima da cabeça
    local bb = Instance.new("BillboardGui")
    bb.Adornee        = p.Character:FindFirstChild("Head") or p.Character.PrimaryPart
    bb.Size           = UDim2.new(0, 120, 0, 40)
    bb.StudsOffset    = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop    = true
    bb.Parent         = game.CoreGui
    espLabels[p.Name] = bb

    local nameLabel = Instance.new("TextLabel", bb)
    nameLabel.Name                  = "NameLbl"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size                  = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Font                  = Enum.Font.GothamBold
    nameLabel.Text                  = p.Name
    nameLabel.TextColor3            = Color3.fromRGB(0, 220, 255)
    nameLabel.TextScaled            = true
    nameLabel.TextStrokeTransparency = 0.4

    local hpLabel = Instance.new("TextLabel", bb)
    hpLabel.Name                   = "HpLbl"
    hpLabel.BackgroundTransparency = 1
    hpLabel.Position               = UDim2.new(0, 0, 0.5, 0)
    hpLabel.Size                   = UDim2.new(1, 0, 0.5, 0)
    hpLabel.Font                   = Enum.Font.Gotham
    hpLabel.TextColor3             = Color3.fromRGB(100, 255, 100)
    hpLabel.TextScaled             = true
    hpLabel.TextStrokeTransparency = 0.4
end

local function RemoveESPForPlayer(name)
    if espBoxes[name]  then espBoxes[name]:Destroy();  espBoxes[name]  = nil end
    if espLabels[name] then espLabels[name]:Destroy(); espLabels[name] = nil end
end

local function ClearAllESP()
    for name, _ in pairs(espBoxes)  do RemoveESPForPlayer(name) end
    espBoxes  = {}
    espLabels = {}
end

ESPAllBtn.MouseButton1Click:Connect(function()
    ToggleColor(ESPAllBtn)
    if IsOn(ESPAllBtn) then
        -- Cria ESP para jogadores já na partida
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= plr then
                pcall(function() CreateESPForPlayer(p) end)
            end
        end

        -- Cria ESP para jogadores que entrarem
        Players.PlayerAdded:Connect(function(p)
            if IsOn(ESPAllBtn) and p ~= plr then
                p.CharacterAdded:Connect(function()
                    task.wait(1)
                    if IsOn(ESPAllBtn) then
                        pcall(function() CreateESPForPlayer(p) end)
                    end
                end)
            end
        end)

        -- Remove se alguém sair
        Players.PlayerRemoving:Connect(function(p)
            RemoveESPForPlayer(p.Name)
        end)

        -- Atualiza HP e refixa adornee se personagem mudar
        espAllConn = RunService.Heartbeat:Connect(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= plr then
                    pcall(function()
                        local tHum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                        local bb   = espLabels[p.Name]
                        if bb and tHum then
                            local hpLbl = bb:FindFirstChild("HpLbl")
                            if hpLbl then
                                hpLbl.Text = string.format("❤ %.0f / %.0f", tHum.Health, tHum.MaxHealth)
                                -- cor verde→vermelho conforme a vida
                                local pct = math.clamp(tHum.Health / tHum.MaxHealth, 0, 1)
                                hpLbl.TextColor3 = Color3.fromRGB(
                                    math.floor((1 - pct) * 255),
                                    math.floor(pct * 220),
                                    50
                                )
                            end
                        end
                        -- Se personagem respawnou, recria ESP
                        if p.Character and not espBoxes[p.Name] then
                            CreateESPForPlayer(p)
                        end
                    end)
                end
            end
        end)

        SendNotify("HmD", "ESP Global ON 👁")
    else
        if espAllConn then espAllConn:Disconnect(); espAllConn = nil end
        ClearAllESP()
        SendNotify("HmD", "ESP Global OFF")
    end
end)

-- ============================================================
-- LÓGICA — ADMIN
-- ============================================================

TpBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local target = Players:FindFirstChild(TpInput.Text)
        if target and target.Character then
            local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if tRoot then
                root.CFrame = tRoot.CFrame + Vector3.new(0, 3, 0)
                SendNotify("HmD", "Teleportado até " .. TpInput.Text)
            end
        else
            SendNotify("HmD", "Jogador não encontrado.")
        end
    end)
end)

TpBringBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local target = Players:FindFirstChild(TpInput.Text)
        if target and target.Character then
            local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if tRoot then
                tRoot.CFrame = root.CFrame + Vector3.new(3, 0, 0)
                SendNotify("HmD", TpInput.Text .. " trazido!")
            end
        else
            SendNotify("HmD", "Jogador não encontrado.")
        end
    end)
end)

TpSpawnBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local spawn = game.Workspace:FindFirstChildOfClass("SpawnLocation")
        if spawn then
            root.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
            SendNotify("HmD", "Teleportado ao spawn 🏁")
        else
            SendNotify("HmD", "SpawnLocation não encontrado.")
        end
    end)
end)

ScoreAddBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local val = tonumber(ScoreInput.Text)
        if not val then return end
        local ls = plr:FindFirstChild("leaderstats")
        if ls then
            for _, stat in ipairs(ls:GetChildren()) do
                if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                    stat.Value = stat.Value + val
                end
            end
            SendNotify("HmD", "+" .. val .. " adicionado!")
        else
            SendNotify("HmD", "leaderstats não encontrado neste jogo.")
        end
    end)
end)

ScoreResetBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local ls = plr:FindFirstChild("leaderstats")
        if ls then
            for _, stat in ipairs(ls:GetChildren()) do
                if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                    stat.Value = 0
                end
            end
            SendNotify("HmD", "Stats zerados 🔁")
        else
            SendNotify("HmD", "leaderstats não encontrado neste jogo.")
        end
    end)
end)

RejoinBtn.MouseButton1Click:Connect(function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
end)

ServerHopBtn.MouseButton1Click:Connect(function()
    SendNotify("HmD", "Server Hop: configure HttpService no seu jogo.")
end)

ChatSendBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local msg = ChatInput.Text
        if msg ~= "" then
            game:GetService("ReplicatedStorage")
                .DefaultChatSystemChatEvents
                .SayMessageRequest:FireServer(msg, "All")
            ChatInput.Text = ""
        end
    end)
end)

-- ============================================================
-- TECLAS DE VÔO (só quando flying = true)
-- ============================================================

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe or not flying then return end
    local k = input.KeyCode
    if k == Enum.KeyCode.W then flyCtrl.f = 1
    elseif k == Enum.KeyCode.S then flyCtrl.b = 1
    elseif k == Enum.KeyCode.A then flyCtrl.l = 1
    elseif k == Enum.KeyCode.D then flyCtrl.r = 1 end
end)

UserInputService.InputEnded:Connect(function(input)
    if not flying then return end
    local k = input.KeyCode
    if k == Enum.KeyCode.W then flyCtrl.f = 0
    elseif k == Enum.KeyCode.S then flyCtrl.b = 0
    elseif k == Enum.KeyCode.A then flyCtrl.l = 0
    elseif k == Enum.KeyCode.D then flyCtrl.r = 0 end
end)

-- ============================================================
-- ABRIR / FECHAR
-- ============================================================

local function ToggleGui()
    Background.Visible = not Background.Visible
end

OpenCloseBtn.MouseButton1Click:Connect(ToggleGui)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.B then ToggleGui() end
end)

-- ============================================================
-- NOTIFICAÇÃO INICIAL
-- ============================================================
SendNotify("HmD", "GUI carregada! [B] abre/fecha  |  Ctrl+Click para TP", 6)

-- ============================================================
-- SISTEMA DE TAGS — interliga todos com HmD no servidor
-- ============================================================

local CollectionService = game:GetService("CollectionService")
local TAG_NAME          = "HmD_User"  -- tag usada para identificar usuários

-- Cores para cada usuário (cíclico)
local TAG_COLORS = {
    Color3.fromRGB(255, 210, 60),   -- dourado
    Color3.fromRGB(80,  200, 255),  -- ciano
    Color3.fromRGB(120, 255, 120),  -- verde
    Color3.fromRGB(255, 120, 120),  -- vermelho
    Color3.fromRGB(200, 120, 255),  -- roxo
    Color3.fromRGB(255, 170, 80),   -- laranja
}

-- Tabela de entradas na lista (nome → frame)
local userEntries  = {}
local colorIndex   = 0
local billboards   = {}  -- tags 3D acima das cabeças

-- ── Marca o jogador local com a tag ─────────────────────────
pcall(function()
    CollectionService:AddTag(plr, TAG_NAME)
end)

-- ── Cria a tag 3D acima da cabeça ───────────────────────────
local function CreateBillboard(p, color)
    pcall(function()
        if billboards[p.Name] then
            billboards[p.Name]:Destroy()
            billboards[p.Name] = nil
        end

        local char3D = p.Character
        if not char3D then return end
        local head = char3D:FindFirstChild("Head")
        if not head then return end

        local role      = GetRole(p)
        local roleColor = role.color

        local bb = Instance.new("BillboardGui")
        bb.Name         = "HmD_Tag"
        bb.Adornee      = head
        bb.Size         = UDim2.new(0, 200, 0, 58)
        bb.StudsOffset  = Vector3.new(0, 3.8, 0)
        bb.AlwaysOnTop  = true
        bb.ResetOnSpawn = false
        bb.LightInfluence = 0
        bb.Parent       = game.CoreGui

        -- Cargo  (ex: 👑 Owner)  — cor do cargo, contorno preto
        local cargoLbl = Instance.new("TextLabel", bb)
        cargoLbl.BackgroundTransparency = 1
        cargoLbl.Size                   = UDim2.new(1, 0, 0, 26)
        cargoLbl.Position               = UDim2.new(0, 0, 0, 0)
        cargoLbl.Font                   = Enum.Font.FredokaOne
        cargoLbl.Text                   = role.emoji .. "  " .. role.role
        cargoLbl.TextColor3             = roleColor
        cargoLbl.TextSize               = 20
        cargoLbl.TextXAlignment         = Enum.TextXAlignment.Center
        cargoLbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
        cargoLbl.TextStrokeTransparency = 0     -- contorno preto sólido

        -- Nome do jogador — branco com contorno preto sólido
        local nameLbl = Instance.new("TextLabel", bb)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Size                   = UDim2.new(1, 0, 0, 28)
        nameLbl.Position               = UDim2.new(0, 0, 0, 28)
        nameLbl.Font                   = Enum.Font.FredokaOne
        nameLbl.Text                   = p.Name
        nameLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
        nameLbl.TextSize               = 22
        nameLbl.TextXAlignment         = Enum.TextXAlignment.Center
        nameLbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
        nameLbl.TextStrokeTransparency = 0     -- contorno preto sólido

        billboards[p.Name] = bb
    end)
end

-- ── Adiciona entrada na lista do Home ───────────────────────
local function AddUserEntry(p, color)
    if userEntries[p.Name] then return end  -- já existe

    local row = Instance.new("Frame")
    row.Name                 = p.Name
    row.Parent               = UsersList
    row.BackgroundColor3     = Color3.fromRGB(38, 38, 38)
    row.BackgroundTransparency = 0.2
    row.BorderSizePixel      = 0
    row.Size                 = UDim2.new(1, 0, 0, 32)
    row.ZIndex               = 13
    AddCorner(row, 4)

    local role      = GetRole(p)
    local roleColor = role.color

    -- Indicador colorido (cor do cargo)
    local dot = Instance.new("Frame", row)
    dot.BackgroundColor3 = roleColor
    dot.BorderSizePixel  = 0
    dot.Position         = UDim2.new(0, 6, 0.5, -6)
    dot.Size             = UDim2.new(0, 12, 0, 12)
    dot.ZIndex           = 14
    AddCorner(dot, 6)

    -- Foto miniatura
    local thumb = Instance.new("ImageLabel", row)
    thumb.BackgroundColor3 = GRAY_DARK
    thumb.BorderSizePixel  = 0
    thumb.Position         = UDim2.new(0, 24, 0.5, -12)
    thumb.Size             = UDim2.new(0, 24, 0, 24)
    thumb.ZIndex           = 14
    AddCorner(thumb, 3)
    pcall(function()
        thumb.Image = Players:GetUserThumbnailAsync(
            p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end)

    -- Nome com cor do cargo
    local nameLbl = Instance.new("TextLabel", row)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Position               = UDim2.new(0, 54, 0, 0)
    nameLbl.Size                   = UDim2.new(1, -120, 1, 0)
    nameLbl.Font                   = Enum.Font.GothamBold
    nameLbl.Text                   = p.Name
    nameLbl.TextColor3             = roleColor
    nameLbl.TextSize               = 13
    nameLbl.TextXAlignment         = Enum.TextXAlignment.Left
    nameLbl.ZIndex                 = 14

    -- Badge de cargo sempre visível
    local badge = Instance.new("TextLabel", row)
    badge.BackgroundColor3       = roleColor
    badge.BackgroundTransparency = 0.25
    badge.BorderSizePixel        = 0
    badge.Position               = UDim2.new(1, -78, 0.5, -9)
    badge.Size                   = UDim2.new(0, 70, 0, 18)
    badge.Font                   = Enum.Font.GothamBold
    badge.Text                   = role.emoji .. " " .. role.role
    badge.TextColor3             = Color3.fromRGB(15, 15, 15)
    badge.TextSize               = 10
    badge.ZIndex                 = 14
    AddCorner(badge, 4)

    -- Indicador "VOCÊ" extra se for o jogador local
    if p == plr then
        local youDot = Instance.new("Frame", row)
        youDot.BackgroundColor3 = Color3.fromRGB(60, 220, 60)
        youDot.BorderSizePixel  = 0
        youDot.Position         = UDim2.new(0, 6, 0.5, -6)
        youDot.Size             = UDim2.new(0, 12, 0, 12)
        youDot.ZIndex           = 15
        AddCorner(youDot, 6)
    end

    -- Atualiza tamanho do canvas
    local count = 0
    for _ in pairs(userEntries) do count = count + 1 end
    UsersList.CanvasSize = UDim2.new(0, 0, 0, (count + 1) * 36)

    userEntries[p.Name] = row
end

-- ── Remove entrada da lista e billboard ─────────────────────
local function RemoveUserEntry(name)
    if userEntries[name] then
        userEntries[name]:Destroy()
        userEntries[name] = nil
    end
    if billboards[name] then
        billboards[name]:Destroy()
        billboards[name] = nil
    end
    -- Atualiza canvas
    local count = 0
    for _ in pairs(userEntries) do count = count + 1 end
    UsersList.CanvasSize = UDim2.new(0, 0, 0, count * 36)
end

-- ── Processa um jogador com a tag ───────────────────────────
local function OnTagged(p)
    if not p:IsA("Player") then return end
    local color = GetRoleColor(p)   -- cor baseada no cargo

    AddUserEntry(p, color)

    local function setupChar()
        task.wait(0.5)
        if p ~= plr then
            CreateBillboard(p, color)
        end
    end

    if p.Character then setupChar() end
    p.CharacterAdded:Connect(setupChar)
end

-- ── Detecta jogadores que JÁ têm a tag ao carregar ──────────
for _, p in ipairs(Players:GetPlayers()) do
    if CollectionService:HasTag(p, TAG_NAME) then
        OnTagged(p)
    end
end

-- ── Detecta novos jogadores que ganham a tag ────────────────
CollectionService:GetInstanceAddedSignal(TAG_NAME):Connect(function(inst)
    if inst:IsA("Player") then
        -- Pequena espera para o personagem carregar
        task.wait(0.3)
        OnTagged(inst)
        if inst ~= plr then
            SendNotify("HmD", "👑 " .. inst.Name .. " também está usando HmD!")
        end
    end
end)

-- ── Remove quando jogador perde a tag ou sai ────────────────
CollectionService:GetInstanceRemovedSignal(TAG_NAME):Connect(function(inst)
    if inst:IsA("Player") then
        RemoveUserEntry(inst.Name)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    -- Remove tag ao sair para limpar em outros clientes
    pcall(function() CollectionService:RemoveTag(p, TAG_NAME) end)
    RemoveUserEntry(p.Name)
end)

-- ── Adiciona o próprio jogador imediatamente ────────────────
task.spawn(function()
    task.wait(0.5)
    OnTagged(plr)
end)
