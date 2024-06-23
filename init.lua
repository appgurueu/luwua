local old_require = require
-- Not really require but for our purposes this hack is equivalent
function require(filename) -- luacheck: ignore
	return dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/" .. filename .. ".lua")
end

luwua = require"luwua"

require = old_require -- luacheck: ignore
