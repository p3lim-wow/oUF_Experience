local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF Experience was unable to locate oUF install')

local function Unbeneficial(self, unit)
	if(unit == 'player') then
		if(UnitLevel(unit) == MAX_PLAYER_LEVEL) then
			return true
		end
	elseif(unit == 'pet') then
		local _, hunterPet = HasPetUI()
		if(not self.disallowVehicleSwap and UnitHasVehicleUI('player')) then
			return true
		elseif(not hunterPet or (UnitLevel(unit) == UnitLevel('player'))) then
			return true
		end
	end
end

local function Update(self, event, unit)
	if(self.unit ~= unit) then return end

	local experience = self.Experience
	if(experience.PreUpdate) then experience:PreUpdate(unit) end

	if(Unbeneficial(self, unit)) then
		return experience:Hide()
	else
		experience:Show()
	end

	local min, max
	if(unit == 'pet') then
		min, max = GetPetExperience()
	else
		min, max = UnitXP(unit), UnitXPMax(unit)
	end

	experience:SetMinMaxValues(0, max)
	experience:SetValue(min)

	if(experience.Rested) then
		local exhaustion = unit == 'player' and GetXPExhaustion() or 0
		experience.Rested:SetMinMaxValues(0, max)
		experience.Rested:SetValue(math.min(min + exhaustion, max))
	end

	if(experience.PostUpdate) then
		return experience:PostUpdate(unit, min, max)
	end
end

local function Path(self, ...)
	return (self.Experience.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local experience = self.Experience
	if(experience) then
		experience.__owner = self
		experience.ForceUpdate = ForceUpdate

		self:RegisterEvent('PLAYER_XP_UPDATE', Path)
		self:RegisterEvent('PLAYER_LEVEL_UP', Path)
		self:RegisterEvent('UNIT_PET_EXPERIENCE', Path)

		if(experience.Rested) then
			self:RegisterEvent('UPDATE_EXHAUSTION', Path)
			experience.Rested:SetFrameLevel(experience:GetFrameLevel() - 1)
		end

		if(not experience:GetStatusBarTexture()) then
			experience:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
		end

		return true
	end
end

local function Disable(self)
	local experience = self.Experience
	if(experience) then
		self:UnregisterEvent('PLAYER_XP_UPDATE', Path)
		self:UnregisterEvent('PLAYER_LEVEL_UP', Path)
		self:UnregisterEvent('UNIT_PET_EXPERIENCE', Path)

		if(experience.Rested) then
			self:UnregisterEvent('UPDATE_EXHAUSTION', Path)
		end
	end
end

oUF:AddElement('Experience', Path, Enable, Disable)
