--local frame = CreateFrame("Frame")

local addonIsLoaded = false
local localVersion = "1.0.0"

local playerIsInCombatLockdown = false

local currentHp = 0
local maxHp = 0
local currentPower = 0
local maxPower = 0

local mainFrame = CreateFrame("Frame", "MainFrame", UIParent)
mainFrame:SetFrameStrata("LOW")

local barAlpha = 1
local barBackgroundAlpha = 0.5

local barsWidth = 400
local healthBarHeight = 20
local powerhBarHeight = 10

local offsetY = -327
local offsetX = 0

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
	
	--print("powertype: "..powerType)
	
	if powerType == 0 then
		mainFrame.power:SetStatusBarColor(0, 0, 1, barAlpha)
	elseif powerType == 1 then
		mainFrame.power:SetStatusBarColor(1, 0, 0, barAlpha)
	elseif powerType == 3 then
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

	if UnitAffectingCombat("player") or playerIsInCombatLockdown or (currentHp < maxHp) or (currentPower < maxPower) and maxHp > 0 and maxPower > 0 then
		shouldShow = true
	else
		shouldShow = false
	end
	
	if shouldShow then
		mainFrame:Show()
		mainFrame.health:Show()
		mainFrame.power:Show()
		mainFrame.borderImageL:Show()
		mainFrame.borderImageR:Show()
	else
		mainFrame:Hide()
		mainFrame.health:Hide()
		mainFrame.power:Hide()
		mainFrame.borderImageL:Hide()
		mainFrame.borderImageR:Hide()
	end
end

function CoolHealthBar_OnLoad(self)
	--print(string.format("%s: v%s by Redbu11 is loaded susscessfully\nThank you for using my addon", "CoolHealthBar", localVersion))
	addonIsLoaded = true

	--frame:SetScript("OnEvent", dispatchEvents)
	this:RegisterEvent("ADDON_LOADED")
	this:RegisterEvent("UNIT_HEALTH")
	this:RegisterEvent("UNIT_MANA")
	this:RegisterEvent("PLAYER_REGEN_DISABLED")
	this:RegisterEvent("PLAYER_REGEN_ENABLED")
	
	this:SetScript("OnEvent", function()
		-- if event == "ADDON_LOADED" then
			-- print("----------ADDON_LOADED: "..arg1)
		-- end
	
		if event == "UNIT_HEALTH" and UnitIsUnit(arg1, "player") then
			UpdateHealth()
		elseif event == "UNIT_MANA" and UnitIsUnit(arg1, "player") then
			UpdatePower()
		elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
			playerIsInCombatLockdown = arg1
			ChangeHealthBarVisibility()
		end
	end)
	
	--mainFrame:SetSize(500, 350)
	mainFrame:SetWidth(barsWidth+8)
	mainFrame:SetHeight(healthBarHeight+powerhBarHeight+8)
	mainFrame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
	
	mainFrame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		--edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	mainFrame:SetBackdropColor(0,0,0,.5)
	
	mainFrame.health = CreateFrame("StatusBar", nil, UIParent)
	mainFrame.health:SetFrameLevel(1) -- keep above glow
	mainFrame.health:SetOrientation("HORIZONTAL")
	mainFrame.health:SetStatusBarTexture(statusBarTexture)
	mainFrame.health:SetStatusBarColor(0, 1, 0, barAlpha)
	mainFrame.health:SetPoint("TOP", mainFrame, "TOP", 0, -4)
	mainFrame.health:SetWidth(barsWidth)
	mainFrame.health:SetHeight(healthBarHeight)
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
	
	
	mainFrame.power = CreateFrame("StatusBar", nil, UIParent)
	mainFrame.power:SetFrameLevel(1) -- keep above glow
	mainFrame.power:SetOrientation("HORIZONTAL")
	mainFrame.power:SetStatusBarTexture(statusBarTexture)
	mainFrame.power:SetStatusBarColor(0, 0, 1, barAlpha)
	mainFrame.power:SetPoint("TOP", mainFrame.health, "BOTTOM", 0, 0)
	mainFrame.power:SetWidth(barsWidth)
	mainFrame.power:SetHeight(powerhBarHeight)
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
	
	mainFrame.borderImageL = CreateFrame("Frame", nil, UIParent)
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

	mainFrame.borderImageR = CreateFrame("Frame", nil, UIParent)
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
	
	UpdateHealth()
	UpdatePower()
end

function CoolHealthBar_OnEvent(self, event, ...)
	-- and UnitName(arg1) == UnitName("player") 
	--local arg1 = ...
	-- if event == "UNIT_HEALTH" then
		-- print("asdasd")
		-- --print(event, ...)
		-- --mainFrame.health:SetMinMaxValues(0, UnitHealthMax("player"))
		-- --mainFrame.health:SetValue(UnitHealth("player"))
	-- end

	--print(string.format("event: %s", event));
	-- if event == "AUCTION_HOUSE_SHOW" then
		-- auctionHouseVisible = true
		-- auctionSortButton:SetPoint("TOPRIGHT",getglobal("AuctionFrame"),"TOPRIGHT",-22,-12)
		-- updateSortByBuyoutButton()
		-- --auctionSortButton:Show()
	-- elseif event == "AUCTION_HOUSE_CLOSED" then
		-- auctionHouseVisible = false
		-- --auctionSortButton:Hide()
		-- updateSortByBuyoutButton()
	-- end
end

-- local version = "1.0.13"

-- function dispatchEvents(self, event, arg1, ...)
	-- if event == "ADDON_LOADED" and arg1 == "CoolHealthBar" then
	    -- print(string.format("%s v%s is loaded susscessfully\nThank you for using my addon", arg1, version));
		-- --initSettings()
		-- addonIsLoaded = true
	-- end
	-- if addonIsLoaded then
		-- if (event == "BAG_UPDATE") then
		-- --do nothing
		-- elseif event == "UNIT_HEALTH" then
			-- --do nothing
		-- elseif event == "AUCTION_HOUSE_SHOW" then
			-- --do nothing
		-- elseif event == "AUCTION_HOUSE_CLOSED" then
			-- --do nothing
		-- end
	-- end	
-- end

-- function handleEvent(self, event, arg1, ...) 
	-- if (event == "BAG_UPDATE") then
		-- --do nothing
	-- elseif event == "UNIT_HEALTH" then
		-- --do nothing
	-- elseif event == "AUCTION_HOUSE_SHOW" then
		-- --do nothing
	-- elseif event == "AUCTION_HOUSE_CLOSED" then
		-- --do nothing
	-- end
-- end