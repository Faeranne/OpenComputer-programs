local component = require('component')
local smeltery = require('smeltery')
local serialize = require('serialization')
local shell = require('shell')
local term = require('term')
local fs = require('filesystem')

local args, opts = shell.parse(...)

local devices = nil

function init()
  term.write('Initializing Smeltery control protocol.\nPlease ensure smeltery is correctly setup before continuing\n[Press Enter to continue]')
  term.read()
  term.write('Scanning all Transposers\n')
  smeltery.init()
  devices = smeltery.devices
  if devices['controller'] then
    term.write('Found Controller at '..devices['controller']..'\n');
  else
    term.write('No Controller Found.  Please make sure the controller has a chest attached.\nDeactivating controller automation\n')
    ---config.set('controller', false)
  end
  if devices['tables'] then
    term.write('Found Casting Tables at '..devices['tables'] .. '\n')
  else
    term.write('No Casting Tables found. Please ensure tables have an attached pattern chest, as well as a normal chest');
  end
  if # devices['storage'] then
    term.write('Found ' .. # devices['storage'] .. ' Storage units\n')
  else
    term.write('No Storage units found.\n')
  end
end

function addFluid(name)
  term.write('Locating ' .. name .. '\n')
  local address, side = smeltery.findFluid(name)
  local device = component.proxy(address)
  local fluid = device.getFluidInTank(side)[1]
  if fluid.name ~= name
  then
    term.write(name .. ' not found.  Closing.\n')
    return
  end
  local smeltery = smeltery.getSmelterySide(smeltery.getTankSides(address))
  device.transferFluid(side, smeltery, fluid.amount)
  term.write('Done\n')
end   

if args[1] == 'init'
then
  init()
end

if args[1] == 'empty'
then
  devices = smeltery.devices
  smeltery.emptyAll(devices)
end

if args[1] == 'addFluid'
then
  addFluid(args[2])
end