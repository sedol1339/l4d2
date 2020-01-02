This is a VScript library for L4D2. Some information:
- Include kapkan/lib/lib.nut to include whole library at once
- Library is divided into parts that are named kapkan/lib/module_*.nut
- Most of library parts require kapkan/lib/module_base.nut
- All library parts contain documentation with examples
- Library uses kapkan/lib folder to prevent name collisions
- Library always includes itself in root table, no matter which scope you specify
- Library can be included several times, supposedly nothing will break
- This library does not create any entities, running tasks or affecting HUD by default

Author: kapkan https://steamcommunity.com/id/xwergxz/
Repository (may be outdated): https://github.com/sedol1339/l4d2/lib

This library can be used together with VSLib, ImprovedScripting, Speedrunner Tools, Sw1ft's lib_utils, but compatibility was not fully tested.

There are some conventions that I used when writing code for this library.
- Most functions are placed in root table.
- All constants are copied to root table.
- Library does not create or affect entities, HUD by default.
- Library does not create any callbacks by default.
- Understandability: functions and variables are named in most clear way. I use snake_case, don't use hungarian notation.
- Encapsulation: internal variables or functions, that are not meant to be used from outside, are eigher made local or prefixed with "__".
- Grouping: all lines of code that refer to the same action are placed in one module and one place if possible.
- Simplicity: classes should only be used where they are really needed.
- I finally unlearned to put a semicolon at the end of line.
- Version number uses semantic versioning convention.

-------------------------------
---------- Changelog ----------
-------------------------------

Lib v2.1.0 (02.01.2020)
- Added entstr(ent) function in module_base for using in task keys
- Added support for "ent" param in register_loop() and register_ticker()
- Added NAN constant (float Not-a-Number)
- loop_info.delta_time is now NAN on first call (to fix some strange squirrel bug (??))
- Added attach(ent, attachment) function in module_entities
- Added kapkan/lib/extras.nut
- Added lists in HUD system: hud.show_list(), hud.hide_list()
- report() function now also prints tasks
- watch_netprops() now uses HUD system instead of conflicting with it
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