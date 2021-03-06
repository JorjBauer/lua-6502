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
					if (k == 0x202 and v ~= nil) then
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

local f = assert(io.open("65C02_extended_opcodes_test.bin", "rb") or
	         io.open("tests/65C02_extended_opcodes_test.bin", "rb"))

local data = f:read("*a")
assert(#data == 65536)

local i = 0
while (i < #data) do
   cpu:writemem(i, data:byte(i+1))
   i = i + 1
end

cpu.pc = 0x400
while (true) do
   local o = cpu:readmem(cpu.pc)
-- These print statements were useful while debugging
--   print(string.format("Executing opcode %s [0x%X]", cpu.opname[cpu.opcodes[o][1]], o))
   local cc = cpu:step()
--   print(string.format("%d OP $%.2X #%d 0x%.2X X 0x%.2X Y 0x%.2X A 0x%.2X SP 0x%.2X S 0x%.2X", 
--		       cpu.cycles, cpu:readmem(cpu.pc), cpu:readmem(0x202),
--		       cpu.pc, cpu.X, cpu.Y, cpu.A, cpu.sp, cpu.F))

end


