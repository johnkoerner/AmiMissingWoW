function AmIMissing_OnLoad()
    SLASH_AMIMISSING1= "/ami";
    SlashCmdList["AMIMISSING"] = AmIMissing_SlashCommand;

end

CRAFTED_MOG = "10.1.5"

function AmIMissing_SlashCommand()  
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
                if (total > 1) then
                    link = TSM_API.GetItemLink(itemNum)
                    table.insert(excess, link)
                    count = count + 1
                end
            end
        end
    end
    if (count < 1) then
        print ("Nothing to report!")
    else 
        table.sort(missing)
        print("Missing Items:")
        for k, link in ipairs(missing) do
            print(link)
        end

        print ("Excess Items:")
        for k, link in ipairs(excess) do
            print(link)
        end
    end
end