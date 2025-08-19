-- FastCastRedux (lite)
-- Minimal projectile raycasting with continuous stepping and RayHit signal

local RunService = game:GetService("RunService")

-- Simple Signal implementation
local function createSignal()
    local connections = {}
    return {
        Connect = function(self, fn)
            connections[fn] = true
            return { Disconnect = function() connections[fn] = nil end }
        end,
        Fire = function(self, ...)
            for fn in pairs(connections) do
                fn(...)
            end
        end,
    }
end

local FastCast = {}
FastCast.__index = FastCast

export type FastCastBehavior = {
    RaycastParams: RaycastParams?,
    Acceleration: Vector3,
    MaxDistance: number,
    HighFidelitySegmentSize: number?,
}

type ActiveCast = {
    UserData: any,
    _pos: Vector3,
    _vel: Vector3,
    _dir: Vector3,
    _traveled: number,
    _beh: FastCastBehavior,
}

local defaultBehavior: FastCastBehavior = {
    RaycastParams = nil,
    Acceleration = Vector3.new(0, 0, 0),
    MaxDistance = 1000,
    HighFidelitySegmentSize = 0.5,
}

function FastCast.new()
    local self = setmetatable({}, FastCast)
    self.RayHit = createSignal()
    self.CastTerminating = createSignal()
    self.WorldRoot = workspace
    self._activeCasts = {} :: {ActiveCast}

    if not self._heartbeatConn then
        self._heartbeatConn = RunService.Heartbeat:Connect(function(dt)
            self:_step(dt)
        end)
    end
    return self
end

function FastCast.newBehavior(): FastCastBehavior
    return table.clone(defaultBehavior)
end

function FastCast:_step(dt: number)
    local world = self.WorldRoot
    local i = 1
    while i <= #self._activeCasts do
        local cast = self._activeCasts[i]
        local beh = cast._beh

        -- integrate velocity with constant acceleration
        local accel = beh.Acceleration or Vector3.zero
        local stepVel = cast._vel + accel * dt
        local step = (cast._vel * dt) + (accel * 0.5 * dt * dt)

        local targetPos = cast._pos + step
        local dir = targetPos - cast._pos
        local dist = dir.Magnitude
        if dist > 0 then
            local result = world:Raycast(cast._pos, dir, beh.RaycastParams)
            if result then
                -- Ray hit
                self.RayHit:Fire(cast, result, stepVel, result.Position)
                table.remove(self._activeCasts, i)
                continue
            end
            cast._pos = targetPos
            cast._vel = stepVel
            cast._traveled += dist
            if cast._traveled >= (beh.MaxDistance or 1000) then
                self.CastTerminating:Fire(cast)
                table.remove(self._activeCasts, i)
                continue
            end
        end
        i += 1
    end
end

function FastCast:Fire(origin: Vector3, direction: Vector3, velocity: Vector3 | number, behavior: FastCastBehavior?)
    local beh = behavior or defaultBehavior
    local velVec = typeof(velocity) == "number" and (direction.Unit * (velocity :: number)) or (velocity :: Vector3)
    local cast: ActiveCast = {
        UserData = nil,
        _pos = origin,
        _vel = velVec,
        _dir = direction.Unit,
        _traveled = 0,
        _beh = beh,
    }
    table.insert(self._activeCasts, cast)
    return cast
end

return FastCast


