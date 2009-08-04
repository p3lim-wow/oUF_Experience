--[[

	Elements handled:
	 .Experience [statusbar]
	 .Experience.Text [fontstring] (optional)
	 .Experience.Rested [statusbar] (optional)

	Booleans:
	 - Tooltip

	Functions that can be overridden from within a layout:
	 - PostUpdate(self, event, unit, bar, min, max)
	 - OverrideText(bar, unit, min, max)

--]]

local function tooltip(self, unit, min, max)
	local bars = unit == 'pet' and 6 or 20

	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 5, -5)
	GameTooltip:AddLine(format('XP: %d / %d (%d%% - %d bars)', min, max, min / max * 100), bars)
	GameTooltip:AddLine(format('Left: %d (%d%% - %d bars)', max - min, (max - min) / max * 100, bars * (max - min) / max))

	if(self.exhaustion) then
		GameTooltip:AddLine(format('|cff0090ffRested: +%d (%d%%)', self.exhaustion, self.exhaustion / max * 100))
	end

	GameTooltip:Show()
end

local function xp(unit)
	if(unit == 'pet') then
		return GetPetExperience()
	else
		return UnitXP(unit), UnitXPMax(unit)
	end
end

local function update(self)
	local bar, unit = self.Experience, self.unit
	local min, max = xp(unit)
	bar:SetMinMaxValues(0, max)
	bar:SetValue(min)

	if(bar.Text) then
		if(bar.OverrideText) then
			bar:OverrideText(unit, min, max)
		else
			bar.Text:SetFormattedText('%d / %d', min, max)
		end
	end

	if(bar.Rested) then
		local exhaustion = GetXPExhaustion()

		if(unit == 'player' and exhaustion and exhaustion > 0) then
			bar.Rested:SetMinMaxValues(0, max)
			bar.Rested:SetValue(math.min(min + exhaustion, max))
			bar.exhaustion = exhaustion
		else
			bar.Rested:SetMinMaxValues(0, 1)
			bar.Rested:SetValue(0)
			bar.exhaustion = nil
		end
	end

	if(bar.Tooltip) then
		bar:SetScript('OnEnter', function()
			tooltip(bar, unit, min, max)
		end)
	end

	if(bar.PostUpdate) then
		bar.PostUpdate(self, event, unit, bar, min, max)
	end
end

local function argChecks(self, event, unit, ...)
	if(self.unit == 'player') then
		if(IsXPUserDisabled()) then
			self:DisableElement('Experience')
			self:RegisterEvent('ENABLE_XP_GAIN', argChecks)
		elseif(UnitLevel('player') == MAX_PLAYER_LEVEL) then
			self:DisableElement('Experience')
		else
			update(self)
		end
	elseif(self.unit == 'pet') then
		if(UnitLevel('pet') ~= UnitLevel('player')) then
			self.Experience:Show()
			update(self)
		else
			self.Experience:Hide()
		end
	end
end

local function loadPet(self, event, unit)
	if(unit == 'player') then
		argChecks(self)
	end
end

local function enable(self, unit)
	local bar = self.Experience
	if(bar) then
		if(not bar:GetStatusBarTexture()) then
			bar:SetStatusBarTexture()
		end

		if(unit == 'player') then
			self:RegisterEvent('PLAYER_XP_UPDATE', argChecks)
			self:RegisterEvent('PLAYER_LEVEL_UP', argChecks)

			if(bar.Rested) then
				self:RegisterEvent('UPDATE_EXHAUSTION', argChecks)
			end
		elseif(unit == 'pet') then
			if(select(2, UnitClass('player')) == 'HUNTER') then
				self:RegisterEvent('UNIT_PET_EXPERIENCE', argChecks)
				self:RegisterEvent('UNIT_PET', loadPet)
			end
		end

		if(bar.Tooltip) then
			bar:EnableMouse()
			bar:SetScript('OnLeave', GameTooltip_Hide)
		end
	end
end

local function disable(self, unit)
	local bar = self.Experience
	if(bar) then
		if(unit == 'player')
			self:UnregisterEvent('PLAYER_XP_UPDATE', argChecks)
			self:UnregisterEvent('PLAYER_LEVEL_UP', argChecks)
			bar:Hide()

			if(bar.Rested) then
				self:UnregisterEvent('UPDATE_EXHAUSTION', argChecks)
				bar.Rested:Hide()
			end
		elseif(unit == 'pet') then
			self:UnregisterEvent('UNIT_PET_EXPERIENCE', argChecks)
			self:UnregisterEvent('UNIT_PET', loadPet)
			bar:Hide()
		end
	end
end

oUF:AddElement('Experience', update, enable, disable)