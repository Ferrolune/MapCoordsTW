local coordFrame = CreateFrame("Frame", "WorldMapCoordsFrame", WorldMapFrame)
coordFrame:SetWidth(200)
coordFrame:SetHeight(24)
coordFrame:SetPoint("BOTTOMLEFT", WorldMapFrame, "BOTTOMLEFT", 10, 10)

coordFrame.text = coordFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
coordFrame.text:SetAllPoints()

-- Returns true if the currently viewed map matches the player's zone.
local function IsMapPlayerZone()
    local mapZone = GetMapInfo()         -- current map name
    local playerZone = GetRealZoneText()   -- player's actual zone
    return mapZone == playerZone
end

-- Get the player's coordinates only if the current map matches their zone.
local function GetPlayerCoords()
    if not IsMapPlayerZone() then
        return nil, nil
    end
    local posX, posY = GetPlayerMapPosition("player")
    if posX and posY and posX > 0 and posY > 0 then
        return math.floor(posX * 100), math.floor(posY * 100)
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
        return math.floor(cx * 100), math.floor(cy * 100)
    end
    return nil, nil
end

-- OnUpdate loop to refresh the coordinate text.
coordFrame:SetScript("OnUpdate", function(self)
    self = coordFrame
    if not WorldMapFrame:IsVisible() then return end

    local playerX, playerY = GetPlayerCoords()
    local mouseX, mouseY = GetMouseCoords()

    local displayText = ""
    if playerX and playerY then
        displayText = displayText .. string.format("Player: %d, %d", playerX, playerY)
    else
        displayText = displayText .. "Player: --, --"
    end

    if mouseX and mouseY then
        displayText = displayText .. string.format(" | Mouse: %d, %d", mouseX, mouseY)
    else
        displayText = displayText .. " | Mouse: --, --"
    end

    self.text:SetText(displayText)
end)

