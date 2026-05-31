local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5
local NewSorpigal = "oute3.odm"
local Quest_Goblinwatch4 = "Quest_Goblinwatch4"
local Quest_Goblinwatch3 = "Quest_Goblinwatch3"
local GuardReinforcementsEncounterName = "Quest_Goblinwatch4_GuardReinforcements"
local goblinwatchHouse = 1463
local urokNPC_ID = 1081
local nilbogNPC_ID = 111

local guardId = 553
local captainId = 555

local function MakeGuardsHostile()
    local guardsMon = (guardId + 2):div(3)
    Game.HostileTxt[guardsMon][0] = 1
end

local function MakeGoblinsFriendly()
    vars.NewSorpigalGoblinsFriendly = true
    local goblinId = 550
    local goblinMon = (goblinId + 2):div(3)
    Game.HostileTxt[goblinMon][0] = 0
end

Quest{
    Quest_Goblinwatch4,
    Slot = E,
    NPC = nilbogNPC_ID,
    Give = function()
        -- respawn all guards if dead
        for _, mon in Map.Monsters do
            if mon.Id == 553 then
                mon.HP = mon.FullHP
                mon.AIState = const.AIState.Active
            end
        end
    end,
    CanShow = function()
        return Map.Name == NewSorpigal and vars.Quests[Quest_Goblinwatch3] == "Done"
    end,
    CheckDone = function()
        local reinforcementsEncounter = GetMonsterEncounter(GuardReinforcementsEncounterName, NewSorpigal)
        if vars.AllGuardsInNSDead == true and reinforcementsEncounter ~= nil then
            if MonsterEncounterHasAnyActive(reinforcementsEncounter) == true then
                return false
            end
        end

        local allGuardsDead = true
        for _, m in Map.Monsters do
            if (m.Id == guardId or m.Id == captainId) and
                (m.AIState ~= const.AIState.Dead and m.AIState ~= const.AIState.Removed) then
                allGuardsDead = false
            end
        end
        return allGuardsDead
    end,
    Done = function()
        MakeGoblinsFriendly()
        MarkMonsterEncounterForRemoval(GuardReinforcementsEncounterName, NewSorpigal)
    end,
    Gold = 2000,
    Exp = 2000
}.SetTexts {
    Quest = "Kill the guards of New Sorpigal",
    FirstTopic = "I got work for you",
    TopicGiven = "Kill the guards of New Sorpigal",
    Give = [[
Goblinwatch was made by humans to watch goblins, now we watch them.

Watching the humans is not enough. The big men at Castle Ironfist are busy with their war, its time to strike!

Take out the guards of New Sorpigal. 

I would do it myself, but I got a bad knee.]],
    Undone = "There are still guards left in New Sorpigal",
    Done = [[
Hah! It got a bit heated there in the end.

You have shown yourself a true friend of goblins. 
I will rein in the other goblins. 

The other goblins in New Sorpigal will no longer attack you unprovoked.]],
    Award = "Befriended the Goblins of New Sorpigal"
}

function events.MonsterKilled(mon, monIndex)
    if Map.Name == NewSorpigal and vars.Quests[Quest_Goblinwatch4] == "Given" and vars.AllGuardsInNSDead ~= true and
        mon.Id == guardId then
        MakeGuardsHostile()
        -- check if all guards are dead or removed
        local guardsLeft = 0
        for i, m in Map.Monsters do
            if i == monIndex then
                -- skip
            elseif m.Id == guardId and (m.AIState ~= const.AIState.Dead and m.AIState ~= const.AIState.Removed) then
                guardsLeft = guardsLeft + 1
            end
        end
        if guardsLeft == 0 then
            Message("All the town guards are dead.")
            vars.AllGuardsInNSDead = true
            local reinforcementIndexes = {}
            for i = 1, 4 do
                local _, guardIndex = SummonMonster(553, -19012, -15459, 1985, true)
                table.insert(reinforcementIndexes, guardIndex)
            end
            local _, captainIndex = SummonMonster(555, -19012, -15459, 1985, true)
            table.insert(reinforcementIndexes, captainIndex)
            CreateAndSetMonsterEncounterFromIndexes(GuardReinforcementsEncounterName, reinforcementIndexes, NewSorpigal)
        end
    end
end

function events.AfterLoadMap(WasInGame)
    if Map.Name == NewSorpigal then
        if vars.Quests[Quest_Goblinwatch4] == "Given" then
            -- forgot to document why sleep, but I think there was a race condition
            Sleep2(function()
                MakeGuardsHostile()
            end, 2, nil, nil)
        end
        if vars.NewSorpigalGoblinsFriendly then
            MakeGoblinsFriendly()
        end
    end
end
