#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

Database DB = null;
char DB_name[7] = "rpg_db";

ConVar g_player_hud_x, g_player_hud_y;

public Plugin myinfo = 
{
	name = "[NMRiH]RPG System",
	author = "Nailaz", 
	description = "RPG features for NMRiH, it will be cool I guess.", 
	version = "1.0"
};

public void OnPluginStart()
{
	if(DB == null) SQL_DBConnect();
	
	RegConsoleCmd("testss", TestMsg);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	g_player_hud_x = CreateConVar("rpg_pinfo_x", "0.01", "設定玩家個人資訊的x座標");
	g_player_hud_y = CreateConVar("rpg_pinfo_y", "1.00", "設定玩家個人資訊的y座標");
}
public void OnConfigsExecuted() 
{
	if(DB == null) SQL_DBConnect();
}
public void OnClientPostAdminCheck(int client)
{
	if (IsValidClient(client))
	{
		char steamid[32], query[1024];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		
		FormatEx(query, sizeof(query), "SELECT name FROM %s WHERE auth = '%s';", DB_name, steamid);
		DB.Query(CheckPlayer_Callback, query, GetClientSerial(client));
	}
}
public void CheckPlayer_Callback(Database db, DBResultSet result, char[] error, any data)
{
	if(result == null)
	{
		LogError("[%s] Query失敗: %s", DB_name, error);
		return;
	}
	int id = GetClientFromSerial(data);

	if(!id) return;
		
	while(result.FetchRow())
	{
		updateName(id);
		return;
	}
	char userName[MAX_NAME_LENGTH], steamid[32], ip[32];
	GetClientName(id, userName, sizeof(userName));
	GetClientAuthId(id, AuthId_Steam2, steamid, sizeof(steamid));
	GetClientIP(id, ip, sizeof(ip));
	
	int len = strlen(userName) * 2 + 1;
	char[] escapedName = new char[len];
	DB.Escape(userName, escapedName, len);

	len = strlen(steamid) * 2 + 1;
	char[] escapedSteamId = new char[len];
	DB.Escape(steamid, escapedSteamId, len);
	
	char query[512], time[32];
	FormatTime(time, sizeof(time), "%d-%m-%Y", GetTime());
	Format(query, sizeof(query), "INSERT INTO `%s` (`name`, `auth`, `ip`, `joindate`, `lastseen`) VALUES ('%s', '%s', '%s', '%s', '%s');", DB_name, escapedName, escapedSteamId, ip, time, time);
	DB.Query(Nothing_Callback, query, id);
}

void updateName(int client)
{
	char userName[MAX_NAME_LENGTH], steamid[32];
	GetClientName(client, userName, sizeof(userName));
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	
	int len = strlen(userName) * 2 + 1;
	char[] escapedName = new char[len];
	DB.Escape(userName, escapedName, len);

	len = strlen(steamid) * 2 + 1;
	char[] escapedSteamId = new char[len];
	DB.Escape(steamid, escapedSteamId, len);

	char query[128], time[32];
	FormatTime(time, sizeof(time), "%d-%m-%Y", GetTime());
	FormatEx(query, sizeof(query), "UPDATE `%s` SET `name` = '%s', `lastseen` = '%s' WHERE `auth` = '%s';", DB_name, escapedName, time, escapedSteamId);
	DB.Query(Nothing_Callback, query, client);
}

void SQL_DBConnect()
{
	if(DB != null) delete DB;
	if(SQL_CheckConfig(DB_name)) Database.Connect(SQLConnection_Callback, DB_name);
	else LogError("[%s]連接資料庫失敗! 請確認database.cfg中資料庫設定正確", DB_name);
}
public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	PrintToChat(client, "\x03你復活了");
}

public void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int Client = GetClientOfUserId(GetEventInt(event, "userid"));
	PrintToChat(Client, "\x03你已經死了");
}
public Action TestMsg(int client, int args)
{
	SetHudTextParams(g_player_hud_x.FloatValue, g_player_hud_y.FloatValue, 5.0, 255, 0, 0, 255, 0, 5.0, 0.5, 0.5);
	ShowHudText(client, -1, "This is a test message");
	PrintToChat(client, "\x04哈囉啊啊 \x02QQ \x03123]");
	//x04 = x02
}
public void SQLConnection_Callback(Database db, char[] error, any data)
{
	if(db == null)
	{
		LogError("[%s] 無法連接伺服器， 錯誤: %s", DB_name, error);
		return;
	}		
	DB = db;
	char query_bf[256];
	Format(query_bf, sizeof(query_bf), "CREATE TABLE IF NOT EXISTS `%s` (`name` varchar(64) NOT NULL,`auth` varchar(32) NOT NULL,`ip` varchar(32) NOT NULL,`joindate` varchar(32) NOT NULL,`lastseen` varchar(32) NOT NULL)", DB_name);
	DB.Query(Nothing_Callback, query_bf, DBPrio_High);

}
public void Nothing_Callback(Database db, DBResultSet result, char[] error, any data)
{
	if(result == null)
		LogError("[%s] 錯誤: %s", DB_name, error);
}

stock bool IsValidClient(int client)
{
	if((1 <= client <= MaxClients) && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
		return true;
	return false;
}