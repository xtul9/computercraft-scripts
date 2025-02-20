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

local function findMostAndLeastFilledChests()
    local wrappedChests = {}
    for i, c in ipairs(chests) do
        wrappedChests[i] = peripheral.wrap(c)
    end

    local mostFilled, leastFilled = nil, nil
    local maxCount, minCount = -1, math.huge

    for i, chest in ipairs(wrappedChests) do
        local count = 0
        for _, item in pairs(chest.list()) do
            count = count + item.count
        end
        
        if count > maxCount then
            maxCount = count
            mostFilled = { index = i, chest = chest }
        end
        
        if count < minCount then
            minCount = count
            leastFilled = { index = i, chest = chest }
        end
    end
    
    return mostFilled, leastFilled
end

local function moveSingleItem()
    local mostFilled, leastFilled = findMostAndLeastFilledChests()
    if not mostFilled or not leastFilled or mostFilled.index == leastFilled.index then return end

    for slot, item in pairs(mostFilled.chest.list()) do
        local moved = leastFilled.chest.pullItems(peripheral.getName(mostFilled.chest), slot)
        if moved > 0 then break end
    end
end

local function refreshStats()
    local totalAvailableSlots = 0
    local usedSlots = 0

    for _, p in ipairs(chests) do
        local chest = peripheral.wrap(p)
        totalAvailableSlots = totalAvailableSlots + (chest.size() * 64)
        for _, item in pairs(chest.list()) do
            usedSlots = usedSlots + item.count
        end
    end

    local pct = (usedSlots / totalAvailableSlots) * 100
    progressLabel:setText(usedSlots .. "/" .. totalAvailableSlots .. " (" .. math.floor(pct) .. "%)")
    progressBar:setProgress(pct)
end

local function mainLoop()
    while true do
        moveSingleItem()
        refreshStats()
    end
end

local frame = basalt.createFrame()
if frame == nil then 
    print("Main frame is nil!")
    return
end

local monitor = peripheral.wrap("left")
local frame
if monitor == nil then 
    print("Monitor frame is nil!")
    frame = basalt.createFrame()
else
    frame = basalt.addMonitor()
    frame:setMonitor(monitor)
end

frame:addLabel()
    :setPosition(1, 1)
    :setText("Chest Balancer")
frame:addLabel()
    :setPosition(1, 2)
    :setText("Version 1.3.0")
progressLabel = frame:addLabel()
    :setPosition(1, 6)
    :setText("Loading...")
progressBar = frame:addProgressbar()
    :setPosition(1, 7)
    :setSize(18, 2)
    :setDirection("right")
    :setProgress(0)
    :setProgressBar(colors.blue)

parallel.waitForAny(mainLoop, basalt.autoUpdate)