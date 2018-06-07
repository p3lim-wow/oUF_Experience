local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF Experience was unable to locate oUF install')

local HONOR = HONOR or 'Honor'
local EXPERIENCE = COMBAT_XP_GAIN or 'Experience'
local RESTED = TUTORIAL_TITLE26 or 'Rested'

local math_floor = math.floor

for tag, func in next, {
	['experience:cur'] = function(unit)
		return (IsWatchingHonorAsXP() and UnitHonor or UnitXP) ('player')
	end,
	['experience:max'] = function(unit)
		return (IsWatchingHonorAsXP() and UnitHonorMax or UnitXPMax) ('player')
	end,
	['experience:per'] = function(unit)
		return math_floor(_TAGS['experience:cur'](unit) / _TAGS['experience:max'](unit) * 100 + 0.5)
	end,
	['experience:currested'] = function()
		local rested
		if(IsWatchingHonorAsXP()) then
			rested = GetHonorExhaustion and GetHonorExhaustion()
		else
			rested = GetXPExhaustion()
		end
		return rested
	end,
	['experience:perrested'] = function(unit)
		local rested = _TAGS['experience:currested']()
		if(rested and rested > 0) then
			return math_floor(rested / _TAGS['experience:max'](unit) * 100 + 0.5)
		end
	end,
} do
	oUF.Tags.Methods[tag] = func
	oUF.Tags.Events[tag] = 'PLAYER_XP_UPDATE UPDATE_EXHAUSTION HONOR_XP_UPDATE'
end

local function GetValues()
	local isHonor = IsWatchingHonorAsXP()
	local cur = (isHonor and UnitHonor or UnitXP)('player')
	local max = (isHonor and UnitHonorMax or UnitXPMax)('player')
	local level = (isHonor and UnitHonorLevel or UnitLevel)('player')

	local rested
	if(isHonor) then
		rested = GetHonorExhaustion and GetHonorExhaustion() or 0
	else
		rested = GetXPExhaustion() or 0
	end

	local perc = math_floor(cur / max * 100 + 0.5)
	local restedPerc = math_floor(rested / max * 100 + 0.5)

	return cur, max, perc, rested, restedPerc, level, isHonor
end

local function UpdateTooltip(element)
	local cur, max, perc, rested, restedPerc, _, isHonor = GetValues()

	GameTooltip:SetText(isHonor and HONOR or EXPERIENCE)
	GameTooltip:AddLine(format('%s / %s (%d%%)', BreakUpLargeNumbers(cur), BreakUpLargeNumbers(max), perc), 1, 1, 1)

	if(rested > 0) then
		GameTooltip:AddLine(format('%s: %s (%d%%)', RESTED, BreakUpLargeNumbers(rested), restedPerc), 1, 1, 1)
	end

	GameTooltip:Show()
end

local function OnEnter(element)
	element:SetAlpha(element.inAlpha)
	GameTooltip:SetOwner(element, element.tooltipAnchor)
	element:UpdateTooltip()
end

local function OnLeave(element)
	GameTooltip:Hide()
	element:SetAlpha(element.outAlpha)
end

local function UpdateColor(element, isHonor, isRested)
	local r, g, b
	if(isHonor) then
		if(isRested) then
			r, g, b = 1, 0.71, 0
		else
			r, g, b = 1, 0.24, 0
		end
	else
		if(isRested) then
			r, g, b = 0, 0.39, 0.88
		else
			r, g, b = 0.58, 0, 0.55
		end
	end

	element:SetStatusBarColor(r, g, b)
	if(element.SetAnimatedTextureColors) then
		element:SetAnimatedTextureColors(r, g, b)
	end
	element.Rested:SetStatusBarColor(r, g, b, element.restedAlpha)
end

local function Update(self, event, unit)
	if(self.unit ~= unit or unit ~= 'player') then return end

	local element = self.Experience
	if(element.PreUpdate) then element:PreUpdate(unit) end

	local cur, max, _, rested, _, level, isHonor = GetValues()
	if(isHonor and GetMaxPlayerHonorLevel and level == GetMaxPlayerHonorLevel()) then
		cur, max = 1, 1
	end

	if(element.SetAnimatedValues) then
		element:SetAnimatedValues(cur, 0, max, level)
	else
		element:SetMinMaxValues(0, max)
		element:SetValue(cur)
	end

	if(element.Rested) then
		element.Rested:SetMinMaxValues(0, max)
		element.Rested:SetValue(math.min(cur + rested, max))
	end

	(element.OverrideUpdateColor or UpdateColor)(element, isHonor, rested > 0)

	if(element.PostUpdate) then
		return element:PostUpdate(unit, cur, max, rested, level, isHonor)
	end
end

local function Path(self, ...)
	return (self.Experience.Override or Update) (self, ...)
end

local function ElementEnable(self)
	local element = self.Experience
	self:RegisterEvent('PLAYER_XP_UPDATE', Path)
	self:RegisterEvent('HONOR_XP_UPDATE', Path)

	if(element.Rested) then
		self:RegisterEvent('UPDATE_EXHAUSTION', Path)
	end

	element:Show()
	element:SetAlpha(element.outAlpha or 1)

	Path(self, 'ElementEnable', 'player')
end

local function ElementDisable(self)
	self:UnregisterEvent('PLAYER_XP_UPDATE', Path)
	self:UnregisterEvent('HONOR_XP_UPDATE', Path)

	if(self.Experience.Rested) then
		self:UnregisterEvent('UPDATE_EXHAUSTION', Path)
	end

	self.Experience:Hide()

	Path(self, 'ElementDisable', 'player')
end

local function Visibility(self, event, unit)
	local element = self.Experience
	local shouldEnable

	if(not UnitHasVehicleUI('player') and not IsXPUserDisabled()) then
		if(UnitLevel('player') ~= element.__accountMaxLevel) then
			shouldEnable = true
		elseif(IsWatchingHonorAsXP() and element.__accountMaxLevel == MAX_PLAYER_LEVEL) then
			shouldEnable = true
		end
	end

	if(shouldEnable) then
		ElementEnable(self)
	else
		ElementDisable(self)
	end
end

local function VisibilityPath(self, ...)
	return (self.Experience.OverrideVisibility or Visibility)(self, ...)
end

local function ForceUpdate(element)
	return VisibilityPath(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self, unit)
	local element = self.Experience
	if(element and unit == 'player') then
		element.__owner = self

		local levelRestriction = GetRestrictedAccountData()
		if(levelRestriction > 0) then
			element.__accountMaxLevel = levelRestriction
		else
			element.__accountMaxLevel = MAX_PLAYER_LEVEL
		end

		element.ForceUpdate = ForceUpdate
		element.restedAlpha = element.restedAlpha or 0.15

		self:RegisterEvent('PLAYER_LEVEL_UP', VisibilityPath, true)
		self:RegisterEvent('HONOR_LEVEL_UPDATE', VisibilityPath)
		self:RegisterEvent('DISABLE_XP_GAIN', VisibilityPath, true)
		self:RegisterEvent('ENABLE_XP_GAIN', VisibilityPath, true)

		hooksecurefunc('SetWatchingHonorAsXP', function()
			if(self:IsElementEnabled('Experience')) then
				VisibilityPath(self, 'SetWatchingHonorAsXP', 'player')
			end
		end)

		local child = element.Rested
		if(child) then
			child:SetFrameLevel(element:GetFrameLevel() - 1)

			if(not child:GetStatusBarTexture()) then
				child:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end
		end

		if(not element:GetStatusBarTexture()) then
			element:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		if(element:IsMouseEnabled()) then
			element.UpdateTooltip = element.UpdateTooltip or UpdateTooltip
			element.tooltipAnchor = element.tooltipAnchor or 'ANCHOR_BOTTOMRIGHT'
			element.inAlpha = element.inAlpha or 1
			element.outAlpha = element.outAlpha or 1

			if(not element:GetScript('OnEnter')) then
				element:SetScript('OnEnter', OnEnter)
			end

			if(not element:GetScript('OnLeave')) then
				element:SetScript('OnLeave', OnLeave)
			end
		end

		return true
	end
end

local function Disable(self)
	local element = self.Experience
	if(element) then
		self:UnregisterEvent('PLAYER_LEVEL_UP', VisibilityPath)
		self:UnregisterEvent('HONOR_LEVEL_UPDATE', VisibilityPath)
		self:UnregisterEvent('DISABLE_XP_GAIN', VisibilityPath)
		self:UnregisterEvent('ENABLE_XP_GAIN', VisibilityPath)

		ElementDisable(self)
	end
end

oUF:AddElement('Experience', VisibilityPath, Enable, Disable)
