local component = require('component')
local smeltery = {}

function smeltery.getAllDevices()
  local transposers = component.list('transposer')
  local smelt = {}
  smelt['storage'] = {}
  for unit,_ in pairs(transposers) do
    local res = smeltery.identifyTransposer(unit)
    if res == 'storage' then
      table.insert(smelt['storage'], unit)
    else
      smelt[res] = unit
    end
  end
  return smelt
end

function smeltery.processOres(devices)
  local controller = component.proxy(devices['controller'])
  local sides = table_invert(smeltery.getInventorySides(devices['controller']))
  controller.transferItem(sides['chest'], sides['controller'])
end

function smeltery.identifyTransposer(address)
  local tanks = smeltery.getTankSides(address)
  local inven = smeltery.getInventorySides(address)
  local totalTanks = 0
  local hasSmeltery = false
  local hasController = false
  local hasPattern = false
  local hasChest = false
  local hasCast = false
  for i=0,5
  do
    if tanks[i] == 'tank'
    then
      totalTanks = totalTanks + 1
    end
    if tanks[i] == 'smeltery'
    then
      hasSmeltery = true;
    end
    if inven[i] == 'chest'
    then
      hasChest = true
    end
    if inven[i] == 'casting'
    then
      hasCast = true
    end
    if inven[i] == 'pattern'
    then
      hasPattern = true
    end
    if inven[i] == 'controller'
    then
      hasController = true
    end
  end
  if hasChest then
    if hasController then
       return 'controller'
    end
    if hasCast then
      if hasPattern then
        return 'tables'
      else
        return 'basens'
      end
    end
  end
  if totalTanks > 3 then
    return 'storage'
  end
  if totalTanks == 1 then
    return 'delivery'
  end
end

function smeltery.getTankSides(address)
  local sideArray = {}
  local transposer = component.proxy(address)
  for i=0,5
  do
    local cap = transposer.getTankCapacity(i)
    if cap==256000
    then
      sideArray[i] = 'tank'
    else
      if cap==0
      then
        sideArray[i] = 'none'
      else
        sideArray[i] = 'smeltery'
      end
    end
  end
  return sideArray
end

function smeltery.getInventorySides(address)
  local sideArray = {}
  local transposer = component.proxy(address)
  for i=0,5
  do
    local cap = transposer.getInventorySize(i)
    if cap == nil
    then
      sideArray[i] = 'none'
    else
      if cap == 27
      then
        sideArray[i] = 'chest'
      else
        if cap == 2
        then
          sideArray[i] = 'casting'
        else
          if cap == 30
          then
            sideArray[i] = 'pattern'
          else
            sideArray[i] = 'controller'
          end
        end
      end
    end
  end
  return sideArray
end

function table_invert(t)
   local s={}
   for k,v in pairs(t) do
     s[v]=k
   end
   return s
end

return smeltery