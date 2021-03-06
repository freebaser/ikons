local myname, ns = ...
local tex1 = "Interface\\AddOns\\ikons\\media\\smooth"

local profile = {

   ["default"] = {
      size = 30,
      width = 4,
      orientation = "VERTICAL",
      gradient = true,
      texture = tex1,
      r = 0,
      g = 1,
      b = 0,
      fontsize = 12,
   },

   -- Only show if owner is player
   ["player"] = {
      size = 30,
      width = 4,
      orientation = "VERTICAL",
      gradient = true,
      texture = tex1,
      r = 0,
      g = 1,
      b = 0,
      fontsize = 12,
      player = true,
   },

   ["big"] = {
      size = 42,
      width = 6,
      orientation = "VERTICAL",
      gradient = true,
      texture = tex1,
      r = 0,
      g = 1,
      b = 0,
      fontsize = 12,
   },
   
   ["horizontal"] = {
      size = 25,
      width = 150,
      orientation = "HORIZONTAL",
      gradient = false,
      texture = tex1,
      r = .8,
      g = .8,
      b = 0,
      fontsize = 10,
   },

   ["ww"] = {
      size = 20,
      width = 150,
      orientation = "HORIZONTAL",
      gradient = false,
      texture = tex1,
      r = 0,
      g = .6,
      b = .9,
      fontsize = 10,
   },

   ["bt"] = {
      size = 20,
      width = 150,
      orientation = "HORIZONTAL",
      gradient = false,
      texture = tex1,
      r = 1,
      g = 0,
      b = 0,
      fontsize = 10,
   },

   ["slam"] = {
      size = 20,
      width = 150,
      orientation = "HORIZONTAL",
      gradient = false,
      texture = tex1,
      r = .8,
      g = .8,
      b = 0,
      fontsize = 10,
   },
}

ns.cfg = {

   ["WARRIOR"] = {
      cds = {
	 ["Bloodthirst"] = profile["bt"],
	 ["Whirlwind"] = profile["ww"],
      },

      auras = {
	 ["Slam!"] = profile["slam"],
      },

      debuffs = {
	 ["Rend"] = profile["player"],
	 ["Sunder Armor"] = profile["big"],
      },

      items = {
	 [50356] = profile["horizontal"],
      },
   },

   ["PRIEST"] = {
      cds = {
	 ["Penance"] = profile["default"],
	 ["Circle of Healing"] = profile["default"],
	 ["Prayer of Mending"] = profile["default"],
      },

      auras = {
	 ["Surge of Light"] = profile["default"],
      },
   },

   ["DEATHKNIGHT"] = {
      cds = {
	 --["Icebound Fortitude"] = profile["default"],
	 --["Vampiric Blood"] = profile["default"],
      },
      
      auras = {
	 ["Icebound Fortitude"] = profile["default"],
	 ["Vampiric Blood"] = profile["default"],
      },
   },
}