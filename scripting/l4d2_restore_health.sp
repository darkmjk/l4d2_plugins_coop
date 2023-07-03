#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <left4dhooks>
#pragma newdecls required
#pragma semicolon 1

ConVar cv_restore_health;
bool flag;
public Plugin myinfo =
{
	name = "[L4D2]通关回血",
	author = "奈",
	description = "过关所有人回满血",
	version = "1.1",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};


public void OnPluginStart()
{
	cv_restore_health = CreateConVar("l4d2_restore_health_flag", "0", "开关回血判定");
	HookEvent("map_transition", ResetSurvivors, EventHookMode_Post);
	HookConVarChange(cv_restore_health, CvarChange);
}

public void CvarChange( ConVar convar, const char[] oldValue, const char[] newValue )
{
	flag = GetConVarBool(cv_restore_health);
}

public void ResetSurvivors(Event event, const char[] name, bool dontBroadcast)
{
	if(flag)
		RestoreHealth();
}

void RestoreHealth()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidSurvivor(client))
		{
			//死亡玩家复活
			if(!IsPlayerAlive(client))
			{
				L4D_RespawnPlayer(client);
				TeleportClient(client);
			}
				
				
			//回血
			GiveCommand(client, "health");
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
			SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
			StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
		}
	}
}

void TeleportClient(int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		float Origin[3];
		if (IsValidSurvivor(i) && i != client)
		{
			ForceCrouch(client);
			GetClientAbsOrigin(i, Origin);
			TeleportEntity(client, Origin, NULL_VECTOR, NULL_VECTOR);
			break;
		}
	}
}

void ForceCrouch(int client)
{
	SetEntProp(client, Prop_Send, "m_bDucked", 1);
	SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags") | FL_DUCKING);
}

bool IsValidSurvivor(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
		return true;
	else
		return false;
}

//cheat命令
void GiveCommand(int client, char[] args = "")
{
	int flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", args);
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

