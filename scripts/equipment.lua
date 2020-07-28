local name, _FishMaster = ...;

local window = LibStub("LibWindow-1.1")

FishMaster.equipment = {};

_FishMaster.dragging = {
    item = nil,
    bag = nil,
    slot = nil
};

local frame;
local frameName = "FishMasterFrame"

local slotinfo = {
    { name = "MainHand", tooltip = MAINHANDSLOT, id = INVSLOT_MAINHAND }
}

local function UpdateModel_ThisSlot(pname, model, idx)
    local _, _, slotnames = FishMaster:GetSlotInfo();
    local slotName = slotnames[idx].name;
    local slotID = slotnames[idx].id;
    local what = _G[pname .. slotName];
    local link = nil;
    if (what and what.used) then
        if (not what.empty) then
            link = "item:" .. what.item;
            model:TryOn(link, slotName);
        end
    elseif (slotnames[idx].transmog) then
        local sourceID = GetDisplaySource(slotID);
        model:TryOn(sourceID);
    else
        link = GetInventoryItemLink("player", slotID)
        if (link) then
            model:TryOn(link, slotName);
        end
    end
end

local function UpdateModel(self, button)
    local pname = self:GetName();
    local model = _G[pname .. "Model"];
    local empty = false;
    if (not model) then
        return ;
    end
    if (button and button.used) then
        if (button.empty and not button.forced) then
            empty = true;
        end
    else
        local _, _, slotnames = FishMaster:GetSlotInfo();
        for _, si in ipairs(slotnames) do
            local what = _G[pname .. si.name];
            if (what and what.empty) then
                empty = true;
            end
        end
    end
    if (empty) then
        model:Undress();
    end
    for i = 18, 1, -1 do
        UpdateModel_ThisSlot(pname, model, i);
    end
end

function FishMaster:GetSlotInfo()
    return slotinfo;
end

local function ODF_PickupContainerItem(bag, slot)
    local _, _, _, _, _, _, _, _, _, itemID = GetContainerItemInfo(bag, slot);
    _FishMaster.dragging.bag = bag
    _FishMaster.dragging.slot = slot
    _FishMaster.dragging.item = itemID
end

local function ODF_PickupInventoryItem(slot)
    _FishMaster.dragging.slot = slot
    _FishMaster.dragging.item = GetInventoryItemID("player", slot)
end

local function SafeHookFunction(func, newfunc)
    if (type(newfunc) == "string") then
        newfunc = _G[newfunc];
    end
    if (_G[func] ~= newfunc) then
        hooksecurefunc(func, newfunc);
        return true;
    end
    return false;
end

function FishMaster.equipment:OnLoad()

    frame = CreateFrame("FRAME", frameName, UIParent, "FishMasterTopFrame");
    frame:Hide();
    frame:SetToplevel(true);
    frame:EnableMouse(true);
    frame:SetMovable(true);
    ButtonFrameTemplate_HideButtonBar(frame);

    _G[frameName .. "Portrait"]:SetTexture("Interface\\Icons\\inv_fishingpole_02");
    _G[frameName .. "TitleText"]:SetText(_FishMaster.name .. " " .. _FishMaster.version);

    frame.UpdateModel = UpdateModel;

    _FishMaster.frame = frame;


end

function FishMaster.equipment:OnFrameLoad()
    local temp = PickupContainerItem;
    if (SafeHookFunction("PickupContainerItem", ODF_PickupContainerItem)) then
        SavedPickupContainerItem = temp;
    end

    temp = PickupInventoryItem;
    if (SafeHookFunction("PickupInventoryItem", ODF_PickupInventoryItem)) then
        SavedPickupInventoryItem = temp;
    end
end

function FishMaster.equipment:Open()
    ShowUIPanel(_FishMaster.frame);
end

function FishMaster.equipment:Close()
    HideUIPanel(_FishMaster.frame);
end

function FishMaster.equipment:Toggle()
    if FishMaster.equipment:IsVisible() then
        FishMaster.equipment:Close()
    else
        FishMaster.equipment:Open()
    end
end

function FishMaster.equipment:IsVisible()
    return _FishMaster.frame:IsVisible();
end

--function FishMaster.equipment:ItemSlotLoad(self)
--    local parentlen = string.len(self:GetParent():GetName()) + 1;
--    local slotName = strsub(self:GetName(), parentlen);
--    local id, textureName = GetInventorySlotInfo(slotName);
--    self:SetID(id);
--    self.backgroundTextureName = textureName;
--    SetItemButtonTexture(self, self.backgroundTextureName);
--    self:RegisterForDrag("LeftButton");
--    self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
--    self:RegisterEvent("CURSOR_UPDATE");
--    self:SetFrameLevel(self:GetFrameLevel() + 3);
--
--    self.slotName = slotName;
--    print(FishMaster.db.char.outfit[self.slotName])
--    if FishMaster.db.char.outfit[self.slotName] then
--        FishMaster.equipment:ItemSlotOnChange(self, FishMaster.db.char.outfit[self.slotName]);
--    end
--
--end
--
--function FishMaster.equipment:ItemSlotDraw(button)
--    if (button.texture) then
--        SetItemButtonTexture(button, button.texture);
--    else
--        SetItemButtonTexture(button, button.backgroundTextureName);
--    end
--
--    if (button.missing) then
--        SetItemButtonTextureVertexColor(button, 1.0, 0.1, 0.1);
--    else
--        SetItemButtonTextureVertexColor(button, 1.0, 1.0, 1.0);
--    end
--end
--
--function FishMaster.equipment:ClearItemSlot(button, empty, used)
--    button.name = nil;
--    button.item = nil;
--    button.texture = nil;
--    button.color = nil;
--    button.missing = nil;
--    button.forced = nil;
--    button.empty = empty;
--    button.used = used or empty;
--end
--
--local function IsBodySlotOneHanded(bodyslot)
--    if (bodyslot == "INVTYPE_2HWEAPON" or bodyslot == INVTYPE_2HWEAPON) then
--        return false;
--    end
--    return true;
--end
--
--local function GetSlotButton(button, slotName)
--    local parent = button:GetParent():GetName();
--    return _G[parent .. slotName];
--end
--
--local function IsItemOneHanded(item)
--    if (item) then
--        local _, _, _, _, _, _, _, _, bodyslot, _ = GetItemInfo(item);
--        return IsBodySlotOneHanded(bodyslot);
--    end
--    return true;
--end
--
--local function SmartCursorCanGoInSlot(button)
--    if (button.forced) then
--        return false;
--    end
--    local secondary = GetSlotButton(button, "SecondaryHandSlot");
--    local mainbutton = GetSlotButton(button, "MainHandSlot");
--    if (button == secondary and mainbutton and mainbutton.item) then
--        return IsItemOneHanded(mainbutton.item);
--    end
--    return CursorCanGoInSlot(button:GetID())
--end
--
--function FishMaster.equipment:AcceptCursorItem(button)
--    local parent = button:GetParent();
--    local pname = parent:GetName();
--
--    local _, _, slotnames = FishMaster:GetSlotInfo();
--    if (not SmartCursorCanGoInSlot(button)) then
--        button = nil;
--        for _, si in ipairs(slotnames) do
--            local temp = _G[pname .. si.name];
--            if (temp and SmartCursorCanGoInSlot(temp)) then
--                button = temp;
--            end
--        end
--    end
--


--
--    OD_Track_Bag = nil;
--    OD_Track_Slot = nil;
--end
--
--function FishMaster.equipment:ItemSlotOnClick(self)
--    if (CursorHasItem()) then
--        FishMaster.equipment:AcceptCursorItem(self);
--    end
--end
--
--function FishMaster.equipment:ItemSlotOnEvent(self)
--
--end
--
--function FishMaster.equipment:ItemSlotOnEnter(self)
--    GameTooltip:ClearLines();
--    GameTooltip:SetOwner(self, "ANCHOR_LEFT");
--
--    local name, link = GetItemInfo(FishMaster.db.char.outfit[self.slotName])
--
--    GameTooltip:SetHyperlink(link);
--    GameTooltip:Show();
--end
--
--function FishMaster.equipment:ItemSlotOnChange(button, item)
--
--    local parent = button:GetParent();
--    local pname = parent:GetName();
--    local parentlen = string.len(pname) + 1;
--    local slotName = strsub(button:GetName(), parentlen);
--
--    --FishMaster.db.char.outfit[slotName] = item;
--
--    if (item) then
--        local name, link, _, _, _, _, _, _, _, texture = GetItemInfo(item);
--        button.item = name;
--        button.link = link;
--        button.name = name;
--        button.texture = texture;
--        button.used = true;
--        button.empty = nil;
--        button.missing = nil;
--    end
--
--    FishMaster.equipment:ItemSlotDraw(button);
--
--    --if (slotName == "MainHandSlot") then
--    --    local secondary = _G[pname .. "SecondaryHandSlot"];
--    --    if (not button.used and secondary.forced) then
--    --        ClearODFButton(secondary, false, false);
--    --    elseif (button.used and not IsItemOneHanded(button.item)) then
--    --        ClearODFButton(secondary, true);
--    --        secondary.forced = true;
--    --    end
--    --    OutfitDisplayItemButton_Draw(secondary);
--    --end
--
--
--
--    --_FishMaster.frame:UpdateModel(button);
--
--end