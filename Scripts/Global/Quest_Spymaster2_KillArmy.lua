-- ============================================================================
--  Spymaster: Kill Army
-- ============================================================================

-- Base data ------------------------------------------------------------------
local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5
local S = Spymaster

-- Text -----------------------------------------------------------------------
local Quest_Spymaster_KillArmyDoneText = [[You have slain their commander?

Excellent.

Without him their force will break up eventually.]]

local Quest_Spymaster_KillArmyDoneText_Bonus = [[You have slain their commander?

And you took care of the rest of the army.

Excellent.]]

-- Army monsters --------------------------------------------------------------
local armyCommander = 587 -- expert swordsman
local armyFighter = 537 -- veteran 
local armyArcher = 475 -- archer
local armySupportMage = 631 -- magician
local armyOffensiveMage = 632 -- magician

local summonHumanArmyInKriegspire
local SetSpymasterArmyMonsterHostile
local ConfigureSpymasterArmyFormationMonster
local MonitorSpymasterArmyHostility
local IsSpymasterArmyMonster
local ApplySpymasterArmySetup
local ApplySpymasterArmyMonsterSetup
local IsSpymasterArmyCurrentlyHostile
local RecordSpymasterArmyFormationAnchor
local HoldSpymasterArmyFormation
local PinSpymasterArmyFormation
local SetSpymasterArmyHostile

-- Quest stages ----------------------------------------------------------------
-- Part 2: Kill the disguised army --------------------------------------------
Quest{
    S.KillArmyQuest,
    Slot = E,
    NPC = S.CarterNPC,
    Give = function()
        vars.SpymasterCommanderKilled = nil
        vars.SpymasterArmyDestroyed = nil
    end,
    CanShow = function()
        return S.InBlackshire() and vars.Quests[S.KillMessengerQuest] == "Done" and vars.Quests[S.AmbushQuest] == nil -- and vars.Quests[S.KillArmyQuest] ~= "Done"
    end,
    CheckDone = function()
        return vars.SpymasterCommanderKilled == true
    end,
    Done = function()
        Message(vars.SpymasterArmyDestroyed == true and Quest_Spymaster_KillArmyDoneText_Bonus or Quest_Spymaster_KillArmyDoneText)
        vars.SpymasterRevealTriggerTime = Game.Time
        if vars.SpymasterArmyDestroyed == true then
            evt.Add("Gold", 10000)
        else
            evt.Add("Gold", 6000)
        end
        MarkMonsterEncounterForRemoval(S.ArmyEncounterName, S.Kriegspire)
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

-- Quest runtime helpers -------------------------------------------------------
IsSpymasterArmyMonster = function(mon)
    return MonsterEncounterContainsMonster(GetMonsterEncounter(S.ArmyEncounterName, S.Kriegspire), mon)
end

ApplySpymasterArmyMonsterSetup = function(mon, resetPowerHP)
    if mon.Id == armyArcher then
        S.ApplyVeteranArcher(mon, resetPowerHP)
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

ApplySpymasterArmySetup = function()
    ForEachMonsterEncounter(GetMonsterEncounter(S.ArmyEncounterName, S.Kriegspire), function(_, mon)
        local monIndex = mon:GetIndex()
        if mon.HP > 0 and mon.AIState ~= const.AIState.Removed then
            ApplySpymasterArmyMonsterSetup(mon, false)
            if mon.Hostile then
                S.ConfigureQuestMonster(mon, true, mon.Ally, mon.Group)
            else
                if mapvars.SpymasterArmyFormationAnchors == nil or mapvars.SpymasterArmyFormationAnchors[monIndex] == nil then
                    RecordSpymasterArmyFormationAnchor(monIndex, mon)
                elseif mapvars.SpymasterArmyFormationAnchors[monIndex].Direction == nil then
                    mapvars.SpymasterArmyFormationAnchors[monIndex].Direction = (mon.Direction + 1024) % 2048
                end
                HoldSpymasterArmyFormation(mon, mapvars.SpymasterArmyFormationAnchors[monIndex])
            end
        end
    end, true)
end

IsSpymasterArmyCurrentlyHostile = function()
    return MonsterEncounterHasAnyHostile(GetMonsterEncounter(S.ArmyEncounterName, S.Kriegspire))
end

RecordSpymasterArmyFormationAnchor = function(monIndex, mon)
    mapvars.SpymasterArmyFormationAnchors = mapvars.SpymasterArmyFormationAnchors or {}
    mapvars.SpymasterArmyFormationAnchors[monIndex] = {X = mon.X, Y = mon.Y, Z = mon.Z, Direction = (mon.Direction + 1024) % 2048}
end

HoldSpymasterArmyFormation = function(mon, anchor)
    anchor = anchor or {X = mon.X, Y = mon.Y, Direction = mon.Direction}
    S.ConfigureQuestMonster(mon, false, 9999, mon.Group)
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

PinSpymasterArmyFormation = function()
    if not S.InKriegspire() or vars.Quests[S.KillArmyQuest] ~= "Given" or IsSpymasterArmyCurrentlyHostile() then
        RemoveTimer(PinSpymasterArmyFormation)
        svars.SpymasterArmyFormationPinTimerRunning = nil
        return
    end

    ForEachMonsterEncounter(GetMonsterEncounter(S.ArmyEncounterName, S.Kriegspire), function(_, mon)
        local monIndex = mon:GetIndex()
        local anchor = mapvars.SpymasterArmyFormationAnchors and mapvars.SpymasterArmyFormationAnchors[monIndex]
        if anchor and mon.HP > 0 and mon.AIState ~= const.AIState.Removed then
            HoldSpymasterArmyFormation(mon, anchor)
        end
    end, true)
end

SetSpymasterArmyHostile = function()
    SetSpymasterArmyMonsterHostile(true)
    RemoveTimer(PinSpymasterArmyFormation)
    svars.SpymasterArmyFormationPinTimerRunning = nil
    ForEachMonsterEncounter(GetMonsterEncounter(S.ArmyEncounterName, S.Kriegspire), function(_, mon)
        if mon.HP > 0 and mon.AIState ~= const.AIState.Removed then
            mon.GuardRadius = 6000
            mon.AIState = const.AIState.Active
            mon:UpdateGraphicState()
        end
    end, true)
end

SetSpymasterArmyMonsterHostile = function(hostile, ally)
    ForEachMonsterEncounter(GetMonsterEncounter(S.ArmyEncounterName, S.Kriegspire), function(_, mon)
        if mon.HP > 0 and mon.AIState ~= const.AIState.Removed then
            S.ConfigureQuestMonster(mon, hostile, ally ~= nil and ally or (hostile and 0 or 9999), mon.Group)
        end
    end, true)
end

ConfigureSpymasterArmyFormationMonster = function(mon, monIndex)
    RecordSpymasterArmyFormationAnchor(monIndex, mon)
    HoldSpymasterArmyFormation(mon, mapvars.SpymasterArmyFormationAnchors[monIndex])
end

summonHumanArmyInKriegspire = function()
    local mapMonIndexes = {}

    local function SummonArmyFormation(monsterId, firstX, firstY, xAxisCount, yAxisCount)
        local _, formationIndexes = MonsterFormation.Summon {
            SummonPos = {
                X = firstX + (xAxisCount - 1) * 50,
                Y = firstY + (yAxisCount - 1) * 50,
                Z = 255,
            },
            Formation = {
                XAxisCount = xAxisCount,
                YAxisCount = yAxisCount,
                XAxisSpacing = 100,
                YAxisSpacing = 100,
                MonsterComposition = {DefaultMonsterId = monsterId},
            },
            Configure = ConfigureSpymasterArmyFormationMonster,
        }
        for _, monIndex in ipairs(formationIndexes) do
            table.insert(mapMonIndexes, monIndex)
        end
    end

    -- Left formation
    SummonArmyFormation(armyArcher, 20200, -14750, 2, 5)
    SummonArmyFormation(armyFighter, 19700, -14750, 3, 5)

    -- Middle formation
    SummonArmyFormation(armyArcher, 20200, -14000, 2, 5)
    SummonArmyFormation(armyFighter, 19700, -14000, 3, 5)

    -- Right formation
    SummonArmyFormation(armyArcher, 20200, -13250, 2, 5)
    SummonArmyFormation(armyFighter, 19700, -13250, 3, 5)

    -- One offensive mage with a support mage behind it between each formation.
    SummonArmyFormation(armyOffensiveMage, 19700, -14175, 1, 1)
    SummonArmyFormation(armySupportMage, 19800, -14175, 1, 1)
    SummonArmyFormation(armyOffensiveMage, 19700, -13425, 1, 1)
    SummonArmyFormation(armySupportMage, 19800, -13425, 1, 1)

    local commander, commanderIndex = SummonMonster(armyCommander, 19500, -13800, 255, true)
    ConfigureSpymasterArmyFormationMonster(commander, commanderIndex)
    table.insert(mapMonIndexes, commanderIndex)
    CreateAndSetMonsterEncounterFromIndexes(S.ArmyEncounterName, mapMonIndexes, S.Kriegspire)
    ApplySpymasterArmySetup()
end

-- Story timers ---------------------------------------------------------------
MonitorSpymasterArmyHostility = function()
    if not S.InKriegspire() or vars.Quests[S.KillArmyQuest] ~= "Given" then
        RemoveTimer(MonitorSpymasterArmyHostility)
        svars.SpymasterArmyHostilityTimerRunning = nil
        return
    end

    if IsSpymasterArmyCurrentlyHostile() then
        SetSpymasterArmyHostile()
        RemoveTimer(MonitorSpymasterArmyHostility)
        svars.SpymasterArmyHostilityTimerRunning = nil
        return
    end
end

-- Event listeners -------------------------------------------------------------
function events.AfterLoadMap()
    if S.InKriegspire() and vars.Quests[S.KillArmyQuest] == "Given" then
        if mapvars.SpymasterArmySummoned ~= true then
            summonHumanArmyInKriegspire()
            mapvars.SpymasterArmySummoned = true
        end
        ApplySpymasterArmySetup()
        if svars.SpymasterArmyHostilityTimerRunning ~= true then
            Timer(MonitorSpymasterArmyHostility, const.Second)
            svars.SpymasterArmyHostilityTimerRunning = true
        end
        if not IsSpymasterArmyCurrentlyHostile() and svars.SpymasterArmyFormationPinTimerRunning ~= true then
            Timer(PinSpymasterArmyFormation, const.Minute / 4)
            svars.SpymasterArmyFormationPinTimerRunning = true
        end
    end
end

function events.LeaveMap()
    RemoveTimer(MonitorSpymasterArmyHostility)
    svars.SpymasterArmyHostilityTimerRunning = nil
    RemoveTimer(PinSpymasterArmyFormation)
    svars.SpymasterArmyFormationPinTimerRunning = nil
end

function events.MonsterKilled(mon)
    if S.InKriegspire() and vars.Quests[S.KillArmyQuest] == "Given" and IsSpymasterArmyMonster(mon) then
        if mon.Id == armyCommander then
            vars.SpymasterCommanderKilled = true
        end

        local armyEncounter = GetMonsterEncounter(S.ArmyEncounterName, S.Kriegspire)
        if armyEncounter then
            local hasActive = MonsterEncounterHasAnyActive(armyEncounter)
            if hasActive == false then
                vars.SpymasterArmyDestroyed = true
            end
        end
    end
end

function events.SpeakWithMonster(t)
    if not S.InKriegspire() then
        return
    end

    if vars.Quests[S.KillArmyQuest] ~= "Given" then
        return
    elseif t.Monster.Id == armyCommander then
        t.Result = [[We are on a secret mission.

Now where is that good for nothing messenger!]]
    elseif IsSpymasterArmyMonster(t.Monster) then
        t.Result = "Commander Carl gives the orders around here."
    end
end

function events.CalcDamageToMonster(t)
    if not t.ByPlayer or not S.InKriegspire() then
        return
    end

    if vars.Quests[S.KillArmyQuest] == "Given" and IsSpymasterArmyMonster(t.Monster) and not IsSpymasterArmyCurrentlyHostile() then
        SetSpymasterArmyHostile()
    end
end
