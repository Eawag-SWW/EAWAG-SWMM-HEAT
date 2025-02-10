# EAWAG-SWMM-HEAT
Repository for the Eawag version of SWMM-HEAT, a thermal-hydrological model to simulate heat- and hydraulic processes in sewers.

![Image of SWMM-HEAT](https://github.com/Eawag-SWW/EAWAG-SWMM-HEAT/blob/main/swmm_temp.png)

# SWMM-HEAT Build and Input Files

## SWMM-HEAT Build files

SWMM-HEAT_Build folder contains the necessary files for performing Thermal-Hydraulic simulations. No installation is required.
SWMM-HEAT is executed from command line and it is called 
using the EPA-SWMM format:

swmmT_v1.001.exe "name_of_file".inp "name_of_file".rpt "name_of_file".out

## SWMM-HEAT Input Files

SWMM-HEAT users will find that input files are very similar to EPA-SWMM input files, however it has several differences.

**OPTIONS SECTION:**  
TEMP_MODEL &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; 1 &nbsp; &nbsp;  &nbsp; &nbsp;  &nbsp; &nbsp; !Thermal dynamic simulation activated  
DENSITY &nbsp; &nbsp; &nbsp;  &nbsp; &nbsp; &nbsp;  &nbsp; &nbsp; &nbsp;  &nbsp; &nbsp; &nbsp; 1000.0 &nbsp; &nbsp; !Density of water in kg/m^3  
SPEC_HEAT_CAPACITY &nbsp; &nbsp; 4190 &nbsp; &nbsp; !Specific Heat capacity of water (J·kg^(−1)·K^(−1))  
HUMIDITY &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; 0.72 &nbsp; &nbsp; !Relative humidity in the sewage system   <br />	 										
EXT_UNIT &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; T &nbsp; &nbsp; !Use of temperature relate units  
GLOBTPAT &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; 1 &nbsp; &nbsp; !if we use the same soil and air temperature patterns in all the system GLOBPAT=1. Improves the computing efficiency of the code.  
ASCII_OUT &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; 1 &nbsp; &nbsp; !Creates an ASCII output file  (1=on, 0=off)  

**CONDUITS SECTION:**

Condouits require 5 extra parameters:

* Thickness of conduit (m) "Thick"
* Thermal conductivity pipe (W·m^(−1)·K^(−1)) "Tcp"
* Thermal conductivity soil (W·m^(−1)·K^(−1)) "Tcs"
* Density of soil (kg·m^(−3)) "Ds"
* Specific heat capacity of soil (J·kg^(−1)·K^(−1)) "Cps"
* Air Temperature Pattern (A_GN) "Atp"
* Soil Temperature Pattern (S_GN) "Stp"

Example:   
;;Name           From Node        To Node          Length     Roughness  InOffset   OutOffset  InitFlow   MaxFlow    Thick Tcp Tcs Ds Cps Atp Stp 			 <br />				
;;------------------------------------------------------------------------------------------------------------------------------      <br />
init_pos2	&nbsp; &nbsp; init  &nbsp; &nbsp;        	pos2 &nbsp; &nbsp; 194.96 &nbsp; &nbsp;  0.011764706 &nbsp; &nbsp; 0	&nbsp; &nbsp; 0 &nbsp; &nbsp;	0	&nbsp; &nbsp; 0	&nbsp; &nbsp; 0.1	&nbsp; &nbsp; 2.3	&nbsp; &nbsp; 0.7	&nbsp; &nbsp; 350	&nbsp; &nbsp; 350   &nbsp; &nbsp; "A_GN"	&nbsp; &nbsp; "S_GN"                     <br />

**WTEMPERATURE SECTION:**

Parameters for water temperature simulations

Example:

[WTEMPERATURE]																
;;Name	&nbsp; &nbsp;  Units	&nbsp; &nbsp;   Crain 	&nbsp; &nbsp; Cgw  	&nbsp; &nbsp; Crdii 	&nbsp; &nbsp;   Kdecay  	&nbsp; &nbsp;    Cdwf 	&nbsp; &nbsp;   Cinit    <br />
;;;----------------------------------------------------------------------------------------------------------				<br />		
WTEMPERATURE &nbsp; &nbsp;   CELSIUS &nbsp; &nbsp;  0.0  &nbsp; &nbsp;    0.0   &nbsp; &nbsp;    0.0   &nbsp; &nbsp;   0.0     &nbsp; &nbsp;     0    &nbsp; &nbsp;       12 	

     
**PATTERNS SECTION:**

Patterns for water temperature simulations. Includes air and soil temperature patterns (Monthly, Weekly, Daily). Temperatures in Celcius.

Example:


;;;Name          	Type      	Multipliers	 <br />	
;;;-----------------------------------------------------	 <br />	
S_GN  &nbsp; &nbsp;         MONTHLY &nbsp; &nbsp; &nbsp;    6.3   6.3  6.3  6.3 12.27 12.5							 <br />										
S_GN    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;     &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;             19.72 17.93 15.21 12.38 8.15  10 						 <br />											
;																 <br />	
A_GN    &nbsp; &nbsp;           MONTHLY &nbsp; &nbsp; &nbsp;    7.24 7.24  7.24  7.24 12.27 23						 <br />											
A_GN    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;  &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;                    18.01 17.96 17.40 16.61 10.32 5		 <br />	


**LICENSE:**

This code is public domain under CCO License


# Tutorial

A SWMM-HEAT model that reproduces the thermal-hydraulic dynamics of a 1.8km sewer line in Rumlang, Switzerland is located in the Tutorial folder. The folder includes a description of the simulation experiment, two folders with the data needed for the simulations and a Python script for reading the output file.
