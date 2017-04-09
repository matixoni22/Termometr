
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

 
ENTITY tb_Therm_driver IS
END tb_Therm_driver;
 
ARCHITECTURE behavior OF tb_Therm_driver IS 
 
 
    COMPONENT Thermo_driver
    PORT(
         One_wire : INOUT  std_logic;
         temp : OUT  std_logic_vector(15 downto 0);
         reset : IN  std_logic;
         clk : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal reset : std_logic := '0';
   signal clk : std_logic := '0';

	--BiDirs
   signal One_wire : std_logic;

 	--Outputs
   signal temp : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant clk_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Thermo_driver PORT MAP (
          One_wire => One_wire,
          temp => temp,
          reset => reset,
          clk => clk
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
	--reset<='1';
	--wait for clk_period;
	
	reset<='0';
	wait for clk_period*55;
	
	wait;
   --assert false severity failure;
   end process;

END;
