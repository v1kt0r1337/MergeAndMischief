local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5
local NewSorpigal = "oute3.odm"
local questName = "Quest_Goblinwatch4"
local prevQuest = "Quest_Goblinwatch3"
local goblinwatchHouse = 1463
local UrokNPC_ID = 1081
local NilbogNPC_ID = 1239

local guardId = 553
local captainId = 555

-- declared here for hoisting
local MakeGoblinsFriendly


Greeting{
    NPC = NilbogNPC_ID,
    Text = "Greetings friends of Goblins. Urok speaks highly of you."
}    

NPCTopic{
    NPC = NilbogNPC_ID,
    Topic = "Finish business with Urok",
    Text = "Finish your business with Urok, then come talk to me.",
    CanShow = function() return vars.Quests[prevQuest] == "Given" end
}


Quest{
    questName,
    Slot = A,
    NPC = NilbogNPC_ID,
    Give = function()
        -- respawn all guards if dead
        for _, mon in Map.Monsters do
            if mon.Id == 553 then
                mon.HP = mon.FullHP
                mon.AIState = const.AIState.Active
            end
        end
    end,
    CanShow = function() return vars.Quests[prevQuest] == "Done" end,
    CheckDone = function()
        local allGuardsDead = true
        for _, m in Map.Monsters do
            if (m.Id == guardId or m.Id == captainId) and (m.AIState ~= const.AIState.Dead and m.AIState ~= const.AIState.Removed) then
                allGuardsDead = false
            end
        end
        return allGuardsDead
    end,
    Done = function()
        MakeGoblinsFriendly()
    end,
    Gold = 2000,
    Exp = 2000,
}.SetTexts{
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
    Award = "Friendly with the Goblins of New Sorpigal",
}

local function MakeGuardsHostile()
    local guardsMon = (guardId + 2):div(3)
    Game.HostileTxt[guardsMon][0] = 1
end

function events.MonsterKilled(mon, monIndex) 
    if Map.Name == NewSorpigal and vars.Quests[questName] == "Given" and vars.AllGuardsInNSDead ~= true and mon.Id == guardId then
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
            for i = 1, 4 do
                local m = SummonMonster(553, -19012, -15459, 1985, true)
            end
            local m = SummonMonster(555, -19012, -15459, 1985, true)
        end
    end
end


MakeGoblinsFriendly = function()
    vars.NewSorpigalGoblinsFriendly = true
    local goblinId = 550
    local goblinMon = (goblinId + 2):div(3)
    Game.HostileTxt[goblinMon][0] = 0
end


-- sound of npcs:
-- SoundDie = 2931,
-- SoundFidget = 0,
-- SoundGetHit = 2932,
-- SoundGotHit = 2932,

-- sound of goblins
--