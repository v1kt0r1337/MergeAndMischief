-- This file is for shared functions meant to be reused across multiple files in the Merge and Mischief mod.
-- It acts as the early-loaded common bootstrap for global scripts.

-- session variables - important state for current gaming session.
svars = {}

-- local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5

-- local urokNPC_ID = 1081 -- goblinwatch apartment pre Goblinwatch quest
-- local samsonTessNPC_ID = 828 -- goblinwatch apartment post Goblinwatch quest
-- local harryMerit_ID = 111 -- not in use
-- local NewSorpigal = "oute3.odm"
-- local houseMapName = "decenthouse.blv"

-- local goblinwatchHouse = 1463


-- Copies combat power from `powerMonster` onto the live map monster `mon`.
-- `mon` is the spawned monster instance that keeps its own appearance/identity.
-- `powerMonster` is usually a `Game.MonstersTxt[id]` entry used as the combat template.
-- `resetHP` should be true for fresh scripted spawns that should start at full powered HP.
-- Use false when reapplying after reload so current battle damage is preserved proportionally.
-- `hpMultiplier` is optional and lets callers scale max HP without breaking reload-time HP preservation.
function ApplyMonsterPowerFromMonster(mon, powerMonster, resetHP, hpMultiplier)
    local oldFullHP = mon.FullHP
    local oldHP = mon.HP
    local targetFullHP = math.max(1, math.floor(powerMonster.FullHP * (hpMultiplier or 1)))

    mon.FullHP = targetFullHP
    if resetHP then
        mon.HP = targetFullHP
    else
        -- Preserve the monster's current health percentage when swapping to a different max HP pool.
        local hpRatio = oldFullHP > 0 and oldHP / oldFullHP or 1
        mon.HP = math.max(1, math.floor(mon.FullHP * hpRatio))
    end
    mon.ArmorClass = powerMonster.ArmorClass
    mon.Exp = powerMonster.Exp
    mon.Level = powerMonster.Level
    mon.MoveType = powerMonster.MoveType
    mon.TreasureItemPercent = powerMonster.TreasureItemPercent
    mon.TreasureDiceCount = powerMonster.TreasureDiceCount
    mon.TreasureDiceSides = powerMonster.TreasureDiceSides
    mon.TreasureItemLevel = powerMonster.TreasureItemLevel
    mon.TreasureItemType = powerMonster.TreasureItemType

    mon.Attack1.DamageAdd = powerMonster.Attack1.DamageAdd
    mon.Attack1.DamageDiceSides = powerMonster.Attack1.DamageDiceSides
    mon.Attack1.DamageDiceCount = powerMonster.Attack1.DamageDiceCount

    mon.Attack2Chance = powerMonster.Attack2Chance
    mon.Attack2.DamageAdd = powerMonster.Attack2.DamageAdd
    mon.Attack2.DamageDiceSides = powerMonster.Attack2.DamageDiceSides
    mon.Attack2.DamageDiceCount = powerMonster.Attack2.DamageDiceCount

    mon.SpellChance = powerMonster.SpellChance
    mon.Spell = powerMonster.Spell
    mon.SpellSkill = powerMonster.SpellSkill
    mon.Spell2Chance = powerMonster.Spell2Chance
    mon.Spell2 = powerMonster.Spell2
    mon.Spell2Skill = powerMonster.Spell2Skill

    mon.FireResistance = powerMonster.FireResistance
    mon.AirResistance = powerMonster.AirResistance
    mon.WaterResistance = powerMonster.WaterResistance
    mon.EarthResistance = powerMonster.EarthResistance
    mon.MindResistance = powerMonster.MindResistance
    mon.SpiritResistance = powerMonster.SpiritResistance
    mon.BodyResistance = powerMonster.BodyResistance
    mon.LightResistance = powerMonster.LightResistance
    mon.DarkResistance = powerMonster.DarkResistance
    mon.PhysResistance = powerMonster.PhysResistance
end

-- local function IsOriginalGoblinwathDone()
--     return Party.QBits[313] and Party.QBits[1324] and Party.QBits[1107] == false
-- end

-- local function RestoreUrok()
--     RemoveSafeTopicsFromNPC(urokNPC_ID)
--     NPCTopic{
--         Slot = A,
--         NPC = urokNPC_ID,
--         Topic = "Humans",
--         Text = [[You no goblin!
-- you leave!
-- We take castle to watch over humans!
-- You no more kill us!]]
--     }
--     if IsOriginalGoblinwathDone() then
--         Game.NPC[urokNPC_ID].House = 0
--     else
--         Game.NPC[urokNPC_ID].House = goblinwatchHouse
--     end
--     Game.NPC[urokNPC_ID].Name = "Urok"
--     Game.NPC[urokNPC_ID].Pic = 1031
-- 	Game.NPC[urokNPC_ID].Profession = 0
-- end

-- local function RestoreSamsonTess()
--     if IsOriginalGoblinwathDone() then
--         Game.NPC[samsonTessNPC_ID].House = goblinwatchHouse
--     else
--         Game.NPC[samsonTessNPC_ID].House = 0
--     end
--     RemoveSafeTopicsFromNPC(samsonTessNPC_ID)
--     Game.NPC[samsonTessNPC_ID].Name = "Samson Tess"
--     Game.NPC[samsonTessNPC_ID].Profession = 73 -- guard
--     Game.NPC[samsonTessNPC_ID].Pic = 429

--     NPCTopic{
--         Slot = A,
--         NPC = samsonTessNPC_ID,
--         Topic = "Greeting",
--         Text = [[God work removing the goblins from this keep.
-- We have the situation mostly under control now,
-- though your help is always appreciated.]]
--     }

--     NPCTopic{
--         Slot = B, -- this is originally at Slot = C,
--         NPC = samsonTessNPC_ID,
--         Topic = "Arena",
--         Text = "Fortunately, most violent people take their aggressions out in the Arena, and not in the towns."
--     }
-- end

-- local function RestoreHarryMerit()
--     Game.NPC[harryMerit_ID].House = 0
--     Game.NPC[harryMerit_ID].Pic = 0
--     RemoveSafeTopicsFromNPC(harryMerit_ID)
--     Game.NPC[harryMerit_ID].Name = "Harry Merit"

-- end

-- function events.BeforeLoadMap()
--     RestoreSamsonTess()
--     RestoreUrok()
--     RestoreHarryMerit()
--     -- if Map.Name == NewSorpigal then
--     --     -- uroks original npc text
--     -- end
--     -- if Map.Name == houseMapName then

--     -- end
-- end

-- function events.LeaveMap()
--     if Map.Name == houseMapName then
--         vars.decentHousePurpose = nil
--         -- removes all monsters in the map for later reuse
--         for _, m in Map.Monsters do
--             m.AIState = const.AIState.Removed
--         end
--         Map.LastRefillDay = 0
--     end
-- end


-- Party.Qbits
-- before accepting goblinwatch
-- 183
-- 308
-- 1104
-- 1105

-- after accepting goblinwathc
-- 183
-- 308
-- 1104
-- 1105
-- 1107

-- after completing
-- 183
-- 308
-- 313
-- 1104
-- 1105
-- 1324

-- after accepting evil cults
-- 183
-- 308
-- 313
-- 1104
-- 1105
-- 1108
-- 1324
