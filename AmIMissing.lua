
CRAFTED_MOG = {"10.1.5","Crafted Restock", "10.1.5 - Icy"} 
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

    -- TODO: Move the spread operator inside each event if that needs it.  The spread operator is index based, not name based and different events have different values sent in the table.
    

    
    if event == "CHAT_MSG_ADDON" then
        local prefixReceived, message, distributionType, sender = ...
        if prefixReceived == prefix then

            if (sender == playerServer) then
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

            if (message == "LEAVE") then 
                C_PartyInfo.LeaveParty()
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
        sendInfo()
    end 


    if event == "BAG_NEW_ITEMS_UPDATED" then
        sendInfo()
    end 

    if event == "OWNED_AUCTIONS_UPDATED" then
        sendInfo()
    end
    -- Accept any rando invite for my mule so I don't have to switch windows.
    if event == "PARTY_INVITE_REQUEST" then
        if (playerName == "Negzmule") then
            print("Accepting group invite")
            AcceptGroup()
            -- Hide the join prompt
            if (StaticPopup1) then
                StaticPopup1:Hide()
            end 
        end
    end 

    -- Leave any group if I get invite to another group. This is if I forget to have them leave the group when the other player logs off.  Hmm... could I trigger this on player log off?
    if event == "CHAT_MSG_SYSTEM" then
        local text = ...
        print(playerName)
        if (playerName == "Negzmule") then
            print("here")
            print(text)
            if string.find(text, "you are already in a group") then
                print("leaving group")
                C_PartyInfo.LeaveParty()
            end 
        end 
    end 
end



local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("CHAT_MSG_SYSTEM")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("OWNED_AUCTIONS_UPDATED")
f:RegisterEvent("BAG_NEW_ITEMS_UPDATED")
f:RegisterEvent("AUCTION_HOUSE_BROWSE_RESULTS_ADDED")
f:RegisterEvent("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
f:RegisterEvent("PARTY_INVITE_REQUEST")
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
        -- Trade all but 10k gold, so we can consolidate funds
        moneyToTrade = GetMoney() - 100000000
        if (moneyToTrade > 0) then
            -- Blizzard disabled the ApI to set money in the trade window, so we can't do that anymore.
            print("Give " .. moneyToTrade .. " to the other account")
    --         MoneyInputFrame_SetCopper(TradePlayerInputMoneyFrame, moneyToTrade);
        end 
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
elseif (args == "z") then
    local results = C_AuctionHouse.GetBrowseResults()
    for k,v in pairs(results) do
        local id = v["itemKey"]["itemID"]
        local link = TSM_API.GetItemLink("i:" .. id)
       print(id .. "," .. link .. ",500000")
    end
elseif (args == "un") then
    ScanRecipes()
elseif (args == "leave") then
    C_ChatInfo.SendAddonMessage(prefix, "LEAVE", "PARTY")
elseif (args == "debug") then
    sendInfo(true)
elseif (args == "help" or args == "?") then
    print("|cff00ff00AmIMissing Commands (/ami):|r")
    print("  |cffffd700(no args)|r - Scan and send missing items info")
    print("  |cffffd700p|r        - Print items by player")
    print("  |cffffd700l|r        - List all missing items with counts")
    print("  |cffffd700c|r        - Clear/reset the missing items list")
    print("  |cffffd700u|r        - Open the UI")
    print("  |cffffd700trade|r    - Initiate trade or send items to trade window")
    print("  |cffffd700leave|r    - Send leave message to party")
    print("  |cffffd700un|r       - Scan for unlearned recipes")
    print("  |cffffd700debug|r    - Run scan with verbose output per item")
    print("  |cffffd700help|r     - Show this help text")
else
    sendInfo()
end
    
end

function sendInfo(debug)
    count = 0
    missing = {}
    excess = {}
    local allGroups = TSM_API.GetGroupPaths({})
    if debug then
        print("|cff00ff00[AMI Debug]|r TSM groups found: " .. #allGroups)
        print("|cff00ff00[AMI Debug]|r Looking for groups: " .. table.concat(CRAFTED_MOG, ", "))
    end
    for i, name in ipairs(allGroups) do
        local matched = contains(CRAFTED_MOG, name)
        if debug then
            print("|cff00ff00[AMI Debug]|r Group: '" .. name .. "' matched=" .. tostring(matched))
        end
        if matched then
            local groupItems = TSM_API.GetGroupItems(name, false, {})
            if debug then
                print("|cff00ff00[AMI Debug]|r  Items in group: " .. #groupItems)
            end
            for j, itemNum in ipairs(groupItems) do
                bag = TSM_API.GetBagQuantity(itemNum)
                auc = TSM_API.GetAuctionQuantity(itemNum)
                mail = TSM_API.GetMailQuantity(itemNum)
                total = bag + auc+mail;
                if debug then
                    print("|cff00ff00[AMI Debug]|r  " .. tostring(itemNum) .. " bag=" .. bag .. " auc=" .. auc .. " mail=" .. mail .. " total=" .. total)
                end
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

local function createUIFrame()
    buffBox = CreateFrame("Frame", "BuffBoxFrame", UIParent, "BasicFrameTemplateWithInset")
    buffBox:SetFrameStrata("MEDIUM")
    buffBox:SetWidth(1200)
    buffBox:SetHeight(600)

    local tex = buffBox:CreateTexture(nil, "BACKGROUND")
    buffBox.texture = tex
    tex:SetAllPoints(true)

    buffBox.title = buffBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    buffBox.title:SetPoint("LEFT", buffBox.TitleBg, "LEFT", 5, 0)
    buffBox.title:SetText("Am I Missing? - " .. playerServer)

    buffBox:SetPoint("TOPLEFT", 0, 0)
    buffBox:SetMovable(true)
    buffBox:EnableMouse(true)
    buffBox:RegisterForDrag("LeftButton")
    buffBox:SetScript("OnDragStart", function(self) self:StartMoving() end)
    buffBox:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    -- Register with UISpecialFrames so ESC closes the window
    tinsert(UISpecialFrames, "BuffBoxFrame")

    local sf = CreateFrame("ScrollFrame", "KethoEditBoxScrollFrame1", buffBox, "UIPanelScrollFrameTemplate")
    sf:SetPoint("LEFT", 16, 0)
    sf:SetPoint("RIGHT", -800, 0)
    sf:SetPoint("TOP", -32, -32)
    sf:SetPoint("BOTTOM", 0, 10)
    buffBox.eb = CreateFrame("EditBox", "KethoEditBoxEditBox1", sf)
    buffBox.eb:SetSize(sf:GetSize())
    buffBox.eb:SetMultiLine(true)
    buffBox.eb:SetAutoFocus(false)
    buffBox.eb:SetFontObject("ChatFontNormal")
    sf:SetScrollChild(buffBox.eb)

    local sf2 = CreateFrame("ScrollFrame", "KethoEditBoxScrollFrame2", buffBox, "UIPanelScrollFrameTemplate")
    sf2:SetPoint("LEFT", 431, 0)
    sf2:SetPoint("RIGHT", -400, 0)
    sf2:SetPoint("TOP", -32, -32)
    sf2:SetPoint("BOTTOM", 0, 10)
    buffBox.eb2 = CreateFrame("EditBox", "KethoEditBoxEditBox2", sf2)
    buffBox.eb2:SetSize(sf2:GetSize())
    buffBox.eb2:SetMultiLine(true)
    buffBox.eb2:SetAutoFocus(false)
    buffBox.eb2:SetFontObject("ChatFontNormal")
    sf2:SetScrollChild(buffBox.eb2)

    local sf3 = CreateFrame("ScrollFrame", "KethoEditBoxScrollFrame3", buffBox, "UIPanelScrollFrameTemplate")
    sf3:SetPoint("LEFT", 831, 0)
    sf3:SetPoint("RIGHT", -32, 0)
    sf3:SetPoint("TOP", -32, -32)
    sf3:SetPoint("BOTTOM", 0, 10)
    buffBox.eb3 = CreateFrame("EditBox", "KethoEditBoxEditBox3", sf3)
    buffBox.eb3:SetSize(sf3:GetSize())
    buffBox.eb3:SetMultiLine(true)
    buffBox.eb3:SetAutoFocus(false)
    buffBox.eb3:SetFontObject("ChatFontNormal")
    sf3:SetScrollChild(buffBox.eb3)
end

function createUI()
    sendInfo()

    if not buffBox then
        createUIFrame()
    end

    local output = ""
    local myOutput = ""
    local shopOutput = ""
    local shoppingList = {}
    local shoppingSorter = {}
    local shoppingLinks = {}
    for name, t in pairs(ItemsByPlayer or {}) do
        for item, discard in pairs(t) do
            output = output .. name .. ":" .. item .. "\n"
            local itemID = GetItemIDFromLink(item) or item
            if shoppingList[itemID] == nil then
                shoppingList[itemID] = 0
                shoppingLinks[itemID] = item
                table.insert(shoppingSorter, itemID)
            end
            shoppingList[itemID] = shoppingList[itemID] + 1
            if (name == playerServer) then
                myOutput = myOutput .. item .. "\n"
            end
        end
    end

    table.sort(shoppingSorter, function(a, b) return ItemLinkSorter(shoppingLinks[a], shoppingLinks[b]) end)

    for idx, itemID in ipairs(shoppingSorter) do
        shopOutput = shopOutput .. shoppingLinks[itemID] .. ":" .. shoppingList[itemID] .. "\n"
    end

    buffBox.eb:SetText(output)
    buffBox.eb2:SetText(myOutput)
    buffBox.eb3:SetText(shopOutput)
    buffBox:Show()
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

-- Need to have the tradeskill window open for this to work.
function ScanRecipes()
    print("Scanning recipes")
    -- Get's the list based on the current filters, so set the filter to drop and unlearned and then you can get a list of only what you haven't learned
    local recipeList = C_TradeSkillUI.GetFilteredRecipeIDs()
    local output = ""
    print("name, id, maxPrice")
    for  k, recipeID in ipairs(recipeList) do
        local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID)
        if recipeInfo and not recipeInfo.learned then
             --local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
             -- print(itemLink)
             --local reason = "";
             --print (schematic.name)

            print(recipeInfo.name .. "," .. recipeID .. ", 50000000")
        end
    end

    print(output)
end

function GetItemIDFromLink(itemLink)
    local _, _, itemID = string.find(itemLink, "item:(%d+)")
    return tonumber(itemID)
end
