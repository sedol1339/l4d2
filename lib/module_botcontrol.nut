//---------- DOCUMENTATION ----------

/**
FUNCTIONS FOR CONTROLLING BOTS
! requires lib/module_base !
! requires lib/module_convars !
! requires lib/module_entities !
! requires lib/module_tasks !
------------------------------------
custom_airstrafe
	This table contains functions allow to simulate air-strafing with movement buttons. It will not do anything until player leaves the ground. These functions work for bots and human players.
	IMPORTANT: these functions does not send any console commands or affect any netprops/offsets. They use fake button mask that is stored in player's script scope, and correct player's velocity every game frame based on fake buttons. This functions use custom movement code, based on AirMove() function in gamemovement.cpp from Source SDK. However, 100% accuracy is not achieved.
custom_airstrafe.start(player)
	Start a ticker that corrects player's velocity based on feke kays.
custom_airstrafe.stop(player)
	Stops a ticker.
custom_airstrafe.press_key(player, key)
custom_airstrafe.release_key(player, key)
custom_airstrafe.set_keys(player, keys)
	These functions set fake keys for player. Should be used between custom_airstrafe.start() and custom_airstrafe.stop().
------------------------------------
mousemove(player, angle_delta, duration)
	Move mouse for a given duration. Example: send QAngle(0, -90, 0) to turn player or bot 90 degrees right.
------------------------------------
spawn_and_launch_infected(type, pos, ang, speed, on_launch = null, on_appearance = null)
	(Not implemented) Spawns special infected of specified type in given position and turned into given angle, then launches it
------------------------------------
autofire_start(player)
autofire_stop(player)
	Starts and stops spamming attack button. This works for human players and bots.
------------------------------------
duck(player, instant = true)
	Forces human player or bor to duck. If instant == true, skips ducking animation.
duck_off(player)
	Stops forcing player to duck.
------------------------------------
motion_capture.start_recording(player)
	Start recording player movement. Continuously prints recorded motion to console.
motion_capture.stop_recording(player)
	Stop recording player movement. Returns object that represents captured motion and contains fields "start_origin", "start_velocity", "frames".
motion_capture.save(captured_motion, filename)
	(Not implemented) Saves captured motion object to file. If cannot write to single file, writes to multiple files (<filename>.part2 etc.)
motion_capture.load(filename)
	(Not implemented) Loads captured motion object from file. Returns captured motion object. Recognizes multiple files (<filename>.part2 etc.)
motion_capture.play(player, captured_motion, start_from_recorded_origin = false)
	Plays captured motion object on given player (human player or bot).
	IMPORTANT: Currently supports only air movement, like hunter's jumps, using custom_airstrafe.* and mousemove() functions. Toggles m_afButtonForced / m_afButtonDisabled for all buttons except WASD. If start_from_recorded_origin == true, player will be teleported to it's recorded origin when motion play starts.
	IMPORTANT: Motion is 100% accurate when is made without air-strafing (WASD). With air-strafing motion replay will be slightly inaccurate.
	IMPORTANT: Behavoiur of record/play functions is designed to not depend on tickrate, but who knows?
	IMPORTANT: If using play() for hunter bot that repeats after human player, be sure that cvar "z_lunge_up" equals "z_player_lunge_up".
------------------------------------
Example of using functions from this module to control hunter bot (map c8m3_sewers):
	//SendToConsole("jointeam 1; setpos_exact 13045.959961 12634.959961 5939.174805; setang_exact 7.846015 119.232750 0.000000")
	IncludeScript("kapkan/lib/lib")
	cvar("z_lunge_power", 600)	
	foreach(player in players()) if (IsPlayerABot(player)) player.Kill()
	hunter <- spawn_infected(ZOMBIE_HUNTER, Vector(12876.355469, 13997.511719, 5624.031250))
	propint(hunter, "m_afButtonForced", IN_DUCK)
	custom_airstrafe.start(hunter)
	delayed_call(hunter, 1, function() {
		teleport_entity(hunter, null, QAngle(-80, -90, 0)) //look up
		delayed_call(hunter, 0.1, function() {
			teleport_entity(hunter, null, QAngle(11.55, -90, 0)) //look forward
		})
		autofire_start(hunter)
		custom_airstrafe.press_key(hunter, IN_BACK)
		delayed_call(hunter, 1, @() mousemove(hunter, QAngle(0, -50, 0), 0.6) )
		delayed_call(hunter, 1.6, @() mousemove(hunter, QAngle(0, 150, 0), 1) )
		delayed_call(hunter, 2.6, @() mousemove(hunter, QAngle(0, -200, 0), 1) )
		delayed_call(hunter, 5.4, @() mousemove(hunter, QAngle(0, -170, 0), 1) )
		delayed_call(hunter, 7.8, function() {
			say_chat("jumping down")
			mousemove(hunter, QAngle(30, 0, 0), 0.1)
			custom_airstrafe.release_key(hunter, IN_BACK)
			delayed_call(hunter, 0.1, function() {
				mousemove(hunter, QAngle(0, -50, 0), 3)
				custom_airstrafe.press_key(hunter, IN_MOVERIGHT)
			})
		})
	})
 */

//---------- CODE ----------

log("[lib] including module_botcontrol")

custom_airstrafe <- {
	
	sv_airaccelerate = cvarf("sv_airaccelerate")
	fsmove_max = 450.0
	AirSpeedCap = 30.0
	accel_multiplier = 7.3
	
	press_key = function(player, key) {
		scope(player).fake_buttons = player_scope.fake_buttons | key
	}
	
	release_key = function(player, key) {
		scope(player).fake_buttons = player_scope.fake_buttons & ~key
	}
	
	set_keys = function(player, keys) {
		scope(player).fake_buttons = keys
	}
	
	get_keys = function(player) {
		return scope(player).fake_buttons
	}
	
	start = function(player) {
		local player_scope = scope(player)
		player_scope.fake_buttons <- 0
		register_ticker(entstr(player) + "_airstrafe", player, function() {
			custom_airstrafe.__do_airmove(player_scope)
		})
	}
	
	//stops airstrafes code, removes data from player scope
	stop = function(player) {
		local player_scope = scope(player)
		if ("fake_buttons" in player_scope) delete player_scope.fake_buttons
		remove_ticker(entstr(player) + "_airstrafe")
	}
	
	__do_airmove = function(player_scope) {
		local strafe_ent = player_scope.self
		//logf("doing airmove for %s, pos = %s, fake_buttons = %d", 
		//	var_to_str(strafe_ent), var_to_str(strafe_ent.GetOrigin()), player_scope.fake_buttons)
		if (propent(strafe_ent, "m_hGroundEntity")) return
		local buttons = player_scope.fake_buttons
		local w = buttons & IN_FORWARD
		local s = buttons & IN_BACK
		local a = buttons & IN_MOVELEFT
		local d = buttons & IN_MOVERIGHT
		local fmove = 0.0
		local smove = 0.0
		if (w && !s) fmove = fsmove_max
		if (s && !w) fmove = -fsmove_max
		if (d && !a) smove = -fsmove_max
		if (a && !d) smove = fsmove_max
		if (fmove == 0.0 && smove == 0.0) return
		
		//local viewangles = strafe_ent.EyeAngles()
		//local viewangles = ::_viewangle
		local viewangles = ("future_viewangles" in player_scope) ? player_scope.future_viewangles : strafe_ent.EyeAngles()
		local velocity = strafe_ent.GetVelocity()
		local forward = viewangles.Forward()
		local right = viewangles.Left().Scale(-1)
		forward.z = 0; forward = normalize(forward)
		right.z = 0; right = normalize(right)
		
		local wishvel = Vector(forward.x * fmove + right.x * smove, forward.y * fmove + right.y * smove, 0)
		local wishspeed = wishvel.Length()
		local wishdir = wishvel.Scale(1/wishspeed)
		wishspeed = min(wishspeed, AirSpeedCap)
		local currentspeed = velocity.Dot(wishdir)
		local addspeed = wishspeed - currentspeed
		
		if (addspeed <= 0) return
		local dt = clock.tick_time
		local velocity_to_analyze = ("old_velocity" in player_scope) ? player_scope.old_velocity : velocity
		local accelspeed
		if (velocity_to_analyze.z > 0 && velocity_to_analyze.z < 100) {
			accelspeed = min(addspeed, sv_airaccelerate * wishspeed * dt * accel_multiplier / 4)
			//log("dividing by 4, result is " + accelspeed)
		} else {
			accelspeed = min(addspeed, sv_airaccelerate * wishspeed * dt * accel_multiplier)
		}
		local push_vel = wishdir.Scale(accelspeed)
		velocity_impulse(strafe_ent, push_vel)
		player_scope.old_velocity <- velocity
	}
	
}

mousemove <- function(player, angle_delta, duration){
	local start_time = Time()
	local total_ticks = duration.tofloat() / clock.tick_time
	local angle_delta_per_tick = QAngle(
		angle_delta.Pitch() / total_ticks,
		angle_delta.Yaw() / total_ticks,
		angle_delta.Roll() / total_ticks
	)	
	register_ticker(entstr(player) + "_mousemove", player, function() {
		if (Time() > start_time + duration) return false
		local viewangles = player.EyeAngles()
		local new_angles = QAngle(
			//89 is a limit for player's view angles
			max(-89, min(89, viewangles.Pitch() + angle_delta_per_tick.Pitch())),
			viewangles.Yaw() + angle_delta_per_tick.Yaw(),
			viewangles.Roll() + angle_delta_per_tick.Roll()
		)
		teleport_entity(player, null, new_angles)
	})
}

autofire_start <- function(player) {
	register_ticker(entstr(player) + "_autofire", player, function() {
		if (propint(player, "m_afButtonDisabled") & IN_ATTACK) {
			propint(player, "m_afButtonDisabled", propint(player, "m_afButtonDisabled") &~ IN_ATTACK)
			propint(player, "m_afButtonForced", propint(player, "m_afButtonForced") | IN_ATTACK)
		} else {
			propint(player, "m_afButtonDisabled", propint(player, "m_afButtonDisabled") | IN_ATTACK)
			propint(player, "m_afButtonForced", propint(player, "m_afButtonForced") &~ IN_ATTACK)
		}
	})
}

autofire_stop <- function(player) {
	remove_ticker(entstr(player) + "_autofire")
	propint(player, "m_afButtonDisabled", propint(player, "m_afButtonDisabled") &~ IN_ATTACK)
	propint(player, "m_afButtonForced", propint(player, "m_afButtonForced") &~ IN_ATTACK)
}

duck <- function(player, instant = true) {
	propint(player, "m_afButtonForced", propint(player, "m_afButtonForced") | IN_DUCK)
	if (instant) {
		propint(player, "m_Local.m_bDucking", 1)
		propint(player, "m_Local.m_bDucked", 1)
	}
}

duck_off <- function(player) {
	propint(player, "m_afButtonForced", propint(player, "m_afButtonForced") & ~IN_DUCK)
}

motion_capture <- {

	__current_recordings = {}

	start_recording = function(player) {
		if (player in motion_capture.__current_recordings) throw "recording for this player is already active"
		local start_time = Time()
		local recording_table = {
			recorded_data = {
				start_origin = player.GetOrigin()
				start_velocity = player.GetVelocity()
				frames = []
			}
		}
		local frames = recording_table.recorded_data.frames
		motion_capture.__current_recordings[player] <- recording_table
		register_ticker(entstr(player) + "_motion_capture", function() {
			frames.append([
				Time() - start_time
				propint(player, "m_nButtons")
				player.EyeAngles().Forward()
				player.GetVelocity()
			])
		})
	}
	
	stop_recording = function(player) {
		if (!(player in motion_capture.__current_recordings)) throw "recording for this player is not active"
		local result = motion_capture.__current_recordings[player].recorded_data
		delete motion_capture.__current_recordings[player]
		remove_ticker(entstr(player) + "_motion_capture")
		return result
	}
	
	save = function(filename) {
		
	}
	
	load = function(filename) {
		
	}
	
	//warning: z_lunge_up, z_player_lunge_up
	play = function(player, captured_motion, start_from_recorded_origin = false) {
		if (start_from_recorded_origin) player.SetOrigin(captured_motion.start_origin)
		player.SetVelocity(captured_motion.start_velocity)
		local saved_flags = player.GetSenseFlags()
		player.SetSenseFlags(-1)
		local frames = captured_motion.frames
		local total_frames = frames.len()
		local index = 0
		local time_tolerance = 0.001
		local start_time = Time()
		local buttons_to_process = [IN_ATTACK, IN_ATTACK2, IN_DUCK, IN_SPEED, IN_JUMP]
		custom_airstrafe.start(player)
		register_ticker(entstr(player) + "_motion_play", player, function() {
			local cancel = function() {
				custom_airstrafe.stop(player)
				log("motion play finished for " + ent_to_str(player))
				player.SetSenseFlags(saved_flags)
				propint(player, "m_afButtonDisabled", 0)
				propint(player, "m_afButtonForced", 0)
			}
			if (player.IsDying()) { cancel(); return false }
			local time = Time() - start_time
			local new_index
			for(new_index = index; ; new_index++) {
				if (new_index >= total_frames) { cancel(); return false }
				if (frames[new_index][0] > time + time_tolerance) break
			}
			if (new_index == 0) return
			local frame_to_apply = frames[new_index - 1]
			local next_frame = (new_index > 1) ? frames[new_index] : frames[new_index - 1]
			local buttons = frame_to_apply[1]
			local strafe_buttons = next_frame[1]
			local prev_buttons = custom_airstrafe.get_keys(player)
			custom_airstrafe.set_keys(player, strafe_buttons)
			foreach(button in buttons_to_process) {
				local pressed_prev = prev_buttons & button
				local pressed = buttons & button
				if (pressed_prev && !pressed) {
					//release
					propint(player, "m_afButtonDisabled", propint(player, "m_afButtonDisabled") | button)
					propint(player, "m_afButtonForced", propint(player, "m_afButtonForced") &~ button)
				} else if (!pressed_prev && pressed) {
					//press
					propint(player, "m_afButtonDisabled", propint(player, "m_afButtonDisabled") &~ button)
					propint(player, "m_afButtonForced", propint(player, "m_afButtonForced") | button)
				}
			}
			player.SetForwardVector(frame_to_apply[2])
			scope(player).future_viewangles <- vector_to_angle(next_frame[2])
			//log(player.GetOrigin() + " forward: " + player.GetForwardVector() + " buttons: " + buttons)
		})
	}
	
}