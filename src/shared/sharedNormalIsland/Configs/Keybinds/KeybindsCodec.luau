--!strict

local DISPLAY_NAMES: { [string]: string } = {
	LeftControl = "LCtrl",
	RightControl = "RCtrl",
	LeftShift = "LShift",
	RightShift = "RShift",
	LeftAlt = "LAlt",
	RightAlt = "RAlt",
	One = "1",
	Two = "2",
	Three = "3",
	Four = "4",
	Five = "5",
	Six = "6",
	Seven = "7",
	Eight = "8",
	Nine = "9",
	Zero = "0",
}

local KEYCODE_BY_NAME: { [string]: Enum.KeyCode } = {}
for _, item in ipairs(Enum.KeyCode:GetEnumItems()) do
	if item ~= Enum.KeyCode.Unknown then
		KEYCODE_BY_NAME[item.Name] = item
	end
end

local function dedupeStrings(values: { string }): { string }
	local seen: { [string]: boolean } = {}
	local result: { string } = {}

	for _, value in ipairs(values) do
		if not seen[value] then
			seen[value] = true
			table.insert(result, value)
		end
	end

	return result
end

local function dedupeKeyCodes(values: { Enum.KeyCode }): { Enum.KeyCode }
	local seen: { [string]: boolean } = {}
	local result: { Enum.KeyCode } = {}

	for _, value in ipairs(values) do
		if not seen[value.Name] then
			seen[value.Name] = true
			table.insert(result, value)
		end
	end

	return result
end

local KeybindsCodec = {}

function KeybindsCodec.KeyCodeToName(keyCode: Enum.KeyCode?): string
	if not keyCode then
		return "Unknown"
	end
	return (keyCode :: Enum.KeyCode).Name
end

function KeybindsCodec.NameToKeyCode(name: string): Enum.KeyCode?
	return KEYCODE_BY_NAME[name]
end

function KeybindsCodec.NormalizeStoredValue(value: any): { string }?
	if type(value) == "string" then
		return { value }
	end

	if type(value) ~= "table" then
		return nil
	end

	local names: { string } = {}
	for _, entry in ipairs(value) do
		if type(entry) == "string" then
			table.insert(names, entry)
		end
	end

	return dedupeStrings(names)
end

function KeybindsCodec.KeyCodesToNames(keyCodes: { Enum.KeyCode }): { string }
	local names: { string } = {}
	for _, keyCode in ipairs(keyCodes) do
		table.insert(names, KeybindsCodec.KeyCodeToName(keyCode))
	end
	return dedupeStrings(names)
end

function KeybindsCodec.NamesToKeyCodes(names: { string }): { Enum.KeyCode }
	local keyCodes: { Enum.KeyCode } = {}
	for _, name in ipairs(names) do
		local keyCode = KeybindsCodec.NameToKeyCode(name)
		if keyCode then
			table.insert(keyCodes, keyCode)
		end
	end
	return dedupeKeyCodes(keyCodes)
end

function KeybindsCodec.FormatKeyCode(keyCode: Enum.KeyCode): string
	return DISPLAY_NAMES[keyCode.Name] or keyCode.Name
end

function KeybindsCodec.FormatKeyCodes(keyCodes: { Enum.KeyCode }): string
	if #keyCodes == 0 then
		return "Unbound"
	end

	local parts: { string } = {}
	for _, keyCode in ipairs(keyCodes) do
		table.insert(parts, KeybindsCodec.FormatKeyCode(keyCode))
	end

	return table.concat(parts, " / ")
end

return table.freeze(KeybindsCodec)
