function cac() 
	-- clear conditions
	for _, a in Party do
		for i in a.Conditions do
			a.Conditions[i] = 0
		end
	end
	Game.NeedRedraw = true

end

function fh()
	-- full HP, SP
	for _,pl in Party do
		pl.HP = pl:GetFullHP()
		pl.SP = pl:GetFullSP()
	end
	
	Game.NeedRedraw = true
end

function fm() 
	cac()
	fh()
end

function inv()
	Party.SpellBuffs[const.PartyBuff.Invisibility].ExpireTime = Game.Time + 100000
end

function ma() 
	evt.Add("Inventory", Mouse.Item.Number)
end

function refill()
	print( Map.LastRefillDay)
	Map.LastRefillDay = 0
end


function printMouse()
	print(dump(Mouse.Item))
	print(dump(Game.ItemsTxt[Mouse.Item.Number]))
end


function mouseInto1H()
    Game.ItemsTxt[Mouse.Item.Number].EquipStat = const.ItemType.Weapon - 1
end
function mouseInto2H()
    Game.ItemsTxt[Mouse.Item.Number].EquipStat = const.ItemType.Weapon2H - 1
end

function RespecSkillPoints(playerIndex, countSharedSkill)
	local sharedSkills = {
		[const.Skills.Repair] = true,
		[const.Skills.IdentifyItem] = true,
		[const.Skills.IdentifyMonster] = true,
		[const.Skills.Repair] = true,
		[const.Skills.Merchant] = true,
		[const.Skills.DisarmTraps] = true,
	}
	local player = Party[playerIndex]
	local freePoints = 0
	for i, val in player.Skills do
		if countSharedSkill == true or sharedSkills[i] ~= true then
			local skill, mastery = SplitSkill(val)
			for i = 2, skill do
				freePoints = freePoints + i
			end
			player.Skills[i] = JoinSkill(skill == 0 and 0 or 1, mastery)
		end 
	end
	player.SkillPoints = player.SkillPoints + freePoints
end


function RespecMastery(playerIndex) 
	local player = Party[playerIndex]
	local gold = 0
	for i, val in player.Skills do
		local skill, mastery = SplitSkill(val)
		if mastery == const.GM then
			gold = gold + 10000 + 7000 + 4000
		elseif mastery == const.Master then
			gold = gold + 7000 + 4000
		elseif mastery == const.Expert then
			gold = gold + 4000 
		end
		player.Skills[i] = JoinSkill(skill, const.Basic)
	end
	Party.Gold = Party.Gold + gold
end

function learnAllAvailableSkills(playerIndex)
	local pl = Party[playerIndex1]
	for i, learn in EnumAvailableSkills(pl.Class) do
		if i ~= const.Skills.Blaster then
			local skill, mastery = SplitSkill(pl.Skills[i])
			if skill < 1 then
				pl.Skills[i] = JoinSkill(1, 1)
			end
		end
	end
end

function summonEnemies() 
	for i = 1, #Map.Monsters - 1 do
		local monster = Map.Monsters[i]
		if Game.MonstersTxt[Map.Monsters[i].Id].Name ~= "Peasant" then
			monster.X, monster.Y, monster.Z = Party.X, Party.Y, Party.Z
		end
	end
 end
 
function summonX(monsterName) 
	for i = 1, #Map.Monsters - 1 do
		local monster = Map.Monsters[i]
		if string.lower(Game.MonstersTxt[Map.Monsters[0].Id]):find(string.lower(monsterName)) then
			monster.X, monster.Y, monster.Z = Party.X, Party.Y, Party.Z
		end
	end
end

function summonRemoved() 
	for i = 0, #Map.Monsters - 1 do
        local monster = Map.Monsters[i]
        -- Log out the Hostile property of the current monster
        if monster.HitPoints > 0 and monster.AIState == const.AIState.Removed  then
            monster.AIState = const.AIState.Active
			monster.X, monster.Y, monster.Z = Party.X, Party.Y, Party.Z
        end
    end
end

 function teleportToRandomMonster()
    for i = 1, #Map.Monsters - 1 do
        local monster = Map.Monsters[i]
        -- Log out the Hostile property of the current monster
        if  Game.MonstersTxt[Map.Monsters[i].Id].Name ~= "Peasant" and monster.HP > 0 and monster.AIState ~= const.AIState.Removed then
            Party.X, Party.Y, Party.Z = monster.X, monster.Y, monster.Z
            return
        end
    end
 end

 function tpMonster()
    teleportToRandomMonster()
 end

 function teleportToRandomNPC()
    for i = 1, #Map.Monsters - 1 do
        local monster = Map.Monsters[i]
        -- Log out the Hostile property of the current monster
        if monster.Hostile == false and monster.HP > 0 then
            Party.X, Party.Y, Party.Z = monster.X, monster.Y, monster.Z
            return
        end
    end
 end

function turnRemovedMonstersActive()
    for i = 1, #Map.Monsters - 1 do
        local monster = Map.Monsters[i]
        -- Log out the Hostile property of the current monster
        if monster.HitPoints > 0 and monster.AIState == const.AIState.Removed  then
            monster.AIState = const.AIState.Active
        end
    end
end



function countRemovedMonsters() 
    local removedMonsters = {}
    for i = 1, #Map.Monsters - 1 do
        local monster = Map.Monsters[i]
        if monster.HitPoints > 0 and monster.AIState == const.AIState.Removed then
            removedMonsters[#removedMonsters + 1] = monster
        end
    end
    print(#removedMonsters)
end



-- BodyLocation = 2,
--     Bonus = 11,
--     Bonus2 = 46,
--     BonusExpireTime = 0,
--     BonusStrength = 56,
--     Broken = false,
--     Charges = 0,
--     Condition = 1,
--     Hardened = false,
--     Identified = true,
--     MaxCharges = 7,
--     Number = 832,
--     Owner = 0,
--     Refundable = false,
--     Stolen = false,
--     TemporaryBonus = false
-- }
-- Il try to change to these values in my save and see how bad I corrupt it
-- Malekith — Today at 7:39 PM
-- enchantment is Bonus, BonusStrength, MaxCharges
-- maxcharges is what determines the base stats and special enchant power 
-- the 2nd normal enchant is Charges
-- BonusExpireTime 1 and 2 is for ancient/primordial (no real change, the bonus is calculated in the item generating process)
-- to generate it easily is:
-- Mouse.Item.Number=832
-- Mouse.Item.Bonus=11 
-- etc...

