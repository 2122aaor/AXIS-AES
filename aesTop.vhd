library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--USE IEEE.std_logic_arith.all;
use ieee.std_logic_unsigned.all;



entity aesTop is
    
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
end aesTop;

architecture Behavioral of aesTop is

component mainRound is
    
    port (
        clk : in std_logic;
        rst : in std_logic;
        
        --main data inputs for single round hardware
        inputBlock : in std_logic_vector(127 downto 0);
        inputKey : in std_logic_vector(127 downto 0);
        roundConst : in std_logic_vector(31 downto 0); --the round constant used in generating the key for this particular round
        
        --main data outputs for single round hardware
        outputBlock : out std_logic_vector(127 downto 0);
        outputKey : out std_logic_vector(127 downto 0);
        
        --valid and last signals
        valid_in : in std_logic;
        last_in : in std_logic;
        valid_out : out std_logic;
        last_out : out std_logic;
        stall : in std_logic
        
    );
end component;

 component mainRoundNoCols is
    
     port (
         clk : in std_logic;
         rst : in std_logic;
        
         --main data inputs for single round hardware
         inputBlock : in std_logic_vector(127 downto 0);
         inputKey : in std_logic_vector(127 downto 0);
         roundConst : in std_logic_vector(31 downto 0); --the round constant used in generating the key for this particular round
        
         --main data outputs for single round hardware
         outputBlock : out std_logic_vector(127 downto 0);
         outputKey : out std_logic_vector(127 downto 0);
         
         --valid and last signals
        valid_in : in std_logic;
        last_in : in std_logic;
        valid_out : out std_logic;
        last_out : out std_logic;
        stall : in std_logic
     );
 end component;

--signals
signal block0_1 : std_logic_vector(127 downto 0);
signal block1_2 : std_logic_vector(127 downto 0);
signal block2_3 : std_logic_vector(127 downto 0);
signal block3_4 : std_logic_vector(127 downto 0);
signal block4_5 : std_logic_vector(127 downto 0);
signal block5_6 : std_logic_vector(127 downto 0);
signal block6_7 : std_logic_vector(127 downto 0);
signal block7_8 : std_logic_vector(127 downto 0);
signal block8_9 : std_logic_vector(127 downto 0);
signal block9_10 : std_logic_vector(127 downto 0);

signal key1_2 : std_logic_vector(127 downto 0);
signal key2_3 : std_logic_vector(127 downto 0);
signal key3_4 : std_logic_vector(127 downto 0);
signal key4_5 : std_logic_vector(127 downto 0);
signal key5_6 : std_logic_vector(127 downto 0);
signal key6_7 : std_logic_vector(127 downto 0);
signal key7_8 : std_logic_vector(127 downto 0);
signal key8_9 : std_logic_vector(127 downto 0);
signal key9_10 : std_logic_vector(127 downto 0);

signal endKey : std_logic_vector(127 downto 0);

signal valid1_2 : std_logic;
signal valid2_3 : std_logic;
signal valid3_4 : std_logic;
signal valid4_5 : std_logic;
signal valid5_6 : std_logic;
signal valid6_7 : std_logic;
signal valid7_8 : std_logic;
signal valid8_9 : std_logic;
signal valid9_10 : std_logic;

signal last1_2 : std_logic;
signal last2_3 : std_logic;
signal last3_4 : std_logic;
signal last4_5 : std_logic;
signal last5_6 : std_logic;
signal last6_7 : std_logic;
signal last7_8 : std_logic;
signal last8_9 : std_logic;
signal last9_10 : std_logic;



begin

    --round 0
    block0_1 <= inputBlock XOR inputKey;
    --outputBlock <= block9_10;

    round1 : mainRound
        port map(
            clk => clk,
            rst => rst,
            inputBlock => block0_1,
            inputKey => inputKey,
            roundConst => x"01000000",
            outputBlock => block1_2,
            outputKey => key1_2,
            valid_in => valid_in,
            last_in => last_in,
            valid_out => valid1_2,
            last_out => last1_2,
            stall => stall
        );
        
    round2 : mainRound
        port map(
            clk => clk,
            rst => rst,
            inputBlock => block1_2,
            inputKey => key1_2,
            roundConst => x"02000000",
            outputBlock => block2_3,
            outputKey => key2_3,
            valid_in => valid1_2,
            last_in => last1_2,
            valid_out => valid2_3,
            last_out => last2_3,
            stall => stall
        );
        
     round3 : mainRound
         port map(
             clk => clk,
             rst => rst,
             inputBlock => block2_3,
             inputKey => key2_3,
             roundConst => x"04000000",
             outputBlock => block3_4,
             outputKey => key3_4,
             valid_in => valid2_3,
            last_in => last2_3,
            valid_out => valid3_4,
            last_out => last3_4,
            stall => stall
         );
        
     round4 : mainRound
         port map(
             clk => clk,
             rst => rst,
             inputBlock => block3_4,
             inputKey => key3_4,
             roundConst => x"08000000",
             outputBlock => block4_5,
             outputKey => key4_5,
             valid_in => valid3_4,
            last_in => last3_4,
            valid_out => valid4_5,
            last_out => last4_5,
            stall => stall
         );
        
     round5 : mainRound
         port map(
             clk => clk,
             rst => rst,
             inputBlock => block4_5,
             inputKey => key4_5,
             roundConst => x"10000000",
             outputBlock => block5_6,
             outputKey => key5_6,
             valid_in => valid4_5,
            last_in => last4_5,
            valid_out => valid5_6,
            last_out => last5_6,
            stall => stall
         );
        
     round6 : mainRound
         port map(
             clk => clk,
             rst => rst,
             inputBlock => block5_6,
             inputKey => key5_6,
             roundConst => x"20000000",
             outputBlock => block6_7,
             outputKey => key6_7,
             valid_in => valid5_6,
            last_in => last5_6,
            valid_out => valid6_7,
            last_out => last6_7,
            stall => stall
         );
        
     round7 : mainRound
         port map(
             clk => clk,
             rst => rst,
             inputBlock => block6_7,
             inputKey => key6_7,
             roundConst => x"40000000",
             outputBlock => block7_8,
             outputKey => key7_8,
             valid_in => valid6_7,
            last_in => last6_7,
            valid_out => valid7_8,
            last_out => last7_8,
            stall => stall
         );
        
     round8 : mainRound
         port map(
             clk => clk,
             rst => rst,
             inputBlock => block7_8,
             inputKey => key7_8,
             roundConst => x"80000000",
             outputBlock => block8_9,
             outputKey => key8_9,
             valid_in => valid7_8,
            last_in => last7_8,
            valid_out => valid8_9,
            last_out => last8_9,
            stall => stall
         );
        
     round9 : mainRound
         port map(
             clk => clk,
             rst => rst,
             inputBlock => block8_9,
             inputKey => key8_9,
             roundConst => x"1b000000",
             outputBlock => block9_10,
             outputKey => key9_10,
             valid_in => valid8_9,
            last_in => last8_9,
            valid_out => valid9_10,
            last_out => last9_10,
            stall => stall
         );
        
     round10 : mainRoundNoCols
         port map(
             clk => clk,
             rst => rst,
             inputBlock => block9_10,
             inputKey => key9_10,
             roundConst => x"36000000",
             outputBlock => outputBlock,
             outputKey => endKey,
             valid_in => valid9_10,
            last_in => last9_10,
            valid_out => valid_out,
            last_out => last_out,
            stall => stall
         );

end Behavioral;