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

	if(unit == 'player' and GetXPExhaustion() and GetXPExhaustion() > 0) then
		GameTooltip:AddLine(format('|cff0090ffRested: +%d (%.1f%%)', GetXPExhaustion(), GetXPExhaustion() / max * 100))
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

local function Update(self)
	local bar, unit = self.Experience, self.unit
	local min, max = getXP(unit)
	bar:SetMinMaxValues(0, max)
	bar:SetValue(min)

	if(bar.Text) then
		if(bar.OverrideText) then
			bar:OverrideText(unit, min, max)
		else
			bar.Text:SetFormattedText('%d / %d', min, max)
		end
	end

	if(bar.Rested and unit == 'player') then
		if(GetXPExhaustion() and GetXPExhaustion() > 0) then
			bar.Rested:SetMinMaxValues(0, max)
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

local function LevelCheck(self)
	if(UnitLevel(self.unit) == MAX_PLAYER_LEVEL) then
		return self:DisableElement('Experience')
	else
		Update(self)
	end

	if(self.unit == 'pet') then
		if(UnitLevel(self.unit) == UnitLevel('player')) then
			self.Experience:Hide()
		else
			self.Experience:Show()
		end
	end
end

local function PetCheck(self, event, unit)
	if(unit == 'player') then
		LevelCheck(self)
	end
end

local function Enable(self, unit)
	local bar = self.Experience
	if(bar) then
		if(not bar:GetStatusBarTexture()) then
			bar:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
		end

		if(unit == 'player') then
			if(UnitLevel(unit) ~= MAX_PLAYER_LEVEL) then
				self:RegisterEvent('PLAYER_XP_UPDATE', Update)
				self:RegisterEvent('PLAYER_LEVEL_UP', LevelCheck)

				if(bar.Rested) then
					self:RegisterEvent('UPDATE_EXHAUSTION', Update)
				end
			else
				bar:Hide()

				if(bar.Rested) then
					bar.Rested:Hide()
				end
			end
		elseif(unit == 'pet') then
			if(select(2, UnitClass('player')) == 'HUNTER') then
				if(UnitLevel(unit) ~= MAX_PLAYER_LEVEL) then
					self:RegisterEvent('UNIT_PET_EXPERIENCE', LevelCheck)
					self:RegisterEvent('UNIT_PET', PetCheck)
				else
					bar:Hide()
				end
			else
				bar:Hide()
			end
		end

		if(bar.MouseOver or bar.Tooltip) then
			bar:EnableMouse()
		end

		if(bar.MouseOver and bar.Tooltip) then
			bar:SetAlpha(0)
			bar:SetScript('OnLeave', function() bar:SetAlpha(0); GameTooltip:Hide() end)
		elseif(bar.MouseOver and not bar.Tooltip) then
			bar:SetAlpha(0)
			bar:SetScript('OnEnter', function() bar:SetAlpha(1) end)
			bar:SetScript('OnLeave', function() bar:SetAlpha(0) end)
		elseif(not bar.MouseOver and bar.Tooltip) then
			bar:SetScript('OnLeave', function() GameTooltip:Hide() end)
		end

		return true
	end
end

local function Disable(self, unit)
	local bar = self.Experience
	if(bar) then
		if(unit == 'player') then
			self:UnregisterEvent('PLAYER_XP_UPDATE', Update)
			bar:Hide()

			if(bar.Rested) then
				self:UnregisterEvent('UPDATE_EXHAUSTION', Update)
				bar:Hide()
			end
		elseif(unit == 'pet') then
			self:UnregisterEvent('UNIT_PET_EXPERIENCE', Update)
			bar:Hide()
		end
	end
end

oUF:AddElement('Experience', Update, Enable, Disable)