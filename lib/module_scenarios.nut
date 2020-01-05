//---------- DOCUMENTATION ----------

/**
FUNCTIONS FOR CREATING CUSTOM SCRIPTED SCENARIOS
! requires lib/module_base !
! requires lib/module_convars !
! requires lib/module_entities !
! requires lib/module_tasks !
------------------------------------
disallow_dying_infected_bots(enabled = true)
	Will automatically remove infected bots that are in dying state (just died, with death camera).
------------------------------------
make_playground(params = {})
	Turns the game into sandbox for scripted scenarios. Performs the following operations:
	- Removes all infected bots
	- Runs stop_director(): sets director_no_specials=1, director_no_mobs=1, director_no_bosses=1, z_common_limit=0, z_background_limit=0
	- Sets sb_all_bot_game=1, dnb_update_frequency=0, allow_all_bot_survivor_team=1, vs_max_team_switches=999, sv_client_min_interp_ratio=0
	Gets optional params table that may contain any of these params:
	True by default:
	- "remove_survivor_bots" - removes survivors bots and sets director_no_survivor_bots=1
	- "disallow_tanks" - any spawned tanks, except ones spawned with spawn_infected(), will be immediately removed (bots) or killed (human players)
	- "no_death_check" - sets director_no_death_check=1
	- "skip_intro" - also skips intro
	- "disallow_dying_infected_bots" - runs function disallow_dying_infected_bots(), this will automatically remove infected bots with death cam
	- "clear_effects" - removes adrenaline effect, vomit from all survivors, removes all flying projectiles
	- "finish_anim" - finish animation for all survivors (for example, getting up from charge)
	False by default:
	- "increase_specials_limit" - runs increase_specials_limit()
	- "remove_items" - remove all weapon, items (also from player inventories) and wepon/item spawns
	- "resurrect" - revive survivors if dead or incapacirated and give them full health
	- "teleport_to_start" - teleport survivors to start positions
	- "remove_info_zombie_spawn" - remove remove info_zombie_spawn entities, it may break map logic for custom campaigns!
	- "god_mode" - sets cvar god=1
	- "infinite_ammo" - sets cvar sv_infinite_ammo=1
	- "coop" - sets cvar mp_gamemode=coop, affects hunter shoving and other stats and game mechanics
	- "versus" - sets cvar mp_gamemode=versus, affects hunter shoving and other stats and game mechanics; warning: in versus mode if user toggles sv_cheats, it will reset sb_all_bot_game variable and probably will shutdown the server
	- "no_discard" - sets z_discard_range=10e6, so infected player bots will not be killed when far away from survivors, human players will not be allowed to reenter ghost mode when far away from survivors
	Undefined by default:
	- "host_lerp" - if stated, sets cl_interp for listenserver host and cl_interp_ratio=0
	Note that some of these actions (all except convar changes) will not have effect in next round.
------------------------------------
spawn_and_launch_infected(type, pos, ang, speed, on_launch = null, on_appearance = null)
	Spawns special infected of specified type in given position and turned into given angle, then launches it
 */

//---------- CODE ----------

make_playground <- function(input_params_table = {}) {
	local params = {
		remove_survivor_bots = true
		remove_items = false
		//c7m1_fix = true //tank will not spawn on map c7m1_docks
		disallow_tanks = true
		remove_info_zombie_spawn = false
		no_death_check = true
		skip_intro = true
		disallow_dying_infected_bots = true
		god_mode = false
		infinite_ammo = false
		increase_specials_limit = true
		no_discard = false
		versus = false
		coop = false
		clear_effects = true
		finish_anim = true
		resurrect = false
		teleport_to_start = false
		host_lerp = null
	}
	foreach(key, value in input_params_table) params[key] <- value
	if (params.versus && params.coop) throw "versus=true and coop=true, check input params!"
	cvar("sb_all_bot_game", 1)
	cvar("allow_all_bot_survivor_team", 1)
	cvar("vs_max_team_switches", 999)
	cvar("nb_update_frequency", 0)
	cvar("sv_client_min_interp_ratio", 0)
	if (params.no_death_check) cvar("director_no_death_check", 1)
	if (params.remove_survivor_bots) cvar("director_no_survivor_bots", 1)
	if (params.no_discard) cvar("z_discard_range", 10e6)
	if (params.god_mode) cvar("god", 1)
	if (params.infinite_ammo) cvar("sv_infinite_ammo", 1)
	if (params.versus) cvar("mp_gamemode", "versus")
	if (params.coop) cvar("mp_gamemode", "coop")
	if (params.skip_intro) skip_intro()
	if (params.disallow_dying_infected_bots) disallow_dying_infected_bots()
	if (params.host_lerp != null) {
		cvar("cl_interp", params.host_lerp)
		cvar("cl_interp_ratio", 0)
	}
	stop_director()
	foreach(player in players()) {
		if (IsPlayerABot(player)) {
			if (player.IsSurvivor()) {
				if (params.remove_survivor_bots) player.Kill()
			} else {
				player.Kill() //hope there can't be spectator bots
			}
		}
	}
	for(local ent = Entities.First(); ent != null; ent = Entities.Next(ent)) {
		local classname = ent.GetClassname()
		if (
			classname == "infected"
			|| (params.remove_items && classname.find("weapon_") != null)
			|| (params.remove_info_zombie_spawn && classname == "info_zombie_spawn")
		) {
			ent.Kill()
		}
		if (params.clear_effects) {
			if (
				classname == "grenade_launcher_projectile"
				|| classname == "tank_rock"
				|| classname == "vomitjar_projectile"
				|| classname == "molotov_projectile"
				|| classname == "pipe_bomb_projectile"
				|| classname == "spitter_projectile"
				|| classname == "inferno"
				|| classname == "insect_swarm" //spit
			) {
				ent.Kill()
			}
		}
	}
	//if (params.c7m1_fix && mapname() == "c7m1_docks") {
	//	EntFire("tankdooroutnavblocker", "Kill")
	//	EntFire("tankdoorout_button", "Kill")	
	//	EntFire("tankdoorout", "Kill")
	//	EntFire("info_zombie_spawn", "Kill")
	//}
	if (params.disallow_tanks) {
		register_ticker("__disallow_tanks", function() {
			foreach(player in players(Teams.INFECTED)) {
				if (player.GetZombieType() != ZOMBIE_TANK) return
				if ("spawned_manually" in scope(player)) return
				if (IsPlayerABot(player)) {
					player.Kill()
				} else {
					kill_player(player, null, false)
				}
			}
		})
	} else {
		remove_ticker("__disallow_tanks")
	}
	local survivors = players(Teams.SURVIVORS)
	if (params.clear_effects) {
		foreach(player in survivors) {
			propfloat(player, "m_itTimer.m_timestamp", -100)
			propfloat(player, "m_vomitStart", -100)
			propfloat(player, "m_vomitFadeStart", -100)
			propint(player, "m_bAdrenalineActive", 0)
		}
	}
	if (params.finish_anim) {
		foreach(player in survivors) {
			propfloat(player, "m_flCycle", 0.99)
		}
	}
	if (params.resurrect) {
		foreach(player in survivors) {
			if(player.IsDead() || player.IsDying())
				defib_dead_survivor(player)
			heal_player(player)
		}
	}
	if (params.teleport_to_start)
		teleport_survivors_to_start_points()
	if (params.increase_specials_limit) increase_specials_limit()
}

//auto removing infected bots that are in dying state
disallow_dying_infected_bots <- function(enabled = true) {
	if (enabled) {
		register_callback("__no_death_cams", "player_death", function(__params) {
			local player = GetPlayerFromUserID(__params.userid);
			if (!player.IsSurvivor() && IsPlayerABot(player)) player.Kill();
		});
	} else {
		remove_callback("player_death", "__no_death_cams");
	}
}

//unfinished, see test31.nut

//if (!("__deathcam_survivors" in this)) __deathcam_survivors <- true
//if (!("__deathcam_infected" in this)) __deathcam_infected <- true

/*skip_deathcam <- function(player) {
	run_this_tick( function() {
		propint(player, "m_lifeState", 2)
		propint(player, "m_iObserverMode", 6)
		propint(player, "m_iPlayerState", 6)
		propint(player, "movetype", 10)
	})
}*/

/*disable_death_cam <- function(teams) {
	local for_surv = teams & Teams.SURVIVORS
	local for_inf = teams & Teams.INFECTED
	if (!for_surv && !for_inf) throw "use disable_death_cam for Teams.SURVIVORS and/or Teams.INFECTED!"
	if (for_surv) __deathcam_survivors <- false
	if (for_inf) __deathcam_infected <- false
	register_callback("__skip_deathcam", "player_death", function(__params) {
		local player = __params.player
		if (get_team(player) & Teams.INFECTED) {
			if (!__deathcam_infected) skip_deathcam(player)
		} else if (get_team(player) & Teams.SURVIVORS) {
			if (!__deathcam_survivors) skip_deathcam(player)
		}
	})
}*/

/*enable_death_cam <- function(teams) {
	local for_surv = teams & Teams.SURVIVORS
	local for_inf = teams & Teams.INFECTED
	if (!for_surv && !for_inf) throw "use enable_death_cam for Teams.SURVIVORS and/or Teams.INFECTED!"
	if (for_surv) __deathcam_survivors <- true
	if (for_inf) __deathcam_infected <- true
	if (__deathcam_survivors && __deathcam_infected) {
		remove_callback("__skip_deathcam", "player_death")
	}
}*/

