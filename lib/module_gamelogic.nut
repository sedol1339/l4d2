//---------- DOCUMENTATION ----------

/**
FUNCTIONS FOR CONTROLLING GAME LOGIC
! requires lib/module_base !
! requires lib/module_convars !
! requires lib/module_entities !
------------------------------------
mapname()
	Returns current map name. Works only in scripted mode.
------------------------------------
modename()
	Returns current mode name (including mutations, takes it from convar mp_gamemode).
------------------------------------
skip_intro()
	Skips intro. Does not work for custom campaigns. Script taken from Speedrunner Tools: https://steamcommunity.com/sharedfiles/filedetails/?id=510955402
------------------------------------
restart_game(reset_cvars = false)
	Restarts round in 1 second by setting. Pass true as additional param to reset cvars (cvars_restore_all() and toggling sv_cheats 2 times).
------------------------------------
stop_director()
	Sets director_no_specials=1, director_no_mobs=1, director_no_bosses=1.
------------------------------------
stop_director_forced()
	Runs stop_director() and director_stop console command (requires sv_cheats 1).
------------------------------------
is_scripted_mode()
	Is scripted mode enabled? Internally function checks that ::SessionState exists.
------------------------------------
increase_specials_limit()
	Sets MaxSpecials = 32 in different tables, that allows spawning 6+ specials simultaneously. If scripted mode is not active, this seems to work only in coop mode. Made with help of Rayman's admin system.
------------------------------------
is_round_in_ending_state()
	(Not implemented) Returns true if director is going to restart map (all survivors died) or final saferoom door was already closed and round/map transition is in progress.
------------------------------------
is_hitscan_weapon(name)
	Given weapon name returns true if weapon is hitscan.
------------------------------------
playsound(path, ent)
	Precaches and plays sound on entity. Soundscripts or paths can be used. If you add sounds to your addon, build sound cache.
------------------------------------
pellets_count(weapon_name)
	Returns pellets count of weapon (1 for all firearm except shotguns, null for not furearm weapons).
 */

//---------- CODE ----------

this = ::root

log("[lib] including module_gamelogic")

/*mapname <- function() {
	//return SessionState.MapName
	local str = cvarstr("host_map")
	if (str.slice(str.len() - 4, str.len()) == ".bsp")
		str = str.slice(0, str.len() - 4)
	return str
}*/

mapname <- function() {
	if (!is_scripted_mode()) throw "mapname() works only in scripted mode"
	return SessionState.MapName
}

modename <- function() {
	return cvarstr("mp_gamemode")
}

/*basemodename <- function() {
	::_1_ <- @()log(1)
	::_2_ <- @()log(2)
	::_3_ <- @()log(3)
	::_4_ <- @()log(4)
	local _vsl_info_gamemode = SpawnEntityFromTable("info_gamemode", {});
	_vsl_info_gamemode.ConnectOutput( "OnCoop", "_1_" );
	_vsl_info_gamemode.ConnectOutput( "OnCoopPostIO", "_1_" );
	_vsl_info_gamemode.ConnectOutput( "OnVersusPostIO", "_2_" );
	_vsl_info_gamemode.ConnectOutput( "OnSurvivalPostIO", "_3_") ;
	_vsl_info_gamemode.ConnectOutput( "OnScavengePostIO", "_4_" );
}*/

skip_intro <- function() {
	IncludeScript("kapkan/lib/skipintro")
}

restart_game <- function(restore_cvars = true) {
	log("restarting...")
	EntFire("info_changelevel", "Disable")
	cvar("mp_restartgame", 1)
	if (restore_cvars) {
		cvars_restore_all()
		if (cvarf("sv_cheats") != 0) {
			Convars.SetValue("sv_cheats", 1)
			Convars.SetValue("sv_cheats", 0)
		} else {
			Convars.SetValue("sv_cheats", 0)
			Convars.SetValue("sv_cheats", 1)
		}
	}
}

stop_director <- function() {
	cvar("director_no_specials", 1)
	cvar("director_no_mobs", 1)
	cvar("director_no_bosses", 1)
	cvar("z_common_limit", 0)
	cvar("z_background_limit", 0)
}

is_scripted_mode <- function() {
	local answer = ("SessionState" in root)
	log("is_scripted_mode(): " + (answer ? "TRUE" : "FALSE"))
	return answer
}

/*
 * made with help of admin system
 */
increase_specials_limit <- function() {
	g_ModeScript.DirectorOptions.MaxSpecials <- 32
	if (is_scripted_mode()) {
		SessionOptions.MaxSpecials <- 32
		SessionOptions.cm_MaxSpecials <- 32
		SessionOptions.cm_DominatorLimit <- 32
		SessionOptions.SmokerLimit <- 32
		SessionOptions.BoomerLimit <- 32
		SessionOptions.HunterLimit <- 32
		SessionOptions.SpitterLimit <- 32
		SessionOptions.JockeyLimit <- 32
		SessionOptions.ChargerLimit <- 32
		SessionOptions.WitchLimit <- 32
		SessionOptions.cm_WitchLimit <- 32
		SessionOptions.TankLimit <- 32
		SessionOptions.cm_TankLimit <- 32
		if ("MutationOptions" in g_ModeScript) g_ModeScript.MutationOptions.MaxSpecials <- 32
		if ("MapOptions" in g_ModeScript) g_ModeScript.MapOptions.MaxSpecials <- 32
	} else {
		log("increase_specials_limit(): not a scripted mode, result is not guaranteed")
	}
}

stop_director_forced <- function() {
	if (Convars.GetStr("sv_cheats") == "0") throw "can't run stop_director_forced without sv_cheats";
	stop_director();
	SendToServerConsole("director_stop");
}

is_hitscan_weapon <- function(weapon_name) {
	return (weapon_name in __hitscan_weapon_table);
}

__hitscan_weapon_table <- {
	pistol = true,
	pistol_magnum = true,
	rifle_ak47 = true,
	rifle_desert = true,
	rifle_m60 = true,
	rifle_sg552 = true,
	rifle = true,
	pumpshotgun = true,
	shotgun_chrome = true,
	autoshotgun = true,
	shotgun_spas = true,
	smg_mp5 = true,
	smg_silenced = true,
	smg = true,
	hunting_rifle = true,
	sniper_military = true,
	sniper_scout = true,
	sniper_awp = true,
}

playsound <- function(sound_path, ent) {
	if (!(sound_path in __playsound_precached)) {
		ent.PrecacheScriptSound(sound_path);
		__playsound_precached[sound_path] <- true;
	}
	EmitSoundOn(sound_path, ent);
}

if (!("__playsound_precached" in this)) __playsound_precached <- {}

pellets_count <- function(weapon_name) {
	local pellets = {
		shotgun_chrome = 8,
		pumpshotgun = 10,
		shotgun_spas = 9,
		autoshotgun = 11
	}
	if (weapon_name in pellets) return pellets[weapon_name]
	if (is_hitscan_weapon(weapon_name)) return 1
	return null
}