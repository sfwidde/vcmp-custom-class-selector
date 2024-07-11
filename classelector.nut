/*
 * Custom class selector for Vice City: Multiplayer (VC:MP) 0.4 servers
 * Author: sfwidde ([R3V]Kelvin)
 * 2024-07-08
 */

const MAX_CLASS_SELECTOR_PLAYERS = 100;  // Change it to whatever max. player limit your server enforces.
const CLASS_SELECTOR_CAMERA_TIME = 1000; // Milliseconds

class PlayerClass
{
	teamId       = null; // int
	skinId       = null; // int
	color        = null; // RGB
	spawnPos     = null; // Vector
	spawnAngle   = null; // float
	spawnWeapons = null; // array
	cameraOffset = null; // Vector
}

function PlayerClass::constructor(teamId, skinId, color, spawnPos, spawnAngle, spawnWeapons, cameraOffset)
{
	this.teamId       = teamId;
	this.skinId       = skinId;
	this.color        = color;
	this.spawnPos     = spawnPos;
	this.spawnAngle   = spawnAngle;
	this.spawnWeapons = spawnWeapons;
	this.cameraOffset = cameraOffset;
}

// -----------------------------------------------------------------------------

class PlayerClassSelectorInfo
{
	// Class ID to remember to return to it upon death or when selecting
	// classes to advance to next/previous class.
	lastIndex = 0;
	// Put in class selection by default.
	canSelect = true;
	isSpawned = false;
}

// -----------------------------------------------------------------------------

ClassSelector <-
{
	classesList         = [],                                  // [::PlayerClass(), ...]
	playersSelectorInfo = ::array(MAX_CLASS_SELECTOR_PLAYERS), // [::PlayerClassSelectorInfo()/null, ...]
	Key                 =
	{
		VK_LEFT    = ::BindKey(true, 0x25, 0x00, 0x00), // Previous class
		VK_RIGHT   = ::BindKey(true, 0x27, 0x00, 0x00), // Next class
		VK_LBUTTON = ::BindKey(true, 0x01, 0x00, 0x00), // Spawn
		VK_CONTROL = ::BindKey(true, 0x11, 0x00, 0x00)  // Spawn
	}
};

function ClassSelector::AddPlayerClass(teamId, skinId, color, spawnPos, spawnAngle, cameraOffset, ...)
{
	// Validate team ID.
	if (typeof(teamId) != "integer") { throw "player class team ID must be an integer"; }

	// Validate skin ID.
	if (typeof(skinId) != "integer") { throw "player class skin ID must be an integer"; }

	// Validate color.
	if (!(color instanceof RGB)) { throw "player class color must be an RGB class instance"; }

	// Validate spawn position.
	if (!(spawnPos instanceof Vector)) { throw "player class spawn position must be a Vector class instance"; }

	// Validate spawn angle.
	local typeOfSpawnAngle = typeof(spawnAngle);
	if (typeOfSpawnAngle != "float")
	{
		if (typeOfSpawnAngle != "integer") { throw "player class spawn angle must be either a float or an integer"; }
		spawnAngle = spawnAngle.tofloat();
	}

	// Validate camera offset.
	if (!(cameraOffset instanceof Vector)) { throw "player class camera offset must be a Vector class instance"; }

	// Validate spawn weapons/ammo.
	if (vargv.len() % 2) { throw "each player class spawn weapon must have a corresponding ammo"; }
	foreach (x in vargv)
	{
		if (typeof(x) != "integer") { throw "player class spawn weapon/ammo must be an integer"; }
	}

	// Append a new class.
	classesList.append(::PlayerClass(teamId, skinId, color, spawnPos, spawnAngle, vargv, cameraOffset));
}

function ClassSelector::ForcePlayerSelect(player, offset = 0)
{
	local playerId     = player.ID;
	local selectorInfo = playersSelectorInfo[playerId];
	local newIndex     = (selectorInfo.lastIndex + offset);
	local maxIndex     = (classesList.len() - 1);
	// First to last
	if (newIndex < 0) { newIndex = maxIndex; }
	// Last to first
	else if (newIndex > maxIndex) { newIndex = 0; }

	local classData       = classesList[newIndex];
	local spawnPos        = classData.spawnPos;
	local cameraPos       = (spawnPos + classData.cameraOffset);
	local spawnWeapons    = classData.spawnWeapons;
	local spawnWeaponsLen = spawnWeapons.len();
	::SetPlayerCameraPos(
		playerId,
		// Pos
		cameraPos.x,
		cameraPos.y,
		cameraPos.z,
		// Look
		spawnPos.x,
		spawnPos.y,
		spawnPos.z,
		// InterpTimeMS
		CLASS_SELECTOR_CAMERA_TIME
	);
	player.World    = player.UniqueWorld;
	player.IsFrozen = true;
	player.Pos      = spawnPos;
	player.Angle    = classData.spawnAngle;
	player.Skin     = classData.skinId;
	player.Disarm();
	if (spawnWeaponsLen)
	{
		// Show last weapon only as it makes more sense.
		player.SetWeapon(spawnWeapons[spawnWeaponsLen - 2], spawnWeapons[spawnWeaponsLen - 1]);
	}
	player.Color  = classData.color;
	player.Health = 100.0;
	player.Armour = 0.0;

	selectorInfo.lastIndex = newIndex;
	selectorInfo.canSelect = true;

	// Attempt to call custom event.
	if ("CustomOnPlayerRequestClass" in ::getroottable())
	{
		::CustomOnPlayerRequestClass(player, newIndex);
	}
}

function ClassSelector::SpawnPlayer(player)
{
	local selectorInfo = playersSelectorInfo[player.ID];
	if (!selectorInfo.canSelect) { return; }

	local classData = classesList[selectorInfo.lastIndex];
	local spawnWeapons = classData.spawnWeapons;
	player.Team  = classData.teamId;
	player.Color = classData.color;
	player.Skin  = classData.skinId;
	player.Pos   = classData.spawnPos;
	player.Angle = classData.spawnAngle;
	player.Disarm();
	for (local i = 0, len = spawnWeapons.len(); i < len; i += 2)
	{
		player.SetWeapon(spawnWeapons[i], spawnWeapons[i + 1]);
	}
	player.Health   = 100.0;
	player.Armour   = 0.0;
	player.IsFrozen = false;
	player.World    = 1;
	player.RestoreCamera();

	selectorInfo.canSelect = false;
	selectorInfo.isSpawned = true;

	// Attempt to call custom event.
	if ("CustomOnPlayerSpawn" in ::getroottable())
	{
		::CustomOnPlayerSpawn(player);
	}
}

function ClassSelector::IsPlayerSpawned(player)
{
	return playersSelectorInfo[player.ID].isSpawned;
}

// -----------------------------------------------------------------------------

function ClassSelector::HandleScriptLoadEvent()
{
	SetUseClasses(false);
	SetKillDelay(255);
}

function ClassSelector::HandlePlayerConnectEvent(player)
{
	playersSelectorInfo[player.ID] = ::PlayerClassSelectorInfo();
}

function ClassSelector::HandlePlayerDisconnectEvent(player)
{
	playersSelectorInfo[player.ID] = null;
}

function ClassSelector::HandlePlayerRequestClassEvent(player)
{
	player.Spawn();
}

function ClassSelector::HandlePlayerSpawnEvent(player)
{
	ForcePlayerSelect(player);
}

function ClassSelector::HandlePlayerDeathEvent(player)
{
	playersSelectorInfo[player.ID].isSpawned = false;
}

function ClassSelector::HandlePlayerKeyDownEvent(player, key)
{
	switch (key)
	{
	case Key.VK_LEFT:
		if (playersSelectorInfo[player.ID].canSelect)
		{
			ForcePlayerSelect(player, -1);
		}
		return;

	case Key.VK_RIGHT:
		if (playersSelectorInfo[player.ID].canSelect)
		{
			ForcePlayerSelect(player, 1);
		}
		return;

	case Key.VK_LBUTTON:
	case Key.VK_CONTROL:
		if (!playersSelectorInfo[player.ID].canSelect ||
			(("CustomOnPlayerRequestSpawn" in ::getroottable()) && !::CustomOnPlayerRequestSpawn(player)))
		{
			return;
		}

		SpawnPlayer(player);
		return;
	}
}
