local A, B, C, D, E, F = 0, 1, 2, 3, 4, 5

function FindNPC(substring)
	for i, npc in Game.NPC do
		if string.find(npc.Name, substring) then
			print("npc index", i)
			print(dump(npc))
		end
	end
end

function FindNPCByHouseId(house)
	for i, npc in Game.NPC do
		if npc.House == house then
			print("npc index", i)
			print(dump(npc))
		end
	end
end


function FindTopicIndex(topicName) 
	for i, topic in Game.NPCTopic do
		if topic == "Hunter" then
			print("topic index", i)
		end
	end
end

function FindNPCText(substring)
	for i, text in Game.NPCText do
		if string.find(text, substring) then
			print("topic index", i)
			print(text)
		end
	end
end


function FindNPCGreeting(substring)
    for i, npc in Game.NPCGreet do
        for j, greeting in npc do
            if string.find(greeting, substring) then
                print("Substring found in Game.NPCGreet["..i.."]["..j.."]")
            end
        end
    end
end


function AddTenOf(itemId)
    for i = 0, 9 do
        evt.Add("Inventory", itemId)
    end
end

function AddXOf(itemId, x)
    for i = 0, x do
        evt.Add("Inventory", itemId)
    end
end

-- These are only safe in the sense of reusable NPC's that follow the guideline:
-- Slot A -> D are NPCTopic, E -> F are Quests that are controlled with CanShow
function RemoveSafeTopicsFromNPC(NPC_ID)
	NPCTopic{Slot = A, NPC = NPC_ID}
    NPCTopic{Slot = B, NPC = NPC_ID} 
	NPCTopic{Slot = C, NPC = NPC_ID}
	NPCTopic{Slot = D, NPC = NPC_ID}
    Greeting{NPC = NPC_ID}
end

function RemoveAllTopicsFromNPC(NPC_ID)
	NPCTopic{Slot = A, NPC = NPC_ID}
    NPCTopic{Slot = B, NPC = NPC_ID} 
	NPCTopic{Slot = C, NPC = NPC_ID}
	NPCTopic{Slot = D, NPC = NPC_ID}
	NPCTopic{Slot = E, NPC = NPC_ID}
	NPCTopic{Slot = F, NPC = NPC_ID} 
    Greeting{NPC = NPC_ID}
end

-- recipe for disovering sounds
-- local index = 0
-- Timer(function()
-- 	evt.PlaySound(index)
-- 	print("sound " .. index)
-- 	index = index + 1
	
-- end, 100)
-- print("sound " .. index - 1)


--  306 - 322

--- gold is 133, dropping a coin is 134

-- evil laughter around sound 219 sound 220

-- last index tried sound 1005