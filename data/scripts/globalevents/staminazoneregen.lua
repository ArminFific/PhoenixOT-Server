local zoneEvent = GlobalEvent("StaminaZoneRegen")

function zoneEvent.onThink(interval)
    local zone = Zone(1)
    if not zone then
        return true
    end

    for _, creature in ipairs(zone:getCreatures()) do
        if creature:isPlayer() then
            local player = creature:getPlayer()
            if player then
				if player:getStamina() ~= 2520 then
					player:setStamina(math.min(2520, player:getStamina() + 1))
					player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Regaining one stamina point: " .. player:getStamina())
				end
            end
        end
    end

    return true
end

zoneEvent:interval(30000)
-- zoneEvent:register()