#!/usr/bin/env lua5.3

require 'std.strict'
require 'lib' ("..")
local _6502 = require '6502'

local cpu = _6502:new()

local mmu = { ram = {} }
local mmu_metatable = { __index = function(t, key)
				     return t.ram[key] or 0
				  end,
			__newindex = function(t, k, v)
					if ((k == 0xBFF0 or
					     k == 0xF001) and v ~= nil) then
					   io.write(string.format("%c", v))
					end
					if (k == 0x200 and v ~= nil) then
					   if (v == 240) then
					      print("All tests successful!")
					      os.exit(0)
					   end
					   print(string.format("Start test %d", v))
					end
					t.ram[k] = v
				     end,
		     }

setmetatable(mmu, mmu_metatable)
cpu.ram = mmu	      

cpu:init()
cpu:rst()

local f = assert(io.open("6502_functional_test_verbose.bin", "rb") or
	         io.open("tests/6502_functional_test_verbose.bin", "rb"))

local data = f:read("*a")
assert(#data == 65536)

local i = 0
while (i < #data) do
   cpu:writemem(i, data:byte(i+1))
   i = i + 1
end

cpu.pc = 0x400
while (true) do
   if (cpu.pc == 0x453a) then
      print("Somehow wound up at input routine; exiting")
      os.exit(1)
   end

   local o = cpu:readmem(cpu.pc)
--   print(string.format("Executing opcode %s [0x%X]", cpu.opname[cpu.opcodes[o][1]], o))
   local cc = cpu:step()
--[[   print(string.format("%d OP $%.2X #%d 0x%.2X X 0x%.2X Y 0x%.2X A 0x%.2X SP 0x%.2X S 0x%.2X %s %s %s %s %s %s %s %s [$11=]0x%.2X", 
		       cpu.cycles, cpu:readmem(cpu.pc), cpu:readmem(0x200),
		       cpu.pc, cpu.X, cpu.Y, cpu.A, cpu.sp, cpu.F,
		       ((cpu.F & cpu.flags.N)~=0) and 'N' or 'n',
		       ((cpu.F & cpu.flags.V)~=0) and 'V' or 'v',
		       ((cpu.F & cpu.flags.UNK)~=0) and 'U' or '-',
		       ((cpu.F & cpu.flags.B)~=0) and 'B' or 'b',
		       ((cpu.F & cpu.flags.D)~=0) and 'D' or 'd',
		       ((cpu.F & cpu.flags.I)~=0) and 'I' or 'i',
		       ((cpu.F & cpu.flags.Z)~=0) and 'Z' or 'z',
		       ((cpu.F & cpu.flags.C)~=0) and 'C' or 'c',
		       cpu:readmem(0x11)
		 ))
		       --]]
end


