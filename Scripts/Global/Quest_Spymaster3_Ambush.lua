-- ============================================================================
--  Spymaster: Ambush
-- ============================================================================

-- Base data ------------------------------------------------------------------
local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5
local S = Spymaster

-- Monster IDs ----------------------------------------------------------------
local devilSpawnMonsterId = 502
local devilWorkerMonsterId = 503
local devilWarriorMonsterId = 504
local ambushCaptainMonsterId = 555
local ambushArcherMonsterId = 475
local ambushMasterMonkMonsterId = 583

-- Ambush setup ---------------------------------------------------------------
local khorTarrAmbushGroup = 60
local ambusherGroup = 61
local ambushX = -6486
local ambushY = -20318
local ambushZ = 225
local ambushPaddingX = 3000
local ambushPaddingY = 3000
local ambushPaddingZ = 400

local ApplySpymasterAmbushSetup
local ApplyResolvedAmbushSide
local StartKhorTarrEscort
local StartSpymasterAmbush
local ResolveSpymasterAmbush
local TriggerSpymasterFollowupDialog
local ApplySpymasterAmbushFactionHostility
local ActivateSpymasterAmbushActors
local SetAmbushMonsterHostile
local SetKhorTarrMonsterHostile
local MarkSpymasterAmbushEncountersForRemoval
local KillKhorTarrSideSummons
local SummonSpymasterAmbushEncounter
local SummonKhorTarrReinforcements
local IsAmbushHumanMonster
local IsKhorTarrSideMonster
local IsKhorTarrMonster
local IsFriendlySpymasterAmbushMonster
local HasActiveSpymasterAmbushActors
local RemoveSpymasterAmbushActorMonsters
local FinishKhorTarrHideoutEscort
local CompleteKhorTarrFollowup
local CompleteAmbusherFollowup
local MonitorSpymasterStoryProgress
local MonitorSpymasterAmbushThresholds

-- Helpers --------------------------------------------------------------------
local function IsAmbushGiven()
    return vars.Quests[S.AmbushQuest] == "Given"
end

local function IsAmbushDone()
    return vars.Quests[S.AmbushQuest] == "Done"
end

local function IsHideKhorTarrGiven()
    return vars.Quests[S.HideKhorTarrQuest] == "Given"
end

local function IsHideKhorTarrDone()
    return vars.Quests[S.HideKhorTarrQuest] == "Done"
end

local function IsAmbushStarted()
    return vars.SpymasterAmbushStarted == true
end

local function IsDialogStage(stage)
    return vars.SpymasterDialogStage == stage
end

local function HasNoDialogStage()
    return vars.SpymasterDialogStage == nil
end

local function InSpymasterAmbushArea()
    return S.InKriegspire() and math.abs(Party.X - ambushX) <= ambushPaddingX and math.abs(Party.Y - ambushY) <= ambushPaddingY and
               math.abs(Party.Z - ambushZ) <= ambushPaddingZ
end

local function EndSpymasterAmbushQuestline(message)
    vars.SpymasterKhorTarrFollowupPending = nil
    vars.SpymasterAmbusherFollowupPending = nil
    vars.SpymasterDialogStage = nil
    vars.Quests[S.AmbushQuest] = "Done"
    MarkSpymasterAmbushEncountersForRemoval()
    evt.PlaySound(142) -- fail sound
    Message(message)
end

-- Ambush helpers -------------------------------------------------------------
IsAmbushHumanMonster = function(mon)
    return MonsterEncounterContainsMonster(GetMonsterEncounter(S.AmbushHumanEncounterName, S.Kriegspire), mon)
end

IsKhorTarrSideMonster = function(mon)
    return MonsterEncounterContainsMonster(GetMonsterEncounter(S.AmbushKhorTarrEncounterName, S.Kriegspire), mon)
end

IsKhorTarrMonster = function(mon)
    return mon.Id == S.KhorTarrMonster and IsKhorTarrSideMonster(mon)
end

IsFriendlySpymasterAmbushMonster = function(mon)
    if not S.InKriegspire() or not IsAmbushStarted() or vars.SpymasterAmbushSide == nil or mon == nil then
        return false
    end

    if vars.SpymasterAmbushSide == "KhorTarr" then
        return IsKhorTarrSideMonster(mon)
    elseif vars.SpymasterAmbushSide == "Ambushers" then
        return IsAmbushHumanMonster(mon)
    end

    return false
end

ApplySpymasterAmbushSetup = function(resetPowerHP)
    S.CreateAmbushContactNPC()
    Game.MonstersTxt[S.KhorTarrMonster].Name = Game.NPC[S.CarterNPC].Name
    Game.MonstersTxt[ambushMasterMonkMonsterId].Name = Game.NPC[S.AmbushContactNPC].Name

    local encounters = {
        {
            name = S.AmbushKhorTarrEncounterName,
            setup = function(mon)
                if mon.Id == S.KhorTarrMonster then
                    S.CreateKhorTarrMonster(mon, resetPowerHP == true)
                end
                if resetPowerHP == true then
                    S.ConfigureQuestMonster(mon, false, 9999, khorTarrAmbushGroup)
                else
                    S.ConfigureQuestMonster(mon, mon.Hostile, mon.Ally, khorTarrAmbushGroup)
                end
            end
        },
        {
            name = S.AmbushHumanEncounterName,
            setup = function(mon)
                if mon.Id == ambushMasterMonkMonsterId then
                    local ambushPowerMonsterId = 585 -- Master monk
                    local ambushContactPowerMonster = Game.MonstersTxt[ambushPowerMonsterId]
                    Game.MonstersTxt[ambushMasterMonkMonsterId].Name = Game.NPC[S.AmbushContactNPC].Name
                    ApplyMonsterPowerFromMonster(mon, ambushContactPowerMonster, resetPowerHP, 6)
                elseif mon.Id == ambushArcherMonsterId then
                    S.ApplyVeteranArcher(mon, resetPowerHP)
                elseif mon.Id == ambushCaptainMonsterId then
                    local minotaurID = 580
                    local minotaurPowerMonster = Game.MonstersTxt[minotaurID]
                    ApplyMonsterPowerFromMonster(mon, minotaurPowerMonster, resetPowerHP)
                end
                if resetPowerHP == true then
                    S.ConfigureQuestMonster(mon, false, 9999, ambusherGroup)
                else
                    S.ConfigureQuestMonster(mon, mon.Hostile, mon.Ally, ambusherGroup)
                end
            end
        }
    }

    for _, encounterData in ipairs(encounters) do
        ForEachMonsterEncounter(GetMonsterEncounter(encounterData.name, S.Kriegspire), function(_, mon)
            if mon.HP > 0 then
                encounterData.setup(mon)
            end
        end)
    end
end

RemoveSpymasterAmbushActorMonsters = function(removeKhorTarr, removeAmbushContact)
    for _, mon in Map.Monsters do
        if (removeKhorTarr and IsKhorTarrSideMonster(mon)) or (removeAmbushContact and IsAmbushHumanMonster(mon) and mon.Id == ambushMasterMonkMonsterId) then
            mon.AIState = const.AIState.Removed
        end
    end
end

HasActiveSpymasterAmbushActors = function()
    local khorTarrEncounter = GetMonsterEncounter(S.AmbushKhorTarrEncounterName, S.Kriegspire)
    local humanEncounter = GetMonsterEncounter(S.AmbushHumanEncounterName, S.Kriegspire)
    if not khorTarrEncounter and not humanEncounter then
        return false
    end

    return MonsterEncounterHasAnyActive(khorTarrEncounter) == true or MonsterEncounterHasAnyActive(humanEncounter) == true
end


-- Hideout escort -------------------------------------------------------------
FinishKhorTarrHideoutEscort = function()
    local khorTarrTravelingWithParty = NPCFollowers.NPCInGroup(S.CarterNPC)

    if not IsHideKhorTarrGiven() or vars.SpymasterKhorTarrHidden == true or not khorTarrTravelingWithParty then
        return
    end

    NPCFollowers.Remove(S.CarterNPC)
    evt.MoveNPC{S.CarterNPC, S.KhorTarrHideoutHouse}
    vars.SpymasterKhorTarrHidden = true
    S.CreateCarterNPCAfterReveal()
    HouseMessage("Khor-Tarr slips inside without another word. It seems he intends to lie low here for a while.")
    -- House/NPC state does not refresh reliably in one step here.
    -- Small delay + reload + refresh gives the most stable result.
    Sleep(1, function() end)
    ReloadHouse(S.KhorTarrHideoutHouse)
    RefreshHouseScreen()
end

-- Quest stages ----------------------------------------------------------------
-- Part 3: Reveal Carter as Khor-Tarr -----------------------------------------

Greeting {
    NPC = S.AmbushContactNPC,
    CanShow = function()
        return S.InKriegspire() and IsDialogStage("Reveal")
    end,
    Text = [[At last I've caught up to you!

The damage you have done have endangered the entire continent.

You thwarted the Superior Temple of Baa extermination force, and killed one of the finest military commanders we had left.

Now the question. Were you misled, or are you in collusion with the Kreegans?
]]
}

NPCTopic {
    Slot = A,
    NPC = S.AmbushContactNPC,
    CanShow = function()
        return S.InKriegspire() and IsDialogStage("Reveal")
    end,
    Topic = "The Kreegans?",
    Ungive = function()
        S.CreateCarterNPCAfterReveal()
        vars.SpymasterRevealSeen = true
        vars.SpymasterDialogStage = nil
        vars.Quests[S.AmbushQuest] = "Given"
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
NPCTopic {
    Slot = B,
    NPC = S.CarterNPC,
    CanShow = function()
        return S.InBlackshire() and IsAmbushGiven() and not IsAmbushStarted() and vars.SpymasterEscortIntent ~= "Tricked"
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
}

NPCTopic {
    Slot = C,
    NPC = S.CarterNPC,
    CanShow = function()
        return S.InBlackshire() and IsAmbushGiven() and not IsAmbushStarted() and vars.SpymasterEscortIntent ~= "Warned"
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
}

NPCTopic {
    Slot = D,
    NPC = S.CarterNPC,
    CanShow = function()
        return S.InBlackshire() and IsAmbushGiven() and vars.SpymasterEscortIntent ~= nil and
                   not IsAmbushStarted() and not NPCFollowers.NPCInGroup(S.CarterNPC)
    end,
    Topic = "Join",
    Ungive = function()
        if S.TryAddKhorTarrFollower() then
            RefreshHouseScreen()
            Message("Excellent. Lets leave at once.")
        end
    end,
    Text = "Make room for me among your followers and I will come."
}

-- Part 5: Ambush choice and resolution ---------------------------------------
Greeting {
    NPC = S.AmbushContactNPC,
    CanShow = function()
        return S.InKriegspire() and IsDialogStage("AmbushChoice")
    end,
    Text = "You brought him. Now lets end that foul demon!"
}

Greeting {
    NPC = S.AmbushContactNPC,
    CanShow = function()
        return S.InKriegspire() and IsDialogStage("AmbusherFollowup")
    end,
    Text = [[
Khor-Tarr is dead.

You have repaid some of your debt.

However I don't have more work for you now.]]
}

NPCTopic {
    Slot = A,
    NPC = S.AmbushContactNPC,
    CanShow = function()
        return S.InKriegspire() and IsDialogStage("AmbushChoice")
    end,
    Topic = "Help Khor-Tarr",
    Ungive = function()
        ResolveSpymasterAmbush("KhorTarr")
        ExitCurrentScreen()
        evt.PlaySound(160) -- encounter for ambush
    end,
    Text = "Then stand and die with him traitor!"
}

NPCTopic {
    Slot = B,
    NPC = S.AmbushContactNPC,
    CanShow = function()
        return S.InKriegspire() and IsDialogStage("AmbushChoice")
    end,
    Topic = "Help ambushers",
    Ungive = function()
        ResolveSpymasterAmbush("Ambushers")
        ExitCurrentScreen()
        evt.PlaySound(160) -- encounter for ambush
    end,
    Text = "Wise enough at last. Khor-Tarr dies here."
}

NPCTopic {
    Slot = A,
    NPC = S.AmbushContactNPC,
    CanShow = function()
        return S.InKriegspire() and IsDialogStage("AmbusherFollowup")
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

-- Part 6A: Hide Khor-Tarr after siding with him -------------------------------
NPCTopic {
    Slot = A,
    NPC = S.CarterNPC,
    CanShow = function()
        return S.InKriegspire() and IsDialogStage("KhorTarrFollowup")
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
}

Quest{
    S.HideKhorTarrQuest,
    Slot = E,
    NPC = S.CarterNPC,
    CanShow = function()
        return (IsHideKhorTarrGiven() and vars.SpymasterKhorTarrHidden ~= true and NPCFollowers.NPCInGroup(S.CarterNPC)) or
                   (S.InBlackshire() and IsHideKhorTarrGiven() and vars.SpymasterKhorTarrHidden ~= true) or
                   (S.InKriegspire() and IsHideKhorTarrGiven() and vars.SpymasterKhorTarrHidden == true)
    end,
    CheckDone = function()
        return vars.SpymasterKhorTarrHidden == true
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
}

NPCTopic {
    Slot = A,
    NPC = S.CarterNPC,
    CanShow = function()
        return S.InBlackshire() and IsHideKhorTarrGiven() and not NPCFollowers.NPCInGroup(S.CarterNPC) and
                   vars.SpymasterKhorTarrHidden ~= true
    end,
    Topic = "Join",
    Ungive = function()
        if S.TryAddKhorTarrFollower() then
            RefreshHouseScreen()
        else
            S.ReturnKhorTarrToHouse()
        end
    end,
    Text = "Make room for me among your followers. The road to Kriegspire will not wait forever."
}

NPCTopic {
    Slot = A,
    NPC = S.DroppaMaPantzNPC,
    CanShow = function()
        return S.InKriegspire() and Game.NPC[S.CarterNPC].House == S.KhorTarrHideoutHouse
    end,
    Topic = "Carter",
    Text = [[
Yes, yes, Carter!

He is a follower of Baa, just like me.

But that is a secret. A secret!

SSHHH!]]
}

NPCTopic {
    Slot = A,
    NPC = S.CarterNPC,
    CanShow = function()
        return S.InKriegspire() and IsHideKhorTarrDone() and Game.NPC[S.CarterNPC].House == S.KhorTarrHideoutHouse
    end,
    Topic = "Staying low",
    Text = [[
I will remain here a while longer.

That fool is driving me mad. The simpleton believes I am merely a follower of Baa.

I am tempted to show him the true extent of my power. Perhaps that would silence him for a while.]]
}

NPCTopic {
    Slot = A,
    NPC = S.AmbushContactNPC,
    CanShow = function()
        return S.InFreehaven() and vars.SpymasterAmbushKhorTarrDead == true and vars.SpymasterAmbushCorvinDead ~= true and
                   Game.NPC[S.AmbushContactNPC].House == S.FreeHavenCorvinHouse
    end,
    Topic = "Khor-Tarr",
    Text = [[
Thank you for helping us bring him down. His days as an infiltrator are over.

I believe his manipulations was instrumental in founding the followers of Baa. However, that cult has grown beyond his influence and will not be undone by his death alone.

I have no further tasks for you at present. Continue the fight against the Kreegans, and remain vigilant against their deceptions.
]]
}

-- Quest runtime helpers -------------------------------------------------------
CompleteAmbusherFollowup = function()
    vars.SpymasterDialogStage = nil
    vars.Quests[S.AmbushQuest] = "Done"
    vars.SpymasterAmbusherFollowupSeen = true
end

CompleteKhorTarrFollowup = function()
    vars.SpymasterDialogStage = nil
    vars.Quests[S.AmbushQuest] = "Done"
    vars.Quests[S.HideKhorTarrQuest] = "Given"
    vars.SpymasterKhorTarrFollowupSeen = true
    Game.NPC[S.CarterNPC].House = S.BlackShireHouse
    if S.TryAddKhorTarrFollower() ~= true then
        S.ReturnKhorTarrToHouse()
    end
end

StartKhorTarrEscort = function(intent)
    vars.SpymasterEscortIntent = intent
end

-- Ambush encounter -----------------------------------------------------------
SummonSpymasterAmbushEncounter = function(showDialog)
    local khorTarrMapMonIndexes = {}
    local humanMapMonIndexes = {}

    local _, khorTarrIndex = SummonMonster(S.KhorTarrMonster, Party.X + 150, Party.Y + 150, Party.Z, true)
    table.insert(khorTarrMapMonIndexes, khorTarrIndex)
    vars.SpymasterAmbushKhorTarrSummoned = true

    local meleeFormation = {
        {ambushCaptainMonsterId, ambushX + 0, ambushY - 40, ambushZ},
        {ambushCaptainMonsterId, ambushX - 90, ambushY - 130, ambushZ},
        {ambushCaptainMonsterId, ambushX + 90, ambushY - 130, ambushZ},
        {ambushCaptainMonsterId, ambushX - 170, ambushY - 220, ambushZ},
        {ambushCaptainMonsterId, ambushX - 60, ambushY - 250, ambushZ},
        {ambushCaptainMonsterId, ambushX + 60, ambushY - 250, ambushZ},
        {ambushCaptainMonsterId, ambushX + 170, ambushY - 220, ambushZ},
        {ambushCaptainMonsterId, ambushX - 260, ambushY - 340, ambushZ},
        {ambushCaptainMonsterId, ambushX - 170, ambushY - 390, ambushZ},
        {ambushCaptainMonsterId, ambushX - 85, ambushY - 425, ambushZ},
        {ambushCaptainMonsterId, ambushX + 0, ambushY - 445, ambushZ},
        {ambushCaptainMonsterId, ambushX + 85, ambushY - 425, ambushZ},
        {ambushCaptainMonsterId, ambushX + 170, ambushY - 390, ambushZ},
        {ambushCaptainMonsterId, ambushX + 260, ambushY - 340, ambushZ},
    }

    local archerFormation = {
        {ambushArcherMonsterId, ambushX - 140, ambushY - 420, ambushZ},
        {ambushArcherMonsterId, ambushX - 45, ambushY - 455, ambushZ},
        {ambushArcherMonsterId, ambushX + 45, ambushY - 455, ambushZ},
        {ambushArcherMonsterId, ambushX + 140, ambushY - 420, ambushZ},
        {ambushArcherMonsterId, ambushX - 220, ambushY - 555, ambushZ},
        {ambushArcherMonsterId, ambushX - 75, ambushY - 600, ambushZ},
        {ambushArcherMonsterId, ambushX + 75, ambushY - 600, ambushZ},
        {ambushArcherMonsterId, ambushX + 220, ambushY - 555, ambushZ},
    }

    for _, ambusherData in ipairs(meleeFormation) do
        local _, ambusherIndex = SummonMonster(ambusherData[1], ambusherData[2], ambusherData[3], ambusherData[4], true)
        table.insert(humanMapMonIndexes, ambusherIndex)
    end

    for _, ambusherData in ipairs(archerFormation) do
        local _, ambusherIndex = SummonMonster(ambusherData[1], ambusherData[2], ambusherData[3], ambusherData[4], true)
        table.insert(humanMapMonIndexes, ambusherIndex)
    end

    local _, ambushContactIndex = SummonMonster(ambushMasterMonkMonsterId , ambushX + 280, ambushY - 180, ambushZ, true)
    table.insert(humanMapMonIndexes, ambushContactIndex)
    vars.SpymasterAmbushSwordsmanSummoned = true

    CreateAndSetMonsterEncounterFromIndexes(S.AmbushKhorTarrEncounterName, khorTarrMapMonIndexes, S.Kriegspire)
    CreateAndSetMonsterEncounterFromIndexes(S.AmbushHumanEncounterName, humanMapMonIndexes, S.Kriegspire)
    ApplySpymasterAmbushSetup(true)
    CreateAndSetMonsterEncounterFromIndexes(S.AmbushKhorTarrEncounterName, khorTarrMapMonIndexes, S.Kriegspire)
    CreateAndSetMonsterEncounterFromIndexes(S.AmbushHumanEncounterName, humanMapMonIndexes, S.Kriegspire)

    if showDialog then
        evt.SpeakNPC{S.AmbushContactNPC}
    end
end

StartSpymasterAmbush = function()
    vars.SpymasterAmbushStarted = true
    vars.SpymasterDialogStage = "AmbushChoice"
    if NPCFollowers.NPCInGroup(S.CarterNPC) then
        NPCFollowers.Remove(S.CarterNPC)
    end
    Game.NPC[S.CarterNPC].House = 0
    SummonSpymasterAmbushEncounter(true)
end

SetAmbushMonsterHostile = function(hostile, ally)
    -- Hostile monsters need their own encounter class as Ally so same-side demons do not fight each other; neutral uses 9999.
    local resolvedAlly = ally ~= nil and ally or (hostile and GetMonsterEncounterAllyClass(S.AmbushHumanEncounterName, S.Kriegspire) or 9999)
    evt.ChangeGroupAlly{ambusherGroup, resolvedAlly}
    evt.SetMonGroupBit{ambusherGroup, const.MonsterBits.Hostile, hostile == true}

    ForEachMonsterEncounter(GetMonsterEncounter(S.AmbushHumanEncounterName, S.Kriegspire), function(_, mon)
        if IsAmbushHumanMonster(mon) and mon.HP > 0 and mon.AIState ~= const.AIState.Removed then
            S.ConfigureQuestMonster(mon, hostile, resolvedAlly, ambusherGroup)
        end
    end, true)
end

SetKhorTarrMonsterHostile = function(hostile, ally)
    -- Hostile monsters need their own encounter class as Ally so same-side demons do not fight each other; neutral uses 9999.
    local resolvedAlly = ally ~= nil and ally or (hostile and GetMonsterEncounterAllyClass(S.AmbushKhorTarrEncounterName, S.Kriegspire) or 9999)
    evt.ChangeGroupAlly{khorTarrAmbushGroup, resolvedAlly}
    evt.SetMonGroupBit{khorTarrAmbushGroup, const.MonsterBits.Hostile, hostile == true}

    ForEachMonsterEncounter(GetMonsterEncounter(S.AmbushKhorTarrEncounterName, S.Kriegspire), function(_, mon)
        if IsKhorTarrSideMonster(mon) and mon.HP > 0 and mon.AIState ~= const.AIState.Removed then
            S.ConfigureQuestMonster(mon, hostile, resolvedAlly, khorTarrAmbushGroup)
        end
    end, true)
end

ApplySpymasterAmbushFactionHostility = function()
    local khorTarrSideClasses = GetMonsterEncounterClasses(S.AmbushKhorTarrEncounterName, S.Kriegspire)
    local humanSideClasses = GetMonsterEncounterClasses(S.AmbushHumanEncounterName, S.Kriegspire)

    for _, khorTarrSideClass in ipairs(khorTarrSideClasses) do
        for _, humanSideClass in ipairs(humanSideClasses) do
            Game.HostileTxt[khorTarrSideClass][humanSideClass] = 4
            Game.HostileTxt[humanSideClass][khorTarrSideClass] = 4
        end
        Game.HostileTxt[khorTarrSideClass][0] = vars.SpymasterAmbushSide == "Ambushers" and 4 or 0
    end

    for _, humanSideClass in ipairs(humanSideClasses) do
        Game.HostileTxt[humanSideClass][0] = vars.SpymasterAmbushSide == "KhorTarr" and 4 or 0
    end
end

ActivateSpymasterAmbushActors = function()
    ForEachMonsterEncounter(GetMonsterEncounter(S.AmbushKhorTarrEncounterName, S.Kriegspire), function(_, mon)
        if IsKhorTarrSideMonster(mon) and mon.HP > 0 and mon.AIState ~= const.AIState.Removed then
            mon.AIState = const.AIState.Active
        end
    end, true)
    ForEachMonsterEncounter(GetMonsterEncounter(S.AmbushHumanEncounterName, S.Kriegspire), function(_, mon)
        if IsAmbushHumanMonster(mon) and mon.HP > 0 and mon.AIState ~= const.AIState.Removed then
            mon.AIState = const.AIState.Active
        end
    end, true)
end

MarkSpymasterAmbushEncountersForRemoval = function()
    MarkMonsterEncounterForRemoval(S.AmbushKhorTarrEncounterName, S.Kriegspire)
    MarkMonsterEncounterForRemoval(S.AmbushHumanEncounterName, S.Kriegspire)
end

KillKhorTarrSideSummons = function()
    ForEachMonsterEncounter(GetMonsterEncounter(S.AmbushKhorTarrEncounterName, S.Kriegspire), function(_, mon)
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
    ForEachMonsterEncounter(GetMonsterEncounter(S.AmbushKhorTarrEncounterName, S.Kriegspire), function(_, mon)
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
        S.ConfigureQuestMonster(demon, khorTarr.Hostile, khorTarr.Ally, khorTarrAmbushGroup)
        table.insert(summonedIndexes, demonIndex)
    end

    AddMonsterEncounterIndexes(S.AmbushKhorTarrEncounterName, summonedIndexes, S.Kriegspire)
    ApplySpymasterAmbushFactionHostility()
end

ApplyResolvedAmbushSide = function()
    if vars.SpymasterAmbushSide == "KhorTarr" then
        ApplySpymasterAmbushFactionHostility()
        SetAmbushMonsterHostile(true)
        SetKhorTarrMonsterHostile(false)
        ActivateSpymasterAmbushActors()
    elseif vars.SpymasterAmbushSide == "Ambushers" then
        ApplySpymasterAmbushFactionHostility()
        SetAmbushMonsterHostile(false)
        SetKhorTarrMonsterHostile(true)
        ActivateSpymasterAmbushActors()
    end
end

ResolveSpymasterAmbush = function(side)
    vars.SpymasterAmbushSide = side
    vars.SpymasterDialogStage = nil

    if side == "KhorTarr" then
        vars.SpymasterKhorTarrFollowupPending = true
    else
        vars.SpymasterAmbusherFollowupPending = true
    end
    ApplyResolvedAmbushSide()
end

TriggerSpymasterFollowupDialog = function()
    if not S.InKriegspire() then
        return
    end

    if vars.SpymasterKhorTarrFollowupPending and vars.SpymasterAmbushGroupDead ~= true then
        local humanEncounter = GetMonsterEncounter(S.AmbushHumanEncounterName, S.Kriegspire)
        if humanEncounter and MonsterEncounterHasAnyActive(humanEncounter) == false then
            vars.SpymasterAmbushGroupDead = true
            MarkSpymasterAmbushEncountersForRemoval()
        end
    end

    if vars.SpymasterKhorTarrFollowupPending and vars.SpymasterAmbushGroupDead == true and S.SafeToInterruptParty() then
        vars.SpymasterKhorTarrFollowupPending = nil
        vars.SpymasterDialogStage = "KhorTarrFollowup"
        RemoveSpymasterAmbushActorMonsters(true, false)
        S.CreateCarterNPCAfterReveal()
        evt.SpeakNPC{S.CarterNPC}
    elseif vars.SpymasterAmbusherFollowupPending and vars.SpymasterAmbushKhorTarrDead == true and vars.SpymasterAmbushCorvinDead ~= true and S.SafeToInterruptParty() then
        vars.SpymasterAmbusherFollowupPending = nil
        vars.SpymasterDialogStage = "AmbusherFollowup"
        RemoveSpymasterAmbushActorMonsters(false, true)
        S.CreateAmbushContactNPC()
        evt.SpeakNPC{S.AmbushContactNPC}
    end
end

-- Story timers ---------------------------------------------------------------
MonitorSpymasterAmbushThresholds = function()
    if not S.InKriegspire() or not IsAmbushStarted() or vars.SpymasterAmbushSide == nil or vars.SpymasterAmbushKhorTarrDead == true then
        return
    end

    local khorTarr
    ForEachMonsterEncounter(GetMonsterEncounter(S.AmbushKhorTarrEncounterName, S.Kriegspire), function(_, mon)
        if IsKhorTarrMonster(mon) and mon.HP > 0 and mon.AIState ~= const.AIState.Removed and mon.AIState ~= const.AIState.Dead then
            khorTarr = mon
        end
    end, true)
    if not khorTarr or khorTarr.FullHP <= 0 then
        return
    end

    local hpPercent = khorTarr.HP * 100 / khorTarr.FullHP
    if hpPercent <= 70 and vars.SpymasterAmbushKhorTarrSummoned70 ~= true then
        vars.SpymasterAmbushKhorTarrSummoned70 = true
        SummonKhorTarrReinforcements(devilSpawnMonsterId)
    end
    if hpPercent <= 40 and vars.SpymasterAmbushKhorTarrSummoned40 ~= true then
        vars.SpymasterAmbushKhorTarrSummoned40 = true
        SummonKhorTarrReinforcements(devilWorkerMonsterId)
    end
    if hpPercent <= 20 and vars.SpymasterAmbushKhorTarrSummoned20 ~= true then
        vars.SpymasterAmbushKhorTarrSummoned20 = true
        SummonKhorTarrReinforcements(devilWarriorMonsterId)
    end
end

MonitorSpymasterStoryProgress = function()
    MonitorSpymasterAmbushThresholds()

    if vars.SpymasterRevealTriggerTime ~= nil and vars.SpymasterRevealSeen ~= true and Game.Time >= vars.SpymasterRevealTriggerTime + const.Hour * 2 and
           S.SafeToInterruptParty() then
        S.CreateAmbushContactNPC()
        vars.SpymasterDialogStage = "Reveal"
        vars.SpymasterRevealTriggerTime = nil
        evt.SpeakNPC{S.AmbushContactNPC}
        return
    end

    if IsAmbushGiven() and vars.SpymasterEscortIntent ~= nil and not IsAmbushStarted() and
           NPCFollowers.NPCInGroup(S.CarterNPC) == nil and Game.NPC[S.CarterNPC].House == 0 then
        Game.NPC[S.CarterNPC].House = S.BlackShireHouse
    end

    if IsAmbushGiven() and NPCFollowers.NPCInGroup(S.CarterNPC) and not IsAmbushStarted() and InSpymasterAmbushArea() and
           S.SafeToInterruptParty() then
        StartSpymasterAmbush()
        return
    end

    if vars.SpymasterKhorTarrFollowupPending or vars.SpymasterAmbusherFollowupPending then
        TriggerSpymasterFollowupDialog()
    end
end

-- Event listeners -------------------------------------------------------------
function events.AfterLoadMap()
    if S.InKriegspire() then
        if vars.SpymasterRevealSeen == true and vars.SpymasterAmbushKhorTarrDead ~= true then
            S.CreateCarterNPCAfterReveal()
        end
        Game.NPC[S.DroppaMaPantzNPC].Joins = 0
        if IsAmbushStarted() then
            if HasActiveSpymasterAmbushActors() then
                ApplySpymasterAmbushSetup()
                ApplyResolvedAmbushSide()
            elseif not IsAmbushDone() and HasNoDialogStage() and vars.SpymasterKhorTarrFollowupPending ~= true and
                       vars.SpymasterAmbusherFollowupPending ~= true and vars.SpymasterAmbushGroupDead ~= true and vars.SpymasterAmbushKhorTarrDead ~= true then
                SummonSpymasterAmbushEncounter(false)
                ApplyResolvedAmbushSide()
            end
        end
    end

    if S.InFreehaven() and vars.SpymasterAmbushKhorTarrDead == true and vars.SpymasterAmbushCorvinDead ~= true then
        S.CreateAmbushContactNPC()
        Game.NPC[S.AmbushContactNPC].House = S.FreeHavenCorvinHouse
    end

    if svars.SpymasterStoryTimerRunning ~= true then
        Timer(MonitorSpymasterStoryProgress, const.Second)
        svars.SpymasterStoryTimerRunning = true
    end
end

function events.LeaveMap()
    if S.InKriegspire() and vars.SpymasterAmbushKhorTarrDead == true then
        MarkSpymasterAmbushEncountersForRemoval()
    end

    RemoveTimer(MonitorSpymasterStoryProgress)
    svars.SpymasterStoryTimerRunning = nil
end

function events.ShowNPCTopics()
    if Game.CurrentScreen == const.Screens.House and Game.GetCurrentHouse() == S.KhorTarrHideoutHouse then
        FinishKhorTarrHideoutEscort()
    end
end

function events.ExitNPC()
    if IsDialogStage("AmbushChoice") and vars.SpymasterAmbushSide == nil then
        if vars.SpymasterEscortIntent == "Tricked" then
            ResolveSpymasterAmbush("Ambushers")
        else
            ResolveSpymasterAmbush("KhorTarr")
        end
    elseif IsDialogStage("KhorTarrFollowup") and vars.SpymasterKhorTarrFollowupSeen ~= true then
        CompleteKhorTarrFollowup()
    elseif IsDialogStage("AmbusherFollowup") and vars.SpymasterAmbusherFollowupSeen ~= true then
        CompleteAmbusherFollowup()
    end
end

function events.MonsterKilled(mon)
    if S.InKriegspire() and IsAmbushStarted() and IsAmbushHumanMonster(mon) then
        if mon.Id == ambushMasterMonkMonsterId then
            vars.SpymasterAmbushCorvinDead = true
            if vars.SpymasterAmbushSide == "Ambushers" then
                EndSpymasterAmbushQuestline("Corvin has died, and the quest line ends with him")
                return
            end
        end

        local humanEncounter = GetMonsterEncounter(S.AmbushHumanEncounterName, S.Kriegspire)
        local hasActiveAmbushers = humanEncounter and MonsterEncounterHasAnyActive(humanEncounter) or nil
        if hasActiveAmbushers == false then
            vars.SpymasterAmbushGroupDead = true
            MarkSpymasterAmbushEncountersForRemoval()
        end
    end

    if S.InKriegspire() and IsAmbushStarted() and IsKhorTarrMonster(mon) then
        vars.SpymasterAmbushKhorTarrDead = true
        KillKhorTarrSideSummons()
        MarkSpymasterAmbushEncountersForRemoval()
        if vars.SpymasterAmbushSide == "KhorTarr" then
            EndSpymasterAmbushQuestline("Khor-Tarr has died, and the quest line ends with him")
        end
    end
end

function events.SpeakWithMonster(t)
    if not S.InKriegspire() then
        return
    end

    if IsAmbushStarted() and IsAmbushHumanMonster(t.Monster) then
        t.Result = "The trap is sprung."
    end
end

function events.CalcDamageToMonster(t)
    if not t.ByPlayer or not S.InKriegspire() then
        return
    end

    if not IsAmbushStarted() or vars.SpymasterAmbushSide == nil then
        return
    end

    if vars.SpymasterAmbushSide == "KhorTarr" then
        if IsKhorTarrSideMonster(t.Monster) then
            t.Result = 0
        end
    elseif vars.SpymasterAmbushSide == "Ambushers" and IsAmbushHumanMonster(t.Monster) then
        t.Result = 0
    end
end

function events.PlayerAttacked(t)
    if IsFriendlySpymasterAmbushMonster(t.Attacker and t.Attacker.Monster) then
        t.Handled = true
    end
end
