-- ============================================================================
--  Kreegan Questline
-- ============================================================================
-- Notes ----------------------------------------------------------------------
-- empty house in blackshire 1387
--[[

-- kreegan pics 971, 1020
 971 fits best

Names:
if we allow h3

 - Cahl / Carl


1. Kill messenger
2. Kill "Kreegan" army "disguised" as humans Army (what is their actual purpose, perhaps cleansing Temple of Baa or taking Castle Kriegspire?)

3. After that party is approached by a stranger, tells party Carter is a Kreegan that has tricked them.
Gives Quest to lure Carter into ambush
   - party can tell Carter the truth, Carter will then want to spring the ambush with party help
   - party can lure Carter out.

Regardless of choice party can still take the decision to either help Carter or ambusher when the ambush springs
But to make it a bit cleaner a dialoge option will be the decision maker.



else
    Khor-Tarr / Carter
    Baal-Zath / Balzar
    A'karr-on / Aaron
]] --

-- Base data ------------------------------------------------------------------
local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5

-- Houses
local blackShireHouse = 1387
local khorTarrHideoutHouse = 1278
local freeHavenCorvinHouse = 1418

-- Locations
local blackshire = "outb2.odm"
local kriegspire = "outb1.odm"
local freehaven = "outc2.odm"
local KreeganQuestLine = "Kreegan"

-- Quest IDs
local Quest_Kreegan_KillMessenger = "Quest_Kreegan_KillMessenger"
local Quest_Kreegan_KillArmy = "Quest_Kreegan_KillArmy"
local Quest_Kreegan_Ambush = "Quest_Kreegan_Ambush"
local Quest_Kreegan_HideKhorTarr = "Quest_Kreegan_HideKhorTarr"

RegisterSharedHouseUse {
    Key = "KreeganBlackshireHouse",
    QuestLine = KreeganQuestLine,
    Map = blackshire,
    House = blackShireHouse
}

RegisterSharedHouseUse {
    Key = "KreeganKhorTarrHideout",
    QuestLine = KreeganQuestLine,
    Quest = Quest_Kreegan_HideKhorTarr,
    Map = kriegspire,
    House = khorTarrHideoutHouse
}

RegisterSharedHouseUse {
    Key = "KreeganFreeHavenCorvinHouse",
    QuestLine = KreeganQuestLine,
    Quest = Quest_Kreegan_Ambush,
    Map = freehaven,
    House = freeHavenCorvinHouse
}

-- Encounter IDs
local KreeganMessengerEncounterName = "KreeganMessenger"
local KreeganArmyEncounterName = "KreeganArmy"
local KreeganAmbushKhorTarrEncounterName = "KreeganAmbushKhorTarrSide"
local KreeganAmbushHumanEncounterName = "KreeganAmbushHumanSide"

-- Text
local Quest_Kreegan_KillArmyDoneText = [[You have slain their commander?

Excellent.

Without him their force will break up eventually.]]

local Quest_Kreegan_KillArmyDoneText_Bonus = [[You have slain their commander?

And you took care of the rest of the army.

Excellent.]]

-- NPC IDs
local carterNPC_ID = 111
local droppaMaPantzNPC_ID = 1000
local enemyMessengerNPC_ID = 645
local ambushContactNPC_ID = 645

-- Army monsters
local armyCommander = 587 -- expert swordsman
local armyFighter = 537 -- veteran 
local armyArcher = 475 -- archer
local armySupportMage = 631 -- magician
local armyOffensiveMage = 632 -- magician

-- Monster IDs
local enemyMessengerMonsterID = 637 -- thief
local khorTarrMonsterID = 501
local devilSpawnMonsterID = 502
local devilWorkerMonsterID = 503
local devilWarriorMonsterID = 504

local ambushCaptainMonsterID = 555
local ambushArcherMonsterID = 475
local ambushMasterMonkMonsterID = 583

-- Ambush setup
local khorTarrAmbushGroup = 60
local ambusherGroup = 61
local ambushX = -6486
local ambushY = -20318
local ambushZ = 225
local ambushPaddingX = 3000
local ambushPaddingY = 3000
local ambushPaddingZ = 400

-- Hoisted forward declarations ------------------------------------------------
local createCarterNPCBeforeReveal
local createCarterNPCAfterReveal
local createAmbushContactNPC
local summonHumanArmyInKriegspire
local SetKreeganArmyMonsterHostile
local ConfigureKreeganArmyFormationMonster
local makeTroop
local CreateEnemyMessenger
local SummonEnemyMessenger
local MakeEnemyMessengerFriendly
local FindEnemyMessenger
local MonitorKreeganArmyHostility
local MonitorKreeganStoryProgress
local MonitorKreeganAmbushThresholds
local IsKreeganArmyMonster
local ApplyKreeganArmySetup
local ApplyKreeganArmyMonsterSetup
local IsKreeganArmyCurrentlyHostile
local RecordKreeganArmyFormationAnchor
local HoldKreeganArmyFormation
local PinKreeganArmyFormation
local SetKreeganArmyHostile
local ApplyKreeganAmbushSetup
local TryAddKhorTarrFollower
local ReturnKhorTarrToHouse
local StartKhorTarrEscort
local StartKreeganAmbush
local ResolveKreeganAmbush
local TriggerKreeganFollowupDialog
local ApplyKreeganAmbushFactionHostility
local ActivateKreeganAmbushActors
local SetAmbushMonsterHostile
local SetKhorTarrMonsterHostile
local MarkKreeganAmbushEncountersForRemoval
local KillKhorTarrSideSummons
local ConfigureKreeganQuestMonster
local CreateKhorTarrMonster
local SummonKreeganAmbushEncounter
local SummonKhorTarrReinforcements
local IsAmbushHumanMonster
local IsKhorTarrSideMonster
local IsKhorTarrMonster
local IsFriendlyKreeganAmbushMonster
local HasActiveKreeganAmbushActors
local RemoveKreeganAmbushActorMonsters
local FinishKhorTarrHideoutEscort
local ResetNPCDialogState
local CompleteKhorTarrFollowup
local CompleteAmbusherFollowup

-- QuestStage wrapper (cosmetic grouping) -------------------------------------
local function QuestStage(name)
    return function(block)
        return block
    end
end

-- Helpers --------------------------------------------------------------------
local function InMap(map)
    return Map.Name == map
end

local function InBlackshire()
    return InMap(blackshire)
end

local function InKriegspire()
    return InMap(kriegspire)
end

local function InFreehaven()
    return InMap(freehaven)
end

local function InKreeganAmbushArea()
    return InKriegspire() and math.abs(Party.X - ambushX) <= ambushPaddingX and math.abs(Party.Y - ambushY) <= ambushPaddingY and
               math.abs(Party.Z - ambushZ) <= ambushPaddingZ
end

local function SafeToInterruptParty()
    return Game.CurrentScreen == 0 and not (Party.EnemyDetectorRed or Party.EnemyDetectorYellow)
end

local function MonsterClass(monsterId)
    return math.floor((monsterId + 2) / 3)
end

local function GetMonsterEncounterClasses(encounterName)
    local classesById = {}
    local classes = {}
    local encounter = GetMonsterEncounter(encounterName, kriegspire)

    if type(encounter) ~= "table" or type(encounter.monsters) ~= "table" then
        return classes
    end

    for _, record in ipairs(encounter.monsters) do
        if type(record.id) == "number" then
            local class = MonsterClass(record.id)
            if classesById[class] ~= true then
                classesById[class] = true
                table.insert(classes, class)
            end
        end
    end

    return classes
end

local function GetMonsterEncounterAllyClass(encounterName)
    local classes = GetMonsterEncounterClasses(encounterName)
    return classes[1] or 9999
end

local function EndKreeganAmbushQuestline(message)
    vars.KreeganKhorTarrFollowupPending = nil
    vars.KreeganAmbusherFollowupPending = nil
    vars.KreeganDialogStage = nil
    vars.Quests[Quest_Kreegan_Ambush] = "Done"
    MarkKreeganAmbushEncountersForRemoval()
    evt.PlaySound(142) -- fail sound
    Message(message)
end

-- NPC helpers ----------------------------------------------------------------
ResetNPCDialogState = function(npcId)
    for i = 0, 5 do
        Game.NPC[npcId].Events[i] = 0
    end
    -- Greeting { NPC = npcId }
end

-- Monster helpers ------------------------------------------------------------
ConfigureKreeganQuestMonster = function(mon, hostile, ally, group)
    mon.NoFlee = true
    mon.GuardRadius = mon.GuardRadius * 2
    mon.Group = group or mon.Group
    if ally ~= nil then
        mon.Ally = ally
    end
    if hostile ~= nil then
        mon.Hostile = hostile
        mon.ShowAsHostile = hostile
        mon.HostileType = hostile and 4 or 3
    end
end

CreateKhorTarrMonster = function(mon, resetHP)
    local hpMultiplier = 2
    local expMultiplier = 2
    local oldFullHP = mon.FullHP
    local oldHP = mon.HP

    Game.MonstersTxt[khorTarrMonsterID].Name = Game.NPC[carterNPC_ID].Name
    mon.FullHP = math.max(1, math.floor(mon.FullHP * hpMultiplier))
    if resetHP then
        mon.HP = mon.FullHP
    else
        local hpRatio = oldFullHP > 0 and oldHP / oldFullHP or 1
        mon.HP = math.max(1, math.floor(mon.FullHP * hpRatio))
    end
    mon.Exp = math.max(1, math.floor(mon.Exp * expMultiplier))
    mon.Fly = 0
end


-- Ambush helpers -------------------------------------------------------------
IsAmbushHumanMonster = function(mon)
    return MonsterEncounterContainsMonster(GetMonsterEncounter(KreeganAmbushHumanEncounterName, kriegspire), mon)
end

IsKhorTarrSideMonster = function(mon)
    return MonsterEncounterContainsMonster(GetMonsterEncounter(KreeganAmbushKhorTarrEncounterName, kriegspire), mon)
end

IsKhorTarrMonster = function(mon)
    return mon.Id == khorTarrMonsterID and IsKhorTarrSideMonster(mon)
end

IsFriendlyKreeganAmbushMonster = function(mon)
    if not InKriegspire() or vars.KreeganAmbushStarted ~= true or vars.KreeganAmbushSide == nil or mon == nil then
        return false
    end

    if vars.KreeganAmbushSide == "KhorTarr" then
        return IsKhorTarrSideMonster(mon)
    elseif vars.KreeganAmbushSide == "Ambushers" then
        return IsAmbushHumanMonster(mon)
    end

    return false
end

ApplyKreeganAmbushSetup = function(resetPowerHP)
    createAmbushContactNPC()
    Game.MonstersTxt[khorTarrMonsterID].Name = Game.NPC[carterNPC_ID].Name
    Game.MonstersTxt[ambushMasterMonkMonsterID].Name = Game.NPC[ambushContactNPC_ID].Name

    local encounters = {
        {
            name = KreeganAmbushKhorTarrEncounterName,
            setup = function(mon)
                if mon.Id == khorTarrMonsterID then
                    CreateKhorTarrMonster(mon, resetPowerHP == true)
                end
                if resetPowerHP == true then
                    ConfigureKreeganQuestMonster(mon, false, 9999, khorTarrAmbushGroup)
                else
                    ConfigureKreeganQuestMonster(mon, mon.Hostile, mon.Ally, khorTarrAmbushGroup)
                end
            end
        },
        {
            name = KreeganAmbushHumanEncounterName,
            setup = function(mon)
                if mon.Id == ambushMasterMonkMonsterID then
                    local ambushPowerMonsterID = 585 -- Master monk
                    local ambushContactPowerMonster = Game.MonstersTxt[ambushPowerMonsterID]
                    Game.MonstersTxt[ambushMasterMonkMonsterID].Name = Game.NPC[ambushContactNPC_ID].Name
                    ApplyMonsterPowerFromMonster(mon, ambushContactPowerMonster, resetPowerHP, 6)
                elseif mon.Id == ambushArcherMonsterID then
                    ApplyVeteranArcher(mon)
                elseif mon.Id == ambushCaptainMonsterID then
                    local minotaurID = 580
                    local minotaurPowerMonster = Game.MonstersTxt[minotaurID]
                    ApplyMonsterPowerFromMonster(mon, minotaurPowerMonster, resetPowerHP)
                end
                if resetPowerHP == true then
                    ConfigureKreeganQuestMonster(mon, false, 9999, ambusherGroup)
                else
                    ConfigureKreeganQuestMonster(mon, mon.Hostile, mon.Ally, ambusherGroup)
                end
            end
        }
    }

    for _, encounterData in ipairs(encounters) do
        ForEachMonsterEncounter(GetMonsterEncounter(encounterData.name, kriegspire), function(_, mon)
            if mon.HP > 0 then
                encounterData.setup(mon)
            end
        end)
    end
end

RemoveKreeganAmbushActorMonsters = function(removeKhorTarr, removeAmbushContact)
    for _, mon in Map.Monsters do
        if (removeKhorTarr and IsKhorTarrSideMonster(mon)) or (removeAmbushContact and IsAmbushHumanMonster(mon) and mon.Id == ambushMasterMonkMonsterID) then
            mon.AIState = const.AIState.Removed
        end
    end
end

HasActiveKreeganAmbushActors = function()
    local khorTarrEncounter = GetMonsterEncounter(KreeganAmbushKhorTarrEncounterName, kriegspire)
    local humanEncounter = GetMonsterEncounter(KreeganAmbushHumanEncounterName, kriegspire)
    if not khorTarrEncounter and not humanEncounter then
        return false
    end

    return MonsterEncounterHasAnyActive(khorTarrEncounter) == true or MonsterEncounterHasAnyActive(humanEncounter) == true
end


-- Hideout escort -------------------------------------------------------------
FinishKhorTarrHideoutEscort = function()
    local khorTarrTravelingWithParty = NPCFollowers.NPCInGroup(carterNPC_ID)

    if vars.Quests[Quest_Kreegan_HideKhorTarr] ~= "Given" or vars.KreeganKhorTarrHidden == true or not khorTarrTravelingWithParty then
        return
    end

    NPCFollowers.Remove(carterNPC_ID)
    evt.MoveNPC{carterNPC_ID, khorTarrHideoutHouse}
    vars.KreeganKhorTarrHidden = true
    createCarterNPCAfterReveal()
    HouseMessage("Khor-Tarr slips inside without another word. It seems he intends to lie low here for a while.")
    -- House/NPC state does not refresh reliably in one step here.
    -- Small delay + reload + refresh gives the most stable result.
    Sleep(1, function() end)
    ReloadHouse(khorTarrHideoutHouse)
    RefreshHouseScreen()
end

-- ============================================================================
--  Quest stages
-- ============================================================================

-- Part 1: Start - Khor-Tarr as Carter ----------------------------------------
QuestStage "Start" {
    Quest{
        Quest_Kreegan_KillMessenger,
        Slot = E,
        NPC = carterNPC_ID,
        Give = function()
            SummonEnemyMessenger()
            evt.PlaySound(205) -- quest sound
        end,
        CanShow = function()
            return InBlackshire() and vars.Quests[Quest_Kreegan_KillMessenger] ~= "Done"
        end,
        CheckDone = function()
            return vars.KreeganMessengerKilled == true
        end,
        Gold = 4000,
        Exp = 5000
    }.SetTexts {
        Topic = "Quest",
        Give = [[
I have reports of an enemy messenger.

He needs to be killed before he reach his target.

He was reported walking near the eastern road outside town.]],
        Undone = "If the messenger is still alive why are you here? He was last reported near the eastern road outside town.",
        Done = [[
Good work!

You have done us a great service.]]
    },

    NPCTopic {
        Slot = A,
        NPC = carterNPC_ID,
        CanShow = function()
            return vars.KreeganEscortIntent == nil
        end,
        Topic = "Secret",
        Text = [[
I'm on a secret mission here.

I normally wouldn't tell anyone, but there is something that makes me trust you.

I'm Queen Catherine's spymaster in Enroth.

Perhaps you could help me out, but you have to keep my existence secret.

Don't trust anyone.]]
    },

    NPCTopic{
        Slot = B,
        NPC = carterNPC_ID,
        CanShow = function()
            return vars.KreeganEscortIntent == nil
        end,
        Topic = "Kreegans",
        Text = [[
The Kreegan, some call them devils, others demons.

They came to Enroth on the Night of the Shooting Stars.

It's my mission here as Queen Catherine's spymaster, to discover their plans and orchestrate their downfall.
]]
    },

    NPCTopic {
        Slot = A,
        NPC = enemyMessengerNPC_ID,
        CanShow = function()
            return InBlackshire() and vars.Quests[Quest_Kreegan_KillMessenger] == "Given" and vars.KreeganMessengerKilled ~= true
        end,
        Topic = "I'm busy",
        Text = "Not now. I'm busy, I simply don't have the time to talk to every traveler I meet on the road."
    }
}

-- Part 2: Kill the disguised army --------------------------------------------
QuestStage "Kill Army" {
    Quest{
        Quest_Kreegan_KillArmy,
        Slot = E,
        NPC = carterNPC_ID,
        Give = function()
            vars.KreeganCommanderKilled = nil
            vars.KreeganArmyDestroyed = nil
        end,
        CanShow = function()
            return InBlackshire() and vars.Quests[Quest_Kreegan_KillMessenger] == "Done" and vars.Quests[Quest_Kreegan_Ambush] == nil -- and vars.Quests[Quest_Kreegan_KillArmy] ~= "Done"
        end,
        CheckDone = function()
            return vars.KreeganCommanderKilled == true
        end,
        Done = function()
            Message(vars.KreeganArmyDestroyed == true and Quest_Kreegan_KillArmyDoneText_Bonus or Quest_Kreegan_KillArmyDoneText)
            vars.KreeganRevealTriggerTime = Game.Time
            if vars.KreeganArmyDestroyed == true then
                evt.Add("Gold", 10000)
            else
                evt.Add("Gold", 6000)
            end
            MarkMonsterEncounterForRemoval(KreeganArmyEncounterName, kriegspire)
            evt.PlaySound(133) -- gold sound
        end,
        Exp = 15000
    }.SetTexts {
        FirstTopic = "An enemy force gathers",
        Topic = "Enemy force",
        Give = [[There is an enemy force east of the town of Kriegspire.

My intelligence says they are Kreegans in human disguise. Gathering before they strike at a greater target.

They are weakened in this form.

Their commander is no ordinary fiend, but a greater lieutenant of the Hive.

Cut down their commander and the rest will fall into chaos.

Kill them all and I'll reward you further.]],
        Done = false,
        Undone = "The commander still lives. Go east of the town of Kriegspire and end him before the force can advance!",
        After = [[Excellent work.

I don't have any more jobs for you at this time.]]
    }
}

-- Part 3: Reveal Carter as Khor-Tarr -----------------------------------------

    Greeting {
        NPC = ambushContactNPC_ID,
        CanShow = function()
            return vars.KreeganDialogStage == "Reveal"
        end,
        Text = [[At last I've caught up to you!

The damage you have done have endangered the entire continent.

You thwarted the Superior Temple of Baa extermination force, and killed one of the finest military commanders we had left.

Now the question. Were you misled, or are you in collusion with the Kreegans?
]]
}

    NPCTopic {
        Slot = A,
        NPC = ambushContactNPC_ID,
        CanShow = function()
            return vars.KreeganDialogStage == "Reveal"
        end,
        Topic = "The Kreegans?",
        Ungive = function()
            createCarterNPCAfterReveal()
            vars.KreeganRevealSeen = true
            vars.KreeganDialogStage = nil
            vars.Quests[Quest_Kreegan_Ambush] = "Given"
            evt.PlaySound(42385) -- remove curse sound
        end,
        Text = [[
Ah I see now. You were tricked by the Kreegan that goes under the guise of Carter.

I have cast a small enchantment that will pierce his disguise. From now on you will see his true form.

He is no man of Enroth. He is Khor-Tarr, a high level Kreegan infiltrator.

You can still make up for some off the harm that you have done.

Turn the table. Trick him with you to the roads west of Kriegspire, and we will set an ambush.]]
    }

-- Part 4: Escort Khor-Tarr to Kriegspire -------------------------------------
QuestStage "Escort Khor-Tarr" {
    NPCTopic {
        Slot = B,
        NPC = carterNPC_ID,
        CanShow = function()
            return vars.Quests[Quest_Kreegan_Ambush] == "Given" and vars.KreeganAmbushStarted ~= true and vars.KreeganEscortIntent ~= "Tricked"
        end,
        Topic = "Warn Khor-Tarr",
        Ungive = function()
            StartKhorTarrEscort("Warned")
            -- find evil laughter sound?
        end,
        Text = [[
[Khor-Tarr smiles menacingly]

I've underestimated you. I am pleased to see that you understand that In the end, this will be the best for everyone.

...

The men that lays waiting in ambush, lets put an end to their foolery.

Lets spring that little trap of their's on the west roads of Kriegspire.]]
    },

    NPCTopic {
        Slot = C,
        NPC = carterNPC_ID,
        CanShow = function()
            return vars.Quests[Quest_Kreegan_Ambush] == "Given" and vars.KreeganAmbushStarted ~= true and vars.KreeganEscortIntent ~= "Warned"
        end,
        Ungive = function()
            StartKhorTarrEscort("Tricked")
        end,
        Topic = "Lead Khor-Tarr into trap",

        Text = [[
[Khor-Tarr regards you in silence, his demonic features oddly contemplative.]

So there is a hooded figure in Kriegspire, asking questions about someone called Carter, and you do not know where this stranger's loyalties lie.

I will need to join you and look upon this stranger myself, to judge whether he is friend or foe.

I cannot allow some unknown meddler to expose my cover as Queen Catherine's spymaster.]]
    },

    NPCTopic {
        Slot = D,
        NPC = carterNPC_ID,
        CanShow = function()
            return InBlackshire() and vars.Quests[Quest_Kreegan_Ambush] == "Given" and vars.KreeganEscortIntent ~= nil and
                       vars.KreeganAmbushStarted ~= true and not NPCFollowers.NPCInGroup(carterNPC_ID)
        end,
        Topic = "Join",
        Ungive = function()
            if TryAddKhorTarrFollower() then
                RefreshHouseScreen()
                Message("Excellent. Lets leave at once.")
            end
        end,
        Text = "Make room for me among your followers and I will come."
    }
}

-- Part 5: Ambush choice and resolution ---------------------------------------
QuestStage "Ambush" {
    Greeting {
        NPC = ambushContactNPC_ID,
        CanShow = function()
            return vars.KreeganDialogStage == "AmbushChoice"
        end,
        Text = "You brought him. Now lets end that foul demon!"
    },

    Greeting {
        NPC = ambushContactNPC_ID,
        CanShow = function()
            return vars.KreeganDialogStage == "AmbusherFollowup"
        end,
        Text = [[
Khor-Tarr is dead.

You have repaid some of your debt.

However I don't have more work for you now.]]
    },

    NPCTopic {
        Slot = A,
        NPC = ambushContactNPC_ID,
        CanShow = function()
            return vars.KreeganDialogStage == "AmbushChoice"
        end,
        Topic = "Help Khor-Tarr",
        Ungive = function()
            ResolveKreeganAmbush("KhorTarr")
            ExitCurrentScreen()
            evt.PlaySound(160) -- encounter for ambush
        end,
        Text = "Then stand and die with him traitor!"
    },

    NPCTopic {
        Slot = B,
        NPC = ambushContactNPC_ID,
        CanShow = function()
            return vars.KreeganDialogStage == "AmbushChoice"
        end,
        Topic = "Help ambushers",
        Ungive = function()
            ResolveKreeganAmbush("Ambushers")
            ExitCurrentScreen()
            evt.PlaySound(160) -- encounter for ambush
        end,
        Text = "Wise enough at last. Khor-Tarr dies here."
    },

    NPCTopic {
        Slot = A,
        NPC = ambushContactNPC_ID,
        CanShow = function()
            return vars.KreeganDialogStage == "AmbusherFollowup"
        end,
        Topic = "The ambush is done",
        Ungive = function()
            CompleteAmbusherFollowup()
        end,
        Text = [[
Khor-Tarr is dead.

You have repaid some of your debt.

I don't have more work for you now.

You can find me ontop of Castle Temper in Free haven]]
    }
}

-- Part 6A: Hide Khor-Tarr after siding with him -------------------------------
QuestStage "Hide Khor-Tarr" {
    NPCTopic {
        Slot = A,
        NPC = carterNPC_ID,
        CanShow = function()
            return vars.KreeganDialogStage == "KhorTarrFollowup"
        end,
        Topic = "Lay low in Kriegspire",
        Ungive = function()
            CompleteKhorTarrFollowup()
        end,
        Text = [[
Excellent.

Those meddlers are dead, but I cannot remain here.

There is a Baa fanatic in Kriegspire, a fool named Droppa MaPantz.

He lives in the north eastern part of the town.

Take me to him, and I will stay low for a while.]]
    },

    Quest{
        Quest_Kreegan_HideKhorTarr,
        Slot = E,
        NPC = carterNPC_ID,
        CanShow = function()
            return (vars.Quests[Quest_Kreegan_HideKhorTarr] == "Given" and vars.KreeganKhorTarrHidden ~= true and NPCFollowers.NPCInGroup(carterNPC_ID)) or
                       (InBlackshire() and vars.Quests[Quest_Kreegan_HideKhorTarr] == "Given" and vars.KreeganKhorTarrHidden ~= true) or
                       (InKriegspire() and vars.Quests[Quest_Kreegan_HideKhorTarr] == "Given" and vars.KreeganKhorTarrHidden == true)
        end,
        CheckDone = function()
            return vars.KreeganKhorTarrHidden == true
        end,
        Exp = 10000,
        Gold = 5000,
    }.SetTexts {
        Topic = "Lay low in Kriegspire",
        TopicGiven = "Lay low in Kriegspire",
        Award = "Traitor of Enroth",
        Undone = [[
There is a Baa fanatic in Kriegspire, a fool named Droppa MaPantz.

He lives in the north eastern part of the town.

Take me to him, and I will stay low for a while.]],
        Done = [[
Good.

I will stay low here for a while, until things cool down.

You have earned your reward.]]
    },

    NPCTopic {
        Slot = A,
        NPC = carterNPC_ID,
        CanShow = function()
            return InBlackshire() and vars.Quests[Quest_Kreegan_HideKhorTarr] == "Given" and not NPCFollowers.NPCInGroup(carterNPC_ID) and
                       vars.KreeganKhorTarrHidden ~= true
        end,
        Topic = "Join",
        Ungive = function()
            if TryAddKhorTarrFollower() then
                RefreshHouseScreen()
            else
                ReturnKhorTarrToHouse()
            end
        end,
        Text = "Make room for me among your followers. The road to Kriegspire will not wait forever."
    },

    NPCTopic {
        Slot = A,
        NPC = droppaMaPantzNPC_ID,
        CanShow = function()
            return InKriegspire() and Game.NPC[carterNPC_ID].House == khorTarrHideoutHouse
        end,
        Topic = "Carter",
        Text = [[
Yes, yes, Carter!

He is a follower of Baa, just like me.

But that is a secret. A secret!

SSHHH!]]
    },

    NPCTopic {
        Slot = A,
        NPC = carterNPC_ID,
        CanShow = function()
            return InKriegspire() and vars.Quests[Quest_Kreegan_HideKhorTarr] == "Done" and Game.NPC[carterNPC_ID].House == khorTarrHideoutHouse
        end,
        Topic = "Staying low",
        Text = [[
I will remain here a while longer.

That fool is driving me mad. The simpleton believes I am merely a follower of Baa.

I am tempted to show him the true extent of my power. Perhaps that would silence him for a while.]]
    }
}

-- ============================================================================
--  Quest runtime helpers
-- ============================================================================

-- NPC setup ------------------------------------------------------------------
createCarterNPCBeforeReveal = function()
    ResetNPCDialogState(carterNPC_ID)
    Game.NPC[carterNPC_ID].House = blackShireHouse
    Game.NPC[carterNPC_ID].Name = "Carter"
    Game.NPC[carterNPC_ID].Pic = 265
    Game.NPC[carterNPC_ID].Profession = 0
end

createCarterNPCAfterReveal = function()
    ResetNPCDialogState(carterNPC_ID)
    if vars.KreeganKhorTarrHidden == true then
        Game.NPC[carterNPC_ID].House = khorTarrHideoutHouse
    elseif NPCFollowers.NPCInGroup(carterNPC_ID) or
        (vars.KreeganAmbushStarted == true and vars.Quests[Quest_Kreegan_Ambush] ~= "Done") then
        Game.NPC[carterNPC_ID].House = 0
    else
        Game.NPC[carterNPC_ID].House = blackShireHouse
    end
    Game.NPC[carterNPC_ID].Name = "Khor-Tarr"
    Game.NPC[carterNPC_ID].Pic = 971
    Game.NPC[carterNPC_ID].Profession = 0
end

createAmbushContactNPC = function()
    ResetNPCDialogState(ambushContactNPC_ID)
    Game.NPC[ambushContactNPC_ID].Name = "Corvin"
    Game.NPC[ambushContactNPC_ID].Pic = 0035
    Game.NPC[ambushContactNPC_ID].Profession = 0
end

-- Follower and quest handoff helpers -----------------------------------------
TryAddKhorTarrFollower = function()
    if NPCFollowers.NPCInGroup(carterNPC_ID) then
        return true
    end
    if #vars.NPCFollowers >= 4 or NPCFollowers.GetTotalFee() >= 100 then
        -- The standard text is confusing, the player might try to remove a party member not follower
        -- Game.GlobalTxt[533] I cannot join you, you're party is full
        Message("I cannot join you, you don't have room for another follower")
        return false
    end
    if NPCFollowers.Add(carterNPC_ID) then
        evt.MoveNPC{carterNPC_ID, 0}
        evt.PlaySound(205) -- quest sound
        return true
    end
    return false
end

ReturnKhorTarrToHouse = function()
    NPCFollowers.Remove(carterNPC_ID)
    Game.NPC[carterNPC_ID].House = blackShireHouse
    Message("Since there was no room for another follower. Khor-Tarr has returned to his house in Blackshire. Meet him there for further instructions")
end

CompleteAmbusherFollowup = function()
    vars.KreeganDialogStage = nil
    vars.Quests[Quest_Kreegan_Ambush] = "Done"
    vars.KreeganAmbusherFollowupSeen = true
end

CompleteKhorTarrFollowup = function()
    vars.KreeganDialogStage = nil
    vars.Quests[Quest_Kreegan_Ambush] = "Done"
    vars.Quests[Quest_Kreegan_HideKhorTarr] = "Given"
    vars.KreeganKhorTarrFollowupSeen = true
    Game.NPC[carterNPC_ID].House = blackShireHouse
    if TryAddKhorTarrFollower() ~= true then
        ReturnKhorTarrToHouse()
    end
end

StartKhorTarrEscort = function(intent)
    vars.KreeganEscortIntent = intent
end

-- Ambush encounter -----------------------------------------------------------
SummonKreeganAmbushEncounter = function(showDialog)
    local khorTarrMapMonIndexes = {}
    local humanMapMonIndexes = {}

    local _, khorTarrIndex = SummonMonster(khorTarrMonsterID, Party.X + 150, Party.Y + 150, Party.Z, true)
    table.insert(khorTarrMapMonIndexes, khorTarrIndex)
    vars.KreeganAmbushKhorTarrSummoned = true

    local meleeFormation = {
        {ambushCaptainMonsterID, ambushX + 0, ambushY - 40, ambushZ},
        {ambushCaptainMonsterID, ambushX - 90, ambushY - 130, ambushZ},
        {ambushCaptainMonsterID, ambushX + 90, ambushY - 130, ambushZ},
        {ambushCaptainMonsterID, ambushX - 170, ambushY - 220, ambushZ},
        {ambushCaptainMonsterID, ambushX - 60, ambushY - 250, ambushZ},
        {ambushCaptainMonsterID, ambushX + 60, ambushY - 250, ambushZ},
        {ambushCaptainMonsterID, ambushX + 170, ambushY - 220, ambushZ},
        {ambushCaptainMonsterID, ambushX - 260, ambushY - 340, ambushZ},
        {ambushCaptainMonsterID, ambushX - 170, ambushY - 390, ambushZ},
        {ambushCaptainMonsterID, ambushX - 85, ambushY - 425, ambushZ},
        {ambushCaptainMonsterID, ambushX + 0, ambushY - 445, ambushZ},
        {ambushCaptainMonsterID, ambushX + 85, ambushY - 425, ambushZ},
        {ambushCaptainMonsterID, ambushX + 170, ambushY - 390, ambushZ},
        {ambushCaptainMonsterID, ambushX + 260, ambushY - 340, ambushZ},
    }

    local archerFormation = {
        {ambushArcherMonsterID, ambushX - 140, ambushY - 420, ambushZ},
        {ambushArcherMonsterID, ambushX - 45, ambushY - 455, ambushZ},
        {ambushArcherMonsterID, ambushX + 45, ambushY - 455, ambushZ},
        {ambushArcherMonsterID, ambushX + 140, ambushY - 420, ambushZ},
        {ambushArcherMonsterID, ambushX - 220, ambushY - 555, ambushZ},
        {ambushArcherMonsterID, ambushX - 75, ambushY - 600, ambushZ},
        {ambushArcherMonsterID, ambushX + 75, ambushY - 600, ambushZ},
        {ambushArcherMonsterID, ambushX + 220, ambushY - 555, ambushZ},
    }

    for _, ambusherData in ipairs(meleeFormation) do
        local _, ambusherIndex = SummonMonster(ambusherData[1], ambusherData[2], ambusherData[3], ambusherData[4], true)
        table.insert(humanMapMonIndexes, ambusherIndex)
    end

    for _, ambusherData in ipairs(archerFormation) do
        local _, ambusherIndex = SummonMonster(ambusherData[1], ambusherData[2], ambusherData[3], ambusherData[4], true)
        table.insert(humanMapMonIndexes, ambusherIndex)
    end

    local _, ambushContactIndex = SummonMonster(ambushMasterMonkMonsterID , ambushX + 280, ambushY - 180, ambushZ, true)
    table.insert(humanMapMonIndexes, ambushContactIndex)
    vars.KreeganAmbushSwordsmanSummoned = true

    CreateAndSetMonsterEncounterFromIndexes(KreeganAmbushKhorTarrEncounterName, khorTarrMapMonIndexes, kriegspire)
    CreateAndSetMonsterEncounterFromIndexes(KreeganAmbushHumanEncounterName, humanMapMonIndexes, kriegspire)
    ApplyKreeganAmbushSetup(true)
    CreateAndSetMonsterEncounterFromIndexes(KreeganAmbushKhorTarrEncounterName, khorTarrMapMonIndexes, kriegspire)
    CreateAndSetMonsterEncounterFromIndexes(KreeganAmbushHumanEncounterName, humanMapMonIndexes, kriegspire)

    if showDialog then
        evt.SpeakNPC{ambushContactNPC_ID}
    end
end

StartKreeganAmbush = function()
    vars.KreeganAmbushStarted = true
    vars.KreeganDialogStage = "AmbushChoice"
    if NPCFollowers.NPCInGroup(carterNPC_ID) then
        NPCFollowers.Remove(carterNPC_ID)
    end
    Game.NPC[carterNPC_ID].House = 0
    SummonKreeganAmbushEncounter(true)
end

SetAmbushMonsterHostile = function(hostile, ally)
    local resolvedAlly = ally ~= nil and ally or (hostile and GetMonsterEncounterAllyClass(KreeganAmbushHumanEncounterName) or 9999)
    evt.ChangeGroupAlly{ambusherGroup, resolvedAlly}
    evt.SetMonGroupBit{ambusherGroup, const.MonsterBits.Hostile, hostile == true}

    ForEachMonsterEncounter(GetMonsterEncounter(KreeganAmbushHumanEncounterName, kriegspire), function(_, mon)
        if IsAmbushHumanMonster(mon) and mon.HP > 0 and mon.AIState ~= const.AIState.Removed then
            ConfigureKreeganQuestMonster(mon, hostile, resolvedAlly, ambusherGroup)
        end
    end, true)
end

SetKhorTarrMonsterHostile = function(hostile, ally)
    local resolvedAlly = ally ~= nil and ally or (hostile and GetMonsterEncounterAllyClass(KreeganAmbushKhorTarrEncounterName) or 9999)
    evt.ChangeGroupAlly{khorTarrAmbushGroup, resolvedAlly}
    evt.SetMonGroupBit{khorTarrAmbushGroup, const.MonsterBits.Hostile, hostile == true}

    ForEachMonsterEncounter(GetMonsterEncounter(KreeganAmbushKhorTarrEncounterName, kriegspire), function(_, mon)
        if IsKhorTarrSideMonster(mon) and mon.HP > 0 and mon.AIState ~= const.AIState.Removed then
            ConfigureKreeganQuestMonster(mon, hostile, resolvedAlly, khorTarrAmbushGroup)
        end
    end, true)
end

ApplyKreeganAmbushFactionHostility = function()
    LocalHostileTxt()

    local khorTarrSideClasses = GetMonsterEncounterClasses(KreeganAmbushKhorTarrEncounterName)
    local humanSideClasses = GetMonsterEncounterClasses(KreeganAmbushHumanEncounterName)

    for _, khorTarrSideClass in ipairs(khorTarrSideClasses) do
        for _, humanSideClass in ipairs(humanSideClasses) do
            Game.HostileTxt[khorTarrSideClass][humanSideClass] = 4
            Game.HostileTxt[humanSideClass][khorTarrSideClass] = 4
        end
        Game.HostileTxt[khorTarrSideClass][0] = vars.KreeganAmbushSide == "Ambushers" and 4 or 0
    end

    for _, humanSideClass in ipairs(humanSideClasses) do
        Game.HostileTxt[humanSideClass][0] = vars.KreeganAmbushSide == "KhorTarr" and 4 or 0
    end
end

ActivateKreeganAmbushActors = function()
    ForEachMonsterEncounter(GetMonsterEncounter(KreeganAmbushKhorTarrEncounterName, kriegspire), function(_, mon)
        if IsKhorTarrSideMonster(mon) and mon.HP > 0 and mon.AIState ~= const.AIState.Removed then
            mon.AIState = const.AIState.Active
        end
    end, true)
    ForEachMonsterEncounter(GetMonsterEncounter(KreeganAmbushHumanEncounterName, kriegspire), function(_, mon)
        if IsAmbushHumanMonster(mon) and mon.HP > 0 and mon.AIState ~= const.AIState.Removed then
            mon.AIState = const.AIState.Active
        end
    end, true)
end

MarkKreeganAmbushEncountersForRemoval = function()
    MarkMonsterEncounterForRemoval(KreeganAmbushKhorTarrEncounterName, kriegspire)
    MarkMonsterEncounterForRemoval(KreeganAmbushHumanEncounterName, kriegspire)
end

KillKhorTarrSideSummons = function()
    ForEachMonsterEncounter(GetMonsterEncounter(KreeganAmbushKhorTarrEncounterName, kriegspire), function(_, mon)
        if IsKhorTarrMonster(mon) or mon.HP <= 0 or mon.AIState == const.AIState.Dead or mon.AIState == const.AIState.Dying or
            mon.AIState == const.AIState.Removed then
            return
        end

        mon.HP = 0
        evt.PlaySound(mon.SoundDie, mon.X, mon.Y)
        mon.AIState = const.AIState.Dying
        mon:UpdateGraphicState()
        events.cocalls("MonsterKilled", mon, mon:GetIndex(), nil)
    end, true)
end

SummonKhorTarrReinforcements = function(monsterId)
    local khorTarr
    ForEachMonsterEncounter(GetMonsterEncounter(KreeganAmbushKhorTarrEncounterName, kriegspire), function(_, mon)
        if IsKhorTarrMonster(mon) and mon.HP > 0 and mon.AIState ~= const.AIState.Removed and mon.AIState ~= const.AIState.Dead then
            khorTarr = mon
        end
    end, true)
    if not khorTarr then
        return
    end

    local offsets = {
        {220, 0},
        {-220, 0},
        {0, 220},
        {0, -220},
    }
    local summonedIndexes = {}

    for _, offset in ipairs(offsets) do
        local demon, demonIndex = SummonMonster(monsterId, khorTarr.X + offset[1], khorTarr.Y + offset[2], khorTarr.Z, true)
        ConfigureKreeganQuestMonster(demon, khorTarr.Hostile, khorTarr.Ally, khorTarrAmbushGroup)
        table.insert(summonedIndexes, demonIndex)
    end

    AddMonsterEncounterIndexes(KreeganAmbushKhorTarrEncounterName, summonedIndexes, kriegspire)
    ApplyKreeganAmbushFactionHostility()
end

ResolveKreeganAmbush = function(side)
    vars.KreeganAmbushSide = side
    vars.KreeganDialogStage = nil
    ApplyKreeganAmbushFactionHostility()

    if side == "KhorTarr" then
        SetAmbushMonsterHostile(true)
        SetKhorTarrMonsterHostile(false)
        vars.KreeganKhorTarrFollowupPending = true
    else
        SetAmbushMonsterHostile(false)
        SetKhorTarrMonsterHostile(true)
        vars.KreeganAmbusherFollowupPending = true
    end
    ActivateKreeganAmbushActors()
end

TriggerKreeganFollowupDialog = function()
    if not InKriegspire() then
        return
    end

    if vars.KreeganKhorTarrFollowupPending and vars.KreeganAmbushGroupDead ~= true then
        local humanEncounter = GetMonsterEncounter(KreeganAmbushHumanEncounterName, kriegspire)
        if humanEncounter and MonsterEncounterHasAnyActive(humanEncounter) == false then
            vars.KreeganAmbushGroupDead = true
            MarkKreeganAmbushEncountersForRemoval()
        end
    end

    if vars.KreeganKhorTarrFollowupPending and vars.KreeganAmbushGroupDead == true and SafeToInterruptParty() then
        vars.KreeganKhorTarrFollowupPending = nil
        vars.KreeganDialogStage = "KhorTarrFollowup"
        RemoveKreeganAmbushActorMonsters(true, false)
        createCarterNPCAfterReveal()
        evt.SpeakNPC{carterNPC_ID}
    elseif vars.KreeganAmbusherFollowupPending and vars.KreeganAmbushKhorTarrDead == true and vars.KreeganAmbushCorvinDead ~= true and SafeToInterruptParty() then
        vars.KreeganAmbusherFollowupPending = nil
        vars.KreeganDialogStage = "AmbusherFollowup"
        RemoveKreeganAmbushActorMonsters(false, true)
        createAmbushContactNPC()
        evt.SpeakNPC{ambushContactNPC_ID}
    end
end

-- Messenger encounter --------------------------------------------------------
FindEnemyMessenger = function()
    for _, mon in Map.Monsters do
        if mon.Id == enemyMessengerMonsterID and mon.AIState ~= const.AIState.Removed then
            return mon
        end
    end
end

MakeEnemyMessengerFriendly = function()
    local enemyMessengerMon = (enemyMessengerMonsterID + 2):div(3)
    Game.HostileTxt[enemyMessengerMon][0] = 0
end

CreateEnemyMessenger = function(mon, resetPowerHP)
    if mon == nil then
        mon = FindEnemyMessenger()
    end

    if mon == nil or mon.AIState == const.AIState.Removed then
        return
    end

    MakeEnemyMessengerFriendly()
    local enemyMessengerPowerMonsterID = 581 -- minotaur mage
    ApplyMonsterPowerFromMonster(mon, Game.MonstersTxt[enemyMessengerPowerMonsterID], resetPowerHP == true)
    mon.AIType = 3
    mon.NPC_ID = enemyMessengerNPC_ID

    Game.MonstersTxt[enemyMessengerMonsterID].Name = "Marvin the Messenger"
    Game.NPC[enemyMessengerNPC_ID].Name = "Marvin the Messenger"
    Game.NPC[enemyMessengerNPC_ID].Profession = 0
    Game.NPC[enemyMessengerNPC_ID].Pic = 442
end

SummonEnemyMessenger = function()
    local mon = FindEnemyMessenger()
    local messengerEncounter = GetMonsterEncounter(KreeganMessengerEncounterName, blackshire)

    if mon == nil then
        local messengerIndex
        mon, messengerIndex = SummonMonster(enemyMessengerMonsterID, -296, 17180, 192, true)
        CreateEnemyMessenger(mon, true)
        CreateAndSetMonsterEncounterFromIndexes(KreeganMessengerEncounterName, {messengerIndex}, blackshire)
        return
    end

    CreateEnemyMessenger(mon)
    if messengerEncounter == nil then
        CreateAndSetMonsterEncounterFromPredicate(KreeganMessengerEncounterName, function(_, candidate)
            return candidate.Id == enemyMessengerMonsterID and candidate.AIState ~= const.AIState.Removed and candidate.NPC_ID == enemyMessengerNPC_ID
        end, blackshire)
    end
end

-- Kriegspire army encounter --------------------------------------------------
IsKreeganArmyMonster = function(mon)
    return MonsterEncounterContainsMonster(GetMonsterEncounter(KreeganArmyEncounterName, kriegspire), mon)
end

ApplyVeteranArcher = function(mon)
    local rockbeastId = 526
    Game.MonstersTxt[mon.Id].Name = "Veteran Archer"
    ApplyMonsterPowerFromMonster(mon, Game.MonstersTxt[rockbeastId], resetPowerHP == true)
end

ApplyKreeganArmyMonsterSetup = function(mon, resetPowerHP)
    if mon.Id == armyArcher then
        ApplyVeteranArcher(mon)
    elseif mon.Id == armySupportMage then
        local mm7Wizard = 293 -- dispel and hour of power
        Game.MonstersTxt[mon.Id].Name = "Veteran Support Mage"
        ApplyMonsterPowerFromMonster(mon, Game.MonstersTxt[mm7Wizard], resetPowerHP == true)
    elseif mon.Id == armyOffensiveMage then
        local efreetId = 546
        Game.MonstersTxt[mon.Id].Name = "Veteran Mage"
        ApplyMonsterPowerFromMonster(mon, Game.MonstersTxt[efreetId], resetPowerHP == true)
    elseif mon.Id == armyCommander then
        local doomknightId= 566
        ApplyMonsterPowerFromMonster(mon, Game.MonstersTxt[doomknightId], resetPowerHP == true)
        Game.MonstersTxt[mon.Id].Name = "Commander Carl"
    end
end

ApplyKreeganArmySetup = function()
    ForEachMonsterEncounter(GetMonsterEncounter(KreeganArmyEncounterName, kriegspire), function(_, mon)
        local monIndex = mon:GetIndex()
        if mon.HP > 0 and mon.AIState ~= const.AIState.Removed then
            ApplyKreeganArmyMonsterSetup(mon, false)
            if mon.Hostile then
                ConfigureKreeganQuestMonster(mon, true, mon.Ally, mon.Group)
            else
                if mapvars.KreeganArmyFormationAnchors == nil or mapvars.KreeganArmyFormationAnchors[monIndex] == nil then
                    RecordKreeganArmyFormationAnchor(monIndex, mon)
                elseif mapvars.KreeganArmyFormationAnchors[monIndex].Direction == nil then
                    mapvars.KreeganArmyFormationAnchors[monIndex].Direction = (mon.Direction + 1024) % 2048
                end
                HoldKreeganArmyFormation(mon, mapvars.KreeganArmyFormationAnchors[monIndex])
            end
        end
    end, true)
end

IsKreeganArmyCurrentlyHostile = function()
    return MonsterEncounterHasAnyHostile(GetMonsterEncounter(KreeganArmyEncounterName, kriegspire))
end

RecordKreeganArmyFormationAnchor = function(monIndex, mon)
    mapvars.KreeganArmyFormationAnchors = mapvars.KreeganArmyFormationAnchors or {}
    mapvars.KreeganArmyFormationAnchors[monIndex] = {X = mon.X, Y = mon.Y, Z = mon.Z, Direction = (mon.Direction + 1024) % 2048}
end

HoldKreeganArmyFormation = function(mon, anchor)
    anchor = anchor or {X = mon.X, Y = mon.Y, Direction = mon.Direction}
    ConfigureKreeganQuestMonster(mon, false, 9999, mon.Group)
    mon.X = anchor.X
    mon.Y = anchor.Y
    mon.StartX = anchor.X
    mon.StartY = anchor.Y
    mon.GuardX = anchor.X
    mon.GuardY = anchor.Y
    mon.Direction = anchor.Direction or mon.Direction
    mon.LookAngle = 0
    mon.GuardRadius = 0
    mon.AIState = const.AIState.Stand
    mon.VelocityX = 0
    mon.VelocityY = 0
    mon.CurrentActionLength = const.Hour
    mon.CurrentActionStep = 0
    mon:UpdateGraphicState()
end

PinKreeganArmyFormation = function()
    if not InKriegspire() or vars.Quests[Quest_Kreegan_KillArmy] ~= "Given" or IsKreeganArmyCurrentlyHostile() then
        RemoveTimer(PinKreeganArmyFormation)
        svars.KreeganArmyFormationPinTimerRunning = nil
        return
    end

    ForEachMonsterEncounter(GetMonsterEncounter(KreeganArmyEncounterName, kriegspire), function(_, mon)
        local monIndex = mon:GetIndex()
        local anchor = mapvars.KreeganArmyFormationAnchors and mapvars.KreeganArmyFormationAnchors[monIndex]
        if anchor and mon.HP > 0 and mon.AIState ~= const.AIState.Removed then
            HoldKreeganArmyFormation(mon, anchor)
        end
    end, true)
end

SetKreeganArmyHostile = function()
    SetKreeganArmyMonsterHostile(true)
    RemoveTimer(PinKreeganArmyFormation)
    svars.KreeganArmyFormationPinTimerRunning = nil
    ForEachMonsterEncounter(GetMonsterEncounter(KreeganArmyEncounterName, kriegspire), function(_, mon)
        if mon.HP > 0 and mon.AIState ~= const.AIState.Removed then
            mon.GuardRadius = 6000
            mon.AIState = const.AIState.Active
            mon:UpdateGraphicState()
        end
    end, true)
end

SetKreeganArmyMonsterHostile = function(hostile, ally)
    ForEachMonsterEncounter(GetMonsterEncounter(KreeganArmyEncounterName, kriegspire), function(_, mon)
        if mon.HP > 0 and mon.AIState ~= const.AIState.Removed then
            ConfigureKreeganQuestMonster(mon, hostile, ally ~= nil and ally or (hostile and 0 or 9999), mon.Group)
        end
    end, true)
end

ConfigureKreeganArmyFormationMonster = function(mon, monIndex)
    RecordKreeganArmyFormationAnchor(monIndex, mon)
    HoldKreeganArmyFormation(mon, mapvars.KreeganArmyFormationAnchors[monIndex])
end

makeTroop = function(monId, firstX, firstY, z, rows, cols, mapMonIndexes, configure)
    local troop = {}

    for i = 0, (rows * cols) - 1 do
        local row = i % rows
        local col = math.floor(i / rows)

        local x = firstX + row * 100
        local y = firstY + col * 100

        local mon, monIndex = SummonMonster(monId, x, y, z, true)

        if configure then
            configure(mon, monIndex)
        end

        table.insert(troop, mon)

        if mapMonIndexes then
            table.insert(mapMonIndexes, monIndex)
        end
    end

    return troop
end

summonHumanArmyInKriegspire = function()
    local mapMonIndexes = {}

    -- Left formation
    makeTroop(armyArcher, 20200, -14750, 255, 2, 5, mapMonIndexes, ConfigureKreeganArmyFormationMonster)
    makeTroop(armyFighter, 19700, -14750, 255, 3, 5, mapMonIndexes, ConfigureKreeganArmyFormationMonster)

    -- Middle formation
    makeTroop(armyArcher, 20200, -14000, 255, 2, 5, mapMonIndexes, ConfigureKreeganArmyFormationMonster)
    makeTroop(armyFighter, 19700, -14000, 255, 3, 5, mapMonIndexes, ConfigureKreeganArmyFormationMonster)

    -- Right formation
    makeTroop(armyArcher, 20200, -13250, 255, 2, 5, mapMonIndexes, ConfigureKreeganArmyFormationMonster)
    makeTroop(armyFighter, 19700, -13250, 255, 3, 5, mapMonIndexes, ConfigureKreeganArmyFormationMonster)

    -- One offensive mage with a support mage behind it between each formation.
    makeTroop(armyOffensiveMage, 19700, -14175, 255, 1, 1, mapMonIndexes, ConfigureKreeganArmyFormationMonster)
    makeTroop(armySupportMage, 19800, -14175, 255, 1, 1, mapMonIndexes, ConfigureKreeganArmyFormationMonster)
    makeTroop(armyOffensiveMage, 19700, -13425, 255, 1, 1, mapMonIndexes, ConfigureKreeganArmyFormationMonster)
    makeTroop(armySupportMage, 19800, -13425, 255, 1, 1, mapMonIndexes, ConfigureKreeganArmyFormationMonster)

    local commander, commanderIndex = SummonMonster(armyCommander, 19500, -13800, 255, true)
    ConfigureKreeganArmyFormationMonster(commander, commanderIndex)
    table.insert(mapMonIndexes, commanderIndex)
    CreateAndSetMonsterEncounterFromIndexes(KreeganArmyEncounterName, mapMonIndexes, kriegspire)
    ApplyKreeganArmySetup()
end

-- Story timers ---------------------------------------------------------------
MonitorKreeganArmyHostility = function()
    if not InKriegspire() or vars.Quests[Quest_Kreegan_KillArmy] ~= "Given" then
        RemoveTimer(MonitorKreeganArmyHostility)
        svars.KreeganArmyHostilityTimerRunning = nil
        return
    end

    if IsKreeganArmyCurrentlyHostile() then
        SetKreeganArmyHostile()
        RemoveTimer(MonitorKreeganArmyHostility)
        svars.KreeganArmyHostilityTimerRunning = nil
        return
    end
end

MonitorKreeganAmbushThresholds = function()
    if not InKriegspire() or vars.KreeganAmbushStarted ~= true or vars.KreeganAmbushSide == nil or vars.KreeganAmbushKhorTarrDead == true then
        return
    end

    local khorTarr
    ForEachMonsterEncounter(GetMonsterEncounter(KreeganAmbushKhorTarrEncounterName, kriegspire), function(_, mon)
        if IsKhorTarrMonster(mon) and mon.HP > 0 and mon.AIState ~= const.AIState.Removed and mon.AIState ~= const.AIState.Dead then
            khorTarr = mon
        end
    end, true)
    if not khorTarr or khorTarr.FullHP <= 0 then
        return
    end

    local hpPercent = khorTarr.HP * 100 / khorTarr.FullHP
    if hpPercent <= 70 and vars.KreeganAmbushKhorTarrSummoned70 ~= true then
        vars.KreeganAmbushKhorTarrSummoned70 = true
        SummonKhorTarrReinforcements(devilSpawnMonsterID)
    end
    if hpPercent <= 40 and vars.KreeganAmbushKhorTarrSummoned40 ~= true then
        vars.KreeganAmbushKhorTarrSummoned40 = true
        SummonKhorTarrReinforcements(devilWorkerMonsterID)
    end
    if hpPercent <= 20 and vars.KreeganAmbushKhorTarrSummoned20 ~= true then
        vars.KreeganAmbushKhorTarrSummoned20 = true
        SummonKhorTarrReinforcements(devilWarriorMonsterID)
    end
end

MonitorKreeganStoryProgress = function()
    MonitorKreeganAmbushThresholds()

    if vars.KreeganRevealTriggerTime ~= nil and vars.KreeganRevealSeen ~= true and Game.Time >= vars.KreeganRevealTriggerTime + const.Hour * 2 and
           SafeToInterruptParty() then
        createAmbushContactNPC()
        vars.KreeganDialogStage = "Reveal"
        vars.KreeganRevealTriggerTime = nil
        evt.SpeakNPC{ambushContactNPC_ID}
        return
    end

    if vars.Quests[Quest_Kreegan_Ambush] == "Given" and vars.KreeganEscortIntent ~= nil and vars.KreeganAmbushStarted ~= true and
           NPCFollowers.NPCInGroup(carterNPC_ID) == nil and Game.NPC[carterNPC_ID].House == 0 then
        Game.NPC[carterNPC_ID].House = blackShireHouse
    end

    if vars.Quests[Quest_Kreegan_Ambush] == "Given" and NPCFollowers.NPCInGroup(carterNPC_ID) and vars.KreeganAmbushStarted ~= true and InKreeganAmbushArea() and
           SafeToInterruptParty() then
        StartKreeganAmbush()
        return
    end

    if vars.KreeganKhorTarrFollowupPending or vars.KreeganAmbusherFollowupPending then
        TriggerKreeganFollowupDialog()
    end
end

-- ============================================================================
--  Event listeners
-- ============================================================================

function events.AfterLoadMap()
    if InBlackshire() then
        if vars.KreeganRevealSeen ~= true then
            createCarterNPCBeforeReveal()
        elseif vars.KreeganAmbushKhorTarrDead ~= true and vars.KreeganAmbushStarted ~= true then
            createCarterNPCAfterReveal()
        end
        if vars.Quests[Quest_Kreegan_KillMessenger] == "Given" and vars.KreeganMessengerKilled ~= true then
            SummonEnemyMessenger()
        end
    end

    if InKriegspire() then
        if vars.KreeganRevealSeen == true and vars.KreeganAmbushKhorTarrDead ~= true then
            createCarterNPCAfterReveal()
        end
        Game.NPC[droppaMaPantzNPC_ID].Joins = 0
        if vars.KreeganAmbushStarted == true then
            if HasActiveKreeganAmbushActors() then
                ApplyKreeganAmbushSetup()
                if vars.KreeganAmbushSide == "KhorTarr" then
                    ApplyKreeganAmbushFactionHostility()
                    SetAmbushMonsterHostile(true)
                    SetKhorTarrMonsterHostile(false)
                    ActivateKreeganAmbushActors()
                elseif vars.KreeganAmbushSide == "Ambushers" then
                    ApplyKreeganAmbushFactionHostility()
                    SetAmbushMonsterHostile(false)
                    SetKhorTarrMonsterHostile(true)
                    ActivateKreeganAmbushActors()
                end
            elseif vars.Quests[Quest_Kreegan_Ambush] ~= "Done" and vars.KreeganDialogStage == nil and vars.KreeganKhorTarrFollowupPending ~= true and
                       vars.KreeganAmbusherFollowupPending ~= true and vars.KreeganAmbushGroupDead ~= true and vars.KreeganAmbushKhorTarrDead ~= true then
                SummonKreeganAmbushEncounter(false)
                if vars.KreeganAmbushSide == "KhorTarr" then
                    ApplyKreeganAmbushFactionHostility()
                    SetAmbushMonsterHostile(true)
                    SetKhorTarrMonsterHostile(false)
                    ActivateKreeganAmbushActors()
                elseif vars.KreeganAmbushSide == "Ambushers" then
                    ApplyKreeganAmbushFactionHostility()
                    SetAmbushMonsterHostile(false)
                    SetKhorTarrMonsterHostile(true)
                    ActivateKreeganAmbushActors()
                end
            end
        end
    end

    if InFreehaven() and vars.KreeganAmbushKhorTarrDead == true and vars.KreeganAmbushCorvinDead ~= true then
        createAmbushContactNPC()
        Game.NPC[ambushContactNPC_ID].House = freeHavenCorvinHouse
        NPCTopic {
            Slot = A,
            NPC = ambushContactNPC_ID,
            CanShow = function()
                return InFreehaven() and vars.KreeganAmbushKhorTarrDead == true and vars.KreeganAmbushCorvinDead ~= true and Game.NPC[ambushContactNPC_ID].House == freeHavenCorvinHouse
            end,
            Topic = "Khor-Tarr",
            Text = [[
Thank you for helping us bring him down. His days as an infiltrator are over.

I believe his manipulations was instrumental in founding the followers of Baa. However, that cult has grown beyond his influence and will not be undone by his death alone.

I have no further tasks for you at present. Continue the fight against the Kreegans, and remain vigilant against their deceptions.
            ]]
            }
    end

    if InKriegspire() and vars.Quests[Quest_Kreegan_KillArmy] == "Given" then
        if mapvars.KreeganArmySummoned ~= true then
            summonHumanArmyInKriegspire()
            mapvars.KreeganArmySummoned = true
        end
        ApplyKreeganArmySetup()
        if svars.KreeganArmyHostilityTimerRunning ~= true then
            Timer(MonitorKreeganArmyHostility, const.Second)
            svars.KreeganArmyHostilityTimerRunning = true
        end
        if not IsKreeganArmyCurrentlyHostile() and svars.KreeganArmyFormationPinTimerRunning ~= true then
            Timer(PinKreeganArmyFormation, const.Minute / 4)
            svars.KreeganArmyFormationPinTimerRunning = true
        end
    end

    if svars.KreeganStoryTimerRunning ~= true then
        Timer(MonitorKreeganStoryProgress, const.Second)
        svars.KreeganStoryTimerRunning = true
    end
end

function events.LeaveMap()
    if InKriegspire() and vars.KreeganAmbushKhorTarrDead == true then
        MarkKreeganAmbushEncountersForRemoval()
    end

    RemoveTimer(MonitorKreeganArmyHostility)
    svars.KreeganArmyHostilityTimerRunning = nil
    RemoveTimer(PinKreeganArmyFormation)
    svars.KreeganArmyFormationPinTimerRunning = nil
    RemoveTimer(MonitorKreeganStoryProgress)
    svars.KreeganStoryTimerRunning = nil
end

function events.ShowNPCTopics()
    if Game.CurrentScreen == const.Screens.House and Game.GetCurrentHouse() == khorTarrHideoutHouse then
        FinishKhorTarrHideoutEscort()
    end
end

function events.ExitNPC()
    if vars.KreeganDialogStage == "AmbushChoice" and vars.KreeganAmbushSide == nil then
        if vars.KreeganEscortIntent == "Tricked" then
            ResolveKreeganAmbush("Ambushers")
        else
            ResolveKreeganAmbush("KhorTarr")
        end
    elseif vars.KreeganDialogStage == "KhorTarrFollowup" and vars.KreeganKhorTarrFollowupSeen ~= true then
        CompleteKhorTarrFollowup()
    elseif vars.KreeganDialogStage == "AmbusherFollowup" and vars.KreeganAmbusherFollowupSeen ~= true then
        CompleteAmbusherFollowup()
    end
end

function events.MonsterKilled(mon)
    if InBlackshire() and mon.Id == enemyMessengerMonsterID and mon.NPC_ID == enemyMessengerNPC_ID then
        vars.KreeganMessengerKilled = true
        MarkMonsterEncounterForRemoval(KreeganMessengerEncounterName, blackshire)
        return
    end

    if InKriegspire() and vars.Quests[Quest_Kreegan_KillArmy] == "Given" and IsKreeganArmyMonster(mon) then
        if mon.Id == armyCommander then
            vars.KreeganCommanderKilled = true
        end

        local armyEncounter = GetMonsterEncounter(KreeganArmyEncounterName, kriegspire)
        if armyEncounter then
            local hasActive = MonsterEncounterHasAnyActive(armyEncounter)
            if hasActive == false then
                vars.KreeganArmyDestroyed = true
            end
        end
    end

    if InKriegspire() and vars.KreeganAmbushStarted == true and IsAmbushHumanMonster(mon) then
        if mon.Id == ambushMasterMonkMonsterID then
            vars.KreeganAmbushCorvinDead = true
            if vars.KreeganAmbushSide == "Ambushers" then
                EndKreeganAmbushQuestline("Corvin has died, and the quest line ends with him")
                return
            end
        end

        local humanEncounter = GetMonsterEncounter(KreeganAmbushHumanEncounterName, kriegspire)
        local hasActiveAmbushers = humanEncounter and MonsterEncounterHasAnyActive(humanEncounter) or nil
        if hasActiveAmbushers == false then
            vars.KreeganAmbushGroupDead = true
            MarkKreeganAmbushEncountersForRemoval()
        end
    end

    if InKriegspire() and vars.KreeganAmbushStarted == true and IsKhorTarrMonster(mon) then
        vars.KreeganAmbushKhorTarrDead = true
        KillKhorTarrSideSummons()
        MarkKreeganAmbushEncountersForRemoval()
        if vars.KreeganAmbushSide == "KhorTarr" then
            EndKreeganAmbushQuestline("Khor-Tarr has died, and the quest line ends with him")
        end
    end
end

function events.SpeakWithMonster(t)
    if not InKriegspire() then
        return
    end

    if vars.KreeganAmbushStarted == true and IsAmbushHumanMonster(t.Monster) then
        t.Result = "The trap is sprung."
    elseif vars.Quests[Quest_Kreegan_KillArmy] ~= "Given" then
        return
    elseif t.Monster.Id == armyCommander then
        t.Result = [[We are on a secret mission.

Now where is that good for nothing messenger!]]
    elseif IsKreeganArmyMonster(t.Monster) then
        t.Result = "Commander Carl gives the orders around here."
    end
end

function events.CalcDamageToMonster(t)
    if not t.ByPlayer or not InKriegspire() then
        return
    end

    if vars.Quests[Quest_Kreegan_KillArmy] == "Given" and IsKreeganArmyMonster(t.Monster) and not IsKreeganArmyCurrentlyHostile() then
        SetKreeganArmyHostile()
    end

    if vars.KreeganAmbushStarted ~= true or vars.KreeganAmbushSide == nil then
        return
    end

    if vars.KreeganAmbushSide == "KhorTarr" then
        if IsKhorTarrSideMonster(t.Monster) then
            t.Result = 0
        end
    elseif vars.KreeganAmbushSide == "Ambushers" and IsAmbushHumanMonster(t.Monster) then
        t.Result = 0
    end
end

function events.PlayerAttacked(t)
    if IsFriendlyKreeganAmbushMonster(t.Attacker and t.Attacker.Monster) then
        t.Handled = true
    end
end
