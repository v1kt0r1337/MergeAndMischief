local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5

local FreeHaven = "outc2.odm"
local HouseID = 1559
local Quest_KillMatronOfOrphanage = "Quest_KillMatronOfOrphanage"
local Quest_FeedChildrenOfOrphanage = "Quest_FeedChildrenOfOrphanage"
local Quest_FaceConsequenceOfOrphanage = "Quest_FaceConsequenceOfOrphanage"

local matronNPC_ID = 111
local child1NPC_ID = 850 -- 850 Saad Shamel
local child2NPC_ID = 836 -- 836 Hector Dragged
local decenthouseMapName = "decenthouse.blv"
local decenthouseExitDoorEventId = 5

local BranchedFightMatronQuest
local SetupNPCs
local EnterOrphanage
local SendPartyBackToOrphanageEntrance
local CreateEnemyMatron
local MatronMonsterID = 598
-- 368680 is 1 day in game time
local ChildrenStarvationTime = 368680 * 1.5

local CreateRevengeGhosts
local ChildrenStarveTimer
-- pic 61 indian fem child
-- pic 62 fem child
-- pic 63 older mischievous child?
-- pic 66 snotty child
-- pic 67 blond fem child
-- pic 71 older fem child
-- pic 72 older snobby child
-- pic 102 asian child
-- pic 158 child bit too happy
-- 277
-- 31

NPCTopic {
    Slot = A,
    NPC = matronNPC_ID,
    CanShow = function()
        return Map.Name == FreeHaven and vars.Quests[Quest_KillMatronOfOrphanage] ~= "Done"
    end,
    Topic = "Matron of the orphanage",
    Text = [[
I am the matron of this orphanage.

The children needs a stern hand. I will not tolerate any mischief or disobedience.]]
}

Greeting {
    NPC = child1NPC_ID,
    Text = "Hilda is mean",
    CanShow = function()
        return Map.Name == FreeHaven and vars.Quests[Quest_KillMatronOfOrphanage] ~= "Done"
    end
}

Quest{
    Quest_KillMatronOfOrphanage,
    Slot = E,
    NPC = child2NPC_ID,
    Give = function()
        evt.PlaySound(205) -- give quest sound
    end,
    CanShow = function()
        return Map.Name == FreeHaven
    end,
    CheckDone = function()
        return vars.MatronOfOrphanageKilled
    end,
    Done = function()
        vars.LastTimeChildrenAte = Game.Time
        evt.PlaySound(205)
        evt.PlaySound(133)
        SetupNPCs()
        ChildrenStarveTimer()
    end
}.SetTexts {
    Topic = "Kill Matron Hildra Briarwood",
    TopicGiven = "Kill Matron Hilda Briarwood",
    TopicDone = "The matron is dead",
    Give = "I hate her. She is always angry and mean. I wish someone would kill her!",
    Undone = "I hate her. She is always angry and mean. I wish someone would kill her!",
    Done = [[
You killed her?

But...

Who will feed us now?]]
}

Greeting {
    NPC = child2NPC_ID,
    Text = "I'm hungry",
    CanShow = function()
        return Map.Name == FreeHaven and vars.Quests[Quest_KillMatronOfOrphanage] == "Done"
    end
}

Greeting {
    NPC = child1NPC_ID,
    Text = "I'm hungry",
    CanShow = function()
        return Map.Name == FreeHaven and vars.Quests[Quest_KillMatronOfOrphanage] == "Done"
    end
}

Quest{
    Quest_FeedChildrenOfOrphanage,
    Slot = E,
    NPC = child2NPC_ID,
    CanShow = function()
        return Map.Name == FreeHaven and vars.Quests[Quest_KillMatronOfOrphanage] == "Done"
    end,
    CheckDone = function()
        if Party.Food > 0 then
            Party.Food = Party.Food - 1
            evt.PlaySound(144) -- eat food sound
            return true
        else
            return false
        end
    end,
    Done = function()
        vars.LastTimeChildrenAte = Game.Time
        -- waits until the player has left the house
        Sleep2(function()
            vars.Quests[Quest_FeedChildrenOfOrphanage] = "Given"
        end, 1, nil, nil)
    end
}.SetTexts {
    Topic = "We are hungry",
    TopicGiven = "Feed",
    TopicDone = "Come back tomorrow",
    Give = "Feed us, we are hungry!",
    Undone = "You don't have any food left.",
    Done = "Thank you. Please come back tomorrow, we will be hungry again."
}

Quest{
    Quest_FaceConsequenceOfOrphanage,
    Slot = E,
    NPC = matronNPC_ID,
    CanShow = function()
        return Map.Name == FreeHaven and vars.orphanChildrenHasStarved and vars.OrphanGhostsKilled == nil
    end,
    CheckDone = function()
        return vars.OrphanGhostsKilled ~= nil
    end,
    Give = function()
        Game.NPC[matronNPC_ID].House = 0
        EnterOrphanage(Quest_FaceConsequenceOfOrphanage)
        vars.Quests[Quest_FaceConsequenceOfOrphanage] = nil
    end,
    Undone = function()
        Game.NPC[matronNPC_ID].House = 0
        EnterOrphanage(Quest_FaceConsequenceOfOrphanage)
        vars.Quests[Quest_FaceConsequenceOfOrphanage] = nil
    end
}.SetTexts {
    Topic = "...",
    TopicGiven = "...",
    Give = "...",
    Undone = "...",
    Done = "..."
}

function events.LeaveMap()
    if Map.Name == FreeHaven and vars.orphanChildrenHasStarved == false then
        RemoveTimer()
    end
end

ChildrenStarveTimer = function()
    Timer(function()
        vars.orphanChildrenHasStarved = true
        SetupNPCs()
        RemoveTimer()
    end, nil, vars.LastTimeChildrenAte + ChildrenStarvationTime, true)
end

CreateRevengeGhosts = function(createAtDoor)
    local ghostId1 = 547
    local ghostId2 = 548
    local ghostId3 = 549

    local ghost1
    local ghost2
    local ghost3

    if createAtDoor then
        ghost1 = SummonMonster(ghostId1, 319, -129, 1, false)
        ghost2 = SummonMonster(ghostId2, 316, -209, 1, false)
        ghost3 = SummonMonster(ghostId3, 309, -279, 1, false)
    else
        ghost1 = SummonMonster(ghostId1, -189, 94, 1, false)
        ghost2 = SummonMonster(ghostId2, -189, -15, 1, false)
        ghost3 = SummonMonster(ghostId3, -189, 130, 1, false)
    end

    Game.MonstersTxt[ghostId1].Name = "Harry"
    Game.MonstersTxt[ghostId2].Name = "Steve"
    Game.MonstersTxt[ghostId3].Name = "Matron Hilda"
    vars.hasSpawnedOrphanGhosts = true
end

local function CreateRevengeSkeletons()
    local skelId1 = 628
    local skelId2 = 629
    local skel1 = SummonMonster(skelId1, -189, 94, 1, false)
    local skel2 = SummonMonster(skelId2, -189, -15, 1, false)
    Game.MonstersTxt[skelId1].Name = "Harry's remains"
    Game.MonstersTxt[skelId2].Name = "Steve's remains"
    skel1.HP = -10
    skel2.HP = -10
    skel1.AIState = const.AIState.Dead
    skel2.AIState = const.AIState.Dead
    skel1:UpdateGraphicState()
    skel2:UpdateGraphicState()
end

function events.PickCorpse(t)
    if Map.Name == decenthouseMapName and vars.decentHousePurpose == Quest_FaceConsequenceOfOrphanage then
        if vars.hasSpawnedOrphanGhosts ~= true and (t.Monster.Id == 628 or t.Monster.Id == 629) then
            CreateRevengeGhosts(true)
        end
    end
end

function events.MonsterSpriteScale(t)
    if Map.Name == decenthouseMapName and vars.decentHousePurpose == Quest_FaceConsequenceOfOrphanage then
        local skelId1 = 628
        local skelId2 = 629
        local ghostId1 = 547
        local ghostId2 = 548
        local ghostId3 = 549
        if t.Monster.Id == skelId1 or t.Monster.Id == skelId2 or t.Monster.Id == ghostId1 or t.Monster.Id == ghostId2 then
            t.Scale = math.floor(t.Scale * 0.6)
        end
    end
end

function events.AfterLoadMap()
    if Map.Name == FreeHaven then
        -- move the previous (unimportant) occupant to the nearby house
        Game.NPC[1156].House = 1560
        if vars.Quests[Quest_KillMatronOfOrphanage] ~= "Done" then
            BranchedFightMatronQuest()
        end
        if vars.Quests[Quest_KillMatronOfOrphanage] == "Done" then
            if Game.Time < vars.LastTimeChildrenAte + ChildrenStarvationTime then
                ChildrenStarveTimer()
            else
                vars.orphanChildrenHasStarved = true
            end
        end
        -- Should be called last as it's impacted by state changes
        SetupNPCs()
    end

    if Map.Name == decenthouseMapName then

        if vars.decentHousePurpose == Quest_KillMatronOfOrphanage then
            local matron = CreateEnemyMatron()

            evt.Map[decenthouseExitDoorEventId] = function()
                if matron.HP > 0 then
                    Game.ShowStatusText(Game.MonstersTxt[matron.Id].Name .. " is blocking your escape!")
                else
                    SendPartyBackToOrphanageEntrance()
                end
            end
        end

        if vars.decentHousePurpose == Quest_FaceConsequenceOfOrphanage then
            vars.orphanChildrenHasStarved = nil
            CreateRevengeSkeletons()
            evt.Map[decenthouseExitDoorEventId] = function()
                if vars.hasSpawnedOrphanGhosts ~= true then
                    CreateRevengeGhosts()
                    return
                end
                if vars.OrphanGhostsKilled ~= nil and vars.OrphanGhostsKilled > 2 then
                    SendPartyBackToOrphanageEntrance()
                end
            end
        end
    end
end

CreateEnemyMatron = function()
    local matron = SummonMonster(MatronMonsterID, -115, 55, 1, true)
    Game.MonstersTxt[MatronMonsterID].Name = "Matron Hilda Briarwood"
    local peasantMon = (MatronMonsterID + 2):div(3)
    Game.HostileTxt[peasantMon][0] = 1
    matron.AIType = 3
    return matron
end

function events.MonsterKilled(mon)
    if Map.Name == decenthouseMapName and Game.MonstersTxt[mon.Id].Name == "Matron Hilda Briarwood" then
        vars.MatronOfOrphanageKilled = true
        Game.NPC[matronNPC_ID].House = 0
        -- RemoveSafeTopicsFromNPC(matronNPC_ID)
    end

    if Map.Name == decenthouseMapName and vars.decentHousePurpose == Quest_FaceConsequenceOfOrphanage then
        local ghostId1 = 547
        local ghostId2 = 548
        local ghostId3 = 549

        if mon.Id == ghostId1 or mon.Id == ghostId2 or mon.Id == ghostId3 then
            vars.OrphanGhostsKilled = (vars.OrphanGhostsKilled or 0) + 1
        end
    end

end

SetupNPCs = function()
    if vars.MatronOfOrphanageKilled ~= true then
        Game.NPC[matronNPC_ID].House = HouseID
        Game.NPC[matronNPC_ID].Pic = 40 -- bytt til 194? 260 perfekt?
        Game.NPC[matronNPC_ID].Name = "Hilda Briarwood"
    end

    if vars.orphanChildrenHasStarved then
        Game.NPC[matronNPC_ID].House = HouseID
        Game.NPC[matronNPC_ID].Pic = 35 -- seer pic -- 1026 skeleton
        Game.NPC[matronNPC_ID].Name = ""
        Game.NPC[child1NPC_ID].House = 0
        Game.NPC[child2NPC_ID].House = 0
    else
        Game.NPC[child1NPC_ID].House = HouseID
        Game.NPC[child2NPC_ID].House = HouseID
        Game.NPC[child1NPC_ID].Name = "Harry"
        Game.NPC[child2NPC_ID].Name = "Steve"
        Game.NPC[child2NPC_ID].Profession = 0
        Game.NPC[child2NPC_ID].Pic = 63
        Game.NPC[child1NPC_ID].Pic = 31 -- bytt til 215?
    end
    if vars.OrphanGhostsKilled ~= nil then
        Game.NPC[matronNPC_ID].House = 0
        Game.NPC[child1NPC_ID].House = 0
        Game.NPC[child2NPC_ID].House = 0
    end
end

BranchedFightMatronQuest = function()
    -- remove branched quest from glitching, look into finding a better way?
    NPCTopic {
        Slot = F,
        NPC = matronNPC_ID
    }

    local QuestBase = {}
    local function MyQuest(t)
        table.copy(QuestBase, t) -- copy common values
        QuestBase.Slot = QuestBase.Slot and QuestBase.Slot + 1 -- auto-increment Slot
        return Quest(t)
    end

    local function SetQuestBranch(t)
        QuestBranch(t.NewBranch)
    end

    QuestNPC = matronNPC_ID
    QuestBase = {
        Branch = "",
        Slot = E,
        Ungive = SetQuestBranch
    }
    MyQuest {
        CanShow = function()
            return Map.Name == FreeHaven and vars.Quests[Quest_KillMatronOfOrphanage] ~= nil and
                       vars.MatronOfOrphanageKilled ~= true
        end,
        NewBranch = "MatronFight",
        Texts = {
            Topic = "Kill Matron Hilda Briarwood",
            Ungive = "What! Kill me?"
        }
    }

    QuestBase = {
        Branch = "MatronFight",
        Slot = E,
        Ungive = SetQuestBranch
    }
    MyQuest {
        NewBranch = "MatronFightNo",
        Texts = {
            Topic = "Just something the children said",
            Ungive = [[
[The matron looks in the direction of the children]

I think the children will feel the belt tonight.]]
        }
    }

    MyQuest {
        NewBranch = "MatronFightYes",
        Ungive = function(t)
            Sleep(2000, 1)
            EnterOrphanage(Quest_KillMatronOfOrphanage)
            -- remove branched topic in case of loading auto save
        end,
        Texts = {
            Topic = "Your malicious reign is over!",
            Ungive = "My what? How dare you!"
        }
    }
end

EnterOrphanage = function(purpose)
    EnterDecentHouseMap(purpose)
end

SendPartyBackToOrphanageEntrance = function()
    evt.PlaySound(7) -- slam door sound
    evt.MoveToMap {
        Name = FreeHaven,
        X = 10897,
        Y = 12046,
        Z = 160,
        Direction = 516
    }
end
