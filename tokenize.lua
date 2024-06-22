local function set(list)
	local t = {}
	for _, e in pairs(list) do
		t[e] = true
	end
	return t
end

local keywords = set{
	"and", "break", "do", "else", "elseif",
	"end", "false", "for", "function", "if",
	"in", "local", "nil", "not", "or",
	"repeat", "return", "then", "true", "until", "while"
}

local escapes = {
	a = '\a', b = '\b', f = '\f', n = '\n', ['\n'] = '\n', r = '\r',
	t = '\t', v = '\v', ["\\"] = "\\", ["'"] = "'", ['"'] = '"',
}

-- Do not pollute error messages by prepending line numbers

local err = error
local function error(msg)
	return err(msg, 0)
end
local function assert(val, msg)
	if val then return val end
	return error(msg or "assertion failed!")
end

local function tokenize(str)
	local pop, raw_pop, peek
	do
		local read_char
		do
			local i = 0
			function read_char()
				i = i + 1
				return str:sub(i, i)
			end
		end
		local c
		function raw_pop()
			c = read_char()
		end
		raw_pop()
		function peek()
			return c
		end
	end
	local function expect_any(message)
		local c = peek()
		if c == "" then error("expected " .. message) end
		pop()
		return c
	end
	local function eat()
		return expect_any"anything but eof"
	end
	local function match(c)
		if peek() == c then
			pop()
			return c
		end
	end
	local function match_charset(patt)
		local c = peek()
		if c:find(patt) then
			pop()
			return c
		end
	end
	local function match_charset_str(patt)
		while match_charset(patt) do end
	end
	local function skip_linefeed()
		if match"\n" then
			return 1
		end if match"\r" then
			return match"\n" and 2 or 1
		end
	end
	-- Note: It is expected that `[` has already been read.
	local function long_content(delim_expected)
		local level = 0
		while match"=" do
			level = level + 1
		end
		if not match"[" then
			assert(level == 0 or not delim_expected, "invalid long delimiter")
			return
		end
		skip_linefeed()
		local rope = {}
		while true do
			if match"]" then
				local closing_level = 0
				while match_charset"=" do
					closing_level = closing_level + 1
				end
				-- Do not use match here! We don't want the `]` to be popped if the levels don't match!
				if peek() == "]" and closing_level == level then
					pop()
					break
				end
				table.insert(rope, "]")
				table.insert(rope, ("="):rep(closing_level))
				-- Note: The closing `]` has not been popped yet! It will be popped in the next iteration.
			elseif skip_linefeed() then
				table.insert(rope, "\n") -- linefeed normalization applies in long strings
			else
				table.insert(rope, eat())
			end
		end
		return table.concat(rope)
	end
	local function exponent()
		if match_charset"[eE]" then
			match_charset"[+-]"
			assert(match_charset"%d", "malformed number: exponent expected")
			match_charset_str"%d"
		end
	end
	return function()
		if peek() == "" then
			return -- eof
		end
		local get_content
		do
			local rope = {}
			function pop()
				table.insert(rope, peek())
				return raw_pop()
			end
			local content
			function get_content()
				if not content then
					content = table.concat(rope)
					return content
				end
				-- If this assertion fails, I messed up
				assert(#content == #rope)
				return content
			end
		end
		local token, value
		if match_charset"[%a_]" then
			token = "name"
			match_charset_str"[%a%d_]"
			if keywords[get_content()] then
				token = "keyword"
				if get_content() == "true" then
					value = true
				elseif get_content() == "false" then
					value = false
				end
			end
		elseif peek():find"['\"]" then
			token = "string"
			local quote = eat()
			local rope = {}
			while true do
				local c = expect_any"unclosed string"
				-- TODO (?) does Lua treat CR this way?
				assert(c ~= "\n" and c ~= "\r", "unclosed string")
				if c == quote then break end
				if c == "\\" then
					local esc = expect_any"escape sequence"
					c = escapes[esc]
					if not c then
						assert(esc:find"%d", "invalid escape sequence")
						local code = tonumber(esc)
						for _ = 1, 2 do
							local digit = match_charset"%d"
							if digit then
								code = code * 10 + digit -- coerces
							end
						end
						assert(code <= 0xFF, "invalid char code")
						c = string.char(code)
					end
				end
				table.insert(rope, c)
			end
			value = table.concat(rope)
		elseif match_charset"%s" then
			token = "whitespace"
			match_charset_str"%s"
		elseif match"-" then
			token = "symbol"
			if match"-" then
				token = "comment"
				if match"[" then
					value = long_content()
				end
				if not value then
					match_charset_str"[^\r\n]"
					value = get_content():sub(#"--")
				end
			end
		elseif match_charset"[]^*+%%/(){}#:;,]" then
			token = "symbol"
		elseif match_charset"[<>=]" then
			token = "symbol"
			match"=" -- <=, >=, ==
		elseif match"~" then
			assert(match"=", "~= expected")
			token = "symbol"
		elseif match"[" then
			value = long_content(true)
			if value then
				token = "string"
			else
				token = "symbol"
			end
		elseif match"." then
			if match_charset"%d" then
				token = "number"
				match_charset_str"%d"
				exponent()
				value = assert(tonumber(get_content()), "malformed number")
			else
				token = "symbol" -- .
				if match"." then -- ..
					match"." -- ...
				end
			end
		elseif peek():find"%d" then -- number
			token = "number"
			if eat() == "0" and match_charset"[xX]" then -- hex
				match_charset_str"%x"
				if match"." then -- fractional hex
					match_charset_str"%x"
				end
			else -- decimal
				match_charset_str"%d"
				if match"." then
					match_charset_str"%d"
				end
				exponent()
			end
			value = assert(tonumber(get_content()), "malformed number")
		else
			-- TODO (?...) emit error tokens instead of bailing out entirely
			error"unexpected symbol"
		end
		return token, get_content(), value
	end
end

return tokenize
