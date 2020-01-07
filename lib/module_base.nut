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
	Example: log("Total" + rabbits_amount + "rabbits") //prints "Total X rabbits" with a linebreak
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
	Adds new function that will be called on report() call. If this name was already added, owerwrites function. Name should be a human-readable string that will be printed to chat before func() call. Different library modules uses this function.
 */
 
//---------- CODE ----------

::root <- getroottable().weakref()
this = ::root

lib_version <- "2.4.0"

if(typeof log == "native function") ln <- log

log <- function(...) {
	local first = true
	foreach(arg in vargv) {
		if (!first) print(" ")
		first = false
		print(arg)
	}
	print("\n")
}

log("[lib] version", lib_version)
log("[lib] including module_base")

IncludeScript("kapkan/lib/constants")

/* for example output: log_table(getroottable()) */
log_table <- function(table, max_depth = 3, current_depth = 0, manual_call = true, original_tables = null) {
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
}

player_to_str <- function(player) {
	if (invalid(player)) return "(deleted entity)"
	return format("Player (%d | %s)", player.GetEntityIndex().tointeger(), player.GetPlayerName())
}

ent_to_str <- function(ent) {
	if (invalid(ent)) return "(deleted entity)"
	local id = ent.GetEntityIndex().tointeger()
	if ("CTerrorPlayer" in getroottable() && ent instanceof ::CTerrorPlayer)
		return player_to_str(ent)
	else {
		local name = ent.GetName()
		return format("Entity (%s #%d%s)", ent.GetClassname(), id, name != "" ? " | " + name : "")
	}
}

var_to_str <- function(var) {
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
}

logv <- @(var) log(var_to_str(var))

loge <- @(var) log(ent_to_str(var))

logp <- @(var) log(player_to_str(var))

logt <- log_table

logf <- function(str, ...) {
	local args = [this, str]
	args.extend(vargv)
	log(format.acall(args))
}

concat <- function(arr, separator) {
	local str = "";
	for (local i = 0; i < arr.len(); i++)
		str += arr[i] + ((i != arr.len() - 1) ? separator : "");
	return str;
}

connect_strings <- concat //legacy

worldspawn <- Entities.First()

scope <- function(ent) {
	ent.ValidateScriptScope()
	return ent.GetScriptScope()
}

invalid <- function(ent) {
	if (!("IsValid" in ent)) return true;
	return !ent.IsValid();
}

entstr <- function(ent) {
	return ent.GetEntityHandle().tointeger().tostring()
}

deleted_ent <- invalid //legacy

ent_fire <- function(ent, action, value = "", delay = 0) {
	DoEntFire("!self", action, value, delay, null, ent)
}

min <- function(a, b) {
	return (a < b) ? a : b
}

max <- function(a, b) {
	return (a > b) ? a : b
}

NUMBER <- -1
FUNC <- -2
STRING <- -3
BOOL <- -4

checktype <- function(var, _type, noException = false /*don't throw exception, return false instead */) {
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
}

Teams <- {
	ANY = -1
	UNASSIGNED = 1 << 0
	SPECTATORS = 1 << 1
	SURVIVORS = 1 << 2
	INFECTED = 1 << 3
}

ClientType <- {
	ANY = -1
	HUMAN = 1 << 0
	BOT = 1 << 1
}

__dummy <- function(...) {}

if (!("__reporters" in this)) __reporters <- []

reporter <- function(name, func) {
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
}

report <- function() {
	log("----------------------------------")
	log("lib version: " + lib_version)
	foreach(_reporter in __reporters) {
		log(_reporter.name + ":")
		if (_reporter.func) _reporter.func()
	}
	log("----------------------------------")
}