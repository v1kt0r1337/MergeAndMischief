-- This summons Ogres

-- this summoning function currently places them in a line /
local function randomSummonTest()

    local ogreMagi = 108
    local ogreWarleader = 33

    -- center spawn around these coordinates
    local initialPosX = Party.X -- 14242
    local initialPosY = Party.Y --4365
    local posZ = Party.Z -- 3072

    local numberOfOgresToSpawn = 10
    local avgPackSize = 6
    local packSizeVariation = 2
    local minSpaceBetweenMonsters = 350
    local maxSpaceToNextMonster = 500
    local minSpaceToNextPacks = 500
    local maxSpaceToNextPack = 1000

    local lastPosX, lastPosY = initialPosX, initialPosY

    for i = 0, numberOfOgresToSpawn - 1 do
        local posX, posY
    
        posX = lastPosX + math.random(minSpaceBetweenMonsters, maxSpaceToNextMonster)
        posY = lastPosY + math.random(minSpaceBetweenMonsters, maxSpaceToNextMonster)

        -- Update last position
        lastPosX, lastPosY = posX, posY

        if (i == 4) then
            -- this one should probably be placed at a very specific coordinate
            SummonMonster(ogreWarleader, posX, posY, posZ)
        elseif (i == 10) then
            -- this one should probably be placed at a very specific coordinate
            SummonMonster(ogreMagi, posX, posY, posZ)
        else 
            local ogreType = getRandomMonsterOgreType()
            SummonMonster(ogreType, posX, posY, posZ)
            -- do math.random and spawn ogre type based on number.
        end

            -- Check if a new pack needs to be started
        if i % math.random(avgPackSize - packSizeVariation, avgPackSize + packSizeVariation) == 0 then
            -- Calculate random position for the next pack
            lastPosX = lastPosX + math.random(minSpaceToNextPacks, maxSpaceToNextPack)
            lastPosY = lastPosY + math.random(minSpaceToNextPacks, maxSpaceToNextPack)

            -- Update last position to the initial position of the next pack
            lastPosX, lastPosY = initialPosX, initialPosY
        end
    end
end

local function getRandomMonsterOgreType()
    local ogreBrawler = 31
    local ogreWarrior = 32
    local ogreMageApprentice = 106
    local ogreMage = 107

    -- we randomize the monstertype based on percentages except for the Warleader and Magi, always spawn on of each
    local ogreBrawlerChance = 50
    local ogreWarriorChance = 20 
    local ogreMageApprenticeChance = 20
    local ogreMageChance = 10
        
    local rand = math.random(100)
    if rand <= ogreBrawlerChance then
        return ogreBrawler
    elseif rand <= ogreBrawlerChance + ogreWarriorChance then
        return ogreWarrior
    elseif rand <= ogreBrawlerChance + ogreWarriorChance + ogreMageApprenticeChance then
        return ogreMageApprentice
    else
        return ogreMage
    end
end

