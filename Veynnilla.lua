--// ============================================================
--// UI language: English (US) only
--// ============================================================

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--// ================= CLEANUP PREVIOUS INSTANCE =================
if CoreGui:FindFirstChild("ZannystarUI") then
    CoreGui.ZannystarUI:Destroy()
end

--// ================= THEME =================
local Theme = {
    Background   = Color3.fromRGB(29, 21, 52),    -- #1D1534 bg-main
    Panel        = Color3.fromRGB(33, 21, 58),    -- #21153A bg-card
    PanelAlt     = Color3.fromRGB(37, 25, 66),    -- #251942 bg-sidebar
    Header       = Color3.fromRGB(49, 32, 75),    -- #31204B bg-card-hover
    Border       = Color3.fromRGB(84, 53, 128),   -- #543580 purple border
    AccentBlue   = Color3.fromRGB(243, 99, 225),  -- #F363E1 pink primary (main accent)
    AccentPurple = Color3.fromRGB(175, 88, 249),  -- #AF58F9 purple neon
    Text         = Color3.fromRGB(226, 190, 250), -- #E2BEFA text primary
    SubText      = Color3.fromRGB(191, 157, 238), -- #BF9DEE text secondary / purple light
    Success      = Color3.fromRGB(158, 206, 106),
    Danger       = Color3.fromRGB(247, 118, 142),
    Neon         = Color3.fromRGB(175, 88, 249),  -- #AF58F9 purple neon
    ToggleOff    = Color3.fromRGB(71, 48, 112),   -- #473070 toggle OFF track
    ToggleKnob   = Color3.fromRGB(226, 190, 250), -- #E2BEFA toggle knob (off)
}

--// ================= CONFIG =================
local UI_NAME        = "Zannystar"
local UI_W, UI_H      = 650, 420      -- reduced UI size
local TOGGLE_SIZE     = 50
local POPUP_TIME      = 0.45
local CLOSE_TIME      = 0.30
local TOPBAR_HEIGHT   = 40

--// ---- Layout margins (per spec) ----
local MARGIN_EDGE     = 8   -- tabs/panels <-> top & bottom of UI, tab list <-> UI left, function panel <-> UI right
local MARGIN_GAP      = 10  -- tab list <-> function panel
local TAB_PANEL_WIDTH = 150 -- fixed width of the left tab-list column (also width of the highlight tab below it)

local HIGHLIGHT_HEIGHT = 56 -- height of the pinned player-info highlight tab
local HIGHLIGHT_GAP     = 8 -- gap between tab list and the highlight tab above it

--// ================= ROOT =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZannystarUI"
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

local function makeDraggable(handle, target)
    local dragging, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
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

-- Same as makeDraggable, but only fires onClick() when the input ends
-- WITHOUT having moved past `threshold` pixels — a real drag never
-- triggers the click, and a real click never moves the button.
local function makeDraggableButton(handle, target, onClick, threshold)
    threshold = threshold or 5
    local dragging, moved, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = target.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if dragging and not moved then
                        onClick()
                    end
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
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

--// ================= FLOATING TOGGLE BUTTON =================
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "MG_Toggle"
ToggleButton.Size = UDim2.new(0, TOGGLE_SIZE, 0, TOGGLE_SIZE)
ToggleButton.Position = UDim2.new(0, 20, 0.5, -TOGGLE_SIZE / 2)
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
MainUI.Position = UDim2.new(0.5, 0, 0.5, 0)
MainUI.Size = UDim2.new(0, 0, 0, 0)
MainUI.BackgroundColor3 = Theme.Background
MainUI.BorderSizePixel = 0
MainUI.ClipsDescendants = true
MainUI.Visible = false
MainUI.Parent = ScreenGui
corner(MainUI, 12)
stroke(MainUI, Theme.Border)

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
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = UI_NAME
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = Theme.AccentBlue
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 2

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -14)
CloseBtn.BackgroundColor3 = Theme.PanelAlt
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.TextColor3 = Theme.Danger
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 2
corner(CloseBtn, 6)

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
HighlightStroke.Transparency = 0.1

-- Neon pulsing glow loop
task.spawn(function()
    while HighlightTab.Parent do
        tween(HighlightStroke, 0.9, { Transparency = 0.6 }, Enum.EasingStyle.Sine):Play()
        task.wait(0.9)
        tween(HighlightStroke, 0.9, { Transparency = 0.1 }, Enum.EasingStyle.Sine):Play()
        task.wait(0.9)
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
makeDraggable(TopBar, MainUI)

--// ================= OPEN / CLOSE ANIMATION =================
local isOpen = false

local function openUI()
    isOpen = true
    MainUI.Visible = true
    MainUI.Size = UDim2.new(0, 0, 0, 0)
    tween(MainUI, POPUP_TIME, { Size = UDim2.new(0, UI_W, 0, UI_H) },
        Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
end

local function closeUI()
    isOpen = false
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
end)

CloseBtn.MouseButton1Click:Connect(closeUI)

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
local Zannystar = {
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

return Zannystar
