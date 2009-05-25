--[[

	Elements handled:
	 .Experience [statusbar]
	 .Experience.Text [fontstring] (optional)
	 .Experience.Rested [statusbar] (optional)

	Shared:
	 - MouseOver [boolean]
	 - Tooltip [boolean]

	Functions that can be overridden from within a layout:
	 - :PostUpdate(event, unit, bar, min, max)
	 - :OverrideText(unit, min, max)
	 - :OverrideTooltip(unit, min, max, bars)

--]]

local function showTooltip(self, unit, min, max, bars)
	if(self.MouseOver) then
		self:SetAlpha(1)
	end

	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 5, -5)
	GameTooltip:AddLine(format('XP: %d/%d (%.1f%%)', min, max, min / max * 100))
	GameTooltip:AddLine(format('%d needed (%.1f%% - %.1f bars)', max - min, (max - min) / max * 100, bars * (max - min) / max))

	local rested = GetXPExhaustion()
	if(unit == 'player' and rested > 0) then
		GameTooltip:AddLine(format('|cff0090ffRested: +%d (%.1f%%)', rested, rested / max * 100))
	end

	GameTooltip:Show()
end

local function getXP(unit)
	if(unit == 'pet') then
		return GetPetExperience()
	else
		return UnitXP(unit), UnitXPMax(unit)
	end
end

local function Update(self, event)
	local bar, unit = self.Experience, self.unit

	if(unit == 'pet' and UnitLevel('pet') == UnitLevel('player')) then
		bar:Hide()
	else
		bar:Show()
	end

	local min, max = getXP(unit)
	bar:SetMinMaxValues(math.min(0, min), max)
	bar:SetValue(min)

	if(bar.Text) then
		if(bar.OverrideText) then
			bar:OverrideText(unit, min, max)
		else
			bar.Text:SetFormattedText('%d / %d', min, max)
		end
	end

	if(bar.Rested and unit == 'player') then
		if(GetXPExhaustion() > 0) then
			bar.Rested:SetMinMaxValues(min, max)
			bar.Rested:SetValue(math.min(min + GetXPExhaustion(), max))
		else
			bar.Rested:SetMinMaxValues(0, 1)
			bar.Rested:SetValue(0)
		end
	elseif(bar.Rested and unit ~= 'player') then
		bar.Rested:SetMinMaxValues(0, 1)
		bar.Rested:SetValue(0)
	end

	if(bar.PostUpdate) then
		bar.PostUpdate(self, event, unit, bar, min, max)
	end

	if(bar.Tooltip) then
		bar:SetScript('OnEnter', function()
			return (bar.OverrideTooltip or showTooltip) (bar, unit, min, max, unit == 'pet' and 6 or 20)
		end)
	end
end

local function UpdateLevel(self, event)
	if(UnitLevel('player') == MAX_PLAYER_LEVEL) then
		self:DisableElement('Experience')
	else
		Update(self, event)
	end
end

local function Enable(self, unit)
	local xp = self.Experience
	if(xp) then
		if(not xp:GetStatusBarTexture()) then
			xp:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
		end

		if(unit == 'player' and UnitLevel('player') ~= MAX_PLAYER_LEVEL) then
			self:RegisterEvent('PLAYER_XP_UPDATE', Update)
			self:RegisterEvent('PLAYER_LEVEL_UP', UpdateLevel)

			if(xp.Rested) then
				self:RegisterEvent('UPDATE_EXHAUSTION', Update)
			end
		elseif(unit == 'pet' and select(2, UnitClass('player')) == 'HUNTER' and UnitLevel('pet') ~= MAX_PLAYER_LEVEL) then -- only called once so select is "ok"
			self:RegisterEvent('UNIT_PET_EXPERIENCE', Update)
		end

		if(xp.MouseOver or xp.Tooltip) then
			xp:EnableMouse()
		end

		if(xp.MouseOver and xp.Tooltip) then
			xp:SetAlpha(0)
			xp:SetScript('OnLeave', function() xp:SetAlpha(0); GameTooltip:Hide() end)
		elseif(xp.MouseOver and not xp.Tooltip) then
			xp:SetAlpha(0)
			xp:SetScript('OnEnter', function() xp:SetAlpha(1) end)
			xp:SetScript('OnLeave', function() xp:SetAlpha(0) end)
		elseif(not xp.MouseOver and xp.Tooltip) then
			xp:SetScript('OnLeave', function() GameTooltip:Hide() end)
		end

		return true
	end	
end

local function Disable(self, unit)
	local xp = self.Experience
	if(xp) then
		xp:Hide()

		if(unit == 'player') then
			self:UnregisterEvent('PLAYER_XP_UPDATE', Update)
			self:UnregisterEvent('PLAYER_LEVEL_UP', UpdateLevel)

			if(xp.Rested) then
				self:UnregisterEvent('UPDATE_EXHAUSTION', Update)
				xp.Rested:Hide()
			end
		elseif(unit == 'pet') then
			self:UnregisterEvent('UNIT_PET_EXPERIENCE', Update)
		end
	end
end

oUF:AddElement('Experience', Update, Enable, Disable)