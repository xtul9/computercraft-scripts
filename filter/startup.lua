local containerToFilter = peripheral.find("minecraft:chest")

if not containerToFilter then
    print("Missing container; please connect a container to the computer")
    return
end

local dumpContainers = { peripheral.find("inventory", function(_, object) 
    return peripheral.getName(object) ~= peripheral.getName(containerToFilter) 
end) }

if #dumpContainers == 0 then
    print("No dump container found; please connect a second container to the computer")
    return
end

print("Dump containers:")
for i, dumpContainer in ipairs(dumpContainers) do
    print(i, peripheral.getName(dumpContainer))
end

print("\nContainer to filter:", peripheral.getName(containerToFilter))

local allowed_items = { ["minecraft:iron_ingot"] = true }

local function validate()
    for slot, details in pairs(containerToFilter.list()) do
        if not details or not allowed_items[details.name] or details.count >= details.maxCount then
            local moved = false

            for _, dumpContainer in ipairs(dumpContainers) do
                local targetName = peripheral.getName(dumpContainer)

                for dumpSlot, dumpItem in pairs(dumpContainer.list()) do
                    local dumpDetails = dumpContainer.getItemDetail(dumpSlot)
                    
                    if dumpDetails.name == details.name and dumpDetails.count < dumpDetails.maxCount then
                        local amountToMove = math.min(details.count, dumpDetails.maxCount - dumpDetails.count)
                        containerToFilter.pushItems(targetName, slot, amountToMove, dumpSlot)
                        moved = true
                        break
                    end
                end

                if moved then break end
            end

            if not moved and details.count > 1 then
                for _, dumpContainer in ipairs(dumpContainers) do
                    local targetName = peripheral.getName(dumpContainer)

                    for dumpSlot = 1, dumpContainer.size() do
                        if not dumpContainer.getItemDetail(dumpSlot) then
                            containerToFilter.pushItems(targetName, slot, details.count, dumpSlot)
                            break
                        end
                    end
                end
            end
        end
    end
end

while true do
    validate()
    sleep(0.05)
end
