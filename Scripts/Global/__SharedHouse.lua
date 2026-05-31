-- Shared reusable 2D house entrance registry for Merge and Mischief.

local SharedHouseUses = {}
local SharedHouseUsesByKey = {}
local SharedHouseOwnersByMapHouse = {}

local SharedHouseUseKey
local SharedHouseUseOwner
local FindSharedHouseUse
local ValidateSharedHouseUse
local CaptureSharedHouseRestore
local RestoreSharedHouseNPCs
local EnterSharedHouseUse
local ApplySharedHouseUse

-- Registers a controlled reusable 2D house entrance for one map.
--
-- Required fields:
--   Key: unique name for this entrance/use, used by IsSharedHouseContext.
--   QuestLine, Owner, or Quest: normalized into Owner. This is the conflict boundary.
--   Map: The map where this house use belongs, such as "outc1.odm".
--   House: 2D house id to reserve/use.
--
-- Optional fields:
--   Quest: specific quest/stage using this entrance; useful metadata when Owner is a questline.
--   Event: map event id used when wiring a clickable entrance.
--   Hint: custom door/status text for the event. Defaults to the house name.
--   Model and Facet: outdoor facet to mark as clickable. Provide both or neither.
--   RemoveMapEvent: true when replacing an existing vanilla map event id.
--   CanEnter(use): return false to block entry.
--   RestoreHouseOccupants: true snapshots NPC house state, hides current occupants
--      of House during Setup, and restores temporary occupants during Cleanup.
--   RestoreNPCs: extra NPC ids to include in the restore snapshot.
--   RestoreHouseState(use, context): called after automatic restore; use this to
--      reapply native quest progression for houses with vanilla occupants.
--   Setup(use, context): called before evt.EnterHouse.
--   Cleanup(use, context): called from ExitHouseScreen when leaving this house context.
--
-- One house ID may be reused across many maps, but only one Owner can control a
-- given Map + House pair. Multiple files in the same questline should use the
-- same Owner/QuestLine and different Keys when needed.
-- Quest scripts should guard NPC/dialog logic with IsSharedHouseContext(...).
function RegisterSharedHouseUse(use)
    ValidateSharedHouseUse(use)

    use.Owner = SharedHouseUseOwner(use)

    local mapHouseKey = SharedHouseUseKey(use.Map, use.House)
    local existingOwner = SharedHouseOwnersByMapHouse[mapHouseKey]
    if existingOwner ~= nil and existingOwner ~= use.Owner then
        error(string.format("Shared house conflict on %s house %s: owner '%s' already registered, refused '%s' (%s)",
            use.Map, tostring(use.House), existingOwner, use.Owner, use.Key), 2)
    end

    local registrationKey = table.concat({use.Map, tostring(use.House), tostring(use.Event or ""), use.Key}, ":")
    if SharedHouseUsesByKey[registrationKey] == nil then
        table.insert(SharedHouseUses, use)
        SharedHouseUsesByKey[registrationKey] = use
        SharedHouseOwnersByMapHouse[mapHouseKey] = use.Owner
    end

    return use
end

function GetSharedHouseContext()
    return vars.SharedHouseContext
end

function IsSharedHouseContext(key, mapName, houseId)
    local context = vars.SharedHouseContext
    if type(context) ~= "table" then
        return false
    end
    if key ~= nil and context.Key ~= key then
        return false
    end
    if mapName ~= nil and context.Map ~= mapName then
        return false
    end
    if houseId ~= nil and context.House ~= houseId then
        return false
    end
    return true
end

function ClearSharedHouseContext()
    local context = vars.SharedHouseContext
    local use = FindSharedHouseUse(context)

    RestoreSharedHouseNPCs(use, context)

    if use ~= nil and type(use.RestoreHouseState) == "function" then
        use.RestoreHouseState(use, context)
    end

    if use ~= nil and type(use.Cleanup) == "function" then
        use.Cleanup(use, context)
    end

    vars.SharedHouseContext = nil
end

function PrintSharedHouseUses()
    for _, use in ipairs(SharedHouseUses) do
        print(string.format("%s questline=%s quest=%s map=%s house=%s event=%s model=%s facet=%s",
            use.Key, use.Owner, tostring(use.Quest), use.Map, tostring(use.House), tostring(use.Event),
            tostring(use.Model), tostring(use.Facet)))
    end
end

function events.LoadMapScripts()
    for _, use in ipairs(SharedHouseUses) do
        ApplySharedHouseUse(use)
    end
end

function events.ExitHouseScreen()
    local context = vars.SharedHouseContext
    if type(context) == "table" and Game.GetCurrentHouse() == context.House then
        ClearSharedHouseContext()
    end
end

SharedHouseUseKey = function(mapName, houseId)
    return tostring(mapName) .. ":" .. tostring(houseId)
end

SharedHouseUseOwner = function(use)
    return use.QuestLine or use.Owner or use.Quest
end

FindSharedHouseUse = function(context)
    if type(context) ~= "table" then
        return nil
    end

    for _, use in ipairs(SharedHouseUses) do
        if use.Key == context.Key and use.Map == context.Map and use.House == context.House then
            return use
        end
    end

    return nil
end

ValidateSharedHouseUse = function(use)
    if type(use) ~= "table" then
        error("RegisterSharedHouseUse expects a table", 3)
    end
    if type(use.Key) ~= "string" or use.Key == "" then
        error("RegisterSharedHouseUse requires Key", 3)
    end
    if type(use.Map) ~= "string" or use.Map == "" then
        error("RegisterSharedHouseUse requires Map", 3)
    end
    if type(SharedHouseUseOwner(use)) ~= "string" or SharedHouseUseOwner(use) == "" then
        error("RegisterSharedHouseUse requires QuestLine, Owner, or Quest", 3)
    end
    if type(use.House) ~= "number" then
        error("RegisterSharedHouseUse requires numeric House", 3)
    end
    if use.Event ~= nil and type(use.Event) ~= "number" then
        error("RegisterSharedHouseUse requires numeric Event when Event is provided", 3)
    end
    if (use.Model == nil) ~= (use.Facet == nil) then
        error("RegisterSharedHouseUse requires both Model and Facet, or neither", 3)
    end
    if use.Model ~= nil and use.Event == nil then
        error("RegisterSharedHouseUse requires Event when Model and Facet are provided", 3)
    end
    if use.RestoreNPCs ~= nil and type(use.RestoreNPCs) ~= "table" then
        error("RegisterSharedHouseUse requires RestoreNPCs to be a table when provided", 3)
    end
end

CaptureSharedHouseRestore = function(use, context)
    if use.RestoreHouseOccupants ~= true and use.RestoreNPCs == nil then
        return
    end

    local restore = {
        House = use.House,
        NPCs = {},
        HiddenNPCs = {},
    }

    local function snapshotNPC(npcId)
        if type(npcId) ~= "number" or restore.NPCs[npcId] ~= nil then
            return
        end

        local npc = Game.NPC[npcId]
        if npc ~= nil then
            restore.NPCs[npcId] = npc.House
        end
    end

    if use.RestoreHouseOccupants == true then
        for npcId, npc in Game.NPC do
            snapshotNPC(npcId)
            if npc.House == use.House then
                restore.HiddenNPCs[npcId] = true
                npc.House = 0
            end
        end
    end

    for _, npcId in ipairs(use.RestoreNPCs or {}) do
        snapshotNPC(npcId)
    end

    context.HouseRestore = restore
end

RestoreSharedHouseNPCs = function(use, context)
    if use == nil or type(context) ~= "table" or type(context.HouseRestore) ~= "table" then
        return
    end

    local restore = context.HouseRestore
    if type(restore.NPCs) ~= "table" then
        return
    end

    for npcId, oldHouse in pairs(restore.NPCs) do
        local npc = Game.NPC[npcId]
        if npc ~= nil then
            local wasHiddenBySharedHouse = restore.HiddenNPCs and restore.HiddenNPCs[npcId] == true and npc.House == 0
            local isTemporaryHouseOccupant = npc.House == restore.House

            if wasHiddenBySharedHouse or isTemporaryHouseOccupant then
                npc.House = oldHouse
            end
        end
    end
end

EnterSharedHouseUse = function(use)
    if type(use.CanEnter) == "function" and use.CanEnter(use) == false then
        return
    end

    local context = {
        Key = use.Key,
        Map = use.Map,
        Quest = use.Quest,
        QuestLine = use.QuestLine,
        Owner = use.Owner,
        House = use.House,
        Event = use.Event,
        MapStatsIndex = Map.MapStatsIndex,
    }

    vars.SharedHouseContext = context
    CaptureSharedHouseRestore(use, context)

    if type(use.Setup) == "function" then
        use.Setup(use, context)
    end

    evt.EnterHouse{use.House}
end

ApplySharedHouseUse = function(use)
    if Map.Name ~= use.Map then
        return
    end
    if use.Event == nil then
        return
    end

    if use.RemoveMapEvent == true then
        Game.MapEvtLines:RemoveEvent(use.Event)
    end

    if use.Model ~= nil and use.Facet ~= nil then
        local model = Map.Models and Map.Models[use.Model] or nil
        local facet = model and model.Facets and model.Facets[use.Facet] or nil
        if facet == nil then
            error(string.format("Shared house use '%s' could not find model %s facet %s on %s",
                use.Key, tostring(use.Model), tostring(use.Facet), tostring(Map.Name)))
        end

        facet.Event = use.Event
        facet.TriggerByClick = true
    end

    evt.house[use.Event] = use.House
    if type(use.Hint) == "string" then
        evt.hint[use.Event] = use.Hint
    end
    evt.map[use.Event] = function()
        EnterSharedHouseUse(use)
    end
end
