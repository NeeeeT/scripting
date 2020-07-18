#include <sourcemod>

#pragma semicolon 1

public Plugin:myinfo = {
	name        = "Name",
	author      = "Author",
	description = "Description",
	version     = "1.0"
};

new Handle:g_hDatabase = INVALID_HANDLE;
new String:g_sError[256];

new String:SQL_InsertClient[] = "INSERT INTO TableName (steamid) VALUES('%s');";

public OnPluginStart()
{
	g_hDatabase = CreateConVar("sm_plugin_database", "DatabaseName", "This is the name you will enter into databases.cfg", 1);
	
	decl String:sDatabase[32];
	GetConVarString(g_hDatabase, sDatabase, sizeof(sDatabase));
	g_hDatabase = SQL_Connect(sDatabase, true, g_sError, sizeof(g_sError));

	if (g_hDatabase == INVALID_HANDLE)
		LogError("[SQL_Connect] Could not connect to database: %s", g_sError);

	SQL_CreateTables();
}

public SQL_CreateTables()
{
	SQL_TQuery(g_hDatabase, SQL_Callback, "CREATE TABLE IF NOT EXISTS TableName (steamid VARCHAR(32));");
}

public OnClientConnected(client)
{
	decl String:SteamID[32], String:sQuery[80];
	// GetClientAuthString(client, SteamID, sizeof(SteamID));
	GetClientAuthId(client, AuthId_Engine, SteamID, sizeof(SteamID));
	Format(sQuery, sizeof(sQuery), SQL_InsertClient, SteamID);
	SQL_TQuery(g_hDatabase, SQL_Callback, sQuery);
}

public SQL_Callback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
		LogError("There's an error babe: %s", error);
}



