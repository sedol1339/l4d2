//---------- DOCUMENTATION ----------

/**
FUNCTIONS FOR WORKING WITH ENTITIES
! requires lib/module_base !
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
	Fast function that returns a human player in singleplayer.
------------------------------------
bot()
	For testing: returns first found bot player.
------------------------------------
server_host()
	Returns listenserver host player or null. Warning! May return null while server host is still connecting.
------------------------------------
players()
	Returns array of player entities, optionally pass team bitmask (Teams.UNASSIGNED, Teams.SPECTATORS, Teams.SURVIVORS, Teams.INFECTED).
	Example: players(Teams.SURVIVORS | Teams.SPECTATORS)
------------------------------------
for_each_player(func)
	Сalls function for every player, passes player as param. Legacy, better use this syntax: foreach(player in players()) {...}
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
spawn_infected(type, position, angle = null, precise_origin = false)
	Spawn special infected and returns it, returns null if can't spawn. Also validates script scope of spawned entity. This function uses ZSpawn() internally, that tries to spawn zombie on ground. So position can be slightly corrected. If you want precise position, use optional parameter precise_origin = true. Function spawn_infected sets entity angle correctly, use enable_fast_rotation() to to make zombie's body instantly turn in the right direction.
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
kill_player(player, attacker = null, set_revive_count = true)
	Kills player by increasing revive count to 100 and calling TakeDamage(). For survivor works only if god=0. Optionally pass attacker as additional param to specify in TakeDamage() function. Set last optional arg to false if you don't want to increase revive count before dealing damage.
------------------------------------
client_command(player, cmd)
	Send command from player using point_clientcommand. Command should have "server_can_execute" flag, for example "slot1".
------------------------------------
switch_to_infected(player, class)
	Switches player to infected team and spaws as zombie class. Under the hood it sets m_iTeamNum=3, m_lifeState=2, CTerrorPlayer.m_iVersusTeam=2, m_iPlayerState=6 and performs spawn_infected() function. May have side effects. Reverse transition (from infected to survivors) seems impossible.
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
 */

//---------- CODE ----------

this = ::root

log("[lib] including module_entities")

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

for_each_player <- function (func) {
	local tmp_player = null;
	while (tmp_player = Entities.FindByClassname(tmp_player, "player"))
		if (tmp_player) func(tmp_player);
}

players <- function (teams = Teams.ANY) {
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

set_ability_cooldown <- function(player, cooldown) {
	local ability = propent(player, "m_customAbility")
	propfloat(ability, "m_nextActivationTimer.m_timestamp", Time() + cooldown)
	propfloat(ability, "m_nextActivationTimer.m_duration", cooldown)
}

//kill bots with death camera
remove_dying_infected <- function() {
	for_each_player(function(player){
		if (!player.IsSurvivor() && player.IsDying() && IsPlayerABot(player))
			player.Kill();
	});
}

/* returns spawned player or null */
spawn_infected <- function(param_type, param_pos, param_ang = null, precise_origin = false) {
	local names = ["ZOMBIE_NORMAL", "ZOMBIE_SMOKER", "ZOMBIE_BOOMER", "ZOMBIE_HUNTER", "ZOMBIE_SPITTER", "ZOMBIE_JOCKEY", "ZOMBIE_CHARGER", "ZOMBIE_WITCH", "ZOMBIE_TANK", "Z_SURVIVOR", "ZSPAWN_MOB", "ZSPAWN_WITCHBRIDE", "ZSPAWN_MUDMEN"]
	if (typeof param_type != "integer" || param_type < 1 || param_type > 8) return null; //survivor spawning is not working
	local player = null;
	local tmp_last_player = null;
	while(player = Entities.FindByClassname(player, "player"))
		tmp_last_player = player;
	ZSpawn({ type = param_type, pos = param_pos });
	player = Entities.FindByClassname(tmp_last_player, "player");
	if (!player) {
		logf("spawn_infected(): ERROR! cannot find spawned %s, returning null", names[param_type])
		return null
	}
	if(player.GetZombieType() == 9) {
		logf("spawn_infected(): ERROR! zombieType of %s is 9, returning null", names[param_type])
		return null; //if an extra infected bot appears, it becomes a survivor and is then removed
	}
	log("spawn_infected(): spawning " + names[param_type] + ": " + player_to_str(player));
	scope(player).spawned_manually <- true; //see make_playground() in lib/module_gamelogic for usage
	teleport_entity(player, precise_origin ? param_pos : null, param_ang)
	return player;
}

create_target_bot <- function(pos) {
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
	propint(target_bot, "m_iMaxHealth", 50000)
	propint(target_bot, "m_takedamage", 0)
	target_bot.SetHealth(50000)
	return target_bot
}

remove_target_bot <- function(target_bot) {
	propint(target_bot, "m_iTeamNum", 3)
	target_bot.Kill()
}

teleport_entity <- function(ent, param_origin, param_angles) {
	assert(ent);
	if (param_origin) ent.SetOrigin(param_origin)
	if (param_angles) ent.SetForwardVector(param_angles.Forward()) //this works for players
}

defib_dead_survivor <- function(player) {
	player.ReviveByDefib()
	propfloat(player, "m_flCycle", 0.99)
	propint(player, "m_useActionOwner", 0)
	propint(player, "m_useActionTarget", 0)
	propint(player, "m_iCurrentUseAction", 0)
}

set_max_health <- function(player, max_health) {
	propint(player, "m_iMaxHealth", max_health)
}

heal_player <- function(player) {
	player.GiveItem("health")
	player.SetHealthBuffer(0)
}

velocity_impulse <- function(ent, impulse_vec) {
	propvec(ent, "m_vecBaseVelocity", propvec(ent, "m_vecBaseVelocity") + impulse_vec)
}

teleport_survivors_to_start_points <- function() {
	EntFire("info_director", "ForceSurvivorPositions")
	EntFire("info_director", "ReleaseSurvivorPositions")
}

enable_fast_rotation <- function(enabled = true) {
	Convars.SetValue("mp_feetmaxyawrate", enabled ? 99999 : 100.0)
	Convars.SetValue("mp_feetyawrate", enabled ? 99999 : 180)
	Convars.SetValue("mp_feetyawrate_max", enabled ? 99999 : 360)
	Convars.SetValue("mp_facefronttime", enabled ? 0 : 2)
}

get_entity_flag <- function(ent, flag) {
	return (propint(ent,"m_fFlags") & flag) ? true : false
}

set_entity_flag <- function(ent, flag, value) {
	local flags = propint(ent,"m_fFlags")
	flags = value ? (flags | flag) : (flags & ~flag)
	propint(ent, "m_fFlags", flags)
}

get_player_button <- function(player, button) {
	return (player.GetButtonMask() & button) ? true : false
}

force_player_button <- function(player, button, press = true) {
	local buttons = propint(player, "m_afButtonForced")
	if (press)
		propint(player, "m_afButtonForced", buttons | button)
	else
		propint(player, "m_afButtonForced", buttons &~ button)
}

kill_player <- function(player, attacker = null, set_revive_count = true) {
	if (set_revive_count) player.SetReviveCount(100)
	player.TakeDamage(10e6, 0, attacker)
	log("killed " + player)
}

client_command <- function(player, command) {
	local ent = SpawnEntityFromTable("point_clientcommand", {})
	DoEntFire("!self", "Command", command, 0, player, ent)
	DoEntFire("!self", "Kill", "", 0, null, ent)
}

switch_to_infected <- function(player, zombie_class) {
	propint(player, "m_iTeamNum", 3)
	propint(player, "m_lifeState", 2)
	propint(player, "CTerrorPlayer.m_iVersusTeam", 2)
	propint(player, "m_iPlayerState", 6)
	spawn_infected(zombie_class, player.GetOrigin())
}

targetname_to_entity <- function(targetname) {
	local ent = Entities.FindByName(null, targetname)
	if (!ent) {
		log("WARNING! entity with targetname " + targetname + " does not exist")
		return null
	}
	if (Entities.FindByName(ent, targetname)) {
		log("WARNING! multiple entities with targetname " + targetname + " exist")
	}
	return ent
}

find_entities <- function(classname) {
	local ent = null
	local arr = []
	while (ent = Entities.FindByClassname(ent, classname))
		arr.push(ent)
	return arr
}

replace_primary_weapon <- function(player, weapon, laser_sight = false, remove_secondary = false) {
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
}

create_particles <- function(effect_name, origin_or_parent, duration = -1, attachment = null) {
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
			log("WARNING! Create_particles(): attachment without parent, ignored")
		else
			DoEntFire("!self", "SetParentAttachment", attachment, 0.01, null, target)
	}
	return effect
}

attach <- function(entity, attachment) {
	local target = SpawnEntityFromTable("info_target", {origin = entity.GetOrigin()})
	DoEntFire("!self", "SetParent", "!activator", 0, entity, target)
	DoEntFire("!self", "SetParentAttachment", attachment, 0, entity, target)
	return target
}