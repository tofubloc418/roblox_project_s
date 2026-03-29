--!strict
-- Stance animation keys → rbxassetid (idle, equip, unequip, block).
-- Keys: <WeaponTag>_<Stance> where WeaponTag matches ItemEnums.WeaponTag and Stance is Idle | Equip | Unequip | Block.
-- Weapon templates reference these via idleMotionId, equipMotionId, unequipMotionId, blockMotionId (optional).
-- Consumed by client WeaponController. Do not duplicate animationId on weapon entries.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemEnums = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"):WaitForChild("ItemEnums")) :: any

export type WeaponStanceAnimationProfile = {
	animationId: string,
}

local WT = ItemEnums.WeaponTag

local ZERO = "rbxassetid://0"

local profiles: { [string]: WeaponStanceAnimationProfile } = {
	[WT.Dagger .. "_Idle"] = { animationId = "rbxassetid://135819574207330" },
	[WT.Dagger .. "_Equip"] = { animationId = "rbxassetid://78451337366421" },
	[WT.Dagger .. "_Unequip"] = { animationId = "rbxassetid://79025678399582" },
	[WT.Dagger .. "_Block"] = { animationId = ZERO },

	[WT.Axe .. "_Idle"] = { animationId = "rbxassetid://112151615655157" },
	[WT.Axe .. "_Equip"] = { animationId = "rbxassetid://79058443592728" },
	[WT.Axe .. "_Unequip"] = { animationId = "rbxassetid://83081513554352" },
	[WT.Axe .. "_Block"] = { animationId = ZERO },

	[WT.Fists .. "_Idle"] = { animationId = "rbxassetid://94290289092098" },
	[WT.Fists .. "_Equip"] = { animationId = ZERO },
	[WT.Fists .. "_Unequip"] = { animationId = ZERO },
	[WT.Fists .. "_Block"] = { animationId = ZERO },

	-- [WT.Greatsword .. "_Idle"] = { animationId = "rbxassetid://85174103443314" },
	[WT.Greatsword .. "_Idle"] = { animationId = ZERO },
	[WT.Greatsword .. "_Equip"] = { animationId = ZERO },
	[WT.Greatsword .. "_Unequip"] = { animationId = ZERO },
	[WT.Greatsword .. "_Block"] = { animationId = ZERO },

	[WT.ThrustingSword .. "_Idle"] = { animationId = ZERO },
	[WT.ThrustingSword .. "_Equip"] = { animationId = ZERO },
	[WT.ThrustingSword .. "_Unequip"] = { animationId = ZERO },
	[WT.ThrustingSword .. "_Block"] = { animationId = ZERO },
}

local WeaponStanceAnimationProfiles = {}

function WeaponStanceAnimationProfiles.GetProfile(motionId: string): WeaponStanceAnimationProfile?
	if type(motionId) ~= "string" or motionId == "" then
		return nil
	end
	return profiles[motionId]
end

function WeaponStanceAnimationProfiles.GetAnimationId(motionId: string): string
	assert(type(motionId) == "string" and #motionId > 0, "[WeaponStanceAnimationProfiles] motionId must be a non-empty string")
	local profile = profiles[motionId]
	assert(profile, "[WeaponStanceAnimationProfiles] unknown motionId: " .. motionId)
	return profile.animationId
end

function WeaponStanceAnimationProfiles.GetAll(): { [string]: WeaponStanceAnimationProfile }
	return profiles
end

return WeaponStanceAnimationProfiles
