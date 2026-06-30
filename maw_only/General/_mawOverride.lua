function events.BeforeLoadMap()
    if Map.Name == "housedecent.blv" or Map.Name == "housefine.blv" then
        if vars.MapStatOfMapBeforeEntering ~= nil then
            Map.MapStatsIndex = vars.MapStatOfMapBeforeEntering
        end
    end
end
