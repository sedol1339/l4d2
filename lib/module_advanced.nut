//---------- DOCUMENTATION ----------

/**
ADVANCED FUNCTIONS THAT USE TASKS
Warning! All tasks and callbacks are removed on round change.
! requires lib/module_base !
! requires lib/module_strings !
! requires lib/module_entities !
! requires lib/module_tasks !
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
------------------------------------
show_hud_hint_singleplayer(text, color, icon, binding, time)
	Shows hud hint to player.
	Example: show_hud_hint_singleplayer("Use reload or leave field to cancel.", Vector(255,255,255), null, "+reload", 2)
	Example: show_hud_hint_singleplayer("Use reload or leave field to cancel.", Vector(255,255,255), "icon_info", null, 2)
------------------------------------
autobhop.set(player_or_team, state)
	Enables or disables auto bunnyhop for player of whole team(s). State can be autobhop.ENABLED or autobhop.DISABLED for team and autobhop.ENABLED, autobhop.DISABLED or autobhop.UNDEFINED for player. Settings for players override team settings.
	Examples:
	autobhop.set(Team.ANY, autobhop.ENABLED) //enables bhop for all players
	autobhop.set(Ent(2), autobhop.DISABLED) //disables bhop for player with index 2, it overrides team bhop state
	autobhop.set(Ent(2), autobhop.UNDEFINED) //now player with index 2 will autobhop only if his whole team has bhop enabled
autobhop.method(method)
	Pass autobhop.PRECISE (default) or autobhop.SMOOTH as parameter. Smooth method use baseVelocity correction instead of simulating jump button press, it seems smoother even on local server, but may be not 100% accurate in some cases (TODO find this cases).
------------------------------------
bhop_instructor.set(player_or_team, state)
	Enables or disables auto bunnyhop instructor for player of whole team(s). Works just like autobhop.set().
bhop_instructor.onSuccessDefault(enabled)
	Here you can disable or enable default bhop_instructor behaviour on jump success (printing to chat). Default = enabled.
bhop_instructor.onFailDefault(enabled)
	Here you can disable or enable default bhop_instructor behaviour on jump fail (printing to chat). Default = enabled.
bhop_instructor.onSuccess(key, func)
	Here you can set custom handle function for bhop success. Key is required. Pass null to remove.
	Signature: function(player, bhops_in_a_row, max_speed)
	"bhops_in_a_row": total bhops in a row including this
	"max_speed": max speed of current bhop streak.
bhop_instructor.onFail(key, func)
	Here you can set custom handle function for bhop fail. Key is required. Pass null to remove.
	Signature: (player, prev_bhops_in_a_row, max_speed, delta)
	"prev_bhops_in_a_row": total bhops in a row, if last jump was a bhop
	"max_speed": max speed of previous bhop streak, if last jump was a bhop
	"delta": delta ticks between ideal bhop jump and this jump. If delta > 0, jump was too late, otherwise too early. If delta == NAN, this means that this was not a jump, just a landing after bhop streak.
	----------
	Example:
	bhop_instructor.set(Teams.ANY, bhop_instructor.ENABLED) //enable instructor for all players
	bhop_instructor.onFailDefault(false) //disabling default logging
	bhop_instructor.onSuccessDefault(false) //disabling default logging
	bhop_instructor.onFail("skillDetect", function(player, prev_bhops_in_a_row, max_speed, delta) {
		if (prev_bhops_in_a_row < 3) return
		say_chat(player.GetName() + " made " + prev_bhops_in_a_row + " bhops in a row (max speed: " + max_speed + ")")
	}) //setting custom listener for bhop streak finish
 */

//---------- CODE ----------

this = ::root

log("[lib] including module_advanced")

//uses Teams and ClientType tables from lib/base

on_player_team <- function(teams, isbot, func) {
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
}

remove_on_player_team <- function() {
	remove_callback("__on_player_team", "player_team");
	for (local team = 0; team <= 3; team++)
		for (local isbot = 0; isbot <= 1; isbot++)
			__on_player_team[team][isbot] = null;
}

if (!("__on_player_team" in this)) __on_player_team <- [
	[null, null], //Teams.UNASSIGNED
	[null, null], //Teams.SPECTATORS
	[null, null], //Teams.SURVIVORS
	[null, null], //Teams.INFECTED
];

reporter("on_player_team listeners", function() {
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

on_key_action <- function(key, player_or_team, keyboard_key, delay, on_pressed, on_released = null, on_hold = null) {
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
}

on_key_action_remove <- function(key) {
	remove_loop("__key_action_" + key)
	for_each_player( function(player) {
		player.ValidateScriptScope()
		local player_scope = player.GetScriptScope()
		local name_in_scope = "__last_buttons_" + key
		if (name_in_scope in player_scope)
			delete player_scope[name_in_scope]
	})
}

if (!("__chat_cmds" in this)) __chat_cmds <- {}

register_chat_command <- function(names, func, argmin = null, argmax = null, errmsg = null) {
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
			logf("WARNING! chat command %s was already registered, overriding...", name)
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
		logf("parsing args for chat command %s from player %s", command, player_to_str(params.player))
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
}

remove_chat_command <- function(names) {
	if (type(names) == "string") {
		names = [names]
	} else if (type(names) != "array") {
		throw "name should be string or array of strings"
	}
	foreach (name in names) {
		name = "cmd_" + tolower(name)
		if (!(name in __chat_cmds))
			logf("WARNING! chat command %s was not registered", name)
		else
			delete __chat_cmds[name]
	}
}

print_all_chat_commands <- function() {
	log("all chat commands registered with register_chat_command")
	logt(__chat_cmds)
}

reporter("Chat commands", function() {
	local cmds = []
	if (__chat_cmds.len() == 0) return
	foreach(cmd, table in __chat_cmds) {
		cmds.append(cmd.slice(4, cmd.len()))
	}
	log("\t" + concat(cmds, ", "))
})

show_hud_hint_singleplayer <- function(text, color, icon, binding, time) {
	log("showing tip: " + text + " [" + icon + " " + binding + " " + time + "]");
	cvar("gameinstructor_enable", 1);
	local hint = SpawnEntityFromTable("env_instructor_hint", {
		hint_static = "1",
		hint_caption = text,
		hint_color = color,
		hint_instance_type = 0,
	});
	if (binding) {
		hint.__KeyValueFromString("hint_icon_onscreen", "use_binding");
		hint.__KeyValueFromString("hint_binding", binding);
	} else {
		hint.__KeyValueFromString("hint_icon_onscreen", icon);
	}
	delayed_call(0.1, function() {
		DoEntFire("!self", "ShowHint", "", 0, null, hint);
		__current_hints[hint] <- true;
	})
	delayed_call(time, function() {
		hint.Kill();
		delete __current_hints[hint];
		if (__current_hints.len() != 0) return; //check if there are other simultaneously displayed hints
		cvar("gameinstructor_enable", 0);
	})
}

if (!("__current_hints" in this)) __current_hints <- {}

__check_jump_possibility <- function(player) { //may not work for custom models
	if (NetProps.GetPropInt(player, "movetype") != 2) return false
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
		if (model in __sequence_after_punch && __sequence_after_punch[model] == sequence) return false
		if (NetProps.GetPropInt(player, "m_isHangingFromLedge") == 1) return false //do we need this?
		return true //true?
	} else {
		if (NetProps.GetPropEntity(player, "m_pounceVictim") != null) return false
		if (NetProps.GetPropEntity(player, "m_carryVictim") != null) return false
		if (NetProps.GetPropEntity(player, "m_pummelVictim") != null) return false
		if (NetProps.GetPropEntity(player, "m_jockeyVictim") != null) return false
		if (NetProps.GetPropEntity(player, "m_tongueVictim") != null) return false
		local sequence = NetProps.GetPropInt(player, "m_nSequence")
		if (player.GetZombieType() == 6 && sequence == 5) return false //charging
		if (NetProps.GetPropInt(player, "m_flStamina") == 3000) return false //throwing rock or vomiting
		return true
	}
}

if (!("autobhop" in this)) autobhop <- {

	/* this values are used in logical expressions and shouldn't be changed */
	ENABLED = 1
	DISABLED = 0
	UNDEFINED = -1
	
	PRECISE = 10
	SMOOTH = 11
	__method = 10
	
	__code_running = false
	__players = {}
	__survivors = false
	__infected = false
	__teams = 0
	
	method = function(new_method) {
		if (new_method != autobhop.PRECISE && new_method != autobhop.SMOOTH)
			throw "autobhop.method(): method should be autobhop.PRECISE or autobhop.SMOOTH"
		if (__method != new_method) {
			foreach(player in players()) __onDisable(player)
			__method = new_method
		}
		log("auto bunnyhop method set to: autobhop." + ((new_method == PRECISE) ? "PRECISE" : "SMOOTH"))
	}
	
	__onTick = function(player) {
		if (__method == PRECISE) __onTickPrecise(player)
		else __onTickSmooth(player)
	}
	
	__onDisable = function(player) {
		if (__method == PRECISE) __onDisablePrecise(player)
		else __onDisableSmooth(player)
	}
	
	// method 1: m_afButtonDisabled
	
	__onTickPrecise = function(player) {
		//using NetProps for performance
		if (
			NetProps.GetPropInt(player, "m_hGroundEntity") == -1
			&& NetProps.GetPropInt(player, "movetype") == 2
		) {
			NetProps.SetPropInt(player, "m_afButtonDisabled", NetProps.GetPropInt(player, "m_afButtonDisabled") | 2)
		} else {
			NetProps.SetPropInt(player, "m_afButtonDisabled", NetProps.GetPropInt(player, "m_afButtonDisabled") & ~2)
		}
	}
	
	__onDisablePrecise = function(player) {
		propint(player, "m_afButtonDisabled", propint(player, "m_afButtonDisabled") & ~2)
	}
	
	//method 2: m_vecBaseVelocity
	
	__sequence_after_punch = {
		"models/survivors/survivor_gambler.mdl": 630
		"models/survivors/survivor_producer.mdl": 638
		"models/survivors/survivor_coach.mdl": 630
		"models/survivors/survivor_mechanic.mdl": 635
		"models/survivors/survivor_namvet.mdl": 538
		"models/survivors/survivor_teenangst.mdl": 547
		"models/survivors/survivor_manager.mdl": 538
		"models/survivors/survivor_biker.mdl": 541
	}
	
	__onTickSmooth = function(player) {
		if (
			NetProps.GetPropInt(player, "m_hGroundEntity") != -1
			&& (NetProps.GetPropInt(player, "m_nButtons") & 2)
			&& NetProps.GetPropInt(player, "movetype") == 2
			&& __check_jump_possibility(player)
		) {
			local ducked = NetProps.GetPropInt(player, "m_Local.m_bDucked")
			local velocity = Vector(0, 0, ducked ? 297.043 : 245.705)
			//no need to use m_nDuckTimeMsecs here, it's always 0 in flight
			NetProps.SetPropVector(player, "m_vecBaseVelocity", NetProps.GetPropVector(player, "m_vecBaseVelocity") + velocity)
			NetProps.SetPropEntity(player, "m_hGroundEntity", null)
		}
	}
	
	__onDisableSmooth = function(player) {
		//nothing
	}
	
	__is_any_bhoppers = function() {
		if (__survivors || __infected) return true
		foreach(player, state in __players)
			if (state == autobhop.ENABLED)
				return true
		return false
	}
	
	set = function(player_or_team, state) {
		if (typeof player_or_team == "integer") {
			local team = player_or_team
			local _state
			if (state == autobhop.DISABLED) _state = false
			else if (state == autobhop.ENABLED) _state = true
			else throw "autobhop.set(): state for team should be autobhop.DISABLED or autobhop.ENABLED"
			if (team & Teams.INFECTED) __infected = _state
			if (team & Teams.SURVIVORS) __survivors = _state
			__teams = (__infected ? Teams.INFECTED : 0) | (__survivors ? Teams.SURVIVORS : 0)
			if (!_state)
				foreach(player in players(team))
					if (!(player in __players) || __players[player] != autobhop.ENABLED)
						__onDisable(player)
		} else {
			local player = player_or_team
			if (state != autobhop.UNDEFINED) {
				__players[player] <- state
			} else {
				if (player in __players) delete __players[player]
			}
			if (
				state == autobhop.DISABLED
				|| (state == autobhop.UNDEFINED && !(__teams & get_team(player)))
			) {
				__onDisable(player)
			}
		}
		if (__code_running) {
			//checking if we should disable it
			if (!__is_any_bhoppers()) {
				__code_running = false
				remove_ticker("__autobhop")
			}
		} else {
			//checking if we should enable it
			if (__is_any_bhoppers()) {
				__code_running = true
				register_ticker("__autobhop", function() {
					if (!__survivors && !__infected) {
						foreach(player, state in __players) {
							if (state == autobhop.ENABLED) __onTick(player)
						}
					} else {
						foreach(player in players()) {
							local enabled = __teams & get_team(player)
							if (player in __players) {
								local state = __players[player]
								if (state != autobhop.UNDEFINED) enabled = state
							}
							if (enabled) __onTick(player)
						}
					}
				})
			}
		}
	}
}

reporter("Autobhop", function() {
	log("\tmethod: " + autobhop.__method + ", code_running: " + autobhop.__code_running
		+ ", is_any_bhoppers: " + autobhop.__is_any_bhoppers())
	log("\tsurvivors: " + autobhop.__survivors + ", infected: " + autobhop.__infected)
	local players_str_lines = []
	foreach(player, state in autobhop.__players) {
		local state_str
		if (state == autobhop.UNDEFINED) state_str = "UNDEFINED"
		else if (state == autobhop.ENABLED) state_str = "ENABLED"
		else if (state == autobhop.DISABLED) state_str = "DISABLED"
		else state_str = (state == null) ? "null" : state.tostring()
		players_str_lines.append(player_to_str(player) + ": " + state_str)
	}
	local players_str = (players_str_lines.len() > 0) ? concat(players_str_lines, ", ") : "empty"
	log("\tplayers: " + players_str)
})

if (!("bhop_instructor" in this)) bhop_instructor <- {

	/* this values are used in logical expressions and shouldn't be changed */
	ENABLED = 1
	DISABLED = 0
	UNDEFINED = -1
	
	__code_running = false
	__players = {}
	__survivors = false
	__infected = false
	__teams = 0
	
	__onSuccessDefault = function(player, bhops_in_a_row, max_speed) {
		say_chat("nice! " + bhops_in_a_row + " bhops in a row")
	}
	
	__onFailDefault = function(player, prev_bhops_in_a_row, max_speed, delta) {
		if (prev_bhops_in_a_row > 0)
			say_chat("done " + prev_bhops_in_a_row + " bhops in a row (max speed " + max_speed + ")")
		if (delta != NAN) { //NAN == NAN in squirrel
			if (delta > 0)
				say_chat("jump " + delta + " ticks earlier")
			else
				say_chat("jump " + -delta + " ticks later")
		}
	}
	
	__onSuccessDefaultEnabled = true
	__onFailDefaultEnabled = true
	
	__onSuccessCustom = {}
	__onFailCustom = {}
	
	__onSuccess = function(player, bhops_in_a_row, max_speed) {
		if (__onSuccessDefaultEnabled) __onSuccessDefault(player, bhops_in_a_row, max_speed)
		foreach(key, func in __onSuccessCustom) func(player, bhops_in_a_row, max_speed)
	}
	
	__onFail = function(player, prev_bhops_in_a_row, max_speed, delta) {
		if (__onFailDefaultEnabled) __onFailDefault(player, prev_bhops_in_a_row, max_speed, delta)
		foreach(key, func in __onFailCustom) func(player, prev_bhops_in_a_row, max_speed, delta)
	}
	
	onSuccessDefault = function(enabled) {
		__onSuccessDefaultEnabled = enabled
	}
	
	onFailDefault = function(enabled) {
		__onFailDefaultEnabled = enabled
	}
	
	onSuccess = function(key, func) {
		if (func) __onSuccessCustom[key] <- func
		else if (key in __onSuccessCustom) delete __onSuccessCustom[key]
	}
	
	onFail = function(key, func) {
		if (func) __onFailCustom[key] <- func
		else if (key in __onFailCustom) delete __onFailCustom[key]
	}
	
	__onTick = function(player) {
		local history_size = 3 //should be more than 0
		local player_scope = scope(player)
		local onGround = (NetProps.GetPropInt(player, "m_hGroundEntity") != -1)
		local inJump = (NetProps.GetPropInt(player, "m_nButtons") & 2)
		if (!("bhop_instructor" in player_scope)) {
			player_scope.bhop_instructor <- {
				bhops_done = 0
				max_speed = 0
				inJump_history = array(history_size * 2 + 3, false)
				onGround_history = array(history_size * 2 + 3, onGround)
			}
		}
		local bhop_instructor = player_scope.bhop_instructor
		local inJump_history = bhop_instructor.inJump_history
		local onGround_history = bhop_instructor.onGround_history
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
				if (__check_jump_possibility(player)) {
					bhop_instructor.bhops_done++
					bhop_instructor.max_speed = max(bhop_instructor.max_speed, current_speed)
					__onSuccess(player, bhop_instructor.bhops_done, bhop_instructor.max_speed)
				} else {
					__onFail(player, bhop_instructor.bhops_done, bhop_instructor.max_speed, NAN)
				}
			} else {
				if (bhop_instructor.bhops_done > 0)
					bhop_instructor.max_speed = max(bhop_instructor.max_speed, current_speed)
				local i
				for(i = 1; i <= history_size; i++) {
					if (wasJumpPressed(history_size + 1 + i)) {
						__onFail(player, bhop_instructor.bhops_done, bhop_instructor.max_speed, -i)
						break
					} else if (wasJumpPressed(history_size + 1 - i)) {
						__onFail(player, bhop_instructor.bhops_done, bhop_instructor.max_speed, i)
						break
					}
				}
				if (i > history_size)
					__onFail(player, bhop_instructor.bhops_done, bhop_instructor.max_speed, NAN)
				bhop_instructor.bhops_done = 0
				bhop_instructor.max_speed = 0
			}
		}
	}
	
	__onDisable = function(player) {
		delete scope(player).bhop_instructor
	}
	
	__is_any_bhoppers = function() {
		if (__survivors || __infected) return true
		foreach(player, state in __players)
			if (state == bhop_instructor.ENABLED)
				return true
		return false
	}
	
	set = function(player_or_team, state) {
		if (typeof player_or_team == "integer") {
			local team = player_or_team
			local _state
			if (state == bhop_instructor.DISABLED) _state = false
			else if (state == bhop_instructor.ENABLED) _state = true
			else throw "bhop_instructor.set(): state for team should be bhop_instructor.DISABLED or bhop_instructor.ENABLED"
			if (team & Teams.INFECTED) __infected = _state
			if (team & Teams.SURVIVORS) __survivors = _state
			__teams = (__infected ? Teams.INFECTED : 0) | (__survivors ? Teams.SURVIVORS : 0)
			if (!_state)
				foreach(player in players(team))
					if (!(player in __players) || __players[player] != bhop_instructor.ENABLED)
						__onDisable(player)
		} else {
			local player = player_or_team
			if (state != bhop_instructor.UNDEFINED) {
				__players[player] <- state
			} else {
				if (player in __players) delete __players[player]
			}
			if (
				state == bhop_instructor.DISABLED
				|| (state == bhop_instructor.UNDEFINED && !(__teams & get_team(player)))
			) {
				__onDisable(player)
			}
		}
		if (__code_running) {
			//checking if we should disable it
			if (!__is_any_bhoppers()) {
				__code_running = false
				remove_ticker("__bhop_instructor")
			}
		} else {
			//checking if we should enable it
			if (__is_any_bhoppers()) {
				__code_running = true
				register_ticker("__bhop_instructor", function() {
					if (!__survivors && !__infected) {
						foreach(player, state in __players) {
							if (state == bhop_instructor.ENABLED) __onTick(player)
						}
					} else {
						foreach(player in players()) {
							local enabled = __teams & get_team(player)
							if (player in __players) {
								local state = __players[player]
								if (state != bhop_instructor.UNDEFINED) enabled = state
							}
							if (enabled) __onTick(player)
						}
					}
				})
			}
		}
	}
}

reporter("Bhop instructor", function() {
	log("\tcode_running: " + bhop_instructor.__code_running
		+ ", is_any_bhoppers: " + bhop_instructor.__is_any_bhoppers())
	log("\tsurvivors: " + bhop_instructor.__survivors + ", infected: " + bhop_instructor.__infected)
	local players_str_lines = []
	foreach(player, state in bhop_instructor.__players) {
		local state_str
		if (state == bhop_instructor.UNDEFINED) state_str = "UNDEFINED"
		else if (state == bhop_instructor.ENABLED) state_str = "ENABLED"
		else if (state == bhop_instructor.DISABLED) state_str = "DISABLED"
		else state_str = (state == null) ? "null" : state.tostring()
		players_str_lines.append(player_to_str(player) + ": " + state_str)
	}
	local players_str = (players_str_lines.len() > 0) ? concat(players_str_lines, ", ") : "empty"
	log("\tplayers: " + players_str)
	//TODO listeners, default listener
})