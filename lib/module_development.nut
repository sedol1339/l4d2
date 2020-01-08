//---------- DOCUMENTATION ----------

/**
FUNCTIONS FOR DEVELOPMENT
Warning! All tasks and callbacks are removed on round change.
! requires lib/module_base !
! requires lib/module_strings !
! requires lib/module_tasks !
------------------------------------
watch_netprops(ent,[netprops])
	For singleplayer development: print entity netprops in real time in HUD and binds actions to save/restore them. As first parameter you can pass entity or function that returns entity (for example, bot()), it will be called every update. Next parameters are any amount of netprops. Pass null as first param to remove anything from HUD and remove binds. All values are updating every tick. Press any number with ALT button on keyboard to save corresponding netprop. Press any number without ALT button to restore it's value. This function will conflict with HUD system from lib/module_hud.
	Example: watch_netprops(player, "movetype", "m_fFlags", "m_nButtons", "m_vecOrigin", "m_flCycle", "m_hGroundEntity")
	For given example, you will see the following on your HUD:
		[1] movetype: 2
		[2] m_fFlags: FL_ONGROUND | FL_CLIENT
		[3] m_nButtons: IN_FORWARD
		[4] m_vecOrigin: <77.819519 8419.559570 0.031250>
		[5] m_flCycle: 0.611931
		[6] m_hGroundEntity: (worldspawn 0)
------------------------------------
log_event(event, enabled = true)
	Start logging event to console. Pass false as additional param to cancel.
------------------------------------
log_events(enabled = true)
	Start logging all events to console using cvar net_showevents=2. Pass false as additional param to cancel.
------------------------------------
draw_collision_box(ent, dur, color)
	Draws collision box for entity for duration. It is drawing not all lines probably due to some engine problems. For correct drawing your lines should not be outside your field of view. Also this function may not work when you paused the game and have your console opened.
------------------------------------
mark(vec, duration, color = Vector(255, 0, 255), radius = 4)
	Marks point, drawing a box for specified duration.
 */

//---------- CODE ----------

this = ::root

log("[lib] including module_development")

__watch_netprops_show <- function() {
	//HUDSetLayout(::__watch_netprops)
	local lines = []
	for (local slot = 1;;slot++) {
		if (slot in ::__watch_netprops.Fields) {
			lines.append(::__watch_netprops.Fields[slot].dataval)
		} else break
	}
	hud.show_list("watch_netprops", lines, 0.05, 0.55 - 0.06*::__watch_netprops.up_shift, 1, 0.1, -0.04)
}

watch_netprops <- function(ent, ...) {
	if (!ent) {
		hud.hide_list("watch_netprops")
		remove_ticker("watch_netprops")
		for (local i = 0; i < 9; i++)
			SendToConsole(format("bind %d slot%d", i, i))
		SendToConsole("unbind alt")
		return;
	}
	::__watch_netprops.ent <- ent
	::__watch_netprops.ent_func <- ((typeof(ent) == "function") ? ent : null)
	local netprops = vargv
	::__watch_netprops.Fields <- {}
	local size = netprops.len()
	::__watch_netprops.up_shift <- (size > 4) ? size - 4 : 0
	foreach(index, netprop in netprops) {
		local slot = index + 1
		//HUDPlace(slot, 0.05, 0.55 + 0.06*(index - ::__watch_netprops.up_shift), 1, 0.1)
		local type = NetProps.GetPropType(
			(::__watch_netprops.ent_func ? ::__watch_netprops.ent_func() : ::__watch_netprops.ent), netprop)
		::__watch_netprops.Fields[slot] <- {
			name = netprop
			type = type
			slot = slot
		}
	}
	register_ticker("watch_netprops", function() {
		local ent = ::__watch_netprops.ent_func ? ::__watch_netprops.ent_func() : ::__watch_netprops.ent
		foreach(slot, table in ::__watch_netprops.Fields) {
			local str = format("[%d] %s: ", slot, table.name)
			switch (table.type) {
				case "integer":
					if (table.name in __netprops_bitmaps) {
						local bitmap = __netprops_bitmaps[table.name]
						local val = NetProps.GetPropInt(ent, table.name)
						local names_arr = []
						foreach (index, flag_name in bitmap)
							if (val & (1 << index))
								names_arr.push(flag_name)
						str += connect_strings(names_arr, " | ")
						break;
					}
					local val = NetProps.GetPropEntity(ent, table.name)
					if (!val)
						str += NetProps.GetPropInt(ent, table.name)
					else
						str += ent_to_str(val);
					break;
				case "string": str += NetProps.GetPropString(ent, table.name); break;
				case "float": str += NetProps.GetPropFloat(ent, table.name).tostring(); break;
				case "Vector":
					local vec = NetProps.GetPropVector(ent, table.name);
					str += format("<%f %f %f>", vec.x, vec.y, vec.z);
				break;
				case null: str += "null"; break;
				default: str += "unsupported prop type: " + table.type;
			}
			table.dataval <- str;
		}
		__watch_netprops_show()
	});
	local slot_count = ::__watch_netprops.Fields.len();
	::__watch_netprops.binds_save <- "";
	::__watch_netprops.binds_restore <- "";
	for (local i = 1; i <= slot_count; i++) {
		::__watch_netprops.binds_save += format("bind %d \"script watch_netprops_save(%d)\";", i, i);
		::__watch_netprops.binds_restore += format("bind %d \"script watch_netprops_restore(%d)\";", i, i);
	}
	watch_netprops_restore_binds();
	SendToConsole("alias +save_mode \"script watch_netprops_save_binds()\"");
	SendToConsole("alias -save_mode \"script watch_netprops_restore_binds()\"");
	SendToConsole("bind alt +save_mode");
}

watch_netprops_save <- function (slot) {
	local ent = ::__watch_netprops.ent_func ? ::__watch_netprops.ent_func() : ::__watch_netprops.ent
	local table = ::__watch_netprops.Fields[slot]
	switch (table.type) {
		case "integer": table.saved <- NetProps.GetPropInt(ent, table.name); break
		case "string": table.saved <- NetProps.GetPropString(ent, table.name); break
		case "float": table.saved <- NetProps.GetPropFloat(ent, table.name); break
		case "Vector": table.saved <- NetProps.GetPropVector(ent, table.name); break
		case null: default: say_chat("can't save netprop of unsupported prop type"); return
	}
	logf("saved value %s of netprop %s", table.saved.tostring(), table.name)
	table.dataval = "<save> " + table.dataval
	__watch_netprops_show()
	loop_add_to_timer("__watch_netprops", 0.1)
}

watch_netprops_restore <- function (slot) {
	local ent = ::__watch_netprops.ent_func ? ::__watch_netprops.ent_func() : ::__watch_netprops.ent
	local table = ::__watch_netprops.Fields[slot]
	if (!("saved" in table)) {
		say_chat("save value before restoring")
		return;
	}
	local saved = table.saved
	switch (table.type) {
		case "integer": NetProps.SetPropInt(ent, table.name, saved); break
		case "string": NetProps.SetPropString(ent, table.name, saved); break
		case "float": NetProps.SetPropFloat(ent, table.name, saved); break
		case "Vector": NetProps.SetPropVector(ent, table.name, saved); break
	}
	logf("restored value %s of netprop %s", saved.tostring(), table.name)
	table.dataval = "<set> " + table.dataval
	__watch_netprops_show()
	loop_add_to_timer("__watch_netprops", 0.1)
}

watch_netprops_save_binds <- @() SendToConsole(::__watch_netprops.binds_save)
watch_netprops_restore_binds <- @() SendToConsole(::__watch_netprops.binds_restore)

local buttons_bits = ["IN_ATTACK", "IN_JUMP", "IN_DUCK", "IN_FORWARD", "IN_BACK", "IN_USE", "IN_CANCEL", "IN_LEFT", "IN_RIGHT", "IN_MOVELEFT", "IN_MOVERIGHT", "IN_ATTACK2", "IN_RUN", "IN_RELOAD", "IN_ALT1", "IN_ALT2", "IN_SCORE", "IN_SPEED", "IN_WALK", "IN_ZOOM", "IN_WEAPON1", "IN_WEAPON2", "IN_BULLRUSH", "IN_GRENADE1", "IN_GRENADE2"]

__netprops_bitmaps <- {
	m_fFlags = ["FL_ONGROUND", "FL_DUCKING", "FL_WATERJUMP", "FL_ONTRAIN", "FL_INRAIN", "FL_FROZEN", "FL_ATCONTROLS", "FL_CLIENT", "FL_FAKECLIENT", "FL_INWATER", "FL_FLY", "FL_SWIM", "FL_CONVEYOR", "FL_NPC", "FL_GODMODE", "FL_NOTARGET", "FL_AIMTARGET", "FL_PARTIALGROUND", "FL_STATICPROP", "FL_GRAPHED", "FL_GRENADE", "FL_STEPMOVEMENT", "FL_DONTTOUCH", "FL_BASEVELOCITY", "FL_WORLDBRUSH", "FL_OBJECT", "FL_KILLME", "FL_ONFIRE", "FL_DISSOLVING", "FL_TRANSRAGDOLL", "FL_UNBLOCKABLE_BY_PLAYER", "FL_FREEZING"]
	m_nButtons = buttons_bits
	m_nOldButtons = buttons_bits
	m_afButtonLast = buttons_bits
	m_afButtonPressed = buttons_bits
	m_afButtonReleased = buttons_bits
	m_afButtonDisabled = buttons_bits
	m_afButtonForced = buttons_bits
}

if (!("__watch_netprops" in getroottable())) ::__watch_netprops <- {}

////////////////////////////

draw_collision_box <- function(ent, duration, color = Vector(255, 255, 0)) {
	local mins = ent.GetOrigin() + propvec(ent, "m_Collision.m_vecMins")
	local maxs = ent.GetOrigin() + propvec(ent, "m_Collision.m_vecMaxs")
	DebugDrawLine_vCol( Vector(mins.x, mins.y, mins.z), Vector(mins.x, maxs.y, mins.z), color, false, duration )
	DebugDrawLine_vCol( Vector(mins.x, mins.y, mins.z), Vector(maxs.x, mins.y, mins.z), color, false, duration )
	DebugDrawLine_vCol( Vector(mins.x, maxs.y, mins.z), Vector(maxs.x, maxs.y, mins.z), color, false, duration )
	DebugDrawLine_vCol( Vector(maxs.x, mins.y, mins.z), Vector(maxs.x, maxs.y, mins.z), color, false, duration )
	
	DebugDrawLine_vCol( Vector(mins.x, mins.y, maxs.z), Vector(mins.x, maxs.y, maxs.z), color, false, duration )
	DebugDrawLine_vCol( Vector(mins.x, mins.y, maxs.z), Vector(maxs.x, mins.y, maxs.z), color, false, duration )
	DebugDrawLine_vCol( Vector(mins.x, maxs.y, maxs.z), Vector(maxs.x, maxs.y, maxs.z), color, false, duration )
	DebugDrawLine_vCol( Vector(maxs.x, mins.y, maxs.z), Vector(maxs.x, maxs.y, maxs.z), color, false, duration )
	
	DebugDrawLine_vCol( Vector(mins.x, mins.y, mins.z), Vector(mins.x, mins.y, maxs.z), color, false, duration )
	DebugDrawLine_vCol( Vector(mins.x, maxs.y, mins.z), Vector(mins.x, maxs.y, maxs.z), color, false, duration )
	DebugDrawLine_vCol( Vector(maxs.x, mins.y, mins.z), Vector(maxs.x, mins.y, maxs.z), color, false, duration )
	DebugDrawLine_vCol( Vector(maxs.x, maxs.y, mins.z), Vector(maxs.x, maxs.y, maxs.z), color, false, duration )
}

mark <- function(vec, duration, color = Vector(255, 0, 255), radius = 4) {
	DebugDrawBoxDirection(vec, Vector(-radius, -radius, -radius), Vector(radius, radius, radius), Vector(0, 0, 1), color, 255, duration)
}

log_event <- function(event, enabled = true) {
	if (enabled) register_callback("__log_event_table", event, log_table);
	else remove_callback("__log_event_table", event);
}

log_events <- function(enabled = true) {
	cvar("net_showevents", enabled ? 2 : 0);
}

__module_development_logstate <- function() {

}