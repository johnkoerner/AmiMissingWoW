
CRAFTED_MOG = {"10.1.5","Crafted Restock"}
local prefix = "AmIMissingItem"

local ignoreList = {["Negz-MoonGuard"]=true, ["Negativezero-Winterhoof"]=true}

local msgLoc = "PARTY"

local playerName = UnitName("player")
local serverName = GetRealmName()
local cleanedServer = serverName:gsub("%s+", "")
local playerServer = playerName .. "-" .. cleanedServer


function AmIMissing_OnLoad()
    SLASH_AMIMISSING1= "/ami";
    SlashCmdList["AMIMISSING"] = AmIMissing_SlashCommand;
    C_ChatInfo.RegisterAddonMessagePrefix(prefix)
end

local function IncrementItemCount(item)
    if ItemCount == nil then
        ItemCount = {}
    end

    if ItemCount[item] == nil then
        ItemCount[item] = 1
    else
        ItemCount[item] = ItemCount[item] + 1
    end
end

local function UpdateItemsByPlayer(sender, item) 
    if ItemsByPlayer == nil then
        ItemsByPlayer = {}
    end
    
    if ItemsByPlayer[sender] == nil then
        ItemsByPlayer[sender]={}
    end 
    
    if ItemsByPlayer[sender][item] == nil then
        ItemsByPlayer[sender][item] = 1
        -- Only want to increment it if we haven't seen this player/item combo otherwise we end up with extras
        IncrementItemCount(item)
    end
end

local function OnEvent(self, event, ...)

    local prefixReceived, message, distributionType, sender = ...

    if event == "CHAT_MSG_ADDON" then
        if prefixReceived == prefix then

            if (sender == playerServer) then
                print("Ignorig self messages.")
                do return end
            end

            if (message == "DONE") then
                print("Received items from " .. sender)
                do return end 
            end

            if (message == "CLEAR") then
                ItemsByPlayer[sender]={}
                do return end 
            end 

            if (message == "INIT") then

                
                senderTable = Split(sender, "-")
                senderName = senderTable[1]
                senderServer = senderTable[2]
                
                tradeSender = sender
                -- If a acct 1 and acct 2 are on the same server, you don't include the -servername in the initiate trade request.
                if (senderServer == cleanedServer) then
                    tradeSender = senderName
                end

                if not TradeFrame:IsShown() then 
                    print("Starting trade with:" .. tradeSender)
                    InitiateTrade(tradeSender) 
                end

                do return end

            end
                



            print("AMI:" .. message)

            for b=0,4 do 
                for s=1,C_Container.GetContainerNumSlots(b)do 
                    local l=C_Container.GetContainerItemLink(b,s)
                    if (l) then
                        local name = GetItemNameFromLink(l)
                        if name and name:find(message) then
                            print("Attempting  to trade : " .. message)
                            C_Container.UseContainerItem(b, s)
                            -- Only want to trade one item at a time
                            do return end
                        end 
                    end
                end 
            end
        end
    end
    
    if event == "GROUP_ROSTER_UPDATE" then
        if sender==nil or (ignoreList[sender]==true) then
            print("Ignored: " .. playerName)
        else
            print("Sender:" .. sender)
            print("playerName:" .. playerName)
            print("here")
            sendInfo()
        end
    end 

    if event == "BAG_NEW_ITEMS_UPDATED" then
        sendInfo()
    end 

    if event == "OWNED_AUCTIONS_UPDATED" then
        sendInfo()
    end
end



local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("OWNED_AUCTIONS_UPDATED")
f:RegisterEvent("BAG_NEW_ITEMS_UPDATED")
f:SetScript("OnEvent", OnEvent)

function AmIMissing_SlashCommand(args)  
if (args == "p") then
    print("here")
    print(ItemsByPlayer)
    for name, t in pairs(ItemsByPlayer) do
        print(name)
        print(t)
        for item, discard in pairs(t) do
            print(name .. ":" .. item)
        end
    end
elseif (args=="l") then
    for item, count in pairs(ItemCount) do
        print(item .. " : ".. count) 
    end
elseif (args=="c") then
    ItemCount = {}
    ItemsByPlayer = {}
    print("Reset Missing Items List")
elseif (args=="u") then
    createUI()
elseif (args=="trade") then
    if not TradeFrame:IsShown() then 
         C_ChatInfo.SendAddonMessage(prefix, "INIT", "PARTY")
    else
        for item, _ in pairs(ItemsByPlayer[playerServer]) do
            print(item)
            name = GetItemNameFromLink(item)
            if (name ~= nil) then



                print("Sending:" .. name)
                C_ChatInfo.SendAddonMessage(prefix, name, "PARTY")
            end
        end
    end
    sendInfo()
else 
    sendInfo()
end
    
end

function sendInfo()
    count = 0
    missing = {}
    excess = {}
    for i, name in ipairs(TSM_API.GetGroupPaths({})) do
        if (contains(CRAFTED_MOG, name)) then
            for j, itemNum in ipairs(TSM_API.GetGroupItems(name, false, {})) do
                bag = TSM_API.GetBagQuantity(itemNum)
                auc = TSM_API.GetAuctionQuantity(itemNum)
                total = bag + auc;
                if (total < 1) then
                    link = TSM_API.GetItemLink(itemNum)
                    table.insert(missing, link)
                    count = count + 1
                end
                -- Track excess but we aren't going to do anything with them right now
                if (total > 1) then
                    link = TSM_API.GetItemLink(itemNum)
                    table.insert(excess, link)
                
                end
            end
        end
    end
    if (count < 1) then
        print ("Nothing to report!")
        ItemsByPlayer[playerServer]={}
    else 
        table.sort(missing)
        ItemsByPlayer[playerServer]={}
        for k, link in ipairs(missing) do
            UpdateItemsByPlayer(playerServer, link)
        end
    end
    
end

function contains(table, value) 
    for index, tableVal in ipairs(table) do
        if value == tableVal then
            return true
        end
    end

    return false

end

function GetItemNameFromLink(itemLink) 
    itemName = GetItemInfo(itemLink)
    return itemName;
end 

function ItemLinkSorter(item1, item2) 
    local item1String = GetItemNameFromLink(item1)
    local item2String = GetItemNameFromLink(item2)
    if (item1String == nil) then
        return false
    elseif (item2String == nil) then
        return true
    else
        return item1String < item2String
    end 
end

function createUI() 
    sendInfo()
    buffBox = CreateFrame("Frame", "BuffBoxFrame", UIParent, "BasicFrameTemplateWithInset")
    tex = buffBox:CreateTexture(nil, "BACKGROUND")
    
    buffBox:SetFrameStrata("MEDIUM")
    buffBox:SetWidth(1200)
    buffBox:SetHeight(600)
    buffBox.texture = tex
    tex:SetAllPoints(true)
    buffBox.title = buffBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    
    buffBox.title:SetPoint("LEFT", buffBox.TitleBg, "LEFT", 5, 0)
    buffBox.title:SetText("Am I Missing?")
    
    buffBox:SetPoint("TOPLEFT", 0, 0)
    buffBox:SetMovable(true)
    buffBox:EnableMouse(true)

    buffBox:RegisterForDrag("LeftButton")
    buffBox:SetScript("OnDragStart", function(self)
                                        self:StartMoving();

                                    end)
    buffBox:SetScript("OnDragStop", function(self)
                                        buffBox:StopMovingOrSizing();
                                    end
    )
    buffBox:Show()
    
    local sf = CreateFrame("ScrollFrame", "KethoEditBoxScrollFrame1", buffBox, "UIPanelScrollFrameTemplate")
    sf:SetPoint("LEFT", 16, 0)
    sf:SetPoint("RIGHT", -800, 0)
    sf:SetPoint("TOP", -32, -32)
    sf:SetPoint("BOTTOM", 0, 10)
    
    -- EditBox
    local eb = CreateFrame("EditBox", "KethoEditBoxEditBox1", KethoEditBoxScrollFrame)
    eb:SetSize(sf:GetSize())
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false) -- dont automatically focus
    eb:SetFontObject("ChatFontNormal")
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    sf:SetScrollChild(eb)

    local sf2 = CreateFrame("ScrollFrame", "KethoEditBoxScrollFrame2", buffBox, "UIPanelScrollFrameTemplate")
    sf2:SetPoint("LEFT",431, 0)
    sf2:SetPoint("RIGHT", -400, 0)
    sf2:SetPoint("TOP", -32, -32)
    sf2:SetPoint("BOTTOM", 0, 10)
    
    -- EditBox
    local eb2 = CreateFrame("EditBox", "KethoEditBoxEditBox2", KethoEditBoxScrollFrame)
    eb2:SetSize(sf2:GetSize())
    eb2:SetMultiLine(true)
    eb2:SetAutoFocus(false) -- dont automatically focus
    eb2:SetFontObject("ChatFontNormal")
    eb2:SetScript("OnEscapePressed", function() f:Hide() end)
    sf2:SetScrollChild(eb2)


    local sf3 = CreateFrame("ScrollFrame", "KethoEditBoxScrollFrame3", buffBox, "UIPanelScrollFrameTemplate")
    sf3:SetPoint("LEFT",831, 0)
    sf3:SetPoint("RIGHT", -32, 0)
    sf3:SetPoint("TOP", -32, -32)
    sf3:SetPoint("BOTTOM", 0, 10)
    
    -- EditBox
    local eb3 = CreateFrame("EditBox", "KethoEditBoxEditBox3", KethoEditBoxScrollFrame)
    eb3:SetSize(sf3:GetSize())
    eb3:SetMultiLine(true)
    eb3:SetAutoFocus(false) -- dont automatically focus
    eb3:SetFontObject("ChatFontNormal")
    eb3:SetScript("OnEscapePressed", function() f:Hide() end)
    sf3:SetScrollChild(eb3)


    output = ""
    myOutput = ""
    shopOutput = ""
    shoppingList = {}
    shoppingSorter = {}
    for name, t in pairs(ItemsByPlayer) do
        for item, discard in pairs(t) do
            output = output .. name .. ":" .. item .. "\n"
            if shoppingList[item]==nil then
                shoppingList[item] = 0
                table.insert(shoppingSorter,item);
            end 
            shoppingList[item] = shoppingList[item] +  1
            
            if (name == playerServer) then
                myOutput = myOutput .. item .. "\n"
            end
        end
    end

    table.sort(shoppingSorter, ItemLinkSorter)

    for idx, itemLink in ipairs(shoppingSorter) do
        shopOutput = shopOutput .. itemLink .. ":" .. shoppingList[itemLink] .. "\n"
    end

    eb:SetText(output)
    eb2:SetText(myOutput)
    eb3:SetText(shopOutput)

end

function Split (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end
