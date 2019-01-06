library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--USE IEEE.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--mainRoundNoCols represents the hardware within a single AES mainstay round
--this includes the following permutations
-- SubBytes
-- ShiftRow
-- MixCols
-- Add RoundKey

--in this version, key generation for this particular round is done locally,
-- therefore the input key should be the key used in the previous round

--Likewise, the 128-bit block input should come from the output of the previous AES round

entity mainRoundNoCols is
    
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
end mainRoundNoCols;

architecture Behavioral of mainRoundNoCols is

--component declarations


component mixcolumns is
Port ( a : in  STD_LOGIC_VECTOR (127 downto 0);
       mixout : out  STD_LOGIC_VECTOR (127 downto 0));
end component;

--signals

--forward sbox lookup array
type ram_type is array(natural range<>) of std_logic_vector(7 downto 0);
constant sbox_ram: ram_type(255 downto 0) :=
(
X"16", X"bb", X"54", X"b0", X"0f", X"2d", X"99", X"41", X"68", X"42", X"e6", X"bf", X"0d", X"89", X"a1", X"8c", 
X"df", X"28", X"55", X"ce", X"e9", X"87", X"1e", X"9b", X"94", X"8e", X"d9", X"69", X"11", X"98", X"f8", X"e1", 
X"9e", X"1d", X"c1", X"86", X"b9", X"57", X"35", X"61", X"0e", X"f6", X"03", X"48", X"66", X"b5", X"3e", X"70", 
X"8a", X"8b", X"bd", X"4b", X"1f", X"74", X"dd", X"e8", X"c6", X"b4", X"a6", X"1c", X"2e", X"25", X"78", X"ba", 
X"08", X"ae", X"7a", X"65", X"ea", X"f4", X"56", X"6c", X"a9", X"4e", X"d5", X"8d", X"6d", X"37", X"c8", X"e7", 
X"79", X"e4", X"95", X"91", X"62", X"ac", X"d3", X"c2", X"5c", X"24", X"06", X"49", X"0a", X"3a", X"32", X"e0", 
X"db", X"0b", X"5e", X"de", X"14", X"b8", X"ee", X"46", X"88", X"90", X"2a", X"22", X"dc", X"4f", X"81", X"60", 
X"73", X"19", X"5d", X"64", X"3d", X"7e", X"a7", X"c4", X"17", X"44", X"97", X"5f", X"ec", X"13", X"0c", X"cd", 
X"d2", X"f3", X"ff", X"10", X"21", X"da", X"b6", X"bc", X"f5", X"38", X"9d", X"92", X"8f", X"40", X"a3", X"51", 
X"a8", X"9f", X"3c", X"50", X"7f", X"02", X"f9", X"45", X"85", X"33", X"4d", X"43", X"fb", X"aa", X"ef", X"d0", 
X"cf", X"58", X"4c", X"4a", X"39", X"be", X"cb", X"6a", X"5b", X"b1", X"fc", X"20", X"ed", X"00", X"d1", X"53", 
X"84", X"2f", X"e3", X"29", X"b3", X"d6", X"3b", X"52", X"a0", X"5a", X"6e", X"1b", X"1a", X"2c", X"83", X"09", 
X"75", X"b2", X"27", X"eb", X"e2", X"80", X"12", X"07", X"9a", X"05", X"96", X"18", X"c3", X"23", X"c7", X"04", 
X"15", X"31", X"d8", X"71", X"f1", X"e5", X"a5", X"34", X"cc", X"f7", X"3f", X"36", X"26", X"93", X"fd", X"b7", 
X"c0", X"72", X"a4", X"9c", X"af", X"a2", X"d4", X"ad", X"f0", X"47", X"59", X"fa", X"7d", X"c9", X"82", X"ca", 
X"76", X"ab", X"d7", X"fe", X"2b", X"67", X"01", X"30", X"c5", X"6f", X"6b", X"f2", X"7b", X"77", X"7c", X"63" 
);

--key generation signals
signal roundKey : std_logic_vector(127 downto 0);
signal rotWord : std_logic_vector(31 downto 0); --rotate last word of input key
signal subWord : std_logic_vector(31 downto 0);
signal subWord_sig : std_logic_vector(31 downto 0); 
signal rCon : std_logic_vector(31 downto 0);


--block permutation signals
signal inputKey_sig : std_logic_vector(127 downto 0);
signal subBytes : std_logic_vector(127 downto 0);

signal inputBlock_sig : std_logic_vector(127 downto 0);

signal tempRow0 : std_logic_vector(31 downto 0);
signal tempRow1 : std_logic_vector(31 downto 0);
signal tempRow2 : std_logic_vector(31 downto 0);
signal tempRow3 : std_logic_vector(31 downto 0);

signal shiftRow0 : std_logic_vector(31 downto 0);
signal shiftRow1 : std_logic_vector(31 downto 0);
signal shiftRow2 : std_logic_vector(31 downto 0);
signal shiftRow3 : std_logic_vector(31 downto 0);
signal shiftRow : std_logic_vector(127 downto 0);

signal mixCols : std_logic_vector(127 downto 0);

signal addRoundKey : std_logic_vector(127 downto 0);

--intermediatary signals between permutation steps
signal subShift : std_logic_vector(127 downto 0);
signal shiftMix : std_logic_vector(127 downto 0);
signal mixAdd : std_logic_vector(127 downto 0);


--state machine signals

--valid and last signals
signal valid_0 : std_logic;
signal last_0 : std_logic;
signal valid_1 : std_logic;
signal last_1 : std_logic;
signal valid_2 : std_logic;
signal last_2 : std_logic;
signal valid_3 : std_logic;
signal last_3 : std_logic;


begin

valid_out <= valid_3;
last_out <= last_3;

--state machine
main_signals : process (clk)
begin
    if rising_edge(clk) then
        if rst = '0' then
            valid_0 <= '0';
            last_0 <= '0';
            valid_1 <= '0';
            last_1 <= '0';
            valid_2 <= '0';
            last_2 <= '0';
            valid_3 <= '0';
            last_3 <= '0';
        else
            inputKey_sig <= inputKey;
            
            if stall = '1' then
                inputBlock_sig <= inputBlock_sig;
            
                tempRow0 <= tempRow0;
                tempRow1 <= tempRow1;
                tempRow2 <= tempRow2;
                tempRow3 <= tempRow3;
                
                shiftMix <= shiftMix;
                mixAdd <= mixAdd;
                
                valid_0 <= valid_0;
                last_0 <= last_0;
                valid_1 <= valid_1;
                last_1 <= last_1;
                valid_2 <= valid_2;
                last_2 <= last_2;
                valid_3 <= valid_3;
                last_3 <= last_3;
                
            else  
                --inputKey_sig <= inputKey;
                subWord_sig <= subWord;
                
                inputBlock_sig <= inputBlock;
                
                tempRow0 <= subBytes(127 downto 120) & subBytes(95 downto 88) & subBytes(63 downto 56) & subBytes(31 downto 24);
                tempRow1 <= subBytes(119 downto 112) & subBytes(87 downto 80) & subBytes(55 downto 48) & subBytes(23 downto 16);
                tempRow2 <= subBytes(111 downto 104) & subBytes(79 downto 72) & subBytes(47 downto 40) & subBytes(15 downto 8);
                tempRow3 <= subBytes(103 downto 96) & subBytes(71 downto 64) & subBytes(39 downto 32) & subBytes(7 downto 0);

                shiftMix <= shiftRow;
                mixAdd <= mixCols;
                
                valid_0 <= valid_in;
                last_0 <= last_in;
                valid_1 <= valid_0;
                last_1 <= last_0;
                valid_2 <= valid_1;
                last_2 <= last_1;
                valid_3 <= valid_2;
                last_3 <= last_2;
            end if;
        end if;
        
    end if;
         
end process;


--/////////////////////////////////////////////////////////////////////////////////////////////////////////////
--output of internal signals to port level
--outputKey <= roundKey;
outputKey <= RoundKey;
outputBlock <= addRoundKey;


--//////////////////////////////////////////////////////////////////////////////////////////////////////////////
--key generation assignments
rotWord <= inputKey_sig(23 downto 0) & inputKey_sig(31 downto 24);

subWord(7 downto 0) <= sbox_ram(conv_integer(rotWord(7 downto 0)));
subWord(15 downto 8) <= sbox_ram(conv_integer(rotWord(15 downto 8)));
subWord(23 downto 16) <= sbox_ram(conv_integer(rotWord(23 downto 16)));
subWord(31 downto 24) <= sbox_ram(conv_integer(rotWord(31 downto 24)));



rCon <= roundConst XOR subWord_sig;

roundKey(127 downto 96) <= inputKey_sig(127 downto 96) XOR rCon;
roundKey(95 downto 64) <= roundKey(127 downto 96) XOR inputKey_sig(95 downto 64);
roundKey(63 downto 32) <= roundKey(95 downto 64) XOR inputKey_sig(63 downto 32);
roundKey(31 downto 0) <= roundKey(63 downto 32) XOR inputKey_sig(31 downto 0);


--//////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- block permutation (currently all done as combinational statements)


--byte substitution

--subBytes word 0
subBytes(7 downto 0) <= sbox_ram(conv_integer(inputBlock_sig(7 downto 0)));
subBytes(15 downto 8) <= sbox_ram(conv_integer(inputBlock_sig(15 downto 8)));
subBytes(23 downto 16) <= sbox_ram(conv_integer(inputBlock_sig(23 downto 16)));
subBytes(31 downto 24) <= sbox_ram(conv_integer(inputBlock_sig(31 downto 24)));
--subBytes word 1
subBytes(39 downto 32) <= sbox_ram(conv_integer(inputBlock_sig(39 downto 32)));
subBytes(47 downto 40) <= sbox_ram(conv_integer(inputBlock_sig(47 downto 40)));
subBytes(55 downto 48) <= sbox_ram(conv_integer(inputBlock_sig(55 downto 48)));
subBytes(63 downto 56) <= sbox_ram(conv_integer(inputBlock_sig(63 downto 56)));
--subBytes word 2
subBytes(71 downto 64) <= sbox_ram(conv_integer(inputBlock_sig(71 downto 64)));
subBytes(79 downto 72) <= sbox_ram(conv_integer(inputBlock_sig(79 downto 72)));
subBytes(87 downto 80) <= sbox_ram(conv_integer(inputBlock_sig(87 downto 80)));
subBytes(95 downto 88) <= sbox_ram(conv_integer(inputBlock_sig(95 downto 88)));
--subBytes word 3
subBytes(103 downto 96) <= sbox_ram(conv_integer(inputBlock_sig(103 downto 96)));
subBytes(111 downto 104) <= sbox_ram(conv_integer(inputBlock_sig(111 downto 104)));
subBytes(119 downto 112) <= sbox_ram(conv_integer(inputBlock_sig(119 downto 112)));
subBytes(127 downto 120) <= sbox_ram(conv_integer(inputBlock_sig(127 downto 120)));


--///////////////////////////////////////////////////////////////////////////////////////////////////////////////
--shift row

--shiftRow done with intermediatary signals for better readability
--construct rows



-- tempRow0 <= subBytes(127 downto 120) & subBytes(95 downto 88) & subBytes(63 downto 56) & subBytes(31 downto 24);
-- tempRow1 <= subBytes(119 downto 112) & subBytes(87 downto 80) & subBytes(55 downto 48) & subBytes(23 downto 16);
-- tempRow2 <= subBytes(111 downto 104) & subBytes(79 downto 72) & subBytes(47 downto 40) & subBytes(15 downto 8);
-- tempRow3 <= subBytes(103 downto 96) & subBytes(71 downto 64) & subBytes(39 downto 32) & subBytes(7 downto 0);


-- --shift the rows
shiftRow0 <= tempRow0;
shiftRow1 <= tempRow1(23 downto 0) & tempRow1(31 downto 24);
shiftRow2 <= tempRow2(15 downto 0) & tempRow2(31 downto 16);
shiftRow3 <= tempRow3(7 downto 0) & tempRow3(31 downto 8);
--reconstruct the block after shifting (yes it's ugly, could make more intermediate signals but it could increase delay)
shiftRow <= shiftRow0(31 downto 24) & shiftRow1(31 downto 24) & shiftRow2(31 downto 24) & shiftRow3(31 downto 24) & 
            shiftRow0(23 downto 16) & shiftRow1(23 downto 16) & shiftRow2(23 downto 16) & shiftRow3(23 downto 16) & 
            shiftRow0(15 downto 8) & shiftRow1(15 downto 8) & shiftRow2(15 downto 8) & shiftRow3(15 downto 8) & 
            shiftRow0(7 downto 0) & shiftRow1(7 downto 0) & shiftRow2(7 downto 0) & shiftRow3(7 downto 0);




--//////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- mix columns

-- column_mix : mixcolumns
    -- port map (
        -- a => shiftMix,
        -- mixout => mixCols
    -- );
mixCols <= shiftMix;
    
    
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- add RoundKey


addRoundKey <= mixAdd XOR roundKey;


end Behavioral;