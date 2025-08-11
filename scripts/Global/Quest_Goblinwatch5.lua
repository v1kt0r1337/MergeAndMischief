local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5
local goblinwatchHouse = 1463
local NilbogNPC_ID = 1239
local UrokNPC_ID = 1081
local JaniceNPC_ID = 1076
local FrankFairchild_ID = 788
local houseBehindGoblinwatch = 1413
local NewSorpigal = "oute3.odm"

local questName = "Quest_Goblinwatch5"
local prevQuest = "Quest_Goblinwatch4"
local questAlternativeEnding = "Quest_Goblinwatch5AlternativeEnding"
local questAlternativeEndingUrukTraitorAward = "Quest_Goblinwatch5AlternativeUrukTraitorAward"

local decenthouseMapName = "decenthouse.blv"
local decenthouseExitDoorEventId = 5

local EnterGoblinwatchApartment
local CreateKillLordNilbogQuestBranch
local CreateMonsterLordNilbog
local MakeGoblinsHostile

-- goblin pic 624  622, maybe 677, 602 (female), 638 (stygg), 638, 613 (female),  547(f), 550(f),607(f),
-- sjekke begge disse(626,1307),543 (f),552 (f ganske grei),


--[[
First Priority: NPCTopics can't be set on map load inside quest. We need more fine grained controll on a questline where dialog changes, place them in Quest_zzMapOverrides.lua 


Currently working on2: Traitor Reward, printing in AutoAward LocalizationAndQuests.lua to find out correct function arguments.
                            - test output when delivering quest with award.
                    Change this to quest award from Uruk, spawn x amounts of goblin outside when player leaves house.


TODO: 

    Must: Change Lord Nilbog's id so he reuse Tess id, and remove or create new .lod file with only the decenthouse.blv file (aparment or room might be a better name).
   
    Must: Resize Lord Nilbog so he becomes bigger, alternatively use a different Goblin model to make him more menacing.
    
    Should: Add traitor reward when doing alternative ending, make the Goblin Kings spawn closer to the house so it feels more like an ambush.

    Should: Ensure Guards don't refill after Quest_Goblinwatch4
        - the easy solution is to loop through map on load and remove them, but this might break other quests.
        - The alternative solution is to replace x amount of guards with Goblin Kings, This could be improved upon by making a geofence solution.

    Should: Change topic for Nilbog after done
    
    Should: After Quest, give new funny topics to Uruk, Frank and Janice

    Should: After alternative ending, give some sort of response from Uruk at the house behind goblinwatch.



    Could: Tune the goblin attack.
    Could: Fix Frank Fairchild quest branch so that only dialogs are visible when quest is clicked
        - Denne var tricky, trolig ikke verdt det.

    Ideally (not feasible): change decenthouse.blv to a proper room deserving of Goblinwatch

    

    

   
]]

-- declared here for hoisting
local GiveFrankSurrenderQuest
local GiveFrankLordNilbogIsDeadQuest
local GiveUrukTraitorAwardQuest
local PlayFightSounds

function events.AfterLoadMap() 
    if (Map.Name == NewSorpigal and vars.Quests[questName] == "Given") then
        GiveFrankSurrenderQuest()
    end
    if (Map.Name == NewSorpigal and vars.LordNilbogDead and vars.Quests[questAlternativeEnding] == nil) then
        GiveFrankLordNilbogIsDeadQuest()
        GiveUrukTraitorAwardQuest()
    end
    if (Map.Name == NewSorpigal and vars.AcceptKillLordNilbog) then 
        CreateKillLordNilbogQuestBranch()
    end
end


PlayFightSounds = function()
    Sleep(800, 1)
    evt.PlaySound(309)
    Sleep(1400, 1)
    evt.PlaySound(316)
    Sleep(1800,1)
    evt.PlaySound(311)
end


Quest{
    questName,
    Slot = A,
    NPC = NilbogNPC_ID,
    Give = function()
        local goblinMonId = 550
        local goblinShamanMonId = 551
        -- summons goblins inside New Sorpigal Town
        SummonMonster(goblinMonId, -13117, -8893, 161, true)
        SummonMonster(goblinMonId, -10252, -9420, 161, true)
        SummonMonster(goblinMonId, -9350, -9035, 161, true)
        SummonMonster(goblinMonId, -9789, -8824, 161, true)
        SummonMonster(goblinShamanMonId, -9672, -8431, 161, true)
        SummonMonster(goblinMonId, -9376, -7920, 161, true)
        SummonMonster(goblinMonId, -5884, -7917, 161, true)
        SummonMonster(goblinMonId, -5947, -7622, 161, true)
        SummonMonster(goblinMonId, -6470, -5788, 161, true)
        -- turn goblins hostile to peasants
        local goblinMon = (goblinMonId + 2):div(3)
        local peasantMon = (595 + 2):div(3)
        Game.HostileTxt[goblinMon][peasantMon] = 4
        PlayFightSounds()
        GiveFrankSurrenderQuest()
    end,
    CanShow = function() return vars.Quests[prevQuest] == "Done" and vars.AcceptKillLordNilbog ~= true end,
    CheckDone = function()
        return vars.FrankFairchildHasSurrendered end,
    Done = function()
        Game.NPC[UrokNPC_ID].House = Game.NPC[FrankFairchild_ID].House
        local goblinMonId = 550
        -- turn goblins friendly to peasants
        local goblinMon = (goblinMonId + 2):div(3)
        local peasantMon = (595 + 2):div(3)
        Game.HostileTxt[goblinMon][peasantMon] = 0
        
        -- change portraits and names on multiple of the expert trainers in-town
        local ErikSalzburgId = 847-- expert body building
        Game.NPC[ErikSalzburgId].Pic = 622
        Game.NPC[ErikSalzburgId].Name = "Uglug"

        local ErikSalzburgId = 857-- expert meditation
        Game.NPC[ErikSalzburgId].Pic = 550
        Game.NPC[ErikSalzburgId].Name = "Ugla"

        local HaroldHessId = 818
        Game.NPC[HaroldHessId].Pic = 623
        Game.NPC[HaroldHessId].Name = "Argag"

        local HejazMawsilId = 1073
        Game.NPC[HejazMawsilId].Pic = 552
        Game.NPC[HejazMawsilId].Name = "Ula"

        local IsaoMagistrusId = 866
        Game.NPC[IsaoMagistrusId].Pic = 626
        Game.NPC[IsaoMagistrusId].Name = "Grol"
    end,
    Gold = 10000,
    Exp = 10000,
}.SetTexts{
    Quest = "Take New Sorpigal", 
    FirstTopic = "Take New Sorpigal",
    TopicGiven = "Force major Frank Fairchild to surrender the town",
    Give = [[
[Lord Nilbogs gives you a wide smile]

Can you hear that sound? Thats my goblins taking New Sorpigal.
Force major Frank Fairchild to surrender the town!

]],
    Undone = "Frank Fairchild has still not surrendered the town",
    Done = [[
The town is ours!

I will reign in castle, my Uruk is new major now!]],
    Award = "Tyrant of New Sorpigal",
}

GiveFrankSurrenderQuest = function()
    local QuestBase = {}
    local function MyQuest(t)
        table.copy(QuestBase, t)  -- copy common values
        QuestBase.Slot = QuestBase.Slot and QuestBase.Slot + 1  -- auto-increment Slot
        return Quest(t)
    end

    local function SetQuestBranch(t)
        QuestBranch(t.NewBranch)
    end

    QuestNPC = FrankFairchild_ID
    QuestBase = {Branch = "", Slot = D, Ungive = SetQuestBranch}
    MyQuest{
        CanShow = function () return  vars.Quests[questName] == "Given" end,
        NewBranch = "AskFrankFairchildToSurrender",
        Texts = {
            Topic = "Surrender to Lord Nilbog",
            Ungive = [[
[Frank looks at you pleadingly]

Lord Nilbog must be stopped.

You are the only one that can help us!]]
        }
    }

    QuestBase = {Branch = "AskFrankFairchildToSurrender", Slot = D, Ungive = SetQuestBranch}
    MyQuest{
        NewBranch = "AgreeToHelpFrank",
        CanShow = function(t) 
            return vars.FrankFairchildHasSurrendered ~= true 
        end,
        Ungive = function(t) 
            vars.AcceptKillLordNilbog = true
            CreateKillLordNilbogQuestBranch()
        end,
        Texts = {
            Topic = "Ok, I will kill Lord Nilbog",
            Ungive = [[
Thank you so much!

Hurry and stop the Goblins!]],
        }
    }

    MyQuest{
        NewBranch = "ForceFrankToSurrender",
        CanShow = function(t) 
            return vars.AcceptKillLordNilbog ~= true 
        end,
        Ungive = function(t) 
            vars.FrankFairchildHasSurrendered = true
        end,
        Texts = {
            Topic = "No Frank, surrender!",
            Ungive = [[
[Frank looks down in defeat]

I guess I have no choice.

Please hurry up and tell Lord Nilbog that I surrender.]],
        }
    }
end



CreateKillLordNilbogQuestBranch = function()
    local QuestBase = {}
    local function MyQuest(t)
        table.copy(QuestBase, t)  -- copy common values
        QuestBase.Slot = QuestBase.Slot and QuestBase.Slot + 1  -- auto-increment Slot
        return Quest(t)
    end

    local function SetQuestBranch(t)
        QuestBranch(t.NewBranch)
    end

    QuestNPC = NilbogNPC_ID
    QuestBase = {Branch = "", Slot = D, Ungive = SetQuestBranch}
    MyQuest{
        CanShow = function () return vars.AcceptKillLordNilbog == true end,
        NewBranch = "KillLordNilbog",
        Texts = {
            Topic = "Kill Lord Nilbog",
            Ungive = [[
[Lord Nilbog cackles]

The major wants me dead huh? Go back to him an finish the job!]]
        }
    }

    QuestBase = {Branch = "KillLordNilbog", Slot = D, Ungive = SetQuestBranch}
    MyQuest{
        NewBranch = "KillLordNilbog",
        Ungive = function(t) 
            vars.AcceptKillLordNilbog = nil 
            QuestBranch('')  
        end,
        Texts = {
            Topic = "Of course!",
            Ungive = "The humans will bow to goblins!"
        }
    }

    MyQuest{
        NewBranch = "KillLordNilbogYes",
        Ungive = function(t) EnterGoblinwatchApartment() end,
        Texts = {
            Topic = "No your tyranny has ended Nilbog!",
            Ungive = [[
[Lord Nilbog shrieks]

Side with humans die with humans!]]
        }
    }
end

local function SendPartyBackToGoblinwatchApartmentEntrance()
    evt.PlaySound(7) -- slam door sound
    evt.MoveToMap{Name=NewSorpigal, X=-18303, Y=-15535, Z=1985, Direction=1538}
end


EnterGoblinwatchApartment = function()
    Sleep(2500, 1)
    vars.movedIntoGoblinwatchApartment = true
    vars.initiateKillNilbog = true;
    evt.PlaySound(6) -- squeaky door sound (might sound off since already inside?)
    evt.MoveToMap{Name=decenthouseMapName, Direction=1000}
end

function events.AfterLoadMap() 
    if (Map.Name == decenthouseMapName and vars.movedIntoGoblinwatchApartment and vars.initiateKillNilbog) then
        local monsterLordNilbog = CreateMonsterLordNilbog() 
        evt.Map[decenthouseExitDoorEventId] = function() 
            if monsterLordNilbog.HP > 0 then
                Game.ShowStatusText(Game.MonstersTxt[monsterLordNilbog.Id].Name  .. " is blocking your escape!")
            else 
                SendPartyBackToGoblinwatchApartmentEntrance()
            end
        end
    end
end

function events.LoadMapScripts()
    if Map.Name == decenthouseMapName and vars.movedIntoGoblinwatchApartment then
        -- this sets the bolstering to be the same as New Sorpigal
        Map.MapStatsIndex = 151 
    end
end

function events.LeaveMap() 
    if Map.Name == decenthouseMapName and vars.movedIntoGoblinwatchApartment then
        vars.movedIntoGoblinwatchApartment = nil
        vars.initiateKillNilbog = nil
        -- removes all monsters in the map for later reuse
        for _, m in Map.Monsters do
            m.AIState = const.AIState.Removed
         end
    end
end

function events.MonsterKilled(mon) 
    if Map.Name == decenthouseMapName and Game.MonstersTxt[mon.Id].Name == "Lord Nilbog" then
        vars.LordNilbogDead = true;
        vars.NewSorpigalGoblinsFriendly = false;
        -- TODO further test is this have unwanted side effects
        vars.Quests[questName] = nil
        GiveFrankLordNilbogIsDeadQuest()
        GiveUrukTraitorAwardQuest()
    end
end


GiveFrankLordNilbogIsDeadQuest = function()
    local questInput = {
        questName = questAlternativeEnding,
        Slot = D,
        NPC = FrankFairchild_ID,
        CanShow = function() return vars.LordNilbogDead end,
        CheckDone = function() return vars.LordNilbogDead end,
        Gold = 10000,
        Exp = 10000
    }

    local textInput = {
            Quest = "Lord Nilbog is dead",
            TopicGiven = "Lord Nilbog is dead",
            Done = [[
Thank you for killing Lord Nilbog and saving our town!
    
Please accept this gold as a token of our gratitude]],
            Award = "Savor of New Sorpigal",
    }

    Quest(questInput).SetTexts(textInput)

    vars.Quests[questAlternativeEnding] = "Given"
end

GiveUrukTraitorAwardQuest = function()
    RemoveAllTopicsFromNPC(UrokNPC_ID)
    Quest{
    questName = questAlternativeEndingUrukTraitorAward,
    Slot = D,
    NPC = UrokNPC_ID,
    CanShow = function() return vars.LordNilbogDead end,
    CheckDone = function() return vars.LordNilbogDead end,
    Done = function()
        local goblinKing = 552
        SummonMonster(goblinKing, -2891, -19562, 0, true)
        SummonMonster(goblinKing, -3059, -19698, 0, true)
        SummonMonster(goblinKing, -3159, -19898, 0, true)
        SummonMonster(goblinKing, -3273, -20352, 0, true)
    end
    
}.SetTexts{
    Quest = "Traitor!",
    FirstTopic = "Take New Sorpigal",
    Give = [[
        [Lord Nilbogs gives you a wide smile]
        
        Can you hear that sound? Thats my goblins taking New Sorpigal.
        Force major Frank Fairchild to surrender the town!
        
        ]],
    TopicGiven = "Traitor to the Goblins of New Sorpigal",
    Undone = "Frank Fairchild has still not surrendered the town",
    Done = [[
You are no friend of goblins!

The other goblins will know of this!]],
    Award = "Traitor to the Goblins of New Sorpigal"
}


    vars.Quests[questAlternativeEndingUrukTraitorAward] = "Given"
end


MakeGoblinsHostile = function()
    -- Make goblins hostile
    local goblinId = 550
    local goblinMon = (goblinId + 2):div(3)
    Game.HostileTxt[goblinMon][0] = 4
end


CreateMonsterLordNilbog = function()
    local OgreChieftainTxtId = 594
    local LordNilbogMonsterTxtId = 550  -- Normal MM6 Goblin
    local monsterLordNilbog
    for _, m in Map.Monsters do
        -- TODO missing robustness: for this loop to work no other monsters sharing Lord Nilbogs index need to exist  
        if m.Id == LordNilbogMonsterTxtId then
            monsterLordNilbog = m
        end
    end
    if monsterLordNilbog == nil then
        monsterLordNilbog = SummonMonster(LordNilbogMonsterTxtId, -115, 55, 1, true)
    end

    local ogreChieftain
    -- this code block fixes bolstering of stats borrowed from Ogre Chieftain
    for _, m in Map.Monsters do
        if m.id == OgreChieftainTxtId then
            ogreChieftain = m
        end
    end
    if ogreChieftain == nil then
        ogreChieftain = SummonMonster(OgreChieftainTxtId, -1076, -5762, 856, true)
        ogreChieftain.AIState = const.AIState.Removed
    end

    if monsterLordNilbog.AIState ~= const.AIState.Dead then
        monsterLordNilbog.HP = ogreChieftain.FullHP
    end
    monsterLordNilbog.FullHP = ogreChieftain.FullHP
    monsterLordNilbog.Exp = ogreChieftain.Exp
    monsterLordNilbog.Attack1.DamageAdd = ogreChieftain.Attack1.DamageAdd
    monsterLordNilbog.Attack1.DamageDiceSides = ogreChieftain.Attack1.DamageDiceSides
    monsterLordNilbog.Attack1.DamageDiceCount = ogreChieftain.Attack1.DamageDiceCount

    -- Changing these doesn't matter because it will reset after map leave
    Game.MonstersTxt[LordNilbogMonsterTxtId].Name = "Lord Nilbog"

    MakeGoblinsHostile()
    return monsterLordNilbog
end