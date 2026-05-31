local frozenHighlands = "outc1.odm"
local princeThievesNPC_ID = 802
local prisonHouse = 1463

local princeOfThievesQuestLine = "PrinceOfThieves"

local function PlacePrinceInPrison()
    Game.NPC[princeThievesNPC_ID].House = prisonHouse
end

local function RemovePrinceFromPrison()
    if Game.NPC[princeThievesNPC_ID].House == prisonHouse then
        Game.NPC[princeThievesNPC_ID].House = 0
    end
end

RegisterSharedHouseUse {
    Key = "PrinceOfThievesFrozenHighlandsPrison",
    QuestLine = princeOfThievesQuestLine,
    Map = frozenHighlands,
    House = prisonHouse,
    Event = 501,
    Model = 1,
    Facet = 53,
    Hint = "Prison",
    RestoreHouseOccupants = true,
    RestoreHouseState = function()
        RestoreGoblinwatchNativeHouseOccupants()
    end,
    Setup = function()
        PlacePrinceInPrison()
    end,
    Cleanup = function()
        RemovePrinceFromPrison()
    end
}

function events.AfterLoadMap()
    if Map.Name == frozenHighlands then
        RemovePrinceFromPrison()
    end
end

function events.LeaveMap()
    if Map.Name == frozenHighlands then
        RemovePrinceFromPrison()
    end
end
