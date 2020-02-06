//---------- DOCUMENTATION ----------

/**
SHARED FUNCTIONS FOR OTHER LIB PARTS
Basic functions and variables, many of them are required by other library parts. Needs to be incuded first. This file also adds a lot of constants to const table and then inject const table to root table. Constants are from kapkan/lib/constants.nut, this file also defines a lot of sourcemod and vslib constants.
------------------------------------
lib_version
	Version of library.
------------------------------------
root
	Root table, same as getroottable().weakref().
------------------------------------
log(...)
	Prints to console. If called with multiple arguments, prints their string representations separated with a whitespace, like print() function in Python. Ends with linebreak.
	Example: log("Total", rabbits_amount, "rabbits") //prints "Total X rabbits" with a linebreak
------------------------------------
log_table(table|class|array, max_depth = 3)
	Dumps deep structure of table, class or array to console. Additinal param is max_depth. Has also some hidden optional params that are used by recursive calls, see code.
	Example: log_table(g_MapScript)
	Some lines of output:
	table: 
		"ScriptMode_OnShutdown": function(reason, nextmap) (0x06C7D770)
		"scriptedModeSlowPollFuncs": [empty array]
		"StartboxFloating_Info": table: 
			"model": "models/props_placeable/striped_barricade.mdl"
			"angles": Vector (0, 0, 0)
			"solid": "0"
------------------------------------
player_to_str(player)
	Converts player entity to string.
	Example: player_to_str(Ent(1)) // returns "Player (1 | kapkan)"
------------------------------------
ent_to_str(ent)
	Converts entity to string. Uses player_to_str if detects that entity is of CTerrorPlayer class
	Example: ent_to_str(Ent(28)) // returns "Entity (prop_dynamic #28 | carousel_ceilinglights)"
------------------------------------
var_to_str(var)
	Converts any variable to string. Uses ent_to_str if detects that entity is of CBaseEntity class. This is used by log_table to print keys and values. If table passed, notifies if table is root table, DirectorScript, g_MapScript or g_ModeScript. If function is passed, prints function argument names or types using getinfos() call.
	Example: var_to_str([]) //returns "array (0x07D13980)"
	Example: var_to_str(getroottable()) //returns "table (0x0674FC90 root table)"
	Example: var_to_str(IncludeScript) //returns "function(name, scope) (0x03C3C070)"
	Example: var_to_str(regexp.search) //returns "native function(string, int/float) (0x067EB7C0)"
	Example: var_to_str(Ent(1).GetOrigin()) //returns "Vector (1621, 2786, 4.03125)"
------------------------------------
logt(table|class|array)
	Shortcut for log_table(table|class|array).
------------------------------------
logp(player)
	Shortcut for (log(player_to_str(player)).
------------------------------------
loge(ent)
	Shortcut for (log(ent_to_str(ent)).
------------------------------------
logv(var)
	Shortcut for (log(var_to_str(var)).
------------------------------------
logf(str, ...)
	Shortcut for log(format(str, ...)).
------------------------------------
concat(array, sep)
	Connects string array using separator. Has alias "connect_strings()".
	Example: concat(["a", "b", "c"], ", ") //returns "a, b, c"
------------------------------------
ln(x)
	Natural logarithm, instead of log(x).
------------------------------------
worldspawn
	Worldspawn entity.
------------------------------------
scope(ent)
	Validates and returns entity script scope.
------------------------------------
invalid(ent)
	Returns true if this is not a valid entity, for example deleted one. Has an alias "deleted_ent(ent)".
------------------------------------
entstr(ent)
	Returns ent.GetEntityHandle().tointeger().tostring(), which is entity string representation, for example for using in task names
------------------------------------
ent_fire(entity, action, value = null, delay = 0)
	Performs DoEntFire("!self", action, value, delay, null, entity).
------------------------------------
cvar(_cvar, value)
	Performs Convars.SetValue and prints to console. Look for advanced version of cvar() at module_serversettings.
------------------------------------
cvarstr(_cvar)
	Alias of Convars.GetStr
------------------------------------
cvarf(_cvar)
	Alias of Convars.GetFloat
------------------------------------
cheats()
	Returns true if sv_cheats integer value is non-zero.
------------------------------------
is_dedicated()
	Returns true if server is dedicated (otherwise listenserver).
------------------------------------
server_host()
	Returns listenserver host player or null. Warning! May return null while server host is still connecting.
------------------------------------
min(a, b)
	Returns min of two numbers.
------------------------------------
max(a, b)
	Returns max of two numbers.
------------------------------------
checktype(var, _type)
	Checks if var is of _type, and if not, throws an exception. Useful for checking arguments in functions.
	_type can be:
	1) String - then typeof(var) will be compared to _type
		Example: checktype(var, "integer") //only integer numbers
		Example: checktype(var, "float") //only float numbers
		Example: checktype(var, "array") //only arrays
		Example: checktype(var, "string") //only strings
		Example: checktype(var, "bool") //only booleans
		Example: checktype(var, "function") //only functions (not native functions)
		Example: checktype(var, "native function") //only native functions
		Example: checktype(var, "Vector") //only instances of Vector class
	2) Integer - one of predefined values: ::NUMBER, ::FUNC, ::STRING, ::BOOL
		Example: checktype(var, NUMBER) //integer or float
		Example: checktype(var, FUNC) //function or native function
		Example: checktype(var, STRING) //string, same as checktype(var, "string")
		Example: checktype(var, BOOL) //boolean, same as checktype(var, "bool")
	3) Array - var should be one of types in array
		Example: checktype(var, ["integer", "string"]) //var should be integer or string
		Example: checktype(var, ["table", "array"]) //var should be table or array
		Example: checktype(var, [NUMBER, "Vector"]) //var should be int, float or Vector
	If something other is passed as _type, behavior is indefined.
------------------------------------
Teams
	Table that contains constant values Teams.UNASSIGNED, Teams.SPECTATORS, Teams.SURVIVORS, Teams.INFECTED. Used by some modules.
------------------------------------
ClientType
	Table that contains constant values ClientType.ANY, ClientType.HUMAN, ClientType.BOT. Used by lib/module_advanced.
------------------------------------
report()
	Prints current library state to chat. Calls all functions that were added with reporter() function by library modules or other scripts.
------------------------------------
reporter(name, func)
	Adds new function that will be called on report() call. If this name was already added, owerwrites function. Name should be a human-readable string that will be printed to chat before func() call. Different library modules use this function.
------------------------------------
debug()
	This library creates "debug" convar that is used to control debug output. Function debug() returns true if debug mode is on. This means that Convars.GetFloat("debug") > 0 or debug was enabled this tick. Debug mode does not affect anything and is used only with debug(str) print function.
------------------------------------
debug(func)
	If debug mode is on, function will be called. If function returns not-null value, it will be printed.
------------------------------------
debug(str, ...)
	 If debug mode is on, debug(str, ...) works like log(str, ...), else does not do anything.
------------------------------------
debugf(str, ...)
	If debug mode is on, debug(str, ...) works like logf(str, ...), else does not do anything.
------------------------------------
debug_on()
	Enabled debug mode: performs "setinfo debug 1". SendToServerConsole() takes some time, so this function  overrides this value for one tick.
------------------------------------
debug_off()
	Disables debug mode: performs "setinfo debug 0". SendToServerConsole() takes some time, so this function  overrides this value for one tick.
------------------------------------
file_read(filename)
	Reads file (from left4dead2/ems directory or subdirectories), returns string or null. Same as FileToString. There may be problems with large files.
------------------------------------
file_write(filename, str)
	Writes string to file (to left4dead2/ems directory or subdirectories), creates if not exist. Same as StringToFile.
------------------------------------
file_to_func(filename)
	Reads file (from left4dead2/ems directory or subdirectories), compiles script from it's contents, returns function or null. Uses compilestring() squirrel function.
------------------------------------
file_append(filename, str)
	Appends string to the end of file (to left4dead2/ems directory or subdirectories).
------------------------------------
say_chat(str, ...)
	Prints to chat for all players. If more than one argument, it uses formatting like say_chat(format(str, ...)). This function uses multiple Say() statements to print long strings. This function prints most unicode characters correctly. If you need to say something to specific team or from specific player, this function as it is is not suitable.
	Example: say_chat("Привет, %s!", playername) //in chat: "Console: Привет, kapkan!"
	If this is a listerserver and host is still not connected, and module_tasks is included, message will be added to queue and sent to chat after first human player connects.
------------------------------------
vecstr2(vec)
	Vector to string: compact 2-digits representation. Uses "%.2f %.2f %.2f" to format vector components. Prints 0.00 instead of -0.00.
	Example: vecstr2(Ent(1).GetOrigin()) //returns "1621.00 2786.00 4.03"
------------------------------------
vecstr3(vec)
	Vector to string: compact 3-digits representation. Uses "%.3f %.3f %.3f" to format vector components. Prints 0.00 instead of -0.00.
	Example: vecstr3(Ent(1).GetOrigin()) //returns "1621.000 2786.000 4.031"
------------------------------------
tolower(str)
	Converts a string to lower case, supports english and russian symbols. If you don't need russian symbols support, use .tolower() string method.
------------------------------------
remove_quotes(str)
	If string is enclosed in quotes (first symbol is \" and last symbol is \"), removes them.
------------------------------------
has_special_symbols(str)
	Returns true if string has symbols not of A-Za-z0-9_.
------------------------------------
is_json_printable(str)
	Returns true if string is json printable (does not contain \r \n \" \\).
 */
 
//---------- CODE ----------

IncludeScript("kapkan/lib/collision_checker")

this = getroottable()
_def_var("root", this.weakref())

_def_var("lib_version", "3.0.0")

IncludeScript("kapkan/lib/debug")

if(typeof log == "native function") ln <- log

_def_func("log", function(...) {
	local first = true
	foreach(arg in vargv) {
		if (!first) print(" ")
		first = false
		print(arg)
	}
	print("\n")
})

log("[lib] version", lib_version)
log("[lib] including module_base")

if (!("dont_add_constants_to_roottable" in this) || !dont_add_constants_to_roottable) {
	IncludeScript("kapkan/lib/constants")
} else {
	//don't do anything (constants already included by lib_auto.nut)
	//just removing dont_add_constants_to_roottable flag
	delete dont_add_constants_to_roottable
}

/* for example output: log_table(getroottable()) */
_def_func("log_table", function(table, max_depth = 3, current_depth = 0, manual_call = true, original_tables = null) {
	local function indents(n) {
		local str = ""
		for (local i = 0; i < n; i++) str += "\t"
		return str
	}
	if (!table) {
		printl("null")
		return
	}
	if (typeof(table) != "table" && typeof(table) != "array" && typeof(table) != "class") {
		printl(format("[%s: not a table, array or class]", typeof(table)))
		if (manual_call)
			printl("trying anyway")
		else
			return;
	}
	if (table == getroottable() && !manual_call) {
		printl("[root table]")
		return
	}
	if (!original_tables)
		original_tables = [table]
	if (current_depth != 0 && original_tables.find(table) != null) {
		printl("[circular reference to parent table " + table.tostring().slice(9, -1) + "]")
		return
	}
	local total_count = 0
	foreach(value in table) total_count++
	if (total_count == 0) {
		printl(format("[empty %s]", typeof(table)))
		return
	}
	if (max_depth == current_depth || (!manual_call && total_count > 200)) {
		printl(format("[%s with %d elements]", typeof(table), total_count))
		return
	}
	printl(typeof(table) + ": ")
	foreach(key, value in table) {
		print(indents(current_depth + 1))
		print(var_to_str(key) + ": ")
		if (typeof(value) == "table" || typeof(value) == "array" || typeof(value) == "class") {
			local new_original_tables = clone original_tables
			new_original_tables.append(table)
			log_table(value, max_depth, current_depth + 1, false, new_original_tables)
		}
		else printl(var_to_str(value))
	}
})

_def_func("player_to_str", function(player) {
	if (invalid(player)) return "(deleted entity)"
	return format("Player (%d | %s)", player.GetEntityIndex().tointeger(), player.GetPlayerName())
})

_def_func("ent_to_str", function(ent) {
	if (invalid(ent)) return "(deleted entity)"
	local id = ent.GetEntityIndex().tointeger()
	if ("CTerrorPlayer" in getroottable() && ent instanceof ::CTerrorPlayer)
		return player_to_str(ent)
	else {
		local name = ent.GetName()
		return format("Entity (%s #%d%s)", ent.GetClassname(), id, name != "" ? " | " + name : "")
	}
})

_def_func("var_to_str", function(var) {
	if (var == null) return "null"
	// CBaseEntity and CTerrorPlayer do not exist until we instantiate them
	if ("CBaseEntity" in getroottable() && var instanceof ::CBaseEntity)
		return ent_to_str(var)
	if (typeof(var) == "string") return "\"" + var + "\""
	if (typeof(var) == "function" || typeof(var) == "native function") {
		local function typemask(n) {
			switch (n) {
				case -1: return "var"
				case 6: return "int/float"
				case 8: return "bool"
				case 17: return "string"
				case 768: return "function"
				case 32768: return "Vector"
			}
			return "<type " + n + ">"
		}
		local infos = var.getinfos();
		local params_arr = [];
		if ("parameters" in infos && infos.parameters != null)
			for(local i = 1; i < infos.parameters.len(); i++)
				params_arr.push(infos.parameters[i].tostring())
		else if ("typecheck" in infos && infos.typecheck != null)
			for(local i = 1; i < infos.typecheck.len(); i++)
				params_arr.push(typemask(infos.typecheck[i]))
		local func_address = var.tostring().slice(typeof(var) == "function" ? 12 : 19 /* native function */, -1)
		return format("%s(%s) (%s)", typeof(var), concat(params_arr, ", "), func_address)
	}
	if (typeof(var) == "class") {
		return "class"
	}
	if (typeof(var) == "table") {
		local table_name = null
		if (var == ::root) table_name = "root table"
		else if (var == ::DirectorScript) table_name = "DirectorScript"
		else if (var == ::g_MapScript) table_name = "g_MapScript"
		else if (var == ::g_ModeScript) table_name = "g_ModeScript"
		return format("table (%s%s)", var.tostring().slice(9, -1), table_name ? " " + table_name : "")
	}
	if (typeof(var) == "array") {
		return format("array (%s)", var.tostring().slice(9, -1))
	}
	if (typeof(var) == "instance") {
		return "instance"
	}
	if (typeof(var) == "Vector") {
		return format("Vector (%g, %g, %g)", var.x, var.y, var.z)
	}
	return var.tostring()
})

_def_func("logv", @(var) log(var_to_str(var)))

_def_func("loge", @(var) log(ent_to_str(var)))

_def_func("logp", @(var) log(player_to_str(var)))

_def_func("logt", log_table)

_def_func("logf", function(str, ...) {
	local args = [this, str]
	args.extend(vargv)
	log(format.acall(args))
})

_def_func("concat", function(arr, separator) {
	local str = "";
	for (local i = 0; i < arr.len(); i++)
		str += arr[i] + ((i != arr.len() - 1) ? separator : "");
	return str;
})

_def_constvar("worldspawn", Entities.First())

_def_func("scope", function(ent) {
	if (!ent) throw "scope(): null entity"	
	ent.ValidateScriptScope()
	return ent.GetScriptScope()
})

_def_func("invalid", function(ent) {
	if (!("IsValid" in ent)) return true;
	return !ent.IsValid();
})

_def_func("entstr", function(ent) {
	return ent.GetEntityHandle().tointeger().tostring()
})

_def_func("deleted_ent", invalid) //legacy

_def_func("ent_fire", function(ent, action, value = "", delay = 0) {
	DoEntFire("!self", action, value, delay, null, ent)
})

_def_func("cvar", function(_cvar, value, flags = 0) {
	if (!flags) {
		Convars.SetValue(_cvar, value)
		logf("[lib] cvar %s set to %s", _cvar, value.tostring())
		if ("cvar_remove_flags" in root) {
			cvar_remove_flags(_cvar, ~0)
		}
	} else if ("cvar2" in root) {
		cvar2(_cvar, value, flags)
	} else {
		throw "[lib] cvar(): function cannot accept 3 parameters without module_serversettings"
	}
})

_def_func("cvarstr", Convars.GetStr.bindenv(Convars))

_def_func("cvarf", Convars.GetFloat.bindenv(Convars))

_def_func("cheats", function() {
	return Convars.GetFloat("sv_cheats").tointeger() != 0
})

_def_func("is_dedicated", function() {
	local terror_gamerules = Entities.FindByClassname(null, "terror_gamerules")
	if (terror_gamerules) return NetProps.GetPropInt(terror_gamerules, "m_bIsDedicatedServer")
	return (Convars.GetStr("ip") != "localhost")
})

_def_func("server_host", function() {
	if (__server_host) return __server_host;
	local terror_player_manager = Entities.FindByClassname(null, "terror_player_manager")
	for (local i = 0; i <= 32; i++)
		if (NetProps.GetPropIntArray(terror_player_manager, "m_listenServerHost", i)) {
			local player = EntIndexToHScript(i)
			__server_host = player
			return player
		}
})

_def_var_nullable("__server_host", null, "instance")

_def_func("min", function(a, b) {
	return (a < b) ? a : b
})

_def_func("max", function(a, b) {
	return (a > b) ? a : b
})

_def_constvar("NUMBER", -1)
_def_constvar("FUNC", -2)
_def_constvar("STRING", -3)
_def_constvar("BOOL", -4)

_def_func("checktype", function(var, _type, noException = false /*don't throw exception, return false instead */) {
	local typeof_var = typeof(var)
	local function throw_invalid_type() {
		if (noException) return false
		throw "invalid variable type: " + typeof_var
	}
	if (typeof(_type) == "string") {
		if (typeof_var != _type) throw_invalid_type()
	} else if (typeof(_type) == "array") {
		foreach(_type_entry in _type) {
			if (checktype(var, _type_entry, true) != false) return true
		}
		throw_invalid_type()
	} else if (_type == NUMBER) {
		if (typeof_var != "float" && typeof_var != "integer") throw_invalid_type()
	} else if (_type == FUNC) {
		if (typeof_var != "function" && typeof_var != "native function") throw_invalid_type()
	} else if (_type == STRING) {
		if (typeof_var != "string") throw_invalid_type()
	} else if (_type == BOOL) {
		if (typeof_var != "bool") throw_invalid_type()
	} else {
		throw "checktype: _type should be string, array, NUMBER, FUNC, STRING or BOOL"
	}
	return true
})

_def_constvar("Teams", {})
_def_constvar("Teams.ANY", -1)
_def_constvar("Teams.UNASSIGNED", 1 << 0)
_def_constvar("Teams.SPECTATORS", 1 << 1)
_def_constvar("Teams.SURVIVORS", 1 << 2)
_def_constvar("Teams.INFECTED", 1 << 3)

_def_constvar("ClientType", {})
_def_constvar("ClientType.ANY", -1)
_def_constvar("ClientType.HUMAN", 1 << 0)
_def_constvar("ClientType.BOT", 1 << 1)

_def_func("__dummy", function(...) {})

_def_func("file_read", FileToString) //gets filename, returns string

_def_func("file_write", function(file, str) {
	if (str == null) throw "trying to write null to file"
	StringToFile(file, str)
})

_def_func("file_to_func", function(filename) {
	local str = FileToString(filename)
	if (!str) return null
	return compilestring(str)
})

_def_func("file_append", function(filename, str) {
	if (str == null) throw "trying to write null to file"
	local str_from_file = FileToString(filename)
	StringToFile(filename, str_from_file ? str_from_file + str : str)
})

_def_func("say_chat", function(message, ...) {
	local UTF8_BYTE_1BYTE = 0
	local UTF8_BYTE_2BYTE_HEAD = 1
	local UTF8_BYTE_3BYTE_HEAD = 2
	local UTF8_BYTE_4BYTE_HEAD = 3
	local UTF8_BYTE_TAIL = 4
	local get_utf8_byte_type = function(int_char) {
		if (!(int_char & (1 << 7))) return UTF8_BYTE_1BYTE
		if (!(int_char & (1 << 6))) return UTF8_BYTE_TAIL
		if (!(int_char & (1 << 5))) return UTF8_BYTE_2BYTE_HEAD
		if (!(int_char & (1 << 4))) return UTF8_BYTE_3BYTE_HEAD
		if (!(int_char & (1 << 3))) return UTF8_BYTE_4BYTE_HEAD
	}
	local messages = []
	local send_str_to_chat = function(str) {
		//removing whitespaces in the beginning - important!
		local last_whitespace_index = 0
		while(
			str[last_whitespace_index].tochar() == " "
			|| str[last_whitespace_index].tochar() == "\n"
			|| str[last_whitespace_index].tochar() == "\t"
		) last_whitespace_index += 1
		str = str.slice(last_whitespace_index, str.len())
		//adding char with code 1 - UTF8 characters fix
		local first_byte_type = get_utf8_byte_type(str[0])
		if (
			first_byte_type == UTF8_BYTE_2BYTE_HEAD
			|| first_byte_type == UTF8_BYTE_3BYTE_HEAD
			|| first_byte_type == UTF8_BYTE_4BYTE_HEAD
		) {
			str = (1).tochar() + str
		}
		messages.append(str)
	}
	local str_to_utf8_chars = function(str) {
		local arr = []
		foreach(int_char in str) {
			if (get_utf8_byte_type(int_char) == UTF8_BYTE_TAIL) {
				if (arr.len() > 0) {
					arr[arr.len() - 1] += int_char.tochar()
				}
			} else {
				arr.push(int_char.tochar())
			}
		}
		return arr
	}
	local MAX_MESSAGE_LENGTH_BYTES = 240
	local MAX_WORD_LENGTH_CHARS = 30
	//-------------------------------------
	if (typeof message != "string") {
		message = message.tostring()
	}
	if (vargv.len() > 0) {
		local args = [this, message]
		args.extend(vargv)
		message = format.acall(args)
	}
	local chars = str_to_utf8_chars(message)
	local start_index = 0
	local word_first_symbol = 0
	local current_len = 0
	while(true) {
		if (word_first_symbol >= chars.len()) {
			//log("word_first_symbol >= chars.len()")
			//printing
			local str = ""
			for (local i = start_index; i < chars.len(); i++) {
				str += chars[i]
			}
			send_str_to_chat(str)
			//log("[str len] " + str.len())
			//log(str)
			break
		}
		//seaching for end of word
		local next_space_symbol
		local word_len = chars[word_first_symbol].len()
		for(next_space_symbol = word_first_symbol + 1; next_space_symbol <= chars.len(); next_space_symbol++) {
			if (next_space_symbol == chars.len()) break
			if (next_space_symbol - word_first_symbol >= MAX_WORD_LENGTH_CHARS) break
			local char = chars[next_space_symbol]
			if (char == " ") break
			if (char == "\n") break
			if (char == "\t") break
			word_len += char.len()
		}
		local currentWordToStr = function() {
			local str = ""
			for (local i = word_first_symbol; i < next_space_symbol ;i++) {
				str += chars[i]
			}
			return str
		}
		//log("[word len] " + word_len + " [" + currentWordToStr() + "] [total len] " + (current_len + word_len))
		// start_index - first symbol that was not printed yet
		// word_first_symbol - first symbol of last word
		// next_space_symbol - first symbol after the end of last word
		// current_len - length from start_index to start of word (exclusive) in bytes
		if (current_len + word_len > MAX_MESSAGE_LENGTH_BYTES) {
			//log("current_len + word_len > MAX_MESSAGE_LENGTH_BYTES" + ": " + current_len + " + " + word_len)
			//printing without last word
			local str = ""
			for (local i = start_index; i < word_first_symbol; i++) {
				str += chars[i]
			}
			send_str_to_chat(str)
			//log("[str len] " + str.len())
			//log(str)
			start_index = word_first_symbol
			word_first_symbol = next_space_symbol
			current_len = word_len
		} else {
			word_first_symbol = next_space_symbol
			current_len += word_len
		}
	}
	local send_all_to_chat = function() {
		foreach(message in messages) {
			Say(null, message, false)
		}
	}
	if (
		!is_dedicated()
		&& !server_host()
		&& ("register_callback" in root)
	) {
		local sent = false
		local unique_key = "__say_" + UniqueString()
		local try_send_later = function() {
			if (!("DirectorScript" in root)) return
			register_callback(unique_key, "player_team", function(params) {
				if (params.oldteam != 0) return
				if (params.isbot) return
				send_all_to_chat()
				sent = true
				return false
			})
		}
		try_send_later()
		EntFire("worldspawn", "callscriptfunction", unique_key, 0.5)
		root[unique_key] <- function() {
			if (sent) return
			if (server_host()) {
				send_all_to_chat()
			} else {
				try_send_later()
			}
			delete root[unique_key]
		}
	} else {
		send_all_to_chat()
	}
})

_def_func("vecstr2", function(vec) {
	local digits = [vec.x, vec.y, vec.z]
	foreach (i, digit in digits) if (digit == -0) digits[i] = 0
	return format("%.2f %.2f %.2f", digits[0], digits[1], digits[2])
})

_def_func("vecstr3", function(vec) {
	local digits = [vec.x, vec.y, vec.z]
	foreach (i, digit in digits) if (digit == -0) digits[i] = 0
	return format("%.3f %.3f %.3f", digits[0], digits[1], digits[2])
})

_def_func("tolower", function(str) {
	//currently supports only english and russian letters
	//extendable by this script: https://pastebin.com/26j2zJAg
	local unicode_tolower = {
		"\xFFD0\xFF90": "\xFFD0\xFFB0",
		"\xFFD0\xFF91": "\xFFD0\xFFB1",
		"\xFFD0\xFF92": "\xFFD0\xFFB2",
		"\xFFD0\xFF93": "\xFFD0\xFFB3",
		"\xFFD0\xFF94": "\xFFD0\xFFB4",
		"\xFFD0\xFF95": "\xFFD0\xFFB5",
		"\xFFD0\xFF81": "\xFFD1\xFF91",
		"\xFFD0\xFF96": "\xFFD0\xFFB6",
		"\xFFD0\xFF97": "\xFFD0\xFFB7",
		"\xFFD0\xFF98": "\xFFD0\xFFB8",
		"\xFFD0\xFF99": "\xFFD0\xFFB9",
		"\xFFD0\xFF9A": "\xFFD0\xFFBA",
		"\xFFD0\xFF9B": "\xFFD0\xFFBB",
		"\xFFD0\xFF9C": "\xFFD0\xFFBC",
		"\xFFD0\xFF9D": "\xFFD0\xFFBD",
		"\xFFD0\xFF9E": "\xFFD0\xFFBE",
		"\xFFD0\xFF9F": "\xFFD0\xFFBF",
		"\xFFD0\xFFA0": "\xFFD1\xFF80",
		"\xFFD0\xFFA1": "\xFFD1\xFF81",
		"\xFFD0\xFFA2": "\xFFD1\xFF82",
		"\xFFD0\xFFA3": "\xFFD1\xFF83",
		"\xFFD0\xFFA4": "\xFFD1\xFF84",
		"\xFFD0\xFFA5": "\xFFD1\xFF85",
		"\xFFD0\xFFA6": "\xFFD1\xFF86",
		"\xFFD0\xFFA7": "\xFFD1\xFF87",
		"\xFFD0\xFFA8": "\xFFD1\xFF88",
		"\xFFD0\xFFA9": "\xFFD1\xFF89",
		"\xFFD0\xFFAA": "\xFFD1\xFF8A",
		"\xFFD0\xFFAB": "\xFFD1\xFF8B",
		"\xFFD0\xFFAC": "\xFFD1\xFF8C",
		"\xFFD0\xFFAD": "\xFFD1\xFF8D",
		"\xFFD0\xFFAE": "\xFFD1\xFF8E",
		"\xFFD0\xFFAF": "\xFFD1\xFF8F",
	}
	str = str.tolower()
	local newstr = ""
	local has_unicode = false
	for(local i = 0; i < str.len(); i++) {
		local symbol = str[i]
		if (symbol < 0) {
			has_unicode = true
			break
		}
	}
	if (!has_unicode)
		return str
	for(local i = 0; i < str.len(); i++) {
		local symbol = str[i]
		if (symbol >= 0) {
			newstr += symbol.tochar()
		} else {
			if (i == str.len() - 1)
				throw "unfinished unicode string: last char have negative code"
			local symbol_next = str[++i]
			local unicode_char = symbol.tochar() + symbol_next.tochar()
			if (unicode_char in unicode_tolower)
				unicode_char = unicode_tolower[unicode_char]
			newstr += unicode_char
		}
	}
	return newstr
})

_def_func("remove_quotes", function(str) {
	if (str.slice(0, 1) == "\"" && str.slice(str.len() - 1) == "\"")
		return str.slice(1, str.len() - 1)
	return str
})

_def_func("has_special_symbols", function(str) {
	//[A-Za-z0-9_]
	local symbolA = "A"[0]
	local symbolZ = "Z"[0]
	local symbola = "a"[0]
	local symbolz = "z"[0]
	local symbol0 = "0"[0]
	local symbol9 = "9"[0]
	local symbol_ = "_"[0]
	foreach (char in str) {
		if (char >= symbolA && char <= symbolZ) continue
		if (char >= symbola && char <= symbolz) continue
		if (char >= symbol0 && char <= symbol9) continue
		if (char == symbol_) continue
		return true
	}
	return false
})

_def_func("is_json_printable", function(str) {
	foreach (char in str) {
		if (char.tochar() == "\r") return false
		if (char.tochar() == "\n") return false
		if (char.tochar() == "\"") return false
		if (char.tochar() == "\\") return false
	}
	return true
})

if (!("__reporters" in this)) _def_constvar("__reporters", [])

_def_func("reporter", function(name, func) {
	foreach(_reporter in __reporters) {
		if(_reporter.name == name) {
			_reporter.func = func
			return
		}
	}
	__reporters.append({
		name = name
		func = func
	})
})

_def_func("report", function() {
	printl("----------------------------------")
	printl("lib version: " + lib_version)
	printl(_version_)
	printl("Scripted mode: " + (("SessionState" in root) ? "true" : "false"))
	local collisions = _get_collisions().errstrings
	if (collisions.len() > 0) {
		printl("PROBLEMS:")
		foreach(str in collisions) {
			printl("\t" + str)
		}
	} else {
		printl("No name collisions/mismatches found")
	}
	foreach(_reporter in __reporters) {
		printl(_reporter.name + ":")
		if (_reporter.func) _reporter.func()
	}
	printl("----------------------------------")
})

_def_func("__report", report) //if some script overrides "report"