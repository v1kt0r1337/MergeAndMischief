-- code originally written by Eksekk

do
	local function getSFTItem(spriteFramePointer)
		local firstFrameAddress = Game.SFTBin.Frames["?ptr"]
		local frameStructSize = Game.SFTBin.Frames[0]["?size"]
		local byteOffset = spriteFramePointer - firstFrameAddress
		local frameIndex = byteOffset / frameStructSize
		return Game.SFTBin.Frames[frameIndex]
	end

	local scaleHook = function(indoor)
		return function(hookContext)
			local t = {Scale = hookContext.eax, Frame = getSFTItem(hookContext.ebx)}
			local monsterIndex = internal.GetMonster(indoor and hookContext.edi or (hookContext.edi - 0x9A))
			t.MonsterIndex = math.floor(monsterIndex)
			t.Monster = Map.Monsters[t.MonsterIndex]
			events.call("MonsterSpriteScale", t)
			hookContext.eax = t.Scale
		end
	end

	-- outdoor
	mem.autohook2(0x47AC26, scaleHook())
	mem.autohook2(0x47AC46, scaleHook())

	-- indoor
	mem.autohook2(0x43D02E, scaleHook(true))
	mem.autohook2(0x43D04D, scaleHook(true))
end
