-- Wanna fix the formatting so it's aligned.


local FONT_NAME = "Fonts\\FRIZQT__.TTF"

-- This should be aligned in a nice way and not like this prob.
-- Left align text and right align numbers?
local AVG_DELAY_TEXT = "Avg:"
local CURR_DELAY_TEXT = "Delay:"
local MIN_DELAY_TEXT = "Min:"
local MAX_DELAY_TEXT = "Max:"
local TOO_EARLY_TEXT = "Early:"
local SLAM_MELEE_TEXT = "Ratio:"

local f = CreateFrame("Frame", "SlamDelayFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local currlabel = f:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
local currlabeltxt = f:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
local avglabel = f:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
local avglabeltxt = f:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
local minlabel = f:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
local minlabeltxt = f:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
local maxlabel = f:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
local maxlabeltxt = f:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
local tooearlylabel = f:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
local tooearlylabeltxt = f:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
local slammeleelabel = f:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
local slammeleelabeltxt = f:CreateFontString(nil, "ARTWORK", "ChatFontNormal")

local prev_melee_ts = nil
local total_delay = 0
local total_slams = 0
local total_melee = 0
local min_delay = nil
local max_delay = 0
local too_early_count = 0

function avglabel:Update()
   if total_slams > 0 then
      local avg_delay = total_delay / total_slams
      avglabel:SetText(string.format("%.3f", avg_delay))
   else
      avglabel:SetText("-")
   end
end

function minlabel:Update()
   if total_slams > 0 then
      minlabel:SetText(string.format("%.3f", min_delay))
   else
      minlabel:SetText("-")
   end
end

function maxlabel:Update()
   if total_slams > 0 then
      maxlabel:SetText(string.format("%.3f", max_delay))
   else
      maxlabel:SetText("-")
   end
end

function tooearlylabel:Update()
   if total_slams > 0 then
      tooearlylabel:SetText(string.format("%d", too_early_count))
   else
      tooearlylabel:SetText("-")
   end
end

function currlabel:Update(delay)
   if delay then
      currlabel:SetText(string.format("%.3f", delay))
   else
      currlabel:SetText("-")
   end
end

function slammeleelabel:Update()
   slammeleelabel:SetText(string.format("%d/%d", total_slams, total_melee))
end


function f:OnEvent(event, ...)
   self[event](self, event, ...)
end

function f:COMBAT_LOG_EVENT_UNFILTERED(event)
   local combat_info = {CombatLogGetCurrentEventInfo()}
   local timestamp, event, _, source_guid, _, _, _, dest_guid, _, _, _, _, spell_name, _ = unpack(combat_info)
   local skip_next_attack = false
   -- make player guid local
   if source_guid == UnitGUID("player") then
      if event == "SPELL_EXTRA_ATTACKS" then
         skip_next_attack = true
      elseif event == "SWING_DAMAGE" or event == "SWING_MISSED" then
         local _, _, _, _, _, _, _, _, _, is_offhand = select(12, unpack(combat_info))
         if not is_offhand then
            if not skip_next_attack then
               prev_melee_ts = timestamp
               total_melee = total_melee + 1
               slammeleelabel:Update()
            else
               skip_next_attack = false
            end
         end
      elseif event == "SPELL_CAST_SUCCESS" and (spell_name == "Heroic Strike" or spell_name == "Cleave") then
         if not skip_next_attack then
            prev_melee_ts = timestamp
            total_melee = total_melee + 1
            slammeleelabel:Update()
         else
            skip_next_attack = false
         end
      elseif event == "SPELL_CAST_SUCCESS" and spell_name == "Slam" then
         if prev_melee_ts then
            -- Update current delay
            local delay = timestamp - prev_melee_ts - 0.5
            currlabel:Update(delay)

            -- Update average delay
            total_delay = total_delay + delay
            total_slams = total_slams + 1
            avglabel:Update()

            -- Update melee/slam ratio
            slammeleelabel:Update()

            -- Update min delay
            if not min_delay or delay < min_delay then
               min_delay = delay
               minlabel:Update()
            end

            -- Update max delay
            if delay > max_delay then
               max_delay = delay
               maxlabel:Update()
            end

            -- Check for early slams
            if delay > 3 then
               too_early_count = too_early_count + 1
               tooearlylabel:Update()
            end
         end
      end
   end
end

f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:SetScript("OnEvent", f.OnEvent)

-- Make frame draggable with mouse
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)


f:SetPoint("CENTER")
f:SetSize(96, 88)
f:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
f:SetBackdropColor(0, 0, 1, .5)


currlabel:SetTextColor(0.8, 0.8, 0.8, 1)
currlabel:SetPoint("TOPRIGHT", -8, -8)
currlabel:SetFont(FONT_NAME, 12)
currlabel:Update()
currlabel:Show()

currlabeltxt:SetTextColor(0.8, 0.8, 0.8, 1)
currlabeltxt:SetPoint("TOPLEFT", 8, -8)
currlabeltxt:SetFont(FONT_NAME, 12)
currlabeltxt:SetText(CURR_DELAY_TEXT)
currlabeltxt:Show()


avglabel:SetTextColor(0.8, 0.8, 0.8, 1)
avglabel:SetPoint("TOPRIGHT", -8, -currlabel:GetHeight()-8)
avglabel:SetFont(FONT_NAME, 12)
avglabel:Update()
avglabel:Show()

avglabeltxt:SetTextColor(0.8, 0.8, 0.8, 1)
avglabeltxt:SetPoint("TOPLEFT", 8, -currlabel:GetHeight()-8)
avglabeltxt:SetFont(FONT_NAME, 12)
avglabeltxt:SetText(AVG_DELAY_TEXT)
avglabeltxt:Show()


minlabel:SetTextColor(0.8, 0.8, 0.8, 1)
minlabel:SetPoint("TOPRIGHT", -8, -currlabel:GetHeight()*2-8)
minlabel:SetFont(FONT_NAME, 12)
minlabel:Update()
minlabel:Show()

minlabeltxt:SetTextColor(0.8, 0.8, 0.8, 1)
minlabeltxt:SetPoint("TOPLEFT", 8, -currlabel:GetHeight()*2-8)
minlabeltxt:SetFont(FONT_NAME, 12)
minlabeltxt:SetText(MIN_DELAY_TEXT)
minlabeltxt:Show()


maxlabel:SetTextColor(0.8, 0.8, 0.8, 1)
maxlabel:SetPoint("TOPRIGHT", -8, -currlabel:GetHeight()*3-8)
maxlabel:SetFont(FONT_NAME, 12)
maxlabel:Update()
maxlabel:Show()

maxlabeltxt:SetTextColor(0.8, 0.8, 0.8, 1)
maxlabeltxt:SetPoint("TOPLEFT", 8, -currlabel:GetHeight()*3-8)
maxlabeltxt:SetFont(FONT_NAME, 12)
maxlabeltxt:SetText(MAX_DELAY_TEXT)
maxlabeltxt:Show()


tooearlylabel:SetTextColor(0.8, 0.8, 0.8, 1)
tooearlylabel:SetPoint("TOPRIGHT", -8, -currlabel:GetHeight()*4-8)
tooearlylabel:SetFont(FONT_NAME, 12)
tooearlylabel:Update()
tooearlylabel:Show()

tooearlylabeltxt:SetTextColor(0.8, 0.8, 0.8, 1)
tooearlylabeltxt:SetPoint("TOPLEFT", 8, -currlabel:GetHeight()*4-8)
tooearlylabeltxt:SetFont(FONT_NAME, 12)
tooearlylabeltxt:SetText(TOO_EARLY_TEXT)
tooearlylabeltxt:Show()


slammeleelabel:SetTextColor(0.8, 0.8, 0.8, 1)
slammeleelabel:SetPoint("TOPRIGHT", -8, -currlabel:GetHeight()*5-8)
slammeleelabel:SetFont(FONT_NAME, 12)
slammeleelabel:Update()
slammeleelabel:Show()

slammeleelabeltxt:SetTextColor(0.8, 0.8, 0.8, 1)
slammeleelabeltxt:SetPoint("TOPLEFT", 8, -currlabel:GetHeight()*5-8)
slammeleelabeltxt:SetFont(FONT_NAME, 12)
slammeleelabeltxt:SetText(SLAM_MELEE_TEXT)
slammeleelabeltxt:Show()



local btn = CreateFrame("Button", "ResetButton", UIParent, "UIPanelButtonTemplate")
-- local btn = CreateFrame("Button", "ResetButton", UIParent, "UIPanelCloseButton")
btn:SetPoint("LEFT", "SlamDelayFrame", "LEFT", -18, 0)
btn:SetSize(20, 20)


function btn:ResetStats(button)
   total_delay = 0
   total_slams = 0
   total_melee = 0
   max_delay = 0
   min_delay = nil
   too_early_count = 0
   currlabel:Update()
   minlabel:Update()
   maxlabel:Update()
   avglabel:Update()
   tooearlylabel:Update()
   slammeleelabel:Update()
end

btn:SetScript("OnClick", btn.ResetStats)
