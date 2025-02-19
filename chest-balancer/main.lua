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

local monitor = peripheral.wrap("left") -- Assuming a monitor is on the left side
local monitorFrame = basalt.addMonitor()

if monitorFrame == nil then 
    print("Monitor frame is nil!")
    return
end

monitorFrame:setMonitor(monitor)

local progressLabel
local progressBar

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

local function mainLoop()
    local function runTasks()
        balanceChests()
        refreshStats()
    end

    local timerDuration = 15
    local timerId = os.startTimer(timerDuration)

    runTasks()

    while true do
      local event = table.pack(os.pullEvent())

      if event[1] == "monitor_touch" then
        refreshStats()
      elseif event[1] == "timer" and event[2] == timerId then
        print("Timer event")
        runTasks()
        timerId = os.startTimer(timerDuration) -- restart the timer
      end
    end
end


monitorFrame:addLabel()
    :setPosition(1, 1)
    :setText("Chest Balancer")
monitorFrame:addLabel()
    :setPosition(1, 2)
    :setText("Version 1.1.1")
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
