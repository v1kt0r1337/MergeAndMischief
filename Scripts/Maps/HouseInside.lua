local H = HouseInside

function events.LoadMapScripts()
    H.EnsureLayoutFacetRoles()

    for _, facetId in ipairs(H.HiddenByDefault) do
        HideFacet(facetId)
    end
    MakeInvisibleFacetsPassable()
end
