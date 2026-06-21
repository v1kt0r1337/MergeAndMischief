local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5
local G = TheGoblinsStrikeBack
local captainMonId = 555

Quest{
    G.Quest3,
    Slot = E,
    NPC = G.NilbogNPC,
    Give = function()
        G.ResetQuest3State()
        -- respawn all guards if dead
        for _, mon in Map.Monsters do
            if mon.Id == G.GuardMonster then
                mon.HP = mon.FullHP
                mon.AIState = const.AIState.Active
            end
        end
    end,
    CanShow = function()
        return Map.Name == G.NewSorpigal and vars.Quests[G.Quest2] == "Done"
    end,
    CheckDone = function()
        local reinforcementsEncounter = GetMonsterEncounter(G.GuardReinforcementsEncounterName, G.NewSorpigal)
        if vars.AllGuardsInNSDead == true and reinforcementsEncounter ~= nil then
            if MonsterEncounterHasAnyActive(reinforcementsEncounter) == true then
                return false
            end
        end

        local allGuardsDead = true
        for _, m in Map.Monsters do
            if (m.Id == G.GuardMonster or m.Id == captainMonId) and
                (m.AIState ~= const.AIState.Dead and m.AIState ~= const.AIState.Removed) then
                allGuardsDead = false
            end
        end
        return allGuardsDead
    end,
    Done = function()
        G.MakeGoblinsFriendlyToPlayer()
        MarkMonsterEncounterForRemoval(G.GuardReinforcementsEncounterName, G.NewSorpigal)
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
    if Map.Name == G.NewSorpigal and vars.Quests[G.Quest3] == "Given" and vars.AllGuardsInNSDead ~= true and
        mon.Id == G.GuardMonster then
        G.MakeGuardsHostileToPlayer()
        -- check if all guards are dead or removed
        local guardsLeft = 0
        for i, m in Map.Monsters do
            if i == monIndex then
                -- skip
            elseif m.Id == G.GuardMonster and (m.AIState ~= const.AIState.Dead and m.AIState ~= const.AIState.Removed) then
                guardsLeft = guardsLeft + 1
            end
        end
        if guardsLeft == 0 then
            Message("All the town guards are dead.")
            vars.AllGuardsInNSDead = true
            local reinforcementIndexes = {}
            for i = 1, 4 do
                local guard, guardIndex = SummonMonster(G.GuardMonster, -19012, -15459, 1985, true)
                ConfigureQuestMonster(guard, true, 0)
                table.insert(reinforcementIndexes, guardIndex)
            end
            local captain, captainIndex = SummonMonster(captainMonId, -19012, -15459, 1985, true)
            ConfigureQuestMonster(captain, true, 0)
            table.insert(reinforcementIndexes, captainIndex)
            CreateAndSetMonsterEncounterFromIndexes(G.GuardReinforcementsEncounterName, reinforcementIndexes, G.NewSorpigal)
        end
    end
end

function events.AfterLoadMap(WasInGame)
    if Map.Name == G.NewSorpigal then
        if vars.Quests[G.Quest3] == "Given" then
            -- forgot to document why sleep, but I think there was a race condition
            Sleep2(function()
                G.MakeGuardsHostileToPlayer()
            end, 2, nil, nil)
        end
        if vars.NewSorpigalGoblinsFriendly then
            G.MakeGoblinsFriendlyToPlayer()
            Sleep2(function()
                if Map.Name == G.NewSorpigal and vars.NewSorpigalGoblinsFriendly then
                    G.MakeGoblinsFriendlyToPlayer()
                end
            end, 2, nil, nil)
        end
    end
end
