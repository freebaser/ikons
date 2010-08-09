
local myname, ns = ...

local backdrop = {
   bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile=true, tileSize = 16,
   edgeFile = "Interface\\AddOns\\ikons\\media\\glowTex", edgeSize = 5,
   insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

ns.icons = {}

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
      frame.update = true
   elseif name then
      local f = findIcon(name)
      return UnregIcon(f)
   end
end

local function OnUpdate()
   return function(self, elapsed)
	     local duration = self.duration - elapsed
	     if duration <= 0 then
		UnregIcon(self)
		return
	     end
	     
	     self.duration = duration
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
		     anchor:SetSize(30, 30)
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
   frame:SetSize(30, 30) -- Get Size

   frame.bg = CreateFrame("Frame")
   frame.bg:SetParent(frame)
   frame.bg:SetPoint("TOPLEFT", frame, "TOPLEFT", -4, 4)
   frame.bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 4, -4)
   frame.bg:SetFrameStrata("LOW")
   frame.bg:SetBackdrop(backdrop)
   frame.bg:SetBackdropColor(0, 0, 0)
   frame.bg:SetBackdropBorderColor(0, 0, 0)

   local cd = CreateFrame"Cooldown"
   cd:SetParent(frame)
   cd:SetAllPoints(frame)

   local icon = cd:CreateTexture(nil, "OVERLAY")
   icon:SetAllPoints(frame)
   icon:SetTexCoord(.07, .93, .07, .93)
   
   frame:SetScript("OnUpdate", OnUpdate())
   
   frame.icon = icon
   frame.cd = cd
   frame.name = name

   CreateAnchor(frame, name)
   table.insert(ns.icons, frame)
end

local function GetIcons()
   for name, obj in pairs(ns.cfg.cds) do
      CreateIcon(name)
   end
   
   for auras, obj in pairs(ns.cfg.auras) do
      CreateIcon(auras)
   end
end

local function RegIcon(name, startTime, seconds, icon)
   local frame = findIcon(name)
   if frame == nil or frame.update == false then return end

   frame.update = false

   local duration = startTime - GetTime() + seconds
   frame.duration = duration
   frame.max = seconds

   frame.icon:SetTexture(icon)
   frame.cd:SetCooldown(startTime, seconds)
   frame:Show()
end

ns:RegisterEvent("SPELL_UPDATE_COOLDOWN")
function ns:SPELL_UPDATE_COOLDOWN()
   for name, obj in pairs(ns.cfg.cds) do
      local startTime, duration, enabled = GetSpellCooldown(name)

      if(enabled == 1 and duration > 1.5) then
	 RegIcon(name, startTime, duration, GetSpellTexture(name))
      end
   end
end

ns:RegisterEvent("UNIT_AURA")
function ns:UNIT_AURA()
   for aura, obj in pairs(ns.cfg.auras) do 
      local name ,_, icon, count,_, duration, expires, caster,_,_, spellID = UnitAura("player", aura, nil, "HELPFUL")

      if name then
	 local dur = -(GetTime() - expires)
	 local startTime = GetTime()
	 if dur > 1.5 then
	    RegIcon(aura, startTime, dur, icon) 
	 end
      else
	 UnregIcon(nil, aura)
      end
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
   
   GetIcons()
   SetPos()

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
