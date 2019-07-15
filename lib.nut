/*
 This file contains some useful functions.
 It can be run several times, nothing breaks.
 Performance is optimized where possible. This library does not create any entities or running tasks by default.
 Short documentation:
 
 FUNCTIONS FOR LOGGING:
 log(str)						prints to console
 say_chat(str, ...)				prints to chat for all players; if more than one argument, using formatting like say_chat(format(str, ...))	
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
 vecstr2(vec)					vec to string (compact 2-digits representation): "0.00 1.00 -1.00"
 vecstr3(vec)					vec to string (compact 3-digits representation): "0.000 1.000 -1.000"
 
 MISC FUNCTIONS
 checktype(var, type)			throws exception if var is not of specified type;
								type can be string: "string", "float", "integer", "bool", "Vector", "array", "function", "native function" etc.
								type can be int constant: NUMBER (integer or float), FUNC (function or native function), STRING or BOOL constants
								type can be array of string types
 
 TASK SHEDULING
 delayed_call(func, delay)					runs func after delay; pass scope or entity as additional param; returns key; see function declaration for more info
 run_this_tick(func)						runs function later (in this tick)
 run_next_tick(func)						runs function later (in next tick)
 register_callback(event, key, func)		registers callback for event using key; pass params table to func
 register_ticker(key, func)					register a function that will be called every tick; example: register_ticker("my_key", @()log("tick"))
 add_task_on_shutdown(key, func)			register a function that will be called on server shutdown; pass true as additional param to run this after all others
 register_loop(key, func, refire_time)		register a function that will be called with an interval of refire_time seconds
 loop_reset(key)							reset loop using it's key; see function declaration for more info
											by default this will prevent loop from running this tick; if you don't want this, pass false as additional param
 loop_subtract_from_timer(key, value)		subtract value from loop timer (function is called then timer value becomes 0)
 loop_add_to_timer(key, value)				add value to loop timer
											by default this will prevent loop from running this tick; if you don't want this, pass false as additional param
 loop_get_refire_time(key)					returns refire time for loop
 loop_set_refire_time(key, refire_time)		sets new refire time for loop
 register_task_on_entity(ent, func, delay)	registers a loop for entity (using AddThinkToEnt); pass REAL delay value in seconds; this is not chained
 on_player_connect(team, isbot, func)		register a callback for player_team event that will fire for specified team and params.isbot condition;
											this is not chained; pass null to cancel
 
 TASK CANCELLING
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
 
 TASK LOGGING
 print_all_tasks()				prints ALL sheduled tasks (does not print tasks on entitites); specific functions are below
 print_all_delayed_calls()		prints all pending delayed calls
 print_all_callbacks()			prints all callbacks
 print_all_tickers()			prints all tickers
 print_all_tasks_on_shutdown()	prints all tasks on shutdown
 print_all_loops()				prints all loops
 
 DEVELOPMENT FUNCTIONS
 log_event(event)				start logging event; pass false as additional param to cancel
 log_events()					start logging all events; pass false as additional param to cancel
 watch_netprops(ent,[netprops])	for singleplayer: print entity netprops in real time in HUD and binds actions to save/restore them;
								see function declaration for more info
 
 CONVARS FUNCTIONS
 cvar(cvar, value)				shortcut for Convars.SetValue(cvar, value); also makes logging
 cvarstr(cvar)					shortcut for Convars.GetStr
 cvarf(cvar)					shortcut for Convars.GetFloat
 cvar_create(cvar, value)		performs "setinfo cvar value", this value can be retrieved or changed later using cvar(), cvarf(), cvarstr();returns value
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
 deleted_ent(ent)				returns true if entity doesn't exist anymore
 player()						for singleplayer: fast function that returns human player
 bot()							for testing: returns first found bot player
 for_each_player(func)			calls function for every player, passes player as param
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
 hud.posess_slot(possessor, name)			take control over freeslot; name - any number or string to name the slot (does not match real slot id,
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

//don't change this line
include_lib <- function() {

///////////////////////////////

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

//solid types
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

constants.NUMBER <- -1
constants.FUNC <- -2
constants.STRING <- -3
constants.BOOL <- -4

g_ModeScript.InjectTable(constants, this);

if (!("__lib" in this)) {
	if (this == getroottable())
		ln <- log; //logarifm
		
	//the following is currently used only for tasks on shutdown
	__lib <- UniqueString(); //identifier
	if (!("__lib_scopes" in getroottable()))
		::__lib_scopes <- {};
	::__lib_scopes[__lib] <- this;
}

log <- printl

say_chat <- function(message, ...) {
	if (vargv.len() > 0) {
		local args = [this, message]
		args.extend(vargv)
		message = format.acall(args)
	}
	Say(null, message, false)
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
	if (deleted_ent(player)) return "(deleted entity)";
	return format("(player %d | %s)", player.GetEntityIndex().tointeger(), player.GetPlayerName());
}

ent_to_str <- function(ent) {
	if (deleted_ent(ent)) return "(deleted entity)";
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

///////////////////////////////

cvar <- function(_cvar, value) {
	logf("cvar %s set to %s", _cvar, value.tostring());
	Convars.SetValue(_cvar, value);
}

cvarstr <- Convars.GetStr.bindenv(Convars)

cvarf <- Convars.GetFloat.bindenv(Convars)

cvar_create <- function(_cvar, value) {
	logf("cvar %s created and set to %s", _cvar, value.tostring());
	SendToServerConsole("setinfo " + _cvar + " " + value) //if anyone doesn't alias setinfo!
	return value
}

/* we need next 3 functions to restore all previously set cvars if user toggles sv_cheats */

if (!("cvars_list" in this)) cvars_list <- {};

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

deleted_ent <- function(ent) {
	if (!("IsValid" in ent)) return true;
	return !ent.IsValid();
}

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

for_each_player <- function (func) {
	local tmp_player = null;
	while (tmp_player = Entities.FindByClassname(tmp_player, "player"))
		if (tmp_player) func(tmp_player);
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
		Convars.SetValue("sv_cheats", 1);
		Convars.SetValue("sv_cheats", 0);
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

if (!("__current_hints" in this)) __current_hints <- {}

create_particles <- function(effect_name, origin, duration = -1) {
	local effect = SpawnEntityFromTable("info_particle_system", {
		effect_name = effect_name,
		origin = origin,
	});
	DoEntFire("!self", "Start", "", 0, null, effect);
	if (duration != -1) DoEntFire("!self", "Kill", "", duration, null, effect);
	return effect;
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
	if ("startsolid" in table && table.startsolid)
		table.fraction = 0;
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

///////////////////////////////

if (!("clock" in this)) clock <- {

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
delayed_call(func, delay) - calls function after delay (seconds);
delayed_call(func, delay, scope) - calls function after delay (seconds) using scope as environment;
delayed_call(func, delay, entity) - calls function after delay (seconds) using entity script scope as environment;

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
//it's the same as this:
entity.ValidateScriptScope();
delayed_call(function(){ self.Kill() }.bindenv(entity.GetScriptScope()), 0.5)

///// delays /////
delay == 0:			function always runs THIS tick, runs immediately even if game is paused
delay <= 0.0333:	function always runs THIS tick, immediately after if game is unpaused;
					nested delayed calls even with non-zero delay will be executed not earlier than next tick
delay >= 0.0334:	function always runs NEXT tick
these numbers are bound to tickrate; this behaviour probably do not depend on server performance
(even when you run heavy script every tick, tickrate remains 30)

you can also use run_this_tick(func), run_next_tick(func)
*/

delayed_call <- function(func, delay, scope_or_ent = null) {
	local key = UniqueString();
	if (scope_or_ent) {
		if ("GetScriptScope" in scope_or_ent) {
			scope_or_ent.ValidateScriptScope();
			func = func.bindenv(scope_or_ent.GetScriptScope());
		} else func = func.bindenv(scope_or_ent);
	}
	::__dc_func[key] <- {
		func = func,
		time = Time() + delay
	}
	if ("dc_debug" in getroottable() && ::dc_debug) {
		log("delayed call registered with key " + key);
		__printstackinfos();
	}
	DoEntFire("!self", "runscriptcode", "::__dc_check()", delay, null, worldspawn);
	return key;
}

worldspawn <- Entities.FindByClassname(null, "worldspawn");

::__dc_check <- function() {
	local time = Time();
	foreach (key, table in ::__dc_func) {
		if (table.time <= time) {
			try {
				table.func();
			} catch(exception) {
				error(format("Exception for delayed call (%s): %s\n", key, exception));
			}
			delete ::__dc_func[key];
		}
	}
}

if (!("__dc_func" in getroottable())) ::__dc_func <- {}

remove_delayed_call <- function (key) {
	if (key in ::__dc_func)
		delete ::__dc_func[key];
}

remove_all_delayed_calls <- function () {
	::__dc_func <- {};
}

run_this_tick <- function(func)  {
	local args = [this, func, 0];
	args.extend(vargv);
	delayed_call.acall(args);
}

run_next_tick <- function(func)  {
	local args = [this, func, 0.001];
	args.extend(vargv);
	delayed_call( function() {
		delayed_call.acall(args);
	}, 0.001);
}

print_all_delayed_calls <- function() {
	print("All delayed calls registered:");
	local strings = [];
	foreach(key, table in __dc_func) {
		strings.push(format(
			"\"%s\": will be called after %f seconds",
			key, table.time - Time()
		));
	}
	if (strings.len() == 0)
		printl(" [none]");
	else {
		printl("");
		foreach(str in strings) printl(str);
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
			foreach(callback in __callbacks[scope.event_name])
				callback(params);
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

//cant' use constants or enums, because vm don't see them from
//other files if we IncludeScript() this library into them

Team  <-{
	ANY = -1
	UNASSIGNED = 0
	SPECTATORS = 1
	SURVIVORS = 2
	INFECTED = 3
}

ClientType <- {
	ANY = -1
	HUMAN = 0
	BOT = 1
}

on_player_connect <- function(team, isbot, func) {
	//it's ok to be registered multiple times
	register_callback("player_team", "__on_player_connect", function(params) {
		local func = __on_player_connect[params.team][params.isbot ? 1 : 0];
		if (func) {
			params.player <- GetPlayerFromUserID(params.userid);
			func(params);
		}
	});
	if (team == Team.ANY && isbot == ClientType.ANY) throw "specify team ot playertype for on_player_connect";
	if (team == Team.ANY) {
		__on_player_connect[0][isbot] = func;
		__on_player_connect[1][isbot] = func;
		__on_player_connect[2][isbot] = func;
		__on_player_connect[3][isbot] = func;
	} else if (isbot == ClientType.ANY) {
		__on_player_connect[team][0] = func;
		__on_player_connect[team][1] = func;
	} else
		__on_player_connect[team][isbot] = func;
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
*/

register_ticker <- function(key, func) {
	if (!key) key = UniqueString();
	if (!__ticker_ent || deleted_ent(__ticker_ent))
		__ticker_init();
	__tickers[key] <- func;
}

__ticker_init <- function() {
	if (__ticker_ent && !deleted_ent(__ticker_ent))
		return;
	__ticker_ent = SpawnEntityFromTable("logic_timer", {
		RefireTime = 0,
	});
	__ticker_ent.ConnectOutput("OnTimer", "func");
	__ticker_ent.ValidateScriptScope();
	__ticker_ent.GetScriptScope().func <- function() {
		clock.__ticks++;
		foreach(ticker in __tickers)
			ticker();
	}.bindenv(this);
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
		if (!deleted_ent(ent))
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

__netprops_bitmaps <- {
	m_fFlags = ["FL_ONGROUND", "FL_DUCKING", "FL_WATERJUMP", "FL_ONTRAIN", "FL_INRAIN", "FL_FROZEN", "FL_ATCONTROLS", "FL_CLIENT", "FL_FAKECLIENT", "FL_INWATER", "FL_FLY", "FL_SWIM", "FL_CONVEYOR", "FL_NPC", "FL_GODMODE", "FL_NOTARGET", "FL_AIMTARGET", "FL_PARTIALGROUND", "FL_STATICPROP", "FL_GRAPHED", "FL_GRENADE", "FL_STEPMOVEMENT", "FL_DONTTOUCH", "FL_BASEVELOCITY", "FL_WORLDBRUSH", "FL_OBJECT", "FL_KILLME", "FL_ONFIRE", "FL_DISSOLVING", "FL_TRANSRAGDOLL", "FL_UNBLOCKABLE_BY_PLAYER", "FL_FREEZING"],
	m_nButtons = ["IN_ATTACK", "IN_JUMP", "IN_DUCK", "IN_FORWARD", "IN_BACK", "IN_USE", "IN_CANCEL", "IN_LEFT", "IN_RIGHT", "IN_MOVELEFT", "IN_MOVERIGHT", "IN_ATTACK2", "IN_RUN", "IN_RELOAD", "IN_ALT1", "IN_ALT2", "IN_SCORE", "IN_SPEED", "IN_WALK", "IN_ZOOM", "IN_WEAPON1", "IN_WEAPON2", "IN_BULLRUSH", "IN_GRENADE1", "IN_GRENADE2"],
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

///////////////////////////////

//don't change this lines
}
include_lib()

///////////////////////////////

log("library included");
