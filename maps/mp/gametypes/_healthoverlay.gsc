init()
{
	precacheShader("overlay_low_health");

	level.healthOverlayCutoff = 0.55;

	regenTime = 5;

	level.playerHealth_RegularRegenDelay = regenTime * 1000;

	level.healthRegenDisabled = (level.playerHealth_RegularRegenDelay <= 0);

	[[level.on]]( "connected", ::onPlayerKilled );
	[[level.on]]( "connected", ::onPlayerDisconnect );
	[[level.on]]( "spawned", ::playerHealthRegen );
	[[level.on]]( "joined_team", ::endHealthRegen );
	[[level.on]]( "joined_spectators", ::endHealthRegen );
}


endHealthRegen()
{
	self notify("end_healthregen");
}

onPlayerKilled()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("killed_player");
		self notify("end_healthregen");
	}
}

onPlayerDisconnect()
{
	self waittill("disconnect");
	self notify("end_healthregen");
}

playerHealthRegen()
{
	self endon("end_healthregen");

	if ( self.health <= 0 )
		return;

	maxhealth = self.health;
	oldhealth = maxhealth;
	player = self;
	health_add = 0;

	regenRate = 0.1;
	veryHurt = false;

	player.breathingStopTime = -10000;

	thread playerBreathingSound(maxhealth * 0.35);

	lastSoundTime_Recover = 0;
	hurtTime = 0;
	newHealth = 0;

	for(;;)
	{
		wait 0.05;
		if (player.health == maxhealth)
		{
			veryHurt = false;
			self.atBrinkOfDeath = false;
			continue;
		}

		if (player.health <= 0)
			return;

		wasVeryHurt = veryHurt;
		ratio = player.health / maxHealth;
		if (ratio <= level.healthOverlayCutoff)
		{
			veryHurt = true;
			self.atBrinkOfDeath = true;
			if (!wasVeryHurt)
				hurtTime = gettime();
		}

		if (player.health >= oldhealth)
		{
			if (gettime() - hurttime < level.playerHealth_RegularRegenDelay || level.healthRegenDisabled)
				continue;

			if (gettime() - lastSoundTime_Recover > level.playerHealth_RegularRegenDelay)
			{
				lastSoundTime_Recover = gettime();
				self playLocalSound("breathing_better");
			}

			if (veryHurt)
			{
				newHealth = ratio;
				if (gettime() > hurtTime + 3000)
					newHealth += regenRate;
			}
			else newHealth = 1;

			if ( newHealth >= 1.0 )
				newHealth = 1.0;

			if (newHealth <= 0)
				return;

			player setnormalhealth (newHealth);
			oldhealth = player.health;
			continue;
		}

		oldhealth = player.health;

		health_add = 0;
		hurtTime = gettime();
		player.breathingStopTime = hurtTime + 6000;
	}
}

playerBreathingSound(healthcap)
{
	self endon("end_healthregen");

	wait 2;
	player = self;
	for(;;)
	{
		wait 0.2;
		if ( player.health <= 0 )
			return;

		if ( player.health >= healthcap || level.healthRegenDisabled && gettime() > player.breathingStopTime )
			continue;

		player playLocalSound("breathing_hurt");
		wait 0.784;
		wait (0.1 + randomfloat (0.8));
	}
}
