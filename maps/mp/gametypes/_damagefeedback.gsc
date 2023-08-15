init()
{
	precacheShader("damage_feedback");
	[[level.on]]( "connected", ::onConnect );
}

onConnect()
{
	self.hud_damagefeedback = newClientHudElem(self);
	self.hud_damagefeedback.horzAlign = "center";
	self.hud_damagefeedback.vertAlign = "middle";
	self.hud_damagefeedback.x = -12;
	self.hud_damagefeedback.y = -12;
	self.hud_damagefeedback.alpha = 0;
	self.hud_damagefeedback.archived = true;
	self.hud_damagefeedback setShader("damage_feedback", 24, 48);
}

updateDamageFeedback( hitBodyArmor )
{
	if ( !isPlayer( self ) )
		return;

	self playlocalsound("MP_hit_alert");
	
	self.hud_damagefeedback.alpha = 1;
	self.hud_damagefeedback fadeOverTime(1);
	self.hud_damagefeedback.alpha = 0;
}