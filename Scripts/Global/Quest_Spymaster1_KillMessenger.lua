-- ============================================================================
--  Spymaster: Kill Messenger
-- ============================================================================

-- Base data ------------------------------------------------------------------
local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5
local S = Spymaster

local enemyMessengerMonsterId = 637 -- thief

local FindEnemyMessenger
local MakeEnemyMessengerFriendly
local CreateEnemyMessenger
local SummonEnemyMessenger

-- Quest stages ----------------------------------------------------------------
Quest{
    S.KillMessengerQuest,
    Slot = E,
    NPC = S.CarterNPC,
    Give = function()
        SummonEnemyMessenger()
        evt.PlaySound(205) -- quest sound
    end,
    CanShow = function()
        return S.InBlackshire() and vars.Quests[S.KillMessengerQuest] ~= "Done"
    end,
    CheckDone = function()
        return vars.SpymasterMessengerKilled == true
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
}

NPCTopic {
    Slot = A,
    NPC = S.CarterNPC,
    CanShow = function()
        return S.InBlackshire() and vars.SpymasterRevealSeen ~= true and vars.SpymasterEscortIntent == nil
    end,
    Topic = "Secret",
    Text = [[
I'm on a secret mission here.

I normally wouldn't tell anyone, but there is something that makes me trust you.

I'm Queen Catherine's spymaster in Enroth.

Perhaps you could help me out, but you have to keep my existence secret.

Don't trust anyone.]]
}

NPCTopic{
    Slot = B,
    NPC = S.CarterNPC,
    CanShow = function()
        return S.InBlackshire() and vars.SpymasterRevealSeen ~= true and vars.SpymasterEscortIntent == nil
    end,
    Topic = "Kreegans",
    Text = [[
The Kreegans, some call them devils, others demons.

They came to Enroth on the Night of the Shooting Stars.

It's my mission here as Queen Catherine's spymaster, to discover their plans and orchestrate their downfall.
]]
}

NPCTopic {
    Slot = A,
    NPC = S.EnemyMessengerNPC,
    CanShow = function()
        return S.InBlackshire() and vars.Quests[S.KillMessengerQuest] == "Given" and vars.SpymasterMessengerKilled ~= true
    end,
    Topic = "I'm busy",
    Text = "Not now. I'm busy, I simply don't have the time to talk to every traveler I meet on the road."
}

-- Quest runtime helpers -------------------------------------------------------
FindEnemyMessenger = function()
    local messengerEncounter = GetMonsterEncounter(S.MessengerEncounterName, S.Blackshire)
    local messenger

    ForEachMonsterEncounter(messengerEncounter, function(_, mon)
        if mon.Id == enemyMessengerMonsterId and mon.NPC_ID == S.EnemyMessengerNPC and mon.AIState ~= const.AIState.Removed then
            messenger = mon
        end
    end, true)
    if messenger ~= nil then
        return messenger
    end

    for _, mon in Map.Monsters do
        if mon.Id == enemyMessengerMonsterId and mon.NPC_ID == S.EnemyMessengerNPC and mon.AIState ~= const.AIState.Removed then
            return mon
        end
    end
end

MakeEnemyMessengerFriendly = function()
    local enemyMessengerMon = (enemyMessengerMonsterId + 2):div(3)
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
    local enemyMessengerPowerMonsterId = 581 -- minotaur mage
    ApplyMonsterPowerFromMonster(mon, Game.MonstersTxt[enemyMessengerPowerMonsterId], resetPowerHP == true)
    S.ConfigureQuestMonster(mon, false, 9999)
    mon.AIType = 3
    mon.NPC_ID = S.EnemyMessengerNPC

    Game.MonstersTxt[enemyMessengerMonsterId].Name = "Marvin the Messenger"
    Game.NPC[S.EnemyMessengerNPC].Name = "Marvin the Messenger"
    Game.NPC[S.EnemyMessengerNPC].Profession = 0
    Game.NPC[S.EnemyMessengerNPC].Pic = 442
end

SummonEnemyMessenger = function()
    local mon = FindEnemyMessenger()
    local messengerEncounter = GetMonsterEncounter(S.MessengerEncounterName, S.Blackshire)

    if mon == nil then
        local messengerIndex
        mon, messengerIndex = SummonMonster(enemyMessengerMonsterId, -296, 17180, 192, true)
        CreateEnemyMessenger(mon, true)
        CreateAndSetMonsterEncounterFromIndexes(S.MessengerEncounterName, {messengerIndex}, S.Blackshire)
        return
    end

    CreateEnemyMessenger(mon)
    if messengerEncounter == nil then
        CreateAndSetMonsterEncounterFromPredicate(S.MessengerEncounterName, function(_, candidate)
            return candidate.Id == enemyMessengerMonsterId and candidate.AIState ~= const.AIState.Removed and candidate.NPC_ID == S.EnemyMessengerNPC
        end, S.Blackshire)
    end
end

-- Event listeners -------------------------------------------------------------
function events.AfterLoadMap()
    if S.InBlackshire() then
        if vars.SpymasterRevealSeen ~= true then
            S.CreateCarterNPCBeforeReveal()
        elseif vars.SpymasterAmbushKhorTarrDead ~= true and vars.SpymasterAmbushStarted ~= true then
            S.CreateCarterNPCAfterReveal()
        end
        if vars.Quests[S.KillMessengerQuest] == "Given" and vars.SpymasterMessengerKilled ~= true then
            SummonEnemyMessenger()
        end
    end
end

function events.MonsterKilled(mon)
    if S.InBlackshire() and mon.Id == enemyMessengerMonsterId and mon.NPC_ID == S.EnemyMessengerNPC then
        vars.SpymasterMessengerKilled = true
        MarkMonsterEncounterForRemoval(S.MessengerEncounterName, S.Blackshire)
        return
    end
end
