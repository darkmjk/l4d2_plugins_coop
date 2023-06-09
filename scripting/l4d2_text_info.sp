#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

ConVar
	cv_Weapon,
	cv_WeaponReplace,
	cv_Rhp,
	cv_Restore,
	cv_Siammoregain,
	cv_Kits,
	cv_Pills,
	cv_Respawn;
	
int
	Weapon,
	Rhp,
	Restore,
	Siammoregain,
	Kits,
	Pills,
	Respawn;

public Plugin myinfo = 
{
    name        = "!xx查询信息",
    author      = "奈",
    description = "服务器信息查询",
    version     = "1.2.1",
    url         = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_xx", Status);
	
	cv_Weapon = CreateConVar("WeaponDamage", "0", "设置武器伤害", 0, false, 0.0, false, 0.0);
	cv_WeaponReplace = CreateConVar("WeaponReplace", "0", "开启大小枪");

	Weapon = GetConVarInt(cv_Weapon);
	HookConVarChange(cv_Weapon, CvarWeapon);
	HookConVarChange(cv_WeaponReplace, CvarWeaponReplace);
}

public void OnAllPluginsLoaded()
{
	cv_Rhp = FindConVar("ss_health");
	cv_Siammoregain = FindConVar("ss_siammoregain");
	cv_Restore = FindConVar("l4d2_restore_health_flag");
	cv_Kits = FindConVar("l4d2_multi_medical_kits");
	cv_Pills = FindConVar("l4d2_multi_medical_pills");
	cv_Respawn = FindConVar("l4d2_respawn_number");
	ServerCommand("exec vt_cfg/bantank.cfg");
}

public void OnConfigsExecuted()
{
	if(cv_Rhp != null){
		cv_Rhp.AddChangeHook(CvarRhp);
	}
	else if(FindConVar("ss_health")){
		cv_Rhp = FindConVar("ss_health");
		cv_Rhp.AddChangeHook(CvarRhp);
	}
	if(cv_Siammoregain != null){
		cv_Siammoregain.AddChangeHook(CvarAmmo);
	}
	else if(FindConVar("ss_siammoregain")){
		cv_Siammoregain = FindConVar("ss_siammoregain");
		cv_Siammoregain.AddChangeHook(CvarAmmo);
	}
	if(cv_Restore != null){
		cv_Restore.AddChangeHook(CvarRestore);
	}
	else if(FindConVar("l4d2_restore_health_flag")){
		cv_Restore = FindConVar("l4d2_restore_health_flag");
		cv_Restore.AddChangeHook(CvarRestore);
	}
	if(cv_Kits != null && cv_Pills != null){
		cv_Kits.AddChangeHook(CvarMedical);
		cv_Pills.AddChangeHook(CvarMedical);
	}
	else if(FindConVar("l4d2_multi_medical_kits") && FindConVar("l4d2_multi_medical_pills")){
		cv_Kits = FindConVar("l4d2_multi_medical_kits");
		cv_Pills = FindConVar("l4d2_multi_medical_pills");
		cv_Kits.AddChangeHook(CvarMedical);
		cv_Pills.AddChangeHook(CvarMedical);
	}
	if(cv_Respawn != null){
		cv_Respawn.AddChangeHook(CvarRespawn);
	}
	else if(FindConVar("l4d2_respawn_number")){
		cv_Respawn = FindConVar("l4d2_respawn_number");
		cv_Respawn.AddChangeHook(CvarRespawn);
	}
}

public void CvarWeapon(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Weapon = GetConVarInt(cv_Weapon);
	if (Weapon == 0)
	{
		ServerCommand("exec vt_cfg/weapon/zonemod.cfg");
	}
	else if (Weapon == 1)
	{
		ServerCommand("exec vt_cfg/weapon/AnneHappy.cfg");
	}
	else if (Weapon == 2)
	{
		ServerCommand("exec vt_cfg/weapon/AnneHappyPlus.cfg");
	}
}
public void CvarWeaponReplace(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (cv_WeaponReplace.BoolValue)
	{
		ServerCommand("exec vt_cfg/weaponreplace.cfg");
		ServerCommand("sm_restartmap");
	}
	else
	{
		ServerCommand("l4d2_resetweaponrules");
	}
}
public void CvarRestore( ConVar convar, const char[] oldValue, const char[] newValue ) 
{
	Restore = GetConVarInt(cv_Restore);
}
public void CvarRhp( ConVar convar, const char[] oldValue, const char[] newValue ) 
{
	Rhp = GetConVarInt(cv_Rhp);
}
public void CvarAmmo( ConVar convar, const char[] oldValue, const char[] newValue) 
{
	Siammoregain = GetConVarInt(cv_Siammoregain);
}
public void CvarMedical( ConVar convar, const char[] oldValue, const char[] newValue)
{
	Kits = GetConVarInt(cv_Kits);
	Pills = GetConVarInt(cv_Pills);
}
public void CvarRespawn( ConVar convar, const char[] oldValue, const char[] newValue)
{
	Respawn = GetConVarInt(cv_Respawn);
}

void printinfo(int client = 0, bool All = true){
	char buffer[256];
	char buffer2[256];
	
	Format(buffer, sizeof(buffer), "\x03武器\x05[\x04%s\x05]", Weapon == 0?"Zone":(Weapon == 1?"Anne":"Anne+"));
	Format(buffer, sizeof(buffer), "%s \x03回血\x05[\x04%s\x05]", buffer, Rhp > 0?"开启":"关闭");
	Format(buffer, sizeof(buffer), "%s \x03回弹\x05[\x04%s\x05]", buffer, Siammoregain == 0?"关闭":"开启");
	Format(buffer, sizeof(buffer), "%s \x03复活\x05[\x04%s\x05]", buffer, Respawn == 0?"关闭":"开启");

	Format(buffer2, sizeof(buffer2), "\x03过关满血\x05[\x04%s\x05]", Restore == 0?"关闭":"开启");
	Format(buffer2, sizeof(buffer2), "%s \x03医疗倍数\x05[\x04%s\x05]", buffer2, Kits > 1 || Pills > 1?"开启":"关闭");
	if(All){
		PrintToChatAll(buffer);
		PrintToChatAll(buffer2);
	}else
	{
		PrintToChat(client, buffer);
		PrintToChat(client, buffer2);
	}
}

public Action Status(int client, int args)
{ 
	printinfo(client,false);
	return Plugin_Handled;
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	printinfo();
	return Plugin_Stop;
}
