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
		name = tolower(name)
		local cmd = "cmd_" + name
		if (cmd in __chat_cmds)
			logf("WARNING! chat command %s was already registered, overriding...", name)
		__chat_cmds[cmd] <- {
			func = func,
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