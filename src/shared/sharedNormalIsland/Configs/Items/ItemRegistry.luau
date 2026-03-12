--!strict
-- ItemRegistry
-- Single access point for every item template in the game.
--
-- HOW IT WORKS:
--   Sub-modules (Weapons/Greatswords.luau, Consumables/Healing.luau, etc.) call
--   ItemRegistry.Register(template) at require-time to publish their items.
--   No central list needs to be maintained here; just require the sub-modules
--   from this file and they self-register.
--
-- HOW TO ADD A NEW ITEM:
--   1. Create or open the appropriate sub-module in Configs/Items/<Category>/.
--   2. Require ItemRegistry from that module and call ItemRegistry.Register(template)
--      for each item.
--   3. Require your sub-module in the "Sub-module auto-discovery" section below.
--      (Until sub-modules exist, the registry starts empty and returns nil for all lookups.)
--
-- HOW TO QUERY:
--   local template = ItemRegistry.GetTemplate("IronGreatsword")
--   local allWeapons = ItemRegistry.GetTemplatesByCategory("Weapon")
--   local greatswords = ItemRegistry.GetTemplatesBySubcategory("Greatsword")

local ItemRegistry = {}

-- ── Internal storage ──────────────────────────────────────────────────────────

-- All registered templates, keyed by templateId.
local _templates: { [string]: any } = {}

-- ── Registration ──────────────────────────────────────────────────────────────

-- Register a single item template. Called by sub-modules during require.
-- Asserts that the required base fields are present.
function ItemRegistry.Register(template: any)
	assert(type(template) == "table",      "ItemRegistry.Register: template must be a table")
	assert(type(template.templateId) == "string" and #template.templateId > 0,
		"ItemRegistry.Register: templateId must be a non-empty string")
	assert(type(template.category) == "string",
		"ItemRegistry.Register: category must be a string (got templateId = " .. tostring(template.templateId) .. ")")

	if _templates[template.templateId] then
		warn("[ItemRegistry] Duplicate templateId registered: " .. template.templateId)
	end

	_templates[template.templateId] = template
end

-- ── Lookup API ────────────────────────────────────────────────────────────────

-- Returns the template for the given templateId, or nil if not registered.
function ItemRegistry.GetTemplate(templateId: string): any?
	return _templates[templateId]
end

-- Returns all templates whose category matches the given string.
function ItemRegistry.GetTemplatesByCategory(category: string): { any }
	local result: { any } = {}
	for _, t in pairs(_templates) do
		if t.category == category then
			table.insert(result, t)
		end
	end
	return result
end

-- Returns all templates whose subcategory matches the given string.
function ItemRegistry.GetTemplatesBySubcategory(subcategory: string): { any }
	local result: { any } = {}
	for _, t in pairs(_templates) do
		if t.subcategory == subcategory then
			table.insert(result, t)
		end
	end
	return result
end

-- Returns all templates whose rarity matches the given string.
function ItemRegistry.GetTemplatesByRarity(rarity: string): { any }
	local result: { any } = {}
	for _, t in pairs(_templates) do
		if t.rarity == rarity then
			table.insert(result, t)
		end
	end
	return result
end

-- Returns all registered weapon templates.
function ItemRegistry.GetWeaponTemplates(): { any }
	return ItemRegistry.GetTemplatesByCategory("Weapon")
end

-- Returns a snapshot of every registered template.
function ItemRegistry.GetAll(): { [string]: any }
	return table.clone(_templates)
end

-- Returns true if a template is registered for the given templateId.
function ItemRegistry.TemplateExists(templateId: string): boolean
	return _templates[templateId] ~= nil
end

-- Filtered random pick. filter fields (all optional):
--   category, subcategory, rarity, minLevel, maxLevel
-- Returns nil if no templates match the filter.
function ItemRegistry.GetRandomTemplate(filter: { [string]: any }?): any?
	local candidates: { any } = {}
	for _, t in pairs(_templates) do
		local ok = true
		if filter then
			if filter.category then
				local cats = if type(filter.category) == "table" then filter.category else { filter.category }
				local found = false
				for _, c in ipairs(cats) do
					if t.category == c then found = true; break end
				end
				if not found then ok = false end
			end
			if ok and filter.subcategory then
				local subs = if type(filter.subcategory) == "table" then filter.subcategory else { filter.subcategory }
				local found = false
				for _, s in ipairs(subs) do
					if t.subcategory == s then found = true; break end
				end
				if not found then ok = false end
			end
			if ok and filter.rarity then
				local rars = if type(filter.rarity) == "table" then filter.rarity else { filter.rarity }
				local found = false
				for _, r in ipairs(rars) do
					if t.rarity == r then found = true; break end
				end
				if not found then ok = false end
			end
			if ok and filter.minLevel and (t.levelReq or 0) < filter.minLevel then
				ok = false
			end
			if ok and filter.maxLevel and (t.levelReq or 0) > filter.maxLevel then
				ok = false
			end
		end
		if ok then
			table.insert(candidates, t)
		end
	end
	if #candidates == 0 then return nil end
	return candidates[math.random(1, #candidates)]
end

-- ── Sub-module auto-discovery ─────────────────────────────────────────────────
-- Require each item config sub-module here, we will register their exported templates.
-- Add new sub-module requires here as item files are created.

local function registerFile(moduleScript: Instance)
	local itemsConfig = require(moduleScript :: ModuleScript) :: any
	for _, template in pairs(itemsConfig) do
		ItemRegistry.Register(template)
	end
end

registerFile(script.Parent:WaitForChild("TestItems"))
registerFile(script.Parent:WaitForChild("Weapons"):WaitForChild("Greatswords"))
registerFile(script.Parent:WaitForChild("Weapons"):WaitForChild("Daggers"))
registerFile(script.Parent:WaitForChild("Weapons"):WaitForChild("ThrustingSwords"))
registerFile(script.Parent:WaitForChild("Weapons"):WaitForChild("Fists"))

return ItemRegistry
