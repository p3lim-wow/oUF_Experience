local function CreatePlayerTooltip(self)
	local min, max = UnitXP('player'), UnitXPMax('player')

	GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
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

local function UpdateElement(self, event, unit, bar)
	if(unit == 'player') then
		local min, max = UnitXP('player'), UnitXPMax('player')
		bar:SetMinMaxValues(0, max)
		bar:SetValue(min)

		if(bar.rested) then
			local rested = GetXPExhaustion() or 0
			bar.rested:SetMinMaxValues(0, max)
			bar.rested:SetValue(rested + min)
			bar.rested:SetFrameLevel(2)
			bar:SetFrameLevel(3)
		end

		if(bar.text) then
			bar.text:SetFormattedText('%s / %s', min, max)
		end

		if(bar.tooltip) then
			bar:EnableMouse()
			bar:SetScript('OnEnter', CreatePlayerTooltip)
			bar:SetScript('OnLeave', function() GameTooltip:Hide() end)
		end

		if(self.PostUpdateExperience) then self:PostUpdateExperience(event, unit, bar, min, max) end
	end
end

function oUF:PLAYER_XP_UPDATE(event, unit)
	if(self.Experience) then
		UpdateElement(self, event, unit, self.Experience)
	end
end

oUF:RegisterSubTypeMapping('PLAYER_XP_UPDATE')
oUF:RegisterInitCallback(function(self)
	if(self.Experience) then
		if(UnitLevel('player') == MAX_PLAYER_LEVEL) then
			self.Experience:Hide()
			if(self.Experience.rested) then
				self.Experience.rested:Hide()
			end
		else
			self:RegisterEvent('PLAYER_XP_UPDATE')
			self:RegisterEvent('PLAYER_LEVEL_UP')
			self:RegisterEvent('UPDATE_EXHAUSTION')

			self.PLAYER_LEVEL_UP = self.PLAYER_XP_UPDATE
			self.UPDATE_EXHAUSTION = self.PLAYER_XP_UPDATE
		end
	end
end)