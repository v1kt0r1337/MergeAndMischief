--[[


TODO: 

    Should: Add goblin npcs to replace npcs killed in the questline.

    could add a recruitable player for each faction at the end.

    Ideally (not feasible): change decenthouse.blv to a proper room deserving of Goblinwatch

    could: Tune the goblin attack on New Sorpigal.

    could: Make Nilbog, Farmer Todd or Samson Tess drop something more interesting?

    -- ReloadHouse(id) can be used to reload a house if needed

    Suggestion inspired by Kromzinger: add new topic to Lord Nilbog
    "Lord Nilbog"
    "I have many names. Here I am known as Lord Nilbog, but some know me as Grognard or Grognard the Sixth

    BUT is Grognard in mm7 referred to as Grognard the Seventh or Grognard? According to sources he is referred to as Grognard, will be too confusing.


        Safe NPC List: [
        111 (Harry Merit, 100% safe),
        836 (Hector Dragged, 100% safe)
        850 (Saad Shamel, 100% safe)
        id: 399 -> 405 looks completely safe, but check them out
    ]

    Urok and Samson Tess are both completely safe in the context of Goblinwatch quest, but should not be used elsewhere.

]] --   
local decenthouseMapName = "decenthouse.blv"

function events.CanCastTownPortal(t)
    if Map.Name == decenthouseMapName then
        t.CanCast = false
        Sleep(1)
        Game.ShowStatusText("Can't teleport now")
    end
end

function events.CanCastLloyd(t)
    if Map.Name == decenthouseMapName then
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
