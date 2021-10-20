#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <shop>
#include <clientprefs>
#include <multicolors>

KeyValues Kv;

Handle g_hCookie;

bool g_bEnabled[MAXPLAYERS+1],
	 g_bShouldSee[MAXPLAYERS+1],
	 g_bHide;
	 
float g_fAmplitude[MAXPLAYERS+1];

int g_iSprite,
	g_iColor[MAXPLAYERS+1][4];

public Plugin myinfo =
{
	name = "[Shop] Color Tracers",
	author = "FrozDark & R1KO",
	description = "Grant players to buy colored tracers",
	version = "2.0.4",
	url  = "www.hlmod.ru"
};

public void OnPluginStart()
{
	HookEvent("bullet_impact", BulletImpact, EventHookMode_Post);	
	if (Shop_IsStarted()) Shop_Started();
	
	g_hCookie = RegClientCookie("sm_shop_tracers_v2", "1 - enabled, 0 - disabled", CookieAccess_Private);
	
	for ( int i = 1; i <= MaxClients; ++i ) {
		if ( IsClientInGame(i) ) {
			OnClientCookiesCached(i);
		}
	}
}

public void OnPluginEnd()
{
	Shop_UnregisterMe();
}

public void OnMapStart() 
{
	if (Kv != INVALID_HANDLE) 
		CloseHandle(Kv);

	char buffer[PLATFORM_MAX_PATH];

	Kv = CreateKeyValues("Tracers");

	Shop_GetCfgFile(buffer, sizeof(buffer), "tracers.txt");

	if (!Kv.ImportFromFile(buffer)) 
		SetFailState("Couldn't parse file %s", buffer);
	Kv.Rewind();

	Kv.GetString("material", buffer, sizeof(buffer), "materials/sprites/laser.vmt");
	g_iSprite = PrecacheModel(buffer);
}

public void Shop_Started()
{
	if (Kv == null) OnMapStart();

	Kv.Rewind();
	char sName[64], sDescription[64];
	g_bHide = view_as<bool>(Kv.GetNum("hide_opposite_team"));
	Kv.GetString("name", sName, sizeof(sName), "Color Tracers");
	Kv.GetString("description", sDescription, sizeof(sDescription));

	CategoryId category_id = Shop_RegisterCategory("color_tracers", sName, sDescription);

	Kv.Rewind();

	if (Kv.GotoFirstSubKey())
	{
		do
		{
			if (Kv.GetSectionName(sName, sizeof(sName)) && Shop_StartItem(category_id, sName))
			{
				Kv.GetString("name", sDescription, sizeof(sDescription), sName);
				Shop_SetInfo(sDescription, "", Kv.GetNum("price", 1000), Kv.GetNum("sellprice", -1), Item_Togglable, Kv.GetNum("duration", 604800), Kv.GetNum("gold_price", -1), Kv.GetNum("gold_sell_price", -1));
				Shop_SetCustomInfo("level", Kv.GetNum("level", 0));
				Shop_SetLuckChance(Kv.GetNum("luckchance", 100));
				Shop_SetHide(view_as<bool>(Kv.GetNum("hidden", 0)));
				Shop_SetCallbacks(_, OnTracersUsed);
				Shop_EndItem();
			}
		} while (Kv.GotoNextKey());
	}

	Kv.Rewind();

	Shop_AddToFunctionsMenu(FuncToggleVisibilityDisplay, FuncToggleVisibility);
}

public void FuncToggleVisibilityDisplay(int client, char[] buffer, int maxlength)
{
	Format(buffer, maxlength, "Tracers: %s", g_bShouldSee[client] ? "Visible" : "Hidden");
}

public bool FuncToggleVisibility(int client)
{
	g_bShouldSee[client] = !g_bShouldSee[client];
	CPrintToChat(client, "{green}[Shop] {default}Shop tracers is %s{default}.", g_bShouldSee[client] ? "{blue}visible":"{red}hidden");
	return false;
}

public void OnClientPostAdminCheck(int client)
{
	g_bEnabled[client] = false;
}

public void OnClientCookiesCached(int client)
{
	g_bShouldSee[client] = GetCookieBool(client, g_hCookie);
}

bool GetCookieBool(int iClient, Handle hCookie)
{
	char sBuffer[4];
	GetClientCookie(iClient, hCookie, sBuffer, 4);
	return (StringToInt(sBuffer) == 0 && sBuffer[0] != 0)?false:true;
}

public void OnClientDisconnect(int client)
{
	SetCookieBool(client, g_hCookie, g_bShouldSee[client]);
	g_bShouldSee[client] = true;
}

void SetCookieBool(int iClient, Handle hCookie, bool bValue)
{
	if ( bValue ) {
		SetClientCookie(iClient, hCookie, "1");
	}
	else {
		SetClientCookie(iClient, hCookie, "0");
	}
}

public ShopAction OnTracersUsed(int iClient, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, bool isOn, bool elapsed)
{
	if (isOn || elapsed)
	{
		g_bEnabled[iClient] = false;
		return Shop_UseOff;
	}

	Kv.Rewind();
	if(Kv.JumpToKey(item))
	{
		g_bEnabled[iClient] = true;
		Kv.GetColor("color", g_iColor[iClient][0], g_iColor[iClient][1], g_iColor[iClient][2], g_iColor[iClient][3]);
		
		g_fAmplitude[iClient] = Kv.GetFloat("amplitude", 0.0);
		return Shop_UseOn;
	}
	Kv.Rewind();
	
	return Shop_Raw;
}

public void BulletImpact(Event event, char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));

	if(iClient <= 0 || !g_bEnabled[iClient]) return;

	float bulletOrigin[3], newBulletOrigin[3],bulletDestination[3];
	int[] clients = new int [MaxClients];

	GetClientEyePosition(iClient, bulletOrigin);

	bulletDestination[0] = event.GetFloat("x");
	bulletDestination[1] = event.GetFloat("y");
	bulletDestination[2] = event.GetFloat("z");

	float distance = GetVectorDistance(bulletOrigin, bulletDestination),percentage = 0.4 / (distance / 100);

	newBulletOrigin[0] = bulletOrigin[0] + ((bulletDestination[0] - bulletOrigin[0]) * percentage);
	newBulletOrigin[1] = bulletOrigin[1] + ((bulletDestination[1] - bulletOrigin[1]) * percentage) - 0.08;
	newBulletOrigin[2] = bulletOrigin[2] + ((bulletDestination[2] - bulletOrigin[2]) * percentage);

	TE_SetupBeamPoints(newBulletOrigin, bulletDestination, g_iSprite, 0, 0, 0, 0.2, 2.0, 2.0, 1, g_fAmplitude[iClient], g_iColor[iClient], 0);

	int totalClients = 0;

	int iTeam = GetClientTeam(iClient);
	for(int i = 1; i <= MaxClients; i++)
	{
		if (g_bHide && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == iTeam && g_bShouldSee[i])
		{
			clients[totalClients++] = i;
		}
		else if (!g_bHide && IsClientInGame(i) && !IsFakeClient(i) && g_bShouldSee[i])
		{
			clients[totalClients++] = i;
		}
	}

	TE_Send(clients, totalClients);
}