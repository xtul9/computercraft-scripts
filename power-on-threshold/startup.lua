local container = peripheral.find("inventory")

if container == nil then
    print("No container found; please connect a container to the computer")
    return
end

local function isContainerFull()
    for _, item in pairs(container.list()) do
        local count = item.count

        if count >= 64 then
            return true
        end
    end

    return false
end

local redstoneSide = "back"

while true do
    if isContainerFull() then
        redstone.setOutput(redstoneSide, false)
    else
        redstone.setOutput(redstoneSide, true)
    end

    sleep(0.5)
end
