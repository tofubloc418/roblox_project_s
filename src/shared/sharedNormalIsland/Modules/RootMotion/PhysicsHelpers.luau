--!strict

local Workspace = game:GetService("Workspace")

export type GroundHit = {
	instance: Instance?,
	position: Vector3?,
	normal: Vector3?,
}

local function getAssemblyMass(rootPart: BasePart): number
	return rootPart.AssemblyMass
end

local function getGravityMagnitude(): number
	return Workspace.Gravity
end

local function getGravityForceVector(rootPart: BasePart): Vector3
	local g = getGravityMagnitude()
	return Vector3.new(0, -getAssemblyMass(rootPart) * g, 0)
end

local function getCounterGravityForceVector(rootPart: BasePart): Vector3
	return -getGravityForceVector(rootPart)
end

local function isGrounded(rootPart: BasePart, rayLength: number?, raycastParams: RaycastParams?): (boolean, GroundHit)
	local len = rayLength or 3.5
	local origin = rootPart.Position
	local direction = Vector3.new(0, -len, 0)
	local p: RaycastParams
	if raycastParams then
		p = raycastParams
	else
		p = RaycastParams.new()
		p.FilterType = Enum.RaycastFilterType.Exclude
		local parent = rootPart.Parent
		if parent then
			p.FilterDescendantsInstances = { parent }
		end
	end
	local result = Workspace:Raycast(origin, direction, p)

	if result then
		return true, {
			instance = result.Instance,
			position = result.Position,
			normal = result.Normal,
		}
	end
	return false, {}
end

local function getGroundNormal(rootPart: BasePart, rayLength: number?, raycastParams: RaycastParams?): Vector3?
	local ok, hit = isGrounded(rootPart, rayLength, raycastParams)
	if ok and hit.normal then
		return hit.normal
	end
	return nil
end

return {
	getAssemblyMass = getAssemblyMass,
	getGravityMagnitude = getGravityMagnitude,
	getGravityForceVector = getGravityForceVector,
	getCounterGravityForceVector = getCounterGravityForceVector,
	isGrounded = isGrounded,
	getGroundNormal = getGroundNormal,
}
