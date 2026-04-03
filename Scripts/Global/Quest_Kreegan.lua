-- empty house in blackshire 1387
--[[

-- kreegan pics 971, 1020
 971 fits best

Names: 
if we allow h3
 - Cahl / Carl

else
    Khor-Tarr / Carter
    Baal-Zath / Balzar
    A'karr-on / Aaron
]] --
-- Slots
local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5

local blackShireHouse = 1387

local blackshire = "outb2.odm"
local kriegspire = "outb1.odm"
local Quest_Kreegan = "Quest_Kreegan"

local carterNPC_ID = 111
local createCarterNPCBeforeReveal
local createCarterNPCAfterReveal
local summonHumanArmyInKriegspire
local changeHumanArmyHostility
local makeTroop

local function InMap(map)
    return Map.Name == map
end
local function InBlackshire()
    return InMap(blackshire)
end
local function InKriegspire()
    return InMap(kriegspire)
end

-- QuestStage wrapper (cosmetic grouping) -------------------------------------
local function QuestStage(name)
    return function(block)
        return block
    end
end

-- ============================================================================
--  Quest stages
-- ============================================================================

QuestStage "Start" {
    Quest{
        Quest_Kreegan,
        Slot = E,
        NPC = carterNPC_ID,
        -- Give = function()
        --     evt.PlaySound(205) -- give quest sound
        -- end,
        CanShow = InBlackshire,
        CheckDone = function()
            return vars.MessengerKilled -- something less generic to avoid conflics
        end,
        Done = function()
        end
    }.SetTexts {
        Topic = "Quest",
        Give = [[
I have reports of an enemy messenger.

He needs to be killed before he reach his target.

He was reported walking]],
        Undone = "If the messenger is still alive why are you here? The messenger is reported to be nearing ",
        Done = "Good"
    },

    NPCTopic {
        Slot = A,
        NPC = carterNPC_ID,
        Topic = "Secret",
        Text = [[
I'm on a secret mission here. 

I normally wouldn't tell anyone, but there is something that makes me trust you.

I'm Queen Catherine's spymaster in Enroth.

Perhaps you could help me out, but you have to keep my existence secret. 

Don't trust anyone.]]
    }
}

createCarterNPCBeforeReveal = function()
    Game.NPC[carterNPC_ID].House = blackShireHouse
    Game.NPC[carterNPC_ID].Name = "Carter"

end

createCarterNPCAfterReveal = function()
    -- Game.NPC[carterNPC_ID].House = blackShireHouse
    Game.NPC[carterNPC_ID].pic = 377 -- 18 -- 265 
    Game.NPC[carterNPC_ID].Name = "Khor-Tarr"
end

function events.AfterLoadMap()
    if InBlackshire() then
        createCarterNPCBeforeReveal()
    end
    if InKriegspire() then
        summonHumanArmyInKriegspire()
        changeHumanArmyHostility(true)
    end
end

--[[
Quest, an army of Kreegans disguised as humans are gathering east of the town small town near Kriegspire, 
-- strike them fast while they are in this weakened guise

]]

changeHumanArmyHostility = function(friendly)
    local hostility = (friendly and 0) or 4
    local archer = 475
    local archerMon = (archer + 2):div(3)
    Game.HostileTxt[archerMon][0] = hostility
    local figher = 535
    local figherMon = (figher + 2):div(3)
    Game.HostileTxt[figherMon][0] = hostility
    local sorcerer = 631
    local sorcererMon = (sorcerer + 2):div(3)
    Game.HostileTxt[sorcererMon][0] = hostility
    local swordsman = 586
    local swordsmanMon = (swordsman + 2):div(3)
    Game.HostileTxt[swordsmanMon][0] = hostility
end

-- higher x more east,
-- higher y more north
makeTroop = function(monId, firstX, firstY, z, rows, cols)
    for i = 0, (rows * cols) - 1 do
        local row = i % rows -- row index (east/west)
        local col = math.floor(i / rows) -- col index (north/south)

        local x = firstX + row * 100 -- step east/west
        local y = firstY + col * 100 -- step north/south

        print("Iteration:", i, "Row:", row, "Col:", col, "Pos:", x, y)
        SummonMonster(monId, x, y, z, true)

        -- make troop not move until hostile, const.AIState.Stand or Paralyze doesn't work. 
        -- Check if there is some AI stuff we can use, or if we need to do a magic effect on them.
    end
end

summonHumanArmyInKriegspire = function()
    local swordsman = 586 -- 
    local guard = 553
    local figher = 535 -- soldier, veteran  // mulig disse er mest passende melee?
    local archer = 475
    local magyar = 478 -- kanskje ikke passende
    local sorcerer = 631

    makeTroop(archer, 20200, -14500, 255, 2, 5)
    makeTroop(figher, 19700, -14500, 255, 3, 5)
    makeTroop(sorcerer, 19900, -14000, 255, 1, 1)
    SummonMonster(swordsman + 1, 19500, -14200, 255, true)

    --[[
        This is at Kriegsspire road exit to Frozen Highlands
        { 17399, 14928, 880 }
    --]]

end
