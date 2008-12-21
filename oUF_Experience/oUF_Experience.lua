--[[

	Elements handled:
	 .Experience [statusbar]
	 .Experience.Text [fontstring] (optional)

	Shared:
	 - Color [table] - will use oUF.colors.health if not set
	 - Tooltip [boolean]
	 - MouseOver [boolean]

--]]
local localized, english = UnitClass('player')

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
	
	if(event == 'UNIT_PET' and self.unit ~= 'player') then
		return
	elseif(self.unit == 'player' and UnitLevel('player') == MAX_PLAYER_LEVEL) then
		bar:SetAlpha(0)
	elseif(self.unit == 'pet' and (UnitLevel('pet') == UnitLevel('player') and english ~= 'HUNTER')) then
		bar:SetAlpha(0)
	else
		local min, max
		if(self.unit == 'pet' and not bar.RepOnly) then
			min, max = GetPetExperience()
		elseif(self.unit == 'player' and not bar.RepOnly) then
			min, max = UnitXP(self.unit), UnitXPMax(self.unit)
		end

		bar:SetMinMaxValues(0, max)
		bar:SetValue(min)
		bar:EnableMouse()
		bar:SetStatusBarColor(unpack(self.Color or self.colors.health))

		if(not bar.MouseOver) then
			bar:SetAlpha(1)
		end

		if(bar.Text) then
			bar.Text:SetFormattedText('%d / %d', min, max)
		end

		if(bar.Tooltip and bar.MouseOver) then
			bar:SetScript('OnEnter', function() bar:SetAlpha(1); Tooltip(bar, unit, min, max) end)
			bar:SetScript('OnLeave', function() bar:SetAlpha(0); GameTooltip:Hide() end)
		elseif(bar.Tooltip and not bar.MouseOver) then
			bar:SetScript('OnEnter', function() Tooltip(bar, unit, min, max) end)
			bar:SetScript('OnLeave', function() GameTooltip:Hide() end)
		elseif(bar.MouseOver and not bar.Tooltip) then
			bar:SetScript('OnEnter', function() bar:SetAlpha(1) end)
			bar:SetScript('OnLeave', function() bar:SetAlpha(0) end)
		end
	end
end

local function Enable(self)
	local experience = self.Experience
	if(experience) then
		self:RegisterEvent('PLAYER_XP_UPDATE', Update)
		self:RegisterEvent('UNIT_PET_EXPERIENCE', Update)
		self:RegisterEvent('UNIT_PET', Update)

		if(not experience:GetStatusBarTexture()) then
			experience:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
		end

		if(experience.MouseOver) then
			experience:SetAlpha(0)
		end

		return true
	end
end

local function Disable(self)
	local experience = self.Experience
	if(experience) then
		self:UnregisterEvent('PLAYER_XP_UPDATE', Update)
		self:UnregisterEvent('UNIT_PET_EXPERIENCE', Update)
		self:UnregisterEvent('UNIT_PET', Update)
	end
end

oUF:AddElement('Experience', Update, Enable, Disable)