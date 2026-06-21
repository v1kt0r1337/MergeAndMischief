-- ============================================================================
--  Spymaster Questline Shared Logic
-- ============================================================================

Spymaster = Spymaster or {}

-- Houses ---------------------------------------------------------------------
local blackShireHouse = 1387
local khorTarrHideoutHouse = 1278
local freeHavenCorvinHouse = 1418

-- Locations ------------------------------------------------------------------
local blackshire = "outb2.odm"
local kriegspire = "outb1.odm"
local freehaven = "outc2.odm"
local SpymasterQuestLine = "Spymaster"

-- Quest IDs ------------------------------------------------------------------
local Quest_Spymaster_KillMessenger = "Quest_Spymaster_KillMessenger"
local Quest_Spymaster_KillArmy = "Quest_Spymaster_KillArmy"
local Quest_Spymaster_Ambush = "Quest_Spymaster_Ambush"
local Quest_Spymaster_HideKhorTarr = "Quest_Spymaster_HideKhorTarr"

-- Encounter IDs --------------------------------------------------------------
local SpymasterMessengerEncounterName = "SpymasterMessenger"
local SpymasterArmyEncounterName = "SpymasterArmy"
local SpymasterAmbushKhorTarrEncounterName = "SpymasterAmbushKhorTarrSide"
local SpymasterAmbushHumanEncounterName = "SpymasterAmbushHumanSide"

-- NPC IDs --------------------------------------------------------------------
local carterNPC_ID = 111
local droppaMaPantzNPC_ID = 1000
local enemyMessengerNPC_ID = 645
local ambushContactNPC_ID = 645

-- Monster IDs ----------------------------------------------------------------
local khorTarrMonsterId = 501

RegisterSharedHouseUse {
    Key = "SpymasterBlackshireHouse",
    QuestLine = SpymasterQuestLine,
    Map = blackshire,
    House = blackShireHouse
}

RegisterSharedHouseUse {
    Key = "SpymasterKhorTarrHideout",
    QuestLine = SpymasterQuestLine,
    Quest = Quest_Spymaster_HideKhorTarr,
    Map = kriegspire,
    House = khorTarrHideoutHouse
}

RegisterSharedHouseUse {
    Key = "SpymasterFreeHavenCorvinHouse",
    QuestLine = SpymasterQuestLine,
    Quest = Quest_Spymaster_Ambush,
    Map = freehaven,
    House = freeHavenCorvinHouse
}

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

local function SafeToInterruptParty()
    return Game.CurrentScreen == 0 and not (Party.EnemyDetectorRed or Party.EnemyDetectorYellow)
end

local function LocalizeMonsterTxt()
    if type(LocalMonstersTxt) == "function" then
        LocalMonstersTxt()
    end
end

local function LocalizeHostileTxt()
    if type(LocalHostileTxt) == "function" then
        LocalHostileTxt()
    end
end

-- NPC helpers ----------------------------------------------------------------
local function ResetNPCDialogState(npcId)
    for i = 0, 5 do
        Game.NPC[npcId].Events[i] = 0
    end
    -- Greeting { NPC = npcId }
end

local function CreateCarterNPCBeforeReveal()
    ResetNPCDialogState(carterNPC_ID)
    Game.NPC[carterNPC_ID].House = blackShireHouse
    Game.NPC[carterNPC_ID].Name = "Carter"
    Game.NPC[carterNPC_ID].Pic = 265
    Game.NPC[carterNPC_ID].Profession = 0
end

local function CreateCarterNPCAfterReveal()
    ResetNPCDialogState(carterNPC_ID)
    if vars.SpymasterKhorTarrHidden == true then
        Game.NPC[carterNPC_ID].House = khorTarrHideoutHouse
    elseif NPCFollowers.NPCInGroup(carterNPC_ID) or
        (vars.SpymasterAmbushStarted == true and vars.Quests[Quest_Spymaster_Ambush] ~= "Done") then
        Game.NPC[carterNPC_ID].House = 0
    else
        Game.NPC[carterNPC_ID].House = blackShireHouse
    end
    Game.NPC[carterNPC_ID].Name = "Khor-Tarr"
    Game.NPC[carterNPC_ID].Pic = 971
    Game.NPC[carterNPC_ID].Profession = 0
end

local function CreateAmbushContactNPC()
    ResetNPCDialogState(ambushContactNPC_ID)
    Game.NPC[ambushContactNPC_ID].Name = "Corvin"
    Game.NPC[ambushContactNPC_ID].Pic = 0035
    Game.NPC[ambushContactNPC_ID].Profession = 0
end

local function CreateKhorTarrMonster(mon, resetHP)
    local hpMultiplier = 2
    local expMultiplier = 2
    local oldFullHP = mon.FullHP
    local oldHP = mon.HP

    Game.MonstersTxt[khorTarrMonsterId].Name = Game.NPC[carterNPC_ID].Name
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

local function ApplyVeteranArcher(mon, resetPowerHP)
    local rockbeastId = 526
    Game.MonstersTxt[mon.Id].Name = "Veteran Archer"
    ApplyMonsterPowerFromMonster(mon, Game.MonstersTxt[rockbeastId], resetPowerHP == true)
end

-- Follower helpers -----------------------------------------------------------
local function TryAddKhorTarrFollower()
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

local function ReturnKhorTarrToHouse()
    NPCFollowers.Remove(carterNPC_ID)
    Game.NPC[carterNPC_ID].House = blackShireHouse
    Message("Since there was no room for another follower. Khor-Tarr has returned to his house in Blackshire. Meet him there for further instructions")
end

Spymaster.BlackShireHouse = blackShireHouse
Spymaster.KhorTarrHideoutHouse = khorTarrHideoutHouse
Spymaster.FreeHavenCorvinHouse = freeHavenCorvinHouse
Spymaster.Blackshire = blackshire
Spymaster.Kriegspire = kriegspire
Spymaster.KillMessengerQuest = Quest_Spymaster_KillMessenger
Spymaster.KillArmyQuest = Quest_Spymaster_KillArmy
Spymaster.AmbushQuest = Quest_Spymaster_Ambush
Spymaster.HideKhorTarrQuest = Quest_Spymaster_HideKhorTarr
Spymaster.MessengerEncounterName = SpymasterMessengerEncounterName
Spymaster.ArmyEncounterName = SpymasterArmyEncounterName
Spymaster.AmbushKhorTarrEncounterName = SpymasterAmbushKhorTarrEncounterName
Spymaster.AmbushHumanEncounterName = SpymasterAmbushHumanEncounterName
Spymaster.CarterNPC = carterNPC_ID
Spymaster.DroppaMaPantzNPC = droppaMaPantzNPC_ID
Spymaster.EnemyMessengerNPC = enemyMessengerNPC_ID
Spymaster.AmbushContactNPC = ambushContactNPC_ID
Spymaster.KhorTarrMonster = khorTarrMonsterId
Spymaster.InBlackshire = InBlackshire
Spymaster.InKriegspire = InKriegspire
Spymaster.InFreehaven = InFreehaven
Spymaster.SafeToInterruptParty = SafeToInterruptParty
Spymaster.CreateCarterNPCBeforeReveal = CreateCarterNPCBeforeReveal
Spymaster.CreateCarterNPCAfterReveal = CreateCarterNPCAfterReveal
Spymaster.CreateAmbushContactNPC = CreateAmbushContactNPC
Spymaster.ConfigureQuestMonster = ConfigureQuestMonster
Spymaster.CreateKhorTarrMonster = CreateKhorTarrMonster
Spymaster.ApplyVeteranArcher = ApplyVeteranArcher
Spymaster.TryAddKhorTarrFollower = TryAddKhorTarrFollower
Spymaster.ReturnKhorTarrToHouse = ReturnKhorTarrToHouse

function events.LoadMapScripts()
    if InBlackshire() then
        LocalizeMonsterTxt()
        LocalizeHostileTxt()
    elseif InKriegspire() then
        LocalizeMonsterTxt()
        LocalizeHostileTxt()
    end
end
