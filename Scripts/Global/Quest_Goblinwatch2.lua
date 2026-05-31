-- ============================================================================
--  Goblinwatch 2 Quest
-- ============================================================================
-- Slots
local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5

-- IDs
local goblinwatchHouse = 1463
local houseBehindGoblinwatch = 1413
local samsonTessNPC_ID = 828
local SamsonTessMonsterTxtId = 587 -- Expert Swordsman
local urokNPC_ID = 1081
local janiceNPC_ID = 1076
local nilbogNPC_ID = 111

-- Locations
local NewSorpigal = "oute3.odm"
local decenthouseMapName = "decenthouse.blv"
local decenthouseExitDoorEventId = 5

-- Quest IDs
local Quest_Goblinwatch2 = "Quest_Goblinwatch2"

-- Hoisted forward declarations
local CreateSamsonTessQuestBranch
local SendPartyBackToGoblinwatchApartmentEntrance

RegisterSharedHouseUse {
    Key = "GoblinwatchNewSorpigalHouse",
    QuestLine = "Goblinwatch",
    Map = "oute3.odm",
    House = 1463
}

-- Helpers --------------------------------------------------------------------
local function InMap(map)
    return Map.Name == map
end
local function InNewSorpigal()
    return InMap(NewSorpigal)
end
local function QuestState(id, state)
    return vars.Quests[id] == state
end

local function IsOriginalGoblinwathDone()
    return Party.QBits[313] and Party.QBits[1324] and Party.QBits[1107] == false
end

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
        NPC = janiceNPC_ID,
        Text = [[
When you took Goblinwatch, a goblin was reported fleeing in the direction
of the house south east of Goblinwatch. 

There lives a man there called Dorf. He is a bit of an oddball,
but please check if he is ok.]],
        CanShow = function()
            return InNewSorpigal() and vars.Quests[Quest_Goblinwatch2] ~= 'Done' and IsOriginalGoblinwathDone()
        end
    }, Quest{
        Quest_Goblinwatch2,
        NPC = urokNPC_ID,
        Slot = E,
        CanShow = function()
            return InNewSorpigal() and
                       (Game.NPC[samsonTessNPC_ID].House == goblinwatchHouse or vars.Quests[Quest_Goblinwatch2] ~= nil)
        end,
        CheckDone = function()
            return vars.Quests[Quest_Goblinwatch2] ~= nil and Game.NPC[samsonTessNPC_ID].House == 0
        end,
        Gold = 2000,
        Exp = 2000,
        Done = function()
            svars.HasNotLeftUrok = true
            Game.NPC[urokNPC_ID].House = goblinwatchHouse
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
Kill filthy human living in my castle!

I will give you riches!]],
        Undone = [[
Why is the filthy human still living in my castle? 

Think about the smells!

[Urok shakes his head in frustration] ]],
        Done = [[
The filthy man swine is dead, back to the castle I go!

Looks like meats back on the menu!

[Urok raises his right hand in victory] ]]
    }}

QuestStage "Given" {
    NPCTopic {
        Slot = A,
        NPC = urokNPC_ID,
        Topic = "Humans",
        Text = [[
Humans took the castle from us! Stupid humans!

Dorf sad for us. Dorf ok.]],
        CanShow = function()
            return InNewSorpigal() and IsOriginalGoblinwathDone()
        end
    }}

QuestStage "DoneBeforeLeavingDorf" {
    NPCTopic {
        Topic = "Back to Goblinwatch",
        Slot = B,
        NPC = urokNPC_ID,
        Text = "Meet me back ontop of Gobliwatch, theres more work to be done.",
        CanShow = function()
            return InNewSorpigal() and QuestState(Quest_Goblinwatch2, "Done") and svars.HasNotLeftUrok
        end
    }}

QuestStage "Done" {
    NPCTopic {
        Slot = A,
        NPC = urokNPC_ID,
        Topic = "Humans",
        Text = [[
[Urok laughts eerily]

Humans think they are safe in their town,
but now Urok is back! 

And soon comes Lord Nilbog.]],
        CanShow = function()
            return InNewSorpigal() and QuestState(Quest_Goblinwatch2, "Done") and svars.HasNotLeftUrok == nil
        end
    }, NPCTopic {
        Topic = "Lord Nilbog",
        Slot = B,
        NPC = urokNPC_ID,
        Text = "The lord of Goblinwatch will return soon.",
        CanShow = function()
            return InNewSorpigal() and QuestState(Quest_Goblinwatch2, "Done") and svars.HasNotLeftUrok == nil
        end
    }, Greeting {
        NPC = urokNPC_ID,
        Text = [[
It's good to be back at castle, but I can still smell
the stink of the filthy human!

Atleast he had the decency to taste good!]],
        CanShow = function()
            return InNewSorpigal() and QuestState(Quest_Goblinwatch2, "Done") and svars.HasNotLeftUrok == nil
        end
    }}

-- ============================================================================
--  Branching Quest: Samson Tess
-- ============================================================================

CreateSamsonTessQuestBranch = function()
    NPCTopic {
        Slot = B,
        NPC = samsonTessNPC_ID
    }
    NPCTopic {
        Slot = C,
        NPC = samsonTessNPC_ID
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

    QuestNPC = samsonTessNPC_ID
    QuestBase = {
        Branch = "",
        Slot = A,
        Ungive = SetQuestBranch
    }

    MyQuest {
        CanShow = function()
            return InNewSorpigal() and QuestState(Quest_Goblinwatch2, "Given")
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
            EnterDecentHouseMap(Quest_Goblinwatch2)
        end,
        Texts = {
            Topic = "Your end has come Samson!",
            Ungive = "Traitor!"
        }
    }
end

-- ============================================================================
--  Goblinwatch 2: helpers & event handlers
-- ============================================================================

-- Reusable CanShow helpers
local function SamsonQuestActive()
    return vars.decentHousePurpose == Quest_Goblinwatch2
end
local function UrokShouldMove()
    return vars.Quests[Quest_Goblinwatch2] ~= "Done" and IsOriginalGoblinwathDone()
end

function RestoreGoblinwatchNativeHouseOccupants()
    if vars.Quests[Quest_Goblinwatch2] ~= nil or vars.SamsonTessDead == true then
        return
    end

    if not IsOriginalGoblinwathDone() then
        Game.NPC[urokNPC_ID].House = goblinwatchHouse
        Game.NPC[samsonTessNPC_ID].House = 0
        return
    end

    Game.NPC[urokNPC_ID].House = houseBehindGoblinwatch
    Game.NPC[samsonTessNPC_ID].House = goblinwatchHouse
end

-- ============================================================================
--  Map / NPC helpers
-- ============================================================================

local function CreateEnemyTess()
    local monster
    for _, m in Map.Monsters do
        if m.Id == SamsonTessMonsterTxtId then
            monster = m
        end
    end
    if not monster then
        monster = SummonMonster(SamsonTessMonsterTxtId, -115, 55, 1, true)
    end
    -- assign readable name
    Game.MonstersTxt[SamsonTessMonsterTxtId].Name = "Samson Tess"
    return monster
end

SendPartyBackToGoblinwatchApartmentEntrance = function()
    evt.PlaySound(7) -- slam door
    evt.MoveToMap {
        Name = NewSorpigal,
        X = -18303,
        Y = -15535,
        Z = 1985,
        Direction = 1538
    }
end

local hasCreatedTimer = false
local function MoveUrokToHouseTimer()
    if not InNewSorpigal() then
        if hasCreatedTimer then
            RemoveTimer(MoveUrokToHouseTimer)
            hasCreatedTimer = false
        end
        return
    end

    if UrokShouldMove() then
        Game.NPC[urokNPC_ID].House = houseBehindGoblinwatch
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
    if InMap(decenthouseMapName) and SamsonQuestActive() then
        vars.decentHousePurpose = nil
    end
end

function events.MonsterKilled(mon)
    if InMap(decenthouseMapName) and Game.MonstersTxt[mon.Id].Name == "Samson Tess" then
        vars.SamsonTessDead = true
    end
end

function events.AfterLoadMap()
    -- Samson Tess apartment logic
    if InMap(decenthouseMapName) and SamsonQuestActive() then
        local monster = CreateEnemyTess()
        evt.Map[decenthouseExitDoorEventId] = function()
            if monster.HP > 0 then
                Game.ShowStatusText("Samson Tess is blocking your escape!")
            else
                SendPartyBackToGoblinwatchApartmentEntrance()
            end
        end
    end

    -- Urok / Samson NPC logic in New Sorpigal
    if InNewSorpigal() then
        -- create timer for Urok movement if quest not started
        if vars.Quests[Quest_Goblinwatch2] == nil and not hasCreatedTimer then
            MoveUrokToHouseTimer()
        end

        RestoreGoblinwatchNativeHouseOccupants()

        if QuestState(Quest_Goblinwatch2, "Done") then
            Game.NPC[urokNPC_ID].House = goblinwatchHouse
        end

        if QuestState(Quest_Goblinwatch2, "Given") and Game.NPC[samsonTessNPC_ID].House == goblinwatchHouse then
            CreateSamsonTessQuestBranch()
        end

        if vars.SamsonTessDead then
            Game.NPC[samsonTessNPC_ID].House = 0
        end
    end
end
