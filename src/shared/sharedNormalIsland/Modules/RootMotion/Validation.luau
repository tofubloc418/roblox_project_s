--!strict

local Workspace = game:GetService("Workspace")

local Types = require(script.Parent.Types)
type ShapecastPathParams = Types.ShapecastPathParams

export type PathResult = {
	safeCFrame: CFrame,
	hitSomething: boolean,
	raycastResult: RaycastResult?,
}

local Validation = {}

local function rayParamsFrom(pathParams: ShapecastPathParams?, rootModel: Model): RaycastParams
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = if pathParams and pathParams.exclude then pathParams.exclude else { rootModel }
	p.FilterDescendantsInstances = exclude
	if pathParams and pathParams.collisionGroup ~= nil and pathParams.collisionGroup ~= "" then
		p.CollisionGroup = pathParams.collisionGroup :: string
	end
	return p
end

--[[
	Casts an oriented block from originCFrame along displacement (world).
	Returns a CFrame translated along the path up to the first obstruction.
]]
function Validation.shapecastPath(
	originCFrame: CFrame,
	displacement: Vector3,
	rootSize: Vector3,
	pathParams: ShapecastPathParams?,
	rootModel: Model
): PathResult
	local dist = displacement.Magnitude
	if dist < 1e-5 then
		return {
			safeCFrame = originCFrame,
			hitSomething = false,
			raycastResult = nil,
		}
	end

	local dir = displacement.Unit
	local params = rayParamsFrom(pathParams, rootModel)
	local castLength = dist

	local result = Workspace:Blockcast(originCFrame, rootSize, dir * castLength, params)
	if not result then
		return {
			safeCFrame = originCFrame + displacement,
			hitSomething = false,
			raycastResult = nil,
		}
	end

	local skin = 0.08
	local safe = math.max(0, result.Distance - skin)
	local safePos = originCFrame.Position + dir * safe
	local rotOnly = originCFrame - originCFrame.Position
	return {
		safeCFrame = CFrame.new(safePos) * rotOnly,
		hitSomething = true,
		raycastResult = result,
	}
end

return Validation
