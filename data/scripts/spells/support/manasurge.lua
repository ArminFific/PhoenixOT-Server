-- ============================================================
--  Mana Surge
--  Spell words: vita surge
--  Effect: Drains 90% of max mana. Requires 90% mana to cast.
--  File: data/scripts/spells/support/manasurge.lua
-- ============================================================

local spell = Spell("instant")

function spell.onCastSpell(creature, variant)
    local player = creature:getPlayer()
    if not player then
        return false
    end

    local maxMana     = player:getMaxMana()
    local currentMana = player:getMana()
    local threshold   = math.floor(maxMana * 0.90)

    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Current mana: " .. currentMana)

    -- Block cast if player doesn't have at least 90% mana
    if currentMana < threshold then
        player:sendCancelMessage("You need at least 90% mana to perform a mana surge.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    -- Drain 90% of max mana and count toward magic level
    player:addMana(-threshold)
    player:addManaSpent(threshold)

    player:getPosition():sendMagicEffect(CONST_ME_LOSEENERGY)
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "You release a mana surge, losing " .. threshold .. " mana.")

    return true
end

spell:name("Mana Surge")
spell:words("vita surge")
spell:cooldown(2 * 1000)        -- 2 second cooldown to prevent spam
spell:groupCooldown(1 * 1000)   -- 1 second group cooldown
spell:level(1)
spell:mana(0)                   -- engine cost is 0, drain handled in script
spell:isAggressive(false)
spell:register()