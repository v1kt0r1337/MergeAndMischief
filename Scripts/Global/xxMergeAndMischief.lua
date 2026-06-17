-- This file is for late overrides and global events that must apply after the other global scripts have loaded.
local decenthouseMapName = "decenthouse.blv"

local function IsPrinceOfThievesTeleportBlocked()
    return type(PrinceOfThievesPrisonEscapeAnchored) == "function" and PrinceOfThievesPrisonEscapeAnchored() == true
end

function events.CanCastTownPortal(t)
    if Map.Name == decenthouseMapName or IsPrinceOfThievesTeleportBlocked() then
        t.CanCast = false
        Sleep(1)
        Game.ShowStatusText("Can't teleport now")
    end
end

function events.CanCastLloyd(t)
    if Map.Name == decenthouseMapName or IsPrinceOfThievesTeleportBlocked() then
        t.Result = false
        Sleep(1)
        Game.ShowStatusText("Can't teleport now")
    end
end

function EnterDecentHouseMap(purpose)
    evt.PlaySound(6)
    vars.MapStatOfMapBeforeEntering = Map.MapStatsIndex
    vars.decentHousePurpose = purpose
    evt.MoveToMap {
        Name = decenthouseMapName,
        Direction = 1000
    }
end

function events.CanSaveGame(t)
    if Map.Name == decenthouseMapName then
        if t.SaveKind ~= 1 then
            Game.ShowStatusText("Can't save here")
        end
        t.Result = false
    end
end
