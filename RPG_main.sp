#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <database_rpg>

#pragma semicolon 1
#pragma newdecls required

#define MAX_DATA_EXISTS 20

//char DB_name[] = "rpg_db";
char sv_prefix[] = "小世界";

//參數設定
ConVar g_player_hud_x, g_player_hud_y, g_player_hud_r, g_player_hud_g, g_player_hud_b, g_player_hud_a;


//變數設定
bool Infection[MAXPLAYERS+1];
bool Bleeding[MAXPLAYERS+1];
bool PlayerInfoToggle[MAXPLAYERS+1];

int g_data[MAXPLAYERS+1][MAX_DATA_EXISTS];//處理玩家資料

//廣告設定
char loopMsg[][] = {
	"",
	"伺服器目前正在測試階段，歡迎對SourceMod有興趣的人加入(模組,插件, etc..)",
	"控制台輸入phud可以開啟/關閉右下角個人資訊顯示",
	"歡迎進入Discord群組: https://discord.gg/GTcct6"
};
int current_msg = 0;

enum{
	exp = 0,
	total_exp,
	level,
	gold,
	cash,
	online_time,
}

Handle PlayerHUDTimers[MAXPLAYERS + 1];

public Plugin myinfo = {
	name = "[NMRiH] RPG System",
	author = "Nailaz", 
	description = "RPG features for NMRiH, it will be cool I guess.", 
	version = "1.0"
};

public void OnPluginStart(){
	RegConsoleCmd("testss", TestMsg);
	RegConsoleCmd("savedb", TestSave);
	RegConsoleCmd("readdb", TestRead);
	RegConsoleCmd("phud", TogglePlayerInfo);
	//RegConsoleCmd("pmsg", ToggleMsgInfo);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("npc_killed", Event_Killed);
	
	g_player_hud_x = CreateConVar("rpg_pinfo_x", "0.75", "設定玩家個人資訊的x座標");
	g_player_hud_y = CreateConVar("rpg_pinfo_y", "0.75", "設定玩家個人資訊的y座標");
	g_player_hud_r = CreateConVar("rpg_pinfo_r", "255", "設定玩家個人資訊的r色");
	g_player_hud_g = CreateConVar("rpg_pinfo_g", "155", "設定玩家個人資訊的g色");
	g_player_hud_b = CreateConVar("rpg_pinfo_b", "0", "設定玩家個人資訊的b色");
	g_player_hud_a = CreateConVar("rpg_pinfo_a", "255", "設定玩家個人資訊的alpha值");
	
	OnStatusTimer();
	OnMsgTimer();
}
public void OnClientPutInServer(int client)
{
    //CreateTimer(15.0, WelcomePlayer, GetClientSerial(client)); // You could also use GetClientUserId(client)
}
public void OnStatusTimer()
{
	for(int Client=1; Client <= 8; Client++)
		CreateTimer(0.5, Event_PlayerStatus, Client, TIMER_REPEAT);
}
public void OnMsgTimer()
{
	CreateTimer(90.0, Event_LoopMsg, _, TIMER_REPEAT);
}
public Action Event_LoopMsg(Handle timer)
{
	if (current_msg < sizeof(loopMsg)-1) current_msg++;
	else current_msg = 1;
	PrintToChatAll("\x04[廣播]\x03%s", loopMsg[current_msg]);
}
public Action Event_PlayerStatus(Handle timer)
{
	for (int Client = 1; Client <= 8; Client++)
	{
		if(IsClientConnected(Client) && IsClientInGame(Client) && IsPlayerAlive(Client))
		{
			if(IsClientInfected(Client) == false) Infection[Client] = false;
			
			if(IsClientInfected(Client) == true)
			{
				if(Infection[Client] == false)
				{
					Infection[Client] = true;
					PrintToChatAll("\x04%N\x03已被感染...", sv_prefix, Client);
				}
			}
			
			if(IsClientBleeding(Client) == false) Bleeding[Client] = false;
			
			if(IsClientBleeding(Client))
			{
				if(Bleeding[Client] == false)
				{
					Bleeding[Client] = true;
					PrintToChatAll("\x04[%s]\x03%N\x04正在流血...", sv_prefix, Client);
				}
			}
		}
	}
}
public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int Client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(Infection[Client]) Infection[Client] = false;
	if(Bleeding[Client]) Bleeding[Client] = false;
	
	//PlayerHUDTimers[Client] = null;
	delete PlayerHUDTimers[Client];
	
	PlayerInfoToggle[Client] = true;
	PlayerHUDTimers[Client] = CreateTimer(0.7, ShowPlayerInfo, Client, TIMER_REPEAT);
	//PrintToChat(client, "\x03這裡是重生資訊");
}
public void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int Client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(Infection[Client]) Infection[Client] = false;
	if(Bleeding[Client]) Bleeding[Client] = false;
	PrintToChat(Client, "\x04[%s]\x03你已經死了", sv_prefix);
}
public void Event_Killed(Event event, const char[] name, bool dontBroadcast)
{
	int killer = event.GetInt("killeridx");
	if(1 <= killer <= 8)
		Set_User_Exp(killer, Get_User_Exp(killer) + 1);
}
public Action TestMsg(int client, int args)
{
	SetHudTextParams(g_player_hud_x.FloatValue, g_player_hud_y.FloatValue, 1.0, g_player_hud_r.IntValue, g_player_hud_g.IntValue, g_player_hud_b.IntValue, g_player_hud_a.IntValue, 0, 0.0, 0.2, 0.2);
	ShowHudText(client, -1, "This is a test message");
	PrintToChat(client, "\x04[RPG]你目前的經驗值: %d", g_data[client][exp]);
	g_data[client][exp]++;
	//x04 = x02
}
public Action TestSave(int client, int args)
{
	PrintToChat(client, "\x04已儲存資料 -> 等級:%d", g_data[client][level]);
	SQL_Write("rpg_db", client, "level", g_data[client][level]);
	//SQL_Write(const String:table[], client, const String:fmt[], any:...);
	//SQL_Read(const String:table[], client, String:text[], maxlength);
	//x04 = x02
}
public Action TestRead(int client, int args)
{
	char x = SQL_Read("rpg_db", client, "level", 50);
	PrintToChat(client, "\x04已讀取資料 -> 等級:%s", x);
	//SQL_Write(const String:table[], client, const String:fmt[], any:...);
	//SQL_Read(const String:table[], client, String:text[], maxlength);
	//x04 = x02
}
public Action TogglePlayerInfo(int client, int args)
{
	PlayerInfoToggle[client] = !PlayerInfoToggle[client];
	if(PlayerInfoToggle[client]) CreateTimer(0.7, ShowPlayerInfo, client, TIMER_REPEAT);
}
public Action ShowPlayerInfo(Handle Timer, int client)
{
	if(!IsClientConnected(client) || !PlayerInfoToggle[client])
		return Plugin_Stop;
		
	int iStamina = RoundToZero(GetEntPropFloat(client, Prop_Send, "m_flStamina", 0));
	char status[64];
	if (Bleeding[client]) Format(status, sizeof(status), "流血");
	else if (Infection[client]) Format(status, sizeof(status), "感染");
	else Format(status, sizeof(status), "正常");
	
	SetHudTextParams(g_player_hud_x.FloatValue, g_player_hud_y.FloatValue, 0.7, g_player_hud_r.IntValue, g_player_hud_g.IntValue, g_player_hud_b.IntValue, g_player_hud_a.IntValue, 0, 0.3, 0.1, 0.1);
	ShowHudText(client, -1, "等級: %d | 經驗值: %d/%s\n血量: %d | 體力: %d\n狀態: %s", g_data[client][level], g_data[client][exp], "10", GetClientHealth(client), iStamina, status);
	return Plugin_Continue;
	//SetEntPropFloat(i, Prop_Send, "m_flStamina", fMaxStamina); set stamina value
}
public Action Set_User_Exp(int client, int amount)
{
	g_data[client][exp] = amount;
	CheckLevel(client);
}
stock int Get_User_Exp(int client)
{
	if(1 <= client <= 8)
		return g_data[client][exp];
	return -1;
}
stock void CheckLevel(int client)
{
	if(g_data[client][exp] >= 10)
	{
		//char name[MAX_NAME_LENGTH];
		g_data[client][exp] -= 10;
		g_data[client][level]++;
		//GetClientName(client, name, sizeof(name));
		PrintToChatAll("\x04[%s]\x01%N的等級上升到\x04%d\x03了!", sv_prefix, client, g_data[client][level]);
		//PrintToChatAll("\x04%N \x04正在流血...", Client);
	}
}
stock bool IsValidClient(int client)
{
	if((1 <= client <= MaxClients) && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
		return true;
	return false;
}
stock bool IsClientInfected(int Client)
{
	if(GetEntPropFloat(Client, Prop_Send, "m_flInfectionTime") > 0 && GetEntPropFloat(Client, Prop_Send, "m_flInfectionDeathTime") > 0) return true;
	else return false;
}

stock bool IsClientBleeding(int Client)
{
	if(GetEntProp(Client, Prop_Send, "_bleedingOut") == 1) return true;
	else return false;
}