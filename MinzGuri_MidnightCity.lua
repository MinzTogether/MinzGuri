--// Services
local CoreGui          = game:GetService("CoreGui")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

--// Cleanup previous instance
if CoreGui:FindFirstChild("MinzyGuriUI") then
    CoreGui.MinzyGuriUI:Destroy()
end

--// ================= THEME: Midnight City (VSCode) =================
local Theme = {
    Background   = Color3.fromRGB(26, 27, 38),   -- #1A1B26
    Panel        = Color3.fromRGB(36, 40, 59),   -- #24283B
    Header       = Color3.fromRGB(30, 32, 48),   -- slightly darker than panel
    Border       = Color3.fromRGB(65, 72, 104),  -- #414868
    AccentBlue   = Color3.fromRGB(122, 162, 247),-- #7AA2F7
    AccentPurple = Color3.fromRGB(187, 154, 247),-- #BB9AF7
    Text         = Color3.fromRGB(192, 202, 245),-- #C0CAF5
    SubText      = Color3.fromRGB(120, 130, 170),
    Success      = Color3.fromRGB(158, 206, 106),-- #9ECE6A
    Danger       = Color3.fromRGB(247, 118, 142),-- #F7768E
}

--// ================= CONFIG =================
local UI_W, UI_H   = 340, 300
local TWEEN_TIME   = 0.25
local CENTER_POS   = UDim2.new(0.5, -UI_W / 2, 0.5, -UI_H / 2)

--// ================= ROOT =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MinzyGuriUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

--// ================= MAIN WINDOW =================
local MainUI = Instance.new("Frame")
MainUI.Name = "MG_Main"
MainUI.Size = UDim2.new(0, UI_W, 0, UI_H)
MainUI.Position = CENTER_POS
MainUI.BackgroundColor3 = Theme.Background
MainUI.BorderSizePixel = 0
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

-- mask the bottom corners of the header so it looks flush with the body
local HeaderMask = Instance.new("Frame", Header)
HeaderMask.Size = UDim2.new(1, 0, 0, 10)
HeaderMask.Position = UDim2.new(0, 0, 1, -10)
HeaderMask.BackgroundColor3 = Theme.Header
HeaderMask.BorderSizePixel = 0
HeaderMask.ZIndex = Header.ZIndex

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
local ToggleStroke = Instance.new("UIStroke", ToggleButton)
ToggleStroke.Color = Theme.Border

--// Confirm-close dialog
local ConfirmBox = Instance.new("Frame", ScreenGui)
ConfirmBox.Size = UDim2.new(0, 260, 0, 130)
ConfirmBox.Position = UDim2.new(0.5, -130, 0.5, -65)
ConfirmBox.BackgroundColor3 = Theme.Panel
ConfirmBox.Visible = false
Instance.new("UICorner", ConfirmBox).CornerRadius = UDim.new(0, 10)
local ConfirmStroke = Instance.new("UIStroke", ConfirmBox)
ConfirmStroke.Color = Theme.AccentPurple

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

--// Show/hide main window
local isUIVisible = true
local lastPos = MainUI.Position

ToggleButton.MouseButton1Click:Connect(function()
    if isUIVisible then
        lastPos = MainUI.Position
        TweenService:Create(MainUI, TweenInfo.new(TWEEN_TIME), {
            Position = UDim2.new(lastPos.X.Scale, lastPos.X.Offset, -1, -UI_H)
        }):Play()
    else
        TweenService:Create(MainUI, TweenInfo.new(TWEEN_TIME), { Position = lastPos }):Play()
    end
    isUIVisible = not isUIVisible
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

local function createFeatureFrame(parent, title)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, 0, 0, 50)
    Frame.BackgroundColor3 = Theme.Panel
    Frame.BorderSizePixel = 0
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
    local FStroke = Instance.new("UIStroke", Frame)
    FStroke.Color = Theme.Border
    FStroke.Thickness = 1

    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1, -20, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 15
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextColor3 = Theme.Text

    return Frame
end

--// ================= FEATURES =================

-- 1) SPEED
local SpeedFrame = createFeatureFrame(Content, "Speed")
local SWITCH_W, TEXTBOX_W, GAP = 50, 60, 8

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
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    applySpeed(hum)
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if speedEnabled and hum then
        originalWalkSpeed = originalWalkSpeed or hum.WalkSpeed
        applySpeed(hum)
    end
end)

-- 2) NOCLIP (fixed: restores each part's original CanCollide, not just the HRP)
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
