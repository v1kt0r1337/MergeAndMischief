-- This file is for shared functions meant to be reused across multiple files in the Merge and Mischief mod.
-- It acts as the early-loaded common bootstrap for global scripts.

-- session variables - important state for current gaming session.
svars = {}

-- Common quest monster setup. Omitted values preserve the monster's current state.
function ConfigureQuestMonster(mon, hostile, ally, group, options)
    options = options or {}

    if options.NoFlee ~= false then
        mon.NoFlee = true
    end
    if group ~= nil then
        mon.Group = group
    end
    if ally ~= nil then
        mon.Ally = ally
    end
    if hostile ~= nil then
        mon.Hostile = hostile
        mon.ShowAsHostile = hostile
        mon.HostileType = hostile and 4 or 3
    end
    if options.Direction ~= nil then
        mon.Direction = options.Direction
    end
    if options.GuardRadius ~= nil then
        mon.GuardRadius = options.GuardRadius
    elseif options.MinimumGuardRadius ~= nil then
        mon.GuardRadius = math.max(mon.GuardRadius, options.MinimumGuardRadius)
    end
    if options.AIState ~= nil then
        mon.AIState = options.AIState
    end
    if options.UpdateGraphicState == true then
        mon:UpdateGraphicState()
    end

    return mon
end


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
