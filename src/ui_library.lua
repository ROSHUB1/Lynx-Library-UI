-- Improved UI Library (place as ModuleScript or save as src/ui_library.lua)
pcall(function()
    if game:GetService('CoreGui'):FindFirstChild('ui') then
        game:GetService('CoreGui'):FindFirstChild('ui'):Destroy()
    end
end)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local Library = {}
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local function detectDevice()
    if UserInputService.TouchEnabled then
        return "Mobile"
    else
        return "Desktop"
    end
end

local DefaultTheme = {
    MainBg = Color3.fromRGB(30, 30, 30),
    TopBg = Color3.fromRGB(24, 24, 24),
    TabsBg = Color3.fromRGB(33, 33, 33),
    Accent = Color3.fromRGB(232, 17, 85),
    AccentDark = Color3.fromRGB(186, 13, 68),
    PrimaryText = Color3.fromRGB(255, 255, 255),
    SecondaryText = Color3.fromRGB(166, 166, 166),
    Fill = Color3.fromRGB(35, 35, 35),
    Highlight = Color3.fromRGB(160, 12, 59),
}

local function tweenObject(obj, props, time, style, dir)
    style = style or Enum.EasingStyle.Quad
    dir = dir or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(time, style, dir), props):Play()
end

local function applyThemeToWindow(win, theme)
    if not win or not win.Main then return end
    local Main = win.Main
    local Top = win.Top
    local Tabs = win.Tabs
    local Pages = win.Pages
    local Logo = win.Logo
    local GameName = win.GameName
    local MinimizedIcon = win.MinimizedIcon

    Main.BackgroundColor3 = theme.MainBg
    Top.BackgroundColor3 = theme.TopBg
    if Top:FindFirstChild("Cover") then
        Top.Cover.BackgroundColor3 = theme.TopBg
    end
    Tabs.BackgroundColor3 = theme.TabsBg
    if Tabs:FindFirstChild("Cover") then
        Tabs.Cover.BackgroundColor3 = theme.TabsBg
    end
    Pages.BackgroundColor3 = theme.MainBg

    pcall(function() Logo.ImageColor3 = theme.Accent end)
    if GameName then GameName.TextColor3 = theme.Accent end
    if MinimizedIcon then MinimizedIcon.BackgroundColor3 = theme.Accent end

    for _, btn in ipairs(win.TabsContainer:GetChildren()) do
        if btn.Name == "TabButton" then
            btn.BackgroundTransparency = 1
            if btn:FindFirstChild("TabContent") and btn.TabContent:FindFirstChild("TextLabel") then
                btn.TabContent.TextLabel.TextColor3 = theme.SecondaryText
            end
        end
    end

    for _, page in ipairs(win.Pages:GetChildren()) do
        if page:IsA("ScrollingFrame") then
            for _, child in ipairs(page:GetChildren()) do
                if child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("Frame") then
                    if child.Name == "Button" then
                        child.BackgroundColor3 = theme.Highlight
                        if child:IsA("TextButton") then child.TextColor3 = theme.PrimaryText end
                    elseif child.Name == "Label" then
                        child.BackgroundColor3 = theme.Fill
                        child.TextColor3 = theme.PrimaryText
                    elseif child.Name == "Toggle" then
                        child.BackgroundColor3 = theme.Fill
                        if child:FindFirstChild("Title") then child.Title.TextColor3 = theme.PrimaryText end
                        if child:FindFirstChild("ToggleFrame") then
                            child.ToggleFrame.BackgroundColor3 = theme.Highlight
                            if child.ToggleFrame:FindFirstChild("UIStroke") then
                                child.ToggleFrame.UIStroke.Color = theme.Highlight
                            end
                        end
                    elseif child.Name == "Slider" then
                        child.BackgroundColor3 = theme.Fill
                        if child:FindFirstChild("SliderClick") then child.SliderClick.BackgroundColor3 = Color3.fromRGB(52,52,52) end
                        if child:FindFirstChild("SliderDrag") then child.SliderDrag.BackgroundColor3 = theme.AccentDark end
                    elseif child.Name == "InputBox" then
                        child.BackgroundColor3 = theme.Fill
                        if child:FindFirstChild("Box") then
                            child.Box.BackgroundColor3 = Color3.fromRGB(43,43,43)
                            child.Box.TextColor3 = theme.PrimaryText
                        end
                    elseif child.Name == "Dropdown" then
                        child.BackgroundTransparency = 1
                        if child:FindFirstChild("Choose") then
                            child.Choose.BackgroundColor3 = theme.Fill
                            if child.Choose:FindFirstChild("Title") then child.Choose.Title.TextColor3 = theme.PrimaryText end
                            if child.Choose:FindFirstChild("Arrow") then child.Choose.Arrow.ImageColor3 = theme.Highlight end
                        end
                        if child:FindFirstChild("OptionHolder") then
                            child.OptionHolder.BackgroundColor3 = theme.Fill
                            for _, opt in ipairs(child.OptionHolder:GetChildren()) do
                                if opt:IsA("TextButton") then opt.BackgroundColor3 = theme.Highlight; opt.TextColor3 = theme.PrimaryText end
                            end
                        end
                    end
                end
            end
        end
    end
end

local WindowDefaults = {
    Desktop = {Size = UDim2.new(0, 470, 0, 283), Position = UDim2.new(0.377, 0, 0.368, 0)},
    Mobile = {Size = UDim2.new(0, 340, 0, 420), Position = UDim2.new(0.5, -170, 0.05, 0)},
}

function Library:Window(title, logoAsset, opts)
    opts = opts or {}
    local device = detectDevice()
    local defaults = WindowDefaults[device]
    local theme = opts.theme or DefaultTheme

    local ui = Instance.new("ScreenGui")
    ui.Name = "ui"
    ui.Parent = CoreGui
    ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ui.IgnoreGuiInset = true
    ui.ResetOnSpawn = false

    local window = {}
    window.Theme = theme
    window.Device = device

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = ui
    Main.BackgroundColor3 = theme.MainBg
    Main.BorderSizePixel = 0
    Main.Position = defaults.Position
    Main.Size = defaults.Size
    Main.Active = true
    Main.Selectable = true

    window.Main = Main

    do
        local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

        local function updateInput(input)
            local Delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + Delta.X, startPos.Y.Scale, startPos.Y.Offset + Delta.Y)
        end

        Main.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Main.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        Main.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                updateInput(input)
            end
        end)
    end

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = Main

    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Parent = Main
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.BackgroundTransparency = 1.000
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    Shadow.Size = UDim2.new(1, 34, 1, 34)
    Shadow.ZIndex = 0
    Shadow.Image = "rbxassetid://5554236805"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(23, 23, 277, 277)

    local Top = Instance.new("Frame")
    Top.Name = "Top"
    Top.Parent = Main
    Top.BackgroundColor3 = theme.TopBg
    Top.BorderSizePixel = 0
    Top.Size = UDim2.new(1, 0, 0, 38)

    window.Top = Top

    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 8)
    TopCorner.Parent = Top

    local TopCover = Instance.new("Frame")
    TopCover.Name = "Cover"
    TopCover.Parent = Top
    TopCover.AnchorPoint = Vector2.new(0.5, 1)
    TopCover.BackgroundColor3 = theme.TopBg
    TopCover.BorderSizePixel = 0
    TopCover.Position = UDim2.new(0.5, 0, 1, 0)
    TopCover.Size = UDim2.new(1, 0, 0, 6)

    local Line = Instance.new("Frame")
    Line.Name = "Line"
    Line.Parent = Top
    Line.AnchorPoint = Vector2.new(0.5, 1)
    Line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Line.BackgroundTransparency = 0.92
    Line.Position = UDim2.new(0.5, 0, 1, 1)
    Line.Size = UDim2.new(1, 0, 0, 1)

    local Logo = Instance.new("ImageLabel")
    Logo.Name = "Logo"
    Logo.Parent = Top
    Logo.AnchorPoint = Vector2.new(0, 0.5)
    Logo.BackgroundTransparency = 1.000
    Logo.Position = UDim2.new(0, 8, 0.5, 0)
    Logo.Size = UDim2.new(0, 28, 0, 28)
    if logoAsset then
        Logo.Image = logoAsset
    else
        Logo.Image = "http://www.roblox.com/asset/?id=7803241868"
    end
    Logo.ImageColor3 = theme.Accent

    window.Logo = Logo

    local GameName = Instance.new("TextLabel")
    GameName.Name = "GameName"
    GameName.Parent = Top
    GameName.AnchorPoint = Vector2.new(0, 0.5)
    GameName.BackgroundTransparency = 1.000
    GameName.Position = UDim2.new(0, 44, 0.5, 0)
    GameName.Size = UDim2.new(0, 220, 0, 24)
    GameName.Font = Enum.Font.Gotham
    GameName.Text = title or "Game Name"
    GameName.TextColor3 = theme.Accent
    GameName.TextSize = device == "Mobile" and 16 or 14
    GameName.TextXAlignment = Enum.TextXAlignment.Left

    window.GameName = GameName

    local Controls = Instance.new("Frame")
    Controls.Name = "Controls"
    Controls.Parent = Top
    Controls.AnchorPoint = Vector2.new(1, 0.5)
    Controls.BackgroundTransparency = 1
    Controls.Position = UDim2.new(1, -8, 0.5, 0)
    Controls.Size = UDim2.new(0, 80, 0, 24)

    local Minimize = Instance.new("ImageButton")
    Minimize.Name = "Minimize"
    Minimize.Parent = Controls
    Minimize.AnchorPoint = Vector2.new(1, 0.5)
    Minimize.BackgroundTransparency = 1.000
    Minimize.Position = UDim2.new(1, -28, 0.5, 0)
    Minimize.Size = UDim2.new(0, 22, 0, 22)
    Minimize.Image = "rbxassetid://7733771811"
    Minimize.ImageColor3 = theme.SecondaryText
    Minimize.ScaleType = Enum.ScaleType.Crop

    local Close = Instance.new("ImageButton")
    Close.Name = "Close"
    Close.Parent = Controls
    Close.AnchorPoint = Vector2.new(1, 0.5)
    Close.BackgroundTransparency = 1.000
    Close.Position = UDim2.new(1, -6, 0.5, 0)
    Close.Size = UDim2.new(0, 22, 0, 22)
    Close.Image = "http://www.roblox.com/asset/?id=7755372427"
    Close.ImageColor3 = theme.SecondaryText
    Close.ScaleType = Enum.ScaleType.Crop

    local MinimizedIcon = Instance.new("ImageButton")
    MinimizedIcon.Name = "MinimizedIcon"
    MinimizedIcon.Parent = ui
    MinimizedIcon.AnchorPoint = Vector2.new(1, 1)
    MinimizedIcon.BackgroundColor3 = theme.Accent
    MinimizedIcon.BackgroundTransparency = 0
    MinimizedIcon.BorderSizePixel = 0
    MinimizedIcon.Position = UDim2.new(1, -20, 1, -20)
    MinimizedIcon.Size = UDim2.new(0, 40, 0, 40)
    MinimizedIcon.Visible = false
    MinimizedIcon.ZIndex = 10
    MinimizedIcon.Image = Logo.Image

    local MinimizedCorner = Instance.new("UICorner")
    MinimizedCorner.CornerRadius = UDim.new(0, 8)
    MinimizedCorner.Parent = MinimizedIcon

    window.MinimizedIcon = MinimizedIcon

    Minimize.MouseButton1Click:Connect(function()
        Main.Visible = false
        MinimizedIcon.Visible = true
    end)
    Minimize.MouseEnter:Connect(function()
        tweenObject(Minimize, {ImageColor3 = theme.PrimaryText}, 0.18)
    end)
    Minimize.MouseLeave:Connect(function()
        tweenObject(Minimize, {ImageColor3 = theme.SecondaryText}, 0.18)
    end)

    MinimizedIcon.MouseButton1Click:Connect(function()
        Main.Visible = true
        MinimizedIcon.Visible = false
    end)

    Close.MouseButton1Click:Connect(function()
        ui:Destroy()
    end)
    Close.MouseEnter:Connect(function()
        tweenObject(Close, {ImageColor3 = theme.PrimaryText}, 0.18)
    end)
    Close.MouseLeave:Connect(function()
        tweenObject(Close, {ImageColor3 = theme.SecondaryText}, 0.18)
    end)

    local Tabs = Instance.new("Frame")
    Tabs.Name = "Tabs"
    Tabs.Parent = Main
    Tabs.BackgroundColor3 = theme.TabsBg
    Tabs.BorderSizePixel = 0
    Tabs.Position = UDim2.new(0, 0, 0, 42)
    local tabsWidth = device == "Mobile" and 86 or 132
    Tabs.Size = UDim2.new(0, tabsWidth, 1, -46)

    local TabsCorner = Instance.new("UICorner")
    TabsCorner.CornerRadius = UDim.new(0, 8)
    TabsCorner.Parent = Tabs

    local TabsCover = Instance.new("Frame")
    TabsCover.Name = "Cover"
    TabsCover.Parent = Tabs
    TabsCover.AnchorPoint = Vector2.new(1, 0.5)
    TabsCover.BackgroundColor3 = theme.TabsBg
    TabsCover.BorderSizePixel = 0
    TabsCover.Position = UDim2.new(1, 0, 0.5, 0)
    TabsCover.Size = UDim2.new(0, 6, 1, 0)

    local TabsContainer = Instance.new("Frame")
    TabsContainer.Name = "TabsContainer"
    TabsContainer.Parent = Tabs
    TabsContainer.BackgroundTransparency = 1.000
    TabsContainer.Size = UDim2.new(1, 0, 1, 0)

    local TabsList = Instance.new("UIListLayout")
    TabsList.Name = "TabsList"
    TabsList.Parent = TabsContainer
    TabsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabsList.SortOrder = Enum.SortOrder.LayoutOrder
    TabsList.Padding = UDim.new(0, 8)

    local TabsPadding = Instance.new("UIPadding")
    TabsPadding.Parent = TabsContainer
    TabsPadding.PaddingTop = UDim.new(0, 8)
    TabsPadding.PaddingLeft = UDim.new(0, 4)
    TabsPadding.PaddingRight = UDim.new(0, 4)

    local SelectedIndicator = Instance.new("Frame")
    SelectedIndicator.Name = "SelectedIndicator"
    SelectedIndicator.Parent = Tabs
    SelectedIndicator.BackgroundColor3 = theme.Accent
    SelectedIndicator.BorderSizePixel = 0
    SelectedIndicator.Size = UDim2.new(0, 4, 0, 36)
    SelectedIndicator.Position = UDim2.new(0, 0, 0, 8)
    SelectedIndicator.AnchorPoint = Vector2.new(0, 0)
    SelectedIndicator.Visible = false
    local SelectedCorner = Instance.new("UICorner")
    SelectedCorner.CornerRadius = UDim.new(0, 4)
    SelectedCorner.Parent = SelectedIndicator

    local Pages = Instance.new("Frame")
    Pages.Name = "Pages"
    Pages.Parent = Main
    Pages.BackgroundColor3 = theme.MainBg
    Pages.BorderSizePixel = 0
    Pages.Position = UDim2.new(0, tabsWidth + 8, 0, 50)
    Pages.Size = UDim2.new(1, -tabsWidth - 16, 1, -58)

    local PagesCorner = Instance.new("UICorner")
    PagesCorner.CornerRadius = UDim.new(0, 8)
    PagesCorner.Parent = Pages

    local Resize = Instance.new("ImageButton")
    Resize.Name = "Resize"
    Resize.Parent = Main
    Resize.AnchorPoint = Vector2.new(1, 1)
    Resize.BackgroundTransparency = 1.000
    Resize.Position = UDim2.new(1, -6, 1, -6)
    Resize.Size = UDim2.new(0, 18, 0, 18)
    Resize.ZIndex = 2
    Resize.Image = "rbxassetid://3926307971"
    Resize.ImageColor3 = theme.AccentDark
    Resize.ImageRectOffset = Vector2.new(204, 364)
    Resize.ImageRectSize = Vector2.new(36, 36)

    if device == "Mobile" then
        Resize.Visible = false
    end

    do
        local resizing = false
        local resizeStart, startSize

        Resize.MouseButton1Down:Connect(function()
            if device == "Mobile" then return end
            resizing = true
            resizeStart = Vector2.new(Mouse.X, Mouse.Y)
            startSize = Main.Size
        end)

        UserInputService.InputChanged:Connect(function(input)
            if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = Vector2.new(input.Position.X - resizeStart.X, input.Position.Y - resizeStart.Y)
                local newX = math.max(320, startSize.X.Offset + delta.X)
                local newY = math.max(240, startSize.Y.Offset + delta.Y)
                Main.Size = UDim2.new(0, newX, 0, newY)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = false
            end
        end)
    end

    local TabFunctions = {}
    local createdPages = {}
    local tabButtonInstances = {}

    function TabFunctions:Tab(tabInfo)
        local title, icon
        if type(tabInfo) == "table" then
            title = tabInfo[1] or "Tab"
            icon = tabInfo[2]
        else
            title = tabInfo or "Tab"
        end

        local TabButton = Instance.new("TextButton")
        TabButton.Name = "TabButton"
        TabButton.Parent = TabsContainer
        TabButton.BackgroundColor3 = theme.Accent
        TabButton.BackgroundTransparency = 1
        TabButton.Size = UDim2.new(1, -12, 0, device == "Mobile" and 48 or 36)
        TabButton.AutoButtonColor = false
        TabButton.Font = Enum.Font.Gotham
        TabButton.Text = ""
        TabButton.TextColor3 = Color3.fromRGB(72,72,72)
        TabButton.TextSize = 14.000
        TabButton.LayoutOrder = #tabButtonInstances + 1

        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 6)
        TabCorner.Parent = TabButton

        local TabContent = Instance.new("Frame")
        TabContent.Name = "TabContent"
        TabContent.Parent = TabButton
        TabContent.BackgroundTransparency = 1
        TabContent.Size = UDim2.new(1, 0, 1, 0)

        local Icon = nil
        if icon then
            Icon = Instance.new("ImageLabel")
            Icon.Name = "Icon"
            Icon.Parent = TabContent
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(0, 8, 0.5, -((device == "Mobile") and 12 or 10))
            Icon.Size = UDim2.new(0, (device == "Mobile") and 28 or 20, 0, (device == "Mobile") and 28 or 20)
            Icon.Image = icon
            Icon.ImageColor3 = theme.Accent
        end

        local TextLabel = Instance.new("TextLabel")
        TextLabel.Name = "TextLabel"
        TextLabel.Parent = TabContent
        TextLabel.BackgroundTransparency = 1
        TextLabel.Size = UDim2.new(1, 0, 1, 0)
        TextLabel.Font = Enum.Font.Gotham
        TextLabel.Text = title
        TextLabel.TextColor3 = theme.SecondaryText
        TextLabel.TextSize = device == "Mobile" and 16 or 14
        TextLabel.TextXAlignment = Enum.TextXAlignment.Center

        if Icon then
            TextLabel.Position = UDim2.new(0, (device == "Mobile") and 40 or 28, 0, 0)
            TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        end

        local Page = Instance.new("ScrollingFrame")
        Page.Name = ("Page_%d"):format(#createdPages + 1)
        Page.Visible = false
        Page.Parent = Pages
        Page.Active = true
        Page.BackgroundTransparency = 1.000
        Page.BorderSizePixel = 0
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.CanvasPosition = Vector2.new(0, 0)
        Page.ScrollBarThickness = device == "Mobile" and 6 or 2
        Page.ScrollBarImageColor3 = theme.Accent
        Page.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar

        local PageList = Instance.new("UIListLayout")
        PageList.Parent = Page
        PageList.HorizontalAlignment = Enum.HorizontalAlignment.Center
        PageList.SortOrder = Enum.SortOrder.LayoutOrder
        PageList.Padding = UDim.new(0, 8)

        local PagePadding = Instance.new("UIPadding")
        PagePadding.Parent = Page
        PagePadding.PaddingTop = UDim.new(0, 8)
        PagePadding.PaddingLeft = UDim.new(0, 6)
        PagePadding.PaddingRight = UDim.new(0, 6)

        PageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageList.AbsoluteContentSize.Y + 8)
        end)

        table.insert(createdPages, Page)
        table.insert(tabButtonInstances, TabButton)

        local function moveIndicatorToButton()
            SelectedIndicator.Visible = true
            RunService.Heartbeat:Wait()
            local absPos = TabButton.AbsolutePosition
            local tabsAbsPos = Tabs.AbsolutePosition
            local yOffset = absPos.Y - tabsAbsPos.Y
            local newPos = UDim2.new(0, 0, 0, yOffset)
            local newSize = UDim2.new(0, 4, 0, TabButton.AbsoluteSize.Y)
            tweenObject(SelectedIndicator, {Position = newPos}, 0.18)
            tweenObject(SelectedIndicator, {Size = newSize}, 0.18)
        end

        TabButton.MouseButton1Click:Connect(function()
            for _, v in ipairs(createdPages) do
                if v:IsA("ScrollingFrame") then
                    v.Visible = false
                end
            end
            Page.Visible = true

            for _, v in ipairs(tabButtonInstances) do
                if v.Name == "TabButton" then
                    tweenObject(v, {BackgroundTransparency = 1}, 0.18)
                    if v:FindFirstChild("TabContent") and v.TabContent:FindFirstChild("TextLabel") then
                        tweenObject(v.TabContent.TextLabel, {TextColor3 = theme.SecondaryText}, 0.18)
                    end
                end
            end

            tweenObject(TabButton, {BackgroundTransparency = 0.6}, 0.18)
            tweenObject(TextLabel, {TextColor3 = theme.PrimaryText}, 0.18)

            moveIndicatorToButton()
        end)

        if #tabButtonInstances == 1 then
            Page.Visible = true
            tweenObject(TabButton, {BackgroundTransparency = 0.6}, 0.18)
            tweenObject(TextLabel, {TextColor3 = theme.PrimaryText}, 0.18)
            RunService.Heartbeat:Wait()
            moveIndicatorToButton()
        end

        local Elements = {}

        function Elements:Button(text, callback)
            local Button = Instance.new("TextButton")
            Button.Name = "Button"
            Button.Parent = Page
            Button.BackgroundColor3 = theme.Highlight
            Button.BorderSizePixel = 0
            Button.Size = UDim2.new(1, -12, 0, device == "Mobile" and 48 or 36)
            Button.AutoButtonColor = false
            Button.Font = Enum.Font.Gotham
            Button.Text = text or "Button"
            Button.TextColor3 = theme.PrimaryText
            Button.TextSize = device == "Mobile" and 18 or 14

            local ButtonCorner = Instance.new("UICorner")
            ButtonCorner.CornerRadius = UDim.new(0, 8)
            ButtonCorner.Parent = Button

            Button.MouseEnter:Connect(function()
                if device == "Desktop" then
                    tweenObject(Button, {BackgroundColor3 = theme.Accent}, 0.18)
                end
            end)

            Button.MouseLeave:Connect(function()
                if device == "Desktop" then
                    tweenObject(Button, {BackgroundColor3 = theme.Highlight}, 0.18)
                end
            end)

            Button.MouseButton1Click:Connect(function()
                if typeof(callback) == "function" then
                    callback()
                end
            end)

            if device == "Mobile" then
                Button.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch then
                        if typeof(callback) == "function" then
                            callback()
                        end
                    end
                end)
            end
        end

        function Elements:Toggle(text, default, callback)
            local Toggle = Instance.new("TextButton")
            Toggle.Name = "Toggle"
            Toggle.Parent = Page
            Toggle.BackgroundColor3 = theme.Fill
            Toggle.BorderSizePixel = 0
            Toggle.Size = UDim2.new(1, -12, 0, device == "Mobile" and 54 or 40)
            Toggle.AutoButtonColor = false
            Toggle.Font = Enum.Font.Gotham
            Toggle.Text = ""
            Toggle.TextColor3 = Color3.new(0,0,0)
            Toggle.TextSize = 14.000

            local ToggleCorner = Instance.new("UICorner")
            ToggleCorner.CornerRadius = UDim.new(0, 8)
            ToggleCorner.Parent = Toggle

            local Title = Instance.new("TextLabel")
            Title.Name = "Title"
            Title.Parent = Toggle
            Title.BackgroundTransparency = 1.000
            Title.Position = UDim2.new(0, 12, 0, 0)
            Title.Size = UDim2.new(1, -12, 1, 0)
            Title.Font = Enum.Font.Gotham
            Title.Text = text or "Toggle"
            Title.TextColor3 = theme.PrimaryText
            Title.TextSize = device == "Mobile" and 18 or 14
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Name = "ToggleFrame"
            ToggleFrame.Parent = Toggle
            ToggleFrame.AnchorPoint = Vector2.new(1, 0.5)
            ToggleFrame.BackgroundColor3 = theme.Highlight
            ToggleFrame.Position = UDim2.new(1, -12, 0.5, 0)
            ToggleFrame.Size = UDim2.new(0, 18, 0, 18)

            local ToggleCorner2 = Instance.new("UICorner")
            ToggleCorner2.CornerRadius = UDim.new(0, 4)
            ToggleCorner2.Parent = ToggleFrame

            local Check = Instance.new("ImageLabel")
            Check.Name = "Check"
            Check.Parent = ToggleFrame
            Check.BackgroundTransparency = 1.000
            Check.Position = UDim2.new(0, 0, 0, 0)
            Check.Size = UDim2.new(1, 0, 1, 0)
            Check.Image = "http://www.roblox.com/asset/?id=7812909048"
            Check.ImageTransparency = 1
            Check.ScaleType = Enum.ScaleType.Fit

            local ToggleStroke = Instance.new("UIStroke")
            ToggleStroke.Parent = ToggleFrame
            ToggleStroke.LineJoinMode = Enum.LineJoinMode.Round
            ToggleStroke.Thickness = 2
            ToggleStroke.Color = theme.Highlight

            local toggled = default or false

            if toggled then
                tweenObject(ToggleFrame, {BackgroundTransparency = 0}, 0.18)
                tweenObject(Check, {ImageTransparency = 0}, 0.18)
            else
                ToggleFrame.BackgroundTransparency = 1
                Check.ImageTransparency = 1
            end

            Toggle.MouseEnter:Connect(function()
                if device == "Desktop" then
                    tweenObject(Toggle, {BackgroundColor3 = Color3.fromRGB(40,40,40)}, 0.12)
                end
            end)

            Toggle.MouseLeave:Connect(function()
                if device == "Desktop" then
                    tweenObject(Toggle, {BackgroundColor3 = theme.Fill}, 0.12)
                end
            end)

            Toggle.MouseButton1Click:Connect(function()
                toggled = not toggled
                if toggled then
                    tweenObject(ToggleFrame, {BackgroundTransparency = 0}, 0.12)
                    tweenObject(Check, {ImageTransparency = 0}, 0.12)
                else
                    tweenObject(ToggleFrame, {BackgroundTransparency = 1}, 0.12)
                    tweenObject(Check, {ImageTransparency = 1}, 0.12)
                end
                if typeof(callback) == "function" then
                    callback(toggled)
                end
            end)

            if device == "Mobile" then
                Toggle.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch then
                        Toggle.MouseButton1Click:Fire()
                    end
                end)
            end
        end

        function Elements:Label(text)
            local Label = Instance.new("TextLabel")
            Label.Parent = Page
            Label.BackgroundColor3 = theme.Fill
            Label.BorderSizePixel = 0
            Label.Size = UDim2.new(1, -12, 0, device == "Mobile" and 52 or 36)
            Label.Font = Enum.Font.Gotham
            Label.Text = "  " .. (text or "Label")
            Label.TextColor3 = theme.PrimaryText
            Label.TextSize = device == "Mobile" and 18 or 14
            Label.TextXAlignment = Enum.TextXAlignment.Left

            local LabelCorner = Instance.new("UICorner")
            LabelCorner.CornerRadius = UDim.new(0, 8)
            LabelCorner.Parent = Label
        end

        function Elements:Slider(text, min, max, default, callback)
            min = min or 0
            max = max or 100
            default = default or min
            callback = callback or function() end

            local Slider = Instance.new("Frame")
            Slider.Name = "Slider"
            Slider.Parent = Page
            Slider.BackgroundColor3 = theme.Fill
            Slider.Size = UDim2.new(1, -12, 0, device == "Mobile" and 64 or 48)

            local SliderCorner = Instance.new("UICorner")
            SliderCorner.CornerRadius = UDim.new(0, 8)
            SliderCorner.Parent = Slider

            local Title = Instance.new("TextLabel")
            Title.Name = "Title"
            Title.Parent = Slider
            Title.BackgroundTransparency = 1.000
            Title.Position = UDim2.new(0, 12, 0, 0)
            Title.Size = UDim2.new(1, -24, 0, 26)
            Title.Font = Enum.Font.Gotham
            Title.Text = text or "Slider"
            Title.TextColor3 = theme.PrimaryText
            Title.TextSize = device == "Mobile" and 16 or 14
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local Value = Instance.new("TextLabel")
            Value.Name = "Value"
            Value.Parent = Slider
            Value.AnchorPoint = Vector2.new(1, 0)
            Value.BackgroundTransparency = 1.000
            Value.Position = UDim2.new(1, -12, 0, 0)
            Value.Size = UDim2.new(0, 48, 0, 26)
            Value.Font = Enum.Font.Gotham
            Value.Text = tostring(default)
            Value.TextColor3 = theme.PrimaryText
            Value.TextSize = device == "Mobile" and 16 or 14
            Value.TextXAlignment = Enum.TextXAlignment.Right

            local SliderClick = Instance.new("TextButton")
            SliderClick.Name = "SliderClick"
            SliderClick.Parent = Slider
            SliderClick.AnchorPoint = Vector2.new(0.5, 1)
            SliderClick.BackgroundColor3 = Color3.fromRGB(52, 52, 52)
            SliderClick.Position = UDim2.new(0.5, 0, 1, -12)
            SliderClick.Size = UDim2.new(1, -24, 0, 8)
            SliderClick.AutoButtonColor = false
            SliderClick.Text = ''

            local SliderClickCorner = Instance.new("UICorner")
            SliderClickCorner.CornerRadius = UDim.new(0, 6)
            SliderClickCorner.Parent = SliderClick

            local SliderDrag = Instance.new("Frame")
            SliderDrag.Name = "SliderDrag"
            SliderDrag.Parent = SliderClick
            SliderDrag.BackgroundColor3 = theme.AccentDark
            SliderDrag.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)

            local SliderDragCorner = Instance.new("UICorner")
            SliderDragCorner.CornerRadius = UDim.new(0, 6)
            SliderDragCorner.Parent = SliderDrag

            local dragging = false

            local function slide(input)
                local pos = math.clamp((input.Position.X - SliderClick.AbsolutePosition.X) / SliderClick.AbsoluteSize.X, 0, 1)
                local newUDim = UDim2.new(pos, 0, 1, 0)
                SliderDrag:TweenSize(newUDim, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.12, true)
                local value = math.floor(min + (pos * (max - min)))
                Value.Text = tostring(value)
                callback(value)
            end

            SliderClick.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    slide(input)
                    dragging = true
                end
            end)

            SliderClick.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    slide(input)
                end
            end)
        end

        function Elements:Keybind(text, defaultKey, callback)
            defaultKey = defaultKey or Enum.KeyCode.Unknown
            local Keybind = Instance.new("TextButton")
            Keybind.Name = "Keybind"
            Keybind.Parent = Page
            Keybind.BackgroundColor3 = theme.Fill
            Keybind.Size = UDim2.new(1, -12, 0, device == "Mobile" and 54 or 40)
            Keybind.AutoButtonColor = false
            Keybind.Font = Enum.Font.Gotham
            Keybind.Text = ""
            Keybind.TextColor3 = Color3.new(0, 0, 0)
            Keybind.TextSize = 14.000

            local KeybindCorner = Instance.new("UICorner")
            KeybindCorner.CornerRadius = UDim.new(0, 8)
            KeybindCorner.Parent = Keybind

            local Title = Instance.new("TextLabel")
            Title.Name = "Title"
            Title.Parent = Keybind
            Title.BackgroundTransparency = 1.000
            Title.Position = UDim2.new(0, 12, 0, 0)
            Title.Size = UDim2.new(1, -12, 1, 0)
            Title.Font = Enum.Font.Gotham
            Title.Text = text or "Keybind"
            Title.TextColor3 = theme.PrimaryText
            Title.TextSize = device == "Mobile" and 16 or 14
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local CurrentKey = Instance.new("TextLabel")
            CurrentKey.Name = "CurrentKey"
            CurrentKey.Parent = Keybind
            CurrentKey.AnchorPoint = Vector2.new(1, 0.5)
            CurrentKey.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
            CurrentKey.Position = UDim2.new(1, -10, 0.5, 0)
            CurrentKey.Size = UDim2.new(0, 64, 0, 28)
            CurrentKey.Font = Enum.Font.Gotham
            CurrentKey.Text = (defaultKey ~= Enum.KeyCode.Unknown) and defaultKey.Name or ". . ."
            CurrentKey.TextColor3 = theme.PrimaryText
            CurrentKey.TextSize = device == "Mobile" and 16 or 14

            local CurrentKeyCorner = Instance.new("UICorner")
            CurrentKeyCorner.CornerRadius = UDim.new(0, 6)
            CurrentKeyCorner.Parent = CurrentKey

            local binding = false
            local key = defaultKey

            Keybind.MouseButton1Click:Connect(function()
                binding = true
                CurrentKey.Text = ". . ."
                local conn
                conn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        key = input.KeyCode
                        CurrentKey.Text = key.Name
                        binding = false
                        conn:Disconnect()
                    end
                end)
            end)

            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if not gameProcessed and input.KeyCode == key then
                    if typeof(callback) == "function" then
                        callback(key)
                    end
                end
            end)

            if device == "Mobile" then
                Keybind.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch then
                        Keybind.MouseButton1Click:Fire()
                    end
                end)
            end
        end

        function Elements:InputBox(text, placeholder, callback)
            local InputBox = Instance.new("Frame")
            InputBox.Name = "InputBox"
            InputBox.Parent = Page
            InputBox.BackgroundColor3 = theme.Fill
            InputBox.Size = UDim2.new(1, -12, 0, device == "Mobile" and 72 or 48)

            local InputBoxCorner = Instance.new("UICorner")
            InputBoxCorner.CornerRadius = UDim.new(0, 8)
            InputBoxCorner.Parent = InputBox

            local Title = Instance.new("TextLabel")
            Title.Name = "Title"
            Title.Parent = InputBox
            Title.BackgroundTransparency = 1.000
            Title.Position = UDim2.new(0, 12, 0, 0)
            Title.Size = UDim2.new(1, -24, 0, 24)
            Title.Font = Enum.Font.Gotham
            Title.Text = text or "Input"
            Title.TextColor3 = theme.PrimaryText
            Title.TextSize = device == "Mobile" and 16 or 14
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local Box = Instance.new("TextBox")
            Box.Name = "Box"
            Box.Parent = InputBox
            Box.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
            Box.BorderSizePixel = 0
            Box.Position = UDim2.new(0, 12, 0, 28)
            Box.Size = UDim2.new(1, -24, 0, 30)
            Box.Font = Enum.Font.Gotham
            Box.PlaceholderText = placeholder or "Enter text..."
            Box.Text = ""
            Box.TextColor3 = theme.PrimaryText
            Box.TextSize = device == "Mobile" and 16 or 14

            local BoxCorner = Instance.new("UICorner")
            BoxCorner.CornerRadius = UDim.new(0, 6)
            BoxCorner.Parent = Box

            Box.FocusLost:Connect(function(enterPressed)
                if enterPressed and typeof(callback) == "function" then
                    callback(Box.Text)
                end
            end)

            if device == "Mobile" then
                Box.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch then
                        Box:CaptureFocus()
                    end
                end)
            end
        end

        function Elements:Dropdown(text, options, callback, multiSelect)
            multiSelect = multiSelect or false
            options = options or {}
            callback = callback or function() end

            local Dropdown = Instance.new("Frame")
            Dropdown.Name = "Dropdown"
            Dropdown.Parent = Page
            Dropdown.BackgroundTransparency = 1.000
            Dropdown.BorderSizePixel = 0
            Dropdown.ClipsDescendants = true
            Dropdown.Size = UDim2.new(1, -12, 0, 36)

            local DropdownList = Instance.new("UIListLayout")
            DropdownList.Parent = Dropdown
            DropdownList.HorizontalAlignment = Enum.HorizontalAlignment.Center
            DropdownList.SortOrder = Enum.SortOrder.LayoutOrder
            DropdownList.Padding = UDim.new(0, 6)

            local Choose = Instance.new("Frame")
            Choose.Name = "Choose"
            Choose.Parent = Dropdown
            Choose.BackgroundColor3 = theme.Fill
            Choose.BorderSizePixel = 0
            Choose.Size = UDim2.new(1, 0, 0, 36)

            local ChooseCorner = Instance.new("UICorner")
            ChooseCorner.CornerRadius = UDim.new(0, 8)
            ChooseCorner.Parent = Choose

            local Title = Instance.new("TextLabel")
            Title.Name = "Title"
            Title.Parent = Choose
            Title.BackgroundTransparency = 1.000
            Title.Position = UDim2.new(0, 12, 0, 0)
            Title.Size = UDim2.new(1, -48, 1, 0)
            Title.Font = Enum.Font.Gotham
            Title.Text = text or "Dropdown"
            Title.TextColor3 = theme.PrimaryText
            Title.TextSize = device == "Mobile" and 16 or 14
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local Arrow = Instance.new("ImageButton")
            Arrow.Name = "Arrow"
            Arrow.Parent = Choose
            Arrow.AnchorPoint = Vector2.new(1, 0.5)
            Arrow.BackgroundTransparency = 1.000
            Arrow.LayoutOrder = 10
            Arrow.Position = UDim2.new(1, -8, 0.5, 0)
            Arrow.Size = UDim2.new(0, 28, 0, 28)
            Arrow.ZIndex = 2
            Arrow.Image = "rbxassetid://3926307971"
            Arrow.ImageColor3 = theme.Highlight
            Arrow.ImageRectOffset = Vector2.new(324, 524)
            Arrow.ImageRectSize = Vector2.new(36, 36)
            Arrow.ScaleType = Enum.ScaleType.Crop

            local OptionHolder = Instance.new("Frame")
            OptionHolder.Name = "OptionHolder"
            OptionHolder.Parent = Dropdown
            OptionHolder.BackgroundColor3 = theme.Fill
            OptionHolder.BorderSizePixel = 0
            OptionHolder.Position = UDim2.new(0, 0, 0, 36)
            OptionHolder.Size = UDim2.new(1, 0, 0, 0)

            local OptionHolderCorner = Instance.new("UICorner")
            OptionHolderCorner.CornerRadius = UDim.new(0, 8)
            OptionHolderCorner.Parent = OptionHolder

            local OptionList = Instance.new("UIListLayout")
            OptionList.Name = "OptionList"
            OptionList.Parent = OptionHolder
            OptionList.HorizontalAlignment = Enum.HorizontalAlignment.Center
            OptionList.SortOrder = Enum.SortOrder.LayoutOrder
            OptionList.Padding = UDim.new(0, 6)

            local OptionPadding = Instance.new("UIPadding")
            OptionPadding.Parent = OptionHolder
            OptionPadding.PaddingTop = UDim.new(0, 8)
            OptionPadding.PaddingLeft = UDim.new(0, 6)
            OptionPadding.PaddingRight = UDim.new(0, 6)

            local dropped = false
            local selected = {}

            local function updateTitle()
                if multiSelect then
                    local selectedList = {}
                    for item, _ in pairs(selected) do
                        table.insert(selectedList, item)
                    end

                    if #selectedList > 0 then
                        if #selectedList <= 3 then
                            Title.Text = text .. ": " .. table.concat(selectedList, ", ")
                        else
                            Title.Text = text .. ": " .. #selectedList .. " selected"
                        end
                    else
                        Title.Text = text
                    end
                end
            end

            local function createOption(option)
                local Option = Instance.new("TextButton")
                Option.Name = "Option"
                Option.Parent = OptionHolder
                Option.BackgroundColor3 = theme.Highlight
                Option.BorderSizePixel = 0
                Option.Size = UDim2.new(1, -12, 0, 34)
                Option.AutoButtonColor = false
                Option.Font = Enum.Font.Gotham
                Option.Text = option
                Option.TextColor3 = theme.PrimaryText
                Option.TextSize = device == "Mobile" and 16 or 14

                local OptionCorner = Instance.new("UICorner")
                OptionCorner.CornerRadius = UDim.new(0, 8)
                OptionCorner.Parent = Option

                if multiSelect then
                    local Checkmark = Instance.new("ImageLabel")
                    Checkmark.Name = "Checkmark"
                    Checkmark.Parent = Option
                    Checkmark.BackgroundTransparency = 1
                    Checkmark.Image = "rbxassetid://6031068421"
                    Checkmark.ImageTransparency = 1
                    Checkmark.Size = UDim2.new(0, 18, 0, 18)
                    Checkmark.Position = UDim2.new(0, 8, 0.5, -9)
                end

                Option.MouseButton1Click:Connect(function()
                    if multiSelect then
                        if selected[option] then
                            selected[option] = nil
                            if Option:FindFirstChild("Checkmark") then
                                Option.Checkmark.ImageTransparency = 1
                            end
                        else
                            selected[option] = true
                            if Option:FindFirstChild("Checkmark") then
                                Option.Checkmark.ImageTransparency = 0
                            end
                        end

                        updateTitle()

                        local selectedList = {}
                        for item, _ in pairs(selected) do
                            table.insert(selectedList, item)
                        end
                        callback(selectedList)
                    else
                        callback(option)
                        Title.Text = text .. ": " .. option
                        dropped = false
                        tweenObject(Arrow, {Rotation = 0}, 0.15)
                        Dropdown:TweenSize(UDim2.new(1, -12, 0, 36), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .15, true)
                    end
                end)

                if device == "Mobile" then
                    Option.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Touch then
                            Option.MouseButton1Click:Fire()
                        end
                    end)
                end
            end

            for _, option in ipairs(options) do
                createOption(option)
            end

            OptionList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if dropped then
                    OptionHolder.Size = UDim2.new(1, 0, 0, OptionList.AbsoluteContentSize.Y + 12)
                    Dropdown.Size = UDim2.new(1, -12, 0, 36 + OptionList.AbsoluteContentSize.Y + 12)
                end
            end)

            Choose.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dropped = not dropped

                    if dropped then
                        Dropdown:TweenSize(UDim2.new(1, -12, 0, 36 + OptionList.AbsoluteContentSize.Y + 12), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, .15, true)
                        tweenObject(Arrow, {Rotation = 180}, 0.15)
                    else
                        tweenObject(Arrow, {Rotation = 0}, 0.15)
                        Dropdown:TweenSize(UDim2.new(1, -12, 0, 36), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, .15, true)
                    end
                end
            end)

            if device == "Mobile" then
                Choose.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch then
                        Choose.InputBegan:Fire(input)
                    end
                end)
            end

            local DropdownFunctions = {}

            function DropdownFunctions:Refresh(newOptions)
                newOptions = newOptions or {}
                selected = {}
                dropped = false

                tweenObject(Arrow, {Rotation = 0}, 0.15)
                Dropdown:TweenSize(UDim2.new(1, -12, 0, 36), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .15, true)

                for _, child in ipairs(OptionHolder:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end

                Title.Text = text

                for _, option in ipairs(newOptions) do
                    createOption(option)
                end

                OptionList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    if dropped then
                        OptionHolder.Size = UDim2.new(1, 0, 0, OptionList.AbsoluteContentSize.Y + 12)
                        Dropdown.Size = UDim2.new(1, -12, 0, 36 + OptionList.AbsoluteContentSize.Y + 12)
                    end
                end)
            end

            return DropdownFunctions
        end

        return Elements
    end

    function window:SetTheme(newTheme)
        if not newTheme then return end
        for k, v in pairs(DefaultTheme) do
            if newTheme[k] == nil then
                newTheme[k] = v
            end
        end
        self.Theme = newTheme
        applyThemeToWindow(self, newTheme)
    end

    function window:SetTitle(newTitle)
        if typeof(newTitle) == "string" then
            self.GameName.Text = newTitle
        end
    end

    function window:SetLogo(asset)
        if typeof(asset) == "string" then
            self.Logo.Image = asset
            if self.MinimizedIcon then
                self.MinimizedIcon.Image = asset
            end
        end
    end

    function Library:SetTheme(newTheme)
        if not newTheme then return end
        for k, v in pairs(DefaultTheme) do
            if newTheme[k] == nil then
                newTheme[k] = v
            end
        end
        DefaultTheme = newTheme
    end

    local result = TabFunctions
    result._window = window

    window.Main = Main
    window.Top = Top
    window.Tabs = Tabs
    window.Pages = Pages
    window.Resize = Resize
    window.TabsContainer = TabsContainer
    window.GameName = GameName
    window.Logo = Logo
    window.MinimizedIcon = MinimizedIcon

    applyThemeToWindow(window, theme)

    return TabFunctions, window
end

return Library
