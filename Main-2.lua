--// ================= SERVICES =================
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local TeleportService  = game:GetService("TeleportService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

--// ================= CLEANUP PREVIOUS INSTANCE =================
if CoreGui:FindFirstChild("ElyseraUI") then
    CoreGui.ElyseraUI:Destroy()
end
if CoreGui:FindFirstChild("ElyseraCover") then
    CoreGui.ElyseraCover:Destroy()
end

--// ================= THEME =================
local Theme = {
    Background     = Color3.fromRGB(29, 21, 52),    -- #1D1534 main background
    Panel          = Color3.fromRGB(33, 21, 58),    -- #21153A cards, buttons, dialogs
    PanelAlt       = Color3.fromRGB(37, 25, 66),    -- #251942 sidebar, tab / function panels
    Header         = Color3.fromRGB(49, 32, 75),    -- #31204B top bar, highlight tab
    Border         = Color3.fromRGB(84, 53, 128),   -- #543580 purple border
    AccentPink     = Color3.fromRGB(243, 99, 225),  -- #F363E1 primary accent
    AccentPurple   = Color3.fromRGB(175, 88, 249),  -- #AF58F9 neon purple
    Sakura         = Color3.fromRGB(255, 183, 213), -- #FFB7D5 selected tab text
    Text           = Color3.fromRGB(226, 190, 250), -- #E2BEFA primary text
    SubText        = Color3.fromRGB(191, 157, 238), -- #BF9DEE secondary text
    Danger         = Color3.fromRGB(247, 118, 142), -- #F7768E close / danger
    ToggleTrackOff = Color3.fromRGB(71, 48, 112),   -- #473070 switch track (off)
    ToggleKnobOn   = Color3.fromRGB(255, 255, 255), -- #FFFFFF switch knob (on)
}

--// ================= CONFIG =================
local UI_NAME             = "Elysera"
local UI_W, UI_H          = 650, 420
local MIN_UI_W, MIN_UI_H  = 420, 260
local TOGGLE_SIZE         = 50
local POPUP_TIME          = 0.25
local CLOSE_TIME          = 0.20
local TOPBAR_HEIGHT       = 40
local SAVE_FILE           = "Elysera_Settings.json"
local SAVE_DELAY          = 0.3

local MARGIN_EDGE         = 8
local MARGIN_GAP          = 10
local TAB_PANEL_WIDTH     = 150
local HIGHLIGHT_HEIGHT    = 56
local HIGHLIGHT_GAP       = 8

local CENTER        = UDim2.fromScale(0.5, 0.5)
local ANCHOR_CENTER = Vector2.new(0.5, 0.5)
local EASE_QUAD     = Enum.EasingStyle.Quad
local EASE_QUINT    = Enum.EasingStyle.Quint
local EASE_BACK     = Enum.EasingStyle.Back
local EASE_LINEAR   = Enum.EasingStyle.Linear
local DIR_IN        = Enum.EasingDirection.In
local DIR_OUT       = Enum.EasingDirection.Out

local uiLocked = false

--// ================= ROOT =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ElyseraUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 10
ScreenGui.Parent = CoreGui

--// ================= UTILITY =================
local Connections = {}
local function track(conn)
    Connections[#Connections + 1] = conn
    return conn
end

ScreenGui.Destroying:Connect(function()
    for _, c in ipairs(Connections) do c:Disconnect() end
end)

local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    inst.Parent = parent
    return inst
end

local function corner(inst, radius)
    return new("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, inst)
end

local function stroke(inst, color, thickness)
    return new("UIStroke", { Color = color or Theme.Border, Thickness = thickness or 1 }, inst)
end

local function padding(inst, left, right, top, bottom)
    return new("UIPadding", {
        PaddingLeft   = UDim.new(0, left or 0),
        PaddingRight  = UDim.new(0, right or 0),
        PaddingTop    = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    }, inst)
end

local function list(inst, gap, props)
    props = props or {}
    props.SortOrder = Enum.SortOrder.LayoutOrder
    props.Padding = UDim.new(0, gap or 0)
    return new("UIListLayout", props, inst)
end

local function label(parent, props)
    props.BackgroundTransparency = 1
    props.Font = props.Font or Enum.Font.GothamBold
    return new("TextLabel", props, parent)
end

local function tween(inst, time, props, style, dir)
    local t = TweenService:Create(inst, TweenInfo.new(time, style or EASE_QUAD, dir or DIR_OUT), props)
    t:Play()
    return t
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

local function makeDraggable(handle, target, onEnd, onClick, threshold)
    threshold = threshold or 0
    local dragging, moved, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if uiLocked or not isPress(input) then return end
        dragging, moved = true, false
        dragStart, startPos = input.Position, target.Position

        input.Changed:Connect(function()
            if input.UserInputState ~= Enum.UserInputState.End then return end
            if dragging then
                if moved then
                    if onEnd then onEnd() end
                elseif onClick and not uiLocked then
                    onClick()
                end
            end
            dragging = false
        end)
    end)

    track(UserInputService.InputChanged:Connect(function(input)
        if uiLocked then dragging = false return end
        if not dragging or not isMove(input) then return end
        local delta = input.Position - dragStart
        if not moved and delta.Magnitude > threshold then moved = true end
        if moved then
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))
end

local function pressScale(btn, downScale)
    local scale = new("UIScale", {}, btn)
    local function release()
        tween(scale, 0.2, { Scale = 1 }, EASE_BACK, DIR_OUT)
    end
    btn.MouseButton1Down:Connect(function()
        if uiLocked then return end
        tween(scale, 0.08, { Scale = downScale })
    end)
    btn.MouseButton1Up:Connect(release)
    btn.MouseLeave:Connect(release)
end

--// ================= SAVED SETTINGS (position / size) =================
local canFS = typeof(writefile) == "function"
    and typeof(readfile) == "function"
    and typeof(isfile) == "function"

local function num(v, default)
    return (type(v) == "number" and v == v and math.abs(v) < 1e6) and v or default
end

local function getViewport()
    local camera = Workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function loadSettings()
    if not canFS then return {} end
    local ok, data = pcall(function()
        if isfile(SAVE_FILE) then
            return HttpService:JSONDecode(readfile(SAVE_FILE))
        end
    end)
    return (ok and type(data) == "table") and data or {}
end

local Saved = loadSettings()
local viewport0 = getViewport()

local curW = math.clamp(num(Saved.w, UI_W), MIN_UI_W, math.max(MIN_UI_W, viewport0.X))
local curH = math.clamp(num(Saved.h, UI_H), MIN_UI_H, math.max(MIN_UI_H, viewport0.Y))

local maxOffX = math.max(0, (viewport0.X - curW) / 2)
local maxOffY = math.max(0, (viewport0.Y - curH) / 2)
local uiPosition = UDim2.new(
    0.5, math.clamp(num(Saved.uiX, 0), -maxOffX, maxOffX),
    0.5, math.clamp(num(Saved.uiY, 0), -maxOffY, maxOffY)
)

local DEFAULT_TOGGLE_POS = UDim2.new(0, 20, 0.5, -TOGGLE_SIZE / 2)
local togglePosition = DEFAULT_TOGGLE_POS
if type(Saved.toggle) == "table" then
    local xs, xo = num(Saved.toggle[1], 0), num(Saved.toggle[2], 20)
    local ys, yo = num(Saved.toggle[3], 0.5), num(Saved.toggle[4], -TOGGLE_SIZE / 2)
    local absX = viewport0.X * xs + xo
    local absY = viewport0.Y * ys + yo
    xo += math.clamp(absX, 0, math.max(0, viewport0.X - TOGGLE_SIZE)) - absX
    yo += math.clamp(absY, 0, math.max(0, viewport0.Y - TOGGLE_SIZE)) - absY
    togglePosition = UDim2.new(xs, xo, ys, yo)
end

local ToggleButton
local saveQueued = false
local function saveSettings()
    if not canFS or saveQueued then return end
    saveQueued = true
    task.delay(SAVE_DELAY, function()
        saveQueued = false
        local t = ToggleButton and ToggleButton.Position or togglePosition
        local data = {
            w = curW, h = curH,
            uiX = uiPosition.X.Offset, uiY = uiPosition.Y.Offset,
            toggle = { t.X.Scale, t.X.Offset, t.Y.Scale, t.Y.Offset },
        }
        pcall(writefile, SAVE_FILE, HttpService:JSONEncode(data))
    end)
end

--// ================= FLOATING TOGGLE BUTTON =================
ToggleButton = new("TextButton", {
    Name = "MG_Toggle",
    Size = UDim2.fromOffset(TOGGLE_SIZE, TOGGLE_SIZE),
    Position = togglePosition,
    BackgroundColor3 = Theme.Panel,
    Text = "",
    AutoButtonColor = false,
}, ScreenGui)
corner(ToggleButton, 14)
stroke(ToggleButton)

do
    local ICON_PX = 32
    local unit = ICON_PX / 48
    local V = Vector2.new

    local Holder = new("Frame", {
        Name = "Icon",
        AnchorPoint = ANCHOR_CENTER,
        Position = CENTER,
        Size = UDim2.fromOffset(ICON_PX, ICON_PX),
        BackgroundTransparency = 1,
    }, ToggleButton)

    local function segment(a, b, thick, color)
        local d, mid = b - a, (a + b) / 2
        corner(new("Frame", {
            AnchorPoint = ANCHOR_CENTER,
            Position = UDim2.fromOffset(mid.X, mid.Y),
            Size = UDim2.fromOffset(d.Magnitude + thick, thick),
            Rotation = math.deg(math.atan2(d.Y, d.X)),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
        }, Holder), thick / 2)
    end

    local function roundPath(pts, r)
        if r <= 0 or #pts < 3 then return pts end
        local out = { pts[1] }
        for i = 2, #pts - 1 do
            local P, A, B = pts[i], pts[i - 1], pts[i + 1]
            local p1 = P + (A - P).Unit * r
            local p2 = P + (B - P).Unit * r
            for step = 0, 5 do
                local t = step / 5
                table.insert(out, p1:Lerp(P, t):Lerp(P:Lerp(p2, t), t))
            end
        end
        table.insert(out, pts[#pts])
        return out
    end

    local function drawPath(pts, radius, width, color, inner)
        pts = roundPath(pts, radius)
        local mapped = {}
        for i, p in ipairs(pts) do
            if inner then p = p * 0.55 + V(10.8, 10.8) end
            mapped[i] = p * unit
        end
        local thick = (inner and width * 0.55 or width) * unit
        for i = 1, #mapped - 1 do
            segment(mapped[i], mapped[i + 1], thick, color)
        end
    end

    local F, S = Theme.AccentPurple, Theme.AccentPink

    drawPath({ V(4, 34), V(4, 44), V(14, 44) }, 0, 4, F)
    drawPath({ V(34, 44), V(44, 44), V(44, 34) }, 0, 4, F)
    drawPath({ V(34, 4), V(44, 4), V(44, 14) }, 0, 4, F)
    drawPath({ V(14, 4), V(4, 4), V(4, 14) }, 0, 4, F)

    drawPath({ V(20, 15), V(24, 19), V(28, 15) }, 0, 6, S, true)
    drawPath({ V(24, 19), V(24, 4), V(44, 4), V(44, 19) }, 4, 6, S, true)
    drawPath({ V(28, 33), V(24, 29), V(20, 33) }, 0, 6, S, true)
    drawPath({ V(24, 29), V(24, 44), V(4, 44), V(4, 29) }, 4, 6, S, true)
    drawPath({ V(33, 20), V(29, 24), V(33, 28) }, 0, 6, S, true)
    drawPath({ V(29, 24), V(44, 24), V(44, 44), V(29, 44) }, 4, 6, S, true)
    drawPath({ V(15, 28), V(19, 24), V(15, 20) }, 0, 6, S, true)
    drawPath({ V(19, 24), V(4, 24), V(4, 4), V(19, 4) }, 4, 6, S, true)
end

--// ================= MAIN WINDOW =================
local MainUI = new("CanvasGroup", {
    Name = "MG_Main",
    AnchorPoint = ANCHOR_CENTER,
    Position = uiPosition,
    Size = UDim2.fromOffset(curW, curH),
    GroupTransparency = 1,
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Visible = false,
}, ScreenGui)
corner(MainUI, 12)
local MainUIStroke = stroke(MainUI)

--// ---- Top bar ----
local TopBar = new("Frame", {
    Name = "TopBar",
    Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT),
    BackgroundColor3 = Theme.Header,
    BorderSizePixel = 0,
    Active = true,
}, MainUI)
corner(TopBar, 12)

new("Frame", {
    Size = UDim2.new(1, 0, 0, 12),
    Position = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = Theme.Header,
    BorderSizePixel = 0,
}, TopBar)

new("Frame", {
    Size = UDim2.new(1, 0, 0, 2),
    Position = UDim2.new(0, 0, 1, -2),
    BackgroundColor3 = Theme.AccentPink,
    BorderSizePixel = 0,
    ZIndex = 2,
}, TopBar)

label(TopBar, {
    Size = UDim2.new(1, -180, 1, 0),
    Position = UDim2.fromOffset(16, 0),
    Text = UI_NAME,
    TextSize = 18,
    TextColor3 = Theme.AccentPink,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 2,
})

--// ---- Topbar icons ----
local TOPBAR_BTN_SIZE   = 26
local TOPBAR_BTN_GAP    = 6
local TOPBAR_BTN_MARGIN = 8
local ICON_SIZE         = 14

local function iconBar(holder, w, h, color, rotation)
    return corner(new("Frame", {
        AnchorPoint = ANCHOR_CENTER,
        Position = CENTER,
        Size = UDim2.fromOffset(w, h),
        Rotation = rotation or 0,
        BackgroundColor3 = color,
        BorderSizePixel = 0,
    }, holder), 1)
end

local function iconBox(holder, size, color, radius, thickness, pos, fill)
    local f = new("Frame", {
        AnchorPoint = ANCHOR_CENTER,
        Position = pos or CENTER,
        Size = UDim2.fromOffset(size, size),
        BackgroundColor3 = fill,
        BackgroundTransparency = fill and 0 or 1,
        BorderSizePixel = 0,
    }, holder)
    corner(f, radius)
    stroke(f, color, thickness)
end

local Icons = {}

function Icons.minimize(h, c)
    iconBar(h, ICON_SIZE, 1.5, c)
end

function Icons.maximize(h, c)
    iconBox(h, ICON_SIZE, c, 3, 1.4)
end

function Icons.restore(h, c, bg)
    iconBox(h, ICON_SIZE - 4, c, 2, 1.3, UDim2.new(0.5, 2, 0.5, -2), bg)
    iconBox(h, ICON_SIZE - 4, c, 2, 1.3, UDim2.new(0.5, -2, 0.5, 2), bg)
end

function Icons.close(h, c)
    iconBar(h, ICON_SIZE + 2, 1.5, c, 45)
    iconBar(h, ICON_SIZE + 2, 1.5, c, -45)
end

function Icons.resize(h, c)
    iconBox(h, ICON_SIZE, c, 3, 1.4)
    iconBar(h, ICON_SIZE * 0.95, 1.5, c, -45)
end

function Icons.reset(h, c)
    local Ring = new("Frame", {
        AnchorPoint = ANCHOR_CENTER,
        Position = CENTER,
        Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE),
        BackgroundTransparency = 1,
    }, h)
    corner(Ring, 100)
    new("UIGradient", {
        Rotation = 45,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 1),
            NumberSequenceKeypoint.new(0.22, 1),
            NumberSequenceKeypoint.new(0.23, 0),
            NumberSequenceKeypoint.new(1.00, 0),
        }),
    }, stroke(Ring, c, 1.5))

    for _, r in ipairs({
        { UDim2.fromOffset(0, 0),   UDim2.fromOffset(1.5, 5) },
        { UDim2.fromOffset(0, 3.5), UDim2.fromOffset(5, 1.5) },
    }) do
        corner(new("Frame", {
            Position = r[1], Size = r[2],
            BackgroundColor3 = c, BorderSizePixel = 0,
        }, h), 1)
    end
end

local function drawIcon(holder, kind, color, bgColor)
    holder:ClearAllChildren()
    Icons[kind](holder, color, bgColor)
end

local function createTopbarButton(kind, order, iconColor)
    iconColor = iconColor or Theme.Text
    local xOffset = -(TOPBAR_BTN_MARGIN + TOPBAR_BTN_SIZE * order + TOPBAR_BTN_GAP * (order - 1))

    local Btn = new("TextButton", {
        Size = UDim2.fromOffset(TOPBAR_BTN_SIZE, TOPBAR_BTN_SIZE),
        Position = UDim2.new(1, xOffset, 0.5, -TOPBAR_BTN_SIZE / 2),
        BackgroundColor3 = Theme.PanelAlt,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 2,
    }, TopBar)
    corner(Btn, 6)

    local IconHolder = new("Frame", {
        Name = "Icon",
        AnchorPoint = ANCHOR_CENTER,
        Position = CENTER,
        Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE),
        BackgroundTransparency = 1,
        ZIndex = 3,
    }, Btn)

    drawIcon(IconHolder, kind, iconColor, Theme.PanelAlt)
    return Btn, IconHolder
end

local CloseBtn                     = createTopbarButton("close", 1, Theme.Danger)
local MaximizeBtn, MaximizeIcon    = createTopbarButton("maximize", 2)
local MinimizeBtn                  = createTopbarButton("minimize", 3)
local ResizeBtn, ResizeIcon        = createTopbarButton("resize", 4)
local ResetBtn                     = createTopbarButton("reset", 5)

--// ---- Body ----
local Body = new("Frame", {
    Name = "Body",
    Size = UDim2.new(1, 0, 1, -TOPBAR_HEIGHT),
    Position = UDim2.fromOffset(0, TOPBAR_HEIGHT),
    BackgroundTransparency = 1,
}, MainUI)

local FunctionPanel = new("Frame", {
    Name = "FunctionPanel",
    Position = UDim2.fromOffset(MARGIN_EDGE + TAB_PANEL_WIDTH + MARGIN_GAP, MARGIN_EDGE),
    Size = UDim2.new(1, -(MARGIN_EDGE + TAB_PANEL_WIDTH + MARGIN_GAP + MARGIN_EDGE), 1, -(MARGIN_EDGE * 2)),
    BackgroundColor3 = Theme.PanelAlt,
    BorderSizePixel = 0,
}, Body)
corner(FunctionPanel, 8)
stroke(FunctionPanel)

local FunctionScroll = new("ScrollingFrame", {
    Name = "FunctionScroll",
    Size = UDim2.new(1, -8, 1, -8),
    Position = UDim2.fromOffset(4, 4),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 5,
    ScrollBarImageColor3 = Theme.AccentPink,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, FunctionPanel)
list(FunctionScroll, 10)
padding(FunctionScroll, 4, 4)

local TabColumn = new("Frame", {
    Name = "TabColumn",
    Position = UDim2.fromOffset(MARGIN_EDGE, MARGIN_EDGE),
    Size = UDim2.new(0, TAB_PANEL_WIDTH, 1, -(MARGIN_EDGE * 2)),
    BackgroundTransparency = 1,
}, Body)

local TabPanel = new("Frame", {
    Name = "TabPanel",
    Size = UDim2.new(1, 0, 1, -(HIGHLIGHT_HEIGHT + HIGHLIGHT_GAP)),
    BackgroundColor3 = Theme.PanelAlt,
    BorderSizePixel = 0,
}, TabColumn)
corner(TabPanel, 8)
stroke(TabPanel)

local TabScroll = new("ScrollingFrame", {
    Name = "TabScroll",
    Size = UDim2.new(1, -8, 1, -8),
    Position = UDim2.fromOffset(4, 4),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Theme.AccentPink,
    CanvasSize = UDim2.new(),
}, TabPanel)
padding(TabScroll, 3, 3, 3, 3)

--// ---- Highlight tab (player info) ----
local HighlightTab = new("Frame", {
    Name = "HighlightTab",
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.fromScale(0, 1),
    Size = UDim2.new(1, 0, 0, HIGHLIGHT_HEIGHT),
    BackgroundColor3 = Theme.Header,
    BorderSizePixel = 0,
}, TabColumn)
corner(HighlightTab, 8)

do
    local HighlightStroke = stroke(HighlightTab, Theme.AccentPurple, 2)
    local Gradient = new("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 1),
            NumberSequenceKeypoint.new(0.04, 0),
            NumberSequenceKeypoint.new(0.14, 0),
            NumberSequenceKeypoint.new(0.20, 1),
            NumberSequenceKeypoint.new(0.50, 1),
            NumberSequenceKeypoint.new(0.54, 0),
            NumberSequenceKeypoint.new(0.64, 0),
            NumberSequenceKeypoint.new(0.70, 1),
            NumberSequenceKeypoint.new(1.00, 1),
        }),
    }, HighlightStroke)
    TweenService:Create(Gradient, TweenInfo.new(2, EASE_LINEAR, DIR_IN, -1), { Rotation = 360 }):Play()

    local Avatar = new("ImageLabel", {
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.new(0, 8, 0.5, -16),
        BackgroundColor3 = Theme.Panel,
        ScaleType = Enum.ScaleType.Crop,
        ZIndex = 2,
    }, HighlightTab)
    corner(Avatar, 16)
    stroke(Avatar)

    local TextHolder = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 48, 0.5, 0),
        Size = UDim2.new(1, -56, 0, 32),
        BackgroundTransparency = 1,
        ZIndex = 2,
    }, HighlightTab)
    list(TextHolder, 0, { VerticalAlignment = Enum.VerticalAlignment.Center })

    label(TextHolder, {
        LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Text = LocalPlayer.DisplayName,
        TextSize = 13,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 2,
    })
    label(TextHolder, {
        LayoutOrder = 2,
        Size = UDim2.new(1, 0, 0, 14),
        Text = "@" .. LocalPlayer.Name,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 2,
    })

    task.spawn(function()
        local ok, content = pcall(Players.GetUserThumbnailAsync, Players,
            LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        if ok and content then Avatar.Image = content end
    end)
end

--// ================= DRAG SUPPORT =================
local isMaximized = false

local function commitUIState()
    if isMaximized then return end
    local p = MainUI.Position
    uiPosition = UDim2.new(0.5, p.X.Offset, 0.5, p.Y.Offset)
    curW, curH = MainUI.Size.X.Offset, MainUI.Size.Y.Offset
    saveSettings()
end

makeDraggable(TopBar, MainUI, commitUIState)

local InteractionBlocker = new("Frame", {
    Name = "InteractionBlocker",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Active = true,
    Visible = false,
    ZIndex = 20,
}, MainUI)

--// ================= DIALOGS =================
local DIALOG_SIZE     = UDim2.fromOffset(300, 140)
local BUBBLE_IN_TIME  = 0.3
local FADE_IN_TIME    = BUBBLE_IN_TIME * 2
local BUBBLE_OUT_TIME = BUBBLE_IN_TIME * 0.7
local FADE_OUT_TIME   = BUBBLE_OUT_TIME / 3

local function createDialog(name, message, yesColor)
    local Box = new("CanvasGroup", {
        Name = name,
        Visible = false,
        AnchorPoint = ANCHOR_CENTER,
        Position = CENTER,
        Size = UDim2.new(),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        ZIndex = 51,
    }, ScreenGui)
    corner(Box, 10)
    stroke(Box)

    corner(new("Frame", {
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = Theme.AccentPink,
        BorderSizePixel = 0,
        ZIndex = 52,
    }, Box), 10)

    label(Box, {
        Size = UDim2.new(1, -24, 0, 60),
        Position = UDim2.fromOffset(12, 18),
        Text = message,
        TextSize = 16,
        TextWrapped = true,
        TextColor3 = Theme.Text,
        ZIndex = 52,
    })

    local function button(text, pos, bg, textColor, outlined)
        local Btn = new("TextButton", {
            Size = UDim2.fromOffset(120, 32),
            Position = pos,
            BackgroundColor3 = bg,
            Text = text,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = textColor,
            AutoButtonColor = false,
            ZIndex = 52,
        }, Box)
        corner(Btn, 8)
        if outlined then stroke(Btn) end
        return Btn
    end

    local Yes = button("Yes", UDim2.new(0, 20, 1, -46), yesColor, Theme.Background)
    local No  = button("No", UDim2.new(1, -140, 1, -46), Theme.PanelAlt, Theme.Text, true)

    local function show()
        InteractionBlocker.Visible = true
        Box.Visible = true
        Box.GroupTransparency = 1
        Box.Size = UDim2.new()
        tween(Box, BUBBLE_IN_TIME, { Size = DIALOG_SIZE }, EASE_QUAD, DIR_OUT)
        tween(Box, FADE_IN_TIME, { GroupTransparency = 0 }, EASE_QUAD, DIR_OUT)
    end

    local function hide()
        local sizeTween = tween(Box, BUBBLE_OUT_TIME, { Size = UDim2.new() }, EASE_QUAD, DIR_IN)
        tween(Box, FADE_OUT_TIME, { GroupTransparency = 1 }, EASE_QUAD, DIR_IN)
        sizeTween.Completed:Connect(function(state)
            if state ~= Enum.PlaybackState.Completed then return end
            Box.Visible = false
            InteractionBlocker.Visible = false
        end)
    end

    No.MouseButton1Click:Connect(hide)
    return { Box = Box, Yes = Yes, show = show, hide = hide }
end

local CloseDialog = createDialog("ConfirmBox", "You want to close this script?", Theme.Danger)
local ResetDialog = createDialog("NotBox2", "Do you want to reset UI?", Theme.AccentPink)

--// ================= OPEN / CLOSE ANIMATION =================
local isOpen = false
local fadeTween

local function fadeMainUI(time, target, dir)
    if fadeTween then fadeTween:Cancel() end
    fadeTween = tween(MainUI, time, { GroupTransparency = target }, EASE_QUAD, dir)
    return fadeTween
end

local function openUI()
    isOpen = true
    MainUI.Visible = true
    fadeMainUI(POPUP_TIME, 0, DIR_OUT)
end

local function closeUI()
    isOpen = false
    if CloseDialog.Box.Visible then CloseDialog.hide() end
    if ResetDialog.Box.Visible then ResetDialog.hide() end
    fadeMainUI(CLOSE_TIME, 1, DIR_IN).Completed:Connect(function(state)
        if state == Enum.PlaybackState.Completed and not isOpen then
            MainUI.Visible = false
        end
    end)
end

makeDraggable(ToggleButton, ToggleButton, saveSettings, function()
    if isOpen then closeUI() else openUI() end
end, 5)

--// ---- Minimize ----
MinimizeBtn.MouseButton1Click:Connect(function()
    if uiLocked then return end
    if isOpen then closeUI() end
end)

--// ---- Maximize / Restore ----
local preMaxSize, preMaxPos

local function toggleMaximize()
    if isMaximized then
        isMaximized = false
        drawIcon(MaximizeIcon, "maximize", Theme.Text, Theme.PanelAlt)
        tween(MainUI, 0.25, { Size = preMaxSize, Position = preMaxPos }, EASE_QUAD, DIR_OUT)
    else
        preMaxSize, preMaxPos = MainUI.Size, MainUI.Position
        isMaximized = true
        drawIcon(MaximizeIcon, "restore", Theme.Text, Theme.PanelAlt)
        local viewport = getViewport()
        tween(MainUI, 0.25, {
            Size = UDim2.fromOffset(viewport.X, viewport.Y),
            Position = CENTER,
        }, EASE_QUAD, DIR_OUT)
    end
end

MaximizeBtn.MouseButton1Click:Connect(function()
    if uiLocked then return end
    toggleMaximize()
end)

--// ---- Close ----
CloseBtn.MouseButton1Click:Connect(function()
    if uiLocked then return end
    CloseDialog.show()
end)
CloseDialog.Yes.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

--// ---- Reset ----
local function resetLayout()
    if isMaximized then
        isMaximized = false
        drawIcon(MaximizeIcon, "maximize", Theme.Text, Theme.PanelAlt)
    end

    curW, curH = UI_W, UI_H
    uiPosition = CENTER

    local props = { Position = uiPosition }
    if isOpen then props.Size = UDim2.fromOffset(curW, curH) end
    tween(MainUI, 0.2, props, EASE_QUAD, DIR_OUT)
    tween(ToggleButton, 0.2, { Position = DEFAULT_TOGGLE_POS }, EASE_QUAD, DIR_OUT)

    saveSettings()
end

ResetBtn.MouseButton1Click:Connect(function()
    if uiLocked then return end
    ResetDialog.show()
end)
ResetDialog.Yes.MouseButton1Click:Connect(function()
    resetLayout()
    ResetDialog.hide()
end)

--// ================= RESIZE MODE =================
local RESIZE_HANDLE_SIZE = 18
local resizeMode = false
local resizeDragCorner
local resizeFixedX, resizeFixedY = 0, 0

local CORNER_ANCHORS = {
    TL = Vector2.new(0, 0),
    TR = Vector2.new(1, 0),
    BL = Vector2.new(0, 1),
    BR = Vector2.new(1, 1),
}
local ResizeHandles = {}

local function updateResizeHandlePositions()
    local pos, size = MainUI.AbsolutePosition, MainUI.AbsoluteSize
    for cornerName, handle in pairs(ResizeHandles) do
        local a = CORNER_ANCHORS[cornerName]
        handle.Position = UDim2.fromOffset(pos.X + size.X * a.X, pos.Y + size.Y * a.Y)
    end
end

for cornerName, anchor in pairs(CORNER_ANCHORS) do
    local Handle = new("Frame", {
        Name = "ResizeHandle",
        AnchorPoint = ANCHOR_CENTER,
        Size = UDim2.fromOffset(RESIZE_HANDLE_SIZE, RESIZE_HANDLE_SIZE),
        BackgroundColor3 = Theme.AccentPink,
        BorderSizePixel = 0,
        Visible = false,
        Active = true,
        ZIndex = 100,
    }, ScreenGui)
    corner(Handle, 6)
    stroke(Handle, Theme.Text, 1.5)
    ResizeHandles[cornerName] = Handle

    local Grip = new("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 101,
    }, Handle)

    Grip.InputBegan:Connect(function(input)
        if not resizeMode or not isPress(input) then return end

        local pos, size = MainUI.AbsolutePosition, MainUI.AbsoluteSize
        resizeFixedX = pos.X + size.X * (1 - anchor.X)
        resizeFixedY = pos.Y + size.Y * (1 - anchor.Y)
        resizeDragCorner = cornerName

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End and resizeDragCorner == cornerName then
                resizeDragCorner = nil
                commitUIState()
            end
        end)
    end)
end

local function onMainUIRectChanged()
    if resizeMode then updateResizeHandlePositions() end
end
MainUI:GetPropertyChangedSignal("AbsolutePosition"):Connect(onMainUIRectChanged)
MainUI:GetPropertyChangedSignal("AbsoluteSize"):Connect(onMainUIRectChanged)

track(UserInputService.InputChanged:Connect(function(input)
    if not resizeMode or not resizeDragCorner or not isMove(input) then return end

    local mouseX, mouseY = input.Position.X, input.Position.Y
    local newW = math.max(MIN_UI_W, math.abs(mouseX - resizeFixedX))
    local newH = math.max(MIN_UI_H, math.abs(mouseY - resizeFixedY))

    local movingX = resizeFixedX + (mouseX >= resizeFixedX and 1 or -1) * newW
    local movingY = resizeFixedY + (mouseY >= resizeFixedY and 1 or -1) * newH
    local viewport = getViewport()

    MainUI.Size = UDim2.fromOffset(newW, newH)
    MainUI.Position = UDim2.new(
        0.5, (resizeFixedX + movingX) / 2 - viewport.X * 0.5,
        0.5, (resizeFixedY + movingY) / 2 - viewport.Y * 0.5
    )
    updateResizeHandlePositions()
end))

local function setResizeMode(enabled)
    resizeMode = enabled
    uiLocked = enabled
    resizeDragCorner = nil
    drawIcon(ResizeIcon, "resize", enabled and Theme.AccentPink or Theme.Text, Theme.PanelAlt)
    tween(MainUIStroke, 0.2, {
        Color = enabled and Theme.AccentPink or Theme.Border,
        Thickness = enabled and 2 or 1,
    })
    for _, h in pairs(ResizeHandles) do h.Visible = enabled end
    if enabled then updateResizeHandlePositions() end
end

ResizeBtn.MouseButton1Click:Connect(function()
    setResizeMode(not resizeMode)
end)

--// ================= TAB SYSTEM =================
local TAB_HEIGHT          = 34
local TAB_GAP             = 6
local TAB_TEXT_PAD        = 14
local TAB_TEXT_PAD_ACTIVE = 18
local TAB_BAR_HEIGHT      = 20

local CONTENT_EDGE     = 2
local CONTENT_FADE_OUT = 0.12
local CONTENT_FADE_IN  = 0.22
local CONTENT_SLIDE    = 10

local TabData = {}
local tabCount = 0
local activeTab
local switchToken = 0
local ContentTweens = {}

local TabPill = new("Frame", {
    Name = "TabPill",
    Size = UDim2.new(1, 0, 0, TAB_HEIGHT),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 1,
}, TabScroll)
corner(TabPill, 6)
new("UIGradient", { Color = ColorSequence.new(Theme.AccentPurple, Theme.AccentPink) }, TabPill)

local PillStroke = stroke(TabPill, Theme.AccentPink, 1)
PillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local PillStrokeGradient = new("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.00, 0.7),
        NumberSequenceKeypoint.new(0.04, 0),
        NumberSequenceKeypoint.new(0.14, 0),
        NumberSequenceKeypoint.new(0.20, 0.7),
        NumberSequenceKeypoint.new(0.50, 0.7),
        NumberSequenceKeypoint.new(0.54, 0),
        NumberSequenceKeypoint.new(0.64, 0),
        NumberSequenceKeypoint.new(0.70, 0.7),
        NumberSequenceKeypoint.new(1.00, 0.7),
    }),
}, PillStroke)
TweenService:Create(PillStrokeGradient, TweenInfo.new(2.5, EASE_LINEAR, DIR_IN, -1), { Rotation = 360 }):Play()

local PillBar = new("Frame", {
    Name = "AccentBar",
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 6, 0.5, 0),
    Size = UDim2.fromOffset(3, TAB_BAR_HEIGHT),
    BackgroundColor3 = Theme.AccentPink,
    BorderSizePixel = 0,
}, TabPill)
corner(PillBar, 2)
local PillBarGlow = stroke(PillBar, Theme.AccentPink, 3)
PillBarGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
PillBarGlow.Transparency = 0.75

local function cancelContentTween(content)
    local t = ContentTweens[content]
    if t then
        t:Cancel()
        ContentTweens[content] = nil
    end
end

local function selectTab(name)
    if activeTab == name then return end
    local previous = activeTab
    activeTab = name
    switchToken += 1
    local token = switchToken

    for tabName, t in pairs(TabData) do
        local selected = tabName == name
        tween(t.btn, 0.2, {
            BackgroundTransparency = 1,
            TextColor3 = selected and Theme.Sakura or Theme.SubText,
        })
        tween(t.pad, 0.25, {
            PaddingLeft = UDim.new(0, selected and TAB_TEXT_PAD_ACTIVE or TAB_TEXT_PAD),
        }, EASE_QUINT, DIR_OUT)
    end

    local target = UDim2.fromOffset(0, TabData[name].index * (TAB_HEIGHT + TAB_GAP))
    if TabPill.Visible then
        tween(TabPill, 0.25, { Position = target }, EASE_QUINT, DIR_OUT)
        tween(PillBar, 0.1, { Size = UDim2.fromOffset(3, 8) }).Completed:Once(function()
            tween(PillBar, 0.25, { Size = UDim2.fromOffset(3, TAB_BAR_HEIGHT) }, EASE_BACK, DIR_OUT)
        end)
    else
        TabPill.Position = target
        TabPill.Visible = true
    end

    for tabName, t in pairs(TabData) do
        if tabName ~= name and tabName ~= previous then
            cancelContentTween(t.content)
            t.content.Visible = false
        end
    end

    local newContent, pad = TabData[name].content, TabData[name].contentPad

    local function fadeIn()
        if token ~= switchToken then return end
        cancelContentTween(newContent)

        if not newContent.Visible then
            newContent.GroupTransparency = 1
            pad.PaddingTop = UDim.new(0, CONTENT_EDGE + CONTENT_SLIDE)
            newContent.Visible = true
        end

        ContentTweens[newContent] = tween(newContent, CONTENT_FADE_IN, { GroupTransparency = 0 }, EASE_QUAD, DIR_OUT)
        tween(pad, CONTENT_FADE_IN, { PaddingTop = UDim.new(0, CONTENT_EDGE) }, EASE_QUINT, DIR_OUT)
    end

    local oldContent = previous and TabData[previous].content
    if oldContent and oldContent.Visible then
        cancelContentTween(oldContent)
        local fade = tween(oldContent, CONTENT_FADE_OUT, { GroupTransparency = 1 }, EASE_QUAD, DIR_IN)
        ContentTweens[oldContent] = fade
        fade.Completed:Connect(function(state)
            if state ~= Enum.PlaybackState.Completed then return end
            oldContent.Visible = false
            ContentTweens[oldContent] = nil
            fadeIn()
        end)
    else
        fadeIn()
    end
end

local function CreateTab(name)
    tabCount += 1
    local index = tabCount - 1
    TabScroll.CanvasSize = UDim2.fromOffset(0, tabCount * (TAB_HEIGHT + TAB_GAP) - TAB_GAP + 6)

    local Btn = new("TextButton", {
        Name = "Tab_" .. name,
        AnchorPoint = ANCHOR_CENTER,
        Position = UDim2.new(0.5, 0, 0, index * (TAB_HEIGHT + TAB_GAP) + TAB_HEIGHT / 2),
        Size = UDim2.new(1, 0, 0, TAB_HEIGHT),
        BackgroundColor3 = Theme.Header,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = name,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        TextWrapped = true,
        ZIndex = 2,
    }, TabScroll)
    corner(Btn, 6)
    local Pad = padding(Btn, TAB_TEXT_PAD, 8)
    pressScale(Btn, 0.97)

    Btn.MouseEnter:Connect(function()
        if uiLocked or activeTab == name then return end
        tween(Btn, 0.15, { BackgroundTransparency = 0.5, TextColor3 = Theme.Text })
        tween(Pad, 0.15, { PaddingLeft = UDim.new(0, TAB_TEXT_PAD + 2) })
    end)
    Btn.MouseLeave:Connect(function()
        if activeTab == name then return end
        tween(Btn, 0.15, { BackgroundTransparency = 1, TextColor3 = Theme.SubText })
        tween(Pad, 0.15, { PaddingLeft = UDim.new(0, TAB_TEXT_PAD) })
    end)
    Btn.MouseButton1Click:Connect(function()
        if uiLocked then return end
        selectTab(name)
    end)

    local Content = new("CanvasGroup", {
        Name = "TabContent_" .. name,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Visible = false,
    }, FunctionScroll)
    local ContentPad = padding(Content, CONTENT_EDGE, CONTENT_EDGE, CONTENT_EDGE, CONTENT_EDGE)
    list(Content, 10)

    TabData[name] = { index = index, btn = Btn, pad = Pad, content = Content, contentPad = ContentPad }

    if tabCount == 1 then selectTab(name) end
    return Content
end

--// ================= FUNCTION ELEMENT BUILDERS =================
local function CreateToggleOption(parent, title, height)
    local Frame = new("Frame", {
        Size = UDim2.new(1, 0, 0, height or 50),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    }, parent)
    corner(Frame, 8)
    stroke(Frame)

    label(Frame, {
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.fromOffset(14, 0),
        Text = title,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Theme.Text,
    })

    local pxW, pxH, rightOffset = 46, 24, 12
    local Switch = new("TextButton", {
        Size = UDim2.fromOffset(pxW, pxH),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -rightOffset, 0.5, 0),
        BackgroundColor3 = Theme.ToggleTrackOff,
        Text = "",
        AutoButtonColor = false,
    }, Frame)
    corner(Switch, 12)

    local SwitchGradient = new("UIGradient", {
        Color = ColorSequence.new(Theme.AccentPurple, Theme.AccentPink),
        Enabled = false,
    }, Switch)

    local Knob = new("Frame", {
        Size = UDim2.fromOffset(pxH - 4, pxH - 4),
        Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = Theme.Text,
        BorderSizePixel = 0,
    }, Switch)
    corner(Knob, 10)

    local state = false
    Switch:SetAttribute("Toggled", false)

    local function setState(value)
        value = value and true or false
        if state == value then return end
        state = value
        Switch:SetAttribute("Toggled", state)

        SwitchGradient.Enabled = state
        tween(Switch, 0.18, { BackgroundColor3 = state and Theme.AccentPink or Theme.ToggleTrackOff })
        tween(Knob, 0.18, {
            Position = state and UDim2.new(1, -(pxH - 2), 0, 2) or UDim2.fromOffset(2, 2),
            BackgroundColor3 = state and Theme.ToggleKnobOn or Theme.Text,
        })
    end

    Switch.MouseButton1Click:Connect(function()
        if uiLocked then return end
        setState(not state)
    end)

    return Switch, setState
end

local function CreateSectionLabel(parent, text)
    return label(parent, {
        Size = UDim2.new(1, 0, 0, 24),
        Text = text,
        TextSize = 13,
        TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
end

local function CreateCard(parent, name, padV, padL, padR)
    local Card = new("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    }, parent)
    corner(Card, 8)
    stroke(Card)
    padding(Card, padL, padR, padV, padV)
    list(Card, 8)
    return Card
end

local function CreateStyledButton(parent, btnText, width)
    local Btn = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(width or 70, 28),
        BackgroundColor3 = Theme.Header,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = btnText,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Theme.Text,
    }, parent)
    corner(Btn, 6)
    stroke(Btn)
    pressScale(Btn, 0.95)

    Btn.MouseEnter:Connect(function()
        if uiLocked then return end
        tween(Btn, 0.15, { BackgroundColor3 = Theme.Border })
    end)
    Btn.MouseLeave:Connect(function()
        tween(Btn, 0.15, { BackgroundColor3 = Theme.Header })
    end)

    return Btn
end

local function flashButtonFeedback(Btn, defaultText, feedbackText, isError, holdTime)
    Btn.Text = feedbackText
    Btn.TextColor3 = isError and Theme.Danger or Theme.Sakura
    task.delay(holdTime or 1.2, function()
        Btn.Text = defaultText
        Btn.TextColor3 = Theme.Text
    end)
end

local function CreateInfoRow(parent, title, height)
    local Frame = new("Frame", {
        Size = UDim2.new(1, 0, 0, height or 50),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, parent)
    corner(Frame, 8)
    stroke(Frame)
    padding(Frame, 14, 12)

    local Left = new("Frame", {
        Name = "Left",
        Size = UDim2.new(1, -90, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, Frame)
    list(Left, 8, {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

    label(Left, {
        Name = "Title",
        LayoutOrder = 1,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = title,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Theme.Text,
    })

    return Frame, Left
end

local function bindBoxFocus(Box, BoxStroke, onFocus, onLost)
    Box.Focused:Connect(function()
        if uiLocked then Box:ReleaseFocus() return end
        tween(BoxStroke, 0.15, { Color = Theme.AccentPurple })
        if onFocus then onFocus() end
    end)
    Box.FocusLost:Connect(function()
        tween(BoxStroke, 0.15, { Color = Theme.Border })
        if onLost then onLost() end
    end)
end

local function flashStrokeError(BoxStroke)
    BoxStroke.Color = Theme.Danger
    tween(BoxStroke, 0.6, { Color = Theme.Border })
end

local function guarded(fn)
    local busy = false
    return function()
        if uiLocked or busy then return end
        busy = true
        fn(function()
            task.delay(1.2, function() busy = false end)
        end)
    end
end

--// ================= TABS =================
local StatusServerTab = CreateTab("Status & Server")
local LocalTab        = CreateTab("Local")
local FPSTab          = CreateTab("FPS")
local ScriptTab       = CreateTab("Script")
local SettingsTab     = CreateTab("Settings")

--// ================= STATUS & SERVER TAB =================
local ScriptStartClock = os.clock()

local function formatTime(seconds)
    if type(seconds) ~= "number" then return "--" end
    seconds = math.max(0, math.floor(seconds))
    return string.format("%dh%dm%ds", seconds // 3600, seconds % 3600 // 60, seconds % 60)
end

local function copyToClipboard(text)
    local fn = setclipboard or toclipboard or set_clipboard
        or (Clipboard and Clipboard.set)
        or (syn and syn.write_clipboard)
    if not fn then return false end
    return (pcall(fn, text))
end

local function joinServer(jobId)
    if not jobId or jobId == "" or jobId == game.JobId then return false end
    return (pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, jobId, LocalPlayer))
end

local function CreateTimerRow(parent, title, getSeconds)
    local Frame = CreateInfoRow(parent, title)

    local Value = label(Frame, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(110, 24),
        Text = formatTime(getSeconds()),
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = Theme.AccentPink,
    })

    task.spawn(function()
        while ScreenGui.Parent do
            local ok, secs = pcall(getSeconds)
            if ok then
                local txt = formatTime(secs)
                if Value.Text ~= txt then Value.Text = txt end
            end
            task.wait(0.25)
        end
    end)

    return Frame
end

local function CreateCopyRow(parent, title, text, valueLabel)
    local Frame, Left = CreateInfoRow(parent, title)

    if valueLabel then
        label(Left, {
            LayoutOrder = 2,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = text,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Theme.AccentPink,
        })
    end

    local Btn = CreateStyledButton(Frame, "Copy", 70)
    Btn.Activated:Connect(guarded(function(done)
        local ok = copyToClipboard(text)
        flashButtonFeedback(Btn, "Copy", ok and "Copied!" or "Failed", not ok)
        done()
    end))
    return Frame
end

CreateTimerRow(StatusServerTab, "Timer", function()
    return os.clock() - ScriptStartClock
end)

-- time() = số giây kể từ khi client vào server này (reset khi teleport sang server khác)
CreateTimerRow(StatusServerTab, "Time Played", function()
    return time()
end)

CreateCopyRow(StatusServerTab, "PlaceID", tostring(game.PlaceId), true)

do
    local SPAM_JOIN_DELAY = 0.25

    local Card = CreateCard(StatusServerTab, "ServerHoper", 12, 14, 12)

    label(Card, {
        LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Text = "Server Hoper",
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Theme.Text,
    })

    local Box = new("TextBox", {
        LayoutOrder = 2,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.PanelAlt,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = "",
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClipsDescendants = true,
    }, Card)
    corner(Box, 6)
    local BoxStroke = stroke(Box)
    padding(Box, 10, 10)

    local Placeholder = label(Box, {
        Size = UDim2.fromScale(1, 1),
        Text = "Paste your JobId here",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Theme.SubText,
        TextTransparency = 0.5,
    })

    local function refreshPlaceholder()
        Placeholder.Visible = Box.Text == "" and not Box:IsFocused()
    end

    bindBoxFocus(Box, BoxStroke, refreshPlaceholder, function()
        Box.Text = (Box.Text:gsub("^%s+", ""):gsub("%s+$", ""))
        refreshPlaceholder()
    end)
    Box:GetPropertyChangedSignal("Text"):Connect(refreshPlaceholder)

    local function getJobId()
        return (Box.Text:gsub("[%s\"']", ""))
    end

    local JoinFrame = CreateInfoRow(Card, "Join JobId", 40)
    JoinFrame.LayoutOrder = 3
    JoinFrame.BackgroundColor3 = Theme.PanelAlt

    local JoinBtn = CreateStyledButton(JoinFrame, "Join", 70)
    local joinBusy = false
    JoinBtn.Activated:Connect(function()
        if uiLocked or joinBusy then return end
        local jobId = getJobId()
        if jobId == "" or jobId == game.JobId then
            flashStrokeError(BoxStroke)
            flashButtonFeedback(JoinBtn, "Join", jobId == "" and "Empty" or "Same", true, 0.8)
            return
        end
        joinBusy = true
        local ok = joinServer(jobId)
        flashButtonFeedback(JoinBtn, "Join", ok and "Joining..." or "Failed", not ok)
        task.delay(1.2, function() joinBusy = false end)
    end)

    local Switch = CreateToggleOption(Card, "Spam Join", 40)
    Switch.Parent.LayoutOrder = 4
    Switch.Parent.BackgroundColor3 = Theme.PanelAlt

    local runId = 0
    Switch:GetAttributeChangedSignal("Toggled"):Connect(function()
        runId += 1
        if not Switch:GetAttribute("Toggled") then return end

        if getJobId() == "" then flashStrokeError(BoxStroke) end
        local myRun = runId
        task.spawn(function()
            while Switch:GetAttribute("Toggled") and myRun == runId and ScreenGui.Parent do
                joinServer(getJobId())
                task.wait(SPAM_JOIN_DELAY)
            end
        end)
    end)
end

CreateCopyRow(StatusServerTab, "Copy Server JobId", game.JobId, false)

do
    local Frame = CreateInfoRow(StatusServerTab, "Rejoin Server")
    local RejoinBtn = CreateStyledButton(Frame, "Rejoin", 70)
    RejoinBtn.Activated:Connect(guarded(function(done)
        local ok = pcall(function()
            if game.JobId == "" then
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end
        end)
        flashButtonFeedback(RejoinBtn, "Rejoin", ok and "Rejoining..." or "Failed", not ok)
        done()
    end))
end

do
    local function httpRequest(url)
        local fn = (syn and syn.request) or http_request or request
            or (http and http.request) or (fluxus and fluxus.request)
        if not fn then return nil, "no http function" end
        local ok, res = pcall(fn, { Url = url, Method = "GET" })
        if not ok then return nil, res end
        if type(res) == "table" and type(res.Body) == "string" then
            return res.Body
        end
        return nil, "bad response"
    end

    local function fetchPublicServers()
        local servers, cursor = {}, ""
        for _ = 1, 5 do
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=2&limit=100"):format(game.PlaceId)
            if cursor ~= "" then url ..= "&cursor=" .. HttpService:UrlEncode(cursor) end

            local body = httpRequest(url)
            if not body then break end

            local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
            if not ok or type(data) ~= "table" or type(data.data) ~= "table" then break end

            for _, srv in ipairs(data.data) do
                table.insert(servers, srv)
            end

            if data.nextPageCursor and data.nextPageCursor ~= "" then
                cursor = data.nextPageCursor
            else
                break
            end
        end
        return servers
    end

    local function pickServerJobId(pickLeast)
        local candidates = {}
        for _, srv in ipairs(fetchPublicServers()) do
            if srv.id and srv.id ~= game.JobId
                and type(srv.playing) == "number" and type(srv.maxPlayers) == "number"
                and srv.playing < srv.maxPlayers then
                table.insert(candidates, srv)
            end
        end
        if #candidates == 0 then return nil end

        if pickLeast then
            table.sort(candidates, function(a, b) return a.playing < b.playing end)
            return candidates[1].id
        end
        return candidates[math.random(1, #candidates)].id
    end

    local function bindHopButton(title, pickLeast)
        local Frame = CreateInfoRow(StatusServerTab, title)
        local Btn = CreateStyledButton(Frame, "Hop", 70)
        Btn.Activated:Connect(guarded(function(done)
            Btn.Text, Btn.TextColor3 = "Finding...", Theme.SubText
            task.spawn(function()
                local ok, jobId = pcall(pickServerJobId, pickLeast)
                if ok and jobId then
                    joinServer(jobId)
                    flashButtonFeedback(Btn, "Hop", "Hopping...", false)
                else
                    flashButtonFeedback(Btn, "Hop", "Failed", true)
                end
                done()
            end)
        end))
    end

    bindHopButton("Server Hop", false)
    bindHopButton("Server Hop With Less People", true)
end

--// ================= LOCAL TAB =================
do
    local LocalCleanups = {}
    ScreenGui.Destroying:Connect(function()
        for _, fn in ipairs(LocalCleanups) do pcall(fn) end
    end)

    local function getHumanoid()
        local c = LocalPlayer.Character
        return c and c:FindFirstChildOfClass("Humanoid")
    end

    local function getRoot()
        local c = LocalPlayer.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end

    local function sanitizeNumber(s)
        s = s:gsub("[^%d%.]", "")
        local dot = s:find(".", 1, true)
        if dot then
            s = s:sub(1, dot) .. (s:sub(dot + 1):gsub("%.", ""))
        end
        return s:sub(1, 7)
    end

    local function readNumber(Box, maxValue)
        local n = tonumber(Box.Text)
        return n and math.clamp(n, 0, maxValue) or nil
    end

    local function BindToggle(Switch, onFn, offFn)
        Switch:GetAttributeChangedSignal("Toggled"):Connect(function()
            if Switch:GetAttribute("Toggled") then onFn() else offFn() end
        end)
        table.insert(LocalCleanups, offFn)
    end

    local function CreateToggleWithBox(parent, title, labelWidth)
        local Switch = CreateToggleOption(parent, title, 50)
        local Frame = Switch.Parent
        Frame:FindFirstChildOfClass("TextLabel").Size = UDim2.new(0, labelWidth, 1, 0)

        local Box = new("TextBox", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 14 + labelWidth + 6, 0.5, 0),
            Size = UDim2.new(1, -(14 + labelWidth + 6 + 70), 0, 30),
            BackgroundColor3 = Theme.PanelAlt,
            BorderSizePixel = 0,
            Text = "",
            PlaceholderText = "Value",
            PlaceholderColor3 = Theme.SubText,
            ClearTextOnFocus = false,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = Theme.Text,
            ClipsDescendants = true,
        }, Frame)
        corner(Box, 6)
        local BoxStroke = stroke(Box)

        new("UISizeConstraint", {
            MinSize = Vector2.new(48, 0),
            MaxSize = Vector2.new(110, math.huge),
        }, Box)

        Box:GetPropertyChangedSignal("Text"):Connect(function()
            local clean = sanitizeNumber(Box.Text)
            if clean ~= Box.Text then Box.Text = clean end
        end)
        bindBoxFocus(Box, BoxStroke)

        return Switch, Box, function() flashStrokeError(BoxStroke) end
    end

    local function CreateHumanoidBoost(title, labelWidth, maxValue, snapshot, apply, restore)
        local Switch, Box, flashError = CreateToggleWithBox(LocalTab, title, labelWidth)
        local conn
        local original = setmetatable({}, { __mode = "k" })

        local function stop()
            if conn then conn:Disconnect() conn = nil end
            for hum, st in pairs(original) do
                if hum.Parent then restore(hum, st) end
                original[hum] = nil
            end
        end

        local function start()
            if conn then return end
            if not readNumber(Box, maxValue) then flashError() end
            conn = RunService.Heartbeat:Connect(function()
                local hum = getHumanoid()
                if not hum then return end
                local v = readNumber(Box, maxValue)
                local st = original[hum]
                if not v then
                    if st then
                        restore(hum, st)
                        original[hum] = nil
                    end
                    return
                end
                if not st then original[hum] = snapshot(hum) end
                apply(hum, v)
            end)
        end

        BindToggle(Switch, start, stop)
    end

    --// ---------------- Speed ----------------
    CreateHumanoidBoost("Speed", 60, 1000,
        function(hum) return hum.WalkSpeed end,
        function(hum, v) if hum.WalkSpeed ~= v then hum.WalkSpeed = v end end,
        function(hum, ws) hum.WalkSpeed = ws end
    )

    --// ---------------- Jump Boost ----------------
    CreateHumanoidBoost("Jump Boost", 96, 1000,
        function(hum)
            return { use = hum.UseJumpPower, power = hum.JumpPower, height = hum.JumpHeight }
        end,
        function(hum, v)
            if not hum.UseJumpPower then hum.UseJumpPower = true end
            if hum.JumpPower ~= v then hum.JumpPower = v end
        end,
        function(hum, st)
            hum.JumpPower = st.power
            hum.JumpHeight = st.height
            hum.UseJumpPower = st.use
        end
    )

    --// ---------------- Infinite Jump ----------------
    do
        local Switch = CreateToggleOption(LocalTab, "Infinite Jump", 50)
        local conn

        local function stop()
            if conn then conn:Disconnect() conn = nil end
        end

        local function start()
            if conn then return end
            conn = UserInputService.JumpRequest:Connect(function()
                local hum = getHumanoid()
                if hum and hum.Health > 0 then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end

        BindToggle(Switch, start, stop)
    end

    --// ---------------- Noclip ----------------
    do
        local Switch = CreateToggleOption(LocalTab, "Noclip", 50)
        local conn
        local changed = setmetatable({}, { __mode = "k" })

        local function stop()
            if conn then conn:Disconnect() conn = nil end
            for part in pairs(changed) do
                if part.Parent then part.CanCollide = true end
                changed[part] = nil
            end
        end

        local function start()
            if conn then return end
            conn = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if not char then return end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        changed[part] = true
                        part.CanCollide = false
                    end
                end
            end)
        end

        BindToggle(Switch, start, stop)
    end

    --// ---------------- Fly ----------------
    do
        local FLY_DEFAULT_SPEED = 60
        local FLY_MAX_SPEED = 1000
        local Switch, SpeedBox = CreateToggleWithBox(LocalTab, "Fly", 40)
        SpeedBox.PlaceholderText = tostring(FLY_DEFAULT_SPEED)
        local conn, jumpConn, bv, bg
        local controls
        local upUntil = 0

        local function resolveControls()
            if controls ~= nil then return end
            controls = false
            pcall(function()
                local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
                local pm = scripts and scripts:FindFirstChild("PlayerModule")
                if pm then controls = require(pm:WaitForChild("ControlModule", 2)) end
            end)
        end

        local function getMoveVector(typing)
            if controls then
                local ok, v = pcall(function() return controls:GetMoveVector() end)
                if ok and typeof(v) == "Vector3" then return v end
            end
            local x, z = 0, 0
            if not typing then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then z -= 1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then z += 1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then x -= 1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then x += 1 end
            end
            return Vector3.new(x, 0, z)
        end

        local function stop()
            if conn then conn:Disconnect() conn = nil end
            if jumpConn then jumpConn:Disconnect() jumpConn = nil end
            if bv then bv:Destroy() bv = nil end
            if bg then bg:Destroy() bg = nil end
            local hum = getHumanoid()
            if hum then hum.PlatformStand = false end
        end

        local function start()
            if conn then return end
            resolveControls()

            jumpConn = UserInputService.JumpRequest:Connect(function()
                upUntil = os.clock() + 0.25
            end)

            conn = RunService.RenderStepped:Connect(function()
                local root, hum, cam = getRoot(), getHumanoid(), Workspace.CurrentCamera
                if not root or not hum or not cam or hum.Health <= 0 then return end

                if not bv or bv.Parent ~= root then
                    if bv then bv:Destroy() end
                    bv = new("BodyVelocity", { MaxForce = Vector3.one * 1e9, Velocity = Vector3.zero }, root)
                end
                if not bg or bg.Parent ~= root then
                    if bg then bg:Destroy() end
                    bg = new("BodyGyro", { MaxTorque = Vector3.one * 1e9, P = 9e4, D = 1e3 }, root)
                end
                hum.PlatformStand = true

                local typing = UserInputService:GetFocusedTextBox() ~= nil
                local cf = cam.CFrame
                local move = getMoveVector(typing)
                local dir = cf.RightVector * move.X - cf.LookVector * move.Z

                if not typing then
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                        or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                        dir -= Vector3.yAxis
                    end
                end
                if os.clock() < upUntil then dir += Vector3.yAxis end
                if dir.Magnitude > 1 then dir = dir.Unit end

                local speed = readNumber(SpeedBox, FLY_MAX_SPEED) or FLY_DEFAULT_SPEED
                bv.Velocity = dir * speed

                local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
                if look.Magnitude > 0.001 then
                    bg.CFrame = CFrame.lookAt(root.Position, root.Position + look)
                end
            end)
        end

        BindToggle(Switch, start, stop)
    end

    --// ---------------- Esp Player (+ Esp Team Player) ----------------
    do
        local WHITE = Color3.fromRGB(255, 255, 255)
        local GREEN = Color3.fromRGB(60, 255, 90)
        local RED   = Color3.fromRGB(255, 60, 60)

        local Card = CreateCard(LocalTab, "EspPlayer", 10, 10, 10)

        local Switch = CreateToggleOption(Card, "Esp Player", 40)
        Switch.Parent.LayoutOrder = 1
        Switch.Parent.BackgroundColor3 = Theme.PanelAlt

        local Holder = new("Frame", {
            LayoutOrder = 2,
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundTransparency = 1,
        }, Card)
        padding(Holder, 18)

        local TeamSwitch = CreateToggleOption(Holder, "Esp Team Player", 40)
        TeamSwitch.Parent.BackgroundColor3 = Theme.PanelAlt

        local teamMode = false
        TeamSwitch:GetAttributeChangedSignal("Toggled"):Connect(function()
            teamMode = TeamSwitch:GetAttribute("Toggled")
        end)

        local entries = {}
        local folder, conn, removingConn

        local function destroyEntry(p)
            local e = entries[p]
            if not e then return end
            e.hl:Destroy()
            e.bb:Destroy()
            entries[p] = nil
        end

        local function makeLine(parent, order)
            return new("TextLabel", {
                LayoutOrder = order,
                Size = UDim2.new(1, 0, 0, 16),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = WHITE,
                TextStrokeColor3 = Color3.new(0, 0, 0),
                TextStrokeTransparency = 0.25,
                Text = "",
            }, parent)
        end

        local function buildEntry(p, char)
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if not hum or not root then return nil end

            local hl = new("Highlight", {
                Name = "ESP_" .. p.Name,
                Adornee = char,
                DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                FillTransparency = 1,
                OutlineTransparency = 0,
                OutlineColor = WHITE,
            }, folder)

            local bb = new("BillboardGui", {
                Name = "ESPInfo_" .. p.Name,
                Adornee = char:FindFirstChild("Head") or root,
                AlwaysOnTop = true,
                LightInfluence = 0,
                Size = UDim2.fromOffset(170, 48),
                StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0),
            }, folder)
            list(bb, 0, { VerticalAlignment = Enum.VerticalAlignment.Bottom })

            local nameLine = makeLine(bb, 1)
            local distLine = makeLine(bb, 2)
            local hpLine   = makeLine(bb, 3)

            nameLine.Text = p.DisplayName ~= p.Name
                and (p.DisplayName .. " (@" .. p.Name .. ")")
                or p.DisplayName

            local e = {
                char = char, hum = hum, root = root, hl = hl, bb = bb,
                nameLine = nameLine, distLine = distLine, hpLine = hpLine,
                color = WHITE, dist = nil, hp = nil,
            }
            entries[p] = e
            return e
        end

        local function update()
            local cam = Workspace.CurrentCamera
            local myRoot = getRoot()
            local origin = myRoot and myRoot.Position or (cam and cam.CFrame.Position) or Vector3.zero

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    local char = p.Character
                    local e = entries[p]
                    if e and e.char ~= char then destroyEntry(p) e = nil end
                    if char and not e then e = buildEntry(p, char) end

                    if e then
                        local alive = e.root.Parent ~= nil and e.hum.Health > 0
                        e.hl.Enabled = alive
                        e.bb.Enabled = alive

                        if alive then
                            local color = WHITE
                            if teamMode then
                                local same = LocalPlayer.Team ~= nil and p.Team == LocalPlayer.Team
                                color = same and GREEN or RED
                            end
                            if e.color ~= color then
                                e.color = color
                                e.hl.OutlineColor = color
                                e.nameLine.TextColor3 = color
                                e.distLine.TextColor3 = color
                            end

                            local d = math.floor((e.root.Position - origin).Magnitude + 0.5)
                            if e.dist ~= d then
                                e.dist = d
                                e.distLine.Text = d .. "m"
                            end

                            local hp = math.floor(e.hum.Health + 0.5)
                            local maxHp = math.max(1, math.floor(e.hum.MaxHealth + 0.5))
                            local key = hp * 100000 + maxHp
                            if e.hp ~= key then
                                e.hp = key
                                e.hpLine.Text = string.format("HP: %d/%d", hp, maxHp)
                                e.hpLine.TextColor3 = RED:Lerp(GREEN, math.clamp(hp / maxHp, 0, 1))
                            end
                        end
                    end
                end
            end
        end

        local function stop()
            if conn then conn:Disconnect() conn = nil end
            if removingConn then removingConn:Disconnect() removingConn = nil end
            for p in pairs(entries) do destroyEntry(p) end
            if folder then folder:Destroy() folder = nil end
        end

        local function start()
            if conn then return end
            folder = new("Folder", { Name = "ElyseraESP" }, CoreGui)
            removingConn = Players.PlayerRemoving:Connect(destroyEntry)
            conn = RunService.RenderStepped:Connect(update)
        end

        BindToggle(Switch, start, stop)
    end
end

--// ================= FPS TAB =================
do
    local RunService        = game:GetService("RunService")
    local Lighting          = game:GetService("Lighting")
    local StarterGui        = game:GetService("StarterGui")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local function setProp(inst, prop, value)
        pcall(function() inst[prop] = value end)
    end

    --// ---------- White Screen / Black Screen ----------
    local Cover = Instance.new("ScreenGui")
    Cover.Name = "ElyseraCover"
    Cover.DisplayOrder = 5
    Cover.IgnoreGuiInset = true
    Cover.ResetOnSpawn = false
    Cover.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Cover.Enabled = false
    Cover.Parent = CoreGui

    local CoverFrame = Instance.new("Frame", Cover)
    CoverFrame.Size = UDim2.new(1, 0, 1, 0)
    CoverFrame.BorderSizePixel = 0
    CoverFrame.BackgroundColor3 = Color3.new(0, 0, 0)

    local function set3D(enabled)
        pcall(function() RunService:Set3dRenderingEnabled(enabled) end)
    end

    local WhiteSwitch, setWhite = CreateToggleOption(FPSTab, "White Screen")
    WhiteSwitch.Parent.LayoutOrder = 1
    local BlackSwitch, setBlack = CreateToggleOption(FPSTab, "Black Screen")
    BlackSwitch.Parent.LayoutOrder = 2

    local function refreshScreen()
        local white = WhiteSwitch:GetAttribute("Toggled")
        local black = BlackSwitch:GetAttribute("Toggled")
        if white or black then
            CoverFrame.BackgroundColor3 = white and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
            Cover.Enabled = true
            set3D(false)
        else
            Cover.Enabled = false
            set3D(true)
        end
    end

    WhiteSwitch:GetAttributeChangedSignal("Toggled"):Connect(function()
        if WhiteSwitch:GetAttribute("Toggled") then setBlack(false) end
        refreshScreen()
    end)
    BlackSwitch:GetAttributeChangedSignal("Toggled"):Connect(function()
        if BlackSwitch:GetAttribute("Toggled") then setWhite(false) end
        refreshScreen()
    end)

    --// ---------- Remove Notification ----------
    local NOTIF_KEYWORDS = { "notif", "notice", "announce", "toast", "alert" }

    local function isNotifName(name)
        name = string.lower(name)
        for _, kw in ipairs(NOTIF_KEYWORDS) do
            if string.find(name, kw, 1, true) then return true end
        end
        return false
    end

    local NotifSwitch = CreateToggleOption(FPSTab, "Remove Notification")
    NotifSwitch.Parent.LayoutOrder = 3

    local notifOn      = false
    local notifRun     = 0
    local notifConns   = {}
    local hiddenGuis   = {}
    local mutedRemotes = {}
    local notifRemotes = {}
    local hooked       = false

    local function installSetCoreHook()
        if hooked then return end
        hooked = true

        local function isBlocked(self, name)
            return notifOn
                and name == "SendNotification"
                and not checkcaller()
                and typeof(self) == "Instance"
                and self.ClassName == "StarterGui"
        end

        if hookmetamethod and getnamecallmethod and newcclosure and checkcaller then
            pcall(function()
                local old
                old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                    if notifOn and getnamecallmethod() == "SetCore" and isBlocked(self, (...)) then
                        return
                    end
                    return old(self, ...)
                end))
            end)
        end

        if hookfunction and newcclosure and checkcaller then
            pcall(function()
                local old
                old = hookfunction(StarterGui.SetCore, newcclosure(function(self, name, ...)
                    if isBlocked(self, name) then return end
                    return old(self, name, ...)
                end))
            end)
        end
    end

    local function hideGui(inst)
        if hiddenGuis[inst] ~= nil then return end
        local prop
        if inst:IsA("ScreenGui") then
            prop = "Enabled"
        elseif inst:IsA("GuiObject") then
            prop = "Visible"
        else
            return
        end
        hiddenGuis[inst] = { prop = prop, value = inst[prop] }
        setProp(inst, prop, false)
        table.insert(notifConns, inst:GetPropertyChangedSignal(prop):Connect(function()
            if notifOn and inst[prop] then setProp(inst, prop, false) end
        end))
    end

    local function scanGui(inst)
        if (inst:IsA("GuiObject") or inst:IsA("ScreenGui")) and isNotifName(inst.Name) then
            hideGui(inst)
        end
    end

    local function removeLegacyMessage(inst)
        if inst:IsA("Message") then
            pcall(function() inst:Destroy() end)
        end
    end

    local function muteRemote(inst)
        if not getconnections then return end
        if not (inst:IsA("RemoteEvent") or inst:IsA("UnreliableRemoteEvent")) then return end
        if not isNotifName(inst.Name) then return end
        notifRemotes[inst] = true
        local ok, conns = pcall(getconnections, inst.OnClientEvent)
        if not ok or type(conns) ~= "table" then return end
        for _, c in ipairs(conns) do
            if not mutedRemotes[c] then
                mutedRemotes[c] = true
                pcall(function() c:Disable() end)
            end
        end
    end

    local function enableNotifBlock(myRun)
        installSetCoreHook()

        pcall(function()
            local rg = CoreGui:FindFirstChild("RobloxGui")
            local nf = rg and rg:FindFirstChild("NotificationFrame")
            if nf then hideGui(nf) end
        end)

        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            for _, d in ipairs(pg:GetDescendants()) do
                scanGui(d)
                removeLegacyMessage(d)
            end
            table.insert(notifConns, pg.DescendantAdded:Connect(function(d)
                if not notifOn then return end
                task.defer(function()
                    scanGui(d)
                    removeLegacyMessage(d)
                end)
            end))
        end

        for _, d in ipairs(workspace:GetChildren()) do
            removeLegacyMessage(d)
        end
        table.insert(notifConns, workspace.DescendantAdded:Connect(function(d)
            if notifOn and d:IsA("Message") then
                task.defer(removeLegacyMessage, d)
            end
        end))

        for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
            muteRemote(d)
        end
        table.insert(notifConns, ReplicatedStorage.DescendantAdded:Connect(function(d)
            if not notifOn then return end
            muteRemote(d)
            task.delay(1, muteRemote, d)
        end))

        task.spawn(function()
            while notifOn and myRun == notifRun and ScreenGui.Parent do
                for r in pairs(notifRemotes) do muteRemote(r) end
                task.wait(2)
            end
        end)
    end

    local function disableNotifBlock()
        for _, c in ipairs(notifConns) do c:Disconnect() end
        table.clear(notifConns)

        for inst, info in pairs(hiddenGuis) do
            setProp(inst, info.prop, info.value)
        end
        table.clear(hiddenGuis)

        for c in pairs(mutedRemotes) do
            pcall(function() c:Enable() end)
        end
        table.clear(mutedRemotes)
        table.clear(notifRemotes)
    end

    NotifSwitch:GetAttributeChangedSignal("Toggled"):Connect(function()
        notifRun += 1
        notifOn = NotifSwitch:GetAttribute("Toggled")
        if notifOn then
            enableNotifBlock(notifRun)
        else
            disableNotifBlock()
        end
    end)

    --// ---------- Boost Fps ----------
    local DESTROY = {
        Decal = true, Texture = true, SurfaceAppearance = true,
        ParticleEmitter = true, Trail = true, Beam = true,
        Smoke = true, Fire = true, Sparkles = true,
        Explosion = true, Atmosphere = true,
    }
    local DISABLE = {
        PointLight = true, SpotLight = true, SurfaceLight = true,
        BlurEffect = true, BloomEffect = true, ColorCorrectionEffect = true,
        DepthOfFieldEffect = true, SunRaysEffect = true,
        Clouds = true, Highlight = true,
    }

    local function optimize(inst)
        local class = inst.ClassName
        if DESTROY[class] then
            pcall(function() inst:Destroy() end)
        elseif DISABLE[class] then
            setProp(inst, "Enabled", false)
        elseif class == "SpecialMesh" then
            setProp(inst, "TextureId", "")
        elseif class ~= "Terrain" and inst:IsA("BasePart") then
            setProp(inst, "Material", Enum.Material.SmoothPlastic)
            setProp(inst, "Reflectance", 0)
            setProp(inst, "CastShadow", false)
            if class == "MeshPart" then
                setProp(inst, "TextureID", "")
                setProp(inst, "RenderFidelity", Enum.RenderFidelity.Performance)
            end
        end
    end

    local function boostEnvironment()
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)

        setProp(Lighting, "GlobalShadows", false)
        setProp(Lighting, "FogEnd", 9e9)
        setProp(Lighting, "ShadowSoftness", 0)
        setProp(Lighting, "EnvironmentDiffuseScale", 0)
        setProp(Lighting, "EnvironmentSpecularScale", 0)
        if sethiddenproperty then
            pcall(sethiddenproperty, Lighting, "Technology", Enum.Technology.Compatibility)
        end

        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            setProp(terrain, "WaterWaveSize", 0)
            setProp(terrain, "WaterWaveSpeed", 0)
            setProp(terrain, "WaterReflectance", 0)
            if sethiddenproperty then
                pcall(sethiddenproperty, terrain, "Decoration", false)
            end
        end
    end

    local boostConn
    local function runBoost()
        boostEnvironment()

        local count = 0
        local function process(list)
            for _, inst in ipairs(list) do
                optimize(inst)
                count += 1
                if count % 400 == 0 then task.wait() end
            end
        end

        process(Lighting:GetDescendants())
        local cam = workspace.CurrentCamera
        if cam then process(cam:GetDescendants()) end
        process(workspace:GetDescendants())

        if not boostConn then
            boostConn = workspace.DescendantAdded:Connect(function(inst)
                task.defer(optimize, inst)
            end)
        end
    end

    do
        local Frame = CreateInfoRow(FPSTab, "Boost Fps")
        Frame.LayoutOrder = 4
        local BoostBtn = CreateStyledButton(Frame, "Boost", 70)
        local busy = false
        BoostBtn.Activated:Connect(function()
            if uiLocked or busy then return end
            busy = true
            BoostBtn.Text, BoostBtn.TextColor3 = "Working...", Theme.SubText
            task.spawn(function()
                local ok = pcall(runBoost)
                flashButtonFeedback(BoostBtn, "Boost", ok and "Done!" or "Failed", not ok)
                task.delay(1.2, function() busy = false end)
            end)
        end)
    end

    --// ---------- Cleanup ----------
    ScreenGui.Destroying:Connect(function()
        notifOn = false
        set3D(true)
        if boostConn then boostConn:Disconnect() end
        disableNotifBlock()
        Cover:Destroy()
    end)
end

--// ================= EXPOSED API =================
local Elysera = {
    ScreenGui = ScreenGui,
    Theme = Theme,
    Open = openUI,
    Close = closeUI,
    CreateTab = CreateTab,
    CreateToggleOption = CreateToggleOption,
    CreateSectionLabel = CreateSectionLabel,
    SelectTab = selectTab,
}

--// ================= INITIAL STATE =================
openUI()

return Elysera
