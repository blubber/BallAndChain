local aName, _ = ...

BCConf = {HideEmptyFrame = true, Debug = false}

local function createCheckBox(setting, parent, anchor, label, tooltip, offsetX,
                              offsetY)

    local offsetX = offsetX or 0
    local offsetY = offsetY or -28

    local checkButton = CreateFrame("CheckButton", nil, parent,
                                    "ChatConfigCheckButtonTemplate")

    checkButton:SetPoint("TOPLEFT", anchor, "TOPLEFT", offsetX, offsetY)

    checkButton.Text:SetText(label)
    checkButton.tooltip = tooltip

    checkButton:SetScript("OnClick", function(self)
        BCConf[setting] = self:GetChecked()

    end)

    checkButton:SetChecked(BCConf[setting])

    return checkButton
end

local panel = CreateFrame("Frame", nil, nil, "SettingsListTemplate")
panel:RegisterEvent("ADDON_LOADED")
panel.name = "Ball And Chain"
InterfaceOptions_AddCategory(panel)

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
title:SetPoint("TOPLEFT", 7, -22)
title:SetText("Ball And Chain")

panel:SetScript("OnEvent", function(self, event, ...)
    local args = {...}

    if event == "ADDON_LOADED" and args[1] == aName then
        local previous = createCheckBox("HideEmptyFrame", panel, panel,
                                        "Hide frame when it's empty",
                                        "Hide the followers frame when nobody has followed you for at least 90 seconds.",
                                        10, -75)
    end
end)
