local effectPreview = TalkAction("/effect")

function effectPreview.onSay(player, words, param)
    -- Must be GM or higher
    if player:getAccountType() < ACCOUNT_TYPE_GAMEMASTER then
        player:sendCancelMessage("You do not have permission to use this command.")
        return false
    end

    local effectId = tonumber(param)

    if not effectId then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /effect <id>  |  Example: /effect 11")
        return false
    end

    if effectId < 0 or effectId > 255 then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Effect ID must be between 0 and 255.")
        return false
    end

    player:getPosition():sendMagicEffect(effectId)
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Playing effect ID: " .. effectId)
    return false
end

effectPreview:separator(" ")
effectPreview:register()