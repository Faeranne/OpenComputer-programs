local component = require('component')
local smeltery = {}

function smeltery.init()
  smeltery.devices = smeltery.getAllDevices()
end

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

function smeltery.emptyAll(devices)
  dummy,_ = smeltery.getEmptyTank(devices)
  if dummy
  then
    local smelterySide = smeltery.getSmelterySide(smeltery.getTankSides(dummy))
    local dummyDevice = component.proxy(dummy)
    local smelteryFluids = dummyDevice.getFluidInTank(smelterySide)
    print(dummy)
    if smelteryFluids.n > 1
    then
      while smelteryFluids.n > 1
      do
        local tank, side = smeltery.findSmelteryFluid()
        if tank == false
        then
          return false, 'no tanks left'
        end
        smeltery.fillTank(tank, side)
        smelteryFluids = dummyDevice.getFluidInTank(smelterySide)
      end
    end
    while smelteryFluids[1].amount > 0
    do
      local tank, side = smeltery.findSmelteryFluid()
      if tank == false
      then
        return false, 'no tanks left'
      end
      smeltery.fillTank(tank, side)
    end
    return true, nil
  else
    return false, 'no tanks left'
  end
end

function smeltery.getEmptyTank(devices)
  for j in ipairs(devices.storage) do
    local address = devices.storage[j]
    print(address)
    tanks = smeltery.getTanks(address)
    for i=0,5 do
      if tanks[i] ~= nil 
      then
        if tanks[i].amount == 0
        then
          return address, i
        end
      end
    end
  end
  return false, null
end

function smeltery.findSmelteryFluid()
  local devices = smeltery.devices
  local smelteryDev = component.proxy(devices.storage[1])
  local devs = smeltery.getTankSides(devices.storage[1])
  local smelterySide = smeltery.getSmelterySide(devs)
  local fluidInSmeltery = smelteryDev.getFluidInTank(smelterySide)
  local fluidToStore = fluidInSmeltery[1].name
  return smeltery.findFluid(fluidToStore)
end

function smeltery.findFluid(fluidToFind)
  local devices = smeltery.devices
  for j in ipairs(devices.storage) do
    local address = devices.storage[j]
    tanks = smeltery.getTanks(address)
    for i=0,5 do
      if tanks[i] ~= nill
      then
        fluidInTank = component.proxy(address).getFluidInTank(i)[1].name
        if fluidToFind == fluidInTank
        then
          return address, i
        end
      end
    end
  end
  return smeltery.getEmptyTank(devices)
end

function smeltery.fillTank(address, tank)
  local transposer = component.proxy(address)
  local device = smeltery.getTankSides(address)
  local side = smeltery.getSmelterySide(device)
  local tankAmmount = transposer.getTankLevel(tank)
  local tankCap = transposer.getTankCapacity(tank)
  local remaining = tankCap - tankAmmount
  if remaining < 0 then
    transposer.transferFluid(side, tank, remaining)
    return false
  else
    transposer.transferFluid(side, tank, remaining)
    return true
  end
end

function smeltery.emptyTank(address, tank)
  local transposer = component.proxy(address)
  local device = smeltery.getTankSides(address)
  local side = smeltery.getSmelterySide(device)
  local tankAmmount = transposer.getTankLevel(tank)
  local smelteryAmmount = transposer.getTankLevel(side)
  local smelteryCap = transposer.getTankCapacity(side)
  local remaining = smelteryCap-smelteryAmmount
  if remaining < 0 then
    return false
  end
  return transposer.transferFluid(tank, side, tankAmmount)
end
  

function smeltery.getTanks(address)
  local tankSides = smeltery.getTankSides(address)
  local transposer = component.proxy(address)
  local inTheTank = {}
  for i=0,5
  do
    if tankSides[i] == 'tank'
    then
      local tank = transposer.getFluidInTank(i)[1]
      inTheTank[i] = tank
    end
  end
  return inTheTank
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
  return 'unknown'
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

function smeltery.getSmelterySide(device)
  for i=0,5
  do
    if device[i] == 'smeltery'
    then
      return i
    end
  end
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