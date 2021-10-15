---------------------------------------------------------------------------------
-- DECA Top level for Zaxxon by Somhic (03/07/21) adapted 
-- from DE10_lite port by Dar (https://sourceforge.net/projects/darfpga/files/Software%20VHDL/zaxxon/)
-- v1 initial revision
-- v2 added video_vs & video_hs in zaxxon.vhd
-- v3 hdmi working. Added video_clk output in zaxxon.vhd
-- v3.1 revised qsf. added joystick. added RGB/VGA.  VGA & RGB output now working
--
-- THIS VERSION STILL MISSING AUDIO
--
---------------------------------------------------------------------------------
-- DE10_lite Top level for Zaxxon by Dar (darfpga@aol.fr) (23/11/2019)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------
-- Educational use only
-- Do not redistribute synthetized file with roms
-- Do not redistribute roms whatever the form
-- Use at your own risk
---------------------------------------------------------------------------------
-- Use zaxxon_de10_lite.sdc to compile (Timequest constraints)
-- /!\
-- Don't forget to set device configuration mode with memory initialization 
--  (Assignments/Device/Pin options/Configuration mode)
---------------------------------------------------------------------------------
--
-- release rev 00 : initial release
--  (23/11/2019)
---------------------------------------------------------------------------------
--
-- Main features :
--  PS2 keyboard input
--  
--
--  Video         : TV 15kHz
--  Cocktail mode : Yes
--  Sound         : No (atm)
-- 
-- For hardware schematic see my other project : NES
--
-- Uses 1 pll 24MHz from 50MHz
--
-- Board key :
--   0 : reset game
--
-- Keyboard players inputs :
--
--   F1 : Add coin
--   F2 : Start 1 player
--   F3 : Start 2 players

--   SPACE       : fire
--   RIGHT arrow : move right
--   LEFT  arrow : move left
--   UP    arrow : move up
--   DOWN  arrow : move down
--
--   F4 : flip screen (additional feature)
--   F5 : Service mode ?! (not tested)
--   F7 : uprigth/cocktail mode (required reset)

--
-- Other details : see zaxxon.vhd
-- For USB inputs and SGT5000 audio output see my other project: xevious_de10_lite
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;

entity zaxxon_deca is
port(
 max10_clk1_50  : in std_logic;
 --ledr           : out std_logic_vector(9 downto 0);
 key            : in std_logic_vector(1 downto 0);

 vga_r     : out std_logic_vector(3 downto 0);
 vga_g     : out std_logic_vector(3 downto 0);
 vga_b     : out std_logic_vector(3 downto 0);
 vga_hs    : out std_logic;
 vga_vs    : out std_logic;
 
 ps2clk   : in std_logic;
 ps2dat   : in std_logic;

--  audio_pwm_l  : out std_logic;
--  audio_pwm_r  : out std_logic;

  -- JOYSTICK
  JOY1_B2_P9		: IN    STD_LOGIC;
  JOY1_B1_P6		: IN    STD_LOGIC;
  JOY1_UP		    : IN    STD_LOGIC;
  JOY1_DOWN		  : IN    STD_LOGIC;
  JOY1_LEFT	  	: IN    STD_LOGIC;
  JOY1_RIGHT		: IN    STD_LOGIC;
  JOYX_SEL_O		: OUT   STD_LOGIC := '1';

-- HDMI-TX  DECA 
	HDMI_I2C_SCL  : inout std_logic; 		          		
	HDMI_I2C_SDA  : inout std_logic; 		          		
	HDMI_I2S      : inout std_logic_vector(3 downto 0);		     	
	HDMI_LRCLK    : inout std_logic; 		          		
	HDMI_MCLK     : inout std_logic;		          		
	HDMI_SCLK     : inout std_logic; 		          		
	HDMI_TX_CLK   : out	std_logic;	          		
	HDMI_TX_D     : out	std_logic_vector(23 downto 0);	    		
	HDMI_TX_DE    : out std_logic;		          		 
	HDMI_TX_HS    : out	std_logic;	          		
	HDMI_TX_INT   : in  std_logic;		          		
	HDMI_TX_VS    : out std_logic         

);
end zaxxon_deca;


architecture struct of zaxxon_deca is

 signal clock_24  : std_logic;
 signal clock_kbd : std_logic;
 signal reset     : std_logic;
 
 signal clock_div : std_logic_vector(3 downto 0);
  
 signal r         : std_logic_vector(2 downto 0);
 signal g         : std_logic_vector(2 downto 0);
 signal b         : std_logic_vector(1 downto 0);
 signal hsync     : std_logic;
 signal vsync     : std_logic;
 signal csync     : std_logic;
 signal blankn    : std_logic;
 signal tv15Khz_mode : std_logic := '0';

 signal audio_l           : std_logic_vector(15 downto 0);
 signal audio_r           : std_logic_vector(15 downto 0);
--  signal pwm_accumulator_l : std_logic_vector(17 downto 0);
--  signal pwm_accumulator_r : std_logic_vector(17 downto 0);

 alias reset_n         : std_logic is key(0);
 alias ps2_clk         : std_logic is ps2clk; 
 alias ps2_dat         : std_logic is ps2dat; 
--  alias pwm_audio_out_l : std_logic is audio_pwm_l;  
--  alias pwm_audio_out_r : std_logic is audio_pwm_r;  
 
 signal kbd_intr       : std_logic;
 signal kbd_scancode   : std_logic_vector(7 downto 0);
 signal joy_BBBBFRLDU  : std_logic_vector(8 downto 0);
 signal fn_pulse       : std_logic_vector(7 downto 0);
 signal fn_toggle      : std_logic_vector(7 downto 0);

signal dbg_cpu_addr : std_logic_vector(15 downto 0);


-- video signals   -- mod by somhic
-- signal clock_vga       : std_logic;   
-- signal clock_vga2       : std_logic;   
 signal video_clk       : std_logic; 
 signal video_pix       : std_logic; 
 signal vga_g_i         : std_logic_vector(5 downto 0);   
 signal vga_r_i         : std_logic_vector(5 downto 0);   
 signal vga_b_i         : std_logic_vector(5 downto 0);   
 signal vga_r_o         : std_logic_vector(5 downto 0);   
 signal vga_g_o         : std_logic_vector(5 downto 0);   
 signal vga_b_o         : std_logic_vector(5 downto 0);   
 signal vga_hs_o        : std_logic;
 signal vga_vs_o        : std_logic;

 signal vga_r_c         : std_logic_vector(3 downto 0);
 signal vga_g_c         : std_logic_vector(3 downto 0);
 signal vga_b_c         : std_logic_vector(3 downto 0);
 signal vga_hs_c        : std_logic;
 signal vga_vs_c        : std_logic;

--  signal ce_x1       : std_logic; 
--  signal i_div       : std_logic_vector(1 downto 0);   
--  signal last_hs_in  : std_logic; 

 signal left_i          : std_logic; 
 signal right_i         : std_logic; 
 signal up_i            : std_logic;
 signal down_i          : std_logic;
 signal fire_i          : std_logic;
 

component scandoubler        -- mod by somhic
    port (
    clk_sys : in std_logic;
    scanlines : in std_logic_vector (1 downto 0);
    ce_x1 : in std_logic;
    ce_x2 : in std_logic;
    hs_in : in std_logic;
    vs_in : in std_logic;
    r_in : in std_logic_vector (5 downto 0);
    g_in : in std_logic_vector (5 downto 0);
    b_in : in std_logic_vector (5 downto 0);
    hs_out : out std_logic;
    vs_out : out std_logic;
    r_out : out std_logic_vector (5 downto 0);
    g_out : out std_logic_vector (5 downto 0);
    b_out : out std_logic_vector (5 downto 0)
  );
end component;


component I2C_HDMI_Config       -- mod by somhic
    port (
    iCLK : in std_logic;
    iRST_N : in std_logic;
    I2C_SCLK : out std_logic;
    I2C_SDAT : inout std_logic;
    HDMI_TX_INT : in std_logic
  );
end component;

begin

reset <= not reset_n;

-- Clock 24MHz for Zaxxon core and sound_board
clocks : entity work.max10_pll_24M
port map(
 inclk0 => max10_clk1_50,
 c0 => clock_24,
 locked => open --pll_locked
);

-- Zaxxon
zaxxon : entity work.zaxxon
port map(
 clock_24   => clock_24,
 reset      => reset,
 
 -- tv15Khz_mode => tv15Khz_mode,
 video_r      => r,
 video_g      => g,
 video_b      => b,
 video_csync  => csync,
 video_blankn => blankn,
 video_hs     => hsync,
 video_vs     => vsync,

 video_clk    => video_clk,    -- mod by somhic
 video_pix    => video_pix,    -- mod by somhic

 audio_out_l    => audio_l,
 audio_out_r    => audio_r,
   
 coin1          => fn_pulse(0), -- F1
 coin2          => '0',
 start1         => fn_pulse(1), -- F2
 start2         => fn_pulse(2), -- F3
 
 left           => not left_i,  -- left
 right          => not right_i, -- right
 up             => not up_i,    -- up
 down           => not down_i,  -- down
 fire           => not fire_i,  -- space
 
 left_c         => joy_BBBBFRLDU(2), -- left
 right_c        => joy_BBBBFRLDU(3), -- right
 up_c           => joy_BBBBFRLDU(0), -- up
 down_c         => joy_BBBBFRLDU(1), -- down
 fire_c         => joy_BBBBFRLDU(4), -- space
 
 cocktail       => fn_toggle(6), -- F7 
 service        => fn_toggle(4), -- F5
 flip_screen    => fn_toggle(3), -- F4
  
 dbg_cpu_addr => dbg_cpu_addr
);

-- VGA 
-- adapt video to 6bits/color only and blank
vga_r_i <= r & r     when blankn = '1' else "000000";
vga_g_i <= g & g     when blankn = '1' else "000000";
vga_b_i <= b & b & b when blankn = '1' else "000000";

-- process (clock_24)
-- begin
-- 		if rising_edge(clock_24) then
--       last_hs_in <= hsync;
-- 			if (last_hs_in = '1' and HSync = '0') then
-- 		    i_div <= "00";
-- 			else
--         i_div <= i_div + '1';
-- 			end if;
-- 		end if;
-- end process;
-- ce_x1 <= i_div(0);    --12 MHz

--clk_sys=clock_24, ce_x1=ce_x1, ce_x2=1   out of range
--clk_sys=clock_24, ce_x1=ce_x1, ce_x2=0   nothing at all
--clk_sys=video_clk(12mhz), ce_x1=video_pix(6mhz), ce_x2=1  good
scandoubler_inst :  scandoubler
  port map (
    clk_sys => video_clk,   
    scanlines => "00",       --(00-none 01-25% 10-50% 11-75%)
    ce_x1 => video_pix,     
    ce_x2 => '1',
    hs_in => hsync,
    vs_in => vsync,
    r_in => vga_r_i,
    g_in => vga_g_i,
    b_in => vga_b_i,
    hs_out => vga_hs_o,
    vs_out => vga_vs_o,
    r_out => vga_r_o,
    g_out => vga_g_o,
    b_out => vga_b_o
  );


-- RGB
-- adapt video to 4bits/color only and blank
vga_r_c <= r & r(2)     when blankn = '1' else "0000";
vga_g_c <= g & g(2)     when blankn = '1' else "0000";
vga_b_c <= b & b        when blankn = '1' else "0000";
-- synchro composite/ synchro horizontale
vga_hs_c <= csync;
-- vga_hs <= csync when tv15Khz_mode = '1' else hsync;
-- commutation rapide / synchro verticale
vga_vs_c <= '1';
-- vga_vs <= '1'   when tv15Khz_mode = '1' else vsync;


--VIDEO OUTPUT VGA/RGB
tv15Khz_mode <= fn_toggle(7);          -- F8 key
process (clock_24)
begin
		if rising_edge(clock_24) then
			if tv15Khz_mode = '1' then
        --RGB
        vga_r  <= vga_r_c;
        vga_g  <= vga_g_c;
        vga_b  <= vga_b_c;
        vga_hs <= vga_hs_c;
        vga_vs <= vga_vs_c; 
			else
        --VGA
        -- adapt video to 4 bits/color only
        vga_r  <= vga_r_o (5 downto 2);
        vga_g  <= vga_g_o (5 downto 2);
        vga_b  <= vga_b_o (5 downto 2);
        vga_hs <= vga_hs_o;       
        vga_vs <= vga_vs_o; 	    	
			end if;
		end if;
end process;


-- Clock MHz for video          -- mod by somhic
-- clocks2 : entity work.pll    
-- port map(
--  inclk0 => max10_clk1_50,
--  c0 => clock_vga,            
--  c1 => clock_vga2,            
--  locked => open --pll_locked
-- );

-- HDMI CONFIG    -- mod by somhic
I2C_HDMI_Config_inst : I2C_HDMI_Config
  port map (
    iCLK     => max10_clk1_50,
    iRST_N   => reset_n,
    I2C_SCLK => HDMI_I2C_SCL,
    I2C_SDAT => HDMI_I2C_SDA,
    HDMI_TX_INT => HDMI_TX_INT
  );

--  HDMI VIDEO   -- mod by somhic
HDMI_TX_CLK <= video_clk;    --clock_24  1024x223   12mhz 512x224@60
HDMI_TX_DE  <= blankn;
HDMI_TX_HS  <= hsync;
HDMI_TX_VS  <= vsync;
HDMI_TX_D   <= vga_r_i&vga_r_i(5 downto 4)&vga_g_i&vga_g_i(5 downto 4)&vga_b_i&vga_b_i(5 downto 4);


-- get scancode from keyboard
process (reset, clock_24)
begin
	if reset='1' then
		clock_div <= (others => '0');
		clock_kbd  <= '0';
	else 
		if rising_edge(clock_24) then
			if clock_div = "0010" then
				clock_div <= (others => '0');
				clock_kbd  <= not clock_kbd;
			else
				clock_div <= clock_div + '1';			
			end if;
		end if;
	end if;
end process;

keyboard : entity work.io_ps2_keyboard
port map (
  clk       => clock_kbd, -- synchrounous clock with core
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);

-- translate scancode to joystick
joystick : entity work.kbd_joystick
port map (
  clk           => clock_kbd, -- synchrounous clock with core
  kbdint        => kbd_intr,
  kbdscancode   => std_logic_vector(kbd_scancode), 
  joy_BBBBFRLDU => joy_BBBBFRLDU,
  fn_pulse      => fn_pulse,
  fn_toggle     => fn_toggle
);

--Sega megadrive gamepad
JOYX_SEL_O <= '1';  --not needed. core uses 1 button only

left_i   <= not joy_BBBBFRLDU(2) and JOY1_LEFT;  -- left
right_i  <= not joy_BBBBFRLDU(3) and JOY1_RIGHT; -- right
up_i     <= not joy_BBBBFRLDU(0) and JOY1_UP;    -- up
down_i   <= not joy_BBBBFRLDU(1) and JOY1_DOWN;  -- down
fire_i   <= not joy_BBBBFRLDU(4) and JOY1_B1_P6; -- space


--ledr(8 downto 0) <= joyBCPPFRLDU;

-- pwm sound output
-- process(clock_24)  -- use same clock as core_sound_board
-- begin
--   if rising_edge(clock_24) then
  
-- 		if clock_div = "0000" then 
-- 			pwm_accumulator_l  <=  ('0'&pwm_accumulator_l(16 downto 0)) + ('0'&audio_l&'0');
-- 			pwm_accumulator_r  <=  ('0'&pwm_accumulator_r(16 downto 0)) + ('0'&audio_r&'0');
-- 		end if;
		
--   end if;
-- end process;

-- pwm_audio_out_l <= pwm_accumulator_l(17);
-- pwm_audio_out_r <= pwm_accumulator_r(17); 


end struct;
