//---------- DOCUMENTATION ----------

/**
FUNCTIONS FOR CONTROLLING GAME LOGIC
FUNCTIONS THAT PROVIDE A CONSISTENT WAY TO CONFIGURE SERVER
This module provides an easy way to configure a server with cvars(), settings() and sanitize() commands. Function settings() collects settings from different modules in one place.
! requires lib/module_base !
! requires lib/module_convars !
! requires lib/module_entities !
! requires lib/module_tasks !
------------------------------------
mapname()
	Returns current map name. Works only in scripted mode.
------------------------------------
modename()
	Returns current mode name (including mutations, takes it from convar mp_gamemode).
------------------------------------
skip_intro()
	Skips intro. Script taken from Speedrunner Tools: https://steamcommunity.com/sharedfiles/filedetails/?id=510955402
------------------------------------
restart_game()
	Restarts round in 1 second by setting mp_gamemode 1.
------------------------------------
restart_game_now()
	Tries to restart game just now.
------------------------------------
is_scripted_mode()
	Is scripted mode enabled? Internally function checks that ::SessionState exists.
------------------------------------
worldspawn
	Worldspawn entity. See lib/base for declaration.
------------------------------------
scope(ent)
	Validates and returns entity script scope. See lib/base for declaration.
------------------------------------
invalid(ent)
	Returns true if this is not a valid entity, for example deleted one. Has an alias "deleted_ent(ent)". See lib/base for declaration.
------------------------------------
player()
	Fast function that returns a human player in singleplayer, can use also Ent(1).
------------------------------------
bot()
	For testing: returns first found bot player.
------------------------------------
players(team = Teams.ANY)
	Returns array of player entities, optionally pass team bitmask (Teams.UNASSIGNED, Teams.SPECTATORS, Teams.SURVIVORS, Teams.INFECTED).
	Example: players(Teams.SURVIVORS | Teams.SPECTATORS)
------------------------------------
humans(team = Teams.ANY)
	Return array of all human players, optionally pass team bitmask, like in players() function.
------------------------------------
bots(team = Teams.ANY)
	Return array of all bot players, optionally pass team bitmask, like in players() function.
------------------------------------
infected()
	Return array of all infected players, commons and witches
------------------------------------
get_team(player)
	Returns team of player (of Teams table: Teams.UNASSIGNED, Teams.SPECTATORS, Teams.SURVIVORS, Teams.INFECTED)
------------------------------------
propint(ent, prop[, value])
	Get/set integer offset.
	Example: propint(player(), "movetype") //returns movetype of player
	Example: propint(player(), "movetype", 0) //sets movetype of player to 0
------------------------------------
propfloat(ent, prop[, value])
	Get/set float offset.
	Example: propfloat(player(), "m_itTimer.m_timestamp", Time())
------------------------------------
propstr(ent, prop[, value])
	Get/set string offset.
	Example: propstr(player(), "m_ModelName")
------------------------------------
propvec(ent, prop[, value])
	Get/set Vector offset.
	Example: propvec(car, "m_angRotation")
------------------------------------
propent(ent, prop[, value])
	Get/set entity handle offset.
	Example: propent(charger, "m_carryVictim") //returns carry victim of charger
	Example: propent(charger, "m_carryVictim", null) //sets carry victim of charger to null
------------------------------------
set_ability_cooldown(player, cooldown)
	Set cooldown for player's custom ability (for example, charge).
------------------------------------
remove_dying_infected()
	Removes all infected bots that were killed and are in "dying" state (death cam). See also no_SI_with_death_cams() in lib/module_advanced (this requires lib/module_tasks).
------------------------------------
spawn_infected(type, position = null, angle = null, precise_origin = false, group_key = null)
	Spawn special infected and returns it, returns null if can't spawn. Also validates script scope of spawned entity. This function uses ZSpawn() internally, that tries to spawn zombie on ground. So position can be slightly corrected. If you want precise position, use optional parameter precise_origin = true. Function spawn_infected sets entity angle correctly, use enable_fast_rotation() to to make zombie's body instantly turn in the right direction.
	Group_key is unnecessary parameter. It is only usable in spawn watcher (see module_watchers).
------------------------------------
teleport_entity(ent, pos, ang)
	Teleports entity. pos == null means don't change pos, ang == null means don't change ang.
------------------------------------
defib_dead_survivor(player)
	Defibs dead survivor and skips animation.
------------------------------------
set_max_health(player, max_health)
	Sets max health for player.
------------------------------------
heal_player(player)
	Heals player and revives him from incap. Performs .GiveItem("health") and .SetHealthBuffer(0).
------------------------------------
velocity_impulse(entity, impulse_vec)
	Apples a velocity impulse. Internally adds impulse_vec to m_vecBaseVelocity.
------------------------------------
teleport_survivors_to_start_points()
	Teleports all survivors to start points. Sends ForceSurvivorPositions and ReleaseSurvivorPositions to info_director entity.
------------------------------------
enable_fast_rotation(enable = true)
	When entities are teleported with angle != null, they will immediately be rotated in the right direction.
------------------------------------
create_target_bot(position)
	Creates invisible target of survivor team, that can be used to attract infected attacks. Bot doesn't move and is not visible. All special infected except smoker can't catch this bot, they will pass through it. However it will appear on HUD as a survivor. Also it may make a jockey sound once. Returns created bot. Throws exception if cannщt create a bot because there is too many bots already.
remove_target_bot(bot)
	Removes bot created by create_target_bot(). Don't try to .Kill() target bot, it will crash the game.
------------------------------------
get_entity_flag(entity, flag)
	Returns entity flag from m_fFlags.
	Example: get_entity_flag(player(), FL_FROZEN)
------------------------------------
set_entity_flag(entity, flag, value)
	Sets entity flag from m_fFlags.
	Example: set_entity_flag(player(), FL_FROZEN, true)
	Example: set_entity_flag(Ent("!player"), (1 << 5), false)
------------------------------------
get_player_button(player, button)
	Returns true if specified button is pressed.
	Example: get_player_button(player(), IN_JUMP)
------------------------------------
force_player_button(player, button, force = true)
	Forces button for player using m_afButtonForced. Pass false as additional param to release button.
------------------------------------
duck(player, instant = true)
	Forces human player or bor to duck. If instant == true, skips ducking animation.
duck_off(player)
	Stops forcing player to duck.
------------------------------------
blind(infected)
	Sets all sense flags for infected, so that it cannot see survivors anymore.
blind_off(infected)
	Infected can see survivors again.
------------------------------------
kill_player(player, attacker = null, set_revive_count = true)
	Kills player by increasing revive count to 100 and calling TakeDamage(). For survivor works only if god=0. Optionally pass attacker as additional param to specify in TakeDamage() function. Set last optional arg to false if you don't want to increase revive count before dealing damage.
------------------------------------
targetname_to_entity(name)
	Returns entity with given targetname or null. Prints warning if there are multiple entities with this targetname.
------------------------------------
find_entities(classname)
	Finds entities by classname, returns array of found entities.
------------------------------------
replace_primary_weapon(player, weapon, laser = false)
	Replaces weapon in primary slot. Pass weapon name as string. Pass true as additional argument to give laser sight.
------------------------------------
create_particles(effect_name, origin_or_parent, duration = -1, attachment = null)
	Creates particles for given duration (default -1 is infinite). Pass origin vector or parent entity as second param. Optionally you can specify attachment point for attaching particles to parent entity. Returns particles entity.
	Example: create_particles("achieved", jockey.GetOrigin(), 6)
------------------------------------
attach(ent, attachment)
	Attaches info_target to specified attachment point of entity and returns it.
	Example: local lfoot = attach(hunter, "lfoot")
------------------------------------
clear_effects()
	Removes adrenaline effect, vomit from all survivors, removes all flying projectiles.
------------------------------------
finish_anim()
	Finish animation for all survivors (for example, getting up from charge).
------------------------------------
remove_items()
	Remove all weapon, items (also from player inventories) and wepon/item spawns.
------------------------------------
resurrect(player)
	Revive survivor if dead or incapacitated and give them full health.
------------------------------------
increase_specials_limit()
	Sets MaxSpecials = 32 in different tables, that allows spawning 6+ specials simultaneously. If scripted mode is not active, this seems to work only in coop mode. Made with help of Rayman's admin system.
------------------------------------
is_hitscan_weapon(name)
	Given weapon name returns true if weapon is hitscan.
------------------------------------
playsound(path, ent)
	Precaches and plays sound on entity. Soundscripts or paths can be used. If you add sounds to your addon, build sound cache.
------------------------------------
pellets_count(weapon_name)
	Returns pellets count of weapon (1 for all firearm except shotguns, null for not firearm weapons).
------------------------------------
show_hud_hint_singleplayer(text, color, icon, binding, time)
	Shows hud hint to player.
	Example: show_hud_hint_singleplayer("Use reload or leave field to cancel.", Vector(255,255,255), null, "+reload", 2)
	Example: show_hud_hint_singleplayer("Use reload or leave field to cancel.", Vector(255,255,255), "icon_info", null, 2)
------------------------------------
client_command(player, cmd)
	Send command from player using point_clientcommand. Command should have "server_can_execute" flag if run on dedicated server.
------------------------------------
broadcast_client_command(cmd)
	Send command from all players using point_broadcastclientcommand. Command should have "server_can_execute" flag if run on dedicated server.
 */

//---------- CODE ----------

this = ::root

log("[lib] including module_gamelogic")

/* returns single player */
_def_func("player", function() {
	if (__player) return __player;
	local ent = null;
	while (ent = Entities.FindByClassname(ent, "player")){
		if (ent && !IsPlayerABot(ent)) {
			__player = ent;
			return ent;
		}
	}
})

_def_var_nullable("__player", null, "instance")

//returns first found bot player
_def_func("bot", function() {
	local ent = null;
	while (ent = Entities.FindByClassname(ent, "player")){
		if (ent && IsPlayerABot(ent)) {
			return ent;
		}
	}
})

_def_func("players", function (teams = Teams.ANY) {
	local player = null
	local arr = []
	while (player = Entities.FindByClassname(player, "player")) {
		if (get_team(player) & teams)
			arr.push(player)
	}
	return arr
})

_def_func("humans", function (teams = Teams.ANY) {
	local player = null
	local arr = []
	while (player = Entities.FindByClassname(player, "player")) {
		if (
			(get_team(player) & teams)
			&& !IsPlayerABot(player)
		) {
			arr.push(player)
		}
	}
	return arr
})

_def_func("bots", function (teams = Teams.ANY) {
	local player = null
	local arr = []
	while (player = Entities.FindByClassname(player, "player")) {
		if (
			(get_team(player) & teams)
			&& IsPlayerABot(player)
		) {
			arr.push(player)
		}
	}
	return arr
})

_def_func("infected", function (teams = Teams.ANY) {
	local arr = []
	local ent = null
	while (ent = Entities.FindByClassname(ent, "player")) {
		if (NetProps.GetPropInt(ent, "m_iTeamNum") == 3) arr.append(ent)
	}
	ent = null
	while (ent = Entities.FindByClassname(ent, "infected")) {
		arr.append(ent)
	}
	ent = null
	while (ent = Entities.FindByClassname(ent, "witch")) {
		arr.append(ent)
	}
	return arr
})

_def_func("get_team", function(player) {
	return 1 << NetProps.GetPropInt(player, "m_iTeamNum")
})

_def_func("propint", function(ent, prop, value = null) {
	if (value != null)
		NetProps.SetPropInt(ent, prop, value)
	else
		return NetProps.GetPropInt(ent, prop)
})

_def_func("propfloat", function(ent, prop, value = null) {
	if (value != null)
		NetProps.SetPropFloat(ent, prop, value)
	else
		return NetProps.GetPropFloat(ent, prop)
})

_def_func("propstr", function(ent, prop, value = null) {
	if (value != null)
		NetProps.SetPropString(ent, prop, value)
	else
		return NetProps.GetPropString(ent, prop)
})

_def_func("propvec", function(ent, prop, value = null) {
	if (value != null)
		NetProps.SetPropVector(ent, prop, value)
	else
		return NetProps.GetPropVector(ent, prop)
})

_def_func("propent", function(ent, prop, ...) {
	if (vargv.len() > 1)
		throw "wrong number of arguments"
	if (vargv.len() == 1)
		NetProps.SetPropEntity(ent, prop, vargv[0])
	else
		return NetProps.GetPropEntity(ent, prop)
})

_def_func("set_ability_cooldown", function(player, cooldown) {
	local ability = propent(player, "m_customAbility")
	propfloat(ability, "m_nextActivationTimer.m_timestamp", Time() + cooldown)
	propfloat(ability, "m_nextActivationTimer.m_duration", cooldown)
})

//kill bots with death camera
_def_func("remove_dying_infected", function() {
	foreach(player in players(Teams.INFECTED)) {
		if (player.IsDying() && IsPlayerABot(player))
			player.Kill()
	}
})

/* returns spawned player or null */
_def_func("spawn_infected", function(
	param_type,
	param_pos = null,
	param_ang = null,
	precise_origin = false,
	group_key = null,
	__supress_output = false
) {
	if (typeof param_type != "integer" || param_type < 1 || param_type > 8) {
		log("[lib] spawn_infected(): ERROR! wrong zombie type " + param_type)
		return null; //survivor spawning is not working
	}
	local on_spawn = function(player) {
		scope(player).group_key <- group_key
		teleport_entity(player, precise_origin ? param_pos : null, param_ang)
	}
	local names = ["ZOMBIE_NORMAL", "ZOMBIE_SMOKER", "ZOMBIE_BOOMER", "ZOMBIE_HUNTER", "ZOMBIE_SPITTER", "ZOMBIE_JOCKEY", "ZOMBIE_CHARGER", "ZOMBIE_WITCH", "ZOMBIE_TANK", "Z_SURVIVOR", "ZSPAWN_MOB", "ZSPAWN_WITCHBRIDE", "ZSPAWN_MUDMEN"]
	local player = null;
	local tmp_last_player = null;
	while(player = Entities.FindByClassname(player, "player")) {
		tmp_last_player = player
		if (!IsPlayerABot(player)) scope(player).prev_life_state <- propint(player, "m_lifeState")
	}
	local table = { type = param_type }
	if (param_pos) table.pos <- param_pos
	ZSpawn(table)
	player = Entities.FindByClassname(tmp_last_player, "player");
	if (!player) {
		while(player = Entities.FindByClassname(player, "player")) {
			if (
				!IsPlayerABot(player)
				&& ("prev_life_state" in scope(player))
				&& scope(player).prev_life_state != 0
				&& propint(player, "m_lifeState") == 0
			) {
				delete scope(player).prev_life_state
				if (!__supress_output)
					logf("[lib] spawn_infected(): player %s takes control of spawned %s",
						player_to_str(player), names[param_type])
				on_spawn(player)
				return player
			}
		}
		if (!__supress_output)
			logf("[lib] spawn_infected(): ERROR! cannot find spawned %s, returning null", names[param_type])
		return null
	}
	if(player.GetZombieType() == 9) {
		if (!__supress_output)
			logf("[lib] spawn_infected(): ERROR! zombieType of %s is 9, returning null", names[param_type])
		return null; //if an extra infected bot appears, it becomes a survivor and is then removed
	}
	if (!__supress_output)
		log("[lib] spawn_infected(): spawning " + names[param_type] + ": " + player_to_str(player));
	on_spawn(player)
	return player
})

_def_func("create_target_bot", function(pos) {
	local target_bot = spawn_infected(ZOMBIE_JOCKEY, pos)
	if (!target_bot) throw "Cannot create target bot"
	propint(target_bot, "m_isGhost", 1)
	propint(target_bot, "m_iTeamNum", 2) //moving to survivors
	local weapon = target_bot.GetActiveWeapon()
	if (weapon) weapon.Kill()
	propint(target_bot, "m_bSurvivorGlowEnabled", 0)
	propint(target_bot, "movetype", 0)
	propint(target_bot, "m_nRenderMode", 10) //RENDER_NONE
	propint(target_bot, "m_fadeMaxDist", 0)
	propint(target_bot, "m_CollisionGroup", 1)  //COLLISION_GROUP_DEBRIS, after this SI can't catch bots, except smoker
	propint(target_bot, "m_takedamage", 0)
	propint(target_bot, "m_iMaxHealth", 50000)
	target_bot.SetHealth(50000)
	propfloat(target_bot, "m_flModelScale", 0.01)
	return target_bot
})

_def_func("remove_target_bot", function(target_bot) {
	propint(target_bot, "m_iTeamNum", 3)
	target_bot.Kill()
})

_def_func("teleport_entity", function(ent, param_origin, param_angles) {
	assert(ent);
	if (param_origin) ent.SetOrigin(param_origin)
	if (param_angles) ent.SetForwardVector(param_angles.Forward()) //this works for players
})

_def_func("defib_dead_survivor", function(player) {
	player.ReviveByDefib()
	propfloat(player, "m_flCycle", 0.99)
	propint(player, "m_useActionOwner", 0)
	propint(player, "m_useActionTarget", 0)
	propint(player, "m_iCurrentUseAction", 0)
})

_def_func("set_max_health", function(player, max_health) {
	propint(player, "m_iMaxHealth", max_health)
})

_def_func("heal_player", function(player) {
	player.GiveItem("health")
	player.SetHealthBuffer(0)
})

_def_func("velocity_impulse", function(ent, impulse_vec) {
	propvec(ent, "m_vecBaseVelocity", propvec(ent, "m_vecBaseVelocity") + impulse_vec)
})

_def_func("teleport_survivors_to_start_points", function() {
	EntFire("info_director", "ForceSurvivorPositions")
	EntFire("info_director", "ReleaseSurvivorPositions")
})

_def_func("enable_fast_rotation", function(enabled = true) {
	Convars.SetValue("mp_feetmaxyawrate", enabled ? 99999 : 100.0)
	Convars.SetValue("mp_feetyawrate", enabled ? 99999 : 180)
	Convars.SetValue("mp_feetyawrate_max", enabled ? 99999 : 360)
	Convars.SetValue("mp_facefronttime", enabled ? 0 : 2)
})

_def_func("get_entity_flag", function(ent, flag) {
	return (propint(ent,"m_fFlags") & flag) ? true : false
})

_def_func("set_entity_flag", function(ent, flag, value) {
	local flags = propint(ent,"m_fFlags")
	flags = value ? (flags | flag) : (flags & ~flag)
	propint(ent, "m_fFlags", flags)
})

_def_func("get_player_button", function(player, button) {
	return (player.GetButtonMask() & button) ? true : false
})

_def_func("force_player_button", function(player, button, press = true) {
	local buttons = propint(player, "m_afButtonForced")
	if (press)
		propint(player, "m_afButtonForced", buttons | button)
	else
		propint(player, "m_afButtonForced", buttons &~ button)
})

_def_func("kill_player", function(player, attacker = null, set_revive_count = true) {
	if (set_revive_count) player.SetReviveCount(100)
	local dmg = 10e6
	player.TakeDamage(dmg, 0, attacker)
	logf("[lib] killed %s with %g damage", player_to_str(player), dmg)
})

_def_func("targetname_to_entity", function(targetname) {
	local ent = Entities.FindByName(null, targetname)
	if (!ent) {
		log("[lib] WARNING! targetname_to_entity(): entity with targetname " + targetname + " does not exist")
		return null
	}
	if (Entities.FindByName(ent, targetname)) {
		log("[lib] WARNING! targetname_to_entity(): multiple entities with targetname " + targetname + " exist")
	}
	return ent
})

_def_func("find_entities", function(classname) {
	local ent = null
	local arr = []
	while (ent = Entities.FindByClassname(ent, classname))
		arr.push(ent)
	return arr
})

_def_func("replace_primary_weapon", function(player, weapon, laser_sight = false, remove_secondary = false) {
	local inv_table = {}
	GetInvTable(player, inv_table)
	if ("slot0" in inv_table)
		inv_table.slot0.Kill()
	if (remove_secondary && "slot1" in inv_table)
		inv_table.slot1.Kill()
	run_this_tick(function() {
		player.GiveItem(weapon)
		if (laser_sight)
			player.GiveUpgrade(UPGRADE_LASER_SIGHT)
	})
})

_def_func("create_particles", function(effect_name, origin_or_parent, duration = -1, attachment = null) {
	local origin = null
	local parent = null
	if (typeof(origin_or_parent) == "Vector")
		origin = origin_or_parent
	else
		parent = origin_or_parent
	local effect = SpawnEntityFromTable("info_particle_system", {
		effect_name = effect_name
		origin = origin ? origin : parent.GetOrigin()
		start_active = 1
	});
	if (parent) DoEntFire("!self", "SetParent", "!activator", 0, parent, effect)
	if (duration != -1) DoEntFire("!self", "Kill", "", duration, null, effect);
	if (attachment) {
		if (!parent)
			log("[lib] WARNING! create_particles(): attachment without parent, ignored")
		else
			DoEntFire("!self", "SetParentAttachment", attachment, 0.01, null, target)
	}
	return effect
})

_def_func("attach", function(entity, attachment) {
	local target = SpawnEntityFromTable("info_target", {origin = entity.GetOrigin()})
	DoEntFire("!self", "SetParent", "!activator", 0, entity, target)
	DoEntFire("!self", "SetParentAttachment", attachment, 0, entity, target)
	return target
})

_def_func("blind", function(infected) {
	infected.SetSenseFlags(-1) //all flags
})

_def_func("blind_off", function(infected) {
	infected.SetSenseFlags(0)
})

_def_func("duck", function(player, instant = true) {
	propint(player, "m_afButtonForced", propint(player, "m_afButtonForced") | IN_DUCK)
	if (instant) {
		propint(player, "m_Local.m_bDucking", 1)
		propint(player, "m_Local.m_bDucked", 1)
	}
})

_def_func("duck_off", function(player) {
	propint(player, "m_afButtonForced", propint(player, "m_afButtonForced") & ~IN_DUCK)
})

_def_func("clear_effects", function() {
	foreach(player in players(Teams.SURVIVORS)) {
		propfloat(player, "m_itTimer.m_timestamp", -100)
		propfloat(player, "m_vomitStart", -100)
		propfloat(player, "m_vomitFadeStart", -100)
		propint(player, "m_bAdrenalineActive", 0)
	}
})

_def_func("finish_anim", function() {
	foreach(player in players(Teams.SURVIVORS)) {
		propfloat(player, "m_flCycle", 0.99)
	}
	for(local ent = Entities.First(); ent != null; ent = Entities.Next(ent)) {
		local classes_to_remove = {
			grenade_launcher_projectile = true
			tank_rock = true
			vomitjar_projectile = true
			molotov_projectile = true
			pipe_bomb_projectile = true
			spitter_projectile = true
			inferno = true
			insect_swarm = true //spit
		}
		if (ent.GetClassname() in classes_to_remove) ent.Kill()
	}
})

_def_func("remove_items", function() {
	for(local ent = Entities.First(); ent != null; ent = Entities.Next(ent)) {
		if (ent.GetClassname().find("weapon_") != null) ent.Kill()
	}
})

_def_func("resurrect", function(player) {
	if(player.IsDead() || player.IsDying()) defib_dead_survivor(player)
	heal_player(player)
})

_def_func("mapname", function() {
	if (!is_scripted_mode()) throw "mapname() works only in scripted mode"
	return SessionState.MapName
})

_def_func("modename", function() {
	return cvarstr("mp_gamemode")
})

/*_def_func("basemodename", function() {
	::_1_ <- @()log(1)
	::_2_ <- @()log(2)
	::_3_ <- @()log(3)
	::_4_ <- @()log(4)
	local _vsl_info_gamemode = SpawnEntityFromTable("info_gamemode", {});
	_vsl_info_gamemode.ConnectOutput( "OnCoop", "_1_" );
	_vsl_info_gamemode.ConnectOutput( "OnCoopPostIO", "_1_" );
	_vsl_info_gamemode.ConnectOutput( "OnVersusPostIO", "_2_" );
	_vsl_info_gamemode.ConnectOutput( "OnSurvivalPostIO", "_3_") ;
	_vsl_info_gamemode.ConnectOutput( "OnScavengePostIO", "_4_" );
})*/

IncludeScript("kapkan/lib/skipintro")

_def_func("restart_game", function() {
	log("[lib] restarting...")
	EntFire("info_changelevel", "Disable")
	cvar("mp_restartgame", 1)
})

_def_func("restart_game_now", function() {
	if (!server_host()) {
		restart_game() //SendToConsole cannot be replaced by SendToServerConsole here
		return
	}
	log("[lib] restarting now...")
	EntFire("info_changelevel", "Disable") //?
	cvar("host_framerate", 1)
	cvar("mp_restartgame", 1)
	SendToConsole("wait; host_framerate 0")
})

_def_func("is_scripted_mode", function(verbose = true) {
	local answer = ("SessionState" in root)
	if (verbose) log("[lib] is_scripted_mode(): " + (answer ? "TRUE" : "FALSE"))
	return answer
})

/*
 * made with help of admin system
 */
_def_func("increase_specials_limit", function() {
	g_ModeScript.DirectorOptions.MaxSpecials <- 32
	if (is_scripted_mode()) {
		SessionOptions.MaxSpecials <- 32
		SessionOptions.cm_MaxSpecials <- 32
		SessionOptions.cm_DominatorLimit <- 32
		SessionOptions.SmokerLimit <- 32
		SessionOptions.BoomerLimit <- 32
		SessionOptions.HunterLimit <- 32
		SessionOptions.SpitterLimit <- 32
		SessionOptions.JockeyLimit <- 32
		SessionOptions.ChargerLimit <- 32
		SessionOptions.WitchLimit <- 32
		SessionOptions.cm_WitchLimit <- 32
		SessionOptions.TankLimit <- 32
		SessionOptions.cm_TankLimit <- 32
		if ("MutationOptions" in g_ModeScript) g_ModeScript.MutationOptions.MaxSpecials <- 32
		if ("MapOptions" in g_ModeScript) g_ModeScript.MapOptions.MaxSpecials <- 32
	} else {
		log("[lib] increase_specials_limit(): not a scripted mode, result is not guaranteed")
	}
})

_def_func("is_hitscan_weapon", function(weapon_name) {
	return (weapon_name in __hitscan_weapon_table);
})

_def_var("__hitscan_weapon_table", {
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
})

_def_func("playsound", function(sound_path, ent) {
	if (!(sound_path in __playsound_precached)) {
		ent.PrecacheScriptSound(sound_path);
		__playsound_precached[sound_path] <- true;
	}
	EmitSoundOn(sound_path, ent);
})

if (!("__playsound_precached" in this)) _def_var("__playsound_precached", {})

_def_func("pellets_count", function(weapon_name) {
	local pellets = {
		shotgun_chrome = 8,
		pumpshotgun = 10,
		shotgun_spas = 9,
		autoshotgun = 11
	}
	if (weapon_name in pellets) return pellets[weapon_name]
	if (is_hitscan_weapon(weapon_name)) return 1
	return null
})

_def_func("show_hud_hint_singleplayer", function(text, color, icon, binding, time) {
	log("[lib] showing tip: " + text + " [" + icon + " " + binding + " " + time + "]");
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
})

if (!("__current_hints" in this)) _def_constvar("__current_hints", {})

if (!("__point_clientcommand" in this)) _def_var_nullable("__point_clientcommand", null, "instance")

_def_func("client_command", function(player, command) {
	if (!__point_clientcommand){
		__point_clientcommand = SpawnEntityFromTable("point_clientcommand", {}).weakref()
	}
	DoEntFire("!self", "Command", command, 0, player, __point_clientcommand)
})

if (!("__point_broadcastclientcommand" in this)) _def_var_nullable("__point_broadcastclientcommand", null, "instance")

_def_func("broadcast_client_command", function(command) {
	if (!__point_broadcastclientcommand){
		__point_broadcastclientcommand = SpawnEntityFromTable("point_broadcastclientcommand", {}).weakref()
	}
	DoEntFire("!self", "Command", command, 0, null, __point_broadcastclientcommand)
})