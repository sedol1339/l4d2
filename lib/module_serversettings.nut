//---------- DOCUMENTATION ----------

/**
TASK-BASED SERVER MODIFICATIONS AND CUSTOM CALLBACKS
! requires lib/module_base !
! requires lib/module_tasks !
! requires lib/module_entities !
------------------------------------
cvar(cvar, value, flags)
	Advanced version of cvar() function from mudole_base. Accept three parameters instead of two. This function set the cvar and perform some additional actions depending on flags.
	Flags is a bitmask of the following constants:
	RESTORE_ON_DISCONNECT //register on_shutdown task that will restore current cvar value before first cvars() call
	CHECK_ON_SV_CHEATS //restore cvar value on sv_cheats change
	CHECK_EVERY_TICK //check value every tick and restore if it's wrong
	CHECK_SERVER_CVAR_EVENT //listens for server_cvar event with this variable and restores it, only seems to work for variables with FCVAR_NOTIFY ("nf") flag; warning! using this with sv_cheats when it's locked may freeze the game
	Examples:
	//this will make a server that will never shutdown by it's own:
	cvar("sb_all_bot_game", 1, CHECK_ON_SV_CHEATS | CHECK_EVERY_TICK)
	//this will make changing sv_cheats impossible without scripts:
	cvar("sv_cheats", 0, CHECK_SERVER_CVAR_EVENT)
	//this will not show flashlight until player exit the map
	cvar("r_flashlightrender", 0, RESTORE_ON_DISCONNECT)
	//infected will not get killed when are too far from survivors (INF is float-point infinity constant)
	cvar("z_discard_range", INF, CHECK_ON_SV_CHEATS | RESTORE_ON_DISCONNECT)
------------------------------------
cvars_restore()
	Restores all cvars that were set using cvars() function with RESTORE_ON_DISCONNECT flag, but not removes them from list, so on disconnect they will be restored again.
------------------------------------
cvar_remove_flags(cvar, flags)
	Remove flags that were set using cvar() function. Valid flag values: RESTORE_ON_DISCONNECT, CHECK_ON_SV_CHEATS, CHECK_EVERY_TICK, CHECK_SERVER_CVAR_EVENT.
------------------------------------
cvar_create(cvarname, value)
	Creates new convar using console command "setinfo <cvarname> <value>". This value can be operated with later, like other convars. Note that since this function runs console command, result cannot be retrieved with cvarf() immediately. TODO: does this work on dedicated server?
------------------------------------
player_settings
	A table that contains different player settings. Each setting is a field in table, for example player_settings.autojump. Each setting is a scope containing the following functions:
		set( team(s) | player, state | UNDEFINED )
		force( player, state )
		unforce( player )
		force_global( state )
		unforce_global()
		resolve_player_state( player ) //returns resolved state of player
		exists_player_with_state( state ) // true it there is at least one player with this resolved state
	What is a player setting? Setting stores a state for each player (usually STATE_ENABLED or STATE_DISABLED). Setting is an algorithm that consists of onTick and onChange functions. Function onChange is called when player state changes and function onTick is called every tick for every player (although it has some performance optimization).
	How does this work? At first player state is getting resolved:
		1) If setting has global forced state (force_global(state)), it is used
		2) Otherwise if player has forced state (force(player, state)), it is used
		3) Otherwise if player has a state (set(player, state)), it is used
		4) Otherwise if player's team (survivors or infected) has a state (set(team, state)), it is used
		5) Otherwise default_state is used
	Then if current state requires an onTick operation, it is performed every tick.
	EXAMPLE: player_settings.autojump
		This is a setting that allows player to jump continuously (autobhop). It has 2 states: STATE_ENABLED and STATE_DISABLED. STATE_ENABLED means that autobhop is active. Default state is STATE_DISABLED.
		Operations:
			player_settings.autojump.set(Teams.ANY, STATE_ENABLED) //enable autobhop for both survivors and infected teams
			player_settings.autojump.set(Teams.INFECTED, STATE_DISABLED) //disble autobhop for infected (for survivors it is still enabled)
			player_settings.autojump.set(Teams.SURVIVORS, null) //removes team state for survivors (use default state == STATE_DISABLED instead)
			player_settings.autojump.set(player, STATE_ENABLED) //enable autobhop for current player (overrides team settings)
			player_settings.autojump.set(player, STATE_DISABLED) //disable autobhop for current player (overrides team settings)
			player_settings.autojump.set(player, null) //remove player state, this player will use team settings instead
			player_settings.autojump.force(player, STATE_ENABLED) //force autobhop for current player (overrides team and player settings). This is almost the same as .set(), but there are some cases when .force() function is still required: for example, for thirdperson setting when you want to force thirdperson view ignoring player settings
			player_settings.autojump.unforce(player) //remove forced state for player.
			player_settings.autojump.force_global(STATE_DISABLED) //disables autobhop globally. This is only useful for some technical reasons.
			player_settings.autojump.unforce_global() //remove global forced state
		Some settings have additional functions, for example autojump has method() function that controls autobhop type (see below).
LIST OF PLAYER SETTINGS
	player_settings.autojump
		Controls autobhop. Has two states: STATE_DISABLED and STATE_ENABLED. Have additional function player_settings.autojump.method() that accepts three values: player_settings.autojump.PRECISE, player_settings.autojump.SMOOTH, player_settings.autojump.SP_SMOOTH. Precise method forces jump button when player lands, smooth method corrects it's velocity instead. SP_SMOOTH also forces buttons for player, but it makes bhop smoother for listenserver host by setting cl_smooth = 0.
	player_settings.external_view
		Has two states: STATE_DISABLED and STATE_ENABLED. If enabled, forces thirdperson view for survivor player. Works in coop and versus.
	player_settings.external_view_pvc
		Has two states: STATE_DISABLED and STATE_ENABLED. If enabled, forces thirdperson view for survivor or infected player using point_viewcontrol. Is not lagcompenstated and not interpolated, so not recommended to use. This is still the only way to enable thirdperson for infected player without forcing it globally (z_view_distance) or changing gamemode to coop and running "thirdperson" from client. Also this thirdperson method disables screen effects like vomit.
	player_settings.jockey_health_modifier
	player_settings.smoker_health_modifier
	player_settings.tank_health_modifier
	player_settings.boomer_health_modifier
	player_settings.charger_health_modifier
	player_settings.hunter_health_modifier
	player_settings.spitter_health_modifier
	player_settings.survivor_health_modifier
	player_settings.survivor_incap_health_modifier
	player_settings.survivor_hanging_health_modifier
		These settings control max health of player classes. Values 0 and 1 mean default max health, Values > 0 mean health multiplier, Values < 0 mean static health (negated). Examples: 0 - default health, 1 - default health, 2 - twice health, 0.5 - half health, -100 - 100 health.
LIST OF PERKS
	This is a special subset of player settings that modify game mechanics.
	player_settings.charger_steering
		Has two states: STATE_DISABLED and STATE_ENABLED. Allows chargers to rotate with mouse while charging. Can be changed while charging.
	player_settings.charger_jump
		Has two states: STATE_DISABLED and STATE_ENABLED. Allows chargers to jump while charging. Will not work if steering is not allowed. Can be changed while charging. Jump force can be chaged by changing field player_settings.charger_jump.jump_force (default 1.0 = survivor's jump height).  Individuela jump force can be set by setting field charger_jump_modifier in player's script scope.
------------------------------------
server_settings
	A table that contains different server settings. Each setting is a field in table, for example server_settings.no_director. Each setting is a scope containing the following functions:
		set(state_or_null)
		force(state)
		unforce()
		resolve_state() //returns resolved state
	This works the same as for player settings, see above. Just an example:
		server_settings.no_director.set(STATE_ENABLED) //disables director for a map
LIST OF SERVER SETTINGS
	server_settings.no_bot_deathcams
		Automatically removes all infected bot players with deathcam (ones that have just died).
	server_settings.no_director
		Disables director and allows to enable it again without using console commands or convars.
	server_settings.playable_team
		Accept values Teams.SURVIVORS, Teams.INFECTED, Teams.ANY (default). Moves all human players to specified team and tries to prevent team changes (it still can be bypassed).
------------------------------------
custom_callbacks
	A table that contains different custom callbacks. Each callback is a field in table, for example custom_callbacks.bunnyhop_attempt. Each callback is a scope containing the following functions:
		register_listener(key, function(params))
		remove_listener(key)
		remove_all_listeners()
	It works the same way as register_callback function. Params table is different for each custom callback.
LIST OF CUSTOM CALLBACKS
	custom_callbacks.bunnyhop_attempt
		This is called everyime 4 ticks after player lands on ground. Parameters:
		player //a player (squirrel CBaseEntity handle) that lands
		success //is true if player made a bunnyhop (perfectly timed jump)
		jump_time_error //is 0 if player made a bunnyhop, is NAN if player didn't press jump button, is -4..4 if player pressed jump button not exactly in time (> 0 means too late, < 0 means too early, measured in server ticks). This may be used to create a bunnyhop instructor
		bhops_done //how many continuous bhops are already done (including this bunnyhop if sucess = true, otherwise excludng this bunnyhop attempt)
		max_speed //max horizontal speed gained in a bunnyhop streak (speed is updated everytime when player lands).
	custom_callbacks.bunnyhop_streak_end
		This is called 4 ticks after player lands on ground after bunnyhop streak. Actually it's possible to use bunnyhop_attempt callback instead of this. Internally bunnyhop_streak_end callback is a listener for bunnyhop_attempt callback. Parameters:
		player //a player (squirrel CBaseEntity handle) that lands after bunnyhop streak
		bhops_done //how many continuous bhops are done
		max_speed //max horizontal speed gained in a bunnyhop streak (speed is updated everytime when player lands).
------------------------------------
new_custom_callback(name, params)
	Creates a new custom callback.
	Params:
	- name: a unique name for callback. This table will be saved as custom_callbacks[name] - a callback scope.
	Params table should contain these fields:
	- on_enable: function that is called when callback is enabled (no listeners -> 1 listener)
	- on_disable: function that is called when callback is disabled (1 listener -> no listeners)
	- validate: optional, function should return true if callback is enabled (ticker registered or something)
	- fix: optional: if validate is stated and validity check failed, this function should revert to disabled state
	(otherwise on_disable() is used)
	Function call_listners(params) is available from on_enable() and should be mentioned there.
	These functions will be available after creating a custom callback:
	custom_callbacks[name].register_listener(key, function(params))
	custom_callbacks[name].remove_listener(key)
	custom_callbacks[name].remove_all_listeners()
------------------------------------
new_server_setting(params)
------------------------------------
new_player_setting(name, params)
	!! this is a function mainly for iternal usage, but it still can be used outside the library
	This is an easy way to customize a server. With new_player_setting() it's possible to define and change things like charger steering, autobhop, different perks and more. Function new_player_setting() allows to define a set of functions that will be called for each players. After defining a setting, it is possible to use its name to enable or disable it, or change it's state. See details and examples in the code.
	Params:
	- name: a unique name for setting. This table will be saved as player_settings[name] - a setting scope.
	Params table should contain these fields:
	- default_state: any value that will be used as default state (not null, usually STATE_DISABLED)
	- should_run_ticker: function that accepts a state and returns true if ticker should be running, otherwise false
	- on_change: function(player, old_state, new_state) - performs any actions
	- on_tick: function(player, player_state) - performs any actions
	- custom_reporter: optionally a function that returns a string or string array without linebreaks, is used in report()
	These functions will be available after creating a setting with a name:
	player_settings[name].set( team(s) | player, state | UNDEFINED )
	player_settings[name].force( player, state )
	player_settings[name].unforce( player )
	player_settings[name].force_global( state )
	player_settings[name].unforce_global()
	player_settings[name].resolve_player_state( player ) //returns resolved state of player
	player_settings[name].exists_player_with_state( state ) // true it there is at least one player with this resolved state
	If new_player_setting is called again for the same setting, it it and overrides functions and validates setting state, but does not reset team states, player states, forced player states.
 */


//---------- CODE ----------

this = ::root

log("[lib] including module_serversettings")

_def_constvar("RESTORE_ON_DISCONNECT", (1 << 0))
_def_constvar("CHECK_ON_SV_CHEATS", (1 << 1))
_def_constvar("CHECK_EVERY_TICK", (1 << 2))
_def_constvar("CHECK_SERVER_CVAR_EVENT", (1 << 3))

_def_constvar("_cvar2_flag_names", [
	"RESTORE_ON_DISCONNECT",
	"CHECK_ON_SV_CHEATS",
	"CHECK_EVERY_TICK",
	"CHECK_SERVER_CVAR_EVENT"
])

if (!("_cvar_restore_on_disconnect" in root))
	_def_constvar("_cvar_restore_on_disconnect", {}) //cvar -> value to restore on disconnect
if (!("_cvar_check_sv_cheats" in root))
	_def_constvar("_cvar_check_sv_cheats", {}) //cvar -> value to restore on event
if (!("_cvar_check_every_tick" in root))
	_def_constvar("_cvar_check_every_tick", {}) //cvar -> value to restore on tick
if (!("_cvar_check_event" in root))
	_def_constvar("_cvar_check_event", {}) //cvar -> value to restore on cvar event

_def_func("cvar2", function(_cvar, value, flags) {
	Convars.SetValue(_cvar, value)
	local flag_names = []
	for(local i = 0; i < _cvar2_flag_names.len(); i++) {
		if (flags & (1 << i)) {
			flag_names.append(_cvar2_flag_names[i])
		}
	}
	logf("[lib] cvar %s set to %s [%s]", _cvar, value.tostring(), concat(flag_names, " | "))
	cvar_remove_flags(_cvar, ~flags)
	if (flags & RESTORE_ON_DISCONNECT) {
		if (!(_cvar in _cvar_restore_on_disconnect)) {
			_cvar_restore_on_disconnect[_cvar] <- value
		}
		add_task_on_shutdown("_cvar_restore_on_disconnect", function() {
			foreach(_cvar, value in _cvar_restore_on_disconnect) {
				Convars.SetValue(_cvar, value)
				logf("[lib] cvar %s restored to %s", _cvar, value.tostring())
			}
		}, true)
	}
	if (flags & CHECK_ON_SV_CHEATS) {
		_cvar_check_sv_cheats[_cvar] <- value
		register_callback("_cvar_check_sv_cheats", "server_cvar", function(params) {
			if (params.cvarname == "sv_cheats" && !cheats()) {
				foreach(_cvar, value in _cvar_check_sv_cheats) {
					Convars.SetValue(_cvar, value)
					logf("[lib] cvar %s restored to %s on sv_cheats reset", _cvar, value.tostring())
				}
			}
		})
	}
	//purpose: get a value that can be written back with Convars.SetValue
	local get_real_value = function(_cvar, str_override = null) {
		local real_value = str_override ? str_override : Convars.GetStr(_cvar)
		if (real_value == "1.#INF00" && Convars.GetFloat(_cvar) == INF) {
			real_value = INF
		} else if (real_value == "-1.#IND00" && Convars.GetFloat(_cvar) == NAN) {
			real_value = NAN
		}
		return real_value
	}
	if (flags & CHECK_EVERY_TICK) {
		local real_value = get_real_value(_cvar)
		_cvar_check_every_tick[_cvar] <- real_value
		register_ticker("_cvar_check_every_tick", function() {
			foreach(_cvar, value in _cvar_check_every_tick) {
				local get_value = get_real_value(_cvar)
				if (get_value != value) {
					Convars.SetValue(_cvar, value)
					logf("[lib] cvar %s restored to %s from %s on check",
						_cvar, value.tostring(), get_value.tostring())
				}
			}
		})
	}
	if (flags & CHECK_SERVER_CVAR_EVENT) {
		_cvar_check_event[_cvar] <- get_real_value(_cvar)
		register_callback("_cvar_check_event", "server_cvar", function(params) {
			local _cvar = params.cvarname
			if (!(_cvar in _cvar_check_event)) return
			local value = get_real_value(_cvar, params.cvarvalue)
			local saved_value = _cvar_check_event[_cvar]
			if (saved_value != value) {
				Convars.SetValue(_cvar, saved_value)
				logf("[lib] cvar %s restored to %s from %s on server_cvar event",
					_cvar, saved_value.tostring(), value.tostring())
			}
		})
	}
})

_def_func("cvars_restore", function() {
	local restored_count = 0
	if (_cvar_restore_on_disconnect.len() > 0) {
		foreach(_cvar, value in _cvar_restore_on_disconnect) {
			Convars.SetValue(_cvar, value)
			logf("[lib] cvar %s restored to %s", _cvar, value.tostring())
		}
	}
	logf("[lib] cvars_restore(): restored %d cvars", restored_count)
})

_def_func("cvar_remove_flags", function(_cvar, flags) {
	local flag_names = []
	if (flags & RESTORE_ON_DISCONNECT) {
		if (_cvar in _cvar_restore_on_disconnect) {
			delete _cvar_restore_on_disconnect[_cvar]
			flag_names.append(_cvar2_flag_names[0])
			if (_cvar_restore_on_disconnect.len() == 0) {
				remove_task_on_shutdown("_cvar_restore_on_disconnect")
			}
		}
	}
	if (flags & CHECK_ON_SV_CHEATS) {
		if (_cvar in _cvar_check_sv_cheats) {
			delete _cvar_check_sv_cheats[_cvar]
			flag_names.append(_cvar2_flag_names[1])
			if (_cvar_check_sv_cheats.len() == 0) {
				if (callback_exists("_cvar_check_sv_cheats", "server_cvar"))
					remove_callback("_cvar_check_sv_cheats", "server_cvar")
			}
		}
	}
	if (flags & CHECK_EVERY_TICK) {
		if (_cvar in _cvar_check_every_tick) {
			delete _cvar_check_every_tick[_cvar]
			flag_names.append(_cvar2_flag_names[2])
			if (_cvar_check_every_tick.len() == 0) {
				remove_ticker("_cvar_check_every_tick")
			}
		}
	}
	if (flags & CHECK_SERVER_CVAR_EVENT) {
		if (_cvar in _cvar_check_event) {
			delete _cvar_check_event[_cvar]
			flag_names.append(_cvar2_flag_names[3])
			if (_cvar_check_event.len() == 0) {
				if (callback_exists("_cvar_check_event", "server_cvar"))
					remove_callback("_cvar_check_event", "server_cvar")
			}
		}
	}
	if (flag_names.len() > 0) {
		logf("[lib] for cvar %s removed flags [%s]", _cvar, concat(flag_names, " | "))
	}
})

///////////////////////////////
// new_player_setting
///////////////////////////////

if (!("player_settings" in root)) _def_constvar("player_settings", {})

_def_func("new_player_setting", function(name, scope) {
	local old_scope
	if (name in player_settings) {
		//log("[lib] new_player_setting(): overriding " + name)
		old_scope = player_settings[name]
	}
	player_settings[name] <- scope
	// -- MOVING FIELDS --
	//re-including library should not change anything in the game, so old fields should remain the same
	scope.__survivors <- null
	scope.__infected <- null
	scope.__players <- {} //no null values!
	scope.__players_forced <- {} //no null values!
	scope.__global_forced <- null
	scope.__marked_players <- {}
	scope.__state <- null
	scope.__forced <- null
	scope.__team_hook_created <- false
	//move all fields from old scope that are not a functions
	if (old_scope) {
		foreach(key, value in old_scope) {
			if (typeof value != "function") {
				scope[key] <- value
			}
		}
	}
	// -- INTERNAL FUNCTIONS --
	scope.__team_hook_create <- function() {
		register_callback("player_settings." + name, "player_team", function(params) {
			__handle_change({
				[params.player] = resolve_player_state(params.player, params.oldteam)
			})
		}.bindenv(scope))
		log("[lib] registered player_team listener for player setting " + name)
	}.bindenv(scope)
	scope.__should_run_ticker <- function() {
		if (__global_forced != null) {
			return should_run_ticker(__global_forced)
		}
		if (
			(__infected != null && should_run_ticker(__infected))
			|| (__survivors != null && should_run_ticker(__survivors))
			|| should_run_ticker(default_state)
		) {
			return true
		}
		foreach (player in players()) {
			local player_state = null
			if (player in __players_forced) {
				player_state = __players_forced[player]
			} else if (player in __players) {
				player_state = __players[player]
			}
			if (player_state != null && should_run_ticker(player_state)) {
				return true
			}
		}
		return false
	}.bindenv(scope)
	scope.__handle_change <- function(prev_player_states = null, on_startup = false) {
		local ticker_name = "player_settings." + name
		if (__should_run_ticker()) {
			if (!loop_exists(ticker_name)) {
				register_ticker(ticker_name, __ticker_func)
			}
		} else {
			remove_ticker(ticker_name)
		}
		foreach(player, value in __players) {
			if (invalid(player)) delete __players[player]
		}
		foreach(player, value in __players_forced) {
			if (invalid(player)) delete __players_forced[player]
		}
		foreach(player, value in __marked_players) {
			if (invalid(player)) delete __marked_players[player]
		}
		foreach(player in players()) {
			__marked_players[player] <- true
			local player_state = resolve_player_state(player)
			if (prev_player_states) {
				if (!(player in prev_player_states)) continue
				local prev_player_state = prev_player_states[player]
				if (prev_player_state != player_state) {
					on_change(player, prev_player_state, player_state)
				}
			} else if (on_startup) {
				on_change(player, null, player_state)
			}
			if (!__team_hook_created && player_state != default_state) {
				//first changes in this setting, registering hook for player_team event
				__team_hook_create()
				__team_hook_created = true
			}
		}
	}.bindenv(scope)
	scope.__erase_invalid_player <- function(player) {
		if (player in __players) delete __players[player]
		if (player in __players_forced) delete __players_forced[player]
		if (player in __marked_players) delete __marked_players[player]
	}
	scope.__ticker_func <- function() {
		this = scope //cannot bindenv ticker func
		foreach(player in players()) {
			if (invalid(player)) {
				__erase_invalid_player(player)
				continue
			}
			local player_state = resolve_player_state(player)
			if (!(player in __marked_players)) {
				__marked_players[player] <- true
				on_change(player, null, player_state)
			}
			if (should_run_ticker(player_state)) on_tick(player, player_state)
		}
	}
	scope.__get_prev_player_states <- function() {
		local prev_player_states = {}
		foreach(player in players()) {
			prev_player_states[player] <- resolve_player_state(player)
		}
		return prev_player_states
	}
	// -- PUBLIC FUNCTIONS --
	scope.resolve_player_state <- function(player, force_team = null) {
		if (__global_forced != null) return __global_forced
		if (player in __players_forced) return __players_forced[player]
		if (player in __players) return __players[player]
		local team = force_team ? force_team : NetProps.GetPropInt(player, "m_iTeamNum")
		if (team == 2 && __survivors != null) return __survivors
		if (team == 3 && __infected != null) return __infected
		return default_state
	}.bindenv(scope)
	scope.exists_player_with_state <- function(state) {
		foreach(player in players()) {
			if (resolve_player_state(player) == state) return true
		}
		return false
	}.bindenv(scope)
	scope.set <- function(team_or_player, state_or_null) {
		local prev_player_states = __get_prev_player_states()
		if (typeof team_or_player == "integer") {
			local team = team_or_player
			if (team & Teams.SURVIVORS) {
				__survivors = state_or_null
			}
			if (team & Teams.INFECTED) {
				__infected = state_or_null
			}
		} else {
			local player = team_or_player
			if (state_or_null == null) {
				if (player in __players) delete __players[player]
			} else {
				__players[player] <- state_or_null
			}
		}
		__handle_change(prev_player_states)
	}.bindenv(scope)
	scope.force <- function(player, state_not_null) {
		local prev_player_states = __get_prev_player_states()
		if (typeof team_or_player != "instance")
			throw "[lib] " + name + ".force(): pass player instance as first argument"
		if (state_not_null == null)
			throw "[lib] " + name + ".force(): state should not be null"
		__players_forced[player] <- state_not_null
		__handle_change(prev_player_states)
	}.bindenv(scope)
	scope.unforce <- function(player) {
		local prev_player_states = __get_prev_player_states()
		if (typeof team_or_player != "instance")
			throw "[lib] " + name + ".unforce(): pass player instance as first argument"
		if (player in __players_forced) delete __players_forced[player]
		__handle_change(prev_player_states)
	}.bindenv(scope)
	scope.force_global <- function(state_not_null) {
		local prev_player_states = __get_prev_player_states()
		if (state_not_null == null)
			throw "[lib] " + name + ".force_global(): state should not be null"
		__global_forced <- state_not_null
		__handle_change(prev_player_states)
	}.bindenv(scope)
	scope.unforce_global <- function() {
		local prev_player_states = __get_prev_player_states()
		__global_forced <- null
		__handle_change(prev_player_states)
	}.bindenv(scope)
	// -- VALIDATION AND ENABLING IF NEEDED --
	scope.__handle_change(null, true)
})

///////////////////////////////
// new_server_setting
///////////////////////////////

if (!("server_settings" in root)) _def_constvar("server_settings", {})

_def_func("new_server_setting", function(name, scope) {
	local old_scope
	if (name in server_settings) {
		//log("[lib] new_server_setting(): overriding " + name)
		old_scope = server_settings[name]
	}
	server_settings[name] <- scope
	// -- MOVING FIELDS --
	//re-including library should not change anything in the game, so old fields should remain the same
	scope.__state <- null
	scope.__forced <- null
	//move all fields from old scope that are not a functions
	if (old_scope) {
		foreach(key, value in old_scope) {
			if (typeof value != "function") {
				scope[key] <- value
			}
		}
	}
	// -- INTERNAL FUNCTIONS --
	scope.__handle_change <- function(prev_state = null) {
		local ticker_name = "server_settings." + name
		local current_state = resolve_state()
		if (should_run_ticker(current_state)) {
			if (!loop_exists(ticker_name)) {
				register_ticker(ticker_name, __ticker_func)
			}
		} else {
			remove_ticker(ticker_name)
		}
		on_change(prev_state, current_state)
	}.bindenv(scope)
	scope.__ticker_func <- function() {
		this = scope //cannot bindenv ticker func
		local current_state = resolve_state()
		on_tick(current_state)
	}
	// -- PUBLIC FUNCTIONS --
	scope.resolve_state <- function() {
		if (__forced != null) return __forced
		if (__state != null) return __state
		return default_state
	}.bindenv(scope)
	scope.set <- function(state_or_null) {
		local prev_state = resolve_state()
		__state = state_or_null
		__handle_change(prev_state)
	}.bindenv(scope)
	scope.force <- function(state_not_null) {
		if (state_not_null == null)
			throw "[lib] " + name + ".force(): state should not be null"
		local prev_state = resolve_state()
		__forced = state_not_null
		__handle_change(prev_state)
	}.bindenv(scope)
	scope.unforce <- function() {
		local prev_state = resolve_state()
		__forced = null
		__handle_change(prev_state)
	}.bindenv(scope)
	// -- VALIDATION AND ENABLING IF NEEDED --
	scope.__handle_change(null)
})

///////////////////////////////
// new_custom_callback
///////////////////////////////

if (!("custom_callbacks" in root)) _def_constvar("custom_callbacks", {})

_def_func("new_custom_callback", function(name, scope) {
	local override_scope = ((name in custom_callbacks) ? custom_callbacks[name] : null)
	//if (override_scope) log("[lib] new_custom_callback(): overriding " + name)
	custom_callbacks[name] <- scope
	// -- INTERNAL FIELDS --
	scope.__listeners <- {}
	scope.__enabled <- false
	scope.__validate <- function() {
		if (!("validate" in this)) return
		local validated_enabled = validate()
		if (__enabled != validated_enabled) {
			local fix_func = ("fix" in this) ? fix : on_disable
			fix_func()
			__enabled = false
		}
	}
	scope.__handle_change <- function() {
		if (__listeners.len() > 0) {
			if (!__enabled) {
				__enabled <- true
				on_enable()
			}
		} else {
			if (__enabled) {
				__enabled <- false
				on_disable()
			}
		}
	}.bindenv(scope)
	// -- PUBLIC FUNCTIONS --
	scope.call_listners <- function(params) {
		foreach(listener in __listeners) {
			try {
				listener.call(clone params)
			} catch (e) {}
		}
	}.bindenv(scope)
	scope.register_listener <- function(key, func) {
		func = func.bindenv(this)
		this = scope
		__validate()
		__listeners[key] <- newthread( function(params) {
			if (func(params) == false) delete scope.__listeners[key]
		})
		__handle_change()
	}
	scope.remove_listener <- function(key) {
		__validate()
		if (key in __listeners) delete __listeners[key]
		__handle_change()
	}.bindenv(scope)
	scope.remove_all_listeners <- function() {
		__validate()
		__listeners.clear()
		__handle_change()
	}.bindenv(scope)
	// -- RESTORING SETTINGS --
	if (override_scope) {
		scope.__listeners = override_scope.__listeners
		scope.__enabled = override_scope.__enabled
	}
	// -- VALIDATION AND ENABLING IF NEEDED --
	scope.__validate()
	scope.__handle_change()
})

///////////////////////////////
// PLAYER SETTINGS
///////////////////////////////

_def_func("__check_jump_possibility", function(player) { //may not work for custom models
	local GetUpFrom_TankPunch = {
		"models/survivors/survivor_gambler.mdl": 630
		"models/survivors/survivor_producer.mdl": 638
		"models/survivors/survivor_coach.mdl": 630
		"models/survivors/survivor_mechanic.mdl": 635
		"models/survivors/survivor_namvet.mdl": 538
		"models/survivors/survivor_teenangst.mdl": 547
		"models/survivors/survivor_manager.mdl": 538
		"models/survivors/survivor_biker.mdl": 541
	}
	local GetUpFrom_Charger = {
		"models/survivors/survivor_gambler.mdl": 667
		"models/survivors/survivor_producer.mdl": 674
		"models/survivors/survivor_coach.mdl": 656
		"models/survivors/survivor_mechanic.mdl": 671
		"models/survivors/survivor_namvet.mdl": 759
		"models/survivors/survivor_teenangst.mdl": 819
		"models/survivors/survivor_manager.mdl": 759
		"models/survivors/survivor_biker.mdl": 762
	}
	local GetUpFrom_Pounced = {
		"models/survivors/survivor_gambler.mdl": 620
		"models/survivors/survivor_producer.mdl": 629
		"models/survivors/survivor_coach.mdl": 621
		"models/survivors/survivor_mechanic.mdl": 625
		"models/survivors/survivor_namvet.mdl": 528
		"models/survivors/survivor_teenangst.mdl": 537
		"models/survivors/survivor_manager.mdl": 528
		"models/survivors/survivor_biker.mdl": 531
	}
	local Charger_Slammed_Wall = {
		"models/survivors/survivor_gambler.mdl": 671
		"models/survivors/survivor_producer.mdl": 678
		"models/survivors/survivor_coach.mdl": 660
		"models/survivors/survivor_mechanic.mdl": 675
		"models/survivors/survivor_namvet.mdl": 763
		"models/survivors/survivor_teenangst.mdl": 823
		"models/survivors/survivor_manager.mdl": 763
		"models/survivors/survivor_biker.mdl": 766
	}
	if (NetProps.GetPropInt(player, "movetype") != 2) return false
	if (NetProps.GetPropInt(player, "m_hGroundEntity") == -1) return false
	if (NetProps.GetPropInt(player, "m_iCurrentUseAction") != 0) return false
	if (NetProps.GetPropInt(player, "m_isIncapacitated") == 1) return false
	if (player.IsSurvivor()) {
		if (NetProps.GetPropEntity(player, "m_reviveTarget") != null) return false
		if (NetProps.GetPropEntity(player, "m_pounceAttacker") != null) return false
		if (NetProps.GetPropEntity(player, "m_carryAttacker") != null) return false
		if (NetProps.GetPropEntity(player, "m_pummelAttacker") != null) return false
		if (NetProps.GetPropEntity(player, "m_jockeyAttacker") != null) return false
		if (NetProps.GetPropEntity(player, "m_tongueOwner") != null) return false
		local model = NetProps.GetPropString(player, "m_ModelName")
		local sequence = NetProps.GetPropInt(player, "m_nSequence")
		if (model in GetUpFrom_TankPunch) {
			//standart model
			if (GetUpFrom_TankPunch[model] == sequence) return false
			if (GetUpFrom_Charger[model] == sequence) return false
			if (GetUpFrom_Pounced[model] == sequence) return false
			if (Charger_Slammed_Wall[model] == sequence) return false
		}
		if (NetProps.GetPropInt(player, "m_isHangingFromLedge") == 1) return false
		if (NetProps.GetPropInt(player, "m_isFallingFromLedge") == 1) return false
		if (NetProps.GetPropFloat(player, "m_jumpSupressedUntil") > Time()) return false
		return true //true?
	} else {
		if (NetProps.GetPropEntity(player, "m_pounceVictim") != null) return false
		if (NetProps.GetPropEntity(player, "m_carryVictim") != null) return false
		if (NetProps.GetPropEntity(player, "m_pummelVictim") != null) return false
		if (NetProps.GetPropEntity(player, "m_jockeyVictim") != null) return false
		if (NetProps.GetPropEntity(player, "m_tongueVictim") != null) return false
		local sequence = NetProps.GetPropInt(player, "m_nSequence")
		if (player.GetZombieType() == 6 && sequence == 5) return false //charging //TODO change to model
		if (NetProps.GetPropInt(player, "m_flStamina") == 3000) return false //throwing rock or vomiting TODO check cvar
		return true
	}
})

new_player_setting("autojump", {
	default_state = STATE_DISABLED
	should_run_ticker = @(state) state == STATE_ENABLED
	on_change = function(player, old_state, new_state) {
		if (
			old_state == STATE_ENABLED
			&& new_state == STATE_DISABLED
			&& (__method == PRECISE || __method == SP_SMOOTH)
		) {
			local m_afButtonDisabled = NetProps.GetPropInt(player, "m_afButtonDisabled")
			NetProps.SetPropInt(player, "m_afButtonDisabled", m_afButtonDisabled & ~2)
		}
	}
	on_tick = function(player, player_state) {
		//is called only for player_state == STATE_ENABLED
		if (__method == PRECISE || __method == SP_SMOOTH) {
			local m_afButtonDisabled = NetProps.GetPropInt(player, "m_afButtonDisabled")
			if (
				NetProps.GetPropInt(player, "m_hGroundEntity") == -1
				&& NetProps.GetPropInt(player, "movetype") == 2
			) {
				NetProps.SetPropInt(player, "m_afButtonDisabled", m_afButtonDisabled | 2)
			} else {
				NetProps.SetPropInt(player, "m_afButtonDisabled", m_afButtonDisabled & ~2)
			}
		} else {
			if (
				(NetProps.GetPropInt(player, "m_nButtons") & 2)
				&& __check_jump_possibility(player)
			) {
				NetProps.SetPropEntity(player, "m_hGroundEntity", null)
				local ducked = NetProps.GetPropInt(player, "m_Local.m_bDucked")
				local velocity = Vector(0, 0, ducked ? 297.043 : 245.705)
				local m_vecBaseVelocity = NetProps.GetPropVector(player, "m_vecBaseVelocity")
				NetProps.SetPropVector(player, "m_vecBaseVelocity", m_vecBaseVelocity + velocity)
				local flags = NetProps.GetPropInt(player, "m_fFlags")
				NetProps.SetPropInt(player, "m_fFlags", flags & ~FL_ONGROUND)
			}
		}
	}
	__get_method_str = function() {
		switch(__method) {
			case PRECISE: return "PRECISE"
			case SMOOTH: return "SMOOTH"
			case SP_SMOOTH: return "SP_SMOOTH"
		}
	}
	custom_reporter = @() "method: " + __get_method_str()
	PRECISE = 0
	SMOOTH = 1
	SP_SMOOTH = 2
	__method = 0 //PRECISE
	method = function(new_method) {
		if (new_method == __method) return
		if (new_method != PRECISE && new_method != SMOOTH && new_method != SP_SMOOTH)
			throw "invalid method"
		force_global(STATE_DISABLED) //disables autojump for all players
		if (new_method = SP_SMOOTH) {
			cvar("cl_smooth", 0, RESTORE_ON_DISCONNECT)
		} else {
			cvar("cl_smooth", 1, RESTORE_ON_DISCONNECT)
		}
		__method = new_method
		unforce_global() //applies method changes
		log("[lib] autojump method set to " + __get_method_str())
	}
})

new_player_setting("external_view", {
	default_state = STATE_DISABLED
	should_run_ticker = @(state) false
	on_change = function(player, old_state, new_state) {
		propfloat(player, "m_TimeForceExternalView", (new_state == STATE_ENABLED) ? INF : -1)
	}
})

new_player_setting("external_view_pvc", {
	default_state = STATE_DISABLED
	should_run_ticker = @(state) state == STATE_ENABLED
	__enable_pvc = function(player) {
		scope(player).pvc_enabled <- true
		if (!("pvc" in scope(player))) {
			scope(player).pvc <- SpawnEntityFromTable("point_viewcontrol", { spawnflags = 8 })
		}
		local pvc = scope(player).pvc
		DoEntFire("!self", "Enable", "", 0, player, pvc)
		local takedamage = propint(player, "m_takedamage")
		run_this_tick( function() {
			propint(player, "m_takedamage", 2)
			propint(pvc, "m_nOldTakeDamage", 2)
		})
	}
	__disable_pvc = function(player) {
		scope(player).pvc_enabled <- false
		if (!("pvc" in scope(player))) return
		DoEntFire("!self", "Disable", "", 0, player, scope(player).pvc)
	}
	on_change = function(player, old_state, new_state) {
		scope(player).pvc_enabled <- old_state //to ensure that this field exists
		if (new_state == STATE_DISABLED) __disable_pvc(player)
	}
	on_tick = function(player, player_state) {
		local enabled = scope(player).pvc_enabled
		if (player.IsDead() || player.IsDying()) {
			if (enabled) __disable_pvc(player)
		} else {
			if (!enabled) __enable_pvc(player)
			local pvc = scope(player).pvc
			pvc.SetOrigin(player.EyePosition() - player.EyeAngles().Forward().Scale(100))
			pvc.SetAngles(player.EyeAngles())
		}
	}
})

local player_classes = {
	[Z_SURVIVOR] = "survivor",
	[Z_SMOKER] = "smoker",
	[Z_BOOMER] = "boomer",
	[Z_HUNTER] = "hunter",
	[Z_SPITTER] = "spitter",
	[Z_JOCKEY] = "jockey",
	[Z_CHARGER] = "charger",
	[Z_TANK] = "tank"
}

_def_func("__apply_health_modifier", function(player, modifier) {
	local current_team = propint(player, "m_iTeamNum")
	if (player.IsDying() || player.IsDead() || player.IsGhost() || current_team < 2) return
	local zombie_class = player.GetZombieType()
	local incapped = player.IsIncapacitated() //true if player is hanging from ledge
	if (zombie_class != Z_SURVIVOR && incapped) return
	logf("[lib] applying health modifier %g to player %s of class %d", modifier, player_to_str(player), zombie_class)
	local player_scope = scope(player)
	local current_max_health = propint(player, "m_iMaxHealth")
	local current_health = propint(player, "m_iHealth")
	local default_max_health //for current class and incap state
	local health_percent = min(1.0, current_health.tofloat() / current_max_health)
	if (zombie_class != Z_SURVIVOR) {
		if (!("default_max_health" in player_scope) || player_scope.default_max_health_class != zombie_class) {
			player_scope.default_max_health <- current_max_health
			player_scope.default_max_health_class <- zombie_class
			logf("[lib] considering player's default max health is %d", current_max_health)
		} else {
			logf("[lib] was considered that player's default max health is %d", player_scope.default_max_health)
		}
		default_max_health = player_scope.default_max_health
	} else { //survivor
		if ("just_revived" in scope(player)) {
			delete scope(player).just_revived
			default_max_health = 100
			log("[lib] survivor was just revived, default max health = " + default_max_health)
		} else if (player.IsHangingFromLedge()) {
			default_max_health = cvarf("survivor_ledge_grab_health").tointeger()
			log("[lib] survivor is handing from ledge, default max health = " + default_max_health)
		} else if (incapped) {
			default_max_health = cvarf("survivor_incap_health").tointeger()
			log("[lib] survivor is incapped, default max health = " + default_max_health)
		} else {
			default_max_health = 100
			log("[lib] survivor is standing, default max health = " + default_max_health)
		}
	}
	if (modifier == 0 || modifier == 1) {
		//default health (maybe should reset it from modified health)
		if (current_max_health != default_max_health) {
			propint(player, "m_iMaxHealth", default_max_health)
			propint(player, "m_iHealth", ceil(default_max_health * health_percent))
		}
	} else if (modifier > 0) {
		//multiplier
		propint(player, "m_iMaxHealth", default_max_health * modifier)
		propint(player, "m_iHealth", ceil(default_max_health * health_percent * modifier))
	} else {
		//static health (negated)
		modifier = (-modifier).tointeger()
		propint(player, "m_iMaxHealth", modifier)
		propint(player, "m_iHealth", ceil(modifier * health_percent))
	}
	local model_index = propint(player, "m_nModelIndex")
	run_next_tick(player, function() {
		if (current_team != propint(player, "m_iTeamNum")) return
		if (player.IsDying() || player.IsDead() || player.IsGhost()) return
		if (model_index != propint(player, "m_nModelIndex")) return
		current_max_health = propint(player, "m_iMaxHealth")
		current_health = propint(player, "m_iHealth")
		local health_buffer = propfloat(player, "m_healthBuffer")
		local max_health_buffer = max(0, current_max_health - current_health)
		if (health_buffer > max_health_buffer) {
			logf("[lib] clumping health buffer from %g to %g", health_buffer, max_health_buffer)
			propfloat(player, "m_healthBuffer", max_health_buffer)
		}
	})
})

_def_func("__player_spawn_health_modifiers", function(params) {
	local player = params.player
	local zombie_class = player.GetZombieType()
	if (!(zombie_class in player_classes)) return
	local class_name = player_classes[zombie_class]
	local setting_scope = player_settings[class_name + "_health_modifier"]
	local modifier = setting_scope.resolve_player_state(player)
	__apply_health_modifier(player, modifier)
})

_def_func("__health_modifiers_handle_incap", function(params) {
	local modifier = player_settings.survivor_incap_health_modifier.resolve_player_state(params.player)
	__apply_health_modifier(params.player, modifier)
})

_def_func("__health_modifiers_handle_hanging", function(params) {
	local modifier = player_settings.survivor_hanging_health_modifier.resolve_player_state(params.player)
	__apply_health_modifier(params.player, modifier)
})

_def_func("__health_modifiers_handle_revive", function(params) {
	local player = GetPlayerFromUserID(params.subject)
	local modifier = player_settings.survivor_health_modifier.resolve_player_state(player)
	scope(player).just_revived <- null
	__apply_health_modifier(player, modifier)
})

_def_func("__health_modifiers_reg_callbacks", function() {
	register_callback("health_modifiers.handle_incap", "player_incapacitated", __health_modifiers_handle_incap)
	register_callback("health_modifiers.handle_hanging", "player_ledge_grab", __health_modifiers_handle_hanging)
	register_callback("health_modifiers.handle_revive", "revive_success", __health_modifiers_handle_revive)
})

foreach(_class_index, class_name in player_classes) {
	local class_index = _class_index
	new_player_setting(class_name + "_health_modifier", {
		default_state = 0
		should_run_ticker = @(state) false
		on_change = function(player, old_state, new_state) {
			//shared callback for all health modifiers
			register_callback("health_modifiers", "player_spawn", __player_spawn_health_modifiers)
			local zombie_class = player.GetZombieType()
			if (class_index == zombie_class) {
				if (class_index != Z_SURVIVOR || !player.IsIncapacitated()) {
					__apply_health_modifier(player, new_state)
				}
			}
			if (class_index == Z_SURVIVOR && new_state != default_state) __health_modifiers_reg_callbacks()
		}
	})
}

new_player_setting("survivor_incap_health_modifier", {
	default_state = 0
	should_run_ticker = @(state) false
	on_change = function(player, old_state, new_state) {
		if (player.GetZombieType() == Z_SURVIVOR && player.IsIncapacitated() && !player.IsHangingFromLedge()) {
			__apply_health_modifier(player, new_state)
		}
		if (new_state != default_state) __health_modifiers_reg_callbacks()
	}
})

new_player_setting("survivor_hanging_health_modifier", {
	default_state = 0
	should_run_ticker = @(state) false
	on_change = function(player, old_state, new_state) {
		if (player.GetZombieType() == Z_SURVIVOR && player.IsHangingFromLedge()) {
			__apply_health_modifier(player, new_state)
		}
		if (new_state != default_state) __health_modifiers_reg_callbacks()
	}
})

IncludeScript("kapkan/lib/perks")

///////////////////////////////
// SERVER SETTINGS
///////////////////////////////

new_server_setting("no_bot_deathcams", {
	default_state = STATE_DISABLED
	should_run_ticker = @(state) false
	on_change = function(old_state, new_state) {
		if (new_state == STATE_ENABLED) {
			register_callback("server_settings.no_bot_deathcams", "player_death", function(params) {
				local player = params.player
				if (!player.IsSurvivor() && IsPlayerABot(player)) {
					run_next_tick( function() { //to prevent errors in other player_death callbacks
						if (!invalid(player) && player.IsDying()) player.Kill()
					})
				}
			})
			foreach(player in players()) {
				if (player.IsDying() && !player.IsSurvivor() && IsPlayerABot(player)) player.Kill()
			}
		} else if (callback_exists("server_settings.no_bot_deathcams", "player_death")) {
			remove_callback("server_settings.no_bot_deathcams", "player_death")
		}
	}
})

new_server_setting("no_director", {
	default_state = STATE_DISABLED
	should_run_ticker = @(state) false
	__DirectorOptions_off = {
		CommonLimit = 0
		MaxSpecials = 0
		MegaMobSize = 0
		MobMaxPending = 0
		MobSpawnSize = 0
		TankLimit = 0
		WitchLimit = 0
	}
	__SessionOptions_off = {
		cm_CommonLimit = 0
		cm_MaxSpecials = 0
		cm_WitchLimit = 0
		cm_TankLimit = 0
	}
	__director_off = function() {
		log("[lib] server_settings.no_director: disabling director")
		if ("SessionOptions" in root) {
			saved_SessionOptions <- SessionOptions
			SessionOptions.clear() //cannot replace
			foreach(key, value in __SessionOptions_off) {
				SessionOptions[key] <- value
			}
		} else if ("DirectorScript" in root) {
			if ("DirectorOptions" in DirectorScript) {
				saved_DirectorOptions <- DirectorScript.DirectorOptions
			}
			DirectorScript.DirectorOptions <- clone __DirectorOptions_off
		}
		local ent = null
		while(ent = Entities.FindByClassname(ent, "info_zombie_spawn")) {
			scope(ent).InputSpawnZombie <- @()false
		}
	}
	__director_on = function() {
		log("[lib] server_settings.no_director: enabling director")
		if ("SessionOptions" in root) {
			SessionOptions.clear()
			if ("saved_SessionOptions" in this) {
				foreach(key, value in saved_SessionOptions) {
					SessionOptions[key] <- value
				}
			}
		}
		if ("DirectorScript" in root) {
			if ("saved_DirectorOptions" in this) {
				DirectorScript.DirectorOptions <- saved_DirectorOptions
			} else if ("DirectorOptions" in DirectorScript) {
				delete DirectorScript.DirectorOptions
			}
		}
		local ent = null
		while(ent = Entities.FindByClassname(ent, "info_zombie_spawn")) {
			delete scope(ent).InputSpawnZombie
		}
	}
	__compare_tables = function(table1, table2) {
		if (table1.len() != table2.len()) return false
		foreach(key, value in table1) {
			if (!(key in table2)) return false
			if (table2[key] != value) return false
		}
		return true
	}
	__check = function() {
		if ("SessionOptions" in root) {
			if (!__compare_tables(SessionOptions, __SessionOptions_off)) {
				SessionOptions.clear()
				foreach(key, value in __SessionOptions_off) {
					SessionOptions[key] <- value
				}
			}
		} else if (!("DirectorScript" in root)) {
			if (
				!("DirectorOptions" in DirectorScript)
				|| !__compare_tables(DirectorScript.DirectorOptions, __DirectorOptions_off)
			) {
				DirectorScript.DirectorOptions <- clone __DirectorOptions_off
			}
		}
		foreach(ent in infected()) {
			if (ent.IsPlayer() && !IsPlayerABot(ent)) continue
			if (!("group_key" in scope(ent))) {
				log("[lib] server_settings.no_director: removing zombie " + ent)
				ent.Kill()
			}
		}
	}
	on_change = function(old_state, new_state) {
		if (old_state == STATE_DISABLED && new_state == STATE_ENABLED) {
			__director_off()
			if (__do_check) __reg_check_task()
		} else if (old_state == STATE_ENABLED && new_state == STATE_DISABLED) {
			__director_on()
			__remove_check_task()
		}
	}
	__do_check = true
	__check_interval = 1.0
	__reg_check_task = function() {
		__check()
		register_loop("server_settings.no_director.check", __check_interval, function() {
			__check()
		})
	}
	__remove_check_task = function() {
		remove_loop("server_settings.no_director.check")
	}
	do_check = function(value) {
		if (value && !__do_check) {
			__reg_check_task()
		} else if (!value && __do_check) {
			__remove_check_task()
		}
		__do_check = value
	}
	set_check_interval = function(interval) {
		__check_interval = interval
		loop_set_delay("server_settings.no_director.check", __check_interval)
		loop_run_after("server_settings.no_director.check", 0)
	}
})

new_server_setting("playable_team", {
	default_state = Teams.ANY
	should_run_ticker = @(state) false
	__try_move_to_survivors = function(player) {
		local survivors = players(Teams.SURVIVORS)
		foreach(survivor in survivors) {
			if (IsPlayerABot(survivor)) {
				//a bot to possess
				client_command(player, "jointeam 2")
				return
			}
		}
		//no bot to possess
		local characters = [0, 1, 2, 3]
		foreach(survivor in survivors) {
			local index = characters.find(propint(survivor, "m_survivorCharacter"))
			if (index != null) characters.remove(index)
		}
		local character = characters.len() ? characters[0] : RandomInt(0, 3)
		local pos
		if (survivors.len()) {
			pos = survivors[0].GetOrigin()
		} else {
			local info_player_start = Entities.FindByClassname(null, "info_player_start")
			pos = info_player_start ? info_player_start.GetOrigin() : Vector(0, 0, 0)
		}
		propint(player, "m_iTeamNum", 2)
		propint(player, "m_iVersusTeam", 1)
		propint(player, "m_survivorCharacter", character)
		local death_model = SpawnEntityFromTable("survivor_death_model", {origin = pos})
		propint(death_model, "m_nCharacterType", character)
		player.ReviveByDefib()
		propint(player, "m_iClass", character + 1)
		propint(player, "m_zombieClass", 9)
		propfloat(player, "m_flCycle", 0.99)
		propint(player, "m_useActionOwner", -1)
		propint(player, "m_useActionTarget", -1)
		propint(player, "m_iCurrentUseAction", 0)
		player.GiveItem("health")
	}
	__allow_switch_for_now = function() {
		//it works strange
		cvar("vs_max_team_switches", 99999, RESTORE_ON_DISCONNECT)
		delayed_call("playable_team", 0.1 /* ? */, @()cvar("vs_max_team_switches", 0, RESTORE_ON_DISCONNECT))
	}
	on_change = function(old_state, new_state) {
		local old_survivors_playable = old_state ? (old_state & Teams.SURVIVORS) : true
		local old_infected_playable = old_state ? (old_state & Teams.INFECTED) : true
		local survivors_playable = new_state & Teams.SURVIVORS
		local infected_playable = new_state & Teams.INFECTED
		if (!survivors_playable && !infected_playable) {
			logf("[lib] server_settings.playable_team: wrong value %d, using Teams.ANY", new_state)
			survivors_playable = true
			infected_playable = true
		}
		if (!old_survivors_playable && !old_infected_playable) {
			old_survivors_playable = true
			old_infected_playable = true
		}
		remove_delayed_call_group("playable_team") //remove pending team changes
		if (old_survivors_playable && !survivors_playable) {
			//moving from survivors to infected
			cvar("mp_defaultteam", 3, RESTORE_ON_DISCONNECT)
			local gamemode = cvarstr("mp_gamemode")
			if (gamemode != "versus") { //use base gamemode instead?
				cvar("mp_gamemode", "versus")
				log("[lib] server_settings.playable_team: changing gamemode to versus")
				//although it's possible to move player to infected team even in coop mode
			}
			__allow_switch_for_now()
			foreach(player in players(Teams.SURVIVORS)) {
				if (!IsPlayerABot(player)) {
					client_command(player, "jointeam 3")
				}
			}
			register_callback("server_settings.playable_team", "player_team", function(params) {
				if (params.isbot) return
				if (params.disconnect) return
				if (params.team == 2) {
					local player = params.player
					delayed_call( 0.4, @()client_command(player, "jointeam 3") )
					logf("[lib] server_settings.playable_team: moving %s to infected", player_to_str(player))
				}
			})
		} else if (old_infected_playable && !infected_playable) {
			//movind from infected to survivors
			cvar("mp_defaultteam", 2, RESTORE_ON_DISCONNECT)
			__allow_switch_for_now()
			foreach(player in players(Teams.INFECTED)) {
				if (!IsPlayerABot(player)) {
					__try_move_to_survivors(player)
				}
			}
			register_callback("server_settings.playable_team", "player_team", function(params) {
				if (params.isbot) return
				if (params.disconnect) return
				if (params.team == 3) {
					local player = params.player
					delayed_call( "playable_team", 0.4, function() {
						__allow_switch_for_now()
						client_command(player, "jointeam 2")
						logf("[lib] server_settings.playable_team: moving %s to survivors", player_to_str(player))
					})
				}
			})
		} else if (survivors_playable && infected_playable) {
			if (cvarf("mp_defaultteam") != 0) cvar("mp_defaultteam", 0, RESTORE_ON_DISCONNECT)
			remove_callback("server_settings.playable_team", "player_team")
		}
	}
})

///////////////////////////////
// CUSTOM CALLBACKS
///////////////////////////////

new_custom_callback("bunnyhop_attempt", {
	__onSuccess = function(player, bhops_done, max_speed) {
		call_listners({
			player = player
			success = true
			jump_time_error = 0
			bhops_done = bhops_done
			max_speed = max_speed
		})
	}
	__onFail = function(player, bhops_done, max_speed, delta) {
		call_listners({
			player = player
			success = false
			jump_time_error = delta
			bhops_done = bhops_done
			max_speed = max_speed
		})
	}
	on_enable = function() {
		register_ticker("__bunnyhop_attempt", function() {
			foreach(player in players()) {
				local history_size = 3 //should be more than 0
				local player_scope = scope(player)
				local onGround = (NetProps.GetPropInt(player, "m_hGroundEntity") != -1)
				local inJump = (NetProps.GetPropInt(player, "m_nButtons") & 2)
				if (!("bunnyhops" in player_scope)) {
					player_scope.bunnyhops <- {
						bhops_done = 0
						max_speed = 0
						inJump_history = array(history_size * 2 + 3, false)
						onGround_history = array(history_size * 2 + 3, onGround)
					}
				}
				local bunnyhops = player_scope.bunnyhops
				local inJump_history = bunnyhops.inJump_history
				local onGround_history = bunnyhops.onGround_history
				inJump_history.pop()
				inJump_history.insert(0, inJump)
				onGround_history.pop()
				onGround_history.insert(0, onGround)
				local jump_delta = -1
				local wasJumpPressed = function(delta) {
					return (inJump_history[delta + jump_delta] && !inJump_history[delta + jump_delta + 1])
				}
				if (onGround_history[history_size + 1] && !onGround_history[history_size + 2]) {
					local current_speed = player.GetVelocity().Length2D()
					//landing history_delta ticks ago
					if (wasJumpPressed(history_size + 1)) {
						if (!onGround_history[history_size]) {
							bunnyhops.bhops_done++
							bunnyhops.max_speed = max(bunnyhops.max_speed, current_speed)
							__onSuccess(player, bunnyhops.bhops_done, bunnyhops.max_speed)
						} else {
							__onFail(player, bunnyhops.bhops_done, bunnyhops.max_speed, NAN)
						}
					} else {
						if (bunnyhops.bhops_done > 0)
							bunnyhops.max_speed = max(bunnyhops.max_speed, current_speed)
						local i
						for(i = 1; i <= history_size; i++) {
							if (wasJumpPressed(history_size + 1 + i)) {
								__onFail(player, bunnyhops.bhops_done, bunnyhops.max_speed, -i)
								break
							} else if (wasJumpPressed(history_size + 1 - i)) {
								__onFail(player, bunnyhops.bhops_done, bunnyhops.max_speed, i)
								break
							}
						}
						if (i > history_size)
							__onFail(player, bunnyhops.bhops_done, bunnyhops.max_speed, NAN)
						bunnyhops.bhops_done = 0
						bunnyhops.max_speed = 0
					}
				}
			}
		})
	}
	on_disable = function() {
		remove_ticker("__bunnyhop_attempt")
	}
	validate = function() {
		return loop_exists("__bunnyhop_attempt")
	}
})

new_custom_callback("bunnyhop_streak_end", {
	on_enable = function() {
		custom_callbacks.bunnyhop_attempt.register_listener("__bunnyhop_streak_end", function(params) {
			if (params.success) return
			call_listners({
				player = params.player
				bhops_done = params.bhops_done
				max_speed = params.max_speed
			})
		})
	}
	on_disable = function() {
		custom_callbacks.bunnyhop_attempt.remove_listener("__bunnyhop_streak_end")
	}
	validate = function() {
		return("__bunnyhop_streak_end" in custom_callbacks.bunnyhop_attempt.__listeners)
	}
})