-- ============================================================================
-- Goblinwatch 5 
-- ============================================================================
-- Base data -------------------------------------------------------------------
local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5
local goblinwatchHouse = 1463
local nilbogNPC_ID = 111
local urokNPC_ID = 1081
local janiceNPC_ID = 1076
local frankFairchild_ID = 788
local houseBehindGoblinwatch = 1413
local NewSorpigal = "oute3.odm"

local Quest_Goblinwatch5 = "Quest_Goblinwatch5"
local Quest_Goblinwatch4 = "Quest_Goblinwatch4"
local questAlternativeEnding = "Quest_Goblinwatch5_AlternativeEnding"
local questAlternativeEndingUrukTraitorAward = "Quest_Goblinwatch5_AlternativeUrukTraitorAward"
local willburHumphrey_ID = 789

local decenthouseMapName = "decenthouse.blv"
local decenthouseExitDoorEventId = 5

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
local function InNewSorpigal()
    return Map.Name == NewSorpigal
end
local function Q4Done()
    return vars.Quests[Quest_Goblinwatch4] == "Done"
end
local function Q5Given()
    return vars.Quests[Quest_Goblinwatch5] == "Given"
end
local function Q5Done()
    return vars.Quests[Quest_Goblinwatch5] == "Done"
end
local function IsLordNilbogDead()
    return vars.LordNilbogDead == true
end
local function CanShowGoblinWon()
    return InNewSorpigal() and Q5Done()
end
local function CanShowGoblinWonNotWaiting()
    return CanShowGoblinWon() and svars.GoblinsWonWaitWithChanges == nil
end

-- Hostility helpers --------------------------------------------------------
local function MakeGoblinsHostile()
    -- goblins hostile to player
    local goblinId = 550
    local goblinMon = (goblinId + 2):div(3)
    Game.HostileTxt[goblinMon][0] = 4
end

local function MakeGoblinsHostileToPeasants()
    local goblinMonId = 550
    local goblinMon = (goblinMonId + 2):div(3)
    local peasantMon = (595 + 2):div(3)
    Game.HostileTxt[goblinMon][peasantMon] = 4
end

-- This one seems bugged, doesn't work?
local function MakeGoblinsFriendlyToPeasants()
    local goblinId = 550
    local goblinMon = (goblinId + 2):div(3)
    local peasantMon = (595 + 2):div(3)
    Game.HostileTxt[goblinMon][peasantMon] = 0
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
        Quest_Goblinwatch5,
        Slot = E,
        NPC = nilbogNPC_ID,

        Give = function()
            local goblinMonId = 550
            local goblinShamanMonId = 551

            SummonMonster(goblinMonId, -13117, -8893, 161, true)
            SummonMonster(goblinMonId, -10252, -9420, 161, true)
            SummonMonster(goblinMonId, -9350, -9035, 161, true)
            SummonMonster(goblinMonId, -9789, -8824, 161, true)
            SummonMonster(goblinShamanMonId, -9672, -8431, 161, true)
            SummonMonster(goblinMonId, -9376, -7920, 161, true)
            SummonMonster(goblinMonId, -5884, -7917, 161, true)
            SummonMonster(goblinMonId, -5947, -7622, 161, true)
            SummonMonster(goblinMonId, -6470, -5788, 161, true)

            MakeGoblinsHostileToPeasants()
            PlayFightSounds()
            GiveFrankSurrenderQuest()
        end,

        CanShow = function()
            return InNewSorpigal() and Q4Done() and vars.AcceptKillLordNilbog ~= true
        end,

        CheckDone = function()
            return vars.FrankFairchildHasSurrendered
        end,

        Done = function()
            svars.GoblinsWonWaitWithChanges = true
            Sleep2(function()
                svars.GoblinsWonWaitWithChanges = nil
                MoveGoblinsIntoNewSorpigal()
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
        NPC = janiceNPC_ID,
        Text = [[
Now that everyting has calmed down things are actually not that bad.

One would think that the goblins would smell, but Urok does actually smell quite good.

[Janice sighs]

Such muscular arms.]]
    },
    NPCTopic {
        Topic = "Tasks",
        Slot = A,
        NPC = nilbogNPC_ID,
        CanShow = CanShowGoblinWon,
        Text = "You have done the goblins a great service. I have however no further tasks for you at this time."
    },
    Greeting {
        NPC = nilbogNPC_ID,
        CanShow = CanShowGoblinWonNotWaiting,
        Text = "Greetings friends of Goblins."
    },
    NPCTopic {
        Slot = A,
        NPC = urokNPC_ID,
        CanShow = CanShowGoblinWonNotWaiting,
        Topic = "Humans",
        Text = "Humans serve goblins, Urok is the mayor now!"
    },
    NPCTopic {
        Topic = "Taxes",
        Slot = B,
        NPC = nilbogNPC_ID,
        CanShow = CanShowGoblinWonNotWaiting,
        Text = "I wonder if Mayor Urok has some taxes for me."
    },
    NPCTopic {
        Topic = "Lord Nilbog",
        Slot = B,
        NPC = urokNPC_ID,
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
            return InNewSorpigal() and IsLordNilbogDead()
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
            return vars.Quests[Quest_Goblinwatch5_AlternativeEnding] == "Done"
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
            return InNewSorpigal() and Q5Given() and
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
            return InNewSorpigal() and vars.FrankFairchildHasSurrendered ~= true
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
            return InNewSorpigal() and vars.AcceptKillLordNilbog ~= true
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
            return InNewSorpigal() and Q5Given() and vars.FrankFairchildHasSurrendered
        end,
        Text = "Please hurry up and tell Lord Nilbog that I surrender."
    }

    NPCTopic {
        Topic = "Kill Lord Nilbog",
        Slot = E,
        NPC = frankFairchild_ID,
        CanShow = function()
            return InNewSorpigal() and Q5Given() and vars.AcceptKillLordNilbog
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

    QuestNPC = nilbogNPC_ID
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
            EnterDecentHouseMap(Quest_Goblinwatch5)
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

    Game.NPC[urokNPC_ID].House = Game.NPC[frankFairchild_ID].House
    Game.NPC[urokNPC_ID].Name = "Mayor Urok"
end

local function SendPartyBackToGoblinwatchApartmentEntrance()
    evt.PlaySound(7) -- slam door sound
    evt.MoveToMap {
        Name = NewSorpigal,
        X = -18303,
        Y = -15535,
        Z = 1985,
        Direction = 1538
    }
end

-- ============================================================================
--  Event listeners (kept separate from QuestStage)
-- ============================================================================

function events.AfterLoadMap()
    if not InNewSorpigal() then
        return
    end

    if Q5Given() then
        GiveFrankSurrenderQuest()
        MakeGoblinsHostileToPeasants()
    end

    if IsLordNilbogDead() then
        Game.NPC[nilbogNPC_ID].House = 0
        Game.NPC[urokNPC_ID].House = houseBehindGoblinwatch
        -- (fear rationale) goblins stop attacking peasants
        MakeGoblinsFriendlyToPeasants()
    end

    if Q5Done() then
        MoveGoblinsIntoNewSorpigal()
        MakeGoblinsFriendlyToPeasants()
    end

    if (IsLordNilbogDead() and vars.Quests[questAlternativeEndingUrukTraitorAward] ~= "Done" and
        svars[questAlternativeEndingUrukTraitorAward] == nil) then

        svars[questAlternativeEndingUrukTraitorAward] = true
        GiveUrukTraitorAwardQuest()
    end

    if vars.AcceptKillLordNilbog then
        CreateKillLordNilbogQuestBranch()
    end

    if Q5Done() then
        local guardId, goblinMonId = 553, 550
        for _, m in Map.Monsters do
            -- If the map refilled guards, convert them to goblins
            if m.Id == guardId and (m.AIState ~= const.AIState.Dead) then
                SummonMonster(goblinMonId, m.X, m.Y, m.Z, true)
                m.AIState = const.AIState.Removed
            end
        end
    end
end

function events.AfterLoadMap()
    if Map.Name == decenthouseMapName and vars.decentHousePurpose == Quest_Goblinwatch5 then
        local monsterLordNilbog = CreateMonsterLordNilbog()
        evt.Map[decenthouseExitDoorEventId] = function()
            if monsterLordNilbog.HP > 0 then
                Game.ShowStatusText(Game.MonstersTxt[monsterLordNilbog.Id].Name .. " is blocking your escape!")
            else
                SendPartyBackToGoblinwatchApartmentEntrance()
            end
        end
    end
end

function events.MonsterKilled(mon)
    if Map.Name == decenthouseMapName and Game.MonstersTxt[mon.Id].Name == "Lord Nilbog" then
        vars.LordNilbogDead = true
        vars.NewSorpigalGoblinsFriendly = false
        -- TODO: further test if this has unwanted side effects
        vars.Quests[Quest_Goblinwatch5] = nil
    end
end

function events.MonsterSpriteScale(t)
    local LordNilbogMonsterTxtId = 550
    if t.Monster.Id == LordNilbogMonsterTxtId and Game.MonstersTxt[LordNilbogMonsterTxtId].Name == "Lord Nilbog" then
        t.Scale = 53248 -- 1.25 scale, hardcoded to prevent conflicts
    end
end

-- ============================================================================
--  One-off follow-up quest (Uruk 'Traitor' award) – created on demand
-- ============================================================================

GiveUrukTraitorAwardQuest = function()
    RemoveAllTopicsFromNPC(urokNPC_ID)

    Quest{
        questAlternativeEndingUrukTraitorAward,
        Slot = E,
        NPC = urokNPC_ID,
        CanShow = function()
            return InNewSorpigal() and IsLordNilbogDead()
        end,
        CheckDone = function()
            return IsLordNilbogDead()
        end,
        Done = function()
            local goblinKing = 552
            SummonMonster(goblinKing, -2891, -19562, 0, true)
            SummonMonster(goblinKing, -3059, -19698, 0, true)
            SummonMonster(goblinKing, -3159, -19898, 0, true)
            SummonMonster(goblinKing, -3273, -20352, 0, true)
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
function Quest_Goblinwatch5_MonsterLordNilbog(monsterLordNilbog)
    local LordNilbogMonsterTxtId = 550
    local ogreChieftain = Game.MonstersTxt[594]

    if monsterLordNilbog.AIState ~= const.AIState.Dead then
        monsterLordNilbog.HP = ogreChieftain.FullHP
    end
    monsterLordNilbog.FullHP = ogreChieftain.FullHP
    monsterLordNilbog.Exp = ogreChieftain.Exp

    monsterLordNilbog.Attack1.DamageAdd = ogreChieftain.Attack1.DamageAdd
    monsterLordNilbog.Attack1.DamageDiceSides = ogreChieftain.Attack1.DamageDiceSides
    monsterLordNilbog.Attack1.DamageDiceCount = ogreChieftain.Attack1.DamageDiceCount

    -- Cosmetic (resets on map leave)
    Game.MonstersTxt[LordNilbogMonsterTxtId].Name = "Lord Nilbog"

    MakeGoblinsHostile()
    return monsterLordNilbog
end

CreateMonsterLordNilbog = function()
    local LordNilbogMonsterTxtId = 550 -- normal MM6 Goblin index
    local monsterLordNilbog
    for _, m in Map.Monsters do
        -- NOTE: assumes no other monsters share Lord Nilbog's index
        if m.Id == LordNilbogMonsterTxtId then
            monsterLordNilbog = m
        end
    end
    if monsterLordNilbog == nil then
        monsterLordNilbog = SummonMonster(LordNilbogMonsterTxtId, -115, 55, 1, true)
    end
    return Quest_Goblinwatch5_MonsterLordNilbog(monsterLordNilbog)
end
