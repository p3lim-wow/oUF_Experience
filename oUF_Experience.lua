local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF Experience was unable to locate oUF install')

for tag, func in next, {
	['experience:cur'] = function(unit)
		return (IsWatchingHonorAsXP() and UnitHonor or UnitXP) ('player')
	end,
	['experience:max'] = function(unit)
		return (IsWatchingHonorAsXP() and UnitHonorMax or UnitXPMax) ('player')
	end,
	['experience:per'] = function(unit)
		return math.floor(_TAGS['experience:cur'](unit) / _TAGS['experience:max'](unit) * 100 + 0.5)
	end,
	['experience:currested'] = function()
		local rested
		if (IsWatchingHonorAsXP()) then
			rested = GetHonorExhaustion and GetHonorExhaustion()
		else
			rested = GetXPExhaustion()
		end
		return rested
	end,
	['experience:perrested'] = function(unit)
		local rested = _TAGS['experience:currested']()
		if(rested and rested > 0) then
			return math.floor(rested / _TAGS['experience:max'](unit) * 100 + 0.5)
		end
	end,
} do
	oUF.Tags.Methods[tag] = func
	oUF.Tags.Events[tag] = 'PLAYER_XP_UPDATE UPDATE_EXHAUSTION HONOR_XP_UPDATE'
end

oUF.Tags.SharedEvents.PLAYER_LEVEL_UP = true

local function UpdateTooltip(element)
	local isHonor = IsWatchingHonorAsXP()
	local cur = (isHonor and UnitHonor or UnitXP)('player')
	local max = (isHonor and UnitHonorMax or UnitXPMax)('player')
	local per = math.floor(cur / max * 100 + 0.5)
	local bars = cur / max * (isHonor and 5 or 20)

	local rested
	if (isHonor) then
		rested = GetHonorExhaustion and GetHonorExhaustion() or 0
	else
		rested = GetXPExhaustion() or 0
	end
	rested = math.floor(rested / max * 100 + 0.5)

	GameTooltip:SetText(format('%s / %s (%d%%)', BreakUpLargeNumbers(cur), BreakUpLargeNumbers(max), per), 1, 1, 1)
	if (rested > 0) then
		GameTooltip:AddLine(format('%.1f bars, %d rested', bars, rested))
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

local function UpdateColor(element, showHonor)
	if(showHonor) then
		element:SetStatusBarColor(1, 1/4, 0)
		if(element.SetAnimatedTextureColors) then
			element:SetAnimatedTextureColors(1, 1/4, 0)
		end

		if(element.Rested and GetHonorExhaustion) then
			element.Rested:SetStatusBarColor(1, 3/4, 0)
		end
	else
		element:SetStatusBarColor(1/6, 2/3, 1/5)
		if(element.SetAnimatedTextureColors) then
			element:SetAnimatedTextureColors(1/6, 2/3, 1/5)
		end

		if(element.Rested) then
			element.Rested:SetStatusBarColor(0, 2/5, 1)
		end
	end
end

local function Update(self, event, unit)
	if(self.unit ~= unit or unit ~= 'player') then return end

	local element = self.Experience
	if(element.PreUpdate) then element:PreUpdate(unit) end

	local showHonor = IsWatchingHonorAsXP()
	local level = (showHonor and UnitHonorLevel or UnitLevel)(unit)
	local cur = (showHonor and UnitHonor or UnitXP)(unit)
	local max = (showHonor and UnitHonorMax or UnitXPMax)(unit)

	if(showHonor and GetMaxPlayerHonorLevel and level == GetMaxPlayerHonorLevel()) then
		cur, max = 1, 1
	end

	if(element.SetAnimatedValues) then
		element:SetAnimatedValues(cur, 0, max, level)
	else
		element:SetMinMaxValues(0, max)
		element:SetValue(cur)
	end

	local exhaustion
	if(element.Rested) then
		if (showHonor) then
			exhaustion = GetHonorExhaustion and GetHonorExhaustion() or 0
		else
			exhaustion = GetXPExhaustion() or 0
		end
		element.Rested:SetMinMaxValues(0, max)
		element.Rested:SetValue(math.min(cur + exhaustion, max))
	end

	(element.OverrideUpdateColor or UpdateColor)(element, showHonor)

	if(element.PostUpdate) then
		return element:PostUpdate(unit, cur, max, exhaustion, level, showHonor)
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
