function HideFacet(facetId)
    local removedCount = 0

    for _, f in Map.Facets do
        local d = f:GetData()
        if d and d.Id == facetId then
            f.Invisible = true
            f.Untouchable = true
            removedCount = removedCount + 1
        end
    end

    return removedCount
end

function ShowFacet(facetId)
    local showCount = 0

    for _, f in Map.Facets do
        local d = f:GetData()
        if d and d.Id == facetId then
            f.Invisible = false
            f.Untouchable = false
            showCount = showCount + 1
        end
    end

    return showCount
end

function MakeInvisibleFacetsPassable()
    local changedCount = 0

    for _, f in Map.Facets do
        if f.Invisible and (not f.Untouchable) then
            f.Untouchable = true
            changedCount = changedCount + 1
        end
    end

    return changedCount
end

local function LoadFacetBitmap(textureName)
    local bitmapId = Game.BitmapsLod:LoadBitmap(textureName)
    Game.BitmapsLod.Bitmaps[bitmapId]:LoadBitmapPalette()
    return bitmapId
end

local function SetFacetBitmap(facet, bitmapId)
    facet.BitmapId = bitmapId
    local data = facet:GetData()
    if data then
        data.BitmapIndex = bitmapId
    end
end

function SetFacetTexture(facet, textureName)
    if facet == nil or textureName == nil then
        return false
    end

    SetFacetBitmap(facet, LoadFacetBitmap(textureName))
    return true
end

function ReplaceFacetTexture(fromName, toName)
    local fromId = Game.BitmapsLod:LoadBitmap(fromName)
    local toId = LoadFacetBitmap(toName)

    local changedCount = 0
    for _, f in Map.Facets do
        if f.BitmapId == fromId then
            SetFacetBitmap(f, toId)
            changedCount = changedCount + 1
        end
    end

    return changedCount
end

function ReplaceFacetTextureById(facetId, toName)
    local toId = LoadFacetBitmap(toName)

    local changedCount = 0
    for _, f in Map.Facets do
        local data = f:GetData()
        if data and data.Id == facetId then
            SetFacetBitmap(f, toId)
            changedCount = changedCount + 1
        end
    end

    return changedCount
end
