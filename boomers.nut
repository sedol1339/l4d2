boomers <- function(level) { //0 = easy, 1 = normal, 2 = hard
	return {
		strafe_params = {
			aside_scale = 90,
			aside_to_backwards_scale = 10,
			backwards_scale = 20,
			aside_change_chance = 20,
			backwards_chance = 30,
			max_aside = level,
			aside_change_min_delay = 0.8,
		},
		do_remove_and_spawn = Spawners.SimpleTargets({
			zombie_type = ZOMBIE_BOOMER,
			x_min = 1000, x_max = 1000,
			y_min = -100, y_max = 100,
			z_min = 150, z_max = 850,
			angle = null,
			amount = 2,
			respawn_only_killed = false,
			frozen = true,
			static_target = true,
			on_spawn = function(ent) {
				ent.GetScriptScope().was_launched <- false;
				local spawn_pos = ent.GetScriptScope().spawn_pos;
				local pitch = Actions.SlidingRandom(-60, -30, 10, 40, z_min, z_max, spawn_pos.z);
				local yaw = 180 + RandomFloat(-45, 45);
				local speed = RandomFloat(800, 1000);
				Actions.LaunchJustSpawnedEntity(ent, pitch, yaw, speed, spawn_pos, function() {
					Actions.StrafeInit(ent, strafe_params);
					register_task_on_entity(ent, @()Actions.DoStrafeTick(ent, strafe_params), 0.1);
					ent.GetScriptScope().was_launched <- true;
				});
			}
		}),
		jump = function(target) {
			local vel = target.GetScriptScope().last_vel;
			NetProps.SetPropVector(target, "m_vecBaseVelocity", Vector(vel.x / 3, vel.y / 3, 600));
			//playsound("level/loud/bell_break.wav", target);
			local particles = SpawnEntityFromTable("info_particle_system", {
				effect_name = "mini_fireworks",
				origin = target.GetOrigin() + Vector(0, 0, -20)
			})
			DoEntFire("!self", "Start", "", 0, null, particles);
			DoEntFire("!self", "Kill", "", 6, null, particles);
		},
		on_tick_foreach = function(index, target) {
			if ((NetProps.GetPropInt(target, "m_fFlags") & FL_ONGROUND) && target.GetScriptScope().was_launched) {
				remove_task_on_entity(target);
				jump(target);
			} else {
				target.GetScriptScope().last_vel <- target.GetVelocity();
			}
		},
		timer_params = {
			refire_delay = 2.5,
			refire_on_shot = false,
			refire_on_kill = false,
			refire_on_event_delay = 0,
			initial_delay = 1,
		},
		on_start = function() {
			Actions.SheduleFinish(120);
			Actions.GiveWeapon(player(), "sniper_awp", true);
			teleport_entity(player(), Vector(0, 0, 0), QAngle(0, 0, 0));
			cvar("cl_interp", 0);
			cvar("cl_interp_ratio", 0);
			cvar("sv_client_min_interp_ratio", 0);
			cvar("mat_postprocess_enable", 0); //adrenaline & vomit
		},
		on_finish = function(was_interrupted) {
			Actions.RemoveAllTargets();
			cvar("sv_client_min_interp_ratio", 1);
			cvar("mat_postprocess_enable", 1);
			remove_all_tasks_on_entities() //to prevent memory leaks
			if (!was_interrupted) {
				Actions.PrintHitsAndShots();
				Actions.SaveHitsAndShots("tr.txt");
			}
		},
	}
}