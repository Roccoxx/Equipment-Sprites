#include <amxmodx>
#include <engine>
#include <cstrike>
#include <fakemeta>

#pragma semicolon 1

static const PLUGIN[] = "EQUIPMENT SPRITES"; static const VERSION[] = "1.0"; static const AUTHOR[] = "DaniwA & Roccoxx";

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

static const szMessageGameRestart[] = "#Game_will_restart_in";

public plugin_precache(){
	new i;

	for(i = 0; i < sizeof(szMoneySprites); i++) precache_model(szMoneySprites[i]);
	for(i = 0; i < sizeof(szWeaponsSprites); i++) precache_model(szWeaponsSprites[i]);

	precache_model(szSpriteSign); precache_model(szSpriteArrow);
}

public plugin_init(){
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_event("HLTV", "EventRoundStart", "a", "1=0", "2=0");

	register_think(szClassNameEntPijuda, "ShowSprites");

	register_logevent("LogEventRoundEnd", 2, "1=Round_End");
	register_message(get_user_msgid("TextMsg"), "TextMsgMessage");
}

public LogEventRoundEnd(){
	remove_task(TASK_REMOVE_ENT); HideEntities();
}

public TextMsgMessage()
{
	static szMsg[22]; get_msg_arg_string(2, szMsg, charsmax(szMsg));
	
	if(equal(szMsg, szMessageGameRestart)) LogEventRoundEnd();
}

public EventRoundStart(){
	remove_task(TASK_REMOVE_ENT); set_task(get_cvar_float("mp_freezetime"), "HideEntities", TASK_REMOVE_ENT);

	g_iEntPijuda = create_entity("info_target");
	if(is_valid_ent(g_iEntPijuda)){
		entity_set_string(g_iEntPijuda, EV_SZ_classname, szClassNameEntPijuda);
		entity_set_float(g_iEntPijuda, EV_FL_nextthink, get_gametime() + 0.2);
	}
}

public client_putinserver(id){
	SetPlayerBit(g_iIsConnected, id); CreateEntitiesOnConnect(id);
}

public client_disconnected(id){
	if(GetPlayerBit(g_iIsConnected, id)){
		ClearPlayerBit(g_iIsConnected, id);
		RemoveEntitiesOnDisconnect(id);
	}
}

CreateEntitiesOnConnect(const iId){
	new i;
	for(i = 0; i < sizeof(szMoneySprites); i++){
		g_iPlayerMoneySprites[iId][i] = create_entity("env_sprite");

		if(is_valid_ent(g_iPlayerMoneySprites[iId][i])) SetEntityAttribs(g_iPlayerMoneySprites[iId][i], szMoneySprites[i]);
	}

	for(i = 0; i < WEAPON_SPRITES; i++){
		g_iPlayerWeaponsSprites[iId][i] = create_entity("env_sprite");

		if(is_valid_ent(g_iPlayerWeaponsSprites[iId][i])) SetEntityAttribs(g_iPlayerWeaponsSprites[iId][i], (i < 5) ? szWeaponsSprites[0] : szWeaponsSprites[1]);
	}
	
	g_iPlayerDolarSign[iId] = create_entity("env_sprite"); if(is_valid_ent(g_iPlayerDolarSign[iId])) SetEntityAttribs(g_iPlayerDolarSign[iId], szSpriteSign);
	g_iPlayerArrow[iId] = create_entity("env_sprite"); if(is_valid_ent(g_iPlayerArrow[iId])) SetEntityAttribs(g_iPlayerArrow[iId], szSpriteArrow);
}

RemoveEntitiesOnDisconnect(const iId){
	new i;
	for(i = 0; i < sizeof(szMoneySprites); i++){
		remove_entity(g_iPlayerMoneySprites[iId][i]);
		g_iPlayerMoneySprites[iId][i] = 0;
	}
	for(i = 0; i < WEAPON_SPRITES; i++){
		remove_entity(g_iPlayerWeaponsSprites[iId][i]);
		g_iPlayerWeaponsSprites[iId][i] = 0;
	}

	remove_entity(g_iPlayerDolarSign[iId]); g_iPlayerDolarSign[iId] = 0;
	remove_entity(g_iPlayerArrow[iId]); g_iPlayerArrow[iId] = 0;
}

public ShowSprites(iEnt){
	if(!is_valid_ent(iEnt)) return PLUGIN_HANDLED;

	static i, j;
	static iMoney, szMoney[6], szValue[2];
	static iWeapons, bPistols, bRifles, iArmortype;

	for(i = 1; i <= MAX_PLAYERS; i++){
		if(!is_user_alive(i)) continue;

		iMoney = cs_get_user_money(i); num_to_str(iMoney, szMoney, charsmax(szMoney));

		for(j = 0; j < sizeof(szMoneySprites); j++){
			szValue[0] = szMoney[j]; szValue[1] = 0;

			if(!szMoney[j]) DisplaySprite(g_iPlayerMoneySprites[i][j], i, 1.0, 34.0, 0, 0, 255, 0);
			else DisplaySprite(g_iPlayerMoneySprites[i][j], i, floatstr(szValue), 34.0, 255,0, 255, 0);
		}

		DisplaySprite(g_iPlayerDolarSign[i], i, 1.0, 34.0, 255, 0, 255, 0);
		DisplaySprite(g_iPlayerArrow[i], i, 1.0, 34.0, 255, 255, 255, 0);

		iWeapons = pev(i, pev_weapons); bPistols = false; bRifles = false;
		
		for(j = 0; j < sizeof (fPistols); j++){
			if(iWeapons & 1<<floatround(fPistols[j])){
				DisplaySprite(g_iPlayerWeaponsSprites[i][0], i, fPistols[j], 50.0, 255, 255, 255, 0);
				bPistols = true;
			}
		}
		
		if(!bPistols) DisplaySprite(g_iPlayerWeaponsSprites[i][0], i, fPistols[0], 50.0, 0, 255, 255, 0);

		for(j = 0; j < sizeof (fRifles); j++){
			if(iWeapons & 1<<floatround(fRifles[j])){
				DisplaySprite(g_iPlayerWeaponsSprites[i][1], i, fRifles[j], 50.0, 255, 255, 255, 0);
				bRifles = true;
			}
		}

		if(!bRifles) DisplaySprite(g_iPlayerWeaponsSprites[i][1], i, fRifles[0], 50.0, 0, 255, 255, 0);
		
		if(iWeapons & 1<<CSW_HEGRENADE) DisplaySprite(g_iPlayerWeaponsSprites[i][2], i, 4.0, 50.0, 255, 255, 255, 255);
		else DisplaySprite(g_iPlayerWeaponsSprites[i][2], i, 4.0, 50.0, 0, 255, 255, 255);
		
		if(iWeapons & 1<<CSW_FLASHBANG) DisplaySprite(g_iPlayerWeaponsSprites[i][3], i, 25.0, 50.0, 255, 255, 255, 255);
		else DisplaySprite(g_iPlayerWeaponsSprites[i][3], i, 25.0, 50.0, 0, 255, 255, 255);
		
		if(iWeapons & 1<<CSW_SMOKEGRENADE) DisplaySprite(g_iPlayerWeaponsSprites[i][4], i, 9.0, 50.0, 255, 255, 255, 255);
		else DisplaySprite(g_iPlayerWeaponsSprites[i][4], i, 9.0, 50.0, 0, 255, 255, 255);

		cs_get_user_armor(i, CsArmorType:iArmortype);
		if(iArmortype == 2) DisplaySprite(g_iPlayerWeaponsSprites[i][5], i, 2.0, 50.0, 255, 0, 0, 255);
		else if(iArmortype == 1) DisplaySprite(g_iPlayerWeaponsSprites[i][5], i, 1.0, 50.0, 255, 0, 0, 255);
		else DisplaySprite(g_iPlayerWeaponsSprites[i][5], i, 1.0, 50.0, 0, 0, 0, 255);

		if(iWeapons & 1<<CSW_C4) DisplaySprite(g_iPlayerWeaponsSprites[i][6], i, 3.0, 50.0, 255, 0, 0, 255);
		else if(cs_get_user_defuse(i)) DisplaySprite(g_iPlayerWeaponsSprites[i][6], i, 4.0, 50.0, 255, 0, 0, 255);
		else DisplaySprite(g_iPlayerWeaponsSprites[i][6], i, 3.0, 50.0, 0, 0, 0, 255);
	}

	entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 1.0);
	return PLUGIN_CONTINUE;
}

DisplaySprite(const iEnt, iPlayer, Float:fFrame, Float:fOffset, const iRender, const iRed, const iGreen, const iBlue)
{
	if(!is_valid_ent(iEnt)) return;

	set_entity_visibility(iEnt, 1);
	entity_set_float(iEnt, EV_FL_frame, fFrame);
	set_rendering(iEnt, kRenderFxNone, iRed, iGreen, iBlue, kRenderTransAdd, iRender);
	static Float:vPlayerOrigin[3]; entity_get_vector(iPlayer, EV_VEC_origin, vPlayerOrigin); vPlayerOrigin[2] += fOffset; 
	entity_set_vector(iEnt, EV_VEC_origin, vPlayerOrigin);
}

SetEntityAttribs(const iEnt, const szModel[]){
	entity_set_model(iEnt, szModel);
	entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_NOCLIP);
	entity_set_float(iEnt, EV_FL_framerate, 1.0);
	entity_set_float(iEnt, EV_FL_scale, 0.3);
	set_entity_visibility(iEnt, 0);
}

public HideEntities(){
	if(is_valid_ent(g_iEntPijuda)){
		remove_entity(g_iEntPijuda);
		g_iEntPijuda = 0;
	}

	new i;
	for(new iId = 1; iId <= MAX_PLAYERS; iId++){
		for(i = 0; i < sizeof(szMoneySprites); i++) if(is_valid_ent(g_iPlayerMoneySprites[iId][i])) set_entity_visibility(g_iPlayerMoneySprites[iId][i], 0);

		for(i = 0; i < WEAPON_SPRITES; i++) if(is_valid_ent(g_iPlayerWeaponsSprites[iId][i])) set_entity_visibility(g_iPlayerWeaponsSprites[iId][i], 0);
	
		if(is_valid_ent(g_iPlayerDolarSign[iId])) set_entity_visibility(g_iPlayerDolarSign[iId], 0);
		if(is_valid_ent(g_iPlayerArrow[iId])) set_entity_visibility(g_iPlayerArrow[iId], 0);
	}
}

// WORK ON AMX_OFF
public plugin_cfg() if(is_plugin_loaded("Pause Plugins") != -1) server_cmd("amx_pausecfg add ^"%s^"", PLUGIN);