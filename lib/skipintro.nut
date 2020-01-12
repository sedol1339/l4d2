/* 
 * Taken from:
 * Speedrunner Tools
 * https://steamcommunity.com/sharedfiles/filedetails/?id=510955402
*/

local mapname = mapname()

if (mapname.find("m1_") != null)
{
	if (mapname == "c1m1_hotel")
	{
		EntFire("sound_chopperleave", "Kill");					//Specific intro sounds.
		EntFire("rescue_chopper", "Kill");						//Specific models of rescue vehicles.
		EntFire("lcs_intro", "Kill");								//Remove survivor voices during intro.
		EntFire("fade_intro", "Kill");								//Remove entity of fade control.
		EntFire("director", "FinishIntro", null, 0.1);					//Stop survivor animations during intro.
		EntFire("director", "ReleaseSurvivorPositions", null, 0.1);		//Teleport to start points + unfreezing.
		EntFire("point_viewcontrol_survivor", "Kill"); 				//Remove intro cameras.
	}
	else if (mapname == "c2m1_highway")
	{
		EntFire("lcs_intro", "Kill");
		EntFire("fade_intro", "Kill");
		EntFire("director", "FinishIntro", null, 0.1);
		EntFire("director", "ReleaseSurvivorPositions", null, 0.1);
		EntFire("point_viewcontrol_survivor", "Kill");
	}
	else if (mapname == "c3m1_plankcountry")
	{
		EntFire("lcs_intro", "Kill");
		EntFire("fade_intro", "Kill");
		EntFire("director", "ReleaseSurvivorPositions", null, 0.1);
		EntFire("point_viewcontrol_survivor", "Kill");
	}
	else if (mapname == "c4m1_milltown_a")
	{
		EntFire("PugTug", "Kill");
		EntFire("@skybox_PugTug", "Kill");
		EntFire("lcs_intro", "Kill");
		EntFire("fade_intro", "Kill");
		EntFire("@director", "FinishIntro", null, 0.1);
		EntFire("@director", "ReleaseSurvivorPositions", null, 0.1);
		EntFire("point_viewcontrol_survivor", "Kill");
	}
	else if (mapname == "c5m1_waterfront")
	{
		EntFire("orator", "Kill");
		EntFire("tug_boat_intro", "Kill");
		EntFire("@skybox_tug_boat_intro", "Kill");
		EntFire("fade_intro", "Kill");
		EntFire("director", "FinishIntro", null, 0.1);
		EntFire("director", "ReleaseSurvivorPositions", null, 0.1);
		EntFire("point_viewcontrol_survivor", "Kill");
	}
	else if (mapname == "c8m1_apartment")
	{
		EntFire("lcs_intro_survivors", "Kill");
		EntFire("tarp_sound", "Kill");
		EntFire("tarp_animated", "Kill");
		EntFire("ghostAnim", "Kill");
		EntFire("sound_chopper", "Kill");
		EntFire("helicopter_speaker", "Kill");
		EntFire("helicopter_animated", "Kill");
		EntFire("fade_intro", "Kill");
		EntFire("director", "FinishIntro", null, 0.3);
		EntFire("director", "ReleaseSurvivorPositions", null, 0.3);
		EntFire("camera_intro_airplane", "Kill");
	}
	else if (mapname == "c13m1_alpinecreek")
	{
		EntFire("gamesound", "PlaySound");
		EntFire("lcs_intro", "Kill");
		EntFire("scene_relay", "Kill");
		EntFire("b_Signboard01", "Kill");
		EntFire("fade_intro", "Kill");
		EntFire("director", "FinishIntro", null, 0.1);
		EntFire("director", "ReleaseSurvivorPositions", null, 0.1);
		EntFire("point_viewcontrol_survivor", "Kill");
	}
	else													//omni skipintro
	{
		EntFire("camera_intro_airplane", "Disable", null, 0.1);
		EntFire("airplane_animated_intro", "Kill");
		EntFire("env_fade", "AddOutput", "duration 0");
		EntFire("env_fade", "Fade");
		EntFire("env_fade", "Kill", null, 1.0);
		EntFire("director", "FinishIntro", null, 0.1);
		EntFire("director", "FinishIntro", null, 0.3);
		EntFire("director", "ReleaseSurvivorPositions", null, 0.1);
		EntFire("@director", "FinishIntro", null, 0.1);
		EntFire("@director", "ReleaseSurvivorPositions", null, 0.1);
		EntFire("point_viewcontrol_survivor", "Disable", null, 0.1);
	}
}