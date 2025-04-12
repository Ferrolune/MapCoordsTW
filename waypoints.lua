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
    -- Use gsub with a function callback to capture the two numbers.
    string.gsub(input, "^(%d+)%s*[:.,;%s]+%s*(%d+)$", function(a, b)
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

------------------------------------------------
-- Waypoint icon handling
-- We store/reuse icons in a table to avoid creating duplicate icons.
------------------------------------------------
local wpIcons = {} -- list of icon frames for the current zone

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
            wpIcons[i] = CreateFrame("Frame", nil, WorldMapFrame)
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
        icon:SetPoint("TOPLEFT", WorldMapButton, "TOPLEFT", (cx / 100) * width - (icon:GetWidth() / 2),
            -(cy / 100) * height - (icon:GetHeight() / 2))


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
