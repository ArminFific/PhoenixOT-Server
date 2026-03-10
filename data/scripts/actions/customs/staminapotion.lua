local StaminaPotion = Action()
local STAMINA_POTION_ITEM_ID = 7439

function StaminaPotion.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if player:getStamina() ~= 2520 then
        player:setStamina(2520)
        player:say("You feel fully rested.", TALKTYPE_MONSTER_SAY)
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
        item:remove(1)
    else
        player:sendCancelMessage("Your stamina is already full.")
        player:say("I already feel rested.", TALKTYPE_MONSTER_SAY)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
    end
    return true
end

StaminaPotion:id(STAMINA_POTION_ITEM_ID)
StaminaPotion:register()