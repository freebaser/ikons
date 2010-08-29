
local myname, ns = ...

local backdrop = {
   bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile=true, tileSize = 16,
   edgeFile = "Interface\\AddOns\\ikons\\media\\glowTex", edgeSize = 5,
   insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

ns.icons = {}
local db, cds, auras, debuffs, items
local CD, AURA, DEBUFF, ITEM = "CD", "AURA", "DEBUFF", "ITEM"

local function getPoint(obj)
   local point, relativeTo, relativePoint, xOffset, yOffset = obj:GetPoint()
   return string.format(
      '%s\\%s\\%d\\%d',
      point, 'UIParent', xOffset, yOffset)
end

local function findIcon(name, type)
   for i=#(ns.icons), 1, -1 do
      if ns.icons[i].name == name and ns.icons[i].type == type then
	 local frame = ns.icons[i]
	 return frame
      end
   end   
end

local function UnregIcon(frame, name, type)
   if frame then
      frame:Hide()
      frame.update = true
   elseif name then
      local f = findIcon(name, type)
      return UnregIcon(f)
   end
end

local fmod = math.fmod
local function OnUpdate()
   return function(self, elapsed)
	     local duration = self.duration - elapsed
	     if duration <= 0 then
		UnregIcon(self)
		return
	     end

	     local min, sec = floor(duration / 60), fmod(duration, 60)
	     if(min > 0) then
		self.timer:SetFormattedText("%d:%02d", min, sec)
	     elseif(sec < 10) then
		self.timer:SetFormattedText("%.1f", sec)
	     else
		self.timer:SetFormattedText("%d", sec)
	     end

	     self.duration = duration
	     
	     local sb = self.sb
	     
	     if self.gradient then 
		local percent = duration / self.max
		sb:SetStatusBarColor(1 + (self.r - 1) * percent, self.g * percent, self.b * percent)
	     end

	     sb:SetValue(duration)
	  end
end

local anchorPool = {}
local CreateAnchor
do
   local OnDragStart = function(self)
			  self:StartMoving()
			  self:ClearAllPoints()
		       end

   local OnDragStop = function(self)
			 self:StopMovingOrSizing()
			 ns.db[self:GetName()] = getPoint(self)
		      end

   CreateAnchor = function(frame)
		     local anchor = CreateFrame("Frame", frame.name..frame.type.."ikon", UIParent)
		     anchor:SetFrameStrata"BACKGROUND"
		     anchor:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background";})
		     anchor:SetBackdropBorderColor(0, .9, 0)
		     anchor:SetBackdropColor(0, .9, 0)
		     anchor:SetSize(frame.size+frame.width+4, frame.size+4)
		     anchor:SetPoint("CENTER")
		     anchor:EnableMouse(true)
		     anchor:SetMovable(true)
		     anchor:SetClampedToScreen(true)
		     anchor:RegisterForDrag"LeftButton"
		     anchor:Hide()

		     anchor:SetScript("OnDragStart", OnDragStart)
		     anchor:SetScript("OnDragStop", OnDragStop)
		
		     anchor.icon = CreateFrame("Frame", nil, anchor)
		     anchor.icon:SetPoint("LEFT", anchor, "LEFT", 1, 0)
		     anchor.icon:SetSize(frame.size, frame.size)
		     
		     anchor.name = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		     anchor.name:SetPoint"TOP"
		     anchor.name:SetJustifyH"CENTER"
		     anchor.name:SetFont(GameFontNormal:GetFont(), 12)
		     anchor.name:SetTextColor(1, 1, 1)
		     anchor.name:SetText(frame.name:sub(0, 5))

		     anchor.type = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		     anchor.type:SetPoint"BOTTOM"
		     anchor.type:SetJustifyH"CENTER"
		     anchor.type:SetFont(GameFontNormal:GetFont(), 10)
		     anchor.type:SetTextColor(1, 1, 1)
		     anchor.type:SetText(frame.type)
		     table.insert(anchorPool, anchor)
		     
		     frame:SetAllPoints(anchor.icon)
		  end
end

local function CreateIcon(name, obj, type)
   local frame = CreateFrame"Frame"
   frame:Hide()
   frame:SetParent(UIParent)

   frame.bg = CreateFrame("Frame")
   frame.bg:SetParent(frame)
   frame.bg:SetPoint("TOPLEFT", frame, "TOPLEFT", -4, 4)
   frame.bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 5 + obj.width, -4)
   frame.bg:SetFrameStrata("LOW")
   frame.bg:SetBackdrop(backdrop)
   frame.bg:SetBackdropColor(.05, .05, .05)
   frame.bg:SetBackdropBorderColor(0, 0, 0)

   local icon = frame:CreateTexture(nil, "OVERLAY")
   icon:SetAllPoints(frame)
   icon:SetTexCoord(.07, .93, .07, .93)

   local sb = CreateFrame"StatusBar"
   sb:SetParent(frame)
   sb:SetPoint("LEFT", frame, "RIGHT", 1, 0)
   sb:SetSize(obj.width, obj.size)
   sb:SetOrientation(obj.orientation)
   sb:SetStatusBarTexture(obj.texture)
   
   local font = GameFontNormal:GetFont()
   local fontsize = obj.fontsize
   
   local count = frame:CreateFontString(nil, "OVERLAY")
   count:SetFont(font, fontsize, "OUTLINE")
   count:SetTextColor(1, 1, 1)
   
   local timer = sb:CreateFontString(nil, "OVERLAY")
   timer:SetFont(font, fontsize, "OUTLINE")
   timer:SetTextColor(1, 1, 1)
   
   if obj.orientation == "HORIZONTAL" then
      count:SetPoint("TOPRIGHT")
      timer:SetPoint("RIGHT", sb)
   else
      count:SetPoint("TOPRIGHT")
      timer:SetPoint("BOTTOM", frame)
   end
  
   frame:SetScript("OnUpdate", OnUpdate())
   
   frame.icon = icon
   frame.sb = sb
   frame.name = tostring(name)
   frame.type = type
   frame.count = count
   frame.timer = timer
   frame.r = obj.r
   frame.g = obj.g
   frame.b = obj.b
   frame.gradient = obj.gradient
   frame.size = obj.size
   frame.width = obj.width

   CreateAnchor(frame)
   table.insert(ns.icons, frame)
end

local function RegIcon(name, startTime, seconds, dura, icon, count, type)
   local frame = findIcon(name, type)
   if frame == nil then return end
   if count and count > 0 then
      frame.count:SetText(count)
   end
   if frame.update == false then
      if frame.duration and seconds < frame.duration+0.5 then return end
   end
   frame.update = false

   local duration = startTime - GetTime() + seconds
   frame.duration = duration
   frame.max = dura

   local sb = frame.sb
   sb:SetStatusBarColor(frame.r, frame.g, frame.b)
   sb:SetMinMaxValues(0, dura)
   sb:SetValue(duration)

   frame.icon:SetTexture(icon)
   frame:Show()
end

ns:RegisterEvent("SPELL_UPDATE_COOLDOWN")
function ns:SPELL_UPDATE_COOLDOWN()
   for cd, obj in pairs(cds) do
      local startTime, duration, enabled = GetSpellCooldown(cd)
      
      if(enabled == 1 and duration > 1.5) then
	 RegIcon(cd, startTime, duration, duration, GetSpellTexture(cd), nil, CD)
      end
   end
end

ns:RegisterEvent("PLAYER_TARGET_CHANGED")
ns:RegisterEvent("UNIT_AURA")
function ns:UNIT_AURA()
   for aura, obj in pairs(auras) do 
      local name ,_, icon, count,_, duration, expires, caster,_,_, spellID = UnitAura("player", aura, nil, "HELPFUL")

      if name then
	 local startTime = GetTime()
	 local secs = -(GetTime() - expires)
	 RegIcon(aura, startTime, secs, duration, icon, count, AURA)
      else
	 UnregIcon(nil, aura, AURA)
      end
   end

   for debuff, obj in pairs(debuffs) do 
      local name ,_, icon, count,_, duration, expires, caster,_,_, spellID = UnitAura("target", debuff, nil, "HARMFUL")

      if name then
	 if((not obj.player) or (obj.player and caster == "player")) then
	    local startTime = GetTime()
	    local secs = -(GetTime() - expires)
	    RegIcon(debuff, startTime, secs, duration, icon, count, DEBUFF)
	 end
      else
	 UnregIcon(nil, debuff, DEBUFF)
      end
   end
end
ns.PLAYER_TARGET_CHANGED = ns.UNIT_AURA

ns:RegisterEvent("BAG_UPDATE_COOLDOWN")
function ns:BAG_UPDATE_COOLDOWN()
   for item, obj in pairs(items) do
      local startTime, duration, enabled = GetItemCooldown(item)
      if(enabled == 1) then
	 RegIcon(tostring(item), startTime, duration, duration, select(10, GetItemInfo(item)), nil, ITEM)
      end
   end
end

local function GetIcons()
   for cd, obj in pairs(cds) do
      CreateIcon(cd, obj, CD)
   end
   
   for aura, obj in pairs(auras) do
      CreateIcon(aura, obj, AURA)
   end

   for debuff, obj in pairs(debuffs) do
      CreateIcon(debuff, obj, DEBUFF)
   end

   for item, obj in pairs(items) do
      CreateIcon(item, obj, ITEM)
   end
end

local function SetPos()
   for k, frame in next, anchorPool do
      if ns.db[frame:GetName()] then
	 frame:ClearAllPoints()

	 local point, parent, x, y = string.split('\\', ns.db[frame:GetName()])
	 frame:SetPoint(point, parent, point, x, y)
      end
   end
end

ns:RegisterEvent("ADDON_LOADED")
function ns:ADDON_LOADED(event, addon)
   if addon ~= myname then return end
   self:InitDB()

   LibStub("tekKonfig-AboutPanel").new(nil, myname)

   self:UnregisterEvent("ADDON_LOADED")
   self.ADDON_LOADED = nil

   if IsLoggedIn() then self:PLAYER_LOGIN() else self:RegisterEvent("PLAYER_LOGIN") end
end

function ns:PLAYER_LOGIN()
   self:RegisterEvent("PLAYER_LOGOUT")	
   local _, class = UnitClass("player")

   db = ns.cfg[class] or nil

   if db then
      cds = db.cds or {}
      auras = db.auras or {}
      debuffs = db.debuffs or {}
      items = db.items or {}

      GetIcons()
      SetPos()
   else
      ns:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
      ns:UnregisterEvent("UNIT_AURA")
      ns:UnregisterEvent("PLAYER_TARGET_CHANGED")
      ns:UnregisterEvent("BAG_UPDATE_COOLDOWN")
   end

   self:UnregisterEvent("PLAYER_LOGIN")
   self.PLAYER_LOGIN = nil
end

function ns:PLAYER_LOGOUT()
   self:FlushDB()
end

local _LOCK
function ns:Slash()
   if(not _LOCK) then
      for k, frame in next, anchorPool do
	 frame:Show()
      end
      _LOCK = true
   else
      for k, frame in next, anchorPool do
	 frame:Hide()
      end
      _LOCK = nil
   end
end
