-- TEL-AVIV MENU
-- Roblox UI library inspired by the supplied reference image.
-- UI-only library: controls expose callbacks but contain no exploit/cheat logic.

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local TELAVIV = {}
TELAVIV.__index = TELAVIV

local Theme = {
	Window = Color3.fromRGB(12, 13, 18),
	Window2 = Color3.fromRGB(15, 16, 21),
	Panel = Color3.fromRGB(14, 15, 20),
	Panel2 = Color3.fromRGB(17, 18, 23),
	Stroke = Color3.fromRGB(27, 29, 36),
	Text = Color3.fromRGB(206, 208, 216),
	Muted = Color3.fromRGB(145, 148, 160),
	Blue = Color3.fromRGB(69, 139, 225),
	Blue2 = Color3.fromRGB(43, 102, 171),
	BlueSoft = Color3.fromRGB(28, 55, 88),
	White = Color3.fromRGB(242, 244, 248),
	Black = Color3.fromRGB(4, 5, 8),
}

local function new(className, props, parent)
	local o = Instance.new(className)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	if parent then o.Parent = parent end
	return o
end

local function corner(parent, px)
	return new("UICorner", {CornerRadius = UDim.new(0, px or 6)}, parent)
end

local function stroke(parent, color, thickness, transparency)
	return new("UIStroke", {
		Color = color or Theme.Stroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function padding(parent, l, r, t, b)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0),
		PaddingRight = UDim.new(0, r or 0),
		PaddingTop = UDim.new(0, t or 0),
		PaddingBottom = UDim.new(0, b or 0),
	}, parent)
end

local function tween(obj, t, props)
	TweenService:Create(obj, TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function text(parent, content, size, color, font, align)
	return new("TextLabel", {
		BackgroundTransparency = 1,
		Text = content or "",
		TextColor3 = color or Theme.Text,
		TextSize = size or 14,
		Font = font or Enum.Font.GothamMedium,
		TextXAlignment = align or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		BorderSizePixel = 0,
	}, parent)
end

local function button(parent, content)
	return new("TextButton", {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = content or "",
		TextColor3 = Theme.Text,
		TextSize = 14,
		Font = Enum.Font.GothamMedium,
	}, parent)
end

local function safeCallback(fn, ...)
	if typeof(fn) == "function" then
		task.spawn(fn, ...)
	end
end

local function makeDraggable(handle, target)
	local dragging = false
	local dragStart
	local startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end

local function addWatermarkLogo(parent)
	local holder = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(108, 78),
		Position = UDim2.fromOffset(21, 18),
	}, parent)

	local positions = {14, 40, 66}
	for i, x in ipairs(positions) do
		local head = new("Frame", {
			BackgroundColor3 = Theme.Blue,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(28, 44),
			Position = UDim2.fromOffset(x, 14 + (i == 2 and -2 or 0)),
		}, holder)
		corner(head, 9)
		local grad = new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 151, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 91, 173)),
			}),
			Rotation = 90,
		}, head)

		if i == 2 then
			local eye1 = text(head, "×", 12, Color3.fromRGB(2, 42, 87), Enum.Font.GothamBold, Enum.TextXAlignment.Center)
			eye1.Size = UDim2.fromOffset(10, 10)
			eye1.Position = UDim2.fromOffset(4, 11)
			local eye2 = eye1:Clone()
			eye2.Position = UDim2.fromOffset(15, 11)
			eye2.Parent = head
			local mouth = new("Frame", {
				BackgroundColor3 = Color3.fromRGB(2, 42, 87),
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(9, 2),
				Position = UDim2.fromOffset(9, 28),
				Rotation = 30,
			}, head)
		else
			local mark = text(head, i == 1 and "⌒" or "×", 12, Color3.fromRGB(2, 42, 87), Enum.Font.GothamBold, Enum.TextXAlignment.Center)
			mark.Size = UDim2.fromScale(1, 1)
		end
	end
	return holder
end

function TELAVIV.new(config)
	config = config or {}
	local self = setmetatable({}, TELAVIV)
	self._tabs = {}
	self._activeTab = nil
	self._theme = Theme

	local gui = new("ScreenGui", {
		Name = config.Name or "TEL_AVIV_MENU",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = false,
	})

	if syn and syn.protect_gui then
		pcall(syn.protect_gui, gui)
	end

	local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
	if ok and coreGui then
		gui.Parent = coreGui
	else
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	self.Gui = gui

	local main = new("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(config.Width or 770, config.Height or 560),
		BackgroundColor3 = Theme.Window,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, gui)
	corner(main, 7)
	stroke(main, Color3.fromRGB(8, 9, 12), 1, 0)
	self.Main = main

	new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 15, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 10, 14)),
		}),
		Rotation = 90,
	}, main)

	local sidebar = new("Frame", {
		Name = "Sidebar",
		Size = UDim2.fromOffset(160, 560),
		BackgroundColor3 = Color3.fromRGB(11, 12, 17),
		BorderSizePixel = 0,
	}, main)
	new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 15, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 10, 14)),
		}),
		Rotation = 90,
	}, sidebar)

	addWatermarkLogo(sidebar)

	local sideLine = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(20, 22, 28),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 1, 1, -1),
		Position = UDim2.new(1, -1, 0, 0),
	}, sidebar)

	local header = new("Frame", {
		Name = "Header",
		BackgroundColor3 = Color3.fromRGB(13, 14, 18),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(160, 0),
		Size = UDim2.new(1, -160, 0, 67),
	}, main)
	new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 17, 22)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(11, 12, 16)),
		}),
		Rotation = 90,
	}, header)
	new("Frame", {
		BackgroundColor3 = Color3.fromRGB(23, 25, 31),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
	}, header)

	local title = text(header, config.Title or "TEL-AVIV MENU", 13, Theme.Muted, Enum.Font.GothamSemibold)
	title.Position = UDim2.new(1, -152, 0, 11)
	title.Size = UDim2.fromOffset(140, 18)
	title.TextXAlignment = Enum.TextXAlignment.Right
	title.TextTransparency = config.ShowTitle == false and 1 or 0.35

	local tabButtons = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -180, 1, 0),
	}, header)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 18),
	}, tabButtons)

	local sideItems = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 106),
		Size = UDim2.new(1, -20, 1, -116),
	}, sidebar)
	new("UIListLayout", {
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, sideItems)

	local content = new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(160, 67),
		Size = UDim2.new(1, -160, 1, -67),
	}, main)
	self._content = content
	self._headerTabs = tabButtons
	self._sideItems = sideItems

	makeDraggable(header, main)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == (config.ToggleKey or Enum.KeyCode.RightShift) then
			main.Visible = not main.Visible
		end
	end)

	return self
end

function TELAVIV:AddSidebarItem(name, iconText)
	local row = button(self._sideItems, "")
	row.Name = name
	row.Size = UDim2.new(1, 0, 0, 43)
	row.BackgroundTransparency = 1
	corner(row, 5)

	local iconHolder = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(20, 31, 45),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.fromOffset(8, 12),
	}, row)
	corner(iconHolder, 9)

	local icon = text(iconHolder, iconText or "◉", 10, Theme.Blue, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	icon.Size = UDim2.fromScale(1, 1)

	local label = text(row, name, 13, Theme.Muted, Enum.Font.GothamSemibold)
	label.Position = UDim2.fromOffset(36, 0)
	label.Size = UDim2.new(1, -36, 1, 0)

	local api = {}
	function api:SetSelected(state)
		if state then
			row.BackgroundTransparency = 0
			row.BackgroundColor3 = Color3.fromRGB(23, 42, 67)
			label.TextColor3 = Color3.fromRGB(151, 190, 245)
			iconHolder.BackgroundColor3 = Color3.fromRGB(28, 59, 97)
		else
			row.BackgroundTransparency = 1
			label.TextColor3 = Theme.Muted
			iconHolder.BackgroundColor3 = Color3.fromRGB(20, 31, 45)
		end
	end
	return api
end

function TELAVIV:AddTab(name)
	local library = self
	local tab = {}
	tab.Name = name
	tab._sections = {}
	tab._sideLinks = {}

	local tabButton = button(self._headerTabs, name)
	tabButton.Size = UDim2.fromOffset(math.max(72, #name * 8 + 24), 66)
	tabButton.TextColor3 = Theme.Muted
	tabButton.Font = Enum.Font.GothamSemibold
	tabButton.TextSize = 14

	local page = new("Frame", {
		Name = name .. "Page",
		BackgroundTransparency = 1,
		Visible = false,
		Size = UDim2.fromScale(1, 1),
	}, self._content)

	padding(page, 10, 10, 9, 10)
	local columns = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, page)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, columns)

	local left = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.51, -6, 1, 0),
	}, columns)
	local right = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.49, -6, 1, 0),
	}, columns)
	new("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, left)
	new("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, right)

	tab._page = page
	tab._left = left
	tab._right = right
	tab._button = tabButton

	function tab:Select()
		for _, other in pairs(library._tabs) do
			other._page.Visible = false
			other._button.TextColor3 = Theme.Muted
		end
		page.Visible = true
		tabButton.TextColor3 = Theme.Blue
		library._activeTab = tab
	end

	tabButton.MouseButton1Click:Connect(function()
		tab:Select()
	end)

	function tab:AddSection(titleText, side)
		local parent = (side == "right") and right or left
		local section = {}
		local frame = new("Frame", {
			BackgroundColor3 = Theme.Panel,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 120),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, parent)
		corner(frame, 5)
		stroke(frame, Theme.Stroke, 1, 0)

		local header = text(frame, titleText, 14, Theme.Text, Enum.Font.GothamSemibold)
		header.Position = UDim2.fromOffset(12, 8)
		header.Size = UDim2.new(1, -24, 0, 22)

		local list = new("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 35),
			Size = UDim2.new(1, -20, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, frame)
		local layout = new("UIListLayout", {
			Padding = UDim.new(0, 7),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, list)

		padding(frame, 0, 0, 0, 10)

		local function rowBase(height)
			return new("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, height or 29),
			}, list)
		end

		function section:AddToggle(opts)
			opts = opts or {}
			local value = opts.Default == true
			local row = rowBase(29)
			local label = text(row, opts.Name or "Toggle", 13, Theme.Text, Enum.Font.GothamMedium)
			label.Size = UDim2.new(1, -38, 1, 0)

			local box = button(row, "")
			box.Size = UDim2.fromOffset(18, 18)
			box.Position = UDim2.new(1, -20, 0.5, -9)
			box.BackgroundTransparency = 0
			box.BackgroundColor3 = value and Theme.Blue2 or Color3.fromRGB(23, 34, 47)
			corner(box, 2)
			stroke(box, Color3.fromRGB(29, 43, 58), 1, 0)

			local check = text(box, "✓", 15, Theme.White, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
			check.Size = UDim2.fromScale(1, 1)
			check.Visible = value

			local function set(v, fire)
				value = not not v
				check.Visible = value
				tween(box, 0.1, {BackgroundColor3 = value and Theme.Blue2 or Color3.fromRGB(23, 34, 47)})
				if fire then safeCallback(opts.Callback, value) end
			end

			box.MouseButton1Click:Connect(function() set(not value, true) end)

			return {
				Set = function(_, v) set(v, true) end,
				Get = function() return value end,
			}
		end

		function section:AddLabel(valueText)
			local row = rowBase(26)
			local label = text(row, valueText or "Label", 13, Theme.Text, Enum.Font.GothamMedium)
			label.Size = UDim2.fromScale(1, 1)
			return label
		end

		function section:AddSlider(opts)
			opts = opts or {}
			local min = opts.Min or 0
			local max = opts.Max or 100
			local value = math.clamp(opts.Default or min, min, max)
			local row = rowBase(47)

			local label = text(row, opts.Name or "Slider", 13, Theme.Muted, Enum.Font.GothamMedium)
			label.Size = UDim2.new(1, -64, 0, 20)

			local valueLabel = text(row, tostring(value), 13, Theme.Text, Enum.Font.GothamMedium, Enum.TextXAlignment.Right)
			valueLabel.Position = UDim2.new(1, -64, 0, 0)
			valueLabel.Size = UDim2.fromOffset(64, 20)

			local track = new("Frame", {
				BackgroundColor3 = Color3.fromRGB(25, 28, 35),
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(0, 31),
				Size = UDim2.new(1, 0, 0, 6),
			}, row)
			corner(track, 3)

			local fill = new("Frame", {
				BackgroundColor3 = Theme.Blue2,
				BorderSizePixel = 0,
				Size = UDim2.new((value - min) / math.max(1, max - min), 0, 1, 0),
			}, track)
			corner(fill, 3)
			new("UIGradient", {
				Color = ColorSequence.new(Theme.Blue2, Theme.Blue),
			}, fill)

			local knob = new("Frame", {
				BackgroundColor3 = Color3.fromRGB(198, 202, 211),
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0),
				Size = UDim2.fromOffset(8, 13),
				ZIndex = 4,
			}, track)
			corner(knob, 3)
			stroke(knob, Color3.fromRGB(100, 105, 115), 1, 0)

			local drag = button(track, "")
			drag.Size = UDim2.new(1, 0, 0, 24)
			drag.Position = UDim2.fromOffset(0, -9)

			local dragging = false
			local function setFromX(x, fire)
				local p = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
				local raw = min + (max - min) * p
				local step = opts.Step or 1
				value = math.floor(raw / step + 0.5) * step
				if step < 1 then
					local decimals = math.max(0, math.ceil(-math.log10(step)))
					valueLabel.Text = string.format("%." .. decimals .. "f", value)
				else
					valueLabel.Text = tostring(math.floor(value + 0.5))
				end
				local alpha = (value - min) / math.max(1e-6, max - min)
				fill.Size = UDim2.new(alpha, 0, 1, 0)
				knob.Position = UDim2.new(alpha, 0, 0.5, 0)
				if fire then safeCallback(opts.Callback, value) end
			end

			drag.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = true
					setFromX(input.Position.X, true)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
					setFromX(input.Position.X, true)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = false
				end
			end)

			return {
				Set = function(_, v)
					value = math.clamp(v, min, max)
					local alpha = (value - min) / math.max(1e-6, max - min)
					fill.Size = UDim2.new(alpha, 0, 1, 0)
					knob.Position = UDim2.new(alpha, 0, 0.5, 0)
					valueLabel.Text = tostring(value)
					safeCallback(opts.Callback, value)
				end,
				Get = function() return value end,
			}
		end

		function section:AddDropdown(opts)
			opts = opts or {}
			local values = opts.Values or {"Option"}
			local value = opts.Default or values[1]
			local open = false

			local row = rowBase(33)
			row.ClipsDescendants = false

			local label = text(row, opts.Name or "Dropdown", 13, Theme.Text, Enum.Font.GothamMedium)
			label.Size = UDim2.new(0.52, 0, 1, 0)

			local box = button(row, "")
			box.BackgroundTransparency = 0
			box.BackgroundColor3 = Color3.fromRGB(15, 16, 21)
			box.Position = UDim2.new(0.52, 0, 0, 0)
			box.Size = UDim2.new(0.48, 0, 0, 30)
			corner(box, 3)
			stroke(box, Theme.Stroke, 1, 0)

			local selected = text(box, tostring(value), 13, Theme.Text, Enum.Font.GothamMedium)
			selected.Position = UDim2.fromOffset(10, 0)
			selected.Size = UDim2.new(1, -28, 1, 0)

			local arrow = text(box, "⌄", 13, Theme.Muted, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
			arrow.Position = UDim2.new(1, -24, 0, 0)
			arrow.Size = UDim2.fromOffset(24, 30)

			local popup = new("Frame", {
				BackgroundColor3 = Color3.fromRGB(12, 13, 18),
				BorderSizePixel = 0,
				Visible = false,
				Position = UDim2.new(0.52, 0, 0, 34),
				Size = UDim2.new(0.48, 0, 0, #values * 31 + 8),
				ZIndex = 20,
			}, row)
			corner(popup, 3)
			stroke(popup, Theme.Stroke, 1, 0)
			padding(popup, 4, 4, 4, 4)
			new("UIListLayout", {Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder}, popup)

			for _, v in ipairs(values) do
				local item = button(popup, tostring(v))
				item.Size = UDim2.new(1, 0, 0, 31)
				item.TextXAlignment = Enum.TextXAlignment.Left
				item.TextSize = 13
				item.ZIndex = 21
				item.MouseEnter:Connect(function()
					item.BackgroundTransparency = 0
					item.BackgroundColor3 = Color3.fromRGB(19, 21, 28)
				end)
				item.MouseLeave:Connect(function()
					item.BackgroundTransparency = 1
				end)
				item.MouseButton1Click:Connect(function()
					value = v
					selected.Text = tostring(v)
					open = false
					popup.Visible = false
					arrow.Text = "⌄"
					safeCallback(opts.Callback, v)
				end)
			end

			box.MouseButton1Click:Connect(function()
				open = not open
				popup.Visible = open
				arrow.Text = open and "⌃" or "⌄"
			end)

			return {
				Set = function(_, v)
					value = v
					selected.Text = tostring(v)
					safeCallback(opts.Callback, v)
				end,
				Get = function() return value end,
			}
		end

		function section:AddKeybind(opts)
			opts = opts or {}
			local current = opts.Default or Enum.KeyCode.Unknown
			local waiting = false
			local row = rowBase(33)

			local label = text(row, opts.Name or "Bind", 13, Theme.Text, Enum.Font.GothamMedium)
			label.Size = UDim2.new(0.58, 0, 1, 0)

			local bind = button(row, "")
			bind.BackgroundTransparency = 0
			bind.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
			bind.Position = UDim2.new(0.58, 0, 0, 0)
			bind.Size = UDim2.new(0.42, 0, 0, 30)
			corner(bind, 3)
			stroke(bind, Theme.Stroke, 1, 0)

			local function friendly(input)
				if typeof(input) == "EnumItem" then
					return input.Name:gsub("MouseButton", "Mouse ")
				end
				return tostring(input)
			end
			bind.Text = friendly(current)

			bind.MouseButton1Click:Connect(function()
				waiting = true
				bind.Text = "..."
			end)

			UserInputService.InputBegan:Connect(function(input, processed)
				if waiting then
					if input.UserInputType == Enum.UserInputType.Keyboard then
						current = input.KeyCode
						waiting = false
						bind.Text = friendly(current)
						safeCallback(opts.Callback, current)
					elseif input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.MouseButton2
						or input.UserInputType == Enum.UserInputType.MouseButton3 then
						current = input.UserInputType
						waiting = false
						bind.Text = friendly(current)
						safeCallback(opts.Callback, current)
					end
				end
			end)

			return {
				Set = function(_, v)
					current = v
					bind.Text = friendly(v)
					safeCallback(opts.Callback, v)
				end,
				Get = function() return current end,
			}
		end

		function section:AddButton(opts)
			opts = opts or {}
			local row = rowBase(34)
			local btn = button(row, opts.Name or "Button")
			btn.BackgroundTransparency = 0
			btn.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
			btn.Size = UDim2.fromScale(1, 1)
			btn.TextSize = 13
			corner(btn, 3)
			stroke(btn, Theme.Stroke, 1, 0)
			btn.MouseEnter:Connect(function() tween(btn, 0.1, {BackgroundColor3 = Color3.fromRGB(24, 28, 36)}) end)
			btn.MouseLeave:Connect(function() tween(btn, 0.1, {BackgroundColor3 = Color3.fromRGB(18, 20, 26)}) end)
			btn.MouseButton1Click:Connect(function() safeCallback(opts.Callback) end)
			return btn
		end

		table.insert(tab._sections, section)
		return section
	end

	table.insert(self._tabs, tab)
	if not self._activeTab then
		tab:Select()
	end
	return tab
end

function TELAVIV:Destroy()
	if self.Gui then
		self.Gui:Destroy()
	end
end

return TELAVIV
