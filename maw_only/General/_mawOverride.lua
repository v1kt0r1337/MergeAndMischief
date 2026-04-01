function events.BeforeLoadMap()
    if Map.Name == "decenthouse.blv" then
        if vars.MapStatOfMapBeforeEntering ~= nil then
            Map.MapStatsIndex = vars.MapStatOfMapBeforeEntering
        end
    end
end