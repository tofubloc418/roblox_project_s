--!strict
-- Settings → Keybinds tab: grouped list, capture mode, reset-all, listening overlay.

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local keybindsFolder = ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Keybinds")
local KeybindIds = require(keybindsFolder:WaitForChild("KeybindIds"))
local KeybindRegistry = require(keybindsFolder:WaitForChild("KeybindRegistry"))
local KeybindsCodec = require(keybindsFolder:WaitForChild("KeybindsCodec"))
local KeybindsClient = require(script.Parent.Parent.Parent:WaitForChild("Input"):WaitForChild("KeybindsClient"))
local KeybindCategorySection = require(script.Parent:WaitForChild("KeybindCategorySection"))

export type KeybindsPageProps = {
	viewportSize: Vector2,
	--- Bumps when KeybindsClient fires so rows re-render with new display strings / conflicts.
	keybindsRevision: number,
	setKeybindsRemote: RemoteEvent,
	onListeningChange: (listening: boolean) -> (),
	settingsScreenGui: ScreenGui,
}

local P = ThemeConfig.Padding
local C = ThemeConfig.Colors
local F = ThemeConfig.Font
local L = ThemeConfig.Loadout
local K = ThemeConfig.KeybindsPage

local SECTION_DEFS: { { title: string, actionIds: { string } } } = {
	{
		title = "GAMEPLAY",
		actionIds = { KeybindIds.Sprint, KeybindIds.Jump, KeybindIds.Interact, KeybindIds.ThirdPersonCameraLock },
	},
	{
		title = "ABILITIES",
		actionIds = {
			KeybindIds.AbilitySlot1,
			KeybindIds.AbilitySlot2,
			KeybindIds.AbilitySlot3,
			KeybindIds.AbilitySlot4,
			KeybindIds.AbilitySlot5,
		},
	},
	{
		title = "HUD LOADOUT",
		actionIds = {
			KeybindIds.HudWeapon1,
			KeybindIds.HudWeapon2,
			KeybindIds.HudSwapWeapons,
			KeybindIds.HudFists,
			KeybindIds.HudQuickUse,
			KeybindIds.HudFlashlight,
		},
	},
	{ title = "INTERFACE", actionIds = { KeybindIds.ToggleLoadout, KeybindIds.ToggleMap } },
}

local function KeybindsPage(props: KeybindsPageProps)
	local viewportSize = props.viewportSize
	local refShort = L.ReferenceShortEdge or 1080
	local scale = math.clamp(math.min(viewportSize.X, viewportSize.Y) / refShort, 0.5, 2)

	local scaledP = {
		OuterFrameHorizontal = math.floor(P.OuterFrameHorizontal * scale),
		OuterFrameVertical = math.floor(P.OuterFrameVertical * scale),
		TitleToContent = math.floor(P.TitleToContent * scale),
	}

	local listeningId, setListeningId = React.useState(nil :: string?)
	local hoveredReset, setHoveredReset = React.useState(false)

	local rowH = math.floor(K.RowHeight * scale)
	local btnW = math.floor(K.ButtonWidth * scale)
	local btnH = math.floor(K.ButtonHeight * scale)
	local descSize = math.floor(F.SectionHeaderSize * 0.75 * scale)
	local btnTextSize = math.floor(F.SectionHeaderSize * 0.7 * scale)
	local titleSize = math.floor(F.TitleSize * 0.55 * scale)
	local catTitleSize = math.floor(F.SectionHeaderSize * 0.85 * scale)

	React.useEffect(function()
		local currentId = listeningId
		if not currentId then
			return
		end

		KeybindsClient.setGameplayActionsSuppressed(true)
		props.onListeningChange(true)

		local conn = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
			if gameProcessed and not KeybindsClient.areGameplayActionsSuppressed() then
				return
			end

			if input.UserInputType ~= Enum.UserInputType.Keyboard then
				return
			end

			if input.KeyCode == Enum.KeyCode.Escape then
				setListeningId(nil :: string?)
				return
			end

			local keyCode = input.KeyCode
			if keyCode == Enum.KeyCode.Unknown then
				return
			end

			local name = KeybindsCodec.KeyCodeToName(keyCode)
			props.setKeybindsRemote:FireServer(currentId, { name })

			setListeningId(nil :: string?)
		end)

		return function()
			conn:Disconnect()
			KeybindsClient.setGameplayActionsSuppressed(false)
			props.onListeningChange(false)
		end
	end, { listeningId } :: { any })

	local sectionsChildren: { [string]: any } = {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, math.floor(K.CategoryGap * scale)),
		}),
		Title = React.createElement("TextLabel", {
			Name = "KeybindsTitle",
			Size = UDim2.new(1, 0, 0, math.floor(F.TitleHeight * 0.5 * scale)),
			BackgroundTransparency = 1,
			Text = "KEYBINDS",
			TextColor3 = C.Text.Primary,
			Font = F.Family,
			TextSize = titleSize,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 1,
			ZIndex = LayoutConfig.ZIndex.Content,
		}),
	}

	local sectionLayoutOrder = 2
	for _, section in SECTION_DEFS do
		local rowProps: { { [string]: any } } = {}
		for _, actionId in section.actionIds do
			local entry = KeybindRegistry.Get(actionId)
			local description = if entry then entry.description else actionId

			table.insert(rowProps, {
				actionId = actionId,
				description = description,
				keyDisplayText = KeybindsClient.getDisplayString(actionId),
				isListening = listeningId == actionId,
				conflictDescriptions = KeybindsClient.getConflictDescriptionsForAction(actionId),
				rowHeight = rowH,
				descriptionSize = descSize,
				buttonWidth = btnW,
				buttonHeight = btnH,
				buttonTextSize = btnTextSize,
				tooltipHostScreen = props.settingsScreenGui,
				onKeybindClicked = function()
					if listeningId == actionId then
						setListeningId(nil :: string?)
					else
						setListeningId(actionId)
					end
				end,
			})
		end

		sectionsChildren["Section_" .. section.title] = React.createElement(KeybindCategorySection, {
			categoryTitle = section.title,
			layoutOrder = sectionLayoutOrder,
			categoryTitleTextSize = catTitleSize,
			rowProps = rowProps,
		})
		sectionLayoutOrder += 1
	end

	local resetW = math.floor(K.ResetButtonWidth * scale)
	local resetH = math.floor(K.ButtonHeight * scale) + 4

	sectionsChildren.ResetSpacer = React.createElement("Frame", {
		Name = "ResetSpacer",
		Size = UDim2.new(1, 0, 0, math.floor(16 * scale)),
		BackgroundTransparency = 1,
		LayoutOrder = sectionLayoutOrder,
	})
	sectionLayoutOrder += 1

	sectionsChildren.ResetAll = React.createElement("TextButton", {
		Name = "ResetAllKeybinds",
		Size = UDim2.new(0, resetW, 0, resetH),
		BackgroundColor3 = C.Slot,
		BackgroundTransparency = C.SlotTransparency,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "RESET ALL TO DEFAULT",
		TextColor3 = C.Text.Primary,
		Font = F.Family,
		TextSize = btnTextSize,
		LayoutOrder = sectionLayoutOrder,
		ZIndex = LayoutConfig.ZIndex.Content + 1,
		[React.Event.MouseEnter] = function()
			setHoveredReset(true)
		end,
		[React.Event.MouseLeave] = function()
			setHoveredReset(false)
		end,
		[React.Event.Activated] = function()
			for actionId, _ in KeybindRegistry.GetAll() do
				props.setKeybindsRemote:FireServer(actionId, {})
			end
		end,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, K.ButtonCornerRadius),
		}),
		Stroke = React.createElement("UIStroke", {
			Color = if hoveredReset then C.Stroke.Active else C.Stroke.Default,
			Thickness = if hoveredReset then C.Stroke.ActiveThickness else C.Stroke.Thickness,
			Transparency = C.Stroke.Transparency,
		}),
	})

	local listeningOverlay = if listeningId
		then React.createElement("TextButton", {
			Name = "KeybindListeningOverlay",
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0, 0),
			BackgroundTransparency = 0.4,
			BackgroundColor3 = C.MainFrame,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			ZIndex = LayoutConfig.Settings.ListeningOverlayZIndex,
			Active = true,
			[React.Event.Activated] = function()
				setListeningId(nil :: string?)
			end,
		})
		else nil

	return React.createElement("Frame", {
		Name = "KeybindsPage",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = LayoutConfig.ZIndex.Content,
	}, {
		Scroll = React.createElement("ScrollingFrame", {
			Name = "KeybindsScroll",
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.fromOffset(0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
			ScrollBarThickness = C.ScrollBar.Thickness,
			ScrollBarImageColor3 = C.ScrollBar.Color,
			ScrollBarImageTransparency = C.ScrollBar.Transparency,
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			ZIndex = LayoutConfig.ZIndex.Content,
		}, {
			ScrollContent = React.createElement("Frame", {
				Name = "KeybindsScrollContent",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
			}, {
				Pad = React.createElement("UIPadding", {
					PaddingTop = UDim.new(0, scaledP.TitleToContent),
					PaddingBottom = UDim.new(0, scaledP.OuterFrameVertical),
					PaddingLeft = UDim.new(0, scaledP.OuterFrameHorizontal),
					PaddingRight = UDim.new(
						0,
						scaledP.OuterFrameHorizontal + math.floor(K.ScrollGapNextToTrack * scale)
					),
				}),
				Inner = React.createElement("Frame", {
					Name = "KeybindsInner",
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
				}, sectionsChildren),
			}),
		}),
		Overlay = listeningOverlay,
	})
end

return KeybindsPage
