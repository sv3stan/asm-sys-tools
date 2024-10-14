**Program in Assembly for DOS that Works with Memory Management and
Displays Information about Memory Segments (MCB - Memory Control Block)
on the Screen.**

**Main Actions of the Program:**

1. **Initialization**: The program sets memory segments and screen parameters,
   outputs a header, and prepares the screen for displaying data about memory segments.

2. **Working with MCB**: The program uses DOS interrupts to obtain a list of memory
   segments (MCB) and their attributes, such as size, PSP address, and segment
   type (e.g., program, system data, or free memory). It also checks the first
   MCB and sequentially traverses the entire memory until it finds all segments.

3. **Displaying Data**: For each found segment, the program:

   - Calculates its size and converts it from binary to decimal representation.
   - Converts the PSP and MCB addresses into hexadecimal representation.
   - Outputs information about the segment to the screen in tabular form.

4. **Keyboard Handling**: The program waits for a key press to continue,
   clears the screen, and if there are too many memory segments for one screen,
   it displays them in parts.

5. **Working with Flags**: The program uses flags to mark the segment type
   (program, free memory, environment, etc.) and then displays the corresponding
   message.

**Key Points:**

- **DOS Interrupts**: The program uses interrupt 21h for interaction with DOS,
  for example, to obtain a list of memory segments (function 5200h) and for
  outputting to the screen (function 13h).
- **Graphical Display**: BIOS function (10h) is used for outputting characters
  and text to the screen.
- **Memory Management**: The program directly accesses memory segments using
  assembly instructions such as `mov`, `cmp`, `lea`, and utilizes registers for
  calculations.
