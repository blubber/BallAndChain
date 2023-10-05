local aName, aObj = ...

local timeSinceLastUpdate = 0
local sharedEvents = {
    AUTOFOLLOW_BEGIN = true,
    AUTOFOLLOW_END = true,
    QUEST_ACCEPTED = true,
    QUEST_AUTOCOMPLETE = true,
    QUEST_TURNED_IN = true
}

local frame = CreateFrame("Frame")

frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("ADDON_LOADED")

for event in pairs(sharedEvents) do frame:RegisterEvent(event) end

frame:SetScript("OnEvent", function(self, event, ...)
    local _ = self[event] and self[event](self, ...)
    return sharedEvents[event] and aObj.SendEvent(event, ...)
end)

frame:SetScript("OnUpdate", function(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed

    if timeSinceLastUpdate >= 10 then
        aObj.Tick(timeSinceLastUpdate)
        timeSinceLastUpdate = 0
    end
end)

function frame:AUTOFOLLOW_BEGIN(name) aObj.SetFollowTarget(name) end

function frame:AUTOFOLLOW_END() aObj.ClearFollowTarget() end

function frame:CHAT_MSG_ADDON(prefix, message, channel, sender, target, _, _, _)
    if prefix == aName then aObj.HandleMessage(message, sender) end
end

function frame:ADDON_LOADED(addonName, _)
    if addonName == aName then
        aObj.Register()
        aObj.Tick(0)
    end
end
