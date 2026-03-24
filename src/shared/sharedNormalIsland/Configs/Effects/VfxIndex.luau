--!strict
--[[
	Central registry of VFX model assets.
	Each key is a short nameID used everywhere in code; values are rbxassetid strings.
	EffectTemplatePreloader loads every entry into ReplicatedStorage.EffectAssets.VFX/<nameID>.
]]

return {
	PrayerSurge = "rbxassetid://119567762929429",
	MagicCircle = "rbxassetid://133872987940774",
}
