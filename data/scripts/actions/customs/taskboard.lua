-- ============================================================
--  Task Board with ModalWindow dialog
--  File: data/scripts/actions/taskboard.lua
--  Requires: data/scripts/lib/tasks.lua
-- ============================================================

local TASK_BOARD_ITEM_ID = 26204

-- Modal window IDs
local WINDOW_BOARD   = 6001
local WINDOW_CONFIRM = 6002
local WINDOW_STATUS  = 6003

-- Button/Choice IDs
local CHOICE_EASY   = 1
local CHOICE_MEDIUM = 2
local CHOICE_HARD   = 3
local BTN_ACCEPT    = 1
local BTN_CANCEL    = 2

-- ============================================================
--  Helpers
-- ============================================================

local function getTierFromChoice(choiceId)
    if choiceId == CHOICE_EASY   then return "easy"   end
    if choiceId == CHOICE_MEDIUM then return "medium" end
    if choiceId == CHOICE_HARD   then return "hard"   end
    return nil
end

local function getTierStatus(player, tier)
    if player:getLevel() < TASK_TIER_LEVELS[tier] then
        return "locked", nil, 0, 0
    end

    local idKey, progressKey, doneKey = TaskGetTierStorage(tier)
    local taskId   = player:getStorageValue(idKey)
    local progress = player:getStorageValue(progressKey)
    local done     = player:getStorageValue(doneKey)

    if taskId == -1 then
        return "empty", nil, 0, 0
    elseif done == 1 then
        local task = TaskGetById(taskId)
        return "done", task, progress, task and task.amount or 0
    else
        local task = TaskGetById(taskId)
        return "active", task, progress, task and task.amount or 0
    end
end

local function assignTask(player, tier)
    local idKey, progressKey, doneKey = TaskGetTierStorage(tier)
    local pool = TASKS[tier]
    local task = pool[math.random(#pool)]
    player:setStorageValue(idKey, task.id)
    player:setStorageValue(doneKey, 0)

    -- For collect tasks, check inventory immediately
    local initialProgress = 0
    if task.type == "collect" then
        initialProgress = math.min(TaskCountItemInInventory(player, task.target), task.amount)
    end
    player:setStorageValue(progressKey, initialProgress)

    return task
end

-- ============================================================
--  Show main board window
-- ============================================================

local function showBoardWindow(player)
    local level = player:getLevel()
    local lines = {}

    for _, tier in ipairs({"easy", "medium", "hard"}) do
        local status, task, progress, total = getTierStatus(player, tier)
        local prefix = "[" .. TASK_TIER_NAMES[tier]:upper() .. "] "

        if status == "locked" then
            table.insert(lines, prefix .. "Locked (Level " .. TASK_TIER_LEVELS[tier] .. " required)")
        elseif status == "empty" then
            table.insert(lines, prefix .. "No task assigned")
        elseif status == "done" then
            table.insert(lines, prefix .. "COMPLETED!")
        elseif status == "active" then
            table.insert(lines, prefix .. task.label .. " (" .. progress .. "/" .. total .. ")")
        end
    end

    local window = ModalWindow(WINDOW_BOARD, "Task Board", table.concat(lines, "\n"))

    if level >= TASK_TIER_LEVELS.easy   then window:addChoice(CHOICE_EASY,   TASK_TIER_NAMES.easy   .. " Task") end
    if level >= TASK_TIER_LEVELS.medium then window:addChoice(CHOICE_MEDIUM, TASK_TIER_NAMES.medium .. " Task") end
    if level >= TASK_TIER_LEVELS.hard   then window:addChoice(CHOICE_HARD,   TASK_TIER_NAMES.hard   .. " Task") end

    window:addButton(BTN_ACCEPT, "View / Get Task")
    window:addButton(BTN_CANCEL, "Close")
    window:setDefaultEnterButton(BTN_ACCEPT)
    window:setDefaultEscapeButton(BTN_CANCEL)
    window:sendToPlayer(player)
end

-- ============================================================
--  Show tier detail window
-- ============================================================

local function showTierWindow(player, tier)
    local status, task, progress, total = getTierStatus(player, tier)
    local tierName = TASK_TIER_NAMES[tier]

    if status == "locked" then
        local w = ModalWindow(WINDOW_STATUS, "Task Board",
            "This tier requires level " .. TASK_TIER_LEVELS[tier] .. ".")
        w:addButton(BTN_CANCEL, "Close")
        w:setDefaultEscapeButton(BTN_CANCEL)
        w:sendToPlayer(player)

    elseif status == "empty" then
        player:setStorageValue(TASK_STORAGE.PENDING_TIER,
            tier == "easy" and 1 or tier == "medium" and 2 or 3)
        local w = ModalWindow(WINDOW_CONFIRM, "Task Board",
            "You have no " .. tierName .. " task assigned.\nWould you like to receive a new task?")
        w:addButton(BTN_ACCEPT, "Yes, assign me a task")
        w:addButton(BTN_CANCEL, "No thanks")
        w:setDefaultEnterButton(BTN_ACCEPT)
        w:setDefaultEscapeButton(BTN_CANCEL)
        w:sendToPlayer(player)

    elseif status == "done" then
        local w = ModalWindow(WINDOW_STATUS, "Task Board - " .. tierName,
            "Task: " .. task.label .. "\nStatus: COMPLETED!\n\nYour reward has been added to your inventory.")
        w:addButton(BTN_CANCEL, "Close")
        w:setDefaultEscapeButton(BTN_CANCEL)
        w:sendToPlayer(player)

    elseif status == "active" then
        local w = ModalWindow(WINDOW_STATUS, "Task Board - " .. tierName,
            "Task: " .. task.label .. "\nProgress: " .. progress .. " / " .. total)
        w:addButton(BTN_CANCEL, "Close")
        w:setDefaultEscapeButton(BTN_CANCEL)
        w:sendToPlayer(player)
    end
end

-- ============================================================
--  Action: click the board
-- ============================================================

local board = Action()

function board.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    showBoardWindow(player)
    return true
end

board:id(TASK_BOARD_ITEM_ID)
board:register()

-- ============================================================
--  ModalWindow response handler
-- ============================================================

local modalHandler = CreatureEvent("TaskBoardModalHandler")

function modalHandler.onModalWindow(player, modalWindowId, buttonId, choiceId)

    if modalWindowId == WINDOW_BOARD then
        if buttonId == BTN_ACCEPT then
            local tier = getTierFromChoice(choiceId)
            if tier then showTierWindow(player, tier) end
        end
        return true
    end

    if modalWindowId == WINDOW_CONFIRM then
        if buttonId == BTN_ACCEPT then
            local pendingVal = player:getStorageValue(TASK_STORAGE.PENDING_TIER)
            local tier = pendingVal == 1 and "easy" or pendingVal == 2 and "medium" or "hard"
            local task = assignTask(player, tier)
            TaskPushState(player)

            local w = ModalWindow(WINDOW_STATUS, "Task Board - " .. TASK_TIER_NAMES[tier],
                "New task assigned!\n\n" .. task.label .. "\n\nGood luck!")
            w:addButton(BTN_CANCEL, "Close")
            w:setDefaultEscapeButton(BTN_CANCEL)
            w:sendToPlayer(player)
        end
        return true
    end

    return true
end

modalHandler:type("modalwindow")
modalHandler:register()

-- ============================================================
--  Login: register modal handler
-- ============================================================

local boardLoginEvent = CreatureEvent("TaskBoardLogin")

function boardLoginEvent.onLogin(player)
    player:registerEvent("TaskBoardModalHandler")
    return true
end

boardLoginEvent:type("login")
boardLoginEvent:register()