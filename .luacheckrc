std = 'lua51'

quiet = 1 -- suppress report output for files without warnings

-- see https://luacheck.readthedocs.io/en/stable/warnings.html#list-of-warnings
-- and https://luacheck.readthedocs.io/en/stable/cli.html#patterns
ignore = {
	'212/self', -- unused argument self
	'212/event', -- unused argument event
	'212/unit', -- unused argument unit
	'212/element', -- unused argument element
	'312/event', -- unused value of argument event
	'312/unit', -- unused value of argument unit
	'431', -- shadowing an upvalue
	'614', -- trailing whitespace in comment (we use this for docs)
	'631', -- line is too long
}

globals = {
	'oUF',
	'_TAGS', -- part of oUF's tag env, not really exposed
}

read_globals = {
	-- FrameXML objects
	'GameTooltip',

	-- FrameXML functions
	'IsWatchingHonorAsXP',

	-- GlobalStrings
	'COMBAT_XP_GAIN',
	'HONOR_LEVEL_LABEL',
	'TUTORIAL_TITLE26',

	-- namespaces
	'C_PvP',

	-- API
	'BreakUpLargeNumbers',
	'GetMaxLevelForPlayerExpansion',
	'GetRestrictedAccountData',
	'GetXPExhaustion',
	'IsInActiveWorldPVP',
	'IsXPUserDisabled',
	'UnitHasVehicleUI',
	'UnitHonor',
	'UnitHonorLevel',
	'UnitHonorMax',
	'UnitLevel',
	'UnitXP',
	'UnitXPMax',
	'hooksecurefunc',
}
