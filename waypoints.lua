--[[
  WaypointAddon.lua
  A WoW 1.12 addon that allows you to add waypoints by entering coordinate pairs.

  The addon creates:
   - A button on WorldMapFrame ("Add WP").
   - A popup input frame that accepts coordinate text such as "9:90", "09,90", or "90 90".
   - It uses Lua pattern matching to extract two numbers from the input.
   - When the waypoint is added, it is stored in a table under the current zone name.
   - The addon then shows a simple red square icon on WorldMapButton at that coordinate.
--]] ------------------------------------------------
-- Global table to store waypoints by zone name:
-- The structure is:
-- Waypoints = {
--   ["Zone Name"] = { {cx,cy}, {cx,cy}, ... },
-- }
------------------------------------------------
Waypoints = {}

------------------------------------------------
-- Create a button on the World Map
------------------------------------------------
local wpButton = CreateFrame("Button", "AddWaypointButton", WorldMapFrame, "UIPanelButtonTemplate")
wpButton:SetWidth(80)
wpButton:SetHeight(22)
wpButton:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -10, -10)
wpButton:SetText("Add WP")

------------------------------------------------
-- Create the popup frame for entering coordinates
------------------------------------------------
local wpPopup = CreateFrame("Frame", "WaypointPopupFrame", WorldMapFrame)
wpPopup:SetWidth(220)
wpPopup:SetHeight(100)
wpPopup:SetPoint("CENTER", WorldMapFrame, "CENTER")
wpPopup:Hide()


wpPopup:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- Background texture
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", -- Border texture
    tile = true,
    tileSize = 32,
    edgeSize = 16,
    insets = {
        left = 4,
        right = 4,
        top = 4,
        bottom = 4
    } -- Adjust padding around the border
})

wpPopup:SetBackdropColor(0, 0, 0, 0.7) -- Set background color (black with 70% opacity)
wpPopup:SetBackdropBorderColor(1, 1, 1) -- Set border color (white)


wpPopup.title = wpPopup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
wpPopup.title:SetPoint("TOP", wpPopup, "TOP", 0, -10)
wpPopup.title:SetText("Enter Coordinates")

local wpEditBox = CreateFrame("EditBox", nil, wpPopup, "InputBoxTemplate")
wpEditBox:SetWidth(180)
wpEditBox:SetHeight(24)
wpEditBox:SetPoint("TOP", wpPopup, "TOP", 0, -40)
wpEditBox:SetAutoFocus(true)

local addButton = CreateFrame("Button", nil, wpPopup, "UIPanelButtonTemplate")
addButton:SetWidth(80)
addButton:SetHeight(22)
addButton:SetPoint("BOTTOMLEFT", wpPopup, "BOTTOMLEFT", 10, 10)
addButton:SetText("Add")

local cancelButton = CreateFrame("Button", nil, wpPopup, "UIPanelButtonTemplate")
cancelButton:SetWidth(80)
cancelButton:SetHeight(22)
cancelButton:SetPoint("BOTTOMRIGHT", wpPopup, "BOTTOMRIGHT", -10, 10)
cancelButton:SetText("Cancel")

------------------------------------------------
-- Function: Extract two numbers from a string using Lua pattern matching.
-- Acceptable delimiters: ", . : ; or any whitespace.
-- Pattern allows one or more digits on each side.
------------------------------------------------
local function ExtractCoordinates(input)
    local coord1, coord2
    string.gsub(input, "^(%d+%.?%d*)%s*[:.,;%s]+%s*(%d+%.?%d*)$", function(a, b)
        coord1 = a
        coord2 = b
    end)
    return coord1, coord2
end


local function print(message)
    DEFAULT_CHAT_FRAME:AddMessage(message, 1.0, 1.0, 0.0)
end

------------------------------------------------
-- Popup button handlers
------------------------------------------------
addButton:SetScript("OnClick", function()
    local text = wpEditBox:GetText()
    local num1, num2 = ExtractCoordinates(text)
    if num1 and num2 then
        local cx = tonumber(num1)
        local cy = tonumber(num2)
        local zone = GetMapInfo() -- store waypoint under current zone

        if not Waypoints[zone] then
            Waypoints[zone] = {}
        end
        table.insert(Waypoints[zone], {cx, cy})
        print(string.format("%s %s,%s %s %s", "Waypoint added:", cx, cy, "in zone", zone))

        wpPopup:Hide()
        wpEditBox:SetText("")
        UpdateWaypoints() -- update the icons on the map
    else
        print("Invalid coordinate format. Examples: 9:90, 09,90, 90 90")
    end
end)

cancelButton:SetScript("OnClick", function()
    wpPopup:Hide()
    wpEditBox:SetText("")
end)

wpButton:SetScript("OnClick", function()
    wpPopup:Show()
    wpEditBox:SetFocus()
end)

wpEditBox:SetScript("OnEnterPressed", function()
    local text = wpEditBox:GetText()

    local num1, num2 = ExtractCoordinates(text)
    if num1 and num2 then
        local cx = tonumber(num1)
        local cy = tonumber(num2)
        local zone = GetMapInfo() -- store waypoint under current zone

        if not Waypoints[zone] then
            Waypoints[zone] = {}
        end
        table.insert(Waypoints[zone], {cx, cy})
        print(string.format("%s %s,%s %s %s", "Waypoint added:", cx, cy, "in zone", zone))

        wpPopup:Hide()
        wpEditBox:SetText("")
        UpdateWaypoints() -- update the icons on the map
    else
        print("Invalid coordinate format. Examples: 9:90, 09,90, 90 90")
    end
end)


wpEditBox:SetScript("OnEscapePressed", function()
    wpPopup:Hide()
    wpEditBox:SetText("")
end)


------------------------------------------------
-- Waypoint icon handling
-- We store/reuse icons in a table to avoid creating duplicate icons.
------------------------------------------------
local wpIcons = {} -- list of icon frames for the current zone


local function Clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end


-- Updates/positions icons for waypoints on the World Map.
function UpdateWaypoints()
    local currentZone = GetMapInfo()
    local zoneData = Waypoints[currentZone]

    -- If there are no waypoints for this zone, hide any existing icons.
    if not zoneData then
        for i, icon in pairs(wpIcons) do
            icon:Hide()
        end
        return
    end

    -- For each stored waypoint in the current zone, create or update the icon.
    local numZoneData = table.getn(zoneData)
    for i = 1, numZoneData do
        local cx, cy = unpack(zoneData[i])
        if not wpIcons[i] then
            wpIcons[i] = CreateFrame("Frame", nil, WorldMapButton)
            wpIcons[i]:SetWidth(12)
            wpIcons[i]:SetHeight(12)
            wpIcons[i]:SetFrameStrata("TOOLTIP")
            local texture = wpIcons[i]:CreateTexture(nil, "OVERLAY")
            texture:SetAllPoints(wpIcons[i])
            local isHorde = (UnitFactionGroup("player") == "Horde" and true) or false

            if isHorde then
                texture:SetTexture("Interface\\Icons\\Inv_banner_03") -- horde wp
            else
                texture:SetTexture("Interface\\Icons\\Inv_banner_02") -- alliance wp
            end

            wpIcons[i].texture = texture
        end

        local icon = wpIcons[i]
        icon:Show()
        -- Position the icon on the map.
        local width = WorldMapButton:GetWidth()
        local height = WorldMapButton:GetHeight()
        -- Calculate offsets based on the normalized coordinates (0-100 stored, so divide by 100)

        local mapLeft = WorldMapButton:GetLeft()
        local mapTop = WorldMapButton:GetTop()
        local mapWidth = WorldMapButton:GetWidth()
        local mapHeight = WorldMapButton:GetHeight()
        local scale = WorldMapButton:GetEffectiveScale()

        -- Convert to screen space
        local x = (cx / 100) * mapWidth
        local y = ((cy / 100) * mapHeight)
        y = Clamp(y, 0, mapHeight) -12

        x = Clamp(x,0,mapWidth)



        -- Then proceed with absolute positioning (as per my previous message)

        -- Place icon using absolute screen coordinates
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", WorldMapButton, "TOPLEFT", x - (icon:GetWidth() / 2), -y - (icon:GetHeight() / 2)) -- negate Y for TOPLEFT anchoring


    end

    -- If there are extra icons (from a previous zone with more waypoints), hide them.
    local numWpIcons = table.getn(wpIcons)
    for i = numZoneData + 1, numWpIcons do
        wpIcons[i]:Hide()
    end
end

------------------------------------------------
-- Update waypoint icons as the map is updated/changed.
-- Because WoW 1.12’s WorldMapFrame doesn’t provide an event for every zoom/move,
-- we hook OnUpdate. (Be aware that this means the function runs every frame.)
------------------------------------------------
WorldMapFrame:SetScript("OnUpdate", function()
    UpdateWaypoints()
end)


