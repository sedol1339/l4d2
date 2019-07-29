**Code for compatible Custom VScripts Loader**
-------------------------------------

As an introduction I will remind that since EMS Update a lot of Left 4 Dead 2 VScripts have been released, but there's still a large problem over the scripting community. Valve didn't make a folder for auto-executing scripts, so scripters had to replace scriptedmode.nut file in their addons, which led to a poor compatibility of addons. In short:

1. Scripts are generally incompatible with each other
2. Even compatible scripts are often colored RED in addons list
3. Hooks (`AllowTakeDamage` and others) are not always available

I edited sm_utilities.nut, that remained untouched by all VScript addons, and added some custom code which always activates Scripted Mode (even without coop.nut, versus.nut and other stubs). But I'm not a magican and cannot create a folder for auto-executing scripts. So, links to script files should be added manually.

I'll start a detailed explanation by demonstrating script loading order in L4D2

![img](https://pp.userapi.com/c855432/v855432672/a4df3/1j0WosClEa8.jpg)

As can be seen, scripted mode is activated only when `ScriptMode_Init()` function returns true. This happens only when `IncludeScript(modename, g_ModeScript)` returns true, and this happens when file modename.nut or modename.nuc exists and is not empty.

After a little research I've listed all changes that popular workshop mods make to default VScript files.

![img](https://pp.userapi.com/c855416/v855416346/a6f67/hYocYWPuOI4.jpg)

So, it's not possible to change scriptedmode.nut, director_base.nut, coop.nut ... onslaught.nut files if we want full compatibility with other workshop mods (without even marking them red in addons list). But sm_utilities.nut and sm_spawn.nut files are free for edit.

If we create a workshop addon, that contains modified sm_utilities.nut, which includes all dependent scripts, they will be fully compatible with each other and with other workshop addons.

As for ScriptedMode, we should have coop.nut ... onslaught.nut files present, but it will again break compatibility (at least addons will be marked red). Hopefully, there is a solution. Since sm_utilities.nut is included earlier than modename.nut, we can override `IncludeScript()` function so that it will always return true. In this case Scripted Mode will be activated even without modename.nut file.

The last problem is ScriptedMode hooks (`AllowTakeDamage()`, `AllowBash()` and others), that can be overwritten by next script files. We solve this problem by searching for these functions after some delay and replacing them. Custom VScripts Loader is registering new function `ScriptedMode_Hook()` than is able to register multiple listeners for ScriptedMode events.

Usage:

`ScriptedMode_Hook("AllowTakeDamage", function(dmgTable))`

`ScriptedMode_Hook("AllowBash", function(basher, bashee))`

`ScriptedMode_Hook("BotQuery", function(flag, bot, val))`

`ScriptedMode_Hook("CanPickupObject", function(object))`

`ScriptedMode_Hook("InterceptChat", function(msg, speaker))`

`ScriptedMode_Hook("UserConsoleCommand", function(player, args))`

If, for example `g_MapScript.AllowTakeDamage()` or `::AllowTakeDamage()` function already existed, Custom VScripts Loader will add it as listener and will allow to create new listeners for the same event.

The last big problem is VSLib compatibility. This library completely overrides functions `ScriptMode_OnActivate`, `ScriptMode_OnGameplayStart`, `ScriptMode_SystemCall`, `Update` (instead of hooking them): all functions that are called after step 4. The VSLib itself is often loaded on steps 2 (different mods) or 3 (admin system). Also we can't use delayed calls in sm_utilities, because in dedicated server delay between step 4 and step 9 may be zero.

But we need to run our code AFTER VSLib code, to override ScriptedMode hooks that are defined in it. In other words, to override ScriptedMode hooks our code should be run after all other `IncludeScript()` statements but not later than `ScriptMode_OnActivate()` is called.

Hacky solution: since we already have `IncludeScript()` hook, after including a script we can check if `ScriptMode_OnActivate()` was changed. If so, we make a backflip: restoring it to saved function and moving new function to `ScriptMode_OnActivateWrapped`.

Finally this is working
