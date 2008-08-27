local function UpdateElement(self, bar)
	local min, max = UnitXP('player'), UnitXPMax('player')
	bar:SetMinMaxValues(0, max)
	bar:SetValue(min)
	bar:SetFrameLevel(3)

	if(bar.rested) then
		local rested = GetXPExhaustion() or 0
		bar.rested:SetMinMaxValues(0, max)
		bar.rested:SetValue(rested)
		bar.rested:SetFrameLevel(2)
	end

	if(bar.text) then
		bar.text:SetFormattedText('%s / %s', min, max)
	end
end

function oUF:PLAYER_XP_UPDATE()
	if(self.Experience) then
		UpdateElement(self, self.Experience)
	end
end

oUF:RegisterSubTypeMapping('PLAYER_XP_UPDATE')
oUF:RegisterInitCallback(function(self)
	if(self.Experience) then
		if(UnitLevel('player') < 70) then
			self:RegisterEvent('PLAYER_XP_UPDATE')
			self:RegisterEvent('PLAYER_LEVEL_UP')
			self:RegisterEvent('UPDATE_EXHAUSTION')

			self.PLAYER_LEVEL_UP = self.PLAYER_XP_UPDATE
			self.UPDATE_EXHAUSTION = self.PLAYER_XP_UPDATE

			UpdateElement(self, self.Experience)
		else
			self.Experience:Hide()
			if(self.Experience.rested) then
				self.Experience.rested:Hide()
			end
		end
	end
end)