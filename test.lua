local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
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
Header.Position = UDim2.new(0,0,0,0)
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

-- Close Btn
local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0,28,0,28)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,6)

-- Toggle button
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
ConfirmBox.BackgroundTransparency = 1
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

-- Fade helper
local function fadeUI(frame, fadeIn)
    local goal = fadeIn and 0.3 or 1
    TweenService:Create(frame, TweenInfo.new(TWEEN_TIME), {BackgroundTransparency = goal}):Play()
    for _,child in ipairs(frame:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            TweenService:Create(child, TweenInfo.new(TWEEN_TIME), {
                TextTransparency = fadeIn and 0 or 1
            }):Play()
        elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
            TweenService:Create(child, TweenInfo.new(TWEEN_TIME), {
                ImageTransparency = fadeIn and 0 or 1
            }):Play()
        elseif child:IsA("Frame") then
            TweenService:Create(child, TweenInfo.new(TWEEN_TIME), {
                BackgroundTransparency = fadeIn and 0.3 or 1
            }):Play()
        end
    end
end

-- Confirm show/hide
local function showConfirm()
    ConfirmBox.Visible = true
    fadeUI(ConfirmBox, true)
end
local function hideConfirm()
    fadeUI(ConfirmBox, false)
    task.delay(TWEEN_TIME, function()
        if ConfirmBox then ConfirmBox.Visible = false end
    end)
end

CloseBtn.MouseButton1Click:Connect(showConfirm)
YesBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
NoBtn.MouseButton1Click:Connect(hideConfirm)

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
    Content.CanvasSize = UDim2.new(0,0,0,0)
    Content.AutomaticCanvasSize = Enum.AutomaticSize.None
    Content.ScrollBarImageTransparency = 0.6
    Instance.new("UICorner", Content).CornerRadius = UDim.new(0,12)
    local CStroke = Instance.new("UIStroke", Content)
    CStroke.Color = Color3.fromRGB(255,105,180)

    local ContentLayout = Instance.new("UIListLayout", Content)
    ContentLayout.FillDirection = Enum.FillDirection.Vertical
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Padding = UDim.new(0,10)

    local ContentPadding = Instance.new("Frame", Content)
    ContentPadding.Size = UDim2.new(1,-20,0,0)
    ContentPadding.BackgroundTransparency = 1
    ContentPadding.LayoutOrder = 0
    ContentPadding.Name = "InnerPadding"

    local Label = Instance.new("TextLabel", Content)
    Label.Size = UDim2.new(1,-20,0,150)
    Label.BackgroundTransparency = 1
    Label.Text = tab.Name.." Content"
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 18
    Label.TextColor3 = Color3.fromRGB(255,105,180)
    Label.TextXAlignment = Enum.TextXAlignment.Center
    Label.TextYAlignment = Enum.TextYAlignment.Center
    Label.LayoutOrder = 1

    Content.Visible = false

    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local absY = ContentLayout.AbsoluteContentSize.Y
        Content.CanvasSize = UDim2.new(0, 0, 0, absY + 20)
    end)

    Btn.MouseButton1Click:Connect(function()
        for _,c in pairs(TabContents) do
            if c.Visible then
                fadeUI(c, false)
                task.delay(TWEEN_TIME, function() c.Visible = false end)
            end
        end
        Content.Visible = true
        fadeUI(Content, true)
    end)

    table.insert(TabButtons, Btn)
    table.insert(TabContents, Content)
end

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

-- Toggle UI with fade
local isUIVisible = true
ToggleButton.MouseButton1Click:Connect(function()
    if isUIVisible then
        fadeUI(MainUI, false)
        task.delay(TWEEN_TIME, function() MainUI.Visible = false end)
    else
        MainUI.Visible = true
        fadeUI(MainUI, true)
    end
    isUIVisible = not isUIVisible
end)
