printl("starting");
DoEntFire("!self", "Enable", "", 0, null, Entities.FindByName(null,"hunter_field"));
DoEntFire("!self", "Disable", "", 0, null, Entities.FindByName(null,"hunter_brush"));
DoEntFire("!self", "Disable", "", 0, null, Entities.FindByName(null,"brush_background_wall"));
DoEntFire("!self", "Disable", "", 0, null, Entities.FindByName(null,"brush_background_panel"));
DoEntFire("!self", "Disable", "", 0, null, Entities.FindByName(null,"brush_idle_background"));
DoEntFire("!self", "Disable", "", 0, null, Entities.FindByName(null,"brush_idle_hunter_button"));
DoEntFire("!self", "Disable", "", 0, null, Entities.FindByName(null,"brush_idle_charger_button"));

IncludeScript("tr/lib", getroottable());
IncludeScript("tr/core", getroottable());
IncludeScript("tr/ext", getroottable());

::Modes <- {};
IncludeScript("tr/modes/boomers", Modes);

//::dc_debug <- true;

stop_director();
cvar("director_no_death_check", 1);
cvar("god", 1);

::target_bot <- null;
::target_bot_initial_pos <- Vector(-15, -7, -3138);
::human_player_connected <- false;

on_player_connect(Team.SURVIVORS, ClientType.BOT, function(params) {
	if (!target_bot) {
		::target_bot = params.player;
		run_this_tick(function() {
			target_bot.SetOrigin(target_bot_initial_pos);
			target_bot.GetActiveWeapon().Kill();
			NetProps.SetPropInt(target_bot, "m_bSurvivorGlowEnabled", 0)
			NetProps.SetPropInt(target_bot, "movetype", 0);
			NetProps.SetPropInt(target_bot, "m_nRenderMode", 10); //RENDER_NONE
			NetProps.SetPropInt(target_bot, "m_fadeMaxDist", 0);
			NetProps.SetPropInt(target_bot, "m_CollisionGroup", 1);  //COLLISION_GROUP_DEBRIS, after this SI can't catch bot
		});
	} else
		SendToServerConsole("kickid " + params.userid);
});

on_player_connect(Team.ANY, ClientType.HUMAN, function(params) {
	if (!human_player_connected) {
		run_this_tick( @()teleport_entity(params.player, Vector(0, 0, 62.03), QAngle(0, 0, 0)) );
		run_this_tick( @()params.player.GiveItem("sniper_awp"));
		run_next_tick( @()EntFire("weapon_pistol", "Kill", "") );
		SendToConsole("bind z noclip");
		::human_player_connected = true;
	}
});