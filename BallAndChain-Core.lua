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
    end,

    AUTOFOLLOW_BEGIN = function(sender, target)
        local playerName, _ = UnitName("player")

        if target ~= playerName and aObj.followers[sender] then
            if aObj.followers[sender].following then
                aObj.followers[sender].since = 0
            end
            aObj.followers[sender].following = false
            return
        end

        if not aObj.followers[sender] then aObj.followers[sender] = {} end

        aObj.followers[sender].following = true
        aObj.followers[sender].since = 0

        aObj.UpdateFrame()
    end,

    AUTOFOLLOW_END = function(sender)
        if aObj.followers[sender] and aObj.followers[sender].following then
            aObj.followers[sender].since = 0
            aObj.followers[sender].following = false
        end

        aObj.UpdateFrame()
    end

}

function aObj.SendEvent(event, ...)
    local message = event
    local args = {...}

    for _, arg in ipairs(args) do
        message = message .. ":"
        if arg ~= nil then message = message .. tostring(arg) end
    end

    aObj.Debug("Dispatch event", event)

    C_ChatInfo.SendAddonMessage(aName, message, "GUILD")
end

function aObj.Register()
    if not C_ChatInfo.IsAddonMessagePrefixRegistered(aName) then
        C_ChatInfo.RegisterAddonMessagePrefix(aName)
    end
    aObj.SendEvent("BC_REGISTER")
end

function aObj.SetFollowTarget(name)
    aObj.Debug("Setting followTarget to", name)
    aObj.followTarget = name
end

function aObj.ClearFollowTarget()
    aObj.Debug("Clearing followTargt")
    aObj.followTarget = nil
end

function aObj.Tick(elapsed)
    for _, follower in pairs(aObj.followers) do
        follower.since = follower.since + elapsed
    end

    aObj.UpdateFrame()

    if aObj.followTarget then
        local playerNAme, _ = UnitName("player")
        aObj.SendEvent("AUTOFOLLOW_BEGIN", playerName)
    else
        aObj.SendEvent("AUTOFOLLOW_END")
    end
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

    return EventHandler[event] and EventHandler[event](senderName, unpack(args))
end

function aObj.Print(...)
    local args = {...}
    local message = ""

    for i, arg in ipairs(args) do
        if i > 0 then message = message .. " " end
        message = message .. arg
    end

    DEFAULT_CHAT_FRAME:AddMessage(message, 0.2, 0.8, 1.0)
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

function aObj.Dump()
    aObj.Debug("FOLLOWERS")
    for name, follower in pairs(aObj.followers) do
        aObj.Debug("  --", name)
        aObj.Debug("   following :", tostring(follower.following))
        aObj.Debug("   since     :", tostring(follower.since))
    end
end

SLASH_BC_REC1 = '/bcrec'
SlashCmdList['BC_REC'] = function(message)
    local unitName, _ = UnitName("player")
    aObj.HandleMessage(message, unitName)
end

SLASH_BC_DUMP1 = '/bcdump'
SlashCmdList['BC_DUMP'] = function(message) aObj.Dump() end
