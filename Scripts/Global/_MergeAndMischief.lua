-- This file is for shared functions meant to be reused across multiple files in the Merge and Mischief mod. 
-- It acts as the early-loaded common bootstrap for global scripts.

-- session variables - important state for current gaming session.
svars = {}

-- local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5

-- local urokNPC_ID = 1081 -- goblinwatch apartment pre Goblinwatch quest
-- local samsonTessNPC_ID = 828 -- goblinwatch apartment post Goblinwatch quest
-- local harryMerit_ID = 111 -- not in use
-- local NewSorpigal = "oute3.odm"
-- local houseMapName = "decenthouse.blv"

-- local goblinwatchHouse = 1463


-- Copies combat power from `powerMonster` onto the live map monster `mon`.
-- `mon` is the spawned monster instance that keeps its own appearance/identity.
-- `powerMonster` is usually a `Game.MonstersTxt[id]` entry used as the combat template.
-- `resetHP` should be true for fresh scripted spawns that should start at full powered HP.
-- Use false when reapplying after reload so current battle damage is preserved proportionally.
-- `hpMultiplier` is optional and lets callers scale max HP without breaking reload-time HP preservation.
function ApplyMonsterPowerFromMonster(mon, powerMonster, resetHP, hpMultiplier)
    local oldFullHP = mon.FullHP
    local oldHP = mon.HP
    local targetFullHP = math.max(1, math.floor(powerMonster.FullHP * (hpMultiplier or 1)))

    mon.FullHP = targetFullHP
    if resetHP then
        mon.HP = targetFullHP
    else
        -- Preserve the monster's current health percentage when swapping to a different max HP pool.
        local hpRatio = oldFullHP > 0 and oldHP / oldFullHP or 1
        mon.HP = math.max(1, math.floor(mon.FullHP * hpRatio))
    end
    mon.ArmorClass = powerMonster.ArmorClass
    mon.Exp = powerMonster.Exp
    mon.Level = powerMonster.Level
    mon.MoveType = powerMonster.MoveType
    mon.TreasureItemPercent = powerMonster.TreasureItemPercent
    mon.TreasureDiceCount = powerMonster.TreasureDiceCount
    mon.TreasureDiceSides = powerMonster.TreasureDiceSides
    mon.TreasureItemLevel = powerMonster.TreasureItemLevel
    mon.TreasureItemType = powerMonster.TreasureItemType

    mon.Attack1.DamageAdd = powerMonster.Attack1.DamageAdd
    mon.Attack1.DamageDiceSides = powerMonster.Attack1.DamageDiceSides
    mon.Attack1.DamageDiceCount = powerMonster.Attack1.DamageDiceCount

    mon.Attack2Chance = powerMonster.Attack2Chance
    mon.Attack2.DamageAdd = powerMonster.Attack2.DamageAdd
    mon.Attack2.DamageDiceSides = powerMonster.Attack2.DamageDiceSides
    mon.Attack2.DamageDiceCount = powerMonster.Attack2.DamageDiceCount

    mon.SpellChance = powerMonster.SpellChance
    mon.Spell = powerMonster.Spell
    mon.SpellSkill = powerMonster.SpellSkill
    mon.Spell2Chance = powerMonster.Spell2Chance
    mon.Spell2 = powerMonster.Spell2
    mon.Spell2Skill = powerMonster.Spell2Skill

    mon.FireResistance = powerMonster.FireResistance
    mon.AirResistance = powerMonster.AirResistance
    mon.WaterResistance = powerMonster.WaterResistance
    mon.EarthResistance = powerMonster.EarthResistance
    mon.MindResistance = powerMonster.MindResistance
    mon.SpiritResistance = powerMonster.SpiritResistance
    mon.BodyResistance = powerMonster.BodyResistance
    mon.LightResistance = powerMonster.LightResistance
    mon.DarkResistance = powerMonster.DarkResistance
    mon.PhysResistance = powerMonster.PhysResistance
end

local IsMonsterEncounterOnCurrentMap
local GetMonsterEncounterMonster
local FindMonsterEncountersForMap
local CleanupMonsterEncountersOnMapEntry


-- ===========================================================================================================================================
--  vars.MonsterEncounters helpers
--
--  vars.MonsterEncounters stores named, per-map quest encounters as tracked monster snapshots.
--  It lets us reliably find the exact monsters that belong to a quest encounter across save/load and map re-entry.
--  We can use it both for cleanup/refill handling and for objective checks like whether an encounter is cleared or a key monster is dead.
-- ===========================================================================================================================================

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
        removeOnMapEntry = false,
    }
    local monsterCount = #Map.Monsters

    for _, index in ipairs(mapMonIndexes) do
        if type(index) == "number" and index >= 0 and index < monsterCount then
            local mon = Map.Monsters[index]
            table.insert(encounter.monsters, {
                index = index,
                id = mon.Id,
                group = mon.Group,
            })
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

function MonsterEncounterHasAnyActive(encounter)
    local found = false
    local ok, reason = ForEachMonsterEncounter(encounter, function(_, mon)
        if mon.HP > 0 and mon.AIState ~= const.AIState.Dead then
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
        if record.group == monsterGroup and mon.HP > 0 and mon.AIState ~= const.AIState.Dead then
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
    local monsterCount = #Map.Monsters
    if type(record.index) ~= "number" or record.index < 0 or record.index >= monsterCount then
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

-- local function IsOriginalGoblinwathDone()
--     return Party.QBits[313] and Party.QBits[1324] and Party.QBits[1107] == false
-- end

-- local function RestoreUrok()
--     RemoveSafeTopicsFromNPC(urokNPC_ID)
--     NPCTopic{
--         Slot = A,
--         NPC = urokNPC_ID,
--         Topic = "Humans",
--         Text = [[You no goblin!
-- you leave!
-- We take castle to watch over humans!
-- You no more kill us!]]
--     }
--     if IsOriginalGoblinwathDone() then
--         Game.NPC[urokNPC_ID].House = 0
--     else
--         Game.NPC[urokNPC_ID].House = goblinwatchHouse
--     end
--     Game.NPC[urokNPC_ID].Name = "Urok"
--     Game.NPC[urokNPC_ID].Pic = 1031
-- 	Game.NPC[urokNPC_ID].Profession = 0
-- end

-- local function RestoreSamsonTess()
--     if IsOriginalGoblinwathDone() then
--         Game.NPC[samsonTessNPC_ID].House = goblinwatchHouse
--     else
--         Game.NPC[samsonTessNPC_ID].House = 0
--     end
--     RemoveSafeTopicsFromNPC(samsonTessNPC_ID)
--     Game.NPC[samsonTessNPC_ID].Name = "Samson Tess"
--     Game.NPC[samsonTessNPC_ID].Profession = 73 -- guard
--     Game.NPC[samsonTessNPC_ID].Pic = 429

--     NPCTopic{
--         Slot = A,
--         NPC = samsonTessNPC_ID,
--         Topic = "Greeting",
--         Text = [[God work removing the goblins from this keep.
-- We have the situation mostly under control now,
-- though your help is always appreciated.]]
--     }

--     NPCTopic{
--         Slot = B, -- this is originally at Slot = C,
--         NPC = samsonTessNPC_ID,
--         Topic = "Arena",
--         Text = "Fortunately, most violent people take their aggressions out in the Arena, and not in the towns."
--     }
-- end

-- local function RestoreHarryMerit()
--     Game.NPC[harryMerit_ID].House = 0
--     Game.NPC[harryMerit_ID].Pic = 0
--     RemoveSafeTopicsFromNPC(harryMerit_ID)
--     Game.NPC[harryMerit_ID].Name = "Harry Merit"
    
-- end

-- function events.BeforeLoadMap()
--     RestoreSamsonTess()
--     RestoreUrok()
--     RestoreHarryMerit()
--     -- if Map.Name == NewSorpigal then
--     --     -- uroks original npc text
--     -- end
--     -- if Map.Name == houseMapName then

--     -- end
-- end

-- function events.LeaveMap() 
--     if Map.Name == houseMapName then
--         vars.decentHousePurpose = nil
--         -- removes all monsters in the map for later reuse
--         for _, m in Map.Monsters do
--             m.AIState = const.AIState.Removed
--         end
--         Map.LastRefillDay = 0
--     end
-- end


-- Party.Qbits 
-- before accepting goblinwatch
-- 183
-- 308
-- 1104
-- 1105

-- after accepting goblinwathc
-- 183
-- 308
-- 1104
-- 1105
-- 1107

-- after completing
-- 183
-- 308
-- 313
-- 1104
-- 1105
-- 1324

-- after accepting evil cults
-- 183
-- 308
-- 313
-- 1104
-- 1105
-- 1108
-- 1324
