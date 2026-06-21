-- ============================================================================
--  TheGoblinsStrikeBack 2 Quest
-- ============================================================================
-- Slots
local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5
local G = TheGoblinsStrikeBack
local farmerToddMonsterId = 577
local farmerToddPowerMonsterId = 588
local farmerToddNPC_ID = 836
local farmerToddEncounterName = "Quest_TheGoblinsStrikeBack2_FarmerTodd"

-- Hoisted forward declarations
local Quest_TheGoblinsStrikeBack2_CreateTodd
local MakeNilbogToLordNPC

-- cosmetic wrapper
local function QuestStage(name)
    return function(block)
        return block
    end
end

-- ============================================================================
-- Quest definition
-- ============================================================================

Quest{
    G.Quest2,
    NPC = G.UrokNPC,
    Give = function()
        vars.FarmerToddDead = nil
        local mon, monIndex = SummonMonster(farmerToddMonsterId, -1076, -5762, 856, true)
        CreateAndSetMonsterEncounterFromIndexes(farmerToddEncounterName, {monIndex}, G.NewSorpigal)
        Quest_TheGoblinsStrikeBack2_CreateTodd(mon, true)
    end,
    CheckDone = function()
        return vars.FarmerToddDead == true
    end,
    CanShow = function()
        return G.InNewSorpigal() and vars.Quests[G.Quest1] == "Done" and Game.NPC[G.UrokNPC].House ==
                   G.GoblinwatchHouse and svars.HasNotLeftUrok == nil
    end,
    Exp = 2000,
    Gold = 2000,
    Slot = E,
    Done = function()
        vars.FarmerToddDead = nil
        MarkMonsterEncounterForRemoval(farmerToddEncounterName, G.NewSorpigal)
    end
}.SetTexts {
    Quest = "Kill Farmer Todd",
    FirstTopic = "Evil gossiper",
    TopicGiven = "Evil gossiper",
    Give = [[
There is a man speaking with false tongues on us goblins!

Kill him for us!

His name is Farmer Todd and he was last seen by the scouts close to the sword stuck in stone here in New Sorpigal.]],
    Undone = [[
Farmer Todd is still around spreading his false tales!

He was last seen by the scouts close to the sword stuck in stone here in New Sorpigal.]],
    Done = [[
Scouts say Farmer Todd is dead. Good!

Urok gives you gold.]]
}

-- ============================================================================
-- Quest stages
-- ============================================================================

QuestStage "Given" {
    NPCTopic {
        Slot = A,
        NPC = farmerToddNPC_ID,
        CanShow = function()
            return G.InNewSorpigal() and vars.Quests[G.Quest2] == "Given"
        end,
        Topic = "Goblins",
        Text = [[
They might look scary, but in reality they are really meek.

One of them tried to jump me the other day.

I just kicked it in the knee and it hobbled away crying.]]
    },
    NPCTopic {
        NPC = G.NilbogNPC,
        Slot = A,
        Topic = "Finish business with Urok",
        CanShow = function()
            return G.InNewSorpigal() and (vars.Quests[G.Quest2] == "Given" or vars.FarmerToddDead == true)
        end,
        Text = "Finish your business with Urok, then come talk to me."
    },
    Greeting {
        NPC = farmerToddNPC_ID,
        CanShow = function()
            return G.InNewSorpigal() and Game.NPC[farmerToddNPC_ID].Name == "Farmer Todd"
        end,
        Text = "Hi there"
    }
}

QuestStage "Done" {
    NPCTopic {
        Slot = A,
        NPC = G.UrokNPC,
        CanShow = function()
            return G.InNewSorpigal() and (vars.Quests[G.Quest2] == "Done" or vars.FarmerToddDead == true)
        end,
        Topic = "Humans",
        Text = [[
[Urok laughs eerily]

Humans think they are safe in their town, but Lord Nilbog and Urok will show them!]]
    },
    NPCTopic {
        Topic = "Lord Nilbog",
        Slot = B,
        Text = "The lord of Goblinwatch",
        CanShow = function()
            return G.InNewSorpigal() and (vars.Quests[G.Quest2] == "Done" or vars.FarmerToddDead == true)
        end,
        NPC = G.UrokNPC
    },
    Greeting {
        NPC = G.NilbogNPC,
        CanShow = function()
            return G.InNewSorpigal() and (vars.Quests[G.Quest2] == "Done" or vars.FarmerToddDead == true)
        end,
        Text = "Greetings friends of Goblins. Urok speaks highly of you."
    },
    NPCTopic {
        Topic = "Lord Nilbog",
        Slot = B,
        Text = "Speak with Lord Nilbog for more work.",
        CanShow = function()
            return G.InNewSorpigal() and vars.Quests[G.Quest2] == "Done"
        end,
        NPC = G.UrokNPC
    }
}

-- ============================================================================
-- Event Handlers
-- ============================================================================

function events.AfterLoadMap()
    if G.InNewSorpigal() then
        if vars.Quests[G.Quest2] == "Given" then
            Quest_TheGoblinsStrikeBack2_CreateTodd(nil, false)
        end
        if vars.FarmerToddDead or vars.Quests[G.Quest2] == 'Done' then
            MakeNilbogToLordNPC()
        end
    end
end

function events.MonsterKilled(mon)
    if G.InNewSorpigal() and MonsterEncounterContainsMonster(GetMonsterEncounter(farmerToddEncounterName, G.NewSorpigal), mon) == true then
        vars.FarmerToddDead = true
        MakeNilbogToLordNPC()
    end
end

-- ============================================================================
--  NPC helpers
-- ============================================================================

MakeNilbogToLordNPC = function()
    G.MakeNilbogToLordNPC()
end

function Quest_TheGoblinsStrikeBack2_CreateTodd(mon, resetPowerHP)
    if mon == nil then
        ForEachMonsterEncounter(GetMonsterEncounter(farmerToddEncounterName, G.NewSorpigal), function(_, encounterMon)
            mon = encounterMon
        end)
    end

    if mon == nil then
        for _, m in Map.Monsters do
            if m.Id == farmerToddMonsterId and m.NPC_ID == farmerToddNPC_ID then
                mon = m
                break
            end
        end
        if mon ~= nil and GetMonsterEncounter(farmerToddEncounterName, G.NewSorpigal) == nil then
            CreateAndSetMonsterEncounterFromIndexes(farmerToddEncounterName, {mon:GetIndex()}, G.NewSorpigal)
        end
    end

    if mon == nil then
        return
    end

    if mon.AIState == const.AIState.Removed then
        return
    end

    mon.AIType = 3
    if mon.AIState ~= const.AIState.Dead then
        ApplyMonsterPowerFromMonster(mon, Game.MonstersTxt[farmerToddPowerMonsterId], resetPowerHP ~= false)
        ConfigureQuestMonster(mon, true, 0)
    end

    -- overwrite NPC identity
    local monTxt = Game.MonstersTxt[farmerToddMonsterId]
    monTxt.Name = "Farmer Todd"
    mon.NPC_ID = farmerToddNPC_ID
    Game.NPC[farmerToddNPC_ID].Name = "Farmer Todd"
    Game.NPC[farmerToddNPC_ID].Pic = 1
    Game.NPC[farmerToddNPC_ID].Profession = 0
end
