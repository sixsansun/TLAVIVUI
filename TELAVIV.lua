--[[
    TEL-AVIV MENU v2
    Single-file Roblox/Luau UI library.
    Designed to be loaded from a GitHub raw URL with loadstring(game:HttpGet(...))().

    UI only. Controls expose callbacks; the library contains no gameplay/cheat logic.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Library = {}
Library.__index = Library
Library.Version = "2.0.0"

local COLORS = {
    Window = Color3.fromRGB(8, 9, 13),
    Sidebar = Color3.fromRGB(10, 11, 16),
    Header = Color3.fromRGB(11, 12, 17),
    Panel = Color3.fromRGB(12, 13, 18),
    Control = Color3.fromRGB(15, 16, 22),
    Control2 = Color3.fromRGB(20, 22, 29),
    Stroke = Color3.fromRGB(27, 30, 38),
    StrokeSoft = Color3.fromRGB(21, 23, 30),
    Text = Color3.fromRGB(214, 216, 224),
    Muted = Color3.fromRGB(143, 146, 158),
    Muted2 = Color3.fromRGB(105, 108, 119),
    Blue = Color3.fromRGB(74, 148, 239),
    BlueBright = Color3.fromRGB(87, 164, 255),
    BlueDark = Color3.fromRGB(36, 91, 157),
    BlueSelection = Color3.fromRGB(23, 48, 79),
    White = Color3.fromRGB(244, 246, 250),
    Knob = Color3.fromRGB(194, 199, 209),
}

local function New(className, props, parent)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        object[key] = value
    end
    if parent then
        object.Parent = parent
    end
    return object
end

local function Corner(parent, radius)
    return New("UICorner", {
        CornerRadius = UDim.new(0, radius or 4)
    }, parent)
end

local function Stroke(parent, color, thickness, transparency)
    return New("UIStroke", {
        Color = color or COLORS.Stroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, parent)
end

local function Padding(parent, left, right, top, bottom)
    return New("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0)
    }, parent)
end

local function Label(parent, value, size, color, font, alignment)
    return New("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = value or "",
        TextColor3 = color or COLORS.Text,
        TextSize = size or 13,
        Font = font or Enum.Font.GothamMedium,
        TextXAlignment = alignment or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    }, parent)
end

local function Button(parent, value)
    return New("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = value or "",
        TextColor3 = COLORS.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium
    }, parent)
end

local function Tween(object, duration, props)
    TweenService:Create(
        object,
        TweenInfo.new(duration or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        props
    ):Play()
end

local function Fire(callback, ...)
    if typeof(callback) == "function" then
        task.spawn(callback, ...)
    end
end

local function Asset(value)
    if value == nil then
        return nil
    end
    if typeof(value) == "number" then
        return "rbxassetid://" .. tostring(value)
    end
    value = tostring(value)
    if value:match("^%d+$") then
        return "rbxassetid://" .. value
    end
    return value
end

local function PrettyKey(value)
    if value == nil or value == Enum.KeyCode.Unknown then
        return "None"
    end
    if typeof(value) == "string" then
        return value
    end
    if typeof(value) == "EnumItem" then
        local name = value.Name
        if name == "MouseButton1" then return "Mouse 1" end
        if name == "MouseButton2" then return "Mouse 2" end
        if name == "MouseButton3" then return "Mouse 3" end
        return name
    end
    return tostring(value)
end

local function MakeDraggable(handle, target)
    local dragging = false
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPosition = target.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function ResolveParent()
    if typeof(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then
            return result
        end
    end

    local ok, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok and coreGui then
        return coreGui
    end

    local player = Players.LocalPlayer
    if player then
        return player:WaitForChild("PlayerGui")
    end

    return nil
end

local function HookCanvas(scroller, layout, extra)
    local function update()
        scroller.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + (extra or 0))
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
    task.defer(update)
end

function Library.new(config)
    config = config or {}

    local self = setmetatable({}, Library)
    self.Config = config
    self.Categories = {}
    self.ActiveCategory = nil
    self._defaultCategory = nil

    local width = config.Width or 770
    local height = config.Height or 558

    local gui = New("ScreenGui", {
        Name = config.Name or "TEL_AVIV_MENU",
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    local parent = config.Parent or ResolveParent()
    if parent then
        gui.Parent = parent
    end
    self.Gui = gui

    local shadow = New("Frame", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(width + 10, height + 10),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.48,
        BorderSizePixel = 0,
        ZIndex = 0
    }, gui)
    Corner(shadow, 9)

    local main = New("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = COLORS.Window,
        BackgroundTransparency = config.WindowTransparency or 0.08,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 1
    }, gui)
    Corner(main, 7)
    Stroke(main, Color3.fromRGB(5, 6, 9), 1, 0.05)
    self.Main = main
    self.Shadow = shadow

    New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(13, 14, 19)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 8, 12))
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(1, 0.18)
        }),
        Rotation = 90
    }, main)

    local sidebarWidth = config.SidebarWidth or 160
    local headerHeight = config.HeaderHeight or 67

    local sidebar = New("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, sidebarWidth, 1, 0),
        BackgroundColor3 = COLORS.Sidebar,
        BackgroundTransparency = config.SidebarTransparency or 0.07,
        BorderSizePixel = 0,
        ZIndex = 2
    }, main)
    New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(13, 14, 19)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 9, 13))
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.02),
            NumberSequenceKeypoint.new(1, 0.12)
        }),
        Rotation = 90
    }, sidebar)

    New("Frame", {
        BackgroundColor3 = COLORS.StrokeSoft,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        ZIndex = 3
    }, sidebar)

    local logoHolder = New("Frame", {
        Name = "LogoHolder",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(18, 15),
        Size = UDim2.new(1, -36, 0, 82),
        ZIndex = 4
    }, sidebar)

    local logoAsset = Asset(config.Logo)
    if logoAsset then
        local glow = New("ImageLabel", {
            Name = "LogoGlow",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(config.LogoWidth or 100, config.LogoHeight or 62),
            Image = logoAsset,
            ImageColor3 = COLORS.Blue,
            ImageTransparency = 0.76,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 4
        }, logoHolder)

        local logo = New("ImageLabel", {
            Name = "Logo",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(config.LogoWidth or 92, config.LogoHeight or 56),
            Image = logoAsset,
            ImageColor3 = config.LogoColor or Color3.new(1, 1, 1),
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 5
        }, logoHolder)
        self.Logo = logo
        self.LogoGlow = glow
    end

    local categoryList = New("Frame", {
        Name = "CategoryList",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 108),
        Size = UDim2.new(1, -20, 1, -118),
        ZIndex = 4
    }, sidebar)
    local categoryLayout = New("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4)
    }, categoryList)

    local header = New("Frame", {
        Name = "Header",
        Position = UDim2.fromOffset(sidebarWidth, 0),
        Size = UDim2.new(1, -sidebarWidth, 0, headerHeight),
        BackgroundColor3 = COLORS.Header,
        BackgroundTransparency = config.HeaderTransparency or 0.15,
        BorderSizePixel = 0,
        ZIndex = 2
    }, main)
    New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 16, 21)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 11, 15))
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.10),
            NumberSequenceKeypoint.new(1, 0.22)
        }),
        Rotation = 90
    }, header)

    New("Frame", {
        BackgroundColor3 = COLORS.StrokeSoft,
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 3
    }, header)

    local title = Label(
        header,
        config.Title or "TEL-AVIV MENU",
        11,
        COLORS.Muted2,
        Enum.Font.GothamMedium,
        Enum.TextXAlignment.Right
    )
    title.Position = UDim2.new(1, -166, 0, 9)
    title.Size = UDim2.fromOffset(152, 18)
    title.TextTransparency = 0.16
    title.ZIndex = 5

    local tabHost = New("Frame", {
        Name = "TabHost",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -180, 1, 0),
        ZIndex = 4
    }, header)

    local contentHost = New("Frame", {
        Name = "ContentHost",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(sidebarWidth, headerHeight),
        Size = UDim2.new(1, -sidebarWidth, 1, -headerHeight),
        ZIndex = 2
    }, main)

    self.Sidebar = sidebar
    self.CategoryList = categoryList
    self.Header = header
    self.TabHost = tabHost
    self.ContentHost = contentHost

    MakeDraggable(header, main)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift
        if input.KeyCode == toggleKey then
            local visible = not main.Visible
            main.Visible = visible
            shadow.Visible = visible
        end
    end)

    function self:SetLogo(value)
        local a = Asset(value)
        if not a then return end
        if self.Logo then self.Logo.Image = a end
        if self.LogoGlow then self.LogoGlow.Image = a end
    end

    return self
end

function Library:AddCategory(options)
    if typeof(options) == "string" then
        options = {Name = options}
    end
    options = options or {}

    local window = self
    local category = {
        Name = options.Name or "Category",
        Tabs = {},
        ActiveTab = nil
    }

    local row = Button(self.CategoryList, "")
    row.Name = category.Name
    row.Size = UDim2.new(1, 0, 0, 45)
    row.BackgroundColor3 = COLORS.BlueSelection
    row.BackgroundTransparency = 1
    row.ZIndex = 5
    Corner(row, 5)

    local selectionGlow = New("Frame", {
        BackgroundColor3 = COLORS.Blue,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(-1, 6),
        Size = UDim2.fromOffset(3, 33),
        ZIndex = 5
    }, row)
    Corner(selectionGlow, 2)

    local iconHolder = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 9),
        Size = UDim2.fromOffset(26, 26),
        ZIndex = 6
    }, row)

    local iconAsset = Asset(options.Icon)
    if iconAsset then
        local iconGlow = New("ImageLabel", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(22, 22),
            Image = iconAsset,
            ImageColor3 = COLORS.Blue,
            ImageTransparency = 0.82,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 6
        }, iconHolder)

        local icon = New("ImageLabel", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(16, 16),
            Image = iconAsset,
            ImageColor3 = COLORS.Blue,
            ImageTransparency = 0.34,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 7
        }, iconHolder)
        category.Icon = icon
        category.IconGlow = iconGlow
    else
        local ring = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(13, 13),
            BackgroundColor3 = COLORS.Blue,
            BackgroundTransparency = 0.88,
            BorderSizePixel = 0,
            ZIndex = 6
        }, iconHolder)
        Corner(ring, 10)
        Stroke(ring, COLORS.Blue, 1, 0.48)

        local dot = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(3, 3),
            BackgroundColor3 = COLORS.Blue,
            BackgroundTransparency = 0.28,
            BorderSizePixel = 0,
            ZIndex = 7
        }, ring)
        Corner(dot, 10)
        category.Icon = ring
    end

    local nameLabel = Label(row, category.Name, 13, COLORS.Muted, Enum.Font.GothamSemibold)
    nameLabel.Position = UDim2.fromOffset(37, 0)
    nameLabel.Size = UDim2.new(1, -42, 1, 0)
    nameLabel.ZIndex = 6

    local tabBar = New("Frame", {
        Name = category.Name .. "_Tabs",
        BackgroundTransparency = 1,
        Visible = false,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 5
    }, self.TabHost)

    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 17)
    }, tabBar)

    category.Row = row
    category.Label = nameLabel
    category.SelectionGlow = selectionGlow
    category.TabBar = tabBar
    category.Window = window

    function category:SetSelected(state)
        if state then
            Tween(row, 0.14, {
                BackgroundTransparency = 0.08,
                BackgroundColor3 = COLORS.BlueSelection
            })
            Tween(selectionGlow, 0.14, {BackgroundTransparency = 0.28})
            Tween(nameLabel, 0.14, {TextColor3 = Color3.fromRGB(160, 195, 245)})
            if category.Icon and category.Icon:IsA("ImageLabel") then
                Tween(category.Icon, 0.14, {ImageTransparency = 0.05})
            elseif category.Icon then
                Tween(category.Icon, 0.14, {BackgroundTransparency = 0.76})
            end
        else
            Tween(row, 0.14, {BackgroundTransparency = 1})
            Tween(selectionGlow, 0.14, {BackgroundTransparency = 1})
            Tween(nameLabel, 0.14, {TextColor3 = COLORS.Muted})
            if category.Icon and category.Icon:IsA("ImageLabel") then
                Tween(category.Icon, 0.14, {ImageTransparency = 0.36})
            elseif category.Icon then
                Tween(category.Icon, 0.14, {BackgroundTransparency = 0.88})
            end
        end
    end

    function category:Select()
        if window.ActiveCategory == category then
            return
        end

        for _, other in ipairs(window.Categories) do
            other:SetSelected(false)
            other.TabBar.Visible = false
            for _, tab in ipairs(other.Tabs) do
                tab.Page.Visible = false
            end
        end

        window.ActiveCategory = category
        category:SetSelected(true)
        category.TabBar.Visible = true

        if not category.ActiveTab and category.Tabs[1] then
            category.Tabs[1]:Select()
        elseif category.ActiveTab then
            category.ActiveTab:Select()
        end
    end

    row.MouseEnter:Connect(function()
        if window.ActiveCategory ~= category then
            Tween(row, 0.10, {
                BackgroundTransparency = 0.78,
                BackgroundColor3 = Color3.fromRGB(19, 27, 38)
            })
        end
    end)

    row.MouseLeave:Connect(function()
        if window.ActiveCategory ~= category then
            Tween(row, 0.10, {BackgroundTransparency = 1})
        end
    end)

    row.MouseButton1Click:Connect(function()
        category:Select()
    end)

    function category:AddTab(name)
        local tab = {
            Name = name,
            Category = category,
            Window = window
        }

        local tabButton = Button(category.TabBar, name)
        tabButton.Size = UDim2.fromOffset(math.max(72, (#name * 7) + 22), 67)
        tabButton.TextSize = 14
        tabButton.Font = Enum.Font.GothamSemibold
        tabButton.TextColor3 = COLORS.Muted
        tabButton.ZIndex = 6

        local tabGlow = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(0.56, 0, 0, 2),
            BackgroundColor3 = COLORS.Blue,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 6
        }, tabButton)
        Corner(tabGlow, 2)

        local page = New("Frame", {
            Name = category.Name .. "_" .. name .. "_Page",
            BackgroundTransparency = 1,
            Visible = false,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 3
        }, window.ContentHost)

        Padding(page, 10, 10, 9, 10)

        local columns = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 3
        }, page)

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10)
        }, columns)

        local left = New("Frame", {
            Name = "LeftColumn",
            BackgroundTransparency = 1,
            Size = UDim2.new(0.515, -5, 1, 0),
            ZIndex = 3
        }, columns)

        local right = New("Frame", {
            Name = "RightColumn",
            BackgroundTransparency = 1,
            Size = UDim2.new(0.485, -5, 1, 0),
            ZIndex = 3
        }, columns)

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10)
        }, left)

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10)
        }, right)

        tab.Button = tabButton
        tab.Glow = tabGlow
        tab.Page = page
        tab.Left = left
        tab.Right = right

        function tab:SetSelected(state)
            if state then
                Tween(tabButton, 0.12, {TextColor3 = COLORS.Blue})
                Tween(tabGlow, 0.12, {BackgroundTransparency = 0.42})
            else
                Tween(tabButton, 0.12, {TextColor3 = COLORS.Muted})
                Tween(tabGlow, 0.12, {BackgroundTransparency = 1})
            end
        end

        function tab:Select()
            if window.ActiveCategory ~= category then
                category:Select()
            end

            for _, other in ipairs(category.Tabs) do
                other.Page.Visible = false
                other:SetSelected(false)
            end

            category.ActiveTab = tab
            page.Visible = true
            tab:SetSelected(true)
        end

        tabButton.MouseEnter:Connect(function()
            if category.ActiveTab ~= tab then
                Tween(tabButton, 0.10, {TextColor3 = Color3.fromRGB(181, 184, 194)})
            end
        end)

        tabButton.MouseLeave:Connect(function()
            if category.ActiveTab ~= tab then
                Tween(tabButton, 0.10, {TextColor3 = COLORS.Muted})
            end
        end)

        tabButton.MouseButton1Click:Connect(function()
            tab:Select()
        end)

        function tab:AddSection(titleText, side, options)
            options = options or {}
            local parentColumn = (side == "right") and right or left
            local height = options.Height or 455

            local section = {
                Title = titleText,
                Tab = tab
            }

            local frame = New("Frame", {
                Name = titleText .. "_Section",
                BackgroundColor3 = COLORS.Panel,
                BackgroundTransparency = options.Transparency or 0.16,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, height),
                ClipsDescendants = true,
                ZIndex = 4
            }, parentColumn)
            Corner(frame, 5)
            Stroke(frame, COLORS.Stroke, 1, 0.08)

            New("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 16, 21)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 11, 15))
                }),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.04),
                    NumberSequenceKeypoint.new(1, 0.13)
                }),
                Rotation = 90
            }, frame)

            local sectionTitle = Label(
                frame,
                titleText,
                14,
                COLORS.Text,
                Enum.Font.GothamSemibold
            )
            sectionTitle.Position = UDim2.fromOffset(11, 7)
            sectionTitle.Size = UDim2.new(1, -22, 0, 22)
            sectionTitle.ZIndex = 6

            local scroller = New("ScrollingFrame", {
                Name = "Controls",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.fromOffset(10, 34),
                Size = UDim2.new(1, -17, 1, -42),
                CanvasSize = UDim2.fromOffset(0, 0),
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = COLORS.Blue,
                ScrollBarImageTransparency = 0.02,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ElasticBehavior = Enum.ElasticBehavior.Never,
                VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
                ZIndex = 5
            }, frame)

            local list = New("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5)
            }, scroller)
            HookCanvas(scroller, list, 7)

            section.Frame = frame
            section.Scroller = scroller
            section.Layout = list

            local function Row(heightPixels)
                return New("Frame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -3, 0, heightPixels),
                    ZIndex = 6
                }, scroller)
            end

            function section:AddToggle(opts)
                opts = opts or {}
                local value = opts.Default == true
                local rowControl = Row(31)

                local name = Label(
                    rowControl,
                    opts.Name or "Toggle",
                    13,
                    COLORS.Text,
                    Enum.Font.GothamMedium
                )
                name.Size = UDim2.new(1, -42, 1, 0)
                name.ZIndex = 7

                local glow = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.fromOffset(25, 25),
                    BackgroundColor3 = COLORS.Blue,
                    BackgroundTransparency = value and 0.76 or 1,
                    BorderSizePixel = 0,
                    ZIndex = 6
                }, rowControl)
                Corner(glow, 4)

                local box = Button(rowControl, "")
                box.AnchorPoint = Vector2.new(0.5, 0.5)
                box.Position = UDim2.new(1, -12, 0.5, 0)
                box.Size = UDim2.fromOffset(18, 18)
                box.BackgroundTransparency = 0
                box.BackgroundColor3 = value and COLORS.BlueDark or Color3.fromRGB(18, 31, 44)
                box.ZIndex = 8
                Corner(box, 2)
                Stroke(box, value and COLORS.Blue or Color3.fromRGB(25, 42, 58), 1, 0.08)

                local check = Label(
                    box,
                    "v",
                    13,
                    COLORS.White,
                    Enum.Font.GothamBold,
                    Enum.TextXAlignment.Center
                )
                check.Size = UDim2.fromScale(1, 1)
                check.Position = UDim2.fromOffset(0, -1)
                check.Rotation = 0
                check.Visible = value
                check.ZIndex = 9

                local function set(newValue, fire)
                    value = not not newValue
                    check.Visible = value
                    Tween(box, 0.10, {
                        BackgroundColor3 = value and COLORS.BlueDark or Color3.fromRGB(18, 31, 44)
                    })
                    Tween(glow, 0.10, {
                        BackgroundTransparency = value and 0.76 or 1
                    })
                    if fire then
                        Fire(opts.Callback, value)
                    end
                end

                box.MouseButton1Click:Connect(function()
                    set(not value, true)
                end)

                return {
                    Get = function()
                        return value
                    end,
                    Set = function(_, newValue)
                        set(newValue, true)
                    end
                }
            end

            function section:AddSlider(opts)
                opts = opts or {}
                local minimum = opts.Min or 0
                local maximum = opts.Max or 100
                local step = opts.Step or 1
                local value = math.clamp(opts.Default or minimum, minimum, maximum)

                local rowControl = Row(49)

                local name = Label(
                    rowControl,
                    opts.Name or "Slider",
                    13,
                    COLORS.Muted,
                    Enum.Font.GothamMedium
                )
                name.Size = UDim2.new(1, -78, 0, 20)
                name.ZIndex = 7

                local valueLabel = Label(
                    rowControl,
                    "",
                    13,
                    COLORS.Text,
                    Enum.Font.GothamMedium,
                    Enum.TextXAlignment.Right
                )
                valueLabel.Position = UDim2.new(1, -76, 0, 0)
                valueLabel.Size = UDim2.fromOffset(76, 20)
                valueLabel.ZIndex = 7

                local track = New("Frame", {
                    Name = "Track",
                    Position = UDim2.fromOffset(0, 31),
                    Size = UDim2.new(1, -2, 0, 5),
                    BackgroundColor3 = Color3.fromRGB(24, 27, 34),
                    BackgroundTransparency = 0.02,
                    BorderSizePixel = 0,
                    ZIndex = 7
                }, rowControl)
                Corner(track, 3)

                local glow = New("Frame", {
                    Name = "FillGlow",
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.fromScale(0, 0.5),
                    Size = UDim2.new(0, 0, 0, 11),
                    BackgroundColor3 = COLORS.Blue,
                    BackgroundTransparency = 0.74,
                    BorderSizePixel = 0,
                    ZIndex = 7
                }, track)
                Corner(glow, 6)

                local fill = New("Frame", {
                    Name = "Fill",
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = COLORS.Blue,
                    BorderSizePixel = 0,
                    ZIndex = 8
                }, track)
                Corner(fill, 3)
                New("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, COLORS.BlueDark),
                        ColorSequenceKeypoint.new(1, COLORS.BlueBright)
                    }),
                    Rotation = 0
                }, fill)

                local knob = New("Frame", {
                    Name = "Knob",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.fromOffset(8, 13),
                    BackgroundColor3 = COLORS.Knob,
                    BorderSizePixel = 0,
                    ZIndex = 10
                }, track)
                Corner(knob, 3)
                Stroke(knob, Color3.fromRGB(107, 112, 123), 1, 0.02)

                local hitbox = Button(rowControl, "")
                hitbox.Position = UDim2.fromOffset(0, 22)
                hitbox.Size = UDim2.new(1, -2, 0, 25)
                hitbox.ZIndex = 11

                local dragging = false

                local function formatValue(v)
                    if opts.Format then
                        return opts.Format(v)
                    end
                    if step < 1 then
                        local decimals = math.max(0, math.ceil(-math.log10(step)))
                        return string.format("%." .. decimals .. "f", v)
                    end
                    return tostring(math.floor(v + 0.5))
                end

                local function render()
                    local alpha = (value - minimum) / math.max(0.000001, maximum - minimum)
                    fill.Size = UDim2.new(alpha, 0, 1, 0)
                    glow.Size = UDim2.new(alpha, 0, 0, 11)
                    knob.Position = UDim2.new(alpha, 0, 0.5, 0)
                    valueLabel.Text = formatValue(value)
                end

                local function setFromX(x, fire)
                    local width = math.max(1, track.AbsoluteSize.X)
                    local alpha = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
                    local raw = minimum + ((maximum - minimum) * alpha)
                    local stepped = math.floor((raw / step) + 0.5) * step
                    value = math.clamp(stepped, minimum, maximum)
                    render()
                    if fire then
                        Fire(opts.Callback, value)
                    end
                end

                hitbox.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        setFromX(input.Position.X, true)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if not dragging then return end
                    if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                        setFromX(input.Position.X, true)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)

                render()

                return {
                    Get = function()
                        return value
                    end,
                    Set = function(_, newValue)
                        value = math.clamp(newValue, minimum, maximum)
                        render()
                        Fire(opts.Callback, value)
                    end
                }
            end

            function section:AddDropdown(opts)
                opts = opts or {}
                local values = opts.Values or {"Option"}
                local current = opts.Default or values[1]
                local opened = false

                local closedHeight = 35
                local itemHeight = 31
                local maxVisible = math.min(#values, opts.MaxVisible or 5)
                local openHeight = closedHeight + (maxVisible * itemHeight) + 7

                local rowControl = Row(closedHeight)

                local name = Label(
                    rowControl,
                    opts.Name or "Dropdown",
                    13,
                    COLORS.Text,
                    Enum.Font.GothamMedium
                )
                name.Size = UDim2.new(0.50, -5, 0, closedHeight)
                name.ZIndex = 7

                local box = Button(rowControl, "")
                box.Position = UDim2.new(0.50, 0, 0, 2)
                box.Size = UDim2.new(0.50, -2, 0, 30)
                box.BackgroundColor3 = COLORS.Control
                box.BackgroundTransparency = 0.10
                box.ZIndex = 8
                Corner(box, 3)
                Stroke(box, COLORS.Stroke, 1, 0.10)

                local selected = Label(
                    box,
                    tostring(current),
                    12,
                    COLORS.Text,
                    Enum.Font.GothamMedium
                )
                selected.Position = UDim2.fromOffset(9, 0)
                selected.Size = UDim2.new(1, -31, 1, 0)
                selected.ZIndex = 9

                local arrow = Label(
                    box,
                    "v",
                    11,
                    COLORS.Muted,
                    Enum.Font.GothamBold,
                    Enum.TextXAlignment.Center
                )
                arrow.Position = UDim2.new(1, -24, 0, 0)
                arrow.Size = UDim2.fromOffset(24, 30)
                arrow.ZIndex = 9

                local popup = New("ScrollingFrame", {
                    BackgroundColor3 = Color3.fromRGB(11, 12, 17),
                    BackgroundTransparency = 0.04,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0.50, 0, 0, 35),
                    Size = UDim2.new(0.50, -2, 0, maxVisible * itemHeight + 6),
                    Visible = false,
                    CanvasSize = UDim2.fromOffset(0, #values * itemHeight),
                    ScrollBarThickness = (#values > maxVisible) and 2 or 0,
                    ScrollBarImageColor3 = COLORS.Blue,
                    ScrollBarImageTransparency = 0.15,
                    ZIndex = 20
                }, rowControl)
                Corner(popup, 3)
                Stroke(popup, COLORS.Stroke, 1, 0.04)
                Padding(popup, 4, 4, 3, 3)

                local popupLayout = New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 0)
                }, popup)

                local function close()
                    opened = false
                    popup.Visible = false
                    rowControl.Size = UDim2.new(1, -3, 0, closedHeight)
                    arrow.Text = "v"
                end

                for _, option in ipairs(values) do
                    local item = Button(popup, tostring(option))
                    item.Size = UDim2.new(1, 0, 0, itemHeight)
                    item.TextXAlignment = Enum.TextXAlignment.Left
                    item.TextSize = 13
                    item.BackgroundColor3 = COLORS.Control2
                    item.BackgroundTransparency = 1
                    item.ZIndex = 21
                    Padding(item, 8, 4, 0, 0)

                    local dot = New("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromOffset(5, itemHeight / 2),
                        Size = UDim2.fromOffset(5, 5),
                        BackgroundColor3 = COLORS.Blue,
                        BackgroundTransparency = (option == current) and 0.05 or 1,
                        BorderSizePixel = 0,
                        ZIndex = 22
                    }, item)
                    Corner(dot, 4)

                    item.MouseEnter:Connect(function()
                        Tween(item, 0.08, {
                            BackgroundTransparency = 0.55,
                            BackgroundColor3 = COLORS.Control2
                        })
                    end)

                    item.MouseLeave:Connect(function()
                        Tween(item, 0.08, {BackgroundTransparency = 1})
                    end)

                    item.MouseButton1Click:Connect(function()
                        current = option
                        selected.Text = tostring(option)

                        for _, child in ipairs(popup:GetChildren()) do
                            if child:IsA("TextButton") then
                                local childDot = child:FindFirstChildOfClass("Frame")
                                if childDot then
                                    childDot.BackgroundTransparency =
                                        (child.Text == tostring(option)) and 0.05 or 1
                                end
                            end
                        end

                        close()
                        Fire(opts.Callback, option)
                    end)
                end

                box.MouseButton1Click:Connect(function()
                    opened = not opened
                    popup.Visible = opened
                    rowControl.Size = UDim2.new(
                        1,
                        -3,
                        0,
                        opened and openHeight or closedHeight
                    )
                    arrow.Text = opened and "^" or "v"
                end)

                return {
                    Get = function()
                        return current
                    end,
                    Set = function(_, value)
                        current = value
                        selected.Text = tostring(value)
                        Fire(opts.Callback, value)
                    end,
                    Close = close
                }
            end

            function section:AddKeybind(opts)
                opts = opts or {}
                local current = opts.Default or Enum.KeyCode.Unknown
                local waiting = false

                local rowControl = Row(35)

                local name = Label(
                    rowControl,
                    opts.Name or "Bind",
                    13,
                    COLORS.Text,
                    Enum.Font.GothamMedium
                )
                name.Size = UDim2.new(0.56, 0, 1, 0)
                name.ZIndex = 7

                local keyButton = Button(rowControl, PrettyKey(current))
                keyButton.Position = UDim2.new(0.56, 0, 0, 2)
                keyButton.Size = UDim2.new(0.44, -2, 0, 30)
                keyButton.BackgroundColor3 = COLORS.Control
                keyButton.BackgroundTransparency = 0.08
                keyButton.ZIndex = 8
                Corner(keyButton, 3)
                Stroke(keyButton, COLORS.Stroke, 1, 0.10)

                keyButton.MouseButton1Click:Connect(function()
                    waiting = true
                    keyButton.Text = "..."
                    Tween(keyButton, 0.10, {TextColor3 = COLORS.Blue})
                end)

                UserInputService.InputBegan:Connect(function(input)
                    if not waiting then
                        return
                    end

                    local value
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        value = input.KeyCode
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.MouseButton2
                    or input.UserInputType == Enum.UserInputType.MouseButton3 then
                        value = input.UserInputType
                    end

                    if value then
                        current = value
                        waiting = false
                        keyButton.Text = PrettyKey(current)
                        Tween(keyButton, 0.10, {TextColor3 = COLORS.Text})
                        Fire(opts.Callback, current)
                    end
                end)

                return {
                    Get = function()
                        return current
                    end,
                    Set = function(_, value)
                        current = value
                        keyButton.Text = PrettyKey(current)
                        Fire(opts.Callback, current)
                    end
                }
            end

            function section:AddColorPicker(opts)
                opts = opts or {}
                local current = opts.Default or Color3.new(1, 1, 1)
                local presets = opts.Presets or {
                    Color3.fromRGB(255, 255, 255),
                    Color3.fromRGB(74, 148, 239),
                    Color3.fromRGB(255, 88, 88),
                    Color3.fromRGB(111, 232, 142),
                    Color3.fromRGB(194, 110, 255),
                    Color3.fromRGB(255, 196, 90)
                }
                local opened = false

                local rowControl = Row(31)

                local name = Label(
                    rowControl,
                    opts.Name or "Color",
                    13,
                    COLORS.Text,
                    Enum.Font.GothamMedium
                )
                name.Size = UDim2.new(1, -42, 1, 0)
                name.ZIndex = 7

                local swatchGlow = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.fromOffset(24, 24),
                    BackgroundColor3 = current,
                    BackgroundTransparency = 0.82,
                    BorderSizePixel = 0,
                    ZIndex = 6
                }, rowControl)
                Corner(swatchGlow, 4)

                local swatch = Button(rowControl, "")
                swatch.AnchorPoint = Vector2.new(0.5, 0.5)
                swatch.Position = UDim2.new(1, -12, 0.5, 0)
                swatch.Size = UDim2.fromOffset(18, 18)
                swatch.BackgroundColor3 = current
                swatch.BackgroundTransparency = 0
                swatch.ZIndex = 8
                Corner(swatch, 3)
                Stroke(swatch, Color3.fromRGB(200, 203, 210), 1, 0.45)

                local palette = New("Frame", {
                    BackgroundColor3 = Color3.fromRGB(11, 12, 17),
                    BackgroundTransparency = 0.02,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -154, 1, 3),
                    Size = UDim2.fromOffset(150, 38),
                    Visible = false,
                    ZIndex = 20
                }, rowControl)
                Corner(palette, 4)
                Stroke(palette, COLORS.Stroke, 1, 0.04)
                Padding(palette, 7, 7, 7, 7)

                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 6)
                }, palette)

                local function set(value, fire)
                    current = value
                    swatch.BackgroundColor3 = value
                    swatchGlow.BackgroundColor3 = value
                    if fire then
                        Fire(opts.Callback, value)
                    end
                end

                for _, value in ipairs(presets) do
                    local p = Button(palette, "")
                    p.Size = UDim2.fromOffset(18, 18)
                    p.BackgroundTransparency = 0
                    p.BackgroundColor3 = value
                    p.ZIndex = 21
                    Corner(p, 3)
                    Stroke(p, Color3.fromRGB(200, 203, 210), 1, 0.60)

                    p.MouseButton1Click:Connect(function()
                        set(value, true)
                        opened = false
                        palette.Visible = false
                        rowControl.Size = UDim2.new(1, -3, 0, 31)
                    end)
                end

                swatch.MouseButton1Click:Connect(function()
                    opened = not opened
                    palette.Visible = opened
                    rowControl.Size = UDim2.new(1, -3, 0, opened and 74 or 31)
                end)

                return {
                    Get = function()
                        return current
                    end,
                    Set = function(_, value)
                        set(value, true)
                    end
                }
            end

            function section:AddButton(opts)
                opts = opts or {}
                local rowControl = Row(37)

                local action = Button(rowControl, opts.Name or "Button")
                action.Size = UDim2.new(1, 0, 0, 32)
                action.BackgroundColor3 = COLORS.Control
                action.BackgroundTransparency = 0.08
                action.TextSize = 13
                action.ZIndex = 8
                Corner(action, 3)
                Stroke(action, COLORS.Stroke, 1, 0.08)

                action.MouseEnter:Connect(function()
                    Tween(action, 0.10, {
                        BackgroundColor3 = Color3.fromRGB(22, 27, 35),
                        TextColor3 = COLORS.Blue
                    })
                end)

                action.MouseLeave:Connect(function()
                    Tween(action, 0.10, {
                        BackgroundColor3 = COLORS.Control,
                        TextColor3 = COLORS.Text
                    })
                end)

                action.MouseButton1Click:Connect(function()
                    Fire(opts.Callback)
                end)

                return action
            end

            function section:AddLabel(value)
                local rowControl = Row(27)
                local label = Label(
                    rowControl,
                    tostring(value or ""),
                    13,
                    COLORS.Muted,
                    Enum.Font.GothamMedium
                )
                label.Size = UDim2.fromScale(1, 1)
                label.ZIndex = 7
                return label
            end

            function section:SetHeight(newHeight)
                frame.Size = UDim2.new(1, 0, 0, newHeight)
            end

            return section
        end

        table.insert(category.Tabs, tab)

        if not category.ActiveTab then
            category.ActiveTab = tab
        end

        if window.ActiveCategory == category and #category.Tabs == 1 then
            tab:Select()
        end

        return tab
    end

    table.insert(self.Categories, category)

    if not self.ActiveCategory and options.AutoSelect ~= false then
        category:Select()
    end

    return category
end

-- Compatibility helper.
-- If you call Window:AddTab("Main") without categories, a hidden/default category is created.
function Library:AddTab(name)
    if not self._defaultCategory then
        self._defaultCategory = self:AddCategory({
            Name = "Main",
            AutoSelect = true
        })
    end
    return self._defaultCategory:AddTab(name)
end

-- Compatibility alias: returns a real functional category now.
function Library:AddSidebarItem(name, icon)
    return self:AddCategory({
        Name = name,
        Icon = icon
    })
end

function Library:SetVisible(state)
    self.Main.Visible = not not state
    self.Shadow.Visible = not not state
end

function Library:Toggle()
    self:SetVisible(not self.Main.Visible)
end

function Library:Destroy()
    if self.Gui then
        self.Gui:Destroy()
    end
end

return Library
