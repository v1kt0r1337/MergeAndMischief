--[[
zzMaw-Map.lua
--needed for chest/objects loot
function events.BeforeLoadMap()
	if Map.Name == "housedecent.blv" then return end
]]--

function events.CalcDamageToMonster(t)
    local NewSorpigal = "oute3.odm"
    if Map.Name == NewSorpigal then
        local masterSwordsmanId = 588
        if Game.MonstersTxt[t.Monster.Id].Name == "Farmer Todd" and t.Monster.HP > 0 and (t.Monster.HP == t.Monster.FullHP or t.Monster.FullHP ~= Game.MonstersTxt[masterSwordsmanId].FullHP) then
            -- if players opens a menu/talks to Farmer Todd, his power is restored to that of a peasant this section fixes that.
            local hpRatio  = t.Monster.HP / t.Monster.FullHP 
            Quest_TheGoblinsStrikeBack2_CreateTodd(t.Monster)
            t.Monster.HP = math.max(1, math.floor(t.Monster.FullHP * hpRatio))
            -- Ensure that Farmer Todd is not invulnerable and this condition only triggers if necessary
            if t.Damage > 0 then
                t.Result = t.Damage
            else
                t.Result = 1
            end
        end
        local guardId = 553
        if vars.Quests["Quest_TheGoblinsStrikeBack3"] == "Given" and (t.Monster.Id == guardId or t.Monster.Id == guardId+1 or t.Monster.Id == guardId+2) then
            t.Result = t.Damage
        end
    end

    if Map.Name == "housefine.blv" then
        -- Hack to prevent MAW making Lord Nilbog weak as a normal goblin, might still not be properly bolstered
        local ogreChieftainId = 594 
        if Game.MonstersTxt[t.Monster.Id].Name == "Lord Nilbog" and t.Monster.HP > 0 and (t.Monster.HP == t.Monster.FullHP or t.Monster.FullHP ~= Game.MonstersTxt[ogreChieftainId].FullHP) then
            local hpRatio  = t.Monster.HP / t.Monster.FullHP 
            Quest_TheGoblinsStrikeBack4_MonsterLordNilbog(t.Monster)
            t.Monster.HP = math.max(1, math.floor(t.Monster.FullHP * hpRatio))
            -- Ensure that this only happens if needed
            if t.Result < 1 then
                t.Result = 1
            end
        end
    end
end
