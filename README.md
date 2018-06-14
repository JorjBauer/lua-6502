This is a complete pure-Lua 65C02 emulator.

This requires Lua 5.3 (because of the bitwise functions). Yes, you
could probably port it to 5.2 and 5.1 fairly easily with one of the
Lua bitwise libraries. I'm more inclined to just leave it at Lua
5.3+. If you want to fork, then have at it!

# How would you use this?

Well, I started to write a "if I wanted to make an Apple emulator" section here... but then I just wrote the emulator instead.

In the **apple1/** directory is a reasonable facsimile of an Apple 1. 

The only tricky piece is the Memory Management Unit; it has two important features - the PIA 6820 interface, and immutable memory.

The PIA 6820 is an interface chip that was used in the Apple 1 to attach the keyboard and screen drivers to the 6502. It has two control registers: DSPCR (the display control register) and KBDCR (the keyboard control register) and two data registers that pair to those (DSP and KBD). If something reads from the KBD data register, then the KDBCR is reset to 0x27 before the read happens; and if something writes to DSP, then the DSPCR is checked before allowing the write. (There's also some initialization of KBDCR the first time it's used.) These pieces of miscellania are implemented via __index (read) and __newindex (write) operations in the MMU's metatable.

ROM is emulated via the immutable memory feature of the MMU. The MMU itself contains two tables: one named ram[], and the other named immutable[]. When a read happens from the MMU as a table object, the data is actually retrieved from the ram[] table. And when writing, the value is written to the ram[] table *if* the immutable[] table does not have a value for that address.

So when the monitor and basic ROMs are loaded at startup, those memory locations are marked as immutable after their initial set.

In checkForInput(), if the KBDCR register shows that the keyboard data register is capable of storing new data, then a key is read (non-blocking, thanks to **stdscr:nodelay(true)**) using **stdscr:getch()**. Assuming a key has been pressed, the value is manipulated to be the value the Apple 1 wants (all uppercase); and then the high bit is set (indicating it's new data) and stored in the KBD data register. The KBDCR register is set to 0xA7, and now the Apple 1 thinks a key has been pressed.

In updateScreen(), we look at the high bit of the DSP register; if it's set, then a new character needs to be output. The character is turned in to an appropriate ascii value, is put on the screen, the cursor moved forward and scrolling taken care of if necessary; then the high bit is cleared, and the value is stored back in DSP (indicating what the key pressed *was*, but that it's no longer a new keypress). **stdscr:redraw()** tells curses to flush the data to the terminal, and then it's done.

Of course, this brute-force approach isn't terribly efficient, and takes a number of shortcuts. It has no speed throttling, so it's slamming the CPU of your machine and runs substantially faster than the original Apple 1; it runs in a terminal, meaning it doesn't use the Apple font or blinking '@' cursor; it's emulating a 65C02 instead of a 6502, so there are opcodes that will actually do things that shouldn't. But it proves the point: in 192 lines of Lua, it's possible to write a fairly decent Apple 1 emulator.

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
