-- Tracked quest monster encounter helpers for Merge and Mischief.

local IsMonsterEncounterOnCurrentMap
local GetMonsterEncounterMonster
local FindMonsterEncountersForMap
local CleanupMonsterEncountersOnMapEntry

-- ============================================================================
--  vars.MonsterEncounters helpers
--
--  vars.MonsterEncounters stores named, per-map quest encounters as tracked
--  monster snapshots. It lets us reliably find the exact monsters that belong
--  to a quest encounter across save/load and map re-entry.
-- ============================================================================

function IsAlive(mon)
    return mon ~= nil
        and mon.HP > 0
        and mon.AIState ~= const.AIState.Dead
        and mon.AIState ~= const.AIState.Removed
        and mon.AIState ~= const.AIState.Dying
end

function GetLastOccupiedMonsterIndex()
    local lastIndex = -1

    for index, mon in Map.Monsters do
        if mon.Id > 0 then
            lastIndex = math.max(lastIndex, index)
        end
    end

    return lastIndex
end

-- `encounterName` is the stable key used under `vars.MonsterEncounters[mapName]`.
-- `mapMonIndexes` is the list of `Map.Monsters[index]` slots that belong to this encounter.
-- `mapName` optionally overrides the current map name and defaults to `Map.Name`.
function CreateAndSetMonsterEncounterFromIndexes(encounterName, mapMonIndexes, mapName)
    mapName = mapName or Map.Name
    local encounter = CreateMonsterEncounter(mapMonIndexes)
    return SetMonsterEncounter(encounterName, encounter, mapName)
end

-- `encounterName` is the stable key used under `vars.MonsterEncounters[mapName]`.
-- `predicate` decides which current `Map.Monsters` entries belong to this encounter.
-- `mapName` optionally overrides the current map name and defaults to `Map.Name`.
function CreateAndSetMonsterEncounterFromPredicate(encounterName, predicate, mapName)
    mapName = mapName or Map.Name
    local encounter = CreateMonsterEncounterFromPredicate(predicate)
    return SetMonsterEncounter(encounterName, encounter, mapName)
end

function CreateAndSetMonsterEncounterFromRange(encounterName, firstIndex, lastIndex, mapName)
    local mapMonIndexes = {}

    if type(firstIndex) == "number" and type(lastIndex) == "number" and firstIndex <= lastIndex then
        for index = firstIndex, lastIndex do
            table.insert(mapMonIndexes, index)
        end
    end

    return CreateAndSetMonsterEncounterFromIndexes(encounterName, mapMonIndexes, mapName)
end

-- Creates a reusable monster encounter from known `Map.Monsters[index]` slots.
-- Each record stores the current map name plus `{index, id, group}` for a monster.
function CreateMonsterEncounter(mapMonIndexes)
    local encounter = {
        map = Map.Name,
        monsters = {},
        monstersByIndex = {},
        monsterIds = {},
        removeOnMapEntry = false,
    }
    for _, index in ipairs(mapMonIndexes) do
        local mon = type(index) == "number" and index >= 0 and Map.Monsters[index] or nil
        if mon ~= nil then
            local record = {
                index = index,
                id = mon.Id,
                group = mon.Group,
            }
            table.insert(encounter.monsters, record)
            encounter.monstersByIndex[index] = {
                id = record.id,
                group = record.group,
            }
            encounter.monsterIds[record.id] = true
        end
    end

    return encounter
end

-- Captures a monster encounter by discovering matching monsters from a predicate.
-- This is the more niche form, useful when the encounter already exists on the map.
function CreateMonsterEncounterFromPredicate(predicate)
    local mapMonIndexes = {}

    for index, mon in Map.Monsters do
        if predicate(index, mon) then
            table.insert(mapMonIndexes, index)
        end
    end

    return CreateMonsterEncounter(mapMonIndexes)
end

function ForEachMonsterEncounter(encounter, fn, includeRemoved)
    if type(encounter) ~= "table" then
        return nil, "missing_encounter"
    end
    if type(encounter.monsters) ~= "table" then
        return nil, "invalid_encounter"
    end
    if encounter.map ~= Map.Name then
        return nil, "wrong_map"
    end
    for _, record in ipairs(encounter.monsters) do
        local mon = GetMonsterEncounterMonster(record)
        if mon ~= nil and (includeRemoved or mon.AIState ~= const.AIState.Removed) then
            fn(record, mon)
        end
    end

    return true
end

function MonsterEncounterContainsMonster(encounter, mon)
    if mon == nil then
        return nil, "missing_monster"
    end
    if type(encounter) ~= "table" then
        return nil, "missing_encounter"
    end
    if type(encounter.monsters) ~= "table" or type(encounter.monstersByIndex) ~= "table" then
        return nil, "invalid_encounter"
    end
    if encounter.map ~= Map.Name then
        return nil, "wrong_map"
    end

    local index = mon:GetIndex()
    local record = encounter.monstersByIndex[index]
    return record ~= nil and mon.Id == record.id and mon.Group == record.group
end

function MonsterEncounterHasAnyHostile(encounter)
    if not IsMonsterEncounterOnCurrentMap(encounter) then
        return false
    end

    for index, record in pairs(encounter.monstersByIndex) do
        local mon = Map.Monsters[index]
        if mon ~= nil and mon.Id == record.id and mon.Group == record.group and IsAlive(mon) and mon.Hostile then
            return true
        end
    end
    return false
end

function MonsterEncounterHasAnyActive(encounter)
    local found = false
    local ok, reason = ForEachMonsterEncounter(encounter, function(_, mon)
        if IsAlive(mon) then
            found = true
        end
    end)
    if not ok then
        return nil, reason
    end
    return found
end

function MonsterEncounterHasAnyActiveForGroup(encounter, monsterGroup)
    local found = false
    local ok, reason = ForEachMonsterEncounter(encounter, function(record, mon)
        if record.group == monsterGroup and IsAlive(mon) then
            found = true
        end
    end)
    if not ok then
        return nil, reason
    end
    return found
end

function RemoveMonsterEncounter(encounter)
    ForEachMonsterEncounter(encounter, function(_, mon)
        mon.AIState = const.AIState.Removed
    end, true)
end

function SetMonsterEncounter(encounterName, encounter, mapName)
    mapName = mapName or Map.Name
    vars.MonsterEncounters = vars.MonsterEncounters or {}
    vars.MonsterEncounters[mapName] = vars.MonsterEncounters[mapName] or {}
    local mapEncounters = vars.MonsterEncounters[mapName]
    mapEncounters[encounterName] = encounter
    return encounter
end

function AddMonsterEncounterIndexes(encounterName, mapMonIndexes, mapName)
    mapName = mapName or Map.Name
    local encounter = GetMonsterEncounter(encounterName, mapName)
    if type(encounter) ~= "table" then
        return nil, "missing_encounter"
    end

    for _, index in ipairs(mapMonIndexes or {}) do
        local mon = type(index) == "number" and index >= 0 and Map.Monsters[index] or nil
        if mon ~= nil then
            local record = {
                index = index,
                id = mon.Id,
                group = mon.Group,
            }
            table.insert(encounter.monsters, record)
            encounter.monstersByIndex[index] = {
                id = record.id,
                group = record.group,
            }
            encounter.monsterIds[record.id] = true
        end
    end

    return encounter
end

function GetMonsterEncounter(encounterName, mapName)
    mapName = mapName or Map.Name
    local mapEncounters = FindMonsterEncountersForMap(mapName)
    return mapEncounters and mapEncounters[encounterName] or nil
end

function MarkMonsterEncounterForRemoval(encounterName, mapName)
    local encounter = GetMonsterEncounter(encounterName, mapName)
    if encounter then
        encounter.removeOnMapEntry = true
    end
    return encounter
end

function PrintMonsterEncounter(encounterName, mapName)
    mapName = mapName or Map.Name

    local encounter = GetMonsterEncounter(encounterName, mapName)
    if not encounter then
        print(string.format("Monster encounter '%s' was not found on map '%s'.", tostring(encounterName), tostring(mapName)))
        return
    end

    local count = 0
    local ok, reason = ForEachMonsterEncounter(encounter, function(record, mon)
        print(record.index, Game.MonstersTxt[mon.Id].Name, "Group", record.group)
        count = count + 1
    end, true)

    if not ok and reason == "wrong_map" then
        print(string.format("Map: %s name: %s Monster data unavailable while current map is %s. Staged for removal: %s",
            tostring(mapName), tostring(encounterName), tostring(Map.Name), tostring(encounter.removeOnMapEntry)))
        return
    end

    print("Map: ", mapName, "name: ", encounterName, "Monster count: ", count, "Staged for removal: ", encounter.removeOnMapEntry)
end

function LsMonsterEncounters()
    local registry = vars.MonsterEncounters
    if type(registry) ~= "table" or next(registry) == nil then
        print("No monster encounters are registered.")
        return
    end

    local mapNames = {}
    for mapName in pairs(registry) do
        table.insert(mapNames, mapName)
    end
    table.sort(mapNames)

    for _, mapName in ipairs(mapNames) do
        local mapEncounters = registry[mapName]
        local encounterNames = {}

        for encounterName in pairs(mapEncounters) do
            table.insert(encounterNames, encounterName)
        end
        table.sort(encounterNames)

        print("Map                " .. mapName)
        print("Encounter      " .. table.concat(encounterNames, " "))
    end
end

function PrintMonsterEncounters()
    local registry = vars.MonsterEncounters
    if type(registry) ~= "table" or next(registry) == nil then
        print("No monster encounters are registered.")
        return
    end

    local mapNames = {}
    for mapName in pairs(registry) do
        table.insert(mapNames, mapName)
    end
    table.sort(mapNames)

    for _, mapName in ipairs(mapNames) do
        local mapEncounters = registry[mapName]
        local encounterNames = {}

        for encounterName in pairs(mapEncounters) do
            table.insert(encounterNames, encounterName)
        end
        table.sort(encounterNames)

        for _, encounterName in ipairs(encounterNames) do
            PrintMonsterEncounter(encounterName, mapName)
        end
    end
end

-- ============================================================================
--  vars.MonsterEncounters internal functions
-- ============================================================================

IsMonsterEncounterOnCurrentMap = function(encounter)
    return type(encounter) == "table" and encounter.map == Map.Name and type(encounter.monsters) == "table"
end

GetMonsterEncounterMonster = function(record)
    if type(record.index) ~= "number" or record.index < 0 then
        return nil
    end
    local mon = Map.Monsters[record.index]
    if mon == nil then
        return nil
    end
    if mon.Id ~= record.id or mon.Group ~= record.group then
        return nil
    end
    return mon
end

FindMonsterEncountersForMap = function(mapName)
    local registry = vars.MonsterEncounters
    return registry and registry[mapName] or nil
end

CleanupMonsterEncountersOnMapEntry = function(mapName)
    local mapEncounters = FindMonsterEncountersForMap(mapName)
    if not mapEncounters then
        return
    end

    for encounterName, encounter in pairs(mapEncounters) do
        if encounter.removeOnMapEntry == true then
            RemoveMonsterEncounter(encounter)
            mapEncounters[encounterName] = nil
        end
    end

    if next(mapEncounters) == nil then
        local registry = vars.MonsterEncounters
        if registry then
            registry[mapName] = nil
        end
    end
end

function events.AfterLoadMap()
    CleanupMonsterEncountersOnMapEntry(Map.Name)
end
