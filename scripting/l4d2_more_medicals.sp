#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
	name = "[L4D2]多倍药物",
	description = "L4D2 MultiMedical Plugin",
	author = "奈",
	version = "1.3",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart(){
	RegAdminCmd("sm_mmn", Cmd_SetMult, ADMFLAG_ROOT, "设置多倍医疗包");
	RegAdminCmd("sm_mmy", Cmd_SetMultY, ADMFLAG_ROOT, "设置多倍止痛药和肾上腺素");
}

public Action Cmd_SetMult(int client, int args){
	char tmp[3];
	GetCmdArg(1, tmp, sizeof(tmp));
	int mult = StringToInt(tmp);
	SetMultMed(mult);
	if(mult == 1){
		PrintToChatAll("\x04[提示]\x05多倍医疗包\x04关闭");
	}
	else{
		PrintToChatAll("\x04[提示]\x05多倍医疗包\x04开启 \x05更改为\x03%d\x05倍",mult);
	}
	return Plugin_Handled;
}

public Action Cmd_SetMultY(int client, int args){
	char tmp[3];
	GetCmdArg(1, tmp, sizeof(tmp));
	int mult = StringToInt(tmp);
	SetMultMedY(mult);
	if(mult == 1){
		PrintToChatAll("\x04[提示]\x05多倍止痛药和肾上腺素\x04关闭");
	}
	else{
		PrintToChatAll("\x04[提示]\x05多倍止痛药和肾上腺素\x04开启 \x05更改为\x03%d\x05倍",mult);
	}
	return Plugin_Handled;
}

void SetEntCount(const char[] ent, int count){
	int idx = FindEntityByClassname(-1, ent);
	while(idx != -1){
		DispatchKeyValueInt(idx, "count", count);
		idx = FindEntityByClassname(idx, ent);
	}
}

void SetMultMed(int mult){
	//SetEntCount("weapon_defibrillator_spawn", mult);	// 电击器
	SetEntCount("weapon_first_aid_kit_spawn", mult);	// 医疗包
	//SetEntCount("weapon_pain_pills_spawn", mult);		// 止痛药
	//SetEntCount("weapon_adrenaline_spawn", mult);		// 肾上腺素
	//SetEntCount("weapon_molotov_spawn", mult);		// 燃烧瓶
	//SetEntCount("weapon_vomitjar_spawn", mult);		// 胆汁罐
	//SetEntCount("weapon_pipe_bomb_spawn", mult);		// 土制炸弹
}

void SetMultMedY(int mult){
	//SetEntCount("weapon_defibrillator_spawn", mult);	// 电击器
	//SetEntCount("weapon_first_aid_kit_spawn", mult);	// 医疗包
	SetEntCount("weapon_pain_pills_spawn", mult);		// 止痛药
	SetEntCount("weapon_adrenaline_spawn", mult);		// 肾上腺素
	//SetEntCount("weapon_molotov_spawn", mult);		// 燃烧瓶
	//SetEntCount("weapon_vomitjar_spawn", mult);		// 胆汁罐
	//SetEntCount("weapon_pipe_bomb_spawn", mult);		// 土制炸弹
}
