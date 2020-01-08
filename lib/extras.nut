/*
 * This file is not included in library by default.
 * Contains different functions. Requires kapkan/lib/lib.
 */

/////////////////
// Aimbot test
/////////////////


move_crosshair <- function(player, desired_angles, total_frames, fixed_fraction = 0, angle_tolerance = 0, on_finish = null) {
	if (on_finish) on_finish = on_finish.bindenv(this)
	register_ticker(entstr(player) + "__move_croshair", player, function() {
		if (player.IsDying() || player.IsDead()) return false
		local current_frame = loop_info.total_calls //1 for first call, "total_frames" is the last frame
		//frames left including this one: total_frames - current_frame + 1
		local current_angles = player.EyeAngles()
		local current_pitch = current_angles.Pitch()
		local current_yaw = current_angles.Yaw()
		local _desired_angles = desired_angles
		if (typeof desired_angles == "function") _desired_angles = desired_angles()
		if (_desired_angles == false) return false
		local desired_pitch = _desired_angles.Pitch()
		local desired_yaw = _desired_angles.Yaw()
		local _angle_tolerance = angle_tolerance
		if (typeof angle_tolerance == "function") _angle_tolerance = angle_tolerance()
		local finish_now = angle_between_vectors(current_angles.Forward(), _desired_angles.Forward()) < _angle_tolerance
		if (current_frame > total_frames || finish_now) {
			if (on_finish) run_this_tick(on_finish)
			return false
		}
		local fraction = fixed_fraction ? fixed_fraction : 1.0 / (total_frames - current_frame + 1)
		local new_pitch = current_pitch + (desired_pitch - current_pitch) * fraction
		local new_yaw = current_yaw + (desired_yaw - current_yaw) * fraction
		local new_angles = QAngle(new_pitch, new_yaw, 0)
		teleport_entity(player, null, new_angles)
	})
}

shoot_player <- function(attacker, victim, delay_in_frames, angle_tolerance = 0, headshot = true) {
	if (invalid(victim)) return
	move_crosshair(
		attacker,
		function() {
			if (invalid(victim)) return false
			local aim_point = victim.GetOrigin() + Vector(0,0,30) // todo head
			local vec_delta = aim_point - attacker.EyePosition()
			return vector_to_angle(vec_delta)
		},
		delay_in_frames, //total_frames
		0, //fixed_fraction
		angle_tolerance, //angle_tolerance
		function() {
			force_player_button(attacker, IN_ATTACK)
			run_next_tick( @()force_player_button(attacker, IN_ATTACK, false) )
		}
	)
}

find_nearest_infected_target <- function(player, origin_delta = Vector(0, 0, 30)) {
	local eyes = player.EyePosition()
	local angles = player.EyeAngles().Forward()
	local nearest_target = null
	local smallest_angle_delta = 0
	foreach (target in players(Teams.INFECTED)) {
		if (target.IsDead() || target.IsDying()) continue
		local angle_delta = angle_between_vectors(angles, target.GetOrigin() + origin_delta - eyes)
		if (nearest_target == null || angle_delta < smallest_angle_delta) {
			smallest_angle_delta = angle_delta
			nearest_target = target
		}
	}
	return {
		target = nearest_target
		angle_delta = smallest_angle_delta
	}
}

do_autoaim_shot <- function(player) {
	local target = find_nearest_infected_target(player).target
	if (!target) return
	log("target is", player_to_str(target))
	shoot_player(player, target, 5, function() {
		local dist = (target.GetOrigin() - player.GetOrigin()).Length()
		return 300 / dist
	})
}