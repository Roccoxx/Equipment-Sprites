#include <amxmodx>
#include <engine>
#include <cstrike>
#include <fakemeta>

static const PLUGIN[] = "EQUIPMENT SPRITES"; static const VERSION[] = "1.3"; static const AUTHOR[] = "DaniwA & Roccoxx";

//#define REAPI_COMPATIBILITY
//#define PREVENT_OVERFLOW 1 // Uncomment this if you have players with high ping and overflow problems9

#if defined REAPI_COMPATIBILITY
#include <reapi>
#else
static const szMessageGameRestart[] = "#Game_will_restart_in";
#endif

#pragma semicolon 1

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)
#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))

/// ================== MONEY ===================================
const WEAPON_SPRITES = 7;

static const szMoneySprites[][] = {"sprites/10000.spr", "sprites/1000.spr", "sprites/100.spr", "sprites/10.spr", "sprites/1.spr"};
static const szWeaponsSprites[][] = {"sprites/weap.spr", "sprites/weap2.spr"};
static const szSpriteSign[] = "sprites/cash.spr";
static const szSpriteArrow[] = "sprites/arrow.spr";

static g_iPlayerMoneySprites[33][5], g_iPlayerWeaponsSprites[33][WEAPON_SPRITES], g_iPlayerDolarSign[33], g_iPlayerArrow[33];

static const Float:fPistols[6] = {1.0,10.0,11.0,16.0,17.0,26.0};
static const Float:fRifles[18] = {3.0,5.0,7.0,8.0,12.0,13.0,14.0,15.0,18.0,19.0,20.0,21.0,22.0,23.0,24.0,27.0,28.0,30.0};

static g_iIsConnected;

const TASK_REMOVE_ENT = 6969;
static const szClassNameEntPijuda[] = "EntityPijuda";
static g_iEntPijuda;
static const Float:SHOW_SPRITES_TIME = 0.2;

#if defined PREVENT_OVERFLOW
enum {
	SHOW_MONEY_SPRITES,
	SHOW_WEAPONS_SPRITES,
	SHOW_NADES_AND_ARMOR_SPRITES,
	SHOW_C4_AND_DEFUSE_SPRITES
}
#endif

//// CVARS
enum SPRITE_COLORS{
	CVAR_SPRITE_WEAPON_COLOR,
	CVAR_SPRITE_MONEY_COLOR,
	CVAR_SPRITE_GRENADES_COLOR,
	CVAR_SPRITE_KEVLAR_HELMET_COLOR,
	CVAR_SPRITE_KEVLAR_COLOR,
	CVAR_SPRITE_ARROW_COLOR,
	CVAR_SPRITE_BOMB_COLOR,
	CVAR_SPRITE_DEFUSE_COLOR,
}

static g_iCvarList[SPRITE_COLORS];

public plugin_precache()
{
	new i;

	for(i = 0; i < sizeof(szMoneySprites); i++) 
		precache_model(szMoneySprites[i]);

	for(i = 0; i < sizeof(szWeaponsSprites); i++) 
		precache_model(szWeaponsSprites[i]);

	precache_model(szSpriteSign); 
	precache_model(szSpriteArrow);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_event("HLTV", "EventRoundStart", "a", "1=0", "2=0");

	register_think(szClassNameEntPijuda, "ShowSprites");

	#if defined REAPI_COMPATIBILITY
		RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
	#else
		register_logevent("fwdRoundEnd", 2, "1=Round_End");
		register_message(get_user_msgid("TextMsg"), "TextMsgMessage");
	#endif

	g_iCvarList[CVAR_SPRITE_WEAPON_COLOR] =	register_cvar("se_sprite_color_weapons", "255255000"); // default yellow
	g_iCvarList[CVAR_SPRITE_MONEY_COLOR] = register_cvar("se_sprite_color_money", "000255000"); // default green
	g_iCvarList[CVAR_SPRITE_GRENADES_COLOR] = register_cvar("se_sprite_color_grenades", "255255255"); // default white
	g_iCvarList[CVAR_SPRITE_KEVLAR_HELMET_COLOR] = register_cvar("se_sprite_color_vesthelm", "080000200"); // default purple
	g_iCvarList[CVAR_SPRITE_KEVLAR_COLOR] =	register_cvar("se_sprite_color_kevlar", "200000200"); // default pink
	g_iCvarList[CVAR_SPRITE_ARROW_COLOR] = register_cvar("se_sprite_color_arrow", "255255000"); // default yellow
	g_iCvarList[CVAR_SPRITE_BOMB_COLOR] = register_cvar("se_sprite_color_c4", "220080000"); // default orange
	g_iCvarList[CVAR_SPRITE_DEFUSE_COLOR] =	register_cvar("se_sprite_color_defusekit", "000255000"); // default green
}

#if defined REAPI_COMPATIBILITY
public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{
	ClearEntitiesForRoundEnding();
}
#else
public fwdRoundEnd()
{
	ClearEntitiesForRoundEnding();
}

public TextMsgMessage()
{
	static szMsg[22]; 
	get_msg_arg_string(2, szMsg, charsmax(szMsg));
	
	if(equal(szMsg, szMessageGameRestart))
		fwdRoundEnd();
}
#endif

ClearEntitiesForRoundEnding()
{
	remove_task(TASK_REMOVE_ENT); 
	HideEntities();
}

public EventRoundStart() 
{
	RemoveBaseEntity();
	CreateBaseEntity();
	TaskHideEntites();
}

public client_putinserver(id)
{
	SetPlayerBit(g_iIsConnected, id); 
	CreateEntitiesOnConnect(id);
}

public client_disconnected(id)
{
	if (GetPlayerBit(g_iIsConnected, id)) {
		ClearPlayerBit(g_iIsConnected, id);
		RemoveEntitiesOnDisconnect(id);
	}
}

CreateEntitiesOnConnect(const iId)
{
	new i;
	for (i = 0; i < sizeof(szMoneySprites); i++) {
		g_iPlayerMoneySprites[iId][i] = create_entity("env_sprite");

		if(is_valid_ent(g_iPlayerMoneySprites[iId][i])) 
			SetEntityAttribs(g_iPlayerMoneySprites[iId][i], szMoneySprites[i]);
	}

	for (i = 0; i < WEAPON_SPRITES; i++) {
		g_iPlayerWeaponsSprites[iId][i] = create_entity("env_sprite");

		if(is_valid_ent(g_iPlayerWeaponsSprites[iId][i])) 
			SetEntityAttribs(g_iPlayerWeaponsSprites[iId][i], (i < 5) ? szWeaponsSprites[0] : szWeaponsSprites[1]);
	}
	
	g_iPlayerDolarSign[iId] = create_entity("env_sprite"); 

	if (is_valid_ent(g_iPlayerDolarSign[iId])) 
		SetEntityAttribs(g_iPlayerDolarSign[iId], szSpriteSign);

	g_iPlayerArrow[iId] = create_entity("env_sprite"); 

	if (is_valid_ent(g_iPlayerArrow[iId]))
 		SetEntityAttribs(g_iPlayerArrow[iId], szSpriteArrow);
}

RemoveEntitiesOnDisconnect(const iId)
{
	new i;

	for (i = 0; i < sizeof(szMoneySprites); i++) {
		if (is_valid_ent(g_iPlayerMoneySprites[iId][i])) {
			remove_entity(g_iPlayerMoneySprites[iId][i]);
			g_iPlayerMoneySprites[iId][i] = 0;
		}
	}

	for (i = 0; i < WEAPON_SPRITES; i++) {
		if (is_valid_ent(g_iPlayerWeaponsSprites[iId][i])) {
			remove_entity(g_iPlayerWeaponsSprites[iId][i]);
			g_iPlayerWeaponsSprites[iId][i] = 0;
		}
	}

	if (is_valid_ent(g_iPlayerDolarSign[iId])) {
		remove_entity(g_iPlayerDolarSign[iId]);
		g_iPlayerDolarSign[iId] = 0;
	}

	if (is_valid_ent(g_iPlayerArrow[iId])) {
		remove_entity(g_iPlayerArrow[iId]); 
		g_iPlayerArrow[iId] = 0;
	}
}

#if defined PREVENT_OVERFLOW
public ShowSprites(iEnt)
{
	if (!is_valid_ent(iEnt)) 
		return PLUGIN_HANDLED;

	static iId, iWeapons;

	static iState;
	iState = entity_get_int(iEnt, EV_INT_iuser1);

	static Float:fPlayerOrigin[3];

	for (iId = 1; iId <= MAX_PLAYERS; iId++) {
		if (!is_user_alive(iId)) 
			continue;

		entity_get_vector(iId, EV_VEC_origin, fPlayerOrigin);

		switch(iState) {
			case SHOW_MONEY_SPRITES: {
				ShowMoneySprites(iId, fPlayerOrigin);
			}
			case SHOW_WEAPONS_SPRITES: {
				iWeapons = pev(iId, pev_weapons); 

				ShowPistolsSprites(iId, fPlayerOrigin, iWeapons);
				ShowRiflesSprites(iId, fPlayerOrigin, iWeapons);
			}
			case SHOW_NADES_AND_ARMOR_SPRITES: {
				iWeapons = pev(iId, pev_weapons); 

				ShowGrenadesSprites(iId, fPlayerOrigin, iWeapons);
				ShowArmorSprites(iId, fPlayerOrigin);
			}
			case SHOW_C4_AND_DEFUSE_SPRITES: {
				iWeapons = pev(iId, pev_weapons); 
				ShowC4AndDefuseSprites(iId, fPlayerOrigin, iWeapons);
			}
		}
	}

	if (iState == SHOW_C4_AND_DEFUSE_SPRITES)
		entity_set_int(iEnt, EV_INT_iuser1, SHOW_MONEY_SPRITES);
	else
		entity_set_int(iEnt, EV_INT_iuser1, ++iState);

	entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 0.3);

	return PLUGIN_CONTINUE;
}
#else
public ShowSprites(iEnt)
{
	if (!is_valid_ent(iEnt)) 
		return PLUGIN_HANDLED;

	static i;
	for (i = 1; i <= MAX_PLAYERS; i++) {
		if (!is_user_alive(i))
			continue;

		ShowAllPlayerSprites(i);
	}

	entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 1.0);
	return PLUGIN_CONTINUE;
}

ShowAllPlayerSprites(const iPlayer)
{
	if (!is_user_alive(iPlayer))
		return;

	static iWeapons;
	iWeapons = pev(iPlayer, pev_weapons); 

	static Float:fPlayerOrigin[3];
	entity_get_vector(iPlayer, EV_VEC_origin, fPlayerOrigin);

	ShowMoneySprites(iPlayer, fPlayerOrigin);
	ShowPistolsSprites(iPlayer, fPlayerOrigin, iWeapons);
	ShowRiflesSprites(iPlayer, fPlayerOrigin, iWeapons);
	ShowGrenadesSprites(iPlayer, fPlayerOrigin, iWeapons);
	ShowArmorSprites(iPlayer, fPlayerOrigin);
	ShowC4AndDefuseSprites(iPlayer, fPlayerOrigin, iWeapons);
}
#endif

ShowMoneySprites(const iPlayer, const Float:fPlayerOrigin[3])
{
	static iColor[3];
	ConvertCvarToRGB(get_pcvar_num(g_iCvarList[CVAR_SPRITE_MONEY_COLOR]), iColor);

	static szMoney[6], szValue[2], j;
	arrayset(szMoney, 0, 6);

	num_to_str(cs_get_user_money(iPlayer), szMoney, charsmax(szMoney));

	for (j = 0; j < sizeof(szMoneySprites); j++) {
		szValue[0] = szMoney[j]; 
		szValue[1] = 0;

		if(!szMoney[j]) 
			DisplaySprite(g_iPlayerMoneySprites[iPlayer][j], fPlayerOrigin, 1.0, 34.0, 0, iColor[0], iColor[1], iColor[2]);
		else 
			DisplaySprite(g_iPlayerMoneySprites[iPlayer][j], fPlayerOrigin, floatstr(szValue), 34.0, 255, iColor[0], iColor[1], iColor[2]);
	}

	DisplaySprite(g_iPlayerDolarSign[iPlayer], fPlayerOrigin, 1.0, 34.0, 255, iColor[0], iColor[1], iColor[2]);

	ConvertCvarToRGB(get_pcvar_num(g_iCvarList[CVAR_SPRITE_ARROW_COLOR]), iColor);
	DisplaySprite(g_iPlayerArrow[iPlayer], fPlayerOrigin, 1.0, 34.0, 255, iColor[0], iColor[1], iColor[2]);
}

ShowPistolsSprites(const iPlayer, const Float:fPlayerOrigin[3], const iWeapons)
{
	static iColor[3];
	ConvertCvarToRGB(get_pcvar_num(g_iCvarList[CVAR_SPRITE_WEAPON_COLOR]), iColor);

	static j;
	static bPistols;
	bPistols= false;

	for (j = 0; j < sizeof (fPistols); j++) {
		if (iWeapons & 1<<floatround(fPistols[j])) {
			DisplaySprite(g_iPlayerWeaponsSprites[iPlayer][0], fPlayerOrigin, fPistols[j], 50.0, 255, iColor[0], iColor[1], iColor[2]);
			bPistols = true;
		}
	}
	
	if (!bPistols) 
		DisplaySprite(g_iPlayerWeaponsSprites[iPlayer][0], fPlayerOrigin, fPistols[0], 50.0, 0, iColor[0], iColor[1], iColor[2]);
}

ShowRiflesSprites(const iPlayer, const Float:fPlayerOrigin[3], const iWeapons)
{
	static iColor[3];
	ConvertCvarToRGB(get_pcvar_num(g_iCvarList[CVAR_SPRITE_WEAPON_COLOR]), iColor);

	static j;
	static bRifles;
	bRifles = false;

	for (j = 0; j < sizeof (fRifles); j++) {
		if (iWeapons & 1<<floatround(fRifles[j])) {
			DisplaySprite(g_iPlayerWeaponsSprites[iPlayer][1], fPlayerOrigin, fRifles[j], 50.0, 255, iColor[0], iColor[1], iColor[2]);
			bRifles = true;
		}
	}

	if (!bRifles) 
		DisplaySprite(g_iPlayerWeaponsSprites[iPlayer][1], fPlayerOrigin, fRifles[0], 50.0, 0, iColor[0], iColor[1], iColor[2]);
}

ShowGrenadesSprites(const iPlayer, const Float:fPlayerOrigin[3], const iWeapons)
{
	static iColor[3];
	ConvertCvarToRGB(get_pcvar_num(g_iCvarList[CVAR_SPRITE_GRENADES_COLOR]), iColor);

	if (iWeapons & 1<<CSW_HEGRENADE) 
		DisplaySprite(g_iPlayerWeaponsSprites[iPlayer][2], fPlayerOrigin, 4.0, 50.0, 255, iColor[0], iColor[1], iColor[2]);
	else
		DisplaySprite(g_iPlayerWeaponsSprites[iPlayer][2], fPlayerOrigin, 4.0, 50.0, 0, iColor[0], iColor[1], iColor[2]);
	
	if (iWeapons & 1<<CSW_FLASHBANG) 
		DisplaySprite(g_iPlayerWeaponsSprites[iPlayer][3], fPlayerOrigin, 25.0, 50.0, 255, iColor[0], iColor[1], iColor[2]);
	else 
		DisplaySprite(g_iPlayerWeaponsSprites[iPlayer][3], fPlayerOrigin, 25.0, 50.0, 0, iColor[0], iColor[1], iColor[2]);
	
	if (iWeapons & 1<<CSW_SMOKEGRENADE) 
		DisplaySprite(g_iPlayerWeaponsSprites[iPlayer][4], fPlayerOrigin, 9.0, 50.0, 255, iColor[0], iColor[1], iColor[2]);
	else 
		DisplaySprite(g_iPlayerWeaponsSprites[iPlayer][4], fPlayerOrigin, 9.0, 50.0, 0, iColor[0], iColor[1], iColor[2]);
}

ShowArmorSprites(const iPlayer, const Float:fPlayerOrigin[3])
{
	static iColor[3];

	static iArmortype;
	cs_get_user_armor(iPlayer, CsArmorType:iArmortype);
	
	switch (iArmortype) {
		case CS_ARMOR_VESTHELM: {
			ConvertCvarToRGB(get_pcvar_num(g_iCvarList[CVAR_SPRITE_KEVLAR_HELMET_COLOR]), iColor);
			DisplaySprite(g_iPlayerWeaponsSprites[iPlayer][5], fPlayerOrigin, 2.0, 50.0, 255, iColor[0], iColor[1], iColor[2]);
		}
		case CS_ARMOR_KEVLAR: {
			ConvertCvarToRGB(get_pcvar_num(g_iCvarList[CVAR_SPRITE_KEVLAR_COLOR]), iColor);
			DisplaySprite(g_iPlayerWeaponsSprites[iPlayer][5], fPlayerOrigin, 1.0, 50.0, 255, iColor[0], iColor[1], iColor[2]);
		}
		case CS_ARMOR_NONE: {
			DisplaySprite(g_iPlayerWeaponsSprites[iPlayer][5], fPlayerOrigin, 1.0, 50.0, 0, 0, 0, 0);
		}
	}
}

ShowC4AndDefuseSprites(const iPlayer, const Float:fPlayerOrigin[3], const iWeapons)
{
	static iColor[3];

	if (iWeapons & 1<<CSW_C4) {
		ConvertCvarToRGB(get_pcvar_num(g_iCvarList[CVAR_SPRITE_BOMB_COLOR]), iColor);
		DisplaySprite(g_iPlayerWeaponsSprites[iPlayer][6], fPlayerOrigin, 3.0, 50.0, 255, iColor[0], iColor[1], iColor[2]);
	}
	else if (cs_get_user_defuse(iPlayer)) {
		ConvertCvarToRGB(get_pcvar_num(g_iCvarList[CVAR_SPRITE_DEFUSE_COLOR]), iColor);
		DisplaySprite(g_iPlayerWeaponsSprites[iPlayer][6], fPlayerOrigin, 4.0, 50.0, 255, iColor[0], iColor[1], iColor[2]);
	}
	else 
		DisplaySprite(g_iPlayerWeaponsSprites[iPlayer][6], fPlayerOrigin, 3.0, 50.0, 0, 0, 0, 0);
}

DisplaySprite(const iEnt, const Float:fPlayerOrigin[3], Float:fFrame, Float:fOffset, const iRender, const iRed, const iGreen, const iBlue)
{
	if (!is_valid_ent(iEnt)) 
		return;

	entity_set_float(iEnt, EV_FL_frame, fFrame);
	set_ent_rendering(iEnt, kRenderFxNone, iRed, iGreen, iBlue, kRenderTransAdd, iRender);

	static Float:fOrigin[3];
	fOrigin[0] = fPlayerOrigin[0];
	fOrigin[1] = fPlayerOrigin[1];
	fOrigin[2] = fPlayerOrigin[2] + fOffset + 10.0;
	entity_set_origin(iEnt, fOrigin);
}

SetEntityAttribs(const iEnt, const szModel[])
{
	entity_set_model(iEnt, szModel);
	entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_NOCLIP);
	entity_set_float(iEnt, EV_FL_framerate, 1.0);
	entity_set_float(iEnt, EV_FL_scale, 0.3);

	set_ent_rendering(iEnt, kRenderFxNone, _, _, _, kRenderTransAdd, 0);
}

RemoveBaseEntity()
{
	if (is_valid_ent(g_iEntPijuda)) {
		remove_entity(g_iEntPijuda);
		g_iEntPijuda = 0;
	}
}

CreateBaseEntity()
{
	g_iEntPijuda = create_entity("info_target");

	if (is_valid_ent(g_iEntPijuda)) {
		entity_set_string(g_iEntPijuda, EV_SZ_classname, szClassNameEntPijuda);

		#if defined PREVENT_OVERFLOW
			entity_set_int(g_iEntPijuda, EV_INT_iuser1, SHOW_MONEY_SPRITES);
		#endif

		entity_set_float(g_iEntPijuda, EV_FL_nextthink, get_gametime() + SHOW_SPRITES_TIME);
	}
}

TaskHideEntites()
{
	remove_task(TASK_REMOVE_ENT);

	static Float:fTime; 
	fTime = get_cvar_float("mp_freezetime");

	if (fTime <= SHOW_SPRITES_TIME)
		fTime = SHOW_SPRITES_TIME + 1.0; // stupid bugfix

	set_task(fTime, "HideEntities", TASK_REMOVE_ENT);
}

public HideEntities()
{
	RemoveBaseEntity();

	for (new iPlayer = 1; iPlayer <= MAX_PLAYERS; iPlayer++) {
		if (GetPlayerBit(g_iIsConnected, iPlayer))
			HidePlayerSprites(iPlayer);
	}
}

HidePlayerSprites(const iId)
{
	new i;
	for (i = 0; i < sizeof(szMoneySprites); i++) {
		if (is_valid_ent(g_iPlayerMoneySprites[iId][i])) 
			set_ent_rendering(g_iPlayerMoneySprites[iId][i], kRenderFxNone, _, _, _, kRenderTransAdd, 0);
	}

	for (i = 0; i < WEAPON_SPRITES; i++) {
		if (is_valid_ent(g_iPlayerWeaponsSprites[iId][i]))
			set_ent_rendering(g_iPlayerWeaponsSprites[iId][i], kRenderFxNone, _, _, _, kRenderTransAdd, 0);
	}
	
	if (is_valid_ent(g_iPlayerDolarSign[iId])) 
		set_ent_rendering(g_iPlayerDolarSign[iId], kRenderFxNone, _, _, _, kRenderTransAdd, 0);

	if (is_valid_ent(g_iPlayerArrow[iId]))
		set_ent_rendering(g_iPlayerArrow[iId], kRenderFxNone, _, _, _, kRenderTransAdd, 0);
}

// WORK ON AMX_OFF
public plugin_cfg() 
{
	if (is_plugin_loaded("Pause Plugins") != -1) 
		server_cmd("amx_pausecfg add ^"%s^"", PLUGIN);
}

ConvertCvarToRGB(pCvar, iColor[3])
{
	iColor[0] = (pCvar / 1000000);
	pCvar %= 1000000;
	iColor[1] = (pCvar / 1000);
	iColor[2] = (pCvar % 1000);
}