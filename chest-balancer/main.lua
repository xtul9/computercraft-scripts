local basalt = require("basalt")

local chests = peripheral.getNames()

-- Filter out non-chest peripherals
for i = #chests, 1, -1 do
    if peripheral.getType(chests[i]) ~= "minecraft:chest" then
        table.remove(chests, i)
    end
end

local progressLabel
local progressBar

local function balanceChests()
    local wrappedChests = {}
    for i, c in ipairs(chests) do
        wrappedChests[i] = peripheral.wrap(c)
    end

    local itemCounts = {}

    -- 1. Collecting information about items in each chest
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

    -- 2. Filling empty chests (when they didn't have the item)
    for chestIndex = 1, #wrappedChests do
        for key, data in pairs(itemCounts) do
            if not data.chests[chestIndex] then
                data.chests[chestIndex] = 0
            end
        end
    end

    -- 3. Moving items
    for key, data in pairs(itemCounts) do
        local numChests = #wrappedChests
        local perChest = math.floor(data.total / numChests)
        local remainder = data.total % numChests
        local maxStack = data.maxStack

        -- Sorting chests by quantity
        local sortedChests = {}
        for chestIndex, count in pairs(data.chests) do
            table.insert(sortedChests, { index = chestIndex, count = count })
        end

        -- Sorting from largest to smallest quantity
        table.sort(sortedChests, function(a, b) return a.count > b.count end)

        local overfilled = {}
        local underfilled = {}

        for _, chestData in ipairs(sortedChests) do
            local chestIndex = chestData.index
            local count = chestData.count

            if count > perChest then
                table.insert(overfilled, { index = chestIndex, excess = count - perChest })
            elseif count < perChest then
                table.insert(underfilled, { index = chestIndex, needed = perChest - count })
            end
        end

        -- Sorting underfilled in ascending order
        table.sort(underfilled, function(a, b) return a.needed > b.needed end)

        -- Transfer items
        for _, over in ipairs(overfilled) do
            local chestFrom = wrappedChests[over.index]

            for _, under in ipairs(underfilled) do
                local chestTo = wrappedChests[under.index]

                if over.excess > 0 and under.needed > 0 then
                    local availableSpace = maxStack - (chestTo.list()[1] and chestTo.list()[1].count or 0)
                    local moveAmount = math.min(over.excess, under.needed, availableSpace)

                    -- Move from a random slot instead of always the first
                    for slot, item in pairs(chestFrom.list()) do
                        if item.name == key then
                            local moved = chestTo.pullItems(peripheral.getName(chestFrom), slot, moveAmount)

                            over.excess = over.excess - moved
                            under.needed = under.needed - moved

                            if over.excess <= 0 then break end
                        end
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

local monitor = peripheral.wrap("left") -- Assuming a monitor is on the left side
local monitorFrame = basalt.addMonitor()

if monitorFrame == nil then 
    print("Monitor frame is nil!")
    return
end

monitorFrame:setMonitor(monitor)

local function refreshStats()
    -- assume each slot is 64 items
    local totalAvailableSlots = 0
    local usedSlots = 0

    for _, p in ipairs(chests) do
        local chest = peripheral.wrap(p)
        totalAvailableSlots = totalAvailableSlots + (chest.size() * 64)
        for slot, item in pairs(chest.list()) do
            local details = chest.getItemDetail(slot)
            usedSlots = usedSlots + details.count
        end
    end

    local pct = (usedSlots / totalAvailableSlots) * 100

    progressLabel:setText(usedSlots .. "/" .. totalAvailableSlots .. " (" .. math.floor(pct) .. "%)")
    progressBar:setProgress(pct)
end

local balancing = false

local function mainLoop()
    local function runTasks()
        if balancing then return end -- Skip if already balancing
        balancing = true

        parallel.waitForAny(
            function()
                balanceChests()
                refreshStats()
                balancing = false -- Unlock balancing 
            end
        )
    end

    while true do
        runTasks()
    end
end



monitorFrame:addLabel()
    :setPosition(1, 1)
    :setText("Chest Balancer")
monitorFrame:addLabel()
    :setPosition(1, 2)
    :setText("Version 1.2.0")
progressLabel = monitorFrame:addLabel()
    :setPosition(1, 6)
    :setText("Loading...")
progressBar = monitorFrame:addProgressbar()
    :setPosition(1, 7)
    :setSize(18, 2)
    :setDirection("right")
    :setProgress(0)
    :setProgressBar(colors.blue)

parallel.waitForAny(mainLoop, basalt.autoUpdate)
