--[[
    TEL-AVIV MENU v4.2
    Single-file Roblox/Luau UI library.
    Designed to be loaded from a GitHub raw URL with loadstring(game:HttpGet(...))().

    UI only. Controls expose callbacks; the library contains no gameplay/cheat logic.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Library = {}
Library.__index = Library
Library.Version = "4.3.0-fullpalette"

local COLORS = {
    Window = Color3.fromRGB(7, 8, 12),
    Sidebar = Color3.fromRGB(8, 9, 13),
    Header = Color3.fromRGB(10, 11, 16),
    Panel = Color3.fromRGB(9, 10, 14),
    Control = Color3.fromRGB(15, 16, 22),
    Control2 = Color3.fromRGB(20, 22, 29),
    Stroke = Color3.fromRGB(27, 30, 38),
    StrokeSoft = Color3.fromRGB(21, 23, 30),
    Text = Color3.fromRGB(235, 237, 243),
    Muted = Color3.fromRGB(177, 180, 190),
    Muted2 = Color3.fromRGB(138, 141, 152),
    Blue = Color3.fromRGB(65, 139, 235),
    BlueBright = Color3.fromRGB(98, 176, 255),
    BlueDark = Color3.fromRGB(36, 91, 157),
    BlueSelection = Color3.fromRGB(22, 49, 82),
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


-- Native blurred shadow when the client supports UIShadow.
-- A layered-frame fallback is used elsewhere for clients/executors without it.
local function Shadow(parent, color, transparency, blurRadius, offset, spread)
    local ok, object = pcall(function()
        return Instance.new("UIShadow")
    end)
    if not ok or not object then
        return nil
    end

    object.Color = color or Color3.new(0, 0, 0)
    object.Transparency = transparency or 0.72
    object.BlurRadius = UDim.new(0, blurRadius or 12)
    object.Offset = offset or UDim2.fromOffset(0, 0)
    object.Spread = spread or UDim2.fromOffset(1, 1)
    object.ZIndex = -1
    object.Parent = parent
    return object
end

-- Lucide-style icon names, resolved through the same remote-icon-pack approach
-- used by the reference library supplied by the user.
local Icons = {}
local DEFAULT_ICON_SOURCE =
    "https://raw.githubusercontent.com/sixsansun/Library/refs/heads/main/icons"

pcall(function()
    local source = game:HttpGet(DEFAULT_ICON_SOURCE)
    local loader = loadstring(source)
    if loader then
        local result = loader()
        if type(result) == "table" then
            Icons = result
        end
    end
end)

local IconAliases = {
    ["home"] = "house",
    ["user"] = "person",
    ["user-round"] = "personCropCircle",
    ["users"] = "person2",
    ["eye"] = "eye",
    ["crosshair"] = "dotCrosshair",
    ["globe"] = "globe",
    ["wifi"] = "wifi",
    ["map-pin"] = "mappin",
    ["package"] = "shippingbox",
    ["package-plus"] = "shippingbox",
    ["box"] = "shippingbox",
    ["code"] = "chevronLeftForwardslashChevronRight",
    ["code-2"] = "chevronLeftForwardslashChevronRight",
    ["braces"] = "curlybraces",
    ["sliders-horizontal"] = "sliderHorizontal3",
    ["settings"] = "gearshape",
    ["settings-2"] = "gearshape2",
    ["wrench"] = "wrench",
    ["car"] = "car",
    ["move"] = "figureWalk",
    ["skull"] = "exclamationmarkTriangle",
}

local BuiltInIcons = {
    ["house"] = "rbxassetid://137977066267668",
    ["figureWalk"] = "rbxassetid://79511822122227",
    ["mappin"] = "rbxassetid://121615146959714",
    ["car"] = "rbxassetid://128495454882226",
    ["person2"] = "rbxassetid://112399905717309",
    ["eye"] = "rbxassetid://111055543166389",
    ["dotCrosshair"] = "rbxassetid://111411956958702",
    ["exclamationmarkTriangle"] = "rbxassetid://107822175160368",
}

local DefaultCategoryIcons = {
    Self = "user-round",
    View = "eye",
    Combat = "crosshair",
    Online = "users",
    Spawner = "package-plus",
    Script = "code-2",
    Misc = "sliders-horizontal",
    Config = "settings",
}

-- Guaranteed fallback assets from the same icon-pack family used by
-- the supplied reference library. This removes the "no icon at all"
-- failure mode when the remote pack cannot be downloaded.
local DefaultCategoryAssets = {
    Self = "rbxassetid://112399905717309",      -- person2
    View = "rbxassetid://111055543166389",      -- eye
    Combat = "rbxassetid://111411956958702",    -- dotCrosshair
    Online = "rbxassetid://137977066267668",    -- house / online hub fallback
    Spawner = "rbxassetid://121615146959714",   -- mappin
    Script = "rbxassetid://107822175160368",    -- triangle/script fallback
    Misc = "rbxassetid://79511822122227",       -- figureWalk
    Config = "rbxassetid://128495454882226",    -- car/settings fallback
}

local function NormalizeIconName(name)
    name = tostring(name or "")
    if IconAliases[name] then
        return IconAliases[name]
    end
    return name:gsub("%-([%w])", function(character)
        return string.upper(character)
    end)
end

local function ResolveIcon(value, categoryName)
    if value ~= nil then
        if typeof(value) == "number" then
            return "rbxassetid://" .. tostring(value), tostring(value)
        end
        local raw = tostring(value)
        if raw:match("^rbxassetid://") or raw:match("^https?://") then
            return raw, raw
        end
        if raw:match("^%d+$") then
            return "rbxassetid://" .. raw, raw
        end
    end

    local requested = value or DefaultCategoryIcons[tostring(categoryName or "")] or "circle"
    local key = NormalizeIconName(requested)
    local asset =
        Icons[key]
        or BuiltInIcons[key]
        or DefaultCategoryAssets[tostring(categoryName or "")]

    return asset, key
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
        TextSize = size or 14,
        Font = font or Enum.Font.GothamBold,
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
        TextSize = 14,
        Font = Enum.Font.GothamBold
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

    -- One shared root holds BOTH the window and its shadow.
    -- Dragging this root fixes the old "panel moves but outline/shadow stays behind" bug.
    local root = New("Frame", {
        Name = "WindowRoot",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(width, height),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 1
    }, gui)

    -- Layered fallback shadow: soft, not a hard outline.
    local shadowOuter = New("Frame", {
        Name = "ShadowOuter",
        Position = UDim2.fromOffset(-3, -2),
        Size = UDim2.new(1, 6, 1, 8),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.91,
        BorderSizePixel = 0,
        ZIndex = 0
    }, root)
    Corner(shadowOuter, 9)

    local shadowMid = New("Frame", {
        Name = "ShadowMid",
        Position = UDim2.fromOffset(-1, 0),
        Size = UDim2.new(1, 2, 1, 4),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.82,
        BorderSizePixel = 0,
        ZIndex = 0
    }, root)
    Corner(shadowMid, 8)

    local main = New("Frame", {
        Name = "Main",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = COLORS.Window,
        BackgroundTransparency = config.WindowTransparency or 0.04,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 1
    }, root)
    Corner(main, 7)
    Stroke(main, Color3.fromRGB(22, 24, 31), 1, 0.34)

    -- Native blur if supported.
    Shadow(main, Color3.new(0, 0, 0), 0.58, 16, UDim2.fromOffset(0, 4), UDim2.fromOffset(2, 2))

    self.Root = root
    self.Main = main
    self.Shadow = shadowOuter

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
        BackgroundTransparency = config.SidebarTransparency or 0.05,
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
        BackgroundTransparency = config.HeaderTransparency or 0.24,
        BorderSizePixel = 0,
        ZIndex = 2
    }, main)
    New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 16, 21)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 11, 15))
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.18),
            NumberSequenceKeypoint.new(0.55, 0.28),
            NumberSequenceKeypoint.new(1, 0.38)
        }),
        Rotation = 90
    }, header)

    New("Frame", {
        BackgroundColor3 = COLORS.StrokeSoft,
        BackgroundTransparency = 0.38,
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
    title.TextTransparency = 0.08
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

    MakeDraggable(header, root)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift
        if input.KeyCode == toggleKey then
            root.Visible = not root.Visible
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

    -- Wide blue selection wash. The gradient fades into the sidebar,
    -- which reads as a glow instead of a flat rectangle/outline.
    local selectionWash = New("Frame", {
        Name = "SelectionWash",
        BackgroundColor3 = COLORS.Blue,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 3),
        Size = UDim2.new(1, 0, 1, -6),
        Visible = false,
        ZIndex = 4
    }, row)
    Corner(selectionWash, 5)
    New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, COLORS.BlueBright),
            ColorSequenceKeypoint.new(0.46, COLORS.Blue),
            ColorSequenceKeypoint.new(1, COLORS.BlueSelection)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.52),
            NumberSequenceKeypoint.new(0.16, 0.55),
            NumberSequenceKeypoint.new(0.42, 0.68),
            NumberSequenceKeypoint.new(0.70, 0.86),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Rotation = 0
    }, selectionWash)

    -- Secondary bloom makes the active tab fade progressively instead of
    -- looking like a solid blue selected rectangle.
    local selectionBloom = New("Frame", {
        Name = "SelectionBloom",
        BackgroundColor3 = COLORS.BlueBright,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(-2, 7),
        Size = UDim2.new(0.72, 0, 1, -14),
        Visible = false,
        ZIndex = 4
    }, row)
    Corner(selectionBloom, 8)
    New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, COLORS.BlueBright),
            ColorSequenceKeypoint.new(1, COLORS.BlueDark)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.76),
            NumberSequenceKeypoint.new(0.30, 0.82),
            NumberSequenceKeypoint.new(0.72, 0.94),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Rotation = 0
    }, selectionBloom)

    local indicatorHalo = New("Frame", {
        Name = "IndicatorHalo",
        BackgroundColor3 = COLORS.BlueBright,
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(-5, 4),
        Size = UDim2.fromOffset(13, 37),
        Visible = false,
        ZIndex = 5
    }, row)
    Corner(indicatorHalo, 7)
    New("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.18),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Rotation = 0
    }, indicatorHalo)

    local selectionGlow = New("Frame", {
        BackgroundColor3 = COLORS.BlueBright,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(-1, 6),
        Size = UDim2.fromOffset(3, 33),
        ZIndex = 6
    }, row)
    Corner(selectionGlow, 2)

    local iconHolder = New("Frame", {
        Name = "IconHolder",
        BackgroundColor3 = Color3.fromRGB(24, 55, 91),
        BackgroundTransparency = 0.93,
        Position = UDim2.fromOffset(7, 10),
        Size = UDim2.fromOffset(24, 24),
        BorderSizePixel = 0,
        ZIndex = 6
    }, row)
    Corner(iconHolder, 7)
    local iconHolderStroke = Stroke(iconHolder, COLORS.Blue, 1, 0.82)
    local iconHolderShadow = Shadow(
        iconHolder,
        COLORS.Blue,
        0.78,
        7,
        UDim2.fromOffset(0, 0),
        UDim2.fromOffset(1, 1)
    )

    local iconAsset, iconName = ResolveIcon(options.Icon, category.Name)
    category.IconName = iconName

    local icon
    if iconAsset then
        icon = New("ImageLabel", {
            Name = "LucideIcon",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(15, 15),
            Image = iconAsset,
            ImageColor3 = COLORS.BlueBright,
            ImageTransparency = 0.10,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 8
        }, iconHolder)
    else
        -- Last-resort fallback only if the remote icon pack is unavailable
        -- AND there is no built-in asset for the requested icon.
        icon = Label(
            iconHolder,
            "•",
            14,
            COLORS.Blue,
            Enum.Font.GothamBold,
            Enum.TextXAlignment.Center
        )
        icon.Size = UDim2.fromScale(1, 1)
        icon.ZIndex = 8
    end

    category.Icon = icon
    category.IconHolder = iconHolder
    category.IconHolderStroke = iconHolderStroke
    category.IconGlow = iconHolderShadow

    local nameLabel = Label(row, category.Name, 14, COLORS.Muted, Enum.Font.GothamBold)
    nameLabel.Position = UDim2.fromOffset(40, 0)
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
    category.SelectionWash = selectionWash
    category.SelectionBloom = selectionBloom
    category.IndicatorHalo = indicatorHalo
    category.TabBar = tabBar
    category.Window = window

    function category:SetSelected(state)
        if state then
            Tween(row, 0.14, {
                BackgroundTransparency = 0.94,
                BackgroundColor3 = COLORS.BlueSelection
            })
            selectionWash.Visible = true
            selectionBloom.Visible = true
            indicatorHalo.Visible = true
            Tween(selectionWash, 0.14, {BackgroundTransparency = 0})
            Tween(selectionBloom, 0.14, {BackgroundTransparency = 0})
            Tween(indicatorHalo, 0.14, {BackgroundTransparency = 0.64})
            Tween(selectionGlow, 0.14, {BackgroundTransparency = 0.00})
            Tween(nameLabel, 0.14, {TextColor3 = Color3.fromRGB(181, 209, 248)})
            if category.Icon and category.Icon:IsA("ImageLabel") then
                Tween(category.Icon, 0.14, {
                    ImageTransparency = 0.02,
                    ImageColor3 = COLORS.BlueBright
                })
            elseif category.Icon and category.Icon:IsA("TextLabel") then
                Tween(category.Icon, 0.14, {TextColor3 = COLORS.BlueBright})
            end
            if category.IconHolder then
                Tween(category.IconHolder, 0.14, {
                    BackgroundTransparency = 0.72,
                    BackgroundColor3 = Color3.fromRGB(26, 62, 105)
                })
            end
            if category.IconHolderStroke then
                Tween(category.IconHolderStroke, 0.14, {
                    Transparency = 0.36,
                    Color = COLORS.BlueBright
                })
            end
            if category.IconGlow then
                category.IconGlow.Enabled = true
                Tween(category.IconGlow, 0.14, {Transparency = 0.62})
            end
        else
            Tween(row, 0.14, {BackgroundTransparency = 1})
            Tween(selectionWash, 0.14, {BackgroundTransparency = 1})
            Tween(selectionBloom, 0.14, {BackgroundTransparency = 1})
            Tween(indicatorHalo, 0.14, {BackgroundTransparency = 1})
            selectionWash.Visible = false
            selectionBloom.Visible = false
            indicatorHalo.Visible = false
            Tween(selectionGlow, 0.14, {BackgroundTransparency = 1})
            Tween(nameLabel, 0.14, {TextColor3 = COLORS.Muted})
            if category.Icon and category.Icon:IsA("ImageLabel") then
                Tween(category.Icon, 0.14, {
                    ImageTransparency = 0.34,
                    ImageColor3 = COLORS.Blue
                })
            elseif category.Icon and category.Icon:IsA("TextLabel") then
                Tween(category.Icon, 0.14, {TextColor3 = COLORS.Blue})
            end
            if category.IconHolder then
                Tween(category.IconHolder, 0.14, {BackgroundTransparency = 0.88})
            end
            if category.IconHolderStroke then
                Tween(category.IconHolderStroke, 0.14, {Transparency = 0.72})
            end
            if category.IconGlow then
                Tween(category.IconGlow, 0.14, {Transparency = 1})
                category.IconGlow.Enabled = false
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
        tabButton.TextSize = 15
        tabButton.Font = Enum.Font.GothamMedium
        tabButton.TextColor3 = COLORS.Muted
        tabButton.ZIndex = 6

        local tabGlowWash = New("Frame", {
            Name = "TabGlowWash",
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 2),
            Size = UDim2.new(0.76, 0, 0, 12),
            BackgroundColor3 = COLORS.BlueBright,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 5
        }, tabButton)
        Corner(tabGlowWash, 6)
        New("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.5, 0.42),
                NumberSequenceKeypoint.new(1, 1)
            }),
            Rotation = 90
        }, tabGlowWash)

        local tabGlow = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(0.60, 0, 0, 2),
            BackgroundColor3 = COLORS.BlueBright,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 6
        }, tabButton)
        Corner(tabGlow, 2)
        local tabGlowShadow = Shadow(
            tabGlow,
            COLORS.Blue,
            1,
            7,
            UDim2.fromOffset(0, 0),
            UDim2.fromOffset(2, 1)
        )

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
        tab.GlowWash = tabGlowWash
        tab.GlowShadow = tabGlowShadow
        tab.Page = page
        tab.Left = left
        tab.Right = right

        function tab:SetSelected(state)
            if state then
                Tween(tabButton, 0.12, {TextColor3 = COLORS.Blue})
                Tween(tabGlow, 0.12, {BackgroundTransparency = 0.00})
                Tween(tabGlowWash, 0.12, {BackgroundTransparency = 0.40})
                if tab.GlowShadow then
                    tab.GlowShadow.Enabled = true
                    Tween(tab.GlowShadow, 0.12, {Transparency = 0.54})
                end
            else
                Tween(tabButton, 0.12, {TextColor3 = COLORS.Muted})
                Tween(tabGlow, 0.12, {BackgroundTransparency = 1})
                Tween(tabGlowWash, 0.12, {BackgroundTransparency = 1})
                if tab.GlowShadow then
                    Tween(tab.GlowShadow, 0.12, {Transparency = 1})
                    tab.GlowShadow.Enabled = false
                end
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
                BackgroundTransparency = options.Transparency or 0.08,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, height),
                ClipsDescendants = true,
                ZIndex = 4
            }, parentColumn)
            Corner(frame, 5)
            Stroke(frame, COLORS.Stroke, 1, 0.24)
            Shadow(frame, Color3.new(0, 0, 0), 0.78, 10, UDim2.fromOffset(0, 2), UDim2.fromOffset(1, 1))

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
                15,
                COLORS.Text,
                Enum.Font.GothamBold
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
                    14,
                    COLORS.Text,
                    Enum.Font.GothamBold
                )
                name.Size = UDim2.new(1, -42, 1, 0)
                name.ZIndex = 7

                -- Soft checkbox bloom: deliberately larger than the square so
                -- it reads as emitted light instead of a second outline.
                local glowWide = New("Frame", {
                    Name = "ToggleGlowWide",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.fromOffset(38, 38),
                    BackgroundColor3 = COLORS.BlueBright,
                    BackgroundTransparency = value and 0.95 or 1,
                    BorderSizePixel = 0,
                    ZIndex = 4
                }, rowControl)
                Corner(glowWide, 12)

                local glowMid = New("Frame", {
                    Name = "ToggleGlowMid",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.fromOffset(30, 30),
                    BackgroundColor3 = COLORS.BlueBright,
                    BackgroundTransparency = value and 0.90 or 1,
                    BorderSizePixel = 0,
                    ZIndex = 5
                }, rowControl)
                Corner(glowMid, 9)

                local glow = New("Frame", {
                    Name = "ToggleGlowCore",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.fromOffset(24, 24),
                    BackgroundColor3 = COLORS.BlueBright,
                    BackgroundTransparency = value and 0.84 or 1,
                    BorderSizePixel = 0,
                    ZIndex = 6
                }, rowControl)
                Corner(glow, 6)

                -- Feather each glow layer vertically so none of them looks
                -- like a second rounded-square border.
                for _, glowLayer in ipairs({glowWide, glowMid, glow}) do
                    New("UIGradient", {
                        Color = ColorSequence.new(COLORS.BlueBright),
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 1),
                            NumberSequenceKeypoint.new(0.30, 0.78),
                            NumberSequenceKeypoint.new(0.50, 0.36),
                            NumberSequenceKeypoint.new(0.70, 0.78),
                            NumberSequenceKeypoint.new(1, 1)
                        }),
                        Rotation = 90
                    }, glowLayer)
                end

                local toggleShadow = Shadow(
                    glow,
                    COLORS.BlueBright,
                    value and 0.64 or 1,
                    10,
                    UDim2.fromOffset(0, 0),
                    UDim2.fromOffset(3, 3)
                )

                local box = Button(rowControl, "")
                box.AnchorPoint = Vector2.new(0.5, 0.5)
                box.Position = UDim2.new(1, -12, 0.5, 0)
                box.Size = UDim2.fromOffset(18, 18)
                box.BackgroundTransparency = 0
                box.BackgroundColor3 = value and Color3.fromRGB(45, 111, 190) or Color3.fromRGB(18, 31, 44)
                box.ZIndex = 8
                Corner(box, 2)
                local boxStroke = Stroke(
                    box,
                    Color3.fromRGB(67, 73, 84),
                    1,
                    value and 0.56 or 0.70
                )

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
                        BackgroundColor3 = value and Color3.fromRGB(45, 111, 190) or Color3.fromRGB(18, 31, 44)
                    })
                    Tween(glow, 0.10, {
                        BackgroundTransparency = value and 0.84 or 1
                    })
                    Tween(glowMid, 0.10, {
                        BackgroundTransparency = value and 0.90 or 1
                    })
                    Tween(glowWide, 0.10, {
                        BackgroundTransparency = value and 0.95 or 1
                    })
                    Tween(boxStroke, 0.10, {
                        Color = Color3.fromRGB(67, 73, 84),
                        Transparency = value and 0.56 or 0.70
                    })
                    if toggleShadow then
                        toggleShadow.Enabled = value
                        Tween(toggleShadow, 0.10, {
                            Transparency = value and 0.64 or 1
                        })
                    end
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
                    14,
                    COLORS.Muted,
                    Enum.Font.GothamBold
                )
                name.Size = UDim2.new(1, -78, 0, 20)
                name.ZIndex = 7

                local valueLabel = Label(
                    rowControl,
                    "",
                    14,
                    COLORS.Text,
                    Enum.Font.GothamBold,
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

                -- Real soft glow: two feathered bands + native UIShadow when available.
                local glowWide = New("Frame", {
                    Name = "FillGlowWide",
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.fromScale(0, 0.5),
                    Size = UDim2.new(0, 0, 0, 17),
                    BackgroundColor3 = COLORS.Blue,
                    BackgroundTransparency = 0.34,
                    BorderSizePixel = 0,
                    ZIndex = 6
                }, track)
                Corner(glowWide, 9)
                New("UIGradient", {
                    Color = ColorSequence.new(COLORS.BlueBright),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(0.20, 0.88),
                        NumberSequenceKeypoint.new(0.50, 0.30),
                        NumberSequenceKeypoint.new(0.80, 0.88),
                        NumberSequenceKeypoint.new(1, 1)
                    }),
                    Rotation = 90
                }, glowWide)

                local glow = New("Frame", {
                    Name = "FillGlow",
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.fromScale(0, 0.5),
                    Size = UDim2.new(0, 0, 0, 11),
                    BackgroundColor3 = COLORS.BlueBright,
                    BackgroundTransparency = 0.18,
                    BorderSizePixel = 0,
                    ZIndex = 7
                }, track)
                Corner(glow, 6)
                New("UIGradient", {
                    Color = ColorSequence.new(COLORS.BlueBright),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(0.28, 0.72),
                        NumberSequenceKeypoint.new(0.50, 0.12),
                        NumberSequenceKeypoint.new(0.72, 0.72),
                        NumberSequenceKeypoint.new(1, 1)
                    }),
                    Rotation = 90
                }, glow)

                local fill = New("Frame", {
                    Name = "Fill",
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = COLORS.Blue,
                    BorderSizePixel = 0,
                    ZIndex = 8
                }, track)
                Corner(fill, 3)
                local fillShadow = Shadow(
                    fill,
                    COLORS.BlueBright,
                    0.52,
                    8,
                    UDim2.fromOffset(0, 0),
                    UDim2.fromOffset(1, 1)
                )
                New("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, COLORS.BlueDark),
                        ColorSequenceKeypoint.new(1, COLORS.BlueBright)
                    }),
                    Rotation = 0
                }, fill)

                local knobHaloOuter = New("Frame", {
                    Name = "KnobHaloOuter",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.fromOffset(22, 22),
                    BackgroundColor3 = COLORS.BlueBright,
                    BackgroundTransparency = 0.88,
                    BorderSizePixel = 0,
                    ZIndex = 8
                }, track)
                Corner(knobHaloOuter, 11)

                local knobHalo = New("Frame", {
                    Name = "KnobHalo",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.fromOffset(14, 18),
                    BackgroundColor3 = COLORS.BlueBright,
                    BackgroundTransparency = 0.72,
                    BorderSizePixel = 0,
                    ZIndex = 9
                }, track)
                Corner(knobHalo, 8)

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
                Shadow(
                    knob,
                    COLORS.BlueBright,
                    0.68,
                    6,
                    UDim2.fromOffset(0, 0),
                    UDim2.fromOffset(1, 1)
                )

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
                    glowWide.Size = UDim2.new(alpha, 0, 0, 17)
                    knob.Position = UDim2.new(alpha, 0, 0.5, 0)
                    knobHalo.Position = UDim2.new(alpha, 0, 0.5, 0)
                    knobHaloOuter.Position = UDim2.new(alpha, 0, 0.5, 0)
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
                    14,
                    COLORS.Text,
                    Enum.Font.GothamBold
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
                    Enum.Font.GothamBold
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
                    14,
                    COLORS.Text,
                    Enum.Font.GothamBold
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

                local current =
                    typeof(opts.Default) == "Color3"
                    and opts.Default
                    or Color3.new(1, 1, 1)

                local presets = opts.Presets or {
                    Color3.fromRGB(255, 255, 255),
                    Color3.fromRGB(74, 148, 239),
                    Color3.fromRGB(255, 88, 88),
                    Color3.fromRGB(111, 232, 142),
                    Color3.fromRGB(194, 110, 255),
                    Color3.fromRGB(255, 196, 90),
                }

                local hue, sat, val =
                    current:ToHSV()

                local opened = false
                local draggingSV = false
                local draggingHue = false

                local CLOSED_HEIGHT = 31
                local OPEN_HEIGHT = 252

                local rowControl = Row(CLOSED_HEIGHT)

                local name = Label(
                    rowControl,
                    opts.Name or "Color",
                    14,
                    COLORS.Text,
                    Enum.Font.GothamBold
                )
                name.Size = UDim2.new(1, -92, 0, CLOSED_HEIGHT)
                name.ZIndex = 7

                local hexPreview = Label(
                    rowControl,
                    "",
                    10,
                    COLORS.Muted2,
                    Enum.Font.GothamMedium,
                    Enum.TextXAlignment.Right
                )
                hexPreview.AnchorPoint = Vector2.new(1, 0)
                hexPreview.Position = UDim2.new(1, -34, 0, 0)
                hexPreview.Size = UDim2.fromOffset(56, CLOSED_HEIGHT)
                hexPreview.ZIndex = 7

                local swatchGlow = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(1, -12, 0, CLOSED_HEIGHT / 2),
                    Size = UDim2.fromOffset(25, 25),
                    BackgroundColor3 = current,
                    BackgroundTransparency = 0.82,
                    BorderSizePixel = 0,
                    ZIndex = 6
                }, rowControl)
                Corner(swatchGlow, 5)

                local swatch = Button(rowControl, "")
                swatch.AnchorPoint = Vector2.new(0.5, 0.5)
                swatch.Position = UDim2.new(1, -12, 0, CLOSED_HEIGHT / 2)
                swatch.Size = UDim2.fromOffset(18, 18)
                swatch.BackgroundColor3 = current
                swatch.BackgroundTransparency = 0
                swatch.ZIndex = 9
                Corner(swatch, 3)
                Stroke(swatch, Color3.fromRGB(200, 203, 210), 1, 0.42)

                local palette = New("Frame", {
                    Name = "FullColorPalette",
                    BackgroundColor3 = Color3.fromRGB(10, 11, 16),
                    BackgroundTransparency = 0.01,
                    BorderSizePixel = 0,
                    Position = UDim2.fromOffset(0, CLOSED_HEIGHT + 3),
                    Size = UDim2.new(1, -2, 0, OPEN_HEIGHT - CLOSED_HEIGHT - 6),
                    Visible = false,
                    ClipsDescendants = true,
                    ZIndex = 20
                }, rowControl)
                Corner(palette, 5)
                Stroke(palette, COLORS.Stroke, 1, 0.04)

                local sv = New("Frame", {
                    Name = "SVSquare",
                    Active = true,
                    BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
                    BorderSizePixel = 0,
                    Position = UDim2.fromOffset(8, 8),
                    Size = UDim2.new(1, -48, 0, 126),
                    ClipsDescendants = true,
                    ZIndex = 22
                }, palette)
                Corner(sv, 4)
                Stroke(sv, Color3.fromRGB(45, 48, 58), 1, 0.10)

                -- Horizontal white -> transparent controls saturation.
                local whiteLayer = New("Frame", {
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    Size = UDim2.fromScale(1, 1),
                    ZIndex = 23
                }, sv)
                Corner(whiteLayer, 4)
                New("UIGradient", {
                    Color = ColorSequence.new(Color3.new(1, 1, 1)),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 1),
                    }),
                    Rotation = 0
                }, whiteLayer)

                -- Vertical transparent -> black controls value.
                local blackLayer = New("Frame", {
                    BackgroundColor3 = Color3.new(0, 0, 0),
                    BorderSizePixel = 0,
                    Size = UDim2.fromScale(1, 1),
                    ZIndex = 24
                }, sv)
                Corner(blackLayer, 4)
                New("UIGradient", {
                    Color = ColorSequence.new(Color3.new(0, 0, 0)),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0),
                    }),
                    Rotation = 90
                }, blackLayer)

                local svHitbox = Button(sv, "")
                svHitbox.Size = UDim2.fromScale(1, 1)
                svHitbox.ZIndex = 26

                local svMarker = New("Frame", {
                    Name = "SVMarker",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Size = UDim2.fromOffset(10, 10),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BackgroundTransparency = 0.78,
                    BorderSizePixel = 0,
                    ZIndex = 27
                }, sv)
                Corner(svMarker, 10)
                Stroke(svMarker, Color3.new(1, 1, 1), 2, 0.02)

                local hueBar = New("Frame", {
                    Name = "HueBar",
                    Active = true,
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -8, 0, 8),
                    Size = UDim2.fromOffset(22, 126),
                    ClipsDescendants = false,
                    ZIndex = 22
                }, palette)
                Corner(hueBar, 4)
                Stroke(hueBar, Color3.fromRGB(45, 48, 58), 1, 0.10)

                New("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0.00, 1, 1)),
                        ColorSequenceKeypoint.new(0.16, Color3.fromHSV(0.16, 1, 1)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
                        ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
                        ColorSequenceKeypoint.new(0.66, Color3.fromHSV(0.66, 1, 1)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
                        ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1.00, 1, 1)),
                    }),
                    Rotation = 90
                }, hueBar)

                local hueHitbox = Button(hueBar, "")
                hueHitbox.Size = UDim2.fromScale(1, 1)
                hueHitbox.ZIndex = 25

                local hueMarker = New("Frame", {
                    Name = "HueMarker",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, hue, 0),
                    Size = UDim2.new(1, 6, 0, 4),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    ZIndex = 27
                }, hueBar)
                Corner(hueMarker, 2)
                Stroke(hueMarker, Color3.fromRGB(25, 27, 34), 1, 0.05)

                local lower = New("Frame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.fromOffset(8, 140),
                    Size = UDim2.new(1, -16, 0, 72),
                    ZIndex = 22
                }, palette)

                local hexLabel = Label(
                    lower,
                    "HEX",
                    10,
                    COLORS.Muted2,
                    Enum.Font.GothamBold
                )
                hexLabel.Position = UDim2.fromOffset(0, 0)
                hexLabel.Size = UDim2.fromOffset(29, 27)
                hexLabel.ZIndex = 23

                local hexBox = New("TextBox", {
                    BackgroundColor3 = COLORS.Control,
                    BackgroundTransparency = 0.04,
                    BorderSizePixel = 0,
                    Position = UDim2.fromOffset(31, 0),
                    Size = UDim2.fromOffset(82, 27),
                    ClearTextOnFocus = false,
                    Text = "",
                    TextColor3 = COLORS.Text,
                    PlaceholderText = "#FFFFFF",
                    PlaceholderColor3 = COLORS.Muted2,
                    TextSize = 11,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 24
                }, lower)
                Corner(hexBox, 4)
                Stroke(hexBox, COLORS.Stroke, 1, 0.08)

                local rgbLabel = Label(
                    lower,
                    "",
                    10,
                    COLORS.Muted,
                    Enum.Font.GothamMedium,
                    Enum.TextXAlignment.Right
                )
                rgbLabel.Position = UDim2.new(0, 119, 0, 0)
                rgbLabel.Size = UDim2.new(1, -119, 0, 27)
                rgbLabel.ZIndex = 23

                local presetHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.fromOffset(0, 35),
                    Size = UDim2.new(1, 0, 0, 27),
                    ZIndex = 23
                }, lower)

                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 6)
                }, presetHolder)

                local function toHex(color)
                    local r = math.floor(math.clamp(color.R, 0, 1) * 255 + 0.5)
                    local g = math.floor(math.clamp(color.G, 0, 1) * 255 + 0.5)
                    local b = math.floor(math.clamp(color.B, 0, 1) * 255 + 0.5)
                    return string.format("#%02X%02X%02X", r, g, b)
                end

                local function fromHex(value)
                    value = tostring(value or "")
                    value = value:gsub("#", ""):gsub("%s+", "")

                    if #value == 3 then
                        value =
                            value:sub(1, 1) .. value:sub(1, 1)
                            .. value:sub(2, 2) .. value:sub(2, 2)
                            .. value:sub(3, 3) .. value:sub(3, 3)
                    end

                    if not value:match("^%x%x%x%x%x%x$") then
                        return nil
                    end

                    return Color3.fromRGB(
                        tonumber(value:sub(1, 2), 16),
                        tonumber(value:sub(3, 4), 16),
                        tonumber(value:sub(5, 6), 16)
                    )
                end

                local function updateIndicators()
                    sv.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                    svMarker.Position = UDim2.fromScale(sat, 1 - val)
                    hueMarker.Position = UDim2.new(0.5, 0, hue, 0)

                    swatch.BackgroundColor3 = current
                    swatchGlow.BackgroundColor3 = current

                    local hex = toHex(current)
                    hexPreview.Text = hex
                    hexBox.Text = hex

                    rgbLabel.Text = string.format(
                        "RGB  %d, %d, %d",
                        math.floor(current.R * 255 + 0.5),
                        math.floor(current.G * 255 + 0.5),
                        math.floor(current.B * 255 + 0.5)
                    )
                end

                local function set(value, fire)
                    if typeof(value) ~= "Color3" then
                        return
                    end

                    current = value
                    hue, sat, val = current:ToHSV()
                    updateIndicators()

                    if fire then
                        Fire(opts.Callback, current)
                    end
                end

                local function setHSV(newHue, newSat, newVal, fire)
                    hue = math.clamp(newHue or hue, 0, 1)
                    sat = math.clamp(newSat or sat, 0, 1)
                    val = math.clamp(newVal or val, 0, 1)

                    current = Color3.fromHSV(hue, sat, val)
                    updateIndicators()

                    if fire then
                        Fire(opts.Callback, current)
                    end
                end

                local function updateSVFromPosition(position)
                    local x = math.clamp(
                        (position.X - sv.AbsolutePosition.X)
                        / math.max(1, sv.AbsoluteSize.X),
                        0,
                        1
                    )

                    local y = math.clamp(
                        (position.Y - sv.AbsolutePosition.Y)
                        / math.max(1, sv.AbsoluteSize.Y),
                        0,
                        1
                    )

                    setHSV(hue, x, 1 - y, true)
                end

                local function updateHueFromPosition(position)
                    local y = math.clamp(
                        (position.Y - hueBar.AbsolutePosition.Y)
                        / math.max(1, hueBar.AbsoluteSize.Y),
                        0,
                        1
                    )

                    setHSV(y, sat, val, true)
                end

                svHitbox.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch
                    then
                        draggingSV = true
                        updateSVFromPosition(input.Position)
                    end
                end)

                hueHitbox.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch
                    then
                        draggingHue = true
                        updateHueFromPosition(input.Position)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch
                    then
                        if draggingSV then
                            updateSVFromPosition(input.Position)
                        elseif draggingHue then
                            updateHueFromPosition(input.Position)
                        end
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch
                    then
                        draggingSV = false
                        draggingHue = false
                    end
                end)

                hexBox.FocusLost:Connect(function(pressedEnter)
                    local parsed = fromHex(hexBox.Text)

                    if parsed then
                        set(parsed, true)
                    else
                        hexBox.Text = toHex(current)
                    end
                end)

                for _, value in ipairs(presets) do
                    local p = Button(presetHolder, "")
                    p.Size = UDim2.fromOffset(21, 21)
                    p.BackgroundTransparency = 0
                    p.BackgroundColor3 = value
                    p.ZIndex = 24
                    Corner(p, 4)
                    Stroke(p, Color3.fromRGB(200, 203, 210), 1, 0.58)

                    p.MouseButton1Click:Connect(function()
                        set(value, true)
                    end)
                end

                swatch.MouseButton1Click:Connect(function()
                    opened = not opened
                    palette.Visible = opened
                    rowControl.Size = UDim2.new(
                        1,
                        -3,
                        0,
                        opened and OPEN_HEIGHT or CLOSED_HEIGHT
                    )
                end)

                updateIndicators()

                return {
                    Get = function()
                        return current
                    end,

                    Set = function(_, value)
                        set(value, true)
                    end,

                    Open = function()
                        opened = true
                        palette.Visible = true
                        rowControl.Size = UDim2.new(1, -3, 0, OPEN_HEIGHT)
                    end,

                    Close = function()
                        opened = false
                        palette.Visible = false
                        rowControl.Size = UDim2.new(1, -3, 0, CLOSED_HEIGHT)
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
                    Enum.Font.GothamBold
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


function Library:GetIcon(name)
    local asset, resolved = ResolveIcon(name)
    return asset, resolved
end

function Library:SetVisible(state)
    if self.Root then
        self.Root.Visible = not not state
    else
        self.Main.Visible = not not state
    end
end

function Library:Toggle()
    self:SetVisible(not (self.Root and self.Root.Visible or self.Main.Visible))
end

function Library:Destroy()
    if self.Gui then
        self.Gui:Destroy()
    end
end


-- ═══════════════════════════════════════════════════════════════
--  TEL-AVIV NOTIFICATIONS v4.2
--  Top-right toast system using the same visual language as the panel.
-- ═══════════════════════════════════════════════════════════════

Library._Notifications = Library._Notifications or {
    Gui = nil,
    Holder = nil,
    Active = {},
    Counter = 0,
}

local function TA_NotificationAccent(kind, explicitColor)
    if typeof(explicitColor) == "Color3" then
        return explicitColor
    end

    kind = string.lower(tostring(kind or "info"))

    if kind == "success" then
        return Color3.fromRGB(73, 187, 125)
    elseif kind == "warning" or kind == "warn" then
        return Color3.fromRGB(224, 170, 74)
    elseif kind == "error" or kind == "danger" then
        return Color3.fromRGB(220, 78, 89)
    end

    return COLORS.BlueBright
end

local function TA_ParseNotification(a, b, c, d)
    local data = {
        Title = "TEL-AVIV",
        Content = "",
        Duration = 3,
        Type = "info",
        Color = nil,
    }

    if type(a) == "table" then
        data.Title = tostring(a.Title or a.Name or "TEL-AVIV")
        data.Content = tostring(a.Content or a.Text or a.Message or "")
        data.Duration = tonumber(a.Duration or a.Time) or 3
        data.Type = tostring(a.Type or "info")
        data.Color = a.Color
        return data
    end

    if type(b) == "string" then
        data.Title = tostring(a or "TEL-AVIV")
        data.Content = tostring(b)
        data.Duration = tonumber(c) or 3
        data.Color = d
        return data
    end

    local message = tostring(a or "")
    local separator = " — "
    local separatorAt = string.find(message, separator, 1, true)

    if separatorAt then
        data.Title = string.sub(message, 1, separatorAt - 1)
        data.Content = string.sub(message, separatorAt + #separator)
    elseif message ~= "" then
        data.Title = message
    end

    data.Duration = tonumber(b) or 3
    data.Color = c
    return data
end

local function TA_EnsureNotificationGui()
    local state = Library._Notifications

    if state.Gui and state.Gui.Parent and state.Holder and state.Holder.Parent then
        return state
    end

    local parent = ResolveParent()
    if not parent then
        return nil
    end

    local gui = New("ScreenGui", {
        Name = "TEL_AVIV_NOTIFICATIONS",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 10000,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, parent)

    local holder = New("Frame", {
        Name = "Holder",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 16),
        Size = UDim2.new(0, 318, 1, -32),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 100,
    }, gui)

    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 7),
    }, holder)

    state.Gui = gui
    state.Holder = holder
    state.Active = {}
    state.Counter = 0

    return state
end

local function TA_RemoveNotificationFromState(item)
    local state = Library._Notifications
    for index, current in ipairs(state.Active) do
        if current == item then
            table.remove(state.Active, index)
            break
        end
    end
end

function Library:Notify(a, b, c, d)
    local data = TA_ParseNotification(a, b, c, d)
    local state = TA_EnsureNotificationGui()
    if not state then
        return nil
    end

    state.Counter += 1

    local width = 308
    local height = data.Content ~= "" and 70 or 55
    local duration = math.max(0.75, tonumber(data.Duration) or 3)
    local accent = TA_NotificationAccent(data.Type, data.Color)

    local slot = New("Frame", {
        Name = "NotificationSlot",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(width, 0),
        LayoutOrder = -state.Counter,
        ClipsDescendants = false,
        ZIndex = 101,
    }, state.Holder)

    local shadowOuter = New("Frame", {
        Name = "ShadowOuter",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.91,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(-3, -2),
        Size = UDim2.new(1, 6, 1, 7),
        ZIndex = 101,
    }, slot)
    Corner(shadowOuter, 9)

    local shadowInner = New("Frame", {
        Name = "ShadowInner",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.80,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(-1, 0),
        Size = UDim2.new(1, 2, 1, 3),
        ZIndex = 102,
    }, slot)
    Corner(shadowInner, 8)

    local card = New("Frame", {
        Name = "Notification",
        BackgroundColor3 = COLORS.Panel,
        BackgroundTransparency = 0.045,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(width + 28, 0),
        Size = UDim2.fromOffset(width, height),
        ClipsDescendants = true,
        ZIndex = 103,
    }, slot)
    Corner(card, 7)
    Stroke(card, COLORS.Stroke, 1, 0.18)

    Shadow(
        card,
        Color3.new(0, 0, 0),
        0.64,
        12,
        UDim2.fromOffset(0, 3),
        UDim2.fromOffset(1, 1)
    )

    New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(13, 14, 19)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 8, 12)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.02),
            NumberSequenceKeypoint.new(0.55, 0.07),
            NumberSequenceKeypoint.new(1, 0.14),
        }),
        Rotation = 90,
    }, card)

    -- Horizontal blue wash, matching the selected sidebar style.
    local wash = New("Frame", {
        Name = "AccentWash",
        BackgroundColor3 = accent,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 92, 1, 0),
        Position = UDim2.fromOffset(0, 0),
        ZIndex = 104,
    }, card)

    New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, accent),
            ColorSequenceKeypoint.new(0.55, accent),
            ColorSequenceKeypoint.new(1, COLORS.Panel),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.80),
            NumberSequenceKeypoint.new(0.18, 0.86),
            NumberSequenceKeypoint.new(0.48, 0.94),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Rotation = 0,
    }, wash)

    -- Soft glow behind the 2 px accent line.
    local lineGlow = New("Frame", {
        Name = "AccentGlow",
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.86,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(-4, 8),
        Size = UDim2.fromOffset(12, height - 16),
        ZIndex = 105,
    }, card)
    Corner(lineGlow, 7)

    New("UIGradient", {
        Color = ColorSequence.new(accent),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.24, 0.78),
            NumberSequenceKeypoint.new(0.5, 0.18),
            NumberSequenceKeypoint.new(0.76, 0.78),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Rotation = 90,
    }, lineGlow)

    local line = New("Frame", {
        Name = "AccentLine",
        BackgroundColor3 = accent,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 10),
        Size = UDim2.fromOffset(2, height - 20),
        ZIndex = 106,
    }, card)
    Corner(line, 2)

    -- Compact icon tile in the same style as the left navigation.
    local iconTile = New("Frame", {
        Name = "IconTile",
        BackgroundColor3 = Color3.fromRGB(24, 55, 91),
        BackgroundTransparency = 0.90,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(13, 12),
        Size = UDim2.fromOffset(25, 25),
        ZIndex = 106,
    }, card)
    Corner(iconTile, 7)
    Stroke(iconTile, accent, 1, 0.72)

    local dotGlow = New("Frame", {
        Name = "DotGlow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(15, 15),
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.89,
        BorderSizePixel = 0,
        ZIndex = 107,
    }, iconTile)
    Corner(dotGlow, 8)

    local dot = New("Frame", {
        Name = "Dot",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(5, 5),
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        ZIndex = 108,
    }, iconTile)
    Corner(dot, 3)

    local title = Label(
        card,
        data.Title,
        13,
        COLORS.Text,
        Enum.Font.GothamBold
    )
    title.Name = "Title"
    title.Position = UDim2.fromOffset(47, data.Content ~= "" and 8 or 0)
    title.Size = UDim2.new(1, -78, 0, data.Content ~= "" and 23 or height - 6)
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.ZIndex = 108

    if data.Content ~= "" then
        local content = Label(
            card,
            data.Content,
            11,
            COLORS.Muted,
            Enum.Font.GothamMedium
        )
        content.Name = "Content"
        content.Position = UDim2.fromOffset(47, 30)
        content.Size = UDim2.new(1, -61, 0, 26)
        content.TextWrapped = true
        content.TextYAlignment = Enum.TextYAlignment.Top
        content.TextTruncate = Enum.TextTruncate.AtEnd
        content.ZIndex = 108
    end

    local close = Button(card, "×")
    close.Name = "Close"
    close.AnchorPoint = Vector2.new(1, 0)
    close.Position = UDim2.new(1, -5, 0, 3)
    close.Size = UDim2.fromOffset(22, 22)
    close.TextSize = 16
    close.Font = Enum.Font.GothamMedium
    close.TextColor3 = COLORS.Muted2
    close.ZIndex = 110

    -- Slider-style lifetime bar.
    local progressTrack = New("Frame", {
        Name = "ProgressTrack",
        BackgroundColor3 = COLORS.Control2,
        BackgroundTransparency = 0.10,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 1, -7),
        Size = UDim2.new(1, -24, 0, 2),
        ZIndex = 106,
    }, card)
    Corner(progressTrack, 2)

    local progressGlow = New("Frame", {
        Name = "ProgressGlow",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 9),
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        ZIndex = 106,
    }, progressTrack)
    Corner(progressGlow, 5)

    New("UIGradient", {
        Color = ColorSequence.new(accent),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.27, 0.74),
            NumberSequenceKeypoint.new(0.50, 0.12),
            NumberSequenceKeypoint.new(0.73, 0.74),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Rotation = 90,
    }, progressGlow)

    local progress = New("Frame", {
        Name = "Progress",
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 107,
    }, progressTrack)
    Corner(progress, 2)

    local item = {
        Slot = slot,
        Card = card,
        ShadowOuter = shadowOuter,
        ShadowInner = shadowInner,
        Closed = false,
    }

    local function dismiss()
        if item.Closed then
            return
        end

        item.Closed = true
        TA_RemoveNotificationFromState(item)

        Tween(card, 0.18, {
            Position = UDim2.fromOffset(width + 30, 0),
            BackgroundTransparency = 0.18,
        })

        Tween(shadowOuter, 0.18, {BackgroundTransparency = 1})
        Tween(shadowInner, 0.18, {BackgroundTransparency = 1})

        task.delay(0.10, function()
            if slot and slot.Parent then
                Tween(slot, 0.16, {
                    Size = UDim2.fromOffset(width, 0),
                })
            end
        end)

        task.delay(0.30, function()
            if slot then
                slot:Destroy()
            end
        end)
    end

    item.Close = dismiss
    table.insert(state.Active, item)

    if #state.Active > 5 then
        local oldest = state.Active[1]
        if oldest and oldest.Close then
            oldest.Close()
        end
    end

    close.MouseEnter:Connect(function()
        Tween(close, 0.08, {TextColor3 = COLORS.Text})
    end)

    close.MouseLeave:Connect(function()
        Tween(close, 0.08, {TextColor3 = COLORS.Muted2})
    end)

    close.MouseButton1Click:Connect(dismiss)

    Tween(slot, 0.17, {
        Size = UDim2.fromOffset(width, height),
    })
    Tween(card, 0.22, {
        Position = UDim2.fromOffset(0, 0),
    })

    TweenService:Create(
        progress,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 0, 1, 0)}
    ):Play()

    TweenService:Create(
        progressGlow,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 0, 0, 9)}
    ):Play()

    task.delay(duration, dismiss)

    return item
end

function Library:Notification(message, duration, color)
    return self:Notify(message, duration, color)
end

function Library:ClearNotifications()
    local copy = {}

    for _, item in ipairs(Library._Notifications.Active or {}) do
        table.insert(copy, item)
    end

    for _, item in ipairs(copy) do
        if item and item.Close then
            item.Close()
        end
    end
end

return Library
