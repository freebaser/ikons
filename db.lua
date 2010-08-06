
local myname, ns = ...


ns.defaults = {}


function ns.InitDB()
	_G[myname.."DB"] = setmetatable(_G[myname.."DB"] or {}, {__index = ns.defaults})
	ns.db = _G[myname.."DB"]

end


function ns.FlushDB()
	for i,v in pairs(ns.defaults) do if ns.db[i] == v then ns.db[i] = nil end end
end
