-- ============================================================
--  Shared Task Definitions
--  File: data/scripts/lib/tasks.lua
-- ============================================================

TASK_OPCODE  = 50
READY_OPCODE = 51

TASK_TIER_LEVELS = {
    easy   = 1,
    medium = 100,
    hard   = 300,
}

TASK_TIER_NAMES = {
    easy   = "Common",
    medium = "Rare",
    hard   = "Legendary",
}

TASK_STORAGE = {
    EASY_ID         = 50000,
    EASY_PROGRESS   = 50001,
    EASY_DONE       = 50002,
    MEDIUM_ID       = 50003,
    MEDIUM_PROGRESS = 50004,
    MEDIUM_DONE     = 50005,
    HARD_ID         = 50006,
    HARD_PROGRESS   = 50007,
    HARD_DONE       = 50008,
    RESET_STAMP     = 50009,
    PENDING_TIER    = 50010,
}

-- ============================================================
--  Task Pool
--  reward: gold (gp), tokens (count), exp
--  type:   "kill"    - target is monster name (string)
--          "collect" - target is item ID (number)
-- ============================================================

TASKS = {
    easy = {
        {id = 1, type = "kill",    target = "Rotworm",   amount = 50,  label = "Kill 50 Rotworms",
            reward = {exp = 5000,   gold = 2000,  tokens = 1}},
        {id = 2, type = "kill",    target = "Troll",     amount = 30,  label = "Kill 30 Trolls",
            reward = {exp = 3000,   gold = 1500,  tokens = 1}},
        {id = 3, type = "collect", target = 10609,       amount = 10,  label = "Collect 10 Lumps of Dirt",
            reward = {exp = 2000,   gold = 1000,  tokens = 1}},
    },
    medium = {
        {id = 4, type = "kill",    target = "Orc",       amount = 100, label = "Kill 100 Orcs",
            reward = {exp = 30000,  gold = 10000, tokens = 3}},
        {id = 5, type = "kill",    target = "Dwarf",     amount = 50,  label = "Kill 50 Dwarves",
            reward = {exp = 20000,  gold = 8000,  tokens = 2}},
        {id = 6, type = "collect", target = 5906,        amount = 30,  label = "Collect 30 Orc Tusks",
            reward = {exp = 15000,  gold = 6000,  tokens = 2}},
    },
    hard = {
        {id = 7, type = "kill",    target = "Demon",     amount = 200, label = "Kill 200 Demons",
            reward = {exp = 150000, gold = 80000, tokens = 5}},
        {id = 8, type = "kill",    target = "Orshabaal", amount = 1,   label = "Slay Orshabaal",
            reward = {exp = 500000, gold = 200000,tokens = 10}},
        {id = 9, type = "collect", target = 2694,        amount = 50,  label = "Collect 50 Demon Legs",
            reward = {exp = 100000, gold = 50000, tokens = 5}},
    },
}

-- ============================================================
--  Shared helpers
-- ============================================================

function TaskGetById(taskId)
    for _, pool in pairs(TASKS) do
        for _, task in ipairs(pool) do
            if task.id == taskId then return task end
        end
    end
    return nil
end

function TaskGetTierStorage(tier)
    if tier == "easy"   then return TASK_STORAGE.EASY_ID,   TASK_STORAGE.EASY_PROGRESS,   TASK_STORAGE.EASY_DONE   end
    if tier == "medium" then return TASK_STORAGE.MEDIUM_ID, TASK_STORAGE.MEDIUM_PROGRESS, TASK_STORAGE.MEDIUM_DONE end
    return TASK_STORAGE.HARD_ID, TASK_STORAGE.HARD_PROGRESS, TASK_STORAGE.HARD_DONE
end

function TaskPushState(player)
    local tiers = {"easy", "medium", "hard"}
    local parts = {}

    for _, tier in ipairs(tiers) do
        local idKey, progressKey, doneKey = TaskGetTierStorage(tier)
        local taskId   = player:getStorageValue(idKey)
        local progress = math.max(0, player:getStorageValue(progressKey))
        local done     = player:getStorageValue(doneKey) == 1
        local locked   = (player:getLevel() < TASK_TIER_LEVELS[tier]) and 1 or 0

        local label, total, rewardGold, rewardTokens, rewardExp
        if locked == 1 then
            label       = "Level " .. TASK_TIER_LEVELS[tier] .. " required"
            total       = 0
            progress    = 0
            done        = false
            rewardGold  = 0
            rewardTokens= 0
            rewardExp   = 0
        elseif taskId == -1 then
            label       = "No task assigned"
            total       = 0
            progress    = 0
            done        = false
            rewardGold  = 0
            rewardTokens= 0
            rewardExp   = 0
        else
            local task  = TaskGetById(taskId)
            label       = task and task.label or "Unknown"
            total       = task and task.amount or 0
            rewardGold  = task and task.reward.gold or 0
            rewardTokens= task and task.reward.tokens or 0
            rewardExp   = task and task.reward.exp or 0
        end

        table.insert(parts, string.format(
            '"%s":{"label":"%s","progress":%d,"total":%d,"done":%d,"locked":%d,"reward_gold":%d,"reward_tokens":%d,"reward_exp":%d}',
            tier, label, progress, total, done and 1 or 0, locked, rewardGold, rewardTokens, rewardExp
        ))
    end

    player:sendExtendedOpcode(TASK_OPCODE, "{" .. table.concat(parts, ",") .. "}")
end

-- ============================================================
--  Inventory item counting (used for collect tasks)
-- ============================================================

function TaskCountItemsInContainer(container, itemId)
    local count = 0
    for i = 0, container:getSize() - 1 do
        local item = container:getItem(i)
        if item then
            if item:getId() == itemId then
                count = count + item:getCount()
            elseif item:isContainer() then
                count = count + TaskCountItemsInContainer(item, itemId)
            end
        end
    end
    return count
end

function TaskCountItemInInventory(player, itemId)
    local count = 0
    for slot = CONST_SLOT_FIRST, CONST_SLOT_LAST do
        local item = player:getSlotItem(slot)
        if item then
            if item:getId() == itemId then
                count = count + item:getCount()
            elseif item:isContainer() then
                count = count + TaskCountItemsInContainer(item, itemId)
            end
        end
    end
    return count
end