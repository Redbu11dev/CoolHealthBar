--local frame = CreateFrame("Frame")

local _G = getfenv(0)

SLASH_COOLHEALTHBAR1 = '/coolhealthbar'
SLASH_COOLHEALTHBAR2 = '/chb'
SlashCmdList["COOLHEALTHBAR"] = function(msg)
  -- if ShaguPlates.gui:IsShown() then
    -- ShaguPlates.gui:Hide()
  -- else
    -- ShaguPlates.gui:Show()
  -- end
  coolHealthBarOptionsFrame:Show()
end

local addonIsLoaded = false
local playerEnteredWorld = false

local playerIsInCombatLockdown = false

local currentHp = 0
local maxHp = 0
local currentPower = 0
local maxPower = 0

local anyWatchedBuffFound = false

local mainFrame = CreateFrame("Frame", "CoolHealthBarMainFrame", UIParent)
mainFrame:SetFrameStrata("LOW")
mainFrame.TimeToCheck = 0

local coolHealthBarScanTooltip = nil

local function getBuffInfo(buffId, buffCancel)
	local scanTextLine1 = _G["CoolHealthBarScanTooltipTextLeft1"]
	coolHealthBarScanTooltip:ClearLines()
	coolHealthBarScanTooltip:SetPlayerBuff(buffId, buffCancel)
	return scanTextLine1:GetText(), GetPlayerBuffTexture(buffId), GetPlayerBuffTimeLeft(buffId), GetPlayerBuffApplications(buffId)
end

mainFrame:SetScript("OnEvent", function()
	addonIsLoaded = true

	if event == "ADDON_LOADED" and arg1 == "CoolHealthBar" then
		addonIsLoaded = true
		--print("----------ADDON_LOADED: "..arg1)
		mainFrame:UnregisterEvent("ADDON_LOADED")
		
		if (addonIsLoaded and playerEnteredWorld) then
			CoolHealthBar_OnLoad()
		end
	end
	if event == "PLAYER_ENTERING_WORLD" then
		playerEnteredWorld = true
		--print("----------ADDON_LOADED: "..arg1)
		mainFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
		
		if (addonIsLoaded and playerEnteredWorld) then
			CoolHealthBar_OnLoad()
		end
	end
end)

local function trimString(s)
  local l = 1
  while strsub(s,l,l) == ' ' do
    l = l+1
  end
  local r = strlen(s)
  while strsub(s,r,r) == ' ' do
    r = r-1
  end
  return strsub(s,l,r)
end

local buffWatchL1Names = {}
local buffWatchR1Names = {}

mainFrame:SetScript("OnUpdate", function()
    mainFrame.TimeToCheck = mainFrame.TimeToCheck - arg1
    if mainFrame.TimeToCheck > 0 then 
        return -- We haven't counted down to zero yet so do nothing
    end
    mainFrame.TimeToCheck = 0.01 -- We've waited a second so reset the timer
	
	anyWatchedBuffFound = false
	local buffL1Found = false
	local buffR1Found = false
	
    for i=0,40 do
		local bId,bCancel = GetPlayerBuff(i,"HELPFUL|HARMFUL|PASSIVE")
		if(bId >= 0) then			
			local buffName, bufftexture, buffSecondsLeft, buffCount = getBuffInfo(bId, bCancel)
			--print(i.." chb debug buffName: "..buffName.." bufftexture: "..bufftexture.." buffSecondsLeft: "..buffSecondsLeft.." buffCount: "..buffCount)
			
			if (table.getn(buffWatchL1Names) > 0) then
				for _, buffToWatchName in ipairs(buffWatchL1Names) do
					local doesNameMatch = false
					
					if not CoolHealthBarSettings.useExactNamingL1 then
						if (string.find(string.upper(buffName), string.upper(buffToWatchName))) then
							doesNameMatch = true
						end
					else
						if (string.upper(buffName) == string.upper(buffToWatchName)) then
							doesNameMatch = true
						end
					end
				
					if doesNameMatch then
						mainFrame.buffWatchL1.icon:SetTexture(bufftexture)
						if (buffSecondsLeft > 0) then
							--mainFrame.buffWatchL1.cdFrame:SetCooldown(buffSecondsLeft, 30)
							mainFrame.buffWatchL1.textDuration:SetText(""..math.floor(buffSecondsLeft))
						else
							mainFrame.buffWatchL1.textDuration:SetText("")
						end
						if (buffCount > 1) then
							mainFrame.buffWatchL1.textCount:SetText(""..buffCount)
						else
							mainFrame.buffWatchL1.textCount:SetText("")
						end
						mainFrame.buffWatchL1:Show()
						
						buffL1Found = true
						anyWatchedBuffFound = true
						break
					end
				end
			end
			
			if (table.getn(buffWatchR1Names) > 0) then
				for _, buffToWatchName in ipairs(buffWatchR1Names) do
					local doesNameMatch = false
					
					if not CoolHealthBarSettings.useExactNamingR1 then
						if (string.find(string.upper(buffName), string.upper(buffToWatchName))) then
							doesNameMatch = true
						end
					else
						if (string.upper(buffName) == string.upper(buffToWatchName)) then
							doesNameMatch = true
						end
					end
					
					if doesNameMatch then
						mainFrame.buffWatchR1.icon:SetTexture(bufftexture)
						if (buffSecondsLeft > 0) then
							--mainFrame.buffWatchR1.cdFrame:SetCooldown(buffSecondsLeft, 30)
							mainFrame.buffWatchR1.textDuration:SetText(""..math.floor(buffSecondsLeft))
						else
							mainFrame.buffWatchR1.textDuration:SetText("")
						end
						if (buffCount > 1) then
							mainFrame.buffWatchR1.textCount:SetText(""..buffCount)
						else
							mainFrame.buffWatchR1.textCount:SetText("")
						end
						mainFrame.buffWatchR1:Show()
						
						buffR1Found = true
						anyWatchedBuffFound = true
						break
					end
				end
			end
		end 
    end
	
	if not buffL1Found then
		mainFrame.buffWatchL1:Hide()
	end
	
	if not buffR1Found then
		mainFrame.buffWatchR1:Hide()
	end
	
end)

--frame:SetScript("OnEvent", dispatchEvents)
mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
mainFrame:RegisterEvent("ADDON_LOADED")

local barAlpha = 1
local barBackgroundAlpha = 0.5

local statusBarTexture = "Interface\\AddOns\\CoolHealthBar\\img\\statusbar\\XPerl_StatusBar7"

function UpdateHealth()
	currentHp = UnitHealth("player")
	maxHp = UnitHealthMax("player")
	
	--if (maxHp < 1) then maxHp = 1 end
	
	local healthPercent = math.floor((currentHp / maxHp)*100)
	
	if healthPercent <= 30 then
		mainFrame.health:SetStatusBarColor(1, 0, 0, barAlpha)
	elseif healthPercent <= 60 then
		mainFrame.health:SetStatusBarColor(1, 1, 0, barAlpha)
	else
		mainFrame.health:SetStatusBarColor(0, 1, 0, barAlpha)
	end
	
	mainFrame.health:SetMinMaxValues(0, maxHp)
	mainFrame.health:SetValue(currentHp)
	
	mainFrame.health.text:SetText(currentHp.."/"..maxHp.." ("..healthPercent.."%)")
	
	ChangeHealthBarVisibility()
end

function UpdatePower()
	currentPower = UnitMana("player")
	maxPower = UnitManaMax("player")
	
	local powerType = UnitPowerType("player")
	
	if powerType == 0 then
		mainFrame.power:SetStatusBarColor(0, 0, 1, barAlpha)
	elseif powerType == 1 then
		mainFrame.power:SetStatusBarColor(1, 0, 0, barAlpha)
	elseif powerType == 2 or powerType == 3 then
		mainFrame.power:SetStatusBarColor(1, 1, 0, barAlpha)
	else
		mainFrame.power:SetStatusBarColor(1, 1, 0, barAlpha)
	end
	
	--if (maxPower < 1) then maxPower = 1 end

	local powerPercent = math.floor((currentPower / maxPower)*100)
	
	mainFrame.power:SetMinMaxValues(0, maxPower)
	mainFrame.power:SetValue(currentPower)
	
	mainFrame.power.text:SetText(currentPower.."/"..maxPower.." ("..powerPercent.."%)")
	
	ChangeHealthBarVisibility()
end

function ChangeHealthBarVisibility()
	local shouldShow = false
	
	if CoolHealthBarSettings.alwaysShowOutOfCombat then
		shouldShow = true
	elseif CoolHealthBarSettings.showOutOfCombatWhenNotFull then
		local powerType = UnitPowerType("player")
		
		if powerType == 1 then
			if UnitAffectingCombat("player") or playerIsInCombatLockdown or (currentHp < maxHp) or currentPower > 0 and maxHp > 0 then
				shouldShow = true
			else
				shouldShow = false
			end
		else
			if UnitAffectingCombat("player") or playerIsInCombatLockdown or (currentHp < maxHp) or (currentPower < maxPower) and maxHp > 0 and maxPower > 0 then
				shouldShow = true
			else
				shouldShow = false
			end
		end
		
		-- if anyWatchedBuffFound then
			-- shouldShow = true
		-- end
	else
		if (UnitAffectingCombat("player") or playerIsInCombatLockdown) then
			shouldShow = true
		else
			shouldShow = false
		end
	end
	
	if UnitIsDeadOrGhost("player") then
		shouldShow = false
	end
	
	if shouldShow then
		mainFrame:Show()
	else
		mainFrame:Hide()
	end
end

function CoolHealthBar_OnLoad()
	initSettings()
	
	coolHealthBarScanTooltip = CreateFrame( "GameTooltip", "CoolHealthBarScanTooltip", nil, "GameTooltipTemplate" )
	coolHealthBarScanTooltip:SetOwner( WorldFrame, "ANCHOR_NONE" )
	
	print(string.format("%s by Redbu11 is loaded susscessfully\nThank you for using my addon", "CoolHealthBar"))
	
	mainFrame:SetScript("OnEvent", function()
		--local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
		if (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") and UnitIsUnit(arg1, "player") then
			UpdateHealth()
		elseif (event == "UNIT_MANA" or event == "UNIT_MAXMANA" or event == "UNIT_RAGE" or event == "UNIT_MAXRAGE" or event == "UNIT_ENERGY" or event == "UNIT_MAXENERGY") and UnitIsUnit(arg1, "player") then
			UpdatePower()
		elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
			playerIsInCombatLockdown = arg1
			ChangeHealthBarVisibility()
		elseif event == "PLAYER_AURAS_CHANGED" then
			-- print("debug args PLAYER_AURAS_CHANGED arg1: "..arg1)
			--local buffName, buffRank = GetPlayerBuffName(1)
			--print("debug: "..buffName.."/"..buffRank)
			-- local ubName, uBCount, uBSpellid = UnitBuff("player",i)
			-- if (ubName) then
				-- print(i.." debug ub: ubName: "..ubName.." uBCount: "..uBCount.." uBSpellid: "..uBSpellid)
				
				-- local name = GetSpellInfo(uBSpellid)
				-- print(i.." debug GetSpellInfo: name: "..name)
			-- end
		end
	end)

	--frame:SetScript("OnEvent", dispatchEvents)
	--mainFrame:RegisterEvent("ADDON_LOADED")
	mainFrame:RegisterEvent("UNIT_HEALTH")
	mainFrame:RegisterEvent("UNIT_MAXHEALTH")
	mainFrame:RegisterEvent("UNIT_MANA")
	mainFrame:RegisterEvent("UNIT_MAXMANA")
	mainFrame:RegisterEvent("UNIT_RAGE")
	mainFrame:RegisterEvent("UNIT_MAXRAGE")
	mainFrame:RegisterEvent("UNIT_ENERGY")
	mainFrame:RegisterEvent("UNIT_MAXENERGY")
	mainFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
	mainFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	mainFrame:RegisterEvent("PLAYER_AURAS_CHANGED")
	
	
	
	--mainFrame:SetSize(500, 350)
	mainFrame:SetWidth(math.max(1, CoolHealthBarSettings.barsWidth+8))
	mainFrame:SetHeight(math.max(1, CoolHealthBarSettings.healthBarHeight+CoolHealthBarSettings.powerBarHeight+8))
	mainFrame:SetPoint("CENTER", UIParent, "CENTER", CoolHealthBarSettings.offsetX, CoolHealthBarSettings.offsetY)
	
	mainFrame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		--edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	mainFrame:SetBackdropColor(0,0,0,.5)
	
	mainFrame.health = CreateFrame("StatusBar", nil, mainFrame)
	mainFrame.health:SetFrameLevel(1) -- keep above glow
	mainFrame.health:SetOrientation("HORIZONTAL")
	mainFrame.health:SetStatusBarTexture(statusBarTexture)
	mainFrame.health:SetStatusBarColor(0, 1, 0, barAlpha)
	mainFrame.health:SetPoint("TOP", mainFrame, "TOP", 0, -4)
	mainFrame.health:SetWidth(math.max(1, CoolHealthBarSettings.barsWidth))
	mainFrame.health:SetHeight(math.max(1, CoolHealthBarSettings.healthBarHeight))
	mainFrame.health:SetMinMaxValues(0, UnitHealthMax("player"))
	mainFrame.health:SetValue(UnitHealth("player"))
	mainFrame.health.text = mainFrame.health:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	--nameplate.health.text:SetAllPoints()
	mainFrame.health.text:SetPoint("RIGHT", mainFrame.health, "RIGHT", -2, -8)
	mainFrame.health.text:SetTextColor(1,1,1,barAlpha)
	mainFrame.health.text:SetFont("Interface\\AddOns\\CoolHealthBar\\fonts\\francois.ttf", 12, "OUTLINE")
	mainFrame.health.text:SetJustifyH("RIGHT")
	mainFrame.health.text:SetText("health")
	
	-- mainFrame.health.bg = mainFrame.health:CreateTexture(nil, "BACKGROUND")
	-- mainFrame.health.bg:SetTexture("Interface\\AddOns\\CoolHealthBar\\img\\statusbar\\XPerl_StatusBar4")
	-- mainFrame.health.bg:SetAllPoints()
	-- mainFrame.health.bg:SetVertexColor(0, 0, 0, barBackgroundAlpha)
	
	mainFrame.health:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 4,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	mainFrame.health:SetBackdropColor(0,0,0,.5)
	
	mainFrame.health:Show()
	
	
	mainFrame.power = CreateFrame("StatusBar", nil, mainFrame)
	mainFrame.power:SetFrameLevel(1) -- keep above glow
	mainFrame.power:SetOrientation("HORIZONTAL")
	mainFrame.power:SetStatusBarTexture(statusBarTexture)
	mainFrame.power:SetStatusBarColor(0, 0, 1, barAlpha)
	mainFrame.power:SetPoint("TOP", mainFrame.health, "BOTTOM", 0, 0)
	mainFrame.power:SetWidth(math.max(1, CoolHealthBarSettings.barsWidth))
	mainFrame.power:SetHeight(math.max(1, CoolHealthBarSettings.powerBarHeight))
	mainFrame.power:SetMinMaxValues(0, UnitManaMax("player"))
	mainFrame.power:SetValue(UnitMana("player"))
	mainFrame.power.text = mainFrame.power:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	mainFrame.power.text:SetPoint("RIGHT", mainFrame.power, "RIGHT", -2, -8)
	mainFrame.power.text:SetTextColor(1,1,1,barAlpha)
	mainFrame.power.text:SetFont("Interface\\AddOns\\CoolHealthBar\\fonts\\francois.ttf", 12, "OUTLINE")
	mainFrame.power.text:SetJustifyH("RIGHT")
	mainFrame.power.text:SetText("power")
	
	-- mainFrame.power.bg = mainFrame.power:CreateTexture(nil, "BACKGROUND")
	-- mainFrame.power.bg:SetTexture("Interface\\AddOns\\CoolHealthBar\\img\\statusbar\\XPerl_StatusBar4")
	-- mainFrame.power.bg:SetAllPoints()
	-- mainFrame.power.bg:SetVertexColor(0, 0, 0, barBackgroundAlpha)
	
	mainFrame.power:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 4,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	mainFrame.power:SetBackdropColor(0,0,0,.5)
	
	mainFrame.power:Show()
	
	local borderImageSize = 80
	
	mainFrame.borderImageL = CreateFrame("Frame", nil, mainFrame)
	mainFrame.borderImageL:SetFrameLevel(0)
	mainFrame.borderImageL:SetPoint("RIGHT", mainFrame, "LEFT", 3, 0)
	mainFrame.borderImageL:SetHeight(borderImageSize)
	mainFrame.borderImageL:SetWidth(borderImageSize)
	mainFrame.borderImageL.icon = mainFrame.borderImageL:CreateTexture(nil, "BORDER")
	mainFrame.borderImageL.icon:SetTexCoord(1, 0, 0, 1)
	mainFrame.borderImageL.icon:SetVertexColor(0.7, 0.7, 0.7, 1)
	--mainFrame.borderImageL.icon:SetVertexColor(1, 1, 0, 1)
	mainFrame.borderImageL.icon:SetAllPoints()
	mainFrame.borderImageL.icon:SetTexture("Interface\\AddOns\\CoolHealthBar\\img\\sword_256")
	mainFrame.borderImageL:Show()

	mainFrame.borderImageR = CreateFrame("Frame", nil, mainFrame)
	mainFrame.borderImageR:SetFrameLevel(0)
	mainFrame.borderImageR:SetPoint("LEFT", mainFrame, "RIGHT", -3, 0)
	mainFrame.borderImageR:SetHeight(borderImageSize)
	mainFrame.borderImageR:SetWidth(borderImageSize)
	mainFrame.borderImageR.icon = mainFrame.borderImageR:CreateTexture(nil, "BORDER")
	mainFrame.borderImageR.icon:SetVertexColor(0.7, 0.7, 0.7, 1)
	--mainFrame.borderImageR.icon:SetTexCoord(1, 0, 0, 1)
	--mainFrame.borderImageR.icon:SetVertexColor(1, 1, 0, 1)
	mainFrame.borderImageR.icon:SetAllPoints()
	mainFrame.borderImageR.icon:SetTexture("Interface\\AddOns\\CoolHealthBar\\img\\sword_256")
	mainFrame.borderImageR:Show()
	
	
	mainFrame.buffWatchL1 = CreateFrame("Frame", nil, mainFrame)
	mainFrame.buffWatchL1:SetPoint("BOTTOMLEFT", mainFrame.health, "TOPLEFT", 0, 2)
	mainFrame.buffWatchL1:SetHeight(math.max(1, CoolHealthBarSettings.buffWatchSize))
	mainFrame.buffWatchL1:SetWidth(math.max(1, CoolHealthBarSettings.buffWatchSize))
	mainFrame.buffWatchL1.icon = mainFrame.buffWatchL1:CreateTexture(nil, "ARTWORK")
	mainFrame.buffWatchL1.icon:SetTexture("Interface\\Icons\\Spell_Holy_AuraOfLight")
	mainFrame.buffWatchL1.icon:SetAllPoints()
	mainFrame.buffWatchL1.textDuration = mainFrame.buffWatchL1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	mainFrame.buffWatchL1.textDuration:SetPoint("CENTER", mainFrame.buffWatchL1, "CENTER", 0, 0)
	mainFrame.buffWatchL1.textDuration:SetTextColor(1,1,1,barAlpha)
	mainFrame.buffWatchL1.textDuration:SetFont("Fonts\\FRIZQT__.TTF", math.max(1, CoolHealthBarSettings.buffWatchSize/2), "OUTLINE")
	mainFrame.buffWatchL1.textDuration:SetJustifyH("RIGHT")
	mainFrame.buffWatchL1.textDuration:SetText("99")
	mainFrame.buffWatchL1.textCount = mainFrame.buffWatchL1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	mainFrame.buffWatchL1.textCount:SetPoint("BOTTOMRIGHT", mainFrame.buffWatchL1, "BOTTOMRIGHT", -math.max(0.1, CoolHealthBarSettings.buffWatchSize/20), math.max(0.1, CoolHealthBarSettings.buffWatchSize/10))
	mainFrame.buffWatchL1.textCount:SetTextColor(1,1,1,barAlpha)
	mainFrame.buffWatchL1.textCount:SetFont("Fonts\\FRIZQT__.TTF", math.max(1, CoolHealthBarSettings.buffWatchSize/4), "OUTLINE")
	mainFrame.buffWatchL1.textCount:SetJustifyH("RIGHT")
	mainFrame.buffWatchL1.textCount:SetText("99")
	--local buffWatchFrame = CreateFrame("Cooldown", "BuffWatchFrame", mainFrame.buffWatchL1, "CooldownFrameTemplate")
	--mainFrame.buffWatchL1.cdFrame = buffWatchL1cdFrame
	-- mainFrame.buffWatchL1.cdFrame:SetAllPoints(mainFrame.buffWatchL1)
	-- mainFrame.buffWatchL1.cdFrame:SetSwipeColor(1, 1, 1)
	-- mainFrame.buffWatchL1.cdFrame:SetCooldown(5, 10)
	--local cooldownFrame = CreateFrame("Cooldown", "MyCdFrame", mainFrame.buffWatchL1, "CooldownFrameTemplate")
	
	-- mainFrame.buffWatchL1.cooldown = CreateFrame("Model", "BuffWatchL1Cooldown", mainFrame.buffWatchL1, "CooldownFrameTemplate")
	-- mainFrame.buffWatchL1.cdFrame:SetAllPoints(mainFrame.buffWatchL1)
	--mainFrame.buffWatchL1.cdFrame:SetSwipeColor(1, 1, 1)
	--mainFrame.buffWatchL1.cdFrame:SetCooldown(5, 10)
	mainFrame.buffWatchL1:Show()
	
	mainFrame.buffWatchR1 = CreateFrame("Frame", nil, mainFrame)
	mainFrame.buffWatchR1:SetPoint("BOTTOMRIGHT", mainFrame.health, "TOPRIGHT", 0, 2)
	mainFrame.buffWatchR1:SetHeight(math.max(1, CoolHealthBarSettings.buffWatchSize))
	mainFrame.buffWatchR1:SetWidth(math.max(1, CoolHealthBarSettings.buffWatchSize))
	mainFrame.buffWatchR1.icon = mainFrame.buffWatchR1:CreateTexture(nil, "ARTWORK")
	mainFrame.buffWatchR1.icon:SetTexture("Interface\\Icons\\Spell_Holy_AuraOfLight")
	mainFrame.buffWatchR1.icon:SetAllPoints()
	mainFrame.buffWatchR1.textDuration = mainFrame.buffWatchR1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	mainFrame.buffWatchR1.textDuration:SetPoint("CENTER", mainFrame.buffWatchR1, "CENTER", 0, 0)
	mainFrame.buffWatchR1.textDuration:SetTextColor(1,1,1,barAlpha)
	mainFrame.buffWatchR1.textDuration:SetFont("Fonts\\FRIZQT__.TTF", math.max(1, CoolHealthBarSettings.buffWatchSize/2), "OUTLINE")
	mainFrame.buffWatchR1.textDuration:SetJustifyH("RIGHT")
	mainFrame.buffWatchR1.textDuration:SetText("99")
	mainFrame.buffWatchR1.textCount = mainFrame.buffWatchR1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	mainFrame.buffWatchR1.textCount:SetPoint("BOTTOMRIGHT", mainFrame.buffWatchR1, "BOTTOMRIGHT", -math.max(0.1, CoolHealthBarSettings.buffWatchSize/20), math.max(0.1, CoolHealthBarSettings.buffWatchSize/10))
	mainFrame.buffWatchR1.textCount:SetTextColor(1,1,1,barAlpha)
	mainFrame.buffWatchR1.textCount:SetFont("Fonts\\FRIZQT__.TTF", math.max(1, CoolHealthBarSettings.buffWatchSize/4), "OUTLINE")
	mainFrame.buffWatchR1.textCount:SetJustifyH("RIGHT")
	mainFrame.buffWatchR1.textCount:SetText("99")
	-- mainFrame.buffWatchR1.cdFrame = CreateFrame("Cooldown", "buffWatchR1cdFrame", mainFrame.buffWatchR1,  "CooldownFrameTemplate")
	-- mainFrame.buffWatchR1.cdFrame:SetAllPoints(mainFrame.buffWatchR1)
	-- mainFrame.buffWatchR1.cdFrame:SetSwipeColor(1, 1, 1)
	-- mainFrame.buffWatchR1.cdFrame:SetCooldown(5, 10)
	mainFrame.buffWatchR1:Show()
	
	applyAllSettings()
end

function loadCoolHealthBarDefaultSettings()
	CoolHealthBarSettings = {
		minimapIconPos = 0,
		showOutOfCombatWhenNotFull=true,
		alwaysShowOutOfCombat=false,
		barsWidth = 400,
		healthBarHeight = 20,
		powerBarHeight = 10,

		offsetY = -327,
		offsetX = 0,
		buffWatchSize = 60,
		buffWatchL1Sequence = "seal of",
		useExactNamingL1 = false,
		buffWatchR1Sequence = "holy shield,drink,food",
		useExactNamingR1 = false
	}
	-- print("--CoolHealthBarSettings start")
	-- print(""..CoolHealthBarSettings.showOutOfCombatWhenNotFull)
	-- print(""..CoolHealthBarSettings.alwaysShowOutOfCombat)
	-- print(""..CoolHealthBarSettings.barsWidth)
	-- print(""..CoolHealthBarSettings.healthBarHeight)
	-- print(""..CoolHealthBarSettings.powerBarHeight)
	-- print(""..CoolHealthBarSettings.offsetY)
	-- print(""..CoolHealthBarSettings.offsetX)
	-- print("--CoolHealthBarSettings end")
end

function loadCoolHealthBarSettings() 
	if CoolHealthBarSettings == nil then
		loadCoolHealthBarDefaultSettings()
		print("unable to load CoolHealthbar saved data, backing up to defaults")
	else
		if CoolHealthBarSettings.minimapIconPos == nil then
			CoolHealthBarSettings.minimapIconPos=0
		end
		if CoolHealthBarSettings.showOutOfCombatWhenNotFull == nil then
			CoolHealthBarSettings.showOutOfCombatWhenNotFull=true
		end
		if CoolHealthBarSettings.showOutOfCombatWhenNotFull == nil then
			CoolHealthBarSettings.showOutOfCombatWhenNotFull=true
		end
		if CoolHealthBarSettings.alwaysShowOutOfCombat == nil then
			CoolHealthBarSettings.alwaysShowOutOfCombat=false
		end
		if CoolHealthBarSettings.barsWidth == nil then
			CoolHealthBarSettings.barsWidth=400
		end
		if CoolHealthBarSettings.healthBarHeight == nil then
			CoolHealthBarSettings.healthBarHeight=20
		end
		if CoolHealthBarSettings.powerBarHeight == nil then
			CoolHealthBarSettings.powerBarHeight=10
		end
		if CoolHealthBarSettings.offsetY == nil then
			CoolHealthBarSettings.offsetY=-327
		end
		if CoolHealthBarSettings.offsetX == nil then
			CoolHealthBarSettings.offsetX=0
		end
		if CoolHealthBarSettings.buffWatchSize == nil then
			CoolHealthBarSettings.buffWatchSize=60
		end
		if CoolHealthBarSettings.buffWatchL1Sequence == nil then
			CoolHealthBarSettings.buffWatchL1Sequence="seal of"
		end
		if CoolHealthBarSettings.useExactNamingL1 == nil then
			CoolHealthBarSettings.useExactNamingL1=false
		end
		if CoolHealthBarSettings.buffWatchR1Sequence == nil then
			CoolHealthBarSettings.buffWatchR1Sequence="holy shield,drink,food"
		end
		if CoolHealthBarSettings.useExactNamingR1 == nil then
			CoolHealthBarSettings.useExactNamingR1=false
		end
		print("CoolHealthBar saved data loaded")
	end
end

function applyAllSettings()
	ChangeHealthBarVisibility()
	
	mainFrame:SetPoint("CENTER", UIParent, "CENTER", CoolHealthBarSettings.offsetX, CoolHealthBarSettings.offsetY)
	
	mainFrame:SetWidth(math.max(1, CoolHealthBarSettings.barsWidth+8))
	mainFrame:SetHeight(math.max(1, CoolHealthBarSettings.healthBarHeight+CoolHealthBarSettings.powerBarHeight+8))
	
	mainFrame.health:SetWidth(math.max(1, CoolHealthBarSettings.barsWidth))
	mainFrame.health:SetHeight(math.max(1, CoolHealthBarSettings.healthBarHeight))
	
	mainFrame.power:SetWidth(math.max(1, CoolHealthBarSettings.barsWidth))
	mainFrame.power:SetHeight(math.max(1, CoolHealthBarSettings.powerBarHeight))
	
	mainFrame.buffWatchL1:SetHeight(math.max(1, CoolHealthBarSettings.buffWatchSize))
	mainFrame.buffWatchL1:SetWidth(math.max(1, CoolHealthBarSettings.buffWatchSize))
	mainFrame.buffWatchL1.textDuration:SetFont("Fonts\\FRIZQT__.TTF", math.max(1, CoolHealthBarSettings.buffWatchSize/2), "OUTLINE")
	mainFrame.buffWatchL1.textCount:SetFont("Fonts\\FRIZQT__.TTF", math.max(1, CoolHealthBarSettings.buffWatchSize/4), "OUTLINE")
	mainFrame.buffWatchL1.textCount:SetPoint("BOTTOMRIGHT", mainFrame.buffWatchL1, "BOTTOMRIGHT", -math.max(0.1, CoolHealthBarSettings.buffWatchSize/20), math.max(0.1, CoolHealthBarSettings.buffWatchSize/10))
	
	mainFrame.buffWatchR1:SetHeight(math.max(1, CoolHealthBarSettings.buffWatchSize))
	mainFrame.buffWatchR1:SetWidth(math.max(1, CoolHealthBarSettings.buffWatchSize))
	mainFrame.buffWatchR1.textDuration:SetFont("Fonts\\FRIZQT__.TTF", math.max(1, CoolHealthBarSettings.buffWatchSize/2), "OUTLINE")
	mainFrame.buffWatchR1.textCount:SetFont("Fonts\\FRIZQT__.TTF", math.max(1, CoolHealthBarSettings.buffWatchSize/4), "OUTLINE")
	mainFrame.buffWatchR1.textCount:SetPoint("BOTTOMRIGHT", mainFrame.buffWatchR1, "BOTTOMRIGHT", -math.max(0.1, CoolHealthBarSettings.buffWatchSize/20), math.max(0.1, CoolHealthBarSettings.buffWatchSize/10))
	
	buffWatchL1Names = {}
	for word in string.gfind(CoolHealthBarSettings.buffWatchL1Sequence, '([^,]+)') do
		table.insert(buffWatchL1Names, trimString(word))
	end
	
	buffWatchR1Names = {}
	for word in string.gfind(CoolHealthBarSettings.buffWatchR1Sequence, '([^,]+)') do
		table.insert(buffWatchR1Names, trimString(word))
	end
	
	UpdateHealth()
	UpdatePower()
end

coolHealthBarOptionsFrame = CreateFrame("Frame", "coolHealthBarOptionsFrame", UIParent)

function initSettings()
	loadCoolHealthBarSettings()
	
	coolHealthBarOptionsFrame:SetMovable(true)
	coolHealthBarOptionsFrame:EnableMouse(true)
	-- coolHealthBarOptionsFrame:RegisterForDrag("LeftButton")
	-- coolHealthBarOptionsFrame:SetScript("OnDragStart", coolHealthBarOptionsFrame.StartMoving)
	-- coolHealthBarOptionsFrame:SetScript("OnDragStop", coolHealthBarOptionsFrame.StopMovingOrSizing)
	
	coolHealthBarOptionsFrame:SetScript("OnMouseDown", function()
	  if arg1 == "LeftButton" and not coolHealthBarOptionsFrame.isMoving then
	   coolHealthBarOptionsFrame:StartMoving()
	   coolHealthBarOptionsFrame.isMoving = true
	  end
	end)
	coolHealthBarOptionsFrame:SetScript("OnMouseUp", function()
	  if arg1 == "LeftButton" and coolHealthBarOptionsFrame.isMoving then
	   coolHealthBarOptionsFrame:StopMovingOrSizing()
	   coolHealthBarOptionsFrame.isMoving = false
	  end
	end)
	coolHealthBarOptionsFrame:SetScript("OnHide", function()
	  if ( coolHealthBarOptionsFrame.isMoving ) then
	   coolHealthBarOptionsFrame:StopMovingOrSizing()
	   coolHealthBarOptionsFrame.isMoving = false
	  end
	end)
	
	coolHealthBarOptionsFrame:SetWidth(500)
	coolHealthBarOptionsFrame:SetHeight(500)
	coolHealthBarOptionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)	
	
	-- local tex = coolHealthBarOptionsFrame:CreateTexture("ARTWORK")
	-- tex:SetAllPoints()
	-- tex:SetTexture(1.0, 0.5, 0)
	-- tex:SetAlpha(0.5)
	
	coolHealthBarOptionsFrame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		--edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	coolHealthBarOptionsFrame:SetBackdropColor(0,0,0,.5)
	
	
	-- input:SetScript("OnEscapePressed", function(self)
	  -- this:ClearFocus()
	-- end)
	
	
	
	---------------------
	

	coolHealthBarOptionsFrame.title = coolHealthBarOptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	--nameplate.health.text:SetAllPoints()
	coolHealthBarOptionsFrame.title:SetPoint("TOP", coolHealthBarOptionsFrame, "TOP", 0, -8)
	coolHealthBarOptionsFrame.title:SetTextColor(1,1,1,barAlpha)
	coolHealthBarOptionsFrame.title:SetFont("Interface\\AddOns\\CoolHealthBar\\fonts\\francois.ttf", 12, "OUTLINE")
	coolHealthBarOptionsFrame.title:SetJustifyH("LEFT")
	coolHealthBarOptionsFrame.title:SetText("CoolHealthBar options")
	
	local closeButton = CreateFrame("Button", nil, coolHealthBarOptionsFrame, "UIPanelButtonTemplate")
	closeButton:SetPoint("TOPRIGHT",0,0)
	closeButton:SetWidth(50)
	closeButton:SetHeight(25)
	closeButton:SetText("Close")
	closeButton:SetScript("OnClick", function()
		coolHealthBarOptionsFrame:Hide()
	end)
	
	local setDefaultsButton = CreateFrame("Button", nil, coolHealthBarOptionsFrame, "UIPanelButtonTemplate")
	setDefaultsButton:SetPoint("BOTTOM",0,0)
	setDefaultsButton:SetWidth(200)
	setDefaultsButton:SetHeight(40)
	setDefaultsButton:SetText("Set defaults & Reload")
	setDefaultsButton:SetScript("OnClick", function()
		loadCoolHealthBarDefaultSettings()
		ReloadUI()
	end)
	
	-- Create the scrolling parent frame and size it to fit inside the texture
	coolHealthBarOptionsFrame.scrollFrame = CreateFrame("ScrollFrame", "CoolHealthBarOptionsFrame_ScrollFrame", coolHealthBarOptionsFrame, "UIPanelScrollFrameTemplate")
	-- scrollFrame:SetPoint("TOPLEFT", 3, -4)
	-- scrollFrame:SetPoint("BOTTOMRIGHT", -27, 4)
	-- coolHealthBarOptionsFrame.scrollFrame:SetPoint("TOPLEFT", coolHealthBarOptionsFrame, "TOPLEFT", 4, -8)
	-- coolHealthBarOptionsFrame.scrollFrame:SetPoint("BOTTOMRIGHT", coolHealthBarOptionsFrame, "BOTTOMRIGHT", -3, 4)
	coolHealthBarOptionsFrame.scrollFrame:SetHeight(coolHealthBarOptionsFrame:GetHeight())
	coolHealthBarOptionsFrame.scrollBar = _G[coolHealthBarOptionsFrame.scrollFrame:GetName() .. "ScrollBar"]
    coolHealthBarOptionsFrame.scrollFrame:SetWidth(coolHealthBarOptionsFrame:GetWidth())
	coolHealthBarOptionsFrame.scrollFrame:SetPoint("TOPLEFT", 10, -30)
	coolHealthBarOptionsFrame.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)

	-- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
	local scrollChild = CreateFrame("Frame", nil, coolHealthBarOptionsFrame.scrollFrame)
	-- scrollChild:SetWidth(InterfaceOptionsFramePanelContainer:GetWidth()-18)
	scrollChild:SetWidth(coolHealthBarOptionsFrame:GetWidth()-18)
	scrollChild:SetHeight(1) 
	scrollChild:SetAllPoints(coolHealthBarOptionsFrame.scrollFrame)
	coolHealthBarOptionsFrame.scrollFrame:SetScrollChild(scrollChild)
		
	local showOutOfCombatCheckbox = CreateFrame("CheckButton", "showOutOfCombatCheckbox", scrollChild, "UICheckButtonTemplate")
	showOutOfCombatCheckbox:SetPoint("TOPLEFT",8,-24)
	getglobal(showOutOfCombatCheckbox:GetName() .. 'Text'):SetText("Show out of combat (if HP or power not full)")
	showOutOfCombatCheckbox:SetChecked(CoolHealthBarSettings.showOutOfCombatWhenNotFull)
	showOutOfCombatCheckbox.tooltip = "This is where you place MouseOver Text."
	showOutOfCombatCheckbox:SetScript("OnClick", function()
		CoolHealthBarSettings.showOutOfCombatWhenNotFull=not CoolHealthBarSettings.showOutOfCombatWhenNotFull
		applyAllSettings()
	end)
	
	local alwaysShowOutOfCombatCheckbox = CreateFrame("CheckButton", "alwaysShowOutOfCombatCheckbox", scrollChild, "UICheckButtonTemplate")
	--alwaysShowOutOfCombatCheckbox:SetPoint("TOPLEFT",8,-48)
	alwaysShowOutOfCombatCheckbox:SetPoint("TOP", showOutOfCombatCheckbox, "BOTTOM", 0, -0)
	getglobal(alwaysShowOutOfCombatCheckbox:GetName() .. 'Text'):SetText("ALWAYS Show out of combat")
	alwaysShowOutOfCombatCheckbox:SetChecked(CoolHealthBarSettings.alwaysShowOutOfCombat)
	alwaysShowOutOfCombatCheckbox.tooltip = "This is where you place MouseOver Text."
	alwaysShowOutOfCombatCheckbox:SetScript("OnClick", function()
		CoolHealthBarSettings.alwaysShowOutOfCombat=not CoolHealthBarSettings.alwaysShowOutOfCombat
		applyAllSettings()
	end)
	
	-- local colorrrr, colorrrg, colorrrb = getglobal(alwaysShowOutOfCombatCheckbox:GetName() .. 'Text'):GetTextColor()
	
	-- print("dddd: "..colorrrr)
	-- print("dddd: "..colorrrg)
	-- print("dddd: "..colorrrb)
	
	-- print("--CoolHealthBarSettings start")
	-- print(""..CoolHealthBarSettings.showOutOfCombatWhenNotFull)
	-- print(""..CoolHealthBarSettings.alwaysShowOutOfCombat)
	-- print(""..CoolHealthBarSettings.barsWidth)
	-- print(""..CoolHealthBarSettings.healthBarHeight)
	-- print(""..CoolHealthBarSettings.powerBarHeight)
	-- print(""..CoolHealthBarSettings.offsetY)
	-- print(""..CoolHealthBarSettings.offsetX)
	-- print("--CoolHealthBarSettings end")
	
	local offsetYInputTitle = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	--nameplate.health.text:SetAllPoints()
	--offsetYnputTitle:SetPoint("TOPLEFT", coolHealthBarOptionsFrame, "TOPLEFT", 12,-86)
	offsetYInputTitle:SetPoint("TOPLEFT", alwaysShowOutOfCombatCheckbox, "BOTTOMLEFT", 4, -8)
	offsetYInputTitle:SetTextColor(0.999,0.819,0,barAlpha)
	-- offsetYInputTitle:SetFontObject("GameFontHighlightSmall")
	--offsetYnputTitle:SetFont("Interface\\AddOns\\CoolHealthBar\\fonts\\francois.ttf", 12, "OUTLINE")
	offsetYInputTitle:SetJustifyH("LEFT")
	offsetYInputTitle:SetText("Offset Y: ")
	
	local offsetYInput = CreateFrame("EditBox", nil, scrollChild)
	offsetYInput:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		--edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	offsetYInput:SetBackdropColor(0,0,0,.5)
	offsetYInput:SetTextInsets(5, 5, 5, 5)
	offsetYInput:SetTextColor(1,1,1,1)
	offsetYInput:SetJustifyH("CENTER")
	offsetYInput:SetWidth(80)
	offsetYInput:SetHeight(26)
	--offsetYnput:SetPoint("TOPLEFT",72,-78)
	offsetYInput:SetPoint("LEFT", offsetYInputTitle, "RIGHT", 0, 0)
	offsetYInput:SetFontObject("GameFontNormal")
	offsetYInput:SetAutoFocus(false)
	offsetYInput:SetText(""..CoolHealthBarSettings.offsetY)
	offsetYInput:SetScript("OnTextChanged", function(self)
		local inputValue = tonumber(offsetYInput:GetText())
		if not inputValue then
			offsetYInput:SetText(""..CoolHealthBarSettings.offsetY)
		else
			CoolHealthBarSettings.offsetY = inputValue
			offsetYInput:SetText(CoolHealthBarSettings.offsetY)
			applyAllSettings()
		end
	end)
	
	--------
	
	local offsetXInputTitle = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	--nameplate.health.text:SetAllPoints()
	--offsetXInputTitle:SetPoint("TOPLEFT", coolHealthBarOptionsFrame, "TOPLEFT", 12,-118)
	offsetXInputTitle:SetPoint("TOPLEFT", offsetYInputTitle, "BOTTOMLEFT", 0, -16)
	offsetXInputTitle:SetTextColor(0.999,0.819,0,barAlpha)
	--offsetXInputTitle:SetFont("Interface\\AddOns\\CoolHealthBar\\fonts\\francois.ttf", 12, "OUTLINE")
	offsetXInputTitle:SetJustifyH("LEFT")
	offsetXInputTitle:SetText("Offset X: ")
	
	local offsetXInput = CreateFrame("EditBox", nil, scrollChild)
	offsetXInput:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		--edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	offsetXInput:SetBackdropColor(0,0,0,.5)
	offsetXInput:SetTextInsets(5, 5, 5, 5)
	offsetXInput:SetTextColor(1,1,1,1)
	offsetXInput:SetJustifyH("CENTER")
	offsetXInput:SetWidth(80)
	offsetXInput:SetHeight(26)
	--offsetXInput:SetPoint("TOPLEFT",72,-110)
	offsetXInput:SetPoint("LEFT", offsetXInputTitle, "RIGHT", 0, 0)
	offsetXInput:SetFontObject("GameFontNormal")
	offsetXInput:SetAutoFocus(false)
	offsetXInput:SetText(""..CoolHealthBarSettings.offsetX)
	offsetXInput:SetScript("OnTextChanged", function(self)
		local inputValue = tonumber(offsetXInput:GetText())
		if not inputValue then
			offsetXInput:SetText(""..CoolHealthBarSettings.offsetX)
		else
			CoolHealthBarSettings.offsetX = inputValue
			offsetXInput:SetText(CoolHealthBarSettings.offsetX)
			applyAllSettings()
		end
	end)
	
	
	---------------
	
	local barWidthInputTitle = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	barWidthInputTitle:SetPoint("TOPLEFT", offsetXInputTitle, "BOTTOMLEFT", 0, -16)
	barWidthInputTitle:SetTextColor(0.999,0.819,0,barAlpha)
	barWidthInputTitle:SetJustifyH("LEFT")
	barWidthInputTitle:SetText("Bar width: ")
	
	local barWidthInput = CreateFrame("EditBox", nil, scrollChild)
	barWidthInput:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	barWidthInput:SetBackdropColor(0,0,0,.5)
	barWidthInput:SetTextInsets(5, 5, 5, 5)
	barWidthInput:SetTextColor(1,1,1,1)
	barWidthInput:SetJustifyH("CENTER")
	barWidthInput:SetWidth(80)
	barWidthInput:SetHeight(26)
	barWidthInput:SetPoint("LEFT", barWidthInputTitle, "RIGHT", 0, 0)
	barWidthInput:SetFontObject("GameFontNormal")
	barWidthInput:SetAutoFocus(false)
	barWidthInput:SetText(""..CoolHealthBarSettings.barsWidth)
	barWidthInput:SetScript("OnTextChanged", function(self)
		local inputValue = tonumber(barWidthInput:GetText())
		if not inputValue then
			barWidthInput:SetText(""..CoolHealthBarSettings.barsWidth)
		else
			CoolHealthBarSettings.barsWidth = inputValue
			barWidthInput:SetText(CoolHealthBarSettings.barsWidth)
			applyAllSettings()
		end
	end)
	
	--------
	
	local hpBarHeightInputTitle = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	hpBarHeightInputTitle:SetPoint("TOPLEFT", barWidthInputTitle, "BOTTOMLEFT", 0, -16)
	hpBarHeightInputTitle:SetTextColor(0.999,0.819,0,barAlpha)
	hpBarHeightInputTitle:SetJustifyH("LEFT")
	hpBarHeightInputTitle:SetText("HP bar height: ")
	
	local hpBarHeightInput = CreateFrame("EditBox", nil, scrollChild)
	hpBarHeightInput:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	hpBarHeightInput:SetBackdropColor(0,0,0,.5)
	hpBarHeightInput:SetTextInsets(5, 5, 5, 5)
	hpBarHeightInput:SetTextColor(1,1,1,1)
	hpBarHeightInput:SetJustifyH("CENTER")
	hpBarHeightInput:SetWidth(80)
	hpBarHeightInput:SetHeight(26)
	hpBarHeightInput:SetPoint("LEFT", hpBarHeightInputTitle, "RIGHT", 0, 0)
	hpBarHeightInput:SetFontObject("GameFontNormal")
	hpBarHeightInput:SetAutoFocus(false)
	hpBarHeightInput:SetText(""..CoolHealthBarSettings.healthBarHeight)
	hpBarHeightInput:SetScript("OnTextChanged", function(self)
		local inputValue = tonumber(hpBarHeightInput:GetText())
		if not inputValue then
			hpBarHeightInput:SetText(""..healthBarHeight)
		else
			CoolHealthBarSettings.healthBarHeight = inputValue
			hpBarHeightInput:SetText(CoolHealthBarSettings.healthBarHeight)
			applyAllSettings()
		end
	end)
	
	--------
	
	local powerBarHeightInputTitle = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	powerBarHeightInputTitle:SetPoint("TOPLEFT", hpBarHeightInputTitle, "BOTTOMLEFT", 0, -16)
	powerBarHeightInputTitle:SetTextColor(0.999,0.819,0,barAlpha)
	powerBarHeightInputTitle:SetJustifyH("LEFT")
	powerBarHeightInputTitle:SetText("Power bar height: ")
	
	local powerBarHeightInput = CreateFrame("EditBox", nil, scrollChild)
	powerBarHeightInput:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	powerBarHeightInput:SetBackdropColor(0,0,0,.5)
	powerBarHeightInput:SetTextInsets(5, 5, 5, 5)
	powerBarHeightInput:SetTextColor(1,1,1,1)
	powerBarHeightInput:SetJustifyH("CENTER")
	powerBarHeightInput:SetWidth(80)
	powerBarHeightInput:SetHeight(26)
	powerBarHeightInput:SetPoint("LEFT", powerBarHeightInputTitle, "RIGHT", 0, 0)
	powerBarHeightInput:SetFontObject("GameFontNormal")
	powerBarHeightInput:SetAutoFocus(false)
	powerBarHeightInput:SetText(""..CoolHealthBarSettings.powerBarHeight)
	powerBarHeightInput:SetScript("OnTextChanged", function(self)
		local inputValue = tonumber(powerBarHeightInput:GetText())
		if not inputValue then
			powerBarHeightInput:SetText(""..powerBarHeight)
		else
			CoolHealthBarSettings.powerBarHeight = inputValue
			powerBarHeightInput:SetText(CoolHealthBarSettings.powerBarHeight)
			applyAllSettings()
		end
	end)
	
	
	-----------------
	
	local buffWatchSectionTitle = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	buffWatchSectionTitle:SetPoint("TOPLEFT", powerBarHeightInputTitle, "BOTTOMLEFT", 0, -16)
	buffWatchSectionTitle:SetTextColor(1,1,1,barAlpha)
	buffWatchSectionTitle:SetJustifyH("LEFT")
	buffWatchSectionTitle:SetText("Buff watch")
	
	-------------
	
	local buffWatchSizeInputTitle = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	buffWatchSizeInputTitle:SetPoint("TOPLEFT", buffWatchSectionTitle, "BOTTOMLEFT", 0, -16)
	buffWatchSizeInputTitle:SetTextColor(0.999,0.819,0,barAlpha)
	buffWatchSizeInputTitle:SetJustifyH("LEFT")
	buffWatchSizeInputTitle:SetText("Buff watch size: ")
	
	local buffWatchSizeInput = CreateFrame("EditBox", nil, scrollChild)
	buffWatchSizeInput:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	buffWatchSizeInput:SetBackdropColor(0,0,0,.5)
	buffWatchSizeInput:SetTextInsets(5, 5, 5, 5)
	buffWatchSizeInput:SetTextColor(1,1,1,1)
	buffWatchSizeInput:SetJustifyH("CENTER")
	buffWatchSizeInput:SetWidth(80)
	buffWatchSizeInput:SetHeight(26)
	buffWatchSizeInput:SetPoint("LEFT", buffWatchSizeInputTitle, "RIGHT", 0, 0)
	buffWatchSizeInput:SetFontObject("GameFontNormal")
	buffWatchSizeInput:SetAutoFocus(false)
	buffWatchSizeInput:SetText(""..CoolHealthBarSettings.buffWatchSize)
	buffWatchSizeInput:SetScript("OnTextChanged", function(self)
		local inputValue = tonumber(buffWatchSizeInput:GetText())
		if not inputValue then
			buffWatchSizeInput:SetText(""..CoolHealthBarSettings.buffWatchSize)
		else
			CoolHealthBarSettings.buffWatchSize = inputValue
			buffWatchSizeInput:SetText(CoolHealthBarSettings.buffWatchSize)
			applyAllSettings()
		end
	end)
	
	-------------
	
	local buffWatchSectionDescription = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	buffWatchSectionDescription:SetPoint("TOPLEFT", buffWatchSizeInputTitle, "BOTTOMLEFT", 0, -16)
	buffWatchSectionDescription:SetTextColor(1,1,1,barAlpha)
	buffWatchSectionDescription:SetJustifyH("LEFT")
	buffWatchSectionDescription:SetText("Specify buff names in format (case insensitive, separate with comma):")
	
	local buffWatchSectionDescription2 = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	buffWatchSectionDescription2:SetPoint("TOPLEFT", buffWatchSectionDescription, "BOTTOMLEFT", 0, -16)
	buffWatchSectionDescription2:SetTextColor(1,1,1,barAlpha)
	buffWatchSectionDescription2:SetJustifyH("LEFT")
	buffWatchSectionDescription2:SetText("(Leave blank to hide)")
	
	local buffWatchSectionDescription3 = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	buffWatchSectionDescription3:SetPoint("TOPLEFT", buffWatchSectionDescription2, "BOTTOMLEFT", 0, -4)
	buffWatchSectionDescription3:SetTextColor(1,1,1,barAlpha)
	buffWatchSectionDescription3:SetJustifyH("LEFT")
	buffWatchSectionDescription3:SetText("seal of, holy shield")
	
	local useExactNamingL1Checkbox = CreateFrame("CheckButton", "useExactNamingL1Checkbox", scrollChild, "UICheckButtonTemplate")
	--useExactNamingL1Checkbox:SetPoint("TOPLEFT",8,-24)
	useExactNamingL1Checkbox:SetPoint("TOPLEFT", buffWatchSectionDescription3, "BOTTOMLEFT", 0, -16)
	getglobal(useExactNamingL1Checkbox:GetName() .. 'Text'):SetText("Use exact buff names (For buff watch left 1)")
	useExactNamingL1Checkbox:SetChecked(CoolHealthBarSettings.useExactNamingL1)
	useExactNamingL1Checkbox.tooltip = "Use exact buff names (For buff watch left 1)"
	useExactNamingL1Checkbox:SetScript("OnClick", function()
		CoolHealthBarSettings.useExactNamingL1=not CoolHealthBarSettings.useExactNamingL1
		applyAllSettings()
	end)
	
	local buffWatchL1Title = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	buffWatchL1Title:SetPoint("TOPLEFT", useExactNamingL1Checkbox, "BOTTOMLEFT", 0, -4)
	buffWatchL1Title:SetTextColor(0.999,0.819,0,barAlpha)
	buffWatchL1Title:SetJustifyH("LEFT")
	buffWatchL1Title:SetText("Buff watch (Left 1): ")
	
	local buffWatchL1Input = CreateFrame("EditBox", nil, scrollChild)
	buffWatchL1Input:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	buffWatchL1Input:SetBackdropColor(0,0,0,.5)
	buffWatchL1Input:SetTextInsets(5, 5, 5, 5)
	buffWatchL1Input:SetTextColor(1,1,1,1)
	buffWatchL1Input:SetJustifyH("LEFT")
	buffWatchL1Input:SetWidth(280)
	buffWatchL1Input:SetHeight(26)
	buffWatchL1Input:SetPoint("LEFT", buffWatchL1Title, "RIGHT", 0, 0)
	buffWatchL1Input:SetFontObject("GameFontNormal")
	buffWatchL1Input:SetAutoFocus(false)
	buffWatchL1Input:SetText(""..CoolHealthBarSettings.buffWatchL1Sequence)
	buffWatchL1Input:SetScript("OnTextChanged", function(self)
		local inputValue = buffWatchL1Input:GetText()
		if not inputValue then
			buffWatchL1Input:SetText(""..CoolHealthBarSettings.buffWatchL1Sequence)
		else
			CoolHealthBarSettings.buffWatchL1Sequence = inputValue
			buffWatchL1Input:SetText(""..CoolHealthBarSettings.buffWatchL1Sequence)
			applyAllSettings()
		end
	end)
	
	local useExactNamingR1Checkbox = CreateFrame("CheckButton", "useExactNamingR1Checkbox", scrollChild, "UICheckButtonTemplate")
	useExactNamingR1Checkbox:SetPoint("TOPLEFT", buffWatchL1Title, "BOTTOMLEFT", 0, -16)
	getglobal(useExactNamingR1Checkbox:GetName() .. 'Text'):SetText("Use exact buff names (For buff watch right 1)")
	useExactNamingR1Checkbox:SetChecked(CoolHealthBarSettings.useExactNamingR1)
	useExactNamingR1Checkbox.tooltip = "Use exact buff names (For buff watch right 1)"
	useExactNamingR1Checkbox:SetScript("OnClick", function()
		CoolHealthBarSettings.useExactNamingR1=not CoolHealthBarSettings.useExactNamingR1
		applyAllSettings()
	end)
	
	local buffWatchR1Title = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	buffWatchR1Title:SetPoint("TOPLEFT", useExactNamingR1Checkbox, "BOTTOMLEFT", 0, -4)
	buffWatchR1Title:SetTextColor(0.999,0.819,0,barAlpha)
	buffWatchR1Title:SetJustifyH("LEFT")
	buffWatchR1Title:SetText("Buff watch (Right 1): ")
	
	local buffWatchR1Input = CreateFrame("EditBox", nil, scrollChild)
	buffWatchR1Input:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	buffWatchR1Input:SetBackdropColor(0,0,0,.5)
	buffWatchR1Input:SetTextInsets(5, 5, 5, 5)
	buffWatchR1Input:SetTextColor(1,1,1,1)
	buffWatchR1Input:SetJustifyH("LEFT")
	buffWatchR1Input:SetWidth(280)
	buffWatchR1Input:SetHeight(26)
	buffWatchR1Input:SetPoint("LEFT", buffWatchR1Title, "RIGHT", 0, 0)
	buffWatchR1Input:SetFontObject("GameFontNormal")
	buffWatchR1Input:SetAutoFocus(false)
	buffWatchR1Input:SetText(""..CoolHealthBarSettings.buffWatchR1Sequence)
	buffWatchR1Input:SetScript("OnTextChanged", function(self)
		local inputValue = buffWatchR1Input:GetText()
		if not inputValue then
			buffWatchR1Input:SetText(""..CoolHealthBarSettings.buffWatchR1Sequence)
		else
			CoolHealthBarSettings.buffWatchR1Sequence = inputValue
			buffWatchR1Input:SetText(""..CoolHealthBarSettings.buffWatchR1Sequence)
			applyAllSettings()
		end
	end)
	
	-- coolHealthBarOptionsFrame.scrollFrame:UpdateScrollChildRect()
	
	coolHealthBarOptionsFrame:Hide()
	
	LoadCHBMinimapButton()
end

local CHBMinimapButton = CreateFrame('Button', "CHBMainMenuBarToggler", Minimap)

function LoadCHBMinimapButton()
    --CHBMinimapButton:SetFrameStrata('HIGH')
    CHBMinimapButton:SetWidth(31)
    CHBMinimapButton:SetHeight(31)
    CHBMinimapButton:SetFrameLevel(8)
    --CHBMinimapButton:RegisterForClicks('anyUp')
    CHBMinimapButton:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')
	CHBMinimapButton:SetMovable(true)
	CHBMinimapButton:EnableMouse(true)

    local CHBMinimapButtonOverlay = CHBMinimapButton:CreateTexture(nil, 'OVERLAY')
    CHBMinimapButtonOverlay:SetWidth(53)
    CHBMinimapButtonOverlay:SetHeight(53)
    CHBMinimapButtonOverlay:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder')
    CHBMinimapButtonOverlay:SetPoint('TOPLEFT', 0, 0)

    local icon = CHBMinimapButton:CreateTexture(nil, 'BACKGROUND')
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetTexture('Interface\\Icons\\Spell_ChargeNegative')
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    icon:SetPoint('TOPLEFT', 7, -5)
    CHBMinimapButton.icon = icon

    CHBMinimapButton:SetScript("OnClick", function()
		if arg1 == "LeftButton" then
			if not coolHealthBarOptionsFrame:IsShown() then
				coolHealthBarOptionsFrame:Show()
			else
				coolHealthBarOptionsFrame:Hide()
			end
		elseif arg1 == "RightButton" then
			-- nothing
		end
	end)
	
	CHBMinimapButton:RegisterForDrag("RightButton")
	CHBMinimapButton:SetScript("OnDragStart", function()
		CHBMinimapButton:StartMoving()
		CHBMinimapButton:SetScript("OnUpdate", function()
			local Xpoa, Ypoa = GetCursorPosition()
			local Xmin, Ymin = Minimap:GetLeft(), Minimap:GetBottom()
			Xpoa = Xmin - Xpoa / Minimap:GetEffectiveScale() + 70
			Ypoa = Ypoa / Minimap:GetEffectiveScale() - Ymin - 70
			CoolHealthBarSettings.minimapIconPos = math.deg(math.atan2(Ypoa, Xpoa))
			CHBMinimapButton:ClearAllPoints()
			CHBMinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 52 - (80 * cos(CoolHealthBarSettings.minimapIconPos)), (80 * sin(CoolHealthBarSettings.minimapIconPos)) - 52)
		end)
	end)
	 
	CHBMinimapButton:SetScript("OnDragStop", function()
		CHBMinimapButton:StopMovingOrSizing()
		CHBMinimapButton:SetScript("OnUpdate", nil)
		CHBUpdateMapBtn()
	end)
	
	CHBMinimapButton:SetScript("OnEnter", function()			
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
		local scale = GameTooltip:GetEffectiveScale()
		local x, y = GetCursorPosition()
		GameTooltip:ClearAllPoints()
		GameTooltip:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
		GameTooltip:SetText("CoolHealthBar")
		GameTooltip:AddLine("\n")
		GameTooltip:AddLine("Left-click to show options", 1, 1, 1)
		GameTooltip:AddLine("Right-click and drag to move the button", 1, 1, 1)
		GameTooltip:Show()
	end)
	
	CHBMinimapButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

    
	if CoolHealthBarSettings.minimapIconPos ~= 0 then
		CHBMinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 52 - (80 * cos(CoolHealthBarSettings.minimapIconPos)), (80 * sin(CoolHealthBarSettings.minimapIconPos)) - 52)
	else
		CHBMinimapButton:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -2, 2)
	end
end