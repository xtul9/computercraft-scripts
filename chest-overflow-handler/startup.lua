local chest = peripheral.find("minecraft:chest")
local hopper = peripheral.find("minecraft:hopper")

if chest == nil then
  print("Chest not found")
  return
end

if hopper == nil then
  print("Hopper not found")
  return
end

local chestItems = chest.list()
local chestSize = chest.size()
local breakpoint = math.floor(chestSize - 5)

local function moveItemsToHopper()
  if (#chestItems > breakpoint) then
    for i = breakpoint, chestSize do
      local item = chestItems[i]
      if item ~= nil then
        print("Moving slot " .. i .. " to hopper")
        chest.pushItems(peripheral.getName(hopper), i)
      end
    end
    return
  end
end


-- every 5 seconds, move items to hopper
local timer = os.startTimer(5)
while true do
  local event, p1 = os.pullEvent()
  if event == "timer" and p1 == timer then
    chestItems = chest.list()
    moveItemsToHopper()
    timer = os.startTimer(5)
  end
end
