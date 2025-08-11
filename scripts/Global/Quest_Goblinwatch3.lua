local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5
local goblinwatchHouse = 1463
local UrokNPC_ID = 1081
local NewSorpigal = "oute3.odm"
local questName = "Quest_Goblinwatch3"
local prevName = "Quest_Goblinwatch2"
local FarmerToddMonsterTxtId = 577 -- Game.MonstersTxt[FarmerToddMonsterTxtId]
local FarmerToddNPC_ID = 1229
local NilbogNPC_ID = 1239
local humansNPCTextIndex = 2064

-- declared here for hoisting
local OnQuestGiven
local OnQuestDone 
local CreateTodd

Quest{
    questName,
    NPC = UrokNPC_ID,
	Give = function() 
        local FarmerToddMonsterTxtId = 577
        mon = SummonMonster(FarmerToddMonsterTxtId, -1076, -5762, 856, true)
        CreateTodd(mon)
    end,
    CheckDone = function() return vars.FarmerToddDead == true  end,
    CanShow = function() return vars.Quests[prevName] == "Done" and Game.NPC[UrokNPC_ID].House == goblinwatchHouse end,
	Exp = 2000,
	Gold = 2000,
    Slot = C,
    Done = function() 
        vars.FarmerToddDead = nil       
        NPCTopic{
            Topic = "Lord Nilbog",
            Slot = B,
            Text = "Speak with Lord Nilbog for more work.",
            NPC = UrokNPC_ID,
        }
    end, -- cleanup
}.SetTexts{
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

Take this pouch of gold as reward.]],
}

OnQuestGiven = function()
    local FarmerToddMonsterTxtId = 577 -- Game.MonstersTxt[FarmerToddMonsterTxtId]
    for _, mon in Map.Monsters do
        -- TODO missing robustness: for this loop to work no other monsters sharing Farmer Todd index need to exist  
		if mon.Id == FarmerToddMonsterTxtId then
            CreateTodd(mon)
        end
	end
end

CreateTodd = function(mon)
    if mon.AIState == const.AIState.Removed then
        return
    end

    local masterSwordsmanMonsterTxtId = 588
    local masterSwordsman = Game.MonstersTxt[masterSwordsmanMonsterTxtId]

    -- this code block fixes bolstering of stats borrowed from Master Swordsman
    local masterSwordsmanAlreadySpawned
    for _, m in Map.Monsters do
        if m.id == masterSwordsmanMonsterTxtId then
            masterSwordsmanAlreadySpawned = true
        end
    end
    if masterSwordsmanAlreadySpawned ~= true then
        tempMon = SummonMonster(masterSwordsmanMonsterTxtId, -1076, -5762, 856, false)
        tempMon.AIState = const.AIState.Removed
    end

    mon.AIType = 3
    
    if mon.AIState ~= const.AIState.Dead then
        mon.HP = masterSwordsman.FullHP
    end
	mon.FullHP = masterSwordsman.FullHP
    mon.Exp = masterSwordsman.Exp
    mon.Attack1.DamageAdd = masterSwordsman.Attack1.DamageAdd
	mon.Attack1.DamageDiceSides = masterSwordsman.Attack1.DamageDiceSides
	mon.Attack1.DamageDiceCount = masterSwordsman.Attack1.DamageDiceCount

    -- Changing these doesn't matter because it will reset after map leave
    monTxt = Game.MonstersTxt[FarmerToddMonsterTxtId]
    monTxt.Name = "Farmer Todd"
    mon.NPC_ID = FarmerToddNPC_ID
    Game.NPC[FarmerToddNPC_ID].Name = "Farmer Todd"
    Game.NPC[FarmerToddNPC_ID].Pic = 1

    Greeting{
        NPC = FarmerToddNPC_ID,
        Text = "Hi there"
    }

    NPCTopic{
        Slot = A,
        NPC = FarmerToddNPC_ID,
        Topic = "Goblins",
        Text = [[
They might look scary, but in reality they are really meek.

One of them tried to jump me the other day.

I just kicked it in the knee and it hobbled away crying.]]
    }

end

local function SetupLordNilbogArc()
    local UrokNPC_ID = 1081

    -- Remove greeting from Urok

    local humansNPCTextIndex = 2064

    Game.NPCText[humansNPCTextIndex] = [[
[Urok laughts eerily]

Humans think they are safe in their town, but Lord Nilbog and Urok will show them!]]
            
    NPCTopic{
        Topic = "Lord Nilbog",
        Slot = B,
        Text = "The lord of Goblinwatch",
        NPC = UrokNPC_ID,
    }

    Greeting{
        NPC = UrokNPC_ID,
    }

end

function events.AfterLoadMap(WasInGame)
    if Map.Name == NewSorpigal then
        if vars.Quests[questName] == "Given" then
            OnQuestGiven()
        end
        if vars.Quests[questName] == "Done" or vars.FarmerToddDead == true then
            SetupLordNilbogArc()
        end
    end

 end


function events.MonsterKilled(mon) 
    if Map.Name == NewSorpigal and Game.MonstersTxt[mon.Id].Name == "Farmer Todd" then
        vars.FarmerToddDead = true
        Game.NPC[NilbogNPC_ID].House = goblinwatchHouse
        SetupLordNilbogArc()
    end
end
