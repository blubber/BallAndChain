local aName, aObj = ...

aObj.followTarget = nil
aObj.followers = {}

local EventHandler = {
    QUEST_ACCEPTED = function(sender, questId)
        local questTitle, _, _, _ = C_TaskQuest.GetQuestInfoByQuestID(questId)
        aObj.Print(sender, "accepted quest", questTitle)
    end,

    QUEST_TURNED_IN = function(sender, questId, _, _)
        local questTitle, _, _, _ = C_TaskQuest.GetQuestInfoByQuestID(questId)
        aObj.Print(sender, "turned in quest", questTitle)
    end,

    QUEST_AUTOCOMPLETE = function(sender, questId)
        local questTitle, _, _, _ = C_TaskQuest.GetQuestInfoByQuestID(questId)
        aObj.Print(sender, "turned in quest", questTitle)
        -- self:QUEST_TURNED_IN(sender, questId, nil, nil)
    end

}

function aObj.SendEvent(event, ...)
    local message = event
    local args = {...}

    for _, arg in ipairs(args) do
        message = message .. ":"
        if arg ~= nil then message = message .. tostring(arg) end
    end

    C_ChatInfo.SendAddonMessage(aName, message, "GUILD")
end

function aObj.Register()
    if not C_ChatInfo.IsAddonMessagePrefixRegistered(aName) then
        C_ChatInfo.RegisterAddonMessagePrefix(aName)
    end
    aObj.SendEvent("BC_REGISTER")
end

function aObj.SetFollowTarget(name) aObj.followTarget = name end

function aObj.ClearFollowTarget() aObj.followTarget = nil end

function aObj.Tick(elapsed)
    for _, follower in pairs(aObj.followers) do
        follower.since = follower.since + elapsed
    end

    if aObj.followTarget then
        aObj.SendEvent("AUTOFOLLOW_BEGINS", aObj.followTarget)
    else
        aObj.SendEvent("AUTOFOLLOW_ENDS")
    end

    aObj.UpdateFrame()
end

function aObj.HandleMessage(message, sender)
    local senderName = gsub(sender, "%-[^|]+", "")

    aObj.Debug("Receive from", senderName, " -- ", message)

    local event = nil
    local args = {}

    for v in string.gmatch(message, "([^:]+)") do
        if not event then
            event = v
        else
            table.insert(args, v)
        end
    end

    return EventHandler[event] and EventHandler[event](sender, unpack(args))
end

function EventHandler:REGISTER(sender, args)
    if aObj.followTarget then
        send_message(Command.FOLLOW, aObj.followTarget)
    else
        send_message(Command.UNFOLLOW)
    end
end

function EventHandler.AUTOFOLLOW_BEGINS(source, args)
    if #args < 1 then return end

    local followTarget = args[1]
    local unitName, _ = UnitName("player")

    aObj.Debug(source, "following", followTarget)

    if unitName ~= followTarget and aObj.followers[source] then
        aObj.Debug(source, "is following somebody else, set following to false")
        if aObj.followers[source].following then
            aObj.followers[source].since = 0
        end
        aObj.followers[source].following = false
        return
    end

    if not aObj.followers[source] then
        aObj.followers[source] = {following = true, frame = nil, since = 0}
    else
        print("Deze case")
        aObj.followers[source].following = true
        aObj.followers[source].since = 0
    end

    aObj.UpdateFrame()
end

function EventHandler.AUTOFOLLOW_ENDS(source, args)
    aObj.Debug(source, "stoppped following")

    if aObj.followers[source] then
        if aObj.followers[source].following then
            aObj.followers[source].since = 0
        end
        aObj.followers[source].following = false
    end

    aObj.UpdateFrame()
end

function aObj.Print(...)
    if BCConf.Debug then
        local args = {...}
        local message = ""

        for i, arg in ipairs(args) do
            if i > 0 then message = message .. " " end
            message = message .. arg
        end

        DEFAULT_CHAT_FRAME:AddMessage(message, 0.2, 0.8, 1.0)
    end
end

function aObj.Debug(...)
    if BCConf.Debug then
        local args = {...}
        local message = ""

        for i, arg in ipairs(args) do
            if i > 0 then message = message .. " " end
            message = message .. arg
        end

        DEFAULT_CHAT_FRAME:AddMessage(message, 1.0, 1.0, 1.0)
    end
end

SLASH_BC_REC1 = '/bcrec'
SlashCmdList['BC_REC'] = function(message)
    local unitName, _ = UnitName("player")
    aObj.HandleMessage(message, unitName)
end
