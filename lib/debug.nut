_def_var_nullable("__debug_override_time", null, "float")
_def_var("__debug_override_value", false)

_def_func("debug_on", function() {
	SendToServerConsole("setinfo debug 1")
	Convar.SetValue("developer", 1)
	__debug_override_time = Time()
	__debug_override_value = true
})

_def_func("debug_off", function() {
	SendToServerConsole("setinfo debug 0")
	__debug_override_time = Time()
	__debug_override_value = false
})

local current_debug_value = Convars.GetFloat("debug")
if (current_debug_value == null) {
	debug_off() //creating convar "debug"
} else if (current_debug_value == 1) {
	Convars.SetValue("developer", 1)
}

_def_func("__is_debug", function() {
	if (__debug_override_time == Time()) {
		return __debug_override_value
	} else {
		return (Convars.GetFloat("debug") > 0) //(null > 0) is false
	}
})

_def_func("debug", function(...) {
	local debug = __is_debug()
	if (vargv.len() == 0) return debug
	if (!debug) return
	if (typeof vargv[0] == "function") {
		local result = vargv[0]()
		if (result != null) log(result)
	} else {
		vargv.insert(0, this)
		log.acall(vargv)
	}
})

_def_func("debugf", function(...) {
	local debug = __is_debug()
	if (vargv.len() == 0) return debug
	if (!debug) return
	vargv.insert(0, this)
	logf.acall(vargv)
})