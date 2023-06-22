#include <sdktools>
#include <sourcemod>
#pragma newdecls required
#pragma semicolon 1

//清除部分功能，让插件通用在服务器

public Plugin myinfo =
{
	name = "Server Function",
	author = "奈",
	description = "服务器一些功能实现",
	version = "1.0",
	url = "https://github.com/darkmjk/l4d2_plugins_coop"
};


public void OnPluginStart()
{
	RegAdminCmd("sm_restartmap", RestartMap, ADMFLAG_ROOT, "restarts map");
	RegConsoleCmd("sm_zs", Kill_Survivor, "幸存者自杀指令.");
	RegConsoleCmd("sm_kill", Kill_Survivor, "幸存者自杀指令.");
	HookUserMessage(GetUserMessageId("TextMsg"), umTextMsg, true);
	HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
}

public void OnPluginEnd()
{
	SetGodMode(false);
}

public void OnMapStart()
{
	SetGodMode(true);
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	SetGodMode(false);
	return Plugin_Stop;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// 开启无敌模式
	SetGodMode(true);
}

// ------------------------------------------------------------------------
// 游戏自带的闲置提示和sourcemod平台自带的[SM]提示 感谢 sorallll
// ------------------------------------------------------------------------
Action umTextMsg(UserMsg msg_id, BfRead msg, const int[] players, int num, bool reliable, bool init) {
	static char buffer[254];
	msg.ReadString(buffer, sizeof buffer);

	if (strcmp(buffer, "\x03#L4D_idle_spectator") == 0) //聊天栏提示：XXX 现已闲置。
		return Plugin_Handled;
	else if (StrContains(buffer, "\x03[SM]") == 0) //聊天栏以[SM]开头的消息。
	{
		DataPack dPack = new DataPack();
		dPack.WriteCell(num);
		for (int i; i < num; i++)
			dPack.WriteCell(players[i]);
		dPack.WriteString(buffer);
		RequestFrame(NextFrame_SMMessage, dPack);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

//https://forums.alliedmods.net/showthread.php?t=187570
void NextFrame_SMMessage(DataPack dPack) {
	dPack.Reset();
	int num = dPack.ReadCell();
	int[] players = new int[num];

	int client, count;
	for (int i; i < num; i++) {
		client = dPack.ReadCell();
		if (IsClientInGame(client) && !IsFakeClient(client) && CheckCommandAccess(client, "", ADMFLAG_ROOT))
			players[count++] = client;
	}

	if (!count) {
		delete dPack;
		return;
	}

	char buffer[254];
	dPack.ReadString(buffer, sizeof buffer);
	delete dPack;

	ReplaceStringEx(buffer, sizeof buffer, "[SM]", "\x04[SM]\x05");
	BfWrite bf = view_as<BfWrite>(StartMessage("SayText2", players, count, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
	bf.WriteByte(-1);
	bf.WriteByte(true);
	bf.WriteString(buffer);
	EndMessage();
}

// ------------------------------------------------------------------------
// ConVar更改提示
// ------------------------------------------------------------------------
Action Event_ServerCvar(Event event, const char[] name, bool dontBroadcast) {
	return Plugin_Handled;
}

stock bool IsSurvivor(int client)
{
	if (client < 1 || client > MaxClients)
		return false;
	if (!IsClientConnected(client) || !IsClientInGame(client))
		return false;
	if (IsFakeClient(client))
		return false;
	if (!IsPlayerAlive(client))
		return false;
	if (GetClientTeam(client) != 2)
		return false;
		
	return true;
}

void SetGodMode(bool canset)
{
	int flags = GetCommandFlags("god");
	SetCommandFlags("god", flags & ~ FCVAR_NOTIFY);
	SetConVarInt(FindConVar("god"), canset);
	SetCommandFlags("god", flags);
	SetConVarInt(FindConVar("sv_infinite_ammo"), canset);
}

public Action RestartMap(int client,int args)
{
	PrintHintTextToAll("地图将在5秒后重启");
	CreateTimer(5.0, Timer_Restartmap);
	return Plugin_Handled;
}

public Action Timer_Restartmap(Handle timer)
{
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	ServerCommand("changelevel %s", mapname);
	return Plugin_Handled;
}

public Action Kill_Survivor(int client, int args)
{
	if(IsSurvivor(client))
	{
		ForcePlayerSuicide(client);
		PrintToChatAll("\x04[提示]\x03%N\x05失去梦想,自裁了.", client);
	}
	return Plugin_Handled;
}
