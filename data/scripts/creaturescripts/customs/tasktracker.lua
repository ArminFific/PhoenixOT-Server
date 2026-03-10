-- ============================================================
--  Task Tracker - Kill & Collect tracking + auto-reward
--  File: data/scripts/creaturescripts/customs/tasktracker.lua
--  Requires: data/scripts/lib/tasks.lua
-- ============================================================

local TOKEN_ITEM_ID  = 6527   -- REPLACE WITH YOUR TASK TOKEN ITEM ID
local READY_OPCODE   = 51  -- client -> server ready signal

-- ============================================================
--  DB helpers
-- ============================================================

local function getTasksCompleted(player)
    local resultId = db.storeQuery(
        "SELECT tasks_completed FROM players WHERE id = " .. player:getGuid()
    )
    if resultId ~= false then
        local count = result.getNumber(resultId, "tasks_completed")
        result.free(resultId)
        return count
    end
    return 0
end

local function incrementTasksCompleted(player)
    db.query(
        "UPDATE players SET tasks_completed = tasks_completed + 1 WHERE id = " .. player:getGuid()
    )
end

-- ============================================================
--  Auto-reward on completion
-- ============================================================

local function giveReward(player, tier, task)
    local reward = task.reward
    player:addExperience(reward.exp, true)
    player:addMoney(reward.gold)
    if TOKEN_ITEM_ID ~= 0 and reward.tokens > 0 then
        player:addItem(TOKEN_ITEM_ID, reward.tokens)
    end
    incrementTasksCompleted(player)
    player:sendTextMessage(MESSAGE_INFO_DESCR,
        "Task complete! [" .. TASK_TIER_NAMES[tier] .. "] " .. task.label ..
        " | Rewards: " .. reward.exp .. " exp, " .. reward.gold ..
        " gold, " .. reward.tokens .. " token(s).")
    player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
end

local function advanceTask(player, tier, task)
    local idKey, progressKey, doneKey = TaskGetTierStorage(tier)
    local progress = player:getStorageValue(progressKey) + 1
    player:setStorageValue(progressKey, progress)

    if progress >= task.amount then
        player:setStorageValue(doneKey, 1)
        giveReward(player, tier, task)
    elseif progress % 10 == 0 then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
            "[" .. TASK_TIER_NAMES[tier] .. " TASK] " .. task.label ..
            ": " .. progress .. "/" .. task.amount)
    end

    TaskPushState(player)
end

local function checkTask(player, taskType, value)
    local tiers = {"easy", "medium", "hard"}
    for _, tier in ipairs(tiers) do
        local idKey, progressKey, doneKey = TaskGetTierStorage(tier)
        local taskId = player:getStorageValue(idKey)
        local done   = player:getStorageValue(doneKey)

        if taskId ~= -1 and done ~= 1 then
            local task = TaskGetById(taskId)
            if task and task.type == taskType then
                local match = false
                if taskType == "kill" then
                    match = task.target:lower() == value:lower()
                elseif taskType == "collect" then
                    match = task.target == value
                end
                if match then
                    advanceTask(player, tier, task)
                end
            end
        end
    end
end

-- ============================================================
--  TaskPushState override to include total completed from DB
-- ============================================================

local function pushTaskStateFull(player)
    local tiers = {"easy", "medium", "hard"}
    local parts = {}

    for _, tier in ipairs(tiers) do
        local idKey, progressKey, doneKey = TaskGetTierStorage(tier)
        local taskId   = player:getStorageValue(idKey)
        local progress = math.max(0, player:getStorageValue(progressKey))
        local done     = player:getStorageValue(doneKey) == 1
        local locked   = (player:getLevel() < TASK_TIER_LEVELS[tier]) and 1 or 0

        local label, total
        if locked == 1 then
            label    = "Level " .. TASK_TIER_LEVELS[tier] .. " required"
            total    = 0
            progress = 0
            done     = false
        elseif taskId == -1 then
            label    = "No task assigned"
            total    = 0
            progress = 0
            done     = false
        else
            local task = TaskGetById(taskId)
            label = task and task.label or "Unknown"
            total = task and task.amount or 0
        end

        table.insert(parts, string.format(
            '"%s":{"label":"%s","progress":%d,"total":%d,"done":%d,"locked":%d}',
            tier, label, progress, total, done and 1 or 0, locked
        ))
    end

    -- Include all-time completed count from DB
    local totalCompleted = getTasksCompleted(player)
    table.insert(parts, string.format('"total_completed":%d', totalCompleted))

    player:sendExtendedOpcode(TASK_OPCODE, "{" .. table.concat(parts, ",") .. "}")
end

-- Override the shared TaskPushState for full pushes
TaskPushState = pushTaskStateFull

-- ============================================================
--  GlobalEvent: record server start time
-- ============================================================

local startupEvent = GlobalEvent("TaskServerStartup")

function startupEvent.onStartup()
    _G["TASK_SERVER_START"] = os.time()
    return true
end

startupEvent:type("startup")
startupEvent:register()

-- ============================================================
--  Kill tracker
-- ============================================================

local killTracker = CreatureEvent("TaskKillTracker")

function killTracker.onKill(creature, target)
    if not creature:isPlayer() then return end
    if not target:isMonster() then return end
    checkTask(creature:getPlayer(), "kill", target:getName())
end

killTracker:type("kill")
killTracker:register()

-- ============================================================
--  Login: register events + daily reset
-- ============================================================

local loginHandler = CreatureEvent("TaskLoginHandler")

function loginHandler.onLogin(player)
    player:registerEvent("TaskKillTracker")
    player:registerEvent("TaskThinkTracker")

    local serverStart = _G["TASK_SERVER_START"] or os.time()
    local lastReset   = player:getStorageValue(TASK_STORAGE.RESET_STAMP)

    if lastReset == -1 or lastReset < serverStart then
        local keys = {
            TASK_STORAGE.EASY_ID,   TASK_STORAGE.EASY_PROGRESS,   TASK_STORAGE.EASY_DONE,
            TASK_STORAGE.MEDIUM_ID, TASK_STORAGE.MEDIUM_PROGRESS, TASK_STORAGE.MEDIUM_DONE,
            TASK_STORAGE.HARD_ID,   TASK_STORAGE.HARD_PROGRESS,   TASK_STORAGE.HARD_DONE,
        }
        for _, key in ipairs(keys) do
            player:setStorageValue(key, -1)
        end
        player:setStorageValue(TASK_STORAGE.RESET_STAMP, os.time())
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
            "Daily bounties have been reset. Visit the Task Board to receive new tasks!")
    end

    return true
end

loginHandler:type("login")
loginHandler:register()

-- ============================================================
--  Ready signal handler: client tells server it's ready
-- ============================================================

local readyHandler = CreatureEvent("TaskReadyHandler")

function readyHandler.onExtendedOpcode(player, opcode, buffer)
    if opcode == READY_OPCODE then
        pushTaskStateFull(player)
    end
end

readyHandler:type("extendedopcode")
readyHandler:register()

-- ============================================================
--  Login: also register ready handler
-- ============================================================

local readyLoginEvent = CreatureEvent("TaskReadyLogin")

function readyLoginEvent.onLogin(player)
    player:registerEvent("TaskReadyHandler")
    return true
end

readyLoginEvent:type("login")
readyLoginEvent:register()

-- ============================================================
--  Collect tracker via onThink (checks inventory every 5s)
-- ============================================================

local function checkCollectTasks(player)
    local tiers = {"easy", "medium", "hard"}
    local updated = false

    for _, tier in ipairs(tiers) do
        local idKey, progressKey, doneKey = TaskGetTierStorage(tier)
        local taskId = player:getStorageValue(idKey)
        local done   = player:getStorageValue(doneKey)

        if taskId ~= -1 and done ~= 1 then
            local task = TaskGetById(taskId)
            if task and task.type == "collect" then
                local have = TaskCountItemInInventory(player, task.target)
                local current = player:getStorageValue(progressKey)
                if have ~= current then
                    player:setStorageValue(progressKey, have)
                    if have >= task.amount then
                        player:setStorageValue(doneKey, 1)
                        giveReward(player, tier, task)
                    elseif have % 5 == 0 then
                        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
                            "[" .. TASK_TIER_NAMES[tier] .. " TASK] " .. task.label ..
                            ": " .. have .. "/" .. task.amount)
                    end
                    updated = true
                end
            end
        end
    end

    if updated then
        TaskPushState(player)
    end
end

local thinkTracker = CreatureEvent("TaskThinkTracker")

function thinkTracker.onThink(creature, interval)
    if not creature:isPlayer() then return true end
    checkCollectTasks(creature:getPlayer())
    return true
end

thinkTracker:type("think")
thinkTracker:register()