/////////////////////////////////////////////////////////////////
// Keks Brigarde Ragdoll Remover / www.keks-brigarde.net
/////////////////////////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.2.1"
#define FALLBACK_DELAY 5.0

enum struct RagdollEntry
{
    int reference;
    float created;
    bool dissolving;
    float fallbackAt;
}

ConVar g_Enabled, g_Lifetime;
ArrayList g_Ragdolls;

public Plugin myinfo =
{
    name = "Ragdoll Remover fix",
    author = "HSFighter",
    description = "Removes CS:S ragdolls after a configurable delay",
    version = PLUGIN_VERSION,
    url = "http://www.keks-brigarde.net"
};

public void OnPluginStart()
{
    g_Ragdolls = new ArrayList(sizeof(RagdollEntry));
    CreateConVar("sm_rgremove_version", PLUGIN_VERSION, "Ragdoll Remover version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
    g_Enabled = CreateConVar("sm_rgremove_enable", "1", "Enable/Disable Ragdoll Remover", FCVAR_NONE, true, 0.0, true, 1.0);
    g_Lifetime = CreateConVar("sm_rgremove_time", "5.0", "Seconds before ragdoll dissolving starts; 0 = immediately", FCVAR_NONE, true, 0.0);
    g_Enabled.AddChangeHook(OnEnabledChanged);
    AutoExecConfig(true, "plugin.ragdoll_remover");
    CreateTimer(0.25, CheckRagdolls, _, TIMER_REPEAT);
    TrackExisting();
}

public void OnConfigsExecuted()
{
    if (g_Enabled.BoolValue) TrackExisting();
}

public void OnMapEnd()
{
    g_Ragdolls.Clear();
}

public void OnEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (g_Enabled.BoolValue) TrackExisting();
    // Preserve in-progress dissolves for fallback cleanup; forget untouched ragdolls.
    else
    {
        RagdollEntry entry;
        for (int i = g_Ragdolls.Length - 1; i >= 0; i--)
        {
            g_Ragdolls.GetArray(i, entry);
            if (!entry.dissolving) g_Ragdolls.Erase(i);
        }
    }
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (g_Enabled != null && g_Enabled.BoolValue && StrEqual(classname, "cs_ragdoll"))
    {
        TrackRagdoll(entity);
    }
}

void TrackExisting()
{
    if (!g_Enabled.BoolValue) return;
    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "cs_ragdoll")) != -1) TrackRagdoll(entity);
}

void TrackRagdoll(int entity)
{
    int reference = EntIndexToEntRef(entity);
    if (reference == INVALID_ENT_REFERENCE) return;
    RagdollEntry entry;
    for (int i = 0; i < g_Ragdolls.Length; i++)
    {
        g_Ragdolls.GetArray(i, entry);
        if (entry.reference == reference) return;
    }
    entry.reference = reference;
    entry.created = GetGameTime();
    entry.dissolving = false;
    entry.fallbackAt = 0.0;
    g_Ragdolls.PushArray(entry);
}

public Action CheckRagdolls(Handle timer)
{
    float now = GetGameTime();
    RagdollEntry entry;
    for (int i = g_Ragdolls.Length - 1; i >= 0; i--)
    {
        g_Ragdolls.GetArray(i, entry);
        int entity = EntRefToEntIndex(entry.reference);
        if (!IsRagdoll(entity))
        {
            g_Ragdolls.Erase(i);
            continue;
        }
        if (entry.dissolving)
        {
            if (now >= entry.fallbackAt)
            {
                RemoveEntity(entity);
                g_Ragdolls.Erase(i);
            }
        }
        else if (g_Enabled.BoolValue && now - entry.created >= g_Lifetime.FloatValue)
        {
            // Mark before invoking engine inputs so this ragdoll is never started twice.
            entry.dissolving = true;
            entry.fallbackAt = now + FALLBACK_DELAY;
            g_Ragdolls.SetArray(i, entry);
            if (!StartDissolve(entity) && IsRagdoll(EntRefToEntIndex(entry.reference)))
            {
                RemoveEntity(EntRefToEntIndex(entry.reference));
                g_Ragdolls.Erase(i);
            }
        }
    }
    return Plugin_Continue;
}

bool IsRagdoll(int entity)
{
    if (entity <= MaxClients || !IsValidEntity(entity)) return false;
    char classname[64];
    GetEntityClassname(entity, classname, sizeof(classname));
    return StrEqual(classname, "cs_ragdoll");
}

bool StartDissolve(int entity)
{
    int dissolver = CreateEntityByName("env_entity_dissolver");
    if (dissolver == -1) return false;
    char target[64];
    Format(target, sizeof(target), "rgremove_%d", EntIndexToEntRef(entity));
    DispatchKeyValue(entity, "targetname", target);
    // Core dissolve avoids the normal dissolve motion controller that lifts ragdolls.
    DispatchKeyValue(dissolver, "dissolvetype", "3");
    DispatchKeyValue(dissolver, "magnitude", "0");
    DispatchKeyValue(dissolver, "target", target);
    bool success = false;
    if (DispatchSpawn(dissolver)) success = AcceptEntityInput(dissolver, "Dissolve");
    if (IsValidEntity(dissolver)) RemoveEntity(dissolver);
    return success;
}
