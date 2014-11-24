-- ############################################################################
-- ## Title: reactorControl
-- **Avaliable at: http://pastebin.com/gFqTUvzM**
--
-- ## Author: Tad DeVries <tad@splunk.net>
-- Copyright (C) 2013-2014 Tad DeVries <tad@splunk.net>
-- http://tad.mit-license.org/2014
--
-- ## Description
-- A Big Reactors control program that monitors multiple reactors and modifies
-- their control rod settings based on the amount of energy stored in the
-- internal buffer of the reactor. By default the program will check all the
-- connected reactors every 5 seconds, when the internal buffer of a reactor
-- is at or above 80% capacity the control rods will start to lower to slow the
-- the reaction speed until their are at 100% inserted. Some basic information
-- is displayed on the computer terminal while this program is running showing
-- the status of connected reactors. Because of the limited space in a terminal
-- only 16 reactors will be displayed.
--
-- ## Use
-- This program should work by just placing a computer next to the computers
-- port on a reactor. However I built this with the idea that multiple
-- reactors would be connected via a wired computer network.
--
-- ## Method of Operation
-- Connect a computer to the computer port on one or more reactors either
-- directly or through a wired computer network. Name this program *startup*
-- then reboot the computer.
--
-- ############################################################################

ProgramVersion = "0.1"
ProgramName = "Reactor Control "
Threshold = 80 --internal storage percentage when to start throttling
Reactors = {} --table of all the reactors found
MaxRF = 10000000 --maximum RF capacity of internal storage
ControlSteps = 100 / (100 - Threshold) --what to increment the control rods by
Interval = 5 --number of seconds to sleep between program loops
Running = false --program loop controls

--
-- Check the current internal energy buffer and modify the control rods if
-- the power storage is above {Threshold}%
--
function checkEnergy(reactorID)
	updateReactorStats(reactorID)
	local stats = Reactors[reactorID].Stats
	local name = Reactors[reactorID].Name
	local currentEnergy = math.ceil((stats.Energy/MaxRF) * 100)
	local changeValue = math.ceil((currentEnergy - Threshold) * 5)

	if currentEnergy >= Threshold then
		if changeValue ~= stats.LastControlRodSetting then
			setAllControlRodLevels(reactorID, changeValue)
		end
	else
		if stats.LastControlRodSetting ~= 0 then
			setAllControlRodLevels(reactorID, 0)
		end
	end
end

--
-- Draw text on a specific line of the terminal
--
function drawLine(lineID, lineText)
	term.setCursorPos(1, lineID)
	term.clearLine()
	term.write(lineText)
end

--
-- Draw the reactor information on the terminal
--
function drawTerminal(...)
	local messageCount = select("#")
	local messageTable = {}
	local statusMessage = "Press Q to shutdown"
	local reactorCount = #Reactors

	if messageCount ~= 0 then
		messageTable = {...}
		statusMessage = messageTable[1]
	end

	term.clear()
	drawLine(1, ProgramName.." v"..ProgramVersion)
	drawLine(2, "---------------------------------------------------")

	-- make sure we only draw the first 16 reactors,
	-- do you really have that many?
	if reactorCount > 16 then
		reactorCount = 16
	end

	for i=1,reactorCount do
		local name = Reactors[i].Name
		local stats = Reactors[i].Stats
		drawLine(2+i, name..": Energy "..stats.Energy..", Rods "..
			stats.LastControlRodSetting.."%")
	end

	drawLine(19, statusMessage)
end

--
-- Print the current status of a reactor, diagnostic function
--
function printStats(reactorID)
	local stats = Reactors[reactorID].Stats
	local name = Reactors[reactorID].Name
	print(name..": Current Energy "..stats.Energy)
end

--
-- Set the all control rods the same and store the value they were set to
--
function setAllControlRodLevels(reactorID, rodInsert)
	Reactors[reactorID].Handle.setAllControlRodLevels(rodInsert)
	Reactors[reactorID].Stats.LastControlRodSetting = rodInsert
end

--
-- Active the Reactor if it is not already running
--
function startReactor(reactorID)
	local handle = Reactors[reactorID].Handle
	local stats = Reactors[reactorID].Stats
	local name = Reactors[reactorID].Name

	updateReactorStats(reactorID)

	if stats.Active ~= true then
		handle.setActive(true)
	end

	setAllControlRodLevels(reactorID, 0)
end

--
-- Deactive the Reactor if it is not already stopped
--
function stopReactor(reactorID)
	local handle = Reactors[reactorID].Handle
	local stats = Reactors[reactorID].Stats
	local name = Reactors[reactorID].Name

	updateReactorStats(reactorID)

	if stats.Active ~= false then
		handle.setActive(false)
	end

	setAllControlRodLevels(reactorID, 100)
end

--
-- Get the Reactor's stats and store them for later use
--
function updateReactorStats(reactorID)
	local stats = Reactors[reactorID].Stats
	local handle = Reactors[reactorID].Handle

	stats.Connected = handle.getConnected()
	stats.Active = handle.getActive()
	--stats.Rods = handle.getNumberOfControlRods()
	--stats.FuelMax = handle.getFuelAmountMax()
	stats.Energy = handle.getEnergyStored()
	--stats.FuelTemp = handle.getFuelTemperature()
	--stats.CasingTemp = handle.getCasingTemperature()
	--stats.FuelAmount = handle.getFuelAmount()
	--stats.WasteAmount = handle.getWasteAmount()
	--stats.EnergyLastTick = handle.getEnergyProducedLastTick()
	--stats.FuelReactivity = handle.getFuelReactivity()
	--stats.FuelLastTick = handle.getFuelConsumedLastTick()

	--for i=1, stats.Rods do
	--	stats.RodName[i] = handle.getControlRodName(i)
	--end

	--for i=1, stats.Rods do
	--	stats.RodLevel[i] = handle.getControlRodLevel(i)
	--end
end

--
-- Find the all the reactors and initialize them
--
function wrapReactors()
	local deviceList = peripheral.getNames()
	local x = 1

	for i=1, #deviceList do
		if peripheral.getType(deviceList[i]) == "BigReactors-Reactor" then
			Reactors[x] = {}
			Reactors[x].Name = deviceList[i]
			Reactors[x].Handle = peripheral.wrap(deviceList[i])
			Reactors[x].Stats = {}
			Reactors[x].Stats.RodName = {}
			Reactors[x].Stats.RodLevel = {}
			x = x + 1
		end
	end
end

-- ############################################################################
--                     Program Running Functions
-- ############################################################################

--
-- Program Startup Procedure
--
function startup()
	Running = true
	wrapReactors()

	for i=1,#Reactors do
		startReactor(i)
	end
end

--
-- Program Shutdown Procedure
--
function shutdown()
	for i=1,#Reactors do
		stopReactor(i)
	end

	term.clear()
	term.setCursorPos(1,1)

	print("Program terminated successfully")
end

--
-- Main program loop to monitor and adjust reactor controls
--
function main()
	while Running do
		for i=1,#Reactors do
			checkEnergy(i)
			drawTerminal()
		end
		sleep(Interval)
	end
end

--
-- shutdown the reactors and this program by pressing 'q'
--
function keyboard()
	while Running do
		local event, key = os.pullEvent() --

		if event == "char" and key =="q" then --wait for the 'terminate' event
			Running = false
			return
		end
	end
end

-- ############################################################################
--                                Program
-- ############################################################################

startup()
parallel.waitForAny(main,keyboard)
shutdown()