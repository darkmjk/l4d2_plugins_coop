#pragma semicolon 1
#pragma newdecls required

#include <sourcemod> 
#include <sdktools>

#define SURPLUS(%1) 	i_MaxWeapon-player[%1].ClientWeapon

enum struct PlayerStruct{
	int ClientWeapon;
	int ClientMelee;
	int ClientPoint;
	float ClientAmmoTime;
	bool CanBuyMedical;
}
PlayerStruct player[MAXPLAYERS + 1];
Database sqlite;
ConVar cv_GetPoint, cv_MaxPoint, cv_MaxWeapon, cv_AmmoTime, cv_Disable, cv_Medical, cv_DeathReset; 
bool b_Disable, b_Medical;
float f_AmmoTime;
int i_MaxPoint, i_MaxWeapon;
char WeaponName[][] = {"铁喷", "木喷", "消音冲锋枪", "冲锋枪", "马格南", "普通小手枪"};
char MeleeName[][] = {"暂无", "砍刀", "消防斧", "小刀", "武士刀", "马格南", "电吉他", "警棍", "平底锅", "撬棍", "草叉", "铲子", "普通小手枪"};


public Plugin myinfo =  
{ 
	name = "[L4D2]Shop", 
	author = "奈", 
	description = "商店(数据库版本)", 
	version = "1.1.3", 
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop" 
}

public void OnPluginStart() 
{ 
	RegConsoleCmd("sm_gw", ShowMenu, "商店菜单"); 
	RegConsoleCmd("sm_buy", ShowMenu, "商店菜单");

	RegAdminCmd("sm_shop", SwitchShop, ADMFLAG_ROOT, "开关商店");
	
	RegConsoleCmd("sm_ammo", GiveAmmo, "补充子弹");
	RegConsoleCmd("sm_chr", GiveChr, "快速选铁喷");
	RegConsoleCmd("sm_pum", GivePum, "快速选木喷");
	RegConsoleCmd("sm_smg", GiveSmg, "快速选smg");
	RegConsoleCmd("sm_uzi", GiveUzi, "快速选uzi");

	cv_Disable = CreateConVar("l4d2_shop_disable", "0", "商店开关 开:0 关:1");
	cv_Medical = CreateConVar("l4d2_medical_enable", "1", "医疗物品购买开关 开:1 关:0");
	cv_MaxWeapon = CreateConVar("l4d2_weapon_number", "2", "每关单人可用白嫖武器上限", FCVAR_NOTIFY);
	cv_GetPoint = CreateConVar("l4d2_get_point", "1", "救援通关获得的点数", FCVAR_NOTIFY);
	cv_MaxPoint = CreateConVar("l4d2_max_point", "10", "获取点数上限", FCVAR_NOTIFY);
	cv_DeathReset = CreateConVar("l4d2_reset_buy", "0", "玩家死亡后是否重置白嫖武器次数 开:1 关:0", FCVAR_NOTIFY);
	cv_AmmoTime = CreateConVar("l4d2_give_ammo_time", "180.0", "补充子弹的最小间隔时间,小于0.0关闭功能");
	HookEvent("round_start", Event_Reset, EventHookMode_Pre);
	HookEvent("mission_lost", Event_Reset, EventHookMode_Post);
	HookEvent("finale_win", Event_RewardPoint, EventHookMode_Pre);
	HookEvent("player_death", Event_player_death, EventHookMode_Post);
	HookConVarChange(cv_Disable, CvarChanged);
	HookConVarChange(cv_MaxWeapon, CvarChanged);
	HookConVarChange(cv_MaxPoint, CvarChanged);
	HookConVarChange(cv_AmmoTime, CvarChanged);
	getCvar();
	if(!sqlite)
		InitSQLite();
	SQL_LoadAll();
	//是否生成cfg文件
	//AutoExecConfig(true, "ShopSystem");
}  

void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	getCvar();
}

public void OnConfigsExecuted()
{
	getCvar();
}

void getCvar()
{
	b_Disable = GetConVarBool(cv_Disable);
	b_Medical = GetConVarBool(cv_Medical);
	i_MaxWeapon = GetConVarInt(cv_MaxWeapon);
	i_MaxPoint = GetConVarInt(cv_MaxPoint);
	f_AmmoTime = GetConVarFloat(cv_AmmoTime);
}

void InitSQLite() 
{	
	char sError[1024];
	if (!(sqlite = SQLite_UseDatabase("ShopSystem", sError, sizeof sError)))
		SetFailState("Could not connect to the database \"ShopSystem\" at the following error:\n%s", sError);

	SQL_FastQuery(sqlite, "CREATE TABLE IF NOT EXISTS Shop(SteamID NVARCHAR(32) NOT NULL DEFAULT '', Select_Melee INT NOT NULL DEFAULT 0, Point INT NOT NULL DEFAULT 0);");
}

void SQL_LoadAll() 
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			SQL_Load(i);
		}
	}
}

void SQL_SaveAll() 
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)){
			SQL_SaveMelee(i);
			SQL_SavePoint(i);
		}		
	}
}

void SQL_Load(int client) 
{
	if (!sqlite)
		return;

	char query[1024];
	FormatEx(query, sizeof query, "SELECT Select_Melee, Point FROM Shop WHERE SteamID = '%s';", GetSteamId(client));
	sqlite.Query(SQL_CallbackLoad, query, GetClientUserId(client));
}

void SQL_SaveMelee(int client)
{
	if (!sqlite)
		return;

	char query[1024];
	FormatEx(query, sizeof query, "UPDATE Shop SET Select_Melee = %d WHERE SteamID = '%s';", player[client].ClientMelee, GetSteamId(client));
	SQL_FastQuery(sqlite, query);
}

void SQL_SavePoint(int client)
{
	if (!sqlite)
		return;

	char query[1024];
	FormatEx(query, sizeof query, "UPDATE Shop SET Point = %d WHERE SteamID = '%s';", player[client].ClientPoint, GetSteamId(client));
	SQL_FastQuery(sqlite, query);
}

void SQL_CallbackLoad(Database db, DBResultSet results, const char[] error, any data) 
{
	if (!db || !results) {
		LogError(error);
		return;
	}

	int client;
	if (!(client = GetClientOfUserId(data)))
		return;

	if (results.FetchRow()){
		player[client].ClientMelee = results.FetchInt(0);
		player[client].ClientPoint = results.FetchInt(1);
	}
	else {
		char query[1024];
		FormatEx(query, sizeof query, "INSERT INTO Shop(SteamID, Select_Melee, Point) VALUES ('%s', %d, %d);", GetSteamId(client), player[client].ClientMelee, player[client].ClientPoint);
		SQL_FastQuery(sqlite, query);
	}

}

public void OnPluginEnd() 
{
	SQL_SaveAll();
}

char[] GetSteamId(int client)
{
	char id[32];
	GetClientAuthId(client, AuthId_Engine, id, sizeof(id), true);
	return id;
}

public void OnClientPutInServer(int client)
{
	if(!IsFakeClient(client))
		SQL_Load(client);

	player[client].ClientAmmoTime = 0.0;
}

public void OnClientDisconnect(int client)
{
	if(!IsFakeClient(client)){
		SQL_SaveMelee(client);
		SQL_SavePoint(client);
	}
		
}

//玩家死亡重置次数
public void Event_player_death(Event event, const char []name, bool dontBroadcast)
{
	if(cv_DeathReset.BoolValue)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		player[client].ClientWeapon = 0;
		player[client].ClientAmmoTime = 0.0;
		player[client].CanBuyMedical = true;
	}
}

//回合开始或失败重开重置次数
public Action Event_Reset(Event event, const char []name, bool dontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++){
		player[client].ClientWeapon = 0;
		player[client].ClientAmmoTime = 0.0;
		player[client].CanBuyMedical = true;
	}
	return Plugin_Continue;
}

//玩家通关救援奖励1点数
public Action Event_RewardPoint(Event event, const char []name, bool dontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++){
		if(!NoValidPlayer(client) && GetClientTeam(client) == 2){
			if(IsPlayerAlive(client))
			{
				if(player[client].ClientPoint < i_MaxPoint){
					player[client].ClientPoint += 1;
					SQL_SavePoint(client);
					PrintToChat(client, "\x04[商店]\x03恭喜通关! 获得\x04 %d \x03点数.", cv_GetPoint.IntValue);
				}
				else{
					PrintToChat(client, "\x04[商店]\x03恭喜通关! 点数到达上限\x04 %d \x03点,本关不会增加点数.", i_MaxPoint);
				}
			}
			else{
				PrintToChat(client, "\x04[商店]\x03恭喜通关! 死亡玩家无点数发放.");
			}
		}
	}
	return Plugin_Continue;
}

//开局发近战武器
public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	if(b_Disable)
		return Plugin_Stop;
	for(int i=1;i<=MaxClients;i++)
		if(!NoValidPlayer(i) && GetClientTeam(i) == 2)
		{
			CreateTimer(0.5, Timer_AutoGive, i, TIMER_FLAG_NO_MAPCHANGE);
		}
	return Plugin_Stop;
}

//开关商店
public Action SwitchShop(int client, int args)
{
	char info[4];
	if(args == 0)
	{
		if(b_Disable)
		{
			PrintToChat(client, "\x04[商店]\x03商店已关闭,打开请输入\x04!shop on");
		}
		else
		{
			PrintToChat(client, "\x04[商店]\x03商店已开启,关闭请输入\x04!shop off");
		}
	}
	else if(args == 1)
	{
		GetCmdArg(1, info, sizeof(info));
		if (strcmp(info, "on", false) == 0)
		{
			b_Disable = false;
			PrintToChatAll("\x04[商店]\x03管理员打开商店");
		}
		else if (strcmp(info, "off", false) == 0)
		{
			b_Disable = true;
			PrintToChatAll("\x04[商店]\x03管理员关闭商店");
		}
		else
		{
			PrintToChat(client, "\x04[商店]\x03请输入正确的命令!");
		}
	}
	return Plugin_Handled;
}

//主面板菜单
public Action ShowMenu(int client, int args)
{
	if(b_Disable)
	{
		PrintToChat(client, "\x04[商店]\x03商店未开启");
		return Plugin_Handled;
	}
	if( !NoValidPlayer(client) && GetClientTeam(client) == 2 )
	{
		Menu menu = new Menu(ShowMenuDetail);
		menu.SetTitle("商店菜单\n---------------");
		menu.AddItem("gun", "白嫖武器");
		menu.AddItem("melee", "白嫖近战");
		menu.AddItem("meleeSelect", "出门近战");
		if(b_Medical)
			menu.AddItem("medical", "医疗物品");
		menu.AddItem("throw", "投掷物品");
		menu.Display(client, 20);
	}
	return Plugin_Handled;
}

//主面板菜单选择后执行
public int ShowMenuDetail(Menu menu, MenuAction action, int client, int num)
{
	char info[32];
	menu.GetItem(num, info, sizeof(info));
	if (action == MenuAction_Select)
	{
		switch(num)
		{
			case 0:
			{
				WeaponMenu(client);
			}
			case 1:
			{
				MeleeMenu(client);
			}
			case 2:
			{
				MeleeSelect(client);
			}
			case 3:
			{
				MedicalMenu(client);
			}
			case 4:
			{
				ThrowMenu(client);
			}
		}
	}
	if (action == MenuAction_End)	
		delete menu;
	return 0;
}

//白嫖武器菜单
public void WeaponMenu(int client) 
{
	Menu menu = new Menu(WeaponMenu_back);
	menu.SetTitle("白嫖武器(剩余:%d次)\n---------------------------",SURPLUS(client));
	menu.AddItem("weapon1", "铁喷");
	menu.AddItem("weapon2", "木喷");
	menu.AddItem("weapon3", "消音冲锋枪");
	menu.AddItem("weapon4", "冲锋枪");
	menu.AddItem("weapon5", "马格南");
	menu.AddItem("weapon6", "普通小手枪");
	menu.Display(client, 20);
} 

//白嫖武器菜单选择后执行
public int WeaponMenu_back(Menu menu, MenuAction action, int client, int num)
{
	if(judge(client))
		return 0;
	char info[64];
	menu.GetItem(num, info, sizeof(info));
	if (action == MenuAction_Select)
	{
		switch (num) 
		{ 
			case 0: //铁喷
			{ 
				GiveCommand(client, "shotgun_chrome");
				PrintWeaponName(client, 0);
			}
			case 1: //木喷
			{ 
				GiveCommand(client, "pumpshotgun");
				PrintWeaponName(client, 1);
			}
			case 2: //消音冲锋枪
			{ 
				GiveCommand(client, "smg_silenced");
				PrintWeaponName(client, 2);
			}
			case 3: //冲锋枪
			{ 
				GiveCommand(client, "smg");
				PrintWeaponName(client, 3);
			}
			case 4:
			{
				GiveCommand(client, "pistol_magnum");
				PrintWeaponName(client, 4);
			}
			case 5:
			{
				GiveCommand(client, "pistol");
				PrintWeaponName(client, 5);
			}
		}
	}
	if (action == MenuAction_End)	
		delete menu;
	return 0;
}

//白嫖近战菜单
public void MeleeMenu(int client) 
{ 
	Menu menu = new Menu(MeleeMenu_back);
	menu.SetTitle("白嫖近战(剩余:%d次)\n---------------------------",SURPLUS(client));
	menu.AddItem("melee1", "砍刀");
	menu.AddItem("melee2", "消防斧");
	menu.AddItem("melee3", "小刀");
	menu.AddItem("melee4", "武士刀");
	menu.AddItem("melee5", "电吉他");
	menu.AddItem("melee6", "警棍");
	menu.AddItem("melee7", "平底锅");
	menu.AddItem("melee8", "撬棍");
	menu.AddItem("melee9", "草叉");
	menu.AddItem("melee10", "铲子");
	menu.Display(client, 20);
}

//白嫖近战菜单选择后执行
public int MeleeMenu_back(Menu menu, MenuAction action, int client, int num)
{
	if(judge(client))
		return 0;
	char info[64];
	menu.GetItem(num, info, sizeof(info));
	if (action == MenuAction_Select)
	{
		switch(num)
		{
			case 0://砍刀
			{
				GiveCommand(client, "machete");
				PrintWeaponName(client, 1, false);
			}
			case 1://消防斧
			{
				GiveCommand(client, "fireaxe");
				PrintWeaponName(client, 2, false);
			}
			case 2://小刀
			{
				GiveCommand(client, "knife");
				PrintWeaponName(client, 3, false);
			}
			case 3://武士刀
			{
				GiveCommand(client, "katana");
				PrintWeaponName(client, 4, false);
			}
			case 4://电吉他
			{
				GiveCommand(client, "electric_guitar");
				PrintWeaponName(client, 6, false);
			}
			case 5://警棍
			{
				GiveCommand(client, "tonfa");
				PrintWeaponName(client, 7, false);
			}
			case 6://平底锅
			{
				GiveCommand(client, "frying_pan");
				PrintWeaponName(client, 8, false);
			}
			case 7://撬棍
			{
				GiveCommand(client, "crowbar");
				PrintWeaponName(client, 9, false);
			}
			case 8://草叉
			{
				GiveCommand(client, "pitchfork");
				PrintWeaponName(client, 10, false);
			}
			case 9://铲子
			{
				GiveCommand(client, "shovel");
				PrintWeaponName(client, 11, false);
			}
		}
	}
	if (action == MenuAction_End)	
		delete menu;
	return 0;
}

//白嫖武器后聊天框展示
void PrintWeaponName(int client, int i, bool isWeapon = true)
{
	player[client].ClientWeapon++;
	PrintToChat(client, "\x04[商店]\x05白嫖\x03%s\x05成功,还剩\x04%d\x05次", isWeapon?WeaponName[i]:MeleeName[i], SURPLUS(client));
}

//医疗物品菜单
public void MedicalMenu(int client) 
{
	Menu menu = new Menu(MedicalMenu_back);
	menu.SetTitle("点数(剩余:%d)\n---------------------", player[client].ClientPoint);
	menu.AddItem("pain_pills", "止痛药(1点)");
	menu.AddItem("adrenaline", "肾上腺素(1点)");
	menu.AddItem("first_aid_kit", "医疗包(2点)");
	menu.AddItem("defibrillator", "电击器(2点)");
	menu.Display(client, 20);
} 

//医疗物品菜单选择后执行
public int MedicalMenu_back(Menu menu, MenuAction action, int client, int num)
{
	if(judge(client))
		return 0;
	if(player[client].ClientPoint == 0){
		PrintToChat(client, "\x04[商店]\x03点数不足!");
		return 0;
	}
	char info[64];
	menu.GetItem(num, info, sizeof(info));
	if (action == MenuAction_Select)
	{
		switch (num) 
		{ 
			case 0: //止痛药
			{ 
				if(player[client].CanBuyMedical)
				{
					GiveCommand(client, "pain_pills");
					PrintMedicalName(client, 0);
					player[client].CanBuyMedical = false;
				}
				else
				{
					PrintToChat(client, "\x04[商店]\x03医疗物品每关只能买一次哦!");
				}
			}
			case 1: //肾上腺素
			{ 
				if(player[client].CanBuyMedical)
				{
					GiveCommand(client, "adrenaline");
					PrintMedicalName(client, 1);
					player[client].CanBuyMedical = false;
				}
				else
				{
					PrintToChat(client, "\x04[商店]\x03医疗物品每关只能买一次哦!");
				}
			}
			case 2: //医疗包
			{ 
				if(player[client].CanBuyMedical)
				{
					if(player[client].ClientPoint == 1)
					{
						PrintToChat(client, "\x04[商店]\x03点数不足!");
						return 0;
					}
					GiveCommand(client, "first_aid_kit");
					player[client].ClientPoint--;
					PrintMedicalName(client, 2);
					player[client].CanBuyMedical = false;
				}
				else
				{
					PrintToChat(client, "\x04[商店]\x03医疗物品每关只能买一次哦!");
				}
			}
			case 3: //电击器
			{ 
				if(player[client].CanBuyMedical)
				{
					if(player[client].ClientPoint == 1)
					{
						PrintToChat(client, "\x04[商店]\x03点数不足!");
						return 0;
					}
					GiveCommand(client, "defibrillator");
					player[client].ClientPoint--;
					PrintMedicalName(client, 3);
					player[client].CanBuyMedical = false;
				}
				else
				{
					PrintToChat(client, "\x04[商店]\x03医疗物品每关只能买一次哦!");
				}
			}
		}
	}
	if (action == MenuAction_End)	
		delete menu;
	return 0;
}

//医疗物品聊天框展示
void PrintMedicalName(int client, int i)
{
	char MedicalName[][] = {"止痛药", "肾上腺素", "医疗包", "电击器"};
	player[client].ClientPoint--;
	SQL_SavePoint(client);
	PrintToChat(client, "\x04[商店]\x05购买\x03%s\x05成功,还剩\x04%d\x05点数", MedicalName[i], player[client].ClientPoint);
}

//投掷物品菜单
public void ThrowMenu(int client) 
{
	Menu menu = new Menu(ThrowMenu_back);
	menu.SetTitle("点数(剩余:%d)\n---------------------", player[client].ClientPoint);
	menu.AddItem("molotov", "燃烧瓶(1点)");
	menu.AddItem("pipe_bomb", "土制炸弹(1点)");
	menu.AddItem("vomitjar", "胆汁(1点)");
	menu.Display(client, 20);
} 

//医疗物品菜单选择后执行
public int ThrowMenu_back(Menu menu, MenuAction action, int client, int num)
{
	if(judge(client))
		return 0;
	if(player[client].ClientPoint == 0){
		PrintToChat(client, "\x04[商店]\x03点数不足!");
		return 0;
	}
	char info[64];
	menu.GetItem(num, info, sizeof(info));
	if (action == MenuAction_Select)
	{
		switch (num) 
		{ 
			case 0: //燃烧瓶
			{ 
				GiveCommand(client, "molotov");
				PrintThrowName(client, 0);
			}
			case 1: //土制炸弹
			{ 
				GiveCommand(client, "pipe_bomb");
				PrintThrowName(client, 1);
			}
			case 2: //胆汁
			{ 
				GiveCommand(client, "vomitjar");
				PrintThrowName(client, 2);
			}
		}
	}
	if (action == MenuAction_End)	
		delete menu;
	return 0;
}

//医疗物品聊天框展示
void PrintThrowName(int client, int i)
{
	char ThrowName[][] = {"燃烧瓶", "土制炸弹", "胆汁"};
	player[client].ClientPoint--;
	SQL_SavePoint(client);
	PrintToChat(client, "\x04[商店]\x05购买\x03%s\x05成功,还剩\x04%d\x05点数", ThrowName[i], player[client].ClientPoint);
}

//出门近战选择菜单
public void MeleeSelect(int client)
{
	if( !NoValidPlayer(client) && GetClientTeam(client) == 2 )
	{
		Menu menu = new Menu(MeleeSelect_back);
		menu.SetTitle("选择出门近战,当前为%s\n---------------------------",MeleeName[player[client].ClientMelee]);
		menu.AddItem("none", "清除武器");
		menu.AddItem("machete", "砍刀");
		menu.AddItem("fireaxe", "消防斧");
		menu.AddItem("knife", "小刀");
		menu.AddItem("katana", "武士刀");
		menu.AddItem("pistol_magnum", "马格南");
		menu.AddItem("electric_guitar", "电吉他");
		menu.AddItem("tonfa", "警棍");
		menu.AddItem("frying_pan", "平底锅");
		menu.AddItem("crowbar", "撬棍");
		menu.AddItem("pitchfork", "草叉");
		menu.AddItem("shovel", "铲子");
		menu.AddItem("pistol", "普通小手枪");
		menu.Display(client, 20);
	}
}

//出门近战选择后执行
public int MeleeSelect_back(Menu menu, MenuAction action, int client, int num)
{
	char info[128];
	menu.GetItem(num, info, sizeof(info));
	if (action == MenuAction_Select)
	{
		switch(num)
		{
			case 0://清除武器
			{
				player[client].ClientMelee=0;
				SQL_SaveMelee(client);
				PrintToChat(client,"\x04[商店]\x03出门近战武器设置已清除");
			}
			case 1://砍刀
			{
				player[client].ClientMelee=1;
				SQL_SaveMelee(client);
				PrintMeleeSelect(client);
			}
			case 2://消防斧
			{
				player[client].ClientMelee=2;
				SQL_SaveMelee(client);
				PrintMeleeSelect(client);
			}
			case 3://小刀
			{
				player[client].ClientMelee=3;
				SQL_SaveMelee(client);
				PrintMeleeSelect(client);
			}
			case 4://武士刀
			{
				player[client].ClientMelee=4;
				SQL_SaveMelee(client);
				PrintMeleeSelect(client);
			}
			case 5://马格南
			{
				player[client].ClientMelee=5;
				SQL_SaveMelee(client);
				PrintMeleeSelect(client);
			}
			case 6://电吉他
			{
				player[client].ClientMelee=6;
				SQL_SaveMelee(client);
				PrintMeleeSelect(client);
			}
			case 7://警棍
			{
				player[client].ClientMelee=7;
				SQL_SaveMelee(client);
				PrintMeleeSelect(client);
			}
			case 8://平底锅
			{
				player[client].ClientMelee=8;
				SQL_SaveMelee(client);
				PrintMeleeSelect(client);
			}
			case 9://撬棍
			{
				player[client].ClientMelee=9;
				SQL_SaveMelee(client);
				PrintMeleeSelect(client);
			}
			case 10://草叉
			{
				player[client].ClientMelee=10;
				SQL_SaveMelee(client);
				PrintMeleeSelect(client);
			}
			case 11://铲子
			{
				player[client].ClientMelee=11;
				SQL_SaveMelee(client);
				PrintMeleeSelect(client);
			}
			case 12://普通小手枪
			{
				player[client].ClientMelee=12;
				SQL_SaveMelee(client);
				PrintMeleeSelect(client);
			}
		}
	}
	if (action == MenuAction_End)	
		delete menu;
	return 0;
}

//出门近战选择后聊天框展示
void PrintMeleeSelect(int client)
{
	PrintToChat(client,"\x04[商店]\x05出门近战武器设为\x03%s", MeleeName[player[client].ClientMelee]);
}

//出门发放近战
public Action Timer_AutoGive(Handle timer, any client)
{
	if (player[client].ClientMelee == 1)
	{
		DeleteMelee(client);
		GiveCommand(client, "machete");
	}
	if (player[client].ClientMelee == 2)
	{
		DeleteMelee(client);
		GiveCommand(client, "fireaxe");
	}
	if (player[client].ClientMelee == 3)
	{
		DeleteMelee(client);
		GiveCommand(client, "knife");
	}
	if (player[client].ClientMelee == 4)
	{
		DeleteMelee(client);
		GiveCommand(client, "katana");
	}
	if (player[client].ClientMelee == 5)
	{
		DeleteMelee(client);
		GiveCommand(client, "pistol_magnum");
	}
	if (player[client].ClientMelee == 6)
	{
		DeleteMelee(client);
		GiveCommand(client, "electric_guitar");
	}
	if (player[client].ClientMelee == 7)
	{
		DeleteMelee(client);
		GiveCommand(client, "tonfa");
	}
	if (player[client].ClientMelee == 8)
	{
		DeleteMelee(client);
		GiveCommand(client, "frying_pan");
	}
	if (player[client].ClientMelee == 9)
	{
		DeleteMelee(client);
		GiveCommand(client, "crowbar");
	}
	if (player[client].ClientMelee == 10)
	{
		DeleteMelee(client);
		GiveCommand(client, "pitchfork");
	}
	if (player[client].ClientMelee == 11)
	{
		DeleteMelee(client);
		GiveCommand(client, "shovel");
	}
	if (player[client].ClientMelee == 12)
	{
		DeleteMelee(client);
		GiveCommand(client, "pistol");
	}
	return Plugin_Continue;
}

//清除副武器，这样不会出门重复刷武器
void DeleteMelee(int client)
{
	int item = GetPlayerWeaponSlot(client, 1);
	if (IsValidEntity(item) && IsValidEdict(item))
	{
		RemovePlayerItem(client, item);
	}
}

//补充子弹指令
public Action GiveAmmo(int client, int args)
{
	if(b_Disable)
	{
		PrintToChat(client, "\x04[商店]\x03商店未开启");
		return Plugin_Handled;
	}
	if(f_AmmoTime < 0.0)
	{
		PrintToChat(client, "\x04[商店]\x03补充子弹已关闭");
		return Plugin_Handled;
	}
	if (GetClientTeam(client) == 2 && !NoValidPlayer(client))
	{
		float fTime = GetEngineTime() - player[client].ClientAmmoTime - f_AmmoTime;
		if (fTime < 0.0)
		{
			PrintToChat(client, "\x04[商店]\x05请等待\x04%.1f\x05秒后补充子弹", FloatAbs(fTime));
			return Plugin_Handled;
		}
		GiveCommand(client, "ammo");
		player[client].ClientAmmoTime = GetEngineTime();
	}
	return Plugin_Handled;
}

//cheat命令
void GiveCommand(int client, char[] args = "")
{
	int iFlags = GetCommandFlags("give");
	SetCommandFlags("give", iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", args);
	SetCommandFlags("give", iFlags);
}

//判断玩家
bool NoValidPlayer(int Client)
{
	if (Client < 1 || Client > MaxClients)
		return true;
	if (!IsClientConnected(Client) || !IsClientInGame(Client))
		return true;
	if (IsFakeClient(Client))
		return true;
	if (!IsPlayerAlive(Client))
		return true;

	return false;
}

//白嫖武器判定
bool judge(int client)
{
	if(NoValidPlayer(client))  
		return true; 
		
	if(GetClientTeam(client) != 2) 
	{ 
		PrintToChat(client, "\x04[商店]\x03武器菜单仅对生还生效"); 
		return true; 
	} 

	if(player[client].ClientWeapon >= i_MaxWeapon)  
	{ 
		PrintToChat(client, "\x04[商店]\x03已达到每关白嫖上限"); 
		return true; 
	}
	return false;
}

//快速白嫖铁喷
public Action GiveChr(int client,int args) 
{ 
	if(b_Disable)
	{
		PrintToChat(client, "\x04[商店]\x03商店未开启");
		return Plugin_Handled;
	}
	if(judge(client))
		return Plugin_Handled;
	GiveCommand(client, "shotgun_chrome");
	PrintWeaponName(client, 0);
	return Plugin_Handled; 
}

//快速白嫖木喷
public Action GivePum(int client,int args) 
{ 
	if(b_Disable)
	{
		PrintToChat(client, "\x04[商店]\x03商店未开启");
		return Plugin_Handled;
	}
	if(judge(client))
		return Plugin_Handled;
	GiveCommand(client, "pumpshotgun");
	PrintWeaponName(client, 1);
	return Plugin_Handled; 
}

//快速白嫖消音冲锋
public Action GiveSmg(int client,int args) 
{ 
	if(b_Disable)
	{
		PrintToChat(client, "\x04[商店]\x03商店未开启");
		return Plugin_Handled;
	}
	if(judge(client))
		return Plugin_Handled;
	GiveCommand(client, "smg_silenced"); 
	PrintWeaponName(client, 2);
	return Plugin_Handled; 
}

//快速白嫖冲锋
public Action GiveUzi(int client,int args) 
{ 
	if(b_Disable)
	{
		PrintToChat(client, "\x04[商店]\x03商店未开启");
		return Plugin_Handled;
	}
	if(judge(client))
		return Plugin_Handled;
	GiveCommand(client, "smg");
	PrintWeaponName(client, 3);
	return Plugin_Handled; 
}