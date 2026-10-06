# Intel 8085 Assembly Exercises

Eleven small Intel 8085 assembly programs written for the μLAB educational microcomputer and its simulator. They read DIP switches and a hex keypad, drive LEDs and 7-segment displays, use the monitor's delay and display routines, and handle the RST 6.5 hardware interrupt. Each exercise set also has a written report with the theory answers: memory organization and address decoding, macros, interrupt timing and a cost comparison of hardware technologies.

These are my solutions to the three exercise sets of **Microcomputer Systems** (Συστήματα Μικροϋπολογιστών), a 6th-semester course at the School of Electrical and Computer Engineering, National Technical University of Athens (ECE NTUA), academic year 2023–24. The sets were issued by the Microcomputer and Digital Systems Laboratory (Εργαστήριο Μικροϋπολογιστών και Ψηφιακών Συστημάτων).

| Set | Exercise | File | Topic |
|-----|----------|------|-------|
| [1](#set-1-machine-code-led-patterns-and-bcd) | 1 | `set1/8085exercises/exercise1.1.asm` | Disassembling machine code |
| | 2 | `set1/8085exercises/exercise1.2.asm` | Moving LED with switch-selected mode |
| | 3 | `set1/8085exercises/exercise1.3.asm` | Binary to two-digit decimal |
| [2](#set-2-memory-polling-and-the-keypad) | 1 | `set2/8085exercises/exercise2.1.asm` | Filling memory, counting bits and values in a range |
| | 2 | `set2/8085exercises/exercise2.2.asm` | Timed light switch (polling) |
| | 3 i | `set2/8085exercises/exercise2.3a.asm` | Lowest ON switch to LED |
| | 3 ii | `set2/8085exercises/exercise2.3b.asm` | Keypad (`KIND`) to LED bar |
| | 3 iii | `set2/8085exercises/exercise2.3c.asm` | Direct keypad scanning, code on 7-segment displays |
| | 4 | `set2/8085exercises/exercise2.4.asm` | Simulating a logic-gate IC |
| [3](#set-3-interrupts) | 1 | `set3/8085exercises/exercise3.1.asm` | Interrupt-driven 45 s blinking timer |
| | 2 | `set3/8085exercises/exercise3.2.asm` | Interrupt-driven keypad input and threshold check |

The theory exercises of each set are answered only in the reports ([`set1/report1.pdf`](set1/report1.pdf), [`set2/report2.pdf`](set2/report2.pdf), [`set3/report3.pdf`](set3/report3.pdf), in Greek). See [Theory exercises](#theory-exercises).

## Getting started

### Prerequisites

- The **μLAB simulator** (the course's 8085 training-system simulator), available from the course website. The course also provides a VirtualBox virtual machine for running it on Linux.

The programs are written for μLAB, not for a generic 8085 assembler. They call routines from the μLAB monitor ROM, use μLAB's memory-mapped I/O addresses, and write hex constants without a leading zero (`FEH` rather than `0FEH`), which most other assemblers reject.

```bash
git clone https://github.com/eleninspl/8085-assembly-exercises.git
cd 8085-assembly-exercises
```

Open an `.asm` file in the simulator, assemble it and run it. Set the inputs with the simulated DIP switches and keypad, and watch the LEDs and 7-segment displays. Set 2 exercise 1 ends with `RST 1`, which returns to the monitor so you can inspect registers and memory; the other programs loop forever. The programs that use `DELB` depend on the simulator's speed setting for their timing.

### μLAB conventions used in the code

| Address / routine | Use |
|-------------------|-----|
| `2000H` | DIP switch input port |
| `3000H` | LED output port. The LEDs use inverted logic: a `0` bit lights the LED. |
| `2800H` / `1800H` | Keypad scan-line output and return-line input (set 2, exercise 3 iii) |
| `0A00H`, `0B00H` | Six-byte display buffers, rightmost digit first. The value `10H` shows a blank digit. |
| `IN 10H` | Lifts the memory protection so programs can write anywhere in RAM (`0800H`–`0BFFH`) |
| `DELB` | Delay of `BC` milliseconds |
| `KIND` | Wait for a keypad key and return its code in `A` |
| `STDM`, `DCD` | Copy six bytes from `(DE)` to the display buffer, then show them on the 7-segment displays |
| `INTR_ROUTINE` | Label of the RST 6.5 interrupt handler, entered when the `INTR` key is pressed |

## Set 1: Machine code, LED patterns and BCD

**Exercise 1. Task.** Disassemble this program, loaded at `0800H`, explain what it does, draw its flowchart, and change it to run continuously:

```
06 01 3A 00 20 FE 00 CA 13 08 1F DA 12 08 04 C2 0A 08 78 2F 32 00 30 CF
```

**How it works.** The program reads the DIP switches. It rotates the value right until a `1` falls into the carry, counting the steps in `B`. The result is the position (1–8) of the lowest switch that is ON, shown in binary on the LEDs. With all switches OFF, all LEDs stay off. `CMA` inverts the value for the active-low LEDs. For continuous operation, the program gets a `START` label and a `JMP START` before the final `RST 1`. The `.asm` file is this continuous version; the address-by-address disassembly and the flowchart are in the report.

**Exercise 2. Task.** Show one lit LED that moves about every 0.5 s:

| DIP switch | Behaviour |
|------------|-----------|
| LSB ON | Bounce between LSB and MSB: positions 1 2 … 8 7 … 2 1 2 … |
| LSB OFF | Rotate left: 1 2 … 8 1 2 … |
| 2nd LSB ON | Freeze; when it goes OFF again, continue from the same LED |

**How it works.** Register `E` holds the current LED pattern. A `DELB` call with `BC = 01F4H` (500 ms) runs before each step. The program then masks the two low switches and jumps to the bounce, rotate or freeze code. The bounce reverses at `7FH` (MSB lit) and `FEH` (LSB lit).

**Exercise 3. Task.** Read an 8-bit number from the DIP switches and show it in decimal on the LEDs: tens in the 4 high bits, units in the 4 low bits. Show *x* − 100 for 100–199, and light all LEDs for 200 and above. Run continuously.

**How it works.** The tens are found by repeated subtraction of 10, and the units are what remains. Values 100–199 have 100 subtracted first. The tens are shifted into the high nibble, the units added, and the result inverted for the LEDs.

## Set 2: Memory, polling and the keypad

**Exercise 1. Task.** (a) Store the numbers 0–127 at `0900H` onward. (b) Count the `1` bits in all of them and keep the result in `BC`. (c) Count how many lie between `10H` and `60H` inclusive and keep the result in `D`.

**How it works.** One loop stores each number and calls two subroutines on it. One subroutine rotates the byte eight times and increments `BC` on each carry. The other increments `D` if the value is in range. The program ends with `BC = 01C0H` (448) and `D = 51H` (81), the values in the report. The report also checks them by hand: 7 bits × 128 numbers / 2 = 448, and 96 − 16 + 1 = 81.

**Exercise 2. Task.** Model a room light. When the DIP switch MSB goes OFF → ON → OFF, like a push button, light all LEDs for about 20 s. A new press during that time restarts the 20 s. Sample the switch at least every 0.1 s.

**How it works.** The program waits for the OFF → ON → OFF sequence, then counts down 200 steps of 100 ms (`DELB` with `BC = 0064H`). It checks the switch at every step. While the switch is ON the countdown continues, and on release it restarts from 200.

**Exercise 3. Task.** Three programs:

1. Light the LED that matches the lowest DIP switch that is ON.
2. Wait for keys 1–8 on the keypad (using `KIND`). For key *n*, light LED *n* and every LED above it.
3. Scan the keypad directly, without `KIND`, and show the code of the pressed key on the two leftmost 7-segment displays using `STDM` and `DCD`.

**How it works.** (i) Rotates the input right until a `1` reaches the carry, rotating the LED pattern left in step. (ii) Builds the pattern 2<sup>*n*−1</sup> − 1 in a loop. Written to the active-low port, this lights LEDs *n* to 8. Other keys turn all LEDs off. (iii) Writes a `0` to one scan line at a time on port `2800H` and reads the three return lines from `1800H`. Each line/column pair maps to its key code from the μLAB keypad table. The two nibbles of the code go into the display buffer for the leftmost digits. The `HDWR STEP` key is skipped, as the assignment allows, because the simulator does not implement it.

**Exercise 4. Task.** Simulate an IC with six gates. The DIP switches give A3 B3 A2 B2 A1 B1 A0 B0 (MSB to LSB), and the four low LEDs show:

| Output | Function |
|--------|----------|
| X0 | (A0 AND B0) OR (A1 AND B1) |
| X1 | A1 AND B1 |
| X2 | (A2 XOR B2) OR (A3 XOR B3) |
| X3 | A3 XOR B3 |

The four high LEDs must stay off.

**How it works.** Each input pair is isolated with `ANI` and lined up with a rotate. The pair is combined with `ANA` or `XRA`, and the results are merged into one byte and inverted for output. X0 and X1 are correct; X2 and X3 are not (see [Known limitations](#known-limitations)).

## Set 3: Interrupts

**Exercise 1. Task.** When an RST 6.5 interrupt arrives (the `INTR` key), blink all LEDs for about 45 s, then turn them off. A new interrupt restarts the 45 s. Show the remaining seconds in decimal on the two leftmost 7-segment displays.

**How it works.** The main program unmasks only RST 6.5 (`SIM` with `0DH`) and waits in a loop. The handler re-enables interrupts at once, so a new interrupt restarts it from 45. Each second is 10 × 50 ms with the LEDs on, then 10 × 50 ms with them off. The display is refreshed every 50 ms. A subroutine converts the counter to tens and units for the display buffer.

**Exercise 2. Task.** On each RST 6.5 interrupt, read two hex digits from the keypad (`KIND`) and show them on the two middle 7-segment displays. Compare the value with three thresholds K1 < K2 < K3, held in `C`, `D` and `E`. Light one of the four low LEDs for the range [0, K1], (K1, K2], (K2, K3] or (K3, FFH]. After initialization, the main program is an endless wait loop.

**How it works.** The thresholds are set to `40H`, `80H` and `C0H`, then incremented once. That way a single `CMP` followed by `JC` tests "value ≤ K". The handler combines the two digits into one byte, shows them, and lights the matching LED.

## Theory exercises

These are answered only in the reports:

| Set | Exercises |
|-----|-----------|
| 1 | Cost per unit of a portable device built with discrete ICs, an FPGA, or one of two custom SoCs. The cheapest option is the FPGA up to 200 units, discrete ICs from 200 to 2,000, SoC-1 from 2,000 to 7,000, and SoC-2 above 7,000. The report also finds the FPGA chip price (€14) at which the discrete-IC option stops being the cheapest anywhere. |
| 2 | Internal organization of a 256×4 SRAM; a memory system of 8 KB ROM and 4 KB RAM with address decoding using a 74LS138 and using gates only; an 8085 system with a given memory map and I/O ports |
| 3 | Macros `INR16`, `FILL` and a 17-bit rotate; the stack and PC when RST 6.5 interrupts a `JMP`; averaging 16 bytes received in 4-bit halves, with and without interrupts |

## Known limitations

The code is kept exactly as it was submitted. While writing this README, I reviewed it again and found the issues below:

- **Set 2, exercise 3 i** (`exercise2.3a.asm`): `JNZ ALL_ZEROS` follows `LDA 2000H`, and `LDA` does not set the flags. The jump therefore depends on whatever zero flag the program started with. If it is clear, the LEDs just copy the switches. If it is set, the program works, except that with all switches OFF it loops forever. The intended check is `ORA A` followed by `JZ ALL_ZEROS`.
- **Set 2, exercise 4** (`exercise2.4.asm`): The A2 XOR B2 term ends up one bit too high, so X2 and X3 are wrong whenever A2 ≠ B2 (half of all inputs). When both XORs are 1, the carry also lights LED 4, which should stay off. One more `RRC` after line 35 fixes it. X0 and X1 are correct.
- **Set 3, both exercises**: The interrupt handlers end with `JMP WAIT` instead of `RET`, so every interrupt leaves its return address on the stack. This is harmless for a short demo, but the stack grows with each interrupt.
- **Set 3, exercise 1**: The LEDs change state every 0.5 s, so a full blink takes 1 s. When the time runs out, the display stays at `01` instead of clearing.
- **Set 3, exercise 2**: The rightmost display (`0B00H`) is never blanked, so it shows whatever byte is in that location. Incrementing the thresholds would wrap a K3 of `FFH` to `00H`; the hard-coded values avoid this.
- **Set 1, exercise 2**: If the LED is frozen while moving right, it moves left when released. The first LED lit after start is position 2, not 1.
- **Reports**: A few theory answers have mistakes. In set 1, the €14 limit is right, but the inequality is written the wrong way round: the discrete-IC option disappears when the FPGA chip costs €14 *or less*. In set 3, the `INR16` macro ends with `PUSH PSW` instead of `POP PSW`. The exercise 5 programs read the low nibble instead of X4–X7, and they never decrement the counter or add the received bytes to `HL`.

## For students taking the course

This repository is here to help you understand the material: how the μLAB I/O ports and monitor routines fit together, and what a working approach looks like. Write your own solutions. The exercise sets carry only part of the grade, and the written exam is most of it. You will not pass the exam with code you did not write.

The μLAB notes ("Εισαγωγή στο Εκπαιδευτικό Σύστημα μLAB") are the reference for every routine and address used here. Single-step a program with `INSTR STEP`, or insert `RST 1` where you want to stop and inspect registers and memory. When single-stepping, replace `CALL DELB` with three `NOP`s.
