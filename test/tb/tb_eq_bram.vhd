-- RAMB18E1, RAMB36E1, RAMB18E2 and RAMB36E2 against the submodule
-- Verilog. XIL_TIMING is left undefined. The Verilog specify paths (and
-- the E2 output assignments) are 100 ps; this bench waits 10 ns after
-- the rising edge. SIM_COLLISION_CHECK is NONE so the reference does
-- not inject collision X. The VHDL model has no collision check.
--
-- RAMB18E1's output reg starts X and is copied from the data mux only
-- when that mux changes. READ_FIRST and NO_CHANGE below use a non-zero
-- INIT_A so GSR drives a real transition before the first clock.
-- RAMB18E2 and RAMB36E2 take their read and write loop counts from
-- always @(READ_WIDTH_*_BIN). NVC does not run that block, the counts
-- stay at 1, and the reference port stays X, so those two cells are
-- checked against the values the Verilog write-first path describes.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

library unisim;

entity bram18_e1_wrap is
  generic (
    as_vhdl : boolean;
    -- Verilog parameters have to be locally static, so each cfg is a
    -- literal generic map rather than a value passed through.
    cfg : integer := 0
  );
  port (
    clka, clkb, ena, enb : in std_ulogic;
    wea : in std_logic_vector(1 downto 0);
    web : in std_logic_vector(3 downto 0);
    addra, addrb : in std_logic_vector(13 downto 0);
    dia, dib : in std_logic_vector(15 downto 0);
    dipa, dipb : in std_logic_vector(1 downto 0);
    rstra, rreg : in std_ulogic;
    regce : in std_ulogic;
    doa, dob : out std_logic_vector(15 downto 0);
    dopa, dopb : out std_logic_vector(1 downto 0)
  );
end entity bram18_e1_wrap;

architecture sim of bram18_e1_wrap is
  component RAMB18E1 is
    generic (
      DOA_REG : integer := 0;
      DOB_REG : integer := 0;
      INITP_00 : bit_vector(255 downto 0) := (others => '0');
      INIT_00 : bit_vector(255 downto 0) := (others => '0');
      INIT_A : bit_vector(17 downto 0) := (others => '0');
      INIT_FILE : string := "NONE";
      RAM_MODE : string := "TDP";
      READ_WIDTH_A : integer := 0;
      READ_WIDTH_B : integer := 0;
      RSTREG_PRIORITY_A : string := "RSTREG";
      SIM_COLLISION_CHECK : string := "ALL";
      SRVAL_A : bit_vector(17 downto 0) := (others => '0');
      WRITE_MODE_A : string := "WRITE_FIRST";
      WRITE_MODE_B : string := "WRITE_FIRST";
      WRITE_WIDTH_A : integer := 0;
      WRITE_WIDTH_B : integer := 0
    );
    port (
      DOADO : out std_logic_vector(15 downto 0);
      DOBDO : out std_logic_vector(15 downto 0);
      DOPADOP : out std_logic_vector(1 downto 0);
      DOPBDOP : out std_logic_vector(1 downto 0);
      ADDRARDADDR : in std_logic_vector(13 downto 0);
      ADDRBWRADDR : in std_logic_vector(13 downto 0);
      CLKARDCLK, CLKBWRCLK : in std_ulogic;
      DIADI, DIBDI : in std_logic_vector(15 downto 0);
      DIPADIP, DIPBDIP : in std_logic_vector(1 downto 0);
      ENARDEN, ENBWREN : in std_ulogic;
      REGCEAREGCE, REGCEB : in std_ulogic;
      RSTRAMARSTRAM, RSTRAMB : in std_ulogic;
      RSTREGARSTREG, RSTREGB : in std_ulogic;
      WEA : in std_logic_vector(1 downto 0);
      WEBWE : in std_logic_vector(3 downto 0)
    );
  end component;
begin
  g_v : if not as_vhdl generate
    g0 : if cfg = 0 generate
      u : RAMB18E1
        generic map (
          DOA_REG => 0, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'), INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 18, READ_WIDTH_B => 18,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => (others => '0'),
          WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
          WRITE_WIDTH_A => 18, WRITE_WIDTH_B => 18
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g1 : if cfg = 1 generate
      u : RAMB18E1
        generic map (
          DOA_REG => 0, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'),
          INIT_A => "100000000011111111", INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 18, READ_WIDTH_B => 18,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => (others => '0'),
          WRITE_MODE_A => "READ_FIRST", WRITE_MODE_B => "READ_FIRST",
          WRITE_WIDTH_A => 18, WRITE_WIDTH_B => 18
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g2 : if cfg = 2 generate
      u : RAMB18E1
        generic map (
          DOA_REG => 0, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'),
          INIT_A => "100000000011111111", INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 18, READ_WIDTH_B => 18,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => (others => '0'),
          WRITE_MODE_A => "NO_CHANGE", WRITE_MODE_B => "NO_CHANGE",
          WRITE_WIDTH_A => 18, WRITE_WIDTH_B => 18
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g3 : if cfg = 3 generate
      u : RAMB18E1
        generic map (
          DOA_REG => 0, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'), INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 9, READ_WIDTH_B => 9,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => (others => '0'),
          WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
          WRITE_WIDTH_A => 9, WRITE_WIDTH_B => 9
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g4 : if cfg = 4 generate
      u : RAMB18E1
        generic map (
          DOA_REG => 0, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'), INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 1, READ_WIDTH_B => 1,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => (others => '0'),
          WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
          WRITE_WIDTH_A => 1, WRITE_WIDTH_B => 1
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g5 : if cfg = 5 generate
      u : RAMB18E1
        generic map (
          DOA_REG => 0, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'), INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 4, READ_WIDTH_B => 4,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => (others => '0'),
          WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
          WRITE_WIDTH_A => 4, WRITE_WIDTH_B => 4
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g6 : if cfg = 6 generate
      u : RAMB18E1
        generic map (
          DOA_REG => 1, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'), INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 18, READ_WIDTH_B => 18,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => (others => '0'),
          WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
          WRITE_WIDTH_A => 18, WRITE_WIDTH_B => 18
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g7 : if cfg = 7 generate
      u : RAMB18E1
        generic map (
          DOA_REG => 0, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'), INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 18, READ_WIDTH_B => 18,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => "100000000011111111",
          WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
          WRITE_WIDTH_A => 18, WRITE_WIDTH_B => 18
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g8 : if cfg = 8 generate
      u : RAMB18E1
        generic map (
          DOA_REG => 1, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'), INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 18, READ_WIDTH_B => 18,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => "100000000011111111",
          WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
          WRITE_WIDTH_A => 18, WRITE_WIDTH_B => 18
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g9 : if cfg = 9 generate
      u : RAMB18E1
        generic map (
          DOA_REG => 0, DOB_REG => 0, INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000003",
          INIT_00 => X"0000000000000000000000000000000000000000000000000000000000001234", INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 18, READ_WIDTH_B => 18,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => (others => '0'),
          WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
          WRITE_WIDTH_A => 18, WRITE_WIDTH_B => 18
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g10 : if cfg = 10 generate
      u : RAMB18E1
        generic map (
          DOA_REG => 0, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'), INIT_FILE => "NONE",
          RAM_MODE => "SDP", READ_WIDTH_A => 36, READ_WIDTH_B => 36,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => (others => '0'),
          WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
          WRITE_WIDTH_A => 36, WRITE_WIDTH_B => 36
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
  end generate;
  g_h : if as_vhdl generate
    g0 : if cfg = 0 generate
      u : entity unisim.RAMB18E1
        generic map (
          DOA_REG => 0, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'), INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 18, READ_WIDTH_B => 18,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => (others => '0'),
          WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
          WRITE_WIDTH_A => 18, WRITE_WIDTH_B => 18
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g1 : if cfg = 1 generate
      u : entity unisim.RAMB18E1
        generic map (
          DOA_REG => 0, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'),
          INIT_A => "100000000011111111", INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 18, READ_WIDTH_B => 18,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => (others => '0'),
          WRITE_MODE_A => "READ_FIRST", WRITE_MODE_B => "READ_FIRST",
          WRITE_WIDTH_A => 18, WRITE_WIDTH_B => 18
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g2 : if cfg = 2 generate
      u : entity unisim.RAMB18E1
        generic map (
          DOA_REG => 0, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'),
          INIT_A => "100000000011111111", INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 18, READ_WIDTH_B => 18,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => (others => '0'),
          WRITE_MODE_A => "NO_CHANGE", WRITE_MODE_B => "NO_CHANGE",
          WRITE_WIDTH_A => 18, WRITE_WIDTH_B => 18
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g3 : if cfg = 3 generate
      u : entity unisim.RAMB18E1
        generic map (
          DOA_REG => 0, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'), INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 9, READ_WIDTH_B => 9,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => (others => '0'),
          WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
          WRITE_WIDTH_A => 9, WRITE_WIDTH_B => 9
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g4 : if cfg = 4 generate
      u : entity unisim.RAMB18E1
        generic map (
          DOA_REG => 0, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'), INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 1, READ_WIDTH_B => 1,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => (others => '0'),
          WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
          WRITE_WIDTH_A => 1, WRITE_WIDTH_B => 1
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g5 : if cfg = 5 generate
      u : entity unisim.RAMB18E1
        generic map (
          DOA_REG => 0, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'), INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 4, READ_WIDTH_B => 4,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => (others => '0'),
          WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
          WRITE_WIDTH_A => 4, WRITE_WIDTH_B => 4
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g6 : if cfg = 6 generate
      u : entity unisim.RAMB18E1
        generic map (
          DOA_REG => 1, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'), INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 18, READ_WIDTH_B => 18,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => (others => '0'),
          WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
          WRITE_WIDTH_A => 18, WRITE_WIDTH_B => 18
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g7 : if cfg = 7 generate
      u : entity unisim.RAMB18E1
        generic map (
          DOA_REG => 0, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'), INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 18, READ_WIDTH_B => 18,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => "100000000011111111",
          WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
          WRITE_WIDTH_A => 18, WRITE_WIDTH_B => 18
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g8 : if cfg = 8 generate
      u : entity unisim.RAMB18E1
        generic map (
          DOA_REG => 1, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'), INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 18, READ_WIDTH_B => 18,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => "100000000011111111",
          WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
          WRITE_WIDTH_A => 18, WRITE_WIDTH_B => 18
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g9 : if cfg = 9 generate
      u : entity unisim.RAMB18E1
        generic map (
          DOA_REG => 0, DOB_REG => 0, INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000003",
          INIT_00 => X"0000000000000000000000000000000000000000000000000000000000001234", INIT_FILE => "NONE",
          RAM_MODE => "TDP", READ_WIDTH_A => 18, READ_WIDTH_B => 18,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => (others => '0'),
          WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
          WRITE_WIDTH_A => 18, WRITE_WIDTH_B => 18
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
    g10 : if cfg = 10 generate
      u : entity unisim.RAMB18E1
        generic map (
          DOA_REG => 0, DOB_REG => 0, INITP_00 => (others => '0'),
          INIT_00 => (others => '0'), INIT_FILE => "NONE",
          RAM_MODE => "SDP", READ_WIDTH_A => 36, READ_WIDTH_B => 36,
          SIM_COLLISION_CHECK => "NONE", SRVAL_A => (others => '0'),
          WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
          WRITE_WIDTH_A => 36, WRITE_WIDTH_B => 36
        )
        port map (
          DOADO => doa, DOBDO => dob, DOPADOP => dopa, DOPBDOP => dopb,
          ADDRARDADDR => addra, ADDRBWRADDR => addrb,
          CLKARDCLK => clka, CLKBWRCLK => clkb,
          DIADI => dia, DIBDI => dib, DIPADIP => dipa, DIPBDIP => dipb,
          ENARDEN => ena, ENBWREN => enb,
          REGCEAREGCE => regce, REGCEB => '0',
          RSTRAMARSTRAM => rstra, RSTRAMB => '0',
          RSTREGARSTREG => rreg, RSTREGB => '0',
          WEA => wea, WEBWE => web
        );
    end generate;
  end generate;
end architecture sim;

library ieee;
use ieee.std_logic_1164.all;
library unisim;

entity bram18_e2_wrap is
  generic (
    as_vhdl : boolean;
    doa_reg : integer := 0;
    rwa : integer := 18;
    rwb : integer := 18;
    wwa : integer := 18;
    wwb : integer := 18;
    wma : string := "WRITE_FIRST";
    wmb : string := "WRITE_FIRST"
  );
  port (
    clka, clkb, ena, enb : in std_ulogic;
    wea : in std_logic_vector(1 downto 0);
    web : in std_logic_vector(3 downto 0);
    addra, addrb : in std_logic_vector(13 downto 0);
    dia, dib : in std_logic_vector(15 downto 0);
    dipa, dipb : in std_logic_vector(1 downto 0);
    regce : in std_ulogic;
    doa, dob : out std_logic_vector(15 downto 0);
    dopa, dopb : out std_logic_vector(1 downto 0)
  );
end entity bram18_e2_wrap;

architecture sim of bram18_e2_wrap is
  component RAMB18E2 is
    generic (
      DOA_REG : integer := 1;
      DOB_REG : integer := 1;
      INIT_FILE : string := "NONE";
      READ_WIDTH_A : integer := 0;
      READ_WIDTH_B : integer := 0;
      SIM_COLLISION_CHECK : string := "ALL";
      WRITE_MODE_A : string := "NO_CHANGE";
      WRITE_MODE_B : string := "NO_CHANGE";
      WRITE_WIDTH_A : integer := 0;
      WRITE_WIDTH_B : integer := 0
    );
    port (
      CASDOUTA, CASDOUTB : out std_logic_vector(15 downto 0);
      CASDOUTPA, CASDOUTPB : out std_logic_vector(1 downto 0);
      DOUTADOUT, DOUTBDOUT : out std_logic_vector(15 downto 0);
      DOUTPADOUTP, DOUTPBDOUTP : out std_logic_vector(1 downto 0);
      ADDRARDADDR, ADDRBWRADDR : in std_logic_vector(13 downto 0);
      ADDRENA, ADDRENB, CASDIMUXA, CASDIMUXB : in std_ulogic;
      CASDINA, CASDINB : in std_logic_vector(15 downto 0);
      CASDINPA, CASDINPB : in std_logic_vector(1 downto 0);
      CASDOMUXA, CASDOMUXB, CASDOMUXEN_A, CASDOMUXEN_B : in std_ulogic;
      CASOREGIMUXA, CASOREGIMUXB, CASOREGIMUXEN_A, CASOREGIMUXEN_B : in std_ulogic;
      CLKARDCLK, CLKBWRCLK : in std_ulogic;
      DINADIN, DINBDIN : in std_logic_vector(15 downto 0);
      DINPADINP, DINPBDINP : in std_logic_vector(1 downto 0);
      ENARDEN, ENBWREN, REGCEAREGCE, REGCEB : in std_ulogic;
      RSTRAMARSTRAM, RSTRAMB, RSTREGARSTREG, RSTREGB, SLEEP : in std_ulogic;
      WEA : in std_logic_vector(1 downto 0);
      WEBWE : in std_logic_vector(3 downto 0)
    );
  end component;
  signal z16 : std_logic_vector(15 downto 0) := (others => '0');
  signal z2 : std_logic_vector(1 downto 0) := "00";
begin
  g_v : if not as_vhdl generate
    u : RAMB18E2
      generic map (
        DOA_REG => 0, DOB_REG => 0, INIT_FILE => "NONE",
        READ_WIDTH_A => 18, READ_WIDTH_B => 18,
        SIM_COLLISION_CHECK => "NONE",
        WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
        WRITE_WIDTH_A => 18, WRITE_WIDTH_B => 18
      )
      port map (
        CASDOUTA => open, CASDOUTB => open, CASDOUTPA => open, CASDOUTPB => open,
        DOUTADOUT => doa, DOUTBDOUT => dob, DOUTPADOUTP => dopa, DOUTPBDOUTP => dopb,
        ADDRARDADDR => addra, ADDRBWRADDR => addrb,
        ADDRENA => '0', ADDRENB => '0', CASDIMUXA => '0', CASDIMUXB => '0',
        CASDINA => z16, CASDINB => z16, CASDINPA => z2, CASDINPB => z2,
        CASDOMUXA => '0', CASDOMUXB => '0', CASDOMUXEN_A => '0', CASDOMUXEN_B => '0',
        CASOREGIMUXA => '0', CASOREGIMUXB => '0',
        CASOREGIMUXEN_A => '0', CASOREGIMUXEN_B => '0',
        CLKARDCLK => clka, CLKBWRCLK => clkb,
        DINADIN => dia, DINBDIN => dib, DINPADINP => dipa, DINPBDINP => dipb,
        ENARDEN => ena, ENBWREN => enb, REGCEAREGCE => regce, REGCEB => '0',
        RSTRAMARSTRAM => '0', RSTRAMB => '0', RSTREGARSTREG => '0', RSTREGB => '0',
        SLEEP => '0', WEA => wea, WEBWE => web
      );
  end generate;
  g_h : if as_vhdl generate
    u : entity unisim.RAMB18E2
      generic map (
        DOA_REG => 0, DOB_REG => 0, INIT_FILE => "NONE",
        READ_WIDTH_A => 18, READ_WIDTH_B => 18,
        SIM_COLLISION_CHECK => "NONE",
        WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
        WRITE_WIDTH_A => 18, WRITE_WIDTH_B => 18
      )
      port map (
        CASDOUTA => open, CASDOUTB => open, CASDOUTPA => open, CASDOUTPB => open,
        DOUTADOUT => doa, DOUTBDOUT => dob, DOUTPADOUTP => dopa, DOUTPBDOUTP => dopb,
        ADDRARDADDR => addra, ADDRBWRADDR => addrb,
        ADDRENA => '0', ADDRENB => '0', CASDIMUXA => '0', CASDIMUXB => '0',
        CASDINA => z16, CASDINB => z16, CASDINPA => z2, CASDINPB => z2,
        CASDOMUXA => '0', CASDOMUXB => '0', CASDOMUXEN_A => '0', CASDOMUXEN_B => '0',
        CASOREGIMUXA => '0', CASOREGIMUXB => '0',
        CASOREGIMUXEN_A => '0', CASOREGIMUXEN_B => '0',
        CLKARDCLK => clka, CLKBWRCLK => clkb,
        DINADIN => dia, DINBDIN => dib, DINPADINP => dipa, DINPBDINP => dipb,
        ENARDEN => ena, ENBWREN => enb, REGCEAREGCE => regce, REGCEB => '0',
        RSTRAMARSTRAM => '0', RSTRAMB => '0', RSTREGARSTREG => '0', RSTREGB => '0',
        SLEEP => '0', WEA => wea, WEBWE => web
      );
  end generate;
end architecture sim;

library ieee;
use ieee.std_logic_1164.all;
library unisim;

entity bram36_e1_wrap is
  generic (
    as_vhdl : boolean;
    rwa : integer := 36;
    rwb : integer := 36;
    wwa : integer := 36;
    wwb : integer := 36
  );
  port (
    clka, ena : in std_ulogic;
    wea : in std_logic_vector(3 downto 0);
    addra : in std_logic_vector(15 downto 0);
    dia : in std_logic_vector(31 downto 0);
    dipa : in std_logic_vector(3 downto 0);
    doa : out std_logic_vector(31 downto 0);
    dopa : out std_logic_vector(3 downto 0)
  );
end entity bram36_e1_wrap;

architecture sim of bram36_e1_wrap is
  component RAMB36E1 is
    generic (
      DOA_REG : integer := 0;
      DOB_REG : integer := 0;
      INIT_FILE : string := "NONE";
      RAM_MODE : string := "TDP";
      READ_WIDTH_A : integer := 0;
      READ_WIDTH_B : integer := 0;
      SIM_COLLISION_CHECK : string := "ALL";
      WRITE_MODE_A : string := "WRITE_FIRST";
      WRITE_MODE_B : string := "WRITE_FIRST";
      WRITE_WIDTH_A : integer := 0;
      WRITE_WIDTH_B : integer := 0
    );
    port (
      CASCADEOUTA, CASCADEOUTB, DBITERR, SBITERR : out std_ulogic;
      DOADO, DOBDO : out std_logic_vector(31 downto 0);
      DOPADOP, DOPBDOP : out std_logic_vector(3 downto 0);
      ECCPARITY : out std_logic_vector(7 downto 0);
      RDADDRECC : out std_logic_vector(8 downto 0);
      ADDRARDADDR, ADDRBWRADDR : in std_logic_vector(15 downto 0);
      CASCADEINA, CASCADEINB, CLKARDCLK, CLKBWRCLK : in std_ulogic;
      DIADI, DIBDI : in std_logic_vector(31 downto 0);
      DIPADIP, DIPBDIP : in std_logic_vector(3 downto 0);
      ENARDEN, ENBWREN, INJECTDBITERR, INJECTSBITERR : in std_ulogic;
      REGCEAREGCE, REGCEB, RSTRAMARSTRAM, RSTRAMB : in std_ulogic;
      RSTREGARSTREG, RSTREGB : in std_ulogic;
      WEA : in std_logic_vector(3 downto 0);
      WEBWE : in std_logic_vector(7 downto 0)
    );
  end component;
  signal z32 : std_logic_vector(31 downto 0) := (others => '0');
  signal z16 : std_logic_vector(15 downto 0) := (others => '0');
  signal z4 : std_logic_vector(3 downto 0) := "0000";
  signal z8 : std_logic_vector(7 downto 0) := (others => '0');
begin
  g_v : if not as_vhdl generate
    u : RAMB36E1
      generic map (
        DOA_REG => 0, DOB_REG => 0, INIT_FILE => "NONE", RAM_MODE => "TDP",
        READ_WIDTH_A => 36, READ_WIDTH_B => 36,
        SIM_COLLISION_CHECK => "NONE",
        WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
        WRITE_WIDTH_A => 36, WRITE_WIDTH_B => 36
      )
      port map (
        CASCADEOUTA => open, CASCADEOUTB => open, DBITERR => open, SBITERR => open,
        DOADO => doa, DOBDO => open, DOPADOP => dopa, DOPBDOP => open,
        ECCPARITY => open, RDADDRECC => open,
        ADDRARDADDR => addra, ADDRBWRADDR => z16,
        CASCADEINA => '0', CASCADEINB => '0', CLKARDCLK => clka, CLKBWRCLK => '0',
        DIADI => dia, DIBDI => z32, DIPADIP => dipa, DIPBDIP => z4,
        ENARDEN => ena, ENBWREN => '0', INJECTDBITERR => '0', INJECTSBITERR => '0',
        REGCEAREGCE => '0', REGCEB => '0', RSTRAMARSTRAM => '0', RSTRAMB => '0',
        RSTREGARSTREG => '0', RSTREGB => '0', WEA => wea, WEBWE => z8
      );
  end generate;
  g_h : if as_vhdl generate
    u : entity unisim.RAMB36E1
      generic map (
        DOA_REG => 0, DOB_REG => 0, INIT_FILE => "NONE", RAM_MODE => "TDP",
        READ_WIDTH_A => 36, READ_WIDTH_B => 36,
        SIM_COLLISION_CHECK => "NONE",
        WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
        WRITE_WIDTH_A => 36, WRITE_WIDTH_B => 36
      )
      port map (
        CASCADEOUTA => open, CASCADEOUTB => open, DBITERR => open, SBITERR => open,
        DOADO => doa, DOBDO => open, DOPADOP => dopa, DOPBDOP => open,
        ECCPARITY => open, RDADDRECC => open,
        ADDRARDADDR => addra, ADDRBWRADDR => z16,
        CASCADEINA => '0', CASCADEINB => '0', CLKARDCLK => clka, CLKBWRCLK => '0',
        DIADI => dia, DIBDI => z32, DIPADIP => dipa, DIPBDIP => z4,
        ENARDEN => ena, ENBWREN => '0', INJECTDBITERR => '0', INJECTSBITERR => '0',
        REGCEAREGCE => '0', REGCEB => '0', RSTRAMARSTRAM => '0', RSTRAMB => '0',
        RSTREGARSTREG => '0', RSTREGB => '0', WEA => wea, WEBWE => z8
      );
  end generate;
end architecture sim;

library ieee;
use ieee.std_logic_1164.all;
library unisim;

entity bram36_e2_wrap is
  generic (as_vhdl : boolean);
  port (
    clka, ena : in std_ulogic;
    wea : in std_logic_vector(3 downto 0);
    addra : in std_logic_vector(14 downto 0);
    dia : in std_logic_vector(31 downto 0);
    dipa : in std_logic_vector(3 downto 0);
    doa : out std_logic_vector(31 downto 0);
    dopa : out std_logic_vector(3 downto 0)
  );
end entity bram36_e2_wrap;

architecture sim of bram36_e2_wrap is
  component RAMB36E2 is
    generic (
      DOA_REG : integer := 1;
      DOB_REG : integer := 1;
      INIT_FILE : string := "NONE";
      READ_WIDTH_A : integer := 0;
      READ_WIDTH_B : integer := 0;
      SIM_COLLISION_CHECK : string := "ALL";
      WRITE_MODE_A : string := "NO_CHANGE";
      WRITE_MODE_B : string := "NO_CHANGE";
      WRITE_WIDTH_A : integer := 0;
      WRITE_WIDTH_B : integer := 0
    );
    port (
      CASDOUTA, CASDOUTB : out std_logic_vector(31 downto 0);
      CASDOUTPA, CASDOUTPB : out std_logic_vector(3 downto 0);
      CASOUTDBITERR, CASOUTSBITERR, DBITERR, SBITERR : out std_ulogic;
      DOUTADOUT, DOUTBDOUT : out std_logic_vector(31 downto 0);
      DOUTPADOUTP, DOUTPBDOUTP : out std_logic_vector(3 downto 0);
      ECCPARITY : out std_logic_vector(7 downto 0);
      RDADDRECC : out std_logic_vector(8 downto 0);
      ADDRARDADDR, ADDRBWRADDR : in std_logic_vector(14 downto 0);
      ADDRENA, ADDRENB, CASDIMUXA, CASDIMUXB : in std_ulogic;
      CASDINA, CASDINB : in std_logic_vector(31 downto 0);
      CASDINPA, CASDINPB : in std_logic_vector(3 downto 0);
      CASDOMUXA, CASDOMUXB, CASDOMUXEN_A, CASDOMUXEN_B : in std_ulogic;
      CASINDBITERR, CASINSBITERR : in std_ulogic;
      CASOREGIMUXA, CASOREGIMUXB, CASOREGIMUXEN_A, CASOREGIMUXEN_B : in std_ulogic;
      CLKARDCLK, CLKBWRCLK : in std_ulogic;
      DINADIN, DINBDIN : in std_logic_vector(31 downto 0);
      DINPADINP, DINPBDINP : in std_logic_vector(3 downto 0);
      ECCPIPECE, ENARDEN, ENBWREN, INJECTDBITERR, INJECTSBITERR : in std_ulogic;
      REGCEAREGCE, REGCEB, RSTRAMARSTRAM, RSTRAMB : in std_ulogic;
      RSTREGARSTREG, RSTREGB, SLEEP : in std_ulogic;
      WEA : in std_logic_vector(3 downto 0);
      WEBWE : in std_logic_vector(7 downto 0)
    );
  end component;
  signal z32 : std_logic_vector(31 downto 0) := (others => '0');
  signal z15 : std_logic_vector(14 downto 0) := (others => '0');
  signal z4 : std_logic_vector(3 downto 0) := "0000";
  signal z8 : std_logic_vector(7 downto 0) := (others => '0');
begin
  g_v : if not as_vhdl generate
    u : RAMB36E2
      generic map (
        DOA_REG => 0, DOB_REG => 0, INIT_FILE => "NONE",
        READ_WIDTH_A => 36, READ_WIDTH_B => 36,
        SIM_COLLISION_CHECK => "NONE",
        WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
        WRITE_WIDTH_A => 36, WRITE_WIDTH_B => 36
      )
      port map (
        CASDOUTA => open, CASDOUTB => open, CASDOUTPA => open, CASDOUTPB => open,
        CASOUTDBITERR => open, CASOUTSBITERR => open, DBITERR => open, SBITERR => open,
        DOUTADOUT => doa, DOUTBDOUT => open, DOUTPADOUTP => dopa, DOUTPBDOUTP => open,
        ECCPARITY => open, RDADDRECC => open,
        ADDRARDADDR => addra, ADDRBWRADDR => z15,
        ADDRENA => '0', ADDRENB => '0', CASDIMUXA => '0', CASDIMUXB => '0',
        CASDINA => z32, CASDINB => z32, CASDINPA => z4, CASDINPB => z4,
        CASDOMUXA => '0', CASDOMUXB => '0', CASDOMUXEN_A => '0', CASDOMUXEN_B => '0',
        CASINDBITERR => '0', CASINSBITERR => '0',
        CASOREGIMUXA => '0', CASOREGIMUXB => '0',
        CASOREGIMUXEN_A => '0', CASOREGIMUXEN_B => '0',
        CLKARDCLK => clka, CLKBWRCLK => '0',
        DINADIN => dia, DINBDIN => z32, DINPADINP => dipa, DINPBDINP => z4,
        ECCPIPECE => '0', ENARDEN => ena, ENBWREN => '0',
        INJECTDBITERR => '0', INJECTSBITERR => '0',
        REGCEAREGCE => '0', REGCEB => '0', RSTRAMARSTRAM => '0', RSTRAMB => '0',
        RSTREGARSTREG => '0', RSTREGB => '0', SLEEP => '0',
        WEA => wea, WEBWE => z8
      );
  end generate;
  g_h : if as_vhdl generate
    u : entity unisim.RAMB36E2
      generic map (
        DOA_REG => 0, DOB_REG => 0, INIT_FILE => "NONE",
        READ_WIDTH_A => 36, READ_WIDTH_B => 36,
        SIM_COLLISION_CHECK => "NONE",
        WRITE_MODE_A => "WRITE_FIRST", WRITE_MODE_B => "WRITE_FIRST",
        WRITE_WIDTH_A => 36, WRITE_WIDTH_B => 36
      )
      port map (
        CASDOUTA => open, CASDOUTB => open, CASDOUTPA => open, CASDOUTPB => open,
        CASOUTDBITERR => open, CASOUTSBITERR => open, DBITERR => open, SBITERR => open,
        DOUTADOUT => doa, DOUTBDOUT => open, DOUTPADOUTP => dopa, DOUTPBDOUTP => open,
        ECCPARITY => open, RDADDRECC => open,
        ADDRARDADDR => addra, ADDRBWRADDR => z15,
        ADDRENA => '0', ADDRENB => '0', CASDIMUXA => '0', CASDIMUXB => '0',
        CASDINA => z32, CASDINB => z32, CASDINPA => z4, CASDINPB => z4,
        CASDOMUXA => '0', CASDOMUXB => '0', CASDOMUXEN_A => '0', CASDOMUXEN_B => '0',
        CASINDBITERR => '0', CASINSBITERR => '0',
        CASOREGIMUXA => '0', CASOREGIMUXB => '0',
        CASOREGIMUXEN_A => '0', CASOREGIMUXEN_B => '0',
        CLKARDCLK => clka, CLKBWRCLK => '0',
        DINADIN => dia, DINBDIN => z32, DINPADINP => dipa, DINPBDINP => z4,
        ECCPIPECE => '0', ENARDEN => ena, ENBWREN => '0',
        INJECTDBITERR => '0', INJECTSBITERR => '0',
        REGCEAREGCE => '0', REGCEB => '0', RSTRAMARSTRAM => '0', RSTRAMB => '0',
        RSTREGARSTREG => '0', RSTREGB => '0', SLEEP => '0',
        WEA => wea, WEBWE => z8
      );
  end generate;
end architecture sim;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_eq_bram is
end entity tb_eq_bram;

architecture sim of tb_eq_bram is
  constant step : time := 5 ns;
  constant init00 : bit_vector(255 downto 0) :=
    X"0000000000000000000000000000000000000000000000000000000000001234";
  constant initp00 : bit_vector(255 downto 0) :=
    X"0000000000000000000000000000000000000000000000000000000000000003";
  constant srval : bit_vector(17 downto 0) := "100000000011111111";
  constant z14 : std_logic_vector(13 downto 0) := (others => '0');
  constant z16 : std_logic_vector(15 downto 0) := (others => '0');
  constant z2 : std_logic_vector(1 downto 0) := "00";
  constant z4 : std_logic_vector(3 downto 0) := "0000";

  signal clk_wf, clk_wfb, clk_rf, clk_nc, clk_9, clk_1, clk_4 : std_ulogic := '0';
  signal clk_reg, clk_ram, clk_pipe, clk_init, clk_sdp_a, clk_sdp_b : std_ulogic := '0';
  signal clk_36, clk_e2, clk_e36 : std_ulogic := '0';
  signal we : std_logic_vector(1 downto 0) := "00";
  signal web : std_logic_vector(3 downto 0) := "0000";
  signal addr, addrb : std_logic_vector(13 downto 0) := (others => '0');
  signal di, dib : std_logic_vector(15 downto 0) := (others => '0');
  signal dip, dipb : std_logic_vector(1 downto 0) := "00";
  signal rstram, rstreg : std_ulogic := '0';
  signal regce : std_ulogic := '1';
  signal en_b : std_ulogic := '0';

  signal wf_h, wf_v, wfb_h, wfb_v : std_logic_vector(15 downto 0);
  signal wfp_h, wfp_v, wfbp_h, wfbp_v : std_logic_vector(1 downto 0);
  signal rf_h, rf_v, nc_h, nc_v : std_logic_vector(15 downto 0);
  signal rfp_h, rfp_v, ncp_h, ncp_v : std_logic_vector(1 downto 0);
  signal b9_h, b9_v, b1_h, b1_v, b4_h, b4_v : std_logic_vector(15 downto 0);
  signal b9p_h, b9p_v, b1p_h, b1p_v, b4p_h, b4p_v : std_logic_vector(1 downto 0);
  signal rg_h, rg_v, rs_h, rs_v, rp_h, rp_v, ini_h, ini_v : std_logic_vector(15 downto 0);
  signal rgp_h, rgp_v, rsp_h, rsp_v, rpp_h, rpp_v, inip_h, inip_v : std_logic_vector(1 downto 0);
  signal sdp_h, sdp_v, sdpb_h, sdpb_v : std_logic_vector(15 downto 0);
  signal sdpp_h, sdpp_v, sdpbp_h, sdpbp_v : std_logic_vector(1 downto 0);
  signal e2_h, e2_v : std_logic_vector(15 downto 0);
  signal e2p_h, e2p_v : std_logic_vector(1 downto 0);

  signal di36 : std_logic_vector(31 downto 0) := (others => '0');
  signal dip36 : std_logic_vector(3 downto 0) := "0000";
  signal we36 : std_logic_vector(3 downto 0) := "0000";
  signal addr36 : std_logic_vector(15 downto 0) := (others => '0');
  signal addr36e : std_logic_vector(14 downto 0) := (others => '0');
  signal d36_h, d36_v, e36_h, e36_v : std_logic_vector(31 downto 0);
  signal p36_h, p36_v, e36p_h, e36p_v : std_logic_vector(3 downto 0);

  function from_vlog(v : std_logic_vector) return std_logic_vector is
    variable r : std_logic_vector(v'range);
  begin
    for i in v'range loop
      if v(i) = 'U' then
        r(i) := 'X';
      else
        r(i) := v(i);
      end if;
    end loop;
    return r;
  end function;

  function slv(n, w : natural) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(n, w));
  end function;

  function xx(n_lo : natural; lo : std_logic_vector) return std_logic_vector is
    variable r : std_logic_vector(15 downto 0) := (others => 'X');
  begin
    r(lo'length - 1 downto 0) := lo;
    return r;
  end function;
begin
  wf_h_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => true)
    port map (
      clka => clk_wf, clkb => clk_wfb, ena => '1', enb => en_b,
      wea => we, web => web, addra => addr, addrb => addrb,
      dia => di, dib => dib, dipa => dip, dipb => dipb,
      rstra => '0', rreg => '0', regce => '0',
      doa => wf_h, dob => wfb_h, dopa => wfp_h, dopb => wfbp_h
    );
  wf_v_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => false)
    port map (
      clka => clk_wf, clkb => clk_wfb, ena => '1', enb => en_b,
      wea => we, web => web, addra => addr, addrb => addrb,
      dia => di, dib => dib, dipa => dip, dipb => dipb,
      rstra => '0', rreg => '0', regce => '0',
      doa => wf_v, dob => wfb_v, dopa => wfp_v, dopb => wfbp_v
    );

  rf_h_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => true, cfg => 1)
    port map (
      clka => clk_rf, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2,
      rstra => '0', rreg => '0', regce => '0',
      doa => rf_h, dob => open, dopa => rfp_h, dopb => open
    );
  rf_v_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => false, cfg => 1)
    port map (
      clka => clk_rf, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2,
      rstra => '0', rreg => '0', regce => '0',
      doa => rf_v, dob => open, dopa => rfp_v, dopb => open
    );

  nc_h_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => true, cfg => 2)
    port map (
      clka => clk_nc, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2,
      rstra => '0', rreg => '0', regce => '0',
      doa => nc_h, dob => open, dopa => ncp_h, dopb => open
    );
  nc_v_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => false, cfg => 2)
    port map (
      clka => clk_nc, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2,
      rstra => '0', rreg => '0', regce => '0',
      doa => nc_v, dob => open, dopa => ncp_v, dopb => open
    );

  b9_h_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => true, cfg => 3)
    port map (
      clka => clk_9, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2,
      rstra => '0', rreg => '0', regce => '0',
      doa => b9_h, dob => open, dopa => b9p_h, dopb => open
    );
  b9_v_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => false, cfg => 3)
    port map (
      clka => clk_9, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2,
      rstra => '0', rreg => '0', regce => '0',
      doa => b9_v, dob => open, dopa => b9p_v, dopb => open
    );

  b1_h_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => true, cfg => 4)
    port map (
      clka => clk_1, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2,
      rstra => '0', rreg => '0', regce => '0',
      doa => b1_h, dob => open, dopa => b1p_h, dopb => open
    );
  b1_v_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => false, cfg => 4)
    port map (
      clka => clk_1, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2,
      rstra => '0', rreg => '0', regce => '0',
      doa => b1_v, dob => open, dopa => b1p_v, dopb => open
    );

  b4_h_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => true, cfg => 5)
    port map (
      clka => clk_4, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2,
      rstra => '0', rreg => '0', regce => '0',
      doa => b4_h, dob => open, dopa => b4p_h, dopb => open
    );
  b4_v_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => false, cfg => 5)
    port map (
      clka => clk_4, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2,
      rstra => '0', rreg => '0', regce => '0',
      doa => b4_v, dob => open, dopa => b4p_v, dopb => open
    );

  rg_h_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => true, cfg => 6)
    port map (
      clka => clk_reg, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2,
      rstra => '0', rreg => '0', regce => regce,
      doa => rg_h, dob => open, dopa => rgp_h, dopb => open
    );
  rg_v_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => false, cfg => 6)
    port map (
      clka => clk_reg, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2,
      rstra => '0', rreg => '0', regce => regce,
      doa => rg_v, dob => open, dopa => rgp_v, dopb => open
    );

  rs_h_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => true, cfg => 7)
    port map (
      clka => clk_ram, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2,
      rstra => rstram, rreg => '0', regce => '0',
      doa => rs_h, dob => open, dopa => rsp_h, dopb => open
    );
  rs_v_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => false, cfg => 7)
    port map (
      clka => clk_ram, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2,
      rstra => rstram, rreg => '0', regce => '0',
      doa => rs_v, dob => open, dopa => rsp_v, dopb => open
    );

  pipe_h_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => true, cfg => 8)
    port map (
      clka => clk_pipe, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2,
      rstra => '0', rreg => rstreg, regce => regce,
      doa => rp_h, dob => open, dopa => rpp_h, dopb => open
    );
  pipe_v_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => false, cfg => 8)
    port map (
      clka => clk_pipe, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2,
      rstra => '0', rreg => rstreg, regce => regce,
      doa => rp_v, dob => open, dopa => rpp_v, dopb => open
    );

  ini_h_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => true, cfg => 9)
    port map (
      clka => clk_init, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2,
      rstra => '0', rreg => '0', regce => '0',
      doa => ini_h, dob => open, dopa => inip_h, dopb => open
    );
  ini_v_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => false, cfg => 9)
    port map (
      clka => clk_init, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2,
      rstra => '0', rreg => '0', regce => '0',
      doa => ini_v, dob => open, dopa => inip_v, dopb => open
    );

  sdp_h_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => true, cfg => 10)
    port map (
      clka => clk_sdp_a, clkb => clk_sdp_b, ena => '1', enb => '1',
      wea => we, web => web, addra => addr, addrb => addrb,
      dia => di, dib => dib, dipa => dip, dipb => dipb,
      rstra => '0', rreg => '0', regce => '0',
      doa => sdp_h, dob => sdpb_h, dopa => sdpp_h, dopb => sdpbp_h
    );
  sdp_v_i : entity work.bram18_e1_wrap
    generic map (as_vhdl => false, cfg => 10)
    port map (
      clka => clk_sdp_a, clkb => clk_sdp_b, ena => '1', enb => '1',
      wea => we, web => web, addra => addr, addrb => addrb,
      dia => di, dib => dib, dipa => dip, dipb => dipb,
      rstra => '0', rreg => '0', regce => '0',
      doa => sdp_v, dob => sdpb_v, dopa => sdpp_v, dopb => sdpbp_v
    );

  e2_h_i : entity work.bram18_e2_wrap
    generic map (as_vhdl => true)
    port map (
      clka => clk_e2, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2, regce => '0',
      doa => e2_h, dob => open, dopa => e2p_h, dopb => open
    );
  e2_v_i : entity work.bram18_e2_wrap
    generic map (as_vhdl => false)
    port map (
      clka => clk_e2, clkb => '0', ena => '1', enb => '0',
      wea => we, web => z4, addra => addr, addrb => z14,
      dia => di, dib => z16, dipa => dip, dipb => z2, regce => '0',
      doa => e2_v, dob => open, dopa => e2p_v, dopb => open
    );

  d36_h_i : entity work.bram36_e1_wrap
    generic map (as_vhdl => true)
    port map (
      clka => clk_36, ena => '1', wea => we36, addra => addr36,
      dia => di36, dipa => dip36, doa => d36_h, dopa => p36_h
    );
  d36_v_i : entity work.bram36_e1_wrap
    generic map (as_vhdl => false)
    port map (
      clka => clk_36, ena => '1', wea => we36, addra => addr36,
      dia => di36, dipa => dip36, doa => d36_v, dopa => p36_v
    );

  e36_h_i : entity work.bram36_e2_wrap
    generic map (as_vhdl => true)
    port map (
      clka => clk_e36, ena => '1', wea => we36, addra => addr36e,
      dia => di36, dipa => dip36, doa => e36_h, dopa => e36p_h
    );
  e36_v_i : entity work.bram36_e2_wrap
    generic map (as_vhdl => false)
    port map (
      clka => clk_e36, ena => '1', wea => we36, addra => addr36e,
      dia => di36, dipa => dip36, doa => e36_v, dopa => e36p_v
    );

  process
    variable checks : integer := 0;

    procedure check(h, v, exp : std_logic_vector; what : string) is
    begin
      checks := checks + 1;
      assert h = exp
        report what & " vhdl=" & to_string(h) & " exp=" & to_string(exp)
        severity failure;
      assert h = from_vlog(v)
        report what & " vhdl=" & to_string(h) & " vlog=" & to_string(from_vlog(v))
        severity failure;
    end procedure;

    -- UltraScale reference stays X under NVC. See the file header.
    procedure check_e2(h, exp : std_logic_vector; what : string) is
    begin
      checks := checks + 1;
      assert h = exp
        report what & " vhdl=" & to_string(h) & " exp=" & to_string(exp)
        severity failure;
    end procedure;

    procedure edge(signal c : out std_ulogic) is
    begin
      c <= '0';
      wait for step;
      c <= '1';
      wait for step;
      wait for step;
    end procedure;

    procedure narrow(nbits : integer; val : std_logic_vector) is
      variable exp : std_logic_vector(15 downto 0) := (others => 'X');
      variable px : std_logic_vector(1 downto 0) := "XX";
    begin
      exp(nbits - 1 downto 0) := val;
      if nbits = 1 then
        check(b1_h, b1_v, exp, "1-bit");
        check(b1p_h, b1p_v, px, "1-bit parity");
      elsif nbits = 4 then
        check(b4_h, b4_v, exp, "4-bit");
        check(b4p_h, b4p_v, px, "4-bit parity");
      end if;
    end procedure;
  begin
    we <= "00";
    addr <= slv(0, 14);
    wait for 120 ns;

    -- 18-bit WRITE_FIRST, then a byte enable, then port B.
    we <= "11";
    di <= x"A5A5";
    dip <= "10";
    addr <= slv(0, 14);
    edge(clk_wf);
    check(wf_h, wf_v, x"A5A5", "wf write data");
    check(wfp_h, wfp_v, "10", "wf write parity");
    we <= "00";
    edge(clk_wf);
    check(wf_h, wf_v, x"A5A5", "wf read data");
    check(wfp_h, wfp_v, "10", "wf read parity");
    we <= "01";
    di <= x"B6B6";
    dip <= "01";
    edge(clk_wf);
    check(wf_h, wf_v, x"A5B6", "wf byte data");
    check(wfp_h, wfp_v, "11", "wf byte parity");

    en_b <= '1';
    web <= "0011";
    dib <= x"3C3C";
    dipb <= "11";
    addrb <= slv(16, 14);
    edge(clk_wfb);
    check(wfb_h, wfb_v, x"3C3C", "port B write data");
    check(wfbp_h, wfbp_v, "11", "port B write parity");
    en_b <= '0';
    we <= "00";
    addr <= slv(16, 14);
    edge(clk_wf);
    check(wf_h, wf_v, x"3C3C", "port A reads B");
    check(wfp_h, wfp_v, "11", "port A reads B parity");

    -- READ_FIRST returns the memory word, which is still zero. INIT_A
    -- has already put a non-zero value on the Verilog port.
    we <= "11";
    di <= x"A5A5";
    dip <= "10";
    addr <= slv(0, 14);
    edge(clk_rf);
    check(rf_h, rf_v, x"0000", "rf first data");
    check(rfp_h, rfp_v, "00", "rf first parity");
    di <= x"5A5A";
    dip <= "01";
    edge(clk_rf);
    check(rf_h, rf_v, x"A5A5", "rf old data");
    check(rfp_h, rfp_v, "10", "rf old parity");
    we <= "00";
    edge(clk_rf);
    check(rf_h, rf_v, x"5A5A", "rf read data");
    check(rfp_h, rfp_v, "01", "rf read parity");

    -- NO_CHANGE holds INIT_A through the write, then a read returns
    -- the word just stored.
    we <= "11";
    di <= x"A5A5";
    dip <= "10";
    addr <= slv(0, 14);
    edge(clk_nc);
    check(nc_h, nc_v, x"00FF", "nc hold data");
    check(ncp_h, ncp_v, "10", "nc hold parity");
    we <= "00";
    edge(clk_nc);
    check(nc_h, nc_v, x"A5A5", "nc read data");
    check(ncp_h, ncp_v, "10", "nc read parity");

    -- 9-bit, then the next byte must not clobber the first.
    we <= "01";
    di <= x"00A5";
    dip <= "01";
    addr <= slv(0, 14);
    edge(clk_9);
    check(b9_h, b9_v, xx(8, x"A5"), "9-bit data");
    check(b9p_h, b9p_v, "X1", "9-bit parity");
    addr <= slv(8, 14);
    di <= x"003C";
    dip <= "00";
    edge(clk_9);
    addr <= slv(0, 14);
    we <= "00";
    edge(clk_9);
    check(b9_h, b9_v, xx(8, x"A5"), "9-bit kept");
    check(b9p_h, b9p_v, "X1", "9-bit parity kept");

    we <= "01";
    di <= x"0001";
    addr <= slv(0, 14);
    edge(clk_1);
    narrow(1, "1");
    addr <= slv(1, 14);
    di <= x"0000";
    edge(clk_1);
    addr <= slv(0, 14);
    we <= "00";
    edge(clk_1);
    narrow(1, "1");

    we <= "01";
    di <= x"000A";
    addr <= slv(0, 14);
    edge(clk_4);
    narrow(4, x"A");
    addr <= slv(4, 14);
    di <= x"0005";
    edge(clk_4);
    addr <= slv(0, 14);
    we <= "00";
    edge(clk_4);
    narrow(4, x"A");

    -- Output register is one cycle behind the latch.
    we <= "11";
    di <= x"A5A5";
    dip <= "10";
    addr <= slv(0, 14);
    regce <= '1';
    edge(clk_reg);
    check(rg_h, rg_v, x"0000", "reg holds init");
    check(rgp_h, rgp_v, "00", "reg parity init");
    we <= "00";
    edge(clk_reg);
    check(rg_h, rg_v, x"A5A5", "reg follows");
    check(rgp_h, rgp_v, "10", "reg parity follows");

    -- RSTRAM forces SRVAL on the latch. The write still stores A5A5,
    -- so the following read returns it.
    we <= "11";
    di <= x"A5A5";
    dip <= "10";
    rstram <= '0';
    edge(clk_ram);
    rstram <= '1';
    we <= "00";
    edge(clk_ram);
    check(rs_h, rs_v, x"00FF", "rstram data");
    check(rsp_h, rsp_v, "10", "rstram parity");
    rstram <= '0';
    edge(clk_ram);
    check(rs_h, rs_v, x"A5A5", "rstram released");
    check(rsp_h, rsp_v, "10", "rstram released parity");

    -- RSTREG wins over REGCE being 0.
    we <= "11";
    di <= x"A5A5";
    dip <= "10";
    regce <= '1';
    rstreg <= '0';
    edge(clk_pipe);
    we <= "00";
    edge(clk_pipe);
    check(rp_h, rp_v, x"A5A5", "pipe loaded");
    regce <= '0';
    rstreg <= '1';
    edge(clk_pipe);
    check(rp_h, rp_v, x"00FF", "rstreg data");
    check(rpp_h, rpp_v, "10", "rstreg parity");

    -- INIT_00 / INITP_00 are the memory, visible on a read.
    we <= "00";
    addr <= slv(0, 14);
    edge(clk_init);
    check(ini_h, ini_v, x"1234", "init data");
    check(inip_h, inip_v, "11", "init parity");

    -- SDP 36: port B writes both data ports, port A reads them back.
    di <= x"1111";
    dib <= x"2222";
    dip <= "01";
    dipb <= "10";
    web <= "1111";
    addr <= slv(0, 14);
    addrb <= slv(0, 14);
    edge(clk_sdp_b);
    we <= "00";
    edge(clk_sdp_a);
    check(sdp_h, sdp_v, x"1111", "sdp low data");
    check(sdpb_h, sdpb_v, x"2222", "sdp high data");
    check(sdpp_h, sdpp_v, "01", "sdp low parity");
    check(sdpbp_h, sdpbp_v, "10", "sdp high parity");

    we36 <= "1111";
    di36 <= x"A5A55A5A";
    dip36 <= "1010";
    addr36 <= (others => '0');
    edge(clk_36);
    check(d36_h, d36_v, x"A5A55A5A", "ramb36 write");
    check(p36_h, p36_v, "1010", "ramb36 parity");
    we36 <= "0000";
    edge(clk_36);
    check(d36_h, d36_v, x"A5A55A5A", "ramb36 read");
    check(p36_h, p36_v, "1010", "ramb36 read parity");

    we <= "11";
    di <= x"A5A5";
    dip <= "10";
    addr <= slv(0, 14);
    edge(clk_e2);
    check_e2(e2_h, x"A5A5", "e2 write data");
    check_e2(e2p_h, "10", "e2 write parity");
    we <= "00";
    edge(clk_e2);
    check_e2(e2_h, x"A5A5", "e2 read data");
    check_e2(e2p_h, "10", "e2 read parity");

    we36 <= "1111";
    di36 <= x"A5A55A5A";
    dip36 <= "1010";
    addr36e <= (others => '0');
    edge(clk_e36);
    check_e2(e36_h, x"A5A55A5A", "e2-36 write");
    check_e2(e36p_h, "1010", "e2-36 parity");
    we36 <= "0000";
    edge(clk_e36);
    check_e2(e36_h, x"A5A55A5A", "e2-36 read");
    check_e2(e36p_h, "1010", "e2-36 read parity");

    report "PASS tb_eq_bram checks=" & integer'image(checks) severity note;
    finish(0);
  end process;
end architecture sim;
