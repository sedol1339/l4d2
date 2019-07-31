# Compatible Custom VScripts Loader
-------------------------------------

This is a code for Workshop addon, that does not do anything by itself, but it allows modders to load their VScript addons without compatibility problems and with full access to ScriptedMode hooks.

Link to workshop: coming soon

This addon DOES NOT TOUCH scriptedmode.nut file!

I've made this addon as a loader for my scripts, but any third party developer can use Custom VScripts Loader for his custom map, mutation or any other script. Benefits that it gives:
1. Your script will be compatible with each other and with almost all addons in workshop, including Admin System, CSS unlocker, Map Entities Extensions, Alternate Difficulties mod, Custom Weapon Base, First Person Animations, Speedrunner tools etc.
2. Your addon will not be colored red in addons list (without Custom VScripts Loader this often happens even with compatible addons)
3. You will always have access to ScriptedMode hooks (`AllowTakeDamage`, `InterceptChat`, `UserConsoleCommand` and others) directly or using new script function `ScriptMode_Hook()`.

### How to use it

1. Place your script into vscripts folder and give it a unique name

             `Example: left4dead2/scripts/vscripts/shchuka.nut`

2. Create empty file maps/scripts_\<scriptname>\.bsp (important!)

             `Example: left4dead2/maps/scripts_shchuka.bsp`

3. Place both files into your addon

             `Example:`
             `maps/scripts_shchuka.bsp`
             `scripts/vscripts/shchuka.nut`
             `addoninfo.txt`

4. Upload addon and add Custom VScripts Loader as a dependency (button "Add/Remove Required Items"). Also you better start your description from words "this addon requires Custom VScripts Loader" and give a link to this addon to make it more clear.

             `Example: coming soon`

**So, all you need is to create a file with required name in maps/ folder and add this addon as a dependency.**

### Some more details

I edited sm_utilities.nut file, that remained untouched by all VScript addons, and added some sofisticated code, which was written after deep research of how the game works. This code does the following:
1. Automatically loads `<scriptname>.nut` if there is file `scripts_<scriptname>.bsp` in `maps` folder
2. Always activates ScriptMode (even without coop.nut, versus.nut and other stubs)
3. Collects ScriptMode hooks from all different scripts, chains them and allows to add new hooks

### How exactly does it work

It's a long time to explain.

As an introduction I remind that since EMS Update a lot of Left 4 Dead 2 VScripts have been released, but there's still a large problem over the scripting community. Valve didn't make a folder for auto-executing scripts, so scripters had to replace scriptedmode.nut file in their addons, which led to a poor compatibility of addons. In short:

1. Scripts are generally incompatible with each other
2. Even compatible scripts are often colored RED in addons list
3. Hooks (`AllowTakeDamage` and others) are not always available

**How does this code auto-loads scripts without knowing their names**

1. Sets cvar `con_logfile = ems/scriptloader/<filename>`
2. Issues command `maps script_`, so list of `script_*.bsp` files is written to `<filename>`
3. Reads and parses `<filename>`, extracting script names
4. Does `IncludeScript("<script>")` for each `script_<script>.bsp` file

**How does this code enables ScriptMode**

I'll start a detailed explanation by demonstrating script loading order in L4D2

![img](https://pp.userapi.com/c855432/v855432672/a4df3/1j0WosClEa8.jpg)

As can be seen, script mode is activated only when `ScriptMode_Init()` function returns true. This happens only when `IncludeScript(modename, g_ModeScript)` returns true, and this happens when file modename.nut or modename.nuc exists and is not empty.

After a little research I've listed all changes that popular workshop mods make to default VScript files.

![img](https://pp.userapi.com/c855416/v855416346/a6f67/hYocYWPuOI4.jpg)

So, it's not possible to change scriptedmode.nut, director_base.nut, coop.nut ... onslaught.nut files if we want full compatibility with other workshop mods (without even marking them red in addons list). But sm_utilities.nut and sm_spawn.nut files are free for edit.

If we create a workshop addon, that contains modified sm_utilities.nut, which includes all dependent scripts, they will be fully compatible with each other and with other workshop addons.

As for ScriptMode, we should have coop.nut ... onslaught.nut files present, but it will again break compatibility (at least addons will be marked red). Hopefully, there is a solution. Since sm_utilities.nut is included earlier than modename.nut, we can override `IncludeScript()` function so that it will always return true. In this case Script Mode will be activated even without modename.nut file.

The next problem is ScriptMode hooks (`AllowTakeDamage()`, `AllowBash()` and others), that can be overwritten by next script files. We solve this problem by searching for these functions on ScriptMode activation and replacing them. Custom VScripts Loader includes new function `ScriptMode_Hook()` than is able to register multiple listeners for ScriptMode events.

Usage:

`ScriptMode_Hook("AllowTakeDamage", function(dmgTable))`

`ScriptMode_Hook("AllowBash", function(basher, bashee))`

`ScriptMode_Hook("BotQuery", function(flag, bot, val))`

`ScriptMode_Hook("CanPickupObject", function(object))`

`ScriptMode_Hook("InterceptChat", function(msg, speaker))`

`ScriptMode_Hook("UserConsoleCommand", function(player, args))`

If, for example `g_MapScript.AllowTakeDamage()` or `::AllowTakeDamage()` function already existed, Custom VScripts Loader will add it as listener and will allow to create new listeners for the same event.

Now the problem is VSLib compatibility. This library completely overrides functions `ScriptMode_OnActivate`, `ScriptMode_OnGameplayStart`, `ScriptMode_SystemCall`, `Update` (instead of hooking them): all functions that are called after step 4. The VSLib itself is often loaded on steps 2 (different mods) or 3 (admin system). Also we can't use delayed calls in sm_utilities, because in dedicated server delay between step 4 and step 9 may be zero.

But we need to run our code AFTER VSLib code, to override ScriptMode hooks that are defined in it. In other words, to override ScriptMode hooks our code should be run after all other `IncludeScript()` statements but not later than `ScriptMode_OnActivate()` is called.

Hacky solution: since we already have `IncludeScript()` hook, after including a script we can check if `ScriptMode_OnActivate()` was changed. If so, we make a backflip: restoring it to saved function and moving new function to `ScriptMode_OnActivateWrapped`.
