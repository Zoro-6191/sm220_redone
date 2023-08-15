init()
{
	level.scoreInfo = [];
	level.rankTable = [];

	level.scoreInfo["kill"] = 5;
	level.scoreInfo["assist"] = 3;
	level.scoreInfo["teamkill"] = 0;
	level.scoreInfo["plant"] = 3;
	level.scoreInfo["defuse"] = 3;
	level.scoreInfo["capture"] = 3;
	level.scoreInfo["assault"] = 3;
	level.scoreInfo["defend"] = 3;

	[[level.on]]( "connected", ::onConnect );
	[[level.on]]( "spawned", ::onSpawn );
	[[level.on]]( "joined_spectators", ::removeRankHUD );
	[[level.on]]( "joined_team", ::removeRankHUD );
}

onConnect()
{
	self.rankUpdateTotal = 0;
}

onSpawn()
{
	if(!isdefined(self.hud_rankscroreupdate))
	{
		self.hud_rankscroreupdate = newClientHudElem(self);
		self.hud_rankscroreupdate.horzAlign = "center";
		self.hud_rankscroreupdate.vertAlign = "middle";
		self.hud_rankscroreupdate.alignX = "center";
		self.hud_rankscroreupdate.alignY = "middle";
		self.hud_rankscroreupdate.x = 0;
		self.hud_rankscroreupdate.y = -60;
		self.hud_rankscroreupdate.font = "default";
		self.hud_rankscroreupdate.fontscale = 2;
		self.hud_rankscroreupdate.archived = false;
		self.hud_rankscroreupdate.color = (0.5,0.5,0.5);
		self.hud_rankscroreupdate maps\mp\gametypes\_hud::fontPulseInit();
	}
}

giveRankXP( type, value )
{
	self endon("disconnect");

	if ( !isDefined( value ) )
		value = level.scoreInfo[type];

	if ( type == "teamkill" )
		self thread updateRankScoreHUD( -5 );
	else self thread updateRankScoreHUD( value );
}

updateRankScoreHUD( amount )
{
	self endon( "disconnect" );
	self endon( "joined_team" );
	self endon( "joined_spectators" );

	if ( !amount )
		return;

	self notify( "update_score" );
	self endon( "update_score" );

	self.rankUpdateTotal += amount;

	wait 0.05;

	if( isDefined( self.hud_rankscroreupdate ) )
	{
		if ( self.rankUpdateTotal < 0 )
		{
			self.hud_rankscroreupdate.label = &"";
			self.hud_rankscroreupdate.color = (1,0,0);
		}
		else
		{
			self.hud_rankscroreupdate.label = &"MP_PLUS";
			self.hud_rankscroreupdate.color = (1,1,0.5);
		}

		self.hud_rankscroreupdate setValue(self.rankUpdateTotal);
		self.hud_rankscroreupdate.alpha = 0.85;
		self.hud_rankscroreupdate thread maps\mp\gametypes\_hud::fontPulse( self );

		wait 1;
		self.hud_rankscroreupdate fadeOverTime( 0.75 );
		self.hud_rankscroreupdate.alpha = 0;

		self.rankUpdateTotal = 0;
	}
}

removeRankHUD()
{
	if(isDefined(self.hud_rankscroreupdate))
		self.hud_rankscroreupdate.alpha = 0;
}