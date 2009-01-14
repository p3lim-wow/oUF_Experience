--[[

	Elements handled:
	 .Experience [statusbar]
	 .Experience.Text [fontstring] (optional)

	Shared:
	 - MouseOver [boolean]
	 - Tooltip [boolean]

	Functions that can be overridden from within a layout:
	 - :PostUpdate(event, unit, bar, min, max)
	 - :OverrideText(min, max)

--]]
local function Tooltip(self, unit, min, max)
	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 5, -5)
	GameTooltip:AddLine(string.format('XP: %d/%d (%.1f%%)', min, max, min/max*100))
	GameTooltip:AddLine(string.format('%d needed (%.1f%% - %.1f bars)', max-min, (max-min)/max*100,(max-min)/max*20))

	if(unit == 'player' and GetXPExhaustion()) then
		GameTooltip:AddLine(string.format('|cff0090ffRested: +%d (%.1f%%)', GetXPExhaustion(), GetXPExhaustion()/max*100))
	end

	GameTooltip:Show()
end

local function Update(self, event, unit)
	local bar = self.Experience
	local min, max

	if(self.unit == 'player' and (UnitLevel(self.unit) ~= MAX_PLAYER_LEVEL) or self.unit == 'pet' and (UnitLevel(self.unit) ~= UnitLevel('player'))) then
		if(self.unit == 'pet') then
			min, max = GetPetExperience()
		elseif(self.unit == 'player') then
			min, max = UnitXP(self.unit), UnitXPMax(self.unit)
		end

		bar:SetMinMaxValues(0, max)
		bar:SetValue(min)
		bar:EnableMouse()
		bar:Show()

		if(bar.Text) then
			if(bar.OverrideText) then
				bar:OverrideText(min, max)
			else
				bar.Text:SetFormattedText('%d / %d', min, max)
			end
		end

		if(bar.Tooltip and bar.MouseOver) then
			bar:SetScript('OnEnter', function() bar:SetAlpha(1); Tooltip(bar, self.unit, min, max) end)
		elseif(bar.Tooltip and not bar.MouseOver) then
			bar:SetScript('OnEnter', function() Tooltip(bar, self.unit, min, max) end)
		end

		if(bar.PostUpdate) then bar.PostUpdate(self, event, unit, bar, min, max) end
	else
		bar:Hide()
	end
end

local function Enable(self)
	local experience = self.Experience
	if(experience) then
		self:RegisterEvent('PLAYER_XP_UPDATE', Update)
		self:RegisterEvent('UNIT_PET_EXPERIENCE', Update)

		if(not experience:GetStatusBarTexture()) then
			experience:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
		end

		if(experience.Tooltip and experience.MouseOver) then
			experience:SetAlpha(0)
			experience:SetScript('OnLeave', function(self) self:SetAlpha(0); GameTooltip:Hide() end)
		elseif(experience.MouseOver and not experience.Tooltip) then
			experience:SetAlpha(0)
			experience:SetScript('OnEnter', function(self) self:SetAlpha(1) end)
			experience:SetScript('OnLeave', function(self) self:SetAlpha(0) end)
		elseif(experience.Tooltip and not experience.MouseOver) then
			experience:SetScript('OnLeave', function() GameTooltip:Hide() end)
		end

		return true
	end
end

local function Disable(self)
	if(self.Experience) then
		self:UnregisterEvent('PLAYER_XP_UPDATE', Update)
		self:UnregisterEvent('UNIT_PET_EXPERIENCE', Update)
	end
end

oUF:AddElement('Experience', Update, Enable, Disable)