local aName, aObj = ...

local timeSinceLastUpdate = 0

local frame = CreateFrame("Frame")

frame:RegisterEvent("AUTOFOLLOW_BEGIN")
frame:RegisterEvent("AUTOFOLLOW_END")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, ...)
    return self[event] and self[event](self, ...)
end)

frame:SetScript("OnUpdate", function(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed

    if timeSinceLastUpdate >= 10 then
        aObj.Tick(timeSinceLastUpdate)
        timeSinceLastUpdate = 0
    end
end)

function frame:AUTOFOLLOW_BEGIN(name)
    aObj.Unfollow()
    aObj.Follow(name)
end

function frame:AUTOFOLLOW_END() aObj.Unfollow() end

function frame:CHAT_MSG_ADDON(prefix, message, channel, sender, target, _,
                                   _, _)
    if prefix == aName then aObj.HandleMessage(message, sender) end
end

function frame:ADDON_LOADED(addonName, _)
    if addonName == aName then
        aObj.Register()
        aObj.Tick(0)
    end
end