#!/usr/bin/env lua5.3

require 'std.strict'

require 'lib' ("..")
local curses = require 'curses'
local _6502 = require '6502'

local cpu = _6502:new()

const = require "const"
local inspect = require "inspect"

-- Per Apple-1 Operation Manual (1976)
local _c = const {
   DSPCR = 0xd013,
   DSP   = 0xd012,
   KBDCR = 0xd011,
   KBD   = 0xd010 }


local stdscr

local screenX = 0
local screenY = 0

local running = true
local mmu = { ram = {},
	      immutable = {},

	      reset = function()
			 mmu.ram[_c.KBDCR] = 0
			 mmu.ram[_c.DSPCR] = 0
			 mmu.ram[_c.DSP] = 0
			 mmu.ram[_c.KBD] = 0x80
		      end,
	   }

local mmu_metatable = { __index = function(t, address)
				     if (address == _c.KBD) then t.ram[_c.KBDCR] = 0x27; return t.ram[_c.KBD] end

				     return t.ram[address] or 0
				  end,
			__newindex = function(t, address, v)
					if (address == _c.DSP) then
					   if ((t.ram[_c.DSPCR] & 0x04) == 0x04) then
					      t.ram[_c.DSP] = v
					      return
					   end
					end
					if (address == _c.KBDCR) then
					   if (t.ram[_c.KBDCR] == 0) then
					      v = 0x27
					   end
					   t.ram[_c.KBDCR] = v
					   return
					end


					if (t.immutable[address]) then
					   assert(0, "Tried to write to ROM")
					   return
					end
					t.ram[address] = v
				     end,
		     }

setmetatable(mmu, mmu_metatable)
cpu.ram = mmu	      

-- Load the monitor ROM @ 0xFF00
local f = assert(io.open("monitor.rom", "rb"), "Can't open monitor.rom")
local data = f:read("*a")
assert(#data == 256)
local i=0
while (i < #data) do
   cpu:writemem(0xFF00 + i, data:byte(i+1))
   mmu.immutable[0xFF00+i] = true
   i = i + 1
end

-- Load the basic ROM @ 0xE000
local f = assert(io.open("basic.rom", "rb"), "Can't open basic.rom")
local data = f:read("*a")
assert(#data == 4096)
local i=0
while (i < #data) do
   cpu:writemem(0xE000 + i, data:byte(i+1))
   mmu.immutable[0xE000+i] = true
   i = i + 1
end

cpu:init()

			 mmu.ram[_c.KBDCR] = 0
			 mmu.ram[_c.DSPCR] = 0
			 mmu.ram[_c.DSP] = 0
			 mmu.ram[_c.KBD] = 0x80

--mmu:reset()
cpu:rst()

stdscr = curses.initscr()
curses.cbreak()
curses.echo(false)
curses.nl(false)
stdscr:clear()
stdscr:nodelay(true)
stdscr:scrollok(true)
stdscr:refresh()

function checkForInput()
   local ret = false

   if (mmu[_c.KBDCR] == 0x27) then -- can handle input
      local c = stdscr:getch()
      if (c and c > 0 and c < 256) then
	 -- and we have input
	 c = c & 0x7F
	 if (c >= 0x61 and c <= 0x7A) then c = c & 0x5F end
	 if (c < 0x60) then
	    mmu[_c.KBD] = c | 0x80 -- write kbd
	    mmu[_c.KBDCR] = 0xA7 -- write KbdCr
	    ret = true
	 end
      end
   end
   
   return ret
end

function updateScreen()
   local dsp = mmu[_c.DSP]

   -- High bit of the display character indicates there's something waiting to display
   if (dsp & 0x80 == 0x80) then
      dsp = dsp & 0x7F
      local tmp = dsp
      if (dsp >= 0x60 and dsp <= 0x7F) then
	 tmp = tmp & 0x5F
      end
      if (tmp == 0x0D) then 
	 -- return key
	 screenX = 0
	 screenY = screenY + 1
      else
	 if (tmp >= 0x20 and tmp <= 0x5F) then
	    stdscr:mvaddch(screenY, screenX, tmp)
	    screenX = screenX + 1
	 end
      end
      
      if (screenX == 40) then
	 screenX = 0
	 screenY = screenY + 1
      end
      
      if (screenY == 24) then
	 stdscr:scrl(1)
	 screenY = 23
      end

      -- draw the cursor
      stdscr:move(screenY, screenX)
      
      mmu[_c.DSP] = dsp -- write to dsp
   end

   stdscr:refresh()
end

local function err (err)
   curses.endwin ()
  print "Caught an error:"
   print (debug.traceback (err, 2))
   os.exit (2)
end

function main()
   while (running) do
      local pc = cpu.pc
      
      local o = cpu:readmem(cpu.pc)
      local cc = cpu:step()
      
      checkForInput()
      updateScreen()
   end
end

xpcall(main, err)
