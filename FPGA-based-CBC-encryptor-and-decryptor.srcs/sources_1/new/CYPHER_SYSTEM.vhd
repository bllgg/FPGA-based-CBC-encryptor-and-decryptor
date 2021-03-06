----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/28/2020 04:44:18 PM
-- Design Name: 
-- Module Name: CYPHER_SYSTEM - Behavioral
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
-- This is the main module of the project.
-- Simply dual-port Block memory is responsible for store data received through UART receiver. The stored data can be send to the computer via UART transmitter.
-- Encrypter module and decrypter module are directly connected with the block RAM and they can be used via giving an enable signal from switches of the basys 3 board.
-- The results of the encryption and decryption will be stored in the block RAM and we can get those results in to the computer.


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CYPHER_SYSTEM is
    Port ( op_indic : out STD_LOGIC; --
           clock : in STD_LOGIC; --
           Encrypt : in STD_LOGIC; --
           Decrypt : in STD_LOGIC; --
           uart_rx_rst : in STD_LOGIC; --
           uart_tx_rst : in STD_LOGIC; --
           rx_serial : in STD_LOGIC; --
           tx_dv : in STD_LOGIC; --
           tx_serial : out STD_LOGIC; --
           tx_done : out STD_LOGIC; --
           key_in : in STD_LOGIC_VECTOR (7 downto 0)); --
end CYPHER_SYSTEM;

architecture Behavioral of CYPHER_SYSTEM is

-- The module which is responsible for handle encryption functionality.
component encrypt_handler is
    Port ( data_in : in STD_LOGIC_VECTOR (7 downto 0);
           data_out : out STD_LOGIC_VECTOR (7 downto 0);
           addr_to_read : out STD_LOGIC_VECTOR (7 downto 0);
           addr_to_write : out STD_LOGIC_VECTOR (7 downto 0);
           key : in STD_LOGIC_VECTOR (7 downto 0);
           read_enable : out STD_LOGIC;
           write_enable : out STD_LOGIC;
           enable : in STD_LOGIC;
           --reset : in STD_LOGIC;
           clock : in STD_LOGIC);
end component;

-- The moudule which is responsible for handle decryption functionality.
component decrypt_handler is
    Port ( data_in : in STD_LOGIC_VECTOR (7 downto 0);
           data_out : out STD_LOGIC_VECTOR (7 downto 0);
           addr_to_read : out STD_LOGIC_VECTOR (7 downto 0);
           addr_to_write : out STD_LOGIC_VECTOR (7 downto 0);
           key : in STD_LOGIC_VECTOR (7 downto 0);
           read_enable : out STD_LOGIC;
           write_enable : out STD_LOGIC;
           enable : in STD_LOGIC;
           --reset : in STD_LOGIC;
           clock : in STD_LOGIC);
end component;

-- Handle UART transmission.
component UART_RX_handeller is
    Port ( rx_serial : in STD_LOGIC;
           rx_enable : out STD_LOGIC;
           rx_byte : out STD_LOGIC_VECTOR (7 downto 0);
           addr_to_write : out STD_LOGIC_VECTOR (7 downto 0);           
           reset : in STD_LOGIC;
           clock : in STD_LOGIC);
end component;

-- Handle UART recieve
component UART_TX_handeller is
    Port ( TX_DV : in STD_LOGIC;
           TX_Byte : in STD_LOGIC_VECTOR (7 downto 0);
           TX_Active : out STD_LOGIC;
           TX_Serial : out STD_LOGIC;
           TX_Done : out STD_LOGIC;
           addr_to_read : out STD_LOGIC_VECTOR (7 downto 0);           
           reset : in STD_LOGIC;
           clock : in STD_LOGIC);
end component;

-- Multiplexers are used for controll data flow
component multi_4_to_1 is
    Port ( a_in : in STD_LOGIC_VECTOR (7 downto 0);
           b_in : in STD_LOGIC_VECTOR (7 downto 0);
           c_in : in STD_LOGIC_VECTOR (7 downto 0);
           d_in : in STD_LOGIC_VECTOR (7 downto 0);
           data_out : out STD_LOGIC_VECTOR (7 downto 0);
           selector : in STD_LOGIC_VECTOR (1 downto 0));
end component;

component multi_4_to_1_1bit is
    Port ( a_in : in STD_LOGIC;
           b_in : in STD_LOGIC;
           c_in : in STD_LOGIC;
           d_in : in STD_LOGIC;
           data_out : out STD_LOGIC;
           selector : in STD_LOGIC_VECTOR (1 downto 0));
end component;

-- Wrapper is used for control BRAM
component Dual_B_RAM_wrapper
    port (
      BRAM_PORTA_0_addr : in STD_LOGIC_VECTOR ( 7 downto 0 );
      BRAM_PORTA_0_clk : in STD_LOGIC;
      BRAM_PORTA_0_din : in STD_LOGIC_VECTOR ( 7 downto 0 );
      BRAM_PORTA_0_dout : out STD_LOGIC_VECTOR ( 7 downto 0 );
      BRAM_PORTA_0_en : in STD_LOGIC;
      BRAM_PORTA_0_we : in STD_LOGIC_VECTOR ( 0 to 0 );
      BRAM_PORTB_0_addr : in STD_LOGIC_VECTOR ( 7 downto 0 );
      BRAM_PORTB_0_clk : in STD_LOGIC;
      BRAM_PORTB_0_din : in STD_LOGIC_VECTOR ( 7 downto 0 );
      BRAM_PORTB_0_dout : out STD_LOGIC_VECTOR ( 7 downto 0 );
      BRAM_PORTB_0_en : in STD_LOGIC;
      BRAM_PORTB_0_we : in STD_LOGIC_VECTOR ( 0 to 0 )
    );
  end component;

component or_gate is
    Port ( a : in STD_LOGIC;
           b : in STD_LOGIC;
           F : out STD_LOGIC);
end component;

-- Byte coounter is used for select address to read and send via UART
component uatr_tx_byte_counter is
    Port ( clock : in STD_LOGIC;
           enable : in STD_LOGIC;
           tx_done : in STD_LOGIC;
           enable_signal : out STD_LOGIC);
end component;

-- TX controller is responsible for controll UART transmission
component UART_TX_CTRL is
    Port ( SEND : in  STD_LOGIC;
           DATA : in  STD_LOGIC_VECTOR (7 downto 0);
           CLK : in  STD_LOGIC;
           READY : out  STD_LOGIC;
           UART_TX : out  STD_LOGIC);
end component;

component down_counter_uart is
    Port ( enable : in STD_LOGIC;
           reset : in STD_LOGIC;
           clock : in STD_LOGIC;
           counter_out : out STD_LOGIC_VECTOR (7 downto 0));
end component;

-------------------------------------------------------------------------
signal common_clock : STD_LOGIC;

signal port_a_addr : STD_LOGIC_VECTOR (7 downto 0);
signal port_a_data_in : STD_LOGIC_VECTOR (7 downto 0);
signal port_a_data_out : STD_LOGIC_VECTOR (7 downto 0);
signal port_a_read_enable : STD_LOGIC;
signal port_a_write_enable : STD_LOGIC_VECTOR (0 downto 0);

signal port_b_addr : STD_LOGIC_VECTOR (7 downto 0);
signal port_b_data_in : STD_LOGIC_VECTOR (7 downto 0);
signal port_b_data_out : STD_LOGIC_VECTOR (7 downto 0);
signal port_b_read_enable : STD_LOGIC;
signal port_b_write_enable : STD_LOGIC_VECTOR (0 downto 0);

signal mode_selector : STD_LOGIC_VECTOR (1 downto 0);

signal enc_data_in : STD_LOGIC_VECTOR (7 downto 0);
signal enc_data_out : STD_LOGIC_VECTOR (7 downto 0);
signal enc_address_to_read : STD_LOGIC_VECTOR (7 downto 0);
signal enc_address_to_write : STD_LOGIC_VECTOR (7 downto 0);
signal enc_read_enable : STD_LOGIC;
signal enc_write_enable : STD_LOGIC;

signal dec_data_in : STD_LOGIC_VECTOR (7 downto 0);
signal dec_data_out : STD_LOGIC_VECTOR (7 downto 0);
signal dec_address_to_read : STD_LOGIC_VECTOR (7 downto 0);
signal dec_address_to_write : STD_LOGIC_VECTOR (7 downto 0);
signal dec_read_enable : STD_LOGIC;
signal dec_write_enable : STD_LOGIC;

signal uart_rx_enable : STD_LOGIC;
signal uart_rx_byte : STD_LOGIC_VECTOR (7 downto 0);
signal uart_rx_addr : STD_LOGIC_VECTOR (7 downto 0);

signal uart_tx_enable : STD_LOGIC;
signal uart_tx_done : STD_LOGIC := '0';
signal uart_tx_dv : STD_LOGIC := '0';
signal uart_tx_byte : STD_LOGIC_VECTOR (7 downto 0);
signal uart_tx_addr : STD_LOGIC_VECTOR (7 downto 0);

signal uart_counter_enable : STD_LOGIC := '0';

begin

dual_RAM: Dual_B_RAM_wrapper port map ( BRAM_PORTA_0_addr => port_a_addr,
                                        BRAM_PORTA_0_clk  => common_clock,
                                        BRAM_PORTA_0_din  => port_a_data_in,
                                        BRAM_PORTA_0_dout => port_a_data_out,
                                        BRAM_PORTA_0_en   => '1',
                                        BRAM_PORTA_0_we   => port_a_write_enable,
                                        BRAM_PORTB_0_addr => port_b_addr,
                                        BRAM_PORTB_0_clk  => common_clock,
                                        BRAM_PORTB_0_din  => port_b_data_in,
                                        BRAM_PORTB_0_dout => port_b_data_out,
                                        BRAM_PORTB_0_en   => '1',
                                        BRAM_PORTB_0_we   => port_b_write_enable );

uart_rx_module: UART_RX_handeller
    port map ( rx_serial => rx_serial,
               rx_enable => uart_rx_enable,
               rx_byte => port_a_data_in,
               addr_to_write => uart_rx_addr,
               reset => uart_rx_rst,
               clock => common_clock);

--uart_tx_module: UART_TX_handeller
--    port map ( TX_DV => uart_tx_dv,
--               TX_Byte => port_b_data_out,
--               TX_Active => port_b_read_enable,
--               TX_Serial => tx_serial,
--               TX_Done => uart_tx_done,
--               addr_to_read => uart_tx_addr,       
--               reset => uart_tx_rst,
--               clock => common_clock);

--uart_counter: uatr_tx_byte_counter
--    port map ( clock => common_clock,
--               enable => uart_counter_enable,
--               tx_done => uart_tx_done,
--               enable_signal => uart_tx_dv);

uart_dwn_counter: down_counter_uart
    port map ( enable => tx_dv,
               reset => uart_tx_rst,
               clock => common_clock,
               counter_out => uart_tx_addr);

uart_transmitter: UART_TX_CTRL
    port map ( SEND => tx_dv,
               DATA => port_b_data_out,
               CLK => common_clock,
               READY => uart_tx_done,
               UART_TX => tx_serial);
                             
encrypt_hndlr : encrypt_handler
    port map ( data_in => port_a_data_out,
               data_out => enc_data_out,
               addr_to_read => enc_address_to_read,
               addr_to_write => enc_address_to_write,
               key => key_in,
               read_enable => enc_read_enable,
               write_enable => enc_write_enable,
               enable => Encrypt,
               clock => common_clock);

decrypt_hndlr : decrypt_handler
    port map ( data_in => port_a_data_out,
               data_out => dec_data_out,
               addr_to_read => dec_address_to_read,
               addr_to_write => dec_address_to_write,
               key => key_in,
               read_enable => dec_read_enable,
               write_enable => dec_write_enable,
               enable => Decrypt,
               clock => common_clock);
           
multi_rx_port_A_addr : multi_4_to_1
    port map ( a_in => enc_address_to_read,
               b_in => dec_address_to_read,
               c_in => uart_rx_addr,
               d_in => "00000000",
               data_out => port_a_addr,
               selector => mode_selector);

multi_tx_port_B_addr : multi_4_to_1
    port map ( a_in => enc_address_to_write,
               b_in => dec_address_to_write,
               c_in => uart_tx_addr,
               d_in => "00000000",
               data_out => port_b_addr,
               selector => mode_selector);

multi_rx_1_bit_port_A_read_en : multi_4_to_1_1bit
    port map ( a_in => enc_read_enable,
               b_in => dec_read_enable,
               c_in => '0',
               d_in => '0',
               data_out => port_a_read_enable,
               selector => mode_selector);

multi_rx_1_bit_port_B_write_en : multi_4_to_1
    port map ( a_in => enc_data_out,
               b_in => dec_data_out,
               c_in => "00000000",
               d_in => "00000000",
               data_out => port_b_data_in,
               selector => mode_selector);

--multi_tx_1_bit : multi_4_to_1_1bit
--    port map ( a_in => enc_write_enable,
--               b_in => dec_write_enable,
--               c_in => uart_tx_enable,
--               d_in => '0',
--               data_out => port_a_read_enable,
--               selector => mode_selector);

we_or:  or_gate
    port map ( a => enc_write_enable,
               b => dec_write_enable,
               F => port_b_write_enable(0));

uart_counter_enable <= '1';
tx_done <= uart_tx_done;
common_clock <= clock;
port_a_write_enable(0) <= uart_rx_enable;
mode_selector(0) <= Encrypt;
mode_selector(1) <= Decrypt;
op_indic <= port_a_read_enable;

end Behavioral;
