local container = peripheral.find("inventory")

if not container then
    print("No container found; please connect a container to the computer")
    return
end

local redstoneSide = "back"

local function countFullStacks()
    local fullStacks = 0

    for slot, _ in ipairs(container.list()) do
        local item = container.getItemDetail(slot)

        if item.count >= item.maxCount then
            fullStacks = fullStacks + 1
        end
    end

    return fullStacks
end

while true do
    local fullStacks = countFullStacks()

    if fullStacks > 0 then
        redstone.setOutput(redstoneSide, false)
    else
        -- turn on redstone only for a single tick
        redstone.setOutput(redstoneSide, true)
        sleep(0.05)
        redstone.setOutput(redstoneSide, false)
    end

    sleep(0.05)
end
