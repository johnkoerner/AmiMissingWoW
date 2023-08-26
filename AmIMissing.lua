
CRAFTED_MOG = "10.1.5"
local prefix = "AmIMissingItem"

local ignoreList = {["Negz-MoonGuard"]=true, ["Negativezero-Winterhoof"]=true}

local msgLoc = "PARTY"

local playerName = UnitName("player")
local serverName = GetRealmName()
local playerServer = playerName .. "-" .. serverName
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
            if (message == "DONE") then
                print("Received items from " .. sender)
                do return end 
            end

            if (message == "CLEAR") then
                ItemsByPlayer[sender]={}
                do return end 
            end 

            UpdateItemsByPlayer(sender, message)
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
else 
    sendInfo()
end
    
end

function sendInfo()
    count = 0
    missing = {}
    excess = {}
    for i, name in ipairs(TSM_API.GetGroupPaths({})) do
        if (name==CRAFTED_MOG) then
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
        C_ChatInfo.SendAddonMessage(prefix, "DONE", msgLoc, playerName)
    else 
        table.sort(missing)
        print("Missing Items:")
        for k, link in ipairs(missing) do
            print(link)
            C_ChatInfo.SendAddonMessage(prefix, link, msgLoc, playerName)
        end
        C_ChatInfo.SendAddonMessage(prefix, "DONE", msgLoc, playerName)
    end
    
end


function createUI() 

    buffBox = CreateFrame("Frame", "BuffBoxFrame", UIParent, "BasicFrameTemplateWithInset")
    tex = buffBox:CreateTexture(nil, "BACKGROUND")
    
    buffBox:SetFrameStrata("MEDIUM")
    buffBox:SetWidth(800)
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
    
    local sf = CreateFrame("ScrollFrame", "KethoEditBoxScrollFrame", buffBox, "UIPanelScrollFrameTemplate")
    sf:SetPoint("LEFT", 16, 0)
    sf:SetPoint("RIGHT", -415, 0)
    sf:SetPoint("TOP", -32, -32)
    sf:SetPoint("BOTTOM", 0, 10)
    
    -- EditBox
    local eb = CreateFrame("EditBox", "KethoEditBoxEditBox", KethoEditBoxScrollFrame)
    eb:SetSize(sf:GetSize())
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false) -- dont automatically focus
    eb:SetFontObject("ChatFontNormal")
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    sf:SetScrollChild(eb)

    local sf2 = CreateFrame("ScrollFrame", "KethoEditBoxScrollFrame", buffBox, "UIPanelScrollFrameTemplate")
    sf2:SetPoint("LEFT",431, 0)
    sf2:SetPoint("RIGHT", -32, 0)
    sf2:SetPoint("TOP", -32, -32)
    sf2:SetPoint("BOTTOM", 0, 10)
    
    -- EditBox
    local eb2 = CreateFrame("EditBox", "KethoEditBoxEditBox", KethoEditBoxScrollFrame)
    eb2:SetSize(sf2:GetSize())
    eb2:SetMultiLine(true)
    eb2:SetAutoFocus(false) -- dont automatically focus
    eb2:SetFontObject("ChatFontNormal")
    eb2:SetScript("OnEscapePressed", function() f:Hide() end)
    sf2:SetScrollChild(eb2)


    output = ""
    myOutput = playerName
    for name, t in pairs(ItemsByPlayer) do
        for item, discard in pairs(t) do
            output = output .. name .. ":" .. item .. "\n"
            if (name == playerServer) then
                myOutput = myOutput .. item .. "\n"
            end
        end
    end

    eb:SetText(output)
    eb2:SetText(myOutput)

end
