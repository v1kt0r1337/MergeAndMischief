-- ============================================================================
--  Prince of Thieves, Act 3: Taking the Barony
-- ============================================================================

-- Base data ------------------------------------------------------------------
local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5
local P = PrinceOfThieves

-- Monster IDs -----------------------------------------------------------------
local guardMonsterId = 553
local lieutenantMonsterId = 554
local captainMonsterId = 555
local masterArcherMonsterId = 476
local fireArcherMonsterId = 477
local soldierMonsterId = 536
local veteranMonsterId = 537
local magicianMonsterId = 632
local magicianSpellSourceMonsterId = 293 -- MM6 Wizard
local warlockMonsterId = 633

-- Encounter IDs and guard tuning ---------------------------------------------
local baronyCastleGuardEncounterName = "PrinceThievesBaronyCastleGuards"
local baronyTownGuardEncounterName = "PrinceThievesBaronyTownGuards"
local baronyGuardPatrolEncounterName = "PrinceThievesBaronyGuardPatrol"
local baronyGuardEncounterNames = {
    baronyCastleGuardEncounterName,
    baronyTownGuardEncounterName,
    baronyGuardPatrolEncounterName,
}
local baronyGuardGroup = 77
local baronyGuardFormationSpacing = 140
local baronyGuardDetectionDistance = 2000
local baronyGuardAlertRadius = 500
local baronyGuardReleasedGuardRadius = 6000
local baronyCastleGuardMinimumSummonMinutes = 2
local baronyCastleGuardMaximumSummonMinutes = 4
local soldierMonsterName = Game.MonstersTxt[soldierMonsterId].Name

local function ApplyBaronyHighMageMonsterSetup()
    local source = Game.MonstersTxt[magicianSpellSourceMonsterId]
    local mageCaptain = Game.MonstersTxt[magicianMonsterId]
    local boss = Game.MonstersTxt[warlockMonsterId]

    mageCaptain.Name = "Mage Captain"
    mageCaptain.Spell2 = source.Spell
    mageCaptain.Spell2Skill = source.SpellSkill
    mageCaptain.Spell2Chance = source.SpellChance

    boss.Name = "High Mage"
    boss.Spell2 = source.Spell
    boss.Spell2Skill = source.SpellSkill
    boss.Spell2Chance = source.SpellChance
end

ApplyBaronyHighMageMonsterSetup()

-- Guard compositions ----------------------------------------------------------
local baronyGuardOrderedModulusComposition = {
    DefaultMonsterId = guardMonsterId,
    Overrides = {
        {Every = 3, Offset = 2, MonsterId = captainMonsterId},
        {Every = 2, Offset = 1, MonsterId = lieutenantMonsterId},
    },
}

local baronyGuardArchersComposition = {
    DefaultMonsterId = masterArcherMonsterId,
    Overrides = {
        {XAxisIndex = 0, YAxisIndex = 0, MonsterId = fireArcherMonsterId},
        {XAxisIndex = 1, YAxisIndex = 1, MonsterId = fireArcherMonsterId},
    },
}

local baronyGuardFrontArcherBackComposition = {
    DefaultMonsterId = lieutenantMonsterId,
    Overrides = {
        {XAxisIndex = 0, YAxisIndex = 0, MonsterId = masterArcherMonsterId},
        {XAxisIndex = 0, YAxisIndex = 1, MonsterId = fireArcherMonsterId},
        {XAxisIndex = 0, YAxisIndex = 2, MonsterId = masterArcherMonsterId},
        {XAxisIndex = 0, YAxisIndex = 3, MonsterId = masterArcherMonsterId},
        {XAxisIndex = 1, YAxisIndex = 2, MonsterId = captainMonsterId},
    },
}

local baronyGuardFighterArcherComposition = {
    DefaultMonsterId = lieutenantMonsterId,
    Overrides = {
        {XAxisIndex = 0, YAxisIndex = 2, MonsterId = masterArcherMonsterId},
        {XAxisIndex = 1, YAxisIndex = 2, MonsterId = fireArcherMonsterId},
        {XAxisIndex = 2, YAxisIndex = 2, MonsterId = masterArcherMonsterId},
        {XAxisIndex = 3, YAxisIndex = 2, MonsterId = masterArcherMonsterId},
        {XAxisIndex = 0, YAxisIndex = 1, MonsterId = soldierMonsterId},
        {XAxisIndex = 1, YAxisIndex = 1, MonsterId = soldierMonsterId},
        {XAxisIndex = 2, YAxisIndex = 1, MonsterId = soldierMonsterId},
        {XAxisIndex = 3, YAxisIndex = 1, MonsterId = soldierMonsterId},
        {XAxisIndex = 2, YAxisIndex = 0, MonsterId = captainMonsterId},
    },
}

-- Static town guard formations ------------------------------------------------
local baronyTownGuardFormations = {
    -- Center archers on stairs
    {
        SummonPos = {X = 13500, Y = -2600, Z = 224},
        Formation = {
            XAxisCount = 1, YAxisCount = 2,
            YAxisSpacing = 180,
            MonsterComposition = {
                DefaultMonsterId = fireArcherMonsterId,
            },
        },
    },
    {
        SummonPos = {X = 13100, Y = -2700, Z = 353},
        Formation = {
            XAxisCount = 1, YAxisCount = 1,
            YAxisSpacing = 180,
            MonsterComposition = {
                DefaultMonsterId = fireArcherMonsterId,
            },
        },
    },

    -- East, North
    {
        SummonPos = {X = 17925, Y = 150, Z = 97},
        Formation = {
            XAxisCount = 2, YAxisCount = 5,
            XAxisSpacing = baronyGuardFormationSpacing, YAxisSpacing = baronyGuardFormationSpacing,
            Layout = "StaggeredColumns",
            MonsterComposition = baronyGuardOrderedModulusComposition,
        },
    },
    {
        SummonPos = {X = 17500, Y = 350, Z = 97},
        Formation = {
            XAxisCount = 2, YAxisCount = 4,
            XAxisSpacing = baronyGuardFormationSpacing, YAxisSpacing = baronyGuardFormationSpacing,
            MonsterComposition = baronyGuardArchersComposition,
        },
    },
    -- East, Center
    {
        SummonPos = {X = 18550, Y = -2200, Z = 131},
        Formation = {
            XAxisCount = 2, YAxisCount = 4,
            XAxisSpacing = baronyGuardFormationSpacing, YAxisSpacing = baronyGuardFormationSpacing,
            MonsterComposition = baronyGuardFrontArcherBackComposition,
        },
    },
    -- Southern town entrance
    {
        SummonPos = {X = 16250, Y = -5250, Z = 97},
        Formation = {
            XAxisCount = 4, YAxisCount = 3,
            XAxisSpacing = 180, YAxisSpacing = 200,
            MonsterComposition = baronyGuardFighterArcherComposition,
        },
    },

    -- South eastern town entrance
    {
        SummonPos = {X = 18500, Y = -3850, Z = 97},
        Formation = {
            XAxisCount = 3, YAxisCount = 4,
            XAxisSpacing = 180, YAxisSpacing = 200,
            MonsterComposition = {
                DefaultMonsterId = soldierMonsterId,
            },
        },
    },
    {
        SummonPos = {X = 18317, Y = -5393, Z = 544},
        Formation = {
            XAxisCount = 1, YAxisCount = 2,
            YAxisSpacing = 180,
            Layout = "LooseColumns",
            MonsterComposition = {
                DefaultMonsterId = fireArcherMonsterId,
            },
        },
    }
}

-- Routed castle guard formations ---------------------------------------------
local baronyCastleGuardFormations = {
    {
        DebugName = "Southern throne exit",
        SummonPos = {X = 11206, Y = -3855, Z = 353},
        Formation = {
            XAxisCount = 4, YAxisCount = 2,
            MonsterComposition = baronyGuardOrderedModulusComposition,
        },
        Route = {
            Waypoints = {
                {X = 11585, Y = -3761, Z = 353},
                {X = 12421, Y = -3703, Z = 97},
                {X = 12505, Y = -3757, Z = 96},
                {X = 12442, Y = -4353, Z = 96},
                {X = 12300, Y = -4330, Z = 97},
            },
            Traversal = "Once",
        },
    },
    {
        DebugName = "Northern throne exit",
        SummonPos = {X = 11218, Y = -2310, Z = 353},
        Formation = {
            XAxisCount = 4, YAxisCount = 2,
            MonsterComposition = baronyGuardOrderedModulusComposition,
        },
        Route = {
            Waypoints = {
                {X = 11618, Y = -2325, Z = 353},
                {X = 12421, Y = -2519, Z = 97},
                {X = 12505, Y = -2416, Z = 97},
                {X = 12442, Y = -1832, Z = 96},
                {X = 12650, Y = -1800, Z = 96},
                {X = 12300, Y = -1800, Z = 97},
            },
            Traversal = "Once",
        },
    },
    {
        DebugName = "Main throne exit south",
        SummonPos = {X = 11323, Y = -3136, Z = 97},
        Formation = {
            XAxisCount = 2, YAxisCount = 5,
            MonsterComposition = baronyGuardOrderedModulusComposition,
        },
        Route = {
            Waypoints = {
                {X = 11522, Y = -3227, Z = 97},
                {X = 12443, Y = -3226, Z = 97},
                {X = 12860, Y = -3250, Z = 96},
                {X = 13000, Y = -3800, Z = 96},
            },
            Traversal = "Once",
        },
    },
    {
        DebugName = "Main throne exit north",
        SummonPos = {X = 11322, Y = -2989, Z = 97},
        Formation = {
            XAxisCount = 2, YAxisCount = 5,
            MonsterComposition = baronyGuardOrderedModulusComposition,
        },
        Route = {
            Waypoints = {
                {X = 11590, Y = -2978, Z = 97},
                {X = 12362, Y = -2935, Z = 97},
                {X = 12860, Y = -2971, Z = 96},
                {X = 13000, Y = -2000, Z = 97},
            },
            Traversal = "Once",
        },
    },
}

-- Late castle reinforcements --------------------------------------------------
local baronyCastleGuardBoss = {
    DebugName = "baronyCastleGuardBoss",
    SummonPos = {X = 11323, Y = -3136, Z = 97},
    Formation = {
        XAxisCount = 1, YAxisCount = 1,
        MonsterComposition = {
            DefaultMonsterId = warlockMonsterId,
        },
    },
    Route = {
        Waypoints = {
            {X = 11522, Y = -3227, Z = 97},
            {X = 12082, Y = -3093, Z = 97},
        },
        Traversal = "Once",
    },
}

local baronyCastleArcherAtopStairs = {
    -- south
    {
        DebugName = "Southern throne exit archers",
        SummonPos = {X = 11206, Y = -3855, Z = 353},
        Formation = {
            XAxisCount = 1, YAxisCount = 4,
            MonsterComposition = {
                DefaultMonsterId = fireArcherMonsterId,
            },
        },
        Route = {
            Waypoints = {
                {X = 11570, Y = -3800, Z = 353},
            },
            Traversal = "Once",
        },
    },
    -- north
    {
        DebugName = "Northern throne exit archers",
        SummonPos = {X = 11218, Y = -2310, Z = 353},
        Formation = {
            XAxisCount = 1, YAxisCount = 4,
            MonsterComposition = {
                DefaultMonsterId = fireArcherMonsterId,
            },
        },
        Route = {
            Waypoints = {
                {X = 11570, Y = -2400, Z = 353},
            },
            Traversal = "Once",
        },
    },
}


-- Guard patrol routes ---------------------------------------------------------
local baronyNorthernGuardPatrol = {
    DebugName = "Northern guard patrol",
    SummonPos = {X = 13000, Y = 250, Z = 96},
    Formation = {
        XAxisCount = 2,
        YAxisCount = 2,
        XAxisSpacing = baronyGuardFormationSpacing,
        YAxisSpacing = baronyGuardFormationSpacing,
        MonsterComposition = {
            DefaultMonsterId = captainMonsterId,
        },
    },
    Route = {
        Waypoints = {
            {X = 13000, Y = 350, Z = 96},
            {X = 14000, Y = 350, Z = 96},
            {X = 15000, Y = 350, Z = 96},
            {X = 16000, Y = 350, Z = 96},
            {X = 17000, Y = 350, Z = 96}
        },
        Traversal = "PingPong",
        WaypointWaitDuration = 1 * const.Minute,
    },
}

local baronyNorthernGuardPatrol2 = {
    DebugName = "Northern guard patrol2",
    SummonPos = {X = 13000, Y = 250, Z = 96},
    Formation = {
        XAxisCount = 2,
        YAxisCount = 2,
        XAxisSpacing = baronyGuardFormationSpacing,
        YAxisSpacing = baronyGuardFormationSpacing,
        MonsterComposition = {
            DefaultMonsterId = captainMonsterId,
        },
    },
    Route = {
        Waypoints = {
            {X = 17000, Y = 50, Z = 96},
            {X = 16000, Y = 50, Z = 96},
            {X = 15000, Y = 50, Z = 96},
            {X = 14000, Y = 50, Z = 96},
            {X = 13000, Y = 50, Z = 96},
        },
        Traversal = "PingPong",
        WaypointWaitDuration = 1 * const.Minute,
    },
}

local baronCenterGuardPatrol = {
    DebugName = "Center guard patrol",
    SummonPos = {X = 15800, Y = -1870, Z = 96},
    Formation = {
        XAxisCount = 2,
        YAxisCount = 3,
        XAxisSpacing = baronyGuardFormationSpacing,
        YAxisSpacing = baronyGuardFormationSpacing,
        MonsterComposition = {
            DefaultMonsterId = soldierMonsterId,
            Overrides = {
                {XAxisIndex = 1, YAxisIndex = 1, MonsterId = magicianMonsterId},
            }
        },
    },
    Route = {
        Waypoints = {
            {X = 16200, Y = -1870, Z = 224},
            {X = 14536, Y = -1962, Z = 97},
            {X = 14000, Y = -2135, Z = 97},
            {X = 13900, Y = -2800, Z = 97},
            {X = 15400, Y = -2800, Z = 97},
            {X = 16200, Y = -2800, Z = 97},
            {X = 17400, Y = -2800, Z = 97},
            {X = 16200, Y = -2800, Z = 97},
        },
        Traversal = "Loop",
        WaypointWaitDuration = 1 * const.Minute,
    },
}

local baronySouthernGuardPatrol = {
    DebugName = "Southern guard patrol",
    SummonPos = {X = 13400, Y = -3825, Z = 96},
    Formation = {
        XAxisCount = 2,
        YAxisCount = 2,
        XAxisSpacing = baronyGuardFormationSpacing,
        YAxisSpacing = baronyGuardFormationSpacing,
        MonsterComposition = {
            DefaultMonsterId = captainMonsterId,
        },
    },
    Route = {
        Waypoints = {
            {X = 13400, Y = -4150, Z = 96},
            {X = 14400, Y = -4150, Z = 96},
            {X = 15400, Y = -4150, Z = 96},
            {X = 16400, Y = -4150, Z = 96},
            {X = 17400, Y = -4150, Z = 96},
        },
        Traversal = "PingPong",
        WaypointWaitDuration = 1 * const.Minute,
    }
}

local baronySouthernGuardPatrol2 = {
    DebugName = "Southern guard patrol2",
    SummonPos = {X = 13400, Y = -3825, Z = 96},
    Formation = {
        XAxisCount = 2,
        YAxisCount = 2,
        XAxisSpacing = baronyGuardFormationSpacing,
        YAxisSpacing = baronyGuardFormationSpacing,
        MonsterComposition = {
            DefaultMonsterId = captainMonsterId,
        },
    },
    Route = {
        Waypoints = {
            {X = 17400, Y = -3850, Z = 96},
            {X = 16400, Y = -3850, Z = 96},
            {X = 15400, Y = -3850, Z = 96},
            {X = 14400, Y = -3850, Z = 96},
            {X = 13400, Y = -3850, Z = 96},
        },
        Traversal = "PingPong",
        WaypointWaitDuration = 1 * const.Minute,
    }
}

local baronyGuardPatrols = {
    baronyNorthernGuardPatrol,
    baronyNorthernGuardPatrol2,
    baronySouthernGuardPatrol,
    baronySouthernGuardPatrol2,
    baronCenterGuardPatrol
}

-- Derived movement formation setup -------------------------------------------
local baronyCastleGuardMaxSummons = 0
for _, definition in ipairs(baronyCastleGuardFormations) do
    definition.MaxSummons = definition.Formation.XAxisCount * definition.Formation.YAxisCount
    baronyCastleGuardMaxSummons = baronyCastleGuardMaxSummons + definition.MaxSummons
end

local baronyCastleGuardMovementFormations = {}
for _, definition in ipairs(baronyCastleGuardFormations) do
    table.insert(baronyCastleGuardMovementFormations, definition)
end
local baronyCastleArcherAtopStairsPairCount =
    baronyCastleArcherAtopStairs[1].Formation.XAxisCount * baronyCastleArcherAtopStairs[1].Formation.YAxisCount

local baronyCastleArcherAtopStairsFirstFormationIndex = #baronyCastleGuardMovementFormations + 1
for _, definition in ipairs(baronyCastleArcherAtopStairs) do
    table.insert(baronyCastleGuardMovementFormations, definition)
end
local baronyCastleGuardBossFormationIndex = #baronyCastleGuardMovementFormations + 1
table.insert(baronyCastleGuardMovementFormations, baronyCastleGuardBoss)

-- Hoisted forward declarations ------------------------------------------------
local ApplyPermanentEndingState
local AlertNearbyBaronyGuards
local HoldBaronyTownGuard
local ReleaseBaronyTownGuard
local ShouldReleaseBaronyGuard
local FinishBaronyDefense
local StartBaronyDefense
local SummonBaronyCastleArchersAtopStairs
local SummonBaronyCastleGuardBoss
local SummonBaronyCastleGuards
local SummonBaronyTownGuards
local SummonBaronyGuardPatrols
local MonitorBaronyDefense
local ApplyBaronyVeteranSoldierSetup
local baronyCastleGuardFormationController
local baronyGuardPatrolController

-- Guard helpers ---------------------------------------------------------------
local function ForEachBaronyGuard(callback)
    for _, encounterName in ipairs(baronyGuardEncounterNames) do
        ForEachMonsterEncounter(GetMonsterEncounter(encounterName, P.FrozenHighlands), function(record, mon)
            callback(record, mon, encounterName)
        end)
    end
end

local function IsBaronyGuard(mon)
    for _, encounterName in ipairs(baronyGuardEncounterNames) do
        if MonsterEncounterContainsMonster(GetMonsterEncounter(encounterName, P.FrozenHighlands), mon) == true then
            return true
        end
    end
    return false
end

local function ConfigureBaronyGuard(mon, options)
    P.ConfigureQuestMonster(mon, true, 0, baronyGuardGroup, options)
end

local function ConfigureActiveBaronyGuard(mon)
    ConfigureBaronyGuard(mon, {
        GuardRadius = 256,
        AIState = const.AIState.Active,
    })
end

local function ActivateReleasedBaronyFormationGuard(mon)
    mon.GuardRadius = baronyGuardReleasedGuardRadius
    mon.AIState = const.AIState.Active
    mon:UpdateGraphicState()
end

-- Ending helpers --------------------------------------------------------------
local function SetupPermanentEndingNPCs()
    if vars.PrinceThievesBaronySwapComplete ~= true then
        return
    end
    Game.NPC[P.MorganNPC].House = P.FrozenHighlandsThroneRoomHouse
    Game.NPC[P.AnthonyStoneNPC].House = P.FrozenHighlandsThroneRoomHouse
    if vars.Quests[P.StealBaronyQuest] == "Done" then
        Game.NPC[P.PrinceNPC].House = P.PrisonHouse
    end
    Game.NPC[P.AnthonyStoneNPC].Name = "The Prince of Thieves"
    Game.NPC[P.PrinceNPC].Name = "Anthony Stone"
    if vars.PrinceThievesOriginalAnthonyPic ~= nil then
        Game.NPC[P.AnthonyStoneNPC].Pic = vars.PrinceThievesOriginalAnthonyPic
        vars.PrinceThievesOriginalAnthonyPic = nil
    end
    if vars.PrinceThievesOriginalPrincePic ~= nil then
        Game.NPC[P.PrinceNPC].Pic = vars.PrinceThievesOriginalPrincePic
        vars.PrinceThievesOriginalPrincePic = nil
    end
end

-- Quest stages ----------------------------------------------------------------
Quest{
    P.StealBaronyQuest,
    Slot = E,
    NPC = P.PrinceNPC,
    CanShow = function()
        return (P.InIvanMagyarHouse() and vars.PrinceThievesIvanRescueTurnedIn == true and
            vars.PrinceThievesBaronySwapComplete ~= true)
    end,
    Give = function()
        vars.PrinceThievesStealBaronyPlanGiven = nil
        evt.PlaySound(205) -- quest sound
    end,
    CheckDone = function()
        return false
    end,
}.SetTexts {
    FirstTopic = "Stealing a barony",
    Topic = "Stealing a barony",
    Give = [[
Even now Anthony Stone's men are looking for me.

Perhaps it's time to put the title "Prince of Thieves" on the mantle.

And...

Become a Baron!

With the help of you and Morgan we will steal the barony!

Speak with Morgan. He will tell you the plan.]],
    Undone = "Speak with Morgan about the plan, then meet us in the Frozen Highlands.",
    Done = "That little plan worked out well. Be sure to visit the... erh... prince in prison",
}

Quest{
    "Quest_PrinceOfThieves_StealBarony_TurnIn",
    BaseName = P.StealBaronyQuest,
    Quest = false,
    Slot = E,
    NPC = P.AnthonyStoneNPC,
    CanShow = function()
        return P.InFrozenHighlandsThroneRoom() and vars.PrinceThievesBaronySwapComplete == true and
            vars.Quests[P.StealBaronyQuest] == "Given"
    end,
    CheckDone = function()
        return vars.PrinceThievesBaronySwapComplete == true
    end,
    Done = function()
        for _, encounterName in ipairs(baronyGuardEncounterNames) do
            RemoveNamedMonsterEncounter(encounterName, P.FrozenHighlands)
        end
        P.RestoreRemovedFriendlyMonsters(P.FrozenHighlandsCastleAmbientRemovalKey)
        ApplyPermanentEndingState()
    end,
    Exp = 30000,
    Gold = 10000,
}.SetTexts {
    Topic = "Stealing a barony",
    Done = "That little plan worked out well. Be sure to visit the... erh... prince in prison",
}

NPCTopic {
    Slot = C,
    NPC = P.MorganNPC,
    CanShow = function()
        return P.InIvanMagyarHouse() and vars.Quests[P.StealBaronyQuest] == "Given"
    end,
    Topic = "How to steal a Barony",
    Ungive = function()
        vars.PrinceThievesStealBaronyPlanGiven = true
        evt.PlaySound(205) -- quest sound
        -- Message("Meet Morgan and the Prince in the Frozen Highlands.")
    end,
    Text = [[He wanted me to tell you the plan, huh? This crazy plan was his idea, so don't judge me.

Me and the "Prince" will hide close to the baron's hall. When you get there I will disguise ]] .. Party[0].Name .. [[ as the Prince of Thieves.

This will draw the guards' ire upon you.

While you fight them off, we will sneak into the throne room and bonk Anthony Stone on the head.

Then I'll disguise the Prince to look like the baron!]]
}

Greeting {
    NPC = P.MorganNPC,
    CanShow = function()
        return vars.PrinceThievesDialogStage == "BaronyDefense"
    end,
    Text = [[
Good, you're here.

Let me apply a little bit of my special makeup on ]] .. Party[0].Name .. [[.

There now. The correct beard and everything.

This will get the guards really riled up. Be ready!

Taking out the guards near the castle should be enough for us to do our job.
]]
}

NPCTopic {
    Slot = A,
    NPC = P.MorganNPC,
    CanShow = function()
        return P.InFrozenHighlandsThroneRoom() and vars.PrinceThievesBaronySwapComplete == true
    end,
    Topic = "The baron and the thief",
    Text = [[
[Morgan lowers his voice]

The disguise is flawless. 

With me here to maintain it, both the former prince and baron will remain in their new roles.
]]
}

NPCTopic {
    Slot = A,
    NPC = P.PrinceNPC,
    CanShow = function()
        return P.InPrincePrison() and vars.Quests[P.StealBaronyQuest] == "Done"
    end,
    Topic = "The Baron Anthony Stone",
    Text = "I am Anthony Stone! I am the Baron! Take me out of this prison and I will prove it!"
}

ApplyPermanentEndingState = function()
    if vars.PrinceThievesBaronySwapComplete ~= true then
        return
    end
    P.RestoreAnthonyDialogState()
    SetupPermanentEndingNPCs()
end

P.ApplyPermanentEndingState = ApplyPermanentEndingState

-- Guard combat and movement helpers ------------------------------------------
AlertNearbyBaronyGuards = function(origin, releaseOrigin, reason)
    local alertRadiusSquared = baronyGuardAlertRadius ^ 2

    ForEachBaronyGuard(function(record, mon, encounterName)
        if mon ~= origin and IsAlive(mon) then
            local dx = mon.X - origin.X
            local dy = mon.Y - origin.Y
            local dz = mon.Z - origin.Z
            if dx * dx + dy * dy + dz * dz <= alertRadiusSquared then
                if encounterName == baronyCastleGuardEncounterName then
                    baronyCastleGuardFormationController:ReleaseMonster(record.index, reason)
                elseif encounterName == baronyGuardPatrolEncounterName then
                    baronyGuardPatrolController:ReleaseMonster(record.index, reason)
                else
                    ReleaseBaronyTownGuard(mon)
                end
            end
        end
    end)

    if releaseOrigin then
        local castleEncounter = GetMonsterEncounter(baronyCastleGuardEncounterName, P.FrozenHighlands)
        if MonsterEncounterContainsMonster(castleEncounter, origin) == true then
            baronyCastleGuardFormationController:ReleaseMonster(origin:GetIndex(), reason)
        elseif MonsterEncounterContainsMonster(
            GetMonsterEncounter(baronyGuardPatrolEncounterName, P.FrozenHighlands), origin) == true then
            baronyGuardPatrolController:ReleaseMonster(origin:GetIndex(), reason)
        else
            ReleaseBaronyTownGuard(origin)
        end
    end
end

ApplyBaronyVeteranSoldierSetup = function()
    Game.MonstersTxt[soldierMonsterId].Name = "Veteran Soldier"
    ForEachBaronyGuard(function(_, mon)
        if mon.Id == soldierMonsterId and IsAlive(mon) then
            ApplyMonsterPowerFromMonster(mon, Game.MonstersTxt[veteranMonsterId], false)
        end
    end)
end

HoldBaronyTownGuard = function(mon, anchor)
    mon.X = anchor.X
    mon.Y = anchor.Y
    mon.StartX = anchor.X
    mon.StartY = anchor.Y
    mon.GuardX = anchor.X
    mon.GuardY = anchor.Y
    mon.GuardZ = anchor.Z
    mon.Direction = anchor.Direction
    mon.GuardRadius = 0
    mon.VelocityX = 0
    mon.VelocityY = 0
    mon.CurrentActionLength = const.Hour
    mon.CurrentActionStep = 0
    mon.AIState = const.AIState.Stand
    mon:UpdateGraphicState()
end

ReleaseBaronyTownGuard = function(mon)
    mapvars.PrinceThievesBaronyTownGuardsReleased = mapvars.PrinceThievesBaronyTownGuardsReleased or {}
    mapvars.PrinceThievesBaronyTownGuardsReleased[mon:GetIndex()] = true
    mon.StartX = mon.X
    mon.StartY = mon.Y
    mon.StartZ = mon.Z
    mon.GuardX = mon.X
    mon.GuardY = mon.Y
    mon.GuardZ = mon.Z
    mon.GuardRadius = baronyGuardReleasedGuardRadius
    mon.VelocityX = 0
    mon.VelocityY = 0
    mon.VelocityZ = 0
    mon.CurrentActionLength = 0
    mon.CurrentActionStep = 0
    mon.AIState = const.AIState.Active
    mon:UpdateGraphicState()
end

ShouldReleaseBaronyGuard = function(mon)
    if mon:IsAgainst() <= 0 or Party.SpellBuffs[const.PartyBuff.Invisibility].ExpireTime > Game.Time then
        return false
    end

    local dx = mon.X - Party.X
    local dy = mon.Y - Party.Y
    local dz = mon.Z - Party.Z
    if dx * dx + dy * dy + dz * dz > baronyGuardDetectionDistance ^ 2 then
        return false
    end

    if Pathfinder == nil or Pathfinder.TraceSight == nil or Pathfinder.TraceSight(mon, Party) ~= true then
        return false
    end

    AlertNearbyBaronyGuards(mon, false, "nearby_alert")
    return true
end

baronyCastleGuardFormationController = MonsterFormation.CreateMovementController {
    Name = "PrinceThievesBaronyCastleGuards",
    Formations = baronyCastleGuardMovementFormations,
    Spacing = baronyGuardFormationSpacing,
    Direction = 2028,
    IsActive = P.IsBaronyDefenseActive,
    ShouldRelease = ShouldReleaseBaronyGuard,
    OnRelease = function(mon, record)
        if record.Formation <= #baronyCastleGuardFormations then
            vars.PrinceThievesBaronyCastleGuardFormationInterrupted = true
        end
        ActivateReleasedBaronyFormationGuard(mon)
    end,
}

baronyGuardPatrolController = MonsterFormation.CreateMovementController {
    Name = "PrinceThievesBaronyGuardPatrol",
    Formations = baronyGuardPatrols,
    Spacing = baronyGuardFormationSpacing,
    IsActive = P.IsBaronyDefenseActive,
    ShouldRelease = ShouldReleaseBaronyGuard,
    OnRelease = ActivateReleasedBaronyFormationGuard,
}

-- Quest runtime helpers -------------------------------------------------------
FinishBaronyDefense = function()
    if vars.PrinceThievesBaronySwapComplete == true then
        ApplyPermanentEndingState()
        return
    end

    vars.PrinceThievesBaronyDefendersDefeated = true
    vars.PrinceThievesBaronySwapComplete = true
    Game.MonstersTxt[soldierMonsterId].Name = soldierMonsterName
    ApplyPermanentEndingState()
end

local function ResetBaronyDefenseState()
    vars.PrinceThievesBaronyDefenseStarted = true
    vars.PrinceThievesBaronyCastleGuardsSummoned = 0
    vars.PrinceThievesBaronyCastleGuardLastSummonTime = nil
    vars.PrinceThievesBaronyCastleGuardFormationInterrupted = nil
    vars.PrinceThievesBaronyCastleArchersAtopStairsSummoned = nil
    vars.PrinceThievesBaronyCastleArcherPairsSummoned = nil
    vars.PrinceThievesBaronyCastleArcherNextSummonTime = nil
    vars.PrinceThievesBaronyCastleArcherLastSummonTime = nil
    vars.PrinceThievesBaronyCastleGuardBossSummoned = nil
    mapvars.PrinceThievesBaronyCastleGuardSummonsByFormation = {}
    mapvars.PrinceThievesBaronyCastleGuardLastSummonIndex = nil
    mapvars.PrinceThievesBaronyTownGuardAnchors = {}
    mapvars.PrinceThievesBaronyTownGuardsReleased = {}
    baronyCastleGuardFormationController:Reset()
    baronyGuardPatrolController:Reset()
end

StartBaronyDefense = function()
    if not P.IsStealBaronyStartedInFrozenHighlands() or vars.PrinceThievesBaronyDefenseStarted == true then
        return
    end

    ResetBaronyDefenseState()
    P.RemoveFriendlyMonstersInRadius(
        P.FrozenHighlandsCastleAmbientRemovalKey,
        P.FrozenHighlandsCastleCenterX, P.FrozenHighlandsCastleCenterY, P.FrozenHighlandsCastleCenterZ,
        P.FrozenHighlandsCastleFriendlyRemovalRadius)
    SummonBaronyTownGuards()
    SummonBaronyGuardPatrols()
    vars.PrinceThievesDialogStage = "BaronyDefense"
    evt.SpeakNPC{P.MorganNPC}
end

SummonBaronyTownGuards = function()
    if not P.IsBaronyDefenseActive() then
        return
    end

    local existingTownGuardEncounter = GetMonsterEncounter(baronyTownGuardEncounterName, P.FrozenHighlands)
    local replacedFireArcherIndexes = P.ReplaceFrozenHighlandsCastleFireArchers(
        fireArcherMonsterId,
        existingTownGuardEncounter,
        function(mon, index, position)
            ConfigureBaronyGuard(mon, {
                Direction = position.Direction,
                GuardRadius = 0,
                AIState = const.AIState.Stand,
            })
            local anchor = {X = mon.X, Y = mon.Y, Z = mon.Z, Direction = mon.Direction}
            mapvars.PrinceThievesBaronyTownGuardAnchors[index] = anchor
            HoldBaronyTownGuard(mon, anchor)
        end)
    if existingTownGuardEncounter ~= nil then
        return
    end

    local _, townGuardIndexes = MonsterFormation.SummonMany(baronyTownGuardFormations, function(mon, index)
        ConfigureBaronyGuard(mon, {
            GuardRadius = 0,
            AIState = const.AIState.Stand,
        })
        local anchor = {X = mon.X, Y = mon.Y, Z = mon.Z, Direction = mon.Direction}
        mapvars.PrinceThievesBaronyTownGuardAnchors[index] = anchor
        HoldBaronyTownGuard(mon, anchor)
    end)

    for _, index in ipairs(replacedFireArcherIndexes) do
        table.insert(townGuardIndexes, index)
    end

    CreateAndSetMonsterEncounterFromIndexes(baronyTownGuardEncounterName, townGuardIndexes, P.FrozenHighlands)
    ApplyBaronyVeteranSoldierSetup()
end

SummonBaronyGuardPatrols = function()
    if not P.IsBaronyDefenseActive() or
        GetMonsterEncounter(baronyGuardPatrolEncounterName, P.FrozenHighlands) ~= nil then
        return
    end

    local patrolIndexes = {}
    for formationIndex, patrol in ipairs(baronyGuardPatrols) do
        local monsters, indexes = MonsterFormation.Summon {
            SummonPos = patrol.SummonPos,
            Formation = patrol.Formation,
            Configure = ConfigureActiveBaronyGuard,
        }
        for formationSlot, mon in ipairs(monsters) do
            local index = indexes[formationSlot]
            baronyGuardPatrolController:AddMonster(mon, index, formationIndex, formationSlot)
            table.insert(patrolIndexes, index)
        end
    end
    CreateAndSetMonsterEncounterFromIndexes(baronyGuardPatrolEncounterName, patrolIndexes, P.FrozenHighlands)
    ApplyBaronyVeteranSoldierSetup()
end

-- Castle reinforcement timers -------------------------------------------------
local function NextBaronyCastleGuardSummonTime()
    return Game.Time + math.random(baronyCastleGuardMinimumSummonMinutes, baronyCastleGuardMaximumSummonMinutes) * const.Minute
end

local baronyCastleGuardSummonTimers = {}

local function SummonBaronyCastleGuard(formationIndex)
    mapvars.PrinceThievesBaronyCastleGuardSummonsByFormation =
        mapvars.PrinceThievesBaronyCastleGuardSummonsByFormation or {}
    local formationSummons = mapvars.PrinceThievesBaronyCastleGuardSummonsByFormation
    if not P.IsBaronyDefenseActive() or
        (vars.PrinceThievesBaronyCastleGuardsSummoned or 0) >= baronyCastleGuardMaxSummons or
        (formationSummons[formationIndex] or 0) >= baronyCastleGuardFormations[formationIndex].MaxSummons then
        RemoveTimer()
        return
    end
    if P.IsOutsideFrozenHighlandsCastleLeash() then
        return
    end

    local definition = baronyCastleGuardFormations[formationIndex]
    local summonPos = definition.SummonPos
    local formationSlot = (formationSummons[formationIndex] or 0) + 1
    local formationPosition = baronyCastleGuardFormationController:GetFormationPosition(formationIndex, formationSlot)
    local monsterId = MonsterFormation.SelectMonsterIdFromComposition(
        definition.Formation.MonsterComposition,
        formationSlot - 1,
        formationPosition.XAxisIndex,
        formationPosition.YAxisIndex,
        definition)
    local mon, index = SummonMonster(monsterId, summonPos.X, summonPos.Y, summonPos.Z, true)
    ConfigureActiveBaronyGuard(mon)
    formationSummons[formationIndex] = formationSlot
    baronyCastleGuardFormationController:AddMonster(mon, index, formationIndex, formationSlot)
    vars.PrinceThievesBaronyCastleGuardsSummoned = (vars.PrinceThievesBaronyCastleGuardsSummoned or 0) + 1
    if vars.PrinceThievesBaronyCastleGuardsSummoned >= baronyCastleGuardMaxSummons then
        vars.PrinceThievesBaronyCastleGuardLastSummonTime = Game.Time
        mapvars.PrinceThievesBaronyCastleGuardLastSummonIndex = index
    end
    if GetMonsterEncounter(baronyCastleGuardEncounterName, P.FrozenHighlands) == nil then
        CreateAndSetMonsterEncounterFromIndexes(baronyCastleGuardEncounterName, {index}, P.FrozenHighlands)
    else
        AddMonsterEncounterIndexes(baronyCastleGuardEncounterName, {index}, P.FrozenHighlands)
    end
    ApplyBaronyVeteranSoldierSetup()
end

local function LastBaronyCastleGuardSummonInPosition()
    local movementStates = mapvars.MonsterFormations
    local movementState = movementStates and movementStates[baronyCastleGuardFormationController.Name]
    local lastSummonIndex = mapvars.PrinceThievesBaronyCastleGuardLastSummonIndex
    return movementState ~= nil and lastSummonIndex ~= nil
        and movementState.Anchors[lastSummonIndex] ~= nil
end

SummonBaronyCastleArchersAtopStairs = function()
    if not P.IsBaronyDefenseActive() or
        vars.PrinceThievesBaronyCastleArchersAtopStairsSummoned == true or
        (vars.PrinceThievesBaronyCastleGuardsSummoned or 0) < baronyCastleGuardMaxSummons then
        return
    end

    local pairsSummoned = vars.PrinceThievesBaronyCastleArcherPairsSummoned or 0
    if pairsSummoned == 0 then
        if vars.PrinceThievesBaronyCastleGuardFormationInterrupted == true then
            local lastSummonTime = vars.PrinceThievesBaronyCastleGuardLastSummonTime
            if lastSummonTime == nil or Game.Time < lastSummonTime + 2 * const.Minute then
                return
            end
        elseif not LastBaronyCastleGuardSummonInPosition() then
            return
        end
    elseif vars.PrinceThievesBaronyCastleArcherNextSummonTime == nil or
        Game.Time < vars.PrinceThievesBaronyCastleArcherNextSummonTime then
        return
    end

    local formationSlot = pairsSummoned + 1
    local indexes = {}
    for archerFormationOffset, definition in ipairs(baronyCastleArcherAtopStairs) do
        local controllerFormationIndex = baronyCastleArcherAtopStairsFirstFormationIndex + archerFormationOffset - 1
        local formationPosition =
            baronyCastleGuardFormationController:GetFormationPosition(controllerFormationIndex, formationSlot)
        local monsterId = MonsterFormation.SelectMonsterIdFromComposition(
            definition.Formation.MonsterComposition,
            formationSlot - 1,
            formationPosition.XAxisIndex,
            formationPosition.YAxisIndex,
            definition)
        local mon, index = SummonMonster(
            monsterId, definition.SummonPos.X, definition.SummonPos.Y, definition.SummonPos.Z, true)
        ConfigureActiveBaronyGuard(mon)
        baronyCastleGuardFormationController:AddMonster(mon, index, controllerFormationIndex, formationSlot)
        table.insert(indexes, index)
    end
    AddMonsterEncounterIndexes(baronyCastleGuardEncounterName, indexes, P.FrozenHighlands)

    vars.PrinceThievesBaronyCastleArcherPairsSummoned = formationSlot
    if formationSlot >= baronyCastleArcherAtopStairsPairCount then
        vars.PrinceThievesBaronyCastleArchersAtopStairsSummoned = true
        vars.PrinceThievesBaronyCastleArcherNextSummonTime = nil
        vars.PrinceThievesBaronyCastleArcherLastSummonTime = Game.Time
    else
        vars.PrinceThievesBaronyCastleArcherNextSummonTime = Game.Time + 4 * const.Second
    end
end

SummonBaronyCastleGuardBoss = function()
    if not P.IsBaronyDefenseActive() or vars.PrinceThievesBaronyCastleGuardBossSummoned == true or
        vars.PrinceThievesBaronyCastleArchersAtopStairsSummoned ~= true then
        return
    end

    local lastArcherSummonTime = vars.PrinceThievesBaronyCastleArcherLastSummonTime
    if lastArcherSummonTime == nil or Game.Time < lastArcherSummonTime + 20 * const.Second then
        return
    end

    local monsters, indexes = MonsterFormation.Summon {
        SummonPos = baronyCastleGuardBoss.SummonPos,
        Formation = baronyCastleGuardBoss.Formation,
        Configure = ConfigureActiveBaronyGuard,
    }
    baronyCastleGuardFormationController:AddMonster(
        monsters[1], indexes[1], baronyCastleGuardBossFormationIndex, 1)
    AddMonsterEncounterIndexes(baronyCastleGuardEncounterName, indexes, P.FrozenHighlands)
    vars.PrinceThievesBaronyCastleGuardBossSummoned = true
end

local function EnsureBaronyCastleGuardSummonTimers()
    if #baronyCastleGuardSummonTimers > 0 then
        return
    end

    for formationIndex in ipairs(baronyCastleGuardFormations) do
        local summonFormationIndex = formationIndex
        baronyCastleGuardSummonTimers[formationIndex] = function()
            SummonBaronyCastleGuard(summonFormationIndex)
        end
    end
end

SummonBaronyCastleGuards = function()
    if not P.InFrozenHighlands() or (vars.PrinceThievesBaronyCastleGuardsSummoned or 0) >= baronyCastleGuardMaxSummons or
        svars.PrinceThievesBaronyCastleGuardSummonTimersRunning == true or P.IsOutsideFrozenHighlandsCastleLeash() then
        return
    end

    EnsureBaronyCastleGuardSummonTimers()
    for _, summonTimer in ipairs(baronyCastleGuardSummonTimers) do
        Timer(summonTimer, const.Minute, NextBaronyCastleGuardSummonTime(), false, NextBaronyCastleGuardSummonTime)
    end
    svars.PrinceThievesBaronyCastleGuardSummonTimersRunning = true
end

-- Defense monitor and route recovery -----------------------------------------
local function EnsureBaronyDefenseTimer()
    if svars.PrinceThievesBaronyDefenseTimerRunning ~= true then
        Timer(MonitorBaronyDefense, const.Second)
        svars.PrinceThievesBaronyDefenseTimerRunning = true
    end
end

MonitorBaronyDefense = function()
    if P.IsStealBaronyStartedInFrozenHighlands() and vars.PrinceThievesBaronyDefenseStarted ~= true and
        Game.CurrentScreen == 0 then
        StartBaronyDefense()
        return
    end

    if P.IsBaronyDefenseActive() then
        SummonBaronyTownGuards()
        SummonBaronyGuardPatrols()
        SummonBaronyCastleGuards()
        SummonBaronyCastleArchersAtopStairs()
        SummonBaronyCastleGuardBoss()
        local castleEncounter = GetMonsterEncounter(baronyCastleGuardEncounterName, P.FrozenHighlands)
        -- Keep these comments, in case we want to increase the scope.
        -- local townEncounter = GetMonsterEncounter(baronyTownGuardEncounterName, P.FrozenHighlands)
        -- local patrolEncounter = GetMonsterEncounter(baronyGuardPatrolEncounterName, P.FrozenHighlands)
        if (vars.PrinceThievesBaronyCastleGuardsSummoned or 0) >= baronyCastleGuardMaxSummons and
            vars.PrinceThievesBaronyCastleGuardBossSummoned == true and
            castleEncounter ~= nil and MonsterEncounterHasAnyActive(castleEncounter) == false
            -- Keep these comments, in case we want to increase the scope.
            -- townEncounter ~= nil and MonsterEncounterHasAnyActive(townEncounter) == false and
            -- patrolEncounter ~= nil and MonsterEncounterHasAnyActive(patrolEncounter) == false 
            then
            FinishBaronyDefense()
        end
    end
end

local function StopBaronyDefenseMonstersForMapLeave()
    ForEachBaronyGuard(function(_, mon)
        if IsAlive(mon) then
            mon.VelocityX = 0
            mon.VelocityY = 0
            mon.VelocityZ = 0
            mon.CurrentActionLength = 0
            mon.CurrentActionStep = 0
            mon.AIState = const.AIState.Stand
            mon:UpdateGraphicState()
        end
    end)

    for _, controller in ipairs({baronyCastleGuardFormationController, baronyGuardPatrolController}) do
        controller:Suspend()
    end
end

local function GetAliveEncounterMonsters(encounterName)
    local aliveIndexes = {}

    ForEachMonsterEncounter(GetMonsterEncounter(encounterName, P.FrozenHighlands), function(record, mon)
        if IsAlive(mon) then
            aliveIndexes[record.index] = mon
        end
    end)
    return aliveIndexes
end

local function RestartBaronyDefenseRoutes()
    local skippedCastleOnceRoute = baronyCastleGuardFormationController:RestartAssignedMonsters(
        GetAliveEncounterMonsters(baronyCastleGuardEncounterName))
    baronyGuardPatrolController:RestartAssignedMonsters(GetAliveEncounterMonsters(baronyGuardPatrolEncounterName))
    if skippedCastleOnceRoute then
        vars.PrinceThievesBaronyCastleGuardFormationInterrupted = true
    end

    local releasedTownGuards = mapvars.PrinceThievesBaronyTownGuardsReleased or {}
    ForEachMonsterEncounter(GetMonsterEncounter(baronyTownGuardEncounterName, P.FrozenHighlands), function(record, mon)
        if IsAlive(mon) and releasedTownGuards[record.index] == true then
            ReleaseBaronyTownGuard(mon)
        end
    end)

    SummonBaronyCastleArchersAtopStairs()
    SummonBaronyCastleGuardBoss()
end

-- Event listeners -------------------------------------------------------------
function events.MonstersProcessed()
    if not P.IsBaronyDefenseActive() then
        return
    end

    -- Town guards are static anchors, not routed MonsterFormation members.
    -- Keep them pinned here until normal guard alert logic releases them.
    local anchors = mapvars.PrinceThievesBaronyTownGuardAnchors or {}
    local released = mapvars.PrinceThievesBaronyTownGuardsReleased or {}
    ForEachMonsterEncounter(GetMonsterEncounter(baronyTownGuardEncounterName, P.FrozenHighlands), function(record, mon)
        local anchor = anchors[record.index]
        if IsAlive(mon) and released[record.index] ~= true and anchor ~= nil then
            if ShouldReleaseBaronyGuard(mon) then
                ReleaseBaronyTownGuard(mon)
            else
                HoldBaronyTownGuard(mon, anchor)
            end
        end
    end)
end

function events.AfterLoadMap()
    if P.InFrozenHighlands() then
        if vars.PrinceThievesBaronyCastleGuardBossSummoned == true then
            Game.MonstersTxt[warlockMonsterId].Name = "High Mage"
        end
        if P.IsBaronyDefenseActive() and vars.PrinceThievesDialogStage ~= "BaronyDefense" then
            P.RestoreRemovedFriendlyMonstersMatching(
                P.FrozenHighlandsCastleAmbientRemovalKey,
                function(_, mon)
                    return IsBaronyGuard(mon)
                end)
            P.ReapplyRemovedFriendlyMonsterHiding(P.FrozenHighlandsCastleAmbientRemovalKey)
            SummonBaronyTownGuards()
            SummonBaronyGuardPatrols()
            SummonBaronyCastleGuards()
        end
        if P.IsBaronyDefenseActive() then
            RestartBaronyDefenseRoutes()
            ApplyBaronyVeteranSoldierSetup()
        end
        ApplyPermanentEndingState()
    end
    if P.IsStealBaronyStartedInFrozenHighlands() or P.IsBaronyDefenseActive() then
        EnsureBaronyDefenseTimer()
    end
end

function events.LeaveMap()
    if P.InFrozenHighlands() then
        if P.IsBaronyDefenseActive() then
            StopBaronyDefenseMonstersForMapLeave()
        end
        Game.MonstersTxt[soldierMonsterId].Name = soldierMonsterName
    end
    RemoveTimer(MonitorBaronyDefense)
    svars.PrinceThievesBaronyDefenseTimerRunning = nil
    for _, summonTimer in ipairs(baronyCastleGuardSummonTimers) do
        RemoveTimer(summonTimer)
    end
    svars.PrinceThievesBaronyCastleGuardSummonTimersRunning = nil
end

function events.EnterHouse(i)
    if i == P.FrozenHighlandsThroneRoomHouse and vars.PrinceThievesBaronySwapComplete == true then
        ApplyPermanentEndingState()
    end
end

function events.ExitNPC()
    if vars.PrinceThievesDialogStage == "BaronyDefense" then
        vars.PrinceThievesDialogStage = nil
        SummonBaronyCastleGuards()
    end
end

function events.MonsterAttacked(t)
    if not P.IsBaronyDefenseActive() or t.Attacker == nil or t.Attacker.Player == nil then
        return
    end

    if IsBaronyGuard(t.Monster) then
        AlertNearbyBaronyGuards(t.Monster, true, "party_attack")
    end
end
