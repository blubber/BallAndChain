local aName, aObj = ...

aObj.followTarget = nil
aObj.followers = {}

local Command = {FOLLOW = "F", UNFOLLOW = "U", REGISTER = "R"}
local Event = {}

local send_message = function(command, ...)
    local message = command
    local args = {...}

    for _, arg in ipairs(args) do message = message .. ":" .. arg end

    aObj.Debug("Sending message", message)

    C_ChatInfo.SendAddonMessage(aName, message, "GUILD")
end

function aObj.Follow(name)
    aObj.followTarget = name
    send_message(Command.FOLLOW, name)
end

function aObj.Unfollow()
    aObj.followTargete = nil
    send_message(Command.UNFOLLOW)
end

function aObj.Register()
    if not C_ChatInfo.IsAddonMessagePrefixRegistered(aName) then
        C_ChatInfo.RegisterAddonMessagePrefix(aName)
    end
    send_message(Command.REGISTER)
end

function aObj.NotifyFollow(name) send_message(Command.FOLLOW, name) end

function aObj.NotifyUnfollow() send_message(Command.UNFOLLOW) end

function aObj.Tick(elapsed)
    for _, follower in pairs(aObj.followers) do
        follower.since = follower.since + elapsed
    end

    if aObj.followTarget then
        send_message(Command.FOLLOW, aObj.followTarget)
    else
        send_message(Command.UNFOLLOW)
    end

    aObj.UpdateFrame()
end

function aObj.HandleMessage(message, sender)
    local senderName = gsub(sender, "%-[^|]+", "")

    aObj.Debug("Receive from", senderName, " -- ", message)

    local command = nil
    local args = {}

    for v in string.gmatch(message, "([^:]+)") do
        if not command then
            command = v
        else
            table.insert(args, v)
        end
    end

    for k, v in pairs(Command) do
        if v == command then return Event[k] and Event[k](sender, args) end
    end
end

function Event:REGISTER(sender, args)
    if aObj.followTarget then
        send_message(Command.FOLLOW, aObj.followTarget)
    else
        send_message(Command.UNFOLLOW)
    end
end

function Event.FOLLOW(source, args)
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

function Event.UNFOLLOW(source, args)
    aObj.Debug(source, "stoppped following")

    if aObj.followers[source] then
        if aObj.followers[source].following then
            aObj.followers[source].since = 0
        end
        aObj.followers[source].following = false
    end

    aObj.UpdateFrame()
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
