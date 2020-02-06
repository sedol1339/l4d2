This is a VScript library for L4D2. Some information:
- Include kapkan/lib/lib.nut to include whole library at once
- Library is divided into parts that are named kapkan/lib/module_*.nut
- Most of library parts require kapkan/lib/module_base.nut
- All library parts contain documentation with examples
- Library always includes itself in root table, no matter which scope you specify
- Library can be included several times, supposedly nothing will break
- This library does not create any entities, running tasks or affecting HUD by default

Author: kapkan https://steamcommunity.com/id/xwergxz/
Repository (may be outdated): https://github.com/sedol1339/l4d2/lib

This library can be used together with VSLib, ImprovedScripting, Speedrunner Tools, Sw1ft's lib_utils, but compatibility was not fully tested.

-------------------------------
---------- Changelog ----------
-------------------------------

Lib v3.0.0 (31.01.2020)
- CHANGE: removed module_convars, functions cvar(), cvarf(), cvarstr() moved to module_base
- CHANGE: removed module_strings, functions moved to module_base
- CHANGE: removed module_advanced, functions moved to module_tasks and module_gamelogic
- CHANGE: removed module_entities, functions moved to module_gamelogic
- CHANGE: removed function for_each_player(), use foreach(player in players()) instead
- CHANGE: removed function switch_to_infected(), use set_playable_team() instead
- CHANGE: removed module_files, functions moved to module_base
- CHANGE: removed connect_strings() alias for function concat()
- CHANGE: removed parameter "restore_cvars" for function restart_game()
- CHANGE: function server_host() moved from module_entities to module_base
- CHANGE: function cvar_create() moved from module_convars to module_serversettings
- CHANGE: removed function disallow_dying_infected_bots() use server_settings.no_bot_deathcams instead
- CHANGE: removed functions stop_director() and stop_director_forced(), use use server_settings.no_director instead
- CHANGE: removed make_playground() function, use functions from module_gamelogic and module_serversettings instead
- NEW: modules module_serversettings, module_addonframework with new functions
- NEW: report() function now detects name collisions and variable type mismatches
- NEW: function broadcast_client_command() in module_gamelogic
- NEW: functions loop_exists(), callback_exists(), loop_pause(), loop_resume() in module_tasks
- NEW: when including file "lib_auto" instead of "lib", constants will not be added to root table
- NEW: functions debug(), debugf(), debug_on(), debug_off() in module_base
- NEW: new function ent_visualise() in module_development
- NEW: buttons_console_cmds, buttons_console_cmds_constraint in module_misc (TODO move somewhere else)
- NEW: function cheats() in module_base
- NEW: functions infected(), humans(), bots(), restart_game_now() in module_gamelogic
- NEW: functions clear_effects(), finish_anim(), remove_items(), resurrect() in module_gamelogic
- NEW: parameter group_key for spawn_infected()
- NEW: constants STATE_DISABLED and STATE_ENABLED
- NEW: new autojump method SP_SMOOTH (see player_settings.autojump in module_serversettings)
- IMPROVE: it's now possible to use functions, binded to some scopes, as task functions (loops, callbacks, delayed calls)
- IMPROVE: if exception occurs in a callback, this will not prevent other callbacks from running
- IMPROVE: all library functions are redefined when library is included again (affects non-root scopes like "hud")
- IMPROVE: optimized function trace_line() in module_math
- IMPROVE: function say_chat() not is able to wait when listenserver host joins the game (see documentation)
- IMPROVE: function spawn_infected() now returns a human player if they take control of spawned zombie
- FIX: All HUD data are clearly removed between rounds
- FIX: on_player_team data and chat commands data are clearly removed between rounds
- FIX: fixed circular references warning after registering callbacks
- FIX: fixed log() and players() descriptions
- FIX: callback functions and delayed calls now check that DirectorScript exists
- tickers, loops and callbacks now use newthread() squirrel built-in function and use func.call(scope) instead of bindenv
- warning! do not use IncludeScript in tickers, loops an callbacks, this may crash the game
- most of library console debug output is now prefixed with "[lib]"
- new files debug.nut, collision_checker.nut, entry.nut for internal usage
- removed useless file kapkan/lib/extras.nut

Lib v2.7.0 (11.01.2020)
- CHANGE: bhop_instructor renamed to bhop_callback
- CHANGE: custom_airstrafe.fsmove_max renamed to custom_airstrafe.speed_max
- NEW: function custom_airstrafe.override_params()
- NEW: position can be null in function spawn_infected(), this means spawn like director spawns
- FIX: fixed custom_airstrafe.press_key() and custom_airstrafe.release_key() functions
- FIX: autobhop smooth method now correctly sets FL_ONGROUND flag and play correct animation
- FIX: fixed hud.hide_list() function
- FIX: fixed watch_netprops() function, when called with null argument
- FIX: when using autobhop SMOOTH method, player will not jump while standing up from infected attacks
- FIX: fixed skip_intro() function in module_gamelogic, now it doesn't use wrong host_map cvar

Lib v2.6.0 (09.01.2020)
- NEW: bhop_instructor.* functions
- NEW: report() now shows detailed autobhop and bhop_instructor state

Lib v2.5.0 (09.01.2020)
- CHANGE: functions duck() and duck_off() moved from module_botcontrol to module_entities
- NEW: 2 methods of autobhop: functions autobhop.set() and autobhop.method() in module_advanced
- NEW: functions blind() and blind_off() in module_entities
- FIX: algorithm corrections in motion_capture and custom_airstrafe, still not 100% accurate
- FIX: register_ticker() and register_loop() now fully supports non-string keys, but key should not be instance
- FIX: re-including library now doesn't reset custom_airstrafe parameters and doesn't break motion_capture recordings
- FIX: file_append() now checks that string is not null, preventing game crash
- FIX: fixed description for mark() function in module_development
- some changes in lib/extras.nut: renamed move_croshair() to move_crosshair()

Lib v2.4.0 (07.01.2020)
- CHANGE: make_playground() and disallow_dying_infected_bots() moved back to module_gamelogic
- CHANGE: module_gamelogic again requires module_tasks
- CHANGE: module_scenarios renamed to module_botcontrol
- NEW: custom_airstrafe.* functions in module_botcontrol
- NEW: mousemove() function in module_botcontrol
- NEW: autofire_start() and autofire_stop() functions in module_botcontrol
- NEW: duck() and duck_off() functions in module_botcontrol
- NEW: motion_capture.* functions in module_botcontrol
- NEW: file_write() now checks that string is not null, preventing game crash
- FIX: module_botcontrol (previous module_scenarios) now also prints it's name to console when included
- FIX: get_datetime() now doesn't catch exceptions in on_get
- FIX: read_console_output(), get_datetime(), register_chat_command() now bind functions to "this"
- FIX: register_chat_command() now throws exception when gets command name that contains spaces

Lib v2.3.0 (04.01.2020)
- New module: lib/module_scenarios
- CHANGE: make_playground() and disallow_dying_infected_bots() moved from module_gamelogic to module_scenarios
- CHANGE: module_gamelogic does not require module_tasks anymore
- CHANGE: heal_survivor() renamed to heal_player()
- CHANGE/FIX: spawn_infected() does not force origin anymore; use optional param "precise_origin" to force origin
- NEW: function set_max_health() in module_entities
- NEW: optional "remove_secondary" param for replace_primary_weapon()
- NEW: function velocity_impulse() in module_entities
- NEW: clock.tick_time field in module_tasks
- IMPROVE: Better client_command() description
- IMPROVE: Better spawn_infected() description
- IMPROVE: report() function now prints keys of delayed calls
- FIX: fixed replace_primary_weapon() function
- FIX: report() function now can print non-string task keys using .tostring()
- FIX: fixed logf() description
- FIX: fixed description of loop_info.delta_time

Lib v2.2.0 (03.01.2020)
- CHANGE: in make_playground() params field "remove_specials_limit" renamed to "increase_specials_limit"
- CHANGE: set_max_specials(amount) replaced by increase_specials_limit() and improved
- CHANGE: fixed mapname() and now it works only in scripted mode
- NEW: spawn_infected() now supports angle
- NEW: function is_scripted_mode() in module_gamelogic
- IMPROVE: spawn_infected() has better debug console output
- FIX: log() now print null values correctly

Lib v2.1.1 (02.01.2020)
- FIX: hud.release_slot() now works for unexisting possessors and slots as intended

Lib v2.1.0 (02.01.2020)
- CHANGE: loop_info.delta_time is now NAN on first call (to fix some strange squirrel bug (??))
- NEW: NAN constant (float Not-a-Number)
- NEW: entstr(ent) function in module_base for using in task keys
- NEW: Support for "ent" param in register_loop() and register_ticker()
- NEW: attach(ent, attachment) function in module_entities
- NEW: lists in HUD system: hud.show_list(), hud.hide_list()
- IMPROVE: report() function now also prints tasks
- FIX: watch_netprops() now uses HUD system instead of conflicting with it
- FIX: fixed crashes, ::root is now weakref to root table
- FIX: fixed watch_netprops() function
- FIX: fixed hud.show_message() function
- FIX: fixed log_event() function
- FIX: fixed on_player_team() and remove_on_player_team() functions
- FIX: fixed on_key_action() function
- FIX: fixed register_chat_command() function
- FIX: fixed show_hud_hint_singleplayer() function
- FIX: fixed disallow_dying_infected_bots() function
- FIX: fixed remove_callback() function
- FIX: fixed report() function
- Added kapkan/lib/extras.nut

Lib v2.0.0 (27.12.2019)
- Library was split into modules that can be included independently
- Library always includes itself in root table
- New signature for delayed_call(), register_ticker(), register_loop(), register_callback() and other tasks
- New way to control loop delays and call times: loop_run_after(key, delay)
- Removing multiple delayed calls at once using group key
- Delayed calls never use scope of entity that passed as param
- FIX: delayed calls are clearly removed between rounds
- Tickers and loops use shared set of keys and use the same logic_timer
- Tickers and loops infos can be read from loop_info table
- FIX: tickers, loops and callbacks are clearly removed between rounds
- FIX: removing logic_timer will not cause subsequent ticker errors
- Removed register_task_on_entity() function
- improved say_chat() function that use formatting, correctly displays unicode and may print long strings
- report() function to print library state to console, lib_version constant
- new ent_fire() function for using with ehandles
- teleport_entity() now doesn't use point_teleport
- some new simple functions in lib/module_entities
- new function create_target_bot() for creating invisible targets for infected attacks
- some new simple functions in lib/module_gamelogic
- skip_intro() function taken from Speedrunner Tools
- complex make_playground() function to create sandbox for scripted scenarios
- new HUD functions: possess_multiple_slots(), release_all_slots(), get_all_slots()
- sliding_random() math function
- read_console_output() function for reading lines from console
- get_datetime() function that retrieves current date and time
- some new data structures in lib/module_misc
- new constants from VSLib
- changed Team table to Teams for compatibility
- added kapkan/lib/phys as an addition to the library