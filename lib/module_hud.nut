//---------- DOCUMENTATION ----------

/**
FRAMEWORK FOR CONTROLLING HUD
Warning! All tasks and callbacks are removed on round change.
! requires lib/module_base !
! requires lib/module_tasks !
See: L4D2_EMS/Appendix:_HUD. Timers can be used independently of HUD. See an example at the end of the documentation. All HUD data (slots, timers, callbacks, lists, messages) are removed between rounds.
------------------------------------
hud.show_message(text, duration, background, float_up, x, y, w, h)
	Shows message without possessing a slot. It's a simple usage of the HUD library.
------------------------------------
hud.possess_slot(possessor, name)
	Takes control over free HUD slot. Possessor is your script name, any string that is used as namespace to prevent name collisions. Name - any number or string to name the slot (does not match real slot id, that is internal). Returns true if success or false if no free slots.
hud.release_slot(possessor, name)
	Releases possessed slot. Slot is getting hidden on HUD and becomes free to possess. You can't perform operations with it anymore.
------------------------------------
hud.release_all_slots(possessor)
	Releases all slots. Same as call hud.release_slot for all possessed slots.
hud.get_all_slots(possessor)
	Returns a list of all possessed slots.
hud.possess_multiple_slots(possessor, names)
	Takes an array of slot names, tries to possess them all. If there is not enough free slots, returns false and does not possess anything.
------------------------------------
hud.set_position(possessor, name, x, y, w, h)
	Sets slot position and dimensions; default is 0.1, 0.1, 0.3, 0.05.
hud.set_visible(possessor, name, visible)
	Draw or hide slot, last argument is boolean; by default slots are drawn when get possessed.
hud.set_text(possessor, name, text)
	Set static text for slot (clears datafunc, special, staticsctring - see L4D2_EMS/Appendix:_HUD).
hud.set_datafunc(possessor, name, func)
	Sets datafunc for slot (clears static text, special, staticsctring - see L4D2_EMS/Appendix:_HUD).
hud.set_special(possessor, name, value, is_prefix, text)
	Sets special value for slot (clears static text and datafunc - see L4D2_EMS/Appendix:_HUD). Does not accept HUD_SPECIAL_TIMER*, use timer name as value. Last two arguments are optional: is_prefix may be hud.PREFIX( = true) or hud.POSTFIX( = false). Text argument is your custom prefix or postfix.
------------------------------------
hud.flags_set(possessor, name, flags)
	Set flags for slot (for example, HUD_FLAG_ALIGN_LEFT, see L4D2_EMS/Appendix:_HUD)
hud.flags_add(possessor, name, flags)
	Add flags for slot.
hud.flags_remove(possessor, name, flags)
	Remove flags for slot.
------------------------------------
hud.possess_timer(possessor, timer_name)
	Posess free timer, timer name should be string; return true (success) or false (no free timer slots). Timers are not shown until binded to slots using set_special function with value = <timer_name>. See example below.
hud.release_timer(possessor, timer_name)
	Release possessed timer (like releasing hud slots).
hud.disable_timer(possessor, timer_name)
	Disables timer (--:-- will be shown), new timers are disabled by default
hud.set_timer(possessor, timer_name, value)
	Sets timer value, does not start or stop timer (if timer is disabled, it will become paused).
hud.start_timer_countup(possessor, timer_name)
	Starts timer, count up; does not change it's value (if it was disabled, 0:00 is default).
hud.start_timer_countdown(possessor, timer_name)
	Starts timer, count down; does not change it's value (if it was disabled, 0:00 is default).
hud.pause_timer(possessor, timer_name)
	Pauses timer; does not change it's value (if it was disabled, 0:00 is default).
hud.get_timer(possessor, timer_name)
	Returns timer value as float.
Hints:
	- Use HUD_FLAG_ALLOWNEGTIMER slot flag to display negative timer values
	- !! timer will work wrongly if slot does not allow negative, but timer once dropped below zero !!
	- !! too lazy to fix this (need to add allow_negative field to timer table) !!
------------------------------------
hud.set_timer_callback(possessor, timer_name, value, func, stop_timer = false)
	Call func on specified timer value; if "stop" argument is true, stops timer on callback. Func may be null if you just want to stop the timer.
hud.remove_timer_callbacks(possessor, timer_name)
	Remove all registered timer callbacks from specified timer.
------------------------------------
//The functions below affect slots for all possessors and so may break other scripts.
hud.global_off()
	Don't render all HUD elements. 
hud.global_on()
	Resume rendering of all HUD elements.
hud.global_clear()
	Release all possessed elements.
------------------------------------
Example:
	hud.possess_timer("MyHUDInterface", "MyTimer")
	//we possess a timer but don't bind it to slot yet, so we don't see it
	hud.set_timer("MyHUDInterface", "MyTimer", 10)
	//we set initial value for our timer
	hud.start_timer_countdown("MyHUDInterface", "MyTimer")
	//we start out timer
	hud.set_timer_callback("MyHUDInterface", "MyTimer", 1, @()cvar("mp_restartgame", 1))
	//we bind action to our timer
	hud.possess_slot("MyHUDInterface", "MyTimerSlot")
	//we possess a slot for out timer
	hud.set_position("MyHUDInterface", "MyTimerSlot", 0.35, 0.75, 0.3, 0.05)
	//we set position for our slot
	hud.set_special("MyHUDInterface", "MyTimerSlot", "MyTimer", hud.PREFIX, "Game is restarting in ")
	//we bind timer to slot and now we see the timer on HUD
 */

//---------- CODE ----------

this = ::root

log("[lib] including module_hud")

_def_func("__hud_data_init", function() { //if we include library first time
	DirectorScript.__hud_data <- {}
	_def_var("__hud_data", DirectorScript.__hud_data.weakref(), 0, "table")
	_def_var("__hud_data.possessors", {})
	_def_var("__hud_data.internal_slots", {})
	_def_var("__hud_data.layout", { //realtime!
		Fields = {}
	})
	_def_var("__hud_data.layout_dummy", {
		Fields = {}
	})
	_def_var("__hud_data.initialized", false)
	_def_var("__hud_data.disabled", false)
	_def_var("__hud_data.timers", {})
	_def_var("__hud_data.timer_callbacks", {})
	_def_var("__hud_data.lists", {})
	
	for (local i = 1; i <= 14; i++) {
		//14 slots (1-14)
		__hud_data.internal_slots[i] <- {
			possessor = null,
			name = null
		}
	}
	for (local i = 0; i < 4; i++) {
		//4 timers (0-3)
		__hud_data.timers[i] <- {
			possessor = null,
			name = null,
			state = TIMER_DISABLE,
		}
	}
})

_def_constvar("hud", {})


_def_func("hud.__check_init", function() {
	if (!("__hud_data" in root) || !__hud_data || !__hud_data.initialized)
		hud.init()
}.bindenv(hud))

_def_func("hud.__refresh", function() {
	HUDSetLayout(__hud_data.disabled ? __hud_data.layout_dummy : __hud_data.layout)
}.bindenv(hud))

_def_func("hud.__find_free_slot", function() { //returns slot internal index or -1 if no free slots
	foreach(index, slot in __hud_data.internal_slots)
		if (!slot.possessor)
			return index
	return -1
}.bindenv(hud))

_def_func("hud.__get_internal_index", function(possessor, name) { //throws exception if not found
	
	checktype(possessor, STRING)
	checktype(name, ["string", "integer"])
	
	if (!(possessor in __hud_data.possessors))
		throw format("Possessor %s not found", possessor.tostring())
	local possessor_table = __hud_data.possessors[possessor]
	if (!(name in possessor_table))
		throw format("Name %s not found for possessor %s", name.tostring(), possessor)
	return possessor_table[name]
}.bindenv(hud))

_def_func("hud.__set_flags", function(slot_table, flag, value) {
	if (value)
		slot_table.flags = slot_table.flags & ~flag
	else
		slot_table.flags = slot_table.flags | flag
}.bindenv(hud))

_def_func("hud.__find_free_timer", function()  { //returns timer index (0-3) or -1 if no free timers
	foreach (id, timer in __hud_data.timers)
		if (!timer.possessor)
			return id
	return -1
}.bindenv(hud))

_def_func("hud.__get_timer_id", function(possessor, name, dont_throw = false) { //throws exception if not found
	
	checktype(possessor, STRING)
	checktype(name, STRING)
	
	foreach (id, timer in __hud_data.timers)
		if (timer.possessor == possessor && timer.name == name)
			return id
	if (dont_throw) return -1
	throw format("cannot find timer named %s for possessor %s", name.tostring(), possessor)
}.bindenv(hud))

_def_func("hud.init", function() {
	if (("__hud_data" in root) && __hud_data && __hud_data.initialized)
		return
	__hud_data_init()
	__hud_data.initialized = true
	log("[lib] HUD was initialized")
	
	hud.__refresh()
}.bindenv(hud))

_def_func("hud.possess_slot", function(possessor, name) {
	__check_init()
	
	checktype(possessor, STRING)
	checktype(name, ["string", "integer"])
	
	local slot_to_possess = hud.__find_free_slot()
	if (slot_to_possess == -1) {
		log("[lib] possess_slot(): cannot find free HUD slots")
		return false
	}
	if (!(possessor in __hud_data.possessors))
		__hud_data.possessors[possessor] <- {}
	local possessor_table = __hud_data.possessors[possessor]
	if (name in possessor_table)
		throw format("name %s is already registered for possessor %s", name.tostring(), possessor)
	
	//first action: add slot to possessors table
	possessor_table[name] <- slot_to_possess
	
	//second action: edit possessor in internal_slots
	__hud_data.internal_slots[slot_to_possess].possessor = possessor
	__hud_data.internal_slots[slot_to_possess].name = name
	
	//third action: add slot to layout
	__hud_data.layout.Fields[slot_to_possess] <- {
		slot = slot_to_possess,
		dataval = "",
		flags = 0
	}
	HUDPlace(slot_to_possess, 0.1, 0.1, 0.3, 0.05)
	
	hud.__refresh()
	return true
}.bindenv(hud))

_def_func("hud.release_slot", function(possessor, name) {
	__check_init()
	
	checktype(possessor, STRING)
	checktype(name, ["string", "integer"])
	
	//first action: remove slot from possessors table
	if (!(possessor in __hud_data.possessors)) {
		log("[lib] hud.release_slot(): no possessor with name " + possessor)
		return
	}
	local possessor_table = __hud_data.possessors[possessor]
	if (!(name in possessor_table)) {
		log("[lib] hud.release_slot(): no slot with name " + possessor + ":" + name.tostring())
		return
	}
	local slot_to_delete = __get_internal_index(possessor, name)
	delete possessor_table[name]
	
	//second action: edit possessor in internal_slots
	__hud_data.internal_slots[slot_to_delete].possessor = null
	
	//third action: remove slot from layout
	delete __hud_data.layout.Fields[slot_to_delete]
	
	hud.__refresh()
}.bindenv(hud))

_def_func("hud.get_all_slots", function(possessor) {
	__check_init()
	
	if (!(possessor in __hud_data.possessors)) return []
	local possessor_table = __hud_data.possessors[possessor]
	local arr = []
	foreach(name in possessor_table) arr.append(name)
	return arr
}.bindenv(hud))

_def_func("hud.release_all_slots", function(possessor) {
	__check_init()
	
	local possessed = __hud_data.get_all_slots(possessor)
	foreach(name in possessed)
		__hud_data.release_slot(possessor, _name)
}.bindenv(hud))

_def_func("hud.possess_multiple_slots", function(possessor, names) {
	__check_init()
	
	checktype(names, "array")
	
	local possessed = []
	foreach(name in names) {
		local success
		try {
			success = __hud_data.possess_slot(possessor, name)
		} catch (exception) {
			success = false
		}
		if (!success) {
			foreach(_name in possessed)
				__hud_data.release_slot(possessor, _name)
			return false
		} else {
			possessed.append(name)
		}
	}
	return true
}.bindenv(hud))

_def_func("hud.set_position", function(possessor, name, x, y, w, h) {
	__check_init()
	
	checktype(x, NUMBER)
	checktype(y, NUMBER)
	checktype(w, NUMBER)
	checktype(h, NUMBER)
		
	local slot = __get_internal_index(possessor, name)
	HUDPlace(slot, x, y, w, h)
	
	hud.__refresh()
}.bindenv(hud))

_def_func("hud.set_visible", function(possessor, name, is_visible) {
	__check_init()
	
	checktype(visible, BOOL)
	
	local slot = __get_internal_index(possessor, name)
	local slot_table = __hud_data.layout.Fields[slot]
	__set_flags(slot_table, HUD_FLAG_NOTVISIBLE, is_visible)
	
	hud.__refresh()
}.bindenv(hud))

_def_func("hud.set_text", function(possessor, name, text) {
	__check_init()
	
	checktype(text, ["string", "integer", "float"])
	
	local slot = __get_internal_index(possessor, name)
	local slot_table = __hud_data.layout.Fields[slot]
	if ("datafunc" in slot_table) delete slot_table.datafunc
	if ("special" in slot_table) delete slot_table.special
	if ("staticstring" in slot_table) delete slot_table.staticstring
	slot_table.dataval <- text
	
	hud.__refresh()
}.bindenv(hud))

_def_func("hud.set_datafunc", function(possessor, name, func) {
	__check_init()
	
	checktype(func, FUNC)
	
	local slot = __get_internal_index(possessor, name)
	local slot_table = __hud_data.layout.Fields[slot]
	if ("dataval" in slot_table) delete slot_table.dataval
	if ("special" in slot_table) delete slot_table.special
	if ("staticstring" in slot_table) delete slot_table.staticstring
	slot_table.datafunc <- func
	
	hud.__refresh()
}.bindenv(hud))

_def_constvar("hud.PREFIX", true)
_def_constvar("hud.POSTFIX", false)

_def_func("hud.set_special", function(possessor, name, value, is_prefix = null, text = null) {
	__check_init()
	
	checktype(value, ["integer", "string"])
	if (is_prefix != null) checktype(is_prefix, BOOL)
	if (text != null) checktype(text, STRING)
	
	if (is_prefix != null && text == null || is_prefix != null && text == null)
		throw "is_prefix (4th argument) and text (5th argument) are used together, one of them is null"
	if (value == HUD_SPECIAL_TIMER0 || value == HUD_SPECIAL_TIMER1 || value == HUD_SPECIAL_TIMER2 || value == HUD_SPECIAL_TIMER3)
		throw "value (3rd argument) cannot be HUD_SPECIAL_TIMER*, use timer name instead"
	if (type(value) == "string")
		value = __get_timer_id(possessor, value) //now it's integer
	
	local slot = __get_internal_index(possessor, name)
	local slot_table = __hud_data.layout.Fields[slot]
	if ("dataval" in slot_table) delete slot_table.dataval
	if ("datafunc" in slot_table) delete slot_table.datafunc
	slot_table.special <- value
	if (is_prefix != null) {
		slot_table.staticstring <- text
		__set_flags(slot_table, HUD_FLAG_POSTSTR, is_prefix)
		__set_flags(slot_table, HUD_FLAG_PRESTR, !is_prefix)
	} else {
		slot_table.staticstring <- null
	}
	
	hud.__refresh()
}.bindenv(hud))

_def_func("hud.flags_set", function(possessor, name, flags) {
	__check_init()
	
	checktype(flags, "integer")
	
	local slot = __get_internal_index(possessor, name)
	local slot_table = __hud_data.layout.Fields[slot]
	slot_table.flags = flags
	
	hud.__refresh()
}.bindenv(hud))

_def_func("hud.flags_add", function(possessor, name, flags) {
	__check_init()
	
	checktype(flags, "integer")
	
	local slot = __get_internal_index(possessor, name)
	local slot_table = __hud_data.layout.Fields[slot]
	__set_flags(slot_table, flags, true)
	
	hud.__refresh()
}.bindenv(hud))

_def_func("hud.flags_remove", function(possessor, name, flags) {
	__check_init()
	
	checktype(flags, "integer")
	
	local slot = __get_internal_index(possessor, name)
	local slot_table = __hud_data.layout.Fields[slot]
	__set_flags(slot_table, flags, false)
	
	hud.__refresh()
}.bindenv(hud))

_def_func("hud.possess_timer", function(possessor, timer_name) {
	__check_init()
	
	checktype(possessor, STRING)
	checktype(timer_name, STRING)
	
	local timer_to_possess = hud.__find_free_timer()
	if (timer_to_possess == -1) {
		log("[lib] possess_timer(): cannot find free timer")
		return false
	}
	if (__get_timer_id(possessor, timer_name, true) != -1)
		throw format("timer name %s is already registered for possessor %s", timer_name.tostring(), possessor)
	
	__hud_data.timers[timer_to_possess].possessor = possessor
	__hud_data.timers[timer_to_possess].name = timer_name
	
	return true
}.bindenv(hud))

_def_func("hud.release_timer", function(possessor, timer_name) {
	__check_init()
	
	local timer_to_release = __get_timer_id(possessor, timer_name)
	__hud_data.timers[timer_to_release].possessor = null
	__hud_data.timers[timer_to_release].name = null
	HUDManageTimers(timer_to_possess, TIMER_DISABLE, 0)
	__hud_data.timers[timer_index].state == TIMER_DISABLE
}.bindenv(hud))

_def_func("hud.disable_timer", function(possessor, timer_name) {
	__check_init()
	
	checktype(possessor, STRING)
	checktype(timer_name, STRING)
	
	local timer_index = __get_timer_id(possessor, timer_name)
	HUDManageTimers(timer_to_possess, TIMER_DISABLE, 0)
	__hud_data.timers[timer_index].state == TIMER_DISABLE
}.bindenv(hud))

_def_func("hud.set_timer", function(possessor, timer_name, value) {
	__check_init()
	
	checktype(value, NUMBER)
	
	local timer_index = __get_timer_id(possessor, timer_name)
	HUDManageTimers(timer_index, TIMER_STOP, 0)
	local old_state = __hud_data.timers[timer_index].state
	HUDManageTimers(timer_index, TIMER_SET, value)
	if (old_state == TIMER_COUNTDOWN) {
		HUDManageTimers(timer_index, TIMER_COUNTDOWN, value)
	} else if (old_state == TIMER_COUNTUP) {
		HUDManageTimers(timer_index, TIMER_COUNTUP, value)
	} else {
		__hud_data.timers[timer_index].state = TIMER_STOP
	}
}.bindenv(hud))

_def_func("hud.start_timer_countup", function(possessor, timer_name) {
	__check_init()
	
	local timer_index = __get_timer_id(possessor, timer_name)
	local old_state = __hud_data.timers[timer_index].state
	local value = HUDReadTimer(timer_index) //even for disabled
	HUDManageTimers(timer_index, TIMER_COUNTUP, value)
	__hud_data.timers[timer_index].state = TIMER_COUNTUP
}.bindenv(hud))

_def_func("hud.start_timer_countdown", function(possessor, timer_name) {
	__check_init()
	
	local timer_index = __get_timer_id(possessor, timer_name)
	local old_state = __hud_data.timers[timer_index].state
	local value = HUDReadTimer(timer_index) //even for disabled
	HUDManageTimers(timer_index, TIMER_COUNTDOWN, value)
	__hud_data.timers[timer_index].state = TIMER_COUNTDOWN
}.bindenv(hud))

_def_func("hud.pause_timer", function(possessor, timer_name) {
	__check_init()
	
	local timer_index = __get_timer_id(possessor, timer_name)
	local value = HUDReadTimer(timer_index) //even for disabled
	HUDManageTimers(timer_index, TIMER_STOP, 0)
	HUDManageTimers(timer_index, TIMER_SET, value)
	__hud_data.timers[timer_index].state = TIMER_STOP
}.bindenv(hud))

_def_func("hud.get_timer", function(possessor, timer_name) {
	__check_init()
	
	local timer_index = __get_timer_id(possessor, timer_name)
	return HUDReadTimer(timer_index)
}.bindenv(hud))

_def_func("hud.set_timer_callback", function(possessor, timer_name, value, func, stop_timer = false) {
	__check_init()
	
	checktype(value, NUMBER)
	if (func != null) checktype(func, FUNC)
	checktype(stop_timer, BOOL)
	
	local timer_index = __get_timer_id(possessor, timer_name)
	if(__hud_data.timer_callbacks.len() == 0) {
		register_ticker("__hud_callbacks", function() {
			foreach(key, callback in __hud_data.timer_callbacks) {
				local timer_index = callback.timer_index
				local state = __hud_data.timers[timer_index].state
				if (state == TIMER_DISABLE) {
					delete __hud_data.timer_callbacks[key]
					continue
				}
				local current_value = HUDReadTimer(timer_index)
				if (
					state == TIMER_COUNTUP && current_value >= callback.value
					|| state == TIMER_COUNTDOWN && current_value <= callback.value
				) {
					if (callback.stop_timer) {
						hud.pause_timer(callback.possessor, callback.name)
						hud.set_timer(callback.possessor, callback.name, value)
						//HUDManageTimers(timer_index, TIMER_STOP, 0)
						//HUDManageTimers(timer_index, TIMER_SET, value)
						//__hud_data.timers[timer_index].state = TIMER_STOP
					}
					delete __hud_data.timer_callbacks[key]
					if (callback.func)
						callback.func()
				}
			}
			if (__hud_data.timer_callbacks.len() == 0)
				remove_ticker("__hud_callbacks")
		})
	}
	__hud_data.timer_callbacks[UniqueString()] <- {
		possessor = possessor,
		name = timer_name,
		value = value,
		func = func,
		stop_timer = stop_timer,
		timer_index = timer_index
	}
}.bindenv(hud))

_def_func("hud.remove_timer_callbacks", function(possessor, timer_name) {
	__check_init()
	
	local timer_index = __get_timer_id(possessor, timer_name)
	foreach(key, callback in __hud_data.timer_callbacks)
		if (callback.possessor == possessor && callback.name = timer_name)
			delete __hud_data.timer_callbacks[key]
	if (__hud_data.timer_callbacks.len() == 0)
		remove_ticker("__hud_callbacks")
}.bindenv(hud))

_def_func("hud.global_off", function() {
	__check_init()
	__hud_data.disabled = true
	hud.__refresh()
}.bindenv(hud))

_def_func("hud.global_on", function() {
	__check_init()
	__hud_data.disabled = false
	hud.__refresh()
}.bindenv(hud))

_def_func("hud.global_clear", function() {
	__check_init()
	__hud_data_init()
	hud.__refresh()
}.bindenv(hud))

_def_func("hud.show_message", function(
	text,
	duration = 5,
	background = true,
	float_up = false,
	x = 0.35,
	y = 0.75,
	w = 0.3,
	h = 0.05
) {
	__check_init()
	
	checktype(text, STRING)
	checktype(duration, NUMBER)
	checktype(background, BOOL)
	checktype(float_up, BOOL)
	checktype(x, NUMBER)
	checktype(y, NUMBER)
	checktype(w, NUMBER)
	checktype(h, NUMBER)
	
	local slot_name = UniqueString()
	if (!hud.possess_slot("__show_message", slot_name)) {
		log("[lib] show_message(): WARNING! no free slots for message: " + text)
		return
	}
	
	hud.set_position("__show_message", slot_name, x, y, w, h)
	hud.flags_set("__show_message", slot_name, HUD_FLAG_ALIGN_CENTER | (background ? 0 : HUD_FLAG_NOBG))
	hud.set_text("__show_message", slot_name, text)
	local start_time = clock.sec()
	
	if (float_up)
		register_ticker("__show_message" + slot_name, function() {
			local function dY(dT) {
				return 0.15*(1 - 1/(dT + 1))
			}
			hud.set_position("__show_message", slot_name, x, y - dY(clock.sec() - start_time), w, h)
			hud.__refresh()
		})
	delayed_call(duration, function() {
		hud.release_slot("__show_message", slot_name)
		if (float_up)
			remove_ticker("__show_message" + slot_name)
	})
	
	hud.__refresh()
}.bindenv(hud))

_def_func("hud.show_list", function(key, lines, x0 = 0.1, y0 = 0.25, w = 0.3, h = 0.05, dh = 0, background = false) {
	__check_init()
	
	checktype(key, STRING)
	checktype(lines, "array")
	checktype(x0, NUMBER)
	checktype(y0, NUMBER)
	checktype(w, NUMBER)
	checktype(h, NUMBER)
	checktype(dh, NUMBER)
	checktype(background, BOOL)
	
	local lists = __hud_data.lists
	if (!(key in lists)) {
		lists[key] <- {
			slots = []
		}
	}
	local list = lists[key]
	list.x0 <- x0
	list.y0 <- y0
	list.w <- w
	list.h <- h
	list.dh <- dh
	list.background <- background
	list.desired_size <- lines.len()
	
	if (!__list_resize(list, lines.len())) {
		log("[lib] show_list(): WARNING! no free slots for list: " + key)
	}
	local len = list.slots.len()
	if (len == 0) {
		log("[lib] show_list(): WARNING! empty list: " + key)
	}
	for(local i = 0; i < len; i++) {
		local key = list.slots[i].key
		hud.set_text("__lists", key, lines[i])
	}
}.bindenv(hud))

//may not add enough slots if there are no free slots, then returns false
_def_func("hud.__list_resize", function(list, new_size) {
	local slots = list.slots
	local current_len = slots.len()
	local not_enough_slots = false
	if (new_size > current_len) {
		for (local i = current_len; i < new_size; i++) {
			local new_key = UniqueString()
			if (!hud.possess_slot("__lists", new_key)) {
				not_enough_slots = true
				break
			}
			slots.append({
				key = new_key
			})
			hud.flags_set("__lists", new_key, HUD_FLAG_ALIGN_LEFT | (list.background ? 0 : HUD_FLAG_NOBG))
		}
	} else if (new_size < current_len) {
		for (local i = new_size; i < current_len; i++) {
			hud.release_slot("__lists", slots[i].key)
		}
		for (local i = new_size; i < current_len; i++) {
			slots.pop()
		}
	}
	local x1 = list.x0
	local w = list.w
	local h = list.h
	for(local i = 0; i < slots.len(); i++) {
		local y1 = list.y0 + (list.h + list.dh) * i
		hud.set_position("__lists", slots[i].key, x1, y1, w, h)
	}
	return !not_enough_slots
}.bindenv(hud))

_def_func("hud.hide_list", function(key) {
	__check_init()
	
	checktype(key, STRING)
	
	local lists = __hud_data.lists
	if (!(key in lists)) throw "no such list: " + key
	
	__list_resize(lists[key], 0)
	delete lists[key]
}.bindenv(hud))

reporter("HUD system", function() {
	local initialized = ("__hud_data" in root) && __hud_data.initialized
	log("\tInitialized: " + (initialized ? "true" : "false"))
	if (!initialized) return
	log("\tTurned on: " + (!__hud_data.disabled ? "true" : "false"))
	log("\tPossessed slots (internal):")
	foreach(index, slot in __hud_data.internal_slots) {
		if (!slot.possessor) continue
		logf("\t\t%d: %s::%s", index, slot.possessor, slot.name)
	}
	log("\tPossessed timers (internal):")
	foreach(index, timer in __hud_data.timers) {
		if (!timer.possessor) continue
		logf("\t\t%d: %s::%s, state = %d", index, timer.possessor, timer.name, timer.state)
	}
	log("\tTimer callbacks:")
	foreach(table in __hud_data.timer_callbacks) {
		logf("\t\t%s::%s at %g %scalls %s", table.possessor, table.timer_name,
			table.value, (table.stop_timer ? "stops and " : ""), var_to_string(table.func))
	}
	log("\tLists:")
	foreach(key, list in __hud_data.lists) {
		local mismatch = list.desired_size != list.slots.len()
		logf("\t\t%s: %d slot(s)%s", key, list.slots.len(),
			mismatch ? format(" (%d desired slots)", list.desired_size) : "")
	}
})