--!strict
-- Shared theme config for GUI components. Use this to maintain visual consistency across the app.

local ThemeConfig = {}

--[[
	PADDING
]]
ThemeConfig.Padding = {
	-- Main frame (Loadout container)
	OuterFrameHorizontal = 48,
	OuterFrameVertical = 8,
	ColumnGap = 32,

	-- Title header to content gap
	TitleToContent = 12,

	-- Section headers to content gap
	HeaderToContent = 8,

	-- Equipment panel
	BackpackArmorGap = 16,
	CardRowGap = 32,

	-- Grid slots (BackpackSlot used for backpack grid gap; QuickUsePanel uses it when matching backpack sizing)
	BackpackSlot = 8,
	QuickUseSlot = 6,

	-- Cards
	Card = 8,
	AbilitySlot = 4,
}

--[[
	FONT
]]
ThemeConfig.Font = {
	Family = Enum.Font.GothamBold,
	FamilySecondary = Enum.Font.Gotham,

	-- Main title (e.g. "LOADOUT")
	TitleSize = 48,
	TitleHeight = 48,

	-- Section headers (e.g. "EQUIPMENT", "BACKPACK", "QUICK USE")
	SectionHeaderSize = 24,
	SectionHeaderHeight = 48,

	-- Slot/card labels (e.g. "Backpack", "Armor", "Weapon 1"). Height scale of label area (0.2 = 20% of slot height)
	SlotLabelHeightScale = 0.2,
}

--[[
	COLORS - Backgrounds
]]
ThemeConfig.Colors = {
	-- Main frame background
	MainFrame = Color3.fromRGB(22, 22, 28),
	MainFrameTransparency = 0.3,

	-- Card backgrounds (weapon card outer, etc.)
	Card = Color3.fromRGB(28, 28, 36),
	CardTransparency = 0.4,

	-- Slot backgrounds (inventory, equipment, ability, quick-use)
	Slot = Color3.fromRGB(35, 35, 42),
	SlotTransparency = 0.5,

	-- Inner card (weapon visual area)
	SlotInner = Color3.fromRGB(35, 35, 42),
	SlotInnerTransparency = 0.5,
}

--[[
	COLORS - Strokes / Borders
]]
ThemeConfig.Colors.Stroke = {
	Default = Color3.fromRGB(60, 60, 68),
	Transparency = 0.3,
	Thickness = 1,

	-- Active/selected state (e.g. equipped inventory slot)
	Active = Color3.fromRGB(218, 165, 32),
	ActiveThickness = 2,
}

--[[
	COLORS - Text
]]
ThemeConfig.Colors.Text = {
	Primary = Color3.fromRGB(255, 255, 255),
	Secondary = Color3.fromRGB(180, 180, 190),
}

--[[
	CORNERS
]]
ThemeConfig.CornerRadius = {
	MainFrame = 12,
	Card = 6,
	Slot = 6,
	SlotSmall = 4,
}

--[[
	GRADIENT BORDER - hover effect rim (white/blue/purple)
]]
ThemeConfig.GradientBorder = {
	BorderWidth = 3,
	AnimationSpeed = 90, -- degrees per second
	SpeedVariance = 0.4, -- ±40% random variation
	Colors = {
		White = Color3.fromRGB(255, 255, 255),
		Cyan = Color3.fromRGB(100, 180, 255),
		Purple = Color3.fromRGB(180, 100, 255),
	},
}

--[[
	SCROLL BARS
]]
ThemeConfig.Colors.ScrollBar = {
	Color = Color3.fromRGB(60, 60, 68),
	Transparency = 0.4,
	Thickness = 4,
}

--[[
	DEBUG - Column colors (red/green/blue). Set transparency to 0.5 to show for layout debugging.
]]
ThemeConfig.DebugColumnColors = {
	Equipment = Color3.fromRGB(255, 80, 80),
	Backpack = Color3.fromRGB(80, 255, 80),
	QuickUse = Color3.fromRGB(80, 80, 255),
	Transparency = 1, -- 1 = invisible
}

--[[
	LOADOUT-SPECIFIC (layout ratios, etc.)
]]
ThemeConfig.Loadout = {
	WidthScale = 0.70,
	ColumnRatioEquip = 3,
	ColumnRatioBackpack = 4,
	ColumnRatioQuick = 3,
	AbilitySlotSize = 48,
	OuterCardHeightRatio = 6 / 9, -- height:width
	-- Reference short edge for scale factor (scale = min(X,Y) / ReferenceShortEdge)
	ReferenceShortEdge = 1080,
	-- Min scale for ability slots so they don't shrink too fast when only viewport height is reduced
	AbilitySlotMinScale = 0.65,
}

--[[
	HUD LOADOUT (in-game equipment section, lower-right corner)
]]
ThemeConfig.HudLoadout = {
	-- Gap between the three columns and between the two weapon cards (same value)
	ColumnGap = 16,

	-- Q and 3 slot visual area (square) — 1.5x scale
	SlotSize = 120,

	-- Weapon slot visual area (slightly wider than square to fit name in bar)
	WeaponSlotWidth = 168,
	WeaponSlotHeight = 120,

	-- Keybind bar attached to the top of each slot
	BarHeight = 45,
	BarFontSize = 26,

	-- Active slot bar: white background, dark text
	BarActiveBackground = Color3.fromRGB(255, 255, 255),
	BarActiveText = Color3.fromRGB(22, 22, 28),

	-- Inactive slot bar: dark/semi-transparent background, white text
	BarInactiveBackground = Color3.fromRGB(35, 35, 42),
	BarInactiveText = Color3.fromRGB(255, 255, 255),
	BarInactiveBackgroundTransparency = 0.4,
}

--[[
	ABILITY BAR (bottom-center, 5 ability slots)
]]
ThemeConfig.AbilityBar = {
	SlotSize = 56,
	SlotGap = 8,
	KeyLabelFontSize = 15,
	KeyLabelHeight = 20,
	KeyLabelToSlotGap = 5,
	-- HUD-only: squared like PlayerStatsHUD bar outlines; inner rim for depth
	HudCornerRadius = 0,
	HudInset = 3,
	HudOuterStroke = {
		Default = Color3.fromRGB(248, 249, 255),
		DefaultTransparency = 0.5,
		DefaultThickness = 2,
	},
	HudInnerStroke = {
		Color = Color3.fromRGB(12, 12, 18),
		Transparency = 0.55,
		Thickness = 1,
	},
}

--[[
	SETTINGS SHELL (tabbed loadout / keybinds / future pages)
]]
ThemeConfig.Settings = {
	TabBarHeight = 40,
	TabPadding = 12,
	TabGap = 2,
	TabMinWidth = 120,
	TabCornerRadius = 6,

	TabActiveBackground = Color3.fromRGB(22, 22, 28),
	TabActiveBackgroundTransparency = 0.3,
	TabActiveText = Color3.fromRGB(255, 255, 255),

	TabInactiveBackground = Color3.fromRGB(35, 35, 42),
	TabInactiveBackgroundTransparency = 0.5,
	TabInactiveText = Color3.fromRGB(180, 180, 190),

	TabHoverText = Color3.fromRGB(220, 220, 230),
	TabHoverBackgroundTransparency = 0.35,
}

ThemeConfig.KeybindsPage = {
	RowHeight = 44,
	RowGap = 4,
	CategoryGap = 20,
	ButtonWidth = 140,
	ButtonHeight = 34,
	ButtonCornerRadius = 6,

	ListeningText = Color3.fromRGB(100, 180, 255),
	ListeningStroke = Color3.fromRGB(100, 180, 255),
	ConflictText = Color3.fromRGB(255, 180, 80),
	ConflictWarningIconColor = Color3.fromRGB(225, 110, 120),
	ConflictTooltipBackground = Color3.fromRGB(26, 29, 34),
	ConflictTooltipTransparency = 0,
	ConflictTooltipText = Color3.fromRGB(245, 248, 252),
	ConflictTooltipMaxWidth = 260,
	ConflictTooltipTextSize = 15,
	ResetButtonWidth = 220,
	ScrollGapNextToTrack = 10,
}

ThemeConfig.AbilitiesPage = {
	-- Column width ratios (left : center : right)
	ColumnRatioTags = 3,
	ColumnRatioPool = 4,
	ColumnRatioDetails = 3,

	-- Weapon-tag list (left column)
	TagRowHeight = 52,
	TagRowGap = 4,
	TagHeaderHeight = 48,
	SearchBarHeight = 32,
	SearchBarGap = 6,
	TagSelectedColor = Color3.fromRGB(22, 22, 28), -- same as TabActiveBackground
	TagSelectedTransparency = 0.3,                  -- same as TabActiveBackgroundTransparency
	TagHoverText = Color3.fromRGB(220, 220, 230),

	-- Preset slot row inside expanded tag
	PresetSlotSize = 40,
	PresetSlotGap = 6,
	PresetRowPadding = 8,

	-- Ability pool grid (center column)
	PoolSlotSize = 64,
	PoolSlotGap = 8,
	PoolCols = 4,

	-- Details pane (right column)
	DetailsIconSize = 96,
	DetailsTagPillHeight = 26,
}

return ThemeConfig
