The program is written in assembly language for DOS and works with memory management and displays information about memory segments (MCB - Memory Control Block) on the screen. The main actions of the program are as follows:

1. **Initialization**: The program sets up memory segments and screen parameters, outputs a header, and prepares the screen for displaying data about memory segments.

2. **Working with MCB**: The program uses DOS interrupts to obtain a list of memory segments (MCB) and their attributes, such as size, PSP address, and segment ownership flags (e.g., program, system data, or free memory). It also checks the first MCB and sequentially traverses all memory until it finds all segments.

3. **Displaying Data**: For each found segment, the program:
   - Calculates its size and converts it from binary to decimal representation.
   - Converts the PSP and MCB addresses to hexadecimal format.
   - Outputs segment information to the screen in tabular form.

4. **Keyboard Handling**: The program waits for a key press to continue its operation, clears the screen, and if there are too many memory segments for one screen, it displays them in parts.

5. **Handling Flags**: The program uses flags to mark the segment type (program, free memory, environment, etc.) and then displays the corresponding message.

### Key Points:

- **DOS Interrupts**: The program uses interrupt 21h to interact with DOS, for example, to obtain a list of memory segments (function 5200h) and to output to the screen (function 13h).
- **Graphical Display**: BIOS function 10h is used for displaying characters and text on the screen.
- **Memory Management**: The program directly accesses memory segments using assembly instructions such as `mov`, `cmp`, `lea`, and utilizes registers for calculations.