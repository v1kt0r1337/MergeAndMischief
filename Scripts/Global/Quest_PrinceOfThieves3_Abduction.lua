-- ============================================================================
--  Prince of Thieves, Act 2: Abduction
-- ============================================================================

-- Base data ------------------------------------------------------------------
local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5
local P = PrinceOfThieves

-- Shadow Guild encounter setup ------------------------------------------------
local shadowGuildIvanEncounterName = "PrinceThievesShadowGuildIvan"
local shadowGuildPrinceEncounterName = "PrinceThievesShadowGuildPrince"
local shadowGuildIvanMonsterId = 258 -- MM7 Bandit
local shadowGuildPrinceMonsterId = 358 -- Peasant
local shadowGuildIvanPowerMonsterId = 580 -- MM6 Minotaur
local shadowGuildActorGroup = 75
local shadowGuildActorAlly = 9999

local SetupShadowGuildRescue
local MonitorPrinceThievesAbduction

-- Quest stages ----------------------------------------------------------------
Quest{
    P.SavePrinceFromIvanQuest,
    Slot = F,
    NPC = P.MorganNPC,
    CanShow = function()
        return P.InIvanMagyarHouse() and vars.PrinceThievesIvanAbductionSeen == true and
            vars.PrinceThievesIvanRescueTurnedIn ~= true and vars.PrinceThievesPrinceDead ~= true
    end,
    CheckDone = function()
        return vars.PrinceThievesPrinceRescuedFromIvan == true
    end,
    Done = function()
        vars.PrinceThievesIvanRescueTurnedIn = true
    end,
    Gold = 5000,
    Exp = 15000,
}.SetTexts {
    Quest = "Save the Prince of Thieves from Ivan",
    Topic = "Ivan abducted the Prince",
    Undone = "Ivan took the Prince of Thieves to the Shadow Guild hideout near Castle Ironfist. Stop him before he can ransom the Prince back to Anthony Stone.",
    Done = "The Prince of Thieves made it back safely. Poor Ivan, his greed finally caught up with him.",
}
Greeting {
    NPC = P.MorganNPC,
    CanShow = function()
        return vars.PrinceThievesDialogStage == "IvanAbduction"
    end,
    Text = [[
Ivan Magyar has abducted the Prince of Thieves. He plans to ransom him back to Baron Anthony Stone!

Ivan and his band of hardened criminals took him to the Shadow Guild hideout near Castle Ironfist. You must stop him!]]
}

Greeting {
    NPC = P.PrinceNPC,
    CanShow = function()
        return vars.PrinceThievesDialogStage == "IvanRescue"
    end,
    Text = [[
Ivan Magyar, that greedy fool. Just a few more days and I would have paid him back, I swear!

I'll find my own way out. Meet me back at Morgan's hideout in northern Free Haven at the Smugglers' Guild.]]
}

-- Shadow Guild runtime helpers ------------------------------------------------
local function ApplyShadowGuildHardenedSetup(resetHP)
    local magyar = 478
    local magyarSoldier = 479
    local magyarMatron = 480
    local fighter = 535
    local soldier = 536
    local veteran = 537

    local powerIds = {
        Thug = magyar,
        Ruffian = magyarSoldier,
        Brigand = magyarMatron,
        Thief = fighter,
        Burglar = soldier,
        Rogue = veteran,
    }

    if mapvars.PrinceThievesShadowGuildChestRewardsUpgraded ~= true then
        for _, chest in Map.Chests do
            for _, item in chest.Items do
                if item.Number > 0 and item.Number ~= 2180 then -- Preserve the dungeon key.
                    local itemType = item:T().EquipStat + 1
                    if itemType ~= const.ItemType.MScroll and itemType <= const.ItemType.Gold then
                        item:Randomize(4, itemType)
                    end
                end
            end
        end
        mapvars.PrinceThievesShadowGuildChestRewardsUpgraded = true
    end

    for _, mon in Map.Monsters do
        if mon.Id > 0 and mon.HP > 0 and mon.AIState ~= const.AIState.Removed then
            mon.Group = shadowGuildActorGroup
            mon.Ally = shadowGuildActorAlly
            mon.Hostile = true
            mon.ShowAsHostile = true
            mon.HostileType = 4

            local source = Game.MonstersTxt[mon.Id]
            local sourceName = source.Name:gsub("^Hardened ", "")
            local powerId = powerIds[sourceName]
            if powerId ~= nil then
                ApplyMonsterPowerFromMonster(mon, Game.MonstersTxt[powerId], resetHP == true)
                source.Name = "Hardened " .. sourceName
            end
        end
    end
end

local function ConfigureShadowGuildPrince(mon)
    P.ConfigureQuestMonster(mon, false, shadowGuildActorAlly, shadowGuildActorGroup, {
        AIState = const.AIState.Active,
    })
    mon.AIType = 3
    mon.NPC_ID = P.PrinceNPC
    Game.MonstersTxt[shadowGuildPrinceMonsterId].Name = "The Prince of Thieves"
    -- Given the HP of a minotaur to ensure he won't be killed by mistake...
    mon.FullHP = Game.MonstersTxt[580].FullHP
    mon.HP = Game.MonstersTxt[580].FullHP
end

local function ConfigureShadowGuildIvan(mon, resetHP)
    ApplyMonsterPowerFromMonster(mon, Game.MonstersTxt[shadowGuildIvanPowerMonsterId], resetHP == true)
    P.ConfigureQuestMonster(mon, true, shadowGuildActorAlly, shadowGuildActorGroup, {
        AIState = const.AIState.Active,
    })
    mon.NPC_ID = P.IvanMagyarNPC
    Game.MonstersTxt[shadowGuildIvanMonsterId].Name = "Ivan Magyar"
end

local function FindShadowGuildRescueNPC(npcId)
    if not P.InShadowGuildHideout() then
        return
    end

    for index, mon in Map.Monsters do
        if mon.NPC_ID == npcId and mon.AIState ~= const.AIState.Removed then
            return mon, index
        end
    end
end

local function SetupShadowGuildRescueNPCEncounter(encounterName, npcId)
    local encounter = GetMonsterEncounter(encounterName, P.ShadowGuildHideout)
    local mon
    local index
    ForEachMonsterEncounter(encounter, function(record, candidate)
        if mon == nil and candidate.NPC_ID == npcId then
            mon = candidate
            index = record.index
        end
    end)

    if mon == nil then
        mon, index = FindShadowGuildRescueNPC(npcId)
    end
    if mon == nil then
        return nil
    end

    if MonsterEncounterContainsMonster(encounter, mon) ~= true then
        encounter = CreateAndSetMonsterEncounterFromIndexes(encounterName, {index}, P.ShadowGuildHideout)
    end
    return encounter
end

local function RemoveShadowGuildPrinceActor()
    local encounter = SetupShadowGuildRescueNPCEncounter(shadowGuildPrinceEncounterName, P.PrinceNPC)
    RemoveMonsterEncounter(encounter)
end

local function ApplyShadowGuildRescueHostility()
    LocalHostileTxt()

    local ivanClass = math.ceil(shadowGuildIvanMonsterId / 3)
    local princeClass = math.ceil(shadowGuildPrinceMonsterId / 3)
    Game.HostileTxt[ivanClass][princeClass] = 0
    Game.HostileTxt[princeClass][ivanClass] = 0
    Game.HostileTxt[ivanClass][0] = 4
    Game.HostileTxt[princeClass][0] = 0
end

local function SetupShadowGuildRescueNPC(options)
    local encounter = SetupShadowGuildRescueNPCEncounter(options.EncounterName, options.NPC)
    if encounter == nil then
        local mon, index = SummonMonster(options.MonsterId, options.X, options.Y, options.Z, true)
        options.Configure(mon, true)
        CreateAndSetMonsterEncounterFromIndexes(options.EncounterName, {index}, P.ShadowGuildHideout)
    else
        ForEachMonsterEncounter(encounter, function(_, mon)
            if IsAlive(mon) then
                options.Configure(mon, false)
            end
        end)
    end
    return SetupShadowGuildRescueNPCEncounter(options.EncounterName, options.NPC)
end

-- Quest runtime helpers -------------------------------------------------------
SetupShadowGuildRescue = function()
    if not P.InShadowGuildHideout() or vars.Quests[P.SavePrinceFromIvanQuest] ~= "Given" then
        return
    end

    ApplyShadowGuildHardenedSetup(mapvars.PrinceThievesShadowGuildHardenedSetup ~= true)
    mapvars.PrinceThievesShadowGuildHardenedSetup = true
    ApplyShadowGuildRescueHostility()

    SetupShadowGuildRescueNPC {
        EncounterName = shadowGuildPrinceEncounterName,
        NPC = P.PrinceNPC,
        MonsterId = shadowGuildPrinceMonsterId,
        X = -1712,
        Y = 1703,
        Z = 1,
        Configure = ConfigureShadowGuildPrince,
    }

    if vars.PrinceThievesIvanDead == true then
        return
    end
    SetupShadowGuildRescueNPC {
        EncounterName = shadowGuildIvanEncounterName,
        NPC = P.IvanMagyarNPC,
        MonsterId = shadowGuildIvanMonsterId,
        X = -1283,
        Y = 1289,
        Z = 1,
        Configure = ConfigureShadowGuildIvan,
    }
end

local function EnsureAbductionTimer()
    if svars.PrinceThievesAbductionTimerRunning ~= true then
        Timer(MonitorPrinceThievesAbduction, const.Second)
        svars.PrinceThievesAbductionTimerRunning = true
    end
end

MonitorPrinceThievesAbduction = function()
    if vars.PrinceThievesIvanAbductionTime ~= nil and vars.PrinceThievesIvanAbductionSeen ~= true and
        Game.Time >= vars.PrinceThievesIvanAbductionTime + const.Hour * 2 and P.SafeToInterruptParty() then
        vars.PrinceThievesIvanAbductionSeen = true
        vars.Quests[P.SavePrinceFromIvanQuest] = "Given"
        vars.PrinceThievesDialogStage = "IvanAbduction"
        Game.NPC[P.IvanMagyarNPC].House = 0
        Game.NPC[P.PrinceNPC].House = 0
        -- Prevent the key from the easier Shadow Guild version from trivializing this rescue.
        if evt.ForPlayer("All").Cmp{"Inventory", 2180} then
            evt.ForPlayer("All").Subtract{"Inventory", 2180}
        end
        evt.SpeakNPC{P.MorganNPC}
        return
    end

    if P.InShadowGuildHideout() and vars.PrinceThievesIvanDead == true and vars.PrinceThievesPrinceDead ~= true and
        vars.PrinceThievesPrinceRescuedFromIvan ~= true and
        Game.Time >= vars.PrinceThievesIvanDeathTime + const.Minute and Game.CurrentScreen == 0 then
        vars.PrinceThievesDialogStage = "IvanRescue"
        RemoveShadowGuildPrinceActor()
        evt.SpeakNPC{P.PrinceNPC}
    end
end

local function FinishIvanRescueDialog()
    vars.PrinceThievesDialogStage = nil
    vars.PrinceThievesPrinceRescuedFromIvan = true

    SetupShadowGuildRescueNPCEncounter(shadowGuildIvanEncounterName, P.IvanMagyarNPC)
    MarkMonsterEncounterForRemoval(shadowGuildIvanEncounterName, P.ShadowGuildHideout)
    MarkMonsterEncounterForRemoval(shadowGuildPrinceEncounterName, P.ShadowGuildHideout)
    Game.NPC[P.PrinceNPC].House = P.IvanMagyarHouse
end

-- Event listeners -------------------------------------------------------------
function events.LoadSavedMap()
    local shadowGuildLoadRef = "6d03.dlv"
    if Map.Name ~= shadowGuildLoadRef then
        return
    end

    local needsInitialQuestRefill = vars.Quests[P.SavePrinceFromIvanQuest] == "Given" and
        vars.PrinceThievesShadowGuildRefillForced ~= true
    local actorDead = vars.PrinceThievesIvanDead == true or vars.PrinceThievesPrinceDead == true
    local needsActorDeathRefill = actorDead and vars.PrinceThievesShadowGuildActorDeathRefillForced ~= true

    if needsInitialQuestRefill or needsActorDeathRefill then
        Map.LastRefillDay = 0
        if needsInitialQuestRefill then
            vars.PrinceThievesShadowGuildRefillForced = true
        end
        if needsActorDeathRefill then
            vars.PrinceThievesShadowGuildActorDeathRefillForced = true
        end
    end
end

function events.AfterLoadMap()
    if P.InShadowGuildHideout() then
        if vars.PrinceThievesPrinceRescuedFromIvan == true then
            RemoveShadowGuildPrinceActor()
        else
            SetupShadowGuildRescue()
        end
    end
    EnsureAbductionTimer()
end

function events.LeaveMap()
    RemoveTimer(MonitorPrinceThievesAbduction)
    svars.PrinceThievesAbductionTimerRunning = nil
end

function events.ExitNPC()
    if vars.PrinceThievesDialogStage == "IvanAbduction" then
        vars.PrinceThievesDialogStage = nil
    elseif vars.PrinceThievesDialogStage == "IvanRescue" then
        FinishIvanRescueDialog()
    end
end

function events.ExitAnyNPC()
    if vars.PrinceThievesDialogStage == "IvanRescue" then
        FinishIvanRescueDialog()
    end
end

function events.MonsterKilled(mon)
    if not P.InShadowGuildHideout() or vars.Quests[P.SavePrinceFromIvanQuest] ~= "Given" then
        return
    end

    local princeEncounter = GetMonsterEncounter(shadowGuildPrinceEncounterName, P.ShadowGuildHideout)
    if MonsterEncounterContainsMonster(princeEncounter, mon) == true then
        vars.PrinceThievesPrinceDead = true
        vars.Quests[P.SavePrinceFromIvanQuest] = "Failed"
        Sleep(const.Minute)
        Message("The Prince of Thieves is dead. The quest has failed.")
        return
    end

    if vars.PrinceThievesIvanDead ~= true then
        local encounter = GetMonsterEncounter(shadowGuildIvanEncounterName, P.ShadowGuildHideout)
        if MonsterEncounterContainsMonster(encounter, mon) == true then
            vars.PrinceThievesIvanDead = true
            vars.PrinceThievesIvanDeathTime = Game.Time
        end
    end
end

function events.MonsterSpriteScale(t)
    if P.InShadowGuildHideout() and t.Monster ~= nil and Game.MonstersTxt[t.Monster.Id].Name == "Ivan Magyar" then
        -- make Ivan slightly bigger
        t.Scale = math.floor(t.Scale * 1.2)
    end
end
