# How-to: use the framework

The present framework allows to investigate thermo-hydraulic processes along the wastewater flow path, from the household tap to the wastewater treatment plant.

The file `MasterScript.py` is the coordinator of everything. With it, you

- Set up the parameters of the simulation you are about to run
- Run the "Residential" part of the network, that is
  - Simulate the wastewater flow and temperature of single households in the catchment for the simulation period using either a stitching procedure (already-simulated single-day thermo-hydrographs stitched together to form the entire period) or the simulating procedure (simulation from scratch using Modelica simulation).
  - Simulate the residential flow through lateral connections (from the building to the sewer network) using SWMM-HEAT
- Simulate the surface runoff with MINUHET
- Simulate the full catchment using SWMM-HEAT


## Run the thing - Stitching mode

- It is advisable to run `MasterScript.py` with Python 3.x

## Run the thing - Simulation mode

- Because we need to simulate each household from scratch using the JModelica software, you will need to run `MasterScript.py` with the Python 2.7 distribution included in the JModelica.org installation.
- If you do not have JModelica installed, you can get the installation setup from here:
  - https://polybox.ethz.ch/index.php/s/cGTJw9pOYCgTezF
- Run the code from the main folder, i.e. `Framework_template` and not from the `Codes` directory (all paths were defined relative to this main folder).

