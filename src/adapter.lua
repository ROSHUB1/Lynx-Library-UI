-- Compatibility adapter updated: returns element handles from Section-created elements and supports two-column layout
local Adapter = {}

function Adapter.CreateWindow(LibraryModule, title, logoAsset, opts)
    opts = opts or {}
    local TabFunctions, window = LibraryModule:Window(title, logoAsset, opts)
    local wrapped = {}

    local function snapshotPages()
        local pages = {}
        for _,c in ipairs(window.Pages:GetChildren()) do if c:IsA("ScrollingFrame") then pages[c]=true end end
        return pages
    end

    function wrapped:Tab(tabInfo)
        local before = snapshotPages()
        local Elements = TabFunctions:Tab(tabInfo)
        local newPage
        for _,c in ipairs(window.Pages:GetChildren()) do if c:IsA("ScrollingFrame") and not before[c] then newPage=c; break end end
        if not newPage then for i=#window.Pages:GetChildren(),1,-1 do local c = window.Pages:GetChildren()[i]; if c:IsA("ScrollingFrame") then newPage=c; break end end end

        local tabWrapper = {}
        for k,v in pairs(Elements) do tabWrapper[k]=v end

        -- create header
        local headerHeight = 44
        local header = Instance.new("Frame") header.Name = "SectionsHeader" header.Parent = window.Pages header.BackgroundTransparency = 1 header.Size = UDim2.new(1,0,0,headerHeight) header.Position = newPage.Position header.ZIndex = 5
        local headerLayout = Instance.new("UIListLayout") headerLayout.Parent = header headerLayout.SortOrder = Enum.SortOrder.LayoutOrder headerLayout.Padding = UDim.new(0,8) headerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        local headerPadding = Instance.new("UIPadding") headerPadding.Parent = header headerPadding.PaddingLeft = UDim.new(0,8) headerPadding.PaddingTop=UDim.new(0,6) headerPadding.PaddingBottom=UDim.new(0,6)

        -- shift page to make room for header
        newPage.Position = UDim2.new(newPage.Position.X.Scale, newPage.Position.X.Offset, 0, headerHeight)
        newPage.Size = UDim2.new(newPage.Size.X.Scale, newPage.Size.X.Offset, 1, -headerHeight)
        newPage:GetPropertyChangedSignal("Visible"):Connect(function() header.Visible = newPage.Visible end)
        header.Visible = newPage.Visible

        -- create two columns container inside page
        local cols = Instance.new("Frame") cols.Name = "SectionsColumns" cols.Parent = newPage cols.BackgroundTransparency = 1 cols.Size = UDim2.new(1, -12, 1, 0) cols.Position = UDim2.new(0,6,0,0)
        local leftCol = Instance.new("Frame") leftCol.Name="LeftCol" leftCol.Parent=cols leftCol.BackgroundTransparency=1 leftCol.Size=UDim2.new(0.5, -6, 1, 0) leftCol.Position=UDim2.new(0,0,0,0)
        local rightCol = Instance.new("Frame") rightCol.Name="RightCol" rightCol.Parent=cols rightCol.BackgroundTransparency=1 rightCol.Size=UDim2.new(0.5, -6, 1, 0) rightCol.Position=UDim2.new(0.5, 12, 0, 0)
        local leftList = Instance.new("UIListLayout") leftList.Parent = leftCol leftList.SortOrder = Enum.SortOrder.LayoutOrder leftList.Padding = UDim.new(0,8)
        local rightList = Instance.new("UIListLayout") rightList.Parent = rightCol rightList.SortOrder = Enum.SortOrder.LayoutOrder rightList.Padding = UDim.new(0,8)

        tabWrapper._page = newPage
        tabWrapper._header = header
        tabWrapper._elements = Elements
        tabWrapper._sections = {}
        tabWrapper._cols = { Left = leftCol, Right = rightCol }

        local function moveNewChildren(targetFrame, beforeSnap)
            for _, child in ipairs(tabWrapper._page:GetChildren()) do
                if not beforeSnap[child] and child ~= cols and child ~= header then
                    child.Parent = targetFrame
                end
            end
        end

        function tabWrapper:Section(opts)
            opts = opts or {}
            local title = opts.Text or "Section"
            local side = opts.Side or "Left"
            side = (side:lower()=="right") and "Right" or "Left"

            local btn = Instance.new("TextButton") btn.Name="SectionButton" btn.AutoButtonColor=false btn.BackgroundColor3=Color3.fromRGB(60,60,60) btn.BackgroundTransparency=0.9 btn.Size=UDim2.new(0,160,0,30) btn.Font=Enum.Font.GothamSemibold btn.Text=title btn.TextColor3=Color3.fromRGB(230,230,230) btn.TextSize=14 btn.Parent=header
            local btnCorner = Instance.new("UICorner") btnCorner.CornerRadius=UDim.new(0,16) btnCorner.Parent=btn

            local sectionFrame = Instance.new("Frame") sectionFrame.Name = ("Section_%s"):format(title:gsub("%s+","_")) sectionFrame.Parent = tabWrapper._cols[side] sectionFrame.BackgroundTransparency = 1 sectionFrame.Size = UDim2.new(1,0,0,0) sectionFrame.LayoutOrder = #tabWrapper._sections + 1
            local padding = Instance.new("UIPadding") padding.Parent=sectionFrame padding.PaddingLeft=UDim.new(0,6) padding.PaddingRight=UDim.new(0,6) padding.PaddingTop=UDim.new(0,6) padding.PaddingBottom=UDim.new(0,6)
            local list = Instance.new("UIListLayout") list.Parent = sectionFrame list.SortOrder=Enum.SortOrder.LayoutOrder list.Padding = UDim.new(0,6)
            list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sectionFrame.Size = UDim2.new(1,0,0, list.AbsoluteContentSize.Y + 12) end)

            local section = {}
            local methods = {"Button","Toggle","Label","Slider","Keybind","InputBox","Dropdown"}
            for _,m in ipairs(methods) do
                section[m] = function(_, ...)
                    local beforeSnap = {}
                    for _,c in ipairs(tabWrapper._page:GetChildren()) do beforeSnap[c]=true end
                    local func = tabWrapper._elements[m]
                    local ok, ret
                    if func then ok, ret = pcall(function() return func(tabWrapper._elements, ...) end) end
                    moveNewChildren(sectionFrame, beforeSnap)
                    return (ok and ret) or nil
                end
            end

            table.insert(tabWrapper._sections, {Title=title, Button=btn, Frame=sectionFrame, Side=side})

            btn.MouseButton1Click:Connect(function()
                -- scroll page to this sectionFrame
                RunService.Heartbeat:Wait()
                local pageAbs = tabWrapper._page.AbsolutePosition.Y
                local secAbs = sectionFrame.AbsolutePosition.Y
                local offset = secAbs - pageAbs
                tabWrapper._page.CanvasPosition = Vector2.new(0, offset)
                -- highlight selected
                for _,s in ipairs(tabWrapper._sections) do s.Button.BackgroundTransparency = 0.9 end
                btn.BackgroundTransparency = 0.6
            end)

            return section
        end

        return tabWrapper
    end

    function wrapped:SetTheme(t) if LibraryModule.SetTheme then LibraryModule:SetTheme(t) end end
    return wrapped
end

return Adapter
