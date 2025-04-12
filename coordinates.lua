local coordFrame = CreateFrame("Frame", "WorldMapCoordsFrame", WorldMapFrame)
coordFrame:SetWidth(300)
coordFrame:SetHeight(24)
coordFrame:SetPoint("BOTTOMLEFT", WorldMapFrame, "BOTTOMLEFT", 0, 0)

coordFrame.text = coordFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
coordFrame.text:SetPoint("LEFT", coordFrame, "LEFT", 10, 0) -- This ensures the text is anchored to the bottom-left corner

-- Returns true if the currently viewed map matches the player's zone.
local function IsMapPlayerZone()
    local mapZone = GetMapInfo()
    local playerZone = GetRealZoneText()
    return mapZone == playerZone
end

-- Get the player's coordinates only if the current map matches their zone.
local function GetPlayerCoords()
    if not IsMapPlayerZone() then
        return nil, nil
    end
    local posX, posY = GetPlayerMapPosition("player")
    if posX and posY and posX > 0 and posY > 0 then
        return string.format("%.1f", posX * 100), string.format("%.1f", posY * 100)
    end
    return nil, nil
end

-- Get mouse cursor coordinates relative to the map.
local function GetMouseCoords()
    local left = WorldMapButton:GetLeft()
    local top = WorldMapButton:GetTop()
    local width = WorldMapButton:GetWidth()
    local height = WorldMapButton:GetHeight()
    local scale = WorldMapButton:GetEffectiveScale()

    local x, y = GetCursorPosition()
    x = x / scale
    y = y / scale

    local cx = (x - left) / width
    local cy = (top - y) / height

    if cx >= 0 and cx <= 1 and cy >= 0 and cy <= 1 then
        return string.format("%.1f", cx * 100), string.format("%.1f", cy * 100)
    end
    return nil, nil
end


local function UpdateCoordTextLocation()
    if (WorldMapFrameMaximizeButton:IsVisible()) then
        coordFrame:SetPoint("BOTTOMLEFT", WorldMapFrame, "BOTTOMLEFT", 0, 8)
    else
        coordFrame:SetPoint("BOTTOMLEFT", WorldMapFrame, "BOTTOMLEFT", 0, -18)
    end
end


-- OnUpdate loop to refresh the coordinate text.
coordFrame:SetScript("OnUpdate", function()
    self = coordFrame
    if not WorldMapFrame:IsVisible() then
        return
    end
    UpdatewpButtonLocation()
    UpdateCoordTextLocation()

    local playerX, playerY = GetPlayerCoords()
    local mouseX, mouseY = GetMouseCoords()

    local displayText = ""
    if playerX and playerY then
        displayText = displayText .. "Player: " .. playerX .. ", " .. playerY
    else
        displayText = displayText .. "Player: --, --"
    end

    if mouseX and mouseY then
        displayText = displayText .. " | Mouse: " .. mouseX .. ", " .. mouseY
    else
        displayText = displayText .. " | Mouse: --, --"
    end

    self.text:SetText(displayText)
end)
