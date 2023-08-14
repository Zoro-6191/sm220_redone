get_config( dataName )
{
	return self getStat( int( tableLookup( "promod/customStatsTable.csv", 1, dataName, 0 ) ) );
}

set_config( dataName, value )
{
	self setStat( int( tableLookup( "promod/customStatsTable.csv", 1, dataName, 0 ) ), value );
	return value;
}

toggle(name)
{
	return self set_config( name, int(!self get_config(name)) );
}

loopthrough(name, limit)
{
	value = self get_config(name)+1;
	if(value > limit) value = 0;
	return self set_config(name, value);
}

setsunlight(n)
{
	sl = 0;
	slsetting = "Off";
	if ( !n )
	{
		sl = 1.2;
		slsetting = 1.2;
	}
	else if ( n == 1 && isDefined(level.sunlight) )
	{
		slsetting = "Stock";
		sl = level.sunlight;
	}
	self setclientdvars("r_lighttweaksunlight", sl, "sunlight", slsetting);
}

use_config()
{
	self setsunlight(self get_config("PROMOD_SUNLIGHT"));
	self setClientDvars(
	"cg_crosshairenemycolor", 0,
	"cg_drawcrosshairnames", 0,
	"cg_drawcrosshair", 1,
	"r_filmtweakinvert", 0,
	"r_desaturation", 0,
	"r_fog", 0,
	"r_blur", 0,
	"cg_drawSpectatorMessages", 1,
	"self_ready", "",
	"ui_hud_hardcore", 0,
	"cg_hudGrenadeIconMaxRangeFrag", 250,
	"r_specularcolorscale", 0,
	"fx_drawclouds", 0,
	"r_normalmap", self get_config("PROMOD_NORMALMAP"),
	"r_texfilterdisable", self get_config("PROMOD_TEXTURE"),
	"r_filmusetweaks", self get_config("PROMOD_FILMTWEAK"),
	"cg_fovscale", 1+int(!self get_config("PROMOD_FOVSCALE"))*0.125);
}