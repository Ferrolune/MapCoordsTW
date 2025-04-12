-- Global references
local wpButton = getglobal("AddWaypointButton")
local wpPopup = getglobal("WaypointPopupFrame")
local wpEditBox = getglobal("WayPointEditbox")
-- Add the keybinding header and names globally so the UI recognizes them
BINDING_HEADER_WAYPOINT_HEADER = "Waypoints"
BINDING_NAME_TOGGLE_WAYPOINT_POPUP = "Toggle Waypoint Popup"

-- Make sure this function is declared globally
function Waypoints_ToggleWaypointPopup()
    if(WorldMapFrame:IsVisible()) then
        if wpPopup:IsVisible() then
            wpPopup:Hide()
        else
            wpPopup:Show()
            wpEditBox:SetFocus()
        end
    end
end

