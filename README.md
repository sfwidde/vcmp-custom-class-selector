# Custom class selector for Vice City: Multiplayer (VC:MP) 0.4 Squirrel servers

Click on the video below to find out what it looks like:

[![VCMP | Custom Class Selector](https://img.youtube.com/vi/w29XKjFQd10/0.jpg)](https://www.youtube.com/watch?v=w29XKjFQd10)

## Installation
1. If you haven't already, download and install
[**sqlatestfeatures** plugin](https://github.com/sfwidde/vcmp-latest-features-for-squirrel/releases/latest)
to your Squirrel server for new 0.4.7 features to be available.
2. Download **classelector.nut** server-side script file found on this
repository, paste it to your server, and load it via `dofile()`.
3. Move ALL of your `onPlayerRequestClass`, `onPlayerRequestSpawn` and
`onPlayerSpawn` events' logic (if any), to these new events with their
respectively form, leaving the aforementioned official events empty:
```
function CustomOnPlayerRequestClass(player, classID) {
	// If your script relies on 'team' and 'skin' variables provided by the
	// official 'onPlayerRequestClass' event, you could just do something like
	//
	// local team = player.Team;
	// local skin = player.Skin;
	//
	// and it would essentially be the same.
}
```
```
function CustomOnPlayerRequestSpawn(player) {
	return 1; // 0/false/null disallows spawn, any other value allows it.
}
```
```
function CustomOnPlayerSpawn(player) {
}
```
4. Add the following lines to the following official events -- if you make no
use of any of the events below, create them:
	- `onScriptLoad` OR (cannot be both!) `onServerStart`:
	```
	ClassSelector.HandleScriptLoadEvent();
	```
	- `onPlayerJoin`:
	```
	ClassSelector.HandlePlayerConnectEvent(player);
	```
	- `onPlayerPart`:
	```
	ClassSelector.HandlePlayerDisconnectEvent(player);
	```
	- `onPlayerRequestClass`:
	```
	ClassSelector.HandlePlayerRequestClassEvent(player);
	```
	- `onPlayerSpawn`:
	```
	ClassSelector.HandlePlayerSpawnEvent(player);
	```
	- `onPlayerDeath`, `onPlayerKill` and `onPlayerTeamKill`:
	```
	ClassSelector.HandlePlayerDeathEvent(player);
	```
	- `onKeyDown`:
	```
	ClassSelector.HandlePlayerKeyDownEvent(player, key);
	```

## `classelector.nut` file
### Constants
- (int) `MAX_CLASS_SELECTOR_PLAYERS`: Change it if your server enforces a
different maximum player count than 100 AND does NOT change player count at ANY
point of its lifetime (except when the server is initializing).
- (int) `CLASS_SELECTOR_CAMERA_TIME`: Time in milliseconds a player's camera
takes from switching from one class to another.

### Functions
- `void ClassSelector::AddPlayerClass(int teamId, int skinId, RGB color,
Vector spawnPos, float spawnAngle, Vector cameraOffset[, int spawnWeapon1Id,
int spawnWeapon1Ammo, int spawnWeapon2Id, int spawnWeapon2Ammo, ...])`
	- Adds a new custom player class.
	- (New!) Parameter `cameraOffset`: Offset distance from player's position
	and player's camera. Camera will always look at the player in question but
	this is how we control where to position it.
	- (New!) Spawn weapons are no longer limited to 3 mandatory weapons per
	class - weapons are now optional and limitless.
- `void ClassSelector::ForcePlayerSelect(player)`
	- Puts player back to the request class screen.
- `void ClassSelector::SpawnPlayer(player)`
	- Forces player to spawn, if unspawned.
- `bool ClassSelector::IsPlayerSpawned(player)`
	- Returns `true` if player is spawned, `false` otherwise.

### Notes
You will have to replace *every* call to `player.IsSpawned` in your code to
`ClassSelector.IsPlayerSpawned(player)` to prevent bugs in your gamemode.

`void ClassSelector::HandleScriptLoadEvent(void)` does the following to your
server:
- Disables built-in class selection (`SetUseClasses(false)`).
- Disables **/kill** client built-in command (`SetKillDelay(255)`).

Re-enabling the above settings is **not** recommended and could lead to
unexpected behavior.

## Examples
This is the code that was used to record demonstration video above, hopefully
you will have a better understanding on how adding a custom class works:
```
ClassSelector.AddPlayerClass(
	0,                                   // Team ID
	0,                                   // Skin ID
	RGB(255, 20,  147),                  // Color
	Vector(-345.234, -541.752, 17.2831), // Spawn position
	0.67678,                             // Spawn angle
	Vector(-2.0, -3.0, 1.0),             // Camera offset
	// Weapons list
	WEP_GOLFCLUB,   1,
	WEP_COLT45,     9999,
	WEP_STUBBY,     9999,
	WEP_LASERSCOPE, 9999,
	WEP_M60,        9999,
	WEP_MP5,        9999
);
ClassSelector.AddPlayerClass(
	1,
	1,
	RGB(119, 136, 153),
	Vector(-657.743, 762.015, 11.6),
	2.3569,
	Vector(0.0, -2.5, -0.6),
	WEP_NIGHTSTICK, 1,
	WEP_SHOTGUN,    9999,
	WEP_INGRAM,     9999,
	WEP_PYTHON,     9999
);
ClassSelector.AddPlayerClass(
	1,
	6,
	RGB(119, 136, 153),
	Vector(-698.566, 924.329, 11.0846),
	-1.56725,
	Vector(8.25, 0.0, 0.25),
	WEP_MOLOTOV,      9999,
	WEP_COLT45,       9999,
	WEP_SPAZ,         9999,
	WEP_SNIPER,       9999,
	WEP_FLAMETHROWER, 9999
);
ClassSelector.AddPlayerClass(
	2,
	87,
	RGB(255, 140, 19),
	Vector(74.665, 1112.72, 23.2426),
	-3.10968,
	Vector(0.0, -12.0, 0.0),
	WEP_KNIFE, 1
);
ClassSelector.AddPlayerClass(
	3,
	58,
	RGB(20,  255, 127),
	Vector(572.756, -457.873, 12.1975),
	-1.18129,
	Vector(4.0, 3.0, -0.25)
);
```