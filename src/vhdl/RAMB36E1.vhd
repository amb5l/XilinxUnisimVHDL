-- RAMB36E1. Same memory map as RAMB18E1, twice the depth, with
-- widths through 72. ECC, cascade and INIT_FILE are not
-- modelled: the ECC and address-error ports stay 0, and
-- CASCADEOUT is data bit 0. No collision X and no $finish.
-- The Verilog specify paths are 100 ps and are not copied.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity RAMB36E1 is
  generic (
    DOA_REG : integer := 0;
    DOB_REG : integer := 0;
    EN_ECC_READ : boolean := FALSE;
    EN_ECC_WRITE : boolean := FALSE;
    INITP_00 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_01 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_02 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_03 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_04 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_05 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_06 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_07 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_08 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_09 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_0A : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_0B : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_0C : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_0D : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_0E : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_0F : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_00 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_01 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_02 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_03 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_04 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_05 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_06 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_07 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_08 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_09 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_0A : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_0B : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_0C : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_0D : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_0E : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_0F : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_10 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_11 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_12 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_13 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_14 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_15 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_16 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_17 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_18 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_19 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_1A : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_1B : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_1C : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_1D : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_1E : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_1F : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_20 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_21 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_22 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_23 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_24 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_25 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_26 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_27 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_28 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_29 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_2A : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_2B : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_2C : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_2D : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_2E : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_2F : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_30 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_31 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_32 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_33 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_34 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_35 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_36 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_37 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_38 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_39 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_3A : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_3B : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_3C : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_3D : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_3E : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_3F : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_40 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_41 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_42 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_43 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_44 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_45 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_46 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_47 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_48 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_49 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_4A : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_4B : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_4C : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_4D : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_4E : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_4F : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_50 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_51 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_52 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_53 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_54 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_55 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_56 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_57 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_58 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_59 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_5A : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_5B : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_5C : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_5D : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_5E : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_5F : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_60 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_61 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_62 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_63 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_64 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_65 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_66 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_67 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_68 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_69 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_6A : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_6B : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_6C : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_6D : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_6E : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_6F : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_70 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_71 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_72 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_73 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_74 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_75 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_76 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_77 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_78 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_79 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_7A : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_7B : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_7C : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_7D : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_7E : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_7F : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_A : bit_vector(35 downto 0) := X"000000000";
    INIT_B : bit_vector(35 downto 0) := X"000000000";
    INIT_FILE : string := "NONE";
    IS_CLKARDCLK_INVERTED : bit := '0';
    IS_CLKBWRCLK_INVERTED : bit := '0';
    IS_ENARDEN_INVERTED : bit := '0';
    IS_ENBWREN_INVERTED : bit := '0';
    IS_RSTRAMARSTRAM_INVERTED : bit := '0';
    IS_RSTRAMB_INVERTED : bit := '0';
    IS_RSTREGARSTREG_INVERTED : bit := '0';
    IS_RSTREGB_INVERTED : bit := '0';
    RAM_EXTENSION_A : string := "NONE";
    RAM_EXTENSION_B : string := "NONE";
    RAM_MODE : string := "TDP";
    RDADDR_COLLISION_HWCONFIG : string := "DELAYED_WRITE";
    READ_WIDTH_A : integer := 0;
    READ_WIDTH_B : integer := 0;
    RSTREG_PRIORITY_A : string := "RSTREG";
    RSTREG_PRIORITY_B : string := "RSTREG";
    SIM_COLLISION_CHECK : string := "ALL";
    SIM_DEVICE : string := "7SERIES";
    SRVAL_A : bit_vector(35 downto 0) := X"000000000";
    SRVAL_B : bit_vector(35 downto 0) := X"000000000";
    WRITE_MODE_A : string := "WRITE_FIRST";
    WRITE_MODE_B : string := "WRITE_FIRST";
    WRITE_WIDTH_A : integer := 0;
    WRITE_WIDTH_B : integer := 0
  );
  port (
    CASCADEOUTA : out std_ulogic;
    CASCADEOUTB : out std_ulogic;
    DBITERR : out std_ulogic;
    DOADO : out std_logic_vector(31 downto 0);
    DOBDO : out std_logic_vector(31 downto 0);
    DOPADOP : out std_logic_vector(3 downto 0);
    DOPBDOP : out std_logic_vector(3 downto 0);
    ECCPARITY : out std_logic_vector(7 downto 0);
    RDADDRECC : out std_logic_vector(8 downto 0);
    SBITERR : out std_ulogic;
    ADDRARDADDR : in std_logic_vector(15 downto 0);
    ADDRBWRADDR : in std_logic_vector(15 downto 0);
    CASCADEINA : in std_ulogic;
    CASCADEINB : in std_ulogic;
    CLKARDCLK : in std_ulogic;
    CLKBWRCLK : in std_ulogic;
    DIADI : in std_logic_vector(31 downto 0);
    DIBDI : in std_logic_vector(31 downto 0);
    DIPADIP : in std_logic_vector(3 downto 0);
    DIPBDIP : in std_logic_vector(3 downto 0);
    ENARDEN : in std_ulogic;
    ENBWREN : in std_ulogic;
    INJECTDBITERR : in std_ulogic;
    INJECTSBITERR : in std_ulogic;
    REGCEAREGCE : in std_ulogic;
    REGCEB : in std_ulogic;
    RSTRAMARSTRAM : in std_ulogic;
    RSTRAMB : in std_ulogic;
    RSTREGARSTREG : in std_ulogic;
    RSTREGB : in std_ulogic;
    WEA : in std_logic_vector(3 downto 0);
    WEBWE : in std_logic_vector(7 downto 0)
  );
end entity RAMB36E1;

architecture behav of RAMB36E1 is
  constant port_d : integer := 32;
  constant port_p : integer := 4;
  constant ra : integer := bram_pick_width(READ_WIDTH_A, READ_WIDTH_B);
  constant rb : integer := bram_pick_width(READ_WIDTH_B, READ_WIDTH_A);
  constant wa : integer := bram_pick_width(WRITE_WIDTH_A, WRITE_WIDTH_B);
  constant wb : integer := bram_pick_width(WRITE_WIDTH_B, WRITE_WIDTH_A);
  constant sdp : boolean := RAM_MODE = "SDP";
  signal gsr : std_ulogic := '1';
  signal doa_q : std_logic_vector(31 downto 0) := (others => 'X');
  signal dob_q : std_logic_vector(31 downto 0) := (others => 'X');
  signal dopa_q : std_logic_vector(3 downto 0) := (others => 'X');
  signal dopb_q : std_logic_vector(3 downto 0) := (others => 'X');
begin
  roc(gsr);
  DOADO <= doa_q;
  DOBDO <= dob_q;
  DOPADOP <= dopa_q;
  DOPBDOP <= dopb_q;

CASCADEOUTA <= doa_q(0);
CASCADEOUTB <= dob_q(0);
DBITERR <= '0';
SBITERR <= '0';
ECCPARITY <= (others => '0');
RDADDRECC <= (others => '0');

  process
    variable ready : boolean := false;
    variable mem : std_logic_vector(32767 downto 0);
    variable memp : std_logic_vector(4095 downto 0);
    variable pa, pb : std_ulogic := 'U';
    variable ca, cb : std_ulogic;
    variable ena_i, enb_i, rstra_i, rstrb_i : std_ulogic;
    variable rrega_i, rregb_i : std_ulogic;
    variable ld_a, rd_a, ld_b, rd_b : std_logic_vector(63 downto 0);
    variable lp_a, rp_a, lp_b, rp_b : std_logic_vector(7 downto 0);
    variable we0 : std_logic_vector(7 downto 0);
    variable wdi : std_logic_vector(63 downto 0);
    variable wdp : std_logic_vector(7 downto 0);
  begin
    if not ready then
      mem := (others => '0');
      memp := (others => '0');
    bram_load(mem, INIT_00, 0);
    bram_load(mem, INIT_01, 1);
    bram_load(mem, INIT_02, 2);
    bram_load(mem, INIT_03, 3);
    bram_load(mem, INIT_04, 4);
    bram_load(mem, INIT_05, 5);
    bram_load(mem, INIT_06, 6);
    bram_load(mem, INIT_07, 7);
    bram_load(mem, INIT_08, 8);
    bram_load(mem, INIT_09, 9);
    bram_load(mem, INIT_0A, 10);
    bram_load(mem, INIT_0B, 11);
    bram_load(mem, INIT_0C, 12);
    bram_load(mem, INIT_0D, 13);
    bram_load(mem, INIT_0E, 14);
    bram_load(mem, INIT_0F, 15);
    bram_load(mem, INIT_10, 16);
    bram_load(mem, INIT_11, 17);
    bram_load(mem, INIT_12, 18);
    bram_load(mem, INIT_13, 19);
    bram_load(mem, INIT_14, 20);
    bram_load(mem, INIT_15, 21);
    bram_load(mem, INIT_16, 22);
    bram_load(mem, INIT_17, 23);
    bram_load(mem, INIT_18, 24);
    bram_load(mem, INIT_19, 25);
    bram_load(mem, INIT_1A, 26);
    bram_load(mem, INIT_1B, 27);
    bram_load(mem, INIT_1C, 28);
    bram_load(mem, INIT_1D, 29);
    bram_load(mem, INIT_1E, 30);
    bram_load(mem, INIT_1F, 31);
    bram_load(mem, INIT_20, 32);
    bram_load(mem, INIT_21, 33);
    bram_load(mem, INIT_22, 34);
    bram_load(mem, INIT_23, 35);
    bram_load(mem, INIT_24, 36);
    bram_load(mem, INIT_25, 37);
    bram_load(mem, INIT_26, 38);
    bram_load(mem, INIT_27, 39);
    bram_load(mem, INIT_28, 40);
    bram_load(mem, INIT_29, 41);
    bram_load(mem, INIT_2A, 42);
    bram_load(mem, INIT_2B, 43);
    bram_load(mem, INIT_2C, 44);
    bram_load(mem, INIT_2D, 45);
    bram_load(mem, INIT_2E, 46);
    bram_load(mem, INIT_2F, 47);
    bram_load(mem, INIT_30, 48);
    bram_load(mem, INIT_31, 49);
    bram_load(mem, INIT_32, 50);
    bram_load(mem, INIT_33, 51);
    bram_load(mem, INIT_34, 52);
    bram_load(mem, INIT_35, 53);
    bram_load(mem, INIT_36, 54);
    bram_load(mem, INIT_37, 55);
    bram_load(mem, INIT_38, 56);
    bram_load(mem, INIT_39, 57);
    bram_load(mem, INIT_3A, 58);
    bram_load(mem, INIT_3B, 59);
    bram_load(mem, INIT_3C, 60);
    bram_load(mem, INIT_3D, 61);
    bram_load(mem, INIT_3E, 62);
    bram_load(mem, INIT_3F, 63);
    bram_load(mem, INIT_40, 64);
    bram_load(mem, INIT_41, 65);
    bram_load(mem, INIT_42, 66);
    bram_load(mem, INIT_43, 67);
    bram_load(mem, INIT_44, 68);
    bram_load(mem, INIT_45, 69);
    bram_load(mem, INIT_46, 70);
    bram_load(mem, INIT_47, 71);
    bram_load(mem, INIT_48, 72);
    bram_load(mem, INIT_49, 73);
    bram_load(mem, INIT_4A, 74);
    bram_load(mem, INIT_4B, 75);
    bram_load(mem, INIT_4C, 76);
    bram_load(mem, INIT_4D, 77);
    bram_load(mem, INIT_4E, 78);
    bram_load(mem, INIT_4F, 79);
    bram_load(mem, INIT_50, 80);
    bram_load(mem, INIT_51, 81);
    bram_load(mem, INIT_52, 82);
    bram_load(mem, INIT_53, 83);
    bram_load(mem, INIT_54, 84);
    bram_load(mem, INIT_55, 85);
    bram_load(mem, INIT_56, 86);
    bram_load(mem, INIT_57, 87);
    bram_load(mem, INIT_58, 88);
    bram_load(mem, INIT_59, 89);
    bram_load(mem, INIT_5A, 90);
    bram_load(mem, INIT_5B, 91);
    bram_load(mem, INIT_5C, 92);
    bram_load(mem, INIT_5D, 93);
    bram_load(mem, INIT_5E, 94);
    bram_load(mem, INIT_5F, 95);
    bram_load(mem, INIT_60, 96);
    bram_load(mem, INIT_61, 97);
    bram_load(mem, INIT_62, 98);
    bram_load(mem, INIT_63, 99);
    bram_load(mem, INIT_64, 100);
    bram_load(mem, INIT_65, 101);
    bram_load(mem, INIT_66, 102);
    bram_load(mem, INIT_67, 103);
    bram_load(mem, INIT_68, 104);
    bram_load(mem, INIT_69, 105);
    bram_load(mem, INIT_6A, 106);
    bram_load(mem, INIT_6B, 107);
    bram_load(mem, INIT_6C, 108);
    bram_load(mem, INIT_6D, 109);
    bram_load(mem, INIT_6E, 110);
    bram_load(mem, INIT_6F, 111);
    bram_load(mem, INIT_70, 112);
    bram_load(mem, INIT_71, 113);
    bram_load(mem, INIT_72, 114);
    bram_load(mem, INIT_73, 115);
    bram_load(mem, INIT_74, 116);
    bram_load(mem, INIT_75, 117);
    bram_load(mem, INIT_76, 118);
    bram_load(mem, INIT_77, 119);
    bram_load(mem, INIT_78, 120);
    bram_load(mem, INIT_79, 121);
    bram_load(mem, INIT_7A, 122);
    bram_load(mem, INIT_7B, 123);
    bram_load(mem, INIT_7C, 124);
    bram_load(mem, INIT_7D, 125);
    bram_load(mem, INIT_7E, 126);
    bram_load(mem, INIT_7F, 127);
    bram_load(memp, INITP_00, 0);
    bram_load(memp, INITP_01, 1);
    bram_load(memp, INITP_02, 2);
    bram_load(memp, INITP_03, 3);
    bram_load(memp, INITP_04, 4);
    bram_load(memp, INITP_05, 5);
    bram_load(memp, INITP_06, 6);
    bram_load(memp, INITP_07, 7);
    bram_load(memp, INITP_08, 8);
    bram_load(memp, INITP_09, 9);
    bram_load(memp, INITP_0A, 10);
    bram_load(memp, INITP_0B, 11);
    bram_load(memp, INITP_0C, 12);
    bram_load(memp, INITP_0D, 13);
    bram_load(memp, INITP_0E, 14);
    bram_load(memp, INITP_0F, 15);
      bram_from_attr(INIT_A, ra, ld_a, lp_a);
      rd_a := ld_a;
      rp_a := lp_a;
      bram_from_attr(INIT_B, rb, ld_b, lp_b);
      rd_b := ld_b;
      rp_b := lp_b;
      ready := true;
    end if;

    ena_i := vxor(ENARDEN, IS_ENARDEN_INVERTED);
    enb_i := vxor(ENBWREN, IS_ENBWREN_INVERTED);
    rstra_i := vxor(RSTRAMARSTRAM, IS_RSTRAMARSTRAM_INVERTED);
    rstrb_i := vxor(RSTRAMB, IS_RSTRAMB_INVERTED);
    rrega_i := vxor(RSTREGARSTREG, IS_RSTREGARSTREG_INVERTED);
    rregb_i := vxor(RSTREGB, IS_RSTREGB_INVERTED);
    ca := vxor(CLKARDCLK, IS_CLKARDCLK_INVERTED);
    cb := vxor(CLKBWRCLK, IS_CLKBWRCLK_INVERTED);

    if gsr = '1' then
      bram_from_attr(INIT_A, ra, ld_a, lp_a);
      rd_a := ld_a;
      rp_a := lp_a;
      bram_from_attr(INIT_B, rb, ld_b, lp_b);
      rd_b := ld_b;
      rp_b := lp_b;
    else
      if verilog_posedge(pa, ca) then
        if DOA_REG = 1 then
          bram_take_reg(rd_a, rp_a, ld_a, lp_a, REGCEAREGCE, rrega_i,
                        RSTREG_PRIORITY_A, SRVAL_A, ra);
        end if;
        if sdp then
          we0 := (others => '0');
          bram_access(mem, memp, ADDRARDADDR, DIADI, DIPADIP, we0,
                      ena_i, rstra_i, bram_mode(WRITE_MODE_A), ra, ra,
                      SRVAL_A, ld_a, lp_a);
        else
          bram_access(mem, memp, ADDRARDADDR, DIADI, DIPADIP, WEA,
                      ena_i, rstra_i, bram_mode(WRITE_MODE_A), ra, wa,
                      SRVAL_A, ld_a, lp_a);
        end if;
      end if;
      if verilog_posedge(pb, cb) then
        if sdp then
          if enb_i = '1' then
            wdi := (others => '0');
            wdp := (others => '0');
            if bram_dwidth(wb) > port_d then
              wdi(port_d - 1 downto 0) := DIADI;
              wdi(2 * port_d - 1 downto port_d) := DIBDI;
              wdp(port_p - 1 downto 0) := DIPADIP;
              wdp(2 * port_p - 1 downto port_p) := DIPBDIP;
              bram_write(mem, memp, ADDRBWRADDR, wdi, wdp, WEBWE, wb);
            else
              bram_write(mem, memp, ADDRBWRADDR, DIBDI, DIPBDIP, WEBWE, wb);
            end if;
          end if;
        else
          if DOB_REG = 1 then
            bram_take_reg(rd_b, rp_b, ld_b, lp_b, REGCEB, rregb_i,
                          RSTREG_PRIORITY_B, SRVAL_B, rb);
          end if;
          bram_access(mem, memp, ADDRBWRADDR, DIBDI, DIPBDIP, WEBWE,
                      enb_i, rstrb_i, bram_mode(WRITE_MODE_B), rb, wb,
                      SRVAL_B, ld_b, lp_b);
        end if;
      end if;
    end if;
    pa := ca;
    pb := cb;

    if sdp then
      if DOA_REG = 1 then
        doa_q <= rd_a(port_d - 1 downto 0);
        dopa_q <= rp_a(port_p - 1 downto 0);
        dob_q <= rd_a(2 * port_d - 1 downto port_d);
        dopb_q <= rp_a(2 * port_p - 1 downto port_p);
      else
        doa_q <= ld_a(port_d - 1 downto 0);
        dopa_q <= lp_a(port_p - 1 downto 0);
        dob_q <= ld_a(2 * port_d - 1 downto port_d);
        dopb_q <= lp_a(2 * port_p - 1 downto port_p);
      end if;
    else
      if DOA_REG = 1 then
        doa_q <= rd_a(port_d - 1 downto 0);
        dopa_q <= rp_a(port_p - 1 downto 0);
      else
        doa_q <= ld_a(port_d - 1 downto 0);
        dopa_q <= lp_a(port_p - 1 downto 0);
      end if;
      if DOB_REG = 1 then
        dob_q <= rd_b(port_d - 1 downto 0);
        dopb_q <= rp_b(port_p - 1 downto 0);
      else
        dob_q <= ld_b(port_d - 1 downto 0);
        dopb_q <= lp_b(port_p - 1 downto 0);
      end if;
    end if;
    wait on CLKARDCLK, CLKBWRCLK, gsr;
  end process;
end architecture behav;
