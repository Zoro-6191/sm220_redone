init()
{
	level.serverDvars = [];

	setServerDvarDefault( "allies_allow_assault", 1, 0, 1 );
	setServerDvarDefault( "allies_allow_specops", 1, 0, 1 );
	setServerDvarDefault( "allies_allow_demolitions", 1, 0, 1 );
	setServerDvarDefault( "allies_allow_sniper", 1, 0, 1 );
	setServerDvarDefault( "axis_allow_assault", 1, 0, 1 );
	setServerDvarDefault( "axis_allow_specops", 1, 0, 1 );
	setServerDvarDefault( "axis_allow_demolitions", 1, 0, 1 );
	setServerDvarDefault( "axis_allow_sniper", 1, 0, 1 );

	setDvarDefault( "class_assault_primary", "ak47" );
	setDvarDefault( "class_assault_primary_attachment", "none" );
	setDvarDefault( "class_assault_secondary", "deserteagle" );
	setDvarDefault( "class_assault_secondary_attachment", "none" );
	setDvarDefault( "class_assault_grenade", "smoke_grenade" );
	setDvarDefault( "class_assault_camo", "camo_none" );

	setDvarDefault( "class_specops_primary", "ak74u" );
	setDvarDefault( "class_specops_primary_attachment", "none" );
	setDvarDefault( "class_specops_secondary", "deserteagle" );
	setDvarDefault( "class_specops_secondary_attachment", "none" );
	setDvarDefault( "class_specops_grenade", "smoke_grenade" );
	setDvarDefault( "class_specops_camo", "camo_none" );

	setDvarDefault( "class_demolitions_primary", "winchester1200" );
	setDvarDefault( "class_demolitions_primary_attachment", "none" );
	setDvarDefault( "class_demolitions_secondary", "deserteagle" );
	setDvarDefault( "class_demolitions_secondary_attachment", "none" );
	setDvarDefault( "class_demolitions_grenade", "smoke_grenade" );
	setDvarDefault( "class_demolitions_camo", "camo_none" );

	setDvarDefault( "class_sniper_primary", "m40a3" );
	setDvarDefault( "class_sniper_primary_attachment", "none" );
	setDvarDefault( "class_sniper_secondary", "deserteagle" );
	setDvarDefault( "class_sniper_secondary_attachment", "none" );
	setDvarDefault( "class_sniper_grenade", "smoke_grenade" );
	setDvarDefault( "class_sniper_camo", "camo_none" );

	[[level.on]]( "connecting", ::updateServerDvars );
}

setClassChoice( classType )
{
	if( classType != "assault" && classType != "specops" && classType != "demolitions" && classType != "sniper" )
		return;

	self.pers["class"] = classType;
	self.class = classType;

	self setClientDvar( "loadout_class", classType );

	self initClassLoadouts();
	self setStatsFromClass( classType );

	thread updateClassAvailability( self.pers["team"] );
}

setDvarWrapper( dvarName, setVal )
{
	setDvar( dvarName, setVal );
	if ( isDefined( level.serverDvars[dvarName] ) )
	{
		level.serverDvars[dvarName] = setVal;
		for ( i = 0; i < level.players.size; i++ )
			level.players[i] setClientDvar( dvarName, setVal );
	}
}

setDvarDefault( dvarName, setVal, minVal, maxVal )
{
	if ( getDvar( dvarName ) != "" )
	{
		if ( isString( setVal ) )
			setVal = getDvar( dvarName );
		else setVal = getDvarFloat( dvarName );
	}

	if ( isDefined( minVal ) && !isString( setVal ) )
		setVal = max( setVal, minVal );

	if ( isDefined( maxVal ) && !isString( setVal ) )
		setVal = min( setVal, maxVal );

	setDvar( dvarName, setVal );
	return setVal;
}

setServerDvarDefault( dvarName, setVal, minVal, maxVal )
{
	setDvar( dvarName, setVal );
	makeDvarServerInfo( dvarName );

	level.serverDvars[dvarName] = setVal;
}

initClassLoadouts()
{
	self initLoadoutForClass( "assault" );
	self initLoadoutForClass( "specops" );
	self initLoadoutForClass( "demolitions" );
	self initLoadoutForClass( "sniper" );
}

initLoadoutForClass( classType )
{
	SSALC = "";
	if ( classType == "assault" )
		SSALC = "ASSAULT";
	else if ( classType == "specops" )
		SSALC = "SPECOPS";
	else if ( classType == "demolitions" )
		SSALC = "DEMOLITIONS";
	else if ( classType == "sniper" )
		SSALC = "SNIPER";

	CLASS_PRIMARY = SSALC + "_PRIMARY";
	CLASS_PRIMARY_ATTACHMENT = SSALC + "_PRIMARY_ATTACHMENT";
	CLASS_SECONDARY = SSALC + "_SECONDARY";
	CLASS_SECONDARY_ATTACHMENT = SSALC + "_SECONDARY_ATTACHMENT";
	CLASS_GRENADE = SSALC + "_GRENADE";
	CLASS_CAMO = SSALC + "_CAMO";

	if ( !isDefined( self.pers[classType] ) || !isDefined( self.pers[classType]["loadout_primary"] ) )
	{
		if ( validClass( classType, get_config( CLASS_PRIMARY ), "loadout_primary" ) )
			self.pers[classType]["loadout_primary"] = get_config( CLASS_PRIMARY );
		else self.pers[classType]["loadout_primary"] = getDvar( "class_" + classType + "_primary" );
	}

	if ( !isDefined( self.pers[classType] ) || !isDefined( self.pers[classType]["loadout_primary_attachment"] ) )
	{
		if ( validClass( classType, get_config( CLASS_PRIMARY_ATTACHMENT ), "loadout_primary_attachment" ) )
			self.pers[classType]["loadout_primary_attachment"] = get_config( CLASS_PRIMARY_ATTACHMENT );
		else self.pers[classType]["loadout_primary_attachment"] = getDvar( "class_" + classType + "_primary_attachment" );
	}

	if ( !isDefined( self.pers[classType] ) || !isDefined( self.pers[classType]["loadout_secondary"] ) )
	{
		if ( validClass( classType, get_config( CLASS_SECONDARY ), "loadout_secondary" ) )
			self.pers[classType]["loadout_secondary"] = get_config( CLASS_SECONDARY );
		else self.pers[classType]["loadout_secondary"] = getDvar( "class_" + classType + "_secondary" );
	}

	if ( !isDefined( self.pers[classType] ) || !isDefined( self.pers[classType]["loadout_secondary_attachment"] ) )
	{
		if ( validClass( classType, get_config( CLASS_SECONDARY_ATTACHMENT ), "loadout_secondary_attachment" ) )
			self.pers[classType]["loadout_secondary_attachment"] = get_config( CLASS_SECONDARY_ATTACHMENT );
		else self.pers[classType]["loadout_secondary_attachment"] = getDvar( "class_" + classType + "_secondary_attachment" );
	}

	if ( !isDefined( self.pers[classType] ) || !isDefined( self.pers[classType]["loadout_grenade"] ) )
	{
		if ( validClass( classType, get_config( CLASS_GRENADE ), "loadout_grenade" ) )
			self.pers[classType]["loadout_grenade"] = get_config( CLASS_GRENADE );
		else self.pers[classType]["loadout_grenade"] = getDvar( "class_" + classType + "_grenade" );
	} 

	if ( !isDefined( self.pers[classType] ) || !isDefined( self.pers[classType]["loadout_camo"] ) )
	{
		if ( validClass( classType, get_config( CLASS_CAMO ), "loadout_camo" ) )
			self.pers[classType]["loadout_camo"] = get_config( CLASS_CAMO );
		else self.pers[classType]["loadout_camo"] = getDvar( "class_" + classType + "_camo" );
	}
}

validClass( classType, preServed, type )
{
	if ( preServed == "" )
		return false;

	loadout_primary = "";
	loadout_primary_attachment = "";
	loadout_secondary = "";
	loadout_secondary_attachment = "";
	loadout_grenade = "";
	loadout_camo = "";

	if ( classType == "assault" )
		loadout_primary = strTok( "m16,ak47,m4,g3,g36c,m14,mp44", "," );
	else if ( classType == "specops" )
		loadout_primary = strTok( "mp5,uzi,ak74u", "," );
	else if ( classType == "demolitions" )
		loadout_primary = strTok( "winchester1200,m1014", "," );
	else if ( classType == "sniper" )
		loadout_primary = strTok( "m40a3,remington700", "," );

	loadout_primary_attachment = strTok( "none,silencer", "," );
	loadout_secondary = strTok( "deserteaglegold,deserteagle,colt45,usp,beretta", "," );
	loadout_secondary_attachment = strTok( "none,silencer", "," );
	loadout_grenade = strTok( "flash_grenade,smoke_grenade", "," );
	loadout_camo = strTok( "camo_none,camo_brockhaurd,camo_bushdweller,camo_blackwhitemarpat,camo_tigerred,camo_stagger,camo_gold", "," );

	switch ( type )
	{
		case "loadout_primary":
			for ( i = 0; i < loadout_primary.size; i++ )
				if ( loadout_primary[i] == preServed )
					return true;
			break;

		case "loadout_primary_attachment":
			if ( classType == "assault" || classType == "specops" )
				for ( i = 0; i < loadout_primary_attachment.size; i++ )
					if ( loadout_primary_attachment[i] == preServed )
						return true;
			break;

		case "loadout_secondary":
			for ( i = 0; i < loadout_secondary.size; i++ )
				if ( loadout_secondary[i] == preServed )
					return true;
			break;

		case "loadout_secondary_attachment":
			for ( i = 0; i < loadout_secondary_attachment.size; i++ )
				if ( loadout_secondary_attachment[i] == preServed )
					return true;
			break;

		case "loadout_grenade":
			for ( i = 0; i < loadout_grenade.size; i++ )
				if ( loadout_grenade[i] == preServed )
					return true;
			break;

		case "loadout_camo":
			for ( i = 0; i < loadout_camo.size; i++ )
				if ( loadout_camo[i] == preServed )
					return true;
			break;

		default:
			return false;
	}

	return false;
}

setStatsFromClass( classType )
{
	self setStat( 67, int(tableLookup( "promod/customStatsTable.csv", 1, self.pers[classType]["loadout_primary"], 0 ) ) );
	self setStat( 68, int(tableLookup( "promod/customStatsTable.csv", 1, self.pers[classType]["loadout_primary_attachment"], 0 ) ) );
	self setStat( 69, int(tableLookup( "promod/customStatsTable.csv", 1, self.pers[classType]["loadout_secondary"], 0 ) ) );
	self setStat( 70, int(tableLookup( "promod/customStatsTable.csv", 1, self.pers[classType]["loadout_secondary_attachment"], 0 ) ) );
	self setStat( 71, int(tableLookup( "promod/customStatsTable.csv", 1, self.pers[classType]["loadout_grenade"], 0 ) ) );
	self setStat( 72, int(tableLookup( "promod/customStatsTable.csv", 1, self.pers[classType]["loadout_camo"], 0 ) ) );
}

processLoadoutResponse( respString )
{
	if ( !isDefined( self.pers["class"] ) )
		return;

	commandTokens = strTok( respString, "," );

	for ( i = 0; i < commandTokens.size; i++ )
	{
		subTokens = strTok( commandTokens[i], ":" );
		if( subTokens.size < 2 )
			return;

		switch ( subTokens[0] )
		{
			case "loadout_primary":
				if ( self verifyWeaponChoice( subTokens[1], self.class ) )
				{
					self.pers[self.class]["loadout_primary"] = subTokens[1];
					self setStat( 67, int(tableLookup( "promod/customStatsTable.csv", 1, subTokens[1], 0 )) );
					if ( subTokens[1] == "mp44" )
					{
						self.pers[self.class]["loadout_primary_attachment"] = "none";
						self setStat( 68, 45 );
					}
				}
				else self setStat( 67, int(tableLookup( "promod/customStatsTable.csv", 1, self.pers[self.class]["loadout_primary"], 0 )) );
				break;
			case "loadout_secondary":
				if ( self verifyWeaponChoice( subTokens[1], self.class ) )
				{
					self.pers[self.class]["loadout_secondary"] = subTokens[1];
					self setStat( 69, int(tableLookup( "promod/customStatsTable.csv", 1, subTokens[1], 0 )) );
					if ( subTokens[1] == "deserteagle" || subTokens[1] == "deserteaglegold" )
					{
						self.pers[self.class]["loadout_secondary_attachment"] = "none";
						self setStat( 70, 45 );
					}
				}
				else self setStat( 69, int(tableLookup( "promod/customStatsTable.csv", 1, self.pers[self.class]["loadout_secondary"], 0 )) );
				break;

			case "loadout_primary_attachment":
			case "loadout_secondary_attachment":
				if ( ( subTokens[1] == "assault" || subTokens[1] == "specops" || subTokens[1] == "pistol" ) && ( subTokens[2] == "none" || subTokens[2] == "silencer" ) )
				{
					if ( subTokens[0] == "loadout_primary_attachment" && self.pers[self.class]["loadout_primary"] == "mp44" )
					{
						self.pers[self.class]["loadout_primary_attachment"] = "none";
						self setStat( 68, 45 );
					}
					else
					{
						self.pers[self.class][subTokens[0]] = subTokens[2];
						self setStat( int(tableLookup( "promod/customStatsTable.csv", 1, subTokens[0], 0 )), int(tableLookup( "promod/customStatsTable.csv", 1, subTokens[2], 0 )) );
					}
					break;
				}
				else return;

			case "loadout_grenade":
				switch ( subTokens[1] )
				{
					case "flash_grenade":
					case "smoke_grenade":
						self.pers[self.class][subTokens[0]] = subTokens[1];
						self setStat( 71, int(tableLookup( "promod/customStatsTable.csv", 1, subTokens[1], 0 )) );
						self setClientDvar( subTokens[0], subTokens[1] );
						break;
					default:
						return;
				}

			case "loadout_camo":
				switch ( subTokens[1] )
				{
					case "camo_none":
					case "camo_brockhaurd":
					case "camo_bushdweller":
					case "camo_blackwhitemarpat":
					case "camo_tigerred":
					case "camo_stagger":
					case "camo_gold":
						self.pers[self.class][subTokens[0]] = subTokens[1];
						self setStat( 72, int(tableLookup( "promod/customStatsTable.csv", 1, subTokens[1], 0 ) ) );
						break;
					default:
						return;
				}
		}
	}
}

verifyWeaponChoice( weaponName, classType )
{
	if ( tableLookup( "mp/statsTable.csv", 4, weaponName, 2 ) == "weapon_pistol" )
		return true;

	switch ( classType )
	{
		case "assault":
		case "sniper":
			if ( tableLookup( "mp/statsTable.csv", 4, weaponName, 2 ) == "weapon_"+classType )
				return true;
			break;
		case "specops":
			if ( tableLookup( "mp/statsTable.csv", 4, weaponName, 2 ) == "weapon_smg" )
				return true;
			break;
		case "demolitions":
			if ( tableLookup( "mp/statsTable.csv", 4, weaponName, 2 ) == "weapon_shotgun" )
				return true;
			break;
	}

	return false;
}

verifyClassChoice( teamName, classType )
{
	if( teamName != "allies" && teamName != "axis" )
		return false;

	if ( isDefined( self.pers["class"] ) && self.pers["class"] == classType )
		return true;

	game[teamName + "_" + classType + "_count"] = 0;
	for ( i = 0; i < level.players.size; i++ )
		if ( level.players[i].team == teamName && isDefined( level.players[i].class ) && level.players[i].class == classType )
			game[teamName + "_" + classType + "_count"]++;

	return ( game[teamName + "_" + classType + "_count"] < getDvarInt( "class_" + classType + "_limit" ) );
}

updateClassAvailability( teamName )
{
	game[teamName + "_assault_count"] = 0;
	game[teamName + "_specops_count"] = 0;
	game[teamName + "_demolitions_count"] = 0;
	game[teamName + "_sniper_count"] = 0;

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];

		if ( player.team == teamName && isDefined( player.class ) && player.class == "assault" )
			game[teamName + "_assault_count"]++;

		if ( player.team == teamName && isDefined( player.class ) && player.class == "specops" )
			game[teamName + "_specops_count"]++;

		if ( player.team == teamName && isDefined( player.class ) && player.class == "demolitions" )
			game[teamName + "_demolitions_count"]++;

		if ( player.team == teamName && isDefined( player.class ) && player.class == "sniper" )
			game[teamName + "_sniper_count"]++;
	}

	setDvar( teamName + "_allow_assault", game[teamName + "_assault_count"] < 64 );
	setDvar( teamName + "_allow_specops", game[teamName + "_specops_count"] < 2 );
	setDvar( teamName + "_allow_demolitions", game[teamName + "_demolitions_count"] < 1 );
	setDvar( teamName + "_allow_sniper", game[teamName + "_sniper_count"] < 1 );
}

menuAcceptClass( response )
{
	if ( !isDefined( self.pers["class"] ) )
		return;

	if ( !isDefined( response ) || response != "back" )
		self maps\mp\gametypes\_globallogic::closeMenus();

	if ( !isDefined( self.pers["team"] ) || ( self.pers["team"] != "allies" && self.pers["team"] != "axis" ) )
		return;

	if ( self.sessionstate == "playing" )
	{
		if ( isDefined( level.rdyup ) && level.rdyup || isDefined( level.strat_over ) && !level.strat_over )
			self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], self.pers["class"] );
		else
		{
			self iprintlnbold( game["strings"]["change_class"] );
			self setStat( 65, int(tableLookup( "promod/customStatsTable.csv", 1, self.pers["class"], 0 )) );
		}

		if ( isDefined( response ) )
			self thread maps\mp\gametypes\_class::preserveClass( self.pers["class"] );
	}
	else
	{
		self setStat( 65, int(tableLookup( "promod/customStatsTable.csv", 1, self.pers["class"], 0 )) );

		if ( isDefined( response) && response == "go" )
			self thread maps\mp\gametypes\_class::preserveClass( self.pers["class"] );

		if ( isDefined( game["state"] ) && game["state"] == "postgame" )
			return;

		if ( isDefined( game["state"] ) && game["state"] == "playing" )
			self thread [[level.spawnClient]]();
	}

	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
}

updateServerDvars()
{
	self endon ( "disconnect" );

	dvarKeys = getArrayKeys( level.serverDvars );
	for ( i = 0; i < dvarKeys.size; i++ )
	{
		self setClientDvar( dvarKeys[i], level.serverDvars[dvarKeys[i]] );
		wait 0.05;
	}
}

get_config( dataName )
{
	dataValue = self getStat( int( tableLookup( "promod/customStatsTable.csv", 1, dataName, 0 ) ) );
	dataString = tablelookup( "promod/customStatsTable.csv", 0, dataValue, 1 );

	return dataString;
}