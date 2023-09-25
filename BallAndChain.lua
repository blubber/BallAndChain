local AddonName, A = ...

local UPDATE_INTERVAL = 10
local FORGET_AFTER = 120

local debug = false
local followers = {}
local followTarget = nil

--
-- Follower Frame
--
local frames = {}

function createFrame()
    local frame = table.remove(frames)
    if not frame then frame = CreateFrame("Frame") end

    return frame
end

function removeFrame(frame)
    frame:Hide()
    table.insert(frames, frame)
end
local BCFrame = CreateFrame("Frame", "BCFrame", UIParent,
                            "TooltipBorderedFrameTemplate")
BCFrame:Hide()
BCFrame:SetFrameStrata("BACKGROUND")
BCFrame:SetWidth(100)
BCFrame:SetMovable(true)
BCFrame:EnableMouse(true)
BCFrame:RegisterForDrag("LeftButton")
BCFrame:SetScript("OnDragStart", BCFrame.StartMoving)
BCFrame:SetScript("OnDragStop", BCFrame.StopMovingOrSizing)
BCFrame:SetPoint("CENTER", 0, 0)

BCFrame.heading = BCFrame:CreateFontString(nil, "ARTWORK")
BCFrame.heading:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
BCFrame.heading:SetPoint("TOP", 0, -10)
BCFrame.heading:SetText("Followers")

function updateFrame()
    local sortedNames = {}

    for name, state in pairs(followers) do
        if state then table.insert(sortedNames, name) end
    end

    table.sort(sortedNames)

    local previousFrame = BCFrame.heading
    local frameHeight = BCFrame.heading:GetStringHeight() + 10

    for _, name in ipairs(sortedNames) do
        local state = followers[name]

        if state.frame == nil then
            state.frame = createFrame()
            state.frame.texture = state.frame:CreateTexture()
            state.frame.texture:SetTexture("Interface/BUTTONS/WHITE8X8")
            state.frame.texture:SetAllPoints(state.frame)

            state.frame.text = state.frame:CreateFontString(nil, "ARTWORK")
            state.frame.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
            state.frame.text:SetText(name)

            state.frame:SetHeight(state.frame.text:GetStringHeight() + 6)
            state.frame.text:SetPoint("CENTER", state.frame, "CENTER", 0, 0)
        end

        if state.following then
            state.frame.texture:SetVertexColor(0.1, 0.7, 0.4)
        else
            state.frame.texture:SetVertexColor(1, 0, 0)
        end

        state.frame:SetPoint("TOP", previousFrame, "BOTTOM", 0, -5)
        state.frame:SetWidth(BCFrame:GetWidth() - 10)
        state.frame:Show()

        previousFrame = state.frame
        frameHeight = frameHeight + state.frame:GetHeight() + 10
    end

    BCFrame:SetHeight(frameHeight)

    if #sortedNames == 0 and BCConf.HideEmptyFrame then
        BCFrame:Hide()
    else
        BCFrame:Show()
    end
end

--
-- Events
--

local timeSinceLastUpdate = 0

local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("AUTOFOLLOW_BEGIN")
EventFrame:RegisterEvent("AUTOFOLLOW_END")
EventFrame:RegisterEvent("CHAT_MSG_ADDON")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:SetScript("OnEvent", function(self, event, ...)
    return self[event] and self[event](self, ...)
end)
EventFrame:SetScript("OnUpdate", function(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
    if timeSinceLastUpdate >= UPDATE_INTERVAL then
        local shouldUpdate = false

        if followTarget then notify_follow(followTarget) end

        for name, state in pairs(followers) do
            if state then
                state.since = state.since + timeSinceLastUpdate

                if state.since >= FORGET_AFTER then
                    removeFrame(state.frame)
                    followers[name] = nil
                    shouldUpdate = true
                end
            end
        end

        timeSinceLastUpdate = 0
        if shouldUpdate then updateFrame() end
    end
end)

function EventFrame:AUTOFOLLOW_BEGIN(name)
    notify_unfollow();
    notify_follow(name)
end

function EventFrame:AUTOFOLLOW_END() notify_unfollow() end

function EventFrame:CHAT_MSG_ADDON(prefix, message, channel, sender, target, _,
                                   _, _)
    if prefix == AddonName then parse_message(message, sender) end
end

function EventFrame:ADDON_LOADED(addonName, _)
    if addonName == AddonName then
        C_ChatInfo.RegisterAddonMessagePrefix(AddonName)
        updateFrame();
    end
end

--
-- Message Halding
--

local Commands = {FOLLOW = "F", UNFOLLOW = "U"}

function notify_follow(target)
    followTarget = target
    send_message(Commands.FOLLOW, followTarget)
end

function notify_unfollow()
    if followTarget then send_message(Commands.UNFOLLOW, followTarget) end

    followTarget = nil
end

function send_message(command, ...)
    local message = command
    local arg = {...}

    for _, v in ipairs(arg) do message = message .. ":" .. v end

    if debug then
        DEFAULT_CHAT_FRAME:AddMessage(AddonName .. " " .. message, 1.0, 1.0, 0.0)
    end
    C_ChatInfo.SendAddonMessage(AddonName, message, "GUILD")
end

function A:FOLLOW(sender, args)
    if #args ~= 1 then return end

    local target = args[1]
    local unitName, _ = UnitName("player")

    if target ~= unitName and followers[sender] then
        followers[sender].following = false
    end

    if target == unitName then
        if followers[sender] == nil then
            followers[sender] = {since = 0, following = true}
        else
            followers[sender].following = true
            followers[sender].since = 0
        end
    end

    updateFrame()
end

function A:UNFOLLOW(sender, args)
    if #args ~= 1 then return end

    local followee = args[1]
    local unitName, _ = UnitName("player")

    if followee ~= unitName then return end

    if followers[sender] == nil then
        followers[sender] = {since = 0, following = false}
    else
        followers[sender].following = false
        followers[sender].since = 0
    end

    updateFrame()
end

function parse_message(message, sender)
    if debug then
        DEFAULT_CHAT_FRAME:AddMessage("Receive message: " .. message ..
                                          " from: " .. sender, 1.0, 1.0, 0.0)
    end

    local command = ""
    local args = {}

    for v in string.gmatch(message, "([^:]+)") do
        if command == "" then
            command = v
        else
            table.insert(args, v)
        end
    end

    for k, v in pairs(Commands) do
        if v == command then return A[k] and A[k](A, sender, args) end
    end
end

--
-- Slash commands
--

SLASH_BC_REC1 = '/bcrec'
SlashCmdList['BC_REC'] = function(message)
    local unitName, _ = UnitName("player")
    parse_message(message, unitName)
end

SLASH_BC_DEBUG1 = "/bcdebug"
SlashCmdList['BC_DEBUG'] = function(message)
    debug = not debug
    if debug then print("Debug on") end
end
