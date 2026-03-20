--!strict
-- Settings shell: tab bar + active page (loadout, keybinds, …).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local ThemeConfig = require(script.Parent.Parent:WaitForChild("ThemeConfig"))
local LayoutConfig = require(script.Parent.Parent:WaitForChild("LayoutConfig"))
local LoadoutApp = require(script.Parent.Parent:WaitForChild("Loadout"):WaitForChild("LoadoutApp"))
local TabBar = require(script.Parent:WaitForChild("TabBar"))
local KeybindsPage = require(script.Parent:WaitForChild("KeybindsPage"))
local AbilityPage = require(script.Parent:WaitForChild("AbilityPage"))
local InventoryTypes = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Data"):WaitForChild("PlayerDataTypes"))

type LoadoutData = InventoryTypes.LoadoutData
type EquipmentSlotId = InventoryTypes.EquipmentSlotId

export type SettingsShellAppProps = {
	activeTabId: string,
	onTabActivated: (tabId: string) -> (),
	viewportSize: Vector2,

	loadoutData: LoadoutData,
	loadoutRows: number,
	loadoutCols: number,
	inventoryGridRef: { current: Frame? }?,
	loadoutDragEnabled: boolean?,
	onLoadoutDragStart: (index: number) -> (),
	onLoadoutEquipmentDragStart: (slotId: EquipmentSlotId) -> (),
	onLoadoutQuickUseDragStart: (index: number) -> (),
	onLoadoutEquipmentClick: (slotId: EquipmentSlotId) -> (),
	onLoadoutAbilityClick: (weaponIndex: number, abilityIndex: number) -> (),
	onLoadoutQuickUseClick: (index: number) -> (),
	onLoadoutMouseEnter: (index: number) -> (),
	onLoadoutMouseLeave: (index: number) -> (),

	keybindsRevision: number,
	setKeybindsRemote: RemoteEvent,
	onKeybindListeningChange: (listening: boolean) -> (),
	settingsScreenGui: ScreenGui,

	abilityPresets: { [string]: any }?,
	unlockedAbilities: { [string]: boolean }?,
	abilityDragEnabled: boolean?,
	onAbilityDragToPreset: ((abilityId: string, weaponTag: string, slotIndex: number) -> ())?,
}

local P = ThemeConfig.Padding
local F = ThemeConfig.Font
local C = ThemeConfig.Colors
local R = ThemeConfig.CornerRadius
local L = ThemeConfig.Loadout
local S = ThemeConfig.Settings

local function SettingsShellApp(props: SettingsShellAppProps)
	local viewportSize = props.viewportSize
	local refShort = L.ReferenceShortEdge or 1080
	local scale = math.clamp(math.min(viewportSize.X, viewportSize.Y) / refShort, 0.5, 2)

	local scaledP = {
		OuterFrameHorizontal = math.floor(P.OuterFrameHorizontal * scale),
		OuterFrameVertical = math.floor(P.OuterFrameVertical * scale),
		TitleToContent = math.floor(P.TitleToContent * scale),
	}

	-- Tabs scale about half as fast as the rest of the UI
	local tabScale = 1 + (scale - 1) * 0.5
	local tabBarH = math.floor(S.TabBarHeight * tabScale)
	local tabBarGap = math.floor(S.TabGap * tabScale)

	local shellContentWidth = viewportSize.X * L.WidthScale - scaledP.OuterFrameHorizontal * 2

	local loadoutElement = React.createElement(LoadoutApp, {
		loadoutData = props.loadoutData,
		rows = props.loadoutRows,
		cols = props.loadoutCols,
		viewportSize = viewportSize,
		inventoryGridRef = props.inventoryGridRef,
		dragEnabled = props.loadoutDragEnabled,
		showHeader = false,
		embeddedInShell = true,
		shellContentWidth = shellContentWidth,
		onDragStart = props.onLoadoutDragStart,
		onEquipmentDragStart = props.onLoadoutEquipmentDragStart,
		onQuickUseDragStart = props.onLoadoutQuickUseDragStart,
		onEquipmentClick = props.onLoadoutEquipmentClick,
		onAbilityClick = props.onLoadoutAbilityClick,
		onQuickUseClick = props.onLoadoutQuickUseClick,
		onMouseEnter = props.onLoadoutMouseEnter,
		onMouseLeave = props.onLoadoutMouseLeave,
	})

	local keybindsElement = React.createElement(KeybindsPage, {
		viewportSize = viewportSize,
		keybindsRevision = props.keybindsRevision,
		setKeybindsRemote = props.setKeybindsRemote,
		onListeningChange = props.onKeybindListeningChange,
		settingsScreenGui = props.settingsScreenGui,
	})

	local abilitiesElement = React.createElement(AbilityPage, {
		viewportSize = viewportSize,
		abilityPresets = props.abilityPresets or {},
		unlockedAbilities = props.unlockedAbilities or {},
		dragEnabled = props.abilityDragEnabled,
		onAbilityDragToPreset = props.onAbilityDragToPreset or function() end,
	})

	local activePage = if props.activeTabId == "loadout"
		then loadoutElement
		elseif props.activeTabId == "abilities" then abilitiesElement
		elseif props.activeTabId == "keybinds" then keybindsElement
		else loadoutElement

	return React.createElement("Frame", {
		Name = "SettingsShellRoot",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		UnifiedContainer = React.createElement("Frame", {
			Name = "UnifiedContainer",
			AnchorPoint = LayoutConfig.Container.AnchorPoint,
			Position = LayoutConfig.Container.Position,
			Size = UDim2.fromScale(L.WidthScale, 1 - 2 * LayoutConfig.Container.VerticalMarginScale),
			BackgroundColor3 = C.MainFrame,
			BackgroundTransparency = C.MainFrameTransparency,
			ZIndex = LayoutConfig.ZIndex.MainFrame,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, R.MainFrame) }),
			Padding = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0, scaledP.TitleToContent),
				PaddingBottom = UDim.new(0, scaledP.OuterFrameVertical),
				PaddingLeft = UDim.new(0, scaledP.OuterFrameHorizontal),
				PaddingRight = UDim.new(0, scaledP.OuterFrameHorizontal),
			}),
			Column = React.createElement("Frame", {
				Name = "ShellColumn",
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
			}, {
				TabBar = React.createElement(TabBar, {
					activeTabId = props.activeTabId,
					onTabActivated = props.onTabActivated,
					tabBarHeight = S.TabBarHeight,
					tabFontSize = F.SectionHeaderSize * 0.82,
					scale = tabScale,
				}),
				Content = React.createElement("Frame", {
					Name = "ShellContent",
					Position = UDim2.fromOffset(0, tabBarH + tabBarGap),
					Size = UDim2.new(1, 0, 1, -(tabBarH + tabBarGap)),
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					ZIndex = LayoutConfig.ZIndex.Content,
				}, {
					ActivePage = activePage,
				}),
			}),
		}),
	})
end

return SettingsShellApp
