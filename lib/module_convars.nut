//---------- DOCUMENTATION ----------

/**
FUNCTIONS FOR GETTING/SETTING CONVARS
! requires lib/module_base !
------------------------------------
cvar(_cvar, value)
	Performs Convars.SetValue and prints to console.
------------------------------------
cvarstr(_cvar)
	Alias of Convars.GetStr
------------------------------------
cvarf(_cvar)
	Alias of Convars.GetFloat
------------------------------------
cvarf_lim(_cvar, min, max)
	Same as Convars.GetFloat, but clumps returned value between min and max (min/max may be null).
------------------------------------
cvar_create(_cvar, value)
	Creates new convar using console command "setinfo <cvar> <value>". This value van be later retrieved with cvarf() or cvarstr() or changed with cvar(). Note that since this function runc console command, it takes some time (result cannot be retrieved with cvarf() immediately).
	Example: cvar_create("new_cvar", "123")
------------------------------------
cvars_add(_cvar, default_value, value)
	Sets cvar to new value, stores default and new value in table.
------------------------------------
cvars_reapply()
	Sets all cvars in table to their "new" values stored in table. Useful if cvars have been reset after "sv_cheats 0". Can be used with listening server_cvar event. Example (requires kapkan/lib/tasks):
	register_callback("server_cvar", "restore_cvars", function(params){
		if(params.cvarname == "sv_cheats") cvars_reapply()
		//Warning: beware changing sv_cheats here if it is locked, it will hang the game
	})
------------------------------------
cvars_restore(_cvar)
	Restores default cvar value from table and remove cvar from table.
------------------------------------
cvars_restore_all()
	Restores default cvar values from table and clears the table.
 */

//---------- CODE ----------

this = ::root

log("[lib] including module_convars")

cvar <- function(_cvar, value) {
	logf("cvar %s set to %s", _cvar, value.tostring());
	Convars.SetValue(_cvar, value);
}

cvarstr <- Convars.GetStr.bindenv(Convars)

cvarf <- Convars.GetFloat.bindenv(Convars)

cvarf_lim <- function(_cvar, min, max) {
	local val = cvarf(_cvar)
	if (min != null && val < min) {
		error(format("cvar %s cannot be less than %.2f\n", _cvar, min))
		val = min
	} else if (max != null && val > max) {
		error(format("cvar %s cannot be more than %.2f\n", _cvar, max))
		val = max
	}
	return val
}

cvar_create <- function(_cvar, value) {
	if (value == "") value = "\"\""
	logf("cvar %s created and set to %s", _cvar, value.tostring());
	SendToServerConsole("setinfo " + _cvar + " " + value) //if anyone doesn't alias setinfo!
	return value
}

/* we need next 3 functions to restore all previously set cvars if user toggles sv_cheats */

if (!("__cvars_list" in this)) __cvars_list <- {};

cvars_add <- function(_cvar, default_value, value) {
	cvar(_cvar, value);
	__cvars_list[_cvar] <- { default_value = default_value, value = value };
}

cvars_reapply <- function() {
	foreach (_cvar, table in __cvars_list)
		cvar(_cvar, table.value);
}

cvars_restore <- function(_cvar) {
	if (!(_cvar in __cvars_list)) throw "Cvar is not in list: " + _cvar;
	if (__cvars_list[_cvar].default_value)
		cvar(_cvar, __cvars_list[_cvar].default_value)
	delete __cvars_list[_cvar];
}

cvars_restore_all <- function() {
	foreach(_cvar, table in __cvars_list)
		if (__cvars_list[_cvar].default_value)
			cvar(_cvar, table.default_value);
	__cvars_list <- {};
}

reporter("Saved cvars", function() {
	if (__cvars_list.len() == 0) return
	local arr = []
	foreach(_cvar, table in __cvars_list)
		arr.append(format("%s = %s (default %s)", _cvar, table.value.tostring(), table.default_value.tostring()))
	log("\t" + concat(arr, ", "))
})