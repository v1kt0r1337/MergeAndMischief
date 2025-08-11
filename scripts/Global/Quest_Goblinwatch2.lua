local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5
local goblinwatchHouse = 1463
local SamsonTessNPC_ID = 828
local SamsonTessMonsterTxtId = 587 -- Expert Swordsman
local UrokNPC_ID = 1081

local houseBehindGoblinwatch = 1413
local NewSorpigal = "oute3.odm"
local humansNPCTextIndex = 2064
local questName = "Quest_Goblinwatch2"

local decenthouseMapName = "decenthouse.blv"
local decenthouseExitDoorEventId = 5

-- declared here for hoisting
local OnQuestGiven 
local OnQuestDone
local EnterGoblinwatchApartment
local CreateSamsonTessQuestBranch

 Quest{
    questName,
	NPC = UrokNPC_ID,
	Slot = B,
	CanShow = function() return Game.NPC[SamsonTessNPC_ID].House == goblinwatchHouse or IsQuestGiven(questName) end,
    CheckDone = function() return IsQuestGiven(questName) and Game.NPC[SamsonTessNPC_ID].House == 0 end, 
    Gold = 2000,
    Exp = 2000,
	Done = function() 
        OnQuestDone(true) 
    end,
    Give = function() OnQuestGiven() end,
}.SetTexts{
    Quest = "Kill Samson Tess ontop of Goblinwatch",
    FirstTopic = "Retake the castle!",
    TopicGiven = "Retake the castle!",
    Give = [[
Kill filthy human living in my castle!

I will give you riches!]],
    Undone = [[
Why is the filthy human still living in my castle? 

Think about the smells!

[Urok shakes his head in frustration]
]],
    Done = [[
The filthy man swine is dead, back to the castle I go!

Tonight theres meat on the menu!

[Urok raises his right hand in victory]
]],
}

OnQuestGiven = function()
    -- remove topics from SamsonTessNPC_ID
    NPCTopic{Slot = A, NPC = SamsonTessNPC_ID}
    NPCTopic{Slot = C, NPC = SamsonTessNPC_ID} 
    CreateSamsonTessQuestBranch()
end

CreateSamsonTessQuestBranch = function()
    --[[ 
        Second step of the quest related to killing Samson Tess
        This quest is branched
    ]]
    local QuestBase = {}
    local function MyQuest(t)
        table.copy(QuestBase, t)  -- copy common values
        QuestBase.Slot = QuestBase.Slot and QuestBase.Slot + 1  -- auto-increment Slot
        return Quest(t)
    end

    local function SetQuestBranch(t)
        QuestBranch(t.NewBranch)
    end

    QuestNPC = SamsonTessNPC_ID
    QuestBase = {Branch = "", Slot = D, Ungive = SetQuestBranch}
    MyQuest{
        CanShow = function () return IsQuestGiven(questName) end,
        NewBranch = "SamsonTessFight",
        Texts = {
            Topic = "Retake the castle!",
            Ungive = [[
So the goblins wants the castle back...

[Samson looks at you with suspecioun]

Your not going to help him are you?]]
        }
    }

    QuestBase = {Branch = "SamsonTessFight", Slot = D, Ungive = SetQuestBranch}
    MyQuest{
        NewBranch = "SamsonTessFightNo",
        Texts = {
            Topic = "No of course not!",
            Ungive = "Sorry for doubting you. I'm thankful for your contribution against the goblins"
        }
    }

    MyQuest{
        NewBranch = "SamsonTessFightYes",
        Ungive = function(t) EnterGoblinwatchApartment() end,
        Texts = {
            Topic = "Your end has come Samson!",
            Ungive = "Traitor!",
        }
    }
end


EnterGoblinwatchApartment = function()
    Sleep(2000, 1)
    vars.movedIntoGoblinwatchApartment = true
    vars.initiateKillTess = true
    evt.PlaySound(6) -- squeaky door sound (might sound off since already inside?)
    evt.MoveToMap{Name=decenthouseMapName, Direction=1000}
end


local function CreateEnemyTess()
    local SamsonTessMonsterTxtId = 587
    local monsterSamsonTess
    for _, m in Map.Monsters do
        -- TODO missing robustness: for this loop to work no other monsters sharing Samson Tess index need to exist  
        if m.Id == SamsonTessMonsterTxtId then
            monsterSamsonTess = m
        end
    end
    if monsterSamsonTess == nil then
        monsterSamsonTess = SummonMonster(SamsonTessMonsterTxtId, -115, 55, 1, false)
    end
    -- changing these doesn't matter because it will reset after map leave
    monTxt = Game.MonstersTxt[SamsonTessMonsterTxtId]
    monTxt.Name = "Samson Tess"
    return monsterSamsonTess
end

local function SendPartyBackToGoblinwatchApartmentEntrance()
    evt.PlaySound(7) -- slam door sound
    evt.MoveToMap{Name=NewSorpigal, X=-18303, Y=-15535, Z=1985, Direction=1538}
end

function events.LeaveMap() 
    if Map.Name == decenthouseMapName and vars.movedIntoGoblinwatchApartment then
        vars.movedIntoGoblinwatchApartment = nil
        vars.initiateKillTess = nil
        -- removes all monsters in the map for later reuse
        for _, m in Map.Monsters do
            m.AIState = const.AIState.Removed
         end
    end
end

function events.LoadMapScripts()
    if Map.Name == decenthouseMapName and vars.movedIntoGoblinwatchApartment then
        -- this sets the bolstering to be the same as New Sorpigal
        Map.MapStatsIndex = 151 
    end
end


function events.MonsterKilled(mon) 
    if Map.Name == decenthouseMapName and Game.MonstersTxt[mon.Id].Name == "Samson Tess" then
        vars.SamsonTessDead = true;
    end
end


OnQuestDone = function(waitWithDialog)
    NPCTopic{
        Topic = "Back to Goblinwatch",
        Slot = B,
        Text = "Meet me back ontop of Gobliwatch, theres more work to be done.",
        NPC = UrokNPC_ID,
    }

    -- Prevent new topics from being instantly available
    function InitializeNewDialog() 
        Game.NPC[UrokNPC_ID].House = goblinwatchHouse
        Game.NPCText[humansNPCTextIndex] = [[
[Urok laughts eerily]

Humans think they are safe in their town, but now Urok is back! 

And soon comes Lord Nilbog.]]
            
        NPCTopic{
            Topic = "Lord Nilbog",
            Slot = B,
            Text = "The lord of Goblinwatch will return soon.",
            NPC = UrokNPC_ID,
        }
    
        Greeting{
            NPC = UrokNPC_ID,
            Text =  [[
It's good to be back at castle, but I can still smell the stink of the filthy human!

Atleast he had the decency to taste good!]]
        }            
    end
    
    if (waitWithDialog) then
        Sleep2(function() InitializeNewDialog() end, 1, nil, nil)
    else 
        InitializeNewDialog()
    end
 end


local function InitializeQuest() 
    if Map.Name ~= NewSorpigal then
        RemoveTimer()
        hasCreatedTimer = false
        return
    end
    if Game.NPC[SamsonTessNPC_ID].House == goblinwatchHouse and IsQuestGiven(questName) == false then
        Game.NPCText[humansNPCTextIndex] = [[
Humans took the castle from us! Stupid humans!

Dorf sad for us. Dorf ok.]]
    end
end

local hasCreatedTimer = false
function events.AfterLoadMap() 
    if (Map.Name == decenthouseMapName and vars.movedIntoGoblinwatchApartment and vars.initiateKillTess) then
        local monsterSamsonTess = CreateEnemyTess() 
        evt.Map[decenthouseExitDoorEventId] = function() 
            if monsterSamsonTess.HP > 0 then
                Game.ShowStatusText(Game.MonstersTxt[SamsonTessMonsterTxtId].Name  .. " is blocking your escape!")
            else 
                SendPartyBackToGoblinwatchApartmentEntrance()
            end
        end
    end
    if Map.Name == NewSorpigal then
        if IsQuestGiven(questName) == false and hasCreatedTimer == false  then
            Timer(function() InitializeQuest() end, const.Minute*3)
            hasCreatedTimer = true
        end
        if vars.Quests[questName] == "Given" then
            Game.NPCText[humansNPCTextIndex] = [[
Humans took the castle from us! Stupid humans!

Dorf sad for us. Dorf ok.]]
            OnQuestGiven()
        end

        if vars.Quests[questName] == "Done" then
            OnQuestDone()
        end
    end

end


-- findNPC("Janice")
-- ---- Log File Output: ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- npc index	1076
-- {
-- 	Bits = 2,
-- 	EventA = 1319,
-- 	EventB = 1032,
-- 	EventC = 1712,
-- 	EventD = 0,
-- 	EventE = 0,
-- 	EventF = 0,
-- 	Events = {
-- 		1319,
-- 		1032,
-- 		1712,
-- 		0,
-- 		0,
-- 		0
-- 	},
-- 	Exist = true,
-- 	Fame = 0,
-- 	Greet = 0,
-- 	Hired = false,
-- 	House = 208,
-- 	Joins = 0,
-- 	Name = "Janice",
-- 	NewsTopic = 0,
-- 	Pic = 20,
-- 	Profession = 72,
-- 	Rep = 0,
-- 	Sex = 0,
-- 	TalkedBefore = true,
-- 	TalkedOnce = false,
-- 	TellsNews = 0,
-- 	ThreatenedBefore = false,
-- 	UsedSpell = 0
-- }



-- BEFORE Goblinwatch quest:
-- > findNPC("Urok")
-- ---- Log File Output: ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- npc index	1081
-- {
-- 	Bits = 1,
-- 	EventA = 1660,
-- 	EventB = 0,
-- 	EventC = 0,
-- 	EventD = 0,
-- 	EventE = 0,
-- 	EventF = 0,
-- 	Events = {
-- 		1660,
-- 		0,
-- 		0,
-- 		0,
-- 		0,
-- 		0
-- 	},
-- 	Exist = true,
-- 	Fame = 0,
-- 	Greet = 0,
-- 	Hired = false,
-- 	House = 1463,
-- 	Joins = 0,
-- 	Name = "Urok",
-- 	NewsTopic = 0,
-- 	Pic = 1031,
-- 	Profession = 0,
-- 	Rep = 0,
-- 	Sex = 0,
-- 	TalkedBefore = false,
-- 	TalkedOnce = true,
-- 	TellsNews = 0,
-- 	ThreatenedBefore = false,
-- 	UsedSpell = 0
-- }

-- after goblinwatch

-- {
-- 	Bits = 2,
-- 	EventA = 1660,
-- 	EventB = 0,
-- 	EventC = 0,
-- 	EventD = 0,
-- 	EventE = 0,
-- 	EventF = 0,
-- 	Events = {
-- 		1660,
-- 		0,
-- 		0,
-- 		0,
-- 		0,
-- 		0
-- 	},
-- 	Exist = true,
-- 	Fame = 0,
-- 	Greet = 0,
-- 	Hired = false,
-- 	House = 0,
-- 	Joins = 0,
-- 	Name = "Urok",
-- 	NewsTopic = 0,
-- 	Pic = 1031,
-- 	Profession = 0,
-- 	Rep = 0,
-- 	Sex = 0,
-- 	TalkedBefore = true,
-- 	TalkedOnce = false,
-- 	TellsNews = 0,
-- 	ThreatenedBefore = false,
-- 	UsedSpell = 0
-- }


-- new owner of goblin watch

-- npc index	828
-- {
-- 	Bits = 1,
-- 	EventA = 1661,
-- 	EventB = 0,
-- 	EventC = 1032,
-- 	EventD = 0,
-- 	EventE = 0,
-- 	EventF = 0,
-- 	Events = {
-- 		1661,
-- 		0,
-- 		1032,
-- 		0,
-- 		0,
-- 		0
-- 	},
-- 	Exist = true,
-- 	Fame = 0,
-- 	Greet = 0,
-- 	Hired = false,
-- 	House = 1463,
-- 	Joins = 0,
-- 	Name = "Samson Tess",
-- 	NewsTopic = 0,
-- 	Pic = 429,
-- 	Profession = 73,
-- 	Rep = 0,
-- 	Sex = 0,
-- 	TalkedBefore = false,
-- 	TalkedOnce = true,
-- 	TellsNews = 0,
-- 	ThreatenedBefore = false,
-- 	UsedSpell = 0
-- }




-- Door
-- Id = 1
-- Speed1 = 50
-- Speed2 = 50
-- MoveLength = 128
-- DirectionX = -1
-- DirectionY = 0
-- DirectionZ = 0
-- NoSound = false
-- StartState2 = false
-- VertexFilter = "Free"      -- (nil, "Free", "Shrink" or "Grow")
-- VertexFilterParam1 = nil
-- VertexFilterParam2 = nil
-- ClosePortal = false
-- event = 5


-- sack
-- X = -288
-- Y = -64
-- Z = 0
-- Direction = 0
-- Id = 0
-- Event = 1
-- TriggerRadius = 0
-- TriggerByTouch = true
-- TriggerByMonster = false
-- TriggerByObject = false
-- ShowOnMap = false
-- IsChest = false
-- Invisible = false
-- IsObeliskChest = false



-- boxes
-- > Bitmap = "CBTINY"
-- BitmapU = 256
-- BitmapV = 64
-- Id = 0
-- Event = 3
-- TriggerByClick = true
-- TriggerByStep = false
-- IsSecret = false
-- Untouchable = false
-- Invisible = false
-- DontShowOnMap = false
-- MovedByDoor = false
-- DoorStaticBmp = false
-- MultiDoor = false
-- AlignTop = false
-- AlignBottom = false
-- AlignLeft = false
-- AlignRight = false
-- IsWater = false
-- IsSky = false
-- IsLava = false
-- ScrollUp = false
-- ScrollDown = false
-- ScrollLeft = false
-- ScrollRight = false
-- AnimatedTFT = false

-- foodbowl
-- DecName = "foodbowl"
-- X = -344
-- Y = 64
-- Z = 0
-- Direction = 0
-- Id = 0
-- Event = 2
-- TriggerRadius = 0
-- TriggerByTouch = true
-- TriggerByMonster = false
-- TriggerByObject = false
-- ShowOnMap = false
-- IsChest = false
-- Invisible = false
-- IsObeliskChest = false

-- barrel
-- DecName = "smlbarel"
-- X = 320
-- Y = 336
-- Z = 0
-- Direction = 0
-- Id = 0
-- Event = 4
-- TriggerRadius = 0
-- TriggerByTouch = true
-- TriggerByMonster = false
-- TriggerByObject = false
-- ShowOnMap = false
-- IsChest = false
-- Invisible = false
-- IsObeliskChest = false