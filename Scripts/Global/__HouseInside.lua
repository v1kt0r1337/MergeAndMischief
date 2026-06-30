HouseInside = HouseInside or {}
HouseInside.MapName = "HouseInside.blv"
HouseInside.MapKey = HouseInside.MapName:lower()
HouseInside.Door = 1
HouseInside.Cabinet = 2
HouseInside.Chest = 3
HouseInside.LordBed = 4
HouseInside.Bed = 5
HouseInside.StrawBed1 = 6
HouseInside.StrawBed2 = 7
-- This is used if we want to wire up a double door
HouseInside.FacetLeftToDoor = 8

HouseInside.HiddenByDefault = {
    HouseInside.Cabinet,
    HouseInside.Chest,
    HouseInside.LordBed,
    HouseInside.Bed,
    HouseInside.StrawBed1,
    HouseInside.StrawBed2,
}
HouseInside.ContainerChestIds = {
    Cabinet = 0,
    Chest = 1,
}
HouseInside.ContainerByFacet = {
    [HouseInside.Cabinet] = {
        ChestId = HouseInside.ContainerChestIds.Cabinet,
        Hint = "Cabinet",
        ChestPicture = 0,
    },
    [HouseInside.Chest] = {
        ChestId = HouseInside.ContainerChestIds.Chest,
        Hint = "Chest",
        ChestPicture = 1,
    },
}
HouseInside.RoomLoadouts = HouseInside.RoomLoadouts or {}
HouseInside.DefaultLayoutTextures = {
    Door = "pgstrdr",
    Wall = "D1WlBctr",
    WallCornerRight = "D1wlbre1",
    WallCornerLeft = "D1wlble1",
    Floor = "d1trimLE",
    Ceiling1 = "D2ceil1",
    Ceiling2 = "D2ceil2",
}
HouseInside.LayoutTexturePacks = {
    -- GoblinwatchAppartement = {
    --     LeftDoor = "T05a03c",
    --     RightDoor = "T05a03d",
    -- },

    CleanStoneSlightlyEvil = {
        Wall = "t05a01A",
        WallCornerLeft = "t05a01A",--"T05a06a",
        WallCornerRight = "t05a01A", --"T05a06b",
        LeftDoor = "T05a03c",
        RightDoor = "T05a03d",
        Floor = "d1trimLE", -- "GStnBOT"
        Ceiling1 = "D2ceil1",
        Ceiling2 = "D2ceil2",
    },
    -- Floor looks slightly off, the room could be used for some holy person.
    NiceWallPaneling = {
        Wall = "grBas1",
        Floor = "grCeil",
        LeftDoor = "grDor1a",
        RightDoor = "grDor1b",
        Ceiling1 = "D2ceil1",
        Ceiling2 = "D2ceil2",
    },
    PoorLayout = {
        Door = "Gkp103a",
        -- LeftOfDoor = "Gkp112a",
        WallCornerLeft = "GKp1-Lt",
        WallCornerRight = "GKp1-Rt",
        Wall = "Gkp1-Tt",
        Floor = "Gkp1flr", --"Gkp1-bs1"
        Ceiling1 = "Gkp1ceil"
    },
    -- looks a bit off, perhaps too light?
    NiceStone = {
        Wall = "t1wl1cts",
        WallCornerLeft = "t1wl1lea",
        WallCornerRight = "t1wl1rea",
        Door = "t1d3",
        Ceiling1 = "t1wl0sm",
        Floor = "t1wl0lg",
    }
}
HouseInterior = HouseInside

function HouseInside.IsMap(mapName)
    return type(mapName) == "string" and mapName:lower() == HouseInside.MapKey
end

local function HasChest(chestId)
    return chestId >= 0 and chestId < Map.Chests.Count
end

local function WireContainer(facetId, container)
    Game.MapEvtLines:RemoveEvent(facetId)
    evt.hint[facetId] = container.Hint
    evt.map[facetId] = function()
        evt.OpenChest{container.ChestId}
    end
end

local function WireFacetToDoorEvent(facetId)
    local changedCount = 0

    for _, f in Map.Facets do
        local data = f:GetData()
        if data and data.Id == facetId then
            data.Event = HouseInside.Door
            f.TriggerByClick = true
            changedCount = changedCount + 1
        end
    end

    return changedCount
end

local function NormalizeTextureName(textureName)
    return type(textureName) == "string" and textureName:lower() or nil
end

-- By building defaults its easier to swap between multiple textures at runtime
local function BuildDefaultLayoutRoleByTexture()
    local defaults = HouseInside.DefaultLayoutTextures
    return {
        [NormalizeTextureName(defaults.Wall)] = "Wall",
        [NormalizeTextureName(defaults.WallCornerLeft)] = "WallCornerLeft",
        [NormalizeTextureName(defaults.WallCornerRight)] = "WallCornerRight",
        [NormalizeTextureName(defaults.Floor)] = "Floor",
        [NormalizeTextureName(defaults.Ceiling1)] = "Ceiling1",
        [NormalizeTextureName(defaults.Ceiling2)] = "Ceiling2",
    }
end

local function GetFacetTextureName(facet)
    local bitmap = Game.BitmapsLod.Bitmaps[facet.BitmapId]
    return bitmap and bitmap.Name or nil
end

-- Cache default layout roles so texture packs can be swapped repeatedly.
-- Cache contains map with Facet index as key and layout role as value
-- [0] = "Wall"
-- [1] = "Floor"
-- [2] = "Wall"
local function EnsureLayoutFacetRoles()
    if mapvars.HouseInsideLayoutFacetRoles ~= nil then
        return mapvars.HouseInsideLayoutFacetRoles
    end

    local roleByTexture = BuildDefaultLayoutRoleByTexture()
    local facetRoles = {}
    for i, facet in Map.Facets do
        local role = roleByTexture[NormalizeTextureName(GetFacetTextureName(facet))]
        if role ~= nil then
            facetRoles[i] = role
        end
    end

    mapvars.HouseInsideLayoutFacetRoles = facetRoles
    return facetRoles
end

function HouseInside.EnsureLayoutFacetRoles()
    return EnsureLayoutFacetRoles()
end

local function GetLayoutTextureForRole(pack, role)
    if role == "WallCornerLeft" then
        return pack.WallCornerLeft or pack.Wall
    end
    if role == "WallCornerRight" then
        return pack.WallCornerRight or pack.Wall
    end
    if role == "Ceiling2" then
        return pack.Ceiling2 or pack.Ceiling1
    end

    return pack[role]
end

local function ApplyLayoutFacetTextures(pack)
    local changedCount = 0
    local facetRoles = EnsureLayoutFacetRoles()

    for facetIndex, role in pairs(facetRoles) do
        local textureName = GetLayoutTextureForRole(pack, role)
        if textureName ~= nil and SetFacetTexture(Map.Facets[facetIndex], textureName) then
            changedCount = changedCount + 1
        end
    end

    return changedCount
end

local function EnsureContainer(facetId)
    local container = HouseInside.ContainerByFacet[facetId]
    if container == nil then
        return
    end

    local chestId = container.ChestId
    if not HasChest(chestId) then
        Map.Chests.Count = chestId + 1
        mem.fill(Map.Chests[chestId])
    end

    Map.Chests[chestId].ChestPicture = container.ChestPicture
    WireContainer(facetId, container)
end

function HouseInside.ShowFacets(...)
    for _, facetId in ipairs({...}) do
        ShowFacet(facetId)
        EnsureContainer(facetId)
    end
end

local function ChestHasItems(chest)
    for _, item in chest.Items do
        if item.Number ~= 0 then
            return true
        end
    end
    return false
end

local function SeedChestWithRandomItems(chest, itemLevel)
    for i = 1, 3 do
        chest.Items[i].Number = -itemLevel
    end
    chest.ItemsPlaced = false
end

function HouseInside.UpgradeChests(itemLevel, mapvarsKey)
    if mapvarsKey ~= nil and mapvars[mapvarsKey] == true then
        return
    end

    local generatedRandomItems = false
    for _, container in pairs(HouseInside.ContainerByFacet) do
        if HasChest(container.ChestId) then
            local chest = Map.Chests[container.ChestId]
            if not ChestHasItems(chest) then
                SeedChestWithRandomItems(chest, itemLevel)
                generatedRandomItems = true
            end
        end
    end

    if generatedRandomItems then
        Game.GenerateChests()
    end

    for _, container in pairs(HouseInside.ContainerByFacet) do
        if HasChest(container.ChestId) then
            local chest = Map.Chests[container.ChestId]
            for _, item in chest.Items do
                if item.Number > 0 then
                    local itemType = item:T().EquipStat + 1
                    if itemType ~= const.ItemType.MScroll and itemType <= const.ItemType.Gold then
                        item:Randomize(itemLevel, itemType)
                    end
                end
            end
        end
    end

    if mapvarsKey ~= nil then
        mapvars[mapvarsKey] = true
    end
end

-- HouseInside.ApplyLayoutTexturePack("NiceStone")
-- HouseInside.ApplyLayoutTexturePack("LayoutPack2")
-- HouseInside.ApplyLayoutTexturePack("PoorLayout")
function HouseInside.ApplyLayoutTexturePack(layoutPack)
    local pack = layoutPack
    if type(layoutPack) == "string" then
        pack = HouseInside.LayoutTexturePacks[layoutPack]
    end
    if pack == nil then
        return nil, "missing layout texture pack"
    end

    ApplyLayoutFacetTextures(pack)

    local rightDoor = pack.RightDoor or pack.RigthDoor or pack.Door
    if pack.LeftDoor ~= nil then
        ReplaceFacetTextureById(HouseInside.FacetLeftToDoor, pack.LeftDoor)
        WireFacetToDoorEvent(HouseInside.FacetLeftToDoor)
        ReplaceFacetTextureById(HouseInside.Door, rightDoor or pack.LeftDoor)
    elseif pack.LeftOfDoor ~= nil then
        ReplaceFacetTextureById(HouseInside.FacetLeftToDoor, pack.LeftOfDoor)
        if rightDoor ~= nil then
            ReplaceFacetTextureById(HouseInside.Door, rightDoor)
        end
    elseif rightDoor ~= nil then
        ReplaceFacetTextureById(HouseInside.Door, rightDoor)
    end

    return true
end

function HouseInside.ApplyRoomLoadout(loadout, tweaks)
    tweaks = tweaks or {}

    if loadout.LayoutTexturePack then
        HouseInside.ApplyLayoutTexturePack(loadout.LayoutTexturePack)
    end

    if loadout.Textures then
        for fromName, toName in pairs(loadout.Textures) do
            ReplaceFacetTexture(fromName, toName)
        end
    end

    if loadout.Facets then
        HouseInside.ShowFacets(unpack(loadout.Facets))
    end

    if loadout.ChestPictures then
        for chestId, pictureId in pairs(loadout.ChestPictures) do
            if HasChest(chestId) then
                Map.Chests[chestId].ChestPicture = pictureId
            end
        end
    end

    if tweaks.Show then
        HouseInside.ShowFacets(unpack(tweaks.Show))
    end

    if tweaks.Hide then
        for _, facetId in ipairs(tweaks.Hide) do
            HideFacet(facetId)
        end
    end
end

--[[ 
Default loadout used inside HouseInside.blv

Facet textureNames:
door "pgstrdr" 
wall "D1WlBctr"
wallCornerRight "D1wlbre1"
WallCornerLeft  "D1wlble1"
floor "d1trimLE"
ceiling1 "D2ceil1"
ceiling2 "D2ceil2"
--]]

--[[ 

metaldoor d8dorf
poorDoor d3rsml hhm3d d2smldor
sturdyDoor tdoorc

potential double door Gkp103a Gkp103b
]]

--[[
Interesting layout?
WallCornerLeft "7twb2el"
WallCornerRight "7twb2er"
Wall 7tws2

Floor "tfs1"
--]]


--[[
LayoutPack1
Wall: grBas3
Floor: grCeil
LeftDoor: grDor1a
RigthDoor: grDor1b
]]

--[[
LayoutPack2
Wall: t05a01A or T05a01c
WallCornerLeft T05a06a
WallCornerRight T05a06b
LeftDoor: T05a03c
RightDoor: T05a03d
]]
