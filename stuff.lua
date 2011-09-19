--Stuffing--
--All credits of this bags script is by Stuffing and his author Hungtar.--
local M = DerpyData[1]
local names = DerpyData[2]['stuffing']
local BAGS_BACKPACK = {0, 1, 2, 3, 4}
local BAGS_BANK = {-1, 5, 6, 7, 8, 9, 10, 11}
local BAGSFONT = M["media"].font
local ST_NORMAL = 1
local ST_SPECIAL = 3
local s_frame = M.frame
local s_find = string.find
local s_string_lower = string.lower
local unpack = unpack
local ipairs = ipairs
local tinsert = tinsert
local sort = table.sort
local tremove = table.remove
local select = select
local grad = {"VERTICAL",.5,.5,.5,1,1,1}
local C = select(2,...)
C.Stuffing = CreateFrame ("Frame", "Stuffing", UIParent)
local Stuffing = C.Stuffing
local getglobal = getglobal
local fakestatusbar_
local GetItemInfo = GetItemInfo
local InCombatLockdown = InCombatLockdown

local function Stuffing_Sort(args)
	if not args then args = "" end
	Stuffing.itmax = 0
	Stuffing:SetBagsForSorting(args)
	Stuffing:SortBags()
end

local function Stuffing_OnShow()
	Stuffing:PLAYERBANKSLOTS_CHANGED(29)	-- XXX: hack to force bag frame update
	Stuffing:Layout()
	Stuffing:SearchReset()
end

local function StuffingBank_OnHide()
	CloseBankFrame()
	if Stuffing.frame:IsShown() then
		Stuffing.frame:Hide()
	end
end

local function Stuffing_OnHide()
	if Stuffing.bankFrame and Stuffing.bankFrame:IsShown() then
		Stuffing.bankFrame:Hide()
	end
end

local function Stuffing_Open()
	Stuffing.frame:show()
end

local function Stuffing_Close()
	Stuffing.frame:Hide()
end

local function Stuffing_Toggle()
	if Stuffing.frame:IsShown() then
		Stuffing.frame:Hide()
	else
		Stuffing.frame:show()
	end
end

local function Stuffing_ToggleBag(id)
	if id == -2 then return end
	Stuffing_Toggle()
end

local HideItAll = function(...)
	for index = 1, select('#',...) do
		local puppy = select(index, ...)
		if not puppy.donthide then
			puppy:Hide()
		end
	end
end

local ShowItAll = function(...)
	for index = 1, select('#',...) do
		local puppy = select(index, ...)
		if not puppy.donthide then
			puppy:Show()
		end
	end
end

local function DragFunction(self,mode)
	if mode then
		self.dragtex:Show()
		HideItAll(self:GetChildren())
	else
		self.dragtex:Hide()
		ShowItAll(self:GetChildren())
	end
end

local function StartMoving(self)
	self:StartMoving()
	self:DragFunction(true)
end

local function StopMoving(self)
	self:StopMovingOrSizing()
	self:DragFunction(false)
end

--
-- bag slot stuff
--
local trashParent = CreateFrame("Frame", nil, UIParent)
local trashButton = {}
local trashBag = {}

-- for the tooltip frame used to scan item tooltips
local StuffingTT = CreateFrame("GameTooltip", "StuffingTT", nil, "GameTooltipTemplate")
StuffingTT:Hide()

-- mostly from cargBags_Aurora
local QUEST_ITEM_STRING = nil

function Stuffing:SlotUpdate(b)
	local texture, count, locked = GetContainerItemInfo (b.bag, b.slot)
	local clink = GetContainerItemLink(b.bag, b.slot)

	if b.Cooldown then
		local cd_start, cd_finish, cd_enable = GetContainerItemCooldown(b.bag, b.slot)
		CooldownFrame_SetTimer(b.Cooldown, cd_start, cd_finish, cd_enable)
	end

	if(clink) then
		local iType
		b.name, _, b.rarity, _, _, iType = GetItemInfo(clink)

			if QUEST_ITEM_STRING == nil then
				-- GetItemInfo returns a localized item type.
				-- this is to figure out what that string is.
				local t = {GetAuctionItemClasses()}
				QUEST_ITEM_STRING = t[#t]	-- #t == 12
			end

			-- load tooltip, check if ITEM_BIND_QUEST ("Quest Item") is in it.
			-- If the tooltip says its a quest item, we assume it is a quest item
			-- and ignore the item type from GetItemInfo.
			StuffingTT:SetOwner(WorldFrame, "ANCHOR_NONE")
			StuffingTT:ClearLines()
			StuffingTT:SetBagItem(b.bag, b.slot)
			for i = 1, StuffingTT:NumLines() do
				local txt = getglobal("StuffingTTTextLeft" .. i)
				if txt then
					local text = txt:GetText()
					if s_find(txt:GetText(), ITEM_BIND_QUEST) then
						iType = QUEST_ITEM_STRING
					end
				end
			end

			if iType and iType == QUEST_ITEM_STRING then
				b.qitem = true
			else
				b.qitem = nil
			end

	else
		b.name, b.rarity, b.qitem = nil, nil, nil
	end
	
	SetItemButtonTexture(b.frame, texture)
	SetItemButtonCount(b.frame, count)
	SetItemButtonDesaturated(b.frame, locked, 0.5, 0.5, 0.5)

	if b.Glow then
		b.Glow:Show()
		if b.rarity then
			if b.rarity > 1 then
				local r,g,y = GetItemQualityColor(b.rarity)
				b.Glow:backcolor(r,g,y,.8)
			elseif b.qitem then
				b.Glow:backcolor(1.0, 0.3, 0.3,.8)
			else
				b.Glow:backcolor(0,0,0,.8)
			end
		else
			b.Glow:backcolor(0,0,0)
		end
	end
	
	if b.iconTex then
		b.iconTex:SetGradient(unpack(grad))
	end
	
	b.frame:Show()
end


function Stuffing:BagSlotUpdate(bag)
	if not self.buttons then
		return
	end

	for _, v in ipairs (self.buttons) do
		if v.bag == bag then
			self:SlotUpdate(v)
		end
	end
end

local setbagicons = function(self)
	local name = self:GetName()
	local Icon = 		_G[name.."IconTexture"]
	local Count = 		_G[name.."Count"]
	local Border =		_G[name.."NormalTexture"]
	local Push =		self:GetPushedTexture()
	local HI =			self:GetHighlightTexture()
	
		Icon:SetTexCoord(.1,.9,.1,.9)
		Border:SetTexture(nil)
		Count:SetFont(BAGSFONT,13,"OUTLINE")
		Count:SetShadowOffset(1,-1)
		Count:ClearAllPoints()
		Count:SetPoint("TOPRIGHT",.3,.3)
		Push:SetTexture(.3,.3,.3,.5)
		HI:SetTexture(1,1,1,.4)
		
	if not self.m_bg then
		local bg = s_frame(self)
		bg:SetPoint("TOPLEFT",-4,4)
		bg:SetPoint("BOTTOMRIGHT",4,-4)
		bg:SetFrameStrata(self:GetFrameStrata())
		bg:SetFrameLevel(self:GetFrameLevel()-2)
		self.m_bg = bg
	end
	
		self:SetSize(30,30)
		
end

function Stuffing:BagFrameSlotNew (slot, p)
	for _, v in ipairs(self.bagframe_buttons) do
		if v.slot == slot then
			return v, false
		end
	end

	local ret = {}
	local tpl

	if slot > 3 then
		ret.slot = slot
		slot = slot - 4
		tpl = "BankItemButtonBagTemplate"
		ret.frame = CreateFrame("CheckButton", "StuffingBBag" .. slot, p, tpl)
		setbagicons(ret.frame)
		ret.frame:SetID(slot + 4)
		tinsert(self.bagframe_buttons, ret)

		BankFrameItemButton_Update(ret.frame)
		BankFrameItemButton_UpdateLocked(ret.frame)

		if not ret.frame.tooltipText then
			ret.frame.tooltipText = ""
		end
	else
		tpl = "BagSlotButtonTemplate"
		ret.frame = CreateFrame("CheckButton", "StuffingFBag" .. slot .. "Slot", p, tpl)
		setbagicons(ret.frame)
		ret.slot = slot
		tinsert(self.bagframe_buttons, ret)
	end

	return ret
end


function Stuffing:SlotNew (bag, slot)
	for _, v in ipairs(self.buttons) do
		if v.bag == bag and v.slot == slot then
			return v, false
		end
	end

	local tpl = "ContainerFrameItemButtonTemplate"

	if bag == -1 then
		tpl = "BankItemButtonGenericTemplate"
	end

	local ret = {}

	if #trashButton > 0 then
		local f = -1
		for i, v in ipairs(trashButton) do
			local b, s = v:GetName():match("(%d+)_(%d+)")

			b = tonumber(b)
			s = tonumber(s)

			if b == bag and s == slot then
				f = i
				break
			end
		end

		if f ~= -1 then
			ret.frame = trashButton[f]
			tremove(trashButton, f)
		end
	end

	if not ret.frame then
		ret.frame = CreateFrame("Button", "StuffingBag" .. bag .. "_" .. slot, self.bags[bag], tpl)
	end

	ret.bag = bag
	ret.slot = slot
	ret.frame:SetID(slot)

	if not ret.Glow then
		-- from cargBags_Aurora
		local glow = s_frame(ret.frame)
		glow:SetFrameStrata(ret.frame:GetFrameStrata())
		glow:SetFrameLevel(ret.frame:GetFrameLevel()-2)
		glow:SetPoint("TOPLEFT",-4,4)
		glow:SetPoint("BOTTOMRIGHT",4,-4)
		ret.Glow = glow
	end

	ret.Cooldown = _G[ret.frame:GetName() .. "Cooldown"]
	ret.Cooldown:Show()

	self:SlotUpdate (ret)

	return ret, true
end


-- from OneBag
local BAGTYPE_PROFESSION = 0x0008 + 0x0010 + 0x0020 + 0x0040 + 0x0080 + 0x0200 + 0x0400

function Stuffing:BagType(bag)
	local bagType = select(2, GetContainerNumFreeSlots(bag))
	if bit.band(bagType, BAGTYPE_PROFESSION) > 0 then
		return ST_SPECIAL
	end

	return ST_NORMAL
end


function Stuffing:BagNew (bag, f)
	for i, v in pairs(self.bags) do
		if v:GetID() == bag then
			v.bagType = self:BagType(bag)
			return v
		end
	end

	local ret

	if #trashBag > 0 then
		local f = -1
		for i, v in pairs(trashBag) do
			if v:GetID() == bag then
				f = i
				break
			end
		end

		if f ~= -1 then
			ret = trashBag[f]
			tremove(trashBag, f)
			ret:Show()
			ret.bagType = self:BagType(bag)
			return ret
		end
	end

	ret = CreateFrame("Frame", "StuffingBag" .. bag, f)
	ret.bagType = self:BagType(bag)
	ret:SetID(bag)
	return ret
end


function Stuffing:SearchUpdate(str)
	str = s_string_lower(str)

	for _, b in ipairs(self.buttons) do
		if b.name then
			if b.iconTex then
				b.iconTex:SetGradient(unpack(grad))
			end
			if not s_find(s_string_lower(b.name), str) then
				SetItemButtonDesaturated(b.frame, 1, 1, 1, 1)
				if b.iconTex then
					b.iconTex:SetGradient(unpack(grad))
				end
				if b.Glow then
					b.Glow:Show()
					b.Glow:backcolor(0,0,0)
				end
			else
				SetItemButtonDesaturated(b.frame, 0, 1, 1, 1)
				if b.iconTex then
					b.iconTex:SetGradient(unpack(grad))
				end
				if b.Glow then
					b.Glow:Show()
					b.Glow:backcolor(1,.7,.1,.8)
				end
			end
		end
	end
end


function Stuffing:SearchReset()
	for _, b in ipairs(self.buttons) do
		SetItemButtonDesaturated(b.frame, 0, 1, 1, 1)
		if b.iconTex then
			b.iconTex:SetGradient(unpack(grad))
		end
		if b.Glow then
			b.Glow:Show()
			if b.rarity then
				if b.rarity > 1 then
					local r,g,y = GetItemQualityColor(b.rarity)
					b.Glow:backcolor(r,g,y,.8)
				elseif b.qitem then
					b.Glow:backcolor(1.0,0.3,0.3,.8)
				else
					b.Glow:backcolor(0,0,0,.8)
				end
			else
				b.Glow:backcolor(0,0,0)
			end
		end
	end
end

local enter_bt = function(self) self:backcolor(1,.7,.2,.8) end
local leave_bt = function(self) self:backcolor(0,0,0) end

local bt_mk = function(func,text,f,x,off)
	local bt = CreateFrame("Button",nil,f)	
		bt:SetSize(x or 62,24)
		bt:SetScript("OnClick",func)
		bt:SetFrameLevel(f:GetFrameLevel()+5)
		bt:RegisterForClicks("AnyDown")
		M.ChangeTemplate(bt)
		local t = M.setfont(bt,13)
		t:SetPoint("CENTER",off or 0.3,.3)
		t:SetText(text)
		bt.text = t
		bt:SetScript("OnEnter",enter_bt)
		bt:SetScript("OnLeave",leave_bt)
	return bt
end

function Stuffing:CreateBagFrame(w)
	local n = "StuffingFrame"  .. w
	local f = CreateFrame ("Frame", n, UIParent)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetToplevel(1)
	f:SetFrameStrata("HIGH")
	f:SetFrameLevel(20)
	M.make_plav(f,.3)
	f:hide()
	
	local up_frame = s_frame(f)
	up_frame:SetPoint("TOPLEFT",2,-4)
	up_frame:SetPoint("TOPRIGHT",-2,-4)
	up_frame:SetFrameStrata(f:GetFrameStrata())
	up_frame:SetFrameLevel(f:GetFrameLevel()-2)
	up_frame:SetHeight(32)
	up_frame.donthide = true
	
	local dragtex = CreateFrame("Frame",nil,f)
	dragtex:SetFrameStrata("MEDIUM")
	dragtex:SetFrameLevel(0)
	dragtex:SetPoint("TOP",0,-7)
	dragtex:SetPoint("TOPLEFT",5,-7)
	dragtex:SetPoint("TOPRIGHT",-5,-7)
	dragtex:SetPoint("BOTTOM")
	dragtex.donthide = true

	local tex = dragtex:CreateTexture(nil,"BORDER")
	tex:SetTexture(M.media.blank)
	tex:SetGradientAlpha("VERTICAL",0,.8,.8,0,0,.5,.9,1)
	tex:SetAllPoints()
	
	f:HookScript("OnShow",function(self)
		self.dragtex:Hide()
	end)
	
	dragtex:Hide()
	f.dragtex = dragtex
	f.DragFunction = DragFunction
	
	local x = 90
	-- GetCoinTextureString(GetMoney(),12)
	if w == "Bank" then
		local ct,full = GetNumBankSlots()
		if not full then
			local buy = function(self)
				PurchaseSlot()
				self:_update()
			end
			local button = bt_mk(buy,"BUY - "..(7-ct).." - "..GetCoinTextureString(GetBankSlotCost(),11),f,144)
			button:SetPoint("LEFT",up_frame,4,0)
			local bt_update = CreateFrame("Frame",nil,button)
			bt_update:Hide()
			button.perv = ct
			button.donthide = true
			bt_update.timer = .3
			button.bt_update = bt_update
			button._update = function(self)
				if GetBankSlotCost()-GetMoney() > 0 then 
					local _,a = GetNumBankSlots()
					if a then self:Hide() end
					return
				end
				self.bt_update.timer = .3
				self.bt_update:Show()
			end
			button.bt_update:SetScript("OnUpdate",function(self,t)
				self.timer = self.timer-t
				if self.timer > 0 then return end
				local bt = self:GetParent()
				local ct,full = GetNumBankSlots()
				if full then bt:Hide() self:Hide() return end
				if ct == bt.perv then self.timer=.3 return end
				bt.text:SetText("BUY - "..(7-ct).." - "..GetCoinTextureString(GetBankSlotCost(),11))
				bt.perv = ct
				self:Hide()
			end)
		end
		f:SetPoint ("LEFT",x,0)
	else
		f:SetPoint ("RIGHT",-x,0)
	end
	f:SetScript("OnMouseDown", StartMoving)
	f:SetScript("OnMouseUp", StopMoving)

	-- close button
	f.b_close = CreateFrame("Button", "Stuffing_CloseButton" .. w, f)
	f.b_close:SetSize(24,24)
	f.b_close:SetPoint("RIGHT",up_frame,-4,0)
	f.b_close:SetScript("OnClick", function(self) self:GetParent():Hide() end)
	f.b_close:RegisterForClicks("AnyUp")
	f.b_close.donthide = true
	x = f.b_close:CreateTexture(nil,"OVERLAY")
	x:SetSize(16,16)
	x:SetPoint("CENTER")
	x:SetTexture(M['media'].crosstex)
	x:SetVertexColor(1,0,0)
	M.ChangeTemplate(f.b_close)
	f.b_close:SetScript("OnEnter",function() x:SetVertexColor(1,.7,.2) end)
	f.b_close:SetScript("OnLeave",function() x:SetVertexColor(1,0,0) end)
	f.up_frame = up_frame
	-- create the bags frame
	local fb = CreateFrame ("Frame", n .. "BagsFrame", f)
		if w == "Bank" then
			fb:SetPoint("TOPLEFT", up_frame, "BOTTOMRIGHT", 1, 0)
		else
			fb:SetPoint("TOPRIGHT", up_frame, "BOTTOMLEFT", -1, 0)
		end
	f.bags_frame = fb

	return f
end


function Stuffing:InitBank()
	if self.bankFrame then return end
	local f = self:CreateBagFrame("Bank")
	f:SetScript("OnHide", StuffingBank_OnHide)
	self.bankFrame = f
end

function Stuffing:SetBagsForSorting(c)
	Stuffing_Open()

	self.sortBags = {}

	local cmd = ((c == nil or c == "") and {"d"} or {strsplit("/", c)})

	for _, s in ipairs(cmd) do
		if s == "c" then
			self.sortBags = {}
		elseif s == "d" then
			if not self.bankFrame or not self.bankFrame:IsShown() then
				for _, i in ipairs(BAGS_BACKPACK) do
					if self.bags[i] and self.bags[i].bagType == ST_NORMAL then
						tinsert(self.sortBags, i)
					end
				end
			else
				for _, i in ipairs(BAGS_BANK) do
					if self.bags[i] and self.bags[i].bagType == ST_NORMAL then
						tinsert(self.sortBags, i)
					end
				end
			end
		elseif s == "p" then
			if not self.bankFrame or not self.bankFrame:IsShown() then
				for _, i in ipairs(BAGS_BACKPACK) do
					if self.bags[i] and self.bags[i].bagType == ST_SPECIAL then
						tinsert(self.sortBags, i)
					end
				end
			else
				for _, i in ipairs(BAGS_BANK) do
					if self.bags[i] and self.bags[i].bagType == ST_SPECIAL then
						tinsert(self.sortBags, i)
					end
				end
			end
		else
			tinsert(self.sortBags, tonumber(s))
		end
	end
end

local parent_startmoving = function(self,bt)
	if bt ~= "LeftButton" then return end
	StartMoving(self:GetParent())
end

local parent_stopmovingorsizing = function (self)
	StopMoving(self:GetParent())
end

function Stuffing:InitBags()
	if self.frame then
		return
	end

	self.buttons = {}
	self.bags = {}
	self.bagframe_buttons = {}

	local f = self:CreateBagFrame("Bags")
	f:SetScript("OnShow", Stuffing_OnShow)
	f:SetScript("OnHide", Stuffing_OnHide)

	-- search editbox (tekKonfigAboutPanel.lua)
	local editbox = CreateFrame("EditBox", nil, f)
	editbox:SetFont(BAGSFONT,13)
	editbox:SetShadowOffset(1,-1)
	editbox:Hide()
	editbox:SetAutoFocus(true)
	editbox:SetHeight(32)

	local resetAndClear = function (self)
		self:GetParent().detail:Show()
		self:GetParent().bt_holder:Show()
		self:ClearFocus()
		Stuffing:SearchReset()
	end

	local updateSearch = function(self, t)
		if t == true then
			Stuffing:SearchUpdate(self:GetText())
		end
	end

	editbox:SetScript("OnEscapePressed", resetAndClear)
	editbox:SetScript("OnEnterPressed", resetAndClear)
	editbox:SetScript("OnEditFocusLost", editbox.Hide)
	editbox:SetScript("OnEditFocusGained", editbox.HighlightText)
	editbox:SetScript("OnTextChanged", updateSearch)
	editbox:SetText(names.srch)

	local detail = M.setfont(f,13)
	detail:SetPoint("LEFT", f.up_frame, 10,0)
	detail:SetPoint("RIGHT",f.up_frame, -44,0)
	detail:SetHeight(13)
	detail:SetJustifyH("LEFT")
	detail:SetText("|cffffff33" .. names.srch)
	editbox:SetAllPoints(detail)
	
	local bt_holder = CreateFrame("Frame",nil,f)
	bt_holder:SetFrameLevel(f:GetFrameLevel()+4)
	f.bt_holder = bt_holder
	
	local gold_backdrop = s_frame(bt_holder,f:GetFrameLevel()+3,f:GetFrameStrata())
	gold_backdrop:SetHeight(24)
	
	local gold = M.setfont(bt_holder,14,nil,nil,"RIGHT")
	gold:SetPoint("RIGHT",f.b_close,"LEFT", -11, 0)
	
	gold_backdrop:SetPoint("RIGHT",f.b_close,"LEFT",2,0)
	f.gold_backdrop = gold_backdrop
	
	f:SetScript("OnEvent", function (self, e)
		self.gold:SetText(GetCoinTextureString(GetMoney(),12))
		local x = self.gold:GetWidth()
		self.gold_backdrop:SetPoint("LEFT",self.gold,-13-(x-floor(x)),0)
	end)

	local fakestatusbar = CreateFrame("StatusBar",nil,bt_holder)
	fakestatusbar_ = fakestatusbar
	
	local sortpress = function(self,button)
		if InCombatLockdown() then return end
		fakestatusbar:run_it()
		if button == "RightButton" then
			Stuffing_Sort('c/p')
		else
			Stuffing_Sort()
		end
	end

	local stakpress = function()
		if InCombatLockdown() then return end
		fakestatusbar:run_it()
		Stuffing:SetBagsForSorting()
		Stuffing:Restack()
	end
	
	local sortbutton = bt_mk(sortpress,"|cffff33ff1|r.|cff0088ff2|r.|cff00ff003|r.4",bt_holder)
	sortbutton:SetPoint("RIGHT",gold_backdrop,"LEFT",2,0)
	
	local sortbutton2 = bt_mk(stakpress,">>|cff00ff0020|r<<",bt_holder)
	sortbutton2:SetPoint("RIGHT",sortbutton,"LEFT",2,0)
	
	fakestatusbar:SetMinMaxValues(0,2)
	fakestatusbar:SetValue(0)
	fakestatusbar:SetFrameLevel(f:GetFrameLevel()+12)
	fakestatusbar.current = 0
	fakestatusbar:SetStatusBarTexture(M['media'].barv)
	fakestatusbar:SetAlpha(0)
	fakestatusbar:SetPoint("TOPLEFT",sortbutton2,4,-4)
	fakestatusbar:SetPoint("BOTTOMRIGHT",sortbutton,-4,4)
	
	local _update = function(self,t)
		self.current = self.current + t
		self:SetValue(self.current)
		if self.current > 2 then self.current = 0 end
	end
	
	fakestatusbar.run_it = function(self)
		UIFrameFadeIn(self,.3,0,1)
		self:SetStatusBarColor(1,.7,.2,.9)
		UIFrameFadeOut(sortbutton,.3,1,0)
		UIFrameFadeOut(sortbutton2,.3,1,0)
		self.current = 0
		self:SetScript("OnUpdate",_update)
		sortbutton:EnableMouse(false)
		sortbutton2:EnableMouse(false)
	end
	
	fakestatusbar.stop_it = function(self)
		UIFrameFadeOut(self,.3,1,0)
		UIFrameFadeIn(sortbutton,.3,0,1)
		UIFrameFadeIn(sortbutton2,.3,0,1)
		self:SetStatusBarColor(0,1,0,.9)
		self:SetValue(2)
		self:SetScript("OnUpdate",nil)
		sortbutton:EnableMouse(true)
		sortbutton2:EnableMouse(true)
	end
	
	local bg_ = s_frame(fakestatusbar,f:GetFrameLevel()+10,f:GetFrameStrata())
	bg_:SetPoint("TOPLEFT",-4,4)
	bg_:SetPoint("BOTTOMRIGHT",4,-4)
	
	f:RegisterEvent("PLAYER_MONEY")
	f:RegisterEvent("PLAYER_LOGIN")
	f:RegisterEvent("PLAYER_TRADE_MONEY")
	f:RegisterEvent("TRADE_MONEY_CHANGED")
	
	local OpenEditbox = function(self)
		self:GetParent().detail:Hide()
		self:GetParent().bt_holder:Hide()
		self:GetParent().editbox:Show()
		self:GetParent().editbox:HighlightText()
	end
	
	local button = CreateFrame("Button", nil, f)
	button:EnableMouse(1)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:SetAllPoints(detail)
	button:SetScript("OnClick", function(self, btn)
		if btn == "RightButton" then
			OpenEditbox(self)
		else
			if self:GetParent().editbox:IsShown() then
				self:GetParent().editbox:Hide()
				self:GetParent().editbox:ClearFocus()
				self:GetParent().detail:Show()
				self:GetParent().bt_holder:Show()
				Stuffing:SearchReset()
			end
		end
	end)

	local tooltip_hide = function()
		GameTooltip:Hide()
	end

	local tooltip_show = function (self)
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
		GameTooltip:ClearLines()
		GameTooltip:SetText(names.rclick)
	end

	button:SetScript("OnEnter", tooltip_show)
	button:SetScript("OnLeave", tooltip_hide)
	
	button:SetScript("OnMouseDown", parent_startmoving)
	button:SetScript("OnMouseUp", parent_stopmovingorsizing)

	editbox.donthide = true
	detail.donthide = true
	button.donthide = true
	gold.donthide = true
	bt_holder.donthide = true
	
	f.editbox = editbox
	f.detail = detail
	f.button = button
	f.gold = gold
	self.frame = f
	f:Hide()
end


function Stuffing:Layout(lb)
	local slots = 0
	local rows = 0
	local off = 26
	local cols
	local f
	local bs
	
	if lb then
		bs = BAGS_BANK
		cols = 10
		f = self.bankFrame
	else
		bs = BAGS_BACKPACK
		cols = 10
		f = self.frame
		f.gold:SetText(GetCoinTextureString(GetMoney(), 12))
	end

	f:SetClampedToScreen(1)
	
	-- bag frame stuff
	local fb = f.bags_frame
	fb:SetClampedToScreen(1)
	local bsize = 32
	if lb then
		fb:SetHeight(7*bsize+26)
	else
		fb:SetHeight(4*bsize+14)
	end
	fb:SetWidth(bsize)
	fb:Show()

	local idx = 0
	for _, v in ipairs(bs) do
		if (not lb and v <= 3 ) or (lb and v ~= -1) then
			local bsize = 32

			local b = self:BagFrameSlotNew(v, fb)

			local off = 2

			off = off + (idx * bsize) + (idx * 4)
			
			b.frame:ClearAllPoints()
			b.frame:SetPoint("TOP", fb, 0, -off)
			b.frame:Show()

			idx = idx + 1
		end
	end


	for _, i in ipairs(bs) do
		local x = GetContainerNumSlots(i)
		if x > 0 then
			if not self.bags[i] then
				self.bags[i] = self:BagNew(i, f)
			end
		
			slots = slots + GetContainerNumSlots(i)	
		end
	end


	rows = floor (slots / cols)
	if (slots % cols) ~= 0 then
		rows = rows + 1
	end

	f:SetWidth(cols * 30
			+ (cols - 1) * 6 + 12)

	f:SetHeight(rows * 30
			+ (rows - 1) * 6
			+ off + 17 * 2)


	local idx = 0
	for _, i in ipairs(bs) do
		local bag_cnt = GetContainerNumSlots(i)

		if bag_cnt > 0 then
			self.bags[i] = self:BagNew(i, f)
			local bagType = self.bags[i].bagType

			self.bags[i]:Show()
				for j = 1, bag_cnt do
					local b, isnew = self:SlotNew (i, j)
					local xoff
					local yoff
					local x = (idx % cols)
					local y = floor(idx / cols)

					if isnew then
						tinsert(self.buttons, idx + 1, b)
					end

					xoff = 6 + (x * 30) + (x * 6)
					yoff = off + 18 + (y * 30) + ((y - 1) * 6)
					yoff = yoff * -1

					b.frame:ClearAllPoints()
					b.frame:SetPoint("TOPLEFT", f, "TOPLEFT", xoff, yoff)
					b.frame:SetHeight(30)
					b.frame:SetWidth(30)
					b.frame:Show()

					local normalTex = _G[b.frame:GetName() .. "NormalTexture"]
					normalTex:SetTexture(nil)
					b.normalTex = normalTex
					
					local Push = b.frame:GetPushedTexture()
					local HI = b.frame:GetHighlightTexture()
	
						Push:SetTexture(.3,.3,.3,.5)
						HI:SetTexture(1,1,1,.4)
					
					local iconTex = _G[b.frame:GetName() .. "IconTexture"]
						iconTex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
						iconTex:ClearAllPoints()
						iconTex:SetPoint("TOPLEFT", b.frame)
						iconTex:SetPoint("BOTTOMRIGHT", b.frame)
					iconTex:Show()
					b.iconTex = iconTex		
					
					local scount = _G[b.frame:GetName() .. "Count"]
						scount:SetFont (BAGSFONT, 13, "OUTLINE")
						scount:SetShadowOffset(1,-1)
						scount:ClearAllPoints()
						scount:SetPoint("TOPRIGHT",b.frame,.3,.3)
						b.scount = scount

					if b.Glow then
						b.Glow:SetPoint("TOPLEFT", b.frame,-4,4)
						b.Glow:SetPoint("BOTTOMRIGHT", b.frame,4,-4)
							if bagType == ST_SPECIAL then
								b.Glow:SetBackdropBorderColor(0,0,1,.2)
							elseif bagType == ST_NORMAL then
								b.Glow:SetBackdropBorderColor(unpack(M["media"].shadow))
							end
					end

					idx = idx + 1
				end
				
		end
	end
end

function Stuffing:PLAYERBANKSLOTS_CHANGED(id)
	if id > 28 then
		for _, v in ipairs(self.bagframe_buttons) do
			if v.frame and v.frame.GetInventorySlot then

				BankFrameItemButton_Update(v.frame)
				BankFrameItemButton_UpdateLocked(v.frame)

				if not v.frame.tooltipText then
					v.frame.tooltipText = ""
				end
			end
		end
	end

	if self.bankFrame and self.bankFrame:IsShown() then
		self:BagSlotUpdate(-1)
	end
end


function Stuffing:BAG_UPDATE(id)
	self:BagSlotUpdate(id)
end


function Stuffing:ITEM_LOCK_CHANGED(bag, slot)
	if slot == nil then
		return
	end

	for _, v in ipairs(self.buttons) do
		if v.bag == bag and v.slot == slot then
			self:SlotUpdate(v)
			break
		end
	end
end


function Stuffing:BANKFRAME_OPENED()
	if not self.bankFrame then
		self:InitBank()
	end

	self:Layout(true)
	for _, x in ipairs(BAGS_BANK) do
		self:BagSlotUpdate(x)
	end
	self.bankFrame:show()
	Stuffing_Open()
end


function Stuffing:BANKFRAME_CLOSED()
	if not self.bankFrame then
		return
	end

	self.bankFrame:Hide()
end


function Stuffing:BAG_CLOSED(id)
	local b = self.bags[id]
	if b then
		tremove(self.bags, id)
		b:Hide()
		tinsert (trashBag, #trashBag + 1, b)
	end

	while true do
		local changed = false

		for i, v in ipairs(self.buttons) do
			if v.bag == id then
				v.frame:Hide()
				v.normalTex:Hide()
				v.iconTex:Hide()

				if v.Glow then
					v.Glow:Hide()
				end

				tinsert (trashButton, #trashButton + 1, v.frame)
				tremove(self.buttons, i)

				v = nil
				changed = true
			end
		end

		if not changed then
			break
		end
	end
end


function Stuffing:SortOnUpdate(e)
	if not self.elapsed then
		self.elapsed = 0
	end

	if not self.itmax then
		self.itmax = 0
	end

	self.elapsed = self.elapsed + e

	if self.elapsed < 0.1 then
		return
	end

	self.elapsed = 0
	self.itmax = self.itmax + 1

	local changed, blocked  = false, false

	if self.sortList == nil or next(self.sortList, nil) == nil then
		-- wait for all item locks to be released.
		local locks = false

		for i, v in pairs(self.buttons) do
			local _, _, l = GetContainerItemInfo(v.bag, v.slot)
			if l then
				locks = true
			else
				v.block = false
			end
		end

		if locks then
			-- something still locked. wait some more.
			return
		else
			-- all unlocked. get a new table.
			self:SetScript("OnUpdate", nil)
			self:SortBags()

			if self.sortList == nil then
				return
			end
		end
	end

	-- go through the list and move stuff if we can.
	for i, v in ipairs (self.sortList) do
		repeat
			if v.ignore then
				blocked = true
				break
			end

			if v.srcSlot.block then
				changed = true
				break
			end

			if v.dstSlot.block then
				changed = true
				break
			end

			local _, _, l1 = GetContainerItemInfo(v.dstSlot.bag, v.dstSlot.slot)
			local _, _, l2 = GetContainerItemInfo(v.srcSlot.bag, v.srcSlot.slot)

			if l1 then
				v.dstSlot.block = true
			end

			if l2 then
				v.srcSlot.block = true
			end

			if l1 or l2 then
				break
			end

			if v.sbag ~= v.dbag or v.sslot ~= v.dslot then
				if v.srcSlot.name ~= v.dstSlot.name then
					v.srcSlot.block = true
					v.dstSlot.block = true
					PickupContainerItem (v.sbag, v.sslot)
					PickupContainerItem (v.dbag, v.dslot)
					changed = true
					break
				end
			end
		until true
	end

	self.sortList = nil

	if (not changed and not blocked) or self.itmax > 250 then
		self:SetScript("OnUpdate", nil)
		self.sortList = nil
		fakestatusbar_:stop_it()
	end
end


local function InBags(x)
	if not Stuffing.bags[x] then
		return false
	end

	for _, v in ipairs(Stuffing.sortBags) do
		if x == v then
			return true
		end
	end
	return false
end


function Stuffing:SortBags()
	local bs = self.sortBags
	if InCombatLockdown() then fakestatusbar_:stop_it(); return end
	if #bs < 1 then fakestatusbar_:stop_it(); return end

	local st = {}
	local bank = false

	Stuffing_Open()

	for i, v in pairs(self.buttons) do
		if InBags(v.bag) then
			self:SlotUpdate(v)

			if v.name then
				local tex, cnt, _, _, _, _, clink = GetContainerItemInfo(v.bag, v.slot)
				local n, _, q, iL, rL, c1, c2, _, Sl = GetItemInfo(clink)
				tinsert(st, {
					srcSlot = v,
					sslot = v.slot,
					sbag = v.bag,
					--sort = q .. iL .. c1 .. c2 .. rL .. Sl .. n .. i,
					--sort = q .. iL .. c1 .. c2 .. rL .. Sl .. n .. (#self.buttons - i),
					sort = q .. c1 .. c2 .. rL .. n .. iL .. Sl .. (#self.buttons - i),
					--sort = q .. (#self.buttons - i) .. n,
				})
			end
		end
	end

	-- sort them
	sort (st, function(a, b)
		return a.sort > b.sort
	end)

	-- for each button we want to sort, get a destination button
	local st_idx = 1
	local dbag = bs[st_idx]
	local dslot = 1
	local max_dslot = GetContainerNumSlots(dbag)

	for i, v in ipairs (st) do
		v.dbag = dbag
		v.dslot = dslot
		v.dstSlot = self:SlotNew(dbag, dslot)

		dslot = dslot + 1

		if dslot > max_dslot then
			dslot = 1

			while true do
				st_idx = st_idx + 1

				if st_idx > #bs then
					break
				end

				dbag = bs[st_idx]

				if Stuffing:BagType(dbag) == ST_NORMAL or dbag > 4 then
					break
				end
			end

			max_dslot = GetContainerNumSlots(dbag)
		end
	end

	-- throw various stuff out of the search list
	local changed = true
	while changed do
		changed = false
		-- XXX why doesn't this remove all x->x moves in one pass?

		for i, v in ipairs (st) do

			-- source is same as destination
			if (v.sslot == v.dslot) and (v.sbag == v.dbag) then
				table.remove (st, i)
				changed = true
			end
		end
	end

	-- kick off moving of stuff, if needed.
	if st == nil or next(st, nil) == nil then
		self:SetScript("OnUpdate", nil)
		fakestatusbar_:stop_it()
	else
		self.sortList = st
		self:SetScript("OnUpdate", Stuffing.SortOnUpdate)
	end
end


function Stuffing:RestackOnUpdate(e)
	if not self.elapsed then
		self.elapsed = 0
	end

	self.elapsed = self.elapsed + e

	if self.elapsed < 0.1 then
		return
	end

	self.elapsed = 0
	self:Restack()
end


function Stuffing:Restack()
	if InCombatLockdown() then return end

	local st = {}

	Stuffing_Open()

	for i, v in pairs(self.buttons) do
		if InBags(v.bag) then
			local tex, cnt, _, _, _, _, clink = GetContainerItemInfo(v.bag, v.slot)
			if clink then
				local n, _, _, _, _, _, _, s = GetItemInfo(clink)

				if cnt ~= s then
					if not st[n] then
						st[n] = {{
							item = v,
							size = cnt,
							max = s
						}}
					else
						tinsert(st[n], {
							item = v,
							size = cnt,
							max = s
						})
					end
				end
			end
		end
	end

	local did_restack = false

	for i, v in pairs(st) do
		if #v > 1 then
			for j = 2, #v, 2 do
				local a, b = v[j - 1], v[j]
				local _, _, l1 = GetContainerItemInfo(a.item.bag, a.item.slot)
				local _, _, l2 = GetContainerItemInfo(b.item.bag, b.item.slot)

				if l1 or l2 then
					did_restack = true
				else
					PickupContainerItem (a.item.bag, a.item.slot)
					PickupContainerItem (b.item.bag, b.item.slot)
					did_restack = true
				end
			end
		end
	end

	if did_restack then
		self:SetScript("OnUpdate", Stuffing.RestackOnUpdate)
	else
		self:SetScript("OnUpdate", nil)
		fakestatusbar_:stop_it()
	end
end

	Stuffing:SetScript("OnEvent", function(this, event, ...)
		Stuffing[event](this, ...)
	end)

	Stuffing:RegisterEvent("BAG_UPDATE")
	Stuffing:RegisterEvent("ITEM_LOCK_CHANGED")
	Stuffing:RegisterEvent("BANKFRAME_OPENED")
	Stuffing:RegisterEvent("BANKFRAME_CLOSED")
	Stuffing:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	Stuffing:RegisterEvent("BAG_CLOSED")

	Stuffing:InitBags()

	tinsert(UISpecialFrames,"StuffingFrameBags")

	ToggleBackpack = Stuffing_Toggle
	ToggleBag = Stuffing_ToggleBag
	OpenAllBags = Stuffing_Open
	ToggleAllBags = Stuffing_Toggle
	OpenBackpack = Stuffing_Open
	CloseAllBags = Stuffing_Close
	CloseBackpack = Stuffing_Close
	
	BankFrame:UnregisterAllEvents()