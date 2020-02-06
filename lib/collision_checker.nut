//For checking name collisions. _def_func(), _def_var(), _def_var_nullable(), _def_var_anytype() are used to "remember" all library fields and check problems (at first, overrides) later

this = getroottable()

if (!("_lib_functions" in this)) _lib_functions <- {}
if (!("_lib_variable_types" in this)) _lib_variable_types <- {}

_def_func <- function(path, func) {
	local table = this
	local path_tokens = split(path, ".")
	try {
		for(local i = 0; i < path_tokens.len() - 1; i++) {
			table = table[path_tokens[i]]
		}
		table[path_tokens.top()] <- func
	} catch (exception) {
		throw "[lib] _def_func(): ERROR for path " + path + ": " + exception
	}
	_lib_functions[path] <- func
}.bindenv(this)

_def_constvar <- _def_func

_VARTYPE_ANY <- (1 << 0)
_VARTYPE_NULLABLE <- (1 << 1)

_def_var <- function(path, value, flags = 0, vartype_override = null) {
	local path_tokens = split(path, ".")
	local table = this
	local vartype
	try {
		for(local i = 0; i < path_tokens.len() - 1; i++) {
			table = table[path_tokens[i]]
		}
		local slotname = path_tokens.top()
		table[slotname] <- value
		vartype = typeof(table[slotname])
		//fixed isssue with weakrefs: when weakref is assigned to a slot, typeof of the slot will not be weakref
		//https://developer.electricimp.com/squirrel/squirrelcrib#weak-references
	} catch (exception) {
		throw "[lib] _def_var(): ERROR for path " + path + ": " + exception
	}
	_lib_variable_types[path] <- [vartype_override ? vartype_override : vartype, flags]
}.bindenv(this)

_def_var_anytype <- function(path, value) {
	_def_var(path, value, _VARTYPE_ANY)
}.bindenv(this)

_def_var_nullable <- function(path, value, vartype_override = null) {
	_def_var(path, value, _VARTYPE_NULLABLE, vartype_override)
}.bindenv(this)

_ERROR_WRONG_FUNC <- 0
_ERROR_UNEXISTING_PATH <- 1
_ERROR_WRONG_VAR_TYPE <- 2
_ERROR_FOUND_IN_CONSTANTS <- 3

_get_collisions <- function() {
	local errlist_WRONG_FUNC = []
	local errlist_UNEXISTING_PATH = []
	local errlist_WRONG_VAR_TYPE = []
	local errlist_FOUND_IN_CONSTANTS = []
	foreach(path, func in _lib_functions) {
		try {
			local path_tokens = split(path, ".")
			if(path_tokens[0] in getconsttable()) {
				errlist_FOUND_IN_CONSTANTS.append({
					error = _ERROR_FOUND_IN_CONSTANTS
					path = path
				})
				continue
			}
			local table = this
			for(local i = 0; i < path_tokens.len() - 1; i++) {
				table = table[path_tokens[i]]
			}
			local value = table[path_tokens.top()]
			if (func != value) {
				errlist_WRONG_FUNC.append({
					error = _ERROR_WRONG_FUNC
					name = path
				})
			}
		} catch (exception) {
			errlist_UNEXISTING_PATH.append({
				error = _ERROR_UNEXISTING_PATH
				path = path
			})
		}
	}
	foreach(path, varinfo in _lib_variable_types) {
		try {
			local path_tokens = split(path, ".")
			if(path_tokens[0] in getconsttable()) {
				errlist_FOUND_IN_CONSTANTS.append({
					error = _ERROR_FOUND_IN_CONSTANTS
					path = path
				})
				continue
			}
			local table = this
			for(local i = 0; i < path_tokens.len() - 1; i++) {
				table = table[path_tokens[i]]
			}
			local varvalue = table[path_tokens.top()]
			local expected_vartype = varinfo[0]
			local varflags = varinfo[1]
			if (varflags & _VARTYPE_ANY) continue
			local vartype = typeof(varvalue)
			if (vartype == "null" && (varflags & _VARTYPE_NULLABLE)) continue
			if (vartype == "table" && expected_vartype == "weakref") continue
			if (vartype == "weakref" && expected_vartype == "table") continue
			if (vartype != expected_vartype) {
				errlist_WRONG_VAR_TYPE.append({
					error = _ERROR_WRONG_VAR_TYPE
					path = path
					vartype = vartype
					varflags = varflags
					expected_vartype = expected_vartype
				})
			}
		} catch (exception) {
			errlist_UNEXISTING_PATH.append({
				error = _ERROR_UNEXISTING_PATH
				path = path
			})
		}
	}
	//-------------
	local errlist = []
	errlist.extend(errlist_WRONG_FUNC)
	errlist.extend(errlist_UNEXISTING_PATH)
	errlist.extend(errlist_WRONG_VAR_TYPE)
	errlist.extend(errlist_FOUND_IN_CONSTANTS)
	//-------------
	local errstring_WRONG_FUNC = ""
	local errstring_UNEXISTING_PATH = ""
	local errstring_WRONG_VAR_TYPE = ""
	local errstring_FOUND_IN_CONSTANTS = ""
	foreach(err in errlist_WRONG_FUNC) {
		if (errstring_WRONG_FUNC.len() > 0) errstring_WRONG_FUNC += ", "
		errstring_WRONG_FUNC += err.name
	}
	foreach(err in errlist_UNEXISTING_PATH) {
		if (errstring_UNEXISTING_PATH.len() > 0) errstring_UNEXISTING_PATH += ", "
		errstring_UNEXISTING_PATH += "\"" + err.path + "\""
	}
	foreach(err in errlist_WRONG_VAR_TYPE) {
		if (errstring_WRONG_VAR_TYPE.len() > 0) errstring_WRONG_VAR_TYPE += ", "
		errstring_WRONG_VAR_TYPE += err.path + " (" + err.vartype + " instead of "
			+ err.expected_vartype + ((err.varflags & _VARTYPE_NULLABLE) ? " or null" : "") + ")"
	}
	foreach(err in errlist_FOUND_IN_CONSTANTS) {
		if (errstring_FOUND_IN_CONSTANTS.len() > 0) errstring_FOUND_IN_CONSTANTS += ", "
		errstring_FOUND_IN_CONSTANTS += "\"" + err.path + "\""
	}
	local errstrings = []
	if (errlist_WRONG_FUNC.len() > 0)
		errstrings.append("Wrong function(s)/const var(s): " + errstring_WRONG_FUNC)
	if (errlist_UNEXISTING_PATH.len() > 0)
		errstrings.append("Unexisting var(s): " + errstring_UNEXISTING_PATH)
	if (errlist_WRONG_VAR_TYPE.len() > 0)
		errstrings.append("Possibly wrong var type(s): " + errstring_WRONG_VAR_TYPE)
	if (errlist_FOUND_IN_CONSTANTS.len() > 0)
		errstrings.append("Overwriten by constants/enums: " + errstring_FOUND_IN_CONSTANTS)
	//-------------
	return {
		errlist = errlist
		errstrings = errstrings
	}
}.bindenv(this)