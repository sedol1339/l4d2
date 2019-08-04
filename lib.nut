/*
 This file contains some useful functions.
 It can be run several times, nothing breaks.
 Performance is optimized where possible. This library does not create any entities, running tasks or affecting HUD by default (unless you run a specific library functions for this).
 
 Author: kapkan https://steamcommunity.com/id/xwergxz/
 Repository: https://github.com/sedol1339/l4d2
 TODO:
	- fix scopes issue
	- delayed_call_group(group_key, func, delay, ...) - for removing a group of delayed calls (for example in tr/core when finishing training)
	- tasks instead of chains: Task(on_start, on_tick, on_finish); chain(task_1, task_2, ...); on_tick = function(){ if (...) task_fihish() }
	- parenting function, more options to create_pacticles (cpoint1, cpoint2, ...?)
	- stop coding and live a real life
	- add "forced" support from line 1550
	- fix on_key_action for player, not team
 
 Short documentation:
 
 FUNCTIONS FOR LOGGING:
 log(str)						prints to console
 say_chat(str, ...)				prints to chat for all players; if more than one argument, using formatting like say_chat(format(str, ...))	
								this function uses multiple Say() statements to print long strings
 debug_enable()					enables debug (pass false to disable)
 debug(str)						prints string to console if debug=true
 debug_t(str)					prints string to console with \t if debug=true
 degug(func)					runs function if debug=true
 log_table(table|class|array)	dumps deep structure of table (better version of DeepPrintTable); additinal param: max_depth
 var_to_str(var)				converts any variable to string (better version of tostring())
 ent_to_str(ent)				converts entity to string (prints entity index and targetname)
 player_to_str(player)			converts player entity to string (prints entity index and player name)
 logv							shortcut for (log(var_to_str(var))
 loge							shortcut for (log(ent_to_str(entity))
 logp							shortcut for (log(player_to_str(player))
 logt							shortcut for log_table(table|class|array)
 logf							shortcut for log(format(str, ...)) bug: printf prints "%%" instead of "%"
 concat(array, sep)				connects string array using separator: ["a", "b", "c"] -> "a, b, c"
 vecstr2(vec)					vec to string (compact 2-digits representation): 0.00 1.00 -1.00
 vecstr3(vec)					vec to string (compact 3-digits representation): 0.000 1.000 -1.000
 tolower(str)					converts a string to lower case, supports english and russian symbols
 remove_quotes(str)				if string is enclosed in quotes, removes them
 
 MISC FUNCTIONS
 checktype(var, type)				throws exception if var is not of specified type;
									type can be string: "string", "float", "integer", "bool", "Vector", "array", "function", "native function" etc.
									type can be int constant: NUMBER (integer or float), FUNC (function or native function), STRING or BOOL constants
									type can be array of string types
 unique_str_id(ent)					converts entity to string, suitable for using as string key
 del(var, scope)					if var is in scope, deletes it
 
 TASK & CALLBACKS SHEDULING
 delayed_call(func, delay)					runs func after delay; pass scope or entity as additional param; returns key;
											see function declaration for more info
 run_this_tick(func)						runs function later (in this tick); second parameter can optionally be scope or ent
 run_next_tick(func)						runs function later (in next tick); second parameter can optionally be scope or ent
 register_ticker(key, func)					register a function that will be called every tick; example: register_ticker("my_key", @()log("tick"))
											if ticker function has a "return" statement and returns false, ticker will be removed
											inside ticker function you have access to the following parameters (changing them will not have effect):
											ticker_info.start_time		//time when current ticker loop started
											ticker_info.delta_time		//time elapsed since last ticker call
											ticker_info.ticks			//ticks elapsed since register_ticker (first call = 1 ticks)
											ticker_info.first_call 		//is it a first call of this ticker?
											!! if we register the same ticker again, ticker info will be reset !!
 register_callback(event, key, func)		registers callback for event using key; pass params table to func
											if event table has "userid" and/or "victim" params,
											they will be also accessible as entity handle: "player" and/or "player_victim", "player_attacker"
 add_task_on_shutdown(key, func)			register a function that will be called on server shutdown; pass true as additional param to run this after all others
 register_loop(key, func, refire_time)		register a function that will be called with an interval of refire_time seconds
 loop_reset(key)							reset loop using it's key; see function declaration for more info
											by default this will prevent loop from running this tick; if you don't want this, pass false as additional param
 loop_subtract_from_timer(key, time)		subtract time from loop timer (timer will trigger when it's time becomes 0)
 loop_add_to_timer(key, time)				add time to loop timer
											by default this will prevent loop from running this tick; if you don't want this, pass false as additional param
 loop_get_refire_time(key)					returns refire time for loop
 loop_set_refire_time(key, refire_time)		sets new refire time for loop
 register_task_on_entity(ent, func, delay)	registers a loop for entity (using AddThinkToEnt); pass REAL delay value in seconds; this is not chained
 on_player_connect(team, isbot, func)		register a callback for player_team event that will fire for specified team and params.isbot condition;
											this is not chained; pass null to cancel; see Team and ClientType tables for first 2 arguments
 register_chat_command(name, func)			registers a chat command (internally makes a callback for event player_say)
											name can be string or array of strings (this means same handler for different commands)
											name "testcmd" means that player types !testcmd or /testcmd in chat (both will work)
											func should have 4 parameters:
												player - player who issued command
												command - what command was called (without ! or /)
												args_text - all arguments as string
												args - all arguments as array (arguments are either enclosed in quotes or divided by spaces)
											example used input: !testcmd a b " c d"
											corresponding function call: func(player, "testcmd", "a b \" c d\"", ["a", "b", " c d"])
											user input cannot have nested quotes (\")
											commands may include unicode and are case-insensitive (only for english and russian letters)
											you can pass up to three optional params to register_chat_command:
												min - minimum number of arguments allowed (or null),
												max - maximum number of arguments allowed (or null),
												msg - message to print when arglen < min or arglen > max
 
 on_key_action(key, player|team, keyboard_key, delay, on_pressed, on_released, on_hold)
								on_pressed will be called when players presses specified keyboard_key
								on_released will be called when players releases specified keyboard_key
								on_hold (optional) will be called together with on_pressed and later until players releases key
								delay is a delay in seconds between checks (0 = every tick)
								key is used for on_key_action_remove()
								second param may be player entity or the whole team (see Team table)
 
 chain(key, func_1, func_2, ...)	chain functions call: call func_1, wait until chain_continue(key) will be called, then call next function etc.
 chain_continue(key)				continue chain using it's key
 
 TASK & CALLBACKS CANCELLING
 remove_delayed_call(key)		cancel delayed call using key
 remove_all_delayed_calls()		cancel all delayed calls
 remove_callback(event, key)	removes callback for event using key
 remove_all_callbacks()			removes all callbacks for all events
 remove_ticker(key)				removes ticker using it's key
 remove_all_tickers()			removes all tickers
 remove_task_on_shutdown(key)	removes task on shutdown using it's key
 remove_all_tasks_on_shutdown()	removes all tasks on shutdown
 remove_loop(key)				removes loop using key
 remove_task_on_entity(ent)		removes loop from entity
 remove_all_tasks_on_entities()	removes all loops from entities
 remove_on_player_connect()		clears all callbacks registered with on_player_connect
 remove_chat_command(name)		removes chat command, given name or array of names
 on_key_action_remove(key)		remove key action registered with on_key_action
 
 TASK & CALLBACKS LOGGING
 print_all_tasks()				prints ALL sheduled tasks (does not print tasks on entitites); specific functions are below
 print_all_delayed_calls()		prints all pending delayed calls
 print_all_callbacks()			prints all callbacks
 print_all_tickers()			prints all tickers
 print_all_tasks_on_shutdown()	prints all tasks on shutdown
 print_all_loops()				prints all loops
 print_all_chat_commands()		prings all chat commands
 
 DEVELOPMENT FUNCTIONS
 log_event(event)				start logging event; pass false as additional param to cancel
 log_events()					start logging all events; pass false as additional param to cancel
 watch_netprops(ent,[netprops])	for singleplayer: print entity netprops in real time in HUD and binds actions to save/restore them;
								see function declaration for more info
 draw_collision_box(ent, dur, color)	draws collision box for entity for duration //is drawing not all lines probably due to engine bug
 mark(ent, dur, color)					marks point, drawing a box for duration
 
 CONVARS FUNCTIONS
 cvar(cvar, value)				shortcut for Convars.SetValue(cvar, value); also makes logging
 cvarstr(cvar)					shortcut for Convars.GetStr
 cvarf(cvar)					shortcut for Convars.GetFloat
 cvarf_lim(cvar, min, max)		returns cvar, not letting it exceed min and max limits; for use with cvar_create(); min/max may be null 
 cvar_create(cvar, value)		performs "setinfo cvar value", this value can be retrieved or changed later using cvar(), cvarf(), cvarstr(); returns value
 cvars_add(cvar, default, new)	sets cvar to new value, stores default and new value in table
 cvars_reapply()				sets all cvars in table to their "new" values stored in table (useful if cvars have been reset after "sv_cheats 0")
 cvars_restore(cvar)			restores default cvar value from table (and remove cvar from table)
 cvars_restore_all()			restores default cvar values from table (and clears the table)
 
 MATH FUNCTIONS
 vector_to_angle(vec)			converts non-zero Vector to QAngle
 angle_between_vectors(v1, v2)	returns angle between non-zero Vectors in degrees
 trace_line(start, end)			does TraceLine, calculates table.hitpos and returns table; optional params: mask, ignore (see TraceLine documentation)
 normalize(vec)					normalizes non-zero vector
 ln(x)							natural logarifm (instead of log)
 min(a, b)						min of two numbers
 max(a, b)						max of two numbers
 roundf(a)						round float to int
 decompose_by_orthonormal_basis(vec, basis_x, basis_y, basis_z)		returns vector of coefficients
 linear_interp(x1, y1, x2, y2, clump_left = false, clump_right = false)
 quadratic_interp(x1, y1, x2, y2, x3, y3, clump_left = false, clump_right = false)
 bilinear_interp(x1, y1, x2, y2, x3, y3, clump_left = false, clump_right = false)
 
 CLOCK FUNCTIONS
 clock.sec()					returns engine time (stops if game is paused)
 clock.msec()					returns engine time * 1000
 clock.frames()					returns frame count (tied to FPS)
 clock.ticks()					return tick count (need to initialize first)
 clock.tick_counter_init()		initializes tick counter (register_ticker call will also do this)
 clock.evaluate_tickrate.start()	starts counting ticks
 clock.evaluate_tickrate.stop()		stops counting ticks and returns tickrate
 clock.evaluate_framerate.start()	starts counting frames
 clock.evaluate_framerate.stop()	stops counting frames and returns framerate (game shound not be paused!)
 
 ENTITY FUNCTIONS
 invalid(ent)					returns true if entity doesn't exist anymore or has never existed
 player()						for singleplayer: fast function that returns human player
 bot()							for testing: returns first found bot player
 server_host()					returns listenserver host player or null
								warning! may return null while server host is still connecting
 scope(player)					validates and returns player's scope
 for_each_player(func)			calls function for every player, passes player as param; better use "foreach(player in players())"
 players()						returns array of player entities, optionally pass team: players(Team.SURVIVORS | Team.SPECTATORS)
 get_team(player)				returns team of player (of Team enum)
 mapname()						returns current map name
 modename()						returns current mode name (including mutations)
 set_ability_cooldown(player, cooldown)		set cooldown for custom ability
 remove_dying_infected()		removes all infected bots that were killed recently and have death cam
 spawn_infected(type, pos)		spawns special infected and returns it, returns null if can't spawn
 teleport_entity(ent, pos, ang)	teleports entity (using point_teleport); pos == null means don't change pos, ang == null means don't change ang
 get_entity_flag(ent, flag)		returns entity flag; example: get_entity_flag(player(), FL_FROZEN)
 set_entity_flag(ent,flag,val)	sets entity flag; example: set_entity_flag(player(), FL_FROZEN, false)
 get_player_button(pl, btn)		returns true if specified button is pressed; example: get_player_button(player(), IN_JUMP)
 force_player_button(pl, btn)	forces button for player; pass false as additional param to release button
 kill_player(player)			kills player (increases revive count, then deals damage); for surv only if god=0; pass attacker as additional param
 client_command(player, cmd)	send command from player (using point_clientcommand)
 switch_to_infected(pl, class)	switches to infected and spaws as zombie class
 targetname_to_entity(name)		returns entity with given targetname or null; print warning if there are multiple entities with this targetname
 find_entities(classname)		find entities by classname (returns array)
 replace_primary_weapon(player, weapon)	replaces weapon in primary slot; pass true as additional argument to give laser sight
 drop_weapon(player, slot)
 create_particles(effect_name, origin_or_parent, duration = -1)
 
 NETPROPS FUNCTIONS
 propint(ent, prop[, value])	get/set integer offset
 propfloat(ent, prop[, value])	get/set float offset
 propstr(ent, prop[, value])	get/set string offset
 propvec(ent, prop[, value])	get/set Vector offset
 propent(ent, prop[, value])	get/set ehandle offset
								see also: watch_netprops()
 
 GAME LOGIC FUNCTIONS
 no_SI_with_death_cams()		will automatically remove infected bots with death cam; pass false as param to cancel
 restart_game()					retsarts round in 1 second; pass true as additional param to reset cvars (cvars_restore_all() & "sv_cheats 0")
 stop_director()				sets all director params to 0
 stop_director_forced()			sets all director params to 0 and runs director_stop
 show_hud_hint_singleplayer()	shows hud hint to player; see function declaration for more info
 is_hitscan_weapon(name)		given weapon name returns true if weapon is hitscan
 playsound(path, ent)			precaches and plays sound on entity; soundscripts or paths can be used; if you add sounds, buid sound cache first
 
 FILE FUNCTIONS (work with left4dead2/ems directory)
 file_read(filename)			reads file, returns string or null
 file_write(filename, str)		writes string to file, creates if not exist
 file_to_func(filename)			reads file, compiles script from it's contents, returns function or null
 file_append(filename, str)		appends string to the end of file
 
 HUD FUNCTIONS (see: L4D2_EMS/Appendix:_HUD) [timers can be used independently of HUD]
 hud.posess_slot(possessor, name)			take control over free slot; name - any number or string to name the slot (does not match real slot id,
											that is internal); return true (success) or false (no free slots)
 hud.release_slot(possessor, name)			release posessed slot (shot is getting hidden, becoming free to posess and you can't refer to it anymore)
 hud.set_position(possessor, name, x, y, w, h)	set slot position and dimensions; default is 0.1, 0.1, 0.3, 0.05
 hud.set_visible(possessor, name, visible)	draw or hide slot, last argument is boolean; by default slots are drawn when get posessed
 hud.set_text(possessor, name, text)		set static text for slot (clears datafunc, special, staticsctring)
 hud.set_datafunc(possessor, name, func)	sets datafunc for slot (clears static text, special, staticsctring)
 hud.set_special(possessor, name, value, is_prefix, text)	sets special value for slot (clears static text and datafunc)
											DOES NOT accept HUD_SPECIAL_TIMER*, use timer name as value
											last two arguments are optional: is_prefix may be hud.PREFIX( = true) or hud.POSTFIX( = false),
											text argument is your custom prefix or postfix
 
 hud.flags_set(possessor, name, flags)		set flags for slot (for example, HUD_FLAG_ALIGN_LEFT)
 hud.flags_add(possessor, name, flags)		add flags for slot
 hud.flags_remove(possessor, name, flags)	remove flags for slot
 
 hud.posess_timer(possessor, timer_name)	posess free timer, timer name should be string; return true (success) or false (no free slots); 
 hud.release_timer(possessor, timer_name)	release posessed timer (like releasing hud slots)
 hud.disable_timer(possessor, timer_name)	disables timer (--:-- will be shown), new timers are disabled by default
 hud.set_timer(possessor, timer_name, value)	sets timer value, does not start or stop timer (if timer is disabled, it will become paused)
 hud.start_timer_countup(possessor, timer_name)	starts timer, count up; does not change it's value (if it was disabled, 0:00 is default)
 hud.start_timer_countdown(possessor, timer_name)	starts timer, count down; does not change it's value (if it was disabled, 0:00 is default)
 hud.pause_timer(possessor, timer_name)		pauses timer; does not change it's value (if it was disabled, 0:00 is default)
 hud.get_timer(possessor, timer_name)		returns timer value as float
											
											use HUD_FLAG_ALLOWNEGTIMER slot flag to display negative timer values
											!! timer will work wrongly if slot does not allow negative, but timer once dropped below zero !!
											!! too lazy to fix this (need to add allow_negative field to timer table) !!

 hud.set_timer_callback(possessor, timer_name, value, func, stop_timer)	call func on specified timer value; if "stop" argument is true,
											stops timer on callback (optional, default is false); func may be null
 hud.remove_timer_callbacks(possessor, timer_name)	remove all registered timer callbacks
 
 hud.global_off()							don't render all HUD elements
 hud.global_on()							resume rendering of all HUD elements
 hud.global_clear()							release all posessed elements
 
 example HUD usage:							> hud.posess_timer("MyHUDInterface", "MyTimer")
											> hud.set_timer("MyHUDInterface", "MyTimer", 10)
											> hud.start_timer_countdown("MyHUDInterface", "MyTimer")
											> hud.set_timer_callback("MyHUDInterface", "MyTimer", 1, @()cvar("mp_restartgame", 1))
											> hud.posess_slot("MyHUDInterface", "MyTimerSlot")
											> hud.set_position("MyHUDInterface", "MyTimerSlot", 0.35, 0.75, 0.3, 0.05)
											> hud.set_special("MyHUDInterface", "MyTimerSlot", "MyTimer", hud.PREFIX, "Game is restarting in ")

 //hud.slot_exclude(slot)					excludes internal slot from hud system (will not be used or posessed) - for solving conflicts
 hud.show_message(text, duration, background, float_up, x, y, w, h)	shows message without posessing a slot
 
*/

///////////////////////////////

if (!("forced" in this)) forced <- false

local constants = getconsttable();

//director constants
constants.ALLOW_BASH_ALL <- 0;
constants.ALLOW_BASH_NONE <- 2;
constants.ALLOW_BASH_PUSHONLY <- 1;
constants.BOT_CANT_FEEL <- 4;
constants.BOT_CANT_HEAR <- 2;
constants.BOT_CANT_SEE <- 1;
constants.BOT_CMD_ATTACK <- 0;
constants.BOT_CMD_MOVE <- 1;
constants.BOT_CMD_RESET <- 3;
constants.BOT_CMD_RETREAT <- 2;
constants.BOT_QUERY_NOTARGET <- 1;
constants.DMG_BLAST <- 64;
constants.DMG_BLAST_SURFACE <- 134217728;
constants.DMG_BUCKSHOT <- 536870912;
constants.DMG_BULLET <- 2;
constants.DMG_BURN <- 8;
constants.DMG_HEADSHOT <- 1073741824;
constants.DMG_MELEE <- 2097152;
constants.DMG_STUMBLE <- 33554432;
constants.FINALE_CUSTOM_CLEAROUT <- 11;
constants.FINALE_CUSTOM_DELAY <- 10;
constants.FINALE_CUSTOM_PANIC <- 7;
constants.FINALE_CUSTOM_SCRIPTED <- 9;
constants.FINALE_CUSTOM_TANK <- 8;
constants.FINALE_FINAL_BOSS <- 5;
constants.FINALE_GAUNTLET_1 <- 0;
constants.FINALE_GAUNTLET_2 <- 3;
constants.FINALE_GAUNTLET_BOSS <- 16;
constants.FINALE_GAUNTLET_BOSS_INCOMING <- 15;
constants.FINALE_GAUNTLET_ESCAPE <- 17;
constants.FINALE_GAUNTLET_HORDE <- 13;
constants.FINALE_GAUNTLET_HORDE_BONUSTIME <- 14;
constants.FINALE_GAUNTLET_START <- 12;
constants.FINALE_HALFTIME_BOSS <- 2;
constants.FINALE_HORDE_ATTACK_1 <- 1;
constants.FINALE_HORDE_ATTACK_2 <- 4;
constants.FINALE_HORDE_ESCAPE <- 6;
constants.HUD_FAR_LEFT <- 7;
constants.HUD_FAR_RIGHT <- 8;
constants.HUD_FLAG_ALIGN_CENTER <- 512;
constants.HUD_FLAG_ALIGN_LEFT <- 256;
constants.HUD_FLAG_ALIGN_RIGHT <- 768;
constants.HUD_FLAG_ALLOWNEGTIMER <- 128;
constants.HUD_FLAG_AS_TIME <- 16;
constants.HUD_FLAG_BEEP <- 4;
constants.HUD_FLAG_BLINK <- 8;
constants.HUD_FLAG_COUNTDOWN_WARN <- 32;
constants.HUD_FLAG_NOBG <- 64;
constants.HUD_FLAG_NOTVISIBLE <- 16384;
constants.HUD_FLAG_POSTSTR <- 2;
constants.HUD_FLAG_PRESTR <- 1;
constants.HUD_FLAG_TEAM_INFECTED <- 2048;
constants.HUD_FLAG_TEAM_MASK <- 3072;
constants.HUD_FLAG_TEAM_SURVIVORS <- 1024;
constants.HUD_LEFT_BOT <- 1;
constants.HUD_LEFT_TOP <- 0;
constants.HUD_MID_BOT <- 3;
constants.HUD_MID_BOX <- 9;
constants.HUD_MID_TOP <- 2;
constants.HUD_RIGHT_BOT <- 5;
constants.HUD_RIGHT_TOP <- 4;
constants.HUD_SCORE_1 <- 11;
constants.HUD_SCORE_2 <- 12;
constants.HUD_SCORE_3 <- 13;
constants.HUD_SCORE_4 <- 14;
constants.HUD_SCORE_TITLE <- 10;
constants.HUD_SPECIAL_COOLDOWN <- 4;
constants.HUD_SPECIAL_MAPNAME <- 6;
constants.HUD_SPECIAL_MODENAME <- 7;
constants.HUD_SPECIAL_ROUNDTIME <- 5;
constants.HUD_SPECIAL_TIMER0 <- 0;
constants.HUD_SPECIAL_TIMER1 <- 1;
constants.HUD_SPECIAL_TIMER2 <- 2;
constants.HUD_SPECIAL_TIMER3 <- 3;
constants.HUD_TICKER <- 6;
constants.INFECTED_FLAG_CANT_FEEL_SURVIVORS <- 32768;
constants.INFECTED_FLAG_CANT_HEAR_SURVIVORS <- 16384;
constants.INFECTED_FLAG_CANT_SEE_SURVIVORS <- 8192;
constants.IN_ATTACK <- 1;
constants.IN_ATTACK2 <- 2048;
constants.IN_BACK <- 16;
constants.IN_CANCEL <- 64;
constants.IN_DUCK <- 4;
constants.IN_FORWARD <- 8;
constants.IN_JUMP <- 2;
constants.IN_LEFT <- 512;
constants.IN_RELOAD <- 8192;
constants.IN_RIGHT <- 1024;
constants.IN_USE <- 32;
constants.SCRIPTED_SPAWN_BATTLEFIELD <- 2;
constants.SCRIPTED_SPAWN_FINALE <- 0;
constants.SCRIPTED_SPAWN_POSITIONAL <- 3;
constants.SCRIPTED_SPAWN_SURVIVORS <- 1;
constants.SCRIPT_SHUTDOWN_EXIT_GAME <- 4;
constants.SCRIPT_SHUTDOWN_LEVEL_TRANSITION <- 3;
constants.SCRIPT_SHUTDOWN_MANUAL <- 0;
constants.SCRIPT_SHUTDOWN_ROUND_RESTART <- 1;
constants.SCRIPT_SHUTDOWN_TEAM_SWAP <- 2;
constants.SPAWNDIR_E <- 4;
constants.SPAWNDIR_N <- 1;
constants.SPAWNDIR_NE <- 2;
constants.SPAWNDIR_NW <- 128;
constants.SPAWNDIR_S <- 16;
constants.SPAWNDIR_SE <- 8;
constants.SPAWNDIR_SW <- 32;
constants.SPAWNDIR_W <- 64;
constants.SPAWN_ABOVE_SURVIVORS <- 6;
constants.SPAWN_ANYWHERE <- 0;
constants.SPAWN_BATTLEFIELD <- 2;
constants.SPAWN_BEHIND_SURVIVORS <- 1;
constants.SPAWN_FAR_AWAY_FROM_SURVIVORS <- 5;
constants.SPAWN_FINALE <- 0;
constants.SPAWN_IN_FRONT_OF_SURVIVORS <- 7;
constants.SPAWN_LARGE_VOLUME <- 9;
constants.SPAWN_NEAR_IT_VICTIM <- 2;
constants.SPAWN_NEAR_POSITION <- 10;
constants.SPAWN_NO_PREFERENCE <- -1;
constants.SPAWN_POSITIONAL <- 3;
constants.SPAWN_SPECIALS_ANYWHERE <- 4;
constants.SPAWN_SPECIALS_IN_FRONT_OF_SURVIVORS <- 3;
constants.SPAWN_SURVIVORS <- 1;
constants.SPAWN_VERSUS_FINALE_DISTANCE <- 8;
constants.STAGE_CLEAROUT <- 4;
constants.STAGE_DELAY <- 2;
constants.STAGE_ESCAPE <- 7;
constants.STAGE_NONE <- 9;
constants.STAGE_PANIC <- 0;
constants.STAGE_RESULTS <- 8;
constants.STAGE_SETUP <- 5;
constants.STAGE_TANK <- 1;
constants.TIMER_COUNTDOWN <- 2;
constants.TIMER_COUNTUP <- 1;
constants.TIMER_DISABLE <- 0;
constants.TIMER_SET <- 4;
constants.TIMER_STOP <- 3;
constants.TRACE_MASK_ALL <- -1;
constants.TRACE_MASK_NPC_SOLID <- 33701899;
constants.TRACE_MASK_PLAYER_SOLID <- 33636363;
constants.TRACE_MASK_SHOT <- 1174421507;
constants.TRACE_MASK_VISIBLE_AND_NPCS <- 33579137;
constants.TRACE_MASK_VISION <- 33579073;
constants.UPGRADE_EXPLOSIVE_AMMO <- 1;
constants.UPGRADE_INCENDIARY_AMMO <- 0;
constants.UPGRADE_LASER_SIGHT <- 2;
constants.ZOMBIE_BOOMER <- 2;
constants.ZOMBIE_CHARGER <- 6;
constants.ZOMBIE_HUNTER <- 3;
constants.ZOMBIE_JOCKEY <- 5;
constants.ZOMBIE_NORMAL <- 0;
constants.ZOMBIE_SMOKER <- 1;
constants.ZOMBIE_SPITTER <- 4;
constants.ZOMBIE_TANK <- 8;
constants.ZOMBIE_WITCH <- 7;
constants.ZSPAWN_MOB <- 10;
constants.ZSPAWN_MUDMEN <- 12;
constants.ZSPAWN_WITCHBRIDE <- 11;

//sourcemod entity_prop_stocks.inc constants (for "m_nRenderMode")
constants.RENDER_NORMAL <- 0;
constants.RENDER_TRANSCOLOR <- 1;
constants.RENDER_TRANSTEXTURE <- 2;
constants.RENDER_GLOW <- 3; //no Z buffer checks -- fixed size in screen space
constants.RENDER_TRANSALPHA <- 4;
constants.RENDER_TRANSADD <- 5;
constants.RENDER_ENVIRONMENTAL <- 6; //not drawn, used for environmental effects
constants.RENDER_TRANSADDFRAMEBLEND <- 7; //use a fractional frame value to blend between animation frames
constants.RENDER_TRANSALPHAADD <- 8;
constants.RENDER_WORLDGLOW <- 9; //same as kRenderGlow but not fixed size in screen space
constants.RENDER_NONE <- 10; //don't render

//renderfx constants (for "renderfx" keyvalue)
constants.RENDERFX_NONE <- 0;
constants.RENDERFX_PULSE_SLOW <- 1;
constants.RENDERFX_PULSE_FAST <- 2;
constants.RENDERFX_PULSE_SLOW_WIDE <- 3;
constants.RENDERFX_PULSE_FAST_WIDE <- 4;
constants.RENDERFX_FADE_SLOW <- 5;
constants.RENDERFX_FADE_FAST <- 6;
constants.RENDERFX_SOLID_SLOW <- 7;
constants.RENDERFX_SOLID_FAST <- 8;
constants.RENDERFX_STROBE_SLOW <- 9;
constants.RENDERFX_STROBE_FAST <- 10;
constants.RENDERFX_STROBE_FASTER <- 11;
constants.RENDERFX_FLICKER_SLOW <- 12;
constants.RENDERFX_FLICKER_FAST <- 13;
constants.RENDERFX_NO_DISSIPATION <- 14;
constants.RENDERFX_DISTORT <- 15;            /**< Distort/scale/translate flicker */
constants.RENDERFX_HOLOGRAM <- 16;           /**< kRenderFxDistort + distance fade */
constants.RENDERFX_EXPLODE <- 17;            /**< Scale up really big! */
constants.RENDERFX_GLOWSHELL <- 18;            /**< Glowing Shell */
constants.RENDERFX_CLAMP_MIN_SCALE <- 19;    /**< Keep this sprite from getting very small (SPRITES only!) */
constants.RENDERFX_ENV_RAIN <- 20;            /**< for environmental rendermode, make rain */
constants.RENDERFX_ENV_SNOW <- 21;            /**<  "        "            "    , make snow */
constants.RENDERFX_SPOTLIGHT <- 22;            /**< TEST CODE for experimental spotlight */
constants.RENDERFX_RAGDOLL <- 23;            /**< HACKHACK: TEST CODE for signalling death of a ragdoll character */
constants.RENDERFX_PULSE_FAST_WIDER <- 24;
constants.RENDERFX_MAX <- 25;
constants.RENDERFX_FADE_NEAR <- 26;

//player specific flag numbers from sourcemod entity_prop_stocks.inc (for "m_fFlags")
constants.FL_ONGROUND <- (1 << 0); //at rest/on the ground
constants.FL_DUCKING <- (1 << 1); //player is fully crouched
constants.FL_WATERJUMP <- (1 << 2); //player jumping out of water
constants.FL_ONTRAIN <- (1 << 3); //player is controlling a train, so movement commands should be ignored on client during prediction
constants.FL_INRAIN <- (1 << 4); //indicates the entity is standing in rain
constants.FL_FROZEN <- (1 << 5); //player is frozen for 3rd person camera
constants.FL_ATCONTROLS <- (1 << 6); //player can't move, but keeps key inputs for controlling another entity
constants.FL_CLIENT <- (1 << 7); //is a player
constants.FL_FAKECLIENT <- (1 << 8); //fake client, simulated server side; don't send network messages to them

//non-player specific flag numbers from sourcemod entity_prop_stocks.inc (for "m_fFlags")
constants.FL_INWATER <- (1 << 9); //in water
constants.FL_FLY <- (1 << 10); //changes the SV_Movestep() behavior to not need to be on ground
constants.FL_SWIM <- (1 << 11); //changes the SV_Movestep() behavior to not need to be on ground (but stay in water)
constants.FL_CONVEYOR <- (1 << 12);
constants.FL_NPC <- (1 << 13);
constants.FL_GODMODE <- (1 << 14);
constants.FL_NOTARGET <- (1 << 15);
constants.FL_AIMTARGET <- (1 << 16); //set if the crosshair needs to aim onto the entity
constants.FL_PARTIALGROUND <- (1 << 17); //not all corners are valid
constants.FL_STATICPROP <- (1 << 18); //eetsa static prop!
constants.FL_GRAPHED <- (1 << 19); //worldgraph has this ent listed as something that blocks a connection
constants.FL_GRENADE <- (1 << 20);
constants.FL_STEPMOVEMENT <- (1 << 21); //changes the SV_Movestep() behavior to not do any processing
constants.FL_DONTTOUCH <- (1 << 22); //doesn't generate touch functions, generates Untouch() for anything it was touching when this flag was set
constants.FL_BASEVELOCITY <- (1 << 23); //base velocity has been applied this frame (used to convert base velocity into momentum)
constants.FL_WORLDBRUSH <- (1 << 24); //not moveable/removeable brush entity (really part of the world, but represented as an entity for transparency or something)
constants.FL_OBJECT <- (1 << 25); //terrible name. This is an object that NPCs should see. Missiles, for example
constants.FL_KILLME <- (1 << 26); //this entity is marked for death -- will be freed by game DLL
constants.FL_ONFIRE <- (1 << 27); //you know...
constants.FL_DISSOLVING <- (1 << 28); //we're dissolving!
constants.FL_TRANSRAGDOLL <- (1 << 29); //in the process of turning into a client side ragdoll
constants.FL_UNBLOCKABLE_BY_PLAYER <- (1 << 30); //pusher that can't be blocked by the player
constants.FL_FREEZING <- (1 << 31); //we're becoming frozen!
constants.FL_EP2V_UNKNOWN1 <- (1 << 31); //unknown

//damage types from SDKHooks, partially collides with director constants
constants.DMG_GENERIC <- 0;
constants.DMG_CRUSH <- 1;
constants.DMG_BULLET <- 2;
constants.DMG_SLASH <- 4;
constants.DMG_BURN <- 8;
constants.DMG_VEHICLE <- 16;
constants.DMG_FALL <- 32;
constants.DMG_BLAST <- 64;
constants.DMG_CLUB <- 128;
constants.DMG_SHOCK <- 256;
constants.DMG_SONIC <- 512;
constants.DMG_ENERGYBEAM <- 1024;
constants.DMG_PREVENT_PHYSICS_FORCE <- 2048;
constants.DMG_NEVERGIB <- 4096;
constants.DMG_ALWAYSGIB <- 8192;
constants.DMG_DROWN <- 16384;
constants.DMG_PARALYZE <- 32768;
constants.DMG_NERVEGAS <- 65536;
constants.DMG_POISON <- 131072;
constants.DMG_RADIATION <- 262144;
constants.DMG_DROWNRECOVER <- 524288;
constants.DMG_ACID <- 1048576;
constants.DMG_SLOWBURN <- 2097152;
constants.DMG_REMOVENORAGDOLL <- 4194304;
constants.DMG_PHYSGUN <- 8388608;
constants.DMG_PLASMA <- 16777216;
constants.DMG_AIRBOAT <- 33554432;
constants.DMG_DISSOLVE <- 67108864;
constants.DMG_BLAST_SURFACE <- 134217728;
constants.DMG_DIRECT <- 268435456;
constants.DMG_BUCKSHOT <- 536870912;

//solid types m_nSolidType
constants.SOLID_NONE <- 0; // no solid model
constants.SOLID_BSP <- 1; // a BSP tree
constants.SOLID_BBOX <- 2; // an AABB
constants.SOLID_OBB <- 3; // an OBB (not implemented yet)
constants.SOLID_OBB_YAW <- 4; // an OBB, constrained so that it can only yaw
constants.SOLID_CUSTOM <- 5; // Always call into the entity for tests
constants.SOLID_VPHYSICS <- 6; // solid vphysics object, get vcollide from the model and collide with that

//extended buttons constants (for GetButtonMask(), "m_nButtons", "m_afButtonForced")
constants.IN_ATTACK <- (1 << 0);
constants.IN_JUMP <- (1 << 1);
constants.IN_DUCK <- (1 << 2);
constants.IN_FORWARD <- (1 << 3);
constants.IN_BACK <- (1 << 4);
constants.IN_USE <- (1 << 5);
constants.IN_CANCEL <- (1 << 6);
constants.IN_LEFT <- (1 << 7);
constants.IN_RIGHT <- (1 << 8);
constants.IN_MOVELEFT <- (1 << 9);
constants.IN_MOVERIGHT <- (1 << 10);
constants.IN_ATTACK2 <- (1 << 11);
constants.IN_RUN <- (1 << 12);
constants.IN_RELOAD <- (1 << 13);
constants.IN_ALT1 <- (1 << 14);
constants.IN_ALT2 <- (1 << 15);
constants.IN_SCORE <- (1 << 16);   // Used by client.dll for when scoreboard is held down
constants.IN_SPEED <- (1 << 17);	// Player is holding the speed key (+speed, or shift in L4D2)
constants.IN_WALK <- (1 << 18);	// Player holding walk key
constants.IN_ZOOM <- (1 << 19);	// Zoom key for HUD zoom
constants.IN_WEAPON1 <- (1 << 20);	// weapon defines these bits
constants.IN_WEAPON2 <- (1 << 21);	// weapon defines these bits
constants.IN_BULLRUSH <- (1 << 22);
constants.IN_GRENADE1 <- (1 << 23);	// grenade 1
constants.IN_GRENADE2 <- (1 << 24);	// grenade 2
constants.IN_ATTACK3 <- (1 << 25);

// (for "movetype")
constants.MOVETYPE_NONE <- 0; //Don't move
constants.MOVETYPE_ISOMETRIC <- 1; //For players, in TF2 commander view, etc
constants.MOVETYPE_WALK <- 2; //Player only, moving on the ground
constants.MOVETYPE_STEP <- 3; //Monster/NPC movement
constants.MOVETYPE_FLY <- 4; //Fly, no gravity
constants.MOVETYPE_FLYGRAVITY <- 5; //Fly, with gravity
constants.MOVETYPE_VPHYSICS <- 6; //Physics movetype
constants.MOVETYPE_PUSH <- 7; //No clip to world, but pushes and crushes things
constants.MOVETYPE_NOCLIP <- 8; //Noclip
constants.MOVETYPE_LADDER <- 9; //For players, when moving on a ladder
constants.MOVETYPE_OBSERVER <- 10; //Spectator movetype. DO NOT use this to make player spectate
constants.MOVETYPE_CUSTOM <- 11; //Custom movetype, can be applied to the player to prevent the default movement code from running, while still calling the related hooks

//for trigger spawnflags
constants.SF_TRIGGER_ALLOW_CLIENTS <- 0x01		// Players can fire this trigger
constants.SF_TRIGGER_ALLOW_NPCS <- 0x02		// NPCS can fire this trigger
constants.SF_TRIGGER_ALLOW_PUSHABLES <- 0x04		// Pushables can fire this trigger
constants.SF_TRIGGER_ALLOW_PHYSICS <- 0x08		// Physics objects can fire this trigger
constants.SF_TRIGGER_ONLY_PLAYER_ALLY_NPCS <- 0x10		// *if* NPCs can fire this trigger, this flag means only player allies do so
constants.SF_TRIGGER_ONLY_CLIENTS_IN_VEHICLES <- 0x20		// *if* Players can fire this trigger, this flag means only players inside vehicles can 
constants.SF_TRIGGER_ALLOW_ALL <- 0x40		// Everything can fire this trigger EXCEPT DEBRIS!
constants.SF_TRIGGER_ONLY_CLIENTS_OUT_OF_VEHICLES <- 0x200	// *if* Players can fire this trigger, this flag means only players outside vehicles can 
constants.SF_TRIG_PUSH_ONCE <- 0x80		// trigger_push removes itself after firing once
constants.SF_TRIG_PUSH_AFFECT_PLAYER_ON_LADDER <- 0x100	// if pushed object is player on a ladder, then this disengages them from the ladder (HL2only)
constants.SF_TRIG_TOUCH_DEBRIS <- 0x400	// Will touch physics debris objects
constants.SF_TRIGGER_ONLY_NPCS_IN_VEHICLES <- 0x800	// *if* NPCs can fire this trigger, only NPCs in vehicles do so (respects player ally flag too)
constants.SF_TRIGGER_DISALLOW_BOTS <- 0x1000   // Bots are not allowed to fire this trigger

//m_CollisionGroup
constants.COLLISION_GROUP_NONE <- 0	//Normal
constants.COLLISION_GROUP_DEBRIS <- 1	//Collides with nothing but world and static stuff
constants.COLLISION_GROUP_DEBRIS_TRIGGER <- 2	//Same as debris, but hits triggers. Useful for an item that can be shot, but doesn't collide.
constants.COLLISION_GROUP_INTERACTIVE_DEBRIS <- 3	//Collides with everything except other interactive debris or debris
constants.COLLISION_GROUP_INTERACTIVE <- 4	//Collides with everything except interactive debris or debris
constants.COLLISION_GROUP_PLAYER <- 5	
constants.COLLISION_GROUP_BREAKABLE_GLASS <- 6	//NPCs can see straight through an Entity with this applied.
constants.COLLISION_GROUP_VEHICLE <- 7	
constants.COLLISION_GROUP_PLAYER_MOVEMENT <- 8	//For HL2, same as Collision_Group_Player, for TF2, this filters out other players and CBaseObjects
constants.COLLISION_GROUP_NPC <- 9	
constants.COLLISION_GROUP_IN_VEHICLE <- 10	//Doesn't collide with anything, no traces
constants.COLLISION_GROUP_WEAPON <- 11	//Doesn't collide with players and vehicles
constants.COLLISION_GROUP_VEHICLE_CLIP <- 12	//Only collides with vehicles
constants.COLLISION_GROUP_PROJECTILE <- 13	
constants.COLLISION_GROUP_DOOR_BLOCKER <- 14	//Blocks entities not permitted to get near moving doors
constants.COLLISION_GROUP_PASSABLE_DOOR <- 15	//Let's the Player through, nothing else.
constants.COLLISION_GROUP_DISSOLVING <- 16	//Things that are dissolving are in this group
constants.COLLISION_GROUP_PUSHAWAY <- 17	//Nonsolid on client and server, pushaway in player code
constants.COLLISION_GROUP_NPC_ACTOR <- 18	
constants.COLLISION_GROUP_NPC_SCRIPTED <- 19	
constants.COLLISION_GROUP_WORLD <- 20	//Doesn't collide with players/props

//movecollide
constants.MOVECOLLIDE_DEFAULT <- 0,
// These ones only work for MOVETYPE_FLY + MOVETYPE_FLYGRAVITY
constants.MOVECOLLIDE_FLY_BOUNCE <- 1,	// bounces, reflects, based on elasticity of surface and object - applies friction (adjust velocity)
constants.MOVECOLLIDE_FLY_CUSTOM <- 2,	// Touch() will modify the velocity however it likes
constants.MOVECOLLIDE_FLY_SLIDE <- 3,  // slides along surfaces (no bounce) - applies friciton (adjusts velocity)

//m_usSolidFlags
constants.FSOLID_CUSTOMRAYTEST <- 1	//Ignore solid type + always call into the entity for ray tests
constants.FSOLID_CUSTOMBOXTEST <- 2	//Ignore solid type + always call into the entity for swept box tests
constants.FSOLID_NOT_SOLID <- 4	//The object is currently not solid
constants.FSOLID_TRIGGER <- 8	//This is something may be collideable but fires touch functions even when it's not collideable (when the FSOLID_NOT_SOLID flag is set)
constants.FSOLID_NOT_STANDABLE <- 16	//The player can't stand on this
constants.FSOLID_VOLUME_CONTENTS <- 32	//Contains volumetric contents (like water)
constants.FSOLID_FORCE_WORLD_ALIGNED <- 64	//Forces the collision representation to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
constants.FSOLID_USE_TRIGGER_BOUNDS <- 128	//Uses a special trigger bounds separate from the normal OBB
constants.FSOLID_ROOT_PARENT_ALIGNED <- 256	//Collisions are defined in root parent's local coordinate space
constants.FSOLID_TRIGGER_TOUCH_DEBRIS <- 512	//This trigger will touch debris objects

//m_iAddonBits - which items to show on a player
constants.CSAddon_NONE <- 0
constants.CSAddon_Flashbang1 <- (1 << 0)
constants.CSAddon_Flashbang2 <- (1 << 1)
constants.CSAddon_HEGrenade <- (1 << 2)
constants.CSAddon_SmokeGrenade <- 1 << 3)
constants.CSAddon_C4 <- (1 << 4)
constants.CSAddon_DefuseKit <- (1 << 5)
constants.CSAddon_PrimaryWeapon <- (1 << 6)
constants.CSAddon_SecondaryWeapon <- (1 << 7)
constants.CSAddon_Holster <- (1 << 8)

//look https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/public/const.h for other constants

constants.NUMBER <- -1
constants.FUNC <- -2
constants.STRING <- -3
constants.BOOL <- -4

constants.DEFAULT_TICKRATE <- 30.0

constants.INF <- 10e100000000

constants.RAD_TO_DEG <- 57.2957795

//g_ModeScript.InjectTable(constants, this); //may be null
foreach (constant, value in constants)
	this[constant] <- value

///////////////////////////////

local overwrite_lib
if (!("__lib" in this)) {
	overwrite_lib = false
	if (this == getroottable())
		ln <- log; //logarifm
		
	//the following is currently used only for tasks on shutdown
	__lib <- UniqueString(); //identifier
	if (!("__lib_scopes" in getroottable()))
		::__lib_scopes <- {};
	::__lib_scopes[__lib] <- this;
} else {
	overwrite_lib = true
}

///////////////////////////////

log <- printl

say_chat <- function(message, ...) {
	if (vargv.len() > 0) {
		local args = [this, message]
		args.extend(vargv)
		message = format.acall(args)
	}
	local MAX_LENGTH = 200
	for (local i = 0; i < message.len(); i += MAX_LENGTH)
		Say(null, message.slice(i, min(message.len(), i + MAX_LENGTH)), false)
	//TODO break by words
}

is_debug <- false

debug_enable <- function(enable = true) {
	is_debug = enable
}

debug <- function(str_or_func) {
	if (is_debug) {
		if (typeof(str_or_func) == "function" || typeof(str_or_func) == "native function")
			str_or_func()
		else
			log(str_or_func)
	}
}

debug_t <- function(str) {
	if (is_debug) { print("\t"); printl(str) }
}

degug <- function(func) {
	if (is_debug) func()
}

/* for example output: log_table(getroottable()) */
log_table <- function(table, max_depth = 3, current_depth = 0, manual_call = true, original_table = null) {
	local function indents(n) {
		local str = "";
		for (local i = 0; i < n; i++) str += "\t";
		return str;
	}
	if (!table) {
		printl("null");
		return;
	}
	if (typeof(table) != "table" && typeof(table) != "array" && typeof(table) != "class") {
		printl(format("[%s: not a table, array or class]", typeof(table)));
		if (manual_call)
			printl("trying anyway");
		else
			return;
	}
	if (table == getroottable() && !manual_call) {
		printl("[root table]");
		return;
	}
	if (current_depth != 0 && table == original_table) {
		printl("[circular reference to original table]");
		return;
	}
	if (!original_table)
		original_table = table;
	local total_count = 0;
	foreach(value in table) total_count++;
	if (total_count == 0) {
		printl(format("[empty %s]", typeof(table)));
		return;
	}
	if (max_depth == current_depth || (!manual_call && total_count > 200)) {
		printl(format("[%s with %d elements]", typeof(table), total_count));
		return;
	}
	printl(typeof(table) + ": ");
	foreach(key, value in table) {
		print(indents(current_depth + 1));
		print(var_to_str(key) + ": ");
		if (typeof(value) == "table" || typeof(value) == "array" || typeof(value) == "class")
			log_table(value, max_depth, current_depth + 1, false, original_table);
		else printl(var_to_str(value));
	}
}

player_to_str <- function(player) {
	if (invalid(player)) return "(deleted entity)";
	return format("(player %d | %s)", player.GetEntityIndex().tointeger(), player.GetPlayerName());
}

ent_to_str <- function(ent) {
	if (invalid(ent)) return "(deleted entity)";
	local id = ent.GetEntityIndex().tointeger();
	if ("CTerrorPlayer" in getroottable() && ent instanceof ::CTerrorPlayer)
		return player_to_str(ent);
	else {
		local name = ent.GetName();
		if (name == "")
			return format("(%s %d)", ent.GetClassname(), id);
		else
			return format("(%s %d | %s)", ent.GetClassname(), id, ent.GetName());
	}
}

var_to_str <- function(var) {
	if (var == null) return "null";
	// CBaseEntity and CTerrorPlayer do not exist until we instantiate them
	if ("CBaseEntity" in getroottable() && var instanceof ::CBaseEntity)
		return ent_to_str(var);
	if (typeof(var) == "string") return "\"" + var + "\"";
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
			return "<type " + n + ">";
		}
		local infos = var.getinfos();
		local params_arr = [];
		if ("parameters" in infos && infos.parameters != null)
			for(local i = 1; i < infos.parameters.len(); i++)
				params_arr.push(infos.parameters[i].tostring());
		else if ("typecheck" in infos && infos.typecheck != null)
			for(local i = 1; i < infos.typecheck.len(); i++)
				params_arr.push(typemask(infos.typecheck[i]));
		return format("%s(%s)", typeof(var), connect_strings(params_arr, ", "));
	}
	if (typeof(var) == "class") return "class";
	if (typeof(var) == "table") return "table";
	if (typeof(var) == "array") return "array";
	if (typeof(var) == "instance") return "instance";
	return var.tostring();
}

logv <- @(var) log(var_to_str(var));

loge <- @(var) log(ent_to_str(var));

logp <- @(var) log(player_to_str(var));

logt <- log_table;

logf <- function(str, ...) {
	local args = [this, str];
	args.extend(vargv);
	log(format.acall(args));
}

concat <- function(arr, separator) {
	local str = "";
	for (local i = 0; i < arr.len(); i++)
		str += arr[i] + ((i != arr.len() - 1) ? separator : "");
	return str;
}

connect_strings <- concat //backward compatibility

vecstr2 <- function(vec) {
	local digits = [vec.x, vec.y, vec.z]
	foreach (i, digit in digits) if (digit == -0) digits[i] = 0
	return format("%.2f %.2f %.2f", digits[0], digits[1], digits[2])
}

vecstr3 <- function(vec) {
	local digits = [vec.x, vec.y, vec.z]
	foreach (i, digit in digits) if (digit == -0) digits[i] = 0
	return format("%.3f %.3f %.3f", digits[0], digits[1], digits[2])
}

tolower <- function(str) {
	//currently supports only english and russian letters
	//extendable by this script: https://pastebin.com/26j2zJAg
	local unicode_tolower = {
		"\xFFD0\xFF90": "\xFFD0\xFFB0",
		"\xFFD0\xFF91": "\xFFD0\xFFB1",
		"\xFFD0\xFF92": "\xFFD0\xFFB2",
		"\xFFD0\xFF93": "\xFFD0\xFFB3",
		"\xFFD0\xFF94": "\xFFD0\xFFB4",
		"\xFFD0\xFF95": "\xFFD0\xFFB5",
		"\xFFD0\xFF81": "\xFFD1\xFF91",
		"\xFFD0\xFF96": "\xFFD0\xFFB6",
		"\xFFD0\xFF97": "\xFFD0\xFFB7",
		"\xFFD0\xFF98": "\xFFD0\xFFB8",
		"\xFFD0\xFF99": "\xFFD0\xFFB9",
		"\xFFD0\xFF9A": "\xFFD0\xFFBA",
		"\xFFD0\xFF9B": "\xFFD0\xFFBB",
		"\xFFD0\xFF9C": "\xFFD0\xFFBC",
		"\xFFD0\xFF9D": "\xFFD0\xFFBD",
		"\xFFD0\xFF9E": "\xFFD0\xFFBE",
		"\xFFD0\xFF9F": "\xFFD0\xFFBF",
		"\xFFD0\xFFA0": "\xFFD1\xFF80",
		"\xFFD0\xFFA1": "\xFFD1\xFF81",
		"\xFFD0\xFFA2": "\xFFD1\xFF82",
		"\xFFD0\xFFA3": "\xFFD1\xFF83",
		"\xFFD0\xFFA4": "\xFFD1\xFF84",
		"\xFFD0\xFFA5": "\xFFD1\xFF85",
		"\xFFD0\xFFA6": "\xFFD1\xFF86",
		"\xFFD0\xFFA7": "\xFFD1\xFF87",
		"\xFFD0\xFFA8": "\xFFD1\xFF88",
		"\xFFD0\xFFA9": "\xFFD1\xFF89",
		"\xFFD0\xFFAA": "\xFFD1\xFF8A",
		"\xFFD0\xFFAB": "\xFFD1\xFF8B",
		"\xFFD0\xFFAC": "\xFFD1\xFF8C",
		"\xFFD0\xFFAD": "\xFFD1\xFF8D",
		"\xFFD0\xFFAE": "\xFFD1\xFF8E",
		"\xFFD0\xFFAF": "\xFFD1\xFF8F",
	}
	//unfurtunately blobs are not supported
	str = str.tolower()
	local newstr = ""
	local has_unicode = false
	for(local i = 0; i < str.len(); i++) {
		local symbol = str[i]
		if (symbol < 0) {
			has_unicode = true
			break
		}
	}
	if (!has_unicode)
		return str
	for(local i = 0; i < str.len(); i++) {
		local symbol = str[i]
		if (symbol >= 0) {
			newstr += symbol.tochar()
		} else {
			if (i == str.len() - 1)
				throw "unfinished unicode string: last char have negative code"
			local symbol_next = str[++i]
			local unicode_char = symbol.tochar() + symbol_next.tochar()
			if (unicode_char in unicode_tolower)
				unicode_char = unicode_tolower[unicode_char]
			newstr += unicode_char
		}
	}
	return newstr
}

remove_quotes <- function(str) {
	if (str.slice(0, 1) == "\"" && str.slice(str.len() - 1) == "\"")
		return str.slice(1, str.len() - 1)
	return str
}

__printstackinfos <- function() {
	local i = 2;
	local stackinfos = null;
	while(true) {
		stackinfos = getstackinfos(i);
		if (!stackinfos) break;
		local src_tokens = split(stackinfos.src, "/");
		logf("\t<%s>: line %s", src_tokens[src_tokens.len() - 1], stackinfos.line.tostring());
		i++;
	}
}

checktype <- function(var, _type) {
	local typeof_var = typeof(var)
	local function throw_invalid_type() {
		throw "invalid variable type: " + typeof_var
	}
	if (typeof(_type) == "string") {
		if (typeof_var != _type) throw_invalid_type()
	} else if (typeof(_type) == "array") {
		foreach(_type_entry in _type)
			if (typeof_var == _type_entry)
				return
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
}

unique_str_id <- function(ent) {
	return ent.GetEntityHandle().tointeger()
}

del <- function(var, scope) {
	if (var in scope)
		delete scope[var]
}

//////////////////////////

/*

 Set(element, element, ...)			creates a Set of elements
 Set.add(element, element, ...)		adds element(s) to set
 Set.remove(element, element, ...)	removes element(s) from set
									check if element is in set: if (element in set) ...
									iterate over set: foreach (element in set) ...
									don't do this: foreach (key, element in set) - key will always be null

 PROBLEM: can't find a way to make "in" operator work, class is unfinished

Set <- class {
	__data = null
	constructor(...) {
		__data = {}
		foreach (element in vargv)
			__data[element] <- true
	}
	function _nexti(prev_index) { //prev_index is null on iteration start
		if (prev_index == null) return "a"
		if (prev_index == "a") return "b"
		if (prev_index == "b") return "c"
		if (prev_index == "c") return null
	}
	function _get(index) {
		if (index == "a") return "A"
		if (index == "b") return "B"
		if (index == "c") return "C"
		throw null //according to documentation
	}
}

*/

//////////////////////////

if (!("__chains" in this) || forced) __chains <- {};

chain <- function(key, ...) {
	__chains[key] <- {
		index = 0,
		functions = clone vargv
	}
	chain_continue(key)
}

chain_continue <- function(key) {
	if (!(key in __chains)) return
	local chain_table = __chains[key]
	local chain_len = chain_table.functions.len()
	local chain_index = chain_table.index
	if (chain_index >= chain_len) {
		delete __chains[key]
	} else {
		local func = chain_table.functions[chain_index]
		run_next_tick(func)
		chain_table.index = chain_index + 1
		if (chain_index == chain_len - 1)
			delete __chains[key]
	}
}

///////////////////////////////

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

if (!("cvars_list" in this) || forced) cvars_list <- {};

cvars_add <- function(_cvar, default_value, value) {
	cvar(_cvar, value);
	cvars_list[_cvar] <- { default_value = default_value, value = value };
}

cvars_reapply <- function() {
	foreach (_cvar, table in cvars_list)
		cvar(_cvar, table.value);
}

cvars_restore <- function(_cvar) {
	if (!(_cvar in cvars_list)) throw "Cvar is not in list: " + _cvar;
	if (cvars_list[_cvar].default_value)
		cvar(_cvar, cvars_list[_cvar].default_value)
	delete cvars_list[_cvar];
}

cvars_restore_all <- function() {
	foreach(_cvar, table in cvars_list)
		if (cvars_list[_cvar].default_value)
			cvar(_cvar, table.default_value);
	cvars_list <- {};
}

///////////////////////////////

invalid <- function(ent) {
	if (!("IsValid" in ent)) return true;
	return !ent.IsValid();
}

deleted_ent <- invalid //legacy

/* returns single player */
player <- function() {
	if (__player) return __player;
	local ent = null;
	while (ent = Entities.FindByClassname(ent, "player")){
		if (ent && !IsPlayerABot(ent)) {
			__player = ent;
			return ent;
		}
	}
}

__player <- null;

//returns first found bot player
bot <- function() {
	local ent = null;
	while (ent = Entities.FindByClassname(ent, "player")){
		if (ent && IsPlayerABot(ent)) {
			return ent;
		}
	}
}

server_host <- function() {
	if (__server_host) return __server_host;
	local terror_player_manager = Entities.FindByClassname(null, "terror_player_manager")
	for (local i = 0; i <= 32; i++)
		if (NetProps.GetPropIntArray(terror_player_manager, "m_listenServerHost", i)) {
			local player = EntIndexToHScript(i)
			__server_host = player
			return player
		}
}

__server_host <- null;

scope <- function(player) {
	player.ValidateScriptScope()
	return player.GetScriptScope()
}

for_each_player <- function (func) {
	local tmp_player = null;
	while (tmp_player = Entities.FindByClassname(tmp_player, "player"))
		if (tmp_player) func(tmp_player);
}

//cant' use constants or enums, because vm don't see them from
//other files if we IncludeScript() this library into them

Team  <-{
	ANY = -1
	UNASSIGNED = 1 << 0
	SPECTATORS = 1 << 1
	SURVIVORS = 1 << 2
	INFECTED = 1 << 3
}

players <- function (teams = Team.ANY) {
	local player = null
	local arr = []
	while (player = Entities.FindByClassname(player, "player")) {
		if (get_team(player) & teams)
			arr.push(player)
	}
	return arr
}

get_team <- function(player) {
	return 1 << propint(player, "m_iTeamNum")
}

mapname <- function() {
	return SessionState.MapName
}

modename <- function() {
	return cvarstr("mp_gamemode")
}

set_ability_cooldown <- function(player, cooldown) {
	local ability = propent(player, "m_customAbility")
	propfloat(ability, "m_nextActivationTimer.m_timestamp", clock.sec() + cooldown)
	propfloat(ability, "m_nextActivationTimer.m_duration", cooldown)
}

//kill bots with death camera
remove_dying_infected <- function() {
	for_each_player(function(player){
		if (!player.IsSurvivor() && player.IsDying() && IsPlayerABot(player))
			player.Kill();
	});
}

//auto remove bot infected with death cams
no_SI_with_death_cams <- function(enabled = true) {
	if (enabled) {
		register_callback("player_death", "__no_death_cams", function(__params) {
			local player = GetPlayerFromUserID(__params.userid);
			if (!player.IsSurvivor() && IsPlayerABot(player)) player.Kill();
		});
	} else {
		remove_callback("player_death", "__no_death_cams");
	}
}

/* returns spawned player or null */
spawn_infected <- function(param_type, param_pos) {
	if (typeof param_type != "integer" || param_type < 1 || param_type > 8) return null; //survivor spawning is not working
	local player = null;
	local tmp_last_player = null;
	while(player = Entities.FindByClassname(player, "player"))
		tmp_last_player = player;
	ZSpawn({ type = param_type, pos = param_pos });
	player = Entities.FindByClassname(tmp_last_player, "player");
	if (!player) return null;
	if(player.GetZombieType() == 9) return null; //if an extra infected bot appears, it becomes a survivor and is then removed
	log("spawning infected type " + param_type + ": " + player_to_str(player));
	player.ValidateScriptScope();
	return player;
}

/* example: teleport_entity(player, Vector(0,0,0), QAngle(0,0,0)) */
teleport_entity <- function(ent, param_origin, param_angles) {
	assert(ent);
	if (!param_origin) param_origin = ent.GetOrigin();
	if (!param_angles) param_angles = ent.IsPlayer() ? ent.EyeAngles() : ent.GetAngles();
	local ent_old_name = ent.GetName();
	local ent_name = UniqueString();
	ent.__KeyValueFromString("targetname", ent_name);
	local teleporter = SpawnEntityFromTable("point_teleport", {
		origin = param_origin,
		angles = Vector(param_angles.x, param_angles.y, param_angles.z), //send Vector of pitch, yaw, roll;
		target = ent_name,
	});
	DoEntFire("!self", "Teleport", "", 0, null, teleporter);
	DoEntFire("!self", "Kill", "", 0, null, teleporter);
	DoEntFire("!self", "AddOutput", "targetname " + ent_old_name, 0.04, null, ent);
}

get_entity_flag <- function(ent, flag) {
	assert(ent);
	return (propint(ent,"m_fFlags") & flag) ? true : false;
}

/* example:
 set_entity_flag(Ent("!player"), (1 << 5), false)
 set_entity_flag(Ent("!player"), FL_FROZEN, false)
*/
set_entity_flag <- function(ent, flag, value) {
	assert(ent);
	local flags = propint(ent,"m_fFlags");
	flags = value ? (flags | flag) : (flags & ~flag);
	propint(ent, "m_fFlags", flags);
}

get_player_button <- function(player, button) {
	assert(player);
	return (player.GetButtonMask() & button) ? true : false;
}

force_player_button <- function(player, button, press = true) {
	assert(player);
	local buttons = propint(player, "m_afButtonForced");
	if (press)
		propint(player, "m_afButtonForced", buttons | button)
	else
		propint(player, "m_afButtonForced", buttons &~ button)
}

kill_player <- function(player, attacker = null, set_revive_count = true) {
	if (set_revive_count) player.SetReviveCount(100);
	player.TakeDamage(10e6, 0, attacker);
	log("killed " + player);
}

restart_game <- function(restore_cvars = true) {
	log("restarting...");
	EntFire("info_changelevel", "Disable");
	cvar("mp_restartgame", 1);
	if (restore_cvars) {
		cvars_restore_all();
		local cheats = (cvarf("sv_cheats") != 0)
		if (!cheats) {
			Convars.SetValue("sv_cheats", 1);
			Convars.SetValue("sv_cheats", 0);
		} else {
			Convars.SetValue("sv_cheats", 0);
			Convars.SetValue("sv_cheats", 1);
		}
	}
}

client_command <- function(player, command) {
	local ent = SpawnEntityFromTable("point_clientcommand", {});
	DoEntFire("!self", "Command", command, 0, player, ent);
	DoEntFire("!self", "Kill", "", 0, null, ent);
}

switch_to_infected <- function(player, zombie_class) {
	propint(player, "m_iTeamNum", 3);
	propint(player, "m_lifeState", 2);
	propint(player, "CTerrorPlayer.m_iVersusTeam", 2);
	propint(player, "m_iPlayerState", 6);
	spawn_infected(zombie_class, player.GetOrigin());
}

stop_director <- function() {
	cvars_add("sb_all_bot_game", 0, 1);
	cvars_add("director_no_specials", 0, 1);
	cvars_add("director_no_mobs", 0, 1);
	cvars_add("director_no_bosses", 0, 1);
	cvars_add("director_no_death_check", 0, 1);
	g_ModeScript.DirectorOptions.MaxSpecials <- 32;
}

stop_director_forced <- function() {
	if (Convars.GetStr("sv_cheats") == "0") throw "can't run stop_director_forced without sv_cheats";
	stop_director();
	SendToServerConsole("director_stop");
}

targetname_to_entity <- function(targetname) {
	local ent = Entities.FindByName(null, targetname);
	if (!ent) {
		log("WARNING! entity with targetname " + targetname + " does not exist");
		return null;
	}
	if (Entities.FindByName(ent, targetname)) {
		log("WARNING! multiple entities with targetname " + targetname + " exist");
	}
	return ent;
}

find_entities <- function(classname) {
	local ent = null
	local arr = []
	while (ent = Entities.FindByClassname(ent, classname))
		arr.push(ent)
	return arr
}

replace_primary_weapon <- function(player, weapon, laser_sight = false) {
	local inv_table = {};
	GetInvTable(player, inv_table);
	if ("slot0" in inv_table)
		inv_table.slot0.Kill();
	run_this_tick(function() {
		player.GiveItem(weapon_name);
		if (laser_sight)
			player.GiveUpgrade(UPGRADE_LASER_SIGHT);
	});
}

drop_weapon <- function(player, slot) {
	/*local function kill_slot(slot) {
		local inv_table = {};
		GetInvTable(player, inv_table);
		if ("slot" + slot in inv_table)
			inv_table["slot" + slot].Kill();
	}
	switch (slot) {
		case 0:
			player.GiveItem("rifle")
			//run_next_tick( @()kill_slot(0) )
			break
	}*/
	//todo https://forums.alliedmods.net/showthread.php?t=110734
}

draw_collision_box <- function(ent, duration, color = Vector(255, 255, 0)) {
	local mins = ent.GetOrigin() + propvec(ent, "m_Collision.m_vecMins")
	local maxs = ent.GetOrigin() + propvec(ent, "m_Collision.m_vecMaxs")
	DebugDrawLine_vCol( Vector(mins.x, mins.y, mins.z), Vector(mins.x, maxs.y, mins.z), color, false, duration )
	DebugDrawLine_vCol( Vector(mins.x, mins.y, mins.z), Vector(maxs.x, mins.y, mins.z), color, false, duration )
	DebugDrawLine_vCol( Vector(mins.x, maxs.y, mins.z), Vector(maxs.x, maxs.y, mins.z), color, false, duration )
	DebugDrawLine_vCol( Vector(maxs.x, mins.y, mins.z), Vector(maxs.x, maxs.y, mins.z), color, false, duration )
	
	DebugDrawLine_vCol( Vector(mins.x, mins.y, maxs.z), Vector(mins.x, maxs.y, maxs.z), color, false, duration )
	DebugDrawLine_vCol( Vector(mins.x, mins.y, maxs.z), Vector(maxs.x, mins.y, maxs.z), color, false, duration )
	DebugDrawLine_vCol( Vector(mins.x, maxs.y, maxs.z), Vector(maxs.x, maxs.y, maxs.z), color, false, duration )
	DebugDrawLine_vCol( Vector(maxs.x, mins.y, maxs.z), Vector(maxs.x, maxs.y, maxs.z), color, false, duration )
	
	DebugDrawLine_vCol( Vector(mins.x, mins.y, mins.z), Vector(mins.x, mins.y, maxs.z), color, false, duration )
	DebugDrawLine_vCol( Vector(mins.x, maxs.y, mins.z), Vector(mins.x, maxs.y, maxs.z), color, false, duration )
	DebugDrawLine_vCol( Vector(maxs.x, mins.y, mins.z), Vector(maxs.x, mins.y, maxs.z), color, false, duration )
	DebugDrawLine_vCol( Vector(maxs.x, maxs.y, mins.z), Vector(maxs.x, maxs.y, maxs.z), color, false, duration )
}

mark <- function(vec, duration, color = Vector(255, 0, 255), radius = 4) {
	DebugDrawBoxDirection(vec, Vector(-radius, -radius, -radius), Vector(radius, radius, radius), Vector(0, 0, 1), color, 255, duration)
}

/* set_speed_multiplier <- function(player, multiplier) {
	propfloat(player, "m_flLaggedMovementValue", multiplier)
	propfloat(player, "m_flGravity", 1.0 / multiplier / multiplier)
	register_callback("player_jump", player, function(_params) {
		local _player = GetPlayerFromUserID(_params.userid);
		run_this_tick(function() {
			local speed = _player.GetVelocity()
			//speed.z /= multiplier
			speed.z = 189.194 / multiplier
			_player.SetVelocity(speed)
			//moving platforms?
			log("m_flGravity " + propfloat(player, "m_flGravity") + " vertical speed " + speed.z)
		})
	})
} */

set_speed_multiplier <- function(player, multiplier) {
	register_ticker(player, function() {
		propfloat(player, "m_flGroundSpeed", 220 * multiplier)
		propfloat(player, "m_flMaxspeed", 220 * multiplier)
		propfloat(player, "m_flSpeed", 220 * multiplier)
		//propfloat(player, "m_flConstraintSpeedFactor", 0.2)
		//propvec(player, "m_vecConstraintCenter", player.GetOrigin())
		//propfloat(player, "m_flConstraintRadius", 100)
		//propfloat(player, "m_flConstraintWidth", 1000)
	})
}

/* netprop <- function(entity, prop, value = null) {
	type = NetProps.GetPropType(ent, prop);
	if (value != null) { //but can be 0
		switch (type) {
			case "integer":
				NetProps.SetPropEntity(ent, prop, value); break;
				NetProps.SetPropInt(ent, prop, value); break; //???
			case "string": NetProps.SetPropString(ent, prop, value); break;
			case "float": NetProps.SetPropFloat(ent, prop, value); break;
			case "Vector": NetProps.SetPropVector(ent, prop, value); break;
			case null: throw "no such prop: " + prop;
			default: throw "unsupported prop type: " + table.type + " of prop " + prop;
		}
	} else {
		
	}
} */

propint <- function(ent, prop, value = null) {
	if (value != null)
		NetProps.SetPropInt(ent, prop, value)
	else
		return NetProps.GetPropInt(ent, prop)
}

propfloat <- function(ent, prop, value = null) {
	if (value != null)
		NetProps.SetPropFloat(ent, prop, value)
	else
		return NetProps.GetPropFloat(ent, prop)
}

propstr <- function(ent, prop, value = null) {
	if (value != null)
		NetProps.SetPropString(ent, prop, value)
	else
		return NetProps.GetPropString(ent, prop)
}

propvec <- function(ent, prop, value = null) {
	if (value != null)
		NetProps.SetPropVector(ent, prop, value)
	else
		return NetProps.GetPropVector(ent, prop)
}

propent <- function(ent, prop, ...) {
	if (vargv.len() > 1)
		throw "wrong number of arguments"
	if (vargv.len() == 1)
		NetProps.SetPropEntity(ent, prop, vargv[0])
	else
		return NetProps.GetPropEntity(ent, prop)
}


/* examples:
 show_hud_hint_singleplayer("Use reload or leave field to cancel.", Vector(255,255,255), null, "+reload", 2);
 show_hud_hint_singleplayer("Use reload or leave field to cancel.", Vector(255,255,255), "icon_info", null, 2);
*/
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
	delayed_call(function() {
		DoEntFire("!self", "ShowHint", "", 0, null, hint);
		__current_hints[hint] <- true;
	}, 0.1);
	delayed_call(function() {
		hint.Kill();
		delete __current_hints[hint];
		if (__current_hints.len() != 0) return; //check if there are other simultaneously displayed hints
		cvar("gameinstructor_enable", 0);
	}, time);
}

if (!("__current_hints" in this) || forced) __current_hints <- {}

create_particles <- function(effect_name, origin_or_parent, duration = -1, attachment = null) {
	local origin = null
	local parent = null
	if (typeof(origin_or_parent) == "Vector")
		origin = origin_or_parent
	else
		parent = origin_or_parent
	local effect = SpawnEntityFromTable("info_particle_system", {
		effect_name = effect_name,
		origin = origin ? origin : parent.GetOrigin(),
		start_active = 1
	});
	if (parent) DoEntFire("!self", "SetParent", "!activator", 0, parent, effect)
	if (duration != -1) DoEntFire("!self", "Kill", "", duration, null, effect);
	if (attachment) {
		if (!parent)
			log("WARNING! Create_particles(): attachment without parent, ignored")
		else
			DoEntFire("!self", "SetParentAttachment", attachment, 0.01, null, target)
	}
	return effect
}

vector_to_angle <- function(vec) {
	if (vec.x == 0 && vec.y == 0 && vec.z == 0) throw "cannot convect zero vector to angle";
	local dx = vec.x;
	local dy = vec.y;
	local dz = vec.z;
	local dxy = sqrt(dx*dx + dy*dy);
	local pitch = -57.2958*atan2(dz, dxy);
	local yaw = 57.2958*atan2(dy, dx);
	return QAngle(pitch, yaw, 0);
}

angle_between_vectors <- function(vec1, vec2) {
	if (vec1.x == 0 && vec1.y == 0 && vec1.z == 0) throw "cannot find angle, vector 1 is zero";
	if (vec2.x == 0 && vec2.y == 0 && vec2.z == 0) throw "cannot find angle, vector 2 is zero";
	local ang_cos = vec1.Dot(vec2) / sqrt(vec1.LengthSqr() * vec2.LengthSqr());
	return 57.2958*acos(ang_cos);
}

trace_line <- function(start, end, mask = TRACE_MASK_VISIBLE_AND_NPCS, ignore = null) {
	local table = { start = start, end = end, mask = mask, ignore = ignore };
	TraceLine(table);
	if ("startsolid" in table) {
		if (table.startsolid) table.fraction = 0;
	} else {
		table.startsolid <- false
	}
	if (table.hit)
		table.hitpos <- table.start + (table.end - table.start).Scale(table.fraction);
	//DebugDrawLine_vCol(start, end, table.hit ? Vector(255,0,0) : Vector(0,255,0), false, 1);
	return table;
}

normalize <- function(vec) {
	if (vec.x == 0 && vec.y == 0 && vec.z == 0) throw "cannot normalize zero vector";
	return vec.Scale(1/vec.Length());
}

min <- function(a, b) {
	return (a < b) ? a : b
}

max <- function(a, b) {
	return (a > b) ? a : b
}

roundf <- function(a) {
	local a_abs = fabs(a)
	local a_abs_flr = floor(a_abs)
	local a_abs_part = a_abs - a_abs_flr
	local a_abs_round = a_abs_flr
	if (a_abs_part >= 0.5)
		a_abs_round++
	return (a > 0) ? a_abs_round : 0 - a_abs_round
}

decompose_by_orthonormal_basis <- function(vec, basis_x, basis_y, basis_z) {
	return Vector(vec.Dot(basis_x), vec.Dot(basis_y), vec.Dot(basis_z))
}

linear_interp <- function(x1, y1, x2, y2, clump_left = false, clump_right = false) {
	x1 = x1.tofloat()
	y1 = y1.tofloat()
	x2 = x2.tofloat()
	y2 = y2.tofloat()
	local a = (y2 - y1)/(x2 - x1)
	local b = y1 - a*x1
	local maxX = max(x1, x2)
	local minX = min(x1, x2)
	return function(x) {
		if (clump_left && x < minX) x = minX
		else if (clump_right && x > maxX) x = maxX
		return a*x + b
	}
}

quadratic_interp <- function(x1, y1, x2, y2, x3, y3, clump_left = false, clump_right = false) {
	x1 = x1.tofloat()
	y1 = y1.tofloat()
	x2 = x2.tofloat()
	y2 = y2.tofloat()
	x3 = x3.tofloat()
	y3 = y3.tofloat()
	local y2y3 = y2 - y3
	local y1y3 = y1 - y3
	local y1y2 = y1 - y2
	local x2x3 = x2 - x3
	local x1x3 = x1 - x3
	local x1x2 = x1 - x2
	local xDifs = x1x2*x1x3*x2x3
	local a = (x1*-y2y3 + x2*y1y3 + x3*-y1y2) / xDifs
	local b = (x1*x1*y2y3 + x2*x2*-y1y3 + x3*x3*y1y2) / xDifs
	local c = (x2*(x1*x1*y3-x3*x3*y1) + x2*x2*(x3*y1-x1*y3) + x1*x3*y2*-x1x3) / xDifs
	local maxX = max(x1, max(x2, x3))
	local minX = min(x1, min(x2, x3))
	return function(x) {
		if (clump_left && x < minX) x = minX
		else if (clump_right && x > maxX) x = maxX
		return a*x*x + b*x + c
	}
}

bilinear_interp <- function(x1, y1, x2, y2, x3, y3, clump_left = false, clump_right = false) {
	x1 = x1.tofloat()
	y1 = y1.tofloat()
	x2 = x2.tofloat()
	y2 = y2.tofloat()
	x3 = x3.tofloat()
	y3 = y3.tofloat()
	if (x1 >= x2 || x2 >= x3) throw "wrong x1 x2 x3"
	local a1 = (y2 - y1)/(x2 - x1)
	local b1 = y1 - a1*x1
	local a2 = (y3 - y2)/(x3 - x2)
	local b2 = y2 - a2*x2
	return function(x) {
		if (clump_left && x < x1) return y1
		if (x <= x2) return a1*x + b1
		if (clump_right && x > x3) return y3
		return a2*x + b2
	}
}

///////////////////////////////

if (!("clock" in this) || forced) clock <- {

	sec = Time,
	
	msec = @() Time() * 1000,
	
	frames = GetFrameCount,
	
	ticks = function() {
		if (__ticks == -1) throw "use clock.tick_counter_init() first";
		return __ticks;
	},
	
	tick_counter_init = @() __ticker_init(),
	
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
	},
	
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
	},
	
	__ticks = -1,
	
}

///////////////////////////////

/*
delayed_call(func, delay) - calls function after delay (seconds)
delayed_call(func, delay, scope) - calls function after delay (seconds) using scope as environment
delayed_call(func, delay, entity) - calls function after delay (seconds) using entity's runscriptscope input

///// example 1 /////
delayed_call( function(){ log("hello!") }, 0.5 )
//it's the same as this:
delayed_call( @()log("hello!"), 0.5 )
//or this:
delayed_call( function(){
	log("hello!")
}, 0.5 )

///// example 2 /////
local a = 5;
delayed_call( function(){ log(a) }, 0.5 )

///// example 3 /////
delayed_call(@()self.Kill(), 0.5, entity)
//entity will be removed after 0.5 sec

///// delays /////
delay == 0:			function always runs THIS tick, runs immediately even if game is paused
delay <= 0.0333:	function always runs THIS tick, immediately after game is unpaused
					nested delayed calls even with non-zero delay will be executed not earlier than next tick
delay >= 0.0334:	function always runs NEXT tick
these numbers are bound to tickrate; this behaviour probably do not depend on server performance
(even when you run heavy script every tick, tickrate remains 30)

you can also use run_this_tick(func[, scope|ent]), run_next_tick(func[, scope|ent])
*/

delayed_call <- function(func, delay, scope_or_ent = null) {
	local key = UniqueString()
	local ent = null
	local scope = null
	if ("CBaseEntity" in getroottable() && scope_or_ent instanceof ::CBaseEntity) {
		ent = scope_or_ent
		if (invalid(ent))
			throw "trying to register a delayed call for deleted entity"
		ent.ValidateScriptScope()
		local scope_key = "__dc" + key
		ent.GetScriptScope().scope_key <- function() {
			delete ::__dc_ents[key]
			func()
			/*try {
				func()
			} catch(exception) {
				error(format("Exception for delayed call (%s) [ent %s]: %s\n", key, ent_to_str(ent), exception));
			}*/
		}
		::__dc_ents[key] <- {
			ent = ent,
			time = clock.sec() + delay
		}
		DoEntFire("!self", "runscriptcode", scope_key + "()", delay, null, ent)
	} else {
		scope = scope_or_ent
		if (scope) {
			try {
				func = func.bindenv(scope)
			} catch (exception) {
				throw "Cannot bindenv function to " + var_to_str(scope)
			}
		}
		::__dc_func[key] <- {
			func = func,
			time = clock.sec() + delay
		}
		if ("dc_debug" in getroottable() && ::dc_debug) {
			log("delayed call registered with key " + key)
			__printstackinfos()
		}
		DoEntFire("!self", "runscriptcode", "::__dc_check()", delay, null, worldspawn)
	}
	return key
}

worldspawn <- Entities.FindByClassname(null, "worldspawn")

::__dc_check <- function() {
	local time = Time()
	foreach (key, table in ::__dc_func) {
		if (table.time <= time) {
			local func = table.func
			delete ::__dc_func[key]
			func()
			/*try {
				table.func()
			} catch(exception) {
				error(format("Exception for delayed call (%s): %s\n", key, exception))
			}*/
		}
	}
}

if (!("__dc_func" in getroottable())) ::__dc_func <- {}

if (!("__dc_ents" in getroottable())) ::__dc_ents <- {}

remove_delayed_call <- function (key) {
	if (key in ::__dc_func) {
		delete ::__dc_func[key]
	} else if (key in ::__dc_ents) {
		local ent_scope = __dc_ents[key].ent.GetScriptScope()
		local scope_key = "__dc" + key
		if (scope_key in ent_scope)
			delete ent_scope[scope_key]
		delete __dc_ents[key]
	}
}

remove_all_delayed_calls <- function () {
	::__dc_func <- {};
	foreach(key, dc_table in ::__dc_ents) {
		remove_delayed_call(key)
	}
}

run_this_tick <- function(func, ...)  {
	local args = [this, func, 0]
	args.extend(vargv)
	delayed_call.acall(args)
}

run_next_tick <- function(func, ...)  {
	local args = [this, func, 0.001]
	args.extend(vargv)
	delayed_call( function() {
		delayed_call.acall(args)
	}, 0.001)
}

print_all_delayed_calls <- function() {
	print("All delayed calls registered:")
	local strings = []
	local time = clock.sec()
	foreach(key, table in __dc_func) {
		strings.push(format(
			"\"%s\": will be called after %f seconds",
			key, table.time - time
		));
	}
	foreach(key, table in __dc_ents) {
		strings.push(format(
			"\"%s\" [ent %s]: will be called after %f seconds",
			key, ent_to_str(table.ent), table.time - time
		))
	}
	if (strings.len() == 0)
		printl(" [none]")
	else {
		printl("")
		foreach(str in strings) printl(str)
	}
}

///////////////////////////////

/*

//outdated, don't uncomment and use this, because after ~30000 delayed calls game will crash: "CUtlRBTree overflow!"
//strings passed to runscriptcode are not removed by game later and fill all memory
//this is museum piece

delayed_call <- function (func, delay, ...)  {
	local args = [this, null, func, delay];
	args.extend(vargv);
	delayed_call_ent.acall(args);
}

delayed_call_ent <- function (ent, func, delay, ...)  {
	local key = UniqueString();
	__dc_func[key] <- (ent ? func : func.bindenv(this ? this : getroottable()));
	__dc_params[key] <- vargv;
	local params_tokens = [];
	for(local i = 0; i < vargv.len(); i++)
		params_tokens.push(format("__lib_scopes.%s.__dc_params.%s[%d]", __lib, key, i));
	local code = format(
		"(__lib_scopes.%s.__dc_func.%s)(%s);delete __lib_scopes.%s.__dc_func.%s;delete __lib_scopes.%s.__dc_params.%s",
		__lib, key, connect_strings(params_tokens, ","), __lib, key, __lib, key
	);
	DoEntFire("!self", "runscriptcode", code, delay, null, (ent ? ent : worldspawn));
	return key;
}

*/

///////////////////////////////

/*
registering function "func" using "key" for "event",later we can remove this callback using it's key; examples:
register_callback("player_hurt", "my_key", @(params)printl("hurt!"));
remove_callback("player_hurt", "my_key")
if we don't care about key, we can use null
register_callback("player_connect", null, @(params)printl("connect!"));
*/

register_callback <- function(event, key, func) {
	if (!key) key = UniqueString();
	if (!(event in __callbacks)) {
		__callbacks[event] <- {};
		local scope = {};
		scope["event_name"] <- event;
		scope["OnGameEvent_" + event] <- function (params) {
			if ("userid" in params)
				params.player <- GetPlayerFromUserID(params.userid);
			if ("victim" in params)
				params.player_victim <- GetPlayerFromUserID(params.victim);
			if ("attacker" in params)
				params.player_attacker <- GetPlayerFromUserID(params.attacker);
			foreach(callback in __callbacks[scope.event_name])
				callback(clone params);
		}.bindenv(this);
		__CollectEventCallbacks(scope, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	}
	__callbacks[event][key] <- func;
}

if (!("__callbacks" in this)) __callbacks <- {};

remove_callback <- function(event, key) {
	if (!(event in __callbacks)) return;
	if (!(key in __callbacks[event])) return;
	delete __callbacks[event][key];
}

remove_all_callbacks <- function() {
	foreach(event, callbacks in __callbacks)
		foreach(key, callback in callbacks)
			delete callbacks[key];
}

log_event <- function(event, enabled = true) {
	if (enabled) register_callback(event, "__log_event_table", log_table);
	else remove_callback(event, "__log_event_table");
}

log_events <- function(enabled = true) {
	cvar("net_showevents", enabled ? 2 : 0);
}

ClientType <- {
	ANY = -1
	HUMAN = 1 << 0
	BOT = 1 << 1
}

on_player_connect <- function(teams, isbot, func) {
	//it's ok to be registered multiple times
	register_callback("player_team", "__on_player_connect", function(params) {
		local func = __on_player_connect[params.team][params.isbot ? 1 : 0];
		if (func) func(params)
	});
	if (teams == Team.ANY && isbot == ClientType.ANY) throw "specify team ot playertype for on_player_connect";
	for(local i = 0; i <= 3; i++)
		if (teams & (1 << i)) {
			if (isbot == ClientType.ANY || !isbot)
				__on_player_connect[i][0] = func
			if (isbot == ClientType.ANY || isbot)
				__on_player_connect[i][1] = func
		}
}

remove_on_player_connect <- function() {
	remove_callback("player_team", "__on_player_connect");
	for (local team = 0; team <= 3; team++)
		for (local isbot = 0; isbot <= 1; isbot++)
			__on_player_connect[team][isbot] = null;
}

if (!("__on_player_connect" in this)) __on_player_connect <- [
	[null, null], //Team.UNASSIGNED
	[null, null], //Team.SPECTATORS
	[null, null], //Team.SURVIVORS
	[null, null], //Team.INFECTED
];

print_all_callbacks <- function() {
	print("All callbacks registered with \"register_callback\":");
	local strings = [];
	foreach(event, callbacks in __callbacks) {
		local tokens = [];
		foreach(key, callback in callbacks)
			tokens.push("\"" + key + "\"");
		if (tokens.len() != 0)
			strings.push(event + ": " + connect_strings(tokens, ","));
	}
	if (strings.len() == 0) {
		printl(" [none]");
		return;
	} else {
		printl("");
		foreach(str in strings) printl(str);
	}
}

///////////////////////////////

/*
register a function that will be called every tick; example:
register_ticker("my_key", @()log("tick"))

tested:
- multiple including this library
- multiple calls of __ticker_init
probably multiple instances of this library with different scopes will also work

if function returns false, ticker will be removed
*/

register_ticker <- function(key, func) {
	if (!key) key = UniqueString();
	if (!__ticker_ent || invalid(__ticker_ent))
		__ticker_init();
	__tickers[key] <- {
		func = func,
		start_time = clock.sec(),
		last_time = null,
		start_ticks = clock.ticks(),
	}
}

//this variable will be accessible from ticker function
ticker_info <- {
	start_time = null, //time when current ticker loop started
	delta_time = null,	//time elapsed since last ticker call
	ticks = null,	//ticks elapsed from first loop call (first call = 0 ticks)
	first_call = null,	//equivalent to "ticker_info.ticks == 0"
}

__ticker_init <- function() {
	if (__ticker_ent && !invalid(__ticker_ent))
		return;
	__ticker_ent = SpawnEntityFromTable("logic_timer", {
		RefireTime = 0,
	});
	__ticker_ent.ConnectOutput("OnTimer", "func");
	__ticker_ent.ValidateScriptScope();
	__ticker_ent.GetScriptScope().func <- function() {
		clock.__ticks++;
		foreach(key, ticker in __tickers) {
			ticker_info.start_time = ticker.start_time
			local current_time = clock.sec()
			ticker_info.delta_time = ticker.last_time ? (current_time - ticker.last_time) : (current_time - ticker.start_time)
			ticker_info.ticks = clock.ticks() - ticker.start_ticks
			ticker_info.first_call = !ticker.last_time
			ticker.last_time = current_time
			local return_value = ticker.func()
			if (return_value == false) {
				delete __tickers[key]
				logf("Removing ticker %s, function returned false", key)
			}
		}
	} //.bindenv(this);
	clock.__ticks = 0;
}

if (!("__tickers" in this)) __tickers <- {};

if (!("__ticker_ent" in this)) __ticker_ent <- null;

remove_ticker <- function(key) {
	if (!(key in __tickers)) return;
	delete __tickers[key];
}

remove_all_tickers <- function() {
	foreach(key, ticker in __tickers)
		delete __tickers[key];
}

print_all_tickers <- function() {
	print("All tickers registered with \"register_ticker\":");
	local tokens = [];
	foreach(key, ticker in __tickers)
		tokens.push("\"" + key + "\"");
	if (tokens.len() == 0)
		printl(" [none]");
	else
		print(" " + connect_strings(tokens, ",") + "\n");
}

///////////////////////////////

/*
register a function that will be called on server shutdown
*/

add_task_on_shutdown <- function(key, func, after_all = false) {
	if (!key) key = UniqueString();
	if (!("__on_shutdown" in this)) {
		__on_shutdown <- {};
		__on_shutdown_after_all <- {};
		
		//this function will be called on shutdown if developer cvar is on
		if (!("FindCircularReferences_replaced" in getroottable())) {
			
			//making circular reference
			::__circ<-{}; __circ.ref<-::__circ;
			::__circ<-{}; __circ.ref<-::__circ;
			
			::FindCircularReferences <- function(...) {
				//scope is root table, lib may not be included
				if ("__on_shutdown_reset_dev" in getroottable()) {
					Convars.SetValue("developer", 0);
					Convars.SetValue("contimes", 8);
				}
				printl("running tasks on shutdown...");
				foreach(lib_id, lib_scope in __lib_scopes) {
					foreach(func in lib_scope.__on_shutdown)
						func.call(lib_scope);
					foreach(func in lib_scope.__on_shutdown_after_all)
						func.call(lib_scope);
				}
			}
			::FindCircularReferences_replaced <- true;
		}
		
		//enabling developer mode
		if (Convars.GetStr("developer") == "0") {
			::__on_shutdown_reset_dev <- true;
			cvar("developer", 1);
			cvar("contimes", 0);
		}
		log("new task on shutdown registered");
	}
	
	if (!after_all) {
		__on_shutdown[key] <- func;
		if (key in __on_shutdown_after_all) delete __on_shutdown_after_all[key];
	} else {
		__on_shutdown_after_all[key] <- func;
		if (key in __on_shutdown) delete __on_shutdown[key];
	}
}

remove_task_on_shutdown <- function(key) {
	if (!("__on_shutdown" in this)) return;
	if (key in __on_shutdown) delete __on_shutdown[key];
	if (key in __on_shutdown_after_all) delete __on_shutdown_after_all[key];
}

remove_all_tasks_on_shutdown <- function() {
	if (!("__on_shutdown" in this)) return;
	__on_shutdown <- {};
	__on_shutdown_after_all <- {};
}

print_all_tasks_on_shutdown <- function() {
	print("All tasks on shutdown:");
	if (!("__on_shutdown" in this)) {
		printl(" [none]");
		return;
	}
	local tokens = [];
	foreach(key, ticker in __on_shutdown)
		tokens.push("\"" + key + "\"");
	foreach(key, ticker in __on_shutdown_after_all)
		tokens.push("\"" + key + "\"");
	if (tokens.len() == 0)
		printl(" [none]");
	else
		printl(" " + connect_strings(tokens, ","));
}

///////////////////////////////

register_loop <- function(key, func, refire_time) {
	if (key in __loops) {
		local timer = __loops[key];
		timer.GetScriptScope().func <- func;
		DoEntFire("!self", "RefireTime", refire_time.tostring(), 0, null, timer);
		DoEntFire("!self", "ResetTimer", "", 0, null, timer);
		return;
	}
	if (!key) key = UniqueString();
	local timer = SpawnEntityFromTable("logic_timer", {
		RefireTime = refire_time,
	});
	timer.ConnectOutput("OnTimer", "func");
	timer.ValidateScriptScope();
	timer.GetScriptScope().func <- func;
	__loops[key] <- timer;
}

if (!("__loops" in this)) __loops <- {}

remove_loop <- function(key) {
	if (!(key in __loops)) return;
	__loops[key].Kill();
	delete __loops[key];
}

/*
loop_reset don't cause fire; after loop_reset timer will fire in RefireTime seconds
to fire immediately, reset timer and then subtract RefireTime from timer
*/

loop_reset <- function(key, prevent_running_this_tick = true) {
	if (!(key in __loops)) return;
	local timer = __loops[key];
	DoEntFire("!self", "ResetTimer", "", 0, null, timer);
	if (prevent_running_this_tick)
		__loop_prevent_running_this_tick(timer);
}

loop_subtract_from_timer <- function(key, value) {
	if (!(key in __loops)) return;
	DoEntFire("!self", "SubtractFromTimer", value.tostring(), 0, null, __loops[key]);
}

loop_add_to_timer <- function(key, value, prevent_running_this_tick = true) {
	if (!(key in __loops)) return;
	local timer = __loops[key];
	DoEntFire("!self", "AddToTimer", value.tostring(), 0, null, timer);
	if (prevent_running_this_tick)
		__loop_prevent_running_this_tick(timer);
}

loop_set_refire_time <- function(key, value) {
	if (!(key in __loops)) return;
	DoEntFire("!self", "RefireTime", value.tostring(), 0, null, __loops[key]);
}

__loop_prevent_running_this_tick <- function(timer) {
	local scope = timer.GetScriptScope();
	if (scope.func == __dummy) return;
	scope.func_disabled <- scope.func;
	scope.func <- __dummy;
	run_next_tick(function() {
		scope.func <- scope.func_disabled;
	});
}

loop_get_refire_time <- function(key) {
	if (!(key in __loops)) return;
	return propint(__loops[key], "m_flRefireTime");
}

print_all_loops <- function() {
	print("All loops registered with \"register_loop\":");
	local tokens = [];
	foreach(key, timer in __loops)
		tokens.push("\"" + key + "\"");
	if (tokens.len() == 0)
		printl(" [none]");
	else
		printl(" " + connect_strings(tokens, ","));
}

__dummy <- function(...) {}

///////////////////////////////

register_task_on_entity <- function(ent, func, delay) {
	local delay_fix = 0.066667;
	if (delay < delay_fix) throw "register_task_on_entity: minimum delay is " + delay_fix;
	delay -= delay_fix; //this does not depend on tickrate
	__tasks_ent[ent] <- true;
	ent.ValidateScriptScope();
	ent.GetScriptScope().task <- function() {
		func();
		return delay;
	};
	AddThinkToEnt(ent, "task");
}

if (!("__tasks_ent" in this)) __tasks_ent <- {}

remove_task_on_entity <- function(ent) {
	if (!(ent in __tasks_ent)) return;
	delete __tasks_ent[ent];
	AddThinkToEnt(ent, null);
	ent.GetScriptScope().task <- function() {};
}

remove_all_tasks_on_entities <- function() {
	foreach(ent in __tasks_ent)
		if (!invalid(ent))
			AddThinkToEnt(ent, null);
	__tasks_ent <- {}
}

/*
::_last <- null; ::_first <- null; ::_count <- 0;
register_task_on_entity(player(), function(){
	if (::_last) {
		local real_delay = Time() - ::_last; ::_count++;
		log(real_delay + ", avg = " + (Time() - ::_first) / ::_count); ::_last <- Time();
	} else { ::_last <- Time(); ::_first <- ::_last; }
}, 0.05)

delay	real avg delay
0		0.0666
0.2		0.2666
0.5		0.5666
*/

if (!("__tasks_ent" in this)) __tasks_ent <- {}

///////////////////////////////

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
	register_callback("player_say", "__chat_cmds", function(params) {
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

///////////////////////////////

/* Team.ANY = -1
Team.UNASSIGNED = 1
Team.SPECTATORS = 2
Team.SURVIVORS = 4
Team.INFECTED = 8 */

//test: script on_key_action("my", Team.SURVIVORS, IN_ATTACK, 0.1, @(player)player.ApplyAbsVelocityImpulse(Vector(0,0,300)), null)
//test: script on_key_action("my", player(), IN_ALT1, 0, @(p)propint(p,"movetype",8), @(p)propint(p,"movetype",2))
//test: register_ticker("test",@()log(player().GetButtonMask()))

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
	register_loop("__key_action_" + key, function() {
		local function do_key_check(player) {
			player.ValidateScriptScope()
			local player_scope = player.GetScriptScope()
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
	}, delay)
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

///////////////////////////////

print_all_tasks <- function() {
	print_all_callbacks();
	print_all_tickers();
	print_all_loops();
	print_all_tasks_on_shutdown();
	print_all_delayed_calls();
}

///////////////////////////////

is_hitscan_weapon <- function(weapon_name) {
	return (weapon_name in __hitscan_weapon_table);
}

__hitscan_weapon_table <- {
	pistol = true,
	pistol_magnum = true,
	rifle_ak47 = true,
	rifle_desert = true,
	rifle_m60 = true,
	rifle_sg552 = true,
	rifle = true,
	pumpshotgun = true,
	shotgun_chrome = true,
	autoshotgun = true,
	shotgun_spas = true,
	smg_mp5 = true,
	smg_silenced = true,
	smg = true,
	hunting_rifle = true,
	sniper_military = true,
	sniper_scout = true,
	sniper_awp = true,
}

playsound <- function(sound_path, ent) {
	if (!(sound_path in __playsound_precached)) {
		ent.PrecacheScriptSound(sound_path);
		__playsound_precached[sound_path] <- true;
	}
	EmitSoundOn(sound_path, ent);
}

if (!("__playsound_precached" in this)) __playsound_precached <- {}

/*
as first parameter you can pass entity or function that returns entity (for example, bot())
next parameters are any amount of netprops

example:
watch_netprops(player, "movetype", "m_fFlags", "m_nButtons", "m_vecOrigin", "m_flCycle", "m_hGroundEntity")

pass NULL as first param to remove anything from HUD and remove binds

----------

for given example, you will see the following on your HUD:
[1] movetype: 2
[2] m_fFlags: FL_ONGROUND | FL_CLIENT
[3] m_nButtons: IN_FORWARD
[4] m_vecOrigin: <77.819519 8419.559570 0.031250>
[5] m_flCycle: 0.611931
[6] m_hGroundEntity: (worldspawn 0)

all values are updating every tick
press any number with ALT button on keyboard to save corresponding netprop
press any number without ALT button to restore it's value

*/

watch_netprops <- function(ent, ...) {
	if (!ent) {
		HUDSetLayout({
			Fields = {}
		});
		remove_loop("__watch_netprops");
		for (local i = 0; i < 9; i++)
			SendToConsole(format("bind %d slot%d", i, i));
		SendToConsole("unbind alt");
		return;
	}
	::__watch_netprops.ent <- ent;
	::__watch_netprops.ent_func <- ((typeof(ent) == "function") ? ent : null);
	local netprops = vargv;
	::__watch_netprops.Fields <- {};
	local size = netprops.len();
	local up_shift = (size > 4) ? size - 4 : 0;
	foreach(index, netprop in netprops) {
		local slot = index + 1;
		HUDPlace(slot, 0.05, 0.55 + 0.06*(index - up_shift), 1, 0.1);
		local type = NetProps.GetPropType((::__watch_netprops.ent_func ? ::__watch_netprops.ent_func() : ::__watch_netprops.ent), netprop);
		::__watch_netprops.Fields[slot] <- {
			name = netprop,
			type = type,
			slot = slot,
			flags = HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG
		}
	}
	register_loop("__watch_netprops", function() {
		local ent = ::__watch_netprops.ent_func ? ::__watch_netprops.ent_func() : ::__watch_netprops.ent;
		foreach(slot, table in ::__watch_netprops.Fields) {
			local str = format("[%d] %s: ", slot, table.name);
			switch (table.type) {
				case "integer":
					if (table.name in __netprops_bitmaps) {
						local bitmap = __netprops_bitmaps[table.name];
						local val = NetProps.GetPropInt(ent, table.name);
						local names_arr = [];
						foreach (index, flag_name in bitmap)
							if (val & (1 << index))
								names_arr.push(flag_name);
						str += connect_strings(names_arr, " | ");
						break;
					}
					local val = NetProps.GetPropEntity(ent, table.name);
					if (!val)
						str += NetProps.GetPropInt(ent, table.name);
					else
						str += ent_to_str(val);
					break;
				case "string": str += NetProps.GetPropString(ent, table.name); break;
				case "float": str += NetProps.GetPropFloat(ent, table.name).tostring(); break;
				case "Vector":
					local vec = NetProps.GetPropVector(ent, table.name);
					str += format("<%f %f %f>", vec.x, vec.y, vec.z);
				break;
				case null: str += "null"; break;
				default: str += "unsupported prop type: " + table.type;
			}
			table.dataval <- str;
		}
		HUDSetLayout(::__watch_netprops);
	}, 0);
	local slot_count = ::__watch_netprops.Fields.len();
	::__watch_netprops.binds_save <- "";
	::__watch_netprops.binds_restore <- "";
	for (local i = 1; i <= slot_count; i++) {
		::__watch_netprops.binds_save += format("bind %d \"script watch_netprops_save(%d)\";", i, i);
		::__watch_netprops.binds_restore += format("bind %d \"script watch_netprops_restore(%d)\";", i, i);
	}
	watch_netprops_restore_binds();
	SendToConsole("alias +save_mode \"script watch_netprops_save_binds()\"");
	SendToConsole("alias -save_mode \"script watch_netprops_restore_binds()\"");
	SendToConsole("bind alt +save_mode");
}

watch_netprops_save <- function (slot) {
	local ent = ::__watch_netprops.ent_func ? ::__watch_netprops.ent_func() : ::__watch_netprops.ent;
	local table = ::__watch_netprops.Fields[slot];
	switch (table.type) {
		case "integer": table.saved <- NetProps.GetPropInt(ent, table.name); break;
		case "string": table.saved <- NetProps.GetPropString(ent, table.name); break;
		case "float": table.saved <- NetProps.GetPropFloat(ent, table.name); break;
		case "Vector": table.saved <- NetProps.GetPropVector(ent, table.name); break;
		case null: default: say_chat("can't save netprop of unsupported prop type"); return;
	}
	logf("saved value %s of netprop %s", table.saved.tostring(), table.name);
	table.dataval = "<save> " + table.dataval;
	HUDSetLayout(::__watch_netprops);
	loop_add_to_timer("__watch_netprops", 0.1);
}

watch_netprops_restore <- function (slot) {
	local ent = ::__watch_netprops.ent_func ? ::__watch_netprops.ent_func() : ::__watch_netprops.ent;
	local table = ::__watch_netprops.Fields[slot];
	if (!("saved" in table)) {
		say_chat("save value before restoring");
		return;
	}
	local saved = table.saved;
	switch (table.type) {
		case "integer": NetProps.SetPropInt(ent, table.name, saved); break;
		case "string": NetProps.SetPropString(ent, table.name, saved); break;
		case "float": NetProps.SetPropFloat(ent, table.name, saved); break;
		case "Vector": NetProps.SetPropVector(ent, table.name, saved); break;
	}
	logf("restored value %s of netprop %s", saved.tostring(), table.name);
	table.dataval = "<set> " + table.dataval;
	HUDSetLayout(::__watch_netprops);
	loop_add_to_timer("__watch_netprops", 0.1);
}

watch_netprops_save_binds <- @() SendToConsole(::__watch_netprops.binds_save);
watch_netprops_restore_binds <- @() SendToConsole(::__watch_netprops.binds_restore);

local buttons_bits = ["IN_ATTACK", "IN_JUMP", "IN_DUCK", "IN_FORWARD", "IN_BACK", "IN_USE", "IN_CANCEL", "IN_LEFT", "IN_RIGHT", "IN_MOVELEFT", "IN_MOVERIGHT", "IN_ATTACK2", "IN_RUN", "IN_RELOAD", "IN_ALT1", "IN_ALT2", "IN_SCORE", "IN_SPEED", "IN_WALK", "IN_ZOOM", "IN_WEAPON1", "IN_WEAPON2", "IN_BULLRUSH", "IN_GRENADE1", "IN_GRENADE2"]

__netprops_bitmaps <- {
	m_fFlags = ["FL_ONGROUND", "FL_DUCKING", "FL_WATERJUMP", "FL_ONTRAIN", "FL_INRAIN", "FL_FROZEN", "FL_ATCONTROLS", "FL_CLIENT", "FL_FAKECLIENT", "FL_INWATER", "FL_FLY", "FL_SWIM", "FL_CONVEYOR", "FL_NPC", "FL_GODMODE", "FL_NOTARGET", "FL_AIMTARGET", "FL_PARTIALGROUND", "FL_STATICPROP", "FL_GRAPHED", "FL_GRENADE", "FL_STEPMOVEMENT", "FL_DONTTOUCH", "FL_BASEVELOCITY", "FL_WORLDBRUSH", "FL_OBJECT", "FL_KILLME", "FL_ONFIRE", "FL_DISSOLVING", "FL_TRANSRAGDOLL", "FL_UNBLOCKABLE_BY_PLAYER", "FL_FREEZING"],
	m_nButtons = buttons_bits,
	m_nOldButtons = buttons_bits,
	m_afButtonLast = buttons_bits,
	m_afButtonPressed = buttons_bits,
	m_afButtonReleased = buttons_bits,
	m_afButtonDisabled = buttons_bits,
	m_afButtonForced = buttons_bits,
}

if (!("__watch_netprops" in getroottable())) ::__watch_netprops <- {}

///////////////////////////////

file_read <- FileToString; //gets filename, returns string

file_write <- StringToFile; //gets filename and string

file_to_func <- function(filename) {
	local str = FileToString(filename);
	if (!str) return null;
	return compilestring(str);
}

file_append <- function(filename, str) {
	local str_from_file = FileToString(filename);
	StringToFile(filename, str_from_file ? str_from_file + str : str);
}

///////////////////////////////

__hud_data_init <- function() { //if we include library first time
	::__hud_data <- {
		possessors = {},
		internal_slots = {},
		layout = { //realtime!
			Fields = {}
		},
		layout_dummy = {
			Fields = {}
		},
		initialized = false,
		disabled = false,
		timers = {},
		timer_callbacks = {}
	}
	for (local i = 1; i <= 14; i++) {
		//14 slots (1-14)
		::__hud_data.internal_slots[i] <- {
			possessor = null,
			name = null
		}
	}
	for (local i = 0; i < 4; i++) {
		//4 timers (0-3)
		::__hud_data.timers[i] <- {
			possessor = null,
			name = null,
			state = TIMER_DISABLE,
		}
	}
}

if (!("__hud_data" in getroottable()))
	__hud_data_init()

hud <- {
	__check_init = function() {
		if (!::__hud_data.initialized)
			//throw "HUD is not initialized"
			hud.init()
	},
	
	__refresh = function() {
		if (::__hud_data.disabled) {
			HUDSetLayout(::__hud_data.layout_dummy)
		} else {
			HUDSetLayout(::__hud_data.layout)
		}
	},
	
	__find_free_slot = function() { //returns slot internal index or -1 if no free slots
		foreach(index, slot in ::__hud_data.internal_slots)
			if (!slot.possessor)
				return index
		return -1
	},
	
	__get_internal_index = function(possessor, name) { //throws exception if not found
		
		checktype(possessor, STRING)
		checktype(name, ["string", "integer"])
		
		if (!(possessor in ::__hud_data.possessors))
			throw format("Possessor %s not found", possessor.tostring())
		local possessor_table = ::__hud_data.possessors[possessor]
		if (!(name in possessor_table))
			throw format("Name %s not found for possessor %s", name.tostring(), possessor)
		return possessor_table[name]
	},
	
	__set_flags = function(slot_table, flag, value) {
		if (value)
			slot_table.flags = slot_table.flags & ~flag
		else
			slot_table.flags = slot_table.flags | flag
	},
	
	__find_free_timer = function()  { //returns timer index (0-3) or -1 if no free timers
		foreach (id, timer in ::__hud_data.timers)
			if (!timer.possessor)
				return id
		return -1
	},
	
	__get_timer_id = function(possessor, name, dont_throw = false) { //throws exception if not found
		
		checktype(possessor, STRING)
		checktype(name, STRING)
		
		foreach (id, timer in ::__hud_data.timers)
			if (timer.possessor == possessor && timer.name == name)
				return id
		if (dont_throw) return -1
		throw format("cannot find timer named %s for possessor %s", name.tostring(), possessor)
	},
	
	init = function() {
		if (::__hud_data.initialized)
			return
		::__hud_data.initialized = true
		log("HUD was initialized")
		
		hud.__refresh()
	},
	
	posess_slot = function(possessor, name) {
		__check_init()
		
		checktype(possessor, STRING)
		checktype(name, ["string", "integer"])
		
		local slot_to_posess = hud.__find_free_slot()
		if (slot_to_posess == -1) {
			log("cannot find free HUD slots")
			return false
		}
		if (!(possessor in ::__hud_data.possessors))
			::__hud_data.possessors[possessor] <- {}
		local possessor_table = ::__hud_data.possessors[possessor]
		if (name in possessor_table)
			throw format("name %s is already registered for possessor %s", name.tostring(), possessor)
		
		//first action: add slot to possessors table
		possessor_table[name] <- slot_to_posess
		
		//second action: edit possessor in internal_slots
		::__hud_data.internal_slots[slot_to_posess].possessor = possessor
		::__hud_data.internal_slots[slot_to_posess].name = name
		
		//third action: add slot to layout
		::__hud_data.layout.Fields[slot_to_posess] <- {
			slot = slot_to_posess,
			dataval = "",
			flags = 0
		}
		HUDPlace(slot_to_posess, 0.1, 0.1, 0.3, 0.05)
		
		hud.__refresh()
		return true
	},
	
	release_slot = function(possessor, name) {
		__check_init()
		
		//first action: remove slot from possessors table
		local possessor_table = ::__hud_data.possessors[possessor]
		local slot_to_delete = __get_internal_index(possessor, name)
		delete possessor_table[name]
		
		//second action: edit possessor in internal_slots
		::__hud_data.internal_slots[slot_to_delete].possessor = null
		
		//third action: remove slot from layout
		delete ::__hud_data.layout.Fields[slot_to_delete]
		
		hud.__refresh()
	},
	
	set_position = function(possessor, name, x, y, w, h) {
		__check_init()
		
		checktype(x, NUMBER)
		checktype(y, NUMBER)
		checktype(w, NUMBER)
		checktype(h, NUMBER)
			
		local slot = __get_internal_index(possessor, name)
		HUDPlace(slot, x, y, w, h)
		
		hud.__refresh()
	},
	
	set_visible = function(possessor, name, is_visible) {
		__check_init()
		
		checktype(visible, BOOL)
		
		local slot = __get_internal_index(possessor, name)
		local slot_table = ::__hud_data.layout.Fields[slot]
		__set_flags(slot_table, HUD_FLAG_NOTVISIBLE, is_visible)
		
		hud.__refresh()
	},
	
	set_text = function(possessor, name, text) {
		__check_init()
		
		checktype(text, ["string", "integer", "float"])
		
		local slot = __get_internal_index(possessor, name)
		local slot_table = ::__hud_data.layout.Fields[slot]
		if ("datafunc" in slot_table) delete slot_table.datafunc
		if ("special" in slot_table) delete slot_table.special
		if ("staticstring" in slot_table) delete slot_table.staticstring
		slot_table.dataval <- text
		
		hud.__refresh()
	},
	
	set_datafunc = function(possessor, name, func) {
		__check_init()
		
		checktype(func, FUNC)
		
		local slot = __get_internal_index(possessor, name)
		local slot_table = ::__hud_data.layout.Fields[slot]
		if ("dataval" in slot_table) delete slot_table.dataval
		if ("special" in slot_table) delete slot_table.special
		if ("staticstring" in slot_table) delete slot_table.staticstring
		slot_table.datafunc <- func
		
		hud.__refresh()
	},
	
	PREFIX = true,
	POSTFIX = false,
	
	set_special = function(possessor, name, value, is_prefix = null, text = null) {
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
		local slot_table = ::__hud_data.layout.Fields[slot]
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
	},
	
	flags_set = function(possessor, name, flags) {
		__check_init()
		
		checktype(flags, "integer")
		
		local slot = __get_internal_index(possessor, name)
		local slot_table = ::__hud_data.layout.Fields[slot]
		slot_table.flags = flags
		
		hud.__refresh()
	},
	
	flags_add = function(possessor, name, flags) {
		__check_init()
		
		checktype(flags, "integer")
		
		local slot = __get_internal_index(possessor, name)
		local slot_table = ::__hud_data.layout.Fields[slot]
		__set_flags(slot_table, flags, true)
		
		hud.__refresh()
	},
	
	flags_remove = function(possessor, name, flags) {
		__check_init()
		
		checktype(flags, "integer")
		
		local slot = __get_internal_index(possessor, name)
		local slot_table = ::__hud_data.layout.Fields[slot]
		__set_flags(slot_table, flags, false)
		
		hud.__refresh()
	},
	
	posess_timer = function(possessor, timer_name) {
		__check_init()
		
		checktype(possessor, STRING)
		checktype(timer_name, STRING)
		
		local timer_to_posess = hud.__find_free_timer()
		if (timer_to_posess == -1) {
			log("cannot find free timer")
			return false
		}
		if (__get_timer_id(possessor, timer_name, true) != -1)
			throw format("timer name %s is already registered for possessor %s", timer_name.tostring(), possessor)
		
		::__hud_data.timers[timer_to_posess].possessor = possessor
		::__hud_data.timers[timer_to_posess].name = timer_name
		
		return true
	},
	
	release_timer = function(possessor, timer_name) {
		__check_init()
		
		local timer_to_release = __get_timer_id(possessor, timer_name)
		::__hud_data.timers[timer_to_release].possessor = null
		::__hud_data.timers[timer_to_release].name = null
		HUDManageTimers(timer_to_posess, TIMER_DISABLE, 0)
		::__hud_data.timers[timer_index].state == TIMER_DISABLE
	},
	
	disable_timer = function(possessor, timer_name) {
		__check_init()
		
		checktype(possessor, STRING)
		checktype(timer_name, STRING)
		
		local timer_index = __get_timer_id(possessor, timer_name)
		HUDManageTimers(timer_to_posess, TIMER_DISABLE, 0)
		::__hud_data.timers[timer_index].state == TIMER_DISABLE
	},
	
	set_timer = function(possessor, timer_name, value) {
		__check_init()
		
		checktype(value, NUMBER)
		
		local timer_index = __get_timer_id(possessor, timer_name)
		HUDManageTimers(timer_index, TIMER_STOP, 0)
		local old_state = ::__hud_data.timers[timer_index].state
		HUDManageTimers(timer_index, TIMER_SET, value)
		if (old_state == TIMER_COUNTDOWN) {
			HUDManageTimers(timer_index, TIMER_COUNTDOWN, value)
		} else if (old_state == TIMER_COUNTUP) {
			HUDManageTimers(timer_index, TIMER_COUNTUP, value)
		} else {
			::__hud_data.timers[timer_index].state = TIMER_STOP
		}
	},
	
	start_timer_countup = function(possessor, timer_name) {
		__check_init()
		
		local timer_index = __get_timer_id(possessor, timer_name)
		local old_state = ::__hud_data.timers[timer_index].state
		local value = HUDReadTimer(timer_index) //even for disabled
		HUDManageTimers(timer_index, TIMER_COUNTUP, value)
		::__hud_data.timers[timer_index].state = TIMER_COUNTUP
	},
	
	start_timer_countdown = function(possessor, timer_name) {
		__check_init()
		
		local timer_index = __get_timer_id(possessor, timer_name)
		local old_state = ::__hud_data.timers[timer_index].state
		local value = HUDReadTimer(timer_index) //even for disabled
		HUDManageTimers(timer_index, TIMER_COUNTDOWN, value)
		::__hud_data.timers[timer_index].state = TIMER_COUNTDOWN
	},
	
	pause_timer = function(possessor, timer_name) {
		__check_init()
		
		local timer_index = __get_timer_id(possessor, timer_name)
		local value = HUDReadTimer(timer_index) //even for disabled
		HUDManageTimers(timer_index, TIMER_STOP, 0)
		HUDManageTimers(timer_index, TIMER_SET, value)
		::__hud_data.timers[timer_index].state = TIMER_STOP
	},
	
	get_timer = function(possessor, timer_name) {
		__check_init()
		
		local timer_index = __get_timer_id(possessor, timer_name)
		return HUDReadTimer(timer_index)
	},
	
	set_timer_callback = function(possessor, timer_name, value, func, stop_timer = false) {
		__check_init()
		
		checktype(value, NUMBER)
		if (func != null) checktype(func, FUNC)
		checktype(stop_timer, BOOL)
		
		local timer_index = __get_timer_id(possessor, timer_name)
		if(::__hud_data.timer_callbacks.len() == 0) {
			register_ticker("__hud_callbacks", function() {
				foreach(key, callback in ::__hud_data.timer_callbacks) {
					local timer_index = callback.timer_index
					local state = ::__hud_data.timers[timer_index].state
					if (state == TIMER_DISABLE) {
						delete ::__hud_data.timer_callbacks[key]
						continue
					}
					local current_value = HUDReadTimer(timer_index)
					if (
						state == TIMER_COUNTUP && current_value >= callback.value
						|| state == TIMER_COUNTDOWN && current_value <= callback.value
					) {
						if (callback.func)
							callback.func()
						if (callback.stop_timer) {
							hud.pause_timer(callback.possessor, callback.name)
							hud.set_timer(callback.possessor, callback.name, value)
							//HUDManageTimers(timer_index, TIMER_STOP, 0)
							//HUDManageTimers(timer_index, TIMER_SET, value)
							//::__hud_data.timers[timer_index].state = TIMER_STOP
						}
						delete ::__hud_data.timer_callbacks[key]
					}
				}
				if (::__hud_data.timer_callbacks.len() == 0)
					remove_ticker("__hud_callbacks")
			})
		}
		::__hud_data.timer_callbacks[UniqueString()] <- {
			possessor = possessor,
			name = timer_name,
			value = value,
			func = func,
			stop_timer = stop_timer,
			timer_index = timer_index
		}
	},
	
	remove_timer_callbacks = function(possessor, timer_name) {
		__check_init()
		
		local timer_index = __get_timer_id(possessor, timer_name)
		foreach(key, callback in ::__hud_data.timer_callbacks)
			if (callback.possessor == possessor && callback.name = timer_name)
				delete ::__hud_data.timer_callbacks[key]
		if (::__hud_data.timer_callbacks.len() == 0)
			remove_ticker("__hud_callbacks")
	},
	
	global_off = function() {
		__check_init()
		::__hud_data.disabled = true
		hud.__refresh()
	},
	
	global_on = function() {
		__check_init()
		::__hud_data.disabled = false
		hud.__refresh()
	},
	
	global_clear = function() {
		__check_init()
		__hud_data_init()
		hud.__refresh()
	},
	
	show_message = function(text, duration = 5, background = true, float_up = false, x = 0.35, y = 0.75, w = 0.3, h = 0.05) {
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
		if (!hud.posess_slot("__show_message", slot_name)) {
			log("warning! no free slots for message: " + text)
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
		delayed_call(function() {
			hud.release_slot("__show_message", slot_name)
			if (float_up)
				remove_ticker("__show_message" + slot_name)
		}, duration)
		
		hud.__refresh()
	}
}

/////////////////////////////////////////////////

/*
 * This is physics data (mass and mass centers) of different physics models
 * here listed all models that have collision data file (.phy) and able to be a prop_physics
 * mass centers were retrieved using in-game physics engine testing, so they are not very accurate
 * models are sorted by mass and then by model path
 * some models have obviously wrong mass (especially those with a large mass)
 *
 */

phys <- {
	"models/props_vehicles/van001a_physics.mdl": {mass=10000.0,center=Vector(-15.36,5.04,2.40)}
	"models/props_wasteland/coolingtank02.mdl": {mass=8000.0,center=Vector(0.00,0.64,19.04)}
	"models/props_interiors/railing_128_breakable01.mdl": {mass=5000.0,center=Vector(0.00,-50.64,26.00)}
	"models/props_interiors/railing_64_breakable01.mdl": {mass=5000.0,center=Vector(0.00,-20.96,26.00)}
	"models/props_vehicles/trailer002a.mdl": {mass=5000.0,center=Vector(-23.04,-1.60,-9.04)}
	"models/props_doors/door_urban_rooftop_damaged_break.mdl": {mass=2963.51,center=Vector(0.00,4.00,52.24)}
	"models/props_vehicles/car004b.mdl": {mass=2500.0,center=Vector(-16.96,3.36,-0.64)}
	"models/props_vehicles/zapastl.mdl": {mass=2500.0,center=Vector(-0.96,0.00,-0.96)}
	"models/props_vehicles/helicopter_crashed_main.mdl": {mass=2000.0,center=Vector(-1.60,0.32,54.32)}
	"models/props_vehicles/news_van.mdl": {mass=2000.0,center=Vector(0.00,8.72,51.60)}
	"models/props_vehicles/van.mdl": {mass=2000.0,center=Vector(0.00,6.00,44.00)}
	"models/props_vehicles/airport_baggage_tractor.mdl": {mass=1800.0,center=Vector(0.00,9.04,25.36)}
	"models/props_fairgrounds/bumpercar.mdl": {mass=1515.4729,center=Vector(-4.64,0.00,12.40)}
	"models/props_foliage/tree_trunk_fallen.mdl": {mass=1500.0,center=Vector(-4.00,26.64,30.00)}
	"models/props_unique/airport/atlas_break_ball.mdl": {mass=1500.0,center=Vector(-1.36,-0.24,162.40)}
	"models/props_vehicles/cara_69sedan.mdl": {mass=1500.0,center=Vector(-0.64,-2.40,27.60)}
	"models/props_vehicles/cara_82hatchback.mdl": {mass=1500.0,center=Vector(-2.24,0.00,25.36)}
	"models/props_vehicles/cara_82hatchback_wrecked.mdl": {mass=1500.0,center=Vector(-4.00,-0.64,23.36)}
	"models/props_vehicles/cara_84sedan.mdl": {mass=1500.0,center=Vector(6.64,0.00,28.40)}
	"models/props_vehicles/cara_95sedan.mdl": {mass=1500.0,center=Vector(-5.36,0.00,26.64)}
	"models/props_vehicles/cara_95sedan_wrecked.mdl": {mass=1500.0,center=Vector(-3.04,0.00,24.96)}
	"models/props_vehicles/flatnose_truck.mdl": {mass=1500.0,center=Vector(18.40,-0.64,48.40)}
	"models/props_vehicles/flatnose_truck_wrecked.mdl": {mass=1500.0,center=Vector(20.96,33.68,-30.00)}
	"models/props_vehicles/flatnose_truck_wrecked_propercollision.mdl": {mass=1500.0,center=Vector(20.96,33.36,-30.00)}
	"models/props_vehicles/longnose_truck.mdl": {mass=1500.0,center=Vector(0.00,-51.60,59.04)}
	"models/props_vehicles/pickup_truck_2004.mdl": {mass=1500.0,center=Vector(4.64,0.00,43.04)}
	"models/props_vehicles/pickup_truck_78.mdl": {mass=1500.0,center=Vector(9.36,0.00,39.04)}
	"models/props_vehicles/police_car.mdl": {mass=1500.0,center=Vector(0.00,0.00,26.00)}
	"models/props_vehicles/police_car_city.mdl": {mass=1500.0,center=Vector(0.00,-0.96,25.36)}
	"models/props_vehicles/police_car_lights_on.mdl": {mass=1500.0,center=Vector(0.00,0.00,26.00)}
	"models/props_vehicles/police_car_opentrunk.mdl": {mass=1500.0,center=Vector(0.00,-5.36,26.00)}
	"models/props_vehicles/police_car_rural.mdl": {mass=1500.0,center=Vector(0.00,-0.96,24.96)}
	"models/props_vehicles/racecar.mdl": {mass=1500.0,center=Vector(-6.00,3.04,0.00)}
	"models/props_vehicles/suv_2001.mdl": {mass=1500.0,center=Vector(-14.64,0.00,44.64)}
	"models/props_vehicles/taxi_cab.mdl": {mass=1500.0,center=Vector(0.00,0.96,26.00)}
	"models/props_vehicles/taxi_city.mdl": {mass=1500.0,center=Vector(0.00,-0.96,25.36)}
	"models/props_vehicles/taxi_rural.mdl": {mass=1500.0,center=Vector(0.00,-0.96,25.36)}
	"models/props_vehicles/utility_truck.mdl": {mass=1500.0,center=Vector(-0.96,0.00,29.36)}
	"models/props_unique/airport/atlas.mdl": {mass=1000.0,center=Vector(-1.60,-0.96,115.04)}
	"models/props/cs_assault/forklift.mdl": {mass=800.0,center=Vector(0.00,38.40,27.60)}
	"models/props_fairgrounds/bumper_car01.mdl": {mass=800.0,center=Vector(0.00,0.00,10.64)}
	"models/props_junk/dumpster.mdl": {mass=800.0,center=Vector(-0.64,0.00,26.00)}
	"models/props_junk/dumpster_2.mdl": {mass=800.0,center=Vector(-0.64,0.00,26.00)}
	"models/props_unique/airport/atlas_break_frame.mdl": {mass=800.0,center=Vector(-0.96,-0.96,9.36)}
	"models/lostcoast/props_wasteland/cliff_stairs_stepset04.mdl": {mass=700.0,center=Vector(-3.04,0.00,-15.36)}
	"models/props_debris/concrete_chunk01c.mdl": {mass=694.1597,center=Vector(0.00,-0.96,-0.96)}
	"models/lostcoast/props_wasteland/cliff_stairs_deck01.mdl": {mass=650.0,center=Vector(4.00,-1.60,22.40)}
	"models/lostcoast/props_wasteland/cliff_stairs_support01.mdl": {mass=600.0,center=Vector(20.00,0.00,11.60)}
	"models/lostcoast/props_wasteland/cliff_stairs_support02.mdl": {mass=600.0,center=Vector(11.60,0.00,10.00)}
	"models/props_foliage/tree_trunk.mdl": {mass=563.9747,center=Vector(0.96,0.00,-3.04)}
	"models/props_unique/infectedbreakwall01_2x4core_main.mdl": {mass=501.0,center=Vector(0.00,0.00,6.00)}
	"models/props_unique/zombiebreakwallcore01_main.mdl": {mass=501.0,center=Vector(0.00,0.00,5.36)}
	"models/props_unique/zombiebreakwallcore01_steel.mdl": {mass=501.0,center=Vector(0.00,0.00,7.60)}
	"models/props_unique/zombiebreakwallexteriorairport01_main.mdl": {mass=501.0,center=Vector(3.36,0.00,0.00)}
	"models/props_unique/zombiebreakwallexteriorairportoffices01_main.mdl": {mass=501.0,center=Vector(3.36,0.00,0.00)}
	"models/props_unique/zombiebreakwallhospitalexterior01_main.mdl": {mass=501.0,center=Vector(3.36,0.00,0.00)}
	"models/lostcoast/props_wasteland/cliff_stairs_deck01_br02.mdl": {mass=500.0,center=Vector(-4.64,-0.64,29.36)}
	"models/props_equipment/gas_pump.mdl": {mass=500.0,center=Vector(-10.96,0.00,39.36)}
	"models/props_equipment/gas_pump_nodebris.mdl": {mass=500.0,center=Vector(-10.96,0.00,39.36)}
	"models/props_exteriors/wood_railing001.mdl": {mass=500.0,center=Vector(0.00,0.00,16.00)}
	"models/props_exteriors/wood_railing001_dm.mdl": {mass=500.0,center=Vector(0.00,0.00,16.00)}
	"models/props_foliage/swamp_fallentree01_bare.mdl": {mass=500.0,center=Vector(3.36,-22.40,16.00)}
	"models/props_industrial/brickpallets.mdl": {mass=500.0,center=Vector(0.00,0.00,-0.64)}
	"models/props_interiors/concretepillar01.mdl": {mass=500.0,center=Vector(0.00,0.00,0.00)}
	"models/props_interiors/concretepillar01_dm_base.mdl": {mass=500.0,center=Vector(0.00,0.00,-41.60)}
	"models/props_interiors/concretepiller01_dm01.mdl": {mass=500.0,center=Vector(0.00,0.00,-1.60)}
	"models/props_interiors/ibeam_breakable01_damaged02.mdl": {mass=500.0,center=Vector(-1.60,5.36,10.00)}
	"models/props_unique/haybails_single.mdl": {mass=500.0,center=Vector(-0.64,-0.64,26.00)}
	"models/props_unique/wooden_barricade_gascans.mdl": {mass=500.0,center=Vector(-0.64,0.00,10.64)}
	"models/props_vehicles/airport_baggage_cart2.mdl": {mass=500.0,center=Vector(0.64,0.00,55.36)}
	"models/props_vehicles/apc001.mdl": {mass=500.0,center=Vector(0.00,0.96,6.96)}
	"models/props_vehicles/apc_tire001.mdl": {mass=500.0,center=Vector(0.00,0.00,0.00)}
	"models/props_vehicles/car002a_physics.mdl": {mass=500.0,center=Vector(-3.04,0.00,-3.36)}
	"models/props_vehicles/car002b_physics.mdl": {mass=500.0,center=Vector(-8.40,0.96,-0.96)}
	"models/props_vehicles/car003a_physics.mdl": {mass=500.0,center=Vector(-10.00,1.60,-0.64)}
	"models/props_vehicles/car003b_physics.mdl": {mass=500.0,center=Vector(-5.04,-2.24,-0.64)}
	"models/props_vehicles/car004a_physics.mdl": {mass=500.0,center=Vector(-9.04,0.96,-2.40)}
	"models/props_vehicles/car004b_physics.mdl": {mass=500.0,center=Vector(-14.00,2.40,1.60)}
	"models/props_vehicles/car005a_physics.mdl": {mass=500.0,center=Vector(-10.64,1.60,-2.40)}
	"models/props_vehicles/car005b_physics.mdl": {mass=500.0,center=Vector(-16.96,3.04,2.24)}
	"models/props_vehicles/generatortrailer01.mdl": {mass=500.0,center=Vector(-20.96,0.00,33.36)}
	"models/props_junk/trashdumpster02.mdl": {mass=450.0,center=Vector(0.00,0.00,-9.04)}
	"models/lostcoast/props_wasteland/cliff_stairs_support01_br01.mdl": {mass=400.0,center=Vector(-4.64,0.00,16.00)}
	"models/lostcoast/props_wasteland/cliff_stairs_support02_br01.mdl": {mass=400.0,center=Vector(-4.00,0.00,32.40)}
	"models/props_vehicles/helicopter_crashed_chunk01.mdl": {mass=400.0,center=Vector(-0.64,-3.04,17.60)}
	"models/props_urban/fence002_128_breakable.mdl": {mass=358.86804,center=Vector(0.00,3.36,59.36)}
	"models/lostcoast/props_wasteland/boat_wooden01a.mdl": {mass=350.0,center=Vector(4.96,0.00,-4.00)}
	"models/lostcoast/props_wasteland/boat_wooden02a.mdl": {mass=350.0,center=Vector(-11.28,0.00,-6.00)}
	"models/lostcoast/props_wasteland/boat_wooden03a.mdl": {mass=350.0,center=Vector(5.36,0.00,-3.36)}
	"models/props_vehicles/boat_smash.mdl": {mass=325.0,center=Vector(0.00,-26.00,9.04)}
	"models/props_vehicles/boat_smash_break01.mdl": {mass=325.0,center=Vector(0.00,-10.64,6.96)}
	"models/props_urban/skylight.mdl": {mass=300.0,center=Vector(0.00,0.00,9.04)}
	"models/props_vehicles/helicopter_crashed_chunk02.mdl": {mass=300.0,center=Vector(-5.04,8.40,4.64)}
	"models/props_swamp/boardwalk_rail_256_break.mdl": {mass=261.35007,center=Vector(-0.64,8.24,-3.36)}
	"models/props_furniture/shelf1.mdl": {mass=251.0,center=Vector(-0.64,0.00,0.00)}
	"models/props_canal/boat001a.mdl": {mass=250.0,center=Vector(1.60,-0.64,-1.76)}
	"models/props_vehicles/boat_smash_break01b.mdl": {mass=250.0,center=Vector(4.40,-10.64,6.00)}
	"models/props_vehicles/boat_smash_break01c.mdl": {mass=250.0,center=Vector(-0.64,2.40,0.00)}
	"models/props_vehicles/boat_smash_break01d.mdl": {mass=250.0,center=Vector(-4.64,-10.96,6.64)}
	"models/props_vehicles/boat_smash_break02.mdl": {mass=250.0,center=Vector(-3.04,0.64,2.40)}
	"models/props_vehicles/boat_smash_break03.mdl": {mass=250.0,center=Vector(3.04,0.00,2.24)}
	"models/props_vehicles/boat_smash_break04.mdl": {mass=250.0,center=Vector(1.60,-0.96,0.64)}
	"models/props_vehicles/boat_smash_break05.mdl": {mass=250.0,center=Vector(5.36,-5.60,0.96)}
	"models/props_vehicles/boat_smash_break06.mdl": {mass=250.0,center=Vector(-2.40,0.64,4.64)}
	"models/props_vehicles/boat_smash_break07.mdl": {mass=250.0,center=Vector(-0.64,-1.60,1.60)}
	"models/props_vehicles/boat_smash_break08.mdl": {mass=250.0,center=Vector(-2.40,-1.60,0.96)}
	"models/props_vehicles/boat_smash_break09.mdl": {mass=250.0,center=Vector(6.00,-1.60,2.40)}
	"models/props_vehicles/boat_smash_break10.mdl": {mass=250.0,center=Vector(0.00,-0.64,0.00)}
	"models/props_vehicles/boat_smash_break11.mdl": {mass=250.0,center=Vector(1.60,3.04,0.64)}
	"models/props_vehicles/boat_smash_break12.mdl": {mass=250.0,center=Vector(-0.96,-0.64,0.96)}
	"models/props_vehicles/helicopter_crashed_chunk03.mdl": {mass=250.0,center=Vector(-15.60,-3.36,4.40)}
	"models/props_exteriors/guardshack_remains.mdl": {mass=222.27107,center=Vector(-7.28,-0.96,12.40)}
	"models/props_swamp/boardwalk_rail_256_break_b.mdl": {mass=216.33424,center=Vector(-0.96,34.64,-2.40)}
	"models/props_swamp/boardwalk_rail_256_break_a.mdl": {mass=216.2684,center=Vector(-0.96,-19.04,-2.40)}
	"models/props_debris/concrete_chunk07a.mdl": {mass=209.55882,center=Vector(3.36,-0.96,-1.60)}
	"models/lostcoast/props_wasteland/cliff_stairs_deck03.mdl": {mass=200.0,center=Vector(0.00,0.00,0.00)}
	"models/lostcoast/props_wasteland/cliff_stairs_stepset03.mdl": {mass=200.0,center=Vector(-4.00,-3.36,-16.64)}
	"models/lostcoast/props_wasteland/cliff_stairs_support01_br02.mdl": {mass=200.0,center=Vector(38.40,0.00,-2.40)}
	"models/lostcoast/props_wasteland/cliff_stairs_support02_br02.mdl": {mass=200.0,center=Vector(38.40,0.00,-2.40)}
	"models/lostcoast/props_wasteland/cliff_stairs_support03.mdl": {mass=200.0,center=Vector(0.00,3.04,16.96)}
	"models/props_foliage/flower_barrel_dead.mdl": {mass=200.0,center=Vector(0.00,0.00,13.36)}
	"models/props_furniture/piano.mdl": {mass=200.0,center=Vector(-9.04,0.00,33.36)}
	"models/props_debris/concrete_chunk02a.mdl": {mass=166.72064,center=Vector(-1.60,0.00,0.00)}
	"models/lostcoast/props_wasteland/cliff_stairs_stepset05_br01.mdl": {mass=150.0,center=Vector(6.00,17.76,-4.00)}
	"models/lostcoast/props_wasteland/cliff_stairs_stepset05_br02.mdl": {mass=150.0,center=Vector(-3.04,-19.04,-28.40)}
	"models/props/cs_office/file_cabinet1_group.mdl": {mass=150.0,center=Vector(-0.64,0.00,31.60)}
	"models/props_c17/furnituredresser001a.mdl": {mass=150.0,center=Vector(0.00,0.00,4.00)}
	"models/props_furniture/dresser1.mdl": {mass=150.0,center=Vector(0.00,0.00,3.36)}
	"models/props_industrial/brickpallets_break01.mdl": {mass=150.0,center=Vector(0.00,0.00,0.00)}
	"models/props_industrial/brickpallets_break02.mdl": {mass=150.0,center=Vector(0.00,0.00,0.00)}
	"models/props_industrial/brickpallets_break03.mdl": {mass=150.0,center=Vector(0.00,0.00,0.00)}
	"models/props_industrial/brickpallets_break04.mdl": {mass=150.0,center=Vector(0.00,0.00,0.00)}
	"models/props_industrial/brickpallets_break05.mdl": {mass=150.0,center=Vector(0.64,0.00,-0.64)}
	"models/props_industrial/brickpallets_break06.mdl": {mass=150.0,center=Vector(0.00,0.00,0.00)}
	"models/props_industrial/brickpallets_break07.mdl": {mass=150.0,center=Vector(0.00,0.00,0.00)}
	"models/props_industrial/brickpallets_break08.mdl": {mass=150.0,center=Vector(0.00,0.00,0.00)}
	"models/props_interiors/file_cabinet1_group.mdl": {mass=150.0,center=Vector(-0.64,0.00,31.60)}
	"models/props_vehicles/tire001a_tractor.mdl": {mass=125.0,center=Vector(0.00,0.00,0.00)}
	"models/lostcoast/props_wasteland/cliff_stairs_deck03_br01.mdl": {mass=100.0,center=Vector(4.64,15.60,6.00)}
	"models/lostcoast/props_wasteland/cliff_stairs_deck03_br02.mdl": {mass=100.0,center=Vector(5.04,-35.36,-39.36)}
	"models/lostcoast/props_wasteland/cliff_stairs_stepset03_br01.mdl": {mass=100.0,center=Vector(-9.04,12.24,-4.96)}
	"models/lostcoast/props_wasteland/cliff_stairs_stepset03_br02.mdl": {mass=100.0,center=Vector(4.96,-35.36,-39.36)}
	"models/lostcoast/props_wasteland/cliff_stairs_stepset04_br01.mdl": {mass=100.0,center=Vector(6.64,54.64,22.40)}
	"models/lostcoast/props_wasteland/cliff_stairs_stepset04_br02.mdl": {mass=100.0,center=Vector(-9.04,-33.36,-37.60)}
	"models/lostcoast/props_wasteland/cliff_stairs_stepset06.mdl": {mass=100.0,center=Vector(-2.40,-0.64,-10.96)}
	"models/lostcoast/props_wasteland/cliff_stairs_support03_br01.mdl": {mass=100.0,center=Vector(0.00,-14.00,19.36)}
	"models/lostcoast/props_wasteland/cliff_stairs_support03_br02.mdl": {mass=100.0,center=Vector(0.00,45.04,10.64)}
	"models/lostcoast/props_wasteland/gate01a.mdl": {mass=100.0,center=Vector(0.00,22.40,-3.04)}
	"models/lostcoast/props_wasteland/gate01b.mdl": {mass=100.0,center=Vector(0.00,-25.04,-3.04)}
	"models/props/cs_assault/handtruck.mdl": {mass=100.0,center=Vector(10.64,0.00,10.00)}
	"models/props_doors/checkpoint_doorframe_-01.mdl": {mass=100.0,center=Vector(0.00,-26.64,13.36)}
	"models/props_doors/checkpoint_doorframe_01.mdl": {mass=100.0,center=Vector(0.00,-26.64,13.36)}
	"models/props_exteriors/concrete_plant01_railing_breakable01.mdl": {mass=100.0,center=Vector(130.40,-162.40,150.24)}
	"models/props_exteriors/concrete_plant01_railing_breakable02.mdl": {mass=100.0,center=Vector(149.60,-162.40,162.40)}
	"models/props_exteriors/concrete_plant01_railing_breakable03.mdl": {mass=100.0,center=Vector(50.40,-162.40,162.40)}
	"models/props_exteriors/guardshack.mdl": {mass=100.0,center=Vector(0.00,0.00,54.64)}
	"models/props_exteriors/lighthouserailing_01_a.mdl": {mass=100.0,center=Vector(162.40,-101.60,25.12)}
	"models/props_exteriors/lighthouserailing_02_a.mdl": {mass=100.0,center=Vector(162.40,109.60,21.20)}
	"models/props_exteriors/lighthouserailing_03_a.mdl": {mass=100.0,center=Vector(136.72,162.40,36.64)}
	"models/props_exteriors/lighthouserailing_04_a.mdl": {mass=100.0,center=Vector(-25.04,0.64,30.96)}
	"models/props_exteriors/lighthouserailing_05_a.mdl": {mass=100.0,center=Vector(-162.40,114.40,24.72)}
	"models/props_exteriors/lighthouserailing_06_a.mdl": {mass=100.0,center=Vector(-162.40,-127.20,32.40)}
	"models/props_exteriors/lighthouserailing_07_a.mdl": {mass=100.0,center=Vector(34.96,-0.96,31.60)}
	"models/props_fairgrounds/bumper_car01_pole.mdl": {mass=100.0,center=Vector(0.00,0.00,64.00)}
	"models/props_fairgrounds/traffic_barrel.mdl": {mass=100.0,center=Vector(0.00,0.00,19.36)}
	"models/props_furniture/desk1.mdl": {mass=100.0,center=Vector(0.00,0.00,11.76)}
	"models/props_industrial/barrel_fuel.mdl": {mass=100.0,center=Vector(0.00,0.00,22.40)}
	"models/props_industrial/pallet_barrels_water01_single.mdl": {mass=100.0,center=Vector(0.00,0.00,22.40)}
	"models/props_interiors/concretepiller01_dm01_1.mdl": {mass=100.0,center=Vector(7.92,-0.64,17.60)}
	"models/props_interiors/concretepiller01_dm01_2.mdl": {mass=100.0,center=Vector(-1.60,-8.24,1.60)}
	"models/props_interiors/concretepiller01_dm01_3.mdl": {mass=100.0,center=Vector(-0.96,1.60,-12.40)}
	"models/props_interiors/concretepiller01_dm01_4.mdl": {mass=100.0,center=Vector(-4.64,6.32,16.00)}
	"models/props_interiors/constructionwalls04.mdl": {mass=100.0,center=Vector(0.00,0.64,95.36)}
	"models/props_interiors/furniture_desk01a.mdl": {mass=100.0,center=Vector(0.00,0.00,12.40)}
	"models/props_interiors/ibeam_breakable01.mdl": {mass=100.0,center=Vector(0.00,0.00,0.00)}
	"models/props_interiors/refrigerator03.mdl": {mass=100.0,center=Vector(0.64,0.00,35.36)}
	"models/props_interiors/sink_industrial01.mdl": {mass=100.0,center=Vector(-2.40,0.00,34.00)}
	"models/props_interiors/stove02.mdl": {mass=100.0,center=Vector(0.00,0.00,20.00)}
	"models/props_interiors/tablecafe_square01.mdl": {mass=100.0,center=Vector(0.00,0.00,29.04)}
	"models/props_office/filecabinet01.mdl": {mass=100.0,center=Vector(-0.64,0.00,31.60)}
	"models/props_unique/airport/atlas_break01.mdl": {mass=100.0,center=Vector(-14.32,-8.72,51.92)}
	"models/props_unique/airport/atlas_break02.mdl": {mass=100.0,center=Vector(27.60,-16.64,44.72)}
	"models/props_unique/airport/atlas_break03.mdl": {mass=100.0,center=Vector(17.28,-14.00,60.64)}
	"models/props_unique/airport/atlas_break04.mdl": {mass=100.0,center=Vector(-14.96,-9.36,77.12)}
	"models/props_unique/airport/atlas_break05.mdl": {mass=100.0,center=Vector(-10.32,-1.84,98.88)}
	"models/props_unique/airport/atlas_break06.mdl": {mass=100.0,center=Vector(6.96,10.32,102.72)}
	"models/props_unique/airport/atlas_break07.mdl": {mass=100.0,center=Vector(-34.00,24.40,121.60)}
	"models/props_unique/airport/atlas_break08.mdl": {mass=100.0,center=Vector(28.24,-32.40,123.36)}
	"models/props_unique/airport/atlas_break09.mdl": {mass=100.0,center=Vector(12.40,-25.36,104.64)}
	"models/props_unique/infectedbreakwall01_mainframe_dm.mdl": {mass=100.0,center=Vector(3.36,-0.64,1.60)}
	"models/props_unique/staircase_spiral01_stair01.mdl": {mass=100.0,center=Vector(-14.00,66.96,48.40)}
	"models/props_unique/staircase_spiral01_stair02.mdl": {mass=100.0,center=Vector(-58.40,-14.64,80.64)}
	"models/props_unique/staircase_spiral01_stair03.mdl": {mass=100.0,center=Vector(28.00,-58.40,116.00)}
	"models/props_unique/staircase_spiral01_stair04.mdl": {mass=100.0,center=Vector(51.60,42.64,151.20)}
	"models/props_unique/zombiebreakwallcorepart01_steel_dm.mdl": {mass=100.0,center=Vector(-0.96,-0.64,-2.40)}
	"models/props_unique/zombiebreakwallexteriorairport01frame.mdl": {mass=100.0,center=Vector(3.36,0.00,1.60)}
	"models/props_unique/zombiebreakwallexteriorairportoffices01frame.mdl": {mass=100.0,center=Vector(4.00,0.00,1.60)}
	"models/props_unique/zombiebreakwallexteriorairportofficespart01_dm.mdl": {mass=100.0,center=Vector(0.00,-1.60,0.00)}
	"models/props_unique/zombiebreakwallexteriorairportofficespart02_dm.mdl": {mass=100.0,center=Vector(0.00,0.00,-0.64)}
	"models/props_unique/zombiebreakwallexteriorairportofficespart03_dm.mdl": {mass=100.0,center=Vector(0.00,0.64,-0.64)}
	"models/props_unique/zombiebreakwallexteriorairportofficespart04_dm.mdl": {mass=100.0,center=Vector(0.00,1.60,1.60)}
	"models/props_unique/zombiebreakwallexteriorairportofficespart05_dm.mdl": {mass=100.0,center=Vector(0.00,1.60,2.40)}
	"models/props_unique/zombiebreakwallexteriorairportofficespart06_dm.mdl": {mass=100.0,center=Vector(0.00,-0.64,3.36)}
	"models/props_unique/zombiebreakwallexteriorairportofficespart07_dm.mdl": {mass=100.0,center=Vector(0.00,0.96,2.24)}
	"models/props_unique/zombiebreakwallexteriorairportofficespart08_dm.mdl": {mass=100.0,center=Vector(0.00,-2.40,2.40)}
	"models/props_unique/zombiebreakwallexteriorairportofficespart09_dm.mdl": {mass=100.0,center=Vector(0.00,0.64,-0.64)}
	"models/props_unique/zombiebreakwallexteriorairportpart01_dm.mdl": {mass=100.0,center=Vector(0.00,-1.60,0.00)}
	"models/props_unique/zombiebreakwallexteriorairportpart02_dm.mdl": {mass=100.0,center=Vector(0.00,0.00,-0.64)}
	"models/props_unique/zombiebreakwallexteriorairportpart03_dm.mdl": {mass=100.0,center=Vector(0.00,0.64,-0.64)}
	"models/props_unique/zombiebreakwallexteriorairportpart04_dm.mdl": {mass=100.0,center=Vector(0.00,0.96,1.60)}
	"models/props_unique/zombiebreakwallexteriorairportpart05_dm.mdl": {mass=100.0,center=Vector(0.00,1.60,2.24)}
	"models/props_unique/zombiebreakwallexteriorairportpart06_dm.mdl": {mass=100.0,center=Vector(0.00,-0.64,3.36)}
	"models/props_unique/zombiebreakwallexteriorairportpart07_dm.mdl": {mass=100.0,center=Vector(0.00,0.96,1.76)}
	"models/props_unique/zombiebreakwallexteriorairportpart08_dm.mdl": {mass=100.0,center=Vector(0.00,-2.40,2.40)}
	"models/props_unique/zombiebreakwallexteriorairportpart09_dm.mdl": {mass=100.0,center=Vector(0.00,0.64,-0.64)}
	"models/props_unique/zombiebreakwallexteriorhospitalframe01_dm.mdl": {mass=100.0,center=Vector(3.36,-0.64,2.24)}
	"models/props_unique/zombiebreakwallexteriorpart04_dm.mdl": {mass=100.0,center=Vector(0.00,1.60,1.60)}
	"models/props_unique/zombiebreakwallexteriorpart06_dm.mdl": {mass=100.0,center=Vector(0.00,-0.96,3.04)}
	"models/props_unique/zombiebreakwallinterior01_brick_dm_frame.mdl": {mass=100.0,center=Vector(0.00,-0.64,1.60)}
	"models/props_unique/zombiebreakwallinterior01_concrete_dm_frame.mdl": {mass=100.0,center=Vector(-0.64,0.00,1.76)}
	"models/props_unique/zombiebreakwallinterior01_concrete_dm_part03.mdl": {mass=100.0,center=Vector(0.00,-0.64,2.40)}
	"models/props_unique/zombiebreakwallinterior01_concrete_dm_part04.mdl": {mass=100.0,center=Vector(-0.64,-0.64,-4.00)}
	"models/props_vehicles/carparts_axel01a.mdl": {mass=100.0,center=Vector(0.00,0.96,-1.60)}
	"models/props_vehicles/helicopter_crashed_chunk04.mdl": {mass=100.0,center=Vector(1.60,4.00,3.36)}
	"models/props_vehicles/helicopter_crashed_chunk05.mdl": {mass=100.0,center=Vector(0.96,-0.96,3.04)}
	"models/props_vehicles/helicopter_crashed_chunk06.mdl": {mass=100.0,center=Vector(-1.76,-4.00,5.04)}
	"models/props_vehicles/helicopter_crashed_chunk07.mdl": {mass=100.0,center=Vector(3.36,5.04,3.04)}
	"models/props_vehicles/helicopter_crashed_chunk08.mdl": {mass=100.0,center=Vector(4.00,0.64,13.36)}
	"models/props_windows/hotel_door_sliding_chips.mdl": {mass=100.0,center=Vector(0.00,94.00,56.00)}
	"models/props_windows/hotel_door_sliding_glass001.mdl": {mass=100.0,center=Vector(0.00,28.40,48.40)}
	"models/props_windows/hotel_door_sliding_glass002.mdl": {mass=100.0,center=Vector(0.00,28.40,48.40)}
	"models/props_windows/hotel_door_sliding_glass003.mdl": {mass=100.0,center=Vector(0.00,29.04,48.40)}
	"models/props_windows/hotel_window002_break001_1.mdl": {mass=100.0,center=Vector(0.00,26.00,10.96)}
	"models/props_windows/hotel_window002_break001_10.mdl": {mass=100.0,center=Vector(0.00,50.00,75.04)}
	"models/props_windows/hotel_window002_break001_2.mdl": {mass=100.0,center=Vector(0.00,44.64,17.60)}
	"models/props_windows/hotel_window002_break001_3.mdl": {mass=100.0,center=Vector(0.00,55.04,27.60)}
	"models/props_windows/hotel_window002_break001_4.mdl": {mass=100.0,center=Vector(0.00,24.64,81.60)}
	"models/props_windows/hotel_window002_break001_5.mdl": {mass=100.0,center=Vector(0.00,26.00,64.96)}
	"models/props_windows/hotel_window002_break001_6.mdl": {mass=100.0,center=Vector(0.00,2.40,51.76)}
	"models/props_windows/hotel_window002_break001_7.mdl": {mass=100.0,center=Vector(0.00,5.04,11.60)}
	"models/props_windows/hotel_window002_break001_8.mdl": {mass=100.0,center=Vector(0.00,30.00,45.04)}
	"models/props_windows/hotel_window002_break001_9.mdl": {mass=100.0,center=Vector(0.00,9.04,26.96)}
	"models/props_windows/hotel_window002_break002_1.mdl": {mass=100.0,center=Vector(0.00,56.96,51.60)}
	"models/props_windows/hotel_window002_break002_2.mdl": {mass=100.0,center=Vector(0.00,50.00,64.00)}
	"models/props_windows/hotel_window002_break002_3.mdl": {mass=100.0,center=Vector(0.00,51.60,82.40)}
	"models/props_windows/hotel_window002_break002_4.mdl": {mass=100.0,center=Vector(0.00,40.64,2.40)}
	"models/props_windows/hotel_window002_break002_6.mdl": {mass=100.0,center=Vector(0.00,6.00,75.36)}
	"models/props_windows/hotel_window002_break002_7.mdl": {mass=100.0,center=Vector(0.00,5.04,46.64)}
	"models/props_windows/hotel_window002_break002_8.mdl": {mass=100.0,center=Vector(0.00,56.00,20.96)}
	"models/props_windows/hotel_window002_break002_9.mdl": {mass=100.0,center=Vector(0.00,5.36,16.64)}
	"models/props_windows/hotel_window002_break003_8.mdl": {mass=100.0,center=Vector(0.00,30.00,38.40)}
	"models/props_windows/hotel_window002_break003_9.mdl": {mass=100.0,center=Vector(0.00,7.60,23.04)}
	"models/props_windows/hotel_window_break001_1.mdl": {mass=100.0,center=Vector(0.64,26.00,10.96)}
	"models/props_windows/hotel_window_break001_10.mdl": {mass=100.0,center=Vector(0.64,49.36,86.64)}
	"models/props_windows/hotel_window_break001_2.mdl": {mass=100.0,center=Vector(0.64,44.64,18.40)}
	"models/props_windows/hotel_window_break001_3.mdl": {mass=100.0,center=Vector(0.64,54.96,28.40)}
	"models/props_windows/hotel_window_break001_4.mdl": {mass=100.0,center=Vector(0.64,24.32,97.60)}
	"models/props_windows/hotel_window_break001_5.mdl": {mass=100.0,center=Vector(0.96,26.00,75.36)}
	"models/props_windows/hotel_window_break001_6.mdl": {mass=100.0,center=Vector(0.64,2.40,57.76)}
	"models/props_windows/hotel_window_break001_7.mdl": {mass=100.0,center=Vector(0.64,4.64,11.60)}
	"models/props_windows/hotel_window_break001_8.mdl": {mass=100.0,center=Vector(0.64,30.00,45.36)}
	"models/props_windows/hotel_window_break001_9.mdl": {mass=100.0,center=Vector(0.64,9.04,27.60)}
	"models/props_windows/hotel_window_break002_1.mdl": {mass=100.0,center=Vector(0.64,60.00,58.40)}
	"models/props_windows/hotel_window_break002_2.mdl": {mass=100.0,center=Vector(0.64,53.04,66.00)}
	"models/props_windows/hotel_window_break002_3.mdl": {mass=100.0,center=Vector(0.64,54.64,94.64)}
	"models/props_windows/hotel_window_break002_4.mdl": {mass=100.0,center=Vector(0.64,42.40,-0.64)}
	"models/props_windows/hotel_window_break002_5.mdl": {mass=100.0,center=Vector(0.00,52.40,33.36)}
	"models/props_windows/hotel_window_break002_6.mdl": {mass=100.0,center=Vector(0.64,4.64,85.04)}
	"models/props_windows/hotel_window_break002_7.mdl": {mass=100.0,center=Vector(0.64,3.36,54.00)}
	"models/props_windows/hotel_window_break002_8.mdl": {mass=100.0,center=Vector(0.64,59.36,22.40)}
	"models/props_windows/hotel_window_break002_9.mdl": {mass=100.0,center=Vector(0.64,4.00,15.36)}
	"models/props_windows/hotel_window_break003_8.mdl": {mass=100.0,center=Vector(0.64,30.00,45.04)}
	"models/props_windows/hotel_window_break003_9.mdl": {mass=100.0,center=Vector(0.64,6.96,26.96)}
	"models/props_windows/hotel_window_glass001.mdl": {mass=100.0,center=Vector(0.00,28.40,40.64)}
	"models/props_windows/hotel_window_glass002.mdl": {mass=100.0,center=Vector(0.00,28.40,48.40)}
	"models/props_windows/hotel_window_glass003.mdl": {mass=100.0,center=Vector(0.00,29.04,40.00)}
	"models/props_windows/window_farmhouse_big.mdl": {mass=100.0,center=Vector(0.00,0.00,3.04)}
	"models/props_windows/window_farmhouse_big_frame.mdl": {mass=100.0,center=Vector(0.00,0.00,-4.00)}
	"models/props_windows/window_farmhouse_small.mdl": {mass=100.0,center=Vector(0.00,0.00,2.40)}
	"models/props_windows/window_farmhouse_small_frame.mdl": {mass=100.0,center=Vector(0.00,0.00,-4.00)}
	"models/props_windows/window_industrial.mdl": {mass=100.0,center=Vector(0.00,0.00,44.64)}
	"models/props_windows/window_industrial_frame.mdl": {mass=100.0,center=Vector(0.00,0.00,44.64)}
	"models/props_windows/window_urban_apt.mdl": {mass=100.0,center=Vector(0.00,0.00,2.40)}
	"models/props_windows/window_urban_apt_frame.mdl": {mass=100.0,center=Vector(0.00,0.00,-4.00)}
	"models/props_windows/window_urban_sash_32_72_full.mdl": {mass=100.0,center=Vector(0.00,0.00,36.00)}
	"models/props_windows/window_urban_sash_48_88_full.mdl": {mass=100.0,center=Vector(0.00,0.00,44.00)}
	"models/props_foliage/flower_barrel.mdl": {mass=90.0,center=Vector(0.00,0.00,13.36)}
	"models/props_foliage/tree_trunk_chunk01.mdl": {mass=85.0,center=Vector(-3.04,-0.96,5.36)}
	"models/props_foliage/tree_trunk_chunk02.mdl": {mass=85.0,center=Vector(6.64,-4.00,18.40)}
	"models/props_foliage/tree_trunk_chunk03.mdl": {mass=85.0,center=Vector(6.96,-10.00,-14.00)}
	"models/props_foliage/tree_trunk_chunk04.mdl": {mass=85.0,center=Vector(4.00,11.76,10.64)}
	"models/props_foliage/tree_trunk_chunk05.mdl": {mass=85.0,center=Vector(1.60,9.36,-14.96)}
	"models/props_foliage/tree_trunk_chunk06.mdl": {mass=85.0,center=Vector(-9.36,-4.32,-15.04)}
	"models/props_fairgrounds/strongmangame_bell.mdl": {mass=80.0,center=Vector(0.00,1.76,0.00)}
	"models/props_interiors/sofa.mdl": {mass=80.0,center=Vector(-2.40,0.00,14.96)}
	"models/props_vehicles/car001a_phy.mdl": {mass=79.96392,center=Vector(-6.96,-3.04,-0.96)}
	"models/props_vehicles/tire001b_truck.mdl": {mass=75.0,center=Vector(0.00,0.00,0.00)}
	"models/props_interiors/prison_heater001a.mdl": {mass=70.0,center=Vector(4.00,0.64,0.00)}
	"models/props_interiors/table_picnic.mdl": {mass=70.0,center=Vector(0.00,0.00,20.00)}
	"models/props_vehicles/boat_smash_gib07.mdl": {mass=68.248726,center=Vector(-1.60,0.00,-1.60)}
	"models/props_c17/furnituretable001a.mdl": {mass=60.0,center=Vector(0.64,0.64,14.64)}
	"models/props_junk/wheebarrow01a.mdl": {mass=60.0,center=Vector(2.24,0.00,6.00)}
	"models/props_junk/wood_crate002a.mdl": {mass=60.0,center=Vector(0.00,0.00,0.00)}
	"models/props_plants/pottedplant_tall01_p1.mdl": {mass=60.0,center=Vector(0.00,0.00,7.60)}
	"models/props_wasteland/controlroom_filecabinet001a.mdl": {mass=60.0,center=Vector(-0.64,0.00,0.00)}
	"models/props_wasteland/controlroom_filecabinet002a.mdl": {mass=60.0,center=Vector(-0.96,0.00,0.00)}
	"models/props_vehicles/car001b_phy.mdl": {mass=56.60888,center=Vector(6.00,-0.96,-6.00)}
	"models/lostcoast/props_wasteland/cliff_stairs_2stair01.mdl": {mass=50.0,center=Vector(0.00,0.00,0.00)}
	"models/lostcoast/props_wasteland/cliff_stairs_stepset06_br01.mdl": {mass=50.0,center=Vector(0.64,10.64,-3.36)}
	"models/lostcoast/props_wasteland/cliff_stairs_stepset06_br02.mdl": {mass=50.0,center=Vector(-0.96,-13.36,-20.64)}
	"models/props/cs_assault/barrelwarning.mdl": {mass=50.0,center=Vector(0.00,0.00,16.64)}
	"models/props/cs_assault/ladderaluminium128.mdl": {mass=50.0,center=Vector(2.24,0.00,0.00)}
	"models/props/cs_office/file_cabinet1.mdl": {mass=50.0,center=Vector(-0.64,0.00,31.60)}
	"models/props/cs_office/file_cabinet2.mdl": {mass=50.0,center=Vector(-0.64,0.00,31.60)}
	"models/props/cs_office/file_cabinet3.mdl": {mass=50.0,center=Vector(0.00,0.00,23.36)}
	"models/props/de_train/ladderaluminium.mdl": {mass=50.0,center=Vector(1.60,0.00,0.64)}
	"models/props_buildables/plank_barricade01.mdl": {mass=50.0,center=Vector(0.64,-0.64,48.40)}
	"models/props_buildables/plank_barricade01_dmg01.mdl": {mass=50.0,center=Vector(0.96,-0.64,50.64)}
	"models/props_buildables/plank_barricade01_dmg02.mdl": {mass=50.0,center=Vector(1.60,-0.96,50.64)}
	"models/props_buildables/plank_barricade01_dmg03.mdl": {mass=50.0,center=Vector(1.60,-3.04,50.64)}
	"models/props_buildables/plank_barricade01_dmg04.mdl": {mass=50.0,center=Vector(2.40,-3.36,54.64)}
	"models/props_buildables/plank_barricade01_dmg05.mdl": {mass=50.0,center=Vector(2.40,-0.96,49.04)}
	"models/props_buildables/plank_barricade01_dmg06.mdl": {mass=50.0,center=Vector(0.64,-0.64,53.36)}
	"models/props_c17/chair_stool01a.mdl": {mass=50.0,center=Vector(0.00,0.96,26.96)}
	"models/props_c17/consolebox01a.mdl": {mass=50.0,center=Vector(0.64,0.00,5.36)}
	"models/props_debris/wood_barricade.mdl": {mass=50.0,center=Vector(0.00,0.00,0.00)}
	"models/props_doors/checkpoint_door_-01.mdl": {mass=50.0,center=Vector(0.00,-26.64,-4.00)}
	"models/props_doors/checkpoint_door_-01_static.mdl": {mass=50.0,center=Vector(0.00,-26.64,-4.00)}
	"models/props_doors/checkpoint_door_-02.mdl": {mass=50.0,center=Vector(0.00,-26.64,0.00)}
	"models/props_doors/checkpoint_door_-02_static.mdl": {mass=50.0,center=Vector(0.00,-26.64,0.00)}
	"models/props_doors/checkpoint_door_01.mdl": {mass=50.0,center=Vector(0.00,-26.64,-4.40)}
	"models/props_doors/checkpoint_door_01_static.mdl": {mass=50.0,center=Vector(0.00,-26.64,-4.00)}
	"models/props_doors/checkpoint_door_02.mdl": {mass=50.0,center=Vector(0.00,-26.64,0.00)}
	"models/props_doors/checkpoint_door_02_static.mdl": {mass=50.0,center=Vector(0.00,-26.64,0.00)}
	"models/props_doors/doordm01_01.mdl": {mass=50.0,center=Vector(0.00,-27.76,-0.64)}
	"models/props_doors/doordm02_01.mdl": {mass=50.0,center=Vector(0.00,-27.60,-0.64)}
	"models/props_doors/doordm03_01.mdl": {mass=50.0,center=Vector(0.00,-27.76,-2.40)}
	"models/props_doors/doordm_rural01_01.mdl": {mass=50.0,center=Vector(0.00,-27.76,0.00)}
	"models/props_doors/doordm_rural02_01.mdl": {mass=50.0,center=Vector(0.00,-27.60,-0.64)}
	"models/props_doors/doordm_rural03_01.mdl": {mass=50.0,center=Vector(0.00,-28.40,-2.40)}
	"models/props_doors/doorfreezer01.mdl": {mass=50.0,center=Vector(0.00,-29.04,-1.60)}
	"models/props_doors/doorglassmain01.mdl": {mass=50.0,center=Vector(0.00,-27.60,-10.96)}
	"models/props_doors/doorglassmain01_dm01.mdl": {mass=50.0,center=Vector(0.00,-27.60,-12.40)}
	"models/props_doors/doorglassmain01_dm02.mdl": {mass=50.0,center=Vector(0.00,-26.96,-11.60)}
	"models/props_doors/doorglassmain01_small.mdl": {mass=50.0,center=Vector(0.00,-24.00,-12.40)}
	"models/props_doors/doorglassmain01_small_dm01.mdl": {mass=50.0,center=Vector(0.00,-24.00,-12.40)}
	"models/props_doors/doorglassmain01_small_dm02.mdl": {mass=50.0,center=Vector(0.00,-23.36,-11.60)}
	"models/props_doors/doormain01.mdl": {mass=50.0,center=Vector(0.00,-27.60,0.00)}
	"models/props_doors/doormain01_airport.mdl": {mass=50.0,center=Vector(0.00,-27.76,0.00)}
	"models/props_doors/doormain01_airport_small.mdl": {mass=50.0,center=Vector(0.00,-24.00,0.00)}
	"models/props_doors/doormain01_small.mdl": {mass=50.0,center=Vector(0.00,-24.00,0.00)}
	"models/props_doors/doormain01_small_01.mdl": {mass=50.0,center=Vector(0.00,-24.64,0.00)}
	"models/props_doors/doormain02_small_01.mdl": {mass=50.0,center=Vector(0.00,-24.00,-0.64)}
	"models/props_doors/doormain03_small_01.mdl": {mass=50.0,center=Vector(0.00,-24.64,-2.40)}
	"models/props_doors/doormain_rural01.mdl": {mass=50.0,center=Vector(0.00,-28.24,0.00)}
	"models/props_doors/doormain_rural01_small.mdl": {mass=50.0,center=Vector(0.00,-24.00,0.00)}
	"models/props_doors/doormain_rural01_small_01.mdl": {mass=50.0,center=Vector(0.00,-24.00,-0.64)}
	"models/props_doors/doormain_rural02_small_01.mdl": {mass=50.0,center=Vector(0.00,-24.00,-0.64)}
	"models/props_doors/doormain_rural03_small_01.mdl": {mass=50.0,center=Vector(0.00,-24.00,-2.40)}
	"models/props_doors/doormainmetal01.mdl": {mass=50.0,center=Vector(0.00,-27.76,0.00)}
	"models/props_doors/doormainmetal01_dm01.mdl": {mass=50.0,center=Vector(0.00,-29.04,0.96)}
	"models/props_doors/doormainmetal01_dm02.mdl": {mass=50.0,center=Vector(0.00,-29.04,0.96)}
	"models/props_doors/doormainmetal01_dm03.mdl": {mass=50.0,center=Vector(0.00,-30.64,0.96)}
	"models/props_doors/doormainmetal01_dm04.mdl": {mass=50.0,center=Vector(0.00,-30.64,0.96)}
	"models/props_doors/doormainmetal01_dm05.mdl": {mass=50.0,center=Vector(0.00,-30.00,1.60)}
	"models/props_doors/doormainmetal01_dm06.mdl": {mass=50.0,center=Vector(0.00,-28.40,0.96)}
	"models/props_doors/doormainmetal01_dm07.mdl": {mass=50.0,center=Vector(0.00,-27.60,0.00)}
	"models/props_doors/doormainmetalsmall01.mdl": {mass=50.0,center=Vector(0.00,-24.00,0.00)}
	"models/props_doors/doormainmetalsmall01_dm01.mdl": {mass=50.0,center=Vector(0.00,-24.64,0.96)}
	"models/props_doors/doormainmetalsmall01_dm02.mdl": {mass=50.0,center=Vector(0.00,-24.64,1.60)}
	"models/props_doors/doormainmetalsmall01_dm03.mdl": {mass=50.0,center=Vector(0.00,-26.64,0.96)}
	"models/props_doors/doormainmetalsmall01_dm04.mdl": {mass=50.0,center=Vector(0.00,-26.00,0.96)}
	"models/props_doors/doormainmetalsmall01_dm05.mdl": {mass=50.0,center=Vector(0.00,-25.36,2.24)}
	"models/props_doors/doormainmetalsmall01_dm06.mdl": {mass=50.0,center=Vector(0.00,-24.00,1.60)}
	"models/props_doors/doormainmetalsmall01_dm07.mdl": {mass=50.0,center=Vector(0.00,-20.00,-1.60)}
	"models/props_doors/doormainmetalwindow01.mdl": {mass=50.0,center=Vector(0.00,-27.60,-0.64)}
	"models/props_doors/doormainmetalwindow01_dm01.mdl": {mass=50.0,center=Vector(0.00,-27.60,-0.64)}
	"models/props_doors/doormainmetalwindow01_dm02.mdl": {mass=50.0,center=Vector(0.00,-24.00,2.40)}
	"models/props_doors/doormainmetalwindow01_dm03.mdl": {mass=50.0,center=Vector(0.00,-25.04,2.40)}
	"models/props_doors/doormainmetalwindow01_dm04.mdl": {mass=50.0,center=Vector(0.00,-27.60,3.04)}
	"models/props_doors/doormainmetalwindow01_dm05.mdl": {mass=50.0,center=Vector(0.00,-29.04,0.00)}
	"models/props_doors/doormainmetalwindow01_dm06.mdl": {mass=50.0,center=Vector(0.00,-27.60,-6.00)}
	"models/props_doors/doormainmetalwindow01_dm07.mdl": {mass=50.0,center=Vector(0.00,-27.60,-3.04)}
	"models/props_doors/doormainmetalwindowsmall01.mdl": {mass=50.0,center=Vector(0.00,-24.00,-0.96)}
	"models/props_doors/doormainmetalwindowsmall01_dm01.mdl": {mass=50.0,center=Vector(0.00,-23.36,-0.96)}
	"models/props_doors/doormainmetalwindowsmall01_dm02.mdl": {mass=50.0,center=Vector(0.00,-23.36,-0.64)}
	"models/props_doors/doormainmetalwindowsmall01_dm03.mdl": {mass=50.0,center=Vector(0.00,-21.60,2.40)}
	"models/props_doors/doormainmetalwindowsmall01_dm04.mdl": {mass=50.0,center=Vector(0.00,-23.36,3.04)}
	"models/props_doors/doormainmetalwindowsmall01_dm05.mdl": {mass=50.0,center=Vector(0.00,-24.96,0.00)}
	"models/props_doors/doormainmetalwindowsmall01_dm06.mdl": {mass=50.0,center=Vector(0.00,-24.00,-6.00)}
	"models/props_doors/doormainmetalwindowsmall01_dm07.mdl": {mass=50.0,center=Vector(0.00,-24.00,-3.04)}
	"models/props_doors/shackwall01.mdl": {mass=50.0,center=Vector(1.60,0.00,48.40)}
	"models/props_doors/shackwall01_dmg01.mdl": {mass=50.0,center=Vector(1.60,0.00,50.96)}
	"models/props_doors/shackwall01_dmg02.mdl": {mass=50.0,center=Vector(2.24,-0.96,48.40)}
	"models/props_doors/shackwall01_dmg03.mdl": {mass=50.0,center=Vector(2.40,-1.76,44.64)}
	"models/props_doors/shackwall01_dmg04.mdl": {mass=50.0,center=Vector(0.96,0.96,33.36)}
	"models/props_downtown/door_interior_112_01.mdl": {mass=50.0,center=Vector(0.00,-28.24,56.00)}
	"models/props_downtown/door_interior_112_01_dm01_01.mdl": {mass=50.0,center=Vector(0.00,-27.60,56.00)}
	"models/props_downtown/door_interior_112_01_dm02_01.mdl": {mass=50.0,center=Vector(0.00,-29.36,56.64)}
	"models/props_downtown/door_interior_112_01_dm03_01.mdl": {mass=50.0,center=Vector(-0.64,-29.36,52.40)}
	"models/props_downtown/door_interior_128_01.mdl": {mass=50.0,center=Vector(0.00,-32.24,64.00)}
	"models/props_downtown/door_interior_128_01_dm01_01.mdl": {mass=50.0,center=Vector(0.00,-31.60,64.00)}
	"models/props_downtown/door_interior_128_01_dm02_01.mdl": {mass=50.0,center=Vector(0.00,-33.36,64.64)}
	"models/props_downtown/door_interior_128_01_dm03_01.mdl": {mass=50.0,center=Vector(0.00,-33.36,60.00)}
	"models/props_downtown/metal_door_112.mdl": {mass=50.0,center=Vector(0.00,-27.76,56.00)}
	"models/props_downtown/metal_door_112_dm01_01.mdl": {mass=50.0,center=Vector(0.00,-27.76,56.00)}
	"models/props_downtown/metal_door_112_dm02_01.mdl": {mass=50.0,center=Vector(0.00,-28.24,55.36)}
	"models/props_downtown/metal_door_112_dm03_01.mdl": {mass=50.0,center=Vector(0.00,-27.60,54.96)}
	"models/props_downtown/metal_door_112_dm04_01.mdl": {mass=50.0,center=Vector(0.00,-27.60,57.60)}
	"models/props_downtown/metal_door_112_noskins.mdl": {mass=50.0,center=Vector(0.00,-27.60,55.36)}
	"models/props_downtown/metal_door_112_noskins_dm01_01.mdl": {mass=50.0,center=Vector(0.00,-27.60,55.36)}
	"models/props_downtown/metal_door_112_noskins_dm02_01.mdl": {mass=50.0,center=Vector(0.00,-26.96,55.36)}
	"models/props_downtown/metal_door_112_noskins_dm03_01.mdl": {mass=50.0,center=Vector(0.00,-27.60,54.96)}
	"models/props_downtown/metal_door_112_noskins_dm04_01.mdl": {mass=50.0,center=Vector(0.00,-26.96,56.96)}
	"models/props_equipment/light_floodlight.mdl": {mass=50.0,center=Vector(-1.60,0.00,66.00)}
	"models/props_equipment/securitycheckpoint.mdl": {mass=50.0,center=Vector(0.00,0.00,58.40)}
	"models/props_furniture/heavy_table.mdl": {mass=50.0,center=Vector(0.00,0.00,5.04)}
	"models/props_industrial/barrel_fuel_parta.mdl": {mass=50.0,center=Vector(-0.96,0.00,32.40)}
	"models/props_industrial/barrel_fuel_partb.mdl": {mass=50.0,center=Vector(-0.96,-0.64,13.36)}
	"models/props_interiors/chairlobby01.mdl": {mass=50.0,center=Vector(0.00,4.64,25.60)}
	"models/props_interiors/ibeam_breakable01_damaged01.mdl": {mass=50.0,center=Vector(0.00,0.00,-10.64)}
	"models/props_interiors/sofa_chair.mdl": {mass=50.0,center=Vector(-1.60,0.00,15.36)}
	"models/props_interiors/tv.mdl": {mass=50.0,center=Vector(0.00,0.96,13.36)}
	"models/props_street/manhole_cover.mdl": {mass=50.0,center=Vector(0.00,0.00,0.96)}
	"models/props_unique/airport/temp_barricade.mdl": {mass=50.0,center=Vector(0.00,0.00,33.04)}
	"models/props_urban/outhouse_door001.mdl": {mass=50.0,center=Vector(0.00,-16.96,45.36)}
	"models/props_urban/outhouse_door001_dm01_01.mdl": {mass=50.0,center=Vector(0.00,-16.96,45.36)}
	"models/props_urban/outhouse_door001_dm02_01.mdl": {mass=50.0,center=Vector(0.00,-16.96,40.64)}
	"models/props_vehicles/carparts_door01a.mdl": {mass=50.0,center=Vector(0.00,0.96,-6.96)}
	"models/props_debris/wood_board05a.mdl": {mass=46.984985,center=Vector(0.00,0.00,0.00)}
	"models/props_debris/wood_chunk05b.mdl": {mass=44.557926,center=Vector(0.00,0.00,-5.36)}
	"models/props_swamp/boardwalk_rail_chunk03.mdl": {mass=43.419575,center=Vector(1.76,136.00,-9.60)}
	"models/props_swamp/boardwalk_rail_chunk01.mdl": {mass=43.34251,center=Vector(1.76,8.24,-10.00)}
	"models/props_swamp/boardwalk_rail_chunk02.mdl": {mass=43.272465,center=Vector(1.76,-120.00,-10.00)}
	"models/props_vehicles/wagon001a_phy.mdl": {mass=41.078144,center=Vector(0.00,0.00,-1.60)}
	"models/lostcoast/props_wasteland/crabpot.mdl": {mass=40.0,center=Vector(0.00,0.00,6.00)}
	"models/props_interiors/couch.mdl": {mass=40.0,center=Vector(0.00,4.00,14.96)}
	"models/props_misc/flour_sack-1.mdl": {mass=40.0,center=Vector(0.00,-3.04,7.76)}
	"models/props_interiors/luggagecarthotel01.mdl": {mass=37.0,center=Vector(0.00,0.00,8.40)}
	"models/props_interiors/trashcan01.mdl": {mass=35.0,center=Vector(0.00,0.00,23.04)}
	"models/props_wasteland/prison_shelf002a.mdl": {mass=35.0,center=Vector(-2.40,0.00,-0.64)}
	"models/props_swamp/boardwalk_rail_chunk05.mdl": {mass=33.604115,center=Vector(-3.36,72.40,12.24)}
	"models/props_c17/oildrum001.mdl": {mass=30.0,center=Vector(0.00,0.00,22.40)}
	"models/props_equipment/cart_utility_01.mdl": {mass=30.0,center=Vector(0.00,-0.64,21.60)}
	"models/props_foliage/flower_barrel_p8.mdl": {mass=30.0,center=Vector(0.00,-2.40,-12.40)}
	"models/props_interiors/picnic_bench_toddler.mdl": {mass=30.0,center=Vector(0.00,0.00,14.64)}
	"models/props_interiors/table_folding.mdl": {mass=30.0,center=Vector(0.00,0.00,28.24)}
	"models/props_junk/wood_crate001a.mdl": {mass=30.0,center=Vector(0.00,0.00,0.00)}
	"models/props_normandy/haybale.mdl": {mass=30.0,center=Vector(-4.00,0.64,0.00)}
	"models/props_trainstation/trashcan_indoor001b.mdl": {mass=30.0,center=Vector(0.00,0.00,4.00)}
	"models/props_unique/subwaycar_all_onetexture_enddoor.mdl": {mass=30.0,center=Vector(0.00,0.00,-8.40)}
	"models/props_unique/subwaycar_all_onetexture_enddoorb.mdl": {mass=30.0,center=Vector(0.00,0.00,-8.40)}
	"models/props_unique/subwaycar_all_onetexture_sidedoor.mdl": {mass=30.0,center=Vector(0.00,0.00,-9.36)}
	"models/props_unique/subwaycar_all_onetexture_sidedoorb.mdl": {mass=30.0,center=Vector(0.00,-0.64,-9.36)}
	"models/props_urban/oil_drum001.mdl": {mass=30.0,center=Vector(0.00,0.00,24.00)}
	"models/props_urban/round_table001.mdl": {mass=30.0,center=Vector(0.00,0.00,37.60)}
	"models/lostcoast/props_wasteland/cliff_stairs_1stair01.mdl": {mass=25.0,center=Vector(0.00,0.00,0.00)}
	"models/lostcoast/props_wasteland/cliff_stairs_2stair01_br01.mdl": {mass=25.0,center=Vector(0.96,20.64,0.64)}
	"models/lostcoast/props_wasteland/cliff_stairs_2stair01_br02.mdl": {mass=25.0,center=Vector(-0.96,-16.00,-0.64)}
	"models/props/cs_office/file_box_p1.mdl": {mass=25.0,center=Vector(0.00,0.00,6.64)}
	"models/props/cs_office/file_box_p2.mdl": {mass=25.0,center=Vector(0.00,0.00,6.64)}
	"models/props_fairgrounds/strongmangame_puck_phys.mdl": {mass=25.0,center=Vector(0.00,0.00,0.00)}
	"models/props_furniture/bathtub1.mdl": {mass=25.0,center=Vector(0.96,-0.96,15.36)}
	"models/props_junk/wood_crate001a_damagedmax.mdl": {mass=25.0,center=Vector(-2.40,0.32,0.00)}
	"models/props_street/trashbin01.mdl": {mass=25.0,center=Vector(1.60,0.00,26.96)}
	"models/props_vehicles/tire001c_car.mdl": {mass=25.0,center=Vector(0.00,0.00,0.00)}
	"models/props_wasteland/barricade001a.mdl": {mass=25.0,center=Vector(0.00,0.00,-0.64)}
	"models/props_fairgrounds/lil'peanut_cutout001.mdl": {mass=24.876507,center=Vector(-4.00,-0.64,28.40)}
	"models/props_interiors/table_motel.mdl": {mass=22.0,center=Vector(0.00,0.00,23.36)}
	"models/props_swamp/boardwalk_rail_chunk04.mdl": {mass=20.596113,center=Vector(-3.04,-78.40,13.04)}
	"models/props/de_inferno/chairantique.mdl": {mass=20.0,center=Vector(-1.60,0.00,17.60)}
	"models/props/de_prodigy/wood_pallet_01.mdl": {mass=20.0,center=Vector(0.00,0.00,3.04)}
	"models/props_equipment/oxygentank01.mdl": {mass=20.0,center=Vector(-2.24,0.00,14.64)}
	"models/props_foliage/flower_barrel_dead_p1.mdl": {mass=20.0,center=Vector(0.00,0.00,0.00)}
	"models/props_foliage/flower_barrel_dead_p11.mdl": {mass=20.0,center=Vector(0.64,0.64,-15.36)}
	"models/props_foliage/flower_barrel_dead_p6.mdl": {mass=20.0,center=Vector(0.00,0.00,0.64)}
	"models/props_foliage/flower_barrel_dead_p7.mdl": {mass=20.0,center=Vector(-0.64,0.00,0.64)}
	"models/props_foliage/flower_barrel_dead_p8.mdl": {mass=20.0,center=Vector(0.00,0.00,0.64)}
	"models/props_foliage/flower_barrel_dead_p9.mdl": {mass=20.0,center=Vector(0.00,0.00,0.00)}
	"models/props_furniture/drawer1.mdl": {mass=20.0,center=Vector(-0.64,0.00,3.04)}
	"models/props_furniture/piano_bench.mdl": {mass=20.0,center=Vector(0.00,0.64,-5.36)}
	"models/props_industrial/pallet01.mdl": {mass=20.0,center=Vector(0.00,0.00,3.04)}
	"models/props_interiors/bench01a.mdl": {mass=20.0,center=Vector(0.00,-0.64,1.60)}
	"models/props_interiors/ceda_easel01.mdl": {mass=20.0,center=Vector(-0.64,0.00,56.00)}
	"models/props_junk/dieselcan.mdl": {mass=20.0,center=Vector(0.64,0.00,0.00)}
	"models/props_junk/explosive_box001.mdl": {mass=20.0,center=Vector(0.00,0.00,0.00)}
	"models/props_junk/gascan001a.mdl": {mass=20.0,center=Vector(0.00,0.00,-0.64)}
	"models/props_junk/propanecanister001a.mdl": {mass=20.0,center=Vector(-6.96,-7.60,-0.64)}
	"models/props_junk/trashbin01a.mdl": {mass=20.0,center=Vector(0.96,0.00,1.60)}
	"models/props_junk/wood_pallet001a.mdl": {mass=20.0,center=Vector(0.00,0.64,0.64)}
	"models/props_plants/claypot03_damage_01.mdl": {mass=20.0,center=Vector(0.00,0.96,-4.00)}
	"models/props_signs/sign_horizontal_01.mdl": {mass=20.0,center=Vector(34.96,0.00,0.00)}
	"models/props_signs/sign_horizontal_02.mdl": {mass=20.0,center=Vector(23.04,0.00,-25.04)}
	"models/props_signs/sign_horizontal_03.mdl": {mass=20.0,center=Vector(0.00,0.00,18.40)}
	"models/props_signs/sign_horizontal_04.mdl": {mass=20.0,center=Vector(34.00,0.00,-14.00)}
	"models/props_signs/sign_horizontal_05.mdl": {mass=20.0,center=Vector(35.36,0.00,-17.60)}
	"models/props_signs/sign_horizontal_09.mdl": {mass=20.0,center=Vector(23.04,0.00,-25.04)}
	"models/props_signs/sign_horizontal_10.mdl": {mass=20.0,center=Vector(0.00,0.00,17.76)}
	"models/props_signs/sign_quarter_02.mdl": {mass=20.0,center=Vector(0.00,2.40,15.04)}
	"models/props_signs/sign_street_05.mdl": {mass=20.0,center=Vector(9.04,0.00,15.36)}
	"models/props_urban/plastic_chair001.mdl": {mass=20.0,center=Vector(-0.96,0.00,26.00)}
	"models/props_urban/plastic_chair001_debris.mdl": {mass=20.0,center=Vector(-0.96,0.00,26.00)}
	"models/props_urban/tire001.mdl": {mass=20.0,center=Vector(0.00,0.00,0.00)}
	"models/props_vehicles/ceda_door_rotating.mdl": {mass=20.0,center=Vector(6.00,32.40,37.60)}
	"models/props_wasteland/controlroom_chair001a.mdl": {mass=20.0,center=Vector(0.00,0.00,-1.60)}
	"models/props_interiors/sofa01.mdl": {mass=19.182207,center=Vector(-2.24,0.00,14.00)}
	"models/props_interiors/sofa02.mdl": {mass=18.96814,center=Vector(-3.04,0.00,16.00)}
	"models/props/cs_office/chair_office.mdl": {mass=15.0,center=Vector(-2.40,0.00,20.64)}
	"models/props/cs_office/table_coffee.mdl": {mass=15.0,center=Vector(0.00,0.00,20.00)}
	"models/props/de_inferno/tv_monitor01.mdl": {mass=15.0,center=Vector(0.96,0.00,-0.64)}
	"models/props_interiors/chair_thonet.mdl": {mass=15.0,center=Vector(-2.40,0.00,24.64)}
	"models/props_interiors/computer_monitor_p1.mdl": {mass=15.0,center=Vector(0.64,0.00,13.36)}
	"models/props_junk/metalbucket02a.mdl": {mass=15.0,center=Vector(-0.64,0.00,-1.60)}
	"models/w_models/weapons/w_pumpshotgun_a.mdl": {mass=15.0,center=Vector(10.00,0.00,1.60)}
	"models/props_downtown/ironing_board.mdl": {mass=14.67638,center=Vector(0.96,0.00,31.60)}
	"models/props_debris/wood_chunk05f.mdl": {mass=14.640072,center=Vector(0.00,-0.64,-11.60)}
	"models/props_lab/monitor01a.mdl": {mass=14.0,center=Vector(0.96,0.64,-0.96)}
	"models/lostcoast/props_wasteland/cliff_stairs_1stair01_br01.mdl": {mass=13.0,center=Vector(0.64,18.40,0.00)}
	"models/lostcoast/props_wasteland/cliff_stairs_1stair01_br02.mdl": {mass=13.0,center=Vector(-0.64,-18.40,0.00)}
	"models/props_interiors/sofa_chair02.mdl": {mass=12.887611,center=Vector(-3.04,0.00,16.96)}
	"models/props_fairgrounds/bumpercar_pole.mdl": {mass=12.598815,center=Vector(0.96,0.00,69.36)}
	"models/props_debris/wood_chunk05e.mdl": {mass=12.460089,center=Vector(0.00,0.96,-6.64)}
	"models/props_unique/hospital/gurney.mdl": {mass=12.0,center=Vector(0.00,0.64,34.00)}
	"models/props_debris/wood_chunk05a.mdl": {mass=11.863307,center=Vector(-0.96,0.64,10.96)}
	"models/props_debris/wood_board04a.mdl": {mass=11.746246,center=Vector(0.00,0.00,0.00)}
	"models/props_c17/handrail04_long.mdl": {mass=11.0,center=Vector(0.00,5.36,7.60)}
	"models/lostcoast/props_wasteland/boat_wooden001a_gib01.mdl": {mass=10.0,center=Vector(101.76,-1.60,-0.96)}
	"models/lostcoast/props_wasteland/boat_wooden001a_gib02.mdl": {mass=10.0,center=Vector(44.64,23.36,3.04)}
	"models/lostcoast/props_wasteland/boat_wooden001a_gib03.mdl": {mass=10.0,center=Vector(30.96,-18.40,-4.00)}
	"models/lostcoast/props_wasteland/boat_wooden001a_gib04.mdl": {mass=10.0,center=Vector(-33.04,-10.96,-13.04)}
	"models/lostcoast/props_wasteland/boat_wooden001a_gib05.mdl": {mass=10.0,center=Vector(-96.96,0.00,-4.24)}
	"models/lostcoast/props_wasteland/boat_wooden001a_gib06.mdl": {mass=10.0,center=Vector(-34.00,24.40,-0.96)}
	"models/lostcoast/props_wasteland/boat_wooden001a_gib07.mdl": {mass=10.0,center=Vector(-40.64,19.04,-9.36)}
	"models/lostcoast/props_wasteland/boat_wooden02a_gib01.mdl": {mass=10.0,center=Vector(80.64,-6.00,-0.64)}
	"models/lostcoast/props_wasteland/boat_wooden02a_gib02.mdl": {mass=10.0,center=Vector(11.76,6.96,-12.24)}
	"models/lostcoast/props_wasteland/boat_wooden02a_gib03.mdl": {mass=10.0,center=Vector(-35.36,-30.00,-0.64)}
	"models/lostcoast/props_wasteland/boat_wooden02a_gib04.mdl": {mass=10.0,center=Vector(-56.96,-3.36,-23.04)}
	"models/lostcoast/props_wasteland/boat_wooden02a_gib05.mdl": {mass=10.0,center=Vector(-44.96,26.00,-7.60)}
	"models/lostcoast/props_wasteland/boat_wooden02a_gib06.mdl": {mass=10.0,center=Vector(-108.64,12.40,-4.00)}
	"models/lostcoast/props_wasteland/boat_wooden03a_gib01.mdl": {mass=10.0,center=Vector(-78.72,8.40,-4.00)}
	"models/lostcoast/props_wasteland/boat_wooden03a_gib02.mdl": {mass=10.0,center=Vector(-70.64,-21.76,0.00)}
	"models/lostcoast/props_wasteland/boat_wooden03a_gib03.mdl": {mass=10.0,center=Vector(-6.00,-23.04,-9.04)}
	"models/lostcoast/props_wasteland/boat_wooden03a_gib04.mdl": {mass=10.0,center=Vector(-10.00,15.36,-16.00)}
	"models/lostcoast/props_wasteland/boat_wooden03a_gib05.mdl": {mass=10.0,center=Vector(50.00,24.64,3.36)}
	"models/lostcoast/props_wasteland/boat_wooden03a_gib06.mdl": {mass=10.0,center=Vector(67.60,-8.40,1.60)}
	"models/lostcoast/props_wasteland/cliff_stairs_deck01_br01.mdl": {mass=10.0,center=Vector(29.04,-6.64,-2.24)}
	"models/lostcoast/props_wasteland/rock_cliff02d.mdl": {mass=10.0,center=Vector(1.60,0.00,0.96)}
	"models/props/cs_militia/militiawindow02_breakable.mdl": {mass=10.0,center=Vector(-0.64,0.00,0.00)}
	"models/props/cs_office/fire_extinguisher.mdl": {mass=10.0,center=Vector(4.00,0.00,10.00)}
	"models/props/cs_office/table_coffee_p1.mdl": {mass=10.0,center=Vector(1.60,-13.36,20.96)}
	"models/props/cs_office/table_coffee_p2.mdl": {mass=10.0,center=Vector(0.00,16.00,20.00)}
	"models/props/de_inferno/chairantique_damage_01.mdl": {mass=10.0,center=Vector(-4.00,-3.04,2.40)}
	"models/props/de_inferno/chairantique_damage_02.mdl": {mass=10.0,center=Vector(0.96,-0.64,1.60)}
	"models/props/de_inferno/chairantique_damage_03.mdl": {mass=10.0,center=Vector(-1.60,2.40,0.00)}
	"models/props_canal/boat001a_chunk01.mdl": {mass=10.0,center=Vector(-52.24,-26.64,-1.60)}
	"models/props_canal/boat001a_chunk010.mdl": {mass=10.0,center=Vector(41.60,8.40,-16.00)}
	"models/props_canal/boat001a_chunk02.mdl": {mass=10.0,center=Vector(31.60,-26.96,3.36)}
	"models/props_equipment/sleeping_bag3.mdl": {mass=10.0,center=Vector(0.00,0.96,9.04)}
	"models/props_furniture/cafe_barstool1.mdl": {mass=10.0,center=Vector(0.00,0.00,26.96)}
	"models/props_interiors/computer_monitor_p2.mdl": {mass=10.0,center=Vector(-1.60,0.00,6.96)}
	"models/props_interiors/door_sliding_breakable01.mdl": {mass=10.0,center=Vector(-0.64,0.64,57.76)}
	"models/props_interiors/luggagescale.mdl": {mass=10.0,center=Vector(0.00,0.00,27.60)}
	"models/props_interiors/refrigerator03_damaged_01.mdl": {mass=10.0,center=Vector(0.00,0.00,34.64)}
	"models/props_interiors/refrigerator03_damaged_02.mdl": {mass=10.0,center=Vector(0.64,0.00,0.00)}
	"models/props_interiors/refrigerator03_damaged_03.mdl": {mass=10.0,center=Vector(-1.60,0.64,-0.96)}
	"models/props_interiors/refrigerator03_damaged_04.mdl": {mass=10.0,center=Vector(-0.64,0.00,0.00)}
	"models/props_interiors/refrigerator03_damaged_05.mdl": {mass=10.0,center=Vector(0.00,0.00,0.00)}
	"models/props_interiors/refrigerator03_damaged_06.mdl": {mass=10.0,center=Vector(-0.64,0.00,0.00)}
	"models/props_interiors/refrigerator03_damaged_07.mdl": {mass=10.0,center=Vector(0.00,0.00,0.00)}
	"models/props_interiors/sawhorse.mdl": {mass=10.0,center=Vector(0.00,0.00,26.00)}
	"models/props_interiors/table_folding_folded.mdl": {mass=10.0,center=Vector(0.00,0.00,18.40)}
	"models/props_interiors/table_folding_folded_new.mdl": {mass=10.0,center=Vector(0.00,0.00,18.40)}
	"models/props_junk/gnome.mdl": {mass=10.0,center=Vector(-6.00,-8.40,3.04)}
	"models/props_lighting/lampbedside01.mdl": {mass=10.0,center=Vector(0.00,0.00,17.60)}
	"models/props_lighting/lighthanging.mdl": {mass=10.0,center=Vector(0.00,0.00,-2.40)}
	"models/props_plants/claypot03_damage_02.mdl": {mass=10.0,center=Vector(-1.28,-0.64,-0.64)}
	"models/props_plants/claypot03_damage_04.mdl": {mass=10.0,center=Vector(0.00,0.64,0.00)}
	"models/props_plants/claypot03_damage_05.mdl": {mass=10.0,center=Vector(0.00,0.64,0.32)}
	"models/props_plants/claypot03_damage_06.mdl": {mass=10.0,center=Vector(0.64,0.64,0.96)}
	"models/props_plants/pottedplant_tall01_p3.mdl": {mass=10.0,center=Vector(4.00,-0.96,6.96)}
	"models/props_plants/pottedplant_tall01_p5.mdl": {mass=10.0,center=Vector(-1.60,4.00,6.00)}
	"models/props_plants/pottedplant_tall01_p7.mdl": {mass=10.0,center=Vector(-4.00,-3.04,6.96)}
	"models/props_unique/subwaycarexterior01_enddoor01_damaged01.mdl": {mass=10.0,center=Vector(0.96,-3.04,0.00)}
	"models/props_unique/subwaycarexterior01_enddoor01_damaged01b.mdl": {mass=10.0,center=Vector(0.96,-3.04,0.00)}
	"models/props_unique/subwaycarexterior01_enddoor01_damaged02.mdl": {mass=10.0,center=Vector(-0.64,-0.96,0.00)}
	"models/props_unique/subwaycarexterior01_enddoor01_damaged02b.mdl": {mass=10.0,center=Vector(0.00,1.60,0.00)}
	"models/props_unique/subwaycarexterior01_enddoor01_damaged03.mdl": {mass=10.0,center=Vector(0.00,0.00,0.00)}
	"models/props_unique/subwaycarexterior01_enddoor01_damaged03b.mdl": {mass=10.0,center=Vector(0.00,0.64,-0.96)}
	"models/props_unique/subwaycarexterior01_enddoor01_damaged04.mdl": {mass=10.0,center=Vector(-0.64,0.64,-0.96)}
	"models/props_unique/subwaycarexterior01_enddoor01_damaged04b.mdl": {mass=10.0,center=Vector(0.00,0.00,0.00)}
	"models/props_unique/subwaycarexterior01_enddoor01_damaged05.mdl": {mass=10.0,center=Vector(0.00,1.60,0.00)}
	"models/props_unique/subwaycarexterior01_enddoor01_damaged05b.mdl": {mass=10.0,center=Vector(-0.96,-0.64,0.00)}
	"models/props_unique/subwaycarexterior01_sidedoor01_damaged_01.mdl": {mass=10.0,center=Vector(-1.60,0.00,-0.64)}
	"models/props_unique/subwaycarexterior01_sidedoor01_damaged_01b.mdl": {mass=10.0,center=Vector(0.64,-0.96,2.24)}
	"models/props_unique/subwaycarexterior01_sidedoor01_damaged_02.mdl": {mass=10.0,center=Vector(-1.76,0.00,3.04)}
	"models/props_unique/subwaycarexterior01_sidedoor01_damaged_02b.mdl": {mass=10.0,center=Vector(-0.96,0.00,-0.64)}
	"models/props_unique/subwaycarexterior01_sidedoor01_damaged_03.mdl": {mass=10.0,center=Vector(0.96,-0.96,2.40)}
	"models/props_unique/subwaycarexterior01_sidedoor01_damaged_03b.mdl": {mass=10.0,center=Vector(-0.64,-0.64,0.64)}
	"models/props_unique/subwaycarexterior01_sidedoor01_damaged_04.mdl": {mass=10.0,center=Vector(-0.64,-0.96,0.00)}
	"models/props_unique/subwaycarexterior01_sidedoor01_damaged_04b.mdl": {mass=10.0,center=Vector(-2.24,0.00,3.04)}
	"models/props_vents/ventbreakable01.mdl": {mass=10.0,center=Vector(0.00,0.00,0.00)}
	"models/w_models/weapons/w_cola.mdl": {mass=10.0,center=Vector(0.00,-0.64,5.36)}
	"models/w_models/weapons/w_desert_rifle.mdl": {mass=10.0,center=Vector(7.60,0.00,1.60)}
	"models/w_models/weapons/w_grenade_launcher.mdl": {mass=10.0,center=Vector(4.00,0.00,2.40)}
	"models/w_models/weapons/w_m60.mdl": {mass=10.0,center=Vector(5.36,-0.96,2.40)}
	"models/w_models/weapons/w_rifle_ak47.mdl": {mass=10.0,center=Vector(6.96,0.00,0.96)}
	"models/w_models/weapons/w_rifle_b.mdl": {mass=10.0,center=Vector(7.60,0.00,1.60)}
	"models/w_models/weapons/w_rifle_m16a2.mdl": {mass=10.0,center=Vector(9.36,0.00,2.40)}
	"models/w_models/weapons/w_shotgun.mdl": {mass=10.0,center=Vector(9.36,-0.64,2.40)}
	"models/props_fairgrounds/lil'peanut_cutout001_dmg005.mdl": {mass=9.848664,center=Vector(-2.40,-1.60,25.04)}
	"models/props_mall/mall_mannequin_female_base.mdl": {mass=9.429596,center=Vector(-2.40,1.60,30.00)}
	"models/props/de_prodigy/wood_pallet_debris_01.mdl": {mass=9.0,center=Vector(2.40,-7.60,0.00)}
	"models/props_industrial/pallet01_gib01.mdl": {mass=9.0,center=Vector(1.76,-8.24,0.00)}
	"models/props_unique/wheelchair01.mdl": {mass=9.0,center=Vector(-5.36,0.00,15.36)}
	"models/props_debris/wood_chunk05d.mdl": {mass=8.141935,center=Vector(0.00,-0.64,9.04)}
	"models/props_interiors/lamp_table01.mdl": {mass=8.0,center=Vector(0.00,0.00,18.40)}
	"models/props_interiors/lamp_table02.mdl": {mass=8.0,center=Vector(0.00,0.00,20.00)}
	"models/props_junk/metalbucket01a.mdl": {mass=8.0,center=Vector(0.00,0.00,0.64)}
	"models/props_lab/desklamp01.mdl": {mass=8.0,center=Vector(0.64,0.00,1.28)}
	"models/props_lab/partsbin01.mdl": {mass=8.0,center=Vector(0.00,0.00,0.00)}
	"models/props_unique/luggagecart01.mdl": {mass=8.0,center=Vector(-10.96,0.00,14.64)}
	"models/props_interiors/lamp_floor_arch.mdl": {mass=6.392386,center=Vector(27.60,0.00,47.60)}
	"models/props/cs_office/phone.mdl": {mass=6.0,center=Vector(-0.64,0.64,1.60)}
	"models/props_interiors/lamp_floor.mdl": {mass=6.0,center=Vector(0.00,0.00,72.72)}
	"models/props_mall/mall_mannequin_base.mdl": {mass=5.405207,center=Vector(-0.64,2.24,30.96)}
	"models/props_mall/mall_mannequin_torso1.mdl": {mass=5.386485,center=Vector(-0.64,0.00,11.60)}
	"models/props_mall/mall_mannequin_torso2.mdl": {mass=5.386485,center=Vector(-0.64,0.00,11.60)}
	"models/props_doors/checkpoint_crossbar_-01.mdl": {mass=5.0,center=Vector(4.00,-34.00,-6.64)}
	"models/props_doors/checkpoint_crossbar_01.mdl": {mass=5.0,center=Vector(-4.00,-22.40,-6.64)}
	"models/props_furniture/hotel_chair.mdl": {mass=5.0,center=Vector(2.40,0.00,25.36)}
	"models/props_interiors/trashcankitchen01.mdl": {mass=5.0,center=Vector(0.00,0.00,19.04)}
	"models/props_plants/planthanging01.mdl": {mass=5.0,center=Vector(0.00,0.00,-2.40)}
	"models/props_street/garbage_can.mdl": {mass=5.0,center=Vector(0.00,0.00,19.36)}
	"models/props_mall/mall_mannequin_female_torso1.mdl": {mass=4.207908,center=Vector(-2.24,0.00,10.64)}
	"models/props/cs_militia/barstool01.mdl": {mass=4.0,center=Vector(0.00,0.00,19.36)}
	"models/props_c17/pottery08a.mdl": {mass=4.0,center=Vector(0.00,0.00,15.04)}
	"models/props_foliage/flower_barrel_p1.mdl": {mass=4.0,center=Vector(0.64,-0.64,0.00)}
	"models/props_foliage/flower_barrel_p11.mdl": {mass=4.0,center=Vector(0.00,0.00,0.00)}
	"models/props_foliage/flower_barrel_p2.mdl": {mass=4.0,center=Vector(0.64,0.64,0.00)}
	"models/props_foliage/flower_barrel_p3.mdl": {mass=4.0,center=Vector(0.00,0.64,0.64)}
	"models/props_foliage/flower_barrel_p4.mdl": {mass=4.0,center=Vector(-0.64,0.00,0.64)}
	"models/props_foliage/flower_barrel_p5.mdl": {mass=4.0,center=Vector(-1.28,0.00,0.64)}
	"models/props_foliage/flower_barrel_p6.mdl": {mass=4.0,center=Vector(0.00,-0.64,0.64)}
	"models/props_foliage/flower_barrel_p7.mdl": {mass=4.0,center=Vector(0.00,-0.64,0.00)}
	"models/props_furniture/chair2_gib1.mdl": {mass=4.0,center=Vector(0.00,0.00,-0.64)}
	"models/props_furniture/chair2_gib3.mdl": {mass=4.0,center=Vector(0.00,0.96,0.64)}
	"models/props_furniture/lamp1.mdl": {mass=4.0,center=Vector(0.00,0.00,17.60)}
	"models/props_mall/mall_mannequin_female_torso2.mdl": {mass=3.827615,center=Vector(-2.24,0.00,10.64)}
	"models/props_mall/mall_mannequin_female_torso3.mdl": {mass=3.827518,center=Vector(-2.40,0.00,10.64)}
	"models/props_waterfront/sign_underriver_easel01.mdl": {mass=3.737612,center=Vector(5.36,0.32,46.64)}
	"models/props_fairgrounds/lil'peanut_cutout001_dmg001.mdl": {mass=3.375763,center=Vector(-1.60,0.00,8.40)}
	"models/props_junk/furnituremattress001a.mdl": {mass=3.143074,center=Vector(0.00,0.00,6.96)}
	"models/props_c17/pottery04a.mdl": {mass=3.0,center=Vector(0.00,0.00,6.96)}
	"models/props_misc/pot-1.mdl": {mass=3.0,center=Vector(0.64,-0.64,0.64)}
	"models/props_urban/shopping_cart001.mdl": {mass=3.0,center=Vector(0.00,-1.60,25.60)}
	"models/props_mall/mall_mannequin_female_lleg.mdl": {mass=2.754055,center=Vector(-1.60,0.00,14.00)}
	"models/props_mall/mall_mannequin_lleg.mdl": {mass=2.66494,center=Vector(-1.60,0.96,14.00)}
	"models/props_misc/mirror-1.mdl": {mass=2.3,center=Vector(0.96,-6.64,28.24)}
	"models/props_c17/pottery02a.mdl": {mass=2.0,center=Vector(0.00,0.00,6.00)}
	"models/props_equipment/tsabin_01.mdl": {mass=2.0,center=Vector(0.00,0.00,2.24)}
	"models/props_foliage/flower_barrel_p10.mdl": {mass=2.0,center=Vector(0.00,0.00,2.40)}
	"models/props_foliage/flower_barrel_p9.mdl": {mass=2.0,center=Vector(0.00,0.00,-7.60)}
	"models/props_fortifications/traffic_barrier001.mdl": {mass=2.0,center=Vector(0.00,0.00,23.04)}
	"models/props_interiors/toaster.mdl": {mass=2.0,center=Vector(0.00,0.00,6.00)}
	"models/props_junk/wood_crate001a_chunk01.mdl": {mass=2.0,center=Vector(3.04,-2.24,0.00)}
	"models/props_junk/wood_crate001a_chunk02.mdl": {mass=2.0,center=Vector(6.64,-3.04,-6.00)}
	"models/props_junk/wood_crate001a_chunk03.mdl": {mass=2.0,center=Vector(0.64,0.00,2.40)}
	"models/props_junk/wood_crate001a_chunk04.mdl": {mass=2.0,center=Vector(-0.96,2.24,-3.04)}
	"models/props_junk/wood_crate001a_chunk07.mdl": {mass=2.0,center=Vector(0.64,0.96,3.04)}
	"models/props_junk/wood_crate001a_chunk09.mdl": {mass=2.0,center=Vector(-2.40,0.96,-0.64)}
	"models/props_unique/mopbucket01.mdl": {mass=2.0,center=Vector(1.60,0.00,16.96)}
	"models/props_urban/ashtray_stand001.mdl": {mass=2.0,center=Vector(0.00,0.00,14.64)}
	"models/props_urban/big_wheel001.mdl": {mass=2.0,center=Vector(-5.04,0.00,10.00)}
	"models/props_urban/gas_sign001.mdl": {mass=2.0,center=Vector(0.00,0.00,33.04)}
	"models/props_windows/hotel_window002_break003_2.mdl": {mass=2.0,center=Vector(0.00,55.04,23.36)}
	"models/props_windows/hotel_window002_break003_3.mdl": {mass=2.0,center=Vector(0.00,32.24,74.64)}
	"models/props_windows/hotel_window002_break003_4.mdl": {mass=2.0,center=Vector(0.00,24.64,83.04)}
	"models/props_windows/hotel_window002_break003_5.mdl": {mass=2.0,center=Vector(0.00,21.60,46.00)}
	"models/props_windows/hotel_window002_break003_6.mdl": {mass=2.0,center=Vector(0.00,2.40,48.40)}
	"models/props_windows/hotel_window002_break003_7.mdl": {mass=2.0,center=Vector(0.00,4.96,9.36)}
	"models/props_windows/hotel_window_break003_1.mdl": {mass=2.0,center=Vector(0.64,56.64,69.36)}
	"models/props_windows/hotel_window_break003_2.mdl": {mass=2.0,center=Vector(0.64,54.96,27.60)}
	"models/props_windows/hotel_window_break003_3.mdl": {mass=2.0,center=Vector(0.64,31.76,87.76)}
	"models/props_windows/hotel_window_break003_4.mdl": {mass=2.0,center=Vector(0.96,9.04,94.96)}
	"models/props_windows/hotel_window_break003_5.mdl": {mass=2.0,center=Vector(0.64,20.96,54.64)}
	"models/props_windows/hotel_window_break003_6.mdl": {mass=2.0,center=Vector(0.64,2.40,56.96)}
	"models/props_windows/hotel_window_break003_7.mdl": {mass=2.0,center=Vector(0.64,4.96,11.60)}
	"models/props_fairgrounds/lil'peanut_cutout001_dmg003.mdl": {mass=1.893939,center=Vector(0.00,-2.24,47.60)}
	"models/props_mall/mall_mannequin_female_larm2.mdl": {mass=1.341033,center=Vector(-3.04,-9.36,2.40)}
	"models/props_mall/mall_mannequin_female_rarm2.mdl": {mass=1.337381,center=Vector(4.00,9.36,2.40)}
	"models/props_misc/lamp-1.mdl": {mass=1.3,center=Vector(0.00,0.96,14.64)}
	"models/props_mall/mall_mannequin_female_larm1.mdl": {mass=1.225032,center=Vector(0.00,-10.00,1.60)}
	"models/props_mall/mall_mannequin_female_rarm1.mdl": {mass=1.225031,center=Vector(0.00,10.00,1.60)}
	"models/props_mall/mall_mannequin_larm2.mdl": {mass=1.090896,center=Vector(-0.96,-6.96,2.40)}
	"models/props_mall/mall_mannequin_rarm1.mdl": {mass=1.060066,center=Vector(-0.64,6.64,3.36)}
	"models/props_mall/mall_mannequin_larm1.mdl": {mass=1.040811,center=Vector(-1.60,-6.64,2.40)}
	"models/props/cs_office/file_box_p1c.mdl": {mass=1.0,center=Vector(9.04,0.00,14.00)}
	"models/props_fairgrounds/lil'peanut_cutout001_dmg002.mdl": {mass=1.0,center=Vector(0.00,15.36,46.00)}
	"models/props_fairgrounds/lil'peanut_cutout001_dmg004.mdl": {mass=1.0,center=Vector(0.00,-2.40,63.04)}
	"models/props_fairgrounds/lil'peanut_sign001.mdl": {mass=1.0,center=Vector(0.64,0.00,44.00)}
	"models/props_fortifications/orange_cone001_reference.mdl": {mass=1.0,center=Vector(0.00,0.00,8.40)}
	"models/props_junk/garbage_milkcarton001a.mdl": {mass=1.0,center=Vector(0.00,0.00,-0.64)}
	"models/props_junk/garbage_newspaper001a.mdl": {mass=1.0,center=Vector(1.60,0.96,-0.64)}
	"models/props_junk/garbage_plasticbottle001a.mdl": {mass=1.0,center=Vector(0.00,-0.64,-1.60)}
	"models/props_junk/garbage_plasticbottle001a_fullsheet.mdl": {mass=1.0,center=Vector(0.00,-0.64,-1.60)}
	"models/props_mall/mall_mannequin_lhand.mdl": {mass=1.0,center=Vector(0.64,0.64,4.96)}
	"models/props_mall/mall_mannequin_rhand.mdl": {mass=1.0,center=Vector(0.00,0.64,4.64)}
	"models/props_misc/lamp-1_gib1.mdl": {mass=1.0,center=Vector(0.00,0.96,21.60)}
	"models/props_misc/mirror-1_gib1.mdl": {mass=1.0,center=Vector(0.96,-4.00,38.24)}
	"models/props_misc/mirror-1_gib2.mdl": {mass=1.0,center=Vector(1.60,-17.60,39.36)}
	"models/props_misc/mirror-1_gib3.mdl": {mass=1.0,center=Vector(1.60,-6.64,13.36)}
	"models/props_misc/saddle-1.mdl": {mass=1.0,center=Vector(1.60,-0.64,8.40)}
	"models/props_misc/shelf-2.mdl": {mass=1.0,center=Vector(0.00,-0.64,3.36)}
	"models/props_urban/hotel_lamp001.mdl": {mass=1.0,center=Vector(0.00,0.00,24.64)}
	"models/props_urban/picture_frame001.mdl": {mass=1.0,center=Vector(2.24,0.00,0.00)}
	"models/props_urban/picture_frame002.mdl": {mass=1.0,center=Vector(2.24,0.00,0.00)}
	"models/props_urban/plastic_basin001.mdl": {mass=1.0,center=Vector(0.00,0.00,8.40)}
	"models/props_urban/plastic_basin002.mdl": {mass=1.0,center=Vector(0.00,0.00,6.32)}
	"models/props_urban/plastic_bucket001.mdl": {mass=1.0,center=Vector(0.00,0.00,10.00)}
	"models/props_urban/plastic_icechest001.mdl": {mass=1.0,center=Vector(0.00,0.00,9.36)}
	"models/props_urban/plastic_icechest_lid001.mdl": {mass=1.0,center=Vector(0.00,0.00,1.60)}
	"models/props_urban/plastic_water_jug001.mdl": {mass=1.0,center=Vector(0.64,0.00,7.60)}
	"models/props_windows/hotel_window002_break003_1.mdl": {mass=1.0,center=Vector(0.64,19.36,39.36)}
	"models/props_windows/window_urban_sash_32_72_full_frame.mdl": {mass=1.0,center=Vector(0.00,0.00,37.60)}
	"models/props_windows/window_urban_sash_32_72_full_gib12.mdl": {mass=1.0,center=Vector(0.00,0.00,36.64)}
	"models/props_windows/window_urban_sash_48_88_full_frame.mdl": {mass=1.0,center=Vector(0.64,0.00,46.00)}
	"models/props_windows/window_urban_sash_48_88_full_gib12.mdl": {mass=1.0,center=Vector(0.00,0.00,34.00)}
}

///////////////////////////////

get_current_table_name <- function() {
	if (this == getroottable()) return "root table"
	foreach(key, val in getroottable()) {
		if (key == "__lib_scopes") continue
		if (val == this) {
			return key
		} else {
			try {
				foreach(key2, val2 in val) {
					if (val2 == this) {
						return key + "." + key2
					} else {
						try {
							foreach(key3, val3 in val2) {
								if (val3 == this) {
									return key + "." + key2 + "." + key3
								} else {
									try {
										foreach(key4, val4 in val3) {
											if (val4 == this) {
												return key + "." + key2 + "." + key3 + "." + key4
											} else {
											
											}
										}
									} catch (e3) {}
								}
							}
						} catch (e2) {}
					}
				}
			} catch (e) {}
		}
	}
	return null
}

local tablename = get_current_table_name()
tablename = tablename ? tablename : (this ? this.tostring() : "null")

log("library included")
log("\t in table [" + tablename + "]")
log("\t with key " + __lib);
log("\t was overwritten: " + overwrite_lib);
