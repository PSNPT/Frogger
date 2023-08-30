![](./Graphic/main.gif)

# Requirements
- Java J2SE 1.5 (or later) SDK 
- [MARS](http://courses.missouristate.edu/kenvollmar/mars/download.htm)

# Execution
1. Double click the .jar file found in the MARS download linked above
2. Click **File**->**Open and navigate** to the folder you cloned the repository to and open **main.asm**
3. Click **Tools**->**Keyboard and Display MMIO Simulator** and click **Connect to MIPS**
4. Click **Tools**->**Bitmap Display** and click **Connect to MIPS**
5. Within **Tools**->**Bitmap Display**, configure the display as outlined in the starting comments of **main.asm**
6. Click **Run**->**Assemble**, then **Run**->**Go**
7. Thats it! The **Bitmap Display** will house the visuals of the game and the WASD keys can be used to control the playable character via inputting them in the **Keyboard** box in the **Keyboard and Display MMIO Simulator**

# Difficulty
The difficulty of the game is linked to the speed with which the main process loop iterates; the faster it iterates, the faster the cars move, the harder it is to dodge them. 

On modern machines which can execute billions of instructions a second, the main loop can iterate essentially instantly, but is limited by MARS. 

A further (main) limitation is placed via the *speed* variable in the .data section in the head of the file. At the end of every main loop, a syscall is requested to sleep for approximately *speed* ms. 

By default, *speed* is set to 17. To make the game easier, increase *speed* and vice versa.

In addition, by default the player has 3 lives. This can be edited via the *lives* variable in the .data section.
