SafeTradeSave       = nil -- saved settings and trusted people - defaults set up in ADDON_LOADED
local eventFrame    = CreateFrame("frame") -- anonymous frame to handle events
local inLockPhase   = nil -- if in locked mode where changes aren't allowed
local trustedTrader = nil -- if the current trader is trusted
local confirmTime   = nil -- GetTime() of when Confirm button is shown, to detect scam-like behavior

----------------------------------------------------------------------------------------------------
-- GUI elements
----------------------------------------------------------------------------------------------------
-- the Lock / fake Trade button
local buttonLock = CreateFrame("Button", "SafeTradeButtonLock", TradeFrame, "UIPanelButtonTemplate")
buttonLock:SetWidth(85)
buttonLock:SetHeight(22)
buttonLock:SetPoint("TOPLEFT", TradeFrameTradeButton, "TOPLEFT", 0, 0)
buttonLock.text = _G[buttonLock:GetName().."Text"] -- the text can change so save a reference for easier access

-- the Confirm button shown when there's a change after locking
local buttonConfirm = CreateFrame("Button", "SafeTradeButtonConfirm", TradeFrame, "UIPanelButtonTemplate")
buttonConfirm:SetWidth(126)
buttonConfirm:SetHeight(22)
buttonConfirm:SetPoint("TOPLEFT", TradeFrameTradeButton, "TOPLEFT", -172, 0)
_G[buttonConfirm:GetName().."Text"]:SetText("Confirm change")
buttonConfirm:SetScript("OnShow", function() confirmTime = GetTime() end)

-- the text shown when lock mode is enabled
local textLock = TradeFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
textLock:SetPoint("TOPLEFT", TradeFrameTradeButton, "TOPLEFT", -164, -3)
textLock:SetText("Locked")

----------------------------------------------------------------------------------------------------
-- handle GUI changes
----------------------------------------------------------------------------------------------------
-- set up the Trade button during unlocked mode - decides whether to enable locking or not
local function SetTradeButton()
	-- first check if the player is trading anything
	local player_is_trading = (GetPlayerTradeMoney() ~= 0) or SafeTradeSave.alwayslock
	if not player_is_trading then
		for i=1,6 do -- don't count the "Will not be traded" item
			if (GetTradePlayerItemLink(i)) ~= nil then
				player_is_trading = true
				break
			end
		end
	end

	if not player_is_trading then
		-- not trading anything, so just show the normal Trade button
		TradeFrameTradeButton:Show()
		buttonLock:Hide()
		buttonConfirm:Hide()
	else
		-- hide the Trade and Confirm buttons
		TradeFrameTradeButton:Hide()
		buttonConfirm:Hide()
		-- show the Lock button in place of the Trade button
		buttonLock.text:SetText("Lock")
		buttonLock:Enable()
		buttonLock:Show()
	end

	-- not in the locked phase, so all changes are allowed
	confirmTime = nil
	inLockPhase = false
	textLock:Hide()
end

-- set the trade as being in the locked phase
local function SetLockPhase()
	buttonConfirm:Hide()
	buttonLock:Hide()
	TradeFrameTradeButton:Show()
	confirmTime = nil
	inLockPhase = true
	textLock:Show()
end

buttonLock:SetScript("OnClick", SetLockPhase)
buttonConfirm:SetScript("OnClick", SetLockPhase)

----------------------------------------------------------------------------------------------------
-- handle events
----------------------------------------------------------------------------------------------------
-- handle when the player edits their money here because the PLAYER_TRADE_MONEY event is unreliable
hooksecurefunc("SetTradeMoney", function() if not trustedTrader then SetTradeButton() end end)

eventFrame:SetScript("OnEvent", function(self, event, ...)
	--------------------------------------------------
	-- the trade window opened
	--------------------------------------------------
	if event == "TRADE_SHOW" then
		-- check if they're a trusted person
		trustedTrader = (SafeTradeSave.trustguild and IsInGuild() and UnitIsInMyGuild("npc"))
		                or SafeTradeSave.trusted[UnitName("npc") or ""]
		if trustedTrader then -- they are trusted, so hide this addon's system
			textLock:Hide()
			buttonLock:Hide()
			buttonConfirm:Hide()
			TradeFrameTradeButton:Show()
			inLockPhase = false
			confirmTime = nil
		else -- they aren't trusted, so set up this addon's system
			SetTradeButton()
		end
		return
	end

	-- only care about changes below if it's not a trusted trader
	if not trustedTrader then
		--------------------------------------------------
		-- the player changed an item
		--------------------------------------------------
		if event == "TRADE_PLAYER_ITEM_CHANGED" then
			SetTradeButton()
			return
		end

		--------------------------------------------------
		-- other trader changed something
		--------------------------------------------------
		if event == "TRADE_TARGET_ITEM_CHANGED" or event == "TRADE_MONEY_CHANGED" then
			-- if during the locked phase, show the Confirm button
			if inLockPhase then
				TradeFrameTradeButton:Hide()
				textLock:Hide()
				buttonConfirm:Show()

				-- change Lock button to look like a disabled Trade button (because a lot of things can
				-- enable the real button again so using a fake one is safer/easier)
				buttonLock.text:SetText("Trade")
				buttonLock:Disable()
				buttonLock:Show()
			end
			return
		end

		--------------------------------------------------
		-- the trade window is being closed
		--------------------------------------------------
		if event == "TRADE_CLOSED" then
			if confirmTime and confirmTime > GetTime()-3 then
				DEFAULT_CHAT_FRAME:AddMessage("WARNING! The trade window closed soon after a change was made during locked mode. " ..
					"This is common in scams to try to hide a last second change when they did it too soon or late.", 1, 0, 0)
				confirmTime = nil -- unset because TRADE_CLOSED is received twice
			end
			return
		end
	end

	--------------------------------------------------
	-- addon loaded
	--------------------------------------------------
	if event == "ADDON_LOADED" and (...) == "SafeTrade" then
		eventFrame:UnregisterEvent(event)
		-- set default settings if needed
		if SafeTradeSave            == nil then SafeTradeSave            = {}    end
		if SafeTradeSave.trustguild == nil then SafeTradeSave.trustguild = false end
		if SafeTradeSave.alwayslock == nil then SafeTradeSave.alwayslock = false end
		if SafeTradeSave.trusted    == nil then SafeTradeSave.trusted    = {}    end
		return
	end
end)

eventFrame:RegisterEvent("TRADE_SHOW")                -- to set up buttons and initiate the system
eventFrame:RegisterEvent("TRADE_CLOSED")              -- to check for quick canceling after changes
eventFrame:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED") -- to know when the player changes items
eventFrame:RegisterEvent("TRADE_TARGET_ITEM_CHANGED") -- to know when the other trader changes items
eventFrame:RegisterEvent("TRADE_MONEY_CHANGED")       -- to know when the other trader changes money
eventFrame:RegisterEvent("ADDON_LOADED")              -- temporary - initiate settings if needed

----------------------------------------------------------------------------------------------------
-- slash command
----------------------------------------------------------------------------------------------------
-- show the trusted player list
local function ShowTrustedList()
	local list = {}
	for name in pairs(SafeTradeSave.trusted) do
		list[#list+1] = name
	end
	if #list > 0 then
		DEFAULT_CHAT_FRAME:AddMessage(" ")
		DEFAULT_CHAT_FRAME:AddMessage("Trusted list: " .. table.concat(list, ", "))
	end
end

_G.SLASH_SAFETRADE1 = "/safetrade"
function SlashCmdList.SAFETRADE(input)
	input = input or ""

	local command, value = input:match("(%w+)%s*(.*)")
	command = command or input -- if using input, then it's a single command without a value
	command = command:lower()
	-- capitalize the value
	if value then
		value = (value:gsub("(%a)(%w*)", function(first,rest) return first:upper()..rest:lower() end))
	end

	local ON_TEXT  = "|cff00FF00ON|r"
	local OFF_TEXT = "|cffFF0000OFF|r"

	--------------------------------------------------
	-- /safetrade trust [name]
	--------------------------------------------------
	if command == "trust" then
		if not value or value == "" then
			DEFAULT_CHAT_FRAME:AddMessage('Syntax: /safetrade trust [name]')
			ShowTrustedList()
			return
		end
		if SafeTradeSave.trusted[value] then
			SafeTradeSave.trusted[value] = nil
		else
			SafeTradeSave.trusted[value] = true
		end
		DEFAULT_CHAT_FRAME:AddMessage(value .. " is now " .. (SafeTradeSave.trusted[value] and "trusted" or "untrusted") .. " in trades.")
		return
	end

	--------------------------------------------------
	-- /safetrade trustguild <on|off>
	--------------------------------------------------
	if command == "trustguild" then
		if value == "On" then
			SafeTradeSave.trustguild = true
		elseif value == "Off" then
			SafeTradeSave.trustguild = false
		else
			DEFAULT_CHAT_FRAME:AddMessage('Syntax: /safetrade trustguild <"on"|"off">')
		end
		DEFAULT_CHAT_FRAME:AddMessage("Trusting guild members is " .. (SafeTradeSave.trustguild and ON_TEXT or OFF_TEXT) .. ".")
		return
	end

	--------------------------------------------------
	-- /safetrade alwayslock <on|off>
	--------------------------------------------------
	if command == "alwayslock" then
		if value == "On" then
			SafeTradeSave.alwayslock = true
		elseif value == "Off" then
			SafeTradeSave.alwayslock = false
		else
			DEFAULT_CHAT_FRAME:AddMessage('Syntax: /safetrade alwayslock <"on"|"off">')
		end
		DEFAULT_CHAT_FRAME:AddMessage("Always using the Lock system is " .. (SafeTradeSave.alwayslock and ON_TEXT or OFF_TEXT) .. ".")
		return
	end

	--------------------------------------------------
	-- no command - show syntax and trusted list
	--------------------------------------------------
	DEFAULT_CHAT_FRAME:AddMessage('SafeTrade commands:', 1, 1, 0)
	DEFAULT_CHAT_FRAME:AddMessage('/safetrade trust [name]')
	DEFAULT_CHAT_FRAME:AddMessage('/safetrade trustguild <"on"|"off"> - now ' .. (SafeTradeSave.trustguild and ON_TEXT or OFF_TEXT))
	DEFAULT_CHAT_FRAME:AddMessage('/safetrade alwayslock <"on"|"off"> - now ' .. (SafeTradeSave.alwayslock and ON_TEXT or OFF_TEXT))
	ShowTrustedList()
end
