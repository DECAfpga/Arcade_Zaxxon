# Zaxxon DECA port 

DECA port for Zaxxon by Somhic (03/07/21) adapted from DE10_lite port by Dar (https://sourceforge.net/projects/darfpga/files/Software%20VHDL/zaxxon/)

[Read history of Zaxxon Arcade.](https://www.arcade-museum.com/game_detail.php?game_id=12757)

**Features:**

* **It does not require SDRAM.**
* HDMI video output (special resolution will not work on all LCD monitors)
* VGA 444 video output is available through GPIO (see pinout below). 
  * VGA (30 kHz) & RGB (15 kHz) modes available. Toggle VGA / RGB  with F8 key
  * Tested with PS2 & R2R VGA adapter (333)  https://www.waveshare.com/vga-ps2-board.htm
* NO AUDIO AVAILABLE IN THIS CORE YET
* Joystick available through GPIO  (see pinout below).  **Joystick power pin must be 2.5 V**
  * **DANGER: Connecting power pin above 2.6 V may damage the FPGA**
  * This core is prepared for Megadrive 6 button gamepads as it outputs a permanent high level on pin 7 of DB9

**Additional hardware required**:

- PS/2 Keyboard connected to GPIO  (see pinout below)

**Versions**:

- v1 initial revision
- v2 added video_vs & video_hs in zaxxon.vhd
- v3 HDMI working. Added video_clk output in zaxxon.vhd
- v3.1. VGA & RGB versions working. 


see changelog in top level file /deca/zaxxon_deca.vhd

**Compiling:**

* Load project from /deca/zaxxon_deca.qpf

* sof/svf files already included in /deca/output_files/


**Pinout connections:**

![pinout_deca](pinout_deca.png)

**Others:**

* Button KEY0 is a reset button

### STATUS

* Working fine

* HDMI video outputs special resolution so will not work on all monitors. 

* No audio possible without adding SDRAM due to the way the original ROM was made.

### Keyboard players inputs :

F1 : Add coin
F2 : Start 1 player
F3 : Start 2 players

SPACE       : fire
RIGHT arrow : move right
LEFT  arrow : move left
UP    arrow : move up
DOWN  arrow : move down

F4 : flip screen (additional feature)
F5 : Service mode ?! (not tested)
F7 : uprigth/cocktail mode (required reset)
F8 : toggles VGA / RGB video mode



Other details : see original README.txt / zaxxon.vhd

---------------------------------
Compiling for DECA
---------------------------------

 - You would need the original MAME ROM files
 - Use tools included to convert ROM files to VHDL (read original README.txt)
 - put the VHDL ROM files (.vhd) into the rtl_dar/proms directory
 - build zaxxon_deca
 - program zaxxon_deca.sof

You can build the project with ROM image embedded in the sof file.
*DO NOT REDISTRIBUTE THESE FILES*

See original [README.txt](README.txt)
------------------------

