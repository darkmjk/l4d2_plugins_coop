#include <left4dhooks>
#include <sourcemod>
#pragma newdecls required
#pragma semicolon 1

ConVar cv_RespawnNumber, cv_RespawnTime, cv_RespawnAddTime;
int i_RespawnNumber, RespawnNum[MAXPLAYERS + 1], RespawnTime[MAXPLAYERS + 1];
float f_RespawnTime;
bool Reset[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "[L4D2]复活",
	author = "奈",
	description = "生还死亡后复活",
	version = "1.0.6",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};


public void OnPluginStart()
{
	cv_RespawnNumber = CreateConVar("l4d2_respawn_number", "0", "复活次数,小于等于0关闭插件功能", FCVAR_NOTIFY);
	cv_RespawnTime = CreateConVar("l4d2_respawn_time", "20.0", "复活时间,小于等于0.0关闭插件功能", FCVAR_NOTIFY);
	cv_RespawnAddTime = CreateConVar("l4d2_respawn_add_time", "5.0", "每次复活后增加复活时间,负数为每次复活减少时间", FCVAR_NOTIFY);
	i_RespawnNumber = GetConVarInt(cv_RespawnNumber);
	f_RespawnTime = GetConVarFloat(cv_RespawnTime);
	HookConVarChange(cv_RespawnNumber, CvarChanged);
	HookConVarChange(cv_RespawnTime, CvarChanged);

	HookEvent("round_start", Event_Reset, EventHookMode_Pre);
	HookEvent("mission_lost", Event_Reset, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_player_death, EventHookMode_PostNoCopy);
	//AutoExecConfig(true, "l4d2_player_respawn");
}

public void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	i_RespawnNumber = GetConVarInt(cv_RespawnNumber);
	f_RespawnTime = GetConVarFloat(cv_RespawnTime);
}

//回合开始或失败重开重置次数
public Action Event_Reset(Event event, const char []name, bool dontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++){
		RespawnNum[client] = i_RespawnNumber;
		RespawnTime[client] = cv_RespawnTime.IntValue;
		Reset[client] = false;
	}
	return Plugin_Continue;
}

// 玩家死亡事件
public Action Event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	Reset[client] = true;
	if(i_RespawnNumber <= 0 || f_RespawnTime <= 0.0)
		return Plugin_Continue;
	if (RespawnNum[client] <= 0)
		return Plugin_Continue;
	if (!event)
		return Plugin_Continue;

	RespawnNum[client]--;
	PrintHintText(client, "——————  将在 %d 秒后复活  ——————", RespawnTime[client]);
	CreateTimer(1.0, Timer_RespawnPlayer, client, TIMER_REPEAT);
	return Plugin_Continue;
}

public Action Timer_RespawnPlayer(Handle timer, any client)
{
	RespawnTime[client]--;
	if (RespawnTime[client] > 0 && Reset[client])
	{
		PrintHintText(client, "——————  将在 %d 秒后复活  ——————", RespawnTime[client]);
	}
	else
	{
		RespawnTeleport(client);
		PrintToChat(client, "\x04剩余复活次数 \x01-> \x03%d", RespawnNum[client]);
		RespawnTime[client] = cv_RespawnTime.IntValue + cv_RespawnAddTime.IntValue * (i_RespawnNumber - RespawnNum[client]);
		return Plugin_Stop;
	}
}

// 复活传送
void RespawnTeleport(int client)
{
	if (IsValidSurvivor(client) && !IsPlayerAlive(client))
	{
		L4D_RespawnPlayer(client);
		GiveCommand(client, "health");
		TeleportClient(client);
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