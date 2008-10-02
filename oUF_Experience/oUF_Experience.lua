local _, class = UnitClass('player')

local function PlayerXPTip(self, min, max)
	GameTooltip:SetOwner(self, 'ANCHOR_CURSOR')
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

local function PlayerRepTip(self, name, standing, min, max, value)
	GameTooltip:SetOwner(self, 'ANCHOR_CURSOR')
	GameTooltip:AddLine(format('|cffffffffWatched Faction:|r %s', name))
	GameTooltip:AddLine(format('|cffffffffRemaining Reputation to go:|r %s', floor(max - value)))
	GameTooltip:AddLine(format('|cffffffffPercentage to go:|r %s%%', floor((max - value) / (max-min) * 100)))
	GameTooltip:AddLine(format('|cffffffffCurrent Standing:|r %s', _G['FACTION_STANDING_LABEL' .. standing]))
	GameTooltip:Show()
end

local function PetTip(self, min, max)
	GameTooltip:SetOwner(self, 'ANCHOR_CURSOR')
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
			local name, standing, min, max, value = GetWatchedFactionInfo()
			bar:SetMinMaxValues(min, max)
			bar:SetValue(value)

			if(bar.Text) then
				bar.Text:SetFormattedText('%d / %d - %s', value, max, name)
			end

			if(bar.Tooltip) then
				bar:EnableMouse()
				bar:SetScript('OnEnter', function() PlayerRepTip(bar, name, standing, min, max, value) end)
				bar:SetScript('OnLeave', function() GameTooltip:Hide() end)
			end
		else
			local min, max = UnitXP('player'), UnitXPMax('player')
			bar:SetMinMaxValues(0, max)
			bar:SetValue(min)
			bar:Show()

			if(bar.Text) then
				bar.Text:SetFormattedText('%d / %d', min, max)
			end

			if(bar.Tooltip) then
				bar:EnableMouse()
				bar:SetScript('OnEnter', function() PlayerXPTip(bar, min, max) end)
				bar:SetScript('OnLeave', function() GameTooltip:Hide() end)
			end
		end
	end
end

function oUF:UNIT_PET_EXPERIENCE(event, unit)
	if(self.unit == 'pet') then
		local bar = self.Experience
		local min, max = GetPetExperience()
		bar:SetMinMaxValues(0, max)
		bar:SetValue(min)
		bar:Show()

		if(bar.Text) then
			bar.Text:SetFormattedText('%d / %d', min, max)
		end

		if(bar.Tooltip) then
			bar:EnableMouse()
			bar:SetScript('OnEnter', function() PetTip(bar, min, max) end)
			bar:SetScript('OnLeave', function() GameTooltip:Hide() end)
		end
	end
end

oUF:RegisterInitCallback(function(self)
	local experience = self.Experience
	if(experience) then
		if(UnitLevel('pet') ~= MAX_PLAYER_LEVEL and class == 'HUNTER') then
			self:RegisterEvent('UNIT_PET_EXPERIENCE')
		else
			experience:Hide()
		end

		if(UnitLevel('player') ~= MAX_PLAYER_LEVEL) then
			self:RegisterEvent('PLAYER_XP_UPDATE')

			-- hook more events
			self:RegisterEvent('UPDATE_FACTION')
			self:RegisterEvent('UPDATE_EXHAUSTION')
			self:RegisterEvent('PLAYER_LEVEL_UP')
			self.UPDATE_FACTION = self.PLAYER_XP_UPDATE
			self.UPDATE_EXAUSTION = self.PLAYER_XP_UPDATE
			self.PLAYER_LEVEL_UP = self.PLAYER_XP_UPDATE
		else
			experience:Hide()
		end

		if(not experience:GetStatusBarTexture()) then
			experience:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
		end
	end
end)

oUF:RegisterSubTypeMapping('PLAYER_XP_UPDATE')
oUF:RegisterSubTypeMapping('UNIT_PET_EXPERIENCE')