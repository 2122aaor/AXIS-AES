library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



--each mixcolumn8 unit calculates 8 bits or 1 cell in the matrix
--it assumes that i1 * 2, i2 * 3, i3 * 1, i4 * 1
--therefore you port map i1-i4 such that the above multiplications are correct

entity mixcolumns is
    port ( 
        a : in  std_logic_vector (127 downto 0);
        mixcol : out  std_logic_vector (127 downto 0)
       );
end mixcolumns;

architecture Behavioral of mixcolumns is

signal p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15:std_logic_vector(7 downto 0);

component mixcolumn8 is
    port ( 
        i1,i2,i3,i4: in std_logic_vector (7 downto 0);
        data_out : out  std_logic_vector (7 downto 0)
           );
end component;
 
begin

m1:mixcolumn8 port map(a(127 downto 120), a(119 downto 112), a(111 downto 104), a(103 downto 96), p0);
m2:mixcolumn8 port map(a(119 downto 112), a(111 downto 104), a(103 downto 96), a(127 downto 120), p1);
m3:mixcolumn8 port map(a(111 downto 104), a(103 downto 96), a(127 downto 120), a(119 downto 112), p2);
m4:mixcolumn8 port map(a(103 downto 96), a(127 downto 120), a(119 downto 112), a(111 downto 104), p3);

m5:mixcolumn8 port map(a(95 downto 88), a(87 downto 80), a(79 downto 72), a(71 downto 64), p4);
m6:mixcolumn8 port map(a(87 downto 80), a(79 downto 72), a(71 downto 64), a(95 downto 88), p5);
m7:mixcolumn8 port map(a(79 downto 72), a(71 downto 64), a(95 downto 88), a(87 downto 80), p6);
m8:mixcolumn8 port map(a(71 downto 64), a(95 downto 88), a(87 downto 80), a(79 downto 72), p7);

m9:mixcolumn8 port map(a(63 downto 56), a(55 downto 48), a(47 downto 40), a(39 downto 32), p8);
m10:mixcolumn8 port map(a(55 downto 48), a(47 downto 40), a(39 downto 32), a(63 downto 56), p9);
m11:mixcolumn8 port map(a(47 downto 40), a(39 downto 32), a(63 downto 56), a(55 downto 48), p10);
m12:mixcolumn8 port map(a(39 downto 32), a(63 downto 56), a(55 downto 48), a(47 downto 40), p11);

m13:mixcolumn8 port map(a(31 downto 24), a(23 downto 16), a(15 downto 8), a(7 downto 0), p12);
m14:mixcolumn8 port map(a(23 downto 16), a(15 downto 8), a(7 downto 0), a(31 downto 24), p13);
m15:mixcolumn8 port map(a(15 downto 8), a(7 downto 0), a(31 downto 24), a(23 downto 16), p14);
m16:mixcolumn8 port map(a(7 downto 0), a(31 downto 24), a(23 downto 16), a(15 downto 8), p15);

mixcol <= p0 & p1 & p2 & p3 & p4 & p5 & p6 & p7 & p8 & p9 & p10 & p11 & p12 & p13 & p14 & p15;


end Behavioral;