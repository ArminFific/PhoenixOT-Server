local firstItems = {2457, 2463, 2647, 2525, 2643, 2173}

local function onLogin(player)
	if player:getLastLoginSaved() == 0 then
		for i = 1, #firstItems do
			player:addItem(firstItems[i], 1)
		end

		-- Backpack
		local backpack = player:addItem(1988, 1)
		backpack:addItem(2160, 10) 	-- Cyrstal coin
		backpack:addItem(2789, 100) -- Brown mushroom
		backpack:addItem(2120, 1) 	-- Rope
		backpack:addItem(2554, 1) 	-- Shovel
		
		-- Vocation-specific items
		local vocation = player:getVocation()
		if vocation == 1 then 			-- Sorcerer
			player:addItem(2190, 1) 
		elseif vocation == 2 then 		-- Druid
			player:addItem(2182, 1) 
		elseif vocation == 3 then 		-- Paladin
			player:addItem(2456, 1)
		elseif vocation == 4 then 		-- Knight
			player:addItem(2383, 1)
		end
		
	end
	return true
end

-- Revscript registrations
local FirstItems = CreatureEvent("FirstItems")
function FirstItems.onLogin(...)
    return onLogin(...)
end
FirstItems:register()
