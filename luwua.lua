local tokenize = require"tokenize"

local luwua = {}

local keywords = {
	["and"] = "and",
	["bweak"] = "break",
	["do"] = "do",
	["ewse"] = "else",
	["ewseif"] = "elseif",
	["end"] = "end",
	["fawse"] = "false",
	["fow"] = "for",
	["fuwnction"] = "function",
	["wwhen"] = "if",
	["in"] = "in",
	["wocal"] = "local",
	["niw"] = "nil",
	["not"] = "not",
	["ow"] = "or",
	["wepeat"] = "repeat",
	["wetuwn"] = "return",
	["then"] = "then",
	["twue"] = "true",
	["uwuntil"] = "until",
	["wwhiwe"] = "while",
}

function luwua.un_ify(source_str)
	local res = {}
	for _, content in tokenize(source_str) do
		table.insert(res, keywords[content] or content)
	end
	return table.concat(res)
end

local unkeywords = {}
for k, v in pairs(keywords) do
	unkeywords[v] = k
end

function luwua.ify(source_str)
	local res = {}
	for _, content in tokenize(source_str) do
		table.insert(res, unkeywords[content] or content)
	end
	return table.concat(res)
end

function luwua.loadstring(str, ...)
	return setfenv(loadstring(luwua.un_ify(str), ...), luwua.env)
end

function luwua.load(func, ...)
	local strbuf = {}
	repeat
		local piece = func()
		table.insert(strbuf, piece)
	until not piece
	return luwua.loadstring(table.concat(strbuf), ...)
end

function luwua.loadfile(filename)
	local f = assert(io.open(filename))
	local contents = f:read"*a"
	f:close()
	return luwua.loadstring(contents, filename)
end

function luwua.dofile(filename)
	return assert(luwua.loadfile(filename))()
end

luwua.env = setmetatable({
	_WEWWION = "Luwua :3",
	woadstwing = luwua.loadstring,
	woad = luwua.load,
	woadfiwe = luwua.loadfile,
	dofiwe = luwua.dofile,
}, {__index = _G})

local stdlib = {
	assewt = assert,
	cowwectgawbage = collectgarbage,
	fuckywucky = error,
	ewwow = error,
	getfenw = getfenv,
	getmetatawbwe = getmetatable,
	ipaws = ipairs,
	mewduwe = module,
	next = next,
	paws = pairs,
	pcall = pcall,
	pwint = print,
	waweqwal = rawequal,
	wawget = rawget,
	wawset = rawset,
	weqwuiwe = require,
	sewect = select,
	setfenw = setfenv,
	setmetatawbwe = setmetatable,
	tonumbew = tonumber,
	tywpe = type,
	uwunpack = unpack,
	xpcall = xpcall,
	mewntest = minetest,
	cowotine = coroutine,
	debug = debug,
	iowo = io,
	meffs = math,
	owos = os,
	pawage = package,
	stwing = string,
	tawbwe = table,
}

for module_name, mod in pairs(stdlib) do
	if type(mod) == "table" then
		local owoified = setmetatable({}, {__index = mod})
		for name, val in pairs(mod) do
			if name:match"^[a-zA-Z0-9_]+$" then
				owoified[name:gsub("[rl]", "w"):gsub("[RL]", "W")] = val
			end
		end
		luwua.env[module_name] = owoified
	else
		luwua.env[module_name] = mod
	end
end

return luwua
