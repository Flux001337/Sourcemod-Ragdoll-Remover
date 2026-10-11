# SourceMod - Ragdoll Remover

SourceMod that dissolves Counter-Strike: Source ragdolls after a configurable delay.
Current version: **1.2.1**. See [CHANGELOG.md](CHANGELOG.md).

## Features

- Track `cs_ragdoll` entities directly, independently of the player's `m_hRagdoll` property.
- Start dissolving each ragdoll after its configured lifetime.
- Use the Core dissolve effect with zero magnitude to avoid the normal dissolve lift.
- Prevent duplicate scheduling and use entity references to protect against reused entity indices.
- Remove ragdolls immediately if starting the dissolve fails.
- Remove surviving ragdolls five seconds after starting the dissolve as a fallback.
- Detect existing ragdolls when loaded late or enabled again.

## Requirements

- Counter-Strike: Source with SourceMod, SDK Tools, and SDK Hooks.
- Only standard SourceMod includes are needed for compilation.

Compiled with SourceMod 1.12.0.7253 without errors or warnings. Version 1.2.1 has not yet been tested on a game server.

## Installation

Copy `plugins/ragdoll_remover.smx` to `addons/sourcemod/plugins/`. Load the plugin with `sm plugins load ragdoll_remover` or change the map.
The configuration is generated at `cfg/sourcemod/plugin.ragdoll_remover.cfg`.
For updates, replace the SMX and run `sm plugins reload ragdoll_remover`.

## Configuration

| ConVar | Default | Description |
| --- | --- | --- |
| `sm_rgremove_version` | `1.2.1` | Plugin version |
| `sm_rgremove_enable` | `1` | Enable or disable new removals |
| `sm_rgremove_time` | `5.0` | Seconds before dissolving starts; 0 = as soon as the next check runs |

For a 60-second delay, add this to the generated configuration:

```text
sm_rgremove_time "60"
```

Checks run every 0.25 seconds, so dissolving starts within approximately one check interval after the configured delay. The dissolve animation takes additional time.
Changing the delay also affects tracked ragdolls whose dissolve has not started. Already dissolving ragdolls retain their fallback cleanup even if the plugin is disabled.
Existing ragdolls found at startup or when enabling the plugin are timed from discovery because their original creation time is unknown.
There are no player or admin commands.

## CSS:DM compatibility

The plugin does not read or modify `cssdm_ragdoll_time` or `cssdm_respawn_wait`. It works without CSS:DM.
Other plugins and game logic can still remove a ragdoll earlier. A delay of 60 seconds here does not guarantee a corpse remains for 60 seconds if CSS:DM removes it on respawn.

## Build

Run from this repository directory. The shared compiler and standard includes in the current workspace are three directories above. For a standalone checkout, replace those paths with your SourceMod installation path.

Linux:

```sh
mkdir -p plugins
../../../spcomp64 scripting/ragdoll_remover.sp -i../../../include -oplugins/ragdoll_remover.smx
```

Windows CMD:

```bat
if not exist plugins mkdir plugins
../../../spcomp64.exe scripting/ragdoll_remover.sp -i../../../include -oplugins/ragdoll_remover.smx
```

## Repository structure

```text
scripting/
└── ragdoll_remover.sp
```

Compiled binaries, release packages, and backups are excluded from Git. A release ZIP contains `plugins/ragdoll_remover.smx` and `scripting/`; extract it into `addons/sourcemod/`.
The original working files and backup remain in `../Ragdoll remover/`. Make future changes in this repository's `scripting/ragdoll_remover.sp`; the copies are not synchronized automatically.

## Author and source notices

HSFighter — http://www.keks-brigarde.net
