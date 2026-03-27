--!strict

local RunService = game:GetService("RunService")

local req = require :: any
local s = script.Parent :: any
local ActiveMovementModule = req(s.ActiveMovement)
local LocomotionSuppress = req(s.LocomotionSuppress)
local Types = req(s.Types)
type ActiveMovement = ActiveMovementModule.ActiveMovement

export type Mover = {
	destroy: (self: Mover) -> (),
	cancelAll: (self: Mover) -> (),
	translate: (self: Mover, params: Types.TranslateParams) -> ActiveMovement,
	dash: (self: Mover, params: Types.DashParams) -> ActiveMovement,
	knockback: (self: Mover, params: Types.KnockbackParams) -> ActiveMovement,
	pull: (self: Mover, params: Types.PullParams) -> ActiveMovement,
	launch: (self: Mover, params: Types.LaunchParams) -> ActiveMovement,
	slam: (self: Mover, params: Types.SlamParams) -> ActiveMovement,
	float: (self: Mover, params: Types.FloatParams) -> ActiveMovement,
	slide: (self: Mover, params: Types.SlideParams) -> ActiveMovement,
	lunge: (self: Mover, params: Types.LungeParams) -> ActiveMovement,
	teleport: (self: Mover, params: Types.TeleportParams) -> ActiveMovement,
	orbit: (self: Mover, params: Types.OrbitParams) -> ActiveMovement,
	springTo: (self: Mover, params: Types.SpringToParams) -> ActiveMovement,
	getRoot: (self: Mover) -> BasePart,
	getCharacter: (self: Mover) -> Model,
	getCachedMass: (self: Mover) -> number,
	acquireLinearVelocity: (self: Mover, owner: ActiveMovement, vectorVelocity: Vector3, maxForce: number) -> (),
	releaseLinearVelocity: (self: Mover, owner: ActiveMovement) -> (),
	acquireVectorForce: (self: Mover, owner: ActiveMovement, force: Vector3) -> (),
	releaseVectorForce: (self: Mover, owner: ActiveMovement) -> (),
	acquireAlignPosition: (
		self: Mover,
		owner: ActiveMovement,
		targetWorldPosition: Vector3,
		maxForce: number,
		maxVelocity: number,
		responsiveness: number,
		applyAtCenterOfMass: boolean
	) -> (),
	releaseAlignPosition: (self: Mover, owner: ActiveMovement) -> (),
	registerFrameUpdate: (self: Mover, owner: ActiveMovement, fn: (dt: number) -> ()) -> (),
	unregisterFrameUpdate: (self: Mover, owner: ActiveMovement) -> (),
	trackActive: (self: Mover, token: ActiveMovement) -> (),
	untrackActive: (self: Mover, token: ActiveMovement) -> (),
}

type MovementBinders = {
	translate: (Mover, Types.TranslateParams) -> ActiveMovement,
	dash: (Mover, Types.DashParams) -> ActiveMovement,
	knockback: (Mover, Types.KnockbackParams) -> ActiveMovement,
	pull: (Mover, Types.PullParams) -> ActiveMovement,
	launch: (Mover, Types.LaunchParams) -> ActiveMovement,
	slam: (Mover, Types.SlamParams) -> ActiveMovement,
	float: (Mover, Types.FloatParams) -> ActiveMovement,
	slide: (Mover, Types.SlideParams) -> ActiveMovement,
	lunge: (Mover, Types.LungeParams) -> ActiveMovement,
	teleport: (Mover, Types.TeleportParams) -> ActiveMovement,
	orbit: (Mover, Types.OrbitParams) -> ActiveMovement,
	springTo: (Mover, Types.SpringToParams) -> ActiveMovement,
}

type FrameRow = {
	owner: ActiveMovement,
	fn: (dt: number) -> (),
}

type MoverState = {
	_character: Model,
	_root: BasePart,
	_mass: number,
	_attachment: Attachment,
	_linearVelocity: LinearVelocity,
	_linearOwner: ActiveMovement?,
	_vectorForce: VectorForce,
	_vfOwner: ActiveMovement?,
	_alignPosition: AlignPosition,
	_apOwner: ActiveMovement?,
	_frameRows: { FrameRow },
	_heartbeat: RBXScriptConnection?,
	_tracked: { ActiveMovement },
	_destroyed: boolean,
	_suppressDefaultLocomotion: boolean,
	_locomotionRestore: (() -> ())?,
}

local DEFAULT_ACCEL_MULT = 1000

local MT = {}

local function stealLinear(self: MoverState, owner: ActiveMovement)
	if self._linearOwner and self._linearOwner ~= owner then
		self._linearOwner:Cancel()
	end
end

local function stealVF(self: MoverState, owner: ActiveMovement)
	if self._vfOwner and self._vfOwner ~= owner then
		self._vfOwner:Cancel()
	end
end

local function stealAP(self: MoverState, owner: ActiveMovement)
	if self._apOwner and self._apOwner ~= owner then
		self._apOwner:Cancel()
	end
end

function MT.getRoot(self: MoverState): BasePart
	return self._root
end

function MT.getCharacter(self: MoverState): Model
	return self._character
end

function MT.getCachedMass(self: MoverState): number
	self._mass = self._root.AssemblyMass
	return self._mass
end

function MT.acquireLinearVelocity(self: MoverState, owner: ActiveMovement, vectorVelocity: Vector3, maxForce: number)
	stealLinear(self, owner)
	self._linearOwner = owner
	local lv = self._linearVelocity
	lv.VectorVelocity = vectorVelocity
	lv.MaxForce = maxForce
	lv.Enabled = true
end

function MT.releaseLinearVelocity(self: MoverState, owner: ActiveMovement)
	if self._linearOwner ~= owner then
		return
	end
	local lv = self._linearVelocity
	lv.Enabled = false
	lv.VectorVelocity = Vector3.zero
	self._linearOwner = nil
end

function MT.acquireVectorForce(self: MoverState, owner: ActiveMovement, force: Vector3)
	stealVF(self, owner)
	self._vfOwner = owner
	local vf = self._vectorForce
	vf.Force = force
	vf.Enabled = true
end

function MT.releaseVectorForce(self: MoverState, owner: ActiveMovement)
	if self._vfOwner ~= owner then
		return
	end
	local vf = self._vectorForce
	vf.Enabled = false
	vf.Force = Vector3.zero
	self._vfOwner = nil
end

function MT.acquireAlignPosition(
	self: MoverState,
	owner: ActiveMovement,
	targetWorldPosition: Vector3,
	maxForce: number,
	maxVelocity: number,
	responsiveness: number,
	applyAtCenterOfMass: boolean
)
	stealAP(self, owner)
	self._apOwner = owner
	local ap = self._alignPosition
	ap.Position = targetWorldPosition
	ap.MaxForce = maxForce
	ap.MaxVelocity = maxVelocity
	ap.Responsiveness = responsiveness
	ap.ApplyAtCenterOfMass = applyAtCenterOfMass
	ap.Enabled = true
end

function MT.releaseAlignPosition(self: MoverState, owner: ActiveMovement)
	if self._apOwner ~= owner then
		return
	end
	local ap = self._alignPosition
	ap.Enabled = false
	self._apOwner = nil
end

function MT.registerFrameUpdate(self: MoverState, owner: ActiveMovement, fn: (dt: number) -> ())
	self:unregisterFrameUpdate(owner)
	table.insert(self._frameRows, { owner = owner, fn = fn })
	self:_ensureHeartbeat()
end

function MT.unregisterFrameUpdate(self: MoverState, owner: ActiveMovement)
	for i = #self._frameRows, 1, -1 do
		if self._frameRows[i].owner == owner then
			table.remove(self._frameRows, i)
		end
	end
	self:_stopHeartbeatIfIdle()
end

function MT._ensureHeartbeat(self: MoverState)
	if self._heartbeat or self._destroyed then
		return
	end
	self._heartbeat = RunService.Heartbeat:Connect(function(dt: number)
		if self._destroyed then
			return
		end
		local snapshot = table.clone(self._frameRows)
		for _, row in snapshot do
			if row.owner:IsActive() then
				row.fn(dt)
			end
		end
	end)
end

function MT._stopHeartbeatIfIdle(self: MoverState)
	if #self._frameRows > 0 then
		return
	end
	if self._heartbeat then
		self._heartbeat:Disconnect()
		self._heartbeat = nil
	end
end

function MT.trackActive(self: MoverState, token: ActiveMovement)
	table.insert(self._tracked, token)
	if self._suppressDefaultLocomotion and #self._tracked == 1 and self._locomotionRestore == nil then
		local hum = self._character:FindFirstChildOfClass("Humanoid")
		if hum then
			self._locomotionRestore = LocomotionSuppress.begin(hum)
		end
	end
end

function MT.untrackActive(self: MoverState, token: ActiveMovement)
	for i = #self._tracked, 1, -1 do
		if self._tracked[i] == token then
			table.remove(self._tracked, i)
		end
	end
	if self._suppressDefaultLocomotion and #self._tracked == 0 then
		local restore = self._locomotionRestore
		if restore then
			self._locomotionRestore = nil
			restore()
		end
	end
end

function MT.cancelAll(self: MoverState)
	local snap = table.clone(self._tracked)
	for _, t in snap do
		if t:IsActive() then
			t:Cancel()
		end
	end
end

function MT.destroy(self: MoverState)
	if self._destroyed then
		return
	end
	self._destroyed = true
	self:cancelAll()
	local restore = self._locomotionRestore
	if restore then
		self._locomotionRestore = nil
		restore()
	end
	if self._heartbeat then
		self._heartbeat:Disconnect()
		self._heartbeat = nil
	end
	table.clear(self._frameRows)
	self._linearVelocity:Destroy()
	self._vectorForce:Destroy()
	self._alignPosition:Destroy()
	self._attachment:Destroy()
end

local function createMover(character: Model, movementBinders: MovementBinders, options: Types.CreateMoverOptions?): Mover
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		error('[RootMotion] Model must contain a BasePart named "HumanoidRootPart"')
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "RootMotion_Attachment"
	attachment.Parent = root

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "RootMotion_LinearVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	linearVelocity.VectorVelocity = Vector3.zero
	linearVelocity.MaxForce = 0
	linearVelocity.Enabled = false
	linearVelocity.Parent = root

	local vectorForce = Instance.new("VectorForce")
	vectorForce.Name = "RootMotion_VectorForce"
	vectorForce.Attachment0 = attachment
	vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	vectorForce.ApplyAtCenterOfMass = true
	vectorForce.Force = Vector3.zero
	vectorForce.Enabled = false
	vectorForce.Parent = root

	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Name = "RootMotion_AlignPosition"
	alignPosition.Attachment0 = attachment
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.Position = root.Position
	alignPosition.MaxForce = 0
	alignPosition.MaxVelocity = 0
	alignPosition.Responsiveness = 10
	alignPosition.ApplyAtCenterOfMass = false
	alignPosition.Enabled = false
	alignPosition.Parent = root

	local suppressLocomotion = if options and options.suppressDefaultLocomotion == false then false else true

	local self: MoverState = {
		_character = character,
		_root = root,
		_mass = root.AssemblyMass,
		_attachment = attachment,
		_linearVelocity = linearVelocity,
		_linearOwner = nil,
		_vectorForce = vectorForce,
		_vfOwner = nil,
		_alignPosition = alignPosition,
		_apOwner = nil,
		_frameRows = {},
		_heartbeat = nil,
		_tracked = {},
		_destroyed = false,
		_suppressDefaultLocomotion = suppressLocomotion,
		_locomotionRestore = nil,
	}

	setmetatable(self, { __index = MT })

	local mover = self :: Mover
	-- Methods are stored on the state table; it is widened only for these assignments.
	local withMovements = self :: any
	withMovements.translate = function(_: Mover, params: Types.TranslateParams): ActiveMovement
		return movementBinders.translate(mover, params)
	end
	withMovements.dash = function(_: Mover, params: Types.DashParams): ActiveMovement
		return movementBinders.dash(mover, params)
	end
	withMovements.knockback = function(_: Mover, params: Types.KnockbackParams): ActiveMovement
		return movementBinders.knockback(mover, params)
	end
	withMovements.pull = function(_: Mover, params: Types.PullParams): ActiveMovement
		return movementBinders.pull(mover, params)
	end
	withMovements.launch = function(_: Mover, params: Types.LaunchParams): ActiveMovement
		return movementBinders.launch(mover, params)
	end
	withMovements.slam = function(_: Mover, params: Types.SlamParams): ActiveMovement
		return movementBinders.slam(mover, params)
	end
	withMovements.float = function(_: Mover, params: Types.FloatParams): ActiveMovement
		return movementBinders.float(mover, params)
	end
	withMovements.slide = function(_: Mover, params: Types.SlideParams): ActiveMovement
		return movementBinders.slide(mover, params)
	end
	withMovements.lunge = function(_: Mover, params: Types.LungeParams): ActiveMovement
		return movementBinders.lunge(mover, params)
	end
	withMovements.teleport = function(_: Mover, params: Types.TeleportParams): ActiveMovement
		return movementBinders.teleport(mover, params)
	end
	withMovements.orbit = function(_: Mover, params: Types.OrbitParams): ActiveMovement
		return movementBinders.orbit(mover, params)
	end
	withMovements.springTo = function(_: Mover, params: Types.SpringToParams): ActiveMovement
		return movementBinders.springTo(mover, params)
	end

	return self :: Mover
end

return {
	create = createMover,
	DEFAULT_ACCEL_MULT = DEFAULT_ACCEL_MULT,
}
