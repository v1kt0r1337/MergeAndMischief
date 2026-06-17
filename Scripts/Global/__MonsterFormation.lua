-- Shared monster formation helpers and routed movement controllers.

MonsterFormation = MonsterFormation or {}

local movementControllers = {}
local GetFormationPositions
local GetFormationLayoutOffset
local GetDeterministicLooseOffset
local GetCompositionOverrideMonsterId
local CompositionOverrideMatchesPositionRange
local CompositionOverrideMatchesSpatialPosition
local IsMonsterAlive
local GetMovementState
local GetControllerFormationPositions
local GetMonster
local RestartMonsterAtFormationStart
local GetRouteTarget
local ResetProgress
local HoldMonster
local GetDynamicClearance
local GetDynamicRouteClearance
local FindLateralWaypoint
local GetDynamicBlockers
local UpdateProgress
local ShouldRelease
local ReleaseMonster
local PinMonster
local AdvanceOnceRoute
local AdvanceSynchronizedRoutes
local UpdateMovingMonsters
local UpdateAnchoredMonsters

-- ============================================================================
--  MonsterFormation helpers
--
--  A formation definition has a SummonPos, a nested Formation description, and
--  optionally a Route. Without a Route, monsters summon directly into formation.
--  Movement controllers guide routed monsters through authored waypoint anchors.
-- ============================================================================

-- Summons monsters directly into formation around `options.SummonPos`.
-- `options.Formation` requires XAxisCount and YAxisCount. Axis spacing defaults
-- to 100. Layout defaults to "OrderedColumns"; other layouts are
-- "StaggeredColumns" and "LooseColumns".
-- `Formation.MonsterComposition` selects monster IDs for formation slots.
-- `options.Configure` optionally receives
-- (monster, mapMonsterIndex, position, xAxisIndex, yAxisIndex).
-- Returns the summoned monsters followed by their `Map.Monsters` indexes.
function MonsterFormation.Summon(options)
    assert(type(options) == "table" and type(options.SummonPos) == "table",
        "Monster formation summon requires SummonPos.")
    assert(type(options.Formation) == "table", "Monster formation summon requires Formation.")
    local formation = options.Formation
    assert(type(formation.MonsterComposition) == "table",
        "Monster formation summon requires Formation.MonsterComposition.")

    local monsters = {}
    local mapMonIndexes = {}
    for formationSlot, formationPosition in ipairs(GetFormationPositions(options.SummonPos, formation, 100)) do
        local position = formationSlot - 1
        local monsterId = MonsterFormation.SelectMonsterIdFromComposition(
            formation.MonsterComposition, position, formationPosition.XAxisIndex, formationPosition.YAxisIndex,
            options)
        local mon, monIndex = SummonMonster(
            monsterId, formationPosition.X, formationPosition.Y, formationPosition.Z, true)

        if options.Configure then
            options.Configure(
                mon, monIndex, position, formationPosition.XAxisIndex, formationPosition.YAxisIndex)
        end
        table.insert(monsters, mon)
        table.insert(mapMonIndexes, monIndex)
    end
    return monsters, mapMonIndexes
end

function MonsterFormation.SummonMany(definitions, configure)
    assert(type(definitions) == "table", "Monster formation SummonMany requires formation definitions.")

    local monsters = {}
    local mapMonIndexes = {}
    for _, definition in ipairs(definitions) do
        local formationMonsters, formationIndexes = MonsterFormation.Summon {
            SummonPos = definition.SummonPos,
            Formation = definition.Formation,
            Configure = configure,
        }
        for _, mon in ipairs(formationMonsters) do
            table.insert(monsters, mon)
        end
        for _, index in ipairs(formationIndexes) do
            table.insert(mapMonIndexes, index)
        end
    end
    return monsters, mapMonIndexes
end

-- Selects a monster ID from the first matching composition override, falling
-- back to DefaultMonsterId. Override forms may be mixed in one ordered list:
-- ordered modulus, inclusive position range, authored spatial position, or callback.
-- All position and spatial axis indexes are zero-based.
function MonsterFormation.SelectMonsterIdFromComposition(composition, position, xAxisIndex, yAxisIndex, context)
    assert(type(composition) == "table", "Monster composition must be a table.")

    for _, override in ipairs(composition.Overrides or {}) do
        if type(override) == "function" then
            local monsterId = override(position, xAxisIndex, yAxisIndex, context)
            if monsterId ~= nil then
                return monsterId
            end
        elseif type(override) == "table" then
            if type(override.Callback) == "function" then
                local monsterId = override.Callback(position, xAxisIndex, yAxisIndex, context, override)
                if monsterId ~= nil then
                    return monsterId
                end
            elseif override.Every ~= nil then
                assert(type(override.Every) == "number" and override.Every > 0,
                    "Monster composition modulus override Every must be a positive number.")
                local offset = override.Offset or 0
                if (position - offset) % override.Every == 0 then
                    local monsterId = GetCompositionOverrideMonsterId(
                        override, position, xAxisIndex, yAxisIndex, context)
                    if monsterId ~= nil then
                        return monsterId
                    end
                end
            elseif override.FromIndex ~= nil or override.ToIndex ~= nil then
                if CompositionOverrideMatchesPositionRange(override, position) then
                    local monsterId = GetCompositionOverrideMonsterId(
                        override, position, xAxisIndex, yAxisIndex, context)
                    if monsterId ~= nil then
                        return monsterId
                    end
                end
            elseif CompositionOverrideMatchesSpatialPosition(override, position, xAxisIndex, yAxisIndex) then
                local monsterId = GetCompositionOverrideMonsterId(
                    override, position, xAxisIndex, yAxisIndex, context)
                if monsterId ~= nil then
                    return monsterId
                end
            end
        end
    end

    return composition.DefaultMonsterId
end

-- Creates and registers a routed movement controller.
-- `options.Formations` contains formation definitions with SummonPos, Formation,
-- and Route. Route.Traversal is "Once", "PingPong", or "Loop".
-- PingPong and Loop routes synchronize all living members at each waypoint,
-- then wait for Route.WaypointWaitDuration before departing together. If some
-- members cannot arrive, the route advances after a capped per-member grace.
-- Returns a controller with Reset, Suspend, RestartAssignedMonsters,
-- AddMonster, GetFormationPosition, ReleaseMonster, Update, and Print methods.
function MonsterFormation.CreateMovementController(options)
    assert(type(options) == "table" and type(options.Name) == "string",
        "Monster formation controller requires Name.")
    assert(type(options.Formations) == "table", "Monster formation controller requires Formations.")
    options.Spacing = options.Spacing or 100
    options.WaypointRadius = options.WaypointRadius or 160
    options.ArrivalRadius = options.ArrivalRadius or 50
    options.WaypointPassProgress = options.WaypointPassProgress or 0.75
    options.ProgressDistance = options.ProgressDistance or 24
    options.StuckDuration = options.StuckDuration or const.Second * 2
    options.RecoveryRetryDelay = options.RecoveryRetryDelay or const.Second * 2
    options.LateralOffsets = options.LateralOffsets or {180, 260, 340}
    options.DynamicClearance = options.DynamicClearance or 24
    options.PartyCollisionRadius = options.PartyCollisionRadius or 100
    options.PartyCollisionHeight = options.PartyCollisionHeight or 192
    options.Direction = options.Direction or 0
    options.HoldGuardRadius = options.HoldGuardRadius or 256

    for _, definition in ipairs(options.Formations) do
        assert(type(definition.SummonPos) == "table", "Routed formation requires SummonPos.")
        assert(type(definition.Formation) == "table", "Routed formation requires Formation.")
        assert(type(definition.Formation.MonsterComposition) == "table",
            "Routed formation requires Formation.MonsterComposition.")
        assert(type(definition.Route) == "table" and type(definition.Route.Waypoints) == "table"
            and #definition.Route.Waypoints > 0, "Routed formation requires at least one Route.Waypoint.")
        assert(definition.Route.Traversal == "Once" or definition.Route.Traversal == "PingPong"
            or definition.Route.Traversal == "Loop",
            "Route.Traversal must be Once, PingPong, or Loop.")
        if definition.Route.Traversal ~= "Once" then
            assert(#definition.Route.Waypoints > 1, "Recurring formation routes require at least two waypoints.")
        end
    end

    local controller = {Name = options.Name, Options = options}

    function controller:Reset()
        mapvars.MonsterFormations = mapvars.MonsterFormations or {}
        mapvars.MonsterFormations[self.Name] = {Routes = {}, Anchors = {}, Debug = {}, RouteProgress = {}}
    end

    -- Clears live movement while preserving Debug assignments for a later restart.
    function controller:Suspend()
        local state = GetMovementState(self.Name)
        state.Routes = {}
        state.Anchors = {}
        state.RouteProgress = {}
    end

    -- Restarts surviving assigned monsters from their authored formation starts.
    -- Returns true when a missing member belonged to a one-shot route.
    function controller:RestartAssignedMonsters(monstersByIndex)
        assert(type(monstersByIndex) == "table", "RestartAssignedMonsters requires monsters keyed by map index.")
        local assignments = GetMovementState(self.Name).Debug
        local skippedOnceRoute = false

        self:Reset()
        for index, assignment in pairs(assignments) do
            local restarted, definition = RestartMonsterAtFormationStart(
                self, monstersByIndex[index], index, assignment)
            if not restarted and definition ~= nil and definition.Route.Traversal == "Once" then
                skippedOnceRoute = true
            end
        end
        return skippedOnceRoute
    end

    -- Assigns `mon` to `formationSlot` on the formation definition at `formationIndex`.
    function controller:AddMonster(mon, index, formationIndex, formationSlot)
        local state = GetMovementState(self.Name)
        local definition = self.Options.Formations[formationIndex]
        local formationPosition = self:GetFormationPosition(formationIndex, formationSlot)
        assert(definition ~= nil and formationPosition ~= nil, "Invalid routed formation assignment.")
        local record = {
            Id = mon.Id,
            Group = mon.Group,
            Formation = formationIndex,
            FormationSlot = formationSlot,
            Waypoint = 1,
            RouteDirection = 1,
            SegmentStart = {X = mon.X, Y = mon.Y, Z = mon.Z},
            FormationPosition = formationPosition,
            ProgressX = mon.X,
            ProgressY = mon.Y,
            ProgressTime = Game.Time,
        }
        state.Routes[index] = record
        state.Debug[index] = {
            Id = record.Id,
            Group = record.Group,
            Formation = record.Formation,
            FormationSlot = record.FormationSlot,
            FormationPosition = record.FormationPosition,
        }
        if definition.Route.Traversal ~= "Once" then
            state.RouteProgress[formationIndex] = state.RouteProgress[formationIndex] or {
                Waypoint = 1,
                RouteDirection = 1,
            }
            record.Waypoint = state.RouteProgress[formationIndex].Waypoint
            record.RouteDirection = state.RouteProgress[formationIndex].RouteDirection
        end
        return formationPosition
    end

    -- Returns the zero-based slot offset and authored axis indexes.
    function controller:GetFormationPosition(formationIndex, formationSlot)
        local definition = self.Options.Formations[formationIndex]
        return definition and GetControllerFormationPositions(self, definition)[formationSlot] or nil
    end

    function controller:ReleaseMonster(index, reason)
        ReleaseMonster(self, GetMovementState(self.Name), index, reason or "explicit")
    end

    function controller:Update()
        if self.Options.IsActive and self.Options.IsActive(self) ~= true then
            return
        end
        local state = GetMovementState(self.Name)
        UpdateMovingMonsters(self, state, GetDynamicBlockers(self, state))
        AdvanceSynchronizedRoutes(self, state)
        UpdateAnchoredMonsters(self, state)
    end

    function controller:Print()
        local state = GetMovementState(self.Name)
        local records = {}
        for index, debugState in pairs(state.Debug) do
            table.insert(records, {Index = index, Debug = debugState})
        end
        table.sort(records, function(a, b)
            if a.Debug.Formation ~= b.Debug.Formation then
                return a.Debug.Formation < b.Debug.Formation
            end
            return a.Debug.FormationSlot < b.Debug.FormationSlot
        end)
        print("=== Monster Formation: " .. self.Name .. " ===")
        for _, entry in ipairs(records) do
            local index = entry.Index
            local debugState = entry.Debug
            local activeState = state.Routes[index]
            local mon = GetMonster(self, index, debugState)
            if mon ~= nil then
                local definition = self.Options.Formations[debugState.Formation]
                local stage
                if activeState and activeState.LateralWaypoint ~= nil then
                    stage = "Lateral recovery toward waypoint " .. tostring(activeState.Waypoint)
                elseif activeState and activeState.ArrivedAtWaypoint then
                    stage = "Waiting at waypoint " .. tostring(activeState.Waypoint)
                elseif activeState then
                    stage = "Waypoint " .. tostring(activeState.Waypoint)
                else
                    stage = state.Anchors[index] and "Formation pinned" or "Formation released"
                end
                print(string.format(
                    "Formation %d (%s) | Slot %d | Index %d | Pos {%d, %d, %d} | Stage %s | AIState %d",
                    debugState.Formation, definition and definition.DebugName or "unnamed",
                    debugState.FormationSlot, index, mon.X, mon.Y, mon.Z, stage, mon.AIState))
            end
        end
    end

    movementControllers[options.Name] = controller
    return controller
end

-- ============================================================================
--  MonsterFormation internal functions
-- ============================================================================

GetFormationPositions = function(anchor, formation, defaultSpacing)
    local layout = formation.Layout or "OrderedColumns"
    assert(layout == "OrderedColumns" or layout == "StaggeredColumns" or layout == "LooseColumns",
        "Unknown monster formation layout: " .. tostring(layout))
    assert(type(formation.XAxisCount) == "number" and type(formation.YAxisCount) == "number",
        "Formation requires XAxisCount and YAxisCount.")

    local xAxisSpacing = formation.XAxisSpacing or defaultSpacing
    local yAxisSpacing = formation.YAxisSpacing or defaultSpacing
    local positions = {}
    for yAxisIndex = 0, formation.YAxisCount - 1 do
        for xAxisIndex = 0, formation.XAxisCount - 1 do
            local offsetX, offsetY = GetFormationLayoutOffset(
                formation, layout, xAxisIndex, yAxisIndex, xAxisSpacing, yAxisSpacing)
            table.insert(positions, {
                X = anchor.X + (xAxisIndex - (formation.XAxisCount - 1) / 2) * xAxisSpacing + offsetX,
                Y = anchor.Y + (yAxisIndex - (formation.YAxisCount - 1) / 2) * yAxisSpacing + offsetY,
                Z = anchor.Z,
                XAxisIndex = xAxisIndex,
                YAxisIndex = yAxisIndex,
            })
        end
    end
    return positions
end

GetFormationLayoutOffset = function(formation, layout, xAxisIndex, yAxisIndex, xAxisSpacing, yAxisSpacing)
    if layout == "StaggeredColumns" then
        local staggerDirection = formation.StaggerDirection or "YAxis"
        assert(staggerDirection == "XAxis" or staggerDirection == "YAxis",
            "Monster formation StaggerDirection must be XAxis or YAxis.")
        if staggerDirection == "XAxis" then
            local staggerOffset = formation.StaggerOffset or xAxisSpacing / 2
            return yAxisIndex % 2 == 0 and -staggerOffset / 2 or staggerOffset / 2, 0
        end
        local staggerOffset = formation.StaggerOffset or yAxisSpacing / 2
        return 0, xAxisIndex % 2 == 0 and -staggerOffset / 2 or staggerOffset / 2
    elseif layout == "LooseColumns" then
        local position = yAxisIndex * formation.XAxisCount + xAxisIndex
        local seed = formation.LayoutSeed or 0
        local looseX = formation.LooseX or xAxisSpacing / 4
        local looseY = formation.LooseY or yAxisSpacing / 4
        return GetDeterministicLooseOffset(position, seed * 2 + 1, looseX),
            GetDeterministicLooseOffset(position, seed * 2 + 2, looseY)
    end
    return 0, 0
end

GetDeterministicLooseOffset = function(position, seed, maximumOffset)
    local oneBasedPosition = position + 1
    local value = (oneBasedPosition * oneBasedPosition * 7919
        + oneBasedPosition * 104729 + seed * 1009 + 1) % 2147483647
    for _ = 1, 3 do
        value = value * 48271 % 2147483647
    end
    return (value / 2147483647 * 2 - 1) * maximumOffset
end

GetCompositionOverrideMonsterId = function(override, position, xAxisIndex, yAxisIndex, context)
    if type(override.MonsterId) == "function" then
        return override.MonsterId(position, xAxisIndex, yAxisIndex, context)
    end
    return override.MonsterId
end

CompositionOverrideMatchesPositionRange = function(override, position)
    local fromIndex = override.FromIndex or 0
    local toIndex = override.ToIndex or math.huge
    assert(type(fromIndex) == "number" and fromIndex >= 0,
        "Monster composition range override FromIndex must be a non-negative number.")
    assert(type(toIndex) == "number" and toIndex >= fromIndex,
        "Monster composition range override ToIndex must be greater than or equal to FromIndex.")
    return position >= fromIndex and position <= toIndex
end

CompositionOverrideMatchesSpatialPosition = function(override, position, xAxisIndex, yAxisIndex)
    local hasSpatialKey = override.Position ~= nil or override.XAxisIndex ~= nil or override.YAxisIndex ~= nil
    return hasSpatialKey
        and (override.Position == nil or override.Position == position)
        and (override.XAxisIndex == nil or override.XAxisIndex == xAxisIndex)
        and (override.YAxisIndex == nil or override.YAxisIndex == yAxisIndex)
end

IsMonsterAlive = function(mon)
    return mon ~= nil
        and mon.HP > 0
        and mon.AIState ~= const.AIState.Dead
        and mon.AIState ~= const.AIState.Removed
        and mon.AIState ~= const.AIState.Dying
end

GetMovementState = function(name)
    mapvars.MonsterFormations = mapvars.MonsterFormations or {}
    mapvars.MonsterFormations[name] = mapvars.MonsterFormations[name] or {
        Routes = {},
        Anchors = {},
        Debug = {},
        RouteProgress = {},
    }
    return mapvars.MonsterFormations[name]
end

GetControllerFormationPositions = function(controller, definition)
    local positions = GetFormationPositions({X = 0, Y = 0, Z = 0}, definition.Formation, controller.Options.Spacing)
    local route = definition.Route
    if route.Traversal ~= "Once" then
        return positions
    end

    local finalWaypoint = route.Waypoints[#route.Waypoints]
    local approach = route.Waypoints[#route.Waypoints - 1] or definition.SummonPos
    local approachX = finalWaypoint.X - approach.X
    local approachY = finalWaypoint.Y - approach.Y
    local useXAxisLayers = math.abs(approachX) >= math.abs(approachY)
    local layerDirection = useXAxisLayers and (approachX >= 0 and 1 or -1)
        or (approachY >= 0 and 1 or -1)
    for _, position in ipairs(positions) do
        if useXAxisLayers then
            position.LayerDepth = position.X * layerDirection
            position.ApproachLaneDistance = math.abs(position.Y)
        else
            position.LayerDepth = position.Y * layerDirection
            position.ApproachLaneDistance = math.abs(position.X)
        end
    end
    table.sort(positions, function(a, b)
        if a.LayerDepth ~= b.LayerDepth then
            return a.LayerDepth > b.LayerDepth
        end
        return a.ApproachLaneDistance < b.ApproachLaneDistance
    end)
    return positions
end

GetMonster = function(controller, index, record)
    local mon = Map.Monsters[index]
    if mon == nil or mon.Id ~= record.Id or mon.Group ~= record.Group then
        return nil
    end
    return mon
end

RestartMonsterAtFormationStart = function(controller, mon, index, assignment)
    local definition = controller.Options.Formations[assignment.Formation]
    local formationPosition = controller:GetFormationPosition(assignment.Formation, assignment.FormationSlot)
    if mon == nil or definition == nil or formationPosition == nil then
        return false, definition
    end

    mon.X = definition.SummonPos.X + formationPosition.X
    mon.Y = definition.SummonPos.Y + formationPosition.Y
    mon.Z = definition.SummonPos.Z
    mon.StartX = mon.X
    mon.StartY = mon.Y
    mon.StartZ = mon.Z
    mon.GuardX = mon.X
    mon.GuardY = mon.Y
    mon.GuardZ = mon.Z
    mon.VelocityX = 0
    mon.VelocityY = 0
    mon.VelocityZ = 0
    mon.CurrentActionLength = 0
    mon.CurrentActionStep = 0
    mon.AIState = const.AIState.Active
    mon:UpdateGraphicState()
    controller:AddMonster(mon, index, assignment.Formation, assignment.FormationSlot)
    return true, definition
end

GetRouteTarget = function(controller, state)
    local definition = controller.Options.Formations[state.Formation]
    local waypoint = definition and definition.Route.Waypoints[state.Waypoint]
    if waypoint == nil or state.FormationPosition == nil then
        return nil, definition
    end
    local useFormationOffset = definition.Route.Traversal ~= "Once"
        or state.Waypoint == #definition.Route.Waypoints
    return {
        X = waypoint.X + (useFormationOffset and state.FormationPosition.X or 0),
        Y = waypoint.Y + (useFormationOffset and state.FormationPosition.Y or 0),
        Z = waypoint.Z,
    }, definition
end

ResetProgress = function(state, mon, target)
    state.ProgressX = mon.X
    state.ProgressY = mon.Y
    state.ProgressTime = Game.Time
    state.ProgressTargetX = target and target.X or nil
    state.ProgressTargetY = target and target.Y or nil
    if target ~= nil then
        local dx = target.X - mon.X
        local dy = target.Y - mon.Y
        state.ProgressTargetDistance = math.sqrt(dx * dx + dy * dy)
    else
        state.ProgressTargetDistance = nil
    end
end

HoldMonster = function(controller, mon, anchor)
    mon.X = anchor.X
    mon.Y = anchor.Y
    mon.StartX = anchor.X
    mon.StartY = anchor.Y
    mon.GuardX = anchor.X
    mon.GuardY = anchor.Y
    mon.GuardZ = anchor.Z
    mon.Direction = anchor.Direction
    mon.GuardRadius = controller.Options.HoldGuardRadius
    mon.VelocityX = 0
    mon.VelocityY = 0
    mon.CurrentActionLength = const.Hour
    mon.CurrentActionStep = 0
    mon.AIState = const.AIState.Stand
    mon:UpdateGraphicState()
end

GetDynamicClearance = function(controller, index, mon, position, blockers)
    local closestClearance
    for _, blocker in ipairs(blockers) do
        if blocker.Index ~= index then
            local verticalDistance = math.abs(position.Z - blocker.Z)
            if verticalDistance < math.max(mon.BodyHeight, blocker.BodyHeight) then
                local dx = position.X - blocker.X
                local dy = position.Y - blocker.Y
                local distance = math.sqrt(dx * dx + dy * dy)
                local clearance = distance - mon.BodyRadius - blocker.BodyRadius
                if closestClearance == nil or clearance < closestClearance then
                    closestClearance = clearance
                end
            end
        end
    end
    if math.abs(position.Z - Party.Z) < controller.Options.PartyCollisionHeight then
        local dx = position.X - Party.X
        local dy = position.Y - Party.Y
        local distance = math.sqrt(dx * dx + dy * dy)
        local clearance = distance - mon.BodyRadius - controller.Options.PartyCollisionRadius
        if closestClearance == nil or clearance < closestClearance then
            closestClearance = clearance
        end
    end
    return closestClearance or 32767
end

GetDynamicRouteClearance = function(controller, index, mon, from, to, blockers)
    local closestClearance = 32767
    for sample = 1, 4 do
        local progress = sample / 4
        closestClearance = math.min(closestClearance, GetDynamicClearance(controller, index, mon, {
            X = from.X + (to.X - from.X) * progress,
            Y = from.Y + (to.Y - from.Y) * progress,
            Z = from.Z + (to.Z - from.Z) * progress,
        }, blockers))
    end
    return closestClearance
end

FindLateralWaypoint = function(controller, index, mon, state, resumeTarget, blockers)
    if not Game.ImprovedPathfinding or type(PathfinderDll) ~= "table" then
        return nil
    end
    local dx = resumeTarget.X - mon.X
    local dy = resumeTarget.Y - mon.Y
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 1 then
        return nil
    end
    local perpendicularX = -dy / length
    local perpendicularY = dx / length
    for _, offset in ipairs(controller.Options.LateralOffsets) do
        local best, bestClearance, bestSide
        for side = -1, 1, 2 do
            local candidate = {
                X = math.floor(mon.X + perpendicularX * offset * side),
                Y = math.floor(mon.Y + perpendicularY * offset * side),
                Z = mon.Z,
            }
            local floorLevel = PathfinderDll.GetFloorLevel(candidate.X, candidate.Y, candidate.Z + mon.BodyHeight)
            if floorLevel > -30000 then
                candidate.Z = floorLevel
            end
            local clearance = math.min(
                GetDynamicRouteClearance(controller, index, mon, mon, candidate, blockers),
                GetDynamicRouteClearance(controller, index, mon, candidate, resumeTarget, blockers))
            if clearance >= controller.Options.DynamicClearance
                and PathfinderDll.TraceWay(mon, mon, candidate)
                and PathfinderDll.TraceWay(mon, candidate, resumeTarget)
                and (best == nil or clearance > bestClearance
                    or (clearance == bestClearance and side ~= state.LastLateralSide)) then
                best = candidate
                bestClearance = clearance
                bestSide = side
            end
        end
        if best ~= nil then
            state.LastLateralSide = bestSide
            return best
        end
    end
end

GetDynamicBlockers = function(controller, movementState)
    local blockers = {}
    for index, record in pairs(movementState.Routes) do
        local mon = GetMonster(controller, index, record)
        if IsMonsterAlive(mon) then
            table.insert(blockers, {
                Index = index,
                X = mon.X,
                Y = mon.Y,
                Z = mon.Z,
                BodyRadius = mon.BodyRadius,
                BodyHeight = mon.BodyHeight,
            })
        end
    end
    for index, record in pairs(movementState.Anchors) do
        local mon = GetMonster(controller, index, record)
        if IsMonsterAlive(mon) then
            table.insert(blockers, {
                Index = index,
                X = mon.X,
                Y = mon.Y,
                Z = mon.Z,
                BodyRadius = mon.BodyRadius,
                BodyHeight = mon.BodyHeight,
            })
        end
    end
    return blockers
end

UpdateProgress = function(controller, index, mon, state, waypoint, blockers)
    local navigationTarget = state.LateralWaypoint or waypoint
    if state.ProgressTargetDistance == nil or state.ProgressTime == nil
        or state.ProgressTargetX ~= navigationTarget.X or state.ProgressTargetY ~= navigationTarget.Y then
        ResetProgress(state, mon, navigationTarget)
        return
    end
    local dx = navigationTarget.X - mon.X
    local dy = navigationTarget.Y - mon.Y
    local targetDistance = math.sqrt(dx * dx + dy * dy)
    if state.ProgressTargetDistance - targetDistance >= controller.Options.ProgressDistance then
        ResetProgress(state, mon, navigationTarget)
    elseif Game.Time - state.ProgressTime >= controller.Options.StuckDuration
        and (state.NextRecoveryTime == nil or Game.Time >= state.NextRecoveryTime) then
        state.NextRecoveryTime = Game.Time + controller.Options.RecoveryRetryDelay
        state.LateralWaypoint = FindLateralWaypoint(controller, index, mon, state, waypoint, blockers)
        ResetProgress(state, mon, state.LateralWaypoint or waypoint)
    end
end

ShouldRelease = function(controller, mon, state)
    return controller.Options.ShouldRelease ~= nil and controller.Options.ShouldRelease(mon, state, controller) == true
end

ReleaseMonster = function(controller, movementState, index, reason)
    local record = movementState.Routes[index] or movementState.Anchors[index]
    local mon = record and GetMonster(controller, index, record)
    movementState.Routes[index] = nil
    movementState.Anchors[index] = nil
    if mon ~= nil then
        -- Remove authored movement state before returning control to native AI.
        mon.StartX = mon.X
        mon.StartY = mon.Y
        mon.StartZ = mon.Z
        mon.GuardX = mon.X
        mon.GuardY = mon.Y
        mon.GuardZ = mon.Z
        mon.VelocityX = 0
        mon.VelocityY = 0
        mon.VelocityZ = 0
        mon.CurrentActionLength = 0
        mon.CurrentActionStep = 0
        if controller.Options.OnRelease then
            controller.Options.OnRelease(mon, record, reason, controller)
        end
    end
end

PinMonster = function(controller, movementState, index, mon, state, target)
    movementState.Routes[index] = nil
    local anchor = {
        Id = state.Id,
        Group = state.Group,
        Formation = state.Formation,
        FormationSlot = state.FormationSlot,
        FormationPosition = state.FormationPosition,
        X = target.X,
        Y = target.Y,
        Z = target.Z,
        Direction = state.Direction or controller.Options.Direction,
    }
    movementState.Anchors[index] = anchor
    HoldMonster(controller, mon, anchor)
end

AdvanceOnceRoute = function(controller, movementState, index, mon, state, definition, target)
    if state.Waypoint >= #definition.Route.Waypoints then
        PinMonster(controller, movementState, index, mon, state, target)
        return
    end
    state.SegmentStart = target
    state.Waypoint = state.Waypoint + 1
    state.LateralWaypoint = nil
    state.NextRecoveryTime = nil
    ResetProgress(state, mon)
end

-- Recurring routes share waypoint progress. The first arrival starts a maximum
-- wait deadline so a living member that cannot arrive cannot block the route.
AdvanceSynchronizedRoutes = function(controller, movementState)
    for formationIndex, definition in ipairs(controller.Options.Formations) do
        local route = definition.Route
        if route.Traversal ~= "Once" and movementState.RouteProgress[formationIndex] ~= nil then
            local progress = movementState.RouteProgress[formationIndex]
            local members = {}
            local anyArrived = false
            local allArrived = true
            for index, state in pairs(movementState.Routes) do
                if state.Formation == formationIndex then
                    local mon = GetMonster(controller, index, state)
                    if IsMonsterAlive(mon) then
                        table.insert(members, {Index = index, State = state, Monster = mon})
                        if state.ArrivedAtWaypoint == progress.Waypoint then
                            anyArrived = true
                        else
                            allArrived = false
                        end
                    end
                end
            end
            if #members > 0 and anyArrived then
                local waypointWaitDuration = route.WaypointWaitDuration or 0
                if progress.MaximumWaitUntil == nil then
                    local graceSeconds = math.min(30, math.max(10, #members))
                    progress.MaximumWaitUntil = Game.Time + waypointWaitDuration + graceSeconds * const.Second
                end
                if allArrived and progress.WaitUntil == nil then
                    progress.WaitUntil = Game.Time + waypointWaitDuration
                elseif not allArrived then
                    progress.WaitUntil = nil
                end
                local departureTime = math.min(progress.WaitUntil or math.huge, progress.MaximumWaitUntil)
                if Game.Time >= departureTime then
                    if route.Traversal == "Loop" then
                        progress.Waypoint = progress.Waypoint % #route.Waypoints + 1
                    else
                        if progress.Waypoint == #route.Waypoints then
                            progress.RouteDirection = -1
                        elseif progress.Waypoint == 1 then
                            progress.RouteDirection = 1
                        end
                        progress.Waypoint = progress.Waypoint + progress.RouteDirection
                    end
                    progress.WaitUntil = nil
                    progress.MaximumWaitUntil = nil
                    for _, member in ipairs(members) do
                        local state = member.State
                        state.SegmentStart = select(1, GetRouteTarget(controller, state))
                        state.Waypoint = progress.Waypoint
                        state.RouteDirection = progress.RouteDirection
                        state.ArrivedAtWaypoint = nil
                        state.LateralWaypoint = nil
                        state.NextRecoveryTime = nil
                        ResetProgress(state, member.Monster)
                    end
                end
            else
                progress.WaitUntil = nil
                progress.MaximumWaitUntil = nil
            end
        end
    end
end

UpdateMovingMonsters = function(controller, movementState, blockers)
    for index, state in pairs(movementState.Routes) do
        local mon = GetMonster(controller, index, state)
        local target, definition = GetRouteTarget(controller, state)
        if not IsMonsterAlive(mon) or definition == nil or target == nil then
            movementState.Routes[index] = nil
        elseif ShouldRelease(controller, mon, state) then
            ReleaseMonster(controller, movementState, index, "trigger")
        elseif state.ArrivedAtWaypoint ~= nil then
            HoldMonster(controller, mon, {
                X = target.X,
                Y = target.Y,
                Z = target.Z,
                Direction = state.Direction or controller.Options.Direction,
            })
        else
            local dx = target.X - mon.X
            local dy = target.Y - mon.Y
            local isFinalOnceWaypoint = definition.Route.Traversal == "Once"
                and state.Waypoint == #definition.Route.Waypoints
            local useArrivalRadius = definition.Route.Traversal ~= "Once" or isFinalOnceWaypoint
            local arrivalRadius = useArrivalRadius and controller.Options.ArrivalRadius
                or controller.Options.WaypointRadius
            local reachedWaypoint = dx * dx + dy * dy <= arrivalRadius ^ 2
            if not reachedWaypoint and definition.Route.Traversal == "Once"
                and state.Waypoint < #definition.Route.Waypoints then
                local segmentStart = state.SegmentStart or definition.SummonPos
                local segmentX = target.X - segmentStart.X
                local segmentY = target.Y - segmentStart.Y
                local segmentLengthSquared = segmentX * segmentX + segmentY * segmentY
                if segmentLengthSquared > 0 then
                    local progress = ((mon.X - segmentStart.X) * segmentX
                        + (mon.Y - segmentStart.Y) * segmentY) / segmentLengthSquared
                    reachedWaypoint = progress >= controller.Options.WaypointPassProgress
                end
            end

            if reachedWaypoint then
                if definition.Route.Traversal == "Once" then
                    AdvanceOnceRoute(controller, movementState, index, mon, state, definition, target)
                else
                    state.ArrivedAtWaypoint = state.Waypoint
                    state.LateralWaypoint = nil
                    state.NextRecoveryTime = nil
                    HoldMonster(controller, mon, {
                        X = target.X,
                        Y = target.Y,
                        Z = target.Z,
                        Direction = state.Direction or controller.Options.Direction,
                    })
                end
            else
                if state.LateralWaypoint ~= nil then
                    local lateralX = state.LateralWaypoint.X - mon.X
                    local lateralY = state.LateralWaypoint.Y - mon.Y
                    if lateralX * lateralX + lateralY * lateralY <= controller.Options.ArrivalRadius ^ 2 then
                        state.LateralWaypoint = nil
                        ResetProgress(state, mon)
                    else
                        UpdateProgress(controller, index, mon, state, target, blockers)
                    end
                else
                    UpdateProgress(controller, index, mon, state, target, blockers)
                end

                local navigationTarget = state.LateralWaypoint or target
                mon.GuardX = navigationTarget.X
                mon.GuardY = navigationTarget.Y
                mon.GuardZ = navigationTarget.Z
                state.Direction = math.floor(
                    math.atan2(navigationTarget.Y - mon.Y, navigationTarget.X - mon.X) * 1024 / math.pi) % 2048
                mon.Direction = state.Direction
                if mon.AIState ~= const.AIState.Pursue then
                    mon.CurrentActionStep = 0
                end
                mon.AIState = const.AIState.Pursue
                mon.CurrentActionLength = const.Hour
                mon:UpdateGraphicState()
            end
        end
    end
end

UpdateAnchoredMonsters = function(controller, movementState)
    for index, anchor in pairs(movementState.Anchors) do
        local mon = GetMonster(controller, index, anchor)
        if not IsMonsterAlive(mon) then
            movementState.Anchors[index] = nil
        elseif ShouldRelease(controller, mon, anchor) then
            ReleaseMonster(controller, movementState, index, "trigger")
        else
            HoldMonster(controller, mon, anchor)
        end
    end
end

function events.MonstersProcessed()
    for _, controller in pairs(movementControllers) do
        controller:Update()
    end
end

function events.MonsterNeedPathfinding(t)
    local targetRef = GetMonsterTarget(t.MonsterIndex)
    if targetRef ~= const.ObjectRefKind.Party then
        return
    end

    for _, controller in pairs(movementControllers) do
        if controller.Options.IsActive == nil or controller.Options.IsActive(controller) == true then
            local state = GetMovementState(controller.Name)
            if state.Routes[t.MonsterIndex] ~= nil then
                t.Result = false
                return
            end
        end
    end
end
