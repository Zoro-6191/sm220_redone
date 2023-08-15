init()
{
	level.spectateOverride["allies"] = spawnstruct();
	level.spectateOverride["axis"] = spawnstruct();

	[[level.on]]( "spawned", ::setSpectatePermissions );
	[[level.on]]( "joined_team", ::setSpectatePermissions );
	[[level.on]]( "joined_spectators", ::setSpectatePermissions );
}

getOtherTeam( team )
{
	if ( team == "axis" )
		return "allies";
	else if ( team == "allies" )
		return "axis";
	else return "none";
}

setSpectatePermissions()
{
	team = self.sessionteam;
	spectateType = maps\mp\gametypes\_tweakables::getTweakableValue( "game", "spectatetype" );

	switch( spectateType )
	{
		case 0:
			self allowSpectateTeam( "allies", false );
			self allowSpectateTeam( "axis", false );
			self allowSpectateTeam( "freelook", false );
			self allowSpectateTeam( "none", false );
			break;
		case 1:
			if ( !level.teamBased )
			{
				self allowSpectateTeam( "allies", true );
				self allowSpectateTeam( "axis", true );
				self allowSpectateTeam( "none", true );
				self allowSpectateTeam( "freelook", true );
			}
			else if ( isDefined( team ) && ( team == "allies" || team == "axis" ) )
			{
				self allowSpectateTeam( team, true );
				self allowSpectateTeam( getOtherTeam( team ), false );
				self allowSpectateTeam( "freelook", false );
				self allowSpectateTeam( "none", false );
			}
			else if ( isDefined( team ) && ( team == "spectator" ) )
			{
				self allowSpectateTeam( "allies", true );
				self allowSpectateTeam( "axis", true );
				self allowSpectateTeam( "freelook", true );
				self allowSpectateTeam( "none", true );
			}
			else
			{
				self allowSpectateTeam( "allies", false );
				self allowSpectateTeam( "axis", false );
				self allowSpectateTeam( "freelook", false );
				self allowSpectateTeam( "none", false );
			}
			break;
		case 2:
			self allowSpectateTeam( "allies", true );
			self allowSpectateTeam( "axis", true );
			self allowSpectateTeam( "freelook", true );
			self allowSpectateTeam( "none", true );
			break;
	}
}