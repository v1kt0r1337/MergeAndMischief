-- This file is for late overrides and global events that must apply after the other global scripts have loaded.

local function IsPrinceOfThievesTeleportBlocked()
    return type(PrinceOfThievesPrisonEscapeAnchored) == "function" and PrinceOfThievesPrisonEscapeAnchored() == true
end

function events.CanCastTownPortal(t)
    if HouseInside.IsMap(Map.Name) or IsPrinceOfThievesTeleportBlocked() then
        t.CanCast = false
        Sleep(1)
        Game.ShowStatusText("Can't teleport now")
    end
end

function events.CanCastLloyd(t)
    if HouseInside.IsMap(Map.Name) or IsPrinceOfThievesTeleportBlocked() then
        t.Result = false
        Sleep(1)
        Game.ShowStatusText("Can't teleport now")
    end
end

function EnterHouseInsideMap(purpose)
    evt.PlaySound(6)
    vars.MapStatOfMapBeforeEntering = Map.MapStatsIndex
    vars.HouseInsidePurpose = purpose
    evt.MoveToMap {
        Name = HouseInside.MapName,
        Direction = 1000,
        X = 280,
        Y = 63,
        Z = -159,
    }
end

function EnterDecentHouseMap(purpose)
    EnterHouseInsideMap(purpose)
end

function EnterHouseFineMap(purpose)
    EnterHouseInsideMap(purpose)
end

function EnterhouseInteriorMap(purpose)
    EnterHouseInsideMap(purpose)
end

function EnterHouseInteriorMap(purpose)
    EnterHouseInsideMap(purpose)
end

function events.CanSaveGame(t)
    if HouseInside.IsMap(Map.Name) then
        if t.SaveKind ~= 1 then
            Game.ShowStatusText("Can't save here")
        end
        t.Result = false
    end
end
