local ec = EventCallback

-- This Event is not triggered by healing.
-- This Event can be triggered by spells.
-- This event is called on items worn by the attacker.
-- This Event is called everytime any attack takes place damage or not, and the item equipped has attack.

-- criticalDamage and leechedDamage are true/false values, to determine if the attack was from a crit or a leech attack.

-- item.onAttack(item, player, creature, blockType, combatType, origin, criticalDamage, leechedDamage)
ec.onAttack = function(self, attacker, target, blockType, combatType, origin, criticalDamage, leechedDamage)
	-- default
	return
end

ec:register()
