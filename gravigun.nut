//gravigun

//requires lib.nut
//https://github.com/sedol1339/l4d2/blob/master/lib.nut

cvar_create("gravigun_enable", 1) //is gravigun enabled (otherwise it will not do anything)
cvar_create("gravigun_debug", 1) //enables debug output in console and draws debug overlays
cvar_create("gravigun_unstuck", 1) //try to unstuck object held by gravigun: 0 - never, 1 - when it seems to be stucked in walls, floor or ceiling, 2 - always
cvar_create("gravigun_instant", 0) //use simple HL2-like gravigun mode: objects move visually faster but movement is jittering due to engine limitations
cvar_create("gravigun_break", 0) //can target escape from gravigun when becomes too far from attraction point?
cvar_create("gravigun_cooldown", 1) //cooldown for gravigun actions
cvar_create("gravigun_particles", 2) //use custom particles for gravigun (0 = none, 1 = onle beam, 2 = beam, electrical arc and explosive particles)
cvar_create("gravigun_rough", 0) //use simple mode (no custom settings for each gravigun target type, no weight check, no breaking force)
cvar_create("gravigun_toggled_mode", 0) //first mouse click catches target, second pushes it
cvar_create("gravigun_max_basevelocity", 650) //max basevelocity applied to target on move tick
cvar_create("gravigun_max_relative_target_velocity", 1200) //max relative velocity that gravigun is able to apply to target to correct it's position when holding it
cvar_create("gravigun_distance", 200) //distance frum gravigun to target
cvar_create("gravigun_interrupt_max_gained_velocity", 500) //max relative velocity that can have a target after gravigun releases them
cvar_create("gravigun_angular_velocity_reduction", 0.005) //how fast angular velocity of gravigun target is decreasing (min 0, max 1)

cvar_create("gravigun_catch_distance", 300) //max distance frum gravigun to possible target
cvar_create("gravigun_catch_angle", 10) //cone radius for gravigun poossible target
cvar_create("gravigun_traces", 37) //how many times should we perform a traceline when searching for gravigun target (min 1)
cvar_create("gravigun_pull_max_distance", 800) //when object is farther that gravigun_catch_distance, but no more than this distance, it will be pulled to gravigun
cvar_create("gravigun_pull_max_force", 150) //max force with which gravigun pulls targets when can't catch them

cvar_create("gravigun_push", 1) //does gravigun push target forward when releases it
cvar_create("gravigun_push_force", 1500) //force with which gravigun pushes things
cvar_create("gravigun_push_velocity", 0) //if non-zero, gravigun applies this velocity to targets when pushes them, ignoring gravigun_push_force
cvar_create("gravigun_push_cone_angle", 35) //when gravigun pushes someting, it will also push all objects in this cone
cvar_create("gravigun_push_cone_distance", 120) //when gravigun pushes someting, it will push all objects in cone witch are no more than that distance
cvar_create("gravigun_push_cone_force", 400) //when gravigun pushes someting, it will push all objects in cone witch this force
cvar_create("gravigun_push_cone_traces", 25) //when gravigun pushes someting, it will push all objects in cone performing this many traces

cvar_create("gravigun_player", 1) //can players be held in gravigun
cvar_create("gravigun_player_survivor", 1) //can survivors be held in gravigun
cvar_create("gravigun_player_survivor_incapacitated", 1) //can incapacitated survivors be held in gravigun
cvar_create("gravigun_player_survivor_grab_ledge", 1) //can survivors that grab ledge be held in gravigun
cvar_create("gravigun_player_infected", 1) //can special infected (except tank) be held in gravigun
cvar_create("gravigun_player_tank", 1) //can tank be held in gravigun

cvar_create("gravigun_witch", 1) //can witch be held in gravigun
cvar_create("gravigun_common_infected", 1) //can common infected be held in gravigun

cvar_create("gravigun_prop_physics", 1) //can physics props be held in gravigun
cvar_create("gravigun_projectiles", 1) //can molotov, bile, pipe bomb, spitter projectiles be held in gravigun
cvar_create("gravigun_tank_rocks", 1) //can tank rocks be held in gravigun
cvar_create("gravigun_equipment", 1) //can equipment (weapons, throwables, medicines, cans, cola, gnome) be held in gravigun

cvar_create("gravigun_activate_throwables", 1) //when molotov or bile bomb is thrown by gravigun, should it be activated and become projectile?
cvar_create("gravigun_player_use_animation", 1) //use thirdperson view and falling animation when player is held by gravigun
cvar_create("gravigun_bots_freeze", 1) //when bot is thrown by gravigun, should it become frozen (doesn't use movement keys) until it lands?
cvar_create("gravigun_prop_physics_protect", 1) //protect survivors from getting damage when collide with prop_physics held in gravigun
cvar_create("gravigun_prop_physics_disallow_heavy", 1) //very heavy physics props cannot be held in gravigun
cvar_create("gravigun_breaks_breakable", 1) //does gravigun break doors and other breakables
cvar_create("gravigun_survivors_no_fall_damage", 0) //survivors will receive no fall damage atfer landing when pushed by gravigun

local debug = @()cvarf("gravigun_debug") != 0

gravigun_start_use <- function(player) {
	if (cvarf("gravigun_enable") == 0) return
	player.ValidateScriptScope()
	player.GetScriptScope().gravigun <- {}
	//anim_layer_start(player)
	local pull_loop = "__gravigun_pull_loop_" + player.GetEntityHandle().tointeger()
	player.GetScriptScope().gravigun.pull_loop <- pull_loop
	clock.tick_counter_init()
	register_loop(pull_loop, function() {
		local target = find_target(player)
		if (target) {
			player.GetScriptScope().gravigun.target <- target
			hang_surv(player, target)
			remove_loop(pull_loop)
		}
	}, 0.1)
	
}

gravigun_stop_use <- function(player, was_interrupted) {
	player.ValidateScriptScope()
	if (!("gravigun" in player.GetScriptScope())) {
		if (debug()) say_chat("player %s is not using gravigun", player_to_str(player))
		return
	}
	//anim_layer_stop(player, was_interrupted)
	if ("target" in player.GetScriptScope().gravigun) {
		local target = player.GetScriptScope().gravigun.target
		unhang_surv(player, target)
	} else if ("pull_loop" in player.GetScriptScope().gravigun) {
		remove_loop(player.GetScriptScope().gravigun.pull_loop)
	}
	delete player.GetScriptScope().gravigun
}

//////////////

anim_layer_start <- function(player) {
	local gravigun_table = player.GetScriptScope().gravigun
	gravigun_table.anim_start_time <- clock.sec()
	gravigun_table.anim_ticker_name <- "__gravigun_anim_" + player.GetEntityHandle().tointeger()
	//local weapon = propent(player, "m_hViewModel")
	//local target = SpawnEntityFromTable("prop_dynamic", {model = "models/w_models/weapons/w_eq_medkit.mdl"})
	//DoEntFire("!self", "SetParent", "!activator", 0, weapon, target)
	//DoEntFire("!self", "SetParentAttachment", "Attach_muzzle", 0, weapon, target)
	register_ticker(gravigun_table.anim_ticker_name, function() {
		if (cvarf("gravigun_enable") == 0) {
			gravigun_stop_use(player, true)
			return
		}
		local direction = player.EyeAngles()
		local direction_forward = direction.Forward()
		local direction_aside = normalize(direction_forward.Cross(Vector(0, 0, 1)))
		local direction_up = Vector(0, 0, 0) - normalize(direction_forward.Cross(direction_aside))
		local box_max = direction_forward * 10 + direction_aside * 1 + direction_up * 1
		if (debug()) DebugDrawBoxDirection(
			player.EyePosition() + RotateOrientation(direction, QAngle(13, -17, 0)).Forward().Scale(30),
			box_max - Vector(10,10,10),
			box_max,
			direction_forward,
			Vector(200, 0, 200),
			255,
			0.05
		)
	})
}

anim_layer_stop <- function(player, was_interrupted) {
	local gravigun_table = player.GetScriptScope().gravigun
	remove_ticker(gravigun_table.anim_ticker_name)
	delete gravigun_table.anim_start_time
	delete gravigun_table.anim_ticker_name
}

find_target <- function(player) {
	local debug = debug()
	if (debug) logf("Gravigun is searching for target (tick %d)", clock.ticks())
	local radius = cvarf_lim("gravigun_catch_angle", 0, 90)
	local trace_count = cvarf_lim("gravigun_traces", 1, 500)
	local pull_distance = cvarf_lim("gravigun_pull_max_distance", 0, null)
	local catch_distance = cvarf_lim("gravigun_catch_distance", 0, null)
	if (catch_distance > pull_distance) {
		error("gravigun_catch_distance cannot be more than gravigun_pull_max_distance\n")
		catch_distance = pull_distance
	}
	local pull_max_force = cvarf_lim("gravigun_pull_max_force", null, null)
	local gravigun_pos = player.EyePosition()
	local traces = get_traces(gravigun_pos, player.EyeAngles(), pull_distance, radius, trace_count)
	if (debug) foreach(line in traces)
			DebugDrawLine_vCol(line[0], line[1], Vector(255, 128, 0), false, 1)
	
	local trace_table = {
		mask = TRACE_MASK_VISIBLE_AND_NPCS,
		ignore = player
	}
	local ents_to_pull = {}
	foreach(line in traces) {
		trace_table.start <- line[0]
		trace_table.end <- line[1]
		TraceLine(trace_table)
		if (!("enthit" in trace_table)) continue
		local ent = trace_table.enthit
		if (ent == worldspawn) continue
		if (ent.GetClassname() in target_classes) {
			local hitpos = trace_table.start + (trace_table.end - trace_table.start).Scale(trace_table.fraction)
			local dist = (hitpos - trace_table.start).Length()
			if (dist > catch_distance) {
				if (!(ent in ents_to_pull)) ents_to_pull[ent] <- true
			} else {
				if (debug) logf("\tFound target %s at distance %.2f", ent_to_str(ent), dist)
				return ent
			}
		}
	}
	//if we are here, we didn't find any target to catch, pull others
	foreach(ent, _ in ents_to_pull) {
		local ent_to_gravigun_vec = gravigun_pos - ent.GetOrigin()
		local dist = ent_to_gravigun_vec.Length()
		local mass = target_classes[ent.GetClassname()].get_mass(ent)
		local force = pull_max_force - max(0, (dist - catch_distance)) * pull_max_force / (pull_distance - catch_distance)
		local speed = force / mass
		if (ent.IsPlayer()) {
			propent(ent, "m_hGroundEntity", null)
		}
		ent.ApplyAbsVelocityImpulse(normalize(ent_to_gravigun_vec).Scale(speed))
		if (debug) logf("\tPulling ent %s (mass %.2f) from dist %.2f with force %.2f and speed %.2f", ent_to_str(ent), mass, dist, force, speed)
	}
}

target_classes <- {
	player = {
		get_mass = function(ent) {return 1},
	},
	prop_physics = {},
}

hang_surv <- function(owner, target) {
	beam_end_target(target)
	beam_start(owner, target)
	if (target.IsPlayer() && target.IsSurvivor()) propint(target, "m_isFallingFromLedge", 1)
	propfloat(target, "m_TimeForceExternalView", 99999)
	propint(target, "m_takedamage", 1)
	remove_ticker("__gravigun_fall_" + target.GetEntityHandle().tointeger())
	local last_target_pos = null
	local last_desired_point = Vector(-8192, -8192, -8192)
	local prev_time = clock.sec()
	local was_correction_prev_tick = false
	register_ticker("__gravigun_move_tick_" + owner.GetEntityHandle().tointeger(), function() {
		local debug = debug()
		local time = clock.sec()
		local delta_time = time - prev_time
		prev_time = time
		if (delta_time == 0) return
		
		if (debug) logf("Gravigun move tick %d", clock.ticks())
		
		//calculating basevelocity
		////////////////////////////
		
		propent(target, "m_hGroundEntity", null)
		set_entity_flag(target, FL_ONGROUND, false)
		local target_pos = target.GetOrigin()
		if (target.GetClassname() == "prop_physics") {
			target_pos = target.GetOrigin() + target.GetAngles().Up().Scale(25) //dumpster
			DebugDrawBoxDirection(target_pos, Vector(-4, -4, -4), Vector(4, 4, 4), Vector(0, 0, 1), Vector(0, 255, 0), 255, 0.1)
		}
		local target_vel = target.GetVelocity()
		if (last_target_pos && target.GetClassname() == "prop_physics") {
			target_vel = (target_pos - last_target_pos).Scale(1 / delta_time)
		}
		local desired_point = owner.EyePosition() + owner.EyeAngles().Forward().Scale(150)
		
		if (debug) DebugDrawBoxDirection(desired_point, Vector(-4, -4, -4), Vector(4, 4, 4), Vector(0, 0, 1), Vector(200, 0, 200), 255, 0.1)
		
		local basevel_scale = 1
		if (target.GetClassname() == "prop_physics") basevel_scale = 0.5
		
		local basevel = (desired_point - target_pos).Scale(1.0 / delta_time).Scale(basevel_scale) - target_vel
		
		local MAX_BASEVEL = cvarf_lim("gravigun_max_basevelocity", 0, null)
		if (basevel.Length() > MAX_BASEVEL) {
			basevel = basevel.Scale(MAX_BASEVEL / basevel.Length())
			if (debug) logf("\tbasevel clumped to %s", vecstr2(basevel))
		}
		local MAX_VEL = cvarf_lim("gravigun_max_relative_target_velocity", 0, null)
		local target_relative_vel = target_vel - owner.GetVelocity()
		if ((target_relative_vel + basevel).Length() > MAX_VEL) {
			//solving square equation
			local a = basevel.LengthSqr()
			local b =  2 * target_relative_vel.Dot(basevel)
			local c = target_relative_vel.LengthSqr() - MAX_VEL * MAX_VEL
			local D = b*b - 4*a*c
			local n = 0
			if (D <= 0) {
				basevel = Vector(0, 0, 0)
			} else {
				n = (-b + sqrt(D)) / 2 / a
				if (n > 0)
					basevel = basevel.Scale(n)
				else
					basevel = Vector(0, 0, 0)
			}
			if (debug) logf("\tbasevel scaled to %s with multiplier %.2f (a=%.2f b=%.2f c=%.2f D=%.2f)", vecstr2(basevel), n, a, b, c, D)
		}
		//basevel.z += cvarf("sv_gravity") * delta_time //?
		
		//next we are checking if player is stuck to floor, wall or ceiling (if so, we need to change basevelocity to unstuck)
		
		//prepare data for correction
		///////////////////////////////

		local mins = target_pos + propvec(target, "m_Collision.m_vecMins")
		local maxs = target_pos + propvec(target, "m_Collision.m_vecMaxs")
		local trace_mask = (target.IsPlayer() && target.IsSurvivor()) ? TRACE_MASK_PLAYER_SOLID : TRACE_MASK_NPC_SOLID
		local trace_data = [
			[Vector(mins.x, mins.y, mins.z), Vector(-1, -1, -1)],
			[Vector(maxs.x, mins.y, mins.z), Vector(1, -1, -1)],
			[Vector(mins.x, maxs.y, mins.z), Vector(-1, 1, -1)],
			[Vector(maxs.x, maxs.y, mins.z), Vector(1, 1, -1)],
			[Vector(mins.x, mins.y, maxs.z), Vector(-1, -1, 1)],
			[Vector(maxs.x, mins.y, maxs.z), Vector(1, -1, 1)],
			[Vector(mins.x, maxs.y, maxs.z), Vector(-1, 1, 1)],
			[Vector(maxs.x, maxs.y, maxs.z), Vector(1, 1, 1)],
		]
		
		if (debug) {
			local lines = [
				[trace_data[0][0], trace_data[1][0]], [trace_data[0][0], trace_data[2][0]],
				[trace_data[3][0], trace_data[1][0]], [trace_data[3][0], trace_data[2][0]],
				[trace_data[4][0], trace_data[5][0]], [trace_data[4][0], trace_data[6][0]],
				[trace_data[7][0], trace_data[5][0]], [trace_data[7][0], trace_data[6][0]],
				[trace_data[0][0], trace_data[4][0]], [trace_data[1][0], trace_data[5][0]],
				[trace_data[2][0], trace_data[6][0]], [trace_data[3][0], trace_data[7][0]],
			]
			foreach (line in lines)
				DebugDrawLine_vCol(line[0], line[1], Vector(255, 180, 0), true, 0.1)
		}
		
		//check if we need correction (real stuck)
		///////////////////////////////////////////
		
		//local delta = target_pos - last_target_pos
		//local desired_delta = last_desired_point - last_target_pos
		//local real_stuck = delta.LengthSqr() < 0.01 && desired_delta.LengthSqr() > 25.0
		
		//check if we need correction (predicted stuck)
		////////////////////////////////////////////////
		
		local predicted_stuck = false
		//if (!real_stuck) {
		local predicted_delta = (target_vel + basevel).Scale(delta_time)
		local trace_table = {
			mask = trace_mask,
			ignore = target
		}
		foreach (data in trace_data) {
			trace_table.start <- data[0]
			trace_table.end <- data[0] + predicted_delta
			TraceLine(trace_table);
			if (trace_table.hit) {
				predicted_stuck = true
				break
			}
		}
		//}
		
		//gathering more data for correction
		//////////////////////////////////////
		
		local real_or_predicted_stuck = predicted_stuck //real_stuck || predicted_stuck
		local last_correction_unsuccessful = was_correction_prev_tick //&& real_stuck
		
		//perform a correction
		////////////////////////
		
		local basevel_corrected = false
		local gravigun_unstuck = cvarf("gravigun_unstuck")
		if (
			basevel.Length() != 0 && gravigun_unstuck != 0
			&& (gravigun_unstuck == 2 || gravigun_unstuck == 1 && real_or_predicted_stuck)
		) {
			if (debug) {
				//logging
				//https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/shared/gamemovement.cpp
				local reason = ""
				if (gravigun_unstuck == 2) reason = "forced correction"
				//else if (real_stuck) reason = "real stuck"
				else if (predicted_stuck) reason = "predicted stuck"
				logf("\tperforming correction [reason: %s]", reason)
			}
			
			//we are going to do up to 8 triple traces to find normal of surface that prevents moving
			foreach(data in trace_data) {
				local possible = predicted_delta.Dot(data[1]) >= 0
				if (debug) DebugDrawLine_vCol(data[0], data[0] + data[1].Scale(10), possible ? Vector(255, 0, 0) : Vector(0, 255, 0), true, 0.1)
				if (!possible) continue
				local trace_start = data[0] - data[1].Scale(0.2)
				local trace_end_main = data[0] + data[1]
				local trace_table = {
					start = trace_start,
					end = trace_end_main,
					mask = trace_mask,
					ignore = target
				}
				local get_hitpos = @(table) table.start + (table.end - table.start).Scale(table.fraction)
				
				//do triple trace
				TraceLine(trace_table);
				if (!trace_table.hit) continue
				local trace_point1 = get_hitpos(trace_table)
				local dist_to_sufrace = (trace_point1 - data[0]).Length()
				
				trace_table.end = trace_end_main + Vector(RandomFloat(-0.1, 0.1), RandomFloat(-0.1, 0.1), RandomFloat(-0.1, 0.1))
				TraceLine(trace_table);
				if (!trace_table.hit) continue
				local trace_point2 = get_hitpos(trace_table)
				
				trace_table.end = trace_end_main + Vector(RandomFloat(-0.1, 0.1), RandomFloat(-0.1, 0.1), RandomFloat(-0.1, 0.1))
				TraceLine(trace_table);
				if (!trace_table.hit) continue
				local trace_point3 = get_hitpos(trace_table)
				
				//given 3 points (trace_pointX), we find normal, correct basevelocity and exit loop
				local normal = (trace_point2 - trace_point1).Cross(trace_point3 - trace_point1)
				if (normal.Length() == 0) continue
				normal = normalize(normal)
				if (normal.Dot(data[1]) < 0) normal = normal.Scale(-1)
				
				if (debug) DebugDrawLine_vCol(trace_point1, trace_point3 + normal.Scale(10), Vector(255, 0, 0), true, 0.1)
				
				if (!basevel_corrected) {
					local parallel = normal.Scale( normal.Dot(basevel) / normal.LengthSqr() )
					local orthogonal = basevel - parallel
					local gravity = propfloat(target, "m_flGravity") * cvarf("sv_gravity")
					local normal_scale = 0.1 * (0.5 - dist_to_sufrace)
					basevel = orthogonal - normal.Scale( normal_scale )
					//basevel.z -= -gravity * delta_time
					basevel_corrected = true
					
					if (debug) logf(
						"\tNORM %s\tORT %s\tPAR %s\tGRAV %.2f\tDIST %.2f\tSCALE %.2f\tBASE %s\tPOS %s",
						vecstr3(normal), vecstr3(orthogonal), vecstr3(parallel),
						gravity * delta_time, dist_to_sufrace, normal_scale, vecstr3(basevel), vecstr3(target_pos)
					)
					
					if (!debug) break //other loop iterations are useless because we don't do anything, just draw
				}
				
			}
			if (debug && !basevel_corrected) log("\tAll tracelines failed, probably in air")
			/* if (last_correction_unsuccessful && RandomInt(0, 1) == 0) {
				local punch_axis = RandomInt(1, 5)
				local random_vel = Vector(RandomFloat(-50, 50), RandomFloat(-50, 50), RandomFloat(-50, 50))
				local punch_value = RandomInt(100, 200)
				if (RandomInt(0, 1) == 0) punch_value = -punch_value
				if (punch_axis == 1)				//probability 20% (10% X up 10% X down)
					random_vel.x += punch_value
				else if (punch_axis == 2)			//probability 20% (10% Y up 10% Y down)
					random_vel.y += punch_value
				else if (punch_axis == 3)			//probability 20% (10% Z up 10% Z down)
					random_vel.z += punch_value
				else								//probability 40% (40% Z up)
					random_vel.z += fabs(punch_value)
				basevel = random_vel
				if (debug) log("\tApplied random basevelocity to unstuck: " + random_vel)
			} */
		} else {
			//if (debug) logf("\tno correction", clock.ticks())
		}
		
		if (debug) {
			local color = basevel_corrected ? Vector(0, 0, 255) : Vector(0, 255, 255)
			DebugDrawLine_vCol(target_pos, target_pos + basevel, color, true, 0.1)
			DebugDrawBoxDirection(target_pos + basevel, Vector(-1, -1, -1), Vector(1, 1, 1), Vector(0, 0, 1), color, 255, 0.1)
			local color2 = Vector(0, 255, 0)
			DebugDrawLine_vCol(target_pos, target_pos + target_vel, color2, true, 0.1)
			DebugDrawBoxDirection(target_pos + target_vel, Vector(-1, -1, -1), Vector(1, 1, 1), Vector(0, 0, 1), color2, 255, 0.1)
		}
		
		//correction finished, applying basevelocity
		/////////////////////////////////////////////
		
		target.ApplyAbsVelocityImpulse(basevel)
		
		//saving data for next move tick
		//////////////////////////////////
		
		last_target_pos = target_pos
		//last_desired_point = desired_point
		was_correction_prev_tick = basevel_corrected
		
		//instant mode check
		//////////////////////////////////////
		if (cvarf("gravigun_instant") != 0) {
			if (!predicted_stuck)
				//target.SetOrigin(desired_point)
				target.SetOrigin(target_pos + (target_vel + basevel).Scale(delta_time))
			if (debug) log("\tInstant mode")
		}
		
		local angvel = GetPhysAngularVelocity(target)
		target.ApplyLocalAngularVelocityImpulse(angvel.Scale(cvarf_lim("gravigun_angular_velocity_reduction", 0, 1)))
	})
}

unhang_surv <- function(owner, target, breaked = false) {
	if (debug()) logf("Gravigun is releasing target (tick %d)%s", clock.ticks(), breaked ? " [breaked force]" : "")
	remove_ticker("__gravigun_move_tick_" + owner.GetEntityHandle().tointeger())
	beam_end_owner(owner)
	target.GetScriptScope().beam_dc <- delayed_call( function(){
		beam_end_target(target)
		delete target.GetScriptScope().beam_dc
	}, 1.5)
	if (target.GetClassname() == "prop_physics") return
	local owner_vel = owner.GetVelocity()
	local target_vel = target.GetVelocity()
	local relative_vel = target_vel - owner_vel
	local desired_relative_vel = relative_vel
	if (!breaked) {
		local max_relative_vel = cvarf_lim("gravigun_interrupt_max_gained_velocity", 0, null)
		if (relative_vel.Length() > max_relative_vel)
			desired_relative_vel = relative_vel.Scale(max_relative_vel / relative_vel.Length())
	}
	local desired_vel = desired_relative_vel + owner_vel
	if (!breaked) {
		local basevel = desired_vel - target_vel
		target.ApplyAbsVelocityImpulse(basevel)
		logf("\trelative vel %s\n\tdesired relative vel %s\n\tapplied basevel %s", vecstr2(relative_vel), vecstr2(desired_relative_vel), vecstr2(basevel))
	}
	local last_check_time = clock.sec()
	propfloat(target, "m_flGravity", 1)
	propint(target, "m_takedamage", 2)
	register_ticker("__gravigun_fall_" + target.GetEntityHandle().tointeger(), function() {
		local function ground_is_near() {
			//to prevent leaving no corpse due to m_isFallingFromLedge
			local player_origin = target.GetOrigin()
			local delta = target.GetVelocity().Scale(0.2)
			local mins = propvec(target, "m_Collision.m_vecMins")
			local maxs = propvec(target, "m_Collision.m_vecMaxs")
			local start_points = [
				player_origin,
				player_origin + Vector(mins.x, mins.y, 0),
				player_origin + Vector(maxs.x, mins.y, 0),
				player_origin + Vector(mins.x, maxs.y, 0),
				player_origin + Vector(maxs.x, maxs.y, 0),
			]
			foreach (vec in start_points)
				if (trace_line(vec, delta + vec, TRACE_MASK_PLAYER_SOLID, target).hit)
					return true
			return false
		}
		if (get_entity_flag(target, FL_ONGROUND) || ground_is_near()) {
			propint(target, "m_isFallingFromLedge", 0)
			propfloat(target, "m_TimeForceExternalView", 0)
			remove_ticker("__gravigun_fall_" + target.GetEntityHandle().tointeger())
		} else {
			local old_vel = target.GetVelocity()
			//local new_vel = Vector(desired_vel.x, desired_vel.y, old_vel.z)
			local gravity = propfloat(target, "m_flGravity") * cvarf("sv_gravity")
			local time = clock.sec()
			local delta_time = time - last_check_time
			last_check_time = time
			desired_vel = desired_vel + Vector(0, 0, -delta_time * gravity)
			target.ApplyAbsVelocityImpulse(desired_vel - old_vel)
		}
	})
}

beam_start <- function(owner, target) {
	if ("beam_dc" in target.GetScriptScope()) {
		remove_delayed_call(target.GetScriptScope().beam_dc)
		delete target.GetScriptScope().beam_dc
	}
	local key = UniqueString("env_beam_target")
	local effect_target = SpawnEntityFromTable("info_particle_target", {
		targetname = key,
		origin = target.GetOrigin() + Vector(0, 0, 30),
	});
	DoEntFire("!self", "SetParent", "!activator", 0, target, effect_target)
	local effect = SpawnEntityFromTable("info_particle_system", {
		effect_name = "storm_lightning_01_thin",
		cpoint1 = key,
	});
	local effect2 = SpawnEntityFromTable("info_particle_system", {
		effect_name = "storm_lightning_02_thin",
		cpoint1 = key,
	});
	DoEntFire("!self", "Start", "", 0, null, effect);
	local weapon = propent(owner, "m_hViewModel")
	DoEntFire("!self", "SetParent", "!activator", 0, weapon, effect)
	DoEntFire("!self", "SetParentAttachment", "Attach_muzzle", 0, weapon, effect)
	DoEntFire("!self", "SetParent", "!activator", 0, weapon, effect2)
	DoEntFire("!self", "SetParentAttachment", "Attach_muzzle", 0, weapon, effect2)
	local effect3 = SpawnEntityFromTable("info_particle_system", {
		effect_name = "electrical_arc_01_parent",
		origin = target.GetOrigin() + Vector(0, 0, 40),
		cpoint1 = key,
	});
	DoEntFire("!self", "SetParent", "!activator", 0, target, effect3)
	DoEntFire("!self", "Start", "", 0.001, null, effect3);
	////////////
	local loop_name = "__beam" + key
	register_loop(loop_name, function() {
		DoEntFire("!self", "Stop", "", 0, null, effect);
		DoEntFire("!self", "Start", "", 0.001, null, effect);
		DoEntFire("!self", "Stop", "", 0, null, effect2);
		DoEntFire("!self", "Start", "", 0.001, null, effect2);
	}, 0.1)
	local effect3_timer = SpawnEntityFromTable("logic_timer", {
		UseRandomTime = 1,
		LowerRandomBound = 0.5,
		UpperRandomBound = 1
	});
	effect3_timer.ConnectOutput("OnTimer", "func");
	effect3_timer.ValidateScriptScope();
	effect3_timer.GetScriptScope().func <- function() {
		DoEntFire("!self", "Stop", "", 0, null, effect3);
		DoEntFire("!self", "Start", "", 0.1, null, effect3);
	}
	/////////////
	owner.ValidateScriptScope()
	target.ValidateScriptScope()
	owner.GetScriptScope().beam_ents <- [effect, effect2]
	owner.GetScriptScope().beam_loop_name <- loop_name
	target.GetScriptScope().beam_ents <- [effect_target, effect3, effect3_timer]
}

beam_end_owner <- function(owner) {
	foreach(ent in owner.GetScriptScope().beam_ents)
		ent.Kill()
	delete owner.GetScriptScope().beam_ents
	remove_loop(owner.GetScriptScope().beam_loop_name)
	delete owner.GetScriptScope().beam_loop_name
}

beam_end_target <- function(target) {
	if ("beam_ents" in target.GetScriptScope()) {
		foreach(ent in target.GetScriptScope().beam_ents)
			ent.Kill()
		delete target.GetScriptScope().beam_ents
	}
}

get_traces <- function(origin, angles, distance, radius, count) {
	Assert(count > 0)
	//(2*grid_radius + 1)^2 >= count
	local grid_radius = ceil( (sqrt(count) - 1) / 2 )
	local points = []
	for (local i = -grid_radius; i <= grid_radius; i++)
		for (local j = -grid_radius; j <= grid_radius; j++)
			points.push([i, j, i*i + j*j])
	points.sort(function(a, b) {
		if (a[2] > b[2]) return 1;
		if (a[2] < b[2]) return -1;
		return 0;
	})
	points = points.slice(0, count)
	local max_dist = sqrt(points[count - 1][2])
	local scale = radius / max_dist
	local trace_lines = []
	foreach(point in points) {
		local pitch = point[0] * scale
		local yaw = point[1] * scale
		local ang = RotateOrientation(angles, QAngle(pitch, yaw, 0))
		local line = [origin, origin + ang.Forward().Scale(distance)]
		trace_lines.push(line)
		
	}
	return trace_lines
}

//beam_start(player(), bot()) //test

run_next_tick( @()gravigun_start_use(player()) ) //test

//alias +gravigun "script_execute _test43"
//alias -gravigun "script gravigun_stop_use(player(), false)"
//bind q +gravigun
