--local frame = CreateFrame("Frame")

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

local localVersion = "1.0.2"

local playerIsInCombatLockdown = false

local currentHp = 0
local maxHp = 0
local currentPower = 0
local maxPower = 0

local mainFrame = CreateFrame("Frame", "MainFrame", UIParent)
mainFrame:SetFrameStrata("LOW")

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
			if UnitAffectingCombat("player") or playerIsInCombatLockdown or (currentHp < maxHp) and maxHp > 0 then
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
	else
		if UnitAffectingCombat("player") or playerIsInCombatLockdown then
			shouldShow = true
		else
			shouldShow = false
		end
	end
	
	if shouldShow then
		mainFrame:Show()
	else
		mainFrame:Hide()
	end
end

function CoolHealthBar_OnLoad()
	initSettings()
	print(string.format("%s: v%s by Redbu11 is loaded susscessfully\nThank you for using my addon", "CoolHealthBar", localVersion))
	
	mainFrame:SetScript("OnEvent", function()
		if event == "UNIT_HEALTH" and UnitIsUnit(arg1, "player") then
			UpdateHealth()
		elseif event == "UNIT_MANA" and UnitIsUnit(arg1, "player") then
			UpdatePower()
		elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
			playerIsInCombatLockdown = arg1
			ChangeHealthBarVisibility()
		end
	end)

	--frame:SetScript("OnEvent", dispatchEvents)
	--mainFrame:RegisterEvent("ADDON_LOADED")
	mainFrame:RegisterEvent("UNIT_HEALTH")
	mainFrame:RegisterEvent("UNIT_MANA")
	mainFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
	mainFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	
	
	
	--mainFrame:SetSize(500, 350)
	mainFrame:SetWidth(CoolHealthBarSettings.barsWidth+8)
	mainFrame:SetHeight(CoolHealthBarSettings.healthBarHeight+CoolHealthBarSettings.powerBarHeight+8)
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
	mainFrame.health:SetWidth(CoolHealthBarSettings.barsWidth)
	mainFrame.health:SetHeight(CoolHealthBarSettings.healthBarHeight)
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
	mainFrame.power:SetWidth(CoolHealthBarSettings.barsWidth)
	mainFrame.power:SetHeight(CoolHealthBarSettings.powerBarHeight)
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
		print("CoolHealthBar saved data loaded")
	end
end

function applyAllSettings()
	ChangeHealthBarVisibility()
	
	mainFrame:SetPoint("CENTER", UIParent, "CENTER", CoolHealthBarSettings.offsetX, CoolHealthBarSettings.offsetY)
	
	mainFrame:SetWidth(CoolHealthBarSettings.barsWidth+8)
	mainFrame:SetHeight(CoolHealthBarSettings.healthBarHeight+CoolHealthBarSettings.powerBarHeight+8)
	
	mainFrame.health:SetWidth(CoolHealthBarSettings.barsWidth)
	mainFrame.health:SetHeight(CoolHealthBarSettings.healthBarHeight)
	
	mainFrame.power:SetWidth(CoolHealthBarSettings.barsWidth)
	mainFrame.power:SetHeight(CoolHealthBarSettings.powerBarHeight)
	
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
	
	coolHealthBarOptionsFrame:SetWidth(400)
	coolHealthBarOptionsFrame:SetHeight(400)
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
		
	local showOutOfCombatCheckbox = CreateFrame("CheckButton", "showOutOfCombatCheckbox", coolHealthBarOptionsFrame, "UICheckButtonTemplate")
	showOutOfCombatCheckbox:SetPoint("TOPLEFT",8,-24)
	getglobal(showOutOfCombatCheckbox:GetName() .. 'Text'):SetText("Show out of combat (if HP or power not full)")
	showOutOfCombatCheckbox:SetChecked(CoolHealthBarSettings.showOutOfCombatWhenNotFull)
	showOutOfCombatCheckbox.tooltip = "This is where you place MouseOver Text."
	showOutOfCombatCheckbox:SetScript("OnClick", function()
		CoolHealthBarSettings.showOutOfCombatWhenNotFull=not CoolHealthBarSettings.showOutOfCombatWhenNotFull
		applyAllSettings()
	end)
	
	local alwaysShowOutOfCombatCheckbox = CreateFrame("CheckButton", "alwaysShowOutOfCombatCheckbox", coolHealthBarOptionsFrame, "UICheckButtonTemplate")
	--alwaysShowOutOfCombatCheckbox:SetPoint("TOPLEFT",8,-48)
	alwaysShowOutOfCombatCheckbox:SetPoint("TOP", showOutOfCombatCheckbox, "BOTTOM", 0, -0)
	getglobal(alwaysShowOutOfCombatCheckbox:GetName() .. 'Text'):SetText("ALWAYS Show out of combat")
	alwaysShowOutOfCombatCheckbox:SetChecked(CoolHealthBarSettings.alwaysShowOutOfCombat)
	alwaysShowOutOfCombatCheckbox.tooltip = "This is where you place MouseOver Text."
	alwaysShowOutOfCombatCheckbox:SetScript("OnClick", function()
		CoolHealthBarSettings.alwaysShowOutOfCombat=not CoolHealthBarSettings.alwaysShowOutOfCombat
		applyAllSettings()
	end)
	
	-- print("--CoolHealthBarSettings start")
	-- print(""..CoolHealthBarSettings.showOutOfCombatWhenNotFull)
	-- print(""..CoolHealthBarSettings.alwaysShowOutOfCombat)
	-- print(""..CoolHealthBarSettings.barsWidth)
	-- print(""..CoolHealthBarSettings.healthBarHeight)
	-- print(""..CoolHealthBarSettings.powerBarHeight)
	-- print(""..CoolHealthBarSettings.offsetY)
	-- print(""..CoolHealthBarSettings.offsetX)
	-- print("--CoolHealthBarSettings end")
	
	local offsetYInputTitle = coolHealthBarOptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	--nameplate.health.text:SetAllPoints()
	--offsetYnputTitle:SetPoint("TOPLEFT", coolHealthBarOptionsFrame, "TOPLEFT", 12,-86)
	offsetYInputTitle:SetPoint("TOPLEFT", alwaysShowOutOfCombatCheckbox, "BOTTOMLEFT", 4, -8)
	offsetYInputTitle:SetTextColor(1,1,1,barAlpha)
	--offsetYnputTitle:SetFont("Interface\\AddOns\\CoolHealthBar\\fonts\\francois.ttf", 12, "OUTLINE")
	offsetYInputTitle:SetJustifyH("LEFT")
	offsetYInputTitle:SetText("Offset Y: ")
	
	local offsetYInput = CreateFrame("EditBox", nil, coolHealthBarOptionsFrame)
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
	
	local offsetXInputTitle = coolHealthBarOptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	--nameplate.health.text:SetAllPoints()
	--offsetXInputTitle:SetPoint("TOPLEFT", coolHealthBarOptionsFrame, "TOPLEFT", 12,-118)
	offsetXInputTitle:SetPoint("TOPLEFT", offsetYInputTitle, "BOTTOMLEFT", 0, -16)
	offsetXInputTitle:SetTextColor(1,1,1,barAlpha)
	--offsetXInputTitle:SetFont("Interface\\AddOns\\CoolHealthBar\\fonts\\francois.ttf", 12, "OUTLINE")
	offsetXInputTitle:SetJustifyH("LEFT")
	offsetXInputTitle:SetText("Offset X: ")
	
	local offsetXInput = CreateFrame("EditBox", nil, coolHealthBarOptionsFrame)
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
	
	local barWidthInputTitle = coolHealthBarOptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	barWidthInputTitle:SetPoint("TOPLEFT", offsetXInputTitle, "BOTTOMLEFT", 0, -16)
	barWidthInputTitle:SetTextColor(1,1,1,barAlpha)
	barWidthInputTitle:SetJustifyH("LEFT")
	barWidthInputTitle:SetText("Bar width: ")
	
	local barWidthInput = CreateFrame("EditBox", nil, coolHealthBarOptionsFrame)
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
	
	local hpBarHeightInputTitle = coolHealthBarOptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	hpBarHeightInputTitle:SetPoint("TOPLEFT", barWidthInputTitle, "BOTTOMLEFT", 0, -16)
	hpBarHeightInputTitle:SetTextColor(1,1,1,barAlpha)
	hpBarHeightInputTitle:SetJustifyH("LEFT")
	hpBarHeightInputTitle:SetText("HP bar height: ")
	
	local hpBarHeightInput = CreateFrame("EditBox", nil, coolHealthBarOptionsFrame)
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
	
	local powerBarHeightInputTitle = coolHealthBarOptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	powerBarHeightInputTitle:SetPoint("TOPLEFT", hpBarHeightInputTitle, "BOTTOMLEFT", 0, -16)
	powerBarHeightInputTitle:SetTextColor(1,1,1,barAlpha)
	powerBarHeightInputTitle:SetJustifyH("LEFT")
	powerBarHeightInputTitle:SetText("Power bar height: ")
	
	local powerBarHeightInput = CreateFrame("EditBox", nil, coolHealthBarOptionsFrame)
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