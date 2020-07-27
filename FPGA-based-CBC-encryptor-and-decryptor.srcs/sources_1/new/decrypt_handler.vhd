----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/27/2020 12:55:40 AM
-- Design Name: 
-- Module Name: decrypt_handler - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity decrypt_handler is
    Port ( data_in : in STD_LOGIC_VECTOR (7 downto 0);
           data_out : out STD_LOGIC_VECTOR (7 downto 0);
           addr_to_read : out STD_LOGIC_VECTOR (7 downto 0);
           addr_to_write : out STD_LOGIC_VECTOR (7 downto 0);
           key : in STD_LOGIC_VECTOR (7 downto 0);
           read_enable : out STD_LOGIC;
           write_enable : out STD_LOGIC;
           enable : in STD_LOGIC;
           reset : in STD_LOGIC;
           clock : in STD_LOGIC);
end decrypt_handler;

architecture Behavioral of decrypt_handler is

component decryptor is
    Port ( key_in : in STD_LOGIC_VECTOR (7 downto 0);
           d_in : in STD_LOGIC_VECTOR (7 downto 0);
           d_out : out STD_LOGIC_VECTOR (7 downto 0);
           clock : in STD_LOGIC;
           reset : in STD_LOGIC;
           selector : in STD_LOGIC);
end component;

component up_counter is
    Port ( clock : in STD_LOGIC;
           reset : in STD_LOGIC;
           counter_out : out STD_LOGIC_VECTOR (7 downto 0));
end component;

component down_counter is
    Port ( clock : in STD_LOGIC;
           reset : in STD_LOGIC;
           counter_out : out STD_LOGIC_VECTOR (7 downto 0));
end component;

component register_8bit
    Port ( data_in : in STD_LOGIC_VECTOR (7 downto 0);
           data_out : out STD_LOGIC_VECTOR (7 downto 0);
           clk, reset : in STD_LOGIC);
end component;

component d_flipflop is
    Port ( data_in : in STD_LOGIC;
           data_out : out STD_LOGIC;
           clk : in STD_LOGIC;
           reset : in STD_LOGIC);
end component;

component or_gate is
    Port ( a : in STD_LOGIC;
           b : in STD_LOGIC;
           F : out STD_LOGIC);
end component;

signal wen : std_logic;
signal ff_a_b: std_logic;
signal down_counter_to_reg : STD_LOGIC_VECTOR (7 downto 0);

begin
decrypt_module : decryptor
    port map (key_in => key,
              d_in => data_in,
              d_out => data_out,
              clock => clock,
              reset => reset,
              selector => wen);

up_count : up_counter
    port map (clock => clock,
              reset => reset,
              counter_out => addr_to_read);

down_count : down_counter
    port map (clock => clock,
              reset => reset,
              counter_out => down_counter_to_reg);

reg_a : register_8bit
    Port map ( data_in => down_counter_to_reg,
               data_out => addr_to_write,
               clk  => clock,
               reset => reset);
              
dff_a : d_flipflop
    port map (data_in => enable,
              data_out => ff_a_b,
              clk => clock,
              reset => reset);

dff_b : d_flipflop
    port map (data_in => ff_a_b,
              data_out => wen,
              clk => clock,
              reset => reset);


read_enable <= enable;
write_enable <= ff_a_b;
end Behavioral;