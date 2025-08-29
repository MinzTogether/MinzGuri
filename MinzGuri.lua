local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- cleanup
if CoreGui:FindFirstChild("MinzyGuriUI") then
    CoreGui.MinzyGuriUI:Destroy()
end

-- config
local UI_W, UI_H = 600, 400
local CENTER_POS = UDim2.new(0.5, -UI_W/2, 0.5, -UI_H/2)
local TWEEN_TIME = 0.28

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MinzyGuriUI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main UI
local MainUI = Instance.new("Frame")
MainUI.Name = "MG_Main"
MainUI.Size = UDim2.new(0, UI_W, 0, UI_H)
MainUI.Position = CENTER_POS
MainUI.BackgroundColor3 = Color3.fromRGB(255,192,203)
MainUI.BackgroundTransparency = 0.3
MainUI.BorderSizePixel = 0
MainUI.Parent = ScreenGui
Instance.new("UICorner", MainUI).CornerRadius = UDim.new(0,12)
local UIStroke = Instance.new("UIStroke", MainUI)
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(255,105,180)

-- Header
local Header = Instance.new("Frame", MainUI)
Header.Size = UDim2.new(1, 0, 0, 36)
Header.BackgroundColor3 = Color3.fromRGB(255,105,180)
Header.BorderSizePixel = 0
Header.Active = true
Instance.new("UICorner", Header).CornerRadius = UDim.new(0,10)

local HeaderTitle = Instance.new("TextLabel", Header)
HeaderTitle.Size = UDim2.new(1, -80, 1, 0)
HeaderTitle.Position = UDim2.new(0, 12, 0, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "MinzGuri"
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.TextSize = 16
HeaderTitle.TextColor3 = Color3.fromRGB(255,255,255)
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Close Btn (vuông bo nhẹ)
local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0,28,0,28)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,6)

-- Toggle button (ẩn/hiện UI)
local ToggleButton = Instance.new("ImageButton")
ToggleButton.Name = "MG_Toggle"
ToggleButton.Size = UDim2.new(0,50,0,50)
ToggleButton.Position = UDim2.new(0, 20, 0.5, -25)
ToggleButton.BackgroundColor3 = Color3.fromRGB(255,105,180)
ToggleButton.Image = "rbxassetid://3926305904"
ToggleButton.ImageRectOffset = Vector2.new(764,44)
ToggleButton.ImageRectSize = Vector2.new(36,36)
ToggleButton.Parent = ScreenGui
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0,12)

-- Confirm Box
local ConfirmBox = Instance.new("Frame", ScreenGui)
ConfirmBox.Size = UDim2.new(0,300,0,150)
ConfirmBox.Position = UDim2.new(0.5, -150, 0.5, -75)
ConfirmBox.BackgroundColor3 = Color3.fromRGB(173,216,230)
ConfirmBox.Visible = false
Instance.new("UICorner", ConfirmBox).CornerRadius = UDim.new(0,12)
local CStroke = Instance.new("UIStroke", ConfirmBox)
CStroke.Color = Color3.fromRGB(0,0,139)

local ConfirmText = Instance.new("TextLabel", ConfirmBox)
ConfirmText.Size = UDim2.new(1,-20,0,60)
ConfirmText.Position = UDim2.new(0,10,0,10)
ConfirmText.BackgroundTransparency = 1
ConfirmText.Text = "Bạn có muốn tắt script không?"
ConfirmText.Font = Enum.Font.GothamBold
ConfirmText.TextSize = 18
ConfirmText.TextColor3 = Color3.fromRGB(255,255,255)

local YesBtn = Instance.new("TextButton", ConfirmBox)
YesBtn.Size = UDim2.new(0.4,0,0,40)
YesBtn.Position = UDim2.new(0.05,0,0.6,0)
YesBtn.BackgroundColor3 = Color3.fromRGB(144,238,144)
YesBtn.Text = "Có"
YesBtn.Font = Enum.Font.GothamBold
YesBtn.TextSize = 18
YesBtn.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", YesBtn).CornerRadius = UDim.new(0,8)

local NoBtn = Instance.new("TextButton", ConfirmBox)
NoBtn.Size = UDim2.new(0.4,0,0,40)
NoBtn.Position = UDim2.new(0.55,0,0.6,0)
NoBtn.BackgroundColor3 = Color3.fromRGB(255,182,193)
NoBtn.Text = "Không"
NoBtn.Font = Enum.Font.GothamBold
NoBtn.TextSize = 18
NoBtn.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", NoBtn).CornerRadius = UDim.new(0,8)

CloseBtn.MouseButton1Click:Connect(function()
    ConfirmBox.Visible = true
end)
YesBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
NoBtn.MouseButton1Click:Connect(function()
    ConfirmBox.Visible = false
end)

-- Main Layout
local LeftCol = Instance.new("ScrollingFrame", MainUI)
LeftCol.Size = UDim2.new(0.25,0,1,-36)
LeftCol.Position = UDim2.new(0,0,0,36)
LeftCol.BackgroundTransparency = 1
LeftCol.ScrollBarThickness = 6
LeftCol.CanvasSize = UDim2.new(0,0,0,0)

local RightCol = Instance.new("Frame", MainUI)
RightCol.Size = UDim2.new(0.75,0,1,-36)
RightCol.Position = UDim2.new(0.25,0,0,36)
RightCol.BackgroundTransparency = 1

-- Tab system
local TabButtons = {}
local TabContents = {}

local Tabs = {
    {Name="Info", Icon="ℹ️"},
    {Name="Player", Icon="👤"},
    {Name="Main", Icon="🏠"},
    {Name="Shop", Icon="🛒"},
    {Name="Pet", Icon="🐶"},
    {Name="Farm", Icon="🌾"},
    {Name="Performance", Icon="⚡"},
    {Name="Ui", Icon="🖥️"},
    {Name="Webhook", Icon="🌐"},
}

local TabList = Instance.new("UIListLayout", LeftCol)
TabList.FillDirection = Enum.FillDirection.Vertical
TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabList.VerticalAlignment = Enum.VerticalAlignment.Top
TabList.Padding = UDim.new(0,10)

for _,tab in ipairs(Tabs) do
    local Btn = Instance.new("TextButton", LeftCol)
    Btn.Size = UDim2.new(1,-20,0,40)
    Btn.BackgroundColor3 = Color3.fromRGB(255,182,193)
    Btn.BackgroundTransparency = 0.3
    Btn.Text = tab.Icon.." "..tab.Name
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 16
    Btn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0,8)

    local Content = Instance.new("ScrollingFrame", RightCol)
    Content.Size = UDim2.new(1,-20,1,-20)
    Content.Position = UDim2.new(0,10,0,10)
    Content.BackgroundColor3 = Color3.fromRGB(255,182,193)
    Content.BackgroundTransparency = 0.3
    Content.BorderSizePixel = 0
    Content.ClipsDescendants = true
    Content.ScrollBarThickness = 8
    Content.CanvasSize = UDim2.new(0,0,0,0) -- auto-expand Y
    Content.ScrollBarImageTransparency = 0.6
    Instance.new("UICorner", Content).CornerRadius = UDim.new(0,12)
    local CStroke = Instance.new("UIStroke", Content)
    CStroke.Color = Color3.fromRGB(255,105,180)

    local ContentLayout = Instance.new("UIListLayout", Content)
    ContentLayout.FillDirection = Enum.FillDirection.Vertical
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Padding = UDim.new(0,10)

    -- padding đầu
    local ContentPadding = Instance.new("Frame", Content)
    ContentPadding.Size = UDim2.new(1,-20,0,0)
    ContentPadding.BackgroundTransparency = 1
    ContentPadding.LayoutOrder = 0
    ContentPadding.Name = "InnerPadding"

    Content.Visible = false

    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local absY = ContentLayout.AbsoluteContentSize.Y
        Content.CanvasSize = UDim2.new(0, 0, 0, absY + 20)
    end)

    Btn.MouseButton1Click:Connect(function()
        for _,c in pairs(TabContents) do
            if c.Visible then
                TweenService:Create(c, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
                task.delay(0.25, function() c.Visible = false end)
            end
        end
        Content.Visible = true
        Content.BackgroundTransparency = 1
        TweenService:Create(Content, TweenInfo.new(0.25), {BackgroundTransparency = 0.3}):Play()
    end)

    table.insert(TabButtons, Btn)
    table.insert(TabContents, Content)
end

-- Set initial
TabContents[1].Visible = true

TabList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    LeftCol.CanvasSize = UDim2.new(0,0,0,TabList.AbsoluteContentSize.Y + 20)
end)

-- Drag function
local function makeDraggable(handle, target)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
makeDraggable(Header, MainUI)
makeDraggable(ToggleButton, ToggleButton)

-- Toggle UI
local isUIVisible = true
local lastPos = MainUI.Position
ToggleButton.MouseButton1Click:Connect(function()
    if isUIVisible then
        lastPos = MainUI.Position
        TweenService:Create(MainUI, TweenInfo.new(TWEEN_TIME), {Position = UDim2.new(lastPos.X.Scale,lastPos.X.Offset,-1,-UI_H)}):Play()
    else
        TweenService:Create(MainUI, TweenInfo.new(TWEEN_TIME), {Position = lastPos}):Play()
    end
    isUIVisible = not isUIVisible
end)

---------------------------------------------------------
-- SWITCH TOGGLE (cần gạt) — size tuyệt đối cho đẹp, mặc định 56x28
local function createSwitch(parent, pxW, pxH, rightOffset)
    pxW = pxW or 56
    pxH = pxH or 28
    rightOffset = rightOffset or 10

    local Switch = Instance.new("TextButton", parent)
    Switch.Size = UDim2.new(0, pxW, 0, pxH)
    Switch.AnchorPoint = Vector2.new(1,0.5)
    Switch.Position = UDim2.new(1, -rightOffset, 0.5, 0)
    Switch.BackgroundColor3 = Color3.fromRGB(200,50,50)
    Switch.Text = ""
    Switch.AutoButtonColor = false
    Instance.new("UICorner", Switch).CornerRadius = UDim.new(1,0)

    local Knob = Instance.new("Frame", Switch)
    Knob.Size = UDim2.new(0, pxW/2 - 4, 0, pxH - 4)
    Knob.Position = UDim2.new(0,2,0,2)
    Knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    Knob.BorderSizePixel = 0
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1,0)

    local state = false
    Switch:SetAttribute("Toggled", state)

    Switch.MouseButton1Click:Connect(function()
        state = not state
        Switch:SetAttribute("Toggled", state)
        if state then
            TweenService:Create(Switch, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(50,200,50)}):Play()
            TweenService:Create(Knob, TweenInfo.new(0.18), {Position = UDim2.new(0, pxW/2, 0, 2)}):Play()
        else
            TweenService:Create(Switch, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(200,50,50)}):Play()
            TweenService:Create(Knob, TweenInfo.new(0.18), {Position = UDim2.new(0, 2, 0, 2)}):Play()
        end
    end)

    return Switch
end

-- Tạo khung tính năng (label trái, control sẽ tự thêm ở phải)
local function createFeatureFrame(parent, title)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1,-40,0,56)
    Frame.Position = UDim2.new(0.5,0,0,0)
    Frame.AnchorPoint = Vector2.new(0.5,0)
    Frame.BackgroundColor3 = Color3.fromRGB(255,192,203)
    Frame.BackgroundTransparency = 0.2
    Frame.BorderSizePixel = 0
    Frame.LayoutOrder = 1
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0,8)

    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1,-20,1,0)
    Label.Position = UDim2.new(0,10,0,0)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 16
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextColor3 = Color3.fromRGB(255,255,255)

    return Frame, Label
end

-- Lấy content của tab Player
local playerContent
for i,tab in ipairs(Tabs) do
    if tab.Name == "Player" then
        playerContent = TabContents[i]
        break
    end
end

if playerContent then
    ----------------------------------------------------------------
    -- 1) SPEED: TextBox + Switch Apply (bật = set speed, tắt = trả speed gốc)
    local SpeedFrame = createFeatureFrame(playerContent, "Speed")
    local TEXTBOX_W, TEXTBOX_H = 110, 28
    local SWITCH_W = 56
    local GAP = 8
    -- Switch ở sát phải, TextBox nằm bên trái Switch một khoảng GAP
    local SpeedSwitch = createSwitch(SpeedFrame, SWITCH_W, 28, 10)

    local SpeedBox = Instance.new("TextBox", SpeedFrame)
    SpeedBox.Size = UDim2.new(0, TEXTBOX_W, 0, TEXTBOX_H)
    SpeedBox.AnchorPoint = Vector2.new(1,0.5)
    SpeedBox.Position = UDim2.new(1, -(10 + SWITCH_W + GAP), 0.5, 0)
    SpeedBox.BackgroundColor3 = Color3.fromRGB(255,105,180)
    SpeedBox.Text = "16"
    SpeedBox.ClearTextOnFocus = false
    SpeedBox.Font = Enum.Font.GothamBold
    SpeedBox.TextSize = 16
    SpeedBox.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", SpeedBox).CornerRadius = UDim.new(0,6)

    local speedEnabled = false
    local originalWalkSpeed = nil
    local function applySpeedIfEnabled(hum)
        if speedEnabled and hum then
            local val = tonumber(SpeedBox.Text) or 16
            if val <= 0 then val = 16 end
            hum.WalkSpeed = val
        end
    end

    -- Theo dõi bật/tắt switch
    SpeedSwitch:GetAttributeChangedSignal("Toggled"):Connect(function()
        speedEnabled = SpeedSwitch:GetAttribute("Toggled")
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if speedEnabled then
            if hum then
                -- nhớ speed gốc 1 lần khi bật
                if originalWalkSpeed == nil then
                    originalWalkSpeed = hum.WalkSpeed
                end
                applySpeedIfEnabled(hum)
            end
        else
            -- trả về speed gốc nếu có
            if hum and originalWalkSpeed ~= nil then
                hum.WalkSpeed = originalWalkSpeed
            end
        end
    end)

    -- Khi người chơi respawn: nếu switch đang bật thì áp lại speed
    LocalPlayer.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 5)
        task.spawn(function()
            if speedEnabled and hum then
                -- nếu chưa có speed gốc (VD join lần đầu bật ngay), lấy tạm mặc định
                if originalWalkSpeed == nil then
                    originalWalkSpeed = hum.WalkSpeed
                end
                applySpeedIfEnabled(hum)
            end
        end)
    end)

    -- Nếu đang bật, thay đổi số trong TextBox sẽ apply ngay
    SpeedBox.FocusLost:Connect(function(enterPressed)
        if speedEnabled then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then applySpeedIfEnabled(hum) end
        end
    end)

    ----------------------------------------------------------------
    -- 2) NOCLIP: Switch
    local NoclipFrame = createFeatureFrame(playerContent, "Noclip")
    local NoclipSwitch = createSwitch(NoclipFrame, 56, 28, 10)
    local noclipConn = nil

    local function setCharacterCollision(char, collide)
        if not char then return end
        for _,v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                -- chỉ khôi phục HRP khi tắt, hạn chế phá default của các phần khác
                if collide then
                    if v.Name == "HumanoidRootPart" then v.CanCollide = true end
                else
                    v.CanCollide = false
                end
            end
        end
    end

    NoclipSwitch:GetAttributeChangedSignal("Toggled"):Connect(function()
        local enabled = NoclipSwitch:GetAttribute("Toggled")
        if enabled then
            -- bật: mỗi frame tắt va chạm
            noclipConn = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if char then setCharacterCollision(char, false) end
            end)
        else
            -- tắt: ngắt kết nối + bật lại collide cho HRP
            if noclipConn then noclipConn:Disconnect() noclipConn = nil end
            local char = LocalPlayer.Character
            setCharacterCollision(char, true)
        end
    end)

    ----------------------------------------------------------------
    -- 3) INFINITE JUMP: Switch
    local IJFrame = createFeatureFrame(playerContent, "Infinite Jump")
    local IJSwitch = createSwitch(IJFrame, 56, 28, 10)
    local ijConn = nil

    IJSwitch:GetAttributeChangedSignal("Toggled"):Connect(function()
        local enabled = IJSwitch:GetAttribute("Toggled")
        if enabled then
            if not ijConn then
                ijConn = UserInputService.JumpRequest:Connect(function()
                    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end)
            end
        else
            if ijConn then ijConn:Disconnect() ijConn = nil end
        end
    end)
end
