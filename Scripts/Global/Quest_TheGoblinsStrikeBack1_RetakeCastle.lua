-- ============================================================================
--  TheGoblinsStrikeBack 1 Quest
-- ============================================================================
-- Slots
local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5
local G = TheGoblinsStrikeBack

-- Hoisted forward declarations
local CreateSamsonTessQuestBranch

-- QuestStage wrapper (cosmetic grouping) -------------------------------------
local function QuestStage(name)
    return function(block)
        return block
    end
end

-- ============================================================================
--  Quest stages
-- ============================================================================

QuestStage "Start" {
    NPCTopic {
        Topic = "Fleeing Goblin",
        Slot = E,
        NPC = G.JaniceNPC,
        Text = [[
When you took Goblinwatch, a goblin was reported fleeing in the direction of the house south east of Goblinwatch.

There lives a man there called Dorf. He is a bit of an oddball, but please check if he is ok.]],
        CanShow = function()
            return G.InNewSorpigal() and vars.Quests[G.Quest1] ~= 'Done' and G.IsOriginalGoblinwatchDone()
        end
    }, Quest{
        G.Quest1,
        NPC = G.UrokNPC,
        Slot = E,
        CanShow = function()
            return G.InNewSorpigal() and
                       (Game.NPC[G.SamsonTessNPC].House == G.GoblinwatchHouse or vars.Quests[G.Quest1] ~= nil)
        end,
        CheckDone = function()
            return vars.Quests[G.Quest1] ~= nil and Game.NPC[G.SamsonTessNPC].House == 0
        end,
        Gold = 2000,
        Exp = 2000,
        Done = function()
            svars.HasNotLeftUrok = true
            Game.NPC[G.UrokNPC].House = G.GoblinwatchHouse
            Sleep2(function()
                svars.HasNotLeftUrok = nil
            end, 1)
        end,
        Give = function()
            CreateSamsonTessQuestBranch()
        end
    }.SetTexts {
        Quest = "Kill Samson Tess ontop of Goblinwatch",
        FirstTopic = "Retake the castle!",
        TopicGiven = "Retake the castle!",
        Give = [[
Kill filthy human living in Urok's castle!

I will give you riches!]],
        Undone = [[
Why is the filthy human still living in Urok's castle?

Think about the smells!

[Urok shakes his head in frustration] ]],
        Done = [[
The filthy man swine is dead, back to the castle I go!

Looks like meat's back on the menu!

[Urok raises his right hand in victory] ]]
    }}

QuestStage "Given" {
    NPCTopic {
        Slot = A,
        NPC = G.UrokNPC,
        Topic = "Humans",
        Text = [[
Humans took the castle from us! Stupid humans!

Dorf sad for us. Dorf ok.]],
        CanShow = function()
            return G.InNewSorpigal() and G.IsOriginalGoblinwatchDone()
        end
    }}

QuestStage "DoneBeforeLeavingDorf" {
    NPCTopic {
        Topic = "Back to Goblinwatch",
        Slot = B,
        NPC = G.UrokNPC,
        Text = "Meet me back ontop of Gobliwatch, theres more work to be done.",
        CanShow = function()
            return G.InNewSorpigal() and G.QuestState(G.Quest1, "Done") and svars.HasNotLeftUrok
        end
    }}

QuestStage "Done" {
    NPCTopic {
        Slot = A,
        NPC = G.UrokNPC,
        Topic = "Humans",
        Text = [[
[Urok laughs eerily]

Humans think they are safe in their town,
but now Urok is back!

And soon comes Lord Nilbog.]],
        CanShow = function()
            return G.InNewSorpigal() and G.QuestState(G.Quest1, "Done") and svars.HasNotLeftUrok == nil
        end
    }, NPCTopic {
        Topic = "Lord Nilbog",
        Slot = B,
        NPC = G.UrokNPC,
        Text = "The lord of Goblinwatch will return soon.",
        CanShow = function()
            return G.InNewSorpigal() and G.QuestState(G.Quest1, "Done") and svars.HasNotLeftUrok == nil
        end
    }, Greeting {
        NPC = G.UrokNPC,
        Text = [[
It's good to be back at castle, but I can still smell
the stink of the filthy human!

At least he tasted good!]],
        CanShow = function()
            return G.InNewSorpigal() and G.QuestState(G.Quest1, "Done") and svars.HasNotLeftUrok == nil
        end
    }}

-- ============================================================================
--  Branching Quest: Samson Tess
-- ============================================================================

CreateSamsonTessQuestBranch = function()
    NPCTopic {
        Slot = B,
        NPC = G.SamsonTessNPC
    }
    NPCTopic {
        Slot = C,
        NPC = G.SamsonTessNPC
    }
    local QuestBase = {}
    local function MyQuest(t)
        table.copy(QuestBase, t)
        QuestBase.Slot = QuestBase.Slot and QuestBase.Slot + 1
        return Quest(t)
    end

    local function SetQuestBranch(t)
        QuestBranch(t.NewBranch)
    end

    QuestNPC = G.SamsonTessNPC
    QuestBase = {
        Branch = "",
        Slot = A,
        Ungive = SetQuestBranch
    }

    MyQuest {
        CanShow = function()
            return G.InNewSorpigal() and G.QuestState(G.Quest1, "Given")
        end,
        NewBranch = "SamsonTessFight",
        Texts = {
            Topic = "Retake the castle!",
            TopicGiven = "Retake the castle!",
            Ungive = [[
So the goblins wants the castle back...

[Samson looks at you with suspicion]

Your not going to help him are you?]]
        }
    }

    QuestBase = {
        Branch = "SamsonTessFight",
        Slot = A,
        Ungive = SetQuestBranch
    }

    MyQuest {
        NewBranch = "SamsonTessFightNo",
        Texts = {
            Topic = "No of course not!",
            Ungive = "Sorry for doubting you. I'm thankful for your contribution against the goblins."
        }
    }

    MyQuest {
        NewBranch = "SamsonTessFightYes",
        Ungive = function(t)
            Sleep(2000, 1)
            ExitScreen()
            Sleep(1, 1)
            EnterDecentHouseMap(G.Quest1)
        end,
        Texts = {
            Topic = "Your end has come Samson!",
            Ungive = "Traitor!"
        }
    }
end

-- ============================================================================
--  TheGoblinsStrikeBack 1: helpers & event handlers
-- ============================================================================

-- Reusable CanShow helpers
local function SamsonQuestActive()
    return vars.decentHousePurpose == G.Quest1
end
local function UrokShouldMove()
    return vars.Quests[G.Quest1] ~= "Done" and G.IsOriginalGoblinwatchDone()
end

-- ============================================================================
--  Map / NPC helpers
-- ============================================================================

local function CreateEnemyTess()
    local monster = FindMonsterEncounterMonster(G.SamsonTessEncounterName, G.DecentHouse)
    for _, m in Map.Monsters do
        if monster == nil and m.Id == G.SamsonTessMonster and m.AIState ~= const.AIState.Removed then
            monster = m
            TrackMonsterEncounterMonster(G.SamsonTessEncounterName, monster, G.DecentHouse)
        end
    end
    if not monster then
        monster = SummonMonster(G.SamsonTessMonster, -115, 55, 1, true)
        TrackMonsterEncounterMonster(G.SamsonTessEncounterName, monster, G.DecentHouse)
    end
    ConfigureQuestMonster(monster, true, 0)
    -- assign readable name
    Game.MonstersTxt[G.SamsonTessMonster].Name = "Samson Tess"
    return monster
end

local hasCreatedTimer = false
local function MoveUrokToHouseTimer()
    if not G.InNewSorpigal() then
        if hasCreatedTimer then
            RemoveTimer(MoveUrokToHouseTimer)
            hasCreatedTimer = false
        end
        return
    end

    if UrokShouldMove() then
        Game.NPC[G.UrokNPC].House = G.HouseBehindGoblinwatch
        if hasCreatedTimer then
            RemoveTimer(MoveUrokToHouseTimer)
            hasCreatedTimer = false
        end
        return
    end

    if not hasCreatedTimer then
        Timer(MoveUrokToHouseTimer, const.Minute * 3)
        hasCreatedTimer = true
    end
end

-- ============================================================================
--  Event Handlers
-- ============================================================================

function events.LeaveMap()
    if G.InMap(G.DecentHouse) and SamsonQuestActive() then
        vars.decentHousePurpose = nil
        MarkMonsterEncounterForRemoval(G.SamsonTessEncounterName, G.DecentHouse)
    end
end

function events.MonsterKilled(mon)
    if G.InMap(G.DecentHouse) and NamedMonsterEncounterContainsMonster(G.SamsonTessEncounterName, mon, G.DecentHouse) then
        vars.SamsonTessDead = true
    end
end

function events.AfterLoadMap()
    -- Samson Tess apartment logic
    if G.InMap(G.DecentHouse) and SamsonQuestActive() then
        local monster = CreateEnemyTess()
        evt.Map[G.DecentHouseExitDoorEventId] = function()
            if monster.HP > 0 then
                Game.ShowStatusText("Samson Tess is blocking your escape!")
            else
                G.SendPartyBackToGoblinwatchApartmentEntrance()
            end
        end
    end

    -- Urok / Samson NPC logic in New Sorpigal
    if G.InNewSorpigal() then
        -- Move Urok immediately when retake is available; otherwise keep watching for the original quest completion.
        if UrokShouldMove() or (vars.Quests[G.Quest1] == nil and not hasCreatedTimer) then
            MoveUrokToHouseTimer()
        end

        RestoreGoblinwatchNativeHouseOccupants()

        if G.QuestState(G.Quest1, "Done") then
            Game.NPC[G.UrokNPC].House = G.GoblinwatchHouse
        end

        if G.QuestState(G.Quest1, "Given") and Game.NPC[G.SamsonTessNPC].House == G.GoblinwatchHouse then
            CreateSamsonTessQuestBranch()
        end

        if vars.SamsonTessDead then
            Game.NPC[G.SamsonTessNPC].House = 0
        end
    end
end
