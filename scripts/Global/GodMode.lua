function god(lev)
	-- get all spells
	for _,pl in Party do
		for i in pl.Spells do
			pl.Spells[i] = true
		end
	end

	for _,pl in Party do
		pl.MightBase = 500	
		pl.IntellectBase = 500
		pl.PersonalityBase = 500
		pl.EnduranceBase = 500	
		pl.SpeedBase = 500	
		pl.AccuracyBase = 500	
		pl.LuckBase	= 500
	end

	-- learn all available skills at their maximum level
	lev = lev or 50
	

	for _, pl in Party do
		for i, learn in EnumAvailableSkills(pl.Class) do
			local skill, mastery = SplitSkill(pl.Skills[i])
			skill = math.max(skill,  30)  -- learn at least the usual needed level
			mastery = math.max(mastery, const.GM)  -- learn the mastery
			pl.Skills[i] = JoinSkill(skill, mastery)
		end
	end

	-- level 200 to all
	for _,pl in Party do
		pl.LevelBase = math.max(pl.LevelBase, 200)
	end
	
	-- clear conditions
	for _, a in Party do
		for i in a.Conditions do
			a.Conditions[i] = 0
		end
	end

	-- full HP, SP
	for _,pl in Party do
		pl.HP = pl:GetFullHP()
		pl.SP = pl:GetFullSP()
	end
	
	Game.NeedRedraw = true
end

function godSkill(lev)
	for _, pl in Party do
		for i, v in pl.Skills do
			local skill = math.max(SplitSkill(v), 10)
			pl.Skills[i] = JoinSkill(skill, const.GM or const.Master)
		end
	end
	-- get all spells
	for _,pl in Party do
		for i in pl.Spells do
			pl.Spells[i] = true
		end
	end
end

-- for _, pl in Party do
-- 	for item, slot in pl:EnumActiveItems() do
-- 		print(dump(item))
-- 	end
-- end


function giveItems()
    for i in Game.ItemsTxt do
		if Game.ItemsTxt[i].Name == "Grand Poleaxr" then
            evt.Add("Inventory",i)
            evt.Add("Inventory",i)
        end
        if Game.ItemsTxt[i].Name == "Golden Plate Armor" then
            evt.Add("Inventory",i)
            evt.Add("Inventory",i)
        end
        if Game.ItemsTxt[i].Name == "Imperial Leather" then
            evt.Add("Inventory",i)
            evt.Add("Inventory",i)
        end
        if Game.ItemsTxt[i].Name == "Stellar Bow" then
            evt.Add("Inventory",i)
            evt.Add("Inventory",i)
			evt.Add("Inventory",i)
            evt.Add("Inventory",i)
        end
        if Game.ItemsTxt[i].Name == "Percival" then
            evt.Add("Inventory",i)
            evt.Add("Inventory",i)
        end
        if Game.ItemsTxt[i].Name == "Merlin" then
            evt.Add("Inventory",i)
            evt.Add("Inventory",i)
        end
        
        if Game.ItemsTxt[i].Name == "Doom's Day Cloak" then
            evt.Add("Inventory",i)
            evt.Add("Inventory",i)
            evt.Add("Inventory",i)
            evt.Add("Inventory",i)
        end
        if Game.ItemsTxt[i].Name == "Angelic Helm" then
            evt.Add("Inventory",i)
            evt.Add("Inventory",i)
            evt.Add("Inventory",i)
            evt.Add("Inventory",i)
        end
        if Game.ItemsTxt[i].Name == "Ultimate Gauntlets" then
            evt.Add("Inventory",i)
            evt.Add("Inventory",i)
            evt.Add("Inventory",i)
            evt.Add("Inventory",i)
        end
        if Game.ItemsTxt[i].Name == "Ultimate Boots" then
            evt.Add("Inventory",i)
            evt.Add("Inventory",i)
            evt.Add("Inventory",i)
            evt.Add("Inventory",i)
        end
		if Game.ItemsTxt[i].Name == "Guinevere" then
			evt.Add("Inventory",i)
            evt.Add("Inventory",i)
		end
		if Game.ItemsTxt[i].Name == "Morgan" then
			evt.Add("Inventory",i)
            evt.Add("Inventory",i)
		end
		if Game.ItemsTxt[i].Name == "Heroic Sword" then
			evt.Add("Inventory",i)
            evt.Add("Inventory",i)
		end
		if Game.ItemsTxt[i].Name == "Scarab Ring"
		then
			evt.Add("Inventory",i)
            evt.Add("Inventory",i)
			evt.Add("Inventory",i)
            evt.Add("Inventory",i)
			evt.Add("Inventory",i)
            evt.Add("Inventory",i)

			evt.Add("Inventory",i)
            evt.Add("Inventory",i)
			evt.Add("Inventory",i)
            evt.Add("Inventory",i)
			evt.Add("Inventory",i)
            evt.Add("Inventory",i)

			evt.Add("Inventory",i)
            evt.Add("Inventory",i)
			evt.Add("Inventory",i)
            evt.Add("Inventory",i)
			evt.Add("Inventory",i)
            evt.Add("Inventory",i)

			evt.Add("Inventory",i)
            evt.Add("Inventory",i)
			evt.Add("Inventory",i)
            evt.Add("Inventory",i)
			evt.Add("Inventory",i)
            evt.Add("Inventory",i)
		end

    end
    -- print(dump(const))
end

function enchantItems()
	for _, pl in Party do
		for item, slot in pl:EnumActiveItems() do
			-- bow
			if item.BodyLocation == 3 then
				item.Bonus2 = 41
			end
			-- main hand including 2handed
			if item.BodyLocation == 2 then
				item.Bonus2 = 41
			end
			-- 11 -> 16 are rings
			if (item.BodyLocation == 11) then
				item.Bonus2 = 38
			end
			if (item.BodyLocation == 12) then
				item.Bonus2 = 37
			end
			if (item.BodyLocation == 13) then
				item.Bonus2 = 1
			end
			if (item.BodyLocation == 14) then
				item.Bonus2 = 1
			end
			if (item.BodyLocation == 15) then
				item.Bonus2 = 1
			end
			if (item.BodyLocation == 16) then
				item.Bonus2 = 1
			end
		end
	end
end
