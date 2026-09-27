--// Services
local CoreGui          = game:GetService("CoreGui")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local LocalPlayer      = Players.LocalPlayer

--// Cleanup previous instance
if CoreGui:FindFirstChild("MinzyGuriUI") then
    CoreGui.MinzyGuriUI:Destroy()
end

--// ================= THEME: Midnight City (VSCode) =================
local Theme = {
    Background   = Color3.fromRGB(26, 27, 38),
    Panel        = Color3.fromRGB(36, 40, 59),
    Header       = Color3.fromRGB(30, 32, 48),
    Border       = Color3.fromRGB(65, 72, 104),
    AccentBlue   = Color3.fromRGB(122, 162, 247),
    AccentPurple = Color3.fromRGB(187, 154, 247),
    Text         = Color3.fromRGB(192, 202, 245),
    SubText      = Color3.fromRGB(120, 130, 170),
    Success      = Color3.fromRGB(158, 206, 106),
    Danger       = Color3.fromRGB(247, 118, 142),
}

--// ================= CONFIG =================
local UI_W, UI_H     = 340, 380
local POPUP_TIME     = 1.5
local CLOSE_TIME     = 0.35

local ESPConfig = {
    UpdateInterval = 0.25,           -- giây giữa mỗi lần cập nhật khoảng cách / máu
    AllyColor      = Theme.Success,  -- màu cho đồng đội
    EnemyColor     = Theme.Danger,   -- màu cho đối thủ / không cùng team
    NeutralColor   = Theme.AccentBlue, -- màu khi game không có hệ thống Team
    BarBackground  = Color3.fromRGB(20, 21, 32),
}

local FIXLAG_EFFECT_CLASSES  = { "ParticleEmitter", "Trail", "Beam", "Smoke", "Fire", "Sparkles" }
local FIXLAG_LIGHT_CLASSES   = { "PointLight", "SpotLight", "SurfaceLight" }
local FIXLAG_LIGHTING_EFFECTS = { "BloomEffect", "BlurEffect", "SunRaysEffect", "ColorCorrectionEffect", "DepthOfFieldEffect" }

local function classIn(list, className)
    for _, name in ipairs(list) do
        if name == className then return true end
    end
    return false
end

--// ================= ROOT =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MinzyGuriUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

--// ================= MAIN WINDOW =================
local MainUI = Instance.new("Frame")
MainUI.Name = "MG_Main"
MainUI.AnchorPoint = Vector2.new(0.5, 0.5)
MainUI.Position = UDim2.new(0.5, 0, 0.5, 0)
MainUI.Size = UDim2.new(0, UI_W, 0, UI_H)
MainUI.BackgroundColor3 = Theme.Background
MainUI.BorderSizePixel = 0
MainUI.ClipsDescendants = true
MainUI.Parent = ScreenGui

Instance.new("UICorner", MainUI).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainUI)
MainStroke.Thickness = 1
MainStroke.Color = Theme.Border

--// Header
local Header = Instance.new("Frame", MainUI)
Header.Size = UDim2.new(1, 0, 0, 36)
Header.BackgroundColor3 = Theme.Header
Header.BorderSizePixel = 0
Header.Active = true
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

local HeaderMask = Instance.new("Frame", Header)
HeaderMask.Size = UDim2.new(1, 0, 0, 10)
HeaderMask.Position = UDim2.new(0, 0, 1, -10)
HeaderMask.BackgroundColor3 = Theme.Header
HeaderMask.BorderSizePixel = 0

local HeaderTitle = Instance.new("TextLabel", Header)
HeaderTitle.Size = UDim2.new(1, -80, 1, 0)
HeaderTitle.Position = UDim2.new(0, 12, 0, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "Player Hub"
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.TextSize = 16
HeaderTitle.TextColor3 = Theme.AccentBlue
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.ZIndex = 2

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -33, 0.5, -13)
CloseBtn.BackgroundColor3 = Theme.Panel
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.TextColor3 = Theme.Danger
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 2
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

--// Floating toggle button
local ToggleButton = Instance.new("ImageButton")
ToggleButton.Name = "MG_Toggle"
ToggleButton.Size = UDim2.new(0, 46, 0, 46)
ToggleButton.Position = UDim2.new(0, 20, 0.5, -23)
ToggleButton.BackgroundColor3 = Theme.Panel
ToggleButton.Image = "rbxassetid://3926305904"
ToggleButton.ImageRectOffset = Vector2.new(764, 44)
ToggleButton.ImageRectSize = Vector2.new(36, 36)
ToggleButton.ImageColor3 = Theme.AccentBlue
ToggleButton.Parent = ScreenGui
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", ToggleButton).Color = Theme.Border

--// Confirm-close dialog
local ConfirmBox = Instance.new("Frame", ScreenGui)
ConfirmBox.Size = UDim2.new(0, 260, 0, 130)
ConfirmBox.Position = UDim2.new(0.5, -130, 0.5, -65)
ConfirmBox.BackgroundColor3 = Theme.Panel
ConfirmBox.Visible = false
Instance.new("UICorner", ConfirmBox).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", ConfirmBox).Color = Theme.AccentPurple

local ConfirmText = Instance.new("TextLabel", ConfirmBox)
ConfirmText.Size = UDim2.new(1, -20, 0, 50)
ConfirmText.Position = UDim2.new(0, 10, 0, 10)
ConfirmText.BackgroundTransparency = 1
ConfirmText.Text = "Đóng script này?"
ConfirmText.Font = Enum.Font.GothamBold
ConfirmText.TextSize = 16
ConfirmText.TextColor3 = Theme.Text
ConfirmText.TextWrapped = true

local YesBtn = Instance.new("TextButton", ConfirmBox)
YesBtn.Size = UDim2.new(0.42, 0, 0, 36)
YesBtn.Position = UDim2.new(0.06, 0, 0.62, 0)
YesBtn.BackgroundColor3 = Theme.Success
YesBtn.Text = "Có"
YesBtn.Font = Enum.Font.GothamBold
YesBtn.TextSize = 16
YesBtn.TextColor3 = Theme.Background
YesBtn.AutoButtonColor = false
Instance.new("UICorner", YesBtn).CornerRadius = UDim.new(0, 8)

local NoBtn = Instance.new("TextButton", ConfirmBox)
NoBtn.Size = UDim2.new(0.42, 0, 0, 36)
NoBtn.Position = UDim2.new(0.52, 0, 0.62, 0)
NoBtn.BackgroundColor3 = Theme.Danger
NoBtn.Text = "Không"
NoBtn.Font = Enum.Font.GothamBold
NoBtn.TextSize = 16
NoBtn.TextColor3 = Theme.Background
NoBtn.AutoButtonColor = false
Instance.new("UICorner", NoBtn).CornerRadius = UDim.new(0, 8)

CloseBtn.MouseButton1Click:Connect(function() ConfirmBox.Visible = true end)
YesBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
NoBtn.MouseButton1Click:Connect(function() ConfirmBox.Visible = false end)

--// ================= CONTENT (single "Player" panel) =================
local Content = Instance.new("ScrollingFrame", MainUI)
Content.Size = UDim2.new(1, -20, 1, -46)
Content.Position = UDim2.new(0, 10, 0, 40)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 5
Content.ScrollBarImageColor3 = Theme.AccentBlue
Content.CanvasSize = UDim2.new(0, 0, 0, 0)

local ContentLayout = Instance.new("UIListLayout", Content)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 10)

ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Content.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10)
end)

--// ================= DRAG SUPPORT =================
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

makeDraggable(Header, MainUI)
makeDraggable(ToggleButton, ToggleButton)

--// ================= POP-UP APPEAR ANIMATION (1.5s) =================
local isUIVisible = true

local function popIn()
    MainUI.Visible = true
    MainUI.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(
        MainUI,
        TweenInfo.new(POPUP_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, UI_W, 0, UI_H) }
    ):Play()
end

local function popOut()
    local tween = TweenService:Create(
        MainUI,
        TweenInfo.new(CLOSE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Size = UDim2.new(0, 0, 0, 0) }
    )
    tween:Play()
    tween.Completed:Connect(function()
        if not isUIVisible then
            MainUI.Visible = false
        end
    end)
end

ToggleButton.MouseButton1Click:Connect(function()
    isUIVisible = not isUIVisible
    if isUIVisible then
        popIn()
    else
        popOut()
    end
end)

--// ================= UI BUILDERS =================
local function createSwitch(parent, pxW, pxH, rightOffset)
    pxW, pxH, rightOffset = pxW or 50, pxH or 26, rightOffset or 10

    local Switch = Instance.new("TextButton", parent)
    Switch.Size = UDim2.new(0, pxW, 0, pxH)
    Switch.AnchorPoint = Vector2.new(1, 0.5)
    Switch.Position = UDim2.new(1, -rightOffset, 0.5, 0)
    Switch.BackgroundColor3 = Theme.Border
    Switch.Text = ""
    Switch.AutoButtonColor = false
    Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame", Switch)
    Knob.Size = UDim2.new(0, pxH - 4, 0, pxH - 4)
    Knob.Position = UDim2.new(0, 2, 0, 2)
    Knob.BackgroundColor3 = Theme.Text
    Knob.BorderSizePixel = 0
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local state = false
    Switch:SetAttribute("Toggled", false)

    Switch.MouseButton1Click:Connect(function()
        state = not state
        Switch:SetAttribute("Toggled", state)

        local knobTarget = state and UDim2.new(1, -(pxH - 2), 0, 2) or UDim2.new(0, 2, 0, 2)
        local bgTarget = state and Theme.AccentBlue or Theme.Border

        TweenService:Create(Switch, TweenInfo.new(0.18), { BackgroundColor3 = bgTarget }):Play()
        TweenService:Create(Knob, TweenInfo.new(0.18), { Position = knobTarget }):Play()
    end)

    return Switch
end

local function createFeatureFrame(parent, title, height)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, 0, 0, height or 50)
    Frame.BackgroundColor3 = Theme.Panel
    Frame.BorderSizePixel = 0
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
    local FStroke = Instance.new("UIStroke", Frame)
    FStroke.Color = Theme.Border
    FStroke.Thickness = 1

    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1, -20, 0, 30)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 15
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextColor3 = Theme.Text

    return Frame
end

local SWITCH_W = 50

--// ================= FEATURES: PLAYER =================

-- 1) SPEED
local SpeedFrame = createFeatureFrame(Content, "Speed")
local TEXTBOX_W, GAP = 60, 8

local SpeedSwitch = createSwitch(SpeedFrame, SWITCH_W, 26, 10)

local SpeedBox = Instance.new("TextBox", SpeedFrame)
SpeedBox.Size = UDim2.new(0, TEXTBOX_W, 0, 26)
SpeedBox.AnchorPoint = Vector2.new(1, 0.5)
SpeedBox.Position = UDim2.new(1, -(10 + SWITCH_W + GAP), 0.5, 0)
SpeedBox.BackgroundColor3 = Theme.Background
SpeedBox.Text = "16"
SpeedBox.ClearTextOnFocus = false
SpeedBox.Font = Enum.Font.GothamBold
SpeedBox.TextSize = 14
SpeedBox.TextColor3 = Theme.AccentBlue
Instance.new("UICorner", SpeedBox).CornerRadius = UDim.new(0, 6)

local speedEnabled = false
local originalWalkSpeed = nil

local function applySpeed(hum)
    if not (speedEnabled and hum) then return end
    local val = tonumber(SpeedBox.Text) or 16
    if val <= 0 then val = 16 end
    hum.WalkSpeed = val
end

SpeedSwitch:GetAttributeChangedSignal("Toggled"):Connect(function()
    speedEnabled = SpeedSwitch:GetAttribute("Toggled")
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

    if speedEnabled then
        if hum then
            originalWalkSpeed = originalWalkSpeed or hum.WalkSpeed
            applySpeed(hum)
        end
    elseif hum and originalWalkSpeed then
        hum.WalkSpeed = originalWalkSpeed
    end
end)

SpeedBox.FocusLost:Connect(function()
    applySpeed(LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"))
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if speedEnabled and hum then
        originalWalkSpeed = originalWalkSpeed or hum.WalkSpeed
        applySpeed(hum)
    end
end)

-- 2) NOCLIP
local NoclipFrame = createFeatureFrame(Content, "Noclip")
local NoclipSwitch = createSwitch(NoclipFrame, SWITCH_W, 26, 10)

local noclipConn = nil
local originalCollide = {}

local function setNoclip(char, enabled)
    if not char then return end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if enabled then
                if originalCollide[part] == nil then
                    originalCollide[part] = part.CanCollide
                end
                part.CanCollide = false
            elseif originalCollide[part] ~= nil then
                part.CanCollide = originalCollide[part]
            end
        end
    end

    if not enabled then
        originalCollide = {}
    end
end

NoclipSwitch:GetAttributeChangedSignal("Toggled"):Connect(function()
    local enabled = NoclipSwitch:GetAttribute("Toggled")

    if enabled then
        noclipConn = RunService.Stepped:Connect(function()
            setNoclip(LocalPlayer.Character, true)
        end)
    else
        if noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end
        setNoclip(LocalPlayer.Character, false)
    end
end)

-- 3) INFINITE JUMP
local IJFrame = createFeatureFrame(Content, "Infinite Jump")
local IJSwitch = createSwitch(IJFrame, SWITCH_W, 26, 10)
local ijConn = nil

IJSwitch:GetAttributeChangedSignal("Toggled"):Connect(function()
    local enabled = IJSwitch:GetAttribute("Toggled")

    if enabled and not ijConn then
        ijConn = UserInputService.JumpRequest:Connect(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    elseif not enabled and ijConn then
        ijConn:Disconnect()
        ijConn = nil
    end
end)

--// ================= FEATURE: FIX LAG =================
local FixLagFrame = createFeatureFrame(Content, "Fix Lag")
local FixLagSwitch = createSwitch(FixLagFrame, SWITCH_W, 26, 10)

local FixLag = {
    enabled = false,
    originalEnabled = {},   -- [instance] = bool (particles/lights/lighting effects)
    originalShadows = {},   -- [light instance] = bool
    originalCastShadow = {},-- [BasePart] = bool
    originalMaterial = {},  -- [BasePart] = Enum.Material
    originalLightingProps = nil,
    workspaceConn = nil,
    lightingConn = nil,
}

local function fixLagProcessEffect(inst)
    local class = inst.ClassName
    if classIn(FIXLAG_EFFECT_CLASSES, class) or classIn(FIXLAG_LIGHT_CLASSES, class) then
        if FixLag.originalEnabled[inst] == nil then
            FixLag.originalEnabled[inst] = inst.Enabled
        end
        inst.Enabled = false
    end

    if classIn(FIXLAG_LIGHT_CLASSES, class) then
        if FixLag.originalShadows[inst] == nil then
            local ok, val = pcall(function() return inst.Shadows end)
            if ok then FixLag.originalShadows[inst] = val end
        end
        pcall(function() inst.Shadows = false end)
    end
end

local function fixLagProcessLightingEffect(inst)
    if classIn(FIXLAG_LIGHTING_EFFECTS, inst.ClassName) then
        if FixLag.originalEnabled[inst] == nil then
            FixLag.originalEnabled[inst] = inst.Enabled
        end
        inst.Enabled = false
    end
end

local function fixLagProcessPart(part)
    if FixLag.originalCastShadow[part] == nil then
        FixLag.originalCastShadow[part] = part.CastShadow
    end
    part.CastShadow = false

    if part.Material == Enum.Material.Neon then
        if FixLag.originalMaterial[part] == nil then
            FixLag.originalMaterial[part] = part.Material
        end
        part.Material = Enum.Material.SmoothPlastic
    end
end

local function enableFixLag()
    FixLag.originalLightingProps = {
        GlobalShadows = Lighting.GlobalShadows,
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd,
    }
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e6

    for _, inst in ipairs(Workspace:GetDescendants()) do
        fixLagProcessEffect(inst)
        if inst:IsA("BasePart") then fixLagProcessPart(inst) end
    end
    for _, inst in ipairs(Lighting:GetChildren()) do
        fixLagProcessLightingEffect(inst)
    end

    -- xử lý hiệu ứng mới được thêm vào sau khi Fix Lag đã bật
    FixLag.workspaceConn = Workspace.DescendantAdded:Connect(function(inst)
        if not FixLag.enabled then return end
        fixLagProcessEffect(inst)
        if inst:IsA("BasePart") then fixLagProcessPart(inst) end
    end)
    FixLag.lightingConn = Lighting.ChildAdded:Connect(function(inst)
        if not FixLag.enabled then return end
        fixLagProcessLightingEffect(inst)
    end)
end

local function disableFixLag()
    if FixLag.workspaceConn then FixLag.workspaceConn:Disconnect(); FixLag.workspaceConn = nil end
    if FixLag.lightingConn then FixLag.lightingConn:Disconnect(); FixLag.lightingConn = nil end

    for inst, val in pairs(FixLag.originalEnabled) do
        if inst and inst.Parent then pcall(function() inst.Enabled = val end) end
    end
    for inst, val in pairs(FixLag.originalShadows) do
        if inst and inst.Parent then pcall(function() inst.Shadows = val end) end
    end
    for part, val in pairs(FixLag.originalCastShadow) do
        if part and part.Parent then part.CastShadow = val end
    end
    for part, val in pairs(FixLag.originalMaterial) do
        if part and part.Parent then part.Material = val end
    end
    if FixLag.originalLightingProps then
        Lighting.GlobalShadows = FixLag.originalLightingProps.GlobalShadows
        Lighting.FogStart = FixLag.originalLightingProps.FogStart
        Lighting.FogEnd = FixLag.originalLightingProps.FogEnd
        FixLag.originalLightingProps = nil
    end

    table.clear(FixLag.originalEnabled)
    table.clear(FixLag.originalShadows)
    table.clear(FixLag.originalCastShadow)
    table.clear(FixLag.originalMaterial)
end

FixLagSwitch:GetAttributeChangedSignal("Toggled"):Connect(function()
    FixLag.enabled = FixLagSwitch:GetAttribute("Toggled")
    if FixLag.enabled then enableFixLag() else disableFixLag() end
end)

--// ================= FEATURE: FULL BRIGHT =================
local FullBrightFrame = createFeatureFrame(Content, "Full Bright")
local FullBrightSwitch = createSwitch(FullBrightFrame, SWITCH_W, 26, 10)

local FullBright = { originalProps = nil }

local function enableFullBright()
    FullBright.originalProps = {
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ExposureCompensation = Lighting.ExposureCompensation,
        GlobalShadows = Lighting.GlobalShadows,
    }
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(140, 140, 140)
    Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 140)
    Lighting.ExposureCompensation = 0.5
    Lighting.GlobalShadows = false
end

local function disableFullBright()
    if not FullBright.originalProps then return end
    local p = FullBright.originalProps
    Lighting.Brightness = p.Brightness
    Lighting.Ambient = p.Ambient
    Lighting.OutdoorAmbient = p.OutdoorAmbient
    Lighting.ExposureCompensation = p.ExposureCompensation
    Lighting.GlobalShadows = p.GlobalShadows
    FullBright.originalProps = nil
end

FullBrightSwitch:GetAttributeChangedSignal("Toggled"):Connect(function()
    if FullBrightSwitch:GetAttribute("Toggled") then
        enableFullBright()
    else
        disableFullBright()
    end
end)

--// ================= FEATURE: PLAYER ESP =================
local ESPFrame = createFeatureFrame(Content, "Player ESP")
local ESPSwitch = createSwitch(ESPFrame, SWITCH_W, 26, 10)

local ESPTeamFrame = createFeatureFrame(Content, "ESP: Chỉ Team Đối Địch")
local ESPTeamSwitch = createSwitch(ESPTeamFrame, SWITCH_W, 26, 10)

local ESP = {
    enabled = false,
    teamOnly = false,
    visuals = {},          -- [player] = {highlight, billboard, healthConn}
    characterConns = {},   -- [player] = CharacterAdded connection
    playerAddedConn = nil,
    playerRemovingConn = nil,
    heartbeatConn = nil,
    accumulator = 0,
}

local function espColorFor(player)
    if player.Team and LocalPlayer.Team then
        return player.Team == LocalPlayer.Team and ESPConfig.AllyColor or ESPConfig.EnemyColor
    end
    return ESPConfig.NeutralColor
end

local function espShouldShow(player)
    if player == LocalPlayer then return false end
    if not ESP.teamOnly then return true end
    if player.Team and LocalPlayer.Team then
        return player.Team ~= LocalPlayer.Team
    end
    return true -- không xác định được team thì mặc định vẫn hiển thị
end

local function espRemoveVisual(player)
    local data = ESP.visuals[player]
    if not data then return end

    if data.healthConn then data.healthConn:Disconnect() end
    if data.highlight then data.highlight:Destroy() end
    if data.billboard then data.billboard:Destroy() end

    ESP.visuals[player] = nil
end

local function espCreateVisual(player, char)
    if ESP.visuals[player] then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not (hum and hrp) then return end

    local color = espColorFor(player)

    local highlight = Instance.new("Highlight")
    highlight.Name = "MG_ESP_Highlight"
    highlight.Adornee = char
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.8
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "MG_ESP_Billboard"
    billboard.Adornee = hrp
    billboard.Size = UDim2.new(0, 160, 0, 56)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = char

    local NameLabel = Instance.new("TextLabel", billboard)
    NameLabel.Size = UDim2.new(1, 0, 0, 18)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextSize = 14
    NameLabel.TextColor3 = color
    NameLabel.Text = player.Name

    local DistanceLabel = Instance.new("TextLabel", billboard)
    DistanceLabel.Size = UDim2.new(1, 0, 0, 14)
    DistanceLabel.Position = UDim2.new(0, 0, 0, 18)
    DistanceLabel.BackgroundTransparency = 1
    DistanceLabel.Font = Enum.Font.Gotham
    DistanceLabel.TextSize = 12
    DistanceLabel.TextColor3 = Theme.SubText
    DistanceLabel.Text = "-- m"

    local BarBg = Instance.new("Frame", billboard)
    BarBg.Size = UDim2.new(1, 0, 0, 6)
    BarBg.Position = UDim2.new(0, 0, 0, 36)
    BarBg.BackgroundColor3 = ESPConfig.BarBackground
    BarBg.BorderSizePixel = 0
    Instance.new("UICorner", BarBg).CornerRadius = UDim.new(1, 0)

    local BarFill = Instance.new("Frame", BarBg)
    BarFill.Size = UDim2.new(1, 0, 1, 0)
    BarFill.BackgroundColor3 = Theme.Success
    BarFill.BorderSizePixel = 0
    Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)

    local HealthLabel = Instance.new("TextLabel", billboard)
    HealthLabel.Size = UDim2.new(1, 0, 0, 14)
    HealthLabel.Position = UDim2.new(0, 0, 0, 42)
    HealthLabel.BackgroundTransparency = 1
    HealthLabel.Font = Enum.Font.Gotham
    HealthLabel.TextSize = 12
    HealthLabel.TextColor3 = Theme.Text
    HealthLabel.Text = "--/--"

    local healthConn = hum.Died:Connect(function()
        espRemoveVisual(player)
    end)

    ESP.visuals[player] = {
        highlight = highlight,
        billboard = billboard,
        healthConn = healthConn,
        hum = hum,
        hrp = hrp,
        distanceLabel = DistanceLabel,
        healthLabel = HealthLabel,
        barFill = BarFill,
    }
end

local function espRefreshVisual(player)
    espRemoveVisual(player)
    if ESP.enabled and espShouldShow(player) and player.Character then
        espCreateVisual(player, player.Character)
    end
end

local function espAttachPlayer(player)
    if player == LocalPlayer then return end

    ESP.characterConns[player] = player.CharacterAdded:Connect(function(char)
        espRemoveVisual(player)
        if ESP.enabled and espShouldShow(player) then
            char:WaitForChild("HumanoidRootPart", 5)
            espCreateVisual(player, char)
        end
    end)

    if ESP.enabled and espShouldShow(player) and player.Character then
        espCreateVisual(player, player.Character)
    end
end

local function espDetachPlayer(player)
    espRemoveVisual(player)
    if ESP.characterConns[player] then
        ESP.characterConns[player]:Disconnect()
        ESP.characterConns[player] = nil
    end
end

local function espUpdateLoop(dt)
    ESP.accumulator += dt
    if ESP.accumulator < ESPConfig.UpdateInterval then return end
    ESP.accumulator = 0

    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    for player, data in pairs(ESP.visuals) do
        if data.hum and data.hum.Parent and data.hrp and data.hrp.Parent then
            local health = math.max(data.hum.Health, 0)
            local maxHealth = data.hum.MaxHealth
            data.healthLabel.Text = string.format("%d/%d", health, maxHealth)
            data.barFill.Size = UDim2.new(maxHealth > 0 and (health / maxHealth) or 0, 0, 1, 0)

            if myHrp then
                local dist = (myHrp.Position - data.hrp.Position).Magnitude
                data.distanceLabel.Text = string.format("%d m", dist)
            end
        else
            espRemoveVisual(player)
        end
    end
end

local function enableESP()
    ESP.enabled = true

    for _, player in ipairs(Players:GetPlayers()) do
        espAttachPlayer(player)
    end

    ESP.playerAddedConn = Players.PlayerAdded:Connect(espAttachPlayer)
    ESP.playerRemovingConn = Players.PlayerRemoving:Connect(espDetachPlayer)
    ESP.heartbeatConn = RunService.Heartbeat:Connect(espUpdateLoop)
end

local function disableESP()
    ESP.enabled = false

    if ESP.playerAddedConn then ESP.playerAddedConn:Disconnect(); ESP.playerAddedConn = nil end
    if ESP.playerRemovingConn then ESP.playerRemovingConn:Disconnect(); ESP.playerRemovingConn = nil end
    if ESP.heartbeatConn then ESP.heartbeatConn:Disconnect(); ESP.heartbeatConn = nil end

    for player, _ in pairs(ESP.characterConns) do
        espDetachPlayer(player)
    end
end

ESPSwitch:GetAttributeChangedSignal("Toggled"):Connect(function()
    if ESPSwitch:GetAttribute("Toggled") then enableESP() else disableESP() end
end)

ESPTeamSwitch:GetAttributeChangedSignal("Toggled"):Connect(function()
    ESP.teamOnly = ESPTeamSwitch:GetAttribute("Toggled")
    if ESP.enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            espRefreshVisual(player)
        end
    end
end)

--// ================= INITIAL APPEARANCE =================
popIn()
