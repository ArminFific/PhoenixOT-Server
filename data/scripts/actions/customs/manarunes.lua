-- ============================================================
--  Mana Runes
--  File: data/scripts/actions/manarunes.lua
-- ============================================================

-- Vocation multipliers
-- Add all your future vocation IDs here as you add promotions
local vocMult = {
    [1]  = 1.0,  -- Sorcerer
    [2]  = 1.1,  -- Druid
    [3]  = 0.7,  -- Paladin
    [4]  = 0.4,  -- Knight
    [5]  = 1.0,  -- Master Sorcerer
    [6]  = 1.1,  -- Elder Druid
    [7]  = 0.7,  -- Royal Paladin
    [8]  = 0.4,  -- Elite Knight
    [9]  = 0.4,  -- Warlord
    [10] = 1.0,  -- Archmage
    [11] = 1.1,  -- High Druid
    [12] = 0.7,  -- Templar
    [13] = 0.4,  -- Dreadnought
    [14] = 1.0,  -- Grand Archmage
    [15] = 1.1,  -- Archdruid
    [16] = 0.7,  -- Divine Sentinel
}

-- Stage table: {minLevel, minMult, maxMult}
local stages = {
    {0,    0.20, 0.30},
    {150,  0.28, 0.40},
    {700,  0.38, 0.52},
    {1000, 0.48, 0.64},
    {1500, 0.58, 0.76},
    {2000, 0.68, 0.88},
    {2500, 0.78, 1.00},
    {3000, 0.88, 1.12},
    {3500, 0.98, 1.24},
    {4000, 1.08, 1.36},
    {4500, 1.18, 1.48},
    {5000, 1.30, 1.60},
}

-- Rune definitions
-- tierMult: multiplier relative to Small (1.0x baseline)
-- minLevel: minimum level required to use the rune at all
local runes = {
    [2276] = {name = "Small Mana Rune",   tierMult = 1.00, minLevel = 0},
    [2270] = {name = "Medium Mana Rune",  tierMult = 1.25, minLevel = 0},
    [2284] = {name = "Great Mana Rune",   tierMult = 1.50, minLevel = 0},
    [2300] = {name = "Ultimate Mana Rune",tierMult = 1.75, minLevel = 10},
    [2294] = {name = "Supreme Mana Rune", tierMult = 2.25, minLevel = 25},
}

-- ============================================================
--  Core Functions
-- ============================================================

local function getStage(level)
    local stage = stages[1]
    for _, s in ipairs(stages) do
        if level >= s[1] then
            stage = s
        end
    end
    return stage
end

local function calcMana(player, tierMult)
    local level    = player:getLevel()
    local maglevel = player:getMagicLevel()
    local vocId    = player:getVocation():getId()
    local vMult    = vocMult[vocId] or 0.5  -- fallback for unknown vocations

    -- Base formula
    local base = (level * 1.5) + (maglevel * 20)

    -- Stage min/max range
    local stage = getStage(level)
    local minMult = stage[2]
    local maxMult = stage[3]

    -- Random value within stage range
    local rangeMult = minMult + math.random() * (maxMult - minMult)

    -- Final mana amount
    local amount = math.floor(base * vMult * rangeMult * tierMult)
    return amount
end

-- ============================================================
--  onUse Handler
-- ============================================================

local function onManaRune(player, item, fromPosition, target, toPosition, isHotkey)
    local rune = runes[item:getId()]
    if not rune then
        return false
    end

    local level = player:getLevel()

    -- Level requirement check
    if level < rune.minLevel then
        player:sendCancelMessage(
            "You need to be level " .. rune.minLevel .. " to use a " .. rune.name .. "."
        )
        return true
    end

    -- Already full mana check
    local currentMana = player:getMana()
    local maxMana     = player:getMaxMana()
    if currentMana >= maxMana then
        player:sendCancelMessage("You already have full mana.")
        -- player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    -- Calculate and apply mana
    local amount   = calcMana(player, rune.tierMult)
    local restored = math.min(amount, maxMana - currentMana)

    player:addMana(restored)
    player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
    player:sendTextMessage(MESSAGE_HEALED, "You restored " .. restored .. " mana.")

    return true
end

-- ============================================================
--  Registration
-- ============================================================

for itemId, _ in pairs(runes) do
    local action = Action()
    action.onUse = onManaRune
    action:id(itemId)
    action:register()
end