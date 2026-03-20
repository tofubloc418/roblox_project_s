--!strict
-- Settings → Keybinds: one action row (label, key button, optional conflict glyph). Tooltip is a separate ScreenGui.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local KeybindConflictTooltipLayer = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("KeybindConflictTooltipLayer"))

export type KeybindRowProps = {
	actionId: string,
	description: string,
	keyDisplayText: string,
	isListening: boolean,
	conflictDescriptions: { string },
	rowHeight: number,
	descriptionSize: number,
	buttonWidth: number,
	buttonHeight: number,
	buttonTextSize: number,
	layoutOrder: number,
	onKeybindClicked: () -> (),
	tooltipHostScreen: ScreenGui,
}

local WARNING_SIGN = "\u{26A0}\u{FE0F}"

local function buildConflictTooltipBody(lines: { string }): string
	if #lines == 0 then
		return ""
	end
	local parts: { string } = { "This bind shares a key with other actions:", "" }
	for _, line in lines do
		table.insert(parts, "• " .. line)
	end
	return table.concat(parts, "\n")
end

local function KeybindRow(props: KeybindRowProps)
	local C = ThemeConfig.Colors
	local S = ThemeConfig.KeybindsPage
	local stroke = ThemeConfig.Colors.Stroke

	local btnHovered, setBtnHovered = React.useState(false)
	local slotHovered, setSlotHovered = React.useState(false)
	local slotRef = React.useRef(nil :: GuiObject?)

	local hasConflict = #props.conflictDescriptions > 0
	local showConflictTip = slotHovered and hasConflict and not props.isListening

	local btnStrokeColor = if props.isListening
		then S.ListeningStroke
		elseif btnHovered then stroke.Active
		else stroke.Default

	local btnStrokeThickness = if props.isListening or btnHovered then stroke.ActiveThickness else stroke.Thickness

	local btnText = if props.isListening then "Press a key…" else props.keyDisplayText
	local btnTextColor = if props.isListening then S.ListeningText else C.Text.Secondary

	local rowPad = 12
	local rightInset = 2

	local warnIconSize = math.floor(math.clamp(props.buttonHeight * 0.55, 18, 28))
	local iconGap = 6
	local warnExtra = if hasConflict then warnIconSize + iconGap else 0
	local slotWidth = props.buttonWidth + warnExtra

	local tipW = math.min(S.ConflictTooltipMaxWidth, 320)
	local tipBody = buildConflictTooltipBody(props.conflictDescriptions)

	React.useEffect(function()
		if not showConflictTip then
			KeybindConflictTooltipLayer.hide()
			return
		end
		local host = props.tooltipHostScreen
		if not host then
			return
		end

		local function tick()
			local inst = slotRef.current
			if not inst then
				return
			end
			local pos = inst.AbsolutePosition
			local sz = inst.AbsoluteSize
			KeybindConflictTooltipLayer.reposition({
				hostScreenGui = host,
				text = tipBody,
				anchorLeftX = pos.X,
				centerY = pos.Y + sz.Y * 0.5,
				maxWidth = tipW,
			})
		end

		local conn = RunService.RenderStepped:Connect(tick)
		tick()
		return function()
			conn:Disconnect()
			KeybindConflictTooltipLayer.hide()
		end
	end, { showConflictTip, tipBody, tipW, props.tooltipHostScreen } :: { any })

	local controlsChildren: { [string]: any } = {
		KeyBtn = React.createElement("TextButton", {
			Name = "KeybindButton",
			Size = UDim2.new(0, props.buttonWidth, 0, props.buttonHeight),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			BackgroundColor3 = C.Slot,
			BackgroundTransparency = C.SlotTransparency,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = btnText,
			TextColor3 = btnTextColor,
			Font = ThemeConfig.Font.FamilySecondary,
			TextSize = props.buttonTextSize,
			ZIndex = LayoutConfig.ZIndex.Content + 2,
			[React.Event.MouseEnter] = function()
				setBtnHovered(true)
			end,
			[React.Event.MouseLeave] = function()
				setBtnHovered(false)
			end,
			[React.Event.Activated] = function()
				props.onKeybindClicked()
			end,
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, S.ButtonCornerRadius),
			}),
			Stroke = React.createElement("UIStroke", {
				Color = btnStrokeColor,
				Thickness = btnStrokeThickness,
				Transparency = stroke.Transparency,
			}),
		}),
	}

	if hasConflict then
		controlsChildren.WarningIcon = React.createElement("TextLabel", {
			Name = "ConflictWarning",
			Size = UDim2.fromOffset(warnIconSize, warnIconSize),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -(props.buttonWidth + iconGap), 0.5, 0),
			BackgroundTransparency = 1,
			Text = WARNING_SIGN,
			TextColor3 = S.ConflictWarningIconColor,
			TextSize = math.floor(warnIconSize * 0.92),
			Font = ThemeConfig.Font.Family,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = LayoutConfig.ZIndex.Content + 2,
		})
	end

	return React.createElement("Frame", {
		Name = "KeybindRowOuter_" .. props.actionId,
		Size = UDim2.new(1, 0, 0, props.rowHeight),
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
		ZIndex = LayoutConfig.ZIndex.Content,
	}, {
		VLayout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		}),
		Row = React.createElement("Frame", {
			Name = "KeybindRow",
			Size = UDim2.new(1, 0, 0, props.rowHeight),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			ZIndex = LayoutConfig.ZIndex.Content,
			ClipsDescendants = false,
		}, {
			Description = React.createElement("TextLabel", {
				Name = "Description",
				Position = UDim2.fromScale(0, 0),
				Size = UDim2.new(1, -(props.buttonWidth + warnExtra + rowPad + rightInset), 1, 0),
				BackgroundTransparency = 1,
				Text = props.description,
				TextColor3 = C.Text.Primary,
				Font = ThemeConfig.Font.FamilySecondary,
				TextSize = props.descriptionSize,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = LayoutConfig.ZIndex.Content,
			}),
			KeybindSlot = React.createElement("Frame", {
				Name = "KeybindSlot",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -rightInset, 0.5, 0),
				Size = UDim2.new(0, slotWidth, 1, 0),
				BackgroundTransparency = 1,
				ZIndex = LayoutConfig.ZIndex.Content + 1,
				ref = slotRef,
				[React.Event.MouseEnter] = function()
					setSlotHovered(true)
				end,
				[React.Event.MouseLeave] = function()
					setSlotHovered(false)
				end,
			}, controlsChildren),
		}),
	})
end

return KeybindRow
