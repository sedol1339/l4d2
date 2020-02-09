//this is a part of module_serversettings

new_player_setting("charger_steering", {
	default_state = STATE_DISABLED
	should_run_ticker = @(state) false
	__unfreeze = function(player) {
		set_entity_flag(player, FL_FROZEN, false)
	}
	__freeze = function(player) {
		set_entity_flag(player, FL_FROZEN, true)
	}
	on_change = function(player, old_state, new_state) {
		local is_charging = player.GetZombieType() == 6 && propint(player, "m_nSequence") == 5
		if (new_state == STATE_ENABLED) {
			scope(player).charger_steering <- true
			if (is_charging) __unfreeze(player)
		} else {
			if ("charger_steering" in scope(player)) delete scope(player).charger_steering
			if (is_charging) __freeze(player)
		}
		if (exists_player_with_state(STATE_ENABLED)) {
			if (!callback_exists("player_settings.charger_steering", "charger_charge_start")) {
				register_callback("player_settings.charger_steering", "charger_charge_start", function(params) {
					if ("charger_steering" in scope(params.player)) __unfreeze(params.player)
				}.bindenv(this))
			}
		} else {
			remove_callback("player_settings.charger_steering", "charger_charge_start")
		}
	}
})

new_player_setting("charger_jump", {
	default_state = STATE_DISABLED
	should_run_ticker = @(state) false //performance reasons
	jump_force = 1.0
	__reg_ticker = function(player) {
		register_ticker("charger_jump_" + entstr(player), player, function() {
			if (propint(player, "m_nSequence") != 5) return false //charge finished?
			if (propint(player, "movetype") != 2) return
			if (!(propint(player, "m_nButtons") & IN_JUMP)) return
			if (propint(player, "m_afButtonLast") & IN_JUMP) return
			if (propint(player, "m_hGroundEntity") == -1) return
			//simulating jump
			propint(player, "m_hGroundEntity", -1)
			local jump_force_modifier = __global_jump_force_modifier
			if ("charger_jump_modifier" in scope(player)) jump_force_modifier = scope(player).charger_jump_modifier
			if (jump_force_modifier == 0) return
			velocity_impulse(player, Vector(0, 0, 245.705 * jump_force_modifier))
		})
	}
	__remove_ticker = function(player) {
		remove_ticker("charger_jump_" + entstr(player))
	}
	on_change = function(player, old_state, new_state) {
		local is_charging = player.GetZombieType() == 6 && propint(player, "m_nSequence") == 5
		if (new_state == STATE_ENABLED) {
			scope(player).charger_jump <- true
			if (is_charging) __reg_ticker(player)
		} else {
			if ("charger_jump" in scope(player)) delete scope(player).charger_jump
			if (is_charging) __remove_ticker(player)
		}
		if (exists_player_with_state(STATE_ENABLED)) {
			if (!callback_exists("player_settings.charger_jump", "charger_charge_start")) {
				register_callback("player_settings.charger_jump", "charger_charge_start", function(params) {
					if ("charger_jump" in scope(params.player)) __reg_ticker(params.player)
				}.bindenv(this))
				register_callback("player_settings.charger_jump", "charger_charge_end", function(params) {
					if ("charger_jump" in scope(params.player)) __remove_ticker(params.player)
				}.bindenv(this))
			}
		} else {
			remove_callback("player_settings.charger_jump", "charger_charge_start")
			remove_callback("player_settings.charger_jump", "charger_charge_end")
		}
	}
})