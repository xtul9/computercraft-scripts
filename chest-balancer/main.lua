local basalt = require("basalt")

local chests = peripheral.getNames()

-- Filter out non-chest peripherals
for i = #chests, 1, -1 do
    if peripheral.getType(chests[i]) ~= "minecraft:chest" then
        table.remove(chests, i)
    end
end

local function balanceChests()
    local wrappedChests = {}
    for i, c in ipairs(chests) do
        wrappedChests[i] = peripheral.wrap(c)
    end

    local itemCounts = {}

    -- 1. Collect amounts of items in each chest
    for chestIndex, chest in ipairs(wrappedChests) do
        for slot, item in pairs(chest.list()) do
            local details = chest.getItemDetail(slot)
            local key = item.name
            if not itemCounts[key] then
                itemCounts[key] = { total = 0, sources = {}, chests = {}, maxStack = details.maxCount }
            end
            itemCounts[key].total = itemCounts[key].total + details.count
            table.insert(itemCounts[key].sources, { chest = chest, slot = slot, count = details.count, chestIndex = chestIndex })
            itemCounts[key].chests[chestIndex] = (itemCounts[key].chests[chestIndex] or 0) + details.count
        end
    end

    -- 2. Balance only the items that need it
    for key, data in pairs(itemCounts) do
        local numChests = #wrappedChests
        local perChest = math.floor(data.total / numChests)
        local remainder = data.total % numChests
        local maxStack = data.maxStack

        -- Divide chests into overfilled and underfilled
        local overfilled = {}
        local underfilled = {}

        for chestIndex, count in pairs(data.chests) do
            if count > perChest then
                table.insert(overfilled, { index = chestIndex, excess = count - perChest })
            elseif count < perChest then
                table.insert(underfilled, { index = chestIndex, needed = perChest - count })
            end
        end

        -- Move the items
        for _, over in ipairs(overfilled) do
            local chestFrom = wrappedChests[over.index]
            for _, under in ipairs(underfilled) do
                local chestTo = wrappedChests[under.index]
                if over.excess > 0 and under.needed > 0 then
                    local chestToContents = chestTo.list()

                    -- Prioritize filling non-maxed out stacks
                    for slot, item in pairs(chestToContents) do
                        if item.name == key and item.count < maxStack then
                            local availableSpace = maxStack - item.count
                            local moveAmount = math.min(over.excess, under.needed, availableSpace)
                            local moved = chestTo.pullItems(peripheral.getName(chestFrom), 1, moveAmount)

                            -- Update the amounts
                            over.excess = over.excess - moved
                            under.needed = under.needed - moved

                            -- If the chest no longer has excess items, move to another chest
                            if over.excess <= 0 then break end
                        end
                    end

                    -- Move to another slot only if there is no more space in existing stacks
                    if over.excess > 0 and under.needed > 0 then
                        local moveAmount = math.min(over.excess, under.needed)
                        local moved = chestTo.pullItems(peripheral.getName(chestFrom), 1, moveAmount)

                        -- Update the amounts
                        over.excess = over.excess - moved
                        under.needed = under.needed - moved
                    end
                end
            end
        end
    end
end



local frame = basalt.createFrame()

if frame == nil then 
    print("Main frame is nil!")
    return
end

local progressLabel
local progressBar

local function refreshStats()
    local totalAvailableSlots = 0
    local usedSlots = 0

    for _, p in ipairs(chests) do
        local chest = peripheral.wrap(p)
        totalAvailableSlots = totalAvailableSlots + chest.size()
        usedSlots = usedSlots + #chest.list()
    end

    local pct = (usedSlots / totalAvailableSlots) * 100

    progressLabel:setText(usedSlots .. "/" .. totalAvailableSlots .. " (" .. math.floor(pct) .. "%)")
    progressBar:setProgress(pct)
end

local function mainLoop()
    balanceChests()
    refreshStats()
    basalt.update()

    local function delayedTask()
        balanceChests()
        refreshStats()
        basalt.update()
    end

    local myTimer = frame:addTimer()

    myTimer:onCall(delayedTask)
    myTimer:setTime(10)
    myTimer:start()
end

frame:addLabel()
    :setPosition(5, 1)
    :setText("Chest Balancer")
frame:addLabel()
    :setPosition(5, 2)
    :setText("Version 1.0")
progressLabel = frame:addLabel()
    :setPosition(5, 4)
    :setText("Loading...")
progressBar = frame:addProgressbar()
    :setPosition(5, 5)
    :setSize(20, 1)
    :setDirection("right")
    :setProgress(0)
    :setProgressBar(colors.blue)

mainLoop()

basalt.autoUpdate()