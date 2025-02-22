
#include maps\mp\gametypes\_hud_util;

main()
{
	if ( game["promod_timeout_called"] )
	{
		thread promod\timeout::main();
		return;
	}

	thread stratTime();

	level waittill( "strat_over" );

	players = getentarray("player", "classname");
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];
		classType = player.pers["class"];

		if ( ( player.pers["team"] == "allies" || player.pers["team"] == "axis" ) && player.sessionstate == "playing" && isDefined( player.pers["class"] ) )
		{
			if ( isDefined( game["PROMOD_KNIFEROUND"] ) && !game["PROMOD_KNIFEROUND"] || !isDefined( game["PROMOD_KNIFEROUND"] ) )
			{
				player giveWeapon( "frag_grenade_mp" );

				if ( player.pers[classType]["loadout_grenade"] == "flash_grenade" )
				{
					player setOffhandSecondaryClass("flash");
					player giveWeapon( "flash_grenade_mp" );
				}
				else if ( player.pers[classType]["loadout_grenade"] == "smoke_grenade" )
				{
					player setOffhandSecondaryClass("smoke");
					player giveWeapon( "smoke_grenade_mp" );
				}

				player maps\mp\gametypes\_class::sidearmWeapon();
				player maps\mp\gametypes\_class::primaryWeapon();
			}
			else
				player thread maps\mp\gametypes\_globallogic::removeWeapons();

			player allowsprint(true);
			player setMoveSpeedScale( 1.0 - 0.05 * int( isDefined( player.curClass ) && player.curClass == "assault" ) * int( isDefined( game["PROMOD_KNIFEROUND"] ) && !game["PROMOD_KNIFEROUND"] || !isDefined( game["PROMOD_KNIFEROUND"] ) ) );
			player allowjump(true);
		}
	}

	UpdateClientNames();

	if ( game["promod_timeout_called"] )
	{
		thread promod\timeout::main();
		return;
	}
}

stratTime()
{
	thread stratTimer();

	level.strat_over = false;
	strat_time_left = game["PROMOD_STRATTIME"];

	while ( !level.strat_over )
	{
		players = getentarray("player", "classname");
		for ( i = 0; i < players.size; i++ )
		{
			player = players[i];

			if ( ( player.pers["team"] == "allies" || player.pers["team"] == "axis" ) && !isDefined( player.pers["class"] ) )
				player.statusicon = "hud_status_dead";
		}

		wait 0.25;

		strat_time_left -= 0.25;

		if ( strat_time_left <= 0 || game["promod_timeout_called"] )
			level.strat_over = true;
	}

	level notify( "strat_over" );
}

stratTimer()
{
	matchStartText = createServerFontString( "big", 1.6 );
	matchStartText setPoint( "CENTER", "CENTER", 0, -60 );
	matchStartText.sort = 1001;

	if( isDefined(game["PROMOD_KNIFEROUND"]) && game["PROMOD_KNIFEROUND"] )
		matchStartText setText( "Knife Round" );
	else matchStartText setText( "Strat Time" );

	matchStartText.foreground = false;
	matchStartText.hidewheninmenu = false;

	matchStartTimer = createServerTimer( "big", 1.5 );
	matchStartTimer setPoint( "CENTER", "CENTER", 0, -45 );
	matchStartTimer setTimer( game["PROMOD_STRATTIME"] );
	matchStartTimer.sort = 1001;
	matchStartTimer.foreground = false;
	matchStartTimer.hideWhenInMenu = false;

	level waittill( "strat_over" );

	if ( isDefined( matchStartText ) )
		matchStartText destroy();

	if ( isDefined( matchStartTimer ) )
		matchStartTimer destroy();
}