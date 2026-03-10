local monsterLevel = CreatureEvent("MonsterLevelThink")

function monsterLevel.onThink(creature, interval)
    if not creature:isMonster() then
        return true
    end

    local monster = Monster(creature:getId())
    if not monster then
        return true
    end

    if not monster:hasSkill("level") then
        return true
    end

    local level = monster:getSkillLevel("level")
    monster:setNameDescription("[L. " .. level .. "] " .. monster:getName())
    monster:unregisterEvent("MonsterLevelThink")

    return true
end

monsterLevel:type("think")
monsterLevel:register()