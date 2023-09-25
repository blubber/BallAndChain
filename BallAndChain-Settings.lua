local AddonName, _ = ...

BCConf = {HideEmptyFrame = true, Debug = false}

local CheckButtons = {
    {
        setting = "HideEmptyFrame",
        title = "Hide empty frame",
        tooltip = "Hide the followers frame when nobody has followed you for a while.",
        checkButton = nil
    }
}

local panel = CreateFrame("Frame")
panel.name = "Ball And Chain"
InterfaceOptions_AddCategory(panel)

local title = panel:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
title:SetPoint("TOP")
title:SetText("Ball And Chain")

panel:RegisterEvent("ADDON_LOADED")
panel:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name, _ = ...

        if name ~= AddonName then return end

        createCheckButtons()
    end
end)

function createCheckButtons()
    local anchor = panel
    local offset = -50

    for _, checkButton in ipairs(CheckButtons) do
        anchor = createCheckButton(checkButton, anchor, offset)
        offset = -20
    end
end

function createCheckButton(checkButton, anchor, offset)
    local button = CreateFrame("CheckButton", nil, panel,
                               "ChatConfigCheckButtonTemplate")
    button:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, offset)
    button.Text:SetText(checkButton.title)
    button.tooltip = checkButton.tooltip
    button:HookScript("OnClick", function(self)
        BCConf[checkButton.setting] = self:GetChecked()
    end)

    checkButton.checkButton = button

    return button
end
