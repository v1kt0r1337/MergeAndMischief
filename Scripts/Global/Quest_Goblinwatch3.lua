-- ============================================================================
--  Goblinwatch 3 Quest
-- ============================================================================
-- Slots
local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5

-- IDs
local goblinwatchHouse = 1463
local urokNPC_ID = 1081
local FarmerToddMonsterTxtId = 577 -- Game.MonstersTxt[FarmerToddMonsterTxtId]
local FarmerToddNPC_ID = 836
local nilbogNPC_ID = 111

local NewSorpigal = "oute3.odm"

-- Quest IDs
local Quest_Goblinwatch3 = "Quest_Goblinwatch3"
local Quest_Goblinwatch2 = "Quest_Goblinwatch2"

-- Hoisted forward declarations
local Quest_Goblinwatch3_CreateTodd
local MakeNilbogToLordNPC

-- cosmetic wrapper
local function QuestStage(name)
    return function(block)
        return block
    end
end

local function InNewSorpigal()
    return Map.Name == NewSorpigal
end

-- ============================================================================
-- Quest definition
-- ============================================================================

Quest{
    Quest_Goblinwatch3,
    NPC = urokNPC_ID,
    Give = function()
        local mon = SummonMonster(FarmerToddMonsterTxtId, -1076, -5762, 856, true)
        Quest_Goblinwatch3_CreateTodd(mon)
    end,
    CheckDone = function()
        return vars.FarmerToddDead == true
    end,
    CanShow = function()
        return InNewSorpigal() and vars.Quests[Quest_Goblinwatch2] == "Done" and Game.NPC[urokNPC_ID].House ==
                   goblinwatchHouse and svars.HasNotLeftUrok == nil
    end,
    Exp = 2000,
    Gold = 2000,
    Slot = E,
    Done = function()
        vars.FarmerToddDead = nil
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
The scouts speak of his demise. Good!

Take this pouch of gold as reward.]]
}

-- ============================================================================
-- Quest stages
-- ============================================================================

QuestStage "Given" {
    NPCTopic {
        Slot = A,
        NPC = FarmerToddNPC_ID,
        CanShow = function()
            return InNewSorpigal() and vars.Quests[Quest_Goblinwatch3] == "Given"
        end,
        Topic = "Goblins",
        Text = [[
They might look scary, but in reality they are really meek.

One of them tried to jump me the other day.

I just kicked it in the knee and it hobbled away crying.]]
    },
    NPCTopic {
        NPC = nilbogNPC_ID,
        Slot = A,
        Topic = "Finish business with Urok",
        CanShow = function()
            return InNewSorpigal() and (vars.Quests[Quest_Goblinwatch3] == "Given" or vars.FarmerToddDead == true)
        end,
        Text = "Finish your business with Urok, then come talk to me."
    },
    Greeting {
        NPC = FarmerToddNPC_ID,
        CanShow = function()
            return InNewSorpigal() and Game.NPC[FarmerToddNPC_ID].Name == "Farmer Todd"
        end,
        Text = "Hi there"
    }
}

QuestStage "Done" {
    NPCTopic {
        Slot = A,
        NPC = urokNPC_ID,
        CanShow = function()
            return InNewSorpigal() and (vars.Quests[Quest_Goblinwatch3] == "Done" or vars.FarmerToddDead == true)
        end,
        Topic = "Humans",
        Text = [[
[Urok laughts eerily]

Humans think they are safe in their town, but Lord Nilbog and Urok will show them!]]
    },
    NPCTopic {
        Topic = "Lord Nilbog",
        Slot = B,
        Text = "The lord of Goblinwatch",
        CanShow = function()
            return InNewSorpigal() and (vars.Quests[Quest_Goblinwatch3] == "Done" or vars.FarmerToddDead == true)
        end,
        NPC = urokNPC_ID
    },
    Greeting {
        NPC = nilbogNPC_ID,
        CanShow = function()
            return InNewSorpigal() and (vars.Quests[Quest_Goblinwatch3] == "Done" or vars.FarmerToddDead == true)
        end,
        Text = "Greetings friends of Goblins. Urok speaks highly of you."
    },
    NPCTopic {
        Topic = "Lord Nilbog",
        Slot = B,
        Text = "Speak with Lord Nilbog for more work.",
        CanShow = function()
            return InNewSorpigal() and vars.Quests[Quest_Goblinwatch3] == "Done"
        end,
        NPC = urokNPC_ID
    }
}

-- ============================================================================
-- Event Handlers
-- ============================================================================

function events.AfterLoadMap(WasInGame)
    if InNewSorpigal() then
        if vars.Quests[Quest_Goblinwatch3] == "Given" then
            Quest_Goblinwatch3_CreateTodd()
        end
        if vars.FarmerToddDead or vars.Quests[Quest_Goblinwatch3] == 'Done' then
            MakeNilbogToLordNPC()
        end
    end
end

function events.MonsterKilled(mon)
    if InNewSorpigal() and Game.MonstersTxt[mon.Id].Name == "Farmer Todd" then
        vars.FarmerToddDead = true
        MakeNilbogToLordNPC()
    end
end

-- ============================================================================
--  NPC helpers
-- ============================================================================

MakeNilbogToLordNPC = function()
    Game.NPC[nilbogNPC_ID].House = goblinwatchHouse
    Game.NPC[nilbogNPC_ID].Pic = 624
    Game.NPC[nilbogNPC_ID].Name = "Lord Nilbog"
end

function Quest_Goblinwatch3_CreateTodd(mon)
    if mon == nil then
        for _, m in Map.Monsters do
            -- TODO: assumes no duplicate monsters with Farmer Todd id
            if m.Id == FarmerToddMonsterTxtId then
                mon = m
                break
            end
        end
    end

    if mon.AIState == const.AIState.Removed then
        return
    end

    local masterSwordsmanMonsterTxtId = 588
    local masterSwordsman = Game.MonstersTxt[masterSwordsmanMonsterTxtId]

    mon.AIType = 3
    if mon.AIState ~= const.AIState.Dead then
        mon.HP = masterSwordsman.FullHP
    end
    mon.FullHP = masterSwordsman.FullHP
    mon.Exp = masterSwordsman.Exp
    mon.Attack1.DamageAdd = masterSwordsman.Attack1.DamageAdd
    mon.Attack1.DamageDiceSides = masterSwordsman.Attack1.DamageDiceSides
    mon.Attack1.DamageDiceCount = masterSwordsman.Attack1.DamageDiceCount

    -- overwrite NPC identity
    local monTxt = Game.MonstersTxt[FarmerToddMonsterTxtId]
    monTxt.Name = "Farmer Todd"
    mon.NPC_ID = FarmerToddNPC_ID
    Game.NPC[FarmerToddNPC_ID].Name = "Farmer Todd"
    Game.NPC[FarmerToddNPC_ID].Pic = 1
    Game.NPC[FarmerToddNPC_ID].Profession = 0
end
