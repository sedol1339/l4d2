Convars.SetValue("fps_max", 120);

IncludeScript("tr/lib", getroottable());
IncludeScript("tr/ext", getroottable());

remove_all_tickers();
remove_all_callbacks();
SendToConsole("alias redloop");

// settings

cvar("god", 1);
cvar("mp_gamemode", "coop");
cvar("z_discard_range", 10e6);
cvar("sb_stop", 1);
stop_director();
cvar("z_jockey_speed", 350);
cvar("z_jockey_leap_time", 0);
cvar("z_leap_interval", 0);
cvar("z_charge_interval", 2);
cvar("z_charge_duration", 10);
cvar("nb_update_frequency", 0);
cvar("z_lunge_interval", 0);
cvar("z_lunge_cooldown", 0);
cvar("z_spitter_range", 2000);
//cvar("boomer_leaker_chance", 100);
cvar("z_exploding_splat", 1000);
cvar("smoker_tongue_delay", 0.6);
cvar("tongue_miss_delay", 1);
cvar("tongue_hit_delay", 1);
cvar("tongue_range", 1000);
no_SI_with_death_cams();

// actions

run_next_tick( @()player().GiveItem("sniper_awp"));

if (!("target_bot" in getroottable())) ::target_bot <- null;
target_bot_pos <- Vector(0, 0, -8000);

for_each_player( function(player) {
	if (IsPlayerABot(player) && player.IsSurvivor()) {
		if (!target_bot) {
			target_bot = player;
			target_bot.SetOrigin(target_bot_pos);
			target_bot.GetActiveWeapon().Kill();
			NetProps.SetPropInt(target_bot, "m_bSurvivorGlowEnabled", 0)
			NetProps.SetPropInt(target_bot, "movetype", 0);
			NetProps.SetPropInt(target_bot, "m_nRenderMode", 10); //RENDER_NONE
			NetProps.SetPropInt(target_bot, "m_fadeMaxDist", 0);
			NetProps.SetPropInt(target_bot, "m_CollisionGroup", 1);  //COLLISION_GROUP_DEBRIS, after this SI can't catch bot
		} else if (player != target_bot) {
			player.Kill();
		}
	}
});

// game logic

local names = ["hunter", "jockey", "charger", "boomer", "smoker", "spitter"];

register_loop("spawner", function() {
	SendToServerConsole("z_spawn_old " + names[RandomInt(0, names.len() - 1)] + " auto");
}, 2);

register_loop("remove_commons", function() {
	local ent = null;
	while (ent = Entities.FindByClassname(ent, "infected")) {
		ent.Kill();
	}
}, 0.1);

shots <- 0;
hits <- 0;

register_callback("weapon_fire", "fire", function(params) {
		local attacker = GetPlayerFromUserID(params.userid);
		if (IsPlayerABot(attacker) || !attacker.IsSurvivor()) return;
		if (params.weapon != "sniper_awp") return;
		shots++;
		log(format("accuracy %f", 100.0 * hits / shots));
});

register_callback("player_hurt", "shot", function(params) {
		if (params.attacker == params.userid) return;
		local attacker = GetPlayerFromUserID(params.attacker);
		if (!attacker || deleted_ent(attacker)) return;
		if (IsPlayerABot(attacker) || !attacker.IsSurvivor()) return;
		local victim = GetPlayerFromUserID(params.userid);
		if (params.weapon != "sniper_awp") return;
		
		kill_player(victim);
		change_score("kill", 1);
		hits++;
});

clear_area <- function(ignored = null) {
	for_each_player( function(infected) {
		if (!deleted_ent(infected) && IsPlayerABot(infected) && !infected.IsSurvivor() && infected != ignored) {
			local dist = (infected.GetOrigin() - player().GetOrigin()).Length();
			if (dist < 600) kill_player(infected);
		}
	});
	NetProps.SetPropFloat(player(), "m_itTimer.m_timestamp", Time());
}

//hud

__free_slots <- [true, true, true, true, true, true, true, true, true, true];

hud_table <- {
	Fields = {}
}

HUDSetLayout(hud_table);

register_ticker("hud", function() {
	if (hud_table.Fields.len() > 0)
		HUDSetLayout(hud_table);
});

print_hud <- function(str) {
	for(local i = 0; i < __free_slots.len(); i++) {
		if (__free_slots[i] == true) {
			__free_slots[i] = false;
			local slot = i + 1;
			hud_table.Fields[slot] <- {
				slot = slot,
				dataval = str,
				flags = 256 | 64
			}
			local key = UniqueString("hud");
			local time = Time();
			register_ticker(key, function() {
				HUDPlace(slot, 0.45, 0.55 - 0.1*(Time() - time), 1, 0.1);
				if (Time() - time > 1) {
					delete hud_table.Fields[slot];
					__free_slots[slot - 1] = true;
					remove_ticker(key);
				}
			});
			return;
		}
	}
	log("cannot find free hud slot for message " + str);
}

score <- 0;

change_score <- function(message, val) {
	score += val;
	print_hud(format("%s %s (%d)", message, (val > 0 ? "+" + val : val.tostring()), score));
}

// jockey

register_callback("player_spawn", "jockey_autojump", function(params) {
	local player = GetPlayerFromUserID(params.userid);
	if (player.GetZombieType() == 5) {
		player.ValidateScriptScope();
		player.GetScriptScope().jump_random_intervals <- function() {
			force_player_button(self, 1); //IN_ATTACK
			//local viewangle = self.EyeAngles().Yaw();
			//target_bot.SetOrigin(self.GetOrigin() + QAngle(0, RandomFloat(viewangle - 45, viewangle + 45), 0).Forward().Scale(150));
			delayed_call( function() {
				if("self" in this) force_player_button(self, 1, false);
				//target_bot.SetOrigin(target_bot_pos);
			}, 0.3, this);
			return RandomFloat(0.3, RandomFloat(0.3, 2));
		}
		delayed_call( @()AddThinkToEnt(player, "jump_random_intervals"), 0.5, this);
	}
});

register_callback("jockey_ride", "kill_jockey", function(params) {
	local jockey = GetPlayerFromUserID(params.userid);
	local effect = create_particles("achieved", jockey.GetOrigin(), 6);
	playsound("level/loud/bell_break.wav", player());
	SendToConsole("cam_command 1");
	/*local view = SpawnEntityFromTable("point_viewcontrol", {
		acceleration = 99999,
		targetattachment = "eyes",
		spawnflags = 32 | 8 | 2 | 16
	});
	view.SetOrigin(player().EyePosition() + Vector(0, -200, 200));
	local key = UniqueString();
	DoEntFire("!self", "AddOutput", "targetname " + key, 0, null, player());
	DoEntFire("!self", "AddOutput", "target " + key, 0, null, view);
	DoEntFire("!self", "Enable", "", 0.1, player(), view);*/
	delayed_call( function(){
		if (!deleted_ent(jockey)) {
			kill_player(jockey);
			clear_area();
		}
		//DoEntFire("!self", "Disable", "", 0, player(), view);
		//DoEntFire("!self", "Kill", "", 1, null, view);
		SendToConsole("red");
		SendToConsole("cam_command 2");
	}, 1.7);
	change_score("jockeyed", -2);
});

// spitter

register_callback("ability_use", "spitter_spit_chase", function(params) {
	if (params.ability != "ability_spit") return;
	local spitter = GetPlayerFromUserID(params.userid);
	spitter.ValidateScriptScope();
	if ("done" in spitter.GetScriptScope()) return;
	spitter.GetScriptScope().done <- true;
	delayed_call( function() {
		kill_player(spitter);
		local projectile_iter = null;
		local projectile = null;
		while (projectile_iter = Entities.FindByClassname(projectile_iter, "spitter_projectile")) {
			projectile_iter.ValidateScriptScope();
			if (!("controlled" in projectile_iter.GetScriptScope())) {
				projectile = projectile_iter;
				break;
			}
		}
		if (!projectile) throw "cannot find spitter projectile";
		projectile.GetScriptScope().controlled <- true;
		DoEntFire("!self", "AddOutput", "rendercolor 255 0 0", 0, null, projectile);
		local key = UniqueString();
		DoEntFire("!self", "AddOutput", "targetname " + key, 0, null, projectile);
		local fire = create_particles("fire_jet_01_smoke", projectile.GetOrigin());
		DoEntFire("!self", "SetParent", key, 0, null, fire);
		local sparks = create_particles("elevatorsparks", projectile.GetOrigin());
		DoEntFire("!self", "SetParent", key, 0, null, sparks);
		local expl = function(pos) {
			local explosion = create_particles("gas_explosion_pump", pos, 6);
			playsound("weapons/hegrenade/explode3.wav", player());
		}
		if (!("__last_pos_spit_proj" in getroottable())) ::__last_pos_spit_proj <- {};
		register_loop(key, function() {
			if (deleted_ent(projectile) || projectile.GetVelocity().Length() < 50) {
				remove_loop(key);
				if (key in __last_pos_spit_proj) {
					expl(__last_pos_spit_proj[key]);
					delete __last_pos_spit_proj[key];
				}
				return;
			}
			local vel = projectile.GetVelocity();
			local player_dist = player().GetOrigin() + Vector(0, 0, 55) - projectile.GetOrigin();
			if (player_dist.Length() < 60) {
				expl(projectile.GetOrigin());
				player().Stagger(projectile.GetOrigin() - normalize(projectile.GetVelocity()).Scale(150));
				::change_score("bombed", -1);
				projectile.Kill();
				fire.Kill();
				remove_loop(key);
				delete __last_pos_spit_proj[key];
				//DropSpit(projectile.GetOrigin());
				return;
			}
			__last_pos_spit_proj[key] <- projectile.GetOrigin();
			local player_direction = normalize(player_dist);
			local desired_vel = player_direction.Scale(vel.Length());
			//local new_vel = vel + (desired_vel - vel).Scale(1.0 / 5);
			//local new_vel = normalize(new_vel).Scale(600);
			//local basevelocity = new_vel - vel;
			local basevelocity = (desired_vel - vel).Scale(1.0 / 3) + vel.Scale(0.03);
			NetProps.SetPropVector(projectile, "m_vecBaseVelocity", basevelocity);
			//NetProps.SetPropInt(projectile, "movetype", 4); //MOVETYPE_FLY
			
			local ang = vector_to_angle(vel.Scale(-1));
			sparks.SetAngles(ang);
			fire.SetAngles(ang);
		}, 0.067);
	}, 0.3);
});

//charger

register_callback("ability_use", "charger_steering", function(params) {
	if (params.ability != "ability_charge") return;		
	local charger = GetPlayerFromUserID(params.userid);
	set_entity_flag(charger, (1 << 5), false);
	charger.ValidateScriptScope();
	charger.GetScriptScope().random_strafes_first_call <- true;
	charger.GetScriptScope().random_strafes <- function() {
		if (random_strafes_first_call) {
			random_strafes_first_call <- false; //skipping first call
			return;
		}
		local viewangle = self.EyeAngles().Yaw();
		target_bot.SetOrigin(self.GetOrigin() + QAngle(0, RandomFloat(viewangle - 15, viewangle + 15), 0).Forward().Scale(400));
		delayed_call( function() {
			target_bot.SetOrigin(target_bot_pos);
		}, RandomFloat(0.5, 2), this);
		return RandomFloat(0.3, 6);
	}
	AddThinkToEnt(charger, "random_strafes");
	local key = UniqueString();
	register_ticker(key, function() {
		if (deleted_ent(charger) || charger.IsDying()) {
			remove_ticker(key);
			return;
		} 
		if (NetProps.GetPropInt(NetProps.GetPropEntity(charger, "m_customAbility"), "m_isCharging") == 0) {
			remove_ticker(key);
			AddThinkToEnt(charger, null);
			return;
		}
		if ((charger.GetOrigin() - target_bot.GetOrigin()).Length() < 100) {
			target_bot.SetOrigin(target_bot_pos);
		}
		if (NetProps.GetPropEntity(charger, "m_carryVictim")) {
			remove_ticker(key);
			set_entity_flag(charger, (1 << 5), true);
			delayed_call( function(){
				if (!deleted_ent(charger) && !charger.IsDying() && NetProps.GetPropInt(NetProps.GetPropEntity(charger, "m_customAbility"), "m_isCharging") != 0)
					NetProps.SetPropFloat(charger, "m_flLaggedMovementValue", 1.2);
			}, 0.1);
			delayed_call( function(){
				if (!deleted_ent(charger) && !charger.IsDying() && NetProps.GetPropInt(NetProps.GetPropEntity(charger, "m_customAbility"), "m_isCharging") != 0)
					NetProps.SetPropFloat(charger, "m_flLaggedMovementValue", 1.5);
			}, 0.2);
			delayed_call( function(){
				if (!deleted_ent(charger) && !charger.IsDying() && NetProps.GetPropInt(NetProps.GetPropEntity(charger, "m_customAbility"), "m_isCharging") != 0)
					NetProps.SetPropFloat(charger, "m_flLaggedMovementValue", 1.9);
			}, 0.3);
			delayed_call( function(){
				if (!deleted_ent(charger) && !charger.IsDying() && NetProps.GetPropInt(NetProps.GetPropEntity(charger, "m_customAbility"), "m_isCharging") != 0)
					NetProps.SetPropFloat(charger, "m_flLaggedMovementValue", 2.5);
			}, 0.4);
			register_ticker(key, function() {
				if(deleted_ent(charger) || charger.IsDying()) {
					remove_ticker(key);
					return;
				}
				if (NetProps.GetPropInt(NetProps.GetPropEntity(charger, "m_customAbility"), "m_isCharging") == 0) {
					playsound("weapons/hegrenade/explode3.wav", player());
					remove_ticker(key);
					local pos = charger.GetOrigin() + charger.EyeAngles().Forward().Scale(50);
					for (local i = 0; i < 3; i++) {
						local explosion = create_particles("boomer_explode_E", pos, 6);
						explosion.SetAngles(QAngle(0, 120*i, 0));
					}
					local explosion2 = create_particles("boomer_explode_F", pos, 6);
					player().UseAdrenaline(0.1);
					return;
				}
			});
		}
	});
});

register_callback("charger_pummel_start", "kill_charger", function(params) {
	local charger = GetPlayerFromUserID(params.userid);
	kill_player(charger);
	clear_area();
	run_next_tick( @()NetProps.SetPropFloat(player(),"serveranimdata.m_flCycle", 0.99) );
	change_score("charged", -2);
});

//hunter

cvar("hunter_pounce_max_loft_angle", 50);
cvar("hunter_pounce_ready_range", 1000);
cvar("z_hunter_lunge_distance", 1000)

register_callback("ability_use", "on_lunge", function(params) {
	if (params.ability != "ability_lunge") return;
	local hunter = GetPlayerFromUserID(params.userid);
	
	/*local vec = hunter.EyeAngles().Forward();
	local aside = normalize(vec.Cross(Vector(0, 0, 1)));
	local basevelocity = aside.Scale(100);
	run_this_tick( @()NetProps.SetPropVector(hunter, "m_vecBaseVelocity", basevelocity) );*/
	
	hunter.ValidateScriptScope();
	hunter.GetScriptScope().last_vel <- Vector(0, 0, 0);
	register_task_on_entity(hunter, function() {
		last_vel <- self.GetVelocity();
	}, 0.67);
	
	local loft_rate = 0;
	switch (RandomInt(0, 8)) {
		case 0: case 1: case 2: case 3: loft_rate = 0.035; break;
		case 4:	loft_rate = 0.02; break;
		case 5: loft_rate = 0.0; break;
		case 6: loft_rate = 0.05; break;
		case 7: loft_rate = 0.075; break;
		case 8: loft_rate = 0.1; break;
	}
	cvar("hunter_pounce_loft_rate", loft_rate);
});

register_callback("lunge_pounce", "kill_hunter", function(params) {
	local hunter = GetPlayerFromUserID(params.userid);
	local victim = GetPlayerFromUserID(params.victim);
	SendToConsole("alias redloop \"red;wait 4;redloop\";redloop");
	delayed_call( function() {
		if (!deleted_ent(hunter) && !hunter.IsDying())
			kill_player(hunter);
			clear_area();
			run_next_tick( @()NetProps.SetPropFloat(player(),"serveranimdata.m_flCycle", 0.99) );
			SendToConsole("alias redloop");
	}, 2);
	change_score("pounced", -2);
	local origin = victim.GetOrigin() + Vector(0, 0, 15);
	local key = UniqueString();
	DoEntFire("!self", "AddOutput", "targetname " + key, 0, null, victim);
	local gore = function(effect_name, duration) {
		local pos = origin + Vector(RandomFloat(-10, 10), RandomFloat(-10, 10), RandomFloat(-10, 10));
		local ang = QAngle(0, RandomFloat(-180, 180), 0);
		local particles = create_particles(effect_name, pos, duration);
		particles.SetAngles(ang);
		DoEntFire("!self", "SetParent", key, 0, null, particles);
		
	}
	delayed_call( @()gore("blood_chainsaw_constant_b", 2.0), 0.1);
	delayed_call( @()gore("gore_wound_fullbody_1", 6), 0.2);
	delayed_call( @()gore("gore_wound_fullbody_2", 6), 0.3);
	delayed_call( @()gore("gore_blood_spurt_generic_2", 6), 0.6);
	delayed_call( @()gore("gore_blood_spurt_generic_2", 6), 0.8);
	delayed_call( @()gore("gore_wound_fullbody_4", 6), 1.2);
	delayed_call( @()gore("gore_blood_spurt_generic_2", 6), 1.6);
	playsound("player/hunter/hit/tackled_1.wav", player());
	
	/*local vel = hunter.GetScriptScope().last_vel.Scale(5);
	vel.z = 1;
	log(vel);
	run_next_tick(function(){
		player().OverrideFriction(0.7, 0);
		NetProps.SetPropVector(player(), "m_vecBaseVelocity", vel);
		NetProps.SetPropInt(player(), "movetype", 2);
		set_entity_flag(player(), 1, 0);
	});*/
});

//boomer

register_callback("player_spawn", "boomer_on_spawn", function(params) {
	local boomer = GetPlayerFromUserID(params.userid);
	if (boomer.GetZombieType() != 2) return;
	boomer.ValidateScriptScope();
	register_task_on_entity(boomer, function() {
		//check conditions for launch
		local trace_between_points = function(point1, point2) {
			local table = trace_line(point1, point2, 147467); //MASK_NPCSOLID_BRUSHONLY
			//DebugDrawLine_vCol(point1, point2, table.hit ? Vector(255, 0, 0) : Vector(0, 255, 0), false, 2);
			return !table.hit;
		}
		local boomer_pos = self.GetOrigin() + Vector(0, 0, 60);
		local player_pos = player().GetOrigin() + Vector(0, 0, 60);
		local boomer_to_player = player_pos - boomer_pos;
		local boomer_to_player_len = boomer_to_player.Length();
		local boomer_to_player_len_hor = boomer_to_player.Length2D();
		local boomer_to_player_len_ver = boomer_to_player.z;
		local normal = normalize(boomer_to_player.Cross(Vector(0, 0, 1)));
		local normal_scaled = normal.Scale(15);
		local air_point_1 = boomer_pos + boomer_to_player.Scale(0.5) + Vector(0, 0, boomer_to_player_len * 0.5);
		local air_point_2 = boomer_pos + boomer_to_player.Scale(0.5) + Vector(0, 0, boomer_to_player_len * 0.3);
		local empty_straight = (
			trace_between_points(boomer_pos + normal_scaled, player_pos + normal_scaled)
			&& trace_between_points(boomer_pos - normal_scaled, player_pos - normal_scaled)
		);
		local empty_up = (
			trace_between_points(boomer_pos + normal_scaled, air_point_2 + normal_scaled)
			&& trace_between_points(boomer_pos - normal_scaled, air_point_2 - normal_scaled)
			&& trace_between_points(player_pos + normal_scaled, air_point_2 + normal_scaled)
			&& trace_between_points(player_pos - normal_scaled, air_point_2 - normal_scaled)
		);
		local empty_up_higher = (
			trace_between_points(boomer_pos + normal_scaled, air_point_1 + normal_scaled)
			&& trace_between_points(boomer_pos - normal_scaled, air_point_1 - normal_scaled)
			&& trace_between_points(player_pos + normal_scaled, air_point_1 + normal_scaled)
			&& trace_between_points(player_pos - normal_scaled, air_point_1 - normal_scaled)
		);
		local desired_velocity = function(tangens) {
			local v_up = sqrt(0.5 * boomer_to_player_len_hor * tangens * 800);
			local v_hor = v_up / tangens;
			v_up += boomer_to_player_len_ver * v_hor / boomer_to_player_len_hor;
			local v_hor_vec = normalize(boomer_to_player).Scale(v_hor);
			return Vector(v_hor_vec.x, v_hor_vec.y, v_up);
		}
		local launch = function(vel) {
			DoEntFire("!self", "AddOutput", format("basevelocity %f %f %f", vel.x, vel.y, vel.z), 0, null, boomer);
			remove_task_on_entity(boomer);
			set_entity_flag(boomer, 1 << 5, true);
			create_particles("mini_fireworks", boomer.GetOrigin() + Vector(0, 0, -27), 5);
			set_entity_flag(boomer, 1, false);
			Actions.StrafeInit(boomer, boomer_strafe_params);
			register_task_on_entity(boomer, @()Actions.DoStrafeTick(boomer, boomer_strafe_params, player().GetOrigin(), true), 0.1);
			local key = UniqueString();
			run_next_tick( function() {
				register_ticker(key, function() {
					if (!boomer || deleted_ent(boomer) || boomer.IsDying()) {
						remove_ticker(key);
					} else if ((NetProps.GetPropInt(boomer, "m_fFlags") & 1)) {
						log((player().GetOrigin() - boomer.GetOrigin()).Length());
						/*if ((player().GetOrigin() - boomer.GetOrigin()).Length() < 250) { //default 200
							player().Stagger(boomer.GetOrigin());
							//NetProps.SetPropVector(player(), "m_vecBaseVelocity", 
							//	normalize(player().GetOrigin() - boomer.GetOrigin()).Scale(400) + Vector(0, 0, 400));
							//NetProps.SetPropFloat(player(), "m_vomitStart", 0.0);
							//NetProps.SetPropFloat(player(), "m_vomitFadeStart", 0.0);
							//player().HitWithVomit();
							//NetProps.SetPropFloat(player(), "m_itTimer.m_timestamp", Time() + 5.0);
						}*/
						NetProps.SetPropFloat(player(), "m_itTimer.m_timestamp", Time());
						kill_player(boomer);
						remove_ticker(key);
					}
				})
			});
		}
		local condition_high = empty_up && empty_up_higher;
		local condition_low = empty_up && empty_straight;
		local launch_high = @()launch(desired_velocity(RandomFloat(0.9, 1.4)).Scale(1.1) + normal.Scale(RandomFloat(-300, 300)));
		local launch_low = @()launch(desired_velocity(RandomFloat(0.4, 0.9)).Scale(1.1) + normal.Scale(RandomFloat(-300, 300)));
		if (condition_high || condition_low) {
			if (RandomInt(0, 1)) {
				if (condition_high) launch_high();
				else launch_low();
			} else {
				if (condition_low) launch_low();
				else launch_high();
			}
		}
	}, 0.5);
});

register_callback("player_now_it", "player_now_it", function(params) {
	local _player = GetPlayerFromUserID(params.userid);
	if (_player == player())
		change_score("vomited", -2);
		NetProps.SetPropFloat(player(), "m_itTimer.m_timestamp", Time() + 4.0);
});

::boomer_strafe_params <- {
	aside_scale = 90,
	aside_to_backwards_scale = 10,
	backwards_scale = 20,
	aside_change_chance = 20,
	backwards_chance = 30,
	max_aside = 2,
	aside_change_min_delay = 0.8,
}

//smoker

register_callback("tongue_grab", "break_tongue", function(params) {
	local smoker = GetPlayerFromUserID(params.userid);
	delayed_call( function(){
		cvar("tongue_force_break", 1);
		change_score("smoked", -1);
		run_next_tick( @()NetProps.SetPropInt(player(), "movetype", 2) );
	}, 0.1);
});