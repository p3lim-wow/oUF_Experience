local function UpdateElement(self, bar)
	if(UnitLevel('player') < 70) then
		local min, max = UnitXP('player'), UnitXPMax('player')

		bar:SetMinMaxValues(0, max)
		bar:SetValue(min)

		if(bar.text) then
			bar.text:SetFormattedText('%s / %s', min, max)
		end
	else
		bar:Hide()
		self:UnregisterEvent('PLAYER_XP_UPDATE')
		self:UnregisterEvent('PLAYER_LEVEL_UP')
		self:UnregisterEvent('UPDATE_EXHAUSTION')
	end
end

function oUF:PLAYER_XP_UPDATE()
	if(self.Experience) then
		UpdateElement(self, self.Experience)
	end
end

oUF:RegisterInitCallback(function(self)
	if(self.Experience) then
		self:RegisterEvent('PLAYER_XP_UPDATE')
		self:RegisterEvent('PLAYER_LEVEL_UP')
		self:RegisterEvent('UPDATE_EXHAUSTION')

		self.PLAYER_LEVEL_UP = self.PLAYER_XP_UPDATE
		self.UPDATE_EXHAUSTION = self.PLAYER_XP_UPDATE
		-- force update at load
		UpdateElement(self, self.Experience)
	end
end)