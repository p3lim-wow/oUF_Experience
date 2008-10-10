--[[

	Elements handled:
	 .Experience [statusbar]
	 .Experience.Text [fontstring]

	Shared:
	 - colorReputation [table] - will use blizzard colors if not set
	 - colorExperience [table] - will use a green color if not set
	 - Tooltip [boolean]
	 - MouseOver [boolean]

--]]
local _, class = UnitClass('player')

local function PlayerXPTip(self, min, max)
	GameTooltip:SetOwner(self, 'TOPLEFT', 5, -5)
	if(GetXPExhaustion()) then
		GameTooltip:AddLine(format('|cffffffffRested XP remaining:|r %s', GetXPExhaustion()))
		GameTooltip:AddLine(' ')
	end
	GameTooltip:AddLine(format('|cffffffffRemaining XP to go:|r %s', floor(max - min)))
	GameTooltip:AddLine(format('|cffffffffPercentage through:|r %s%%', floor(min / max * 100)))
	GameTooltip:AddLine(format('|cffffffffPercentage to go:|r %s%%', floor((max - min) / max * 100)))
	GameTooltip:AddLine(format('|cffffffffBars through:|r %s', floor(min / max * 20)))
	GameTooltip:AddLine(format('|cffffffffBars to go:|r %s', floor((max - min) / max * 20)))
	GameTooltip:Show()
end

local function PlayerRepTip(self, name, id, min, max, value)
	GameTooltip:SetOwner(self, 'TOPLEFT', 5, -5)
	GameTooltip:AddLine(format('|cffffffffWatched Faction:|r %s', name))
	GameTooltip:AddLine(format('|cffffffffRemaining Reputation to go:|r %s', floor(max - value)))
	GameTooltip:AddLine(format('|cffffffffPercentage to go:|r %s%%', floor((max - value) / (max-min) * 100)))
	GameTooltip:AddLine(format('|cffffffffCurrent Standing:|r %s', _G['FACTION_STANDING_LABEL'..id]))
	GameTooltip:Show()
end

local function PetTip(self, min, max)
	GameTooltip:SetOwner(self, 'TOPLEFT', 5, -5)
	GameTooltip:AddLine(format('|cffffffffRemaining XP to go:|r %s', floor(max - min)))
	GameTooltip:AddLine(format('|cffffffffPercentage through:|r %s%%', floor(min / max * 100)))
	GameTooltip:AddLine(format('|cffffffffPercentage to go:|r %s%%', floor((max - min) / max * 100)))
	GameTooltip:AddLine(format('|cffffffffBars through:|r %s', floor(min / max * 20)))
	GameTooltip:AddLine(format('|cffffffffBars to go:|r %s', floor((max - min) / max * 20)))
	GameTooltip:Show()
end

function oUF:PLAYER_XP_UPDATE(event, unit)
	if(self.unit == 'player') then
		local bar = self.Experience
		if(GetWatchedFactionInfo()) then
			local name, id, min, max, value = GetWatchedFactionInfo()
			bar:SetMinMaxValues(min, max)
			bar:SetValue(value)
			bar:SetStatusBarColor(unpack(self.colorReputation or { FACTION_BAR_COLORS[id].r, FACTION_BAR_COLORS[id].g, FACTION_BAR_COLORS[id].b}))
			if(not bar.MouseOver) then
				bar:SetAlpha(1)
			end

			if(bar.Text) then
				bar.Text:SetFormattedText('%d / %d - %s', value - min, max - min, name)
			end

			if(bar.Tooltip and bar.MouseOver) then
				bar:EnableMouse()
				bar:SetScript('OnEnter', function() bar:SetAlpha(1); PlayerRepTip(bar, name, id, min, max, value) end)
				bar:SetScript('OnLeave', function() bar:SetAlpha(0); GameTooltip:Hide() end)
			elseif(bar.Tooltip and not bar.MouseOver) then
				bar:EnableMouse()
				bar:SetScript('OnEnter', function() PlayerXPTip(bar, name, id, min, max, value) end)
				bar:SetScript('OnLeave', function() GameTooltip:Hide() end)
			elseif(bar.MouseOver and not bar.Tooltip) then
				bar:EnableMouse()
				bar:SetScript('OnEnter', function() bar:SetAlpha(1) end)
				bar:SetScript('OnLeave', function() bar:SetAlpha(0) end)
			end
		elseif(UnitLevel('player') ~= MAX_PLAYER_LEVEL) then
			local min, max = UnitXP('player'), UnitXPMax('player')
			bar:SetMinMaxValues(0, max)
			bar:SetValue(min)
			bar:SetStatusBarColor(unpack(self.colorExperience or self.colors.health))
			if(not bar.MouseOver) then
				bar:SetAlpha(1)
			end

			if(bar.Text) then
				bar.Text:SetFormattedText('%d / %d', min, max)
			end

			if(bar.Tooltip and bar.MouseOver) then
				bar:EnableMouse()
				bar:SetScript('OnEnter', function() bar:SetAlpha(1); PlayerXPTip(bar, min, max) end)
				bar:SetScript('OnLeave', function() bar:SetAlpha(0); GameTooltip:Hide() end)
			elseif(bar.Tooltip and not bar.MouseOver) then
				bar:EnableMouse()
				bar:SetScript('OnEnter', function() PlayerXPTip(bar, min, max) end)
				bar:SetScript('OnLeave', function() GameTooltip:Hide() end)
			elseif(bar.MouseOver and not bar.Tooltip) then
				bar:EnableMouse()
				bar:SetScript('OnEnter', function() bar:SetAlpha(1) end)
				bar:SetScript('OnLeave', function() bar:SetAlpha(0) end)
			end
		else
			bar:SetAlpha(0)
		end
	end
end

function oUF:UNIT_PET_EXPERIENCE(event, unit)
	if(self.unit == 'pet') then
		local bar = self.Experience
		if(UnitLevel('pet') ~= UnitLevel('player') and class == 'HUNTER') then
			local min, max = GetPetExperience()
			bar:SetMinMaxValues(0, max)
			bar:SetValue(min)
			bar:SetStatusBarColor(unpack(self.colorExperience or self.colors.health))
			if(not bar.MouseOver) then
				bar:SetAlpha(1)
			end

			if(bar.Text) then
				bar.Text:SetFormattedText('%d / %d', min, max)
			end

			if(bar.Tooltip and bar.MouseOver) then
				bar:EnableMouse()
				bar:SetScript('OnEnter', function() bar:SetAlpha(1); PlayerXPTip(bar, min, max) end)
				bar:SetScript('OnLeave', function() bar:SetAlpha(0); GameTooltip:Hide() end)
			elseif(bar.Tooltip and not bar.MouseOver) then
				bar:EnableMouse()
				bar:SetScript('OnEnter', function() PlayerXPTip(bar, min, max) end)
				bar:SetScript('OnLeave', function() GameTooltip:Hide() end)
			elseif(bar.MouseOver and not bar.Tooltip) then
				bar:EnableMouse()
				bar:SetScript('OnEnter', function() bar:SetAlpha(1) end)
				bar:SetScript('OnLeave', function() bar:SetAlpha(0) end)
			end
		else
			bar:SetAlpha(0)
		end
	end
end

oUF:RegisterInitCallback(function(self)
	local experience = self.Experience
	if(experience) then
		self:RegisterEvent('PLAYER_XP_UPDATE')
		self:RegisterEvent('UNIT_PET_EXPERIENCE')
		self:RegisterEvent('UPDATE_FACTION')
		self.UPDATE_FACTION = self.PLAYER_XP_UPDATE

		if(not experience:GetStatusBarTexture()) then
			experience:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
		end

		if(experience.MouseOver) then
			experience:SetAlpha(0)
		end
	end
end)

oUF:RegisterSubTypeMapping('PLAYER_XP_UPDATE')
oUF:RegisterSubTypeMapping('UNIT_PET_EXPERIENCE')
oUF:RegisterSubTypeMapping('UPDATE_FACTION')