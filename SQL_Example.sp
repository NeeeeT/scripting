#include <sourcemod>
#pragma semicolon 1

new Handle:db;

public Plugin:myinfo = 
{
	name = "SQL資料庫",
	author = "Nailaz",
	description = "儲存玩家資料",
	version = "1.0",
	url = "#"
}

public OnPluginStart()
{
	// Testcommand
	RegConsoleCmd("say sql_test", Command_Test);
	RegConsoleCmd("say test", Command_Test1);
	
	// Create database if it doesn't exist and create rhe table
	InitDB(db);
}



InitDB(&Handle:DbHNDL)
{

	// Errormessage Buffer
	new String:Error[255];
	
	// COnnect to the DB
	DbHNDL = SQL_Connect("clientprefs", true, Error, sizeof(Error));
	
	
	// If something fails we quit
	if(DbHNDL == INVALID_HANDLE)
	{
		SetFailState(Error);
	}
	
	// Querystring
	new String:Query[255];
	Format(Query, sizeof(Query), "CREATE TABLE IF NOT EXISTS players (steamid TEXT UNIQUE, name TEXT);");
	
	// Database lock
	SQL_LockDatabase(DbHNDL);
	
	// Execute the query
	SQL_FastQuery(DbHNDL, Query);
	
	// Database unlock
	SQL_UnlockDatabase(DbHNDL);
	
}

public Action:Command_Test(client, args)
{
	// Use our function to write something to the DB
	AddPlayer("STEAM_:xxx", "Some name or so");
	
	// Prints all users out
	ReadAll();
	
	// Updates a single player
	UpdatePlayer("STEAM_:xxx", "Petrus is a much cooler name");
	
	
	return Plugin_Handled;
}
public Action:Command_Test1(client, args){
	PrintToServer("已測試!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
}
// Function to add something to the DB
AddPlayer(const String:Id[21], const String:Name[32])
{
	// We could just write the query in the function but i like it that way
	new String:Query[255];
	Format(Query, sizeof(Query), "INSERT OR IGNORE INTO players VALUES ('%s', '%s')", Id, Name);
	
	// Send our Query to the Function
	SQL_TQuery(db, SQL_ErrorCheckCallBack, Query);
}




// Function to update/rename something in the DB
UpdatePlayer(const String:Id[21], const String:Name[32])
{
	// We could just write the query in the function but i like it that way
	new String:Query[255];
	Format(Query, sizeof(Query), "UPDATE players SET name = '%s' WHERE steamid = '%s'", Name, Id);
	
	// Send our Query to the Function
	SQL_TQuery(db, SQL_ErrorCheckCallBack, Query);
}




ReadAll()
{
	new String:Query[255];
	Format(Query, sizeof(Query), "SELECT * FROM players");
	
	// Send our Query to the Function
	SQL_TQuery(db, SQL_ReadAll, Query);
}





public SQL_ReadAll(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	// We need to know the rowcount, in this case 2-1 because field begins at 0
	new RowCount = SQL_GetFieldCount(hndl);
	
	// Temp, just for debugging or so
	new field;
	
	// Buffer for our result
	new String:Buffer[255];
	
	// We need to fetch each row to get the results of it
	while(SQL_FetchRow(hndl))
	{
		// For every row one go
		for(new i; i< RowCount; i++)
		{
			// Gets the String from field i
			SQL_FetchString(hndl, i, Buffer, sizeof(Buffer));
			PrintToServer("Field %d | Row: %d | String: %s", field, i, Buffer);
		}
		// Increment our fieldcount
		field++;
	}
}

public SQL_ErrorCheckCallBack(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	// This is just an errorcallback for function who normally don't return any data
	if(hndl == INVALID_HANDLE)
	{
		SetFailState("Query failed! %s", error);
	}
}