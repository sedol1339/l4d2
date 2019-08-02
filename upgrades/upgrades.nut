//todo выключать, если обнаружены соответствующие SM плагины

////////////////////////////////////
//		Thirdperson Allowed
////////////////////////////////////

// the problems here are:
// 1. m_TimeForceExternalView is not working for infected
// 2. point_viewcontrol is laggy because is not interpolated and probably not lagcompensated
// so ForceExternalView is used for survivors and point_viewcontrol is used for infected

// due to point_viewcontrol bug (player does not receive damage) thirdperson for infected is disabled

local thirdperson_cmds = ["thirdperson", "third", "3rd"]

local thirdperson_for_infected = false

external_view <- function(player) {
	propfloat(player, "m_TimeForceExternalView", INF)
}

external_view_off <- function(player) {
	propfloat(player, "m_TimeForceExternalView", -1)
}

enable_pvc <- function(player) {
	if (!thirdperson_for_infected) return
	if (player.IsDead() || player.IsDying()) return
	if ("pvc" in scope(player)) return
	scope(player).pvc <- SpawnEntityFromTable("point_viewcontrol", {
		spawnflags = 8
	});
	DoEntFire("!self", "Enable", "", 0, player, scope(player).pvc);
	register_ticker("pvc_target" + unique_str_id(player), function() {
		local player_scope = player.GetScriptScope()
		if (!("pvc" in player_scope)) return false
		player_scope.pvc.SetOrigin(player.EyePosition() - player.EyeAngles().Forward().Scale(100))
		player_scope.pvc.SetAngles(player.EyeAngles())
	})
}

disable_pvc <- function(player) {
	if (!("pvc" in scope(player))) return
	DoEntFire("!self", "Disable", "", 0, player, scope(player).pvc);
	DoEntFire("!self", "Kill", "", 0.1, null, scope(player).pvc);
	delete scope(player).pvc
}

_3rd_enabled <- function(player) {
	local player_scope = scope(player)
	if (!("is_3rd_enabled" in player_scope)) return false
	return player_scope.is_3rd_enabled
}

_3rd_forced <- function(player) {
	local player_scope = scope(player)
	if (!("is_3rd_forced" in player_scope)) return false
	return player_scope.is_3rd_forced
} 

_3rd_enable <- function(player, enable) {
	scope(player).is_3rd_enabled <- enable
	_3rd_apply(player)
}

_3rd_force <- function(player, force) {
	scope(player).is_3rd_forced <- force
	_3rd_apply(player)
}

_3rd_apply <- function(player) {
	local player_scope = scope(player)
	if (!("is_3rd_forced" in player_scope)) 
		player_scope.is_3rd_forced <- false
	if (!("is_3rd_enabled" in player_scope)) 
		player_scope.is_3rd_enabled <- false
	local _3rd_enabled_or_forced = player_scope.is_3rd_enabled || player_scope.is_3rd_forced
	if (player.IsSurvivor()) {
		_3rd_enabled_or_forced ? external_view(player) : external_view_off(player)
	} else {
		_3rd_enabled_or_forced ? enable_pvc(player) : disable_pvc(player)
	}
}

//don't remove this in ThirdpersonAllowed on_disable because other ungrades use forced thirdperson view
register_callback("player_team", "thirdperson_on_change_team", function(params) {
	if (invalid(params.player)) return
	external_view_off(params.player)
	disable_pvc(params.player)
	scope(params.player).is_3rd_forced <- false
	scope(params.player).is_3rd_enabled <- false
})

new_upgrade({
	name = "ThirdpersonAllowed",
	display_name = "Thirdperson Allowed",
	on_enable = function() {
		on_key_action("thirdperson", Team.SURVIVORS | Team.INFECTED, IN_SPEED, 0.1, @(p)_3rd_enable(p, true), @(p)_3rd_enable(p, false))
		register_chat_command(thirdperson_cmds, function(player, command, args_text, args) {
			if (propint(player, "m_iTeamNum") < 2) return
			_3rd_enable(player, !_3rd_enabled(player))
		}, 0, 0)
	},
	on_disable = function() {
		on_key_action_remove("thirdperson")
		remove_chat_command(thirdperson_cmds)
		foreach(player in players())
			_3rd_enable(player, false)
	}
})

////////////////////////////////////
//		Auto Bunnyhop
////////////////////////////////////

local enable_jump = @(player) propint(player, "m_afButtonDisabled", propint(player, "m_afButtonDisabled") &~ IN_JUMP)

local disable_jump = @(player) propint(player, "m_afButtonDisabled", propint(player, "m_afButtonDisabled") | IN_JUMP)

local bhop_cmds = ["bunnyhop", "bhop"]

new_upgrade({
	name = "AutoBunnyhop",
	display_name = "Auto Bunnyhop",
	on_enable = function() {
		run_this_tick( @()say_chat("If bhop is not working for you, use !bhop command.") )
		register_chat_command(bhop_cmds, function(player, command, args_text, args) {
			scope(player).autobhop = !scope(player).autobhop
			say_chat("Bunnyhop is %s for %s", scope(player).autobhop ? "enabled" : "disabled", player.GetPlayerName())
		}, 0, 0)
		register_ticker("bunnyhop", function() {
			for_each_player( function(player) {
				if (IsPlayerABot(player)) return
				if (!("autobhop" in scope(player)))
					scope(player).autobhop <- true
				else if (!scope(player).autobhop)
					return
				if (propint(player, "movetype") != MOVETYPE_WALK) return
				if (get_entity_flag(player, FL_ONGROUND))
					enable_jump(player)
				else
					disable_jump(player)
			})
		})
	}
	on_disable = function() {
		remove_chat_command(bhop_cmds)
		remove_ticker("bunnyhop")
		for_each_player(enable_jump)
	}
})

////////////////////////////////////
//		Charger Steering
////////////////////////////////////

local set_NextSecondaryAttack = function(player, value) {
	local weapon = propent(params.player, "m_hActiveWeapon")
	if (weapon)
		propfloat(weapon, "m_flNextSecondaryAttack", value)
}

new_upgrade({
	name = "ChargerSteering",
	display_name = "Charger Steering",
	on_enable = function() {
		register_callback("charger_charge_start", "steering", function(params) {
			set_entity_flag(params.player, FL_FROZEN, false)
			set_NextSecondaryAttack(params.player, INF)
		})
		register_callback("charger_charge_end", "steering", function(params) {
			set_NextSecondaryAttack(params.player, clock.sec() + 0.5)
		})
		cvar("z_charger_impact_epsilon", 0)
	}
	on_disable = function() {
		remove_callback("charger_charge_start", "steering")
		remove_callback("charger_charge_end", "steering")
		cvar("z_charger_impact_epsilon", 8)
	}
})

////////////////////////////////////
//		Jockey Jumper
////////////////////////////////////

jockey_jump_force <- 330 //default jump height is 247, 330 in Jockey jump SM plugin

jockey_jump_delay <- 2.5

new_upgrade({
	name = "JockeyJumper",
	display_name = "Jockey Jumper",
	on_enable = function() {
		jockey_riders <- {}
		for_each_player( function(player) {
			if (!IsPlayerABot(player) && propent(player, "m_jockeyVictim"))
				jockey_riders[player] <- true
				scope(player).last_jump <- -jockey_jump_delay
		})
		register_callback("jockey_ride", "jockey_riders", function(params) {
			if (!IsPlayerABot(params.player))
				jockey_riders[params.player] <- true
				scope(params.player).last_jump <- -jockey_jump_delay
		})
		register_callback("jockey_ride_end", "jockey_riders", function(params) {
			del(params.player, jockey_riders)
		})
		register_ticker("jockey_jump", function() {
			foreach(jockey, _ in jockey_riders) {
				if (get_player_button(jockey, IN_JUMP)) {
					if (clock.sec() < scope(jockey).last_jump + jockey_jump_delay) continue
					local victim = propent(jockey, "m_jockeyVictim")
					if (invalid(victim)) continue
					if (get_entity_flag(victim, FL_ONGROUND)) {
						propent(victim, "m_hGroundEntity", null)
						victim.ApplyAbsVelocityImpulse(Vector(0, 0, jockey_jump_force))
						playsound("player/jockey/voice/attack/jockey_loudattack01_wet.wav", jockey)
						scope(jockey).last_jump = clock.sec()
					}
				}
			}
		})
	}
	on_disable = function() {
		remove_callback("jockey_ride", "jockey_riders")
		remove_callback("jockey_ride_end", "jockey_riders")
		remove_ticker("jockey_jump")
	}
})

////////////////////////////////////
//		Hunter Jumper
////////////////////////////////////

local hunter_upgrade_lunge_multiplier = 4.0 / 3

new_upgrade({
	name = "HunterJumper",
	display_name = "Hunter Jumper",
	on_enable = function() {
		cvar("z_lunge_power", 600 * hunter_upgrade_lunge_multiplier)
		cvar("z_lunge_up", 200 * hunter_upgrade_lunge_multiplier)
		cvar("z_player_lunge_up", 150 * hunter_upgrade_lunge_multiplier)
	}
	on_disable = function() {
		cvar("z_lunge_power", 600)
		cvar("z_lunge_up", 200)
		cvar("z_player_lunge_up", 150)
	}
})

////////////////////////////////////
//		Hunter Brutal
////////////////////////////////////

local incap_damage_multiplier = 3

//this works for incapped survivors

local fatal_dist_incap = 1500

local fatal_damage_incap = 100

//this works for standing survivors

local fatal_dist_standing = 1700

local fatal_damage_standing = 200

// explicitly kill player on fatal dist

local always_kill_on_fatal_dist = false 

last_brutal_pounces <- []

new_upgrade({
	name = "HunterBrutal",
	display_name = "Hunter Brutal",
	on_enable = function() {
		register_callback("lunge_pounce", "brutal", function(params) {
			local hunter = params.player
			local victim = params.player_victim
			if (victim.IsDead() || victim.IsDying()) return
			local endpos = hunter.GetOrigin() //not victim's origin (this is according to SM Brutal hunter mod)
			local startpos = propvec(hunter, "m_pounceStartPosition")
			local dist = (endpos - startpos).Length()
			local total_damage = 0
			if (victim.IsIncapacitated()) {
				local damage = dist / fatal_dist_incap * fatal_damage_incap
				if (dist >= fatal_dist_incap && always_kill_on_fatal_dist)
					damage = 10e6
				victim.TakeDamage(incap_damage_multiplier * damage, 0, hunter)
				total_damage += incap_damage_multiplier * damage
			} else {
				local damage = dist / fatal_dist_standing * fatal_damage_standing
				if (dist >= fatal_dist_standing && always_kill_on_fatal_dist)
					damage = 10e6
				local alive_health = victim.GetHealth() + victim.GetHealthBuffer()
				if (alive_health < damage) {
					victim.TakeDamage(alive_health, 0, hunter)
					total_damage += alive_health
					run_this_tick( function() {
						local incap_damage = (damage - alive_health) * incap_damage_multiplier
						if (!victim.IsDying())
							victim.TakeDamage(incap_damage, 0, hunter)
						total_damage += incap_damage
					}.bindenv(this) )
				} else {
					victim.TakeDamage(damage, 0, hunter)
					total_damage += damage
				}
			}
			//for announcing, look HighPounce
			run_next_tick( function() {
				last_brutal_pounces.push({
					hunter = hunter,
					damage = total_damage,
					dist = dist,
					explicit_kill = (dist >= fatal_dist_standing && always_kill_on_fatal_dist),
					kill = victim.IsDead() || victim.IsDying()
				})
			}.bindenv(this) )
		})
	}
	on_disable = function() {
		remove_callback("lunge_pounce", "brutal")
	}
})

////////////////////////////////////
//		Boomer Walker
////////////////////////////////////

new_upgrade({
	name = "BoomerWalker",
	display_name = "Boomer Walker",
	on_enable = function() {
		cvar("z_vomit_fatigue", 0)
	}
	on_disable = function() {
		cvar("z_vomit_fatigue", 3000)
	}
})

////////////////////////////////////
//		Smoker Walker
////////////////////////////////////

// hack with MOVETYPE_ISOMETRIC from Perkmod SM plugin
// fixed faster moving when holding two moving buttons

smoker_walker_phystimescale <- 0.21 //same as in Perkmod SM plugin

local start_smoker_walk = function(smoker) {
	propint(smoker, "movetype", MOVETYPE_ISOMETRIC)
	register_ticker("smoker_walker" + unique_str_id(smoker), function() {
		local phystimescale = smoker_walker_phystimescale
		local speed = propvec(smoker, "m_vecAbsVelocity").Length()
		if (speed > 450)
			phystimescale = phystimescale * 450 / speed
		propfloat(smoker, "m_flLaggedMovementValue", phystimescale)
	})
}

local stop_smoker_walk = function(smoker) {
	if (propint(smoker, "movetype") == MOVETYPE_ISOMETRIC)
		propint(smoker, "movetype", MOVETYPE_WALK)
	propfloat(smoker, "m_flLaggedMovementValue", 1)
	remove_ticker("smoker_walker" + unique_str_id(smoker))
}

new_upgrade({
	name = "SmokerWalker",
	display_name = "Smoker Walker",
	on_enable = function() {
		register_callback("tongue_grab", "walk", function(params) {
			start_smoker_walk(params.player)
		})
		register_callback("tongue_release", "stop_walk", function(params) {
			stop_smoker_walk(params.player)
		})
		for_each_player( function(player) {
			if (propent(player, "m_tongueVictim"))
				start_smoker_walk(player)
		})
	}
	on_disable = function() {
		remove_callback("tongue_grab", "walk")
		remove_callback("tongue_release", "stop_walk")
		for_each_player( function(player) {
			if (propent(player, "m_tongueVictim"))
				stop_smoker_walk(player)
		})
	}
})

////////////////////////////////////
//		Boomer Bouncer
////////////////////////////////////

// this is one of the most complex scripts, which uses undocumented engine features,
// creates hidden entities and makes weird operations, so there is a possibility of bugs

// this doesn't work in god mode, because player_hurt event is not fired

local backward_force = 200

local upward_force = 250

local cooldown = 0

local allow_continuous_punches = false //allow to punch while past punch is not finished

local allow_punch_infected = true

local allow_throw_off_the_ledge = true

local backward_force_throw_off_the_ledge = 80

local upward_force_throw_off_the_ledge = 50

local rock_launcher = null

local create_rock_launcher = function() {
	rock_launcher = SpawnEntityFromTable("env_rock_launcher", {
		RockDamageOverride = 1,
		origin = Vector(0, 0, 30000) //outside the map
	})
	scope(rock_launcher).fake <- true
}

create_rock_launcher()

local stop_screen_shake = function(player) {
	local screen_shake_disabler = SpawnEntityFromTable("env_shake", {
		radius = 50,
		origin = player.GetOrigin()
	})
	DoEntFire("!self", "StopShake", "", 0, null, screen_shake_disabler)
	DoEntFire("!self", "Kill", "", 0, null, screen_shake_disabler)
}

local get_flight_sequence = function(player) {
	local model_to_sequence = {
		"models/survivors/survivor_gambler.mdl": 643,
		"models/survivors/survivor_producer.mdl": 651,
		"models/survivors/survivor_coach.mdl": 637,
		"models/survivors/survivor_mechanic.mdl": 648,
		"models/survivors/survivor_namvet.mdl": 551,
		"models/survivors/survivor_teenangst.mdl": 554,
		"models/survivors/survivor_manager.mdl": 551,
		"models/survivors/survivor_biker.mdl": 554,
	}
	local model = propstr(player, "m_ModelName")
	if (model in model_to_sequence)
		return model_to_sequence[model]
	return null
}

local get_rising_sequence = function(player) {
	local model_to_sequence = {
		"models/survivors/survivor_gambler.mdl": 630,
		"models/survivors/survivor_producer.mdl": 638,
		"models/survivors/survivor_coach.mdl": 630,
		"models/survivors/survivor_mechanic.mdl": 635,
		"models/survivors/survivor_namvet.mdl": 538,
		"models/survivors/survivor_teenangst.mdl": 547,
		"models/survivors/survivor_manager.mdl": 538,
		"models/survivors/survivor_biker.mdl": 541,
	}
	local model = propstr(player, "m_ModelName")
	if (model in model_to_sequence)
		return model_to_sequence[model]
	return null
}

launch_rock <- function(player) {
	log("launched")
	local rock = null; local last_rock = null;
	while (rock = Entities.FindByClassname(rock, "tank_rock"))
		last_rock = rock
	DoEntFire("!self", "LaunchRock", "", 0, null, rock_launcher)
	run_this_tick( function(){
		rock = Entities.FindByClassname(last_rock, "tank_rock")
		scope(rock).fake <- true
		local delta = player.GetOrigin() - rock.GetOrigin()
		//position rock's collision box inside the player (it's going to be reset reset next tick)
		propvec(rock, "m_Collision.m_vecMins",  delta + Vector(-1, -1, 1))
		propvec(rock, "m_Collision.m_vecMaxs", delta + Vector(1, 1, 2))
		//applying some velocity (when zero, collision will not happen); collision will reset velocity
		player.ApplyAbsVelocityImpulse(Vector(100, 100, 0))
		//set ground entity (if null, collision will not happen)
		if (!propent(player, "m_hGroundEntity")) propent(player, "m_hGroundEntity", worldspawn)
		run_next_tick( function() {
			if (!invalid(rock)) { //should never happen.. I think?
				log("Rock collision FAILED")
				rock.Kill()
			}
			stop_screen_shake(player)
			//StopSoundOn("HulkZombie.ThrownProjectileHit", player) //not working, only with EmitSoundOn
			scope(player).in_punch_flight = false
		})
	})
}

punch <- function(boomer, victim, punch_from = null, stun = true, backward_override = null, upward_override = null, vel_override = null) {
	//boomer may be null, then specify punch_from
	
	local boomer_scope 
	if (boomer)
		boomer_scope = scope(boomer)
	local victim_scope = scope(victim)
	
	if (!punch_from) punch_from = boomer.GetOrigin()
	
	if (propent(victim, "m_pummelAttacker"))
		victim = propent(victim, "m_pummelAttacker")
	else if (propent(victim, "m_carryAttacker"))
		victim = propent(victim, "m_carryAttacker")
	else if (propent(victim, "m_pounceAttacker"))
		victim = propent(victim, "m_pounceAttacker")
	else if (propent(victim, "m_jockeyVictim"))
		victim = propent(victim, "m_jockeyVictim")
	
	
	if (!victim.IsSurvivor() && !allow_punch_infected) return
	if (victim.IsDead() || victim.IsDying()) return
	if (victim.IsIncapacitated() && !victim.IsHangingFromLedge() && !propent(victim, "m_tongueOwner")) return
	
	if (boomer && !allow_continuous_punches) {
		if (("in_punch_flight" in victim_scope) && victim_scope.in_punch_flight) {
			log("punch denied: in_punch_flight")
			return
		}
		if (propint(victim, "m_nSequence") == get_rising_sequence(victim)) {
			log("punch denied: m_nSequence")
			return
		}
	}
	
	local throw_off_the_ledge = false
	if (victim.IsHangingFromLedge()) {
		if (!allow_throw_off_the_ledge) return
		propint(victim, "m_isHangingFromLedge", 0)
		throw_off_the_ledge = true
	}
	
	if (propent(victim, "m_pounceVictim")) {
		victim.Stagger(punch_from)
		return
	}
	
	if (propent(victim, "m_pummelVictim")) {
		victim.Stagger(punch_from)
		set_ability_cooldown(victim, cvarf("z_charge_interval"))
		return
	}
	
	local break_tongue = function(smoker) {
		propent(propent(smoker, "m_tongueVictim"), "m_tongueOwner", null)
		propent(smoker, "m_tongueVictim", null)
	}
	
	if (propent(victim, "m_tongueVictim")) {
		break_tongue(victim)
	} else if (propent(victim, "m_tongueOwner")) {
		if (!allow_punch_infected) return
		break_tongue(propent(victim, "m_tongueOwner"))
	}
	
	if (boomer) {
		if ("last_punch" in boomer_scope && boomer_scope.last_punch + cooldown > clock.sec()) return
		boomer_scope.last_punch <- clock.sec()
	}
	
	local yaw = vector_to_angle(punch_from - victim.GetOrigin()).Yaw()
	local backward = throw_off_the_ledge ? -backward_force_throw_off_the_ledge : -backward_force
	local upward = throw_off_the_ledge ? upward_force_throw_off_the_ledge : upward_force
	if (backward_override != null) backward = -backward_override
	if (upward_override != null) upward = upward_override
	local force = vel_override ? vel_override : QAngle(0, yaw, 0).Forward().Scale(backward) + Vector(0, 0, upward)
	propent(victim, "m_hGroundEntity", null)
	victim.ApplyAbsVelocityImpulse(force)
	
	propint(victim, "m_afButtonDisabled", IN_ATTACK | IN_ATTACK2 | IN_DUCK | IN_USE
		| IN_MOVELEFT | IN_MOVERIGHT | IN_FORWARD | IN_BACK | IN_SPEED | IN_RELOAD | IN_ZOOM)
	_3rd_force(victim, true)
	
	if ("to_firstperson" in victim_scope) remove_delayed_call(victim_scope.to_firstperson)
		
	local victim_to_firstperson = function() {
		if (invalid(victim)) return
		_3rd_force(victim, false)
		propint(victim, "m_afButtonDisabled", 0)
		del("to_firstperson", victim_scope)
	}
	
	victim_scope.in_punch_flight <- true
	
	local flight_sequence = get_flight_sequence(victim)
	register_ticker("punch_flight" + unique_str_id(victim), function() {
		if (invalid(victim)) return false
		if (propint(victim, "m_lifeState") != 0 || victim.IsGhost() || victim.IsIncapacitated() || victim.IsHangingFromLedge()) {
			victim_to_firstperson()
			scope(victim).in_punch_flight = false
			return false
		}
		if (flight_sequence != null)
			propint(victim, "m_nSequence", flight_sequence)
		if (propent(victim, "m_hGroundEntity") || propint(victim, "movetype") == MOVETYPE_LADDER) {
			if (victim.IsSurvivor() && !propent(victim, "m_jockeyAttacker") && stun) {
				launch_rock(victim)
				victim_scope.to_firstperson <- delayed_call(victim_to_firstperson, 2)
			} else {
				scope(victim).in_punch_flight = false
				victim_scope.to_firstperson <- delayed_call(victim_to_firstperson, 1)
			}
			return false
		}
	})
}

new_upgrade({
	name = "BoomerBouncer",
	display_name = "Boomer Bouncer",
	on_enable = function() {
		register_callback("player_hurt", "boomer_punch", function(params) {
			if (!("weapon" in params) || params.weapon != "boomer_claw") return
			local boomer = params.player_attacker
			local victim = params.player
			punch(boomer, victim)
		})
	}
	on_disable = function() {
		rock_launcher.Kill()
		remove_callback("player_hurt", "boomer_punch")
	}
})

////////////////////////////////////
//		Spitter Glue
////////////////////////////////////

local spitter_glue_velocity_modifier = 0.4

new_upgrade({
	name = "SpitterGlue",
	display_name = "Spitter Glue",
	on_enable = function() {
		register_callback("player_hurt", "spitter_glue", function(params) {
			if (!("weapon" in params) || params.weapon != "insect_swarm") return
			propfloat(params.player, "m_flVelocityModifier", spitter_glue_velocity_modifier)
		})
	}
	on_disable = function() {
		remove_callback("player_hurt", "spitter_glue")
	}
})

////////////////////////////////////
//		Tank Bomber
////////////////////////////////////

// this is the longest script here (to this time)

tank_bomber_throw_interval <- 3.1

explosion_trace_inner_shpere <- 10

traces_count_multiplier <- 14

tank_explosion_force <- 200

tank_explosion_dist <- 200

local player_backward_func = linear_interp(0.3, 400, 1.2, 100, true, true)
local player_upward_func = linear_interp(0.3, 400, 1.2, 200, true, true)

local tank_force_func = bilinear_interp(50, 800, 130, 600, 250, 0, true, true)
local tank_pitch_correction = linear_interp(-90, -90, 90, -20)

local traces_debug = false

local punch_debug = false

local flight_debug = false

if (!("phys" in this) && !("phys" in getroottable())) IncludeScript("kapkan/phys")

local bomber_create_particles = function(particles, beacon, sequence) {
	local delta_time = 0
	if (sequence == 49) delta_time = 0.75 //one-handed overhand
	else if (sequence == 50) delta_time = 0.5 //underhand
	else if (sequence == 51) delta_time = 0.9 //two-handed overhand
	delayed_call( function() {
		if (!invalid(beacon)) {
			particles.push(create_particles("env_fire_medium_smoke", beacon))
			//particles.push(create_particles("fire_jet_01_smoke", beacon))
		}
	}, delta_time)
}

local bomber_update_particles = function(particles, beacon, delta) {
	if (delta.Length() == 0) return
	local backward_direction = vector_to_angle(delta.Scale(-1))
	foreach(ent in particles)
		ent.SetAngles(backward_direction)
}

local bomber_create_explosion_particles = function(explosion_pos) {
	local explosion_tier2 = (tank_explosion_force > 550)
	local explosion_tier3 = (tank_explosion_force > 1200)
	if (!explosion_tier2) {
		create_particles("weapon_pipebomb_child_fire", explosion_pos, 6)
		create_particles("gas_explosion_initialburst_blast", explosion_pos, 6)
	} else if (!explosion_tier3) {
		//create_particles("gas_explosion_main", explosion_pos, 10)
		create_particles("weapon_pipebomb_child_fire", explosion_pos, 6)
		create_particles("gas_explosion_initialburst_blast", explosion_pos, 6)
	} else {
		create_particles("explosion_huge", explosion_pos, 10)
	}
	//create_particles("charger_wall_impact", explosion_pos, 6)
	local trace_result = trace_line(explosion_pos, explosion_pos - Vector(0, 0, 60), TRACE_MASK_SHOT)
	if (trace_result.hit) {
		if (!explosion_tier2) {
			create_particles("boomer_leg_smoke", trace_result.hitpos, RandomInt(10, 30))
		} else {
			create_particles("env_fire_large_smoke", trace_result.hitpos, RandomInt(10, 30))
		}
	}
}

//returns [basevelocity, angvelocity], but doesn't push
local prop_physics_precalc = function(ent, point, direction, speed) {
	local ent_angles = ent.GetAngles()
	local base_velocity = direction.Scale(speed)
	local delta = point - ent.GetOrigin()
	local rotation_axis = normalize(delta.Cross(base_velocity))
	local rotation_speed = base_velocity.Length() / sqrt(delta.Length()) * RAD_TO_DEG //?
	local rotations = decompose_by_orthonormal_basis(rotation_axis, ent_angles.Forward(), ent_angles.Left().Scale(-1), ent_angles.Up())
	//ent.ApplyAbsVelocityImpulse(base_velocity)
	//ent.ApplyLocalAngularVelocityImpulse(rotations.Scale(rotation_speed))
	return [base_velocity, rotations.Scale(rotation_speed)]
	//DebugDrawLine_vCol(ent_origin, ent_origin + base_velocity, Vector(0, 255, 0), false, 3)
}

local explode_tank_rock = function(tank, explosion_pos) {
	bomber_create_explosion_particles(explosion_pos)
	local traces_yaw = 4 * traces_count_multiplier
	local traces_pitch = 2 * traces_count_multiplier
	local get_explosion_trace_directions = function() {
		local directions = []
		local pitch_step = 180.0 / (traces_pitch - 1)
		for (local pitch = -90; pitch <= 90; pitch += pitch_step) {
			local amount = max(1, ceil(cos(pitch / RAD_TO_DEG) * traces_yaw))
			local odd = (pitch % 10 == 0)
			local yaw_step = 360.0 / amount
			for(local yaw = 0; yaw < 360; yaw += yaw_step)
				directions.push(QAngle(pitch, odd ? yaw + yaw_step / 2 : yaw, 0).Forward())
		}
		return directions
	}
	local directions = get_explosion_trace_directions()
	local traces_count = directions.len()
	if (traces_debug || flight_debug) {
		mark(explosion_pos, 3)
		if (traces_debug) say_chat(traces_count + " traces")
	}
	local explosion_targets = {}
	foreach(direction in directions) {
		local trace_start_pos = explosion_pos + direction.Scale(RandomFloat(0, explosion_trace_inner_shpere * 2))
		local trace_end_pos = explosion_pos + direction.Scale(tank_explosion_dist)
		local trace_table = trace_line(trace_start_pos, trace_end_pos, TRACE_MASK_SHOT)
		if (trace_table.hit && trace_table.enthit != worldspawn) {
			local ent = trace_table.enthit
			local hitpos = trace_table.hitpos
			if (traces_debug) {
				local color = Vector(180, 0, 0)
				DebugDrawLine_vCol(trace_start_pos, trace_end_pos, color, false, 3)
				mark(hitpos, 3, color)
			}
			if (!(ent in explosion_targets)) {
				local model = propstr(ent, "m_ModelName")
				local physdata = (model in phys) ? phys[model] : null
				explosion_targets[ent] <- {
					model = model,
					mass = physdata ? physdata.mass : 75.0,
					//center = physdata ? physdata.center : ent.GetOrigin(),
					rays = []
				}
			}
			explosion_targets[ent].rays.push({
				direction = direction,
				hitpos = hitpos
			})
		} else if (traces_debug) {
			local color = Vector(0, 255, 128)
			DebugDrawLine_vCol(trace_start_pos, trace_end_pos, color, false, 3)
			mark(trace_end_pos, 3, color, 1)
		}
	}
	local phys_classnames = {
		prop_physics = true,
		func_physbox = true,
		infected = true,
		prop_dynamic = true,
		func_breakable = true,
		prop_door_rotating = true,
	}
	foreach(ent, table in explosion_targets) {
		local ent_class = ent.GetClassname()
		if (traces_debug) {
			local _ent = ent
			register_ticker("debug_text" + unique_str_id(_ent), function(){
				DebugDrawText(_ent.GetOrigin(), ent_class, false, 0.09)
				if (clock.sec() - ticker_info.start_time > 4) return false
			})
		}
		if (ent_class in phys_classnames) {
			local basevel = Vector(0, 0, 0)
			local angvel = Vector(0, 0, 0)
			logf("ENTITY %s was hit with %d traces", ent_to_str(ent), table.rays.len())
			foreach(ray in table.rays) {
				local push_speed = 13000 / (table.mass + 18) * 200 * tank_explosion_force / traces_count
				local push_data = prop_physics_precalc(ent, ray.hitpos, ray.direction, push_speed)
				basevel += push_data[0]
				angvel += push_data[1]
			}
			logf("basevel = %s, angvel = %s", vecstr2(basevel), vecstr2(angvel))
			// applying coefficient based on ray count
			local coef = 2 - max(0.6, table.rays.len() * 4 / traces_count)
			basevel *= coef; angvel *= coef
			logf("coef = %.2f", coef)
			//model-specific actions
			if (table.model == "models/props_junk/dumpster_2.mdl") {
				basevel *= 2; angvel *= 2
			}
			// clumping base velocity
			local basevel_max_length = 800 * max(1, tank_explosion_force / 200)
			log("" + basevel_max_length)
			if (basevel.Length() > 800)
				basevel = basevel.Scale(800 / basevel.Length())
			// clumping angular velocity
			local angvel_max = 500 * max(1, tank_explosion_force / 200)
			if (angvel.x > angvel_max) angvel.x = angvel_max
			else if (angvel.x < -angvel_max) angvel.x = -angvel_max
			if (angvel.y > angvel_max) angvel.y = angvel_max
			else if (angvel.y < -angvel_max) angvel.y = -angvel_max
			if (angvel.z > angvel_max) angvel.z = angvel_max
			else if (angvel.z < -angvel_max) angvel.z = -angvel_max
			logf("clumping, basevel = %s, angvel = %s", vecstr2(basevel), vecstr2(angvel))
			//applying base velocity and angular velocity
			ent.ApplyAbsVelocityImpulse(basevel)
			ent.ApplyLocalAngularVelocityImpulse(angvel)
			ent.TakeDamage(table.rays.len() * tank_explosion_force / 4, DMG_BLAST, null)
		} else if (ent_class == "player") {
			local player_pos = ent.GetOrigin() + Vector(0, 0, propvec(ent, "m_Collision.m_vecMaxs").z / 2)
			local force_vec = player_pos - explosion_pos
			local dist = force_vec.Length()
			local fraction = dist / tank_explosion_dist //from ~0.3 (nearest) to ~1.2 (farthest)
			local backward, upward
			if (punch_debug) {
				mark(explosion_pos, 3, Vector(0, 0, 255))
				mark(player_pos, 3, Vector(255, 255, 255))
			}
			if (ent != tank) {
				backward = player_backward_func(fraction)
				upward = player_upward_func(fraction)
				backward *= tank_explosion_force / 200; upward *= tank_explosion_force / 200
				if (punch_debug) say_chat(fraction + " : " + backward + " " + upward)
				punch(null, ent, explosion_pos, false, backward, upward)
			} else {
				//backward = tank_backward_func(fraction)
				//upward = tank_upward_func(fraction)
				local force = tank_force_func(dist)
				if (punch_debug) say_chat("dist " + dist + " : " + force)
				if (force > 0) {
					local force_ang = vector_to_angle(force_vec)
					if (punch_debug) say_chat("%.2f -> %.2f", force_ang.x, tank_pitch_correction(force_ang.x))
					force_ang.x = tank_pitch_correction(force_ang.x)
					local velocity = force_ang.Forward().Scale(force)
					velocity *= tank_explosion_force / 200
					if (punch_debug) mark(explosion_pos + velocity.Scale(0.5), 3, Vector(0, 255, 255))
					punch(null, ent, explosion_pos, false, null, null, velocity)
				}
			}
			if (!invalid(tank))
				propint(tank, "m_frustration", 0)
		} else {
			say_chat(ent_to_str(ent) + " push action unspecified")
		}
	}
}

/* test_push <- function() {
	local start_pos = player().EyePosition()
	local direction = player().EyeAngles().Forward()
	local trace_end_pos = start_pos + direction.Scale(200)
	local trace_table = trace_line(start_pos, trace_end_pos, TRACE_MASK_ALL, player())
	DebugDrawLine_vCol(start_pos, trace_end_pos, Vector(0, 255, 128), false, 3)
	logt(trace_table)
	if (trace_table.hit) {
		local ent = trace_table.enthit
		if (ent.GetClassname() != "prop_physics") return
		local hitpos = trace_table.hitpos
		mark(hitpos, 3, Vector(0, 255, 128))
		local vels = prop_physics_precalc(ent, hitpos, direction, 200)
		ent.ApplyAbsVelocityImpulse(vels[0])
		ent.ApplyLocalAngularVelocityImpulse(vels[1])
	}
} */

local ignite_tank_rock = function(tank, rock) {
	//tank may be null
	if ("ignited" in scope(rock)) {
		log("already ignited")
		return
	}
	scope(rock).ignited <- true
	DoEntFire("!self", "AddOutput", "rendercolor 20 20 20", 0, null, rock)
	local rock_throwed = false
	local beacon = SpawnEntityFromTable("info_particle_target", {})
	local last_beacon_pos = beacon.GetOrigin()
	local last_beacon_vel = beacon.GetVelocity()
	local particles = []
	bomber_create_particles(particles, beacon, tank ? propint(tank, "m_nSequence") : 0)
	local beacon_positions = [last_beacon_pos]
	if (tank) {
		DoEntFire("!self", "SetParent", "!activator", 0, tank, beacon)
		DoEntFire("!self", "SetParentAttachment", "debris", 0.01, null, beacon)
	}
	register_ticker("rock_ticker" + unique_str_id(rock), function() {
		if (invalid(rock)) {
			if (rock_throwed) {
				local len = beacon_positions.len()
				for (local i = 0; i < 50; i++) {
					local index = len - (i + 1)
					if (index < 0) break
					local trace_start = beacon_positions[index]
					local trace_end = (i == 0) ? (last_beacon_pos + last_beacon_vel.Scale(ticker_info.delta_time)) : beacon_positions[index + 1]
					local trace_result = trace_line(trace_start, trace_end, TRACE_MASK_SHOT)
					if (trace_result.startsolid) continue
					local fraction = max(trace_result.fraction, 0.9) //if didn't hit, fraction is 1
					local explosion_pos = trace_start + (trace_start - trace_end).Scale(fraction)
					explode_tank_rock(tank, explosion_pos)
					break
				}
			}
			if (!invalid(beacon)) beacon.Kill()
			return false
		}
		if (!rock_throwed && propint(rock, "movetype") == MOVETYPE_FLYGRAVITY) {
			rock_throwed = true
			if (!tank) {
				local origin = rock.GetOrigin()
				beacon.SetOrigin(origin)
				foreach(ent in particles)
					ent.SetOrigin(origin)
			}
			DoEntFire("!self", "SetParent", "!activator", 0, rock, beacon)
		}
		//don't change order of these lines -->
		local target_pos = beacon.GetOrigin()
		local delta = target_pos - last_beacon_pos
		bomber_update_particles(particles, beacon, delta)
		if (flight_debug) DebugDrawLine_vCol(target_pos, last_beacon_pos, Vector(0, 255, 0), false, 3)
		last_beacon_pos = target_pos
		beacon_positions.push(last_beacon_pos)
		last_beacon_vel = beacon.GetVelocity()
		// <-- don't change order of these lines
	})
}

new_upgrade({
	name = "TankBomber",
	display_name = "Tank Bomber",
	on_enable = function() {
		register_callback("ability_use", "tank_bomber", function(params) {
			local tank = params.player
			register_ticker("rock_finder" + unique_str_id(tank), function() {
				if (invalid(tank) || tank.IsDead() || tank.IsDying()) return false
				local rock = tank.FirstMoveChild()
				if (("GetClassname" in rock) && rock.GetClassname() == "tank_rock") {
					ignite_tank_rock(tank, rock)
					return false;
				}
			})
			set_ability_cooldown(tank, max(tank_bomber_throw_interval, 3.1))
		})
		foreach(launcher in find_entities("env_rock_launcher")) {
			if ("fake" in scope(launcher)) continue //see create_rock_launcher() and maybe upcoming code
			if (!invalid(launcher)) {
				scope(launcher).InputLaunchRock <- function() {
					run_next_tick( function() {
						foreach(rock in find_entities("tank_rock")) {
							if (!("ignited" in scope(rock)) && !("fake" in scope(rock))) {
								ignite_tank_rock(null, rock)
								break
							}
						}
					}.bindenv(scope(launcher)))
					return true
				}
			}
		}
	}
	on_disable = function() {
		remove_callback("ability_use", "tank_bomber")
		foreach(launcher in find_entities("env_rock_launcher")) {
			if ("fake" in scope(launcher)) continue
			if (!invalid(launcher))
				del("InputLaunchRock", scope(launcher))
		}
	}
})









// i didn't reinvent the wheel, it works just like Incapped Crawling SM plugin
// (although this code is 10 times shorter)
