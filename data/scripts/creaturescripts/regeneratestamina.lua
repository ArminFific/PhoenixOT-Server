local function onLogin(player)
	if not configManager.getBoolean(configKeys.STAMINA_SYSTEM) then
		return true
	end

	local lastLogout = player:getLastLogout()
	local offlineTime = lastLogout ~= 0 and math.min(os.time() - lastLogout, 86400 * 21) or 0

	if offlineTime < 60 then
		return true
	end

	local staminaMinutes = player:getStamina()
	local regainStaminaMinutes = offlineTime / 60
	staminaMinutes = math.min(2520, staminaMinutes + regainStaminaMinutes)

	player:setStamina(staminaMinutes)
	return true
end

-- Revscript registrations
local RegenerateStamina = CreatureEvent("RegenerateStamina")
function RegenerateStamina.onLogin(...)
    return onLogin(...)
end
RegenerateStamina:register()
