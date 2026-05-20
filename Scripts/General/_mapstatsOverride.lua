function events.BeforeLoadMap()
    if Map.Name == "decenthouse.blv" then
        if vars.MapStatOfMapBeforeEntering ~= nil then
            -- sets the MapStatsIndex to the index of the map party entered from. 
            Map.MapStatsIndex = vars.MapStatOfMapBeforeEntering
        end
    end
end
function events.LeaveMap()
    if Map.Name == "decenthouse.blv" then
        vars.decentHousePurpose = nil
        -- removes all monsters in the map for later reuse
        for _, m in Map.Monsters do
            m.AIState = const.AIState.Removed
        end
        Map.LastRefillDay = 0
    end
end