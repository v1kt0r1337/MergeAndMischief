-- Shared identities, locations, and behavior used throughout the Prince of Thieves quest line.

PrinceOfThieves = PrinceOfThieves or {}

local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5

local frozenHighlands = "outc1.odm"
local freeHaven = "outc2.odm"
local shadowGuildHideout = "6d03.blv"

local princeThievesNPC_ID = 802
local anthonyStoneNPC_ID = 801
local prisonHouse = 1463

local princeOfThievesQuestLine = "PrinceOfThieves"

local Quest_PrinceOfThieves_FreePrince = "Quest_PrinceOfThieves_FreePrince"
local Quest_PrinceOfThieves_EscortPrince = "Quest_PrinceOfThieves_EscortPrince"
local Quest_PrinceOfThieves_SavePrinceFromIvan = "Quest_PrinceOfThieves_SavePrinceFromIvan"
local Quest_PrinceOfThieves_StealBarony = "Quest_PrinceOfThieves_StealBarony"

local princeOfThievesAward = 60

local sergioCarringtonNPC_ID = 849
local ivanMagyarNPC_ID = 962
local MorganNPC_ID = 651
local ivanMagyarHouse = 1221
local morganDisguiserName = "Morgan the Disguiser"

local disarmExpertTopic = 1569
local gabeLesterTopic = 1601
local smugglerGuildMembershipTopic = 1698

local disarmExpertProfession = 13

local frozenHighlandsCastleCenterX = 14908
local frozenHighlandsCastleCenterY = -2251
local frozenHighlandsCastleCenterZ = 96
local frozenHighlandsCastleLeashRadius = 6000
local prisonEscapeLeashReturnX = 12218
local prisonEscapeLeashReturnY = -3072
local prisonEscapeLeashReturnZ = 96
local frozenHighlandsCastleFriendlyRemovalRadius = 5000
local frozenHighlandsCastleFireArcherRadius = 10000
local frozenHighlandsThroneRoomEvent = 33
local frozenHighlandsThroneRoomHouse = 225
local frozenHighlandsThroneRoomModel = 1
local frozenHighlandsThroneRoomFacet = 59

-- local PrinceOfThievesFriendlyMonsterDebug = true

local frozenHighlandsCastleAmbientRemovalKey = "PrinceThievesFrozenHighlandsCastle"
local legacyBaronyFriendlyRemovalKey = "PrinceThievesBaronyCastle"

local function RandomizeDisguiserPicForEnteredHouse(house)
    local morgan = Game.NPC[MorganNPC_ID]
    if house == morgan.House and morgan.Name == morganDisguiserName then
        -- mm6 none council pics
        Game.NPC[MorganNPC_ID].Pic = math.random(18, 453)
    end
end

local function IsOriginalPrinceOfThievesDone()
    return Party[0].Awards[princeOfThievesAward] == true
end

local function InMap(mapName)
    return Map.Name == mapName
end

local function InFrozenHighlands()
    return InMap(frozenHighlands)
end

local function IsStealBaronyStartedInFrozenHighlands()
    return InFrozenHighlands() and vars.Quests[Quest_PrinceOfThieves_StealBarony] == "Given"
        and vars.PrinceThievesStealBaronyPlanGiven == true
end

local function InFreeHaven()
    return InMap(freeHaven)
end

local function InShadowGuildHideout()
    return InMap(shadowGuildHideout)
end

local function InIvanMagyarHouse()
    return InFreeHaven() and Game.CurrentScreen == const.Screens.House and Game.GetCurrentHouse() == ivanMagyarHouse
end

local function InPrincePrison()
    return IsSharedHouseContext("PrinceOfThievesFrozenHighlandsPrison", frozenHighlands, prisonHouse)
end

local function InFrozenHighlandsThroneRoom()
    return InFrozenHighlands() and Game.CurrentScreen == const.Screens.House and Game.GetCurrentHouse() == frozenHighlandsThroneRoomHouse
end

local function IsBaronyDefenseActive()
    return InFrozenHighlands() and vars.PrinceThievesBaronyDefenseStarted == true
        and vars.PrinceThievesBaronySwapComplete ~= true
end

local function IsPrisonEscapeActive()
    return InFrozenHighlands() and vars.PrinceThievesPrisonEscapeStarted == true
        and vars.PrinceThievesPrisonEscapeComplete ~= true
end

local function ShouldHideFrozenHighlandsCastleAmbientMonsters()
    local baronyAwaitingTurnIn = vars.PrinceThievesBaronySwapComplete == true
        and vars.Quests[Quest_PrinceOfThieves_StealBarony] == "Given"
    return IsPrisonEscapeActive() or IsBaronyDefenseActive() or baronyAwaitingTurnIn
end

local function SafeToInterruptParty()
    return Game.CurrentScreen == 0 and not (Party.EnemyDetectorRed or Party.EnemyDetectorYellow)
end

local function ResetNPCDialogState(npcId, firstSlot, lastSlot)
    firstSlot = firstSlot or A
    lastSlot = lastSlot or F
    for i = firstSlot, lastSlot do
        Game.NPC[npcId].Events[i] = 0
    end
end

local function SaveAndClearAnthonyDialogState()
    if vars.PrinceThievesAnthonyStoneEvents == nil then
        vars.PrinceThievesAnthonyStoneEvents = {}
        for i = A, F do
            vars.PrinceThievesAnthonyStoneEvents[i] = Game.NPC[anthonyStoneNPC_ID].Events[i]
        end
    end
    ResetNPCDialogState(anthonyStoneNPC_ID)
end

local function RestoreAnthonyDialogState()
    local eventsBackup = vars.PrinceThievesAnthonyStoneEvents
    if type(eventsBackup) ~= "table" then
        return
    end
    for i = A, F do
        Game.NPC[anthonyStoneNPC_ID].Events[i] = eventsBackup[i] or 0
    end
    vars.PrinceThievesAnthonyStoneEvents = nil
end

local function TryAddFollower(npcId, fullMessage)
    if NPCFollowers.NPCInGroup(npcId) then
        return true
    end
    if (vars.NPCFollowers and #vars.NPCFollowers or 0) >= 4 or NPCFollowers.GetTotalFee() >= 100 then
        Message(fullMessage or "I cannot join you, you don't have room for another follower")
        return false
    end
    if NPCFollowers.Add(npcId) then
        evt.MoveNPC{npcId, 0}
        evt.PlaySound(205)
        return true
    end
    return false
end

local function TryAddMorganFollower()
    return TryAddFollower(MorganNPC_ID)
end

local function TryAddPrinceFollower()
    return TryAddFollower(princeThievesNPC_ID)
end

local function FriendlyMonsterDebugLog(message, ...)
    if PrinceOfThievesFriendlyMonsterDebug == true then
        print(string.format("[PrinceThievesFriendlyMonsterDebug] " .. message, ...))
    end
end

local function MigrateFrozenHighlandsCastleAmbientRemovalRecord()
    local allRestore = vars.PrinceThievesRemovedFriendlyMonsters
    local legacy = type(allRestore) == "table" and allRestore[legacyBaronyFriendlyRemovalKey] or nil
    if type(legacy) ~= "table" or type(legacy.Monsters) ~= "table" then
        return
    end

    local shared = allRestore[frozenHighlandsCastleAmbientRemovalKey]
    if type(shared) ~= "table" or shared.Map ~= legacy.Map or type(shared.Monsters) ~= "table" then
        allRestore[frozenHighlandsCastleAmbientRemovalKey] = legacy
    else
        for index, monsterRestore in pairs(legacy.Monsters) do
            if shared.Monsters[index] == nil then
                shared.Monsters[index] = monsterRestore
            end
        end
    end
    allRestore[legacyBaronyFriendlyRemovalKey] = nil
end

local function HideFriendlyMonstersForRestore(key, predicate)
    if not InFrozenHighlands() then
        FriendlyMonsterDebugLog("hide skipped | key=%s | reason=wrong_map | map=%s", key, tostring(Map.Name))
        return {}
    end

    vars.PrinceThievesRemovedFriendlyMonsters = vars.PrinceThievesRemovedFriendlyMonsters or {}
    local restore = vars.PrinceThievesRemovedFriendlyMonsters[key]
    if restore == nil then
        restore = {
            Map = Map.Name,
            Monsters = {},
        }
        vars.PrinceThievesRemovedFriendlyMonsters[key] = restore
    elseif restore.Map ~= Map.Name or type(restore.Monsters) ~= "table" then
        FriendlyMonsterDebugLog("hide skipped | key=%s | reason=invalid_restore_record", key)
        return {}
    end

    local positions = {}
    local liveCount = 0
    local friendlyCount = 0
    for i, mon in Map.Monsters do
        local live = mon.HP > 0 and mon.AIState ~= const.AIState.Removed
        local friendly = live and not mon.Hostile
        if live then
            liveCount = liveCount + 1
        end
        if friendly then
            friendlyCount = friendlyCount + 1
        end
        if friendly and predicate(i, mon) then
            local monsterRestore = restore.Monsters[i]
            if monsterRestore == nil then
                monsterRestore = {
                    AIState = mon.AIState,
                    X = mon.X,
                    Y = mon.Y,
                    Z = mon.Z,
                }
                restore.Monsters[i] = monsterRestore
            end
            table.insert(positions, {
                X = monsterRestore.X,
                Y = monsterRestore.Y,
                Z = monsterRestore.Z,
                Direction = mon.Direction,
            })
            -- Invisible reserves the index without exposing the monster to normal map processing.
            mon.AIState = const.AIState.Invisible
            FriendlyMonsterDebugLog(
                "hidden | key=%s | index=%d | id=%d | npc=%s | pos=%d,%d,%d",
                key, i, mon.Id, tostring(mon.NPC_ID), monsterRestore.X, monsterRestore.Y, monsterRestore.Z)
        end
    end
    FriendlyMonsterDebugLog(
        "hide summary | key=%s | live=%d | friendly=%d | hidden=%d",
        key, liveCount, friendlyCount, #positions)
    return positions
end

local function HideFrozenHighlandsCastleFireArchers(fireArcherMonsterId, excludedEncounter)
    local radiusSquared = frozenHighlandsCastleFireArcherRadius * frozenHighlandsCastleFireArcherRadius

    return HideFriendlyMonstersForRestore(frozenHighlandsCastleAmbientRemovalKey, function(_, mon)
        local dx = mon.X - frozenHighlandsCastleCenterX
        local dy = mon.Y - frozenHighlandsCastleCenterY
        local dz = mon.Z - frozenHighlandsCastleCenterZ
        return mon.Id == fireArcherMonsterId and
            MonsterEncounterContainsMonster(excludedEncounter, mon) ~= true and
            dx * dx + dy * dy + dz * dz <= radiusSquared
    end)
end

local function ReplaceFrozenHighlandsCastleFireArchers(fireArcherMonsterId, excludedEncounter, configure)
    local positions = HideFrozenHighlandsCastleFireArchers(fireArcherMonsterId, excludedEncounter)
    local indexes = {}

    if excludedEncounter ~= nil then
        return indexes
    end

    for _, position in ipairs(positions) do
        local mon, index = SummonMonster(fireArcherMonsterId, position.X, position.Y, position.Z, true)
        if configure ~= nil then
            configure(mon, index, position)
        end
        table.insert(indexes, index)
    end
    return indexes
end

local function RemoveFriendlyMonstersInRadius(key, x, y, z, radius)
    if not InFrozenHighlands() then
        return
    end

    local radiusSquared = radius * radius
    HideFriendlyMonstersForRestore(key, function(_, mon)
        local dx, dy, dz = mon.X - x, mon.Y - y, mon.Z - z
        return dx * dx + dy * dy + dz * dz <= radiusSquared
    end)
end

local function ReapplyRemovedFriendlyMonsterHiding(key)
    local allRestore = vars.PrinceThievesRemovedFriendlyMonsters
    local restore = type(allRestore) == "table" and allRestore[key] or nil
    if type(restore) ~= "table" or restore.Map ~= Map.Name or type(restore.Monsters) ~= "table" then
        FriendlyMonsterDebugLog("rehide skipped | key=%s | reason=missing_or_wrong_map", key)
        return
    end

    local hiddenCount = 0
    for index in pairs(restore.Monsters) do
        local mon = Map.Monsters[index]
        if mon ~= nil then
            mon.AIState = const.AIState.Invisible
            hiddenCount = hiddenCount + 1
        end
    end
    FriendlyMonsterDebugLog("rehide summary | key=%s | hidden=%d", key, hiddenCount)
end

local function RestoreRemovedFriendlyMonster(mon, monsterRestore)
    mon.X = monsterRestore.X
    mon.Y = monsterRestore.Y
    mon.Z = monsterRestore.Z
    mon.AIState = monsterRestore.AIState
end

local function RestoreRemovedFriendlyMonstersMatching(key, predicate)
    local allRestore = vars.PrinceThievesRemovedFriendlyMonsters
    local restore = type(allRestore) == "table" and allRestore[key] or nil
    if type(restore) ~= "table" or restore.Map ~= Map.Name or type(restore.Monsters) ~= "table" then
        return
    end

    for index, monsterRestore in pairs(restore.Monsters) do
        local mon = Map.Monsters[index]
        if mon ~= nil and predicate(index, mon) then
            RestoreRemovedFriendlyMonster(mon, monsterRestore)
            restore.Monsters[index] = nil
            FriendlyMonsterDebugLog(
                "restored matching | key=%s | index=%d | id=%d | state=%d | pos=%d,%d,%d",
                key, index, mon.Id, monsterRestore.AIState,
                monsterRestore.X, monsterRestore.Y, monsterRestore.Z)
        end
    end
end

local function RestoreRemovedFriendlyMonsters(key)
    local allRestore = vars.PrinceThievesRemovedFriendlyMonsters
    local restore = type(allRestore) == "table" and allRestore[key] or nil
    if type(restore) ~= "table" or restore.Map ~= Map.Name or type(restore.Monsters) ~= "table" then
        FriendlyMonsterDebugLog("restore skipped | key=%s | reason=missing_or_wrong_map", key)
        return
    end

    local restoredAll = true
    local restoredCount = 0
    for index, monsterRestore in pairs(restore.Monsters) do
        local mon = Map.Monsters[index]
        if mon ~= nil then
            RestoreRemovedFriendlyMonster(mon, monsterRestore)
            restoredCount = restoredCount + 1
            FriendlyMonsterDebugLog(
                "restored | key=%s | index=%d | id=%d | npc=%s | state=%d | pos=%d,%d,%d",
                key, index, mon.Id, tostring(mon.NPC_ID), monsterRestore.AIState,
                monsterRestore.X, monsterRestore.Y, monsterRestore.Z)
        else
            restoredAll = false
            FriendlyMonsterDebugLog("restore missing monster | key=%s | index=%d", key, index)
        end
    end

    if restoredAll then
        allRestore[key] = nil
    end
    FriendlyMonsterDebugLog(
        "restore summary | key=%s | restored=%d | complete=%s",
        key, restoredCount, tostring(restoredAll))
end

local function IsOutsideFrozenHighlandsCastleLeash()
    local dx = Party.X - frozenHighlandsCastleCenterX
    local dy = Party.Y - frozenHighlandsCastleCenterY
    local dz = Party.Z - frozenHighlandsCastleCenterZ
    return dx * dx + dy * dy + dz * dz > frozenHighlandsCastleLeashRadius * frozenHighlandsCastleLeashRadius
end

local function SetupFreeHavenDisarmTrainers()
    if vars.PrinceThievesPrinceRescuedFromIvan == true and vars.PrinceThievesIvanRescueTurnedIn ~= true and
        vars.Quests[Quest_PrinceOfThieves_SavePrinceFromIvan] == "Done" then
        vars.Quests[Quest_PrinceOfThieves_SavePrinceFromIvan] = "Given"
    end

    local abductionActive = vars.Quests[Quest_PrinceOfThieves_SavePrinceFromIvan] == "Given" and
        vars.PrinceThievesPrinceRescuedFromIvan ~= true
    local endingComplete = vars.PrinceThievesBaronySwapComplete == true

    if endingComplete and PrinceOfThieves.ApplyPermanentEndingState then
        PrinceOfThieves.ApplyPermanentEndingState()
    elseif vars.PrinceThievesMorganInPrison ~= true and not NPCFollowers.NPCInGroup(MorganNPC_ID) then
        Game.NPC[MorganNPC_ID].House = ivanMagyarHouse
    end
    if abductionActive or vars.PrinceThievesIvanDead == true then
        Game.NPC[ivanMagyarNPC_ID].House = 0
    end
    if abductionActive then
        Game.NPC[princeThievesNPC_ID].House = 0
    elseif vars.PrinceThievesPrinceRescuedFromIvan == true and not endingComplete then
        Game.NPC[princeThievesNPC_ID].House = ivanMagyarHouse
    end
    Game.NPC[MorganNPC_ID].Name = morganDisguiserName
    -- Pic 44, looks a bit scetchy, scetchy combo with 68 and 74


    local sergio = Game.NPC[sergioCarringtonNPC_ID]
    sergio.Profession = disarmExpertProfession
    sergio.EventA = disarmExpertTopic
    sergio.EventB = gabeLesterTopic
    sergio.EventC = smugglerGuildMembershipTopic
    sergio.EventD = 0
    sergio.EventE = 0
    sergio.EventF = 0

    local ivan = Game.NPC[ivanMagyarNPC_ID]
    ivan.Profession = 0
    ivan.EventA = 0
    ivan.EventB = 0
    ivan.EventC = 0
    ivan.EventD = 0
    ivan.EventE = 0
    ivan.EventF = 0
    ivan.Name = "Ivan Magyar the Burglar"

    NPCTopic {
        Slot = A,
        NPC = ivanMagyarNPC_ID,
        CanShow = function()
            return InIvanMagyarHouse() and vars.PrinceThievesDeliveredToHideout ~= true
        end,
        Topic = "The Prince of Thieves",
        Text = IsOriginalPrinceOfThievesDone() and [[That rascal owes me money, but got himself captured by the baron, Anthony Stone!

I know Morgan is plotting something.

I will have my money one way or the other!]] or
            "I don't know where that rascal hides. He owes me money. If I knew where he hid I'd find him myself!"
    }

    NPCTopic {
        Slot = A,
        NPC = ivanMagyarNPC_ID,
        CanShow = function()
            return InIvanMagyarHouse() and vars.PrinceThievesDeliveredToHideout == true and
                vars.PrinceThievesIvanAbductionSeen ~= true
        end,
        Topic = "The Prince of Thieves",
        Text = "That bugger still owes me money"
    }

    NPCTopic {
        Slot = B,
        NPC = ivanMagyarNPC_ID,
        CanShow = function()
            return InIvanMagyarHouse() and vars.PrinceThievesIvanAbductionSeen ~= true
        end,
        Topic = "Morgan",
        Text = [[
Morgan loves disguises. I believe a mix of magical skill and natural talent is at work.

I've nearly beaten Morgan senseless on more than one occasion, mistaking the scoundrel for a rival burglar or some other rogue.

And the talent isn't limited to personal disguises. Morgan has provided me with disguises for many... ah... professional endeavors.]]
    }

    NPCTopic {
        Slot = B,
        NPC = MorganNPC_ID,
        CanShow = function()
            return InIvanMagyarHouse() and vars.PrinceThievesBaronySwapComplete ~= true
        end,
        Topic = "Disguise",
        Text = "When it comes to disguises, I've yet to meet my equal."
    }

    NPCTopic {
        Slot = A,
        NPC = MorganNPC_ID,
        CanShow = function()
            return InIvanMagyarHouse() and vars.PrinceThievesPrinceDead == true
        end,
        Topic = "The Prince of Thieves is dead",
        Text = "The Prince of Thieves is dead. There is nothing more we can do."
    }

    NPCTopic {
        Slot = A,
        CanShow = function ()
            return InIvanMagyarHouse() and IsOriginalPrinceOfThievesDone() ~= true and vars.PrinceThievesDeliveredToHideout ~= true
        end,
        NPC = MorganNPC_ID,
        Topic = "The Prince of Thieves",
        Text = [[
Ah yes, the Prince of Thieves.

Ivan Magyar has a score to settle with him.

Last I heard, he went into hiding up north.

[Morgan winks]

At least, that's what people are meant to believe.

He crossed the wrong people this time. Far more powerful than Ivan.

Still, he has a habit of overcoming bad odds and coming out further ahead than any man ought to.]]
    }

    NPCTopic {
        Slot = A,
        NPC = MorganNPC_ID,
        CanShow = function()
            return InIvanMagyarHouse() and vars.PrinceThievesDeliveredToHideout == true and
                vars.PrinceThievesIvanAbductionSeen ~= true and vars.PrinceThievesBaronySwapComplete ~= true
        end,
        Topic = "The Prince of Thieves",
        Text = "He will stay low here for a while, until he gets his bearings"
    }

    NPCTopic {
        Slot = A,
        NPC = princeThievesNPC_ID,
        CanShow = function()
            return InIvanMagyarHouse() and vars.PrinceThievesDeliveredToHideout == true and
                vars.PrinceThievesPrinceRescuedFromIvan ~= true and
                Game.NPC[princeThievesNPC_ID].House == ivanMagyarHouse
        end,
        Topic = "The Prince of Thieves",
        Text = [[
Yes the Prince of Thieves thats me.

Had a run-in with some cultist and things went downhill from there.

But I have a feeling life will soon start smiling back at me]]
    }

    NPCTopic {
        Slot = A,
        NPC = princeThievesNPC_ID,
        CanShow = function()
            return InIvanMagyarHouse() and vars.Quests[Quest_PrinceOfThieves_FreePrince] == "Given"
        end,
        Topic = "Speak with Morgan",
        Text = "Speak with Morgan. He will reward you for the rescue."
    }

    NPCTopic {
        Slot = A,
        NPC = princeThievesNPC_ID,
        CanShow = function()
            return InIvanMagyarHouse() and vars.PrinceThievesPrinceRescuedFromIvan == true and
                vars.Quests[Quest_PrinceOfThieves_SavePrinceFromIvan] == "Given"
        end,
        Topic = "Speak with Morgan",
        Text = "Speak with Morgan. He will see that our business with Ivan is properly concluded."
    }
end

local function ApplyFrozenHighlandsThroneRoomDoorSetup()
    if not InFrozenHighlands() then
        return
    end

    Game.MapEvtLines:RemoveEvent(frozenHighlandsThroneRoomEvent)

    local model = Map.Models and Map.Models[frozenHighlandsThroneRoomModel] or nil
    local facet = model and model.Facets and model.Facets[frozenHighlandsThroneRoomFacet] or nil
    if facet ~= nil then
        facet.Event = frozenHighlandsThroneRoomEvent
        facet.TriggerByClick = true
    end

    evt.house[frozenHighlandsThroneRoomEvent] = frozenHighlandsThroneRoomHouse
    evt.map[frozenHighlandsThroneRoomEvent] = function()
        if vars.PrinceThievesPrisonEscapeStarted == true and vars.Quests[Quest_PrinceOfThieves_FreePrince] ~= "Done" then
            Message("The throne room is closed during time of strife")
            return
        end
        if IsBaronyDefenseActive() then
            Message("The throne room doors are barred while the guards defend the hall.")
            return
        end

        evt.EnterHouse{frozenHighlandsThroneRoomHouse}
    end
end

PrinceOfThieves.FrozenHighlands = frozenHighlands
PrinceOfThieves.ShadowGuildHideout = shadowGuildHideout
PrinceOfThieves.PrinceNPC = princeThievesNPC_ID
PrinceOfThieves.AnthonyStoneNPC = anthonyStoneNPC_ID
PrinceOfThieves.MorganNPC = MorganNPC_ID
PrinceOfThieves.IvanMagyarNPC = ivanMagyarNPC_ID
PrinceOfThieves.PrisonHouse = prisonHouse
PrinceOfThieves.IvanMagyarHouse = ivanMagyarHouse
PrinceOfThieves.FrozenHighlandsThroneRoomHouse = frozenHighlandsThroneRoomHouse
PrinceOfThieves.QuestLine = princeOfThievesQuestLine
PrinceOfThieves.FreePrinceQuest = Quest_PrinceOfThieves_FreePrince
PrinceOfThieves.EscortPrinceQuest = Quest_PrinceOfThieves_EscortPrince
PrinceOfThieves.SavePrinceFromIvanQuest = Quest_PrinceOfThieves_SavePrinceFromIvan
PrinceOfThieves.StealBaronyQuest = Quest_PrinceOfThieves_StealBarony
PrinceOfThieves.FrozenHighlandsCastleAmbientRemovalKey = frozenHighlandsCastleAmbientRemovalKey
PrinceOfThieves.FrozenHighlandsCastleCenterX = frozenHighlandsCastleCenterX
PrinceOfThieves.FrozenHighlandsCastleCenterY = frozenHighlandsCastleCenterY
PrinceOfThieves.FrozenHighlandsCastleCenterZ = frozenHighlandsCastleCenterZ
PrinceOfThieves.FrozenHighlandsCastleLeashRadius = frozenHighlandsCastleLeashRadius
PrinceOfThieves.PrisonEscapeLeashReturnX = prisonEscapeLeashReturnX
PrinceOfThieves.PrisonEscapeLeashReturnY = prisonEscapeLeashReturnY
PrinceOfThieves.PrisonEscapeLeashReturnZ = prisonEscapeLeashReturnZ
PrinceOfThieves.FrozenHighlandsCastleFriendlyRemovalRadius = frozenHighlandsCastleFriendlyRemovalRadius
PrinceOfThieves.FrozenHighlandsCastleFireArcherRadius = frozenHighlandsCastleFireArcherRadius
PrinceOfThieves.IsOriginalPrinceOfThievesDone = IsOriginalPrinceOfThievesDone
PrinceOfThieves.InFrozenHighlands = InFrozenHighlands
PrinceOfThieves.IsStealBaronyStartedInFrozenHighlands = IsStealBaronyStartedInFrozenHighlands
PrinceOfThieves.InFreeHaven = InFreeHaven
PrinceOfThieves.InShadowGuildHideout = InShadowGuildHideout
PrinceOfThieves.InIvanMagyarHouse = InIvanMagyarHouse
PrinceOfThieves.InPrincePrison = InPrincePrison
PrinceOfThieves.InFrozenHighlandsThroneRoom = InFrozenHighlandsThroneRoom
PrinceOfThieves.IsBaronyDefenseActive = IsBaronyDefenseActive
PrinceOfThieves.IsPrisonEscapeActive = IsPrisonEscapeActive
PrinceOfThieves.ShouldHideFrozenHighlandsCastleAmbientMonsters = ShouldHideFrozenHighlandsCastleAmbientMonsters
PrinceOfThieves.SafeToInterruptParty = SafeToInterruptParty
PrinceOfThieves.ResetNPCDialogState = ResetNPCDialogState
PrinceOfThieves.SaveAndClearAnthonyDialogState = SaveAndClearAnthonyDialogState
PrinceOfThieves.RestoreAnthonyDialogState = RestoreAnthonyDialogState
PrinceOfThieves.TryAddMorganFollower = TryAddMorganFollower
PrinceOfThieves.TryAddPrinceFollower = TryAddPrinceFollower
PrinceOfThieves.ConfigureQuestMonster = ConfigureQuestMonster
PrinceOfThieves.HideFriendlyMonstersForRestore = HideFriendlyMonstersForRestore
PrinceOfThieves.ReplaceFrozenHighlandsCastleFireArchers = ReplaceFrozenHighlandsCastleFireArchers
PrinceOfThieves.RemoveFriendlyMonstersInRadius = RemoveFriendlyMonstersInRadius
PrinceOfThieves.ReapplyRemovedFriendlyMonsterHiding = ReapplyRemovedFriendlyMonsterHiding
PrinceOfThieves.RestoreRemovedFriendlyMonstersMatching = RestoreRemovedFriendlyMonstersMatching
PrinceOfThieves.RestoreRemovedFriendlyMonsters = RestoreRemovedFriendlyMonsters
PrinceOfThieves.IsOutsideFrozenHighlandsCastleLeash = IsOutsideFrozenHighlandsCastleLeash
PrinceOfThieves.SetupFreeHavenDisarmTrainers = SetupFreeHavenDisarmTrainers

function events.AfterLoadMap()
    MigrateFrozenHighlandsCastleAmbientRemovalRecord()
    if NPCFollowers.NPCInGroup(MorganNPC_ID) then
        Game.NPC[MorganNPC_ID].Name = morganDisguiserName
    end
    if InFreeHaven() then
        SetupFreeHavenDisarmTrainers()
    end
end

function events.EnterHouse(i)
    RandomizeDisguiserPicForEnteredHouse(i)
end

function events.LoadMapScripts()
    ApplyFrozenHighlandsThroneRoomDoorSetup()
end
