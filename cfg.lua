local myname, ns = ...

ns.cfg = {
   icon = {
     size = 30, 
   },
   
   statusbar = {
      width = 4,
      orientation = "VERTICAL",
      gradient = true,
      texture = "Interface\\AddOns\\ikons\\media\\smooth",
      r = 0,
      g = 1,
      b = 0,
   },

   ["WARRIOR"] = {
      cds = {
	 ["Bloodthirst"] = true,
	 ["Whirlwind"] = true,
      },

      auras = {
	 ["Slam!"] = true,
      },

      debuffs = {
	 ["Rend"] = { player = true },
	 ["Sunder Armor"] = true,
      },
   },

   ["PRIEST"] = {
      cds = {
	 ["Penance"] = true,
	 ["Circle of Healing"] = true,
	 ["Prayer of Mending"] = true,
      },

      auras = {
	 ["Surge of Light"] = true,
      },
   },
}