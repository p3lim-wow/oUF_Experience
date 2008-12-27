--[[

	Elements handled:
	 .Experience [statusbar]
	 .Experience.Text [fontstring] (optional)

	Shared:
	 - Colors [table] - will use oUF.colors.health if not set
	 - Tooltip [boolean]
	 - MouseOver [boolean]

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
	if(self.unit ~= unit) then return end
	local bar = self.Experience
	
	if(self.unit == 'pet' and UnitLevel('pet') == UnitLevel('player')) then
		bar:SetAlpha(0)
	elseif(self.unit == 'player' and UnitLevel('player') == MAX_PLAYER_LEVEL) then
		bar:SetAlpha(0)
	else
		local min, max
		if(self.unit == 'pet') then
			min, max = GetPetExperience()
		elseif(self.unit == 'player') then
			min, max = UnitXP('player'), UnitXPMax('player')
		end

		bar:SetMinMaxValues(0, max)
		bar:SetValue(min)
		bar:EnableMouse()
		bar:SetStatusBarColor(unpack(bar.Colors or self.colors.health))

		if(not bar.MouseOver) then
			bar:SetAlpha(1)
		end

		if(bar.Text) then
			bar.Text:SetFormattedText('%d / %d', min, max)
		end

		if(bar.Tooltip and bar.MouseOver) then
			bar:SetScript('OnEnter', function() bar:SetAlpha(1); Tooltip(bar, self.unit, min, max) end)
			bar:SetScript('OnLeave', function() bar:SetAlpha(0); GameTooltip:Hide() end)
		elseif(bar.Tooltip and not bar.MouseOver) then
			bar:SetScript('OnEnter', function() Tooltip(bar, self.unit, min, max) end)
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
	if(self.Experience) then
		self:UnregisterEvent('PLAYER_XP_UPDATE', Update)
		self:UnregisterEvent('UNIT_PET_EXPERIENCE', Update)
		self:UnregisterEvent('UNIT_PET', Update)
	end
end

oUF:AddElement('Experience', Update, Enable, Disable)