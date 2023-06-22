#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

ConVar cv_lobby;

public Plugin myinfo = {
	name = "进服关闭匹配",
	author = "奈",
	description = "有人连接进入服务器自动关闭匹配",
	version = "1.1",
	url = "https://github.com/darkmjk/l4d2_plugins_coop"
};

public void OnPluginStart()
{
	cv_lobby = FindConVar("sv_allow_lobby_connect_only");
}

public void OnClientConnected(int client)
{
	if (IsFakeClient(client))
		return;

	cv_lobby.SetInt(0);
	ServerCommand("sv_cookie 0");
}
