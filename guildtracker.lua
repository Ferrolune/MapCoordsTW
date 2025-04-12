local GuildMates = {}
local lastUpdateTime = 0
local lastCleanupTime = 0

-- Send waypoint data
local lastValidCoordinates = {
    x = 0,
    y = 0
}
local lastValidZone = ""

-- Send waypoint data
local function SendWaypoint()
    local name = UnitName("player")
    local currentZone = GetZoneLongName(GetMapInfo())
    local playerZone = GetZoneText()
    local playerClass = UnitClass("player")
    local x, y = GetPlayerMapPosition("player")
    x = math.floor(x * 10000 + 0.5) / 100
    y = math.floor(y * 10000 + 0.5) / 100

    -- Check if the player is in the same zone or if it's a zone change
    if currentZone == playerZone then
        -- Update last valid coordinates only if they're different
        if lastValidCoordinates.x ~= x or lastValidCoordinates.y ~= y then
            lastValidCoordinates.x = x
            lastValidCoordinates.y = y
            lastValidZone = currentZone
        end
    else
        -- If zones don't match, send the last valid coordinates
        x = lastValidCoordinates.x
        y = lastValidCoordinates.y
        currentZone = lastValidZone -- Use the last valid zone name
    end

    -- Construct the message to send
    local msg = string.format("%s,%s,%.2f,%.2f,%s", name, currentZone, x, y, playerClass)
    SendAddonMessage("WAYPOINTSTW", msg, "GUILD")
end

-- Convert short zone name to long using global table
 function GetZoneLongName(shortName)
    local lookup = getglobal("WaypointPopupFrame").ZoneShortsToFullName
    return lookup and lookup[shortName] or shortName
end
 function Clamp(val, min, max)
    if val < min then
        return min
    end
    if val > max then
        return max
    end
    return val
end

local function HideAllMarkers()
    for pname, data in pairs(GuildMates) do
        if data.marker then
            data.marker:Hide() -- Hide the marker for all guildmates
        end
    end
end


-- Create or move a marker for the guildmate on the world map
-- Function to update or create the map marker for a guildmate
function UpdateMapMarker(pname, x, y)
    -- Get the current zone of the player
    local currentZone = GetZoneLongName(GetMapInfo())

    -- Check if the guildmate is in the same zone
    if GuildMates[pname] and GuildMates[pname].zone == currentZone then

        -- Ensure we have a valid marker
        local guildmate = GuildMates[pname]

        if not guildmate.marker then
            -- Create the marker if it doesn't exist
            guildmate.marker = CreateFrame("Frame", nil, WorldMapButton)
            guildmate.marker:SetWidth(20)
            guildmate.marker:SetHeight(20)
            guildmate.marker:SetFrameStrata("FULLSCREEN")

            local texture = guildmate.marker:CreateTexture(nil, "OVERLAY")
            texture:SetTexture(GuildMates[pname].icon)
            --texture:SetTexture("Interface\\Icons\\Inv_banner_03")

            texture:SetAllPoints(guildmate.marker)

            guildmate.marker.texture = texture
        end

        -- Position the marker based on the coordinates
        local mapWidth = WorldMapButton:GetWidth()
        local mapHeight = WorldMapButton:GetHeight()

        -- Convert x, y to screen coordinates based on the map size (using 0-100 scale)
        local xPos = (x / 100) * mapWidth
        local yPos = (y / 100) * mapHeight

        -- Clamp the positions to make sure they don't go outside the map boundaries
        xPos = Clamp(xPos, 0, mapWidth)
        yPos = Clamp(yPos, 0, mapHeight)

        -- Set the position of the marker (adjusting for anchor position)
        guildmate.marker:ClearAllPoints()
        guildmate.marker:SetPoint("TOPLEFT", WorldMapButton, "TOPLEFT", xPos - (guildmate.marker:GetWidth() / 2),
            -(yPos - (guildmate.marker:GetHeight() / 2)))

        guildmate.marker:Show()
    elseif guildmate and guildmate.marker then
        -- Hide the marker if the guildmate is not in the current zone
        guildmate.marker:Hide()
    end
end



-- Frame for OnUpdate ticking
local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", function()
    local now = GetTime()

    -- Send player data ~60 times a second
    if now - lastUpdateTime >= 0.016 then
        lastUpdateTime = now
        SendWaypoint()
        HideAllMarkers()
    end

    -- Cleanup stale guildmate data every 20 seconds
    if now - lastCleanupTime >= 20 then
        lastCleanupTime = now
        for pname, data in pairs(GuildMates) do
            if now - data.lastupdate > 20 then
                -- Remove the marker if the guildmate data is outdated
                if data.marker then
                    data.marker:Hide()
                    data.marker = nil
                end
                GuildMates[pname] = nil
            end
        end
    end

    -- Loop through the GuildMates table and check if any guildmate is in the same zone
    local playerZone = GetZoneLongName(GetZoneText()) -- Current zone of the player

    for pname, data in pairs(GuildMates) do
        if data.zone == playerZone then
            -- Add or move the marker for guildmate if they are in the same zone
            UpdateMapMarker(pname, data.x, data.y)
        else
            -- Hide the marker if the guildmate is not in the same zone
            if data.marker then
                data.marker:Hide()
            end
        end
    end
end)

-- Receive and store/update guildmate data
local eventReceiver = CreateFrame("Frame")
eventReceiver:RegisterEvent("CHAT_MSG_ADDON")
eventReceiver:SetScript("OnEvent", function()
    if event == "CHAT_MSG_ADDON" and arg1 == "WAYPOINTSTW" then
        local pname, zone, x, y, class
        local i = 0
        string.gsub(arg2, "([^,]+)", function(match)
            i = i + 1
            if i == 1 then
                pname = match
            elseif i == 2 then
                zone = match
            elseif i == 3 then
                x = tonumber(match)
            elseif i == 4 then
                y = tonumber(match)
            elseif i == 5 then
                class = match
            end
        end)
        if pname and zone and x and y then
            -- Check if the guildmate already exists in the table
            if GuildMates[pname] then
                -- Update the existing guildmate data (no need to reset marker to nil)
                GuildMates[pname].zone = zone
                GuildMates[pname].x = x
                GuildMates[pname].y = y
                GuildMates[pname].lastupdate = GetTime()
                GuildMates[pname].class = class
                -- If the player is in the same zone, move the marker or show it
                if GetZoneLongName(GetZoneText()) == zone then
                    UpdateMapMarker(pname, x, y)
                elseif GuildMates[pname].marker then
                    GuildMates[pname].marker:Hide() -- Hide the marker if the guildmate is not in the same zone
                end
            else
                -- Create a new entry for the guildmate if not already in the table
                GuildMates[pname] = {
                    zone = zone,
                    x = x,
                    y = y,
                    class = class,
                    lastupdate = GetTime(),
                    marker = nil, -- Initially no marker
                    icon = getglobal("WaypointPopupFrame").classIcons[class]
                }

                -- If the player is in the same zone, create the marker right away
                if GetZoneLongName(GetZoneText()) == zone then
                    UpdateMapMarker(pname, x, y)
                end
            end

            -- Debug message (optional)
            -- print(string.format("|cffffcc00[Waypoint]|r %s in %s at (%.2f, %.2f) class %s", pname, zone, x, y, class))
        end

    end
end)
function print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)

end


-- Optional for some servers
if RegisterAddonMessagePrefix then
    RegisterAddonMessagePrefix("WAYPOINTSTW")
end



-- This function will be called when the map is clicked.
local function OnMapClick()
    local currentZone = GetZoneLongName(GetMapInfo()) -- Get current zone name

    -- Loop through the GuildMates table and check if their zone matches the current zone
    for pname, data in pairs(GuildMates) do
        if data.zone == currentZone then
            -- Show the marker if they are in the same zone
            if data.marker then
                data.marker:Show()
            end
        else
            -- Hide the marker if they are not in the same zone
            if data.marker then
                data.marker:Hide()
            end
        end
    end
end

-- You can hook this function to a map-related event. For example:
WorldMapButton:SetScript("OnClick", function(self, button)
    OnMapClick() -- When the map is clicked, run the OnMapClick function
end)

-- Or use an event-based approach
local mapUpdateFrame = CreateFrame("Frame")
mapUpdateFrame:RegisterEvent("WORLD_MAP_UPDATE")
mapUpdateFrame:SetScript("OnEvent", function(self, event, ...)
    OnMapClick() -- Call OnMapClick when the world map is updated
end)
