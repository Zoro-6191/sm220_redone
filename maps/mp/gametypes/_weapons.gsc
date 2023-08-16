init()
{
	precacheItem( "ak47_mp" );
	precacheItem( "ak47_silencer_mp" );
	precacheItem( "ak74u_mp" );
	precacheItem( "ak74u_silencer_mp" );
	precacheItem( "beretta_mp" );
	precacheItem( "beretta_silencer_mp" );
	precacheItem( "colt45_mp" );
	precacheItem( "colt45_silencer_mp" );
	precacheItem( "deserteagle_mp" );
	precacheItem( "deserteaglegold_mp" );
	precacheItem( "frag_grenade_mp" );
	precacheItem( "g3_mp" );
	precacheItem( "g3_silencer_mp" );
	precacheItem( "g36c_mp" );
	precacheItem( "g36c_silencer_mp" );
	precacheItem( "m4_mp" );
	precacheItem( "m4_silencer_mp" );
	precacheItem( "m14_mp" );
	precacheItem( "m14_silencer_mp" );
	precacheItem( "m16_mp" );
	precacheItem( "m16_silencer_mp" );
	precacheItem( "m40a3_mp" );
	precacheItem( "m1014_mp" );
	precacheItem( "mp5_mp" );
	precacheItem( "mp5_silencer_mp" );
	precacheItem( "mp44_mp" );
	precacheItem( "remington700_mp" );
	precacheItem( "usp_mp" );
	precacheItem( "usp_silencer_mp" );
	precacheItem( "uzi_mp" );
	precacheItem( "uzi_silencer_mp" );
	precacheItem( "winchester1200_mp" );
	precacheItem( "smoke_grenade_mp" );
	precacheItem( "flash_grenade_mp" );
	precacheItem( "destructible_car" );
	precacheShellShock( "default" );
	thread maps\mp\_flashgrenades::main();

	[[level.on]]( "spawned", ::onSpawn );
	[[level.on]]( "spawned", ::watchWeaponUsage );
	[[level.on]]( "spawned", ::watchGrenadeUsage );
	[[level.on]]( "spawned", ::watchGrenadeAmmo );
}

onSpawn()
{
	self.hasDoneCombat = false;
}

watchGrenadeAmmo()
{
	self endon("death");
	self endon("disconnect");
	self endon("game_ended");

	prim = true;
	sec = true;

	while(prim || sec)
	{
		self waittill("grenade_fire");

		if((isDefined( game["promod_do_readyup"] ) && game["promod_do_readyup"]) )
			break;

		wait 0.25; // 5 frames, ought to be enough

		pg = "";
		if(self hasWeapon("frag_grenade_mp"))
			pg = "frag_grenade_mp";
		else prim = false;

		sg = "";
		if(self hasWeapon("flash_grenade_mp"))
			sg = "flash_grenade_mp";
		else if(self hasWeapon("smoke_grenade_mp"))
			sg = "smoke_grenade_mp";
		else
			sec = false;

		if(prim && pg != "" && self GetAmmoCount(pg) < 1)
		{
			self TakeWeapon(pg);
			prim = false;
		}

		if(sec && sg != "" && self GetAmmoCount(sg) < 1)
		{
			self TakeWeapon(sg);
			sec = false;
		}
	}
}

dropWeaponForDeath( attacker )
{
	weapon = self getCurrentWeapon();

	if ( !isDefined( weapon ) || !self hasWeapon( weapon ) )
		return;

	switch ( weapon )
	{
		case "m40a3_mp":
		case "remington700_mp":
		case "winchester1200_mp":
		case "m1014_mp":
			return;
		default:
			break;
	}

	clipAmmo = self GetWeaponAmmoClip( weapon );

	if ( !clipAmmo )
		return;

	stockAmmo = self GetWeaponAmmoStock( weapon );
	stockMax = WeaponMaxAmmo( weapon );
	if ( stockAmmo > stockMax )
		stockAmmo = stockMax;

	item = self dropItem( weapon );

	item ItemWeaponSetAmmo( clipAmmo, stockAmmo );

	if( level.gametype != "sd" || game["promod_do_readyup"] )
		item thread deletePickupAfterAWhile();
}

deletePickupAfterAWhile()
{
	self endon("death");

	wait 180;

	if ( !isDefined( self ) )
		return;

	self delete();
}

watchWeaponUsage()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	self waittill ( "begin_firing" );
	self.hasDoneCombat = true;
}

watchGrenadeUsage()
{
	self endon( "death" );
	self endon( "disconnect" );

	self.throwingGrenade = false;

	for(;;)
	{
		self waittill ( "grenade_pullback", weaponName );

		self.hasDoneCombat = true;
		self.throwingGrenade = true;
		self beginGrenadeTracking();
	}
}

beginGrenadeTracking()
{
	self endon ( "death" );
	self endon ( "disconnect" );

	self waittill ( "grenade_fire", grenade, weaponName );

	if ( weaponName == "frag_grenade_mp" )
		grenade thread maps\mp\gametypes\_shellshock::grenade_earthQuake();

	self.throwingGrenade = false;
}

onWeaponDamage( eInflictor, sWeapon, meansOfDeath, damage )
{
	self endon ( "death" );
	self endon ( "disconnect" );

	maps\mp\gametypes\_shellshock::shellshockOnDamage( meansOfDeath, damage );
}