-- ============================================================================
-- TheGoblinsStrikeBack 4
-- ============================================================================
-- Base data -------------------------------------------------------------------
local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5
local G = TheGoblinsStrikeBack
local frankFairchild_ID = 788
local willburHumphrey_ID = 789
local questAlternativeEnding = "Quest_TheGoblinsStrikeBack4_AlternativeEnding"
local questAlternativeEndingUrukTraitorAward = "Quest_TheGoblinsStrikeBack4_AlternativeUrukTraitorAward"
local goblinMonId = 550
local goblinShamanMonId = 551
local goblinKingMonId = 552
local lordNilbogMonsterId = 550
local lordNilbogPowerMonsterId = 594

-- Hoisted forward declarations
local GiveFrankSurrenderQuest
local CreateKillLordNilbogQuestBranch
local CreateMonsterLordNilbog
local MoveGoblinsIntoNewSorpigal
local PlayFightSounds
local GiveUrukTraitorAwardQuest

-- QuestStage wrapper (cosmetic grouping) -------------------------------------
local function QuestStage(name)
    return function(block)
        return block
    end
end

-- Helpers --------------------------------------------------------------------
local function Q4Done()
    return vars.Quests[G.Quest3] == "Done"
end
local function Q5Given()
    return vars.Quests[G.Quest4] == "Given"
end
local function Q5Done()
    return vars.Quests[G.Quest4] == "Done"
end
local function IsLordNilbogDead()
    return vars.LordNilbogDead == true
end
local function CanShowGoblinWon()
    return G.InNewSorpigal() and Q5Done()
end
local function CanShowGoblinWonNotWaiting()
    return CanShowGoblinWon() and svars.GoblinsWonWaitWithChanges == nil
end

-- SFX -------------------------------------------------------------------------
PlayFightSounds = function()
    Sleep(800, 1);
    evt.PlaySound(309)
    Sleep(1400, 1);
    evt.PlaySound(316)
    Sleep(1800, 1);
    evt.PlaySound(311)
end

-- ============================================================================
--  Quest stages
-- ============================================================================

-- Part 1: Start (main quest) --------------------------------------------------
QuestStage "Start" {
    Quest{
        G.Quest4,
        Slot = E,
        NPC = G.NilbogNPC,

        Give = function()
            G.ResetQuest4State()
            local goblinAttackIndexes = {}

            local function SummonGoblinAttackMonster(monId, x, y, z)
                local mon, monIndex = SummonMonster(monId, x, y, z, true)
                ConfigureQuestMonster(mon, false, 9999)
                table.insert(goblinAttackIndexes, monIndex)
            end

            SummonGoblinAttackMonster(goblinMonId, -13117, -8893, 161)
            SummonGoblinAttackMonster(goblinMonId, -10252, -9420, 161)
            SummonGoblinAttackMonster(goblinMonId, -9350, -9035, 161)
            SummonGoblinAttackMonster(goblinMonId, -9789, -8824, 161)
            SummonGoblinAttackMonster(goblinShamanMonId, -9672, -8431, 161)
            SummonGoblinAttackMonster(goblinMonId, -9376, -7920, 161)
            SummonGoblinAttackMonster(goblinMonId, -5884, -7917, 161)
            SummonGoblinAttackMonster(goblinMonId, -5947, -7622, 161)
            SummonGoblinAttackMonster(goblinMonId, -6470, -5788, 161)
            AddOrCreateMonsterEncounterIndexes(G.GoblinAttackEncounterName, goblinAttackIndexes, G.NewSorpigal)

            G.MakeGoblinsHostileToPeasants()
            PlayFightSounds()
            GiveFrankSurrenderQuest()
        end,

        CanShow = function()
            return G.InNewSorpigal() and Q4Done() and vars.AcceptKillLordNilbog ~= true
        end,

        CheckDone = function()
            return vars.FrankFairchildHasSurrendered
        end,

        Done = function()
            svars.GoblinsWonWaitWithChanges = true
            G.MakeGoblinsFriendlyToPeasants()
            Sleep2(function()
                svars.GoblinsWonWaitWithChanges = nil
                MoveGoblinsIntoNewSorpigal()
                G.MakeGoblinsFriendlyToPeasants()
            end, 1, nil, nil)
        end,

        Gold = 10000,
        Exp = 10000
    }.SetTexts {
        Quest = "Take New Sorpigal",
        FirstTopic = "Take New Sorpigal",
        TopicGiven = "Force mayor Frank Fairchild to surrender the town",
        Give = [[
[Lord Nilbogs gives you a wide smile]

Can you hear that sound? Thats my goblins taking New Sorpigal.

Force mayor Frank Fairchild to surrender the town!]],
        Undone = "Frank Fairchild has still not surrendered the town",
        Done = [[
The town is ours!

I will reign in castle, and my Urok will be the towns mayor!]],
        Award = "Helped the Goblins take New Sorpigal"
    }
}

QuestStage "Goblins Won" {
    NPCTopic {
        Topic = "Mayor Urok",
        NPC = frankFairchild_ID,
        CanShow = CanShowGoblinWon,
        Slot = E,
        Text = [[
Mayor Urok...

Well, at least he lets me do the real work while he struts around looking important.

Basically, business is as usual.

Janice, however... I think she secretly lusts after that fell beast.]]
    },
    NPCTopic {
        Topic = "The Goblins",
        Slot = E,
        CanShow = CanShowGoblinWon,
        NPC = G.JaniceNPC,
        Text = [[
Now that everyting has calmed down things are actually not that bad.

One would think that the goblins would smell, but Urok does actually smell quite good.

[Janice sighs]

Such muscular arms.]]
    },
    NPCTopic {
        Topic = "Tasks",
        Slot = A,
        NPC = G.NilbogNPC,
        CanShow = CanShowGoblinWon,
        Text = "You have done the goblins a great service. I have however no further tasks for you at this time."
    },
    Greeting {
        NPC = G.NilbogNPC,
        CanShow = CanShowGoblinWonNotWaiting,
        Text = "Greetings friends of Goblins."
    },
    NPCTopic {
        Slot = A,
        NPC = G.UrokNPC,
        CanShow = CanShowGoblinWonNotWaiting,
        Topic = "Humans",
        Text = "Humans serve goblins, Urok is the mayor now!"
    },
    NPCTopic {
        Topic = "Taxes",
        Slot = B,
        NPC = G.NilbogNPC,
        CanShow = CanShowGoblinWonNotWaiting,
        Text = "I wonder if Mayor Urok has some taxes for me."
    },
    NPCTopic {
        Topic = "Lord Nilbog",
        Slot = B,
        NPC = G.UrokNPC,
        CanShow = CanShowGoblinWonNotWaiting,
        Text = "Lord Nilbog rules Goblinwatch, I rule the town!"
    },
    NPCTopic {
        Topic = "Goblins in New Sorpigal",
        Slot = E,
        NPC = willburHumphrey_ID,
        CanShow = Q5Done,
        Text = [[
Have you heard? The goblins have taken New Sorpigal.

We are supposed to be the defenders of this land, and yet we let a bunch of goblins take over one of our towns!

What an embarrassment!

Unfortunately we already have too much trouble on our hands to deal with them at this time.]]
    }
}

-- Goblins lost (alternative ending quest) -------------------------------------
QuestStage "Goblins Lost (Alt Ending)" {
    Quest{
        questAlternativeEnding,
        Slot = E,
        NPC = frankFairchild_ID,
        CanShow = function()
            return G.InNewSorpigal() and IsLordNilbogDead()
        end,
        CheckDone = function()
            return IsLordNilbogDead()
        end,
        Gold = 10000,
        Exp = 10000
    }.SetTexts {
        Quest = "Lord Nilbog is dead",
        FirstTopic = "Lord Nilbog's demise",
        Give = "Really? You killed Lord Nilbog? I can't believe it!",
        TopicGiven = "Reward killing Lord Nilbog",
        Done = [[
Thank you for killing Lord Nilbog and saving our town!

Please accept this gold as a token of our gratitude

I herby grant you the title...

Savior of New Sorpigal!]],
        Award = "Granted the title Savior of New Sorpigal"
    },
    NPCTopic {
        Topic = "Goblins in New Sorpigal",
        Slot = E,
        NPC = willburHumphrey_ID,
        CanShow = function()
            return vars.Quests[questAlternativeEnding] == "Done"
        end,
        Text = [[
Have you heard? There was a goblin attack on the town New Sorpigal.

We are supposed to be the defenders of this land.

Luckily a group of adventurers stepped in and saved us the embarrasment.
]]
    }
}

-- ============================================================================
--  Runtime quest branches
-- ============================================================================

GiveFrankSurrenderQuest = function()
    local QuestBase = {}
    local function MyQuest(t)
        table.copy(QuestBase, t)
        QuestBase.Slot = QuestBase.Slot and QuestBase.Slot + 1
        return Quest(t)
    end
    local function SetQuestBranch(t)
        QuestBranch(t.NewBranch)
    end

    QuestNPC = frankFairchild_ID
    QuestBase = {
        Branch = "",
        Slot = E,
        Ungive = SetQuestBranch
    }

    MyQuest {
        CanShow = function()
            return G.InNewSorpigal() and Q5Given() and
                       (vars.FrankFairchildHasSurrendered ~= true and vars.AcceptKillLordNilbog ~= true)
        end,
        NewBranch = "AskFrankFairchildToSurrender",
        Texts = {
            Topic = "Surrender to Lord Nilbog",
            Ungive = [[
[Frank looks at you pleadingly]

Lord Nilbog must be stopped.

You are the only one that can help us!]]
        }
    }

    QuestBase = {
        Branch = "AskFrankFairchildToSurrender",
        Slot = E,
        Ungive = SetQuestBranch
    }
    MyQuest {
        NewBranch = "AgreeToHelpFrank",
        CanShow = function()
            return G.InNewSorpigal() and vars.FrankFairchildHasSurrendered ~= true
        end,
        Ungive = function()
            vars.AcceptKillLordNilbog = true
            CreateKillLordNilbogQuestBranch()
            QuestBranch('')
        end,
        Texts = {
            Topic = "Kill Lord Nilbog!",
            Ungive = [[
Thank you so much!

Hurry and stop the Goblins!]]
        }
    }

    MyQuest {
        NewBranch = "ForceFrankToSurrender",
        CanShow = function()
            return G.InNewSorpigal() and vars.AcceptKillLordNilbog ~= true
        end,
        Ungive = function()
            vars.FrankFairchildHasSurrendered = true
            QuestBranch('')
        end,
        Texts = {
            Topic = "Surrender!",
            Ungive = [[
[Frank looks down in defeat]

I guess I have no choice.

Please hurry up and tell Lord Nilbog that I surrender.]]
        }
    }

    NPCTopic {
        Topic = "Surrender",
        Slot = E,
        NPC = frankFairchild_ID,
        CanShow = function()
            return G.InNewSorpigal() and Q5Given() and vars.FrankFairchildHasSurrendered
        end,
        Text = "Please hurry up and tell Lord Nilbog that I surrender."
    }

    NPCTopic {
        Topic = "Kill Lord Nilbog",
        Slot = E,
        NPC = frankFairchild_ID,
        CanShow = function()
            return G.InNewSorpigal() and Q5Given() and vars.AcceptKillLordNilbog
        end,
        Text = "Hurry up and slay that fell beast."
    }
end

CreateKillLordNilbogQuestBranch = function()
    local QuestBase = {}
    local function MyQuest(t)
        table.copy(QuestBase, t)
        QuestBase.Slot = QuestBase.Slot and QuestBase.Slot + 1
        return Quest(t)
    end
    local function SetQuestBranch(t)
        QuestBranch(t.NewBranch)
    end

    QuestNPC = G.NilbogNPC
    QuestBase = {
        Branch = "",
        Slot = E,
        Ungive = SetQuestBranch
    }

    MyQuest {
        CanShow = function()
            return vars.AcceptKillLordNilbog == true
        end,
        NewBranch = "KillLordNilbog",
        Texts = {
            Topic = "Kill Lord Nilbog",
            Ungive = [[
[Lord Nilbog cackles]

The mayor wants me dead huh? Go back to him an finish the job!]]
        }
    }

    QuestBase = {
        Branch = "KillLordNilbog",
        Slot = E,
        Ungive = SetQuestBranch
    }
    MyQuest {
        NewBranch = "KillLordNilbog",
        Ungive = function()
            vars.AcceptKillLordNilbog = false
            QuestBranch('')
        end,
        Texts = {
            Topic = "Of course!",
            Ungive = "The humans will bow to goblins!"
        }
    }

    MyQuest {
        NewBranch = "KillLordNilbogYes",
        Ungive = function()
            Sleep(2500, 1)
            EnterDecentHouseMap(G.Quest4)
        end,
        Texts = {
            Topic = "No your tyranny has ended Nilbog!",
            Ungive = [[
[Lord Nilbog shrieks]

Side with humans die with humans!]]
        }
    }
end

-- ============================================================================
--  Map/NPC state mutations
-- ============================================================================

MoveGoblinsIntoNewSorpigal = function()
    -- Update trainer portraits/names (fixed duplicate local name)
    local ErikSalzburgBodyId = 847 -- expert body building
    Game.NPC[ErikSalzburgBodyId].Pic = 622
    Game.NPC[ErikSalzburgBodyId].Name = "Uglug"

    local ErikSalzburgMeditId = 857 -- expert meditation
    Game.NPC[ErikSalzburgMeditId].Pic = 550
    Game.NPC[ErikSalzburgMeditId].Name = "Ugla"

    local HaroldHessId = 818
    Game.NPC[HaroldHessId].Pic = 623
    Game.NPC[HaroldHessId].Name = "Argag"

    local HejazMawsilId = 1073
    Game.NPC[HejazMawsilId].Pic = 552
    Game.NPC[HejazMawsilId].Name = "Ula"

    local IsaoMagistrusId = 866
    Game.NPC[IsaoMagistrusId].Pic = 626
    Game.NPC[IsaoMagistrusId].Name = "Grol"

    Game.NPC[G.UrokNPC].House = Game.NPC[frankFairchild_ID].House
    Game.NPC[G.UrokNPC].Name = "Mayor Urok"
end

local function SendPartyBackToGoblinwatchApartmentEntrance()
    G.SendPartyBackToGoblinwatchApartmentEntrance()
end

-- ============================================================================
--  Event listeners (kept separate from QuestStage)
-- ============================================================================

function events.AfterLoadMap()
    if not G.InNewSorpigal() then
        return
    end

    if Q5Given() then
        GiveFrankSurrenderQuest()
        G.MakeGoblinsHostileToPeasants()
    end

    if IsLordNilbogDead() then
        Game.NPC[G.NilbogNPC].House = 0
        Game.NPC[G.UrokNPC].House = G.HouseBehindGoblinwatch
        -- (fear rationale) goblins stop attacking peasants
        G.MakeGoblinsFriendlyToPeasants()
    end

    if Q5Done() then
        MoveGoblinsIntoNewSorpigal()
        G.MakeGoblinsFriendlyToPeasants()
    end

    if (IsLordNilbogDead() and vars.Quests[questAlternativeEndingUrukTraitorAward] ~= "Done" and
        svars[questAlternativeEndingUrukTraitorAward] == nil) then

        svars[questAlternativeEndingUrukTraitorAward] = true
        GiveUrukTraitorAwardQuest()
    end

    if vars.AcceptKillLordNilbog then
        CreateKillLordNilbogQuestBranch()
    end

    if Q4Done() and not IsLordNilbogDead() then
        local shouldReplaceGuards = Q5Done()
        local replacementGoblinIndexes = {}
        for _, m in Map.Monsters do
            -- If the map refilled guards after Quest 4, resolve them for the current Quest 5 ending.
            if m.Id == G.GuardMonster and (m.AIState ~= const.AIState.Dead) then
                if shouldReplaceGuards then
                    local goblin, goblinIndex = SummonMonster(goblinKingMonId, m.X, m.Y, m.Z, true)
                    ConfigureQuestMonster(goblin, false, 9999)
                    table.insert(replacementGoblinIndexes, goblinIndex)
                end
                m.AIState = const.AIState.Removed
            end
        end
        if shouldReplaceGuards then
            AddOrCreateMonsterEncounterIndexes(G.GuardReplacementGoblinEncounterName, replacementGoblinIndexes, G.NewSorpigal)
        end
    end
end

function events.AfterLoadMap()
    if Map.Name == G.DecentHouse and vars.decentHousePurpose == G.Quest4 then
        local monsterLordNilbog = CreateMonsterLordNilbog()
        evt.Map[G.DecentHouseExitDoorEventId] = function()
            if monsterLordNilbog.HP > 0 then
                Game.ShowStatusText(Game.MonstersTxt[monsterLordNilbog.Id].Name .. " is blocking your escape!")
            else
                SendPartyBackToGoblinwatchApartmentEntrance()
            end
        end
    end
end

function events.MonsterKilled(mon)
    if Map.Name == G.DecentHouse and NamedMonsterEncounterContainsMonster(G.LordNilbogEncounterName, mon, G.DecentHouse) then
        vars.LordNilbogDead = true
        vars.NewSorpigalGoblinsFriendly = false
        vars.AcceptKillLordNilbog = nil
        -- TODO: further test if this has unwanted side effects
        vars.Quests[G.Quest4] = nil
    end
end

function events.MonsterSpriteScale(t)
    if Map.Name == G.DecentHouse and NamedMonsterEncounterContainsMonster(G.LordNilbogEncounterName, t.Monster, G.DecentHouse) then
        t.Scale = 53248 -- 1.25 scale, hardcoded to prevent conflicts
    end
end

-- ============================================================================
--  One-off follow-up quest (Uruk 'Traitor' award) – created on demand
-- ============================================================================

GiveUrukTraitorAwardQuest = function()
    RemoveAllTopicsFromNPC(G.UrokNPC)

    Quest{
        questAlternativeEndingUrukTraitorAward,
        Slot = E,
        NPC = G.UrokNPC,
        CanShow = function()
            return G.InNewSorpigal() and IsLordNilbogDead()
        end,
        CheckDone = function()
            return IsLordNilbogDead()
        end,
        Done = function()
            local goblinKing = goblinKingMonId
            local revengeIndexes = {}
            local firstGoblin, firstGoblinIndex = SummonMonster(goblinKing, -2891, -19562, 0, true)
            ConfigureQuestMonster(firstGoblin, true, 0)
            table.insert(revengeIndexes, firstGoblinIndex)
            local secondGoblin, secondGoblinIndex = SummonMonster(goblinKing, -3059, -19698, 0, true)
            ConfigureQuestMonster(secondGoblin, true, 0)
            table.insert(revengeIndexes, secondGoblinIndex)
            local thirdGoblin, thirdGoblinIndex = SummonMonster(goblinKing, -3159, -19898, 0, true)
            ConfigureQuestMonster(thirdGoblin, true, 0)
            table.insert(revengeIndexes, thirdGoblinIndex)
            local fourthGoblin, fourthGoblinIndex = SummonMonster(goblinKing, -3273, -20352, 0, true)
            ConfigureQuestMonster(fourthGoblin, true, 0)
            table.insert(revengeIndexes, fourthGoblinIndex)
            AddOrCreateMonsterEncounterIndexes(G.TraitorRevengeEncounterName, revengeIndexes, G.NewSorpigal)
        end
    }.SetTexts {
        Quest = "Traitor!",
        FirstTopic = "Traitor!",
        Give = [[
You betrayed us!]],
        TopicGiven = "Revenge!",
        Undone = "The other goblins will know of this!",
        Done = [[
You are no friend of goblins!

The other goblins will know of this!]],
        Award = "Betrayed the Goblins of New Sorpigal"
    }
end

-- ============================================================================
--  Boss setup (Lord Nilbog)
-- ============================================================================

-- Public for MAW workaround
function Quest_TheGoblinsStrikeBack4_MonsterLordNilbog(monsterLordNilbog, resetPowerHP)
    local ogreChieftain = Game.MonstersTxt[lordNilbogPowerMonsterId]

    TrackMonsterEncounterMonster(G.LordNilbogEncounterName, monsterLordNilbog, G.DecentHouse)

    if monsterLordNilbog.AIState ~= const.AIState.Dead then
        ApplyMonsterPowerFromMonster(monsterLordNilbog, ogreChieftain, resetPowerHP ~= false)
        ConfigureQuestMonster(monsterLordNilbog, true, 0)
    end

    -- Cosmetic (resets on map leave)
    Game.MonstersTxt[lordNilbogMonsterId].Name = "Lord Nilbog"

    G.MakeGoblinsHostileToPlayer()
    return monsterLordNilbog
end

CreateMonsterLordNilbog = function()
    local monsterLordNilbog = FindMonsterEncounterMonster(G.LordNilbogEncounterName, G.DecentHouse)
    local resetPowerHP = false
    for _, m in Map.Monsters do
        -- NOTE: assumes no other monsters share Lord Nilbog's index
        if monsterLordNilbog == nil and m.Id == lordNilbogMonsterId and m.AIState ~= const.AIState.Removed then
            monsterLordNilbog = m
            TrackMonsterEncounterMonster(G.LordNilbogEncounterName, monsterLordNilbog, G.DecentHouse)
        end
    end
    if monsterLordNilbog == nil then
        monsterLordNilbog = SummonMonster(lordNilbogMonsterId, -115, 55, 1, true)
        resetPowerHP = true
        TrackMonsterEncounterMonster(G.LordNilbogEncounterName, monsterLordNilbog, G.DecentHouse)
    end
    return Quest_TheGoblinsStrikeBack4_MonsterLordNilbog(monsterLordNilbog, resetPowerHP)
end
