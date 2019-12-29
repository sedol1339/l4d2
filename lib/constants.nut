this = getroottable()
local constants = getconsttable()

//director constants
constants.ALLOW_BASH_ALL <- 0;
constants.ALLOW_BASH_NONE <- 2;
constants.ALLOW_BASH_PUSHONLY <- 1;
constants.BOT_CANT_FEEL <- 4;
constants.BOT_CANT_HEAR <- 2;
constants.BOT_CANT_SEE <- 1;
constants.BOT_CMD_ATTACK <- 0;
constants.BOT_CMD_MOVE <- 1;
constants.BOT_CMD_RESET <- 3;
constants.BOT_CMD_RETREAT <- 2;
constants.BOT_QUERY_NOTARGET <- 1;
constants.DMG_BLAST <- 64;
constants.DMG_BLAST_SURFACE <- 134217728;
constants.DMG_BUCKSHOT <- 536870912;
constants.DMG_BULLET <- 2;
constants.DMG_BURN <- 8;
constants.DMG_HEADSHOT <- 1073741824;
constants.DMG_MELEE <- 2097152;
constants.DMG_STUMBLE <- 33554432;
constants.FINALE_CUSTOM_CLEAROUT <- 11;
constants.FINALE_CUSTOM_DELAY <- 10;
constants.FINALE_CUSTOM_PANIC <- 7;
constants.FINALE_CUSTOM_SCRIPTED <- 9;
constants.FINALE_CUSTOM_TANK <- 8;
constants.FINALE_FINAL_BOSS <- 5;
constants.FINALE_GAUNTLET_1 <- 0;
constants.FINALE_GAUNTLET_2 <- 3;
constants.FINALE_GAUNTLET_BOSS <- 16;
constants.FINALE_GAUNTLET_BOSS_INCOMING <- 15;
constants.FINALE_GAUNTLET_ESCAPE <- 17;
constants.FINALE_GAUNTLET_HORDE <- 13;
constants.FINALE_GAUNTLET_HORDE_BONUSTIME <- 14;
constants.FINALE_GAUNTLET_START <- 12;
constants.FINALE_HALFTIME_BOSS <- 2;
constants.FINALE_HORDE_ATTACK_1 <- 1;
constants.FINALE_HORDE_ATTACK_2 <- 4;
constants.FINALE_HORDE_ESCAPE <- 6;
constants.HUD_FAR_LEFT <- 7;
constants.HUD_FAR_RIGHT <- 8;
constants.HUD_FLAG_ALIGN_CENTER <- 512;
constants.HUD_FLAG_ALIGN_LEFT <- 256;
constants.HUD_FLAG_ALIGN_RIGHT <- 768;
constants.HUD_FLAG_ALLOWNEGTIMER <- 128;
constants.HUD_FLAG_AS_TIME <- 16;
constants.HUD_FLAG_BEEP <- 4;
constants.HUD_FLAG_BLINK <- 8;
constants.HUD_FLAG_COUNTDOWN_WARN <- 32;
constants.HUD_FLAG_NOBG <- 64;
constants.HUD_FLAG_NOTVISIBLE <- 16384;
constants.HUD_FLAG_POSTSTR <- 2;
constants.HUD_FLAG_PRESTR <- 1;
constants.HUD_FLAG_TEAM_INFECTED <- 2048;
constants.HUD_FLAG_TEAM_MASK <- 3072;
constants.HUD_FLAG_TEAM_SURVIVORS <- 1024;
constants.HUD_LEFT_BOT <- 1;
constants.HUD_LEFT_TOP <- 0;
constants.HUD_MID_BOT <- 3;
constants.HUD_MID_BOX <- 9;
constants.HUD_MID_TOP <- 2;
constants.HUD_RIGHT_BOT <- 5;
constants.HUD_RIGHT_TOP <- 4;
constants.HUD_SCORE_1 <- 11;
constants.HUD_SCORE_2 <- 12;
constants.HUD_SCORE_3 <- 13;
constants.HUD_SCORE_4 <- 14;
constants.HUD_SCORE_TITLE <- 10;
constants.HUD_SPECIAL_COOLDOWN <- 4;
constants.HUD_SPECIAL_MAPNAME <- 6;
constants.HUD_SPECIAL_MODENAME <- 7;
constants.HUD_SPECIAL_ROUNDTIME <- 5;
constants.HUD_SPECIAL_TIMER0 <- 0;
constants.HUD_SPECIAL_TIMER1 <- 1;
constants.HUD_SPECIAL_TIMER2 <- 2;
constants.HUD_SPECIAL_TIMER3 <- 3;
constants.HUD_TICKER <- 6;
constants.INFECTED_FLAG_CANT_FEEL_SURVIVORS <- 32768;
constants.INFECTED_FLAG_CANT_HEAR_SURVIVORS <- 16384;
constants.INFECTED_FLAG_CANT_SEE_SURVIVORS <- 8192;
constants.IN_ATTACK <- 1;
constants.IN_ATTACK2 <- 2048;
constants.IN_BACK <- 16;
constants.IN_CANCEL <- 64;
constants.IN_DUCK <- 4;
constants.IN_FORWARD <- 8;
constants.IN_JUMP <- 2;
constants.IN_LEFT <- 512;
constants.IN_RELOAD <- 8192;
constants.IN_RIGHT <- 1024;
constants.IN_USE <- 32;
constants.SCRIPTED_SPAWN_BATTLEFIELD <- 2;
constants.SCRIPTED_SPAWN_FINALE <- 0;
constants.SCRIPTED_SPAWN_POSITIONAL <- 3;
constants.SCRIPTED_SPAWN_SURVIVORS <- 1;
constants.SCRIPT_SHUTDOWN_EXIT_GAME <- 4;
constants.SCRIPT_SHUTDOWN_LEVEL_TRANSITION <- 3;
constants.SCRIPT_SHUTDOWN_MANUAL <- 0;
constants.SCRIPT_SHUTDOWN_ROUND_RESTART <- 1;
constants.SCRIPT_SHUTDOWN_TEAM_SWAP <- 2;
constants.SPAWNDIR_E <- 4;
constants.SPAWNDIR_N <- 1;
constants.SPAWNDIR_NE <- 2;
constants.SPAWNDIR_NW <- 128;
constants.SPAWNDIR_S <- 16;
constants.SPAWNDIR_SE <- 8;
constants.SPAWNDIR_SW <- 32;
constants.SPAWNDIR_W <- 64;
constants.SPAWN_ABOVE_SURVIVORS <- 6;
constants.SPAWN_ANYWHERE <- 0;
constants.SPAWN_BATTLEFIELD <- 2;
constants.SPAWN_BEHIND_SURVIVORS <- 1;
constants.SPAWN_FAR_AWAY_FROM_SURVIVORS <- 5;
constants.SPAWN_FINALE <- 0;
constants.SPAWN_IN_FRONT_OF_SURVIVORS <- 7;
constants.SPAWN_LARGE_VOLUME <- 9;
constants.SPAWN_NEAR_IT_VICTIM <- 2;
constants.SPAWN_NEAR_POSITION <- 10;
constants.SPAWN_NO_PREFERENCE <- -1;
constants.SPAWN_POSITIONAL <- 3;
constants.SPAWN_SPECIALS_ANYWHERE <- 4;
constants.SPAWN_SPECIALS_IN_FRONT_OF_SURVIVORS <- 3;
constants.SPAWN_SURVIVORS <- 1;
constants.SPAWN_VERSUS_FINALE_DISTANCE <- 8;
constants.STAGE_CLEAROUT <- 4;
constants.STAGE_DELAY <- 2;
constants.STAGE_ESCAPE <- 7;
constants.STAGE_NONE <- 9;
constants.STAGE_PANIC <- 0;
constants.STAGE_RESULTS <- 8;
constants.STAGE_SETUP <- 5;
constants.STAGE_TANK <- 1;
constants.TIMER_COUNTDOWN <- 2;
constants.TIMER_COUNTUP <- 1;
constants.TIMER_DISABLE <- 0;
constants.TIMER_SET <- 4;
constants.TIMER_STOP <- 3;
constants.TRACE_MASK_ALL <- -1;
constants.TRACE_MASK_NPC_SOLID <- 33701899;
constants.TRACE_MASK_PLAYER_SOLID <- 33636363;
constants.TRACE_MASK_SHOT <- 1174421507;
constants.TRACE_MASK_VISIBLE_AND_NPCS <- 33579137;
constants.TRACE_MASK_VISION <- 33579073;
constants.UPGRADE_EXPLOSIVE_AMMO <- 1;
constants.UPGRADE_INCENDIARY_AMMO <- 0;
constants.UPGRADE_LASER_SIGHT <- 2;
constants.ZOMBIE_BOOMER <- 2;
constants.ZOMBIE_CHARGER <- 6;
constants.ZOMBIE_HUNTER <- 3;
constants.ZOMBIE_JOCKEY <- 5;
constants.ZOMBIE_NORMAL <- 0;
constants.ZOMBIE_SMOKER <- 1;
constants.ZOMBIE_SPITTER <- 4;
constants.ZOMBIE_TANK <- 8;
constants.ZOMBIE_WITCH <- 7;
constants.ZSPAWN_MOB <- 10;
constants.ZSPAWN_MUDMEN <- 12;
constants.ZSPAWN_WITCHBRIDE <- 11;

//sourcemod entity_prop_stocks.inc constants (for "m_nRenderMode")
constants.RENDER_NORMAL <- 0;
constants.RENDER_TRANSCOLOR <- 1;
constants.RENDER_TRANSTEXTURE <- 2;
constants.RENDER_GLOW <- 3; //no Z buffer checks -- fixed size in screen space
constants.RENDER_TRANSALPHA <- 4;
constants.RENDER_TRANSADD <- 5;
constants.RENDER_ENVIRONMENTAL <- 6; //not drawn, used for environmental effects
constants.RENDER_TRANSADDFRAMEBLEND <- 7; //use a fractional frame value to blend between animation frames
constants.RENDER_TRANSALPHAADD <- 8;
constants.RENDER_WORLDGLOW <- 9; //same as kRenderGlow but not fixed size in screen space
constants.RENDER_NONE <- 10; //don't render

//renderfx constants (for "renderfx" keyvalue)
constants.RENDERFX_NONE <- 0;
constants.RENDERFX_PULSE_SLOW <- 1;
constants.RENDERFX_PULSE_FAST <- 2;
constants.RENDERFX_PULSE_SLOW_WIDE <- 3;
constants.RENDERFX_PULSE_FAST_WIDE <- 4;
constants.RENDERFX_FADE_SLOW <- 5;
constants.RENDERFX_FADE_FAST <- 6;
constants.RENDERFX_SOLID_SLOW <- 7;
constants.RENDERFX_SOLID_FAST <- 8;
constants.RENDERFX_STROBE_SLOW <- 9;
constants.RENDERFX_STROBE_FAST <- 10;
constants.RENDERFX_STROBE_FASTER <- 11;
constants.RENDERFX_FLICKER_SLOW <- 12;
constants.RENDERFX_FLICKER_FAST <- 13;
constants.RENDERFX_NO_DISSIPATION <- 14;
constants.RENDERFX_DISTORT <- 15;            /**< Distort/scale/translate flicker */
constants.RENDERFX_HOLOGRAM <- 16;           /**< kRenderFxDistort + distance fade */
constants.RENDERFX_EXPLODE <- 17;            /**< Scale up really big! */
constants.RENDERFX_GLOWSHELL <- 18;            /**< Glowing Shell */
constants.RENDERFX_CLAMP_MIN_SCALE <- 19;    /**< Keep this sprite from getting very small (SPRITES only!) */
constants.RENDERFX_ENV_RAIN <- 20;            /**< for environmental rendermode, make rain */
constants.RENDERFX_ENV_SNOW <- 21;            /**<  "        "            "    , make snow */
constants.RENDERFX_SPOTLIGHT <- 22;            /**< TEST CODE for experimental spotlight */
constants.RENDERFX_RAGDOLL <- 23;            /**< HACKHACK: TEST CODE for signalling death of a ragdoll character */
constants.RENDERFX_PULSE_FAST_WIDER <- 24;
constants.RENDERFX_MAX <- 25;
constants.RENDERFX_FADE_NEAR <- 26;

//player specific flag numbers from sourcemod entity_prop_stocks.inc (for "m_fFlags")
constants.FL_ONGROUND <- (1 << 0); //at rest/on the ground
constants.FL_DUCKING <- (1 << 1); //player is fully crouched
constants.FL_WATERJUMP <- (1 << 2); //player jumping out of water
constants.FL_ONTRAIN <- (1 << 3); //player is controlling a train, so movement commands should be ignored on client during prediction
constants.FL_INRAIN <- (1 << 4); //indicates the entity is standing in rain
constants.FL_FROZEN <- (1 << 5); //player is frozen for 3rd person camera
constants.FL_ATCONTROLS <- (1 << 6); //player can't move, but keeps key inputs for controlling another entity
constants.FL_CLIENT <- (1 << 7); //is a player
constants.FL_FAKECLIENT <- (1 << 8); //fake client, simulated server side; don't send network messages to them

//non-player specific flag numbers from sourcemod entity_prop_stocks.inc (for "m_fFlags")
constants.FL_INWATER <- (1 << 9); //in water
constants.FL_FLY <- (1 << 10); //changes the SV_Movestep() behavior to not need to be on ground
constants.FL_SWIM <- (1 << 11); //changes the SV_Movestep() behavior to not need to be on ground (but stay in water)
constants.FL_CONVEYOR <- (1 << 12);
constants.FL_NPC <- (1 << 13);
constants.FL_GODMODE <- (1 << 14);
constants.FL_NOTARGET <- (1 << 15);
constants.FL_AIMTARGET <- (1 << 16); //set if the crosshair needs to aim onto the entity
constants.FL_PARTIALGROUND <- (1 << 17); //not all corners are valid
constants.FL_STATICPROP <- (1 << 18); //eetsa static prop!
constants.FL_GRAPHED <- (1 << 19); //worldgraph has this ent listed as something that blocks a connection
constants.FL_GRENADE <- (1 << 20);
constants.FL_STEPMOVEMENT <- (1 << 21); //changes the SV_Movestep() behavior to not do any processing
constants.FL_DONTTOUCH <- (1 << 22); //doesn't generate touch functions, generates Untouch() for anything it was touching when this flag was set
constants.FL_BASEVELOCITY <- (1 << 23); //base velocity has been applied this frame (used to convert base velocity into momentum)
constants.FL_WORLDBRUSH <- (1 << 24); //not moveable/removeable brush entity (really part of the world, but represented as an entity for transparency or something)
constants.FL_OBJECT <- (1 << 25); //terrible name. This is an object that NPCs should see. Missiles, for example
constants.FL_KILLME <- (1 << 26); //this entity is marked for death -- will be freed by game DLL
constants.FL_ONFIRE <- (1 << 27); //you know...
constants.FL_DISSOLVING <- (1 << 28); //we're dissolving!
constants.FL_TRANSRAGDOLL <- (1 << 29); //in the process of turning into a client side ragdoll
constants.FL_UNBLOCKABLE_BY_PLAYER <- (1 << 30); //pusher that can't be blocked by the player
constants.FL_FREEZING <- (1 << 31); //we're becoming frozen!
constants.FL_EP2V_UNKNOWN1 <- (1 << 31); //unknown

//damage types from SDKHooks, partially collides with director constants
constants.DMG_GENERIC <- 0;
constants.DMG_CRUSH <- 1;
constants.DMG_BULLET <- 2;
constants.DMG_SLASH <- 4;
constants.DMG_BURN <- 8;
constants.DMG_VEHICLE <- 16;
constants.DMG_FALL <- 32;
constants.DMG_BLAST <- 64;
constants.DMG_CLUB <- 128;
constants.DMG_SHOCK <- 256;
constants.DMG_SONIC <- 512;
constants.DMG_ENERGYBEAM <- 1024;
constants.DMG_PREVENT_PHYSICS_FORCE <- 2048;
constants.DMG_NEVERGIB <- 4096;
constants.DMG_ALWAYSGIB <- 8192;
constants.DMG_DROWN <- 16384;
constants.DMG_PARALYZE <- 32768;
constants.DMG_NERVEGAS <- 65536;
constants.DMG_POISON <- 131072;
constants.DMG_RADIATION <- 262144;
constants.DMG_DROWNRECOVER <- 524288;
constants.DMG_ACID <- 1048576;
constants.DMG_SLOWBURN <- 2097152;
constants.DMG_REMOVENORAGDOLL <- 4194304;
constants.DMG_PHYSGUN <- 8388608;
constants.DMG_PLASMA <- 16777216;
constants.DMG_AIRBOAT <- 33554432;
constants.DMG_DISSOLVE <- 67108864;
constants.DMG_BLAST_SURFACE <- 134217728;
constants.DMG_DIRECT <- 268435456;
constants.DMG_BUCKSHOT <- 536870912;

//solid types m_nSolidType
constants.SOLID_NONE <- 0; // no solid model
constants.SOLID_BSP <- 1; // a BSP tree
constants.SOLID_BBOX <- 2; // an AABB
constants.SOLID_OBB <- 3; // an OBB (not implemented yet)
constants.SOLID_OBB_YAW <- 4; // an OBB, constrained so that it can only yaw
constants.SOLID_CUSTOM <- 5; // Always call into the entity for tests
constants.SOLID_VPHYSICS <- 6; // solid vphysics object, get vcollide from the model and collide with that

//extended buttons constants (for GetButtonMask(), "m_nButtons", "m_afButtonForced")
constants.IN_ATTACK <- (1 << 0);
constants.IN_JUMP <- (1 << 1);
constants.IN_DUCK <- (1 << 2);
constants.IN_FORWARD <- (1 << 3);
constants.IN_BACK <- (1 << 4);
constants.IN_USE <- (1 << 5);
constants.IN_CANCEL <- (1 << 6);
constants.IN_LEFT <- (1 << 7);
constants.IN_RIGHT <- (1 << 8);
constants.IN_MOVELEFT <- (1 << 9);
constants.IN_MOVERIGHT <- (1 << 10);
constants.IN_ATTACK2 <- (1 << 11);
constants.IN_RUN <- (1 << 12);
constants.IN_RELOAD <- (1 << 13);
constants.IN_ALT1 <- (1 << 14);
constants.IN_ALT2 <- (1 << 15);
constants.IN_SCORE <- (1 << 16);   // Used by client.dll for when scoreboard is held down
constants.IN_SPEED <- (1 << 17);	// Player is holding the speed key (+speed, or shift in L4D2)
constants.IN_WALK <- (1 << 18);	// Player holding walk key
constants.IN_ZOOM <- (1 << 19);	// Zoom key for HUD zoom
constants.IN_WEAPON1 <- (1 << 20);	// weapon defines these bits
constants.IN_WEAPON2 <- (1 << 21);	// weapon defines these bits
constants.IN_BULLRUSH <- (1 << 22);
constants.IN_GRENADE1 <- (1 << 23);	// grenade 1
constants.IN_GRENADE2 <- (1 << 24);	// grenade 2
constants.IN_ATTACK3 <- (1 << 25);

// (for "movetype")
constants.MOVETYPE_NONE <- 0; //Don't move
constants.MOVETYPE_ISOMETRIC <- 1; //For players, in TF2 commander view, etc
constants.MOVETYPE_WALK <- 2; //Player only, moving on the ground
constants.MOVETYPE_STEP <- 3; //Monster/NPC movement
constants.MOVETYPE_FLY <- 4; //Fly, no gravity
constants.MOVETYPE_FLYGRAVITY <- 5; //Fly, with gravity
constants.MOVETYPE_VPHYSICS <- 6; //Physics movetype
constants.MOVETYPE_PUSH <- 7; //No clip to world, but pushes and crushes things
constants.MOVETYPE_NOCLIP <- 8; //Noclip
constants.MOVETYPE_LADDER <- 9; //For players, when moving on a ladder
constants.MOVETYPE_OBSERVER <- 10; //Spectator movetype. DO NOT use this to make player spectate
constants.MOVETYPE_CUSTOM <- 11; //Custom movetype, can be applied to the player to prevent the default movement code from running, while still calling the related hooks

//for trigger spawnflags
constants.SF_TRIGGER_ALLOW_CLIENTS <- 0x01		// Players can fire this trigger
constants.SF_TRIGGER_ALLOW_NPCS <- 0x02		// NPCS can fire this trigger
constants.SF_TRIGGER_ALLOW_PUSHABLES <- 0x04		// Pushables can fire this trigger
constants.SF_TRIGGER_ALLOW_PHYSICS <- 0x08		// Physics objects can fire this trigger
constants.SF_TRIGGER_ONLY_PLAYER_ALLY_NPCS <- 0x10		// *if* NPCs can fire this trigger, this flag means only player allies do so
constants.SF_TRIGGER_ONLY_CLIENTS_IN_VEHICLES <- 0x20		// *if* Players can fire this trigger, this flag means only players inside vehicles can 
constants.SF_TRIGGER_ALLOW_ALL <- 0x40		// Everything can fire this trigger EXCEPT DEBRIS!
constants.SF_TRIGGER_ONLY_CLIENTS_OUT_OF_VEHICLES <- 0x200	// *if* Players can fire this trigger, this flag means only players outside vehicles can 
constants.SF_TRIG_PUSH_ONCE <- 0x80		// trigger_push removes itself after firing once
constants.SF_TRIG_PUSH_AFFECT_PLAYER_ON_LADDER <- 0x100	// if pushed object is player on a ladder, then this disengages them from the ladder (HL2only)
constants.SF_TRIG_TOUCH_DEBRIS <- 0x400	// Will touch physics debris objects
constants.SF_TRIGGER_ONLY_NPCS_IN_VEHICLES <- 0x800	// *if* NPCs can fire this trigger, only NPCs in vehicles do so (respects player ally flag too)
constants.SF_TRIGGER_DISALLOW_BOTS <- 0x1000   // Bots are not allowed to fire this trigger

//m_CollisionGroup
constants.COLLISION_GROUP_NONE <- 0	//Normal
constants.COLLISION_GROUP_DEBRIS <- 1	//Collides with nothing but world and static stuff
constants.COLLISION_GROUP_DEBRIS_TRIGGER <- 2	//Same as debris, but hits triggers. Useful for an item that can be shot, but doesn't collide.
constants.COLLISION_GROUP_INTERACTIVE_DEBRIS <- 3	//Collides with everything except other interactive debris or debris
constants.COLLISION_GROUP_INTERACTIVE <- 4	//Collides with everything except interactive debris or debris
constants.COLLISION_GROUP_PLAYER <- 5	
constants.COLLISION_GROUP_BREAKABLE_GLASS <- 6	//NPCs can see straight through an Entity with this applied.
constants.COLLISION_GROUP_VEHICLE <- 7	
constants.COLLISION_GROUP_PLAYER_MOVEMENT <- 8	//For HL2, same as Collision_Group_Player, for TF2, this filters out other players and CBaseObjects
constants.COLLISION_GROUP_NPC <- 9	
constants.COLLISION_GROUP_IN_VEHICLE <- 10	//Doesn't collide with anything, no traces
constants.COLLISION_GROUP_WEAPON <- 11	//Doesn't collide with players and vehicles
constants.COLLISION_GROUP_VEHICLE_CLIP <- 12	//Only collides with vehicles
constants.COLLISION_GROUP_PROJECTILE <- 13	
constants.COLLISION_GROUP_DOOR_BLOCKER <- 14	//Blocks entities not permitted to get near moving doors
constants.COLLISION_GROUP_PASSABLE_DOOR <- 15	//Let's the Player through, nothing else.
constants.COLLISION_GROUP_DISSOLVING <- 16	//Things that are dissolving are in this group
constants.COLLISION_GROUP_PUSHAWAY <- 17	//Nonsolid on client and server, pushaway in player code
constants.COLLISION_GROUP_NPC_ACTOR <- 18	
constants.COLLISION_GROUP_NPC_SCRIPTED <- 19	
constants.COLLISION_GROUP_WORLD <- 20	//Doesn't collide with players/props

//movecollide
constants.MOVECOLLIDE_DEFAULT <- 0,
// These ones only work for MOVETYPE_FLY + MOVETYPE_FLYGRAVITY
constants.MOVECOLLIDE_FLY_BOUNCE <- 1,	// bounces, reflects, based on elasticity of surface and object - applies friction (adjust velocity)
constants.MOVECOLLIDE_FLY_CUSTOM <- 2,	// Touch() will modify the velocity however it likes
constants.MOVECOLLIDE_FLY_SLIDE <- 3,  // slides along surfaces (no bounce) - applies friciton (adjusts velocity)

//m_usSolidFlags
constants.FSOLID_CUSTOMRAYTEST <- 1	//Ignore solid type + always call into the entity for ray tests
constants.FSOLID_CUSTOMBOXTEST <- 2	//Ignore solid type + always call into the entity for swept box tests
constants.FSOLID_NOT_SOLID <- 4	//The object is currently not solid
constants.FSOLID_TRIGGER <- 8	//This is something may be collideable but fires touch functions even when it's not collideable (when the FSOLID_NOT_SOLID flag is set)
constants.FSOLID_NOT_STANDABLE <- 16	//The player can't stand on this
constants.FSOLID_VOLUME_CONTENTS <- 32	//Contains volumetric contents (like water)
constants.FSOLID_FORCE_WORLD_ALIGNED <- 64	//Forces the collision representation to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
constants.FSOLID_USE_TRIGGER_BOUNDS <- 128	//Uses a special trigger bounds separate from the normal OBB
constants.FSOLID_ROOT_PARENT_ALIGNED <- 256	//Collisions are defined in root parent's local coordinate space
constants.FSOLID_TRIGGER_TOUCH_DEBRIS <- 512	//This trigger will touch debris objects

//m_iAddonBits - which items to show on a player
constants.CSAddon_NONE <- 0
constants.CSAddon_Flashbang1 <- (1 << 0)
constants.CSAddon_Flashbang2 <- (1 << 1)
constants.CSAddon_HEGrenade <- (1 << 2)
constants.CSAddon_SmokeGrenade <- (1 << 3)
constants.CSAddon_C4 <- (1 << 4)
constants.CSAddon_DefuseKit <- (1 << 5)
constants.CSAddon_PrimaryWeapon <- (1 << 6)
constants.CSAddon_SecondaryWeapon <- (1 << 7)
constants.CSAddon_Holster <- (1 << 8)

//look https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/public/const.h for other constants

constants.INF <- 10e100000000

constants.RAD_TO_DEG <- 57.2957795

/////// VSLIB CONSTANTS ///////

constants.UNKNOWN <- 0 /* Anything that is unknown. */
constants.SPECTATORS <- 1
constants.SURVIVORS <- 2
constants.INFECTED <- 3
constants.L4D1_SURVIVORS <- 4

constants.MALE <- 1
constants.FEMALE <- 2

constants.Z_INFECTED <- 0;
constants.Z_COMMON <- 0;
constants.Z_SMOKER <- 1;
constants.Z_BOOMER <- 2;
constants.Z_HUNTER <- 3;
constants.Z_SPITTER <- 4;
constants.Z_JOCKEY <- 5;
constants.Z_CHARGER <- 6;
constants.Z_WITCH <- 7;
constants.Z_TANK <- 8;
constants.Z_SURVIVOR <- 9;
constants.Z_MOB <- 10;
constants.Z_WITCH_BRIDE <- 11;

constants.Z_CEDA <- 11;
constants.Z_MUD <- 12;
constants.Z_ROADCREW <- 13;
constants.Z_FALLEN <- 14;
constants.Z_RIOT <- 15;
constants.Z_CLOWN <- 16;
constants.Z_JIMMY <- 17;

constants.NICK <- 0;
constants.ROCHELLE <- 1;
constants.COACH <- 2;
constants.ELLIS <- 3;
constants.BILL <- 4;
constants.ZOEY <- 5;
constants.FRANCIS <- 6;
constants.LOUIS <- 7;
constants.SURVIVOR <- 9;

constants.AMMOTYPE_PISTOL <- 1;
constants.AMMOTYPE_MAGNUM <- 2;
constants.AMMOTYPE_ASSAULTRIFLE <- 3;
constants.AMMOTYPE_MINIGUN <- 4;
constants.AMMOTYPE_SMG <- 5;
constants.AMMOTYPE_M60 <- 6;
constants.AMMOTYPE_SHOTGUN <- 7;
constants.AMMOTYPE_AUTOSHOTGUN <- 8;
constants.AMMOTYPE_HUNTINGRIFLE <- 9;
constants.AMMOTYPE_SNIPERRIFLE <- 10;
constants.AMMOTYPE_TURRET <- 11;
constants.AMMOTYPE_PIPEBOMB <- 12;
constants.AMMOTYPE_MOLOTOV <- 13;
constants.AMMOTYPE_VOMITJAR <- 14;
constants.AMMOTYPE_PAINPILLS <- 15;
constants.AMMOTYPE_FIRSTAID <- 16;
constants.AMMOTYPE_GRENADELAUNCHER <- 17;
constants.AMMOTYPE_ADRENALINE <- 18;
constants.AMMOTYPE_CHAINSAW <- 19;

constants.BUTTON_ATTACK <- 1;
constants.BUTTON_JUMP <- 2;
constants.BUTTON_DUCK <- 4;
constants.BUTTON_FORWARD <- 8;
constants.BUTTON_BACK <- 16;
constants.BUTTON_USE <- 32;
constants.BUTTON_CANCEL <- 64;
constants.BUTTON_LEFT <- 128;
constants.BUTTON_RIGHT <- 256;
constants.BUTTON_MOVELEFT <- 512; // move left key (e.g. A)
constants.BUTTON_MOVERIGHT <- 1024; // move right key (e.g. D)
constants.BUTTON_SHOVE <- 2048;
constants.BUTTON_RUN <- 4096;
constants.BUTTON_RELOAD <- 8192;
constants.BUTTON_ALT1 <- 16384;
constants.BUTTON_ALT2 <- 32768;
constants.BUTTON_SCORE <- 65536;   // Used by client.dll for when scoreboard is held down
constants.BUTTON_WALK <- 131072; // Player is holding the walk key
constants.BUTTON_ZOOM <- 524288; // Zoom key
constants.BUTTON_WEAPON1 <- 1048576; // weapon defines these bits
constants.BUTTON_WEAPON2 <- 2097152; // weapon defines these bits
constants.BUTTON_BULLRUSH <- 4194304;
constants.BUTTON_GRENADE1 <- 8388608; // grenade 1
constants.BUTTON_GRENADE2 <- 16777216; // grenade 2
constants.BUTTON_LOOKSPIN <- 0x2000000; // lookspin if bound #shotgunefx

constants.DAMAGE_NO <- 0;
constants.DAMAGE_EVENTS_ONLY <- 1;
constants.DAMAGE_YES <- 2;
constants.DAMAGE_AIM <- 3;

constants.CONTENTS_EMPTY <-			0;		/**< No contents. */
constants.CONTENTS_SOLID <-			0x1;		/**< an eye is never valid in a solid . */
constants.CONTENTS_WINDOW <-			0x2;		/**< translucent, but not watery (glass). */
constants.CONTENTS_AUX <-			0x4;
constants.CONTENTS_GRATE <-			0x8;		/**< alpha-tested "grate" textures.  Bullets/sight pass through, but solids don't. */
constants.CONTENTS_SLIME <-			0x10;
constants.CONTENTS_WATER <-			0x20;
constants.CONTENTS_MIST <-			0x40;
constants.CONTENTS_OPAQUE <-			0x80;		/**< things that cannot be seen through (may be non-solid though). */
constants.LAST_VISIBLE_CONTENTS <-	0x80;
constants.ALL_VISIBLE_CONTENTS <- 	(constants.LAST_VISIBLE_CONTENTS | (constants.LAST_VISIBLE_CONTENTS-1))
constants.CONTENTS_TESTFOGVOLUME <-	0x100;
constants.CONTENTS_UNUSED5 <-		0x200;
constants.CONTENTS_UNUSED6 <-		0x4000;
constants.CONTENTS_TEAM1 <-			0x800;		/**< per team contents used to differentiate collisions. */
constants.CONTENTS_TEAM2 <-			0x1000;		/**< between players and objects on different teams. */
constants.CONTENTS_IGNORE_NODRAW_OPAQUE <-	0x2000;		/**< ignore CONTENTS_OPAQUE on surfaces that have SURF_NODRAW. */
constants.CONTENTS_MOVEABLE <-		0x4000;		/**< hits entities which are MOVETYPE_PUSH (doors, plats, etc) */
constants.CONTENTS_AREAPORTAL <-		0x8000;		/**< remaining contents are non-visible, and don't eat brushes. */
constants.CONTENTS_PLAYERCLIP <-		0x10000;
constants.CONTENTS_MONSTERCLIP <-	0x20000;
constants.CONTENTS_ORIGIN <-			0x1000000;	/**< removed before bsping an entity. */
constants.CONTENTS_MONSTER <-		0x2000000;	/**< should never be on a brush, only in game. */
constants.CONTENTS_DEBRIS <-			0x4000000;
constants.CONTENTS_DETAIL <-			0x8000000;	/**< brushes to be added after vis leafs. */
constants.CONTENTS_TRANSLUCENT <-	0x10000000;	/**< auto set if any surface has trans. */
constants.CONTENTS_LADDER <-			0x20000000;
constants.CONTENTS_HITBOX <-			0x40000000;	/**< use accurate hitboxes on trace. */

constants.MASK_WATER <-(constants.CONTENTS_WATER|constants.CONTENTS_MOVEABLE|constants.CONTENTS_SLIME) /**< water physics in these contents */
constants.MASK_OPAQUE <-(constants.CONTENTS_SOLID|constants.CONTENTS_MOVEABLE|constants.CONTENTS_OPAQUE) /**< everything that blocks line of sight for AI, lighting, etc */
constants.MASK_OPAQUE_AND_NPCS <-(constants.MASK_OPAQUE|constants.CONTENTS_MONSTER)/**< everything that blocks line of sight for AI, lighting, etc, but with monsters added. */
constants.MASK_VISIBLE <-(constants.MASK_OPAQUE|constants.CONTENTS_IGNORE_NODRAW_OPAQUE) /**< everything that blocks line of sight for players */
constants.MASK_VISIBLE_AND_NPCS <-(constants.MASK_OPAQUE_AND_NPCS|constants.CONTENTS_IGNORE_NODRAW_OPAQUE) /**< everything that blocks line of sight for players, but with monsters added. */
constants.MASK_SHOT_HULL <-(constants.CONTENTS_SOLID|constants.CONTENTS_MOVEABLE|constants.CONTENTS_MONSTER|constants.CONTENTS_WINDOW|constants.CONTENTS_DEBRIS|constants.CONTENTS_GRATE) /**< non-raycasted weapons see this as solid (includes grates) */
constants.MASK_SHOT_PORTAL <-(constants.CONTENTS_SOLID|constants.CONTENTS_MOVEABLE|constants.CONTENTS_WINDOW) /**< hits solids (not grates) and passes through everything else */
constants.MASK_SOLID_BRUSHONLY <-(constants.CONTENTS_SOLID|constants.CONTENTS_MOVEABLE|constants.CONTENTS_WINDOW|constants.CONTENTS_GRATE) /**< everything normally solid, except monsters (world+brush only) */
constants.MASK_PLAYERSOLID_BRUSHONLY <-(constants.CONTENTS_SOLID|constants.CONTENTS_MOVEABLE|constants.CONTENTS_WINDOW|constants.CONTENTS_PLAYERCLIP|constants.CONTENTS_GRATE) /**< everything normally solid for player movement, except monsters (world+brush only) */
constants.MASK_NPCSOLID_BRUSHONLY <-(constants.CONTENTS_SOLID|constants.CONTENTS_MOVEABLE|constants.CONTENTS_WINDOW|constants.CONTENTS_MONSTERCLIP|constants.CONTENTS_GRATE) /**< everything normally solid for npc movement, except monsters (world+brush only) */
constants.MASK_NPCWORLDSTATIC <-(constants.CONTENTS_SOLID|constants.CONTENTS_WINDOW|constants.CONTENTS_MONSTERCLIP|constants.CONTENTS_GRATE) /**< just the world, used for route rebuilding */
constants.MASK_SPLITAREAPORTAL <-(constants.CONTENTS_WATER|constants.CONTENTS_SLIME) /**< These are things that can split areaportals */

///////////////////////////////////////////////////////

foreach (constant, value in constants)
	getroottable()[constant] <- value