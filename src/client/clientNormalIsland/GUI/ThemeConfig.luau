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
	ColumnGap = 64,

	-- Title header to content gap
	TitleToContent = 12,

	-- Section headers to content gap
	HeaderToContent = 8,

	-- Equipment panel
	BackpackShieldGap = 16,
	CardRowGap = 32,

	-- Grid slots
	InventorySlot = 8,
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

	-- Slot/card labels (e.g. "Backpack", "Shield", "Weapon 1"). Height scale of label area (0.2 = 20% of slot height)
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
	Inventory = Color3.fromRGB(80, 255, 80),
	QuickUse = Color3.fromRGB(80, 80, 255),
	Transparency = 1, -- 1 = invisible
}

--[[
	LOADOUT-SPECIFIC (layout ratios, etc.)
]]
ThemeConfig.Loadout = {
	WidthScale = 0.70,
	ColumnRatioEquip = 3,
	ColumnRatioInv = 4,
	ColumnRatioQuick = 3,
	AbilitySlotSize = 48,
	OuterCardHeightRatio = 6 / 9, -- height:width
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

return ThemeConfig
