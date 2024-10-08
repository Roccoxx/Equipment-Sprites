#include <amxmodx>
#include <engine>
#include <cstrike>
#include <fakemeta>

static const PLUGIN[] = "EQUIPMENT SPRITES"; static const VERSION[] = "1.2"; static const AUTHOR[] = "DaniwA & Roccoxx";

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
	SHOW_DOLAR_AND_ARROW_SPRITES,
	SHOW_WEAPONS_SPRITES,
	SHOW_NADES_AND_ARMOR_SPRITES
}
#endif

public plugin_precache(){
	new i;

	for(i = 0; i < sizeof(szMoneySprites); i++) 
		precache_model(szMoneySprites[i]);

	for(i = 0; i < sizeof(szWeaponsSprites); i++) 
		precache_model(szWeaponsSprites[i]);

	precache_model(szSpriteSign); 
	precache_model(szSpriteArrow);
}

public plugin_init(){
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_event("HLTV", "EventRoundStart", "a", "1=0", "2=0");

	register_think(szClassNameEntPijuda, "ShowSprites");

	#if defined REAPI_COMPATIBILITY
	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
	#else
	register_logevent("fwdRoundEnd", 2, "1=Round_End");
	register_message(get_user_msgid("TextMsg"), "TextMsgMessage");
	#endif
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

RemoveBaseEntity() {
	if (is_valid_ent(g_iEntPijuda)) {
		remove_entity(g_iEntPijuda);
		g_iEntPijuda = 0;
	}
}

public EventRoundStart() 
{
	RemoveBaseEntity();

	g_iEntPijuda = create_entity("info_target");

	if (is_valid_ent(g_iEntPijuda)) {
		entity_set_string(g_iEntPijuda, EV_SZ_classname, szClassNameEntPijuda);

		#if defined PREVENT_OVERFLOW
			entity_set_int(g_iEntPijuda, EV_INT_iuser1, SHOW_MONEY_SPRITES);
		#endif

		entity_set_float(g_iEntPijuda, EV_FL_nextthink, get_gametime() + SHOW_SPRITES_TIME);
	}

	remove_task(TASK_REMOVE_ENT);

	static Float:fTime; 
	fTime = get_cvar_float("mp_freezetime");

	if (fTime <= SHOW_SPRITES_TIME)
		fTime = SHOW_SPRITES_TIME + 1.0; // stupid bugfix

	set_task(fTime, "HideEntities", TASK_REMOVE_ENT);
}

public client_putinserver(id){
	SetPlayerBit(g_iIsConnected, id); 
	CreateEntitiesOnConnect(id);
}

public client_disconnected(id){
	if (GetPlayerBit(g_iIsConnected, id)) {
		ClearPlayerBit(g_iIsConnected, id);
		RemoveEntitiesOnDisconnect(id);
	}
}

CreateEntitiesOnConnect(const iId){
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

RemoveEntitiesOnDisconnect(const iId){
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
public ShowSprites(iEnt) {
	if (!is_valid_ent(iEnt)) 
		return PLUGIN_HANDLED;

	static i, j;
	static szMoney[6], szValue[2];
	static iWeapons, bPistols, bRifles, iArmortype;

	static iState;
	iState = entity_get_int(iEnt, EV_INT_iuser1);

	for (i = 1; i <= MAX_PLAYERS; i++) {
		if (!is_user_alive(i)) 
			continue;

		switch(iState) {
			case SHOW_MONEY_SPRITES: {
				arrayset(szMoney, 0, 6);

				num_to_str(cs_get_user_money(i), szMoney, charsmax(szMoney));

				for (j = 0; j < sizeof(szMoneySprites); j++) {
					szValue[0] = szMoney[j]; 
					szValue[1] = 0;

					if(!szMoney[j]) 
						DisplaySprite(g_iPlayerMoneySprites[i][j], i, 1.0, 34.0, 0, 0, 255, 0);
					else 
						DisplaySprite(g_iPlayerMoneySprites[i][j], i, floatstr(szValue), 34.0, 255, 0, 255, 0);
				}
			}
			case SHOW_DOLAR_AND_ARROW_SPRITES: {
				DisplaySprite(g_iPlayerDolarSign[i], i, 1.0, 34.0, 255, 0, 255, 0);
				DisplaySprite(g_iPlayerArrow[i], i, 1.0, 34.0, 255, 255, 255, 0);
			}
			case SHOW_WEAPONS_SPRITES: {
				iWeapons = pev(i, pev_weapons); 
				bPistols = false; 
				bRifles = false;

				for (j = 0; j < sizeof (fPistols); j++) {
					if (iWeapons & 1<<floatround(fPistols[j])) {
						DisplaySprite(g_iPlayerWeaponsSprites[i][0], i, fPistols[j], 50.0, 255, 255, 255, 0);
						bPistols = true;
					}
				}
				
				if (!bPistols) 
					DisplaySprite(g_iPlayerWeaponsSprites[i][0], i, fPistols[0], 50.0, 0, 255, 255, 0);

				for (j = 0; j < sizeof (fRifles); j++) {
					if (iWeapons & 1<<floatround(fRifles[j])) {
						DisplaySprite(g_iPlayerWeaponsSprites[i][1], i, fRifles[j], 50.0, 255, 255, 255, 0);
						bRifles = true;
					}
				}

				if (!bRifles) 
					DisplaySprite(g_iPlayerWeaponsSprites[i][1], i, fRifles[0], 50.0, 0, 255, 255, 0);
			}
			case SHOW_NADES_AND_ARMOR_SPRITES: {
				iWeapons = pev(i, pev_weapons); 

				if (iWeapons & 1<<CSW_HEGRENADE) 
					DisplaySprite(g_iPlayerWeaponsSprites[i][2], i, 4.0, 50.0, 255, 255, 255, 255);
				else
					DisplaySprite(g_iPlayerWeaponsSprites[i][2], i, 4.0, 50.0, 0, 255, 255, 255);
				
				if (iWeapons & 1<<CSW_FLASHBANG) 
					DisplaySprite(g_iPlayerWeaponsSprites[i][3], i, 25.0, 50.0, 255, 255, 255, 255);
				else 
					DisplaySprite(g_iPlayerWeaponsSprites[i][3], i, 25.0, 50.0, 0, 255, 255, 255);
				
				if (iWeapons & 1<<CSW_SMOKEGRENADE) 
					DisplaySprite(g_iPlayerWeaponsSprites[i][4], i, 9.0, 50.0, 255, 255, 255, 255);
				else 
					DisplaySprite(g_iPlayerWeaponsSprites[i][4], i, 9.0, 50.0, 0, 255, 255, 255);

				cs_get_user_armor(i, CsArmorType:iArmortype);
		
				if (iArmortype == 2) 
					DisplaySprite(g_iPlayerWeaponsSprites[i][5], i, 2.0, 50.0, 255, 0, 0, 255);
				else if (iArmortype == 1) 
					DisplaySprite(g_iPlayerWeaponsSprites[i][5], i, 1.0, 50.0, 255, 0, 0, 255);
				else 
					DisplaySprite(g_iPlayerWeaponsSprites[i][5], i, 1.0, 50.0, 0, 0, 0, 255);

				if (iWeapons & 1<<CSW_C4) 
					DisplaySprite(g_iPlayerWeaponsSprites[i][6], i, 3.0, 50.0, 255, 0, 0, 255);
				else if (cs_get_user_defuse(i)) 
					DisplaySprite(g_iPlayerWeaponsSprites[i][6], i, 4.0, 50.0, 255, 0, 0, 255);
				else 
					DisplaySprite(g_iPlayerWeaponsSprites[i][6], i, 3.0, 50.0, 0, 0, 0, 255);
			}
		}
	}

	if (iState == SHOW_NADES_AND_ARMOR_SPRITES)
		entity_set_int(iEnt, EV_INT_iuser1, SHOW_MONEY_SPRITES);
	else
		entity_set_int(iEnt, EV_INT_iuser1, ++iState);

	entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 0.3);

	return PLUGIN_CONTINUE;
}
#else
public ShowSprites(iEnt) {
	if (!is_valid_ent(iEnt)) 
		return PLUGIN_HANDLED;

	static i, j;
	static szMoney[6], szValue[2];
	static iWeapons, bPistols, bRifles, iArmortype;

	for (i = 1; i <= MAX_PLAYERS; i++) {
		if (!is_user_alive(i)) 
			continue;

		arrayset(szMoney, 0, 6);

		num_to_str(cs_get_user_money(i), szMoney, charsmax(szMoney));

		for (j = 0; j < sizeof(szMoneySprites); j++) {
			szValue[0] = szMoney[j]; 
			szValue[1] = 0;

			if(!szMoney[j]) 
				DisplaySprite(g_iPlayerMoneySprites[i][j], i, 1.0, 34.0, 0, 0, 255, 0);
			else 
				DisplaySprite(g_iPlayerMoneySprites[i][j], i, floatstr(szValue), 34.0, 255, 0, 255, 0);
		}

		DisplaySprite(g_iPlayerDolarSign[i], i, 1.0, 34.0, 255, 0, 255, 0);
		DisplaySprite(g_iPlayerArrow[i], i, 1.0, 34.0, 255, 255, 255, 0);

		iWeapons = pev(i, pev_weapons); 
		bPistols = false; 
		bRifles = false;
		
		for (j = 0; j < sizeof (fPistols); j++) {
			if (iWeapons & 1<<floatround(fPistols[j])) {
				DisplaySprite(g_iPlayerWeaponsSprites[i][0], i, fPistols[j], 50.0, 255, 255, 255, 0);
				bPistols = true;
			}
		}
		
		if (!bPistols) 
			DisplaySprite(g_iPlayerWeaponsSprites[i][0], i, fPistols[0], 50.0, 0, 255, 255, 0);

		for (j = 0; j < sizeof (fRifles); j++) {
			if (iWeapons & 1<<floatround(fRifles[j])) {
				DisplaySprite(g_iPlayerWeaponsSprites[i][1], i, fRifles[j], 50.0, 255, 255, 255, 0);
				bRifles = true;
			}
		}

		if (!bRifles) 
			DisplaySprite(g_iPlayerWeaponsSprites[i][1], i, fRifles[0], 50.0, 0, 255, 255, 0);
		
		if (iWeapons & 1<<CSW_HEGRENADE) 
			DisplaySprite(g_iPlayerWeaponsSprites[i][2], i, 4.0, 50.0, 255, 255, 255, 255);
		else
			DisplaySprite(g_iPlayerWeaponsSprites[i][2], i, 4.0, 50.0, 0, 255, 255, 255);
		
		if (iWeapons & 1<<CSW_FLASHBANG) 
			DisplaySprite(g_iPlayerWeaponsSprites[i][3], i, 25.0, 50.0, 255, 255, 255, 255);
		else 
			DisplaySprite(g_iPlayerWeaponsSprites[i][3], i, 25.0, 50.0, 0, 255, 255, 255);
		
		if (iWeapons & 1<<CSW_SMOKEGRENADE) 
			DisplaySprite(g_iPlayerWeaponsSprites[i][4], i, 9.0, 50.0, 255, 255, 255, 255);
		else 
			DisplaySprite(g_iPlayerWeaponsSprites[i][4], i, 9.0, 50.0, 0, 255, 255, 255);

		cs_get_user_armor(i, CsArmorType:iArmortype);
		
		if (iArmortype == 2) 
			DisplaySprite(g_iPlayerWeaponsSprites[i][5], i, 2.0, 50.0, 255, 0, 0, 255);
		else if (iArmortype == 1) 
			DisplaySprite(g_iPlayerWeaponsSprites[i][5], i, 1.0, 50.0, 255, 0, 0, 255);
		else 
			DisplaySprite(g_iPlayerWeaponsSprites[i][5], i, 1.0, 50.0, 0, 0, 0, 255);

		if (iWeapons & 1<<CSW_C4) 
			DisplaySprite(g_iPlayerWeaponsSprites[i][6], i, 3.0, 50.0, 255, 0, 0, 255);
		else if (cs_get_user_defuse(i)) 
			DisplaySprite(g_iPlayerWeaponsSprites[i][6], i, 4.0, 50.0, 255, 0, 0, 255);
		else 
			DisplaySprite(g_iPlayerWeaponsSprites[i][6], i, 3.0, 50.0, 0, 0, 0, 255);
	}

	entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 1.0);
	return PLUGIN_CONTINUE;
}
#endif

DisplaySprite(const iEnt, iPlayer, Float:fFrame, Float:fOffset, const iRender, const iRed, const iGreen, const iBlue)
{
	if (!is_valid_ent(iEnt)) 
		return;

	entity_set_float(iEnt, EV_FL_frame, fFrame);
	set_ent_rendering(iEnt, kRenderFxNone, iRed, iGreen, iBlue, kRenderTransAdd, iRender);

	static Float:vPlayerOrigin[3];
	entity_get_vector(iPlayer, EV_VEC_origin, vPlayerOrigin);
	vPlayerOrigin[2] += fOffset + 10.0; 

	entity_set_origin(iEnt, vPlayerOrigin);
}

SetEntityAttribs(const iEnt, const szModel[]){
	entity_set_model(iEnt, szModel);
	entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_NOCLIP);
	entity_set_float(iEnt, EV_FL_framerate, 1.0);
	entity_set_float(iEnt, EV_FL_scale, 0.3);

	set_ent_rendering(iEnt, kRenderFxNone, _, _, _, kRenderTransAdd, 0);
}

public HideEntities()
{
	RemoveBaseEntity();

	new i;

	for (new iId = 1; iId <= MAX_PLAYERS; iId++)
	{
		for (i = 0; i < sizeof(szMoneySprites); i++)
			if (is_valid_ent(g_iPlayerMoneySprites[iId][i])) 
				set_ent_rendering(g_iPlayerMoneySprites[iId][i], kRenderFxNone, _, _, _, kRenderTransAdd, 0);

		for (i = 0; i < WEAPON_SPRITES; i++)
			if (is_valid_ent(g_iPlayerWeaponsSprites[iId][i]))
				set_ent_rendering(g_iPlayerWeaponsSprites[iId][i], kRenderFxNone, _, _, _, kRenderTransAdd, 0);
	
		if (is_valid_ent(g_iPlayerDolarSign[iId])) 
			set_ent_rendering(g_iPlayerDolarSign[iId], kRenderFxNone, _, _, _, kRenderTransAdd, 0);

		if (is_valid_ent(g_iPlayerArrow[iId]))
			set_ent_rendering(g_iPlayerArrow[iId], kRenderFxNone, _, _, _, kRenderTransAdd, 0);
	}
}

// WORK ON AMX_OFF
public plugin_cfg() 
	if (is_plugin_loaded("Pause Plugins") != -1) 
		server_cmd("amx_pausecfg add ^"%s^"", PLUGIN);