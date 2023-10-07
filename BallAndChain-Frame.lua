local aName, aObj = ...

local FOLLOWER_TIMEOUT = 90

local createFrame = function()
    local frame = CreateFrame("Frame")

    frame.texture = frame:CreateTexture()
    frame.texture:SetTexture("Interface/BUTTONS/WHITE8X8")

    frame.text = frame:CreateFontString(nil, "ARTWORK")
    frame.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")

    frame:SetHeight(19)
    frame.texture:SetAllPoints(frame)
    frame.text:SetPoint("CENTER", frame, "CENTER", 0, 0)

    return frame
end

local frame = CreateFrame("Frame", "BallAndChainFrame", UIParent,
                          "TooltipBorderedFrameTemplate")
frame:Hide()
frame:SetFrameStrata("BACKGROUND")
frame:SetWidth(100)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetPoint("CENTER", 0, 0)

frame.heading = frame:CreateFontString(nil, "ARTWORK")
frame.heading:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
frame.heading:SetPoint("TOP", 0, -10)
frame.heading:SetText("Followers")

function aObj.UpdateFrame()
    local sortedNames = {}

    for name, state in pairs(aObj.followers) do
        if state then table.insert(sortedNames, name) end
    end

    table.sort(sortedNames)

    local previousFrame = frame.heading
    local frameHeight = frame.heading:GetStringHeight() + 10
    local rows = 0

    for _, name in ipairs(sortedNames) do
        local follower = aObj.followers[name]

        if not follower.frame then
            follower.frame = createFrame()
            follower.frame.text:SetText(name)
        end

        if follower.following then
            follower.frame.texture:SetVertexColor(0.1, 0.7, 0.4)
        else
            follower.frame.texture:SetVertexColor(1, 0, 0)
        end

        follower.frame:SetPoint("TOP", previousFrame, "BOTTOM", 0, -5)
        follower.frame:SetWidth(frame:GetWidth() - 10)

        if follower.since > FOLLOWER_TIMEOUT then
            follower.frame:Hide()
        else
            follower.frame:Show()
            rows = rows + 1
        end

        previousFrame = follower.frame
        frameHeight = frameHeight + follower.frame:GetHeight() + 10
    end

    frame:SetHeight(frameHeight)

    if rows == 0 and BCConf.HideEmptyFrame then
        frame:Hide()
    else
        frame:Show()
    end
end
