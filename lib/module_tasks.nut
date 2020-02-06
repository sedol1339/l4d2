//---------- DOCUMENTATION ----------

/**
FUNCTIONS FOR TASK MANAGMENT:
Delayer calls, tickers (OnGameFrame functions), loops, callbacks for events, tasks on shutdown and others.
! requires lib/module_base !
------------------------------------
delayed_call(...)
	Calls function after a given time. Usage:
	delayed_call(delay, func)
	delayed_call(entity, delay, func)
	delayed_call(group_key, delay, func)
	delayed_call(group_key, entity, delay, func)
	Function params:
	"func" - function that accepts zero arguments
	"delay" - delay in seconds
	"entity" (optional) - instance of CBaseEntity class; if entity becomes invalid, function will not be called
	"group_key" (optional) - any string, see below
	Function does not fully check argument types, so be careful. Function returns a string key, that can be used in remove_delayed_call(key). Group key may be used to remove multiple delayed calls at once: remove_delayed_call_group(group_key)
	Delay behaviour:
	delay == 0: function always runs THIS tick, runs immediately even if game is paused
	delay <= 0.0333: function always runs THIS tick, immediately after game is unpaused; nested delayed calls even with non-zero delay will be executed not earlier than next tick
	delay >= 0.0334: function always runs NEXT tick or later
	These numbers are bound to tickrate. This behaviour probably do not depend on server performance (even when you run heavy script every tick, tickrate remains 30). But i'm not sure of that.
	Execution scope: when delayed_call() is being called, it binds function to "this" scope (this action saves weakref to "this"). So if "entity" param is specified, this entity will NOT be accessible as "self" from the function unless you bind the function to the entity scope. Also you can manually delegate entity scope to "this" and bind function to entity scope, if you are crazy, so "self" and all variables from "this" will be accessible.
	Round transition behaviour: all delayed calls are removed between rounds because they are stored in table DirectorScript that is cleared between rounds, this is intended behaviour.
	Example: delayed_call( 0.5, ReloadMOTD ) //ReloadMOTD() will be called after 0.5 seconds
	Example: delayed_call( 0.5, function(){ log("hello!") } ) //function prints "hello!" after 0.5 seconds
	Example: delayed_call( 0.5, @()log("hello!") ) //the same as previous
	Example: local a = 5; delayed_call( 0.5, @()log(a) ) //local variables are accessible from function
	Example: delayed_call( hunter, 0.5, @()hunter.Kill() ) //removes hunter after 0.5 seconds if it still exists
	Example: delayed_call( "training", hunter, 0.5, @()hunter.Kill() ) //the same as previous, but group key was specified
remove_delayed_call(key)
	Removes delayed call using a key that is returned from delayed_call(). If given delayed call has alreaddy been called, does nothing.
remove_delayed_call_group(group_key)
	Removes multiple delayed calls by their group key. Useful when you want to finish some complex script, where all delayed calls were registered using the same group key.
run_this_tick(...)
	Calls function in this tick (game frame), immediately even if game is paused. Same as calling delayed_call() with zero delay. Params and behaviour are the same as in delayed_call(). Usage:
	run_this_tick(function)
	run_this_tick(entity, function)
	run_this_tick(group_key, func)
	run_this_tick(group_key, entity, func)
run_next_tick(...)
	Calls function in next tick (game frame). Params and behaviour are the same as in delayed_call(). Usage:
	run_next_tick(function)
	run_next_tick(entity, function)
	run_next_tick(group_key, func)
	run_next_tick(group_key, entity, func)
------------------------------------
clock.sec()
	Returns engine time in seconds. Same as Time(). Time stops if game is paused and is affected by host_timescale.
clock.msec()
	Returns engine time * 1000.
clock.frames()
	Returns frame count (tied to FPS). Same as GetFrameCount().
clock.ticks()
	Returns tick count. Tick counter needs to be initialized first. It can be done by registering any ticker or loop or running clock.tick_counter_init().
clock.tick_counter_init()
	Initializes tick counter.
clock.tick_time
	Time between this and last tick (1.0 / tickrate), usually 0.03333. It is always 0.0333 for first tick after clock initializing.
------------------------------------
register_loop(...)
register_ticker(...)
	Loop is a function that will be called cyclically with specified delay between calls. Ticker is a function that is called every tick (a loop with zero delay). The function will NOT be called more than once every tick, even if you set delay to 0.001 or -1. Usage:
	register_loop(delay, func)
	register_loop(key, delay, func)
	register_loop(ent, delay, func)
	register_loop(key, ent, delay, func)
	register_ticker(func) //same as register_loop(0, func)
	register_ticker(key, func) //same as register_loop(key, 0, func)
	register_ticker(ent, func)
	register_ticker(key, ent, func)
	Function params:
	"func" - function that accepts zero arguments. First loop function call will be performed as soon as possible, in this tick. If func returns false (exactly false, not null), loop or ticker will be removed.
	"delay" (for loops) - delay between calls in seconds
	"key" (optional) - key that can be used to remove this loop or ticker in future. Try to choose a unique key. Calling register_loop() or register_ticker() twice with the same key will override function, and also will override a delay and reset elspsed time for loops. Note that ticker cannot have the same key as loop, or one of them will override the other.
	"ent" - if this entity becomes invalid, loop or ticker will be removed
	Function does not fully check argument types, so be careful.
	Execution scope: when register_loop() or register_ticker() is being called, it binds function to "this" scope (this action saves weakref to "this").
	Round transition behaviour: all tickers and loops calls are performed by logic_timer entity, which is created while first loop or ticker is registered. If this entity gets removed, all registered tickers and loops are removed (list of them is stored inside logic_timer's scope, this table is erased from memory). So all tickers and loops are removed between rounds.
	Exception handling: if ticker or loop throws an exception, stack trace will appear in console, but this will not prevent other tickers and loops from running.
	Warning: do not use IncludeScript in tickers and loops, this may crash the game
	Table ::loop_info contains some information about the current loop (use it only from loop or ticker function!):
	loop_info.start_time: time when current loop was registered
	loop_info.delta_time: delay between this and previous calls; this key is NAN at first call. See also: clock.tick_time.
	loop_info.total_calls: total function calls (1 for first call, 2 for next, ...)
	loop_info.first_call: is it a first call after loop was registered? (same as loop_info.total_calls == 1)
	Table loop_info is read-only: it is filled right before function call and is not read back, so changes in it have no effect.
	Example: register_ticker( "test", function(){ log("Server time is", Time()) } ) //will print server time every tick
	Example: register_loop( 1, function(){ if(player().IsDying()) return false; log("player is alive") } ) //will print "player is alive" every second until player dies, then will stop printing anything forever (requires lib/module_entities)
	Example: register_ticker( "myticker", @()logt(loop_info) ) //will print all information about current loop from loop_info every tick
remove_ticker(key)
	Removes ticker using it's key. It will not be called anymore until registered again.
remove_loop(key)
	Removes loop using it's key. Tickers and loops use shared set of keys, so it's absolutely the same as remove_ticker(key).
loop_get_next_call_time(key)
	Returns a time when loop will be called. If next delay was explicitely set by loop_run_after(), returns time specified in loop_run_after(), otherwise returns next sheduled call.
loop_run_after(key, delay)
	Sets a delay before next loop call. Current loop or ticker will be called next time after "delay" seconds.
	Example: loop_run_after("my_ticker", 1) //ticker will be paused for 1 second and then again will be called every tick.
loop_get_delay(key)
	Returns delay of a loop.
loop_set_delay(key, delay)
	Sets delay for a loop. Loop will be called next time when "delay" seconds passed from last call (before first call last call time is -INF).
loop_exists(key)
	Returns true if loop exists.
loop_pause(key)
	Pauses a loop.
loop_resume(key)
	Resumes a loop from the same time.
------------------------------------
register_callback(...)
	Registering a function that will be called on specified game event. Usage:
	register_callback(event, func)
	register_callback(key, event, func)
	register_callback(entity, event, func)
	register_callback(key, entity, event, func)
	Function params:
	"func" - function that accepts one argument: table with event parameters
	"event" - name of event, see "Source events", "Left 4 Dead 2 events"
	"entity" (optional) - instance of CBaseEntity class; if entity becomes invalid, callback not be called
	"key" (optional) - any string that can be used used to identify callback in callbacks list or remove it. Key should be unique within the event.
	If function returns false (exactly false, not null), callback will be removed.
	Function does not fully check argument types for performance reasons, so be careful.
	Execution scope: when register_callback() is being called, it binds function to "this" scope, like tickers and loops do.
	Exception handling: if callback throws an exception, stack trace will appear in console, but this will not prevent other callbacks for same event from running.
	Warning: do not use IncludeScript in callbacks, this may crash the game
remove_callback(key, event)
	Removes a callback.
callback_exists(key, event)
	Returns true if callback exists.
------------------------------------
clock.evaluate_tickrate.start()
	Starts counting ticks.
clock.evaluate_tickrate.stop()
	Stops counting ticks and returns tickrate.
clock.evaluate_framerate.start()
	Starts counting frames.
clock.evaluate_framerate.stop()
	Stops counting frames and returns framerate. Game should not be paused for correct results.
------------------------------------
add_task_on_shutdown(key, func, after_all = false)
	Register a function that will be called on server shutdown. Pass true as last parameter to run this after all others. This function for technical reasons silently enables developer mode and restores it back on server shutdown.
	Execution scope: when add_task_on_shutdown() is being called, it binds function to "this" scope.
remove_task_on_shutdown(key)
	Removes task on shutdown.
------------------------------------
on_player_team(team, is_bot, func)
	Register a callback for player_team event that will fire for specified team and params.is_bot condition. This is not chained! Pass null to cancel. Parameter "team" should be one of (Teams.UNASSIGNED, Teams.SPECTATORS, Teams.SURVIVORS, Teams.INFECTED). Parameter "is_bot" should be one of (ClientType.ANY, ClientType.HUMAN, ClientType.BOT).
remove_on_player_team()
	Removes all functions registered with on_player_team().
------------------------------------
on_key_action(key, player|team, keyboard_key, delay, on_pressed, on_released = null, on_hold = null)
	Register listener(s) for key press/hold/release events. Function "on_pressed" is called when player presses specified keyboard_key and gets player as parameter. Function "on_released" is called when player releases specified keyboard_key and gets player as parameter. Function "on_hold" is called together with "on_pressed" and later until players releases specified key, this function also gets player as parameter. Delay is a delay in seconds between checks (0 = every tick). Key is not a keyboard key but an identifier that can be used for on_key_action_remove() later. Second param may be player entity or the whole team (Teams.UNASSIGNED, Teams.SPECTATORS, Teams.SURVIVORS, Teams.INFECTED).
	Example: on_key_action("my", Teams.SURVIVORS, IN_ATTACK, 0.1, @(player)player.ApplyAbsVelocityImpulse(Vector(0,0,300)), null)
	Result: any survivor will be pushed upwards when press primary attack key. Check is performed every 0.1 second.
	Example: on_key_action("my", player(), IN_ALT1, 0, @(p)propint(p,"movetype",8), @(p)propint(p,"movetype",2))
	Result: player (see lib/base for player() function) will enter noclip mode when press alt button and will return to normal walk when releases alt button.
on_key_action_remove(key)
	Remove key action registered with on_key_action.
------------------------------------
register_chat_command(name, func, min = null, max = null, msg = null)
	Registers a chat command (under the hood makes a callback for event player_say). Name can be string or array of strings (this means same handler for different commands). For example, name "testcmd" means that player types !testcmd or /testcmd in chat (both will work). Func should have 4 parameters:
		player - player who issued command
		command - what command was called (without ! or /)
		args_text - all arguments as string
		args - all arguments as array (arguments are either enclosed in quotes or divided by spaces)
	Example used input: !testcmd a b " c d"
	Corresponding function call: func(player, "testcmd", "a b \" c d\"", ["a", "b", " c d"])
	User input cannot have nested quotes (\"). Commands may include unicode and are case-insensitive (only for english and russian letters). You can pass up to three optional params to register_chat_command: min - minimum number of arguments allowed (or null), max - maximum number of arguments allowed (or null), msg - message to print when arglen < min or arglen > max.
remove_chat_command(names)
	Remove chat command registered with register_chat_command given name or array of names.
print_all_chat_commands()
	Prints all chat commands registered with register_chat_command to console.
 */

//---------- CODE ----------

this = ::root

log("[lib] including module_tasks")

_def_func("__dc_check", function() {
	local time = Time()
	if (!("DirectorScript" in root) || !("__delayed_calls" in DirectorScript)) return
	foreach (key, table in DirectorScript.__delayed_calls) {
		if (table.time <= time) {
			delete DirectorScript.__delayed_calls[key]
			if (table.ent != null && invalid(table.ent)) return
			table.func.call(table.scope)
		}
	}
})

_def_func("delayed_call", function(...) {
	if (!("DirectorScript" in root)) return
	if (!("__delayed_calls" in DirectorScript)) DirectorScript.__delayed_calls <- {}
	//we need to put delayed calls table in some scope that is getting cleared between rounds, because delayed calls should be removed between rounds
	local func, delay, ent = null, group_key = null
	switch (vargv.len()) {
		case 2:
			delay = vargv[0]
			func = vargv[1]
			break
		case 3:
			if (typeof vargv[0] == "string") group_key = vargv[0]
			else if (typeof vargv[0] == "instance") ent = vargv[0]
			delay = vargv[1]
			func = vargv[2]
			break
		case 4:
			group_key = vargv[0]
			ent = vargv[1]
			delay = vargv[2]
			func = vargv[3]
			break
	}
	local key = UniqueString()
	DirectorScript.__delayed_calls[key] <- {
		func = func
		scope = this.weakref()
		group_key = group_key
		ent = ent
		time = Time() + delay
	}
	ent_fire(worldspawn, "CallScriptFunction", "__dc_check", delay)
})

_def_func("run_this_tick", function(...) {
	local func, ent = null, group_key = null
	switch (vargv.len()) {
		case 1:
			func = vargv[0]
			break
		case 2:
			if (typeof vargv[0] == "string") group_key = vargv[0]
			else if (typeof vargv[0] == "instance") ent = vargv[0]
			func = vargv[1]
			break
		case 3:
			group_key = vargv[0]
			ent = vargv[1]
			func = vargv[2]
			break
	}
	delayed_call(group_key, ent, 0, func)
})

_def_func("run_next_tick", function(...) {
	local func, ent = null, group_key = null
	switch (vargv.len()) {
		case 1:
			func = vargv[0]
			break
		case 2:
			if (typeof vargv[0] == "string") group_key = vargv[0]
			else if (typeof vargv[0] == "instance") ent = vargv[0]
			func = vargv[1]
			break
		case 3:
			group_key = vargv[0]
			ent = vargv[1]
			func = vargv[2]
			break
	}
	delayed_call(group_key, ent, 0.001, function() {
		delayed_call(group_key, ent, 0.001, func)
	})
})

_def_func("remove_delayed_call", function (key) {
	if (!("DirectorScript" in root) || !("__delayed_calls" in DirectorScript)) return
	if (key in DirectorScript.__delayed_calls)
		delete DirectorScript.__delayed_calls[key]
})

_def_func("remove_delayed_call_group", function (group_key) {
	if (group_key == null) throw "group key is null"
	if (!("DirectorScript" in root) || !("__delayed_calls" in DirectorScript)) return
	local keys_to_delete = []
	foreach (key, table in DirectorScript.__delayed_calls) {
		if (table.group_key == group_key)
			keys_to_delete.append(key)
	}
	foreach (key in keys_to_delete)
		delete DirectorScript.__delayed_calls[key]
})

//----------------------------------

if (!("__clock_ent" in this)) {
	_def_var_nullable("__clock_ent", null, "instance")
	_def_var_nullable("__loops", null, "table")
}

//performs logic_timer initializing if not initialized yet
_def_func("__clock_init", function() {
	if (__clock_ent) return
	if (clock.__ticks == -1) clock.__ticks = 0
	clock.__last_tick_time = NAN
	local __clock = SpawnEntityFromTable("logic_timer", { RefireTime = 0 })
	__clock.ConnectOutput("OnTimer", "func")
	scope(__clock).loops <- {}
	scope(__clock).func <- function() {
		clock.__ticks++
		local time = Time()
		if (clock.__last_tick_time != NAN) clock.tick_time = time - clock.__last_tick_time
		clock.__last_tick_time = time
		foreach(key, loop_table in loops) {
			local next_call = loop_table.last_call + loop_table.delay
			local next_call_override = loop_table.next_call_time_override
			local delta = time - loop_table.last_call
			if (
				(next_call_override && time >= next_call_override)
				|| (!next_call_override && time >= next_call)
			) {
				loop_table.last_call = time
				loop_table.last_delta = delta
				loop_table.total_calls++
				if (next_call_override) loop_table.next_call_time_override = null
				if (loop_table.ent != null && invalid(loop_table.ent)) {
					delete loops[key]
					continue
				}
				loop_info.start_time = loop_table.start_time
				if (loop_table.last_delta != INF) {
					loop_info.delta_time = loop_table.last_delta
				} else {
					loop_info.delta_time = NAN
				}
				loop_info.total_calls = loop_table.total_calls
				loop_info.first_call = (loop_table.total_calls == 1)
				try {
					//we need to see callstack of possible exception
					//but this should not prevent execution of other loops
					loop_table.thread.call()
				} catch (e) {}
			}
		}
	}
	__clock_ent = __clock.weakref()
	__loops = scope(__clock).loops.weakref()
})

_def_func("register_ticker", function(...) {
	local func, key, ent = null
	switch (vargv.len()) {
		case 1:
			func = vargv[0]
			break
		case 2:
			if (typeof vargv[0] == "instance") ent = vargv[0]
			else key = vargv[0]
			func = vargv[1]
			break
		case 3:
			key = vargv[0]
			ent = vargv[1]
			func = vargv[2]
			break
	}
	__register_loop_internal(key, ent, 0, func)
})

_def_func("register_loop", function(...) {
	local func, delay, key, ent = null
	switch (vargv.len()) {
		case 2:
			delay = vargv[0]
			func = vargv[1]
			break
		case 3:
			if (typeof vargv[0] == "instance") ent = vargv[0]
			else key = vargv[0]
			delay = vargv[1]
			func = vargv[2]
			break
		case 4:
			key = vargv[0]
			ent = vargv[1]
			delay = vargv[2]
			func = vargv[3]
			break
	}
	__register_loop_internal(key, ent, delay, func)
})

//fixed arguments
_def_func("__register_loop_internal", function(key, ent, delay, func) {
	if (!key) key = UniqueString()
	__clock_init()
	local scope = this.weakref()
	__loops[key] <- {
		thread = newthread( function() {
			if (func.call(scope) == false) delete __loops[key]
		})
		ent = ent
		delay = delay
		last_call = -INF
		start_time = Time()
		total_calls = 0
		last_delta = 0
		next_call_time_override = null
	}
})

_def_var("loop_info", {})
_def_var_nullable("loop_info.start_time", null, "float") //time when current loop started
_def_var_nullable("loop_info.delta_time", null, "float")	//time elapsed since last function call
_def_var_nullable("loop_info.total_calls", null, "integer")	//total calls (1 for first call)
_def_var_nullable("loop_info.first_call", null, "bool")	//equivalent to "loop_info.ticks == 0"

_def_func("remove_ticker", function(key) {
	if(key in __loops)
		delete __loops[key]
})

_def_func("remove_loop", remove_ticker)

_def_func("loop_run_after", function(key, delay) {
	if(!(key in __loops)) throw "no loop for given key"
	__loops[key].next_call_time_override = Time() + delay
})

_def_func("loop_get_next_call_time", function(key) {
	if(!(key in __loops)) throw "no loop for given key"
	local loop_table = __loops[key]
	local next_call = loop_table.last_call + loop_table.delay
	local next_call_override = loop_table.next_call_time_override
	if (next_call_override)
		return next_call_override
	return next_call
})

_def_func("loop_get_delay", function(key) {
	if(!(key in __loops)) throw "no loop for given key"
	return __loops[key].delay
})

_def_func("loop_set_delay", function(key, delay) {
	if(!(key in __loops)) throw "no loop for given key"
	__loops[key].delay = delay
})

_def_func("loop_exists", function(key) {
	if (!__loops) return false
	return (key in __loops)
})

_def_func("loop_pause", function(key) {
	if(!(key in __loops)) throw "no loop for given key"
	local loop_table = __loops[key]
	loop_table.next_call_time_override = INF
	loop_table.saved_delay <- loop_get_next_call_time(key)
})

_def_func("loop_resume", function(key) {
	if(!(key in __loops)) throw "no loop for given key"
	local loop_table = __loops[key]
	if (!("saved_delay" in loop_table)) throw "loop was not paused, cannot resume"
	loop_table.next_call_time_override = Time() + loop_table.saved_delay
	delete loop_table.saved_delay
})

//----------------------------------

_def_func("register_callback", function(...) {
	if (!("DirectorScript" in root)) throw "No DirectorScript! Cannot run register_callback()"
	if (!("__callbacks" in DirectorScript)) DirectorScript.__callbacks <- {}
	if (!("__callbackFuncs" in DirectorScript)) DirectorScript.__callbackFuncs <- {}
	//we need to put callbacks table in some scope that is getting cleared between rounds, because callbacks should be removed between rounds
	local func, event, ent = null, key = null
	switch (vargv.len()) {
		case 2:
			event = vargv[0]
			func = vargv[1]
			break
		case 3:
			if (typeof vargv[0] == "string") key = vargv[0]
			else if (typeof vargv[0] == "instance") ent = vargv[0]
			event = vargv[1]
			func = vargv[2]
			break
		case 4:
			key = vargv[0]
			ent = vargv[1]
			event = vargv[2]
			func = vargv[3]
			break
	}
	if (key == null) key = UniqueString()
	if (!(event in DirectorScript.__callbacks)) {
		DirectorScript.__callbacks[event] <- {}
		DirectorScript.__callbackFuncs["OnGameEvent_" + event] <- function(params) {
			local callback_tables = DirectorScript.__callbacks[event]
			if (callback_tables.len() == 0) return
			if ("userid" in params)
				params.player <- GetPlayerFromUserID(params.userid)
			if ("victim" in params)
				params.player_victim <- GetPlayerFromUserID(params.victim)
			if ("attacker" in params)
				params.player_attacker <- GetPlayerFromUserID(params.attacker)
			foreach(key, callback_table in callback_tables) {
				if (callback_table.ent != null && invalid(callback_table.ent)) {
					logf("[lib] removing callback %s.%s because entity is not valid", event, key.tostring())
					delete DirectorScript.__callbacks[event][key]
					continue
				}
				try {
					callback_table.thread.call(clone params)
				} catch (e) {}
			}
		}
		//see: https://github.com/sedol1339/l4d2/blob/master/squirrel/defaults.nut
		__CollectEventCallbacks(DirectorScript.__callbackFuncs,
			"OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener)
	}
	local scope = this.weakref()
	DirectorScript.__callbacks[event][key] <- {
		ent = ent
		thread = newthread( function(params) {
			if (func.call(scope, params) == false) delete DirectorScript.__callbacks[event][key]
		})
	}
})

_def_func("remove_callback", function(key, event) {
	if (!("DirectorScript" in root)) return
	if (!("__callbacks" in DirectorScript)) return
	if (!(event in DirectorScript.__callbacks)) return
	local event_table = DirectorScript.__callbacks[event]
	if (!(key in event_table)) return
	delete event_table[key]
})

_def_func("callback_exists", function(key, event) {
	if (!("DirectorScript" in root)) return false
	if (!("__callbacks" in DirectorScript)) return false
	if (!(event in DirectorScript.__callbacks)) return false
	local event_table = DirectorScript.__callbacks[event]
	return (key in event_table)
})

//----------------------------------

if (!("clock" in this)) _def_constvar("clock", {})
	
_def_func("clock.sec", Time)

_def_func("clock.msec", @() Time() * 1000)

_def_func("clock.frames", GetFrameCount)

_def_var("clock.__ticks", -1)

_def_var("clock.__last_tick_time", NAN)

_def_var("clock.tick_time", 1.0 / 30)

_def_func("clock.ticks", function() {
	if (__ticks == -1) throw "use clock.tick_counter_init() first"
	return __ticks
})

_def_func("clock.tick_counter_init", function() {
	__clock_init()
})

_def_var("clock.evaluate_tickrate", {})

_def_func("clock.evaluate_tickrate.start", function() {
	clock.evaluate_tickrate.start_sec <- clock.sec();
	clock.evaluate_tickrate.start_ticks <- clock.ticks();
})

_def_func("clock.evaluate_tickrate.finish", function() { 
	if (!("start_sec" in clock.evaluate_tickrate)) throw "clock.evaluate_tickrate: finish without start";
	if (clock.sec() == clock.evaluate_tickrate.start_sec) throw "zero time elapsed (game was paused?)";
	return (clock.ticks() - clock.evaluate_tickrate.start_ticks) / (clock.sec() - clock.evaluate_tickrate.start_sec);
})

_def_var("clock.evaluate_framerate", {})

_def_func("clock.evaluate_framerate.start", function() {
	clock.evaluate_framerate.start_sec <- clock.sec();
	clock.evaluate_framerate.start_frames <- clock.frames();
})

_def_func("clock.evaluate_framerate.finish", function() { 
	if (!("start_sec" in clock.evaluate_framerate)) throw "clock.evaluate_framerate: finish without start";
	if (clock.sec() == clock.evaluate_framerate.start_sec) throw "zero time elapsed (game was paused?)";
	return (clock.frames() - clock.evaluate_framerate.start_frames) / (clock.sec() - clock.evaluate_framerate.start_sec);
})

//----------------------------------

_def_func("add_task_on_shutdown", function(key, func, after_all = false) {
	local scope = this
	this = root
	if (!key) key = UniqueString()
	if (!("__on_shutdown" in this)) {
		__on_shutdown <- {}
		__on_shutdown_after_all <- {}
		
		//making circular reference
		::__circ<-{}; __circ.ref<-::__circ
		::__circ<-{}; __circ.ref<-::__circ
		
		//this function will be called on shutdown if developer cvar is on
		FindCircularReferences <- function(...) {
			if ("__on_shutdown_reset_dev" in this) {
				Convars.SetValue("developer", 0)
				Convars.SetValue("contimes", 8)
			}
			log("[lib] running tasks on shutdown...")
			local arr = []
			foreach(key, func in __on_shutdown) arr.append([key, func])
			foreach(key, func in __on_shutdown_after_all) arr.append([key, func])
			foreach(key_and_func in arr) {
				try {
					key_and_func[1]()
				} catch (exception) {
					logf("[lib] ERROR! Exception in task on shutdown %s: %s", key_and_func[0].tostring(), exception)
				}
			}
		}.bindenv(this)
		
		//enabling developer mode
		if (Convars.GetStr("developer") == "0") {
			::__on_shutdown_reset_dev <- true
			Convars.SetValue("developer", 1)
			Convars.SetValue("contimes", 0)
		}
		log("[lib] add_task_on_shutdown(): new task on shutdown registered");
	}
	
	if (!after_all) {
		__on_shutdown[key] <- func.bindenv(scope)
		if (key in __on_shutdown_after_all) delete __on_shutdown_after_all[key]
	} else {
		__on_shutdown_after_all[key] <- func.bindenv(scope)
		if (key in __on_shutdown) delete __on_shutdown[key]
	}
})

_def_func("remove_task_on_shutdown", function(key) {
	if (!("__on_shutdown" in root)) return
	if (key in __on_shutdown) delete __on_shutdown[key]
	if (key in __on_shutdown_after_all) delete __on_shutdown_after_all[key]
})

reporter("Tasks", function() {
	log("\tClock initialized: " + (__clock_ent ? "true" : "false"))
	if (__clock_ent) {
		log("\tTickers and loops:")
		foreach(key, loop in __loops) {
			logf(
				"\t\t%s [delay = %g%s%s]",
				key.tostring(), loop.delay,
				loop.ent ? format(", ent = %s", var_to_str(loop.ent)) : "",
				loop.next_call_time_override ? format(", next call override = %g", next_call_time_override) : ""
			)
		}
	}
	log("\tCallbacks:")
	if ("__callbacks" in DirectorScript) {
		foreach(event, callbacks in DirectorScript.__callbacks) {
			local listeners = []
			foreach(key, callback in callbacks)
				listeners.push(key.tostring())
			if (listeners.len() != 0)
				log("\t\t" + event + ": " + (listeners.len() > 0 ? concat(listeners, ", ") : "[none]"))
		}
	}
	log("\tDelayed calls:")
	if ("__delayed_calls" in DirectorScript) {
		logf("\t\t<current time: %g>", Time())
		foreach(key, delayed_call in DirectorScript.__delayed_calls) {
			logf(
				"\t\t%s [key = %s, time = %g%s%s]",
				var_to_str(delayed_call.func),
				key.tostring(),
				delayed_call.time,
				(delayed_call.ent ? format(", ent = %s", var_to_str(delayed_call.ent)) : ""),
				(delayed_call.group_key ? format(", group_key = %g", delayed_call.group_key) : "")
			)
		}
	}
	log("\tTasks on shutdown:")
	if ("__on_shutdown" in root) {
		foreach(key, task in __on_shutdown)
			logf("\t\t%s: %s", key.tostring(), var_to_str(task))
		foreach(key, task in __on_shutdown_after_all)
			logf("\t\t%s: %s", key.tostring(), var_to_str(task))
	}
})

//uses Teams and ClientType tables from lib/base

_def_func("on_player_team", function(teams, isbot, func) {
	if (!__on_player_team) {
		DirectorScript.__on_player_team <- [
			[null, null], //Teams.UNASSIGNED
			[null, null], //Teams.SPECTATORS
			[null, null], //Teams.SURVIVORS
			[null, null], //Teams.INFECTED
		]
		__on_player_team = DirectorScript.__on_player_team.weakref()
	}
	//it's ok to be registered multiple times
	register_callback("__on_player_team", "player_team", function(params) {
		local func = __on_player_team[params.team][params.isbot ? 1 : 0];
		if (func) func(params)
	});
	if (teams == Teams.ANY && isbot == ClientType.ANY) throw "specify team ot playertype for on_player_connect";
	for(local i = 0; i <= 3; i++)
		if (teams & (1 << i)) {
			if (isbot == ClientType.ANY || !isbot)
				__on_player_team[i][0] = func
			if (isbot == ClientType.ANY || isbot)
				__on_player_team[i][1] = func
		}
})

_def_func("remove_on_player_team", function() {
	remove_callback("__on_player_team", "player_team");
	for (local team = 0; team <= 3; team++)
		for (local isbot = 0; isbot <= 1; isbot++)
			__on_player_team[team][isbot] = null;
})

if (!("__on_player_team" in this)) {
	_def_var_nullable("__on_player_team", null, "array")
}

reporter("on_player_team listeners", function() {
	if (!__on_player_team) {
		logf("\tNone")
		return
	}
	local t = __on_player_team
	if (t[0][0] || t[0][1])
		logf("\tTeams.UNASSIGNED & HUMAN: %s, \n\tTeams.UNASSIGNED & BOT: %s", var_to_str(t[0][0]), var_to_str(t[0][1]))
	if (t[1][0] || t[1][1])
		logf("\tTeams.SPECTATORS & HUMAN: %s, \n\tTeams.SPECTATORS & BOT: %s", var_to_str(t[1][0]), var_to_str(t[1][1]))
	if (t[2][0] || t[2][1])
		logf("\tTeams.SURVIVORS & HUMAN: %s, \n\tTeams.SURVIVORS & BOT: %s", var_to_str(t[2][0]), var_to_str(t[2][1]))
	if (t[3][0] || t[3][1])
		logf("\tTeams.SURVIVORS & HUMAN: %s, \n\tTeams.SURVIVORS & BOT: %s", var_to_str(t[3][0]), var_to_str(t[3][1]))
})

_def_func("on_key_action", function(
	key,
	player_or_team,
	keyboard_key,
	delay,
	on_pressed,
	on_released = null,
	on_hold = null
) {
	if (!key) key = UniqueString()
	if (!on_pressed) on_pressed = __dummy
	if (!on_released) on_released = __dummy
	if (!on_hold) on_hold = __dummy
	local player = null
	local team = null
	if (type(player_or_team) == "integer") {
		team = player_or_team
	} else {
		player = player_or_team
	}
	register_loop("__key_action_" + key, delay, function() {
		local function do_key_check(player) {
			local player_scope = scope(player)
			local name_in_scope = "__last_buttons_" + key
			local key_pressed = (propint(player, "m_nButtons") & keyboard_key) ? true : false
			if (name_in_scope in player_scope) {
				local last_key_state = player_scope[name_in_scope]
				if (last_key_state && !key_pressed)
					on_released(player)
				else if (!last_key_state && key_pressed)
					on_pressed(player)
				if (key_pressed)
					on_hold(player)
			}
			player_scope[name_in_scope] <- key_pressed
		}
		if (player) {
			do_key_check(player)
		} else {
			for_each_player( function(player) {
				if (get_team(player) & team)
					do_key_check(player)
			})
		}
	})
})

_def_func("on_key_action_remove", function(key) {
	remove_loop("__key_action_" + key)
	for_each_player( function(player) {
		player.ValidateScriptScope()
		local player_scope = player.GetScriptScope()
		local name_in_scope = "__last_buttons_" + key
		if (name_in_scope in player_scope)
			delete player_scope[name_in_scope]
	})
})

if (!("__chat_cmds" in this)) _def_var_nullable("__chat_cmds", null, "table")

_def_func("register_chat_command", function(names, func, argmin = null, argmax = null, errmsg = null) {
	if (!__chat_cmds) {
		DirectorScript.__chat_cmds <- {}
		__chat_cmds = DirectorScript.__chat_cmds.weakref()
	}
	if (type(names) == "string") {
		names = [names]
	} else if (type(names) != "array") {
		throw "name should be string or array of strings"
	}
	foreach (name in names) {
		if (names.find(" ") != null) throw "chat command name cannot contain spaces"
		name = tolower(name)
		local cmd = "cmd_" + name
		if (cmd in __chat_cmds)
			logf("[lib] WARNING! chat command %s was already registered, overriding...", name)
		__chat_cmds[cmd] <- {
			func = func.bindenv(this),
			argmin = argmin,
			argmax = argmax,
			errmsg = errmsg
		}
	}
	register_callback("__chat_cmds", "player_say", function(params) {
		local cmd_markers = ["!", "/"]
		local text = lstrip(params.text)
		local is_command = false
		foreach(marker in cmd_markers)
			if (text.len() >= marker.len() && text.slice(0, marker.len()) == marker) {
				text = text.slice(marker.len())
				is_command = true
				break
			}
		if (!is_command) return
		local space_pos = text.find(" ")
		local command = tolower(space_pos ? text.slice(0, space_pos) : text)
		if (!("cmd_" + command in __chat_cmds)) return
		logf("[lib] parsing args for chat command %s from player %s", command, player_to_str(params.player))
		local initial_args_text = ""
		local args = []
		if (space_pos) {
			initial_args_text = text.slice(space_pos + 1)
			local args_text = initial_args_text
			//now we start parsing arguments
			while(true) {
				args_text = lstrip(args_text)
				if (args_text.len() == 0) break
				if (args_text[0].tochar() == "\"") {
					//quotes are started
					local end_quote_pos = -1
					local next_quote_pos = 0
					while(true) {
						next_quote_pos = args_text.find("\"", next_quote_pos + 1)
						if (next_quote_pos == null) break
						if (next_quote_pos == args_text.len() - 1 || args_text[next_quote_pos + 1].tochar() == " ") {
							end_quote_pos = next_quote_pos
							break
						}
					}
					if (end_quote_pos == -1) {
						//quotes are not closed
						local next_space = args_text.find(" ", 1)
						if (next_space == null) next_space = args_text.len()
						local arg = args_text.slice(0, next_space)
						args.push(arg)
						args_text = args_text.slice(next_space)
					} else {
						//quotes are closed
						local arg = args_text.slice(0, end_quote_pos + 1)
						//removing quotes
						arg = arg.slice(1, arg.len() - 1)
						args.push(arg)
						args_text = args_text.slice(end_quote_pos + 1)
					}
				} else {
					//no quotes
					local next_space = args_text.find(" ", 1)
						if (next_space == null) next_space = args_text.len()
					local arg = args_text.slice(0, next_space)
					args.push(arg)
					args_text = args_text.slice(next_space)
				}
			}
		}
		local cmd_table = __chat_cmds["cmd_" + command]
		local argmin = cmd_table.argmin
		local argmax = cmd_table.argmax
		local errmsg = cmd_table.errmsg
		if (argmin != null && argmin != 0 && argmin == argmax && args.len() != argmin) {
			say_chat(errmsg ? errmsg : format("This command requires %s arguments", argmin))
		} else if (argmin != null && args.len() < argmin) {
			say_chat(errmsg ? errmsg : format("This command requires at least %s %s", argmin, argmin > 1 ? "arguments" : "argument"))
		} else if (argmax != null && args.len() > argmax) {
			if (argmax != 0) {
				say_chat(errmsg ? errmsg : format("This command accepts no more than %s %s", argmax, argmax > 1 ? "arguments" : "argument"))
			} else {
				say_chat(errmsg ? errmsg : "This command does not accept arguments")
			}
		} else {
			cmd_table.func(params.player, command, initial_args_text, args)
		}
	})
})

_def_func("remove_chat_command", function(names) {
	if (type(names) == "string") {
		names = [names]
	} else if (type(names) != "array") {
		throw "name should be string or array of strings"
	}
	foreach (name in names) {
		name = "cmd_" + tolower(name)
		if (!(name in __chat_cmds))
			logf("[lib] WARNING! chat command %s was not registered", name)
		else
			delete __chat_cmds[name]
	}
})

_def_func("print_all_chat_commands", function() {
	log("[lib] all chat commands registered with register_chat_command")
	if (__chat_cmds) {
		logt(__chat_cmds)
	} else {
		log("\tNone")
	}
})

reporter("Chat commands", function() {
	local cmds = []
	if (!__chat_cmds || __chat_cmds.len() == 0) {
		log("\tNone")
		return
	}
	foreach(cmd, table in __chat_cmds) {
		cmds.append(cmd.slice(4, cmd.len()))
	}
	log("\t" + concat(cmds, ", "))
})