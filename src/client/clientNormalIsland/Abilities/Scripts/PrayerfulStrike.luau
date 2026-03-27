--!strict
--[[
	Client ability script for PrayerfulStrike.
	- OnStarted: all clients start surge VFX on the caster's character;
	  LocalPlayer additionally plays animation, locks movement, and fires markers.
	- OnRelay: all clients play SFX/VFX for marker names from params (server relay).
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AbilityRegistry = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Abilities"):WaitForChild("AbilityRegistry")) :: any
local EffectAssets = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("EffectAssets")) :: any
local MovementControlLocks = require(
	ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MovementControl"):WaitForChild("MovementControlLocks")
) :: any
local VfxHelpers = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("VfxHelpers")) :: any

type AbilityClientContext = {
	player: Player,
	character: Model,
	abilityId: string,
	slotIndex: number,
	animator: Animator?,
}

local ABILITY_ID = "PrayerfulStrike"
local LOCK_TAG = "Ability_PrayerfulStrike"
local WEAPON_MODEL_NAME = "EquippedWeapon"

-- ── Surge visual constants ──────────────────────────────────────────────────

local SURGE_BURST_TRANS_ADD = 0.94
local SURGE_SEQUENCE_BURST_TRANS_ADD = 0.8
local SURGE_TRANSPARENCY_EASE_K = 3.5
local SURGE_DISPEL_SEC = 0.11
local SURGE_DISPEL_SIZE_MULT = 3.0
local SURGE_CLEANUP_AFTER_DISPEL = SURGE_DISPEL_SEC + 0.08

local WEAPON_RETRY_ATTEMPTS = 5
local WEAPON_RETRY_INTERVAL = 0.1

-- ── Types ───────────────────────────────────────────────────────────────────

type PartSnap = {
	p: BasePart,
	trans0: number,
	transBurst: number,
	size0: Vector3?,
	sizeBurst: Vector3?,
	sizeEnd: Vector3?,
}
type FaceSnap = { face: any, trans0: number, transBurst: number }
type SeqSnap = { obj: any, trans0: NumberSequence, transBurst: NumberSequence }
type SurgeB = {
	inst: Instance,
	conn: RBXScriptConnection?,
	alive: boolean,
	useModelScale: boolean,
	modelRoot: Model?,
	scale0: number,
	parts: { PartSnap },
	faces: { FaceSnap },
	seqSnaps: { SeqSnap },
}
type PlaybackSession = { surges: { SurgeB } }

local sessions: { [Model]: PlaybackSession } = {}

-- ── Config helpers ──────────────────────────────────────────────────────────

local function cfgAssets(): { [string]: string }?
	local c = AbilityRegistry.GetAbility(ABILITY_ID)
	return c and c.assets
end

local function assetNameId(key: string): string
	local t = cfgAssets()
	local s = t and t[key]
	return if type(s) == "string" then s else ""
end

local function cfgMarkers(): (string, string)
	local c = AbilityRegistry.GetAbility(ABILITY_ID)
	if not c then
		error(`[PrayerfulStrike] AbilityRegistry missing entry for {ABILITY_ID}`, 2)
	end
	local p = c.params
	if type(p) ~= "table" then
		error("[PrayerfulStrike] params table is required", 2)
	end
	local t = p :: any
	local mpu, mpi = t.markerPowerup, t.markerImpact
	if type(mpu) ~= "string" or mpu == "" then
		error("[PrayerfulStrike] params.markerPowerup must be a non-empty string", 2)
	end
	if type(mpi) ~= "string" or mpi == "" then
		error("[PrayerfulStrike] params.markerImpact must be a non-empty string", 2)
	end
	return mpu, mpi
end

local function surgeTune(): (number, number, number)
	local maxScale = 8.0
	local minScale = 1.0
	local duration = 2.75
	local c = AbilityRegistry.GetAbility(ABILITY_ID)
	local p = c and c.params
	if type(p) == "table" then
		local pt = p :: any
		if type(pt.surgeMaxScale) == "number" and pt.surgeMaxScale > 0 then
			maxScale = pt.surgeMaxScale
		end
		if type(pt.surgeMinScale) == "number" and pt.surgeMinScale > 0 then
			minScale = pt.surgeMinScale
		end
		if type(pt.surgeCondenseDurationSeconds) == "number" and pt.surgeCondenseDurationSeconds > 0 then
			duration = pt.surgeCondenseDurationSeconds
		end
	end
	return maxScale, minScale, duration
end

local function magicCircleTune(): (number, number)
	local offsetY = 0.35
	local lifetimeSec = 6
	local c = AbilityRegistry.GetAbility(ABILITY_ID)
	local p = c and c.params
	if type(p) == "table" then
		local pt = p :: any
		if type(pt.magicCircleOffsetY) == "number" then
			offsetY = pt.magicCircleOffsetY
		end
		if type(pt.magicCircleLifetimeSeconds) == "number" and pt.magicCircleLifetimeSeconds > 0 then
			lifetimeSec = pt.magicCircleLifetimeSeconds
		end
	end
	return offsetY, lifetimeSec
end

local function magicCircleAnimTune(): (number, number, number, number)
	local scaleMin = 0.4
	local scaleMax = 1.2
	local fadeInSec = 0.07
	local opaqueHoldSec = 0.1
	local c = AbilityRegistry.GetAbility(ABILITY_ID)
	local p = c and c.params
	if type(p) == "table" then
		local pt = p :: any
		if type(pt.magicCircleScaleMin) == "number" and pt.magicCircleScaleMin > 0 then
			scaleMin = pt.magicCircleScaleMin
		end
		if type(pt.magicCircleScaleMax) == "number" and pt.magicCircleScaleMax > 0 then
			scaleMax = pt.magicCircleScaleMax
		end
		if type(pt.magicCircleFadeInSeconds) == "number" and pt.magicCircleFadeInSeconds >= 0 then
			fadeInSec = pt.magicCircleFadeInSeconds
		end
		if type(pt.magicCircleOpaqueHoldSeconds) == "number" and pt.magicCircleOpaqueHoldSeconds >= 0 then
			opaqueHoldSec = pt.magicCircleOpaqueHoldSeconds
		end
	end
	if scaleMin > scaleMax then
		scaleMin, scaleMax = scaleMax, scaleMin
	end
	return scaleMin, scaleMax, fadeInSec, opaqueHoldSec
end

local function magicCircleMaterialFromParams(v: any): Enum.Material
	if typeof(v) == "EnumItem" then
		local e = v :: EnumItem
		if e.EnumType == Enum.Material then
			return (e :: any) :: Enum.Material
		end
	end
	return Enum.Material.Neon
end

local function magicCircleVisualTune(): (Color3, Enum.Material, number, number)
	local glowColor = Color3.fromRGB(255, 224, 96)
	local partMaterial = Enum.Material.Neon
	local lightBrightness = 2.2
	local lightRange = 14
	local c = AbilityRegistry.GetAbility(ABILITY_ID)
	local p = c and c.params
	if type(p) == "table" then
		local pt = p :: any
		if typeof(pt.magicCircleGlowColor) == "Color3" then
			glowColor = pt.magicCircleGlowColor
		end
		partMaterial = magicCircleMaterialFromParams(pt.magicCirclePartMaterial)
		if type(pt.magicCirclePointLightBrightness) == "number" and pt.magicCirclePointLightBrightness >= 0 then
			lightBrightness = pt.magicCirclePointLightBrightness
		end
		if type(pt.magicCirclePointLightRange) == "number" and pt.magicCirclePointLightRange > 0 then
			lightRange = pt.magicCirclePointLightRange
		end
	end
	return glowColor, partMaterial, lightBrightness, lightRange
end

local function styleMagicCircleGlow(root: Instance, glowColor: Color3, partMaterial: Enum.Material)
	VfxHelpers.setPartProperties(root, {
		CastShadow = false,
		Material = partMaterial,
		Color = glowColor,
	})
	-- Decals / Textures use Color3 (not BasePart.Color).
	VfxHelpers.setFaceProperties(root, {
		Color3 = glowColor,
	})
	for _, d in root:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			d.Color = ColorSequence.new(glowColor)
		elseif d:IsA("Beam") then
			d.Color = ColorSequence.new(glowColor)
		elseif d:IsA("Trail") then
			d.Color = ColorSequence.new(glowColor)
		end
	end
end

-- Rune-style assets: keep carrier BaseParts fully invisible so only Decals/Textures read as the circle.
local function lockMagicCirclePartCarriersInvisible(root: Instance)
	VfxHelpers.setPartProperties(root, { Transparency = 1 })
end

local function applyMagicCircleFaceAndFxTransparency(root: Instance, transparency: number)
	local t = math.clamp(transparency, 0, 1)
	VfxHelpers.setFaceProperties(root, { Transparency = t })
	local seq = NumberSequence.new(t)
	VfxHelpers.forEachTransparencySequence(root, function(obj: ParticleEmitter | Beam | Trail)
		(obj :: any).Transparency = seq
	end)
end

local function tryAddMagicCirclePointLight(root: Instance, glowColor: Color3, brightness: number, range: number): PointLight?
	local part: BasePart?
	if root:IsA("Model") then
		local m = root :: Model
		part = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
	elseif root:IsA("BasePart") then
		part = root :: BasePart
	end
	if not part then
		return nil
	end
	local light = Instance.new("PointLight")
	light.Name = "PrayerfulStrikeMagicCircleGlow"
	light.Color = glowColor
	light.Brightness = brightness
	light.Range = range
	light.Shadows = false
	light.Parent = part
	return light
end

-- ── NumberSequence / easing helpers ─────────────────────────────────────────

local function condenseTransparencyT(linearP: number): number
	local p = math.clamp(linearP, 0, 1)
	local k = SURGE_TRANSPARENCY_EASE_K
	local den = math.exp(k) - 1
	if den < 1e-9 then
		return p
	end
	return (math.exp(k * p) - 1) / den
end

local function quadIn(t: number): number
	return t * t
end

local function bumpNumberSequence(seq: NumberSequence, add: number): NumberSequence
	local kps = {}
	for _, kp in seq.Keypoints do
		table.insert(kps, NumberSequenceKeypoint.new(kp.Time, math.clamp(kp.Value + add, 0, 1)))
	end
	return NumberSequence.new(kps)
end

local function sampleNumberSequence(seq: NumberSequence, time: number): number
	local k = seq.Keypoints
	if #k == 0 then
		return 0
	end
	if time <= k[1].Time then
		return k[1].Value
	end
	if time >= k[#k].Time then
		return k[#k].Value
	end
	for i = 1, #k - 1 do
		local k0, k1 = k[i], k[i + 1]
		if k1.Time >= time then
			if k1.Time == k0.Time then
				return k0.Value
			end
			local alpha = (time - k0.Time) / (k1.Time - k0.Time)
			return k0.Value + (k1.Value - k0.Value) * alpha
		end
	end
	return k[#k].Value
end

local function lerpNumberSequence(a: NumberSequence, b: NumberSequence, alpha: number): NumberSequence
	local timesMap: { [number]: boolean } = {}
	for _, kp in a.Keypoints do
		timesMap[kp.Time] = true
	end
	for _, kp in b.Keypoints do
		timesMap[kp.Time] = true
	end
	local times: { number } = {}
	for tm in pairs(timesMap) do
		table.insert(times, tm)
	end
	table.sort(times)
	local kps = {}
	for _, tm in times do
		local v = sampleNumberSequence(a, tm) * (1 - alpha) + sampleNumberSequence(b, tm) * alpha
		table.insert(kps, NumberSequenceKeypoint.new(tm, math.clamp(v, 0, 1)))
	end
	return NumberSequence.new(kps)
end

local function opaqueNumberSequence(): NumberSequence
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
end

-- ── Instance helpers ────────────────────────────────────────────────────────

local function atts(root: Instance, name: string): { Attachment }
	local r: { Attachment } = {}
	for _, d in root:GetDescendants() do
		if d:IsA("Attachment") and d.Name == name then
			table.insert(r, d)
		end
	end
	return r
end

local function normalizeSurgeVfxRoot(clone: Instance): Instance
	if clone:IsA("Model") then
		return clone
	end
	if clone:IsA("BasePart") then
		local wrap = Instance.new("Model")
		local p = clone :: BasePart
		p.Parent = wrap
		wrap.PrimaryPart = p
		return wrap
	end
	if clone:IsA("Folder") then
		local inner = clone:FindFirstChildWhichIsA("Model", false)
		if not inner then
			inner = clone:FindFirstChildWhichIsA("Model", true)
		end
		if inner and inner:IsA("Model") then
			inner.Parent = nil
			clone:Destroy()
			return inner
		end
	end
	return clone
end

-- ── Surge binding lifecycle ─────────────────────────────────────────────────

local function killSurges(sess: PlaybackSession)
	for _, b in sess.surges do
		b.alive = false
		if b.conn then
			b.conn:Disconnect()
			b.conn = nil
		end
		local inst = b.inst
		task.defer(function()
			if inst.Parent then
				inst:Destroy()
			end
		end)
	end
	table.clear(sess.surges)
end

local function buildSurgeBinding(root: Instance, followConn: RBXScriptConnection?): SurgeB
	local useModelScale = false
	local modelRoot: Model? = nil
	local scale0 = 1.0
	if root:IsA("Model") then
		useModelScale = true
		modelRoot = root
		local sc = VfxHelpers.tryGetScale(root)
		if type(sc) == "number" and sc > 1e-6 then
			scale0 = sc
		else
			scale0 = 1.0
		end
	end

	local maxScale, minScale, _ = surgeTune()
	local parts: { PartSnap } = {}
	local faces: { FaceSnap } = {}
	local seqSnaps: { SeqSnap } = {}

	VfxHelpers.forEachPart(root, function(p: BasePart)
		local t0 = p.Transparency
		local tB = math.clamp(t0 + SURGE_BURST_TRANS_ADD, 0, 0.98)
		local sz0: Vector3? = if useModelScale then nil else p.Size
		local szB: Vector3? = if sz0 then sz0 * maxScale else nil
		local szE: Vector3? = if sz0 then sz0 * minScale else nil
		table.insert(parts, { p = p, trans0 = t0, transBurst = tB, size0 = sz0, sizeBurst = szB, sizeEnd = szE })
	end)

	VfxHelpers.forEachFace(root, function(face: any)
		local t0 = face.Transparency
		table.insert(faces, {
			face = face,
			trans0 = t0,
			transBurst = math.clamp(t0 + SURGE_BURST_TRANS_ADD, 0, 0.99),
		})
	end)

	VfxHelpers.forEachTransparencySequence(root, function(obj: any)
		local seq0 = obj.Transparency :: NumberSequence
		table.insert(seqSnaps, {
			obj = obj,
			trans0 = seq0,
			transBurst = bumpNumberSequence(seq0, SURGE_SEQUENCE_BURST_TRANS_ADD),
		})
	end)

	return {
		inst = root,
		conn = followConn,
		alive = true,
		useModelScale = useModelScale,
		modelRoot = modelRoot,
		scale0 = scale0,
		parts = parts,
		faces = faces,
		seqSnaps = seqSnaps,
	}
end

local function applySurgeBurst(b: SurgeB)
	local maxScale = select(1, surgeTune())
	if b.useModelScale and b.modelRoot and b.modelRoot.Parent then
		VfxHelpers.scaleTo(b.modelRoot, b.scale0 * maxScale)
	end
	for _, row in b.parts do
		row.p.Transparency = row.transBurst
		if row.sizeBurst then
			row.p.Size = row.sizeBurst
		end
	end
	for _, row in b.faces do
		local f = row.face
		if f:IsA("Decal") or f:IsA("Texture") then
			f.Transparency = row.transBurst
		end
	end
	for _, sq in b.seqSnaps do
		if sq.obj.Parent then
			(sq.obj :: any).Transparency = sq.transBurst
		end
	end
end

local function runSurgeCondense(b: SurgeB)
	task.spawn(function()
		local maxScale, minScale, duration = surgeTune()
		local scaleStart = b.scale0 * maxScale
		local scaleEnd = b.scale0 * minScale
		local t0 = os.clock()

		local function applyFrame(progress: number)
			local p = math.clamp(progress, 0, 1)
			local pt = condenseTransparencyT(p)
			if b.useModelScale and b.modelRoot and b.modelRoot.Parent then
				local sc = scaleStart + (scaleEnd - scaleStart) * p
				VfxHelpers.scaleTo(b.modelRoot, sc)
			end
			for _, row in b.parts do
				if row.p.Parent then
					row.p.Transparency = row.transBurst + (row.trans0 - row.transBurst) * pt
					if row.sizeBurst and row.sizeEnd then
						row.p.Size = row.sizeBurst:Lerp(row.sizeEnd, p)
					end
				end
			end
			for _, row in b.faces do
				local f = row.face
				if (f:IsA("Decal") or f:IsA("Texture")) and f.Parent then
					f.Transparency = row.transBurst + (row.trans0 - row.transBurst) * pt
				end
			end
			for _, sq in b.seqSnaps do
				if sq.obj.Parent then
					(sq.obj :: any).Transparency = lerpNumberSequence(sq.transBurst, sq.trans0, pt)
				end
			end
		end

		while b.alive and b.inst.Parent do
			local elapsed = os.clock() - t0
			if elapsed >= duration then
				applyFrame(1)
				break
			end
			local progress = math.min(1, elapsed / duration)
			applyFrame(progress)
			RunService.Heartbeat:Wait()
		end
	end)
end

local function dispelSurgeBinding(b: SurgeB)
	b.alive = false

	local scaleStart = b.scale0
	if b.useModelScale and b.modelRoot and b.modelRoot.Parent then
		local sc = VfxHelpers.tryGetScale(b.modelRoot)
		if type(sc) == "number" and sc > 1e-6 then
			scaleStart = sc
		end
	end
	local scaleEnd = scaleStart * SURGE_DISPEL_SIZE_MULT

	local seqOpaque = opaqueNumberSequence()
	local t0 = os.clock()

	task.spawn(function()
		while os.clock() - t0 < SURGE_DISPEL_SEC and b.inst.Parent do
			local u = math.clamp((os.clock() - t0) / SURGE_DISPEL_SEC, 0, 1)
			local e = quadIn(u)
			if b.useModelScale and b.modelRoot and b.modelRoot.Parent then
				local s = scaleStart + (scaleEnd - scaleStart) * e
				VfxHelpers.scaleTo(b.modelRoot, s)
			end
			for _, row in b.parts do
				if row.p.Parent then
					row.p.Transparency = row.trans0 + (1 - row.trans0) * e
					local szFrom = row.sizeEnd or row.size0
					if szFrom then
						row.p.Size = szFrom:Lerp(szFrom * SURGE_DISPEL_SIZE_MULT, e)
					elseif not b.useModelScale then
						row.p.Size = row.p.Size:Lerp(row.p.Size * SURGE_DISPEL_SIZE_MULT, e)
					end
				end
			end
			for _, row in b.faces do
				local f = row.face
				if (f:IsA("Decal") or f:IsA("Texture")) and f.Parent then
					f.Transparency = row.trans0 + (1 - row.trans0) * e
				end
			end
			for _, sq in b.seqSnaps do
				if sq.obj.Parent then
					(sq.obj :: any).Transparency = lerpNumberSequence(sq.trans0, seqOpaque, e)
				end
			end
			RunService.Heartbeat:Wait()
		end
		if b.conn then
			b.conn:Disconnect()
			b.conn = nil
		end
		task.delay(SURGE_CLEANUP_AFTER_DISPEL, function()
			if b.inst.Parent then
				b.inst:Destroy()
			end
		end)
	end)
end

local function dispelAllSurges(sess: PlaybackSession)
	local copy = table.clone(sess.surges)
	table.clear(sess.surges)
	for _, b in copy do
		dispelSurgeBinding(b)
	end
end

-- ── Surge spawn ─────────────────────────────────────────────────────────────

local function surgeAt(a: Attachment, sess: PlaybackSession)
	local t = EffectAssets.CloneVfx(assetNameId("VfxPrayerSurge"))
	if not t then
		return
	end
	local vfx: Instance = normalizeSurgeVfxRoot(t)
	vfx.Name = "PrayerSurgeVFX"
	VfxHelpers.setPartProperties(vfx, { CastShadow = false })

	local conn: RBXScriptConnection? = nil
	if vfx:IsA("BasePart") or vfx:IsA("Model") then
		(vfx :: Instance).Parent = a.Parent
		if vfx:IsA("Model") then
			local m = vfx :: Model
			local pp = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
			if pp and not m.PrimaryPart then
				m.PrimaryPart = pp
			end
		end
		conn = RunService.Heartbeat:Connect(function()
			if a.Parent and vfx.Parent then
				if vfx:IsA("Model") then
					local m = vfx :: Model
					if m.PrimaryPart then
						m:PivotTo(a.WorldCFrame)
					end
				elseif vfx:IsA("BasePart") then
					(vfx :: BasePart).CFrame = a.WorldCFrame
				end
			end
		end)
	else
		vfx.Parent = a
	end

	local b = buildSurgeBinding(vfx, conn)
	applySurgeBurst(b)
	runSurgeCondense(b)
	table.insert(sess.surges, b)
end

local function startSurges(character: Model)
	local prev = sessions[character]
	if prev then
		killSurges(prev)
	end
	local sess: PlaybackSession = { surges = {} }
	sessions[character] = sess

	task.spawn(function()
		local w: Instance? = nil
		for _ = 1, WEAPON_RETRY_ATTEMPTS do
			w = character:FindFirstChild(WEAPON_MODEL_NAME)
			if w then
				break
			end
			task.wait(WEAPON_RETRY_INTERVAL)
		end
		if not w then
			return
		end
		for _, a in atts(w, "SurgePoint") do
			surgeAt(a, sess)
		end
	end)
end

-- ── Powerup / Impact ────────────────────────────────────────────────────────

local function playPowerup(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	EffectAssets.PlaySound(assetNameId("SfxPowerup"), root)

	local feetAtt = root:FindFirstChild("MiddleFeetAttachment")
	if not feetAtt or not feetAtt:IsA("Attachment") then
		return
	end

	local raw = EffectAssets.CloneVfx(assetNameId("VfxMagicCircle"))
	if not raw then
		return
	end
	local circle = normalizeSurgeVfxRoot(raw)
	circle.Name = "PrayerfulStrikeMagicCircle"
	local glowColor, partMaterial, lightBrightness, lightRange = magicCircleVisualTune()
	styleMagicCircleGlow(circle, glowColor, partMaterial)
	lockMagicCirclePartCarriersInvisible(circle)
	local pointLight = tryAddMagicCirclePointLight(circle, glowColor, lightBrightness, lightRange)

	local offsetY, lifetimeSec = magicCircleTune()
	local scaleMin, scaleMax, fadeInSec, opaqueHoldSec = magicCircleAnimTune()
	local feetAttTyped = feetAtt :: Attachment

	if circle:IsA("Model") then
		local m = circle :: Model
		local p0 = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
		if p0 and not m.PrimaryPart then
			m.PrimaryPart = p0
		end
	end

	local fadeIn = math.clamp(fadeInSec, 0, lifetimeSec)
	local hold = math.clamp(opaqueHoldSec, 0, math.max(0, lifetimeSec - fadeIn))
	local fadeOutDur = math.max(1e-3, lifetimeSec - fadeIn - hold)

	local function pivotMagicCircle()
		local cf = feetAttTyped.WorldCFrame * CFrame.new(0, offsetY, 0)
		if circle:IsA("Model") then
			local m = circle :: Model
			if m.PrimaryPart then
				m:PivotTo(cf)
			end
		elseif circle:IsA("BasePart") then
			(circle :: BasePart).CFrame = cf
		end
	end

	-- Start invisible and at min scale; animate over exactly magicCircleLifetimeSeconds.
	applyMagicCircleFaceAndFxTransparency(circle, 1)
	if circle:IsA("Model") then
		VfxHelpers.scaleTo(circle, scaleMin)
	end
	if pointLight then
		pointLight.Brightness = 0
	end

	circle.Parent = root
	pivotMagicCircle()

	if not (circle:IsA("Model") or circle:IsA("BasePart")) then
		return
	end

	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		if not circle.Parent or not feetAttTyped.Parent then
			conn:Disconnect()
			return
		end

		local elapsed = os.clock() - t0
		if elapsed >= lifetimeSec then
			conn:Disconnect()
			circle:Destroy()
			return
		end

		pivotMagicCircle()

		local partTransparency: number
		if fadeIn <= 1e-6 then
			partTransparency = if elapsed < hold then 0 else (elapsed - hold) / fadeOutDur
		elseif elapsed < fadeIn then
			partTransparency = 1 - (elapsed / fadeIn)
		elseif elapsed < fadeIn + hold then
			partTransparency = 0
		else
			partTransparency = (elapsed - fadeIn - hold) / fadeOutDur
		end
		partTransparency = math.clamp(partTransparency, 0, 1)
		applyMagicCircleFaceAndFxTransparency(circle, partTransparency)

		if pointLight then
			pointLight.Brightness = lightBrightness * (1 - partTransparency)
		end

		local u = elapsed / lifetimeSec
		local sc = scaleMin + (scaleMax - scaleMin) * u
		if circle:IsA("Model") then
			VfxHelpers.scaleTo(circle, sc)
		end
	end)
end

local function playImpactVfxAtAttachment(a: Attachment, parentPart: BasePart, assetConfigKey: string, instanceName: string, debrisSeconds: number)
	local im = EffectAssets.CloneVfx(assetNameId(assetConfigKey))
	if not im then
		return
	end
	im.Name = instanceName
	VfxHelpers.setPartProperties(im, { CastShadow = false })
	im.Parent = parentPart
	if im:IsA("Model") then
		local m = im :: Model
		local p0 = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
		if p0 and not m.PrimaryPart then
			m.PrimaryPart = p0
		end
		if m.PrimaryPart then
			m:PivotTo(a.WorldCFrame)
		end
	elseif im:IsA("BasePart") then
		(im :: BasePart).CFrame = a.WorldCFrame
	end
	Debris:AddItem(im, debrisSeconds)
end

local function playImpact(character: Model)
	local sess = sessions[character]
	local didSfx = false
	local w = character:FindFirstChild(WEAPON_MODEL_NAME)
	if w then
		for _, a in atts(w, "ImpactPoint") do
			local pp = a.Parent
			if pp and pp:IsA("BasePart") then
				playImpactVfxAtAttachment(a, pp, "VfxMediumImpact", "PrayerfulStrikeMediumImpact", 0.40)
				EffectAssets.PlaySound(assetNameId("SfxImpact"), pp)
				didSfx = true
			end
		end
	end
	if not didSfx then
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			EffectAssets.PlaySound(assetNameId("SfxImpact"), root)
		end
	end
	if sess then
		dispelAllSurges(sess)
	end
end

-- ── Animation helpers (LocalPlayer only) ────────────────────────────────────

local function animId(): string
	local c = AbilityRegistry.GetAbility(ABILITY_ID)
	local t = c and c.assets
	local s = t and t["Animation"]
	return if type(s) == "string" then s else "rbxassetid://0"
end

local function connectMarker(track: AnimationTrack, name: string, fire: () -> ())
	return track:GetMarkerReachedSignal(name):Connect(function()
		task.defer(fire)
	end)
end

-- ── Exported API ────────────────────────────────────────────────────────────

local PrayerfulStrike = {}

function PrayerfulStrike.OnStarted(context: AbilityClientContext)
	local character = context.character
	if not character then
		return
	end

	startSurges(character)

	if context.player ~= Players.LocalPlayer then
		return
	end

	local animator = context.animator
	if not animator then
		return
	end

	local cfg = AbilityRegistry.GetAbility(ABILITY_ID)
	local dur = 220 / 60
	if cfg and cfg.params and type((cfg.params :: any).totalDurationSeconds) == "number" then
		dur = (cfg.params :: any).totalDurationSeconds
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = animId()
	local ok, tr = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	anim:Destroy()
	local track = if ok and typeof(tr) == "Instance" and (tr :: Instance):IsA("AnimationTrack") then (tr :: AnimationTrack) else nil
	if not track then
		return
	end

	MovementControlLocks.Lock(LOCK_TAG, { "All" }, dur)
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = false

	local remote = ReplicatedStorage:WaitForChild("InventoryRemotes"):WaitForChild("AbilityAnimationMarker") :: RemoteEvent
	local conns: { RBXScriptConnection } = {}

	local function off()
		for _, c in conns do
			c:Disconnect()
		end
		table.clear(conns)
	end

	local markPowerup, markImpact = cfgMarkers()
	table.insert(conns, connectMarker(track, markPowerup, function()
		remote:FireServer(ABILITY_ID, markPowerup)
	end))
	table.insert(conns, connectMarker(track, markImpact, function()
		remote:FireServer(ABILITY_ID, markImpact)
	end))
	table.insert(
		conns,
		track.Stopped:Connect(off)
	)

	track:Play(0.05, 1, 1)
end

function PrayerfulStrike.OnRelay(casterCharacter: Model, eventName: string, _payload: any?)
	local markPowerup, markImpact = cfgMarkers()
	if eventName == markPowerup then
		playPowerup(casterCharacter)
	elseif eventName == markImpact then
		playImpact(casterCharacter)
	end
end

return PrayerfulStrike
