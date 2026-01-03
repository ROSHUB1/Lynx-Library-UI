-- Compatibility adapter: adds Section API on top of the improved ui_library
local Adapter = {}

function Adapter.CreateWindow(LibraryModule, title, logoAsset, opts)
    opts = opts or {}
    local TabFunctions, window = LibraryModule:Window(title, logoAsset, opts)
    local wrapped = {}

    local function captureNewPage()
        local pages = {}
        for _,c in ipairs(window.Pages:GetChildren()) do
            if c:IsA("ScrollingFrame") then
                pages[c] = true
            end
        end
        return pages
    end

    function wrapped:Tab(tabInfo)
        local before = captureNewPage()
        local Elements = TabFunctions:Tab(tabInfo)
        local newPage = nil
        for _,c in ipairs(window.Pages:GetChildren()) do
            if c:IsA("ScrollingFrame") and not before[c] then
                newPage = c
                break
            end
        end
        if not newPage then
            for i = #window.Pages:GetChildren(), 1, -1 do
                local c = window.Pages:GetChildren()[i]
                if c:IsA("ScrollingFrame") then
                    newPage = c
                    break
                end
            end
        end

        local tabWrapper = {}
        for k,v in pairs(Elements) do tabWrapper[k] = v end

        local headerHeight = 36
        local header = Instance.new("Frame")
        header.Name = "SectionsHeader"
        header.Parent = window.Pages
        header.BackgroundTransparency = 1
        header.Size = UDim2.new(1, 0, 0, headerHeight)
        header.Position = newPage.Position
        header.ZIndex = 5

        local headerLayout = Instance.new("UIListLayout")
        headerLayout.Parent = header
        headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
        headerLayout.Padding = UDim.new(0, 8)
        headerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

        local headerPadding = Instance.new("UIPadding")
        headerPadding.Parent = header
        headerPadding.PaddingLeft = UDim.new(0, 8)
        headerPadding.PaddingTop = UDim.new(0, 4)
        headerPadding.PaddingBottom = UDim.new(0, 4)

        newPage.Position = UDim2.new(newPage.Position.X.Scale, newPage.Position.X.Offset, 0, headerHeight)
        newPage.Size = UDim2.new(newPage.Size.X.Scale, newPage.Size.X.Offset, 1, -headerHeight)

        newPage:GetPropertyChangedSignal("Visible"):Connect(function()
            header.Visible = newPage.Visible
        end)
        header.Visible = newPage.Visible

        tabWrapper._sections = {}
        tabWrapper._page = newPage
        tabWrapper._header = header
        tabWrapper._elements = Elements

        local function moveNewChildrenToSection(sectionFrame, beforeSnapshot)
            for _, child in ipairs(tabWrapper._page:GetChildren()) do
                if not beforeSnapshot[child] then
                    child.Parent = sectionFrame
                end
            end
        end

        function tabWrapper:Section(opts)
            opts = opts or {}
            local title = opts.Text or "Section"
            local side = opts.Side or "Left"

            local btn = Instance.new("TextButton")
            btn.Name = "SectionButton"
            btn.AutoButtonColor = false
            btn.BackgroundColor3 = Color3.fromRGB(48,48,48)
            btn.BackgroundTransparency = 0.9
            btn.Size = UDim2.new(0, 140, 0, 28)
            btn.Font = Enum.Font.GothamSemibold
            btn.Text = title
            btn.TextColor3 = Color3.fromRGB(220,220,220)
            btn.TextSize = 14
            btn.Parent = header

            local btnCorner = Instance.new("UICorner"); btnCorner.CornerRadius = UDim.new(0,6); btnCorner.Parent = btn

            local sectionFrame = Instance.new("Frame")
            sectionFrame.Name = ("Section_%s"):format(title:gsub("%s+","_"))
            sectionFrame.Parent = tabWrapper._page
            sectionFrame.BackgroundTransparency = 1
            sectionFrame.Size = UDim2.new(1, -12, 0, 0)
            sectionFrame.LayoutOrder = #tabWrapper._sections + 1

            local padding = Instance.new("UIPadding")
            padding.Parent = sectionFrame
            padding.PaddingLeft = UDim.new(0,6)
            padding.PaddingRight = UDim.new(0,6)
            padding.PaddingTop = UDim.new(0,6)
            padding.PaddingBottom = UDim.new(0,6)

            local list = Instance.new("UIListLayout")
            list.Parent = sectionFrame
            list.SortOrder = Enum.SortOrder.LayoutOrder
            list.HorizontalAlignment = Enum.HorizontalAlignment.Center
            list.Padding = UDim.new(0,6)

            local function updateSectionSize()
                local h = list.AbsoluteContentSize.Y + 12
                sectionFrame.Size = UDim2.new(1, -12, 0, h)
            end
            list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSectionSize)
            updateSectionSize()

            local section = {}
            local elementMethods = {"Button","Toggle","Label","Slider","Keybind","InputBox","Dropdown"}
            for _,m in ipairs(elementMethods) do
                section[m] = function(_, ...)
                    local beforeSnap = {}
                    for _,c in ipairs(tabWrapper._page:GetChildren()) do beforeSnap[c] = true end
                    local func = tabWrapper._elements[m]
                    if func then
                        pcall(function() func(tabWrapper._elements, ...) end)
                    else
                        warn("Adapter: original library missing element method:", m)
                    end
                    moveNewChildrenToSection(sectionFrame, beforeSnap)
                end
            end

            table.insert(tabWrapper._sections, {Title = title, Button = btn, Frame = sectionFrame})

            btn.MouseButton1Click:Connect(function()
                local absPage = tabWrapper._page.AbsolutePosition.Y
                local absSection = sectionFrame.AbsolutePosition.Y
                local offset = absSection - absPage
                tabWrapper._page.CanvasPosition = Vector2.new(0, offset)
                for _,s in ipairs(tabWrapper._sections) do
                    s.Button.BackgroundTransparency = 0.9
                end
                btn.BackgroundTransparency = 0.5
            end)

            return section
        end

        return tabWrapper
    end

    function wrapped:SetTheme(t)
        if LibraryModule.SetTheme then
            LibraryModule:SetTheme(t)
        end
    end

    return wrapped
end

return Adapter
