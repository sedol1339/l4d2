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
	Returns engine time in seconds. Same as Time(). This time stops if game is paused and is affected by host_timescale.
clock.msec()
	Returns engine time * 1000.
clock.frames()
	Returns frame count (tied to FPS). Same as GetFrameCount().
clock.ticks()
	Returns tick count. Tick counter needs to be initialized first. It can be done by registering any ticker or loop or running clock.tick_counter_init().
clock.tick_counter_init()
	Initializes tick counter.
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
	Table ::loop_info contains some information about the current loop (use it only from loop or ticker function!):
	loop_info.start_time: time when current loop was registered
	loop_info.delta_time: time delta between this and previous calls (around 0.033 for tickers); this key does NOT exist at first call.
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
	Exception handling: if callback throws an exception, this will not prevent other callbacks from running, but stack trace will not appear in console, only exception title will be printed.
remove_callback(key, event)
	Removes a callback.
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
 */

//---------- CODE ----------

this = ::root

log("[lib] including module_tasks")

__dc_check <- function() {
	local time = Time()
	foreach (key, table in DirectorScript.__delayed_calls) {
		if (table.time <= time) {
			delete DirectorScript.__delayed_calls[key]
			if (table.ent != null && invalid(table.ent)) return
			table.func() //function is binded to some scope
		}
	}
}

delayed_call <- function(...) {
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
		func = func.bindenv(this)
		group_key = group_key
		ent = ent
		time = Time() + delay
	}
	ent_fire(worldspawn, "CallScriptFunction", "__dc_check", delay)
}

run_this_tick <- function(...) {
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
}

run_next_tick <- function(...) {
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
}

remove_delayed_call <- function (key) {
	if (!("__delayed_calls" in DirectorScript)) return
	if (key in DirectorScript.__delayed_calls)
		delete DirectorScript.__delayed_calls[key]
}

remove_delayed_call_group <- function (group_key) {
	if (group_key == null) throw "group key is null"
	if (!("__delayed_calls" in DirectorScript)) return
	local keys_to_delete = []
	foreach (key, table in DirectorScript.__delayed_calls) {
		if (table.group_key == group_key)
			keys_to_delete.append(key)
	}
	foreach (key in keys_to_delete)
		delete DirectorScript.__delayed_calls[key]
}

//----------------------------------

if (!("__clock_ent" in this)) {
	__clock_ent <- null
	__loops <- null
}

//performs logic_timer initializing if not initialized yet
__clock_init <- function() {
	if (__clock_ent) return
	if (clock.__ticks == -1) clock.__ticks = 0
	local __clock = SpawnEntityFromTable("logic_timer", { RefireTime = 0 })
	__clock.ConnectOutput("OnTimer", "func")
	scope(__clock).loops <- {}
	scope(__clock).func <- function() {
		clock.__ticks++
		local time = Time()
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
				__call_this_tick(loop_table.func, key)
			}
		}
	}
	__clock_ent = __clock.weakref()
	__loops = scope(__clock).loops.weakref()
}

register_ticker <- function(...) {
	local func, key, ent = null
	switch (vargv.len()) {
		case 1:
			func = vargv[0]
			break
		case 2:
			if (typeof vargv[0] == "string") key = vargv[0]
			else if (typeof vargv[0] == "instance") ent = vargv[0]
			func = vargv[1]
			break
		case 3:
			key = vargv[0]
			ent = vargv[1]
			func = vargv[2]
			break
	}
	__register_loop_internal(key, ent, 0, func)
}

register_loop <- function(...) {
	local func, delay, key, ent = null
	switch (vargv.len()) {
		case 2:
			delay = vargv[0]
			func = vargv[1]
			break
		case 3:
			if (typeof vargv[0] == "string") key = vargv[0]
			else if (typeof vargv[0] == "instance") ent = vargv[0]
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
}

//fixed arguments
__register_loop_internal <- function(key, ent, delay, func) {
	if (!key) key = UniqueString()
	__clock_init()
	__loops[key] <- {
		func = func.bindenv(this)
		ent = ent
		delay = delay
		last_call = -INF
		start_time = Time()
		total_calls = 0
		last_delta = 0
		next_call_time_override = null
	}
}

remove_ticker <- function(key) {
	if(key in __loops)
		delete __loops[key]
}

remove_loop <- remove_ticker

/**
 * this function will execute func(...) with passed args
 * later in this tick; if func throws an exception,
 * callstack will be shown in console, but __call_this_tick
 * will never throw an exception
 * 
 * purpose:
 * we use __call_this_tick(func, key) instead of func() in tasks,
 * because we don't want this statement to throw an exception,
 * and also we want to see callstack if func throws exception
 *
 * key should be valid or function will not do anything
 */

__call_this_tick <- function(func, key) {
	__queue_func.push(func)
	__queue_keys.push(key)
	//DoEntFire("!self", "FireUser3", "", 0, null, worldspawn)
	ent_fire(worldspawn, "FireUser3")
}

__queue_func <- []
__queue_keys <- []

loop_info <- {
	start_time = null, //time when current loop started
	delta_time = null,	//time elapsed since last function call
	total_calls = null,	//total calls (1 for first call)
	first_call = null,	//equivalent to "loop_info.ticks == 0"
}

scope(worldspawn).InputFireUser3 <- function() {
	//takes and runs one function from queue
	if (__queue_func.len() > 0) {
		//add "__" because these variables should not override vars from function's "this"
		local func = __queue_func.remove(0)
		local key = __queue_keys.remove(0)
		if (!(key in __loops)) return //loop was removed
		local table = __loops[key]
		if (table.ent != null && invalid(table.ent)) {
			delete __loops[key]
			return
		}
		if (table.next_call_time_override != null) return
		loop_info.start_time = table.start_time
		if (table.last_delta != INF) {
			loop_info.delta_time = table.last_delta
		} else {
			loop_info.delta_time = NAN
		}
		loop_info.total_calls = table.total_calls
		loop_info.first_call = (table.total_calls == 1)
		local result = func()
		if (result == false) delete __loops[key]
	}
	return false
}

loop_run_after <- function(key, delay) {
	if(!(key in __loops)) throw "no loop for given key"
	__loops[key].next_call_time_override = Time() + delay
}

loop_get_next_call_time <- function(key) {
	if(!(key in __loops)) throw "no loop for given key"
	local loop_table = __loops[key]
	local next_call = loop_table.last_call + loop_table.delay
	local next_call_override = loop_table.next_call_time_override
	if (next_call_override)
		return next_call_override
	return next_call
}

loop_get_delay <- function(key) {
	if(!(key in __loops)) throw "no loop for given key"
	return __loops[key].delay
}

loop_set_delay <- function(key, delay) {
	if(!(key in __loops)) throw "no loop for given key"
	__loops[key].delay = delay
}

//----------------------------------

register_callback <- function(...) {
	if (!("__callbacks" in DirectorScript)) DirectorScript.__callbacks <- {}
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
	//don't touch something that is working
	if (!(event in DirectorScript.__callbacks)) {
		DirectorScript.__callbacks[event] <- {}
		local scope = { event_name = event }
		scope["OnGameEvent_" + event] <- function (params) {
			if ("userid" in params)
				params.player <- GetPlayerFromUserID(params.userid)
			if ("victim" in params)
				params.player_victim <- GetPlayerFromUserID(params.victim)
			if ("attacker" in params)
				params.player_attacker <- GetPlayerFromUserID(params.attacker)
			foreach(key, callback_table in DirectorScript.__callbacks[scope.event_name]) {
				try {
					if (callback_table.ent != null && invalid(callback_table.ent)) {
						logf("Removing callback %s.%s because entity is not valid", scope.event_name, key.tostring())
						delete DirectorScript.__callbacks[scope.event_name][key]
						continue
					}
					local result = callback_table.func(clone params)
					if (result == false) delete DirectorScript.__callbacks[scope.event_name][key]
				} catch (exception) {
					logf("ERROR! Exception in callback %s.%s: %s", scope.event_name, key.tostring(), exception)
				}
			}
		}
		__CollectEventCallbacks(scope, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener)
	}
	DirectorScript.__callbacks[event][key] <- {
		ent = ent
		func = func.bindenv(this)
	}
}

remove_callback <- function(key, event) {
	if (!("__callbacks" in DirectorScript)) return
	if (!(event in DirectorScript.__callbacks)) return
	local event_table = DirectorScript.__callbacks[event]
	if (!(key in event_table)) return
	delete event_table[key]
}

//----------------------------------

if (!("clock" in this)) clock <- {
	
	sec = Time
	
	msec = @() Time() * 1000
	
	frames = GetFrameCount
	
	__ticks = -1
	
	ticks = function() {
		if (__ticks == -1) throw "use clock.tick_counter_init() first"
		return __ticks
	}
	
	tick_counter_init = function() {
		__clock_init()
	}
	
	evaluate_tickrate = {
		start = function() {
			clock.evaluate_tickrate.start_sec <- clock.sec();
			clock.evaluate_tickrate.start_ticks <- clock.ticks();
		},
		finish = function() { 
			if (!("start_sec" in clock.evaluate_tickrate)) throw "clock.evaluate_tickrate: finish without start";
			if (clock.sec() == clock.evaluate_tickrate.start_sec) throw "zero time elapsed (game was paused?)";
			return (clock.ticks() - clock.evaluate_tickrate.start_ticks) / (clock.sec() - clock.evaluate_tickrate.start_sec);
		},
	}
	
	evaluate_framerate = {
		start = function() {
			clock.evaluate_framerate.start_sec <- clock.sec();
			clock.evaluate_framerate.start_frames <- clock.frames();
		},
		finish = function() { 
			if (!("start_sec" in clock.evaluate_framerate)) throw "clock.evaluate_framerate: finish without start";
			if (clock.sec() == clock.evaluate_framerate.start_sec) throw "zero time elapsed (game was paused?)";
			return (clock.frames() - clock.evaluate_framerate.start_frames) / (clock.sec() - clock.evaluate_framerate.start_sec);
		},
	}
	
}

//----------------------------------

add_task_on_shutdown <- function(key, func, after_all = false) {
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
			printl("running tasks on shutdown...")
			local arr = []
			foreach(key, func in __on_shutdown) arr.append([key, func])
			foreach(key, func in __on_shutdown_after_all) arr.append([key, func])
			foreach(key_and_func in arr) {
				try {
					key_and_func[1]()
				} catch (exception) {
					logf("ERROR! Exception in task on shutdown %s: %s", key_and_func[0].tostring(), exception)
				}
			}
		}.bindenv(this)
		
		//enabling developer mode
		if (Convars.GetStr("developer") == "0") {
			::__on_shutdown_reset_dev <- true
			Convars.SetValue("developer", 1)
			Convars.SetValue("contimes", 0)
		}
		log("new task on shutdown registered");
	}
	
	if (!after_all) {
		__on_shutdown[key] <- func.bindenv(scope)
		if (key in __on_shutdown_after_all) delete __on_shutdown_after_all[key]
	} else {
		__on_shutdown_after_all[key] <- func.bindenv(scope)
		if (key in __on_shutdown) delete __on_shutdown[key]
	}
}

remove_task_on_shutdown <- function(key) {
	if (!("__on_shutdown" in root)) return
	if (key in __on_shutdown) delete __on_shutdown[key]
	if (key in __on_shutdown_after_all) delete __on_shutdown_after_all[key]
}

reporter("Tasks", function() {
	log("\tClock initialized: " + (__clock_ent ? "true" : "false"))
	if (__clock_ent) {
		log("\tTickers and loops:")
		foreach(key, loop in __loops) {
			logf(
				"\t\t%s [delay = %g%s%s]",
				key, loop.delay,
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
				listeners.push(key)
			if (listeners.len() != 0)
				log("\t\t" + event + ": " + (listeners.len() > 0 ? concat(listeners, ", ") : "[none]"))
		}
	}
	log("\tDelayed calls:")
	if ("__delayed_calls" in DirectorScript) {
		logf("\t\t<current time: %g>", Time())
		foreach(key, delayed_call in DirectorScript.__delayed_calls) {
			logf(
				"\t\t%s [time = %g%s%s]",
				var_to_str(delayed_call.func),
				delayed_call.time,
				(delayed_call.ent ? format(", ent = %s", var_to_str(delayed_call.ent)) : ""),
				(delayed_call.group_key ? format(", group_key = %g", delayed_call.group_key) : "")
			)
		}
	}
	log("\tTasks on shutdown:")
	if ("__on_shutdown" in root) {
		foreach(key, task in __on_shutdown)
			logf("\t\t%s: %s", key, var_to_str(task))
		foreach(key, task in __on_shutdown_after_all)
			logf("\t\t%s: %s", key, var_to_str(task))
	}
})