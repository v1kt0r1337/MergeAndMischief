-- ============================================================================
--  Prince of Thieves, Act 1: Prison Breakout
-- ============================================================================

-- Base data ------------------------------------------------------------------
local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5
local P = PrinceOfThieves

-- Hoisted forward declarations ------------------------------------------------
local StartPrisonEscape
local StartPrisonExitAmbush
local SummonPrisonEscapeMages
local SummonPrisonEscapeGuards
local HasActivePrisonEscapeMages
local MonitorPrinceThievesFrozenHighlands
local FinishPrinceHideoutEscort

local prisonEscapeMageEncounterName = "PrinceThievesPrisonEscapeMages"
local prisonEscapeMageMonsterId = 631 -- Sorcerer
local prisonEscapeMageSpellSourceMonsterId = 292 -- MM6 Sorcerer
local prisonEscapeMageGroup = 72

local function ApplyPrisonEscapeMageMonsterSetup()
    local source = Game.MonstersTxt[prisonEscapeMageSpellSourceMonsterId]
    local target = Game.MonstersTxt[prisonEscapeMageMonsterId]
    target.Name = "Court Mage"
    target.Spell2 = source.Spell
    target.Spell2Skill = source.SpellSkill
    target.Spell2Chance = source.SpellChance
end

ApplyPrisonEscapeMageMonsterSetup()

-- Prison escape encounter setup ----------------------------------------------
local prisonEscapeMagePositions = {
    {13139, -2706, 352},
    {17798, -1930, 224},
    {17291, -5008, 97},
}

local guardMonsterId = 553
local lieutenantMonsterId = 554
local captainMonsterId = 555
local expertSwordsmanMonsterId = 587
local masterSwordsmanMonsterId = 588
local archerMonsterId = 475
local masterArcherMonsterId = 476
local fireArcherMonsterId = 477
local prisonEscapeTroopEncounterName = "PrinceThievesPrisonEscapeTroops"
local prisonEscapeTroopGroup = 74
local guardLieutenantComposition = {
    DefaultMonsterId = guardMonsterId,
    Overrides = {
        {Every = 3, Offset = 2, MonsterId = lieutenantMonsterId},
    },
}
local guardLieutenantCaptainComposition = {
    DefaultMonsterId = guardMonsterId,
    Overrides = {
        {Every = 8, Offset = 7, MonsterId = captainMonsterId},
        {Every = 3, Offset = 2, MonsterId = lieutenantMonsterId},
    },
}
local archerFireComposition = {
    DefaultMonsterId = archerMonsterId,
    Overrides = {
        {Every = 3, Offset = 2, MonsterId = masterArcherMonsterId},
    },
}

local archerFireMasterComposition = {
    DefaultMonsterId = archerMonsterId,
    Overrides = {
        {Every = 8, Offset = 7, MonsterId = masterArcherMonsterId},
        {Every = 3, Offset = 2, MonsterId = fireArcherMonsterId},
    },
}
local swordsmanMasterComposition = {
    DefaultMonsterId = expertSwordsmanMonsterId,
    Overrides = {
        {Every = 3, Offset = 2, MonsterId = masterSwordsmanMonsterId},
    },
}
local prisonEscapeTroops = {
    -- infront of prison
    {
        SummonPos = {X = 12490, Y = -2880, Z = 96},
        Formation = {XAxisCount = 2, YAxisCount = 5, MonsterComposition = guardLieutenantComposition},
    },
    -- north front of prison
    {
        SummonPos = {X = 12823, Y = -2070, Z = 97},
        Formation = {XAxisCount = 3, YAxisCount = 3, MonsterComposition = archerFireMasterComposition},
    },

    -- south front of prison
    {
        SummonPos = {X = 14062, Y = -3722, Z = 96},
        Formation = {XAxisCount = 2, YAxisCount = 3, MonsterComposition = archerFireComposition},
    },
    {
        SummonPos = {X = 13537, Y = -3813, Z = 96},
        Formation = {XAxisCount = 2, YAxisCount = 3, MonsterComposition = swordsmanMasterComposition},
    },

    -- town east exit
    {
        SummonPos = {X = 17530, Y = -2660, Z = 97},
        Formation = {XAxisCount = 3, YAxisCount = 3, MonsterComposition = archerFireMasterComposition},
    },
    {
        SummonPos = {X = 17530, Y = -2280, Z = 224},
        Formation = {XAxisCount = 3, YAxisCount = 3, MonsterComposition = swordsmanMasterComposition},
    },
    -- town east (slightly south) exit
    {
        SummonPos = {X = 17263, Y = -4124, Z = 96},
        Formation = {XAxisCount = 3, YAxisCount = 3, MonsterComposition = swordsmanMasterComposition},
    },
    -- town south east exit
    {
        SummonPos = {X = 16815, Y = -6206, Z = 390},
        Formation = {XAxisCount = 2, YAxisCount = 5, MonsterComposition = guardLieutenantCaptainComposition},
    },
    -- town north east exit
    {
        SummonPos = {X = 17946, Y = -223, Z = 96},
        Formation = {XAxisCount = 2, YAxisCount = 5, MonsterComposition = guardLieutenantCaptainComposition},
    },
}

-- House and NPC helpers -------------------------------------------------------
local function EnsureFrozenHighlandsTimer()
    if svars.PrinceThievesFrozenHighlandsTimerRunning ~= true then
        Timer(MonitorPrinceThievesFrozenHighlands, const.Second)
        svars.PrinceThievesFrozenHighlandsTimerRunning = true
    end
end

local function PlacePrinceInPrison()
    P.ResetNPCDialogState(P.PrinceNPC, A, D)
    Game.NPC[P.PrinceNPC].House = P.PrisonHouse
end

local function PlaceMorganInPrison()
    NPCFollowers.Remove(P.MorganNPC)
    Game.NPC[P.MorganNPC].House = P.PrisonHouse
    vars.PrinceThievesMorganInPrison = true
end

local function RemovePrinceFromPrison()
    if Game.NPC[P.PrinceNPC].House == P.PrisonHouse then
        Game.NPC[P.PrinceNPC].House = 0
    end
end

local function RemoveMorganFromPrison()
    if Game.NPC[P.MorganNPC].House == P.PrisonHouse then
        Game.NPC[P.MorganNPC].House = 0
    end
    vars.PrinceThievesMorganInPrison = nil
end

local function ArrestPrinceAfterPrisonEscapeDeath()
    NPCFollowers.Remove(P.PrinceNPC)
    PlacePrinceInPrison()
    P.TryAddMorganFollower()
    MarkMonsterEncounterForRemoval(prisonEscapeMageEncounterName, P.FrozenHighlands)
    MarkMonsterEncounterForRemoval(prisonEscapeTroopEncounterName, P.FrozenHighlands)
    vars.Quests[P.EscortPrinceQuest] = nil
    vars.PrinceThievesPrisonEscapeStarted = nil
    vars.PrinceThievesPrisonEscapeComplete = nil
    vars.PrinceThievesPrisonExitAmbushStarted = nil
    vars.PrinceThievesDialogStage = nil
    Sleep(const.Hour)
    Message("The Prince of Thieves got arrested, but Morgan found his way back to you.")
end

-- Shared house registration ---------------------------------------------------
RegisterSharedHouseUse {
    Key = "PrinceOfThievesFrozenHighlandsPrison",
    QuestLine = P.QuestLine,
    Map = P.FrozenHighlands,
    House = P.PrisonHouse,
    Event = 501,
    Model = 1,
    Facet = 53,
    Hint = "Prison worthy of a prince",
    RestoreHouseOccupants = true,
    RestoreNPCs = {P.MorganNPC, P.PrinceNPC, P.AnthonyStoneNPC},
    CanEnter = function()
        if vars.PrinceThievesBaronySwapComplete == true then
            return true
        end
        if vars.Quests[P.FreePrinceQuest] ~= "Given" then
            Message("The prison is locked tight.")
            return false
        end
        if not NPCFollowers.NPCInGroup(P.MorganNPC) then
            Message("Morgan and his key is needed to enter this prison.")
            return false
        end
        return true
    end,
    RestoreHouseState = function()
        RestoreGoblinwatchNativeHouseOccupants()
    end,
    Setup = function()
        if vars.Quests[P.StealBaronyQuest] == "Done" then
            Game.NPC[P.PrinceNPC].House = P.PrisonHouse
        elseif vars.PrinceThievesBaronySwapComplete ~= true then
            PlaceMorganInPrison()
            PlacePrinceInPrison()
        end
    end,
    Cleanup = function()
        if vars.Quests[P.StealBaronyQuest] == "Done" then
            -- PrinceNPC is made into Anthony Stone, and vice versa to avoid risk of breaking main quests
            Game.NPC[P.PrinceNPC].House = P.PrisonHouse
        elseif vars.PrinceThievesBaronySwapComplete ~= true and
            vars.Quests[P.EscortPrinceQuest] == "Given" and vars.PrinceThievesPrisonExitAmbushStarted ~= true then
            StartPrisonExitAmbush()
        elseif vars.PrinceThievesBaronySwapComplete ~= true and
            vars.Quests[P.FreePrinceQuest] == "Given" and vars.Quests[P.EscortPrinceQuest] ~= "Given" then
            P.TryAddMorganFollower()
        end
        RemoveMorganFromPrison()
        if vars.Quests[P.StealBaronyQuest] ~= "Done" then
            RemovePrinceFromPrison()
        end
    end,
}

-- Quest stages ----------------------------------------------------------------
Quest{
    P.FreePrinceQuest,
    Slot = E,
    NPC = P.MorganNPC,
    Give = function()
        evt.PlaySound(205) -- quest sound
    end,
    CanShow = function()
        return (P.InFreeHaven() or NPCFollowers.NPCInGroup(P.MorganNPC)) and P.IsOriginalPrinceOfThievesDone() == true and
            vars.PrinceThievesIvanAbductionSeen ~= true
    end,
    CheckDone = function()
        return Game.NPC[P.PrinceNPC].House == P.IvanMagyarHouse
    end,
    Done = function()
        Message("Thank you for helping us free him. His stay here is temporary, for sure.")
        MarkMonsterEncounterForRemoval(prisonEscapeMageEncounterName, P.FrozenHighlands)
        MarkMonsterEncounterForRemoval(prisonEscapeTroopEncounterName, P.FrozenHighlands)
        vars.PrinceThievesIvanAbductionTime = Game.Time
    end,
    Gold = 5000,
    Exp = 15000,
}.SetTexts {
    FirstTopic = "Quest",
    Topic = "Free the Prince of Thieves",
    Give = [[
I need your help. I want to free the Prince of Thieves.

He is located in baron Anthony Stones finest prison. Above the baron's own throne entrance.

I have managed to procure a copy of the key to the door.

I believe my skills with disguises will come in handy and I know the spell jump.

Take me with you.]],
    Undone = [[
The Prince of Thieves is still locked in Anthony Stone's prison.

I got a copy of the key to the prison. I believe my skills with disguises will come in handy and I know the spell jump.

Take me with you, and we will free him.
]],
    Done = false,
    After = "The Prince will stay low here for a while, until he gets his bearings."
}

NPCTopic {
    Slot = D,
    NPC = P.MorganNPC,
    CanShow = function()
        return P.InFreeHaven() and vars.Quests[P.FreePrinceQuest] == "Given" and
            vars.Quests[P.EscortPrinceQuest] ~= "Given" and
            vars.PrinceThievesDeliveredToHideout ~= true and not NPCFollowers.NPCInGroup(P.MorganNPC)
    end,
    Topic = "Join",
    Ungive = function()
        if P.TryAddMorganFollower() then
            ExitCurrentScreen(true)
            Message("Excellent. Lets leave at once.")
        end
    end,
    Text = "Make room for me among your followers and I will come."
}

NPCTopic {
    Slot = D,
    NPC = P.MorganNPC,
    CanShow = function()
        return NPCFollowers.NPCInGroup(P.MorganNPC)
    end,
    Topic = "Jump",
    Ungive = function()
        ExitCurrentScreen(false, true)
        Sleep(const.Minute * 1)
        evt.Jump{Direction = Party.Direction, ZAngle = 384, Speed = 800}
    end,
    Text = "Hold on. This should get us over it."
}

Quest{
    P.EscortPrinceQuest,
    Slot = E,
    NPC = P.PrinceNPC,
    CanShow = function()
        return P.InIvanMagyarHouse() ~= true and vars.Quests[P.FreePrinceQuest] ~= nil and
            vars.Quests[P.EscortPrinceQuest] ~= "Done"
    end,
    Give = function()
        StartPrisonEscape()
    end,
    CheckDone = function()
        return false
    end
}.SetTexts {
    Quest = "Escort the Prince of Thieves to Morgan's hideout",
    Topic = "Escape",
    Give = [[
While this is a fine prison, I'm getting bored.

Help me escape, bring me back to Morgan's base at the Smugglers guild in Free Haven, and I'l lay low there for a while.]],
    Undone = "Morgan's hideout is in north eastern Free Haven, by the Smugglers Guild."
}

NPCTopic {
    Slot = A,
    NPC = P.MorganNPC,
    CanShow = function()
        return P.InPrincePrison() and vars.Quests[P.EscortPrinceQuest] ~= "Given"
    end,
    Topic = "The Prince of Thieves",
    Text = [[Take the Prince of Thieves with you back to my house in Free Haven. The one north east at the Smugglers guild, do you remember?

I will sneak out when the guards start chasing you.]]
}

NPCTopic {
    Slot = B,
    NPC = P.MorganNPC,
    CanShow = function()
        return P.InPrincePrison() and vars.Quests[P.EscortPrinceQuest] == "Given"
    end,
    Topic = "I've disguised you",
    Text = [[
I've disguised you so you won't be recognized by the guards when you exit.

I will stay behind and sneak out when the guards are chasing you.]]
}

Greeting {
    NPC = P.AnthonyStoneNPC,
    CanShow = function()
        return vars.PrinceThievesDialogStage == "PrisonExitAmbush"
    end,
    Text = [[
So. The Prince of Thieves was not satisfied with my finest prison cell.

It matter's not. My mages have anchored this ground. You can not escape!
]]
}

-- Quest runtime helpers -------------------------------------------------------
StartPrisonEscape = function()
    vars.PrinceThievesPrisonEscapeStarted = true
    P.RemoveFriendlyMonstersInRadius(
        P.FrozenHighlandsCastleAmbientRemovalKey,
        P.FrozenHighlandsCastleCenterX, P.FrozenHighlandsCastleCenterY, P.FrozenHighlandsCastleCenterZ,
        P.FrozenHighlandsCastleFriendlyRemovalRadius)
    SummonPrisonEscapeGuards()
    SummonPrisonEscapeMages()
    EnsureFrozenHighlandsTimer()
end

StartPrisonExitAmbush = function()
    vars.PrinceThievesPrisonExitAmbushStarted = true
    vars.PrinceThievesDialogStage = "PrisonExitAmbush"
    RemoveMorganFromPrison()
    if P.TryAddPrinceFollower() then
        Game.NPC[P.PrinceNPC].House = 0
    end
    Party.X = 11620
    Party.Y = -3083
    Party.Z = 449
    Party.Direction = 2028
    Party.LookAngle = -130 --68
    SummonPrisonEscapeGuards()
    SummonPrisonEscapeMages()
    Sleep(10, function() end)
    P.SaveAndClearAnthonyDialogState()
    evt.SpeakNPC{P.AnthonyStoneNPC}
end

SummonPrisonEscapeMages = function()
    if not P.InFrozenHighlands() or vars.PrinceThievesPrisonEscapeComplete == true then
        return
    end

    local encounter = GetMonsterEncounter(prisonEscapeMageEncounterName, P.FrozenHighlands)
    if MonsterEncounterHasAnyActive(encounter) == true then
        return
    elseif encounter ~= nil then
        vars.PrinceThievesPrisonEscapeComplete = true
        return
    end

    local mageIndexes = {}
    for _, position in ipairs(prisonEscapeMagePositions) do
        local mon, monIndex = SummonMonster(prisonEscapeMageMonsterId, position[1], position[2], position[3], true)
        P.ConfigureQuestMonster(mon, true, 0, prisonEscapeMageGroup, {
            Direction = 1028,
            GuardRadius = 256,
            AIState = const.AIState.Stand,
        })
        table.insert(mageIndexes, monIndex)
    end

    CreateAndSetMonsterEncounterFromIndexes(prisonEscapeMageEncounterName, mageIndexes, P.FrozenHighlands)
end

SummonPrisonEscapeGuards = function()
    if not P.InFrozenHighlands() or vars.PrinceThievesPrisonEscapeComplete == true then
        return
    end

    local existingTroopEncounter = GetMonsterEncounter(prisonEscapeTroopEncounterName, P.FrozenHighlands)
    local replacedFireArcherIndexes = P.ReplaceFrozenHighlandsCastleFireArchers(
        fireArcherMonsterId,
        existingTroopEncounter,
        function(mon, _, position)
            P.ConfigureQuestMonster(mon, true, 0, prisonEscapeTroopGroup, {
                Direction = position.Direction,
                GuardRadius = 256,
                AIState = const.AIState.Stand,
            })
        end)
    if existingTroopEncounter ~= nil then
        return
    end

    local _, troopIndexes = MonsterFormation.SummonMany(prisonEscapeTroops, function(mon)
        P.ConfigureQuestMonster(mon, true, 0, prisonEscapeTroopGroup, {
            Direction = 1028,
            GuardRadius = 256,
            AIState = const.AIState.Stand,
        })
    end)

    for _, index in ipairs(replacedFireArcherIndexes) do
        table.insert(troopIndexes, index)
    end

    CreateAndSetMonsterEncounterFromIndexes(prisonEscapeTroopEncounterName, troopIndexes, P.FrozenHighlands)
end

HasActivePrisonEscapeMages = function()
    if not P.InFrozenHighlands() or vars.PrinceThievesPrisonEscapeStarted ~= true or vars.PrinceThievesPrisonEscapeComplete == true then
        return false
    end
    return MonsterEncounterHasAnyActive(GetMonsterEncounter(prisonEscapeMageEncounterName, P.FrozenHighlands)) == true
end

function PrinceOfThievesPrisonEscapeAnchored()
    return HasActivePrisonEscapeMages()
end

MonitorPrinceThievesFrozenHighlands = function()
    if not HasActivePrisonEscapeMages() then
        if vars.PrinceThievesPrisonEscapeStarted == true and vars.PrinceThievesPrisonEscapeComplete ~= true then
            vars.PrinceThievesPrisonEscapeComplete = true
            Sleep(const.Second * 10)
            Game.ShowStatusText("The anchoring magic fades.")
        end
        return
    end

    if P.IsOutsideFrozenHighlandsCastleLeash() then
        Game.ShowStatusText("The anchoring magic pulls you back.")
        Sleep(const.Minute)
        Party.X = P.PrisonEscapeLeashReturnX
        Party.Y = P.PrisonEscapeLeashReturnY
        Party.Z = P.PrisonEscapeLeashReturnZ
    end
end

FinishPrinceHideoutEscort = function()
    if vars.Quests[P.EscortPrinceQuest] ~= "Given" or vars.PrinceThievesDeliveredToHideout == true or
        not NPCFollowers.NPCInGroup(P.PrinceNPC) then
        return
    end

    NPCFollowers.Remove(P.PrinceNPC)

    Game.NPC[P.PrinceNPC].House = P.IvanMagyarHouse
    Game.NPC[P.MorganNPC].House = P.IvanMagyarHouse
    vars.Quests[P.EscortPrinceQuest] = "Done"
    vars.PrinceThievesDeliveredToHideout = true
    P.SetupFreeHavenDisarmTrainers()
    HouseMessage("The Prince of Thieves slips inside Morgan's hideout. For now, he has a place to lie low.")
    Sleep(1)
    RefreshHouseScreen()
end

-- Event listeners -------------------------------------------------------------
function events.AfterLoadMap()
    if P.InFrozenHighlands() then
        if P.ShouldHideFrozenHighlandsCastleAmbientMonsters() then
            P.ReapplyRemovedFriendlyMonsterHiding(P.FrozenHighlandsCastleAmbientRemovalKey)
        else
            P.RestoreRemovedFriendlyMonsters(P.FrozenHighlandsCastleAmbientRemovalKey)
        end
        if vars.Quests[P.EscortPrinceQuest] ~= "Given" then
            RemovePrinceFromPrison()
        end
        if vars.PrinceThievesPrisonEscapeStarted == true and vars.PrinceThievesPrisonEscapeComplete ~= true then
            SummonPrisonEscapeGuards()
            SummonPrisonEscapeMages()
            EnsureFrozenHighlandsTimer()
        end
    end
end

function events.DeathMap()
    if P.InFrozenHighlands() and vars.Quests[P.FreePrinceQuest] == "Given" and
        vars.Quests[P.EscortPrinceQuest] == "Given" then
        ArrestPrinceAfterPrisonEscapeDeath()
    end
end

function events.LeaveMap()
    if P.InFrozenHighlands() then
        RemovePrinceFromPrison()
        RemoveMorganFromPrison()
        P.RestoreAnthonyDialogState()
    end
    RemoveTimer(MonitorPrinceThievesFrozenHighlands)
    svars.PrinceThievesFrozenHighlandsTimerRunning = nil
end

function events.EnterHouse(i)
    if i == P.IvanMagyarHouse then
        FinishPrinceHideoutEscort()
    end
end

function events.ExitNPC()
    if vars.PrinceThievesDialogStage == "PrisonExitAmbush" then
        P.RestoreAnthonyDialogState()
        vars.PrinceThievesDialogStage = nil
    end
end
