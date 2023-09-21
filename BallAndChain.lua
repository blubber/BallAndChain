local AddonName, A = ...

local DEBUG = true

A.timeSinceLastUpdate = 0
A.updateInterval = 10
A.forgetAfter = 300

A.followers = {}

A.CMD_FOLLOW = "F"
A.CMD_UNFOLLOW = "U"

local followTarget = nil

function send_message(command, ...)
    local message = command
    local arg = {...}

    print(select("#", ...))

    for _, v in ipairs(arg) do message = message .. ":" .. v end

    if DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage(AddonName .. " " .. message, 1.0, 1.0, 0.0)
    end
    C_ChatInfo.SendAddonMessage(AddonName, message, "GUILD")
end

function handle_follow(sender, args)
    if #args ~= 1 then return end

    local target = args[1]

    if target ~= UnitName("player") and A.followers[sender] then
        A.followers[sender].following = false
        return
    end

    if A.followers[sender] == nil then
        A.followers[sender] = {since = 0, following = true}
    else
        A.followers[sender].following = true
        A.followers[sender].since = 0
    end

    updateFrame()
end

function handle_unfollow(sender, args)
    if #args ~= 1 then return end

    local followee = args[1]

    if followee ~= UnitName("player") then return end

    if A.followers[sender] == nil then
        A.followers[sender] = {since = 0, following = false}
    else
        A.followers[sender].following = false
        A.followers[sender].since = 0
    end

    updateFrame()
end

function parse_message(message, sender)
    if DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("Receive message: " .. message ..
                                          " from: " .. sender, 1.0, 1.0, 0.0)

        local command = ""
        local args = {}

        for v in string.gmatch(message, "([^:]+)") do
            if command == "" then
                command = v
            else
                table.insert(args, v)
            end
        end

        if command == A.CMD_FOLLOW then
            handle_follow(sender, args)
        elseif command == A.CMD_UNFOLLOW then
            handle_unfollow(sender, args)
        end
    end
end

--
-- Frames
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

local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("AUTOFOLLOW_BEGIN")
EventFrame:RegisterEvent("AUTOFOLLOW_END")
EventFrame:RegisterEvent("CHAT_MSG_ADDON")
EventFrame:SetScript("OnEvent", function(self, event, ...)
    return self[event] and self[event](self, ...)
end)
EventFrame:SetScript("OnUpdate", function(self, elapsed)
    A.timeSinceLastUpdate = A.timeSinceLastUpdate + elapsed
    if A.timeSinceLastUpdate >= A.updateInterval then
        local shouldUpdate = false

        if followTarget then sned_message(A.CMD_FOLLOW, followTarget) end

        for name, state in pairs(A.followers) do
            state.since = state.since + A.timeSinceLastUpdate

            if state.since >= A.forgetAfter then
                removeFrame(state.frame)
                A.followers[name] = nil
                shouldUpdate = true
            end
        end

        A.timeSinceLastUpdate = 0
        if shouldUpdate then updateFrame() end
    end
end)

local BCFrame = CreateFrame("Frame", "BCFrame", UIParent,
                                   "TooltipBorderedFrameTemplate")
BCFrame:SetFrameStrata("BACKGROUND")
BCFrame:SetWidth(100)
BCFrame:SetHeight(128)
BCFrame:SetMovable(true)
BCFrame:EnableMouse(true)
BCFrame:RegisterForDrag("LeftButton")
BCFrame:SetScript("OnDragStart", BCFrame.StartMoving)
BCFrame:SetScript("OnDragStop", BCFrame.StopMovingOrSizing)


BCFrame:SetPoint("CENTER", 0, 0)
BCFrame:Show()

BCFrame.heading = BCFrame:CreateFontString(nil, "ARTWORK")
BCFrame.heading:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
BCFrame.heading:SetPoint("TOP", 0, -10)
BCFrame.heading:SetText("Followers")

function updateFrame()
    local sortedNames = {}

    for name in pairs(A.followers) do table.insert(sortedNames, name) end

    table.sort(sortedNames)

    local previousFrame = BCFrame.heading
    local frameHeight = BCFrame.heading:GetStringHeight() + 10

    for _, name in ipairs(sortedNames) do
        local state = A.followers[name]

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

        print(state.frame:GetHeight())
    end

    BCFrame:SetHeight(frameHeight)
end

function EventFrame:AUTOFOLLOW_BEGIN(name)
    if followTarget then send_message(A.CMD_UNFOLLOW, followTarget) end

    followTarget = name

    send_message(A.CMD_FOLLOW, followTarget)
end

function EventFrame:AUTOFOLLOW_END()
    send_message(A.CMD_UNFOLLOW)
    send_message(A.CMD_UNFOLLOW, followTarget)
    followTarget = nil
end

function EventFrame:CHAT_MSG_ADDON(prefix, message, channel, sender, target, _,
                                   _, _)
    if prefix == AddonName then parse_message(message, sender) end
end

--
-- Slash commands
--

SLASH_BC_REC1 = '/bcrec'
SlashCmdList['BC_REC'] = function(message)
    parse_message(message, UnitName("player"))
end
