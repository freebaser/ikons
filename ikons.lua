
local myname, ns = ...

local backdrop = {
   bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile=true, tileSize = 16,
   edgeFile = "Interface\\AddOns\\ikons\\media\\glowTex", edgeSize = 5,
   insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

ns.icons = {}
local db, cds, auras, debuffs

local function getPoint(obj)
   local point, relativeTo, relativePoint, xOffset, yOffset = obj:GetPoint()
   return string.format(
      '%s\\%s\\%d\\%d',
      point, 'UIParent', xOffset, yOffset)
end

local function findIcon(name)
   for i=#(ns.icons), 1, -1 do
      if ns.icons[i].name == name then
	 local frame = ns.icons[i]
	 return frame
      end
   end   
end

local function UnregIcon(frame, name)
   if frame then
      frame:Hide()
   elseif name then
      local f = findIcon(name)
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
	     
	     if ns.cfg.statusbar.gradient then 
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

   CreateAnchor = function(frame, name)
		     local anchor = CreateFrame("Frame", name.."ikon", UIParent)
		     anchor:SetSize(ns.cfg.icon.size, ns.cfg.icon.size)
		     anchor:SetPoint("CENTER")
		     anchor:SetFrameStrata"TOOLTIP"
		     anchor:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background";})
		     anchor:EnableMouse(true)
		     anchor:SetMovable(true)
		     anchor:SetClampedToScreen(true)
		     anchor:RegisterForDrag"LeftButton"
		     anchor:SetBackdropBorderColor(0, .9, 0)
		     anchor:SetBackdropColor(0, .9, 0)
		     anchor:Hide()

		     anchor:SetScript("OnDragStart", OnDragStart)
		     anchor:SetScript("OnDragStop", OnDragStop)
		
		     anchor.name = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		     anchor.name:SetPoint"CENTER"
		     anchor.name:SetJustifyH"CENTER"
		     anchor.name:SetFont(GameFontNormal:GetFont(), 12)
		     anchor.name:SetTextColor(1, 1, 1)
		     anchor.name:SetText(name)
		     table.insert(anchorPool, anchor)
		     
		     frame:SetAllPoints(anchor)
		  end
end

local function CreateIcon(name)
   local frame = CreateFrame"Frame"
   frame:Hide()
   frame:SetParent(UIParent)

   frame.bg = CreateFrame("Frame")
   frame.bg:SetParent(frame)
   frame.bg:SetPoint("TOPLEFT", frame, "TOPLEFT", -4, 4)
   frame.bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 5 + ns.cfg.statusbar.width, -4)
   frame.bg:SetFrameStrata("LOW")
   frame.bg:SetBackdrop(backdrop)
   frame.bg:SetBackdropColor(0, 0, 0)
   frame.bg:SetBackdropBorderColor(0, 0, 0)

   local icon = frame:CreateTexture(nil, "OVERLAY")
   icon:SetAllPoints(frame)
   icon:SetTexCoord(.07, .93, .07, .93)

   local sb = CreateFrame"StatusBar"
   sb:SetParent(frame)
   sb:SetPoint("LEFT", frame, "RIGHT", 1, 0)
   sb:SetSize(ns.cfg.statusbar.width, ns.cfg.icon.size)
   sb:SetOrientation(ns.cfg.statusbar.orientation)
   sb:SetStatusBarTexture(ns.cfg.statusbar.texture)
   
   local font, fontsize = GameFontNormal:GetFont()
   local count = frame:CreateFontString(nil, "OVERLAY")
   count:SetFont(font, fontsize, "OUTLINE")
   count:SetShadowOffset(-1, 1)
   count:SetTextColor(1, 1, 1)
   count:SetPoint("TOPRIGHT")
  
   local timer = frame:CreateFontString(nil, "OVERLAY")
   timer:SetFont(font, 10, "OUTLINE")
   timer:SetTextColor(1, 1, 1)
   timer:SetPoint("BOTTOM")
  
   frame:SetScript("OnUpdate", OnUpdate())
   
   frame.icon = icon
   frame.sb = sb
   frame.name = name
   frame.count = count
   frame.timer = timer
   frame.r = ns.cfg.statusbar.r
   frame.g = ns.cfg.statusbar.g
   frame.b = ns.cfg.statusbar.b

   CreateAnchor(frame, name)
   table.insert(ns.icons, frame)
end

local function RegIcon(name, startTime, seconds, icon, count)
   local frame = findIcon(name)
   if frame == nil then return end
   if count and count > 0 then
      frame.count:SetText(count)
   end
   if frame.duration and seconds < frame.duration+0.5 then return end

   local duration = startTime - GetTime() + seconds
   frame.duration = duration
   frame.max = seconds

   local sb = frame.sb
   sb:SetStatusBarColor(frame.r, frame.g, frame.b)
   sb:SetMinMaxValues(0, seconds)
   sb:SetValue(duration)

   frame.icon:SetTexture(icon)
   frame:Show()
end

ns:RegisterEvent("SPELL_UPDATE_COOLDOWN")
function ns:SPELL_UPDATE_COOLDOWN()
   for name, obj in pairs(cds) do
      local startTime, duration, enabled = GetSpellCooldown(name)
      
      if(enabled == 1 and duration > 1.5) then
	 RegIcon(name, startTime, duration, GetSpellTexture(name))
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
	 local dur = -(GetTime() - expires)
	 RegIcon(name, startTime, dur, icon, count)
      else
	 UnregIcon(nil, aura)
      end
   end

   for debuff, obj in pairs(debuffs) do 
      local name ,_, icon, count,_, duration, expires, caster,_,_, spellID = UnitAura("target", debuff, nil, "HARMFUL")

      if name then
	 if((not debuff.player) or (debuff.player and caster == "player")) then
	    local startTime = GetTime()
	    local dur = -(GetTime() - expires)
	    RegIcon(name, startTime, dur, icon, count)
	 end
      else
	 UnregIcon(nil, debuff)
      end
   end
end
ns.PLAYER_TARGET_CHANGED = ns.UNIT_AURA

local function GetIcons()
   for cd, obj in pairs(cds) do
      CreateIcon(cd)
   end
   
   for aura, obj in pairs(auras) do
      CreateIcon(aura)
   end

   for debuff, obj in pairs(debuffs) do
      CreateIcon(debuff)
   end
end

local function SetPos()
   for k, frame in next, anchorPool do
      if ns.db[frame:GetName()] then
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

      GetIcons()
      SetPos()
   else
      ns:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
      ns:UnregisterEvent("UNIT_AURA")
      ns:UnregisterEvent("PLAYER_TARGET_CHANGED")
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
