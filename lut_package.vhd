
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library paco_lut;

package lut_package is

  function cdiv(x:positive; y:positive) return natural;
  
  constant C_WORD_SIZE : integer := 32;
  constant C_CFG_WORD_SIZE : integer := C_WORD_SIZE;
  constant C_SELECTOR_BITS : integer := 8;
  constant C_INTERPOLATION_BITS : integer := 8;
  constant C_SEGMENT_BITS : integer := 4;
  constant C_BASE_BITS : integer := 48;
  constant C_INCLINE_BITS : integer := 32;
  constant C_LUT_BRAM_WIDTH : integer := C_BASE_BITS+C_INCLINE_BITS;
  constant C_RAM_CONFIG_BUFFER_SIZE : integer 
    := cdiv(C_LUT_BRAM_WIDTH,C_CFG_WORD_SIZE);
  constant C_RAM_CONFIG_BUFFER_SIZE_BITS : integer := 
    C_RAM_CONFIG_BUFFER_SIZE*C_CFG_WORD_SIZE;
  constant C_CFG_LUT_REGISTER_COUNT : integer
    := C_RAM_CONFIG_BUFFER_SIZE*(2**C_SEGMENT_BITS);
  constant C_CFG_CHAIN_REGISTER_COUNT : integer := 1; -- input shamt
  constant C_CFG_REGISTER_COUNT : integer := 
    C_CFG_LUT_REGISTER_COUNT+C_CFG_CHAIN_REGISTER_COUNT;
  constant C_INTERPOLATOR_DELAY : integer := 4;

  type p_input_t is record
    valid : std_logic;
    data : std_logic_vector(C_WORD_SIZE-1 downto 0);
  end record;
  type p_pla_t is record
    valid : std_logic;
    selector : std_logic_vector(C_SELECTOR_BITS-1 downto 0);
    interpolator : std_logic_vector(C_INTERPOLATION_BITS-1 downto 0);
  end record;
  type p_lut_t is record
    valid : std_logic;
    selector : std_logic_vector(C_SELECTOR_BITS-1 downto 0);
    interpolator : std_logic_vector(C_INTERPOLATION_BITS-1 downto 0);
    address : std_logic_vector(C_SEGMENT_BITS-1 downto 0);
  end record;

  type p_interpolator_t is record
    valid : std_logic;
    selector : std_logic_vector(C_SELECTOR_BITS-1 downto 0);
    interpolator : std_logic_vector(C_INTERPOLATION_BITS-1 downto 0);
    base : std_logic_vector(C_BASE_BITS-1 downto 0);
    incline : std_logic_vector(C_INCLINE_BITS-1 downto 0);
  end record;

  type p_output_t is record
    valid : std_logic;
    data : std_logic_vector(C_WORD_SIZE-1 downto 0);
  end record;

  type cfg_word_t is record
    d : std_logic_vector(C_CFG_WORD_SIZE-1 downto 0);
    valid : std_logic;
  end record;
    
  component single_port_ram
    generic (
      DATA_WIDTH : integer := 32;
      ADDR_WIDTH  : integer := 8
    );
    port(
      clk : in std_logic; 
      port1_addr   : in  std_logic_vector(0 to ADDR_WIDTH-1); 
      port1_data_w : in  std_logic_vector(0 to DATA_WIDTH-1); 
      port1_data_r : out std_logic_vector(0 to DATA_WIDTH-1); 
      port1_we     : in  std_logic
    );
  end component;

  component lut_controller
    port (
      clk : in std_logic;
      id_rst_i : in std_logic;
      id_stat_i : in std_logic;
      id_exe_i : in std_logic;
      id_cfg_i : in std_logic;
      data_i : in std_logic_vector(C_WORD_SIZE-1 downto 0);

      status_o : out std_logic_vector(C_WORD_SIZE-1 downto 0);
      error_o : out std_logic;
      
      cfg_mode_o : out std_logic;
      cfg_o : out cfg_word_t;

      lut_addr_o : out std_logic_vector(C_SEGMENT_BITS-1 downto 0);
      lut_data_o : out std_logic_vector(C_LUT_BRAM_WIDTH-1 downto 0);
      lut_we_o   : out std_logic;

      pipeline_o : out p_input_t

    );
  end component;


  component input_processor
    port (
      clk : in std_logic;
      rst : in std_logic;
      
      cfg_i : in  cfg_word_t;
      cfg_o : out cfg_word_t;

      pipeline_i : in p_input_t;
      pipeline_o : out p_pla_t

    );
  end component;

  component address_translator
    port (
      clk : in std_logic;
      rst : in std_logic;
      
      cfg_i : in  cfg_word_t;
      cfg_o : out cfg_word_t;

      pipeline_i : in p_pla_t;
      pipeline_o : out p_lut_t

    );
  end component;

  component bram_controller
    port (
      clk : in std_logic;
      rst : in std_logic;
      
      cfg_i : in  cfg_word_t;
      cfg_o : out cfg_word_t;

      cfg_mode_i : in std_logic;
      ram_addr_i : in std_logic_vector(C_SEGMENT_BITS-1 downto 0);
      ram_data_i : in std_logic_vector(C_LUT_BRAM_WIDTH-1 downto 0);
      ram_we_i   : in std_logic;

      pipeline_i : in p_lut_t;
      pipeline_o : out p_interpolator_t

    );
  end component;

  component interpolator
    port (
      clk : in std_logic;
      rst : in std_logic;
      
      cfg_i : in  cfg_word_t;
      cfg_o : out cfg_word_t;

      pipeline_i : in p_interpolator_t;
      pipeline_o : out p_output_t

    );
  end component;

end package;

package body lut_package is

  function cdiv(x:positive; y:positive) return natural is
    variable d: natural;
  begin
    d:=x/y;
    if (d*y)<x then 
      d := d+1;
    end if;
    return d;
  end function;

end package body;
