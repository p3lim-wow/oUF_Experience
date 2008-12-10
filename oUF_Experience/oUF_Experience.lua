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
local localized, english = UnitClass('player')
local _format = string.format

local function PlayerXPTip(self, min, max)
	local rested = GetXPExhaustion()
	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 5, -5)
	GameTooltip:AddLine(_format('XP: %d/%d (%.1f%%)', min, max, min/max*100))
	GameTooltip:AddLine(_format('%d needed (%.1f%% - %.1f bars)', max-min, (max-min)/max*100,(max-min)/max*20))
	if(rested) then
		GameTooltip:AddLine(_format('|cff0090ffRested: +%d (%.1f%%)', rested, rested/max*100))
	end
	GameTooltip:Show()
end

local function PlayerRepTip(self, name, id, min, max)
	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 5, -5)
	GameTooltip:AddLine(_format('%s (%s)', name, _G['FACTION_STANDING_LABEL'..id]))
	GameTooltip:AddLine(_format('%d/%d (%.1f%%)', min, max, min/max*100))
	GameTooltip:Show()
end

local function PetTip(self, min, max)
	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 5, -5)
	GameTooltip:AddLine(_format('XP: %d/%d (%.1f%%)', min, max, min/max*100))
	GameTooltip:AddLine(_format('%d needed (%.1f%% - %.1f bars)', max-min, (max-min)/max*100,(max-min)/max*20))
	GameTooltip:Show()
end

function oUF:PLAYER_XP_UPDATE(event, unit)
	if(self.unit == 'player') then
		local bar = self.Experience
		
		if(GetWatchedFactionInfo()) then
			local name, id, min, max, value = GetWatchedFactionInfo()
			bar:SetMinMaxValues(min, max)
			bar:SetValue(value)
			bar:EnableMouse()
			bar:SetStatusBarColor(unpack(self.colorReputation or {FACTION_BAR_COLORS[id].r, FACTION_BAR_COLORS[id].g, FACTION_BAR_COLORS[id].b}))

			if(not bar.MouseOver) then
				bar:SetAlpha(1)
			end

			if(bar.Text) then
				bar.Text:SetFormattedText('%d / %d - %s', value - min, max - min, name)
			end

			if(bar.Tooltip and bar.MouseOver) then
				bar:SetScript('OnEnter', function() bar:SetAlpha(1); PlayerRepTip(bar, name, id, value - min, max - min) end)
				bar:SetScript('OnLeave', function() bar:SetAlpha(0); GameTooltip:Hide() end)
			elseif(bar.Tooltip and not bar.MouseOver) then
				bar:SetScript('OnEnter', function() PlayerRepTip(bar, name, id, value - min, max - min) end)
				bar:SetScript('OnLeave', function() GameTooltip:Hide() end)
			elseif(bar.MouseOver and not bar.Tooltip) then
				bar:SetScript('OnEnter', function() bar:SetAlpha(1) end)
				bar:SetScript('OnLeave', function() bar:SetAlpha(0) end)
			end
		elseif(UnitLevel('player') ~= MAX_PLAYER_LEVEL) then
			local min, max = UnitXP('player'), UnitXPMax('player')
			bar:SetMinMaxValues(0, max)
			bar:SetValue(min)
			bar:EnableMouse()
			bar:SetStatusBarColor(unpack(self.colorExperience or self.colors.health))

			if(not bar.MouseOver) then
				bar:SetAlpha(1)
			end

			if(bar.Text) then
				bar.Text:SetFormattedText('%d / %d', min, max)
			end

			if(bar.Tooltip and bar.MouseOver) then
				bar:SetScript('OnEnter', function() bar:SetAlpha(1); PlayerXPTip(bar, min, max) end)
				bar:SetScript('OnLeave', function() bar:SetAlpha(0); GameTooltip:Hide() end)
			elseif(bar.Tooltip and not bar.MouseOver) then
				bar:SetScript('OnEnter', function() PlayerXPTip(bar, min, max) end)
				bar:SetScript('OnLeave', function() GameTooltip:Hide() end)
			elseif(bar.MouseOver and not bar.Tooltip) then
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
		if(UnitLevel('pet') ~= UnitLevel('player') and english == 'HUNTER') then
			local min, max = GetPetExperience()
			bar:SetMinMaxValues(0, max)
			bar:SetValue(min)
			bar:EnableMouse()
			bar:SetStatusBarColor(unpack(self.colorExperience or self.colors.health))

			if(not bar.MouseOver) then
				bar:SetAlpha(1)
			end

			if(bar.Text) then
				bar.Text:SetFormattedText('%d / %d', min, max)
			end

			if(bar.Tooltip and bar.MouseOver) then
				bar:SetScript('OnEnter', function() bar:SetAlpha(1); PetTip(bar, min, max) end)
				bar:SetScript('OnLeave', function() bar:SetAlpha(0); GameTooltip:Hide() end)
			elseif(bar.Tooltip and not bar.MouseOver) then
				bar:SetScript('OnEnter', function() PetTip(bar, min, max) end)
				bar:SetScript('OnLeave', function() GameTooltip:Hide() end)
			elseif(bar.MouseOver and not bar.Tooltip) then
				bar:SetScript('OnEnter', function() bar:SetAlpha(1) end)
				bar:SetScript('OnLeave', function() bar:SetAlpha(0) end)
			end
		else
			bar:SetAlpha(0)
		end
	end
end

function oUF:UNIT_PET(event, unit)
	if(unit == 'player') then
		self.UNIT_PET_EXPERIENCE(self, event, unit)
	end
end

oUF:RegisterInitCallback(function(self)
	local experience = self.Experience
	if(experience) then
		self:RegisterEvent('PLAYER_XP_UPDATE')
		self:RegisterEvent('UNIT_PET_EXPERIENCE')
		self:RegisterEvent('UPDATE_FACTION')
		self:RegisterEvent('UNIT_PET')
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