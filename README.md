This is a complete pure-Lua 65C02 emulator.

This requires Lua 5.3 (because of the bitwise functions). Yes, you
could probably port it to 5.2 and 5.1 fairly easily with one of the
Lua bitwise libraries. I'm more inclined to just leave it at Lua
5.3+. If you want to fork, then have at it!

# How would you use this?

Well, if I wanted to build an (original) Apple ][ emulator, I would
probably do it similarly to how I structured the tests. First build a
CPU...

``` lua
local _6502 = require '6502'
local cpu = _6502:new()
```

... and then override the simple memory array with a memory management
unit, which implements the various pieces of Apple ][ memory magic:

``` lua
local mmu = { ram = {} }
local mmu_metatable = { __index = function(t, key)
                                     return t.ram[key] or 0
                                  end,
                        __newindex = function(t, k, v)
                                        if (k == 0xF001 and v ~= nil) then
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
```

Basically, the **__index** function gets called for any memory "read"; and
the **__newindex** function gets called for any "write". This MMU was
specifically built for the verbose CPU test; whenever it wants to
output a character, the test writes it to memory location 0xF001; and
whenever it starts a new test, it writes to memory location 0x200. So
those two memory locations are treated specially when writing to this
MMU; but it returns straight out of its "ram" table when reading
(since there's nothing special about its reads).

For memory in an Apple ][, it would do straight reads and writes for
any memory <= 0xC000. For 0xC000 through 0xCFFF, you'd do something
with the hardware I/O (where reads and writes are both special); and
then from 0xD000 through 0xFFFF you have ROM, which will need to be
loaded from a file or some such:

``` lua
local f = assert(io.open("apple2o.rom", "rb") )
local data = f:read("*a")
assert(#data == 12288)

local i = 0
while (i < #data) do
   mmu[0xC000 + i] = data:byte(i+1)
   i = i + 1
end
```

Finally, you would reinitialize the CPU, perform a reset, and then
start running it in a loop.

``` lua
cpu:init()
cpu:rst()
while (true) do
   cpu:step()
end
```

Of course, then you get in to I/O issues, like keyboards and disk
drives; how you're going to draw a display; performance issues; what
about proper speed timing?; and details, details, details...

# Tests

The tests are from the fantastic project

  https://github.com/Klaus2m5/6502_65C02_functional_tests

The tests in the tests/ directory are...

## 6502_functional_test.lua
  from git commit fe99e5616243a1bdbceaf5907390ce4443de7db0
   using files
    6502_functional_test.bin
    6502_functional_test.lst

This is basic testing of all core 6502 functions. In all, there are 43
tests; it takes some time to execute them (about 40 seconds on my 2015
Macbook Pro).

## 6502_functional_test_verbose.lua
  from git commit fe99e5616243a1bdbceaf5907390ce4443de7db0
  which I assembled with as65, with 'report' enabled
    6502_functional_test_verbose.bin
    6502_functional_test_verbose.lst

These are the same tests as above, but I assembled it in verbose mode;
if there's a test failure, it's much more explicit about it. An error
elicits output like this:

```
  regs Y X A  PS PCLPCH
  01F9 04 02 20 B0 0B 2F 30
  000C 20 00 00 00 00 00 00
  0200 1E 00 00 00 00 00 00 00
  press C to continue
```

(Of course, I haven't implemented "press C to continue" so it just
busy-loops forever.)

## 65C02_extended_opcodes_test.lua
  from git commit f54e9a77efad2d78077107a919a412407c106f22
    65C02_extended_opcodes_test.bin
    65C02_extended_opcodes_test.lst

This tests much of the 65C02's extended behavior, including the
"invalid" opcodes. This has 21 tests and should end with "All tests
successful!" just like the other two tests.

## decimal_tests/*

The BCD "decimal mode" ADC and SBC operations behave in unexpected and difficult to explain ways - particularly the oVerflow flag, and especially when operating on "invalid" BCD numbers. For example - in Decimal mode, the operation "0x19 ADC 0x01" (hex 19 plus 1 -- or 25 + 1 in decimal) equals "0x20" (32). That's binary coded decimal, where the "hex" number 0x20 actually represents the decimal number 20.

So what happens when you tell it to add 0x1C + 0x01? 0x1C isn't a valid BCD number, so it's not obvious what should happen.

The test **65c02-all.bin** is a complete test of all decimal mode addition and subtraction, with validation of all of the N, V, Z, and C status flags. The wrapper 6502_decimal_test.lua take a "-f" argument that tells it which of the .bin files you want to load and execute. So it's invoked like this:

```
$ tests/decimal-tests/6502_decimal_test.lua -f tests/decimal-tests/65c02-all.bin
```

## Questions?

You can try emailing me at jorj@jorj.org. Glad to answer what I can, but my mailbox overfloweth perpetually and sometimes it takes a while for a reply!
