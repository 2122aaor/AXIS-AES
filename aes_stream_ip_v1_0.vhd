library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity aes_stream_ip_v1_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- AXI4Stream sink: Data Width
        C_AXIS_TDATA_WIDTH : integer := 128  
	);
	port (
        
        --slave signals (data coming into the IP)
        s00_axis_aclk : in std_logic;  
        s00_axis_aresetn : in std_logic;
        s00_axis_tdata : in std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
        s00_axis_tstrb : in std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0); --unused in this implementation
        s00_axis_tvalid : in std_logic;  
        s00_axis_tready : out std_logic;
        s00_axis_tlast : in std_logic;
        
        --master signals (data coming out of the IP)
        m00_axis_aclk : in std_logic;  
        m00_axis_aresetn : in std_logic;
        m00_axis_tdata : out std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
        m00_axis_tstrb : out std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0); --unused in this implementation
        m00_axis_tvalid : out std_logic;  
        m00_axis_tready : in std_logic;
        m00_axis_tlast : out std_logic
        
        
	);
end aes_stream_ip_v1_0;

architecture arch_imp of aes_stream_ip_v1_0 is

--component declaration
component aesTop is
    
    port (
        clk : in std_logic;
        rst : in std_logic;
        
        --main data inputs for single round hardware
        inputBlock : in std_logic_vector(127 downto 0);
        inputKey : in std_logic_vector(127 downto 0);
        
        --main data outputs for single round hardware
        outputBlock : out std_logic_vector(127 downto 0);
        
        --valid and last signals
        valid_in : in std_logic;
        last_in : in std_logic;
        valid_out : out std_logic;
        last_out : out std_logic;
        
        stall : in std_logic
    );
end component;
	  


--standard signals
signal clk : std_logic;
signal rst : std_logic; 

--used for determining the first block as being the key
signal key : std_logic;
	
--slave signals
signal s_tdata : std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
signal s_tvalid : std_logic;  
signal s_tready : std_logic;
signal s_tlast : std_logic; 

--master signals
signal m_tdata : std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
signal m_tvalid : std_logic;  
signal m_tready : std_logic;
signal m_tlast : std_logic;

--additional signals

signal inputBlock : std_logic_vector(127 downto 0);
signal inputBlock_sig : std_logic_vector(127 downto 0);
signal inputKey : std_logic_vector(127 downto 0);
signal inputKey_sig : std_logic_vector(127 downto 0);
signal outputBlock : std_logic_vector(127 downto 0);
signal outputBlock_sig : std_logic_vector(127 downto 0);
signal valid_in : std_logic;
signal last_in : std_logic;
signal valid_out : std_logic;
signal last_out : std_logic;   

-- --states for the slave FSM (takes data in)
-- constant S_idle : std_logic_vector(2 downto 0) := "000"; 
-- constant S_read : std_logic_vector(2 downto 0) := "001"; 
-- constant S_stall : std_logic_vector(2 downto 0) := "010"; 
-- --slave state
-- signal S_present : std_logic_vector(2 downto 0);


-- --states for the master FSM (sends data out)
-- constant M_idle : std_logic_vector(2 downto 0) := "000";
-- constant M_write : std_logic_vector(2 downto 0) := "001"; 
-- constant M_stall : std_logic_vector(2 downto 0) := "010";
-- --master state
-- signal M_present : std_logic_vector(2 downto 0);

type STATE_TYPE is (Idle, Read_Inputs, Stall, Idle2, Write_Outputs);

signal state  : STATE_TYPE;
signal state2 : STATE_TYPE;
-- TLAST signal
   signal tlast : std_logic;
   
signal timer : integer;

signal last_sig : std_logic;

signal stall_sig : std_logic;
    
begin
--encrypter instantiation
encrypt : aesTop
    port map(
        clk => s00_axis_aclk,
        rst => s00_axis_aresetn,
        inputBlock => inputBlock,
        inputKey => inputKey,
        outputBlock => outputBlock,
        valid_in => valid_in,
        last_in => last_in,
        valid_out => valid_out,
        last_out => last_out,
        stall => stall_sig
    );
--standard assignments
clk <= s00_axis_aclk;
rst <= s00_axis_aresetn;
--axis slave assignments
s_tdata <= s00_axis_tdata;
s_tvalid <= s00_axis_tvalid;
s00_axis_tready <= s_tready;
s_tlast <= s00_axis_tlast;
--axis master assignments
m00_axis_tdata <= m_tdata;
m00_axis_tvalid <= m_tvalid;
m_tready <= m00_axis_tready;
m00_axis_tlast <= m_tlast;

s_tready  <= '1' when state = Read_Inputs else '0';
m_tvalid <= '1' when state2 = Write_Outputs else '0';



m_tdata <= outputBlock_sig;
--m_tlast <= last_sig;
--m_tlast <= last_out;


--read side FSM (slave)
The_SW_accelerator : process (clk) is
   begin  -- process The_SW_accelerator
    if rising_edge(clk) then     -- Rising clock edge
      if rst = '0' then               -- Synchronous reset (active low)
        
        state        <= Idle;
        --tlast        <= '0';
        key <= '1';
        --timer <= 0;
        --last_sig <= '0';
        valid_in <= '0';
        last_in <= '0';
      else
        --timer <= timer + 1;
      
        case state is
          when Idle =>
            --timer <= 0;
            valid_in <= '0';
            last_in <= '0';
            if (s_tvalid = '1' AND stall_sig = '0') then
              state       <= Read_Inputs;            
            else
                state <= Idle;
            end if;

          when Read_Inputs =>
            --timer <= 0;
            if (s_tvalid = '1' and s_tready = '1') then
              
                if key = '1' then
                    inputKey_sig <= s_tdata;                
                    state <= Idle;
                else
                    inputBlock_sig <= s_tdata;
                    valid_in <= '1';
                    last_in <= s_tlast;
                    state <= Idle;
                end if;
                --last_sig <= s_tlast;
                
                
                if (s_tlast = '1') then
                
                    key <= '1';
                  else
                    key <= '0';
                  end if;
                             
            else
                state <= Read_Inputs;
            end if;
            
          when others =>

        end case;
      end if;
    end if;
   end process The_SW_accelerator;
   
   
--write side FSM (master)
The_M_accelerator : process (clk) is
   begin  -- process The_SW_accelerator
    if rising_edge(clk) then     -- Rising clock edge
      if rst = '0' then               -- Synchronous reset (active low)
        
        state2        <= Idle2;        
        stall_sig <= '0';
      else
        
        case state2 is
          when Idle2 =>          
            
            if (valid_out = '1') then
                stall_sig <= '1';
                state2 <= Write_Outputs;
                m_tlast <= last_out;
                
                outputBlock_sig(127 downto 120) <= outputBlock(7 downto 0);
                outputBlock_sig(119 downto 112) <= outputBlock(15 downto 8);
                outputBlock_sig(111 downto 104) <= outputBlock(23 downto 16);
                outputBlock_sig(103 downto 96) <= outputBlock(31 downto 24);
                outputBlock_sig(95 downto 88) <= outputBlock(39 downto 32);
                outputBlock_sig(87 downto 80) <= outputBlock(47 downto 40);
                outputBlock_sig(79 downto 72) <= outputBlock(55 downto 48);
                outputBlock_sig(71 downto 64) <= outputBlock(63 downto 56);
                outputBlock_sig(63 downto 56) <= outputBlock(71 downto 64);
                outputBlock_sig(55 downto 48) <= outputBlock(79 downto 72);
                outputBlock_sig(47 downto 40) <= outputBlock(87 downto 80);
                outputBlock_sig(39 downto 32) <= outputBlock(95 downto 88);
                outputBlock_sig(31 downto 24) <= outputBlock(103 downto 96);
                outputBlock_sig(23 downto 16) <= outputBlock(111 downto 104);
                outputBlock_sig(15 downto 8) <= outputBlock(119 downto 112);
                outputBlock_sig(7 downto 0) <= outputBlock(127 downto 120);
                
            else
                state2 <= Idle2;
                stall_sig <= '0';
            end if;

          when Write_Outputs =>
            --if transfer complete
            if (m_tready = '1' and m_tvalid = '1') then
                state2 <= Idle2;
                stall_sig <= '0';                           
           
            end if;
            
          when others =>
          
        end case;
      end if;
    end if;
   end process The_M_accelerator;  


--endianness conversion
inputBlock(127 downto 120) <= inputBlock_sig(7 downto 0);
inputBlock(119 downto 112) <= inputBlock_sig(15 downto 8);
inputBlock(111 downto 104) <= inputBlock_sig(23 downto 16);
inputBlock(103 downto 96) <= inputBlock_sig(31 downto 24);
inputBlock(95 downto 88) <= inputBlock_sig(39 downto 32);
inputBlock(87 downto 80) <= inputBlock_sig(47 downto 40);
inputBlock(79 downto 72) <= inputBlock_sig(55 downto 48);
inputBlock(71 downto 64) <= inputBlock_sig(63 downto 56);
inputBlock(63 downto 56) <= inputBlock_sig(71 downto 64);
inputBlock(55 downto 48) <= inputBlock_sig(79 downto 72);
inputBlock(47 downto 40) <= inputBlock_sig(87 downto 80);
inputBlock(39 downto 32) <= inputBlock_sig(95 downto 88);
inputBlock(31 downto 24) <= inputBlock_sig(103 downto 96);
inputBlock(23 downto 16) <= inputBlock_sig(111 downto 104);
inputBlock(15 downto 8) <= inputBlock_sig(119 downto 112);
inputBlock(7 downto 0) <= inputBlock_sig(127 downto 120);

-- outputBlock_sig(127 downto 120) <= outputBlock(7 downto 0);
-- outputBlock_sig(119 downto 112) <= outputBlock(15 downto 8);
-- outputBlock_sig(111 downto 104) <= outputBlock(23 downto 16);
-- outputBlock_sig(103 downto 96) <= outputBlock(31 downto 24);
-- outputBlock_sig(95 downto 88) <= outputBlock(39 downto 32);
-- outputBlock_sig(87 downto 80) <= outputBlock(47 downto 40);
-- outputBlock_sig(79 downto 72) <= outputBlock(55 downto 48);
-- outputBlock_sig(71 downto 64) <= outputBlock(63 downto 56);
-- outputBlock_sig(63 downto 56) <= outputBlock(71 downto 64);
-- outputBlock_sig(55 downto 48) <= outputBlock(79 downto 72);
-- outputBlock_sig(47 downto 40) <= outputBlock(87 downto 80);
-- outputBlock_sig(39 downto 32) <= outputBlock(95 downto 88);
-- outputBlock_sig(31 downto 24) <= outputBlock(103 downto 96);
-- outputBlock_sig(23 downto 16) <= outputBlock(111 downto 104);
-- outputBlock_sig(15 downto 8) <= outputBlock(119 downto 112);
-- outputBlock_sig(7 downto 0) <= outputBlock(127 downto 120);

inputKey(127 downto 120) <= inputKey_sig(7 downto 0);
inputKey(119 downto 112) <= inputKey_sig(15 downto 8);
inputKey(111 downto 104) <= inputKey_sig(23 downto 16);
inputKey(103 downto 96) <= inputKey_sig(31 downto 24);
inputKey(95 downto 88) <= inputKey_sig(39 downto 32);
inputKey(87 downto 80) <= inputKey_sig(47 downto 40);
inputKey(79 downto 72) <= inputKey_sig(55 downto 48);
inputKey(71 downto 64) <= inputKey_sig(63 downto 56);
inputKey(63 downto 56) <= inputKey_sig(71 downto 64);
inputKey(55 downto 48) <= inputKey_sig(79 downto 72);
inputKey(47 downto 40) <= inputKey_sig(87 downto 80);
inputKey(39 downto 32) <= inputKey_sig(95 downto 88);
inputKey(31 downto 24) <= inputKey_sig(103 downto 96);
inputKey(23 downto 16) <= inputKey_sig(111 downto 104);
inputKey(15 downto 8) <= inputKey_sig(119 downto 112);
inputKey(7 downto 0) <= inputKey_sig(127 downto 120);
    
        

end arch_imp;
