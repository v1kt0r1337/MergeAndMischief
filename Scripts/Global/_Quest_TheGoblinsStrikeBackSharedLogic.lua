-- ============================================================================
--  TheGoblinsStrikeBack Questline Shared Logic
-- ============================================================================

TheGoblinsStrikeBack = TheGoblinsStrikeBack or {}

-- Locations ------------------------------------------------------------------
local newSorpigal = "oute3.odm"
local decenthouse = "decenthouse.blv"
local decenthouseExitDoorEventId = 5

-- Houses ---------------------------------------------------------------------
local goblinwatchHouse = 1463
local houseBehindGoblinwatch = 1413

-- Quest IDs ------------------------------------------------------------------
local Quest_TheGoblinsStrikeBack1 = "Quest_TheGoblinsStrikeBack1"
local Quest_TheGoblinsStrikeBack2 = "Quest_TheGoblinsStrikeBack2"
local Quest_TheGoblinsStrikeBack3 = "Quest_TheGoblinsStrikeBack3"
local Quest_TheGoblinsStrikeBack4 = "Quest_TheGoblinsStrikeBack4"

-- Encounter IDs --------------------------------------------------------------
local SamsonTessEncounterName = "Quest_TheGoblinsStrikeBack1_SamsonTess"
local GuardReinforcementsEncounterName = "Quest_TheGoblinsStrikeBack3_GuardReinforcements"
local GoblinAttackEncounterName = "Quest_TheGoblinsStrikeBack4_GoblinAttack"
local GuardReplacementGoblinEncounterName = "Quest_TheGoblinsStrikeBack4_GuardReplacementGoblins"
local TraitorRevengeEncounterName = "Quest_TheGoblinsStrikeBack4_TraitorRevenge"
local LordNilbogEncounterName = "Quest_TheGoblinsStrikeBack4_LordNilbog"

-- NPC IDs --------------------------------------------------------------------
local samsonTessNPC_ID = 828
local urokNPC_ID = 1081
local janiceNPC_ID = 1076
local nilbogNPC_ID = 111

-- Monster IDs ----------------------------------------------------------------
local samsonTessMonsterId = 587
local goblinMonsterId = 550
local guardMonsterId = 553
local peasantMonsterId = 595

RegisterSharedHouseUse {
    Key = "TheGoblinsStrikeBackNewSorpigalHouse",
    QuestLine = "TheGoblinsStrikeBack",
    Map = newSorpigal,
    House = goblinwatchHouse
}

-- Helpers --------------------------------------------------------------------
local function InMap(map)
    return Map.Name == map
end

local function InNewSorpigal()
    return InMap(newSorpigal)
end

local function InDecentHouse()
    return InMap(decenthouse)
end

local function QuestState(id, state)
    return vars.Quests[id] == state
end

local function IsOriginalGoblinwatchDone()
    return Party.QBits[313] and Party.QBits[1324] and Party.QBits[1107] == false
end

local function SetHostility(monsterId, targetClass, hostility)
    if type(LocalHostileTxt) == "function" then
        LocalHostileTxt()
    end
    Game.HostileTxt[MonsterClass(monsterId)][targetClass] = hostility
end

local function SetBidirectionalHostility(firstMonsterId, secondMonsterId, hostility)
    if type(LocalHostileTxt) == "function" then
        LocalHostileTxt()
    end
    local firstClass = MonsterClass(firstMonsterId)
    local secondClass = MonsterClass(secondMonsterId)
    Game.HostileTxt[firstClass][secondClass] = hostility
    Game.HostileTxt[secondClass][firstClass] = hostility
end

local function ResetNPCDialogState(npcId)
    for i = 0, 5 do
        Game.NPC[npcId].Events[i] = 0
    end
end

local function MakeNilbogToLordNPC()
    ResetNPCDialogState(nilbogNPC_ID)
    Game.NPC[nilbogNPC_ID].House = goblinwatchHouse
    Game.NPC[nilbogNPC_ID].Pic = 624
    Game.NPC[nilbogNPC_ID].Name = "Lord Nilbog"
    Game.NPC[nilbogNPC_ID].Profession = 0
end

local function MakeGoblinsHostileToPlayer()
    SetHostility(goblinMonsterId, 0, 4)
end

local function MakeGoblinsFriendlyToPlayer()
    vars.NewSorpigalGoblinsFriendly = true
    SetHostility(goblinMonsterId, 0, 0)
end

local function MakeGuardsHostileToPlayer()
    SetHostility(guardMonsterId, 0, 1)
end

local function MakeGoblinsHostileToPeasants()
    SetBidirectionalHostility(goblinMonsterId, peasantMonsterId, 4)
end

local function MakeGoblinsFriendlyToPeasants()
    SetBidirectionalHostility(goblinMonsterId, peasantMonsterId, 0)
end

local function SendPartyBackToGoblinwatchApartmentEntrance()
    evt.PlaySound(7)
    evt.MoveToMap {
        Name = newSorpigal,
        X = -18303,
        Y = -15535,
        Z = 1985,
        Direction = 1538
    }
end

local function RestoreNativeHouseOccupants()
    if vars.Quests[Quest_TheGoblinsStrikeBack1] == "Done" or vars.SamsonTessDead == true then
        return
    end

    if not IsOriginalGoblinwatchDone() then
        Game.NPC[urokNPC_ID].House = goblinwatchHouse
        Game.NPC[samsonTessNPC_ID].House = 0
        return
    end

    Game.NPC[urokNPC_ID].House = houseBehindGoblinwatch
    Game.NPC[samsonTessNPC_ID].House = goblinwatchHouse
end

local function ResetTheGoblinsStrikeBack3State()
    vars.AllGuardsInNSDead = nil
    MarkMonsterEncounterForRemoval(GuardReinforcementsEncounterName, newSorpigal)
end

local function ResetTheGoblinsStrikeBack4State()
    vars.FrankFairchildHasSurrendered = nil
    vars.AcceptKillLordNilbog = nil
    vars.LordNilbogDead = nil
    MarkMonsterEncounterForRemoval(GoblinAttackEncounterName, newSorpigal)
    MarkMonsterEncounterForRemoval(GuardReplacementGoblinEncounterName, newSorpigal)
    MarkMonsterEncounterForRemoval(TraitorRevengeEncounterName, newSorpigal)
    MarkMonsterEncounterForRemoval(LordNilbogEncounterName, decenthouse)
end

TheGoblinsStrikeBack.NewSorpigal = newSorpigal
TheGoblinsStrikeBack.DecentHouse = decenthouse
TheGoblinsStrikeBack.DecentHouseExitDoorEventId = decenthouseExitDoorEventId
TheGoblinsStrikeBack.GoblinwatchHouse = goblinwatchHouse
TheGoblinsStrikeBack.HouseBehindGoblinwatch = houseBehindGoblinwatch
TheGoblinsStrikeBack.Quest1 = Quest_TheGoblinsStrikeBack1
TheGoblinsStrikeBack.Quest2 = Quest_TheGoblinsStrikeBack2
TheGoblinsStrikeBack.Quest3 = Quest_TheGoblinsStrikeBack3
TheGoblinsStrikeBack.Quest4 = Quest_TheGoblinsStrikeBack4
TheGoblinsStrikeBack.SamsonTessEncounterName = SamsonTessEncounterName
TheGoblinsStrikeBack.GuardReinforcementsEncounterName = GuardReinforcementsEncounterName
TheGoblinsStrikeBack.GoblinAttackEncounterName = GoblinAttackEncounterName
TheGoblinsStrikeBack.GuardReplacementGoblinEncounterName = GuardReplacementGoblinEncounterName
TheGoblinsStrikeBack.TraitorRevengeEncounterName = TraitorRevengeEncounterName
TheGoblinsStrikeBack.LordNilbogEncounterName = LordNilbogEncounterName
TheGoblinsStrikeBack.SamsonTessNPC = samsonTessNPC_ID
TheGoblinsStrikeBack.UrokNPC = urokNPC_ID
TheGoblinsStrikeBack.JaniceNPC = janiceNPC_ID
TheGoblinsStrikeBack.NilbogNPC = nilbogNPC_ID
TheGoblinsStrikeBack.SamsonTessMonster = samsonTessMonsterId
TheGoblinsStrikeBack.GuardMonster = guardMonsterId
TheGoblinsStrikeBack.InMap = InMap
TheGoblinsStrikeBack.InNewSorpigal = InNewSorpigal
TheGoblinsStrikeBack.InDecentHouse = InDecentHouse
TheGoblinsStrikeBack.QuestState = QuestState
TheGoblinsStrikeBack.IsOriginalGoblinwatchDone = IsOriginalGoblinwatchDone
TheGoblinsStrikeBack.ResetNPCDialogState = ResetNPCDialogState
TheGoblinsStrikeBack.MakeNilbogToLordNPC = MakeNilbogToLordNPC
TheGoblinsStrikeBack.MakeGoblinsHostileToPlayer = MakeGoblinsHostileToPlayer
TheGoblinsStrikeBack.MakeGoblinsFriendlyToPlayer = MakeGoblinsFriendlyToPlayer
TheGoblinsStrikeBack.MakeGuardsHostileToPlayer = MakeGuardsHostileToPlayer
TheGoblinsStrikeBack.MakeGoblinsHostileToPeasants = MakeGoblinsHostileToPeasants
TheGoblinsStrikeBack.MakeGoblinsFriendlyToPeasants = MakeGoblinsFriendlyToPeasants
TheGoblinsStrikeBack.SendPartyBackToGoblinwatchApartmentEntrance = SendPartyBackToGoblinwatchApartmentEntrance
TheGoblinsStrikeBack.RestoreNativeHouseOccupants = RestoreNativeHouseOccupants
TheGoblinsStrikeBack.ResetQuest3State = ResetTheGoblinsStrikeBack3State
TheGoblinsStrikeBack.ResetQuest4State = ResetTheGoblinsStrikeBack4State

-- Public compatibility hook used by other quest files.
function RestoreGoblinwatchNativeHouseOccupants()
    RestoreNativeHouseOccupants()
end


local function IsGoblinKind(mon)
    return mon.Id == goblinMonsterId or mon.Id == goblinMonsterId + 1 or mon.Id == goblinMonsterId + 2
end

local goblinTextMap = {
    "New Sorpigal belongs to us goblins. Humans live at our mercy!",
    "New Sorpigal belongs to goblins now. Humans behave, or humans become dinner!",
    "Goblins rule this town. Good friends of goblins may walk safely.",
    "Goblinwatch is strong again. Human won't take it twice!",
    "Humans feared goblins before. Now they fear us more!",
    "You are friend of goblins. No goblin bites you.",
    "Humans work. Goblins counts the gold.",
    "Humans may stay, so long as humans obey.",
    "Lord Nilbog rules the castle. Urok rules the town.",
    "Goblins watch every road. Humans cannot surprise us now.",
    "Lord Nilbog in the castle. Urok in the office. Goblins in the town!"
}

function events.SpeakWithMonster(t)
    if InNewSorpigal() and IsGoblinKind(t.Monster) and vars.NewSorpigalGoblinsFriendly == true then
        if (vars.Quests[Quest_TheGoblinsStrikeBack4] == "Done") then
            t.Result = goblinTextMap[math.random(1, #goblinTextMap)]
        else
            t.Result = "Greetings friend of goblins"
        end
   end
end
