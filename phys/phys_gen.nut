/* local dummy = SpawnEntityFromTable("weapon_pain_pills", {
	targetname = "dummy",
	origin = Ent("q2").GetOrigin() + Vector(0,0,150),
	model = "models/w_models/weapons/w_eq_painpills.mdl"
})
run_next_tick( function() {
	propint(dummy, "m_CollisionGroup", 20) //COLLISION_GROUP_WORLD
	SendToConsole("ent_fire dummy addoutput \"solid 0\"")
	local constraint = SpawnEntityFromTable("phys_spring", {
		attach1 = "dummy",
		attach2 = "q2",
		length = 100,
		constant = 10000,
		damping = 10,
	})
	register_ticker("myticker", function() {
		DebugDrawBoxDirection(dummy.GetOrigin(), Vector(-4, -4, -4), Vector(4, 4, 4), Vector(0, 0, 1), Vector(200, 0, 200), 255, 0.1)
		DebugDrawLine_vCol(dummy.GetOrigin(), Ent("q2").GetOrigin(), Vector(0, 255, 0), false, 0.1)
	})
}) */


testing_pos <- Vector(300, 0, 500)

steps_info <- null

last_result <- null

local test_time = 2
local common_steps = 21
local common_next_steps = 4

total_strings_appended <- 0

test <- function(model, on_finish) {
	local ent = null
	last_result = null
	chain(
		"testing",
		
		function() {
			ent = SpawnEntityFromTable("prop_physics", {
				origin = testing_pos,
				model = model
			})
			if (!deleted_ent(ent)) {
				propint(ent, "m_CollisionGroup", 20)
				ent.ApplyAbsVelocityImpulse(Vector(0, 0, 21))
				say_chat("created entity " + ent_to_str(ent))
			} else {
				say_chat("failed to create entity")
			}
			chain_continue("testing")
		},
		
		function() {
			if (deleted_ent(ent)) {say_chat("cannot find entity");chain_continue("testing");return}
			steps_info = {
				x = {min = -100, max = 100, steps = common_steps},
				y = {min = -100, max = 100, steps = common_steps},
				z = {min = -100, max = 100, steps = common_steps},
			}
			say_chat(ent_to_str(ent))
			do_test(ent, test_time, steps_info, @()chain_continue("testing"))
		},
		
		function() {
			if (!last_result) {chain_continue("testing");return}
			local last_min_x = last_result[0]
			local last_min_y = last_result[1]
			local last_min_z = last_result[2]
			local last_step_x = (steps_info.x.max - steps_info.x.min) / (steps_info.x.steps - 1.0)
			local last_step_y = (steps_info.y.max - steps_info.y.min) / (steps_info.y.steps - 1.0)
			local last_step_z = (steps_info.z.max - steps_info.z.min) / (steps_info.z.steps - 1.0)
			local max_step = max(last_step_x, max(last_step_y, last_step_z))
			steps_info = {
				x = {min = last_min_x - common_next_steps * max_step, max = last_min_x + common_next_steps * max_step, steps = common_steps},
				y = {min = last_min_y - common_next_steps * max_step, max = last_min_y + common_next_steps * max_step, steps = common_steps},
				z = {min = last_min_z - common_next_steps * max_step, max = last_min_z + common_next_steps * max_step, steps = common_steps},
			}
			//say_chat("Testing, max_step %.2f (of %.2f %.2f %.2f)...", max_step, last_step_x, last_step_y, last_step_z)
			do_test(ent, test_time, steps_info, @()chain_continue("testing"))
		},
		
		function() {
			if (!last_result) {chain_continue("testing");return}
			local last_min_x = last_result[0]
			local last_min_y = last_result[1]
			local last_min_z = last_result[2]
			local last_step_x = (steps_info.x.max - steps_info.x.min) / (steps_info.x.steps - 1.0)
			local last_step_y = (steps_info.y.max - steps_info.y.min) / (steps_info.y.steps - 1.0)
			local last_step_z = (steps_info.z.max - steps_info.z.min) / (steps_info.z.steps - 1.0)
			local max_step = max(last_step_x, max(last_step_y, last_step_z))
			steps_info = {
				x = {min = last_min_x - common_next_steps * max_step, max = last_min_x + common_next_steps * max_step, steps = common_steps},
				y = {min = last_min_y - common_next_steps * max_step, max = last_min_y + common_next_steps * max_step, steps = common_steps},
				z = {min = last_min_z - common_next_steps * max_step, max = last_min_z + common_next_steps * max_step, steps = common_steps},
			}
			//say_chat("Testing, max_step %.2f (of %.2f %.2f %.2f)...", max_step, last_step_x, last_step_y, last_step_z)
			do_test(ent, test_time, steps_info, @()chain_continue("testing"))
		},
		
		function() {
			if (!last_result) {chain_continue("testing");return}
			local last_min_x = last_result[0]
			local last_min_y = last_result[1]
			local last_min_z = last_result[2]
			local last_step_x = (steps_info.x.max - steps_info.x.min) / (steps_info.x.steps - 1.0)
			local last_step_y = (steps_info.y.max - steps_info.y.min) / (steps_info.y.steps - 1.0)
			local last_step_z = (steps_info.z.max - steps_info.z.min) / (steps_info.z.steps - 1.0)
			local max_step = max(last_step_x, max(last_step_y, last_step_z))
			steps_info = {
				x = {min = last_min_x - common_next_steps * max_step, max = last_min_x + common_next_steps * max_step, steps = common_steps},
				y = {min = last_min_y - common_next_steps * max_step, max = last_min_y + common_next_steps * max_step, steps = common_steps},
				z = {min = last_min_z - common_next_steps * max_step, max = last_min_z + common_next_steps * max_step, steps = common_steps},
			}
			//say_chat("Testing, max_step %.2f (of %.2f %.2f %.2f)...", max_step, last_step_x, last_step_y, last_step_z)
			do_test(ent, test_time, steps_info, @()chain_continue("testing"))
		},
		
		function() {
			if (last_result) {
				if (last_result[0] <= 0 && last_result[0] > -0.005) last_result[0] = 0
				if (last_result[1] <= 0 && last_result[1] > -0.005) last_result[1] = 0
				if (last_result[2] <= 0 && last_result[2] > -0.005) last_result[2] = 0
				local str = "\"" + model + "\": " + format("Vector(%.2f, %.2f, %.2f)", last_result[0], last_result[1], last_result[2]) + "\n"
				local file_index = total_strings_appended / 50
				file_append("phys_output" + file_index + ".txt", str)
				total_strings_appended++
				say_chat("SUCCESS")
			} else {
				//file_append("phys_output.txt", "(ERROR) \"" + model + "\"\n")
				say_chat("ERROR")
			}
			if (!deleted_ent(ent)) {
				//say_chat("removing entity " + ent_to_str(ent))
				ent.Kill()
			}
			chain_continue("testing")
		},
		
		on_finish
	)
}

do_test <- function(ent, duration, steps_info, on_finish) {
	if (deleted_ent(ent)) {
		run_this_tick(on_finish)
		return
	}
	local start_time = clock.sec()
	local last_time = clock.sec()
	ent.SetOrigin(testing_pos)
	local angvel_ticks = 0
	//////////////////
	local x_steps = steps_info.x.steps
	local y_steps = steps_info.y.steps
	local z_steps = steps_info.z.steps
	local x_min = steps_info.x.min
	local y_min = steps_info.y.min
	local z_min = steps_info.z.min
	local x_delta = (steps_info.x.max - steps_info.x.min) / (x_steps - 1.0)
	local y_delta = (steps_info.y.max - steps_info.y.min) / (y_steps - 1.0)
	local z_delta = (steps_info.z.max - steps_info.z.min) / (z_steps - 1.0)
	local last_origins = array(x_steps * y_steps * z_steps, null)
	local total_lengths = array(x_steps * y_steps * z_steps, 0)
	//////////////////
	register_ticker("do_test", function() {
		if (clock.sec() - start_time > duration) {
			local min_total_length = INF
			local min_total_length_x = 0
			local min_total_length_y = 0
			local min_total_length_z = 0
			for(local x_step = 0; x_step < x_steps; x_step++) {
				for(local y_step = 0; y_step < y_steps; y_step++) {
					local tmp_array_pos = y_step * z_steps + x_step * y_steps * z_steps
					for(local z_step = 0; z_step < z_steps; z_step++) {
						local array_pos = z_step + tmp_array_pos
						local total_length = total_lengths[array_pos]
						if (total_length < min_total_length) {
							min_total_length = total_length
							min_total_length_x = x_step
							min_total_length_y = y_step
							min_total_length_z = z_step
						}
					}
				}
			}
			local min_x = x_min + x_delta*min_total_length_x
			local min_y = y_min + y_delta*min_total_length_y
			local min_z = z_min + z_delta*min_total_length_z
			say_chat("min length %.2f [deltas = %.2f %.2f %.2f]", min_total_length, min_x, min_y, min_z)
			last_result = [min_x, min_y, min_z]
			on_finish()
			return false
		}
		local last_delta_time = clock.sec() - last_time
		if (last_delta_time == 0) return
		last_time = clock.sec()
		
		ent.ApplyAbsVelocityImpulse(Vector(0, 0, 800 * last_delta_time))
		local angvel_max_per_tick = 500
		local angvel = Vector(
			RandomFloat(-angvel_max_per_tick, angvel_max_per_tick),
			RandomFloat(-angvel_max_per_tick, angvel_max_per_tick),
			RandomFloat(-angvel_max_per_tick, angvel_max_per_tick)
		)
		angvel_ticks++
		if (angvel_ticks >= 10) {
			angvel_ticks = 0
			log("resetting")
			angvel -= GetPhysAngularVelocity(ent)
		}
		ent.ApplyLocalAngularVelocityImpulse(angvel)
		//////////////////////////////////
		local origin = ent.GetOrigin()
		local angles = ent.GetAngles()
		local forward = angles.Forward()
		local left = angles.Left()
		local up = angles.Up()
		for(local x_step = 0; x_step < x_steps; x_step++) {
			local x = x_min + x_delta * x_step
			local tmp1_vec = origin + forward.Scale(x)
			for(local y_step = 0; y_step < y_steps; y_step++) {
				local y = y_min + y_delta * y_step
				local tmp2_vec = tmp1_vec + left.Scale(y)
				local tmp_array_pos = y_step * z_steps + x_step * y_steps * z_steps
				for(local z_step = 0; z_step < z_steps; z_step++) {
					local z = z_min + z_delta * z_step
					local vec = tmp2_vec + up.Scale(z)
					local array_pos = z_step + tmp_array_pos
					local last_origin = last_origins[array_pos]
					if (last_origin) {
						local delta = (vec - last_origin).Length()
						total_lengths[array_pos] += delta
					}
					last_origins[array_pos] = vec
				}
			}
		}
	})
}

//test("models/props_junk/dumpster_2.mdl", @()log("f"))
//test("models/props_vehicles/cara_84sedan.mdl", @()log("f"))

register_chat_command("t", function(player, command, args_text, args) {
	test(args[0], @()log("f"))
}, 1, 1)

register_chat_command("props", function(player, command, args_text, args) {
	local props_found = find_entities("prop_physics")
	local model_names = {}
	foreach(ent in props_found)
		model_names[propstr(ent, "m_ModelName")] <- true
	foreach(model, _ in model_names)
		log("" + model)
	say_chat("found %d prop models, see console", model_names.len())
}, 0, 0)

models_list <- null
models_index <- 0

_process <- function() {
	say_chat("_process: %d of %d", models_index, models_list.len())
	if (models_index >= models_list.len()) {
		say_chat("FINISH")
		return
	}
	local model = models_list[models_index]
	test(model, @()delayed_call(_process, 0))
	models_index++
}

register_chat_command("process", function(player, command, args_text, args) {
	models_list = []
	for(local i = 27; i <= 33; i++) {
		local filename = "phys_input/" + i + ".txt"
		say_chat("reading " + filename)
		models_list.extend(split(file_read(filename), "\n"))
		say_chat("total %d models", models_list.len())
	}
	_process()
}, 0, 0)

/* local ent = Ent("q2")
local last_origins = {}
local total_lengths = {}
local first_tick = true
local time = clock.sec()
register_ticker("getmasscenter", function() {
	local origin = ent.GetOrigin()
	local angles = ent.GetAngles()
	for(local a = -5; a <= 5; a++)
		for(local b = -5; b <= 5; b++)
			for(local c = -5; c <= 5; c++) {
				local point = origin + angles.Forward().Scale(a*5) + angles.Left().Scale(b*5) + angles.Up().Scale(c*5)
				local key = a + "_" + b + "_" + c
				if (!first_tick) {
					total_lengths[key] += (last_origins[key] - point).Length()
					DebugDrawLine_vCol(last_origins[key], point, Vector(0, 255, 0), false, 0.1)
				} else {
					total_lengths[key] <- 0
				}
				last_origins[key] <- point
			}
	if (clock.sec() - time > 0.3) {
		remove_ticker("getmasscenter")
		local min_length = 99999
		local min_length_index = "_"
		foreach(key, length in total_lengths)
			if (length < min_length) {
				min_length = length
				min_length_index = key
			}
		log(min_length_index)
		log(min_length)
	}
	first_tick = false
}) */
