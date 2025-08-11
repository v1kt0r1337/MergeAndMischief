--[[
I made the overrides in this file instead of adding them in the respective map files to make the mod more self-contained and compatible with other mods
]]
local NewSorpigal = "oute3.odm"
local decenthouseMapName = "decenthouse.blv"

local SamsonTessNPC_ID = 828
local UrokNPC_ID = 1081
local NilbogNPC_ID = 1239

local goblinwatchHouse = 1463
local houseBehindGoblinwatch = 1413

local Quest_Goblinwatch2 = "Quest_Goblinwatch2"
local Quest_Goblinwatch3 = "Quest_Goblinwatch3"
local Quest_Goblinwatch4 = "Quest_Goblinwatch4"

local MakeGoblinsFriendly
local MakeGoblinsHostile


function PlaceNPCsInNewSorpigal()
    if vars.Quests[Quest_Goblinwatch2] ~= 'Done' and Game.NPC[UrokNPC_ID].House == 0 then
        Game.NPC[UrokNPC_ID].House = houseBehindGoblinwatch
    end

    if vars.SamsonTessDead then
        Game.NPC[SamsonTessNPC_ID].House = 0
    end

    if vars.Quests[Quest_Goblinwatch2] == 'Done' then
        Game.NPC[UrokNPC_ID].House = goblinwatchHouse
    end

    if vars.FarmerToddDead then
        Game.NPC[NilbogNPC_ID].House = goblinwatchHouse
    end

    if vars.LordNilbogDead then
        Game.NPC[NilbogNPC_ID].House = 0
        Game.NPC[UrokNPC_ID].House = houseBehindGoblinwatch
    end
end

function events.AfterLoadMap(WasInGame)
    if Map.Name == NewSorpigal then
        PlaceNPCsInNewSorpigal()
        if vars.NewSorpigalGoblinsFriendly then
            MakeGoblinsFriendly()
        end
    end

 end

MakeGoblinsFriendly = function()
    local goblinId = 550
    local goblinMon = (goblinId + 2):div(3)
    Game.HostileTxt[goblinMon][0] = 0
end

MakeGoblinsHostile = function()
    -- Make goblins hostile
    local goblinId = 550
    local goblinMon = (goblinId + 2):div(3)
    Game.HostileTxt[goblinMon][0] = 4
end
