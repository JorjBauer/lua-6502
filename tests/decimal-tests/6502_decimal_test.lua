#!/usr/bin/env lua5.3

require 'std.strict'
require 'lib' ("../..", "..")
local _6502 = require '6502'

local cpu = _6502:new()

local getopt = require 'getopt'
local opts = {}
local ret = getopt.std("f:v", opts)

if (not opts["f"]) then
   print("Missing '-f <file>' argument")
   os.exit(1)
end

cpu:init()
cpu:rst()

local f = assert(io.open(opts['f'], "rb"))

local data = f:read("*a")

local i = 0
while (i < #data) do
   cpu:writemem(i, data:byte(i+1))
   i = i + 1
end

local last3 = {0,0,0} -- last 3 PCs, for reporting of errors

cpu.pc = 0x200
while (true) do
   last3[3] = last3[2]
   last3[2] = last3[1]
   last3[1] = cpu.pc

   local o = cpu:readmem(cpu.pc)
--   print(string.format("Executing opcode %s [0x%X]", cpu.opname[cpu.opcodes[o][1]], o))
   if (o == 0xDB) then
      local result = (cpu:readmem(0x0B) == 0x01) and "failed" or "passed"
      print("Test complete. Result: " .. result)

      if (result == "failed") then
	 print(string.format("Failed during test at 0x%.4X; failed specific test at 0x%.4X", last3[2], last3[3]))
	 print(string.format("  Operands under test: $%.2X and $%.2X", cpu:readmem(0), cpu:readmem(1)))
	 print(string.format("%X HA=$%.2X HNVZC=$%.2X DA=$%.2X DNVZC=$%.2X AR=$%.2X NF=$%.2X VF=$%.2X ZF=$%.2X CF=$%.2X",
			     cpu.cycles,
			  cpu:readmem(2),
			  cpu:readmem(3),
			  cpu:readmem(4),
			  cpu:readmem(5),
			  cpu:readmem(6),
			  cpu:readmem(7),
			  cpu:readmem(8),
			  cpu:readmem(9),
			  cpu:readmem(0x0A)
		    ))

      end

      os.exit(0)
   end

   local cc = cpu:step()

   if (opts['v']) then
      print(string.format("%d OP $%.2X 0x%.2X X 0x%.2X Y 0x%.2X A 0x%.2X SP 0x%.2X S 0x%.2X // N1=$%.2X N2=$%.2X HA=$%.2X HNVZC=$%.2X DA=$%.2X DNVZC=$%.2X AR=$%.2X NF=$%.2X VF=$%.2X ZF=$%.2X CF=$%.2X ERROR=$%.2X N1L=$%.2X N1H=$%.2X N2L=$%.2X N2H=$%.2X", 
			  cpu.cycles, cpu:readmem(cpu.pc),
			  cpu.pc, cpu.X, cpu.Y, cpu.A, cpu.sp, cpu.F,
			  cpu:readmem(0),
			  cpu:readmem(1),
			  cpu:readmem(2),
			  cpu:readmem(3),
			  cpu:readmem(4),
			  cpu:readmem(5),
			  cpu:readmem(6),
			  cpu:readmem(7),
			  cpu:readmem(8),
			  cpu:readmem(9),
			  cpu:readmem(0x0A),
			  cpu:readmem(0x0B),
			  cpu:readmem(0x0C),
			  cpu:readmem(0x0D),
			  cpu:readmem(0x0E),
			  cpu:readmem(0x0F)
		    ))
   end

end


