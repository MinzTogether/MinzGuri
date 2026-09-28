--// ============================================================
--// UI language: English (US) only
--// ============================================================

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

--// ================= CLEANUP PREVIOUS INSTANCE =================
if CoreGui:FindFirstChild("ElyseraUI") then
    CoreGui.ElyseraUI:Destroy()
end

--// ================= THEME =================
local Theme = {
    Background   = Color3.fromRGB(29, 21, 52),    -- #1D1534 bg-main
    Panel        = Color3.fromRGB(33, 21, 58),    -- #21153A bg-card
    PanelAlt     = Color3.fromRGB(37, 25, 66),    -- #251942 bg-sidebar
    Header       = Color3.fromRGB(49, 32, 75),    -- #31204B bg-card-hover
    Border       = Color3.fromRGB(84, 53, 128),   -- #543580 purple border
    AccentBlue   = Color3.fromRGB(243, 99, 225),  -- #F363E1 pink primary
    AccentPurple = Color3.fromRGB(175, 88, 249),  -- #AF58F9 purple neon
    Text         = Color3.fromRGB(226, 190, 250), -- #E2BEFA text primary
    SubText      = Color3.fromRGB(191, 157, 238), -- #BF9DEE text secondary
    Success      = Color3.fromRGB(158, 206, 106),
    Danger       = Color3.fromRGB(247, 118, 142),
    Neon         = Color3.fromRGB(175, 88, 249),  -- #AF58F9 purple neon
    ToggleOff    = Color3.fromRGB(71, 48, 112),   -- #473070 toggle OFF track
    ToggleKnob   = Color3.fromRGB(226, 190, 250), -- #E2BEFA toggle knob
}

--// ================= CONFIG =================
local UI_NAME        = "Elysera"
local UI_W, UI_H      = 650, 420
local TOGGLE_SIZE     = 50
local POPUP_TIME      = 0.45
local CLOSE_TIME      = 0.30
local TOPBAR_HEIGHT   = 40
local MIN_UI_W, MIN_UI_H = 420, 260
local SAVE_FILE       = "Elysera_Settings.json"
local SAVE_DELAY      = 0.3

--// ---- Layout margins ----
local MARGIN_EDGE     = 8
local MARGIN_GAP      = 10
local TAB_PANEL_WIDTH = 150

local HIGHLIGHT_HEIGHT = 56
local HIGHLIGHT_GAP     = 8

--// When true, every interactive element except the Resize button ignores
--// clicks/drags. Set while resize mode is active.
local uiLocked = false

--// ================= ROOT =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ElyseraUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

--// ================= UTILITY =================
local function corner(inst, radius)
    local c = Instance.new("UICorner", inst)
    c.CornerRadius = UDim.new(0, radius or 8)
    return c
end

local function stroke(inst, color, thickness)
    local s = Instance.new("UIStroke", inst)
    s.Color = color or Theme.Border
    s.Thickness = thickness or 1
    return s
end

local function tween(inst, time, props, style, dir)
    return TweenService:Create(
        inst,
        TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    )
end

local function makeDraggable(handle, target, onEnd)
    local dragging, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if uiLocked then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if dragging and onEnd then onEnd() end
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if uiLocked then dragging = false return end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function makeDraggableButton(handle, target, onClick, threshold, onEnd)
    threshold = threshold or 5
    local dragging, moved, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if uiLocked then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = target.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if dragging and not moved and not uiLocked then
                        onClick()
                    elseif dragging and moved and onEnd then
                        onEnd()
                    end
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if uiLocked then dragging = false return end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if not moved and delta.Magnitude > threshold then
                moved = true
            end
            if moved then
                target.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
end

--// ================= SAVED SETTINGS (position / size) =================
-- Needs an executor with file functions; silently does nothing otherwise.
local canFS = typeof(writefile) == "function"
    and typeof(readfile) == "function"
    and typeof(isfile) == "function"

local function num(v, default)
    return (type(v) == "number" and v == v and math.abs(v) < 1e6) and v or default
end

local function getViewport()
    local camera = workspace.CurrentCamera
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

-- Current (restorable) UI size + position; kept in sync by drag/resize handlers.
local curW = math.clamp(num(Saved.w, UI_W), MIN_UI_W, math.max(MIN_UI_W, viewport0.X))
local curH = math.clamp(num(Saved.h, UI_H), MIN_UI_H, math.max(MIN_UI_H, viewport0.Y))

-- MainUI is center-anchored with scale 0.5, so only the pixel offset is stored.
-- Clamp so the whole window stays on screen (e.g. after a viewport change).
local uiOffX = num(Saved.uiX, 0)
local uiOffY = num(Saved.uiY, 0)
local maxOffX = math.max(0, (viewport0.X - curW) / 2)
local maxOffY = math.max(0, (viewport0.Y - curH) / 2)
uiOffX = math.clamp(uiOffX, -maxOffX, maxOffX)
uiOffY = math.clamp(uiOffY, -maxOffY, maxOffY)
local uiPosition = UDim2.new(0.5, uiOffX, 0.5, uiOffY)

local DEFAULT_TOGGLE_POS = UDim2.new(0, 20, 0.5, -TOGGLE_SIZE / 2)
local togglePosition = DEFAULT_TOGGLE_POS
if type(Saved.toggle) == "table" then
    local xs, xo = num(Saved.toggle[1], 0), num(Saved.toggle[2], 20)
    local ys, yo = num(Saved.toggle[3], 0.5), num(Saved.toggle[4], -TOGGLE_SIZE / 2)
    local absX = viewport0.X * xs + xo
    local absY = viewport0.Y * ys + yo
    xo = xo + (math.clamp(absX, 0, math.max(0, viewport0.X - TOGGLE_SIZE)) - absX)
    yo = yo + (math.clamp(absY, 0, math.max(0, viewport0.Y - TOGGLE_SIZE)) - absY)
    togglePosition = UDim2.new(xs, xo, ys, yo)
end

local ToggleButton -- assigned below
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
        pcall(function()
            writefile(SAVE_FILE, HttpService:JSONEncode(data))
        end)
    end)
end

--// ================= FLOATING TOGGLE BUTTON =================
ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "MG_Toggle"
ToggleButton.Size = UDim2.new(0, TOGGLE_SIZE, 0, TOGGLE_SIZE)
ToggleButton.Position = togglePosition
ToggleButton.BackgroundColor3 = Theme.Panel
ToggleButton.Text = "Z"
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 20
ToggleButton.TextColor3 = Theme.AccentBlue
ToggleButton.AutoButtonColor = false
ToggleButton.Parent = ScreenGui
corner(ToggleButton, 14)
stroke(ToggleButton, Theme.Border)

--// ================= MAIN WINDOW =================
local MainUI = Instance.new("Frame")
MainUI.Name = "MG_Main"
MainUI.AnchorPoint = Vector2.new(0.5, 0.5)
MainUI.Position = uiPosition
MainUI.Size = UDim2.new(0, 0, 0, 0)
MainUI.BackgroundColor3 = Theme.Background
MainUI.BorderSizePixel = 0
MainUI.ClipsDescendants = true
MainUI.Visible = false
MainUI.Parent = ScreenGui
corner(MainUI, 12)
local MainUIStroke = stroke(MainUI, Theme.Border)

--// ---- Top bar (highlighted) with title ----
local TopBar = Instance.new("Frame", MainUI)
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT)
TopBar.BackgroundColor3 = Theme.Header
TopBar.BorderSizePixel = 0
TopBar.Active = true
corner(TopBar, 12)

local TopBarMask = Instance.new("Frame", TopBar)
TopBarMask.Size = UDim2.new(1, 0, 0, 12)
TopBarMask.Position = UDim2.new(0, 0, 1, -12)
TopBarMask.BackgroundColor3 = Theme.Header
TopBarMask.BorderSizePixel = 0

local AccentBar = Instance.new("Frame", TopBar)
AccentBar.Size = UDim2.new(1, 0, 0, 2)
AccentBar.Position = UDim2.new(0, 0, 1, -2)
AccentBar.BackgroundColor3 = Theme.AccentBlue
AccentBar.BorderSizePixel = 0
AccentBar.ZIndex = 2

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -180, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = UI_NAME
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = Theme.AccentBlue
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 2

--// ---- Windows-style topbar controls: minimize / maximize / close ----
local TOPBAR_BTN_SIZE   = 26
local TOPBAR_BTN_GAP    = 6
local TOPBAR_BTN_MARGIN = 8

-- Icon "logical" canvas is 16x16 (same as the source chrome-* SVGs), drawn
-- with native Frames/UIStroke so the icon color stays theme-driven.
local ICON_SIZE = 14

local function clearIcon(holder)
    for _, child in ipairs(holder:GetChildren()) do
        child:Destroy()
    end
end

-- Draws the requested icon ("minimize" | "maximize" | "restore" | "close")
-- into `holder`, an empty centered Frame sized ICON_SIZE x ICON_SIZE.
local function drawIcon(holder, kind, color, bgColor)
    clearIcon(holder)

    if kind == "minimize" then
        -- chrome-minimize.svg: a single centered horizontal bar
        local Bar = Instance.new("Frame", holder)
        Bar.AnchorPoint = Vector2.new(0.5, 0.5)
        Bar.Position = UDim2.new(0.5, 0, 0.5, 0)
        Bar.Size = UDim2.new(0, ICON_SIZE, 0, 1.5)
        Bar.BackgroundColor3 = color
        Bar.BorderSizePixel = 0
        corner(Bar, 1)

    elseif kind == "maximize" then
        -- chrome-maximize.svg: a single rounded square outline
        local Box = Instance.new("Frame", holder)
        Box.AnchorPoint = Vector2.new(0.5, 0.5)
        Box.Position = UDim2.new(0.5, 0, 0.5, 0)
        Box.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
        Box.BackgroundTransparency = 1
        corner(Box, 3)
        stroke(Box, color, 1.4)

    elseif kind == "restore" then
        -- Classic restore glyph: two overlapping rounded-square outlines
        local Back = Instance.new("Frame", holder)
        Back.AnchorPoint = Vector2.new(0.5, 0.5)
        Back.Position = UDim2.new(0.5, 2, 0.5, -2)
        Back.Size = UDim2.new(0, ICON_SIZE - 4, 0, ICON_SIZE - 4)
        Back.BackgroundColor3 = bgColor
        Back.BorderSizePixel = 0
        corner(Back, 2)
        stroke(Back, color, 1.3)

        local Front = Instance.new("Frame", holder)
        Front.AnchorPoint = Vector2.new(0.5, 0.5)
        Front.Position = UDim2.new(0.5, -2, 0.5, 2)
        Front.Size = UDim2.new(0, ICON_SIZE - 4, 0, ICON_SIZE - 4)
        Front.BackgroundColor3 = bgColor
        Front.BorderSizePixel = 0
        corner(Front, 2)
        stroke(Front, color, 1.3)

    elseif kind == "close" then
        -- chrome-close.svg: two crossed rounded bars
        local Bar1 = Instance.new("Frame", holder)
        Bar1.AnchorPoint = Vector2.new(0.5, 0.5)
        Bar1.Position = UDim2.new(0.5, 0, 0.5, 0)
        Bar1.Size = UDim2.new(0, ICON_SIZE + 2, 0, 1.5)
        Bar1.Rotation = 45
        Bar1.BackgroundColor3 = color
        Bar1.BorderSizePixel = 0
        corner(Bar1, 1)

        local Bar2 = Instance.new("Frame", holder)
        Bar2.AnchorPoint = Vector2.new(0.5, 0.5)
        Bar2.Position = UDim2.new(0.5, 0, 0.5, 0)
        Bar2.Size = UDim2.new(0, ICON_SIZE + 2, 0, 1.5)
        Bar2.Rotation = -45
        Bar2.BackgroundColor3 = color
        Bar2.BorderSizePixel = 0
        corner(Bar2, 1)

    elseif kind == "resize" then
        -- Rounded square outline with a diagonal line (bottom-left -> top-right),
        -- matching the reference "resize" glyph.
        local Box = Instance.new("Frame", holder)
        Box.AnchorPoint = Vector2.new(0.5, 0.5)
        Box.Position = UDim2.new(0.5, 0, 0.5, 0)
        Box.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
        Box.BackgroundTransparency = 1
        corner(Box, 3)
        stroke(Box, color, 1.4)

        local Diag = Instance.new("Frame", holder)
        Diag.AnchorPoint = Vector2.new(0.5, 0.5)
        Diag.Position = UDim2.new(0.5, 0, 0.5, 0)
        Diag.Size = UDim2.new(0, ICON_SIZE * 0.95, 0, 1.5)
        Diag.Rotation = -45
        Diag.BackgroundColor3 = color
        Diag.BorderSizePixel = 0
        corner(Diag, 1)

    elseif kind == "reset" then
        -- debug-restart glyph: open ring (gap at top-left) + corner arrow head
        local Ring = Instance.new("Frame", holder)
        Ring.AnchorPoint = Vector2.new(0.5, 0.5)
        Ring.Position = UDim2.new(0.5, 0, 0.5, 0)
        Ring.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
        Ring.BackgroundTransparency = 1
        corner(Ring, 100)
        local RingStroke = stroke(Ring, color, 1.5)
        local RingGradient = Instance.new("UIGradient", RingStroke)
        RingGradient.Rotation = 45
        RingGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 1),
            NumberSequenceKeypoint.new(0.22, 1),
            NumberSequenceKeypoint.new(0.23, 0),
            NumberSequenceKeypoint.new(1.00, 0),
        })

        local ArrowV = Instance.new("Frame", holder)
        ArrowV.Position = UDim2.new(0, 0, 0, 0)
        ArrowV.Size = UDim2.new(0, 1.5, 0, 5)
        ArrowV.BackgroundColor3 = color
        ArrowV.BorderSizePixel = 0
        corner(ArrowV, 1)

        local ArrowH = Instance.new("Frame", holder)
        ArrowH.Position = UDim2.new(0, 0, 0, 3.5)
        ArrowH.Size = UDim2.new(0, 5, 0, 1.5)
        ArrowH.BackgroundColor3 = color
        ArrowH.BorderSizePixel = 0
        corner(ArrowH, 1)
    end
end

local function createTopbarButton(kind, xOffset, iconColor)
    iconColor = iconColor or Theme.Text

    local Btn = Instance.new("TextButton", TopBar)
    Btn.Size = UDim2.new(0, TOPBAR_BTN_SIZE, 0, TOPBAR_BTN_SIZE)
    Btn.Position = UDim2.new(1, xOffset, 0.5, -TOPBAR_BTN_SIZE / 2)
    Btn.BackgroundColor3 = Theme.PanelAlt
    Btn.Text = ""
    Btn.AutoButtonColor = false
    Btn.ZIndex = 2
    corner(Btn, 6)

    local IconHolder = Instance.new("Frame", Btn)
    IconHolder.Name = "Icon"
    IconHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    IconHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
    IconHolder.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
    IconHolder.BackgroundTransparency = 1
    IconHolder.ZIndex = 3

    drawIcon(IconHolder, kind, iconColor, Theme.PanelAlt)

    return Btn, IconHolder
end

-- Rightmost = Close, then Maximize, Minimize, Resize, Reset (leftmost)
local CloseBtn, CloseIcon = createTopbarButton("close", -(TOPBAR_BTN_MARGIN + TOPBAR_BTN_SIZE), Theme.Danger)
local MaximizeBtn, MaximizeIcon = createTopbarButton("maximize", -(TOPBAR_BTN_MARGIN + TOPBAR_BTN_SIZE * 2 + TOPBAR_BTN_GAP))
local MinimizeBtn, MinimizeIcon = createTopbarButton("minimize", -(TOPBAR_BTN_MARGIN + TOPBAR_BTN_SIZE * 3 + TOPBAR_BTN_GAP * 2))
local ResizeBtn, ResizeIcon = createTopbarButton("resize", -(TOPBAR_BTN_MARGIN + TOPBAR_BTN_SIZE * 4 + TOPBAR_BTN_GAP * 3))
local ResetBtn, ResetIcon = createTopbarButton("reset", -(TOPBAR_BTN_MARGIN + TOPBAR_BTN_SIZE * 5 + TOPBAR_BTN_GAP * 4))


--// ---- Body (tab column + function panel) ----
local Body = Instance.new("Frame", MainUI)
Body.Name = "Body"
Body.Size = UDim2.new(1, 0, 1, -TOPBAR_HEIGHT)
Body.Position = UDim2.new(0, 0, 0, TOPBAR_HEIGHT)
Body.BackgroundTransparency = 1

--// Function panel (right column) — 8px from UI right, 8px from top/bottom
local FunctionPanel = Instance.new("Frame", Body)
FunctionPanel.Name = "FunctionPanel"
FunctionPanel.Position = UDim2.new(0, MARGIN_EDGE + TAB_PANEL_WIDTH + MARGIN_GAP, 0, MARGIN_EDGE)
FunctionPanel.Size = UDim2.new(1, -(MARGIN_EDGE + TAB_PANEL_WIDTH + MARGIN_GAP + MARGIN_EDGE), 1, -(MARGIN_EDGE * 2))
FunctionPanel.BackgroundColor3 = Theme.PanelAlt
FunctionPanel.BorderSizePixel = 0
corner(FunctionPanel, 8)
stroke(FunctionPanel, Theme.Border)

local FunctionScroll = Instance.new("ScrollingFrame", FunctionPanel)
FunctionScroll.Name = "FunctionScroll"
FunctionScroll.Size = UDim2.new(1, -8, 1, -8)
FunctionScroll.Position = UDim2.new(0, 4, 0, 4)
FunctionScroll.BackgroundTransparency = 1
FunctionScroll.BorderSizePixel = 0
FunctionScroll.ScrollBarThickness = 5
FunctionScroll.ScrollBarImageColor3 = Theme.AccentBlue
FunctionScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
FunctionScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local FunctionLayout = Instance.new("UIListLayout", FunctionScroll)
FunctionLayout.SortOrder = Enum.SortOrder.LayoutOrder
FunctionLayout.Padding = UDim.new(0, 10)

local FunctionPadding = Instance.new("UIPadding", FunctionScroll)
FunctionPadding.PaddingLeft = UDim.new(0, 6)
FunctionPadding.PaddingRight = UDim.new(0, 6)

--// Tab column (left) — 8px from UI left, 8px from top/bottom, 10px from function panel.
--// Holds the tab-list panel on top and the pinned highlight (player info) tab below it.
local TabColumn = Instance.new("Frame", Body)
TabColumn.Name = "TabColumn"
TabColumn.Position = UDim2.new(0, MARGIN_EDGE, 0, MARGIN_EDGE)
TabColumn.Size = UDim2.new(0, TAB_PANEL_WIDTH, 1, -(MARGIN_EDGE * 2))
TabColumn.BackgroundTransparency = 1

--// Tab list panel (top part of the column)
local TabPanel = Instance.new("Frame", TabColumn)
TabPanel.Name = "TabPanel"
TabPanel.Size = UDim2.new(1, 0, 1, -(HIGHLIGHT_HEIGHT + HIGHLIGHT_GAP))
TabPanel.Position = UDim2.new(0, 0, 0, 0)
TabPanel.BackgroundColor3 = Theme.PanelAlt
TabPanel.BorderSizePixel = 0
corner(TabPanel, 8)
stroke(TabPanel, Theme.Border)

local TabScroll = Instance.new("ScrollingFrame", TabPanel)
TabScroll.Name = "TabScroll"
TabScroll.Size = UDim2.new(1, -8, 1, -8)
TabScroll.Position = UDim2.new(0, 4, 0, 4)
TabScroll.BackgroundTransparency = 1
TabScroll.BorderSizePixel = 0
TabScroll.ScrollBarThickness = 4
TabScroll.ScrollBarImageColor3 = Theme.AccentBlue
TabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local TabLayout = Instance.new("UIListLayout", TabScroll)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 6)

--// Highlight tab (pinned below the tab list, same width as the tab list)
local HighlightTab = Instance.new("Frame", TabColumn)
HighlightTab.Name = "HighlightTab"
HighlightTab.AnchorPoint = Vector2.new(0, 1)
HighlightTab.Position = UDim2.new(0, 0, 1, 0)
HighlightTab.Size = UDim2.new(1, 0, 0, HIGHLIGHT_HEIGHT)
HighlightTab.BackgroundColor3 = Theme.Header
HighlightTab.BorderSizePixel = 0
corner(HighlightTab, 8)

local HighlightStroke = stroke(HighlightTab, Theme.Neon, 2)
HighlightStroke.Transparency = 0 -- transparency nền được điều khiển bởi gradient bên dưới

-- Gradient tạo 2 vùng sáng cách đều nhau trên viền, phần còn lại gần như ẩn
local HighlightGradient = Instance.new("UIGradient", HighlightStroke)
HighlightGradient.Color = ColorSequence.new(Theme.Neon)
HighlightGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0.00, 1),   -- ẩn
    NumberSequenceKeypoint.new(0.04, 0),   -- vùng sáng 1 bắt đầu
    NumberSequenceKeypoint.new(0.14, 0),   -- vùng sáng 1 kết thúc
    NumberSequenceKeypoint.new(0.20, 1),   -- ẩn
    NumberSequenceKeypoint.new(0.50, 1),   -- ẩn (nửa còn lại của viền)
    NumberSequenceKeypoint.new(0.54, 0),   -- vùng sáng 2 bắt đầu
    NumberSequenceKeypoint.new(0.64, 0),   -- vùng sáng 2 kết thúc
    NumberSequenceKeypoint.new(0.70, 1),   -- ẩn
    NumberSequenceKeypoint.new(1.00, 1),   -- ẩn (khép vòng)
})

-- Xoay gradient liên tục quanh viền -> tạo hiệu ứng 2 điểm sáng chạy đuổi nhau,
-- luôn cùng tốc độ vì cùng nằm trên 1 gradient duy nhất.
local ROTATE_SPEED = 2 -- giây / 1 vòng quanh viền (chỉnh nhỏ hơn = chạy nhanh hơn)

task.spawn(function()
    while HighlightTab.Parent do
        HighlightGradient.Rotation = 0
        local spin = tween(
            HighlightGradient,
            ROTATE_SPEED,
            { Rotation = 360 },
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.In
        )
        spin:Play()
        spin.Completed:Wait()
    end
end)

local AvatarFrame = Instance.new("ImageLabel", HighlightTab)
AvatarFrame.Size = UDim2.new(0, 32, 0, 32)
AvatarFrame.Position = UDim2.new(0, 8, 0.5, -16)
AvatarFrame.BackgroundColor3 = Theme.Panel
AvatarFrame.ScaleType = Enum.ScaleType.Crop
AvatarFrame.ZIndex = 2
corner(AvatarFrame, 16)
stroke(AvatarFrame, Theme.Border)

--// Player name — truncates to "…" when it doesn't fit the highlight tab's width
local PlayerNameLabel = Instance.new("TextLabel", HighlightTab)
PlayerNameLabel.Size = UDim2.new(1, -50, 0, 18)
PlayerNameLabel.Position = UDim2.new(0, 48, 0, 8)
PlayerNameLabel.BackgroundTransparency = 1
PlayerNameLabel.Text = LocalPlayer.DisplayName
PlayerNameLabel.Font = Enum.Font.GothamBold
PlayerNameLabel.TextSize = 13
PlayerNameLabel.TextColor3 = Theme.Text
PlayerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
PlayerNameLabel.ZIndex = 2

local PlayerTagLabel = Instance.new("TextLabel", HighlightTab)
PlayerTagLabel.Size = UDim2.new(1, -50, 0, 14)
PlayerTagLabel.Position = UDim2.new(0, 48, 0, 26)
PlayerTagLabel.BackgroundTransparency = 1
PlayerTagLabel.Text = "@" .. LocalPlayer.Name
PlayerTagLabel.Font = Enum.Font.Gotham
PlayerTagLabel.TextSize = 11
PlayerTagLabel.TextColor3 = Theme.SubText
PlayerTagLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerTagLabel.TextTruncate = Enum.TextTruncate.AtEnd
PlayerTagLabel.ZIndex = 2

-- Load avatar thumbnail (safe pcall in case of API failure)
task.spawn(function()
    local ok, content = pcall(function()
        return Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100
        )
    end)
    if ok and content then
        AvatarFrame.Image = content
    end
end)

--// ================= DRAG SUPPORT =================
-- Remember where the window was left (skipped while maximized).
local isMaximized = false
local function commitUIState()
    if isMaximized then return end
    local p = MainUI.Position
    uiPosition = UDim2.new(0.5, p.X.Offset, 0.5, p.Y.Offset)
    curW, curH = MainUI.Size.X.Offset, MainUI.Size.Y.Offset
    saveSettings()
end

makeDraggable(TopBar, MainUI, commitUIState)

--// ---- Interaction blocker: covers MainUI while the close-confirm dialog is
--// open, so only the floating main toggle and the dialog's Yes/No remain
--// clickable (both live outside MainUI's subtree, so they're unaffected).
local InteractionBlocker = Instance.new("Frame", MainUI)
InteractionBlocker.Name = "InteractionBlocker"
InteractionBlocker.Size = UDim2.new(1, 0, 1, 0)
InteractionBlocker.BackgroundTransparency = 1
InteractionBlocker.BorderSizePixel = 0
InteractionBlocker.Active = true
InteractionBlocker.Visible = false
InteractionBlocker.ZIndex = 20

--// ================= OPEN / CLOSE ANIMATION =================
local isOpen = false

-- Forward-declared: assigned once the confirm dialog (Toggle 3) is built below.
-- closeUI needs to reference it so minimizing also dismisses a stray dialog.
local ConfirmBox
local hideConfirmDialog
local NotBox2
local hideNotBox2

local function openUI()
    isOpen = true
    MainUI.Visible = true
    MainUI.Size = UDim2.new(0, 0, 0, 0)
    tween(MainUI, POPUP_TIME, { Size = UDim2.new(0, curW, 0, curH) },
        Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
end

local function closeUI()
    isOpen = false
    if ConfirmBox and ConfirmBox.Visible then
        hideConfirmDialog()
    end
    if NotBox2 and NotBox2.Visible then
        hideNotBox2()
    end
    local t = tween(MainUI, CLOSE_TIME, { Size = UDim2.new(0, 0, 0, 0) },
        Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    t:Play()
    t.Completed:Connect(function()
        if not isOpen then
            MainUI.Visible = false
        end
    end)
end

makeDraggableButton(ToggleButton, ToggleButton, function()
    if isOpen then closeUI() else openUI() end
end, nil, saveSettings)

--// ---- Toggle 1: Minimize (same behavior as pressing the floating toggle) ----
MinimizeBtn.MouseButton1Click:Connect(function()
    if uiLocked then return end
    if isOpen then closeUI() end
end)

--// ---- Toggle 2: Maximize / Restore ----
local preMaxSize, preMaxPos

local function toggleMaximize()
    if isMaximized then
        isMaximized = false
        drawIcon(MaximizeIcon, "maximize", Theme.Text, Theme.PanelAlt)
        tween(MainUI, 0.25, { Size = preMaxSize, Position = preMaxPos },
            Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()
    else
        preMaxSize = MainUI.Size
        preMaxPos = MainUI.Position
        isMaximized = true
        drawIcon(MaximizeIcon, "restore", Theme.Text, Theme.PanelAlt)
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(UI_W, UI_H)
        tween(MainUI, 0.25, {
            Size = UDim2.new(0, viewport.X, 0, viewport.Y),
            Position = UDim2.new(0.5, 0, 0.5, 0),
        }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()
    end
end

MaximizeBtn.MouseButton1Click:Connect(function()
    if uiLocked then return end
    toggleMaximize()
end)

--// ---- Toggle 3: Fully close UI + main toggle (with confirmation) ----
ConfirmBox = Instance.new("CanvasGroup", ScreenGui)
ConfirmBox.Name = "ConfirmBox"
ConfirmBox.Visible = false
ConfirmBox.AnchorPoint = Vector2.new(0.5, 0.5)
ConfirmBox.Position = UDim2.new(0.5, 0, 0.5, 0)
ConfirmBox.Size = UDim2.new(0, 300, 0, 140)
ConfirmBox.BackgroundColor3 = Theme.Panel
ConfirmBox.BorderSizePixel = 0
ConfirmBox.GroupTransparency = 1
ConfirmBox.ZIndex = 51
corner(ConfirmBox, 10)
stroke(ConfirmBox, Theme.Border)

local ConfirmAccent = Instance.new("Frame", ConfirmBox)
ConfirmAccent.Size = UDim2.new(1, 0, 0, 3)
ConfirmAccent.BackgroundColor3 = Theme.AccentBlue
ConfirmAccent.BorderSizePixel = 0
ConfirmAccent.ZIndex = 52
corner(ConfirmAccent, 10)

local ConfirmText = Instance.new("TextLabel", ConfirmBox)
ConfirmText.Size = UDim2.new(1, -24, 0, 60)
ConfirmText.Position = UDim2.new(0, 12, 0, 18)
ConfirmText.BackgroundTransparency = 1
ConfirmText.Text = "You want to close this script?"
ConfirmText.Font = Enum.Font.GothamBold
ConfirmText.TextSize = 16
ConfirmText.TextWrapped = true
ConfirmText.TextColor3 = Theme.Text
ConfirmText.ZIndex = 52

local YesBtn = Instance.new("TextButton", ConfirmBox)
YesBtn.Size = UDim2.new(0, 120, 0, 32)
YesBtn.Position = UDim2.new(0, 20, 1, -46)
YesBtn.BackgroundColor3 = Theme.Danger
YesBtn.Text = "Yes"
YesBtn.Font = Enum.Font.GothamBold
YesBtn.TextSize = 14
YesBtn.TextColor3 = Theme.Background
YesBtn.AutoButtonColor = false
YesBtn.ZIndex = 52
corner(YesBtn, 8)

local NoBtn = Instance.new("TextButton", ConfirmBox)
NoBtn.Size = UDim2.new(0, 120, 0, 32)
NoBtn.Position = UDim2.new(1, -140, 1, -46)
NoBtn.BackgroundColor3 = Theme.PanelAlt
NoBtn.Text = "No"
NoBtn.Font = Enum.Font.GothamBold
NoBtn.TextSize = 14
NoBtn.TextColor3 = Theme.Text
NoBtn.AutoButtonColor = false
NoBtn.ZIndex = 52
corner(NoBtn, 8)
stroke(NoBtn, Theme.Border)

local CONFIRM_SIZE = UDim2.new(0, 300, 0, 140)
local BUBBLE_IN_TIME  = 0.3                 -- bubble grow duration
local FADE_IN_TIME    = BUBBLE_IN_TIME * 2  -- fade in is 2x slower than the bubble

local BUBBLE_OUT_TIME = BUBBLE_IN_TIME * 0.7 -- bubble shrink duration
local FADE_OUT_TIME   = BUBBLE_OUT_TIME / 3  -- fade out is 3x faster than the bubble

local function showConfirmDialog()
    InteractionBlocker.Visible = true
    ConfirmBox.Visible = true
    ConfirmBox.GroupTransparency = 1
    ConfirmBox.Size = UDim2.new(0, 0, 0, 0)
    tween(ConfirmBox, BUBBLE_IN_TIME, { Size = CONFIRM_SIZE },
        Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()
    tween(ConfirmBox, FADE_IN_TIME, { GroupTransparency = 0 },
        Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()
end

function hideConfirmDialog()
    local sizeTween = tween(ConfirmBox, BUBBLE_OUT_TIME, { Size = UDim2.new(0, 0, 0, 0) },
        Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local fadeTween = tween(ConfirmBox, FADE_OUT_TIME, { GroupTransparency = 1 },
        Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    sizeTween:Play()
    fadeTween:Play()
    sizeTween.Completed:Connect(function()
        ConfirmBox.Visible = false
        InteractionBlocker.Visible = false
    end)
end

CloseBtn.MouseButton1Click:Connect(function()
    if uiLocked then return end
    showConfirmDialog()
end)

YesBtn.MouseButton1Click:Connect(function()
    -- Fully closes both the UI and the floating main toggle
    ScreenGui:Destroy()
end)

NoBtn.MouseButton1Click:Connect(hideConfirmDialog)

--// ================= TOGGLE 5: RESET (NotBox2) =================
-- Same look/behavior as the close-confirm box: blocks MainUI while open.
NotBox2 = Instance.new("CanvasGroup", ScreenGui)
NotBox2.Name = "NotBox2"
NotBox2.Visible = false
NotBox2.AnchorPoint = Vector2.new(0.5, 0.5)
NotBox2.Position = UDim2.new(0.5, 0, 0.5, 0)
NotBox2.Size = UDim2.new(0, 0, 0, 0)
NotBox2.BackgroundColor3 = Theme.Panel
NotBox2.BorderSizePixel = 0
NotBox2.GroupTransparency = 1
NotBox2.ZIndex = 51
corner(NotBox2, 10)
stroke(NotBox2, Theme.Border)

local NotBox2Accent = Instance.new("Frame", NotBox2)
NotBox2Accent.Size = UDim2.new(1, 0, 0, 3)
NotBox2Accent.BackgroundColor3 = Theme.AccentBlue
NotBox2Accent.BorderSizePixel = 0
NotBox2Accent.ZIndex = 52
corner(NotBox2Accent, 10)

local NotBox2Text = Instance.new("TextLabel", NotBox2)
NotBox2Text.Size = UDim2.new(1, -24, 0, 60)
NotBox2Text.Position = UDim2.new(0, 12, 0, 18)
NotBox2Text.BackgroundTransparency = 1
NotBox2Text.Text = "Do you want to reset UI?"
NotBox2Text.Font = Enum.Font.GothamBold
NotBox2Text.TextSize = 16
NotBox2Text.TextWrapped = true
NotBox2Text.TextColor3 = Theme.Text
NotBox2Text.ZIndex = 52

local NotBox2Yes = Instance.new("TextButton", NotBox2)
NotBox2Yes.Size = UDim2.new(0, 120, 0, 32)
NotBox2Yes.Position = UDim2.new(0, 20, 1, -46)
NotBox2Yes.BackgroundColor3 = Theme.AccentBlue
NotBox2Yes.Text = "Yes"
NotBox2Yes.Font = Enum.Font.GothamBold
NotBox2Yes.TextSize = 14
NotBox2Yes.TextColor3 = Theme.Background
NotBox2Yes.AutoButtonColor = false
NotBox2Yes.ZIndex = 52
corner(NotBox2Yes, 8)

local NotBox2No = Instance.new("TextButton", NotBox2)
NotBox2No.Size = UDim2.new(0, 120, 0, 32)
NotBox2No.Position = UDim2.new(1, -140, 1, -46)
NotBox2No.BackgroundColor3 = Theme.PanelAlt
NotBox2No.Text = "No"
NotBox2No.Font = Enum.Font.GothamBold
NotBox2No.TextSize = 14
NotBox2No.TextColor3 = Theme.Text
NotBox2No.AutoButtonColor = false
NotBox2No.ZIndex = 52
corner(NotBox2No, 8)
stroke(NotBox2No, Theme.Border)

local function showNotBox2()
    InteractionBlocker.Visible = true
    NotBox2.Visible = true
    NotBox2.GroupTransparency = 1
    NotBox2.Size = UDim2.new(0, 0, 0, 0)
    tween(NotBox2, BUBBLE_IN_TIME, { Size = CONFIRM_SIZE },
        Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()
    tween(NotBox2, FADE_IN_TIME, { GroupTransparency = 0 },
        Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()
end

function hideNotBox2()
    local sizeTween = tween(NotBox2, BUBBLE_OUT_TIME, { Size = UDim2.new(0, 0, 0, 0) },
        Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local fadeTween = tween(NotBox2, FADE_OUT_TIME, { GroupTransparency = 1 },
        Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    sizeTween:Play()
    fadeTween:Play()
    sizeTween.Completed:Connect(function()
        NotBox2.Visible = false
        InteractionBlocker.Visible = false
    end)
end

-- Restores main toggle position, UI position and UI size to their defaults.
local function resetLayout()
    if isMaximized then
        isMaximized = false
        drawIcon(MaximizeIcon, "maximize", Theme.Text, Theme.PanelAlt)
    end

    curW, curH = UI_W, UI_H
    uiPosition = UDim2.new(0.5, 0, 0.5, 0)

    local props = { Position = uiPosition }
    if isOpen then
        props.Size = UDim2.new(0, curW, 0, curH)
    end
    tween(MainUI, 0.2, props, Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()
    tween(ToggleButton, 0.2, { Position = DEFAULT_TOGGLE_POS },
        Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()

    saveSettings()
end

ResetBtn.MouseButton1Click:Connect(function()
    if uiLocked then return end
    showNotBox2()
end)

NotBox2Yes.MouseButton1Click:Connect(function()
    resetLayout()
    hideNotBox2()
end)

NotBox2No.MouseButton1Click:Connect(hideNotBox2)

--// ================= TOGGLE 4: RESIZE MODE =================
-- Locks every other control (via `uiLocked`) and shows 4 draggable corner
-- handles so the player can freely resize MainUI by touch/mouse.
local RESIZE_HANDLE_SIZE = 18
local resizeMode = false
local ResizeHandleList = {}

local function createResizeHandle()
    local Handle = Instance.new("Frame")
    Handle.Name = "ResizeHandle"
    Handle.AnchorPoint = Vector2.new(0.5, 0.5)
    Handle.Size = UDim2.new(0, RESIZE_HANDLE_SIZE, 0, RESIZE_HANDLE_SIZE)
    Handle.BackgroundColor3 = Theme.AccentBlue
    Handle.BorderSizePixel = 0
    Handle.Visible = false
    Handle.Active = true
    Handle.ZIndex = 100
    Handle.Parent = ScreenGui
    corner(Handle, 6)
    stroke(Handle, Theme.Text, 1.5)

    local Grip = Instance.new("TextButton", Handle)
    Grip.Size = UDim2.new(1, 0, 1, 0)
    Grip.BackgroundTransparency = 1
    Grip.Text = ""
    Grip.AutoButtonColor = false
    Grip.ZIndex = 101

    table.insert(ResizeHandleList, Handle)
    return Handle, Grip
end

local TLHandle, TLGrip = createResizeHandle()
local TRHandle, TRGrip = createResizeHandle()
local BLHandle, BLGrip = createResizeHandle()
local BRHandle, BRGrip = createResizeHandle()

local function updateResizeHandlePositions()
    local pos, size = MainUI.AbsolutePosition, MainUI.AbsoluteSize
    TLHandle.Position = UDim2.new(0, pos.X, 0, pos.Y)
    TRHandle.Position = UDim2.new(0, pos.X + size.X, 0, pos.Y)
    BLHandle.Position = UDim2.new(0, pos.X, 0, pos.Y + size.Y)
    BRHandle.Position = UDim2.new(0, pos.X + size.X, 0, pos.Y + size.Y)
end

MainUI:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    if resizeMode then updateResizeHandlePositions() end
end)
MainUI:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    if resizeMode then updateResizeHandlePositions() end
end)

-- Only one corner can be dragged at a time; a single shared InputChanged
-- connection (see below) drives the live resize while `resizeDragCorner` is set.
local resizeDragCorner = nil
local resizeFixedX, resizeFixedY = 0, 0

local function beginResizeDrag(cornerName)
    local pos, size = MainUI.AbsolutePosition, MainUI.AbsoluteSize
    if cornerName == "TL" then
        resizeFixedX, resizeFixedY = pos.X + size.X, pos.Y + size.Y
    elseif cornerName == "TR" then
        resizeFixedX, resizeFixedY = pos.X, pos.Y + size.Y
    elseif cornerName == "BL" then
        resizeFixedX, resizeFixedY = pos.X + size.X, pos.Y
    else -- "BR"
        resizeFixedX, resizeFixedY = pos.X, pos.Y
    end
    resizeDragCorner = cornerName
end

local function setupResizeGrip(grip, cornerName)
    grip.InputBegan:Connect(function(input)
        if not resizeMode then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            beginResizeDrag(cornerName)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End
                    and resizeDragCorner == cornerName then
                    resizeDragCorner = nil
                    commitUIState()
                end
            end)
        end
    end)
end

setupResizeGrip(TLGrip, "TL")
setupResizeGrip(TRGrip, "TR")
setupResizeGrip(BLGrip, "BL")
setupResizeGrip(BRGrip, "BR")

UserInputService.InputChanged:Connect(function(input)
    if not resizeMode or not resizeDragCorner then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local mouseX, mouseY = input.Position.X, input.Position.Y
    local newW = math.max(MIN_UI_W, math.abs(mouseX - resizeFixedX))
    local newH = math.max(MIN_UI_H, math.abs(mouseY - resizeFixedY))

    local signX = (mouseX >= resizeFixedX) and 1 or -1
    local signY = (mouseY >= resizeFixedY) and 1 or -1
    local movingX = resizeFixedX + signX * newW
    local movingY = resizeFixedY + signY * newH

    local centerX = (resizeFixedX + movingX) / 2
    local centerY = (resizeFixedY + movingY) / 2

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(newW, newH)

    MainUI.Size = UDim2.new(0, newW, 0, newH)
    MainUI.Position = UDim2.new(
        0.5, centerX - viewport.X * 0.5,
        0.5, centerY - viewport.Y * 0.5
    )

    updateResizeHandlePositions()
end)

local function enterResizeMode()
    resizeMode = true
    uiLocked = true
    drawIcon(ResizeIcon, "resize", Theme.AccentBlue, Theme.PanelAlt)
    tween(MainUIStroke, 0.2, { Color = Theme.AccentBlue, Thickness = 2 }):Play()
    for _, h in ipairs(ResizeHandleList) do
        h.Visible = true
    end
    updateResizeHandlePositions()
end

local function exitResizeMode()
    resizeMode = false
    uiLocked = false
    resizeDragCorner = nil
    drawIcon(ResizeIcon, "resize", Theme.Text, Theme.PanelAlt)
    tween(MainUIStroke, 0.2, { Color = Theme.Border, Thickness = 1 }):Play()
    for _, h in ipairs(ResizeHandleList) do
        h.Visible = false
    end
end

ResizeBtn.MouseButton1Click:Connect(function()
    if resizeMode then
        exitResizeMode()
    else
        enterResizeMode()
    end
end)

--// ================= TAB SYSTEM =================
local Tabs = {}          -- ordered list of tab names
local TabButtons = {}     -- [name] = TextButton
local TabContents = {}    -- [name] = Frame (inside FunctionScroll)
local activeTab = nil

local function selectTab(name)
    if activeTab == name then return end
    activeTab = name

    for tabName, btn in pairs(TabButtons) do
        local selected = tabName == name
        tween(btn, 0.15, {
            BackgroundColor3 = selected and Theme.AccentBlue or Theme.Panel,
        }):Play()
        btn.TextColor3 = selected and Theme.Background or Theme.Text
    end

    for tabName, content in pairs(TabContents) do
        content.Visible = tabName == name
    end
end

-- Creates a new tab; returns the content frame to add functions/elements into.
local function CreateTab(name)
    table.insert(Tabs, name)

    local Btn = Instance.new("TextButton", TabScroll)
    Btn.Name = "Tab_" .. name
    Btn.Size = UDim2.new(1, 0, 0, 34)
    Btn.BackgroundColor3 = Theme.Panel
    Btn.Text = name
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.TextColor3 = Theme.Text
    Btn.AutoButtonColor = false
    Btn.TextWrapped = true
    corner(Btn, 6)
    TabButtons[name] = Btn

    local Content = Instance.new("Frame", FunctionScroll)
    Content.Name = "TabContent_" .. name
    Content.Size = UDim2.new(1, 0, 0, 0)
    Content.AutomaticSize = Enum.AutomaticSize.Y
    Content.BackgroundTransparency = 1
    Content.Visible = false

    local ContentLayout = Instance.new("UIListLayout", Content)
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Padding = UDim.new(0, 10)

    TabContents[name] = Content

    Btn.MouseButton1Click:Connect(function()
        if uiLocked then return end
        selectTab(name)
    end)

    if #Tabs == 1 then
        selectTab(name)
    end

    return Content
end

--// ================= FUNCTION ELEMENT BUILDERS =================
-- Generic feature row with a title and a toggle switch. Attach your own
-- logic to the returned Switch's "Toggled" attribute changes.
local function CreateToggleOption(parent, title, height)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, 0, 0, height or 50)
    Frame.BackgroundColor3 = Theme.Panel
    Frame.BorderSizePixel = 0
    corner(Frame, 8)
    stroke(Frame, Theme.Border)

    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1, -80, 1, 0)
    Label.Position = UDim2.new(0, 14, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 15
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextColor3 = Theme.Text

    local pxW, pxH, rightOffset = 46, 24, 12
    local Switch = Instance.new("TextButton", Frame)
    Switch.Size = UDim2.new(0, pxW, 0, pxH)
    Switch.AnchorPoint = Vector2.new(1, 0.5)
    Switch.Position = UDim2.new(1, -rightOffset, 0.5, 0)
    Switch.BackgroundColor3 = Theme.ToggleOff
    Switch.Text = ""
    Switch.AutoButtonColor = false
    corner(Switch, 12)

    -- Purple -> pink gradient shown only while the switch is ON
    local SwitchGradient = Instance.new("UIGradient", Switch)
    SwitchGradient.Color = ColorSequence.new(Theme.AccentPurple, Theme.AccentBlue)
    SwitchGradient.Enabled = false

    local Knob = Instance.new("Frame", Switch)
    Knob.Size = UDim2.new(0, pxH - 4, 0, pxH - 4)
    Knob.Position = UDim2.new(0, 2, 0, 2)
    Knob.BackgroundColor3 = Theme.ToggleKnob
    Knob.BorderSizePixel = 0
    corner(Knob, 10)

    local state = false
    Switch:SetAttribute("Toggled", false)

    Switch.MouseButton1Click:Connect(function()
        if uiLocked then return end
        state = not state
        Switch:SetAttribute("Toggled", state)

        local knobTarget = state and UDim2.new(1, -(pxH - 2), 0, 2) or UDim2.new(0, 2, 0, 2)
        local bgTarget = state and Theme.AccentBlue or Theme.ToggleOff
        local knobColorTarget = state and Color3.fromRGB(255, 255, 255) or Theme.ToggleKnob

        SwitchGradient.Enabled = state
        tween(Switch, 0.18, { BackgroundColor3 = bgTarget }):Play()
        tween(Knob, 0.18, { Position = knobTarget, BackgroundColor3 = knobColorTarget }):Play()
    end)

    return Switch
end

-- Simple section header inside a tab (for grouping options visually).
local function CreateSectionLabel(parent, text)
    local Label = Instance.new("TextLabel", parent)
    Label.Size = UDim2.new(1, 0, 0, 24)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 13
    Label.TextColor3 = Theme.SubText
    Label.TextXAlignment = Enum.TextXAlignment.Left
    return Label
end

--// ================= EXAMPLE TABS (replace with real content) =================
local MainTab = CreateTab("Main")
CreateSectionLabel(MainTab, "General Options")
CreateToggleOption(MainTab, "Example Option 1")
CreateToggleOption(MainTab, "Example Option 2")

local SettingsTab = CreateTab("Settings")
CreateSectionLabel(SettingsTab, "UI Settings")
CreateToggleOption(SettingsTab, "Example Setting 1")

local InfoTab = CreateTab("Info")
CreateSectionLabel(InfoTab, "About")
CreateToggleOption(InfoTab, "Example Info Toggle")

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
