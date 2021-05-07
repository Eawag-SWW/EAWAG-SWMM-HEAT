# EAWAG-SWMM-HEAT
Repository for the Eawag version of SWMM-HEAT, a thermal-hydrological model to simulate heat- and hydraulic processes in sewers.
# SWMM-HEAT Build and Input Files

## SWMM-HEAT Build files

SWMM-HEAT_Build folder contains the necessary files for performing Thermal-Hydraulic simulations. No installation is required.
SWMM-HEAT is executed from command line and it is called 
using the EPA-SWMM format:

swmmT_v1.001.exe "name_of_file".inp "name_of_file".rpt "name_of_file".out


## SWMM-HEAT Input Files

SWMM-HEAT users will find that input files are very similar to EPA-SWMM input files, however it has several differences.

OPTIONS SECTION:
TEMP_MODEL           1          !Thermal dynamic simulation activated
DENSITY              1000.0     !Density of water in kg/m^3
SPEC_HEAT_CAPACITY   4190       !Specific Heat capacity of water (J·kg^(−1)·K^(−1))
HUMIDITY             0.72	!Relative humidity in the sewage system				 										
EXT_UNIT             T	        !Use of temperature relate units
GLOBTPAT             1          !if we use the same soil and air temperature patterns in all the system GLOBPAT=1. It improves the computing efficiency of the code.
ASCII_OUT            1          !Creates an ASCII output file  (1=on, 0=off)

CONDUITS SECTION:

Condouits require 5 extra parameters:
_Thickness of conduit (m)
_Thermal conductivity pipe (W·m^(−1)·K^(−1))
_Thermal conductivity soil (W·m^(−1)·K^(−1))
_Density of soil (kg·m^(−3))
_specific heat capacity of soil (J·kg^(−1)·K^(−1))
_Air Temperature Pattern
_Soil Temperature Pattern

Example:
;;Name           From Node        To Node          Length     Roughness  InOffset   OutOffset  InitFlow   MaxFlow   							
;;-------------- ---------------- ---------------- ---------- ---------- ---------- ---------- ---------- ----------
init_pos2	init         	pos2         194.96  		0.011764706	0	0	0	0	0.1	2.3	0.7	350	350   "A_GN"	"S_GN"

WTEMPERATURE SECTION:

Parameters for water temperature simulations

Example:

[WTEMPERATURE]																
;;Name           Units  Crain      Cgw        Crdii      Kdecay         Cdwf       Cinit     																
;;-------------- ------ ---------- ---------- ---------- ----------  ---------- ----------																
WTEMPERATURE      CELSIUS 0.0        0.0        0.0        0.0              0         12 	


PATTERNS SECTION:

Patterns for water temperature simulations. Includes air and soil temperature patterns (Monthly, Weekly, Daily). Temperatures in Celcius.

Example:


;;;Name          	Type      	Multipliers
;;;--------------	----------	-----------
;; refine this according to depth															
S_GN         MONTHLY    6.3   6.3  6.3  6.3 12.27 12.5															
S_GN                    19.72 17.93 15.21 12.38 8.15  10 															
;															
A_GN             MONTHLY    7.24 7.24  7.24  7.24 12.27 23															
A_GN                        18.01 17.96 17.40 16.61 10.32 5	
