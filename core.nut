const MISS = 0
const BODYSHOT = 1
const HEADSHOT = 2

/*
params table includes:
do_remove_and_spawn //gets training scope, performs any manipulations when it's time to spawn target(s), called by timer, don't forget to remove old targets here
on_tick //gets training scope, performs any manipulations every tick, here you can check scope.start_time and call scope::finish()
on_tick_foreach //same, but called for every alive target, gets training scope, target index and target entity
timer_params // contains:
	float "refire_delay" //seconds between do_spawn_func calls, later you can call function scope.timer_params::set_refire_delay(delay) to change it
	boolean "refire_on_shot"
	boolean "refire_on_kill"
	float "refire_on_event_delay"
	// this can be replaced by running scope::refire(delay_before) in more comples cases
	float "initial_delay"
on_player_shot //gets training scope and table with params:
	shot //MISS, BODYSHOT, HEADSHOT
	was_kill //true or false, may be set to true in function (target will be killed) - changes NOT IMPLEMENTED yet
	damage //amount of damage dealt, may be changed in function (target's health will be changed accordingly) - changes NOT IMPLEMENTED yet
	target_index //index of the victim entity in scope.targets[] array
	player //player entity who made a shot (is survivor and is not a bot)
	weapon_id //if firearm weapon, otherwise -1
	weapon_name //string
	// performs any manipulations
on_player_shot_post //gets training scope, table with params and history: table with fields "misses", "bodyshots", "headshots", "kills" (may be changed in on_player_shot)
on_start //gets training scope, performs any manipulations
on_finish //gets training scope and "was_interrupted" bool (false if normal finish), performs any manipulations
*/

start_training <- function(params, scope = null) {
	
	g_ModeScript.DirectorOptions.MaxSpecials <- 32;
	no_SI_with_death_cams(true);
	
	g_ModeScript.InjectTable(params, this);
	
	start_time <- Time();
	targets <- [];
	_key <- UniqueString("training");
	_shots <- {};
	_shots_history <- {};
	_delayed_calls <- [];
	
	if (!("do_remove_and_spawn" in this)) do_remove_and_spawn <- null
	if (!("on_tick" in this)) on_tick <- null
	if (!("on_tick_foreach" in this)) on_tick_foreach <- null
	if (!("on_player_shot" in this)) on_player_shot <- null
	if (!("on_player_shot_post" in this)) on_player_shot_post <- null
	if (!("on_start" in this)) on_start <- null
	if (!("on_finish" in this)) on_finish <- null
	
	get_history <- @()_shots_history;
	
	register_loop(_key, function() {
		if (do_remove_and_spawn)
			do_remove_and_spawn();
	}, params.timer_params.refire_delay);
	
	register_ticker(_key, function() {
		if (on_tick)
			on_tick();
		if (on_tick_foreach) 
			foreach (index, target in targets)
				if (!deleted_ent(target) && !target.IsDead())
					on_tick_foreach (index, target);
	});
	
	refire <- function(delay_before = 0) {
		local prevent_running_this_tick = (delay_before > 0);
		loop_reset(_key, prevent_running_this_tick);
		loop_subtract_from_timer(_key, timer_params.refire_delay);
		loop_add_to_timer(_key, delay_before, prevent_running_this_tick);
	}
	
	refire(timer_params.initial_delay);
	
	timer_params.set_refire_delay <- function(delay) {
		loop_set_refire_time(_key, delay);
		timer_params.refire_delay = delay;
	}
	
	register_callback("weapon_fire", _key, function(__params) {
		local attacker = GetPlayerFromUserID(__params.userid);
		if (IsPlayerABot(attacker) || !attacker.IsSurvivor()) return;
		if (!is_hitscan_weapon(__params.weapon)) return;
		_shots[attacker] <- {
			weapon_id = __params.weaponid,
			weapon_name = __params.weapon
		}
		run_this_tick(function() {
			if (attacker in _shots) {
				local shot_table = _shots[attacker];
				local table = {
					shot = MISS,
					was_kill = false,
					damage = 0,
					target_index = null,
					player = attacker,
					weapon_id = shot_table.weapon_id,
					weapon_name = shot_table.weapon_name
				}
				if (on_player_shot)
					on_player_shot(table);
				if (!(attacker in _shots_history))
					_shots_history[attacker] <- {
						misses = 0, bodyshots = 0, headshots = 0, kills = 0, hits = 0
					};
				local history_table = _shots_history[attacker];
				history_table.misses++;
				delete _shots[attacker];
				if (on_player_shot_post)
					on_player_shot_post(table, history_table);
				if (timer_params.refire_on_shot)
					refire(timer_params.refire_on_event_delay);
			}
		});
	});
	
	register_callback("player_hurt", _key, function(__params) {
		if (__params.attacker == __params.userid) return;
		local attacker = GetPlayerFromUserID(__params.attacker);
		if (IsPlayerABot(attacker) || !attacker.IsSurvivor()) return;
		local victim = GetPlayerFromUserID(__params.userid);
		local target_index = -1;
		foreach (i, target in targets) {
			if (target == victim) {
				target_index = i;
				break;
			}
		}
		if (target_index == -1) return;
		local hitscan = is_hitscan_weapon(__params.weapon);
		if (hitscan && !(attacker in _shots)) throw "wtf? attacker not in _shots";
		local was_kill = (__params.health == 0);
		local headshot = (__params.hitgroup == 1);
		local table = {
			shot = (headshot ? HEADSHOT : BODYSHOT),
			was_kill = was_kill,
			damage = __params.dmg_health,
			target_index = target_index,
			player = attacker,
			weapon_id = (hitscan ? _shots[attacker].weapon_id : -1),
			weapon_name = __params.weapon
		}
		if (on_player_shot)
			on_player_shot(table);
		if (hitscan) delete _shots[attacker];
		if (!(attacker in _shots_history)) _shots_history[attacker] <- {
			misses = 0, bodyshots = 0, headshots = 0, kills = 0, hits = 0
		};
		local history_table = _shots_history[attacker];
		if (headshot) history_table.headshots++;
		else history_table.bodyshots++;
		history_table.hits++;
		if (was_kill) history_table.kills++;
		if (on_player_shot_post)
			on_player_shot_post(table, history_table);
		if (
			timer_params.refire_on_shot ||
			(timer_params.refire_on_kill && was_kill)
		) refire(timer_params.refire_on_event_delay);
	});
	
	//NOT IMPLEMENTED yet
	//register_callback("infected_hurt", _key, function(__params) {
	//	
	//});
	
	finish <- function(was_interrupted) {
		remove_loop(_key);
		remove_ticker(_key);
		remove_callback("weapon_fire", _key);
		remove_callback("player_hurt", _key);
		remove_callback("infected_hurt", _key);
		no_SI_with_death_cams(false);
		if (on_finish)
			on_finish(was_interrupted);
		foreach (key in _delayed_calls)
			remove_delayed_call(key);
		
		log("---------------------------------");
		log("\tTraining finished");
		log("---------------------------------");
		print_all_tasks();
		log("---------------------------------");
	}
	
	log("---------------------------------");
	log("\tTraining started");
	log("---------------------------------");
	print_all_tasks();
	log("---------------------------------");
	
	if (on_start)
		on_start();
}

interrupt_training <- @()finish(true);