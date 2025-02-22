#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	if ( !isDefined( level.tweakablesInitialized ) )
		maps\mp\gametypes\_tweakables::init();

	level.splitscreen = 0;
	level.xenon = 0;
	level.ps3 = 0;
	level.console = 0;
	level.oldschool = 0;

	level.onlineGame = false;
	level.rankedMatch = false;

	level.script = toLower( getDvar( "mapname" ) );
	level.gametype = toLower( getDvar( "g_gametype" ) );

	checkRestartMap();

	level.otherTeam["allies"] = "axis";
	level.otherTeam["axis"] = "allies";

	level.teamBased = false;

	level.overrideTeamScore = false;
	level.overridePlayerScore = false;
	level.displayHalftimeText = false;
	level.displayRoundEndText = true;

	level.endGameOnScoreLimit = true;
	level.endGameOnTimeLimit = true;

	precacheString( &"MP_HALFTIME" );
	precacheString( &"MP_OVERTIME" );
	precacheString( &"MP_ROUNDEND" );
	precacheString( &"MP_INTERMISSION" );
	precacheString( &"MP_SWITCHING_SIDES" );
	precacheString( &"MP_CONNECTED" );

	level.halftimeType = "halftime";
	level.halftimeSubCaption = &"MP_SWITCHING_SIDES";

	level.lastStatusTime = 0;
	level.wasWinning = "none";

	level.lastSlowProcessFrame = 0;

	level.placement["allies"] = [];
	level.placement["axis"] = [];
	level.placement["all"] = [];

	level.postRoundTime = 5;

	level.inOvertime = false;

	level.players = [];

	registerDvars();

	precacheModel( "tag_origin" );

	precacheShader( "faction_128_usmc" );
	precacheShader( "faction_128_arab" );
	precacheShader( "faction_128_ussr" );
	precacheShader( "faction_128_sas" );

	if ( !isDefined( game["tiebreaker"] ) )
		game["tiebreaker"] = false;

	if ( !isDefined( game["gamestarted"] ) )
		promod\modes::main();

	level.roundswitch = getDvarInt( "scr_" + level.gametype + "_roundswitch" );
	level.roundLimit = getDvarInt( "scr_" + level.gametype + "_roundlimit" );
	level.timelimit = getDvarFloat( "scr_" + level.gametype + "_timelimit" );
	level.scoreLimit = getDvarInt( "scr_" + level.gametype + "_scorelimit" );
	level.numLives = getDvarInt( "scr_" + level.gametype + "_numlives" );

	setDvar( "ui_scorelimit", level.scoreLimit );
	setDvar( "ui_timelimit", level.timelimit );

	setDvar( "scr_player_maxhealth", 100 );
}

registerDvars()
{
	setDvar( "ui_bomb_timer", 0 );
	makeDvarServerInfo( "ui_bomb_timer" );
}

SetupCallbacks()
{
	level.spawnPlayer = ::spawnPlayer;
	level.spawnClient = ::spawnClient;
	level.spawnSpectator = ::spawnSpectator;
	level.spawnIntermission = ::spawnIntermission;
	level.onPlayerScore = ::default_onPlayerScore;
	level.onTeamScore = ::default_onTeamScore;

	level.onXPEvent = ::onXPEvent;
	level.waveSpawnTimer = ::waveSpawnTimer;

	level.onSpawnPlayer = ::blank;
	level.onSpawnSpectator = ::default_onSpawnSpectator;
	level.onSpawnIntermission = ::default_onSpawnIntermission;
	level.onRespawnDelay = ::blank;

	level.onTimeLimit = ::default_onTimeLimit;
	level.onScoreLimit = ::default_onScoreLimit;
	level.onDeadEvent = ::default_onDeadEvent;
	level.onOneLeftEvent = ::default_onOneLeftEvent;
	level.giveTeamScore = ::giveTeamScore;
	level.givePlayerScore = ::givePlayerScore;

	level._setTeamScore = ::_setTeamScore;
	level._setPlayerScore = ::_setPlayerScore;

	level._getTeamScore = ::_getTeamScore;
	level._getPlayerScore = ::_getPlayerScore;

	level.onPrecacheGametype = ::blank;
	level.onStartGameType = ::blank;
	level.onPlayerConnect = ::blank;
	level.onPlayerDisconnect = ::blank;
	level.onPlayerDamage = ::blank;
	level.onPlayerKilled = ::blank;

	level.onEndGame = ::blank;

	level.autoassign = ::menuAutoAssign;
	level.spectator = ::menuSpectator;
	level.killspec = ::menuKillspec;
	level.allies = ::menuAllies;
	level.axis = ::menuAxis;
}

WaitTillSlowProcessAllowed()
{
	while ( level.lastSlowProcessFrame == gettime() )
		wait 0.05;

	level.lastSlowProcessFrame = gettime();
}

blank( arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 )
{
}

default_onDeadEvent( team )
{
	if ( team == "allies" )
	{
		iPrintLn( game["strings"]["allies_eliminated"] );
		thread endGame( "axis", game["strings"]["allies_eliminated"] );
	}
	else if ( team == "axis" )
	{
		iPrintLn( game["strings"]["axis_eliminated"] );
		thread endGame( "allies", game["strings"]["axis_eliminated"] );
	}
	else
	{
		if ( level.teamBased )
			thread endGame( "tie", game["strings"]["tie"] );
		else thread endGame( undefined, game["strings"]["tie"] );
	}
}

default_onOneLeftEvent( team )
{
	if ( !level.teamBased )
	{
		winner = getHighestScoringPlayer();
		thread endGame( winner, &"MP_ENEMIES_ELIMINATED" );
	}
}

default_onTimeLimit()
{
	winner = undefined;

	if ( level.teamBased )
	{
		if ( game["teamScores"]["allies"] == game["teamScores"]["axis"] )
			winner = "tie";
		else if ( game["teamScores"]["axis"] > game["teamScores"]["allies"] )
			winner = "axis";
		else winner = "allies";
	}
	else winner = getHighestScoringPlayer();

	thread endGame( winner, game["strings"]["time_limit_reached"] );
}

default_onScoreLimit()
{
	if ( !level.endGameOnScoreLimit )
		return;

	winner = undefined;

	if ( level.teamBased )
	{
		if ( game["teamScores"]["allies"] == game["teamScores"]["axis"] )
			winner = "tie";
		else if ( game["teamScores"]["axis"] > game["teamScores"]["allies"] )
			winner = "axis";
		else winner = "allies";
	}
	else winner = getHighestScoringPlayer();

	level.forcedEnd = true;
	thread endGame( winner, game["strings"]["score_limit_reached"] );
}

updateGameEvents()
{
	if ( ( !level.numLives && !level.inOverTime ) || level.inGracePeriod )
		return;

	if ( level.teamBased )
	{
		if ( level.everExisted["allies"] && !level.aliveCount["allies"] && level.everExisted["axis"] && !level.aliveCount["axis"] && !level.playerLives["allies"] && !level.playerLives["axis"] )
		{
			[[level.onDeadEvent]]( "all" );
			return;
		}

		if ( level.everExisted["allies"] && !level.aliveCount["allies"] && !level.playerLives["allies"] )
		{
			[[level.onDeadEvent]]( "allies" );
			return;
		}

		if ( level.everExisted["axis"] && !level.aliveCount["axis"] && !level.playerLives["axis"] )
		{
			[[level.onDeadEvent]]( "axis" );
			return;
		}

		if ( level.lastAliveCount["allies"] > 1 && level.aliveCount["allies"] == 1 && level.playerLives["allies"] == 1 )
		{
			[[level.onOneLeftEvent]]( "allies" );
			return;
		}

		if ( level.lastAliveCount["axis"] > 1 && level.aliveCount["axis"] == 1 && level.playerLives["axis"] == 1 )
		{
			[[level.onOneLeftEvent]]( "axis" );
			return;
		}
	}
	else
	{
		if ( (!level.aliveCount["allies"] && !level.aliveCount["axis"]) && (!level.playerLives["allies"] && !level.playerLives["axis"]) && level.maxPlayerCount > 1 )
		{
			[[level.onDeadEvent]]( "all" );
			return;
		}

		if ( (level.aliveCount["allies"] + level.aliveCount["axis"] == 1) && (level.playerLives["allies"] + level.playerLives["axis"] == 1) && level.maxPlayerCount > 1 )
		{
			[[level.onOneLeftEvent]]( "all" );
			return;
		}
	}
}

matchStartTimer()
{
	visionSetNaked( "mpIntro", 0 );

	matchStartText = createServerFontString( "big", 1.5 );
	matchStartText setPoint( "CENTER", "CENTER", 0, -60 );
	matchStartText.sort = 1001;
	matchStartText setText( game["strings"]["match_starting_in"] );
	matchStartText.foreground = false;
	matchStartText.hidewheninmenu = true;

	matchStartTimer = createServerTimer( "big", 1.4 );
	matchStartTimer setPoint( "CENTER", "CENTER", 0, -45 );
	matchStartTimer setTimer( level.prematchPeriod );
	matchStartTimer.sort = 1001;
	matchStartTimer.foreground = false;
	matchStartTimer.hideWhenInMenu = true;

	wait level.prematchPeriod;

	visionSetNaked( getDvar( "mapname" ), 1 );

	matchStartText destroyElem();
	matchStartTimer destroyElem();
}

matchStartTimerSkip()
{
	visionSetNaked( getDvar( "mapname" ), 0 );
}

spawnPlayer()
{
	prof_begin( "spawnPlayer_preUTS" );

	self endon("disconnect");
	self endon("joined_spectators");
	self endon("joined_team");
	self notify("spawned");
	self notify("end_respawn");

	self setSpawnVariables();

	if ( isDefined( self.proxBar ) )
		self.proxBar destroyElem();
	if ( isDefined( self.proxBarText ) )
		self.proxBarText destroyElem();
	if ( isDefined( self.xpBar ) )
		self.xpBar destroyElem();

	if ( level.teamBased )
		self.sessionteam = self.team;
	else
		self.sessionteam = "none";

	hadSpawned = self.hasSpawned;

	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;

	self.maxhealth = maps\mp\gametypes\_tweakables::getTweakableValue( "player", "maxhealth" );
	self.health = self.maxhealth;
	self.hasSpawned = true;
	self.spawnTime = getTime();

	if ( self.pers["lives"] )
		self.pers["lives"]--;

	if ( !self.wasAliveAtMatchStart )
	{
		acceptablePassedTime = 20;
		if ( level.timeLimit > 0 && acceptablePassedTime < level.timeLimit * 15 )
			acceptablePassedTime = level.timeLimit * 15;

		if ( level.inGracePeriod || getTimePassed() < acceptablePassedTime * 1000 )
			self.wasAliveAtMatchStart = true;
	}

	[[level.onSpawnPlayer]]();

	prof_end( "spawnPlayer_preUTS" );

	level thread updateTeamStatus();

	prof_begin( "spawnPlayer_postUTS" );

	if ( isDefined( game["PROMOD_KNIFEROUND"] ) && game["PROMOD_KNIFEROUND"] && isDefined( level.strat_over ) && level.strat_over )
		self thread removeWeapons();
	else self maps\mp\gametypes\_class::giveLoadout( self.team, self.class );

	if ( level.inPrematchPeriod && game["promod_do_readyup"] )
		self freezeControls( true );
	else if ( level.inPrematchPeriod )
		self freezeControls( true );
	else
	{
		self freezeControls( false );
		self enableWeapons();
	}

	if ( isDefined( level.strat_over ) && !level.strat_over )
	{
		self allowsprint(false);
		self allowjump(false);
		self setMoveSpeedScale( 0 );
	}

	prof_end( "spawnPlayer_postUTS" );

	wait 0.1;

	self notify( "spawned_player" );

	if ( isDefined( game["state"] ) && game["state"] == "postgame" )
		self freezePlayerForRoundEnd();

	waittillframeend;

	if ( !isDefined( level.rdyup ) || !level.rdyup )
		self.statusicon = "";
}

removeWeapons()
{
	self endon("disconnect");

	self maps\mp\gametypes\_class::giveLoadout( self.team, self.class );

	wait 0.05;

	attachment = "";
	if(self.pers[self.pers["class"]]["loadout_secondary_attachment"] == "silencer")
		attachment = "_silencer";

	sidearmWeapon = self.pers[self.pers["class"]]["loadout_secondary"]+attachment+"_mp";

	self takeAllWeapons();
	self giveWeapon(sidearmWeapon, 0);
	self setweaponammoclip(sidearmWeapon, 0);
	self setweaponammostock(sidearmWeapon, 0);
	self switchtoWeapon(sidearmWeapon);
	self setclientdvar("g_compassShowEnemies", 1);
}

spawnSpectator( origin, angles )
{
	self notify("spawned");
	self notify("end_respawn");
	in_spawnSpectator( origin, angles );
}

respawn_asSpectator( origin, angles )
{
	in_spawnSpectator( origin, angles );
}

in_spawnSpectator( origin, angles )
{
	self setSpawnVariables();

	if ( self.pers["team"] == "spectator" )
		self clearLowerMessage();

	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;

	if(self.pers["team"] == "spectator")
	{
		if ( !isDefined( level.rdyup ) || !level.rdyup )
			self.statusicon = "";

		if ( !isDefined( self.freelook ) )
			self thread monitorFreeLook();
	}

	maps\mp\gametypes\_spectating::setSpectatePermissions();

	[[level.onSpawnSpectator]]( origin, angles );

	level thread updateTeamStatus();
}

getPlayerFromClientNum( clientNum )
{
	if ( clientNum < 0 )
		return undefined;

	for ( i = 0; i < level.players.size; i++ )
	{
		if ( level.players[i] getEntityNumber() == clientNum )
			return level.players[i];
	}
	return undefined;
}

waveSpawnTimer()
{
	level endon( "game_ended" );

	while ( isDefined( game["state"] ) && game["state"] == "playing" )
	{
		time = getTime();

		if ( time - level.lastWave["allies"] > (level.waveDelay["allies"] * 1000) )
		{
			level notify ( "wave_respawn_allies" );
			level.lastWave["allies"] = time;
			level.wavePlayerSpawnIndex["allies"] = 0;
		}

		if ( time - level.lastWave["axis"] > (level.waveDelay["axis"] * 1000) )
		{
			level notify ( "wave_respawn_axis" );
			level.lastWave["axis"] = time;
			level.wavePlayerSpawnIndex["axis"] = 0;
		}

		wait 0.05;
	}
}

freeLook( condition )
{
	if ( condition )
		wait 0.1;

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( player.pers["team"] == "spectator" )
		{
			if ( !isDefined( player.freelook ) || !player.freelook )
				player allowSpectateTeam( "freelook", condition );
		}
	}
}

monitorFreeLook()
{
	self.freelook = true;

	self thread checkADS();
	self thread checkAttack();
	self thread checkMelee();
}

checkMelee()
{
	self endon("disconnect");
	self endon("joined_team");

	waittillframeend;

	for(;;)
	{
		if ( self meleeButtonPressed() )
		{
			self notify ( "stop_follow" );
			self.freelook = true;
			self.spectatorlast = undefined;
		}

		while ( self meleeButtonPressed() )
		{
			wait 0.05;
			continue;
		}

		wait 0.05;
	}
}

checkAttack()
{
	self endon("disconnect");
	self endon("joined_team");

	waittillframeend;

	for(;;)
	{
		if ( self attackButtonPressed() )
		{
			for ( i = 0; i < level.players.size; i++ )
			{
				players = level.players[i];

				if ( isAlive( players ) && ( ( players.pers["team"] == "allies" || players.pers["team"] == "axis" ) ) )
				{
					self notify ( "stop_follow" );
					self.freelook = false;
					break;
				}
			}
		}

		while ( self attackButtonPressed() )
		{
			wait 0.05;
			continue;
		}

		wait 0.05;
	}
}

checkADS()
{
	self endon("disconnect");
	self endon("joined_team");

	waittillframeend;

	for(;;)
	{
		while( !self adsButtonPressed() )
			wait 0.05;

		for ( i = 0; i < level.players.size; i++ )
		{
			players = level.players[i];

			if ( isAlive( players ) && ( ( players.pers["team"] == "allies" || players.pers["team"] == "axis" ) ) )
			{
				self notify ( "stop_follow" );
				self.freelook = false;
				break;
			}
		}

		while( self adsButtonPressed() )
			wait 0.05;
	}
}

default_onSpawnSpectator( origin, angles)
{
	thread freeLook( false );

	if( isDefined( origin ) && isDefined( angles ) )
	{
		self spawn(origin, angles);
		thread freeLook( true );
		return;
	}

	spawnpointname = "mp_global_intermission";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

	self spawn(spawnpoint.origin, spawnpoint.angles);

	thread freeLook( true );
}

spawnIntermission()
{
	self notify("spawned");
	self notify("end_respawn");

	self setSpawnVariables();

	self clearLowerMessage();

	self freezeControls( false );

	self.sessionstate = "intermission";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;

	[[level.onSpawnIntermission]]();
	self setDepthOfField( 0, 128, 512, 4000, 6, 1.8 );
}

default_onSpawnIntermission()
{
	spawnpointname = "mp_global_intermission";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = spawnPoints[0];

	if( isDefined( spawnpoint ) )
		self spawn( spawnpoint.origin, spawnpoint.angles );
}

timeUntilRoundEnd()
{
	if ( level.gameEnded )
	{
		timePassed = (getTime() - level.gameEndTime) / 1000;
		timeRemaining = level.postRoundTime - timePassed;

		if ( timeRemaining < 0 )
			return 0;

		return timeRemaining;
	}

	if ( level.inOvertime || level.timeLimit <= 0 || !isDefined( level.startTime ) )
		return undefined;

	timePassed = (getTime() - level.startTime)/1000;
	timeRemaining = (level.timeLimit * 60) - timePassed;

	return timeRemaining + level.postRoundTime;
}

freezePlayerForRoundEnd()
{
	self clearLowerMessage();
}

freeGameplayHudElems()
{
	if ( isDefined( self.lowerMessage ) )
		self.lowerMessage destroyElem();
	if ( isDefined( self.lowerTimer ) )
		self.lowerTimer destroyElem();

	if ( isDefined( self.proxBar ) )
		self.proxBar destroyElem();
	if ( isDefined( self.proxBarText ) )
		self.proxBarText destroyElem();
}

endGame( winner, endReasonText )
{
	if ( isDefined( game["state"] ) && game["state"] == "postgame" )
		return;

	if ( isDefined( level.onEndGame ) )
		[[level.onEndGame]]( winner );

	setDvar( "g_deadChat", 1 );

	game["state"] = "postgame";
	level.gameEndTime = getTime();
	level.gameEnded = true;
	level.inGracePeriod = false;

	level notify ( "game_ended" );

	setGameEndTime( 0 );

	updatePlacement();

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];

		player freezePlayerForRoundEnd();
		player thread roundEndDoF( 4 );
		player freeGameplayHudElems();
	}

	if ( (level.roundLimit > 1 || (!level.roundLimit && level.scoreLimit != 1)) && !level.forcedEnd )
	{
		if ( level.displayRoundEndText )
		{
			for ( i = 0; i < level.players.size; i++ )
			{
				player = level.players[i];

				if ( level.teamBased )
					player thread maps\mp\gametypes\_hud_message::teamOutcomeNotify( winner, true, endReasonText, 0.75 );
				else player thread maps\mp\gametypes\_hud_message::outcomeNotify( winner, endReasonText, 0.75 );

				if ( isDefined( player.pers["team"] ) && player.pers["team"] == "spectator" )
					continue;

				player setStat( 75, 1 );
				player setClientDvars( "cg_drawSpectatorMessages", 0, "g_compassShowEnemies", 0 );
			}

			level thread header();

			if ( hitRoundLimit() || hitScoreLimit() )
				roundEndWait( level.roundEndDelay / 2 );
			else roundEndWait( level.roundEndDelay );
		}

		game["roundsplayed"]++;
		roundSwitching = false;
		if ( !hitRoundLimit() && !hitScoreLimit() )
			roundSwitching = checkRoundSwitch();

		if ( roundSwitching && level.teamBased )
		{
			for ( i = 0; i < level.players.size; i++ )
			{
				player = level.players[i];

				if ( !isDefined( player.pers["team"] ) || player.pers["team"] == "spectator" )
				{
					player [[level.spawnIntermission]]();
					player closeMenu();
					player closeInGameMenu();
					continue;
				}

				switchType = level.halftimeType;
				if ( switchType == "halftime" )
				{
					if ( level.roundLimit )
					{
						if ( (game["roundsplayed"] * 2) == level.roundLimit )
							switchType = "halftime";
						else
							switchType = "intermission";
					}
					else if ( level.scoreLimit )
					{
						if ( game["roundsplayed"] == (level.scoreLimit - 1) )
							switchType = "halftime";
						else switchType = "intermission";
					}
					else switchType = "intermission";
				}

				player thread maps\mp\gametypes\_hud_message::teamOutcomeNotify( switchType, true, level.halftimeSubCaption );
				player setStat( 75, 1 );

				if ( player.pers["team"] == "axis" )
				{
					player.switching = true;
					player menuAllies();
				}
				else if( player.pers["team"] == "allies" )
				{
					player.switching = true;
					player menuAxis();
				}
			}

			old_score = game["teamScores"]["allies"];
			game["teamScores"]["allies"] = game["teamScores"]["axis"];
			game["teamScores"]["axis"] = old_score;

			game["allies_timeout_called"] = 0;
			game["axis_timeout_called"] = 0;

			thread maps\mp\gametypes\_promod::updateClassAvailability( "allies" );
			thread maps\mp\gametypes\_promod::updateClassAvailability( "axis" );

			roundEndWait( level.halftimeRoundEndDelay );
		}
		else if ( !hitRoundLimit() && !hitScoreLimit() && !level.displayRoundEndText && level.teamBased )
		{
			for ( i = 0; i < level.players.size; i++ )
			{
				player = level.players[i];

				if ( !isDefined( player.pers["team"] ) || player.pers["team"] == "spectator" )
				{
					player [[level.spawnIntermission]]();
					player closeMenu();
					player closeInGameMenu();
					continue;
				}

				switchType = level.halftimeType;
				if ( switchType == "halftime" )
				{
					if ( level.roundLimit )
					{
						if ( (game["roundsplayed"] * 2) == level.roundLimit )
							switchType = "halftime";
						else
							switchType = "roundend";
					}
					else if ( level.scoreLimit )
					{
						if ( game["roundsplayed"] == (level.scoreLimit - 1) )
							switchType = "halftime";
						else
							switchTime = "roundend";
					}
				}

				player thread maps\mp\gametypes\_hud_message::teamOutcomeNotify( switchType, true, endReasonText );
				player setStat( 75, 1 );
			}

			roundEndWait( level.halftimeRoundEndDelay );
		}

		if ( isDefined(game["PROMOD_KNIFEROUND"]) && game["PROMOD_KNIFEROUND"] )
		{
			game["promod_do_readyup"] = 1;
			game["promod_first_readyup_done"] = 0;
			for(i=0;i<level.players.size;i++)
			{
				level.players[i].pers["kills"] = 0;
				level.players[i].pers["deaths"] = 0;
				level.players[i].pers["assists"] = 0;
				level.players[i].pers["score"] = 0;
				waittillframeend;
			}
			game["roundsplayed"]--;
			[[level._setTeamScore]]( "allies", 0 );
			[[level._setTeamScore]]( "axis", 0 );

			game["PROMOD_KNIFEROUND"] = 0;
			for(i=0;i<level.players.size;i++)
			{
				if(level.players[i].pers["team"] == "axis" || level.players[i].pers["team"] == "allies")
					level.players[i] setclientdvar("g_compassShowEnemies", 0);
				waittillframeend;
			}
		}

		if ( !hitRoundLimit() && !hitScoreLimit() )
		{
			game["state"] = "playing";
			map_restart( true );
			return;
		}

		if ( hitRoundLimit() )
			endReasonText = game["strings"]["round_limit_reached"];
		else if ( hitScoreLimit() )
			endReasonText = game["strings"]["score_limit_reached"];
		else endReasonText = game["strings"]["time_limit_reached"];
	}

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];

		if ( !isDefined( player.pers["team"] ) || player.pers["team"] == "spectator" )
		{
			player [[level.spawnIntermission]]();
			player closeMenu();
			player closeInGameMenu();
			continue;
		}

		if ( level.teamBased )
		{
			winner = getWinningTeam();
			player thread maps\mp\gametypes\_hud_message::teamOutcomeNotify( winner, false, endReasonText );
		}
		else player thread maps\mp\gametypes\_hud_message::outcomeNotify( winner, endReasonText );
		
		player setStat( 75, 1 );
		player setClientDvars( "cg_drawSpectatorMessages", 0, "g_compassShowEnemies", 0 );
	}

	roundEndWait( level.postRoundTime );

	level.intermission = true;

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];

		player closeMenu();
		player closeInGameMenu();
		player notify ( "reset_outcome" );
		player thread spawnIntermission();
		player setStat( 75, 0 );
	}

	wait 4;

	map_restart( false );
	return;
}

getWinningTeam()
{
	if ( getGameScore( "allies" ) == getGameScore( "axis" ) )
		winner = "tie";
	else if ( getGameScore( "allies" ) > getGameScore( "axis" ) )
		winner = "allies";
	else
		winner = "axis";

	return winner;
}

roundEndWait( defaultDelay )
{
	notifiesDone = false;
	while ( !notifiesDone )
	{
		notifiesDone = true;
		for ( i = 0; i < level.players.size; i++ )
		{
			players = level.players[i];
			if ( !isDefined( players.doingNotify ) || !players.doingNotify )
				continue;

			notifiesDone = false;
		}
		wait 0.5;
	}

	wait defaultDelay;
}

roundEndDOF( time )
{
	self setDepthOfField( 0, 128, 512, 4000, 6, 1.8 );
}

getHighestScoringPlayer()
{
	winner = undefined;
	tie = false;

	for( i = 0; i < level.players.size; i++ )
	{
		players = level.players[i];
		if ( !isDefined( players.score ) || players.score < 1 )
			continue;

		if ( !isDefined( winner ) || players.score > winner.score )
		{
			winner = players;
			tie = false;
		}
		else if ( players.score == winner.score )
			tie = true;
	}

	if ( tie || !isDefined( winner ) )
		return undefined;
	else
		return winner;
}

checkTimeLimit()
{
	if ( isDefined( level.timeLimitOverride ) && level.timeLimitOverride )
		return;

	if ( !isDefined( game["state"] ) || game["state"] != "playing" )
	{
		setGameEndTime( 0 );
		return;
	}

	if ( level.timeLimit <= 0 )
	{
		setGameEndTime( 0 );
		return;
	}

	if ( level.inPrematchPeriod )
	{
		setGameEndTime( 0 );
		return;
	}

	if ( !isdefined( level.startTime ) )
		return;

	timeLeft = getTimeRemaining();

	setGameEndTime( getTime() + int(timeLeft) );

	if ( timeLeft > 0 )
		return;

	[[level.onTimeLimit]]();
}

getTimeRemaining()
{
	return level.timeLimit * 60000 - getTimePassed();
}

checkScoreLimit()
{
	if ( ( !isDefined( game["state"] ) || game["state"] != "playing" ) || level.scoreLimit <= 0 || ( level.teamBased && game["teamScores"]["allies"] < level.scoreLimit && game["teamScores"]["axis"] < level.scoreLimit) || ( !level.teamBased && ( !isPlayer( self ) || self.score < level.scoreLimit ) ) )
		return;

	[[level.onScoreLimit]]();
}

hitRoundLimit()
{
	if( level.roundLimit <= 0 )
		return false;

	return ( game["roundsplayed"] >= level.roundLimit );
}

hitScoreLimit()
{
	if( level.scoreLimit <= 0 )
		return false;

	if ( level.teamBased )
	{
		if( game["teamScores"]["allies"] >= level.scoreLimit || game["teamScores"]["axis"] >= level.scoreLimit )
			return true;
	}
	else
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			if ( isDefined( player.score ) && player.score >= level.scorelimit )
				return true;
		}
	}
	return false;
}

updateGameTypeDvars()
{
	level endon ( "game_ended" );

	while ( isDefined( game["state"] ) && game["state"] == "playing" )
	{
		thread checkTimeLimit();
		thread checkScoreLimit();

		if ( isdefined( level.startTime ) && getTimeRemaining() < 3000 )
		{
			wait 0.1;
			continue;
		}
		wait 1;
	}
}

menuAutoAssign()
{
	teams[0] = "allies";
	teams[1] = "axis";
	assignment = teams[randomInt(2)];

	self closeMenus();

	if ( level.teamBased )
	{
		playerCounts = self maps\mp\gametypes\_teams::CountPlayers();

		if ( playerCounts["allies"] == playerCounts["axis"] )
		{
			if( getTeamScore( "allies" ) == getTeamScore( "axis" ) )
				assignment = teams[randomInt(2)];
			else if ( getTeamScore( "allies" ) < getTeamScore( "axis" ) )
				assignment = "allies";
			else
				assignment = "axis";
		}
		else if( playerCounts["allies"] < playerCounts["axis"] )
			assignment = "allies";
		else
			assignment = "axis";

		if ( assignment == self.pers["team"] && (self.sessionstate == "playing" || self.sessionstate == "dead") )
		{
			self beginClassChoice();
			return;
		}
	}

	if ( assignment != self.pers["team"] && self.sessionstate == "playing" )
	{
		self.switching_teams = true;
		self.joining_team = assignment;
		self.leaving_team = self.pers["team"];
		self suicide();
	}

	oldTeam = self.pers["team"];

	self.pers["class"] = undefined;
	self.class = undefined;
	self.pers["team"] = assignment;
	self.team = assignment;
	self setStat( 65 , 0 );

	if ( level.teamBased )
		self.sessionteam = assignment;
	else self.sessionteam = "none";

	if ( !isDefined( level.rdyup ) || !level.rdyup )
	{
		if ( !isAlive( self ) )
			self.statusicon = "hud_status_dead";
		else self.statusicon = "";
	}

	self notify("joined_team");
	self notify("end_respawn");

	self.freelook = undefined;

	if( self.pers["team"] == "allies" && oldTeam != self.pers["team"] )
	{
		if( game["attackers"] == "allies" && game["defenders"] == "axis" )
			iPrintLN(self.name + " ^7Joined Attack");
		else iPrintLN(self.name + " ^7Joined Defence");
	}
	else if( self.pers["team"] == "axis" && oldTeam != self.pers["team"] )
	{
		if( game["attackers"] == "allies" && game["defenders"] == "axis" )
			iPrintLN(self.name + " ^7Joined Defence");
		else iPrintLN(self.name + " ^7Joined Attack");
	}

	if ( oldTeam != self.pers["team"] && ( oldTeam == "allies" || oldTeam == "axis" ) )
			thread maps\mp\gametypes\_promod::updateClassAvailability( oldTeam );

	self setClientDvars("g_compassShowEnemies", 0, "cg_scoreboardheight", 435 );

	self beginClassChoice();

	self setclientdvar( "g_scriptMainMenu", game[ "menu_class_" + self.pers["team"] ] );
}

closeMenus()
{
	self closeMenu();
	self closeInGameMenu();
}

beginClassChoice()
{
	if ( self.pers["team"] == "axis" || self.pers["team"] == "allies" )
		self openMenu( game[ "menu_changeclass_" + self.pers["team"] ] );
}

menuAllies()
{
	if ( self.pers["team"] == "allies" )
		return;

	self closeMenus();

	if ( !isDefined( self.switching ) )
		self.switching = false;

	if ( self.pers["team"] != "allies" )
	{
		if ( level.inGracePeriod && (!isdefined(self.hasDoneCombat) || !self.hasDoneCombat) )
			self.hasSpawned = false;

		if( self.sessionstate == "playing" && !self.switching )
		{
			self.switching_teams = true;
			self.joining_team = "allies";
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		oldTeam = self.pers["team"];

		if ( self.switching )
		{
			self.pers["team"] = "allies";
			self.team = "allies";
		}
		else
		{
			self.pers["class"] = undefined;
			self.class = undefined;
			self.pers["team"] = "allies";
			self.team = "allies";
			self setStat( 65 , 0 );
		}

		if ( level.teamBased )
			self.sessionteam = "allies";
		else
			self.sessionteam = "none";

		if ( !isDefined( level.rdyup ) || !level.rdyup )
		{
			if ( !isAlive( self ) )
				self.statusicon = "hud_status_dead";
			else self.statusicon = "";
		}

		self setclientdvar("g_scriptMainMenu", game["menu_class_allies"]);

		self notify("joined_team");
		self notify("end_respawn");

		self.freelook = undefined;

		if( game["attackers"] == "allies" && game["defenders"] == "axis" && !self.switching )
			iprintln(self.name + " ^7Joined Attack");
		else if ( !self.switching )
			iprintln(self.name + " ^7Joined Defence");

		if ( oldTeam == "axis" )
			thread maps\mp\gametypes\_promod::updateClassAvailability( oldTeam );

		self setClientDvars("g_compassShowEnemies", 0, "cg_scoreboardheight", 435 );
	}

	if ( !self.switching )
		self beginClassChoice();

	self.switching = false;
}

menuAxis()
{
	if ( self.pers["team"] == "axis" )
		return;

	self closeMenus();

	if ( !isDefined( self.switching ) )
		self.switching = false;

	if ( self.pers["team"] != "axis" )
	{
		if ( level.inGracePeriod && (!isdefined(self.hasDoneCombat) || !self.hasDoneCombat) )
			self.hasSpawned = false;

		if( self.sessionstate == "playing" && !self.switching )
		{
			self.switching_teams = true;
			self.joining_team = "axis";
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		oldTeam = self.pers["team"];

		if ( self.switching )
		{
			self.pers["team"] = "axis";
			self.team = "axis";
		}
		else
		{
			self.pers["class"] = undefined;
			self.class = undefined;
			self.pers["team"] = "axis";
			self.team = "axis";
			self setStat( 65 , 0 );
		}

		if ( level.teamBased )
			self.sessionteam = "axis";
		else self.sessionteam = "none";

		if ( !isDefined( level.rdyup ) || !level.rdyup )
		{
			if ( !isAlive( self ) )
				self.statusicon = "hud_status_dead";
			else self.statusicon = "";
		}

		self setclientdvar("g_scriptMainMenu", game["menu_class_axis"]);

		self notify("joined_team");
		self notify("end_respawn");

		self.freelook = undefined;

		if( game["attackers"] == "allies" && game["defenders"] == "axis" && !self.switching )
			iprintln(self.name + " ^7Joined Defence");
		else if ( !self.switching )
			iprintln(self.name + " ^7Joined Attack");

		if ( oldTeam == "allies" )
			thread maps\mp\gametypes\_promod::updateClassAvailability( oldTeam );

		self setClientDvars("g_compassShowEnemies", 0, "cg_scoreboardheight", 435 );
	}

	if ( !self.switching )
		self beginClassChoice();

	self.switching = false;
}

menuKillspec()
{
	if ( self.pers["team"] != "axis" && self.pers["team"] != "allies" )
		return;

	self closeMenus();

	if( self.sessionstate == "playing" )
		self suicide();

	self.pers["class"] = undefined;
	self.class = undefined;
	self iprintln("Choose a class to respawn");
	self setStat( 65 , 0 );
	self thread [[level.spawnSpectator]]( self.origin, self.angles );

	thread maps\mp\gametypes\_promod::updateClassAvailability( self.pers["team"] );
}

menuSpectator()
{
	if ( self.pers["team"] == "spectator" )
		return;

	self closeMenus();
	self openMenu(game["menu_shoutcast"]);

	if(self.pers["team"] != "spectator")
	{
		if(self.sessionstate == "playing")
		{
			self.switching_teams = true;
			self.joining_team = "spectator";
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		oldTeam = self.pers["team"];

		self.pers["class"] = undefined;
		self.class = undefined;
		self.pers["team"] = "spectator";
		self.team = "spectator";
		self setStat( 65 , 0 );

		self.sessionteam = "spectator";
		self thread [[level.spawnSpectator]]( self.origin, self.angles );

		self setclientdvar( "g_scriptMainMenu", game["menu_shoutcast"] );

		self notify("joined_spectators");
		iprintln(self.name + " ^7Joined Shoutcaster");

		if ( oldTeam == "allies" || oldTeam == "axis" )
			thread maps\mp\gametypes\_promod::updateClassAvailability( oldTeam );

		self setClientDvars("g_compassShowEnemies", 1, "cg_scoreboardheight", 500 );
	}
}

removeDisconnectedPlayerFromPlacement()
{
	offset = 0;
	numPlayers = level.placement["all"].size;
	found = false;
	for ( i = 0; i < numPlayers; i++ )
	{
		if ( level.placement["all"][i] == self )
			found = true;

		if ( found )
			level.placement["all"][i] = level.placement["all"][ i + 1 ];
	}
	if ( !found )
		return;

	level.placement["all"][ numPlayers - 1 ] = undefined;

	updateTeamPlacement();

	if ( level.teamBased )
		return;

	numPlayers = level.placement["all"].size;
	for ( i = 0; i < numPlayers; i++ )
	{
		player = level.placement["all"][i];
		player notify( "update_outcome" );
	}
}

updatePlacement()
{
	prof_begin("updatePlacement");

	if ( !level.players.size )
		return;

	level.placement["all"] = [];
	for ( i = 0; i < level.players.size; i++ )
	{
		if ( level.players[i].team == "allies" || level.players[i].team == "axis" )
			level.placement["all"][level.placement["all"].size] = level.players[i];
	}

	placementAll = level.placement["all"];

	for ( i = 1; i < placementAll.size; i++ )
	{
		player = placementAll[i];
		playerScore = player.score;
		for ( j = i - 1; j >= 0 && (playerScore > placementAll[j].score || (playerScore == placementAll[j].score && player.deaths < placementAll[j].deaths)); j-- )
			placementAll[j + 1] = placementAll[j];
		placementAll[j + 1] = player;
	}

	level.placement["all"] = placementAll;

	updateTeamPlacement();

	prof_end("updatePlacement");
}

updateTeamPlacement()
{
	placement["allies"]	= [];
	placement["axis"] = [];
	placement["spectator"] = [];

	if ( !level.teamBased )
		return;

	placementAll = level.placement["all"];
	placementAllSize = placementAll.size;

	for ( i = 0; i < placementAllSize; i++ )
	{
		player = placementAll[i];
		team = player.pers["team"];

		placement[team][ placement[team].size ] = player;
	}

	level.placement["allies"] = placement["allies"];
	level.placement["axis"] = placement["axis"];
}

onXPEvent( event )
{
	self maps\mp\gametypes\_rank::giveRankXP( event );
}

givePlayerScore( event, player, victim )
{
	if ( level.overridePlayerScore )
		return;

	score = player.pers["score"];
	[[level.onPlayerScore]]( event, player, victim );

	if ( score == player.pers["score"] )
		return;

	player.score = player.pers["score"];

	if ( !level.teambased )
		thread sendUpdatedDMScores();

	player notify ( "update_playerscore_hud" );
	player thread checkScoreLimit();
}

default_onPlayerScore( event, player, victim )
{
	score = level.scoreInfo[event];
	player.pers["score"] += score;
}

_setPlayerScore( player, score )
{
	if ( score == player.pers["score"] )
		return;

	player.pers["score"] = score;
	player.score = player.pers["score"];

	player notify ( "update_playerscore_hud" );
	player thread checkScoreLimit();
}

_getPlayerScore( player )
{
	return player.pers["score"];
}

giveTeamScore( event, team, player, victim )
{
	if ( level.overrideTeamScore )
		return;

	teamScore = game["teamScores"][team];
	[[level.onTeamScore]]( event, team, player, victim );

	if ( teamScore == game["teamScores"][team] )
		return;

	updateTeamScores( team );

	thread checkScoreLimit();
}

_setTeamScore( team, teamScore )
{
	if ( teamScore == game["teamScores"][team] )
		return;

	game["teamScores"][team] = teamScore;

	updateTeamScores( team );

	thread checkScoreLimit();
}

updateTeamScores( team1, team2 )
{
	setTeamScore( team1, getGameScore( team1 ) );
	if ( isdefined( team2 ) )
		setTeamScore( team2, getGameScore( team2 ) );

	if ( level.teambased )
		thread sendUpdatedTeamScores();
}

_getTeamScore( team )
{
	return game["teamScores"][team];
}

default_onTeamScore( event, team, player, victim )
{
	score = level.scoreInfo[event];

	otherTeam = level.otherTeam[team];

	if ( game["teamScores"][team] > game["teamScores"][otherTeam] )
		level.wasWinning = team;
	else if ( game["teamScores"][otherTeam] > game["teamScores"][team] )
		level.wasWinning = otherTeam;

	game["teamScores"][team] += score;

	isWinning = "none";
	if ( game["teamScores"][team] > game["teamScores"][otherTeam] )
		isWinning = team;
	else if ( game["teamScores"][otherTeam] > game["teamScores"][team] )
		isWinning = otherTeam;

	if ( isWinning != "none" && isWinning != level.wasWinning && getTime() - level.lastStatusTime > 5000 )
		level.lastStatusTime = getTime();

	if ( isWinning != "none" )
		level.wasWinning = isWinning;
}

sendUpdatedTeamScores()
{
	level notify("updating_scores");
	level endon("updating_scores");
	wait 0.05;

	WaitTillSlowProcessAllowed();

	for ( i = 0; i < level.players.size; i++ )
		level.players[i] updateScores();
}

sendUpdatedDMScores()
{
	level notify("updating_dm_scores");
	level endon("updating_dm_scores");
	wait 0.05;

	WaitTillSlowProcessAllowed();

	for ( i = 0; i < level.players.size; i++ )
	{
		level.players[i] updateDMScores();
		level.players[i].updatedDMScores = true;
	}
}

updateTeamStatus()
{
	level notify("updating_team_status");
	level endon("updating_team_status");
	level endon ( "game_ended" );

	if ( isDefined( game["state"] ) && game["state"] == "postgame" )
		return;

	resetTimeout();

	prof_begin( "updateTeamStatus" );

	level.playerCount["allies"] = 0;
	level.playerCount["axis"] = 0;

	level.lastAliveCount["allies"] = level.aliveCount["allies"];
	level.lastAliveCount["axis"] = level.aliveCount["axis"];
	level.aliveCount["allies"] = 0;
	level.aliveCount["axis"] = 0;
	level.playerLives["allies"] = 0;
	level.playerLives["axis"] = 0;
	level.alivePlayers["allies"] = [];
	level.alivePlayers["axis"] = [];
	level.activePlayers = [];

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];

		team = player.team;
		class = player.class;

		if ( team != "spectator" && (isDefined( class ) && class != "") )
		{
			level.playerCount[team]++;

			if ( player.sessionstate == "playing" )
			{
				level.aliveCount[team]++;
				level.playerLives[team]++;

				if ( isAlive( player ) )
				{
					level.alivePlayers[team][level.alivePlayers.size] = player;
					level.activeplayers[ level.activeplayers.size ] = player;
				}
			}
			else if ( player maySpawn() )
				level.playerLives[team]++;
		}
	}

	if ( level.aliveCount["allies"] + level.aliveCount["axis"] > level.maxPlayerCount )
		level.maxPlayerCount = level.aliveCount["allies"] + level.aliveCount["axis"];

	if ( level.aliveCount["allies"] )
		level.everExisted["allies"] = true;
	if ( level.aliveCount["axis"] )
		level.everExisted["axis"] = true;

	for( i = 0; i < level.players.size; i++ )
		if( level.players[i].pers["team"] == "allies" || level.players[i].pers["team"] == "axis" )
			level.players[i] setClientDvars("self_alive", level.aliveCount[level.players[i].pers["team"]],
											"opposing_alive", level.aliveCount[maps\mp\gametypes\_gameobjects::getEnemyTeam(level.players[i].pers["team"])] );

	prof_end( "updateTeamStatus" );

	level updateGameEvents();
}

isValidClass( class )
{
	return isdefined( class ) && class != "";
}

playTickingSound()
{
	self endon("death");
	self endon("stop_ticking");

	level endon("game_ended");

	for(;;)
	{
		self playSound( "ui_mp_suitcasebomb_timer" );
		wait 1;
	}
}

stopTickingSound()
{
	self notify("stop_ticking");
}

timeLimitClock()
{
	level endon ( "game_ended" );

	wait 0.05;

	clockObject = spawn( "script_origin", (0,0,0) );

	while ( isDefined( game["state"] ) && game["state"] == "playing" )
	{
		if ( !level.timerStopped && level.timeLimit )
		{
			timeLeft = getTimeRemaining() / 1000;
			timeLeftInt = int(timeLeft + 0.5);

			if ( timeLeftInt <= 10 || (timeLeftInt <= 30 && timeLeftInt % 2 == 0) )
			{
				if ( !timeLeftInt )
					break;

				clockObject playSound( "ui_mp_timer_countdown" );
			}

			if ( timeLeft - floor(timeLeft) >= 0.05 )
				wait timeLeft - floor(timeLeft);
		}

		wait 1;
	}
}

gameTimer()
{
	level endon ( "game_ended" );

	level waittill("prematch_over");

	level.startTime = getTime();
	level.discardTime = 0;

	if ( isDefined( game["roundMillisecondsAlreadyPassed"] ) )
	{
		level.startTime -= game["roundMillisecondsAlreadyPassed"];
		game["roundMillisecondsAlreadyPassed"] = undefined;
	}

	prevtime = gettime();

	while ( isDefined( game["state"] ) && game["state"] == "playing" )
	{
		if ( !level.timerStopped )
			game["timepassed"] += gettime() - prevtime;

		prevtime = gettime();
		wait 1;
	}
}

getTimePassed()
{
	if ( !isDefined( level.startTime ) )
		return 0;

	if ( level.timerStopped )
		return (level.timerPauseTime - level.startTime) - level.discardTime;
	else
		return (gettime() - level.startTime) - level.discardTime;
}

pauseTimer()
{
	if ( level.timerStopped )
		return;

	level.timerStopped = true;
	level.timerPauseTime = gettime();
}

resumeTimer()
{
	if ( !level.timerStopped )
		return;

	level.timerStopped = false;
	level.discardTime += gettime() - level.timerPauseTime;
}

openMainMenu()
{
	maxwait = 0;
	while ( !level.players.size && maxwait <= 1 )
	{
		wait 0.05;
		maxwait += 0.05;
	}

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( !isDefined( player.pers["team"] ) || player.pers["team"] == "none" )
		{
			player setclientdvar( "g_scriptMainMenu", game["menu_team"] );
			player openMenu( game["menu_team"] );
		}
	}
}

checkRestartMap()
{
	if ( getDvar( "o_gametype" ) == "" )
		setDvar( "o_gametype", level.gametype );
	else if ( getDvar( "o_gametype" ) != level.gametype )
	{
		level.restarting = true;

		setDvar( "o_gametype", level.gametype );

		maprot = getDvar( "sv_maprotationcurrent" );
		new_maprot = "map " + level.script + " " + maprot;
		setDvar( "sv_maprotationcurrent", new_maprot );
		exitLevel( false );
	}
}

startGame()
{
	level thread header();

	thread gameTimer();
	level.timerStopped = true;
	thread maps\mp\gametypes\_spawnlogic::spawnPerFrameUpdate();

	prematchPeriod();

	thread openMainMenu();

	if ( isDefined( game["promod_timeout_called"] ) && game["promod_timeout_called"] )
	{
		thread promod\timeout::main();
		return;
	}

	if ( isDefined( game["promod_do_readyup"] ) && game["promod_do_readyup"] )
	{
		thread disableBombsites();
		thread promod\readyup::main();
		return;
	}

	promod\strattime::main();

	setDvar( "g_deadChat", 0 );

	if ( isDefined( level.timeout_over ) && !level.timeout_over )
		return;

	if ( isDefined(game["PROMOD_KNIFEROUND"]) && game["PROMOD_KNIFEROUND"] )
	{
		thread disableBombsites();

		if(game["PROMOD_MATCH_MODE"] != "pub")
		{
			level.timeLimitOverride = true;
			setGameEndTime( 0 );
		}
	}

	level notify("prematch_over");
	level notify("header_destroy");
	level.timerStopped = false;

	game["promod_in_timeout"] = 0;

	if ( !isDefined( game["PROMOD_KNIFEROUND"] ) || !game["PROMOD_KNIFEROUND"] || game["PROMOD_MATCH_MODE"] == "pub" )
		thread timeLimitClock();

	thread gracePeriod();
}

header()
{
	if ( isDefined( game["state"] ) && game["state"] == "postgame" )
		wait 0.75;

	promod_ver = newHudElem();
	promod_ver.x = -7;
	promod_ver.y = 35;
	promod_ver.horzAlign = "right";
	promod_ver.vertAlign = "top";
	promod_ver.alignX = "right";
	promod_ver.alignY = "middle";
	promod_ver.fontScale = 1.4;
	promod_ver.hidewheninmenu = true;
	promod_ver.color = (0.8, 1, 1);
	promod_ver setText( game["PROMOD_VERSION"] );

	promod_mode = newHudElem();
	promod_mode.x = -7;
	promod_mode.y = 50;
	promod_mode.horzAlign = "right";
	promod_mode.vertAlign = "top";
	promod_mode.alignX = "right";
	promod_mode.alignY = "middle";
	promod_mode.fontScale = 1.4;
	promod_mode.hidewheninmenu = true;
	promod_mode.color = (1,1,0);
	promod_mode setText( game["PROMOD_MODE_HUD"] );

	level waittill( "header_destroy" );

	if ( isDefined( promod_ver ) )
		promod_ver destroy();

	if ( isDefined( promod_mode ) )
		promod_mode destroy();
}

disableBombsites()
{
	if ( level.gametype == "sd" && isDefined( level.bombZones ) )
		for ( j = 0; j < level.bombZones.size; j++ )
			level.bombZones[j] maps\mp\gametypes\_gameobjects::disableObject();
}

prematchPeriod()
{
	level endon( "game_ended" );

	matchStartTimerSkip();

	level.inPrematchPeriod = false;

	for ( i = 0; i < level.players.size; i++ )
	{
		level.players[i] freezeControls( false );
		level.players[i] enableWeapons();
	}
}

gracePeriod()
{
	level endon("game_ended");

	wait level.gracePeriod;

	level notify ( "grace_period_ending" );
	wait 0.05;

	level.inGracePeriod = false;

	if ( !isDefined( game["state"] ) || game["state"] != "playing" )
		return;

	if ( level.numLives )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];

			if ( !player.hasSpawned && player.sessionteam != "spectator" && !isAlive( player ) )
				player.statusicon = "hud_status_dead";
		}
	}

	level thread updateTeamStatus();
}

TimeUntilWaveSpawn( minimumWait )
{
	earliestSpawnTime = gettime() + minimumWait * 1000;

	lastWaveTime = level.lastWave[self.pers["team"]];
	waveDelay = level.waveDelay[self.pers["team"]] * 1000;

	numWavesPassedEarliestSpawnTime = (earliestSpawnTime - lastWaveTime) / waveDelay;

	numWaves = ceil( numWavesPassedEarliestSpawnTime );

	timeOfSpawn = lastWaveTime + numWaves * waveDelay;

	if ( isdefined( self.waveSpawnIndex ) )
		timeOfSpawn += 50 * self.waveSpawnIndex;

	return (timeOfSpawn - gettime()) / 1000;
}

TimeUntilSpawn()
{
	if ( ( level.inGracePeriod && !self.hasSpawned ) || ( isDefined( level.rdyup ) && level.rdyup )  )
		return 0;

	respawnDelay = 0;
	if ( self.hasSpawned )
	{
		result = self [[level.onRespawnDelay]]();
		if ( isDefined( result ) )
			respawnDelay = result;
		else
			respawnDelay = getDvarInt( "scr_" + level.gameType + "_playerrespawndelay" );
	}

	waveBased = (getDvarInt( "scr_" + level.gameType + "_waverespawndelay" ) > 0);

	if ( waveBased )
		return self TimeUntilWaveSpawn( respawnDelay );

	return respawnDelay;
}

maySpawn()
{
	if ( ( isDefined( level.rdyup ) && level.rdyup ) )
		return true;

	if ( level.inOvertime )
		return false;

	if ( level.numLives )
	{
		if ( level.teamBased )
			gameHasStarted = ( level.everExisted[ "axis" ] && level.everExisted[ "allies" ] );
		else
			gameHasStarted = (level.maxPlayerCount > 1);

		if ( gameHasStarted && ( !self.pers["lives"] || ( !level.inGracePeriod && !self.hasSpawned ) ) )
			return false;
	}
	return true;
}

spawnClient( timeAlreadyPassed )
{
	if ( !self maySpawn() )
	{
		shouldShowRespawnMessage = true;
		if ( ( level.roundLimit > 1 && game["roundsplayed"] >= (level.roundLimit - 1) ) || ( level.scoreLimit > 1 && level.teambased && game["teamScores"]["allies"] >= level.scoreLimit - 1 && game["teamScores"]["axis"] >= level.scoreLimit - 1 ) )
			shouldShowRespawnMessage = false;

		if ( shouldShowRespawnMessage )
		{
			setLowerMessage( game["strings"]["spawn_next_round"] );
			self thread removeSpawnMessageShortly();
		}
		self thread [[level.spawnSpectator]]( self.origin, self.angles );
		return;
	}

	if ( self.waitingToSpawn )
		return;

	self.waitingToSpawn = true;

	self waitAndSpawnClient( timeAlreadyPassed );

	if ( isdefined( self ) )
		self.waitingToSpawn = false;
}

waitAndSpawnClient( timeAlreadyPassed )
{
	self endon ( "disconnect" );
	self endon ( "end_respawn" );
	self endon ( "game_ended" );

	if ( !isdefined( timeAlreadyPassed ) )
		timeAlreadyPassed = 0;

	spawnedAsSpectator = false;

	if ( !isdefined( self.waveSpawnIndex ) && isdefined( level.wavePlayerSpawnIndex[self.team] ) )
	{
		self.waveSpawnIndex = level.wavePlayerSpawnIndex[self.team];
		level.wavePlayerSpawnIndex[self.team]++;
	}

	timeUntilSpawn = TimeUntilSpawn();
	if ( timeUntilSpawn > timeAlreadyPassed )
	{
		timeUntilSpawn -= timeAlreadyPassed;
		timeAlreadyPassed = 0;
	}
	else
	{
		timeAlreadyPassed -= timeUntilSpawn;
		timeUntilSpawn = 0;
	}

	if ( timeUntilSpawn > 0 )
	{
		setLowerMessage( game["strings"]["waiting_to_spawn"], timeUntilSpawn );

		if ( !spawnedAsSpectator )
			self thread respawn_asSpectator( self.origin + (0, 0, 60), self.angles );
		spawnedAsSpectator = true;

		self waitForTimeOrNotify( timeUntilSpawn, "force_spawn" );
	}

	waveBased = (getDvarInt( "scr_" + level.gameType + "_waverespawndelay" ) > 0);
	if ( !maps\mp\gametypes\_tweakables::getTweakableValue( "player", "forcerespawn" ) && self.hasSpawned && !waveBased )
	{
		setLowerMessage( game["strings"]["press_to_spawn"] );

		if ( !spawnedAsSpectator )
			self thread respawn_asSpectator( self.origin + (0, 0, 60), self.angles );
		spawnedAsSpectator = true;

		self waitRespawnButton();
	}

	self.waitingToSpawn = false;

	self clearLowerMessage();

	self.waveSpawnIndex = undefined;

	self thread [[level.spawnPlayer]]();
}

waitForTimeOrNotify( time, notifyname )
{
	self endon("disconnect");
	self endon( notifyname );
	wait time;
}

removeSpawnMessageShortly()
{
	self endon("disconnect");

	waittillframeend;

	self endon("end_respawn");

	wait 2;

	self clearLowerMessage( 2 );
}

Callback_StartGameType()
{
	level.prematchPeriod = 0;

	level.intermission = false;
	game["state"] = "playing";

	if ( !isDefined( game["gamestarted"] ) )
	{
		if ( !isDefined( game["allies"] ) )
			game["allies"] = "marines";
		if ( !isDefined( game["axis"] ) )
			game["axis"] = "opfor";
		if ( !isDefined( game["attackers"] ) )
			game["attackers"] = "allies";
		if ( !isDefined( game["defenders"] ) )
			game["defenders"] = "axis";

		if ( !isDefined( game["state"] ) )
			game["state"] = "playing";

		precacheStatusIcon("hud_status_dead");
		precacheStatusIcon("hud_status_connecting");
		precacheStatusIcon("compassping_friendlyfiring_mp");
		precacheStatusIcon("compassping_enemy");

		precacheRumble( "damage_heavy" );

		precacheShader( "white" );
		precacheShader( "black" );

		game["strings"]["press_to_spawn"] = &"PLATFORM_PRESS_TO_SPAWN";
		if ( level.teamBased )
		{
			game["strings"]["waiting_for_teams"] = &"MP_WAITING_FOR_TEAMS";
			game["strings"]["opponent_forfeiting_in"] = &"MP_OPPONENT_FORFEITING_IN";
		}
		else
		{
			game["strings"]["waiting_for_teams"] = &"MP_WAITING_FOR_PLAYERS";
			game["strings"]["opponent_forfeiting_in"] = &"MP_OPPONENT_FORFEITING_IN";
		}

		game["strings"]["match_starting_in"] = &"MP_MATCH_STARTING_IN";
		game["strings"]["spawn_next_round"] = &"MP_SPAWN_NEXT_ROUND";
		game["strings"]["waiting_to_spawn"] = &"MP_WAITING_TO_SPAWN";
		game["strings"]["match_starting"] = &"MP_MATCH_STARTING";
		game["strings"]["change_class"] = &"MP_CHANGE_CLASS_NEXT_SPAWN";

		game["strings"]["tie"] = &"MP_MATCH_TIE";
		game["strings"]["round_draw"] = &"MP_ROUND_DRAW";

		game["strings"]["enemies_eliminated"] = &"MP_ENEMIES_ELIMINATED";
		game["strings"]["score_limit_reached"] = &"MP_SCORE_LIMIT_REACHED";
		game["strings"]["round_limit_reached"] = &"MP_ROUND_LIMIT_REACHED";
		game["strings"]["time_limit_reached"] = &"MP_TIME_LIMIT_REACHED";
		game["strings"]["players_forfeited"] = &"MP_PLAYERS_FORFEITED";

		if( game["attackers"] == "allies" && game["defenders"] == "axis" )
		{
			game["strings"]["allies_name"] = "Attack";
			game["strings"]["axis_name"] = "Defence";
			game["strings"]["allies_eliminated"] = "Attack eliminated";
			game["strings"]["axis_eliminated"] = "Defence eliminated";
			game["strings"]["allies_forfeited"] = "Attack forfeited";
			game["strings"]["axis_forfeited"] = "Defence forfeited";
		}
		else
		{
			game["strings"]["allies_name"] = "Defence";
			game["strings"]["axis_name"] = "Attack";
			game["strings"]["allies_eliminated"] = "Defence eliminated";
			game["strings"]["axis_eliminated"] = "Attack eliminated";
			game["strings"]["allies_forfeited"] = "Defence forfeited";
			game["strings"]["axis_forfeited"] = "Attack forfeited";
		}

		switch ( game["allies"] )
		{
			case "sas":
				game["strings"]["allies_win"] = &"MP_SAS_WIN_MATCH";
				game["strings"]["allies_win_round"] = &"MP_SAS_WIN_ROUND";
				game["strings"]["allies_mission_accomplished"] = &"MP_SAS_MISSION_ACCOMPLISHED";

				game["icons"]["allies"] = "faction_128_sas";
				game["colors"]["allies"] = (0.6,0.64,0.69);
				game["voice"]["allies"] = "UK_1mc_";
				setDvar( "scr_allies", "sas" );
				break;

			default:
				game["strings"]["allies_win"] = &"MP_MARINES_WIN_MATCH";
				game["strings"]["allies_win_round"] = &"MP_MARINES_WIN_ROUND";
				game["strings"]["allies_mission_accomplished"] = &"MP_MARINES_MISSION_ACCOMPLISHED";

				game["icons"]["allies"] = "faction_128_usmc";
				game["colors"]["allies"] = (0.6,0.64,0.69);
				game["voice"]["allies"] = "US_1mc_";
				setDvar( "scr_allies", "usmc" );
				break;
		}
		switch ( game["axis"] )
		{
			case "russian":
				game["strings"]["axis_win"] = &"MP_SPETSNAZ_WIN_MATCH";
				game["strings"]["axis_win_round"] = &"MP_SPETSNAZ_WIN_ROUND";
				game["strings"]["axis_mission_accomplished"] = &"MP_SPETSNAZ_MISSION_ACCOMPLISHED";

				game["icons"]["axis"] = "faction_128_ussr";
				game["colors"]["axis"] = (0.52,0.28,0.28);
				game["voice"]["axis"] = "RU_1mc_";
				setDvar( "scr_axis", "ussr" );
				break;

			default:
				game["strings"]["axis_win"] = &"MP_OPFOR_WIN_MATCH";
				game["strings"]["axis_win_round"] = &"MP_OPFOR_WIN_ROUND";
				game["strings"]["axis_mission_accomplished"] = &"MP_OPFOR_MISSION_ACCOMPLISHED";

				game["icons"]["axis"] = "faction_128_arab";
				game["colors"]["axis"] = (0.65,0.57,0.41);
				game["voice"]["axis"] = "AB_1mc_";
				setDvar( "scr_axis", "arab" );
				break;
		}

		[[level.onPrecacheGameType]]();

		game["gamestarted"] = true;

		game["teamScores"]["allies"] = game["SCORES_ATTACK"];
		game["teamScores"]["axis"] = game["SCORES_DEFENCE"];

		level.prematchPeriod = maps\mp\gametypes\_tweakables::getTweakableValue( "game", "matchstarttime" );

		thread setvariables();
	}

	if ( !isdefined( game["timepassed"] ) )
		game["timepassed"] = 0;

	if ( !isdefined( game["roundsplayed"] ) )
		game["roundsplayed"] = game["SCORES_ATTACK"] + game["SCORES_DEFENCE"];

	if ( !isDefined( game["promod_do_readyup"] ) )
		game["promod_do_readyup"] = false;

	if ( (isDefined( game["PROMOD_MATCH_MODE"] ) && game["PROMOD_MATCH_MODE"] == "match" || isDefined( game["CUSTOM_MODE"] ) && game["CUSTOM_MODE"]) && ( !game["roundsplayed"] && !game["promod_first_readyup_done"] || ( game["SCORES_ATTACK"] > 0 || game["SCORES_DEFENCE"] > 0 ) ) )
		game["promod_do_readyup"] = true;

	game["SCORES_ATTACK"] = 0;
	game["SCORES_DEFENCE"] = 0;

	level.gameEnded = false;
	level.teamSpawnPoints["axis"] = [];
	level.teamSpawnPoints["allies"] = [];

	level.objIDStart = 0;
	level.forcedEnd = false;

	level.useStartSpawns = true;

	thread maps\mp\gametypes\_eventmanager::init();
	thread maps\mp\gametypes\_rank::init();
	thread maps\mp\gametypes\_menus::init();
	thread maps\mp\gametypes\_hud::init();
	thread maps\mp\gametypes\_serversettings::init();
	thread maps\mp\gametypes\_clientids::init();
	thread maps\mp\gametypes\_teams::setPlayerModels();
	thread maps\mp\gametypes\_weapons::init();
	thread maps\mp\gametypes\_scoreboard::init();
	thread maps\mp\gametypes\_shellshock::init();
	thread maps\mp\gametypes\_damagefeedback::init();
	thread maps\mp\gametypes\_healthoverlay::init();
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_objpoints::init();
	thread maps\mp\gametypes\_gameobjects::init();
	thread maps\mp\gametypes\_spawnlogic::init();
	thread maps\mp\gametypes\_hud_message::init();
	thread maps\mp\gametypes\_quickmessages::init();

	stringNames = getArrayKeys( game["strings"] );
	for ( i = 0; i < stringNames.size; i++ )
		if(!isstring(game["strings"][stringNames[i]]))
			precacheString( game["strings"][stringNames[i]] );

	level.maxPlayerCount = 0;
	level.playerCount["allies"] = 0;
	level.playerCount["axis"] = 0;
	level.aliveCount["allies"] = 0;
	level.aliveCount["axis"] = 0;
	level.playerLives["allies"] = 0;
	level.playerLives["axis"] = 0;
	level.lastAliveCount["allies"] = 0;
	level.lastAliveCount["axis"] = 0;
	level.everExisted["allies"] = false;
	level.everExisted["axis"] = false;
	level.waveDelay["allies"] = 0;
	level.waveDelay["axis"] = 0;
	level.lastWave["allies"] = 0;
	level.lastWave["axis"] = 0;
	level.wavePlayerSpawnIndex["allies"] = 0;
	level.wavePlayerSpawnIndex["axis"] = 0;
	level.alivePlayers["allies"] = [];
	level.alivePlayers["axis"] = [];
	level.activePlayers = [];

	makeDvarServerInfo( "ui_scorelimit" );
	makeDvarServerInfo( "ui_timelimit" );

	waveDelay = getDvarInt( "scr_" + level.gameType + "_waverespawndelay" );
	if ( waveDelay )
	{
		level.waveDelay["allies"] = waveDelay;
		level.waveDelay["axis"] = waveDelay;
		level.lastWave["allies"] = 0;
		level.lastWave["axis"] = 0;

		level thread [[level.waveSpawnTimer]]();
	}

	level.inPrematchPeriod = true;

	level.gracePeriod = 4;

	level.inGracePeriod = true;

	level.roundEndDelay = 4;
	level.halftimeRoundEndDelay = 3;

	updateTeamScores( "axis", "allies" );

	if ( !level.teamBased )
		thread initialDMScoreUpdate();

	[[level.onStartGameType]]();

	deletePlacedEntity("misc_turret");

	thread deletePickups();

	thread startGame();

	level thread updateGameTypeDvars();
}

setvariables()
{
	setDvar( "bg_bobMax", 0 );
	setDvar( "player_sustainAmmo", 0 );
	setDvar( "player_throwBackInnerRadius", 0 );
	setDvar( "player_throwBackOuterRadius", 0 );
	setDvar( "loc_warnings", 0 );

	setDvar( "scr_game_deathpointloss", 0 );
	setDvar( "scr_game_suicidepointloss", 0 );
	setDvar( "scr_player_suicidespawndelay", 0 );
	setDvar( "scr_player_forcerespawn", 1 );

	setDvar( "bg_fallDamageMinHeight", 140 );
	setDvar( "bg_fallDamageMaxHeight", 350 );

	setDvar( "logfile", 0 );
	setDvar( "g_log", "games_mp.log" );
	setDvar( "g_logSync", 0 );

	setDvar( "g_inactivity", 0 );
	setDvar( "g_no_script_spam", 1 );
	setDvar( "g_antilag", 1 );
	setDvar( "g_smoothClients", 1 );
	setDvar( "sv_allowDownload", 1 );
	setDvar( "sv_maxPing", 0 );
	setDvar( "sv_minPing", 0 );
	setDvar( "sv_reconnectlimit", 3 );
	setDvar( "sv_timeout", 240 );
	setDvar( "sv_zombietime", 2 );
	setDvar( "sv_floodprotect", 4 );
	setDvar( "sv_kickBanTime", 0 );
	setDvar( "sv_disableClientConsole", 0 );
	setDvar( "sv_voice", 0 );
	setDvar( "sv_clientarchive", 1 );
	setDvar( "timescale", 1 );

	setDvar( "g_allowVote", 0 );

	game["allies_assault_count"] = 0;
	game["allies_specops_count"] = 0;
	game["allies_demolitions_count"] = 0;
	game["allies_sniper_count"] = 0;

	game["axis_assault_count"] = 0;
	game["axis_specops_count"] = 0;
	game["axis_demolitions_count"] = 0;
	game["axis_sniper_count"] = 0;

	game["promod_timeout_called"] = false;
	game["promod_in_timeout"] = 0;
	game["allies_timeout_called"] = 0;
	game["axis_timeout_called"] = 0;

	game["promod_first_readyup_done"] = 0;
	game["PROMOD_VERSION"] = "Promod ^1LIVE ^7V2.20 EU";

	setDvar( "class_assault_primary", "ak47" );
	setDvar( "class_assault_primary_attachment", "none" );
	setDvar( "class_assault_secondary", "deserteagle" );
	setDvar( "class_assault_secondary_attachment", "none" );
	setDvar( "class_assault_grenade", "smoke_grenade" );

	setDvar( "class_specops_primary", "ak74u" );
	setDvar( "class_specops_primary_attachment", "none" );
	setDvar( "class_specops_secondary", "deserteagle" );
	setDvar( "class_specops_secondary_attachment", "none" );
	setDvar( "class_specops_grenade", "smoke_grenade" );

	setDvar( "class_demolitions_primary", "winchester1200" );
	setDvar( "class_demolitions_primary_attachment", "none" );
	setDvar( "class_demolitions_secondary", "deserteagle" );
	setDvar( "class_demolitions_secondary_attachment", "none" );
	setDvar( "class_demolitions_grenade", "smoke_grenade" );

	setDvar( "class_sniper_primary", "m40a3" );
	setDvar( "class_sniper_primary_attachment", "none" );
	setDvar( "class_sniper_secondary", "deserteagle" );
	setDvar( "class_sniper_secondary_attachment", "none" );
	setDvar( "class_sniper_grenade", "smoke_grenade" );

	setServerDvarDefault( "allies_allow_assault", 1 );
	setServerDvarDefault( "allies_allow_specops", 1 );
	setServerDvarDefault( "allies_allow_demolitions", 1 );
	setServerDvarDefault( "allies_allow_sniper", 1 );
	setServerDvarDefault( "axis_allow_assault", 1 );
	setServerDvarDefault( "axis_allow_specops", 1 );
	setServerDvarDefault( "axis_allow_demolitions", 1 );
	setServerDvarDefault( "axis_allow_sniper", 1 );
}

setServerDvarDefault( dvarName, setVal )
{
	setDvar( dvarName, setVal );
	makeDvarServerInfo( dvarName );
}

deletePickups()
{
	pickups = getentarray( "oldschool_pickup", "targetname" );

	for ( i = 0; i < pickups.size; i++ )
	{
		if ( isdefined( pickups[i].target ) )
			getent( pickups[i].target, "targetname" ) delete();
		pickups[i] delete();
	}
}

initialDMScoreUpdate()
{
	wait 0.2;
	numSent = 0;
	for(;;)
	{
		didAny = false;

		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];

			if ( !isdefined( player ) )
				continue;

			if ( isdefined( player.updatedDMScores ) )
				continue;

			player.updatedDMScores = true;
			player updateDMScores();

			didAny = true;
			wait 0.5;
		}

		if ( !didAny )
			wait 3;
	}
}

checkRoundSwitch()
{
	if ( !level.roundSwitch || level.gametype == "dm" )
		return false;

	if ( game["roundsplayed"] % level.roundswitch == 0 )
	{
		if ( ( isDefined( game["PROMOD_MATCH_MODE"] ) && game["PROMOD_MATCH_MODE"] == "match" || isDefined( game["CUSTOM_MODE"] ) && game["CUSTOM_MODE"] ) && game["promod_first_readyup_done"] )
			game["promod_do_readyup"] = true;

		game["promod_timeout_called"] = false;

		[[level.onRoundSwitch]]();
		return true;
	}

	return false;
}

getGameScore( team )
{
	return game["teamScores"][team];
}

Callback_PlayerConnect()
{
	thread notifyConnecting();

	self.statusicon = "hud_status_connecting";
	self waittill( "begin" );
	waittillframeend;

	if ( !isDefined( self ) )
		return;

	level notify( "connected", self );

	self setStat( 75, 0 );

	if ( !isDefined( level.rdyup ) || !level.rdyup )
		self.statusicon = "";

	if( !isdefined( self.pers["score"] ) )
		iPrintLn( &"MP_CONNECTED", self.name );

	if( !isDefined( self.pers["score"] ) ) self.pers["score"] = 0;
	if( !isDefined( self.pers["deaths"] ) ) self.pers["deaths"] = 0;
	if( !isDefined( self.pers["kills"] ) ) self.pers["kills"] = 0;
	if( !isDefined( self.pers["assists"] ) ) self.pers["assists"] = 0;

	self.score = self.pers["score"];
	self.deaths = self.pers["deaths"];
	self.kills = self.pers["kills"];
	self.assists = self.pers["assists"];

	self.pers["lives"] = level.numLives;

	self.hasSpawned = false;
	self.waitingToSpawn = false;
	self.deathCount = 0;

	self.wasAliveAtMatchStart = false;

	self thread maps\mp\_flashgrenades::monitorFlash();

	level.players[level.players.size] = self;

	if ( level.teambased )
		self updateScores();

	level endon( "game_ended" );

	if ( isDefined( self.pers["team"] ) )
		self.team = self.pers["team"];

	if ( isDefined( self.pers["class"] ) )
		self.class = self.pers["class"];

	if ( !isDefined( self.pers["team"] ) )
	{
		self.pers["team"] = "none";
		self.team = "none";
		self.sessionstate = "dead";

		self setStat( 65 , 0 );

		[[level.spawnSpectator]]();

		self thread promod\client::use_config();
		self thread maps\mp\gametypes\_promod::initClassLoadouts();

		thread maps\mp\gametypes\_promod::updateClassAvailability( "allies" );
		thread maps\mp\gametypes\_promod::updateClassAvailability( "axis" );

		self setclientdvar( "g_scriptMainMenu", game["menu_team"] );
		self openMenu( game["menu_team"] );

		if ( level.teamBased )
		{
			self.sessionteam = self.pers["team"];

			if ( ( !isDefined( level.rdyup ) || !level.rdyup ) && !isAlive( self ) )
				self.statusicon = "hud_status_dead";

			self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
		}
	}
	else if ( self.pers["team"] == "spectator" )
	{
		self setclientdvar( "g_scriptMainMenu", game["menu_shoutcast"] );
		self.sessionteam = "spectator";
		self.sessionstate = "spectator";
		[[level.spawnSpectator]]();
	}
	else
	{
		self.sessionteam = self.pers["team"];
		self.sessionstate = "dead";

		[[level.spawnSpectator]]();

		if ( isValidClass( self.pers["class"] ) )
			self thread [[level.spawnClient]]();

		self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
	}
}

Callback_PlayerDisconnect()
{
	self removePlayerOnDisconnect();

	[[level.onPlayerDisconnect]]();

	for ( i = 0; i < level.players.size; i++ )
	{
		if ( level.players[i] == self )
		{
			while ( i < level.players.size-1 )
			{
				level.players[i] = level.players[i+1];
				i++;
			}
			level.players[i] = undefined;
			break;
		}
	}

	if ( level.gameEnded )
		self removeDisconnectedPlayerFromPlacement();

	if ( isDefined( self.pers["team"] ) && ( self.pers["team"] == "allies" || self.pers["team"] == "axis" ) )
		thread maps\mp\gametypes\_promod::updateClassAvailability( self.pers["team"] );

	level thread updateTeamStatus();
}

removePlayerOnDisconnect()
{
	for ( i = 0; i < level.players.size; i++ )
	{
		if ( level.players[i] == self )
		{
			while ( i < level.players.size-1 )
			{
				level.players[i] = level.players[i+1];
				i++;
			}
			level.players[i] = undefined;
			break;
		}
	}
}

isHeadShot( sWeapon, sHitLoc, sMeansOfDeath )
{
	return (sHitLoc == "head" || sHitLoc == "helmet") && sMeansOfDeath != "MOD_MELEE" && sMeansOfDeath != "MOD_IMPACT";
}

Callback_PlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime )
{
	if ( !isDefined( level.rdyup ) )
		level.rdyup = false;

	if ( getDvarInt("g_knockback") != 1000 || isDefined( game["state"] ) && game["state"] == "postgame" || self.sessionteam == "spectator" || isDefined( level.bombDefused ) && level.bombDefused || isDefined( level.bombExploded ) && level.bombExploded && self.pers["team"] == game["attackers"] )
		return;

	if( isDefined(eAttacker) && isPlayer(eAttacker) && isPlayer(self) && eAttacker.sessionstate == "playing" && isDefined(iDamage) && isDefined( sMeansOfDeath ) && sMeansOfDeath != "" && (sMeansOfDeath == "MOD_RIFLE_BULLET" || sMeansOfDeath == "MOD_PISTOL_BULLET"))
		iDamage = int(iDamage*1.4);

	self.iDFlags = iDFlags;
	self.iDFlagsTime = getTime();

	// bit arrays are interesting, huh?
	if( !isDefined( vDir ) )
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	// Process Assists
	if ( level.teamBased && self.health == self.maxhealth || !isDefined( self.attackers ) )
	{
		self.attackers = [];
		self.attackerData = [];
	}

	if ( isHeadShot( sWeapon, sHitLoc, sMeansOfDeath ) )
		sMeansOfDeath = "MOD_HEAD_SHOT";

	if ( sWeapon == "none" && isDefined( eInflictor ) )
	{
		if ( isDefined( eInflictor.targetname ) && eInflictor.targetname == "explodable_barrel" )
			sWeapon = "explodable_barrel";
		else if ( isDefined( eInflictor.destructible_type ) && isSubStr( eInflictor.destructible_type, "vehicle_" ) )
			sWeapon = "destructible_car";
	}
	friendly = false;

	// if level.iDFLAGS_NO_PROTECTION element in iDflags is not 0, this will happen. NO_PROTECTION == 0 could be god-mode
	if( !(iDFlags & level.iDFLAGS_NO_PROTECTION) )
	{
		if ( (isSubStr( sMeansOfDeath, "MOD_GRENADE" ) || isSubStr( sMeansOfDeath, "MOD_EXPLOSIVE" ) || isSubStr( sMeansOfDeath, "MOD_PROJECTILE" )) && isDefined( eInflictor ) && game["PROMOD_MATCH_MODE"] != "match" && eInflictor.classname == "grenade" && ( (self.lastSpawnTime + 3500) > getTime() && distance( eInflictor.origin, self.lastSpawnPoint.origin ) < 250 || !isDefined ( eAttacker.pers["class"] ) ) )
			return;

		if ( level.teamBased && isPlayer( eAttacker ) && self != eAttacker && self.pers["team"] == eAttacker.pers["team"] )
		{
			if ( !level.friendlyfire )
				return;
			if ( level.friendlyfire == 1 || (level.friendlyfire == 2 || level.friendlyfire == 3) && isAlive( eAttacker ) )
			{
				if( (level.friendlyfire & 2) > 0 ) // 2 or 3
					iDamage = int(iDamage * 0.5);

				if ( iDamage < 1 )
					iDamage = 1;

				if( (level.friendlyfire & 1) > 0 ) // 1 or 3
					self finishPlayerDamageWrapper(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				if( (level.friendlyfire & 2) > 0 ) // 2 or 3
					eAttacker finishPlayerDamageWrapper(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
			}
			friendly = true;
		}
		else
		{
			if(iDamage < 1)
				iDamage = 1;

			if ( level.teamBased && isDefined( eAttacker ) && isPlayer( eAttacker ) )
			{
				if ( !isdefined( self.attackerData[eAttacker.clientid] ) )
				{
					self.attackers[ self.attackers.size ] = eAttacker;
					self.attackerData[eAttacker.clientid] = false;
				}
				if ( isDefined(sWeapon) )
					self.attackerData[eAttacker.clientid] = true;
			}
			self finishPlayerDamageWrapper(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
		}

		if ( isDefined(eAttacker) && eAttacker != self )
		{
			if ( sMeansOfDeath == "MOD_HEAD_SHOT" )
				thread dinkNoise(eAttacker, self);

			if ( iDamage > 0 && !(iDFlags & level.iDFLAGS_PENETRATION) )
				eAttacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback( false );
		}
		self.hasDoneCombat = true;
	}

	if ( isdefined( eAttacker ) && eAttacker != self && !friendly )
		level.useStartSpawns = false;
}

dinkNoise( player1, player2 )
{
	player1 playLocalSound("bullet_impact_headshot_2");
	player2 playLocalSound("bullet_impact_headshot_2");
}

finishPlayerDamageWrapper( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime )
{
	self finishPlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime );
	self damageShellshockAndRumble( eInflictor, sWeapon, sMeansOfDeath, iDamage );
}

damageShellshockAndRumble( eInflictor, sWeapon, sMeansOfDeath, iDamage )
{
	self thread maps\mp\gametypes\_weapons::onWeaponDamage( eInflictor, sWeapon, sMeansOfDeath, iDamage );
	self PlayRumbleOnEntity( "damage_heavy" );
}

Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	if ( !isDefined( level.rdyup ) )
		level.rdyup = false;

	self endon( "spawned" );
	self notify( "killed_player" );

	if ( self.sessionteam == "spectator" || ( isDefined( game["state"] ) && game["state"] == "postgame" ) )
		return;

	prof_begin( "PlayerKilled pre constants" );

	if( isHeadShot( sWeapon, sHitLoc, sMeansOfDeath ) )
		sMeansOfDeath = "MOD_HEAD_SHOT";

	if( attacker.classname == "script_vehicle" && isDefined( attacker.owner ) )
		attacker = attacker.owner;

	if( level.teamBased && isDefined( attacker.pers ) && self.team == attacker.team && sMeansOfDeath == "MOD_GRENADE" && !level.friendlyfire )
		obituary(self, self, sWeapon, sMeansOfDeath);
	else obituary(self, attacker, sWeapon, sMeansOfDeath);

	if ( !isDefined( game["promod_do_readyup"] ) || !game["promod_do_readyup"] )
		self maps\mp\gametypes\_weapons::dropWeaponForDeath( attacker );

	self.sessionstate = "dead";

	if ( !isDefined( level.rdyup ) || !level.rdyup )
		self.statusicon = "hud_status_dead";

	if (!level.rdyup)
	{
		self.deathCount++;

		if( isDefined( attacker.pers ) && !isDefined( self.switching_teams ) )
		{
			self.pers["deaths"]++;
			self.deaths = self.pers["deaths"];
		}
	}

	prof_end( "PlayerKilled pre constants" );

	if( isPlayer( attacker ) )
	{
		if ( attacker == self )
		{
			if ( isDefined( self.switching_teams ) )
				if ( !level.teamBased && ((self.leaving_team == "allies" && self.joining_team == "axis") || (self.leaving_team == "axis" && self.joining_team == "allies")) )
				{
					playerCounts = self maps\mp\gametypes\_teams::CountPlayers();
					playerCounts[self.leaving_team]--;
					playerCounts[self.joining_team]++;
				}
		}
		else
		{
			prof_begin( "PlayerKilled attacker" );

			if ( level.teamBased && self.pers["team"] == attacker.pers["team"] )
			{
				if ( sMeansOfDeath != "MOD_GRENADE" && level.friendlyfire && !level.rdyup )
				{
					attacker thread [[level.onXPEvent]]( "teamkill" );
					if ( maps\mp\gametypes\_tweakables::getTweakableValue( "team", "teamkillpointloss" ) )
						_setPlayerScore( attacker, _getPlayerScore( attacker ) - 5 );
				}
			}
			else
			{
				prof_begin( "pks1" );

				attacker thread maps\mp\gametypes\_rank::giveRankXP( "kill", 5 );

				if (!level.rdyup)
				{
					attacker.pers["kills"]++;
					attacker.kills = attacker.pers["kills"];
					givePlayerScore( "kill", attacker, self );
					giveTeamScore( "kill", attacker.pers["team"], attacker, self );
					scoreSub = maps\mp\gametypes\_tweakables::getTweakableValue( "game", "deathpointloss" );
					_setPlayerScore( self, _getPlayerScore( self ) - scoreSub );
				}
				prof_end( "pks1" );

				if ( !level.rdyup && level.teamBased )
				{
					prof_begin( "PlayerKilled assists" );
					if ( isdefined( self.attackers ) )
					{
						for ( j = 0; j < self.attackers.size; j++ )
						{
							player = self.attackers[j];

							if ( !isDefined( player ) || player == attacker )
								continue;

							player thread processAssist( self );
						}
						self.attackers = [];
					}
					prof_end( "PlayerKilled assists" );
				}
			}
			prof_end( "PlayerKilled attacker" );
		}
	}
	else if ( isDefined( attacker ) && isDefined( attacker.team ) && (attacker.team == "axis" || attacker.team == "allies") && attacker.team != self.pers["team"] )
			if ( level.teamBased )
				giveTeamScore( "kill", attacker.team, attacker, self );

	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	prof_begin( "PlayerKilled post constants" );

	if ( sMeansOfDeath == "MOD_MELEE" )
		scWeapon = "knife_mp";
	else scWeapon = sWeapon;

	sHeadshot = int(sMeansOfDeath == "MOD_HEAD_SHOT");
	level thread updateTeamStatus();
	self clonePlayer( deathAnimDuration );
	self thread [[level.onPlayerKilled]](eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);
	self.deathTime = getTime();
	wait 0.25;
	postDeathDelay = waitForTimeOrNotifies( 0.75 );
	self notify ( "death_delay_finished" );

	if ( !isDefined( game["state"] ) || game["state"] != "playing" )
		return;

	respawnTimerStartTime = gettime();
	prof_end( "PlayerKilled post constants" );

	if ( !isDefined( game["state"] ) || game["state"] != "playing" )
	{
		self.sessionstate = "dead";
		self.spectatorclient = -1;
		self.archivetime = 0;
		self.psoffsettime = 0;
		return;
	}

	if ( isValidClass( self.class ) )
	{
		timePassed = (gettime() - respawnTimerStartTime) / 1000;
		self thread [[level.spawnClient]]( timePassed );
	}
}

waitForTimeOrNotifies( desiredDelay )
{
	startedWaiting = getTime();

	waitedTime = (getTime() - startedWaiting)/1000;

	if ( waitedTime < desiredDelay )
	{
		wait desiredDelay - waitedTime;
		return desiredDelay;
	}
	else
		return waitedTime;
}

processAssist( killedplayer )
{
	self endon("disconnect");
	killedplayer endon("disconnect");

	wait 0.05;
	WaitTillSlowProcessAllowed();

	if ( ( self.pers["team"] != "axis" && self.pers["team"] != "allies" ) || ( self.pers["team"] == killedplayer.pers["team"] ) )
		return;

	self thread [[level.onXPEvent]]( "assist" );
	self.pers["assists"]++;
	self.assists = self.pers["assists"];

	givePlayerScore( "assist", self, killedplayer );

	if ( !isDefined( level.rdyup ) )
		level.rdyup = false;
}

Callback_PlayerLastStand()
{
}

setSpawnVariables()
{
	resetTimeout();

	self StopShellshock();
	self StopRumble( "damage_heavy" );
}

notifyConnecting()
{
	self setRank( 0, 1 );

	waittillframeend;

	if( isDefined( self ) )
		level notify( "connecting", self );
}

setObjectiveText( team, text )
{
	game["strings"]["objective_"+team] = text;
	precacheString( text );
}

setObjectiveScoreText( team, text )
{
	game["strings"]["objective_score_"+team] = text;
	precacheString( text );
}

setObjectiveHintText( team, text )
{
	game["strings"]["objective_hint_"+team] = text;
	precacheString( text );
}

getObjectiveText( team )
{
	if ( !isDefined( game["strings"]["objective_"+team] ) )
		return "";

	return game["strings"]["objective_"+team];
}

getObjectiveScoreText( team )
{
	if ( !isDefined( game["strings"]["objective_score_"+team] ) )
		return "";

	return game["strings"]["objective_score_"+team];
}

getObjectiveHintText( team )
{
	if ( !isDefined( game["strings"]["objective_hint_"+team] ) )
		return "";

	return game["strings"]["objective_hint_"+team];
}