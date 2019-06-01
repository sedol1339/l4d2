//////////////////////////////////////////////////
////// Spawners //////////////////////////////////
//////////////////////////////////////////////////

if (!("Spawners" in this)) Spawners <- {}

//initialization: zombie_type, x_min, x_max, y_min, y_max, z_min, z_max, angle (may be null), amount, respawn_only_killed, on_spawn = null, frozen, static_target
Spawners.SimpleTargets <- function(params) {
	if (!("angle" in params)) params.angle <- null;
	if (!("on_spawn" in params)) params.on_spawn <- null;
	return function() {
		local function spawn() {
			local pos = Vector(RandomFloat(params.x_min, params.x_max), RandomFloat(params.y_min, params.y_max), RandomFloat(params.z_min, params.z_max));
			local ent = spawn_infected(params.zombie_type, pos);
			ent.ValidateScriptScope();
			ent.GetScriptScope().spawn_pos <- pos;
			if (params.frozen) set_entity_flag(ent, FL_FROZEN, true);
			if (params.static_target) NetProps.SetPropInt(ent, "movetype", MOVETYPE_NONE);
			if (params.angle != null) teleport_entity(ent, null, params.angle);
			if (params.on_spawn != null) params.on_spawn(ent);
			return ent;
		}
		if (params.respawn_only_killed) {
			foreach(i, target in targets)
				if (!target.IsValid() || target.IsDead()) {
					targets[i] = spawn();
				}
			local diff = params.amount - targets.len();
			for (local i = 0; i < diff; i++) targets.push(spawn());
		} else {
			foreach(target in targets) if (target.IsValid()) target.Kill();
			targets = [];
			for (local i = 0; i < params.amount; i++) targets.push(spawn());
		}
	}
}

//////////////////////////////////////////////////
////// Actions ///////////////////////////////////
//////////////////////////////////////////////////

if (!("Actions" in this)) Actions <- {}

function Actions::ResetMovetypeToStatic() {
	foreach(target in targets) {
		NetProps.SetPropInt(target, "movetype", 0);
		NetProps.SetPropFloat(target, "m_staggerTimer.m_timestamp", 0);
	}
}

function Actions::RemoveAllTargets() {
	foreach(target in targets) if (target.IsValid()) target.Kill();
	targets = [];
}

function Actions::PrintHitsAndShots() {
	foreach(player, player_stats in get_history()) {
		say_chat(
			"Score [" + player.GetPlayerName() + "]: "
			+ player_stats.hits + " hits "
			+ "(" + (100.0 * player_stats.hits / (player_stats.hits + player_stats.misses)) + "%)"
		);
	}
}

function Actions::SaveHitsAndShots(filename) {
	local history = get_history();
	if (history.len() > 1) throw "SaveHitsAndShots() does not support multiple players";
	local arr = null;
	if (history.len() > 0) {
		local player_stats = null;
		foreach(entry in history) {
			player_stats = entry;
			break;
		}
		arr = [player_stats.misses, player_stats.hits, player_stats.bodyshots, player_stats.headshots, player_stats.kills];
	} else {
		//get_history() does not contain players
		arr = [0, 0, 0, 0, 0];
	}
	local str = connect_strings(arr, "\t\t");
	local file_str = file_read(filename);
	if (!file_str) file_str = "miss\thits\tbody\thead\tkills\n";
	file_write(filename, file_str + str + "\n");
}

function Actions::SheduleFinish(time) {
	for (local t = 30; t < time; t += 30)
	_delayed_calls.push(delayed_call( @()say_chat(t + " seconds elapsed"), t));
	_delayed_calls.push(delayed_call(function() {
		say_chat("training finished");
		finish(false);
	}, time));
}

//params: aside_scale, aside_to_backwards_scale, backwards_scale, aside_change_chance, backwards_chance, max_aside, aside_change_min_delay
function Actions::StrafeInit(ent, table) {
	ent.ValidateScriptScope();
	local ent_scope = ent.GetScriptScope();
	if (-table.max_aside == 2 && RandomInt(0, 2) != 0) {
		if (RandomInt(0, 1) == 0) ent_scope.strafe_speed_aside <- -2;
		else ent_scope.strafe_speed_aside <- 2;
	} else {
		ent_scope.strafe_speed_aside <- RandomInt(-table.max_aside, table.max_aside);
	}
	ent_scope.strafe_backwards <- 0;
	ent_scope.strafe_backwards_timer <- 0;
	ent_scope.aside_change_time <- Time() - table.aside_change_min_delay / 2;
}

//params: aside_scale, aside_to_backwards_scale, backwards_scale, aside_change_chance, backwards_chance, max_aside, aside_change_min_delay
function Actions::DoStrafeTick(ent, table, target_pos = null, forced = null) { //supposed to be called every 0.1 second
	local ent_scope = ent.GetScriptScope();
	local ent_vel = ent.GetVelocity();
	local vel = ent_vel;
	if (fabs(vel.x) < 1 && fabs(vel.y) < 1) return;
	vel.z = 0;
	local vel_perp = Vector(-vel.y, vel.x, 0);
	vel_perp = vel_perp.Scale(-1.0/vel_perp.Length());
	local vel_back = vel.Scale(-1.0/vel.Length());
	local basevelocity = 
		vel_perp.Scale(ent_scope.strafe_speed_aside * table.aside_scale) //aside velocity
		+ vel_back.Scale(ent_scope.strafe_backwards * table.backwards_scale + fabs(ent_scope.strafe_speed_aside) * table.aside_to_backwards_scale); //backwards velocity
	if (!target_pos || !forced) {
		NetProps.SetPropVector(ent, "m_vecBaseVelocity", basevelocity);
	} else {
		local next_velocity = ent_vel + basevelocity;
		local next_speed = next_velocity.Length();
		local desired_velocity = normalize(target_pos - ent.GetOrigin()).Scale(next_speed);
		local velocity_correction = (desired_velocity - next_velocity).Scale(1.0 / 5);
		local next_velocity2 = normalize(next_velocity + velocity_correction).Scale(next_speed);
		local new_basevelocity = next_velocity2 - ent_vel;
		NetProps.SetPropVector(ent, "m_vecBaseVelocity", new_basevelocity);
	}
	
	local desired_direction = 0;
	local desired_direction_forced = false;
	if (target_pos) {
		local yaw_currrent = vector_to_angle(vel).Yaw();
		local yaw_target = vector_to_angle(target_pos - ent.GetOrigin()).Yaw();
		local yaw_diff = yaw_target - yaw_currrent;
		if (fabs(yaw_diff) > 180) {
			target_pos = null;
		} else {
			if (yaw_diff > 10) desired_direction = -1;
			else if (yaw_diff < -10) desired_direction = 1;
			if (fabs(yaw_diff) > 40) desired_direction_forced = true;
		}
	}
	
	local draw_box = function() {
		//DebugDrawBoxDirection(ent.GetOrigin(), Vector(-4,-4,-4), Vector(4,4,4), Vector(1,0,0), Vector(128, 0, 255), 255, 2);
	}
	if (target_pos) {
		if (RandomInt(1, 100) <= table.aside_change_chance && (Time() - ent_scope.aside_change_time > table.aside_change_min_delay)) {
			log("strafe aside change"); draw_box();
			ent_scope.aside_change_time = Time();
			if (desired_direction == 1) {
				ent_scope.strafe_speed_aside = RandomInt(1, table.max_aside);
			} else if (desired_direction == -1) {
				ent_scope.strafe_speed_aside = RandomInt(-1, -table.max_aside);
			} else {
				if ((target_pos - ent.GetOrigin()).Length() > 400) ent_scope.strafe_speed_aside = RandomInt(-1, 1);
			}
		} else if (desired_direction_forced && (Time() - ent_scope.aside_change_time > table.aside_change_min_delay / 2)) {
			log("strafe aside change"); draw_box();
			ent_scope.aside_change_time = Time();
			if (desired_direction == 1) {
				ent_scope.strafe_speed_aside = RandomInt(2, table.max_aside);
			} else if (desired_direction == -1) {
				ent_scope.strafe_speed_aside = RandomInt(-2, -table.max_aside);
			}
		}
	} else {
		if (RandomInt(1, 100) <= table.aside_change_chance && (Time() - ent_scope.aside_change_time > table.aside_change_min_delay)) {
			log("strafe aside change"); draw_box();
			ent_scope.aside_change_time = Time();
			if (table.max_aside == 2 && RandomInt(1, 10) > 2 && ent_scope.strafe_speed_aside == -2) {
				ent_scope.strafe_speed_aside = 2;
			} else if (table.max_aside == 2 && RandomInt(1, 10) > 2 && ent_scope.strafe_speed_aside == 2) {
				ent_scope.strafe_speed_aside = -2;
			} else if (table.max_aside == 2 && RandomInt(1, 10) > 5) {
				ent_scope.strafe_speed_aside += 3;
				if (ent_scope.strafe_speed_aside > 2) ent_scope.strafe_speed_aside -= 4;
			} else {
				ent_scope.strafe_speed_aside = RandomInt(-table.max_aside, table.max_aside);
			}
		}
	}
	if (ent_scope.strafe_speed_aside != 0) {
		ent_scope.strafe_backwards = 0;
	} else {
		if (ent_scope.strafe_backwards_timer == 0) {
			if (ent_scope.strafe_backwards != 0) {
				ent_scope.strafe_backwards = 0;
			} else if (RandomInt(1, 100) <= table.backwards_chance) {
				ent_scope.strafe_backwards = 1;
				ent_scope.strafe_backwards_timer = RandomInt(1, 3);
			}
		} else {
			ent_scope.strafe_backwards_timer -= 1;
		}
	}
}

function Actions::GiveWeapon(player, weapon_name, laser_sight) {
	local inv_table = {}; GetInvTable(player, inv_table); if ("slot0" in inv_table) inv_table.slot0.Kill();
	delayed_call(function() {
		player.GiveItem(weapon_name);
		if (laser_sight) player.GiveUpgrade(UPGRADE_LASER_SIGHT);
	}, 0);
}

/*
when we are in point A, random bounds are [a_rndMin, a_rndMax]
when we are in point B, random bounds are [b_rndMin, b_rndMax]
let this bounds change linearly when we move from A to B
we calculate fraction based on a_val, cur_val and b_val and get random bounds
then we get random value between these bounds and return it
*/
function Actions::SlidingRandom(a_rndMin, a_rndMax, b_rndMin, b_rndMax, a_val, b_val, cur_val) {
	local fraction = (cur_val - a_val) / (b_val - a_val);
	local cur_rndMin = a_rndMin + (b_rndMin - a_rndMin) * fraction;
	local cur_rndMax = a_rndMax + (b_rndMax - a_rndMax) * fraction;
	return RandomFloat(cur_rndMin, cur_rndMax);
}

function Actions::LaunchJustSpawnedEntity(ent, pitch, yaw, speed, spawn_pos, func_after_launch = null) {
	NetProps.SetPropInt(ent, "m_nRenderMode", RENDER_NONE);
	NetProps.SetPropInt(ent, "movetype", MOVETYPE_NONE);
	set_entity_flag(ent, FL_ONGROUND, false);
	teleport_entity(ent, spawn_pos, null); //because zspawn tries to spawn on ground
	local velocity = QAngle(pitch, yaw, 0).Forward().Scale(speed);
	//we need delay more than ~0.25 sec + cl_interp, otherwise entity interpolation will disrupt visible movement of target
	_delayed_calls.push(delayed_call(function() {
		NetProps.SetPropInt(ent, "movetype", MOVETYPE_FLYGRAVITY);
		NetProps.SetPropVector(ent, "m_vecBaseVelocity", velocity);
		func_after_launch();
	}, 0.25));
	_delayed_calls.push(delayed_call(function() {
		NetProps.SetPropInt(ent, "m_nRenderMode", RENDER_NORMAL);
	}, 0.3));
}