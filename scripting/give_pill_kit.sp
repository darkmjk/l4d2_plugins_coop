#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
 
public Plugin myinfo =
{
	name = "开局发包药",
	author = "奈",
	description = "回合开始发包药",
	version = "1.1",
	url = "https://github.com/darkmjk/l4d2_plugins_coop"
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	GiveMedicals();
	return Plugin_Stop;
}

public void GiveMedicals()
{
	int flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2) 
		{
		FakeClientCommand(client, "give first_aid_kit");
		FakeClientCommand(client, "give pain_pills");
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}
