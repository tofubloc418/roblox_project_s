--!strict
-- VFX helpers: descendant walks, mass property setters, Model GetScale/ScaleTo.

export type Face = Decal | Texture
export type TransparencySequenceObject = ParticleEmitter | Beam | Trail

type Props = { [string]: any }

local VfxHelpers = {}

local function applyProps(inst: any, props: Props)
	for key, value in props do
		inst[key] = value
	end
end

function VfxHelpers.each(root: Instance, visit: (Instance) -> ())
	visit(root)
	for _, child in root:GetDescendants() do
		visit(child)
	end
end

function VfxHelpers.forEachPart(root: Instance, visit: (BasePart) -> ())
	VfxHelpers.each(root, function(inst)
		if inst:IsA("BasePart") then
			visit(inst)
		end
	end)
end

function VfxHelpers.forEachFace(root: Instance, visit: (Face) -> ())
	VfxHelpers.each(root, function(inst)
		if inst:IsA("Decal") or inst:IsA("Texture") then
			visit(inst)
		end
	end)
end

function VfxHelpers.forEachTransparencySequence(root: Instance, visit: (TransparencySequenceObject) -> ())
	VfxHelpers.each(root, function(inst)
		if inst:IsA("ParticleEmitter") or inst:IsA("Beam") or inst:IsA("Trail") then
			visit(inst)
		end
	end)
end

function VfxHelpers.setPartProperties(root: Instance, props: Props)
	VfxHelpers.forEachPart(root, function(part)
		applyProps(part, props)
	end)
end

function VfxHelpers.setFaceProperties(root: Instance, props: Props)
	VfxHelpers.forEachFace(root, function(face)
		applyProps(face, props)
	end)
end

function VfxHelpers.setTransparencySequence(root: Instance, transparency: NumberSequence)
	VfxHelpers.forEachTransparencySequence(root, function(obj)
		(obj :: any).Transparency = transparency
	end)
end

function VfxHelpers.tryGetScale(root: Instance): number?
	if not root:IsA("Model") then
		return nil
	end
	local ok, scale = pcall(function()
		return root:GetScale()
	end)
	if ok and type(scale) == "number" then
		return scale
	end
	return nil
end

function VfxHelpers.scaleTo(root: Instance, scale: number): boolean
	if not root:IsA("Model") then
		return false
	end
	return pcall(function()
		root:ScaleTo(scale)
	end)
end

return VfxHelpers
