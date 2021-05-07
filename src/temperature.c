//-----------------------------------------------------------------------------
//   temperature.c
//
//   Project:  EPA SWMM5
//   Version:  5.1
//   Date:     09/24/15   (Build 5.1.015)
//   Author:   A. Figueroa
//
//   Water temperature functions.
//
//   Build 5.1.008:
//   - Pollutant mass lost to seepage flow added to mass balance totals.
//   - Pollutant concen. increased when evaporation occurs.
//
//   Build 5.1.009:
//   - Criterion for dry link/storage node changed to avoid concen. blowup.
//
//   Build 5.1.010:
//   - Entire module re-written to be more compact and easier to follow.
//   - Neglible depth limit replaced with a negligible volume limit.
//
//-----------------------------------------------------------------------------
#define _CRT_SECURE_NO_DEPRECATE

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include "headers.h"

//-----------------------------------------------------------------------------
//  Constants
//-----------------------------------------------------------------------------

static const double ZeroVolume = 0.0353147; // 1 liter in ft3
//-----------------------------------------------------------------------------
//  External functions (declared in funcs.h)
//-----------------------------------------------------------------------------
//  temprout_init            (called by swmm_start)
//  Temprout_execute         (called by routing_execute)

//-----------------------------------------------------------------------------
//  Function declarations
//-----------------------------------------------------------------------------
static void  findLinkMassFlowT(int i, double tStep);
static void  findNodeTemp(int j);
static void  findLinkTemp(int i, double tStep, int month, int day, int hour);
static void  findLinkTemps(int i, double tStep, double airt, double soilt);
static void  findSFLinkTemp(int i, double qSeep, double fEvap, double tStep);
static void  findStorageTemp(int j, double tStep, int month, int day, int hour);
static void  findStorageTemps(int j, double tStep, double airt, double soilt);
static void  updateHRTT(int j, double v, double q, double tStep);
static double getMixedTemp(double c, double v1, double wIn, double qIn,
	double tStep);
static double getReactedTemp(double oldTemp, int i, double tStep, int month, int day, int hour);
static double getReactedTemps(double oldTemp, int i, double tStep, double airt, double soilt);
static double getReactedTempStNode(double oldTemp, int j, double tStep, int month, int day, int hour);
static double getReactedTempStNodes(double oldTemp, int j, double tStep, double airt, double soilt);
static double getWettedArea(TTable* table, double d);
//=============================================================================

void    temprout_init()
//
//  Input:   none
//  Output:  none
//  Purpose: initializes water temperature in all nodes and links.
//
{
	int     i, isWet;
	double  c;

	for (i = 0; i < Nobjects[NODE]; i++)
	{
		isWet = (Node[i].newDepth > FUDGE);

				c =- NAN; // set temperature to NaN, because 0 is a valid temperatur value
			if (isWet) c = WTemperature.initTemp;
			Node[i].oldTemp = c;
			Node[i].newTemp = c;

		if (Node[i].type == STORAGE)
		{
			int k = Node[i].subIndex;
			// calculate the penetration depth for each storage node
			Storage[k].penDepth = sqrt(Storage[k].kSoil / (0.0000727220 * (Storage[k].densitySoil * Storage[k].specHcSoil))) / UCF(LENGTH);
		}
	}

	for (i = 0; i < Nobjects[LINK]; i++)
	{
		isWet = (Link[i].newDepth > FUDGE);
		//	if (strcmp(QualUnitsWords[Temperature.units], "CELSIUS") == 0 && TempModel.active == 1)
				c =- NAN; // set temperature to NaN, because 0 is a valid temperatur value
		//	else
		//		c = 0.0;
			if (isWet) c = WTemperature.initTemp;
			Link[i].oldTemp = c;
			Link[i].newTemp = c;

		int k = Link[i].subIndex;
		// calculate the penetration depth for each conduit
		Conduit[k].penDepth = sqrt(Conduit[k].kSoil / (0.0000727220 * Conduit[k].densitySoil * Conduit[k].specHcSoil)) / UCF(LENGTH);
	}
}

//=============================================================================

void temprout_execute(double tStep)
//
//  Input:   tStep = routing time step (sec)
//  Output:  none
//  Purpose: calculate water temperature trough the drainage
//           network over the current time step.
//
{
	int    i, j;
	double qIn, vAvg;
	double airt, soilt;

	// get the current month of simulation
	DateTime currentDate = getDateTime(NewRoutingTime);
	int month = datetime_monthOfYear(currentDate) - 1;
	int day   = datetime_dayOfWeek(currentDate) - 1;
    int hour  = datetime_hourOfDay(currentDate);
	if (TempModel.GTPattern == 1)
	{
		airt = inflow_getPatternFactor((int)Conduit[Link[0].subIndex].airPat, month, day, hour
	);
		soilt= inflow_getPatternFactor((int)Conduit[Link[0].subIndex].soilPat, month, day, hour
		);
	}

	// --- find mass flow each link contributes to its downstream node
	for (i = 0; i < Nobjects[LINK]; i++) findLinkMassFlowT(i, tStep);

	// --- find new water temperature at each node  
	if (TempModel.GTPattern == 0)
	{
		for (j = 0; j < Nobjects[NODE]; j++)
		{
			// --- get node inflow and average volume
			qIn = Node[j].inflow;
			vAvg = (Node[j].oldVolume + Node[j].newVolume) / 2.0;

			// --- find new temperature at the node 
			if (Node[j].type == STORAGE || Node[j].oldVolume > FUDGE)
			{
				findStorageTemp(j, tStep, month, day, hour);
			}
			else findNodeTemp(j);
		}
	}
	else if (TempModel.GTPattern == 1)
	{
		for (j = 0; j < Nobjects[NODE]; j++)
		{
			// --- get node inflow and average volume
			qIn = Node[j].inflow;
			vAvg = (Node[j].oldVolume + Node[j].newVolume) / 2.0;

			// --- find new temperature at the node 
			if (Node[j].type == STORAGE || Node[j].oldVolume > FUDGE)
			{
			findStorageTemps(j, tStep, airt, soilt);
			}
			else findNodeTemp(j);
		}
	}

	// --- find new water temperature in each link
	if (TempModel.GTPattern == 0)
		for (i = 0; i < Nobjects[LINK]; i++) findLinkTemp(i, tStep, month, day, hour);
	else if (TempModel.GTPattern == 1)
		for (i = 0; i < Nobjects[LINK]; i++) findLinkTemps(i, tStep, airt, soilt);
}

//=============================================================================

double getMixedTemp(double c, double v1, double wIn, double qIn, double tStep)
//
//  Input:   c = Temperature in reactor at start of time step 
//           v1 = volume in reactor at start of time step (ft3)
//           wIn = mass inflow rate (mass/sec)
//           qIn = flow inflow rate (cfs)
//           tStep = time step (sec)
//  Output:  returns temperature at end of time step 
//  Purpose: finds temperature within a completely mixed reactor.
//
{
	double vIn, cIn, cMax;

	// --- if no inflow then reactor temperature is unchanged
	if (qIn <= ZERO) return c;
	// --- compute temperature of any inflow
	vIn = qIn * tStep;
	cIn = wIn * tStep / vIn;

	// --- mixture temperature can't exceed either original or inflow concen.
	cMax = MAX(c, cIn);

	// --- mix inflow with current reactor temperature
	c = (c * v1 + wIn * tStep) / (v1 + vIn);
	c = MIN(c, cMax);
	c = MAX(c, 0.0);
	return c;
}

//=============================================================================

void findLinkMassFlowT(int i, double tStep)
//
//  Input:   i = link index
//           tStep = time step (sec)
//  Output:  none
//  Purpose: adds temperature-mass flow out of link to the total
//           accumulation at the link's downstream node.
//
//  Note:    Node[].newTemp[], the accumulator variable, already contains
//           contributions from runoff and other external inflows from
//           calculations made in routing_execute().
{
	int    j;// , p;
	double qLink, w;

	// --- find inflow to downstream node
	qLink = Link[i].newFlow;

	// --- identify index of downstream node
	j = Link[i].node2;
	if (qLink < 0.0) j = Link[i].node1;
	qLink = fabs(qLink);

			// --- temporarily accumulate inflow load in Node[j].newTemp
			if (!isnan(Link[i].oldTemp)) // do not consider NaN values
			{
				w = qLink * Link[i].oldTemp;
				Node[j].newTemp += w;

			}
			else
			{
				w = 0.0;
			}
			// --- update total temperature/heat transported by link
		Link[i].totalLoadT += w * tStep;
	//}
}
//=============================================================================

void findNodeTemp(int j)
//
//  Input:   j = node index
//  Output:  none
//  Purpose: finds new temperature in a node with no storage volume.
//
{
	double qNode;

	// --- if there is flow into node then  = mass inflow/node flow
	qNode = Node[j].inflow;
	if (qNode > ZERO )
	{

			Node[j].newTemp /= qNode;
	}
	// set temperature to NaN, because 0 is a valid temperatur value
	else
		Node[j].newTemp = -NAN;

}

//=============================================================================

void findLinkTemp(int i, double tStep, int month, int day, int hour)
//
//  Input:   i = link index
//           tStep = routing time step (sec)
//  Output:  none
//  Purpose: finds new temperature in a link at end of the current time step.
//
{
	int    j,             // upstream node index
		k;             // conduit index
	double wIn,           // temperature mass inflow rate 
		qIn,              // inflow rate (cfs)
		qSeep,            // rate of seepage loss (cfs)
		v1,               // link volume at start of time step (ft3)
		v2,               // link volume at end of time step (ft3)
		c1,               // current temperature within link 
		c2,               // new temperature within link 
		vEvap,            // volume lost to evaporation (ft3)
		vLosses,          // evap. + seepage volume loss (ft3)
		fEvap,            // evaporation concentration factor
		barrels;          // number of barrels in conduit

 // --- identify index of upstream node
	j = Link[i].node1;
	if (Link[i].newFlow < 0.0) j = Link[i].node2;

	// --- link temperature is that of upstream node when
	//     link is not a conduit or is a dummy link or retention time less than 10secs
	if (Link[i].type != CONDUIT || Link[i].xsect.type == DUMMY || Link[i].newVolume / Link[i].newFlow < 10.0)
	{
		Link[i].newTemp = Node[j].newTemp;
		return;
	}

	// --- get flow rates and evaporation loss
	k = Link[i].subIndex;
	barrels = Conduit[k].barrels;
	qIn = fabs(Conduit[k].q1) * barrels;
	qSeep = Conduit[k].seepLossRate * barrels;
	vEvap = Conduit[k].evapLossRate * barrels * tStep;

	// --- get starting and ending volumes
	v1 = Link[i].oldVolume;
	v2 = Link[i].newVolume;
	vLosses = qSeep * tStep + vEvap;

	// --- compute factor by which concentrations are increased due to
	//     evaporation loss 
	fEvap = 1.0;
	if (vEvap > 0.0 && v1 > ZeroVolume) fEvap += vEvap / v1;

	// --- Steady Flow routing requires special treatment
	if (RouteModel == SF)
	{
		findSFLinkTemp(i, qSeep, fEvap, tStep);
		return;
	}

	// --- adjust inflow to compensate for volume change under Dynamic
	//     Wave routing (which produces just a single (out)flow rate
	//     for a conduit)
	if (RouteModel == DW)
	{
		qIn = qIn + (v2 + vLosses - v1) / tStep;
		qIn = MAX(qIn, 0.0);
	}

		// --- start with temperature at start of time step
	c1 = Link[i].oldTemp;
	if (!isnan(c1)) {
		// --- update mass balance accounting for seepage loss
		massbal_addSeepageLossT(qSeep * c1);

		// --- increase concen. by evaporation factor
		c1 *= fEvap;
			// --- adjust temperature by heat exchange processes
		c2 = getReactedTemp(c1, i, tStep, month, day, hour);
		// --- mix resulting contents with inflow from upstream node
		if (!isnan(Node[j].newTemp)) { // do not consider NaN values
			wIn = Node[j].newTemp * qIn;
			c2 = getMixedTemp(c2, v1, wIn, qIn, tStep);
		}
	}
	else{
		if (!isnan(Node[j].newTemp)) {
			c2 = Node[j].newTemp;
		}
		else c2 = NAN;
    }
		// --- set concen. to zero if remaining volume is negligible
		if (v2 < ZeroVolume)
		{
			massbal_addToFinalStorageT(c2 * v2);

			// set temperature to NaN, because 0 is a valid temperatur value
				c2 =- NAN;
		}

				// --- assign new temperature to link
		Link[i].newTemp = c2;
	//}
}

//=============================================================================

void findLinkTemps(int i, double tStep, double airt, double soilt)
//
//  Input:   i = link index
//           tStep = routing time step (sec)
//  Output:  none
//  Purpose: finds new temperature in a link at end of the current time step.
//
{
	int    j,             // upstream node index
		k;             // conduit index
	double wIn,           // temperature mass inflow rate 
		qIn,              // inflow rate (cfs)
		qSeep,            // rate of seepage loss (cfs)
		v1,               // link volume at start of time step (ft3)
		v2,               // link volume at end of time step (ft3)
		c1,               // current temperature within link 
		c2,               // new temperature within link 
		vEvap,            // volume lost to evaporation (ft3)
		vLosses,          // evap. + seepage volume loss (ft3)
		fEvap,            // evaporation concentration factor
		barrels;          // number of barrels in conduit

 // --- identify index of upstream node
	j = Link[i].node1;
	if (Link[i].newFlow < 0.0) j = Link[i].node2;

	// --- link temperature is that of upstream node when
	//     link is not a conduit or is a dummy link or retention time less than 10secs
	if (Link[i].type != CONDUIT || Link[i].xsect.type == DUMMY || Link[i].newVolume / Link[i].newFlow < 10.0)
	{
		Link[i].newTemp = Node[j].newTemp;
		return;
	}
	// --- get flow rates and evaporation loss
	k = Link[i].subIndex;
	barrels = Conduit[k].barrels;
	qIn = fabs(Conduit[k].q1) * barrels;
	qSeep = Conduit[k].seepLossRate * barrels;
	vEvap = Conduit[k].evapLossRate * barrels * tStep;

	// --- get starting and ending volumes
	v1 = Link[i].oldVolume;
	v2 = Link[i].newVolume;
	vLosses = qSeep * tStep + vEvap;

	// --- compute factor by which concentrations are increased due to
	//     evaporation loss 
	fEvap = 1.0;
	if (vEvap > 0.0 && v1 > ZeroVolume) fEvap += vEvap / v1;

	// --- Steady Flow routing requires special treatment
	if (RouteModel == SF)
	{
		findSFLinkTemp(i, qSeep, fEvap, tStep);
		return;
	}

	// --- adjust inflow to compensate for volume change under Dynamic
	//     Wave routing (which produces just a single (out)flow rate
	//     for a conduit)
	if (RouteModel == DW)
	{
		qIn = qIn + (v2 + vLosses - v1) / tStep;
		qIn = MAX(qIn, 0.0);
	}

	//{
		// --- start with concen. at start of time step
	c1 = Link[i].oldTemp;
	if(!isnan(c1)) {
	// --- update mass balance accounting for seepage loss
	massbal_addSeepageLossT(qSeep * c1);

	// --- increase concen. by evaporation factor
	c1 *= fEvap;
			// --- adjust temperature by heat exchange processes
			//fprintf(stdout, "inside\n");
			c2 = getReactedTemps(c1, i, tStep, airt, soilt);
			// --- mix resulting contents with inflow from upstream node
			if (!isnan(Node[j].newTemp)) { // do not consider NaN values
				wIn = Node[j].newTemp * qIn;
				c2 = getMixedTemp(c2, v1, wIn, qIn, tStep);
			}
	}
	else{
		if (!isnan(Node[j].newTemp)) {
			c2 = Node[j].newTemp;
		}
		else c2 = NAN;
	}


	// --- set temperature to soil temperature if remaining volume is negligible
	if (v2 < ZeroVolume)
	{
		massbal_addToFinalStorageT(c2 * v2);
		// set temperature to NaN, because 0 is a valid temperatur value
		c2 =- NAN;
	}
	// --- assign new concen. to link
	Link[i].newTemp = c2;
	//}
}

//=============================================================================

void  findSFLinkTemp(int i, double qSeep, double fEvap, double tStep)
//
//  Input:   i = link index
//           tStep = routing time step (sec)
//  Output:  none
//  Purpose: finds new Temperature in a link at end of the current time step for
//           Steady Flow routing.
//
{
	int j = Link[i].node1;
	double c1;
	//double lossRate;

	// --- examine each pollutant
	//for (p = 0; p < Nobjects[POLLUT]; p++)
	//{
		// --- conduit's temperature equals upstream node temperature
		c1 = Node[j].newTemp;

		// --- update mass balance accounting for seepage loss
		massbal_addSeepageLossT(qSeep * c1);

		// --- increase concen. by evaporation factor
		c1 *= fEvap;
		Link[i].newTemp = c1;
	//}
}

//=============================================================================

void  findStorageTemp(int j, double tStep, int month, int day, int hour)
//
//  Input:   j = node index
//           tStep = routing time step (sec)
//  Output:  none
//  Purpose: finds new temperature in a node with storage volume.
//  
{
	int k;                // storage unit index
	double qIn,           // inflow rate (cfs)
		wIn,              // pollutant mass inflow rate (mass)
		v1,               // volume at start of time step (ft3)
		c1,               // initial Temperature
		c2,               // final Temperature
		qExfil = 0.0,     // exfiltration rate from storage unit (cfs)
		vEvap = 0.0,      // evaporation loss from storage unit (ft3)
		fEvap = 1.0;      // evaporation concentration factor

 // --- get inflow rate & initial volume
	qIn = Node[j].inflow;
	v1 = Node[j].oldVolume;

	// -- for storage nodes
	if (Node[j].type == STORAGE)
	{
		// --- get exfiltration rate and evaporation loss
		k = Node[j].subIndex;
		qExfil = Storage[k].exfilLoss / tStep;
		vEvap = Storage[k].evapLoss;

		// --- compute factor by which concentrations are increased due to
		//     evaporation loss (avoiding huge factors as storage unit
		//     dries out completely)
		if (vEvap > 0.0 && v1 > ZeroVolume) fEvap += vEvap / v1;
	}

		// --- start with concen. at start of time step 
		c1 = Node[j].oldTemp;

		// --- update mass balance accounting for exfiltration loss
		massbal_addSeepageLossT(qExfil * c1);

		// --- increase concen. by evaporation factor
		c1 *= fEvap;
		if (c1 != 0.0 && !isnan(c1))
			c1 = getReactedTempStNode(c1, j, tStep, month, day, hour);

		// --- mix resulting contents with inflow from all sources
		//     (temporarily accumulated in Node[j].newTemp)
		wIn = Node[j].newTemp;
		c2 = getMixedTemp(c1, v1, wIn, qIn, tStep);

		// --- set concen. to zero if remaining volume & inflow is negligible
		if (Node[j].newVolume <= ZeroVolume && qIn <= FLOW_TOL)
		{
			massbal_addToFinalStorageT(c2 * Node[j].newVolume);
			c2 = 0.0;
		}

		// --- assign new concen. to node
		Node[j].newTemp = c2;
}

//=============================================================================

void  findStorageTemps(int j, double tStep, double airt, double soilt)
//
//  Input:   j = node index
//           tStep = routing time step (sec)
//  Output:  none
//  Purpose: finds new temperature in a node with storage volume.
//  
{
	int k;                // storage unit index
	double qIn,           // inflow rate (cfs)
		wIn,              // pollutant mass inflow rate (mass)
		v1,               // volume at start of time step (ft3)
		c1,               // initial Temperature
		c2,               // final Temperature
		qExfil = 0.0,     // exfiltration rate from storage unit (cfs)
		vEvap = 0.0,      // evaporation loss from storage unit (ft3)
		fEvap = 1.0;      // evaporation concentration factor

 // --- get inflow rate & initial volume
	qIn = Node[j].inflow;
	v1 = Node[j].oldVolume;

	// -- for storage nodes
	if (Node[j].type == STORAGE)
	{

		// --- get exfiltration rate and evaporation loss
		k = Node[j].subIndex;
		qExfil = Storage[k].exfilLoss / tStep;
		vEvap = Storage[k].evapLoss;

		// --- compute factor by which concentrations are increased due to
		//     evaporation loss (avoiding huge factors as storage unit
		//     dries out completely)
		if (vEvap > 0.0 && v1 > ZeroVolume) fEvap += vEvap / v1;
	}
		// --- start with concen. at start of time step 
	c1 = Node[j].oldTemp;

	// --- update mass balance accounting for exfiltration loss
	massbal_addSeepageLossT(qExfil * c1);

	// --- increase concen. by evaporation factor
	c1 *= fEvap;
	if (c1 != 0.0 && !isnan(c1))
		c1 = getReactedTempStNodes(c1, j, tStep, airt, soilt);
	// --- mix resulting contents with inflow from all sources
	//     (temporarily accumulated in Node[j].newTemp)
	wIn = Node[j].newTemp;
	c2 = getMixedTemp(c1, v1, wIn, qIn, tStep);

	// --- set concen. to zero if remaining volume & inflow is negligible
	if (Node[j].newVolume <= ZeroVolume && qIn <= FLOW_TOL)
	{
		massbal_addToFinalStorageT(c2 * Node[j].newVolume);
		c2 = 0.0;
	}
	// --- assign new concen. to node
	Node[j].newTemp = c2;
}

//=============================================================================

void updateHRTT(int j, double v, double q, double tStep)
//
//  Input:   j = node index
//           v = storage volume (ft3)
//           q = inflow rate (cfs)
//           tStep = time step (sec)
//  Output:  none
//  Purpose: updates hydraulic residence time (i.e., water age) at a 
//           storage node.
//
{
	int    k = Node[j].subIndex;
	double hrt = Storage[k].hrt;
	if (v < ZERO) hrt = 0.0;
	else hrt = (hrt + tStep) * v / (v + q * tStep);
	Storage[k].hrt = MAX(hrt, 0.0);
}

//=============================================================================

double getReactedTemp(double oldTemp, int i, double tStep, int month, int day, int hour)
//
//  Input:   oldTemp = temperature of the previous timestep (C)
//           i = index of the current conduit
//           tStep = time step (sec)
//  Output:  none
//  Purpose: calculate the heat exchange by soil and air of the conduit
//
{
	// local variables
	int k = Link[i].subIndex;
	double  thickness, width, velocity, wetp, length, flow, volume, kp, ks, hwa, Rwa, Rws, Ewa, Ews, area;
	double  radius, penDepth, radThick, penThick, humidity;
	double dryPerimeter, widthLength, windVel;
	double deltaTa, deltaTs, deltaV;
	double denom, deltaT;
	double  ps0 = 1730000000.0;
	double  ts0 = 5311.0;
	double length2 = UCF(LENGTH) * UCF(LENGTH);
	double soilTemp, airTemp;
	double thermalExt;
	// transform from FT to M
	thickness = Conduit[k].thickness;
	width = Conduit[k].oldwidth;
	velocity = Conduit[k].velocity;
	wetp = Conduit[k].oldwetp;
	length = Conduit[k].length;
	kp = Conduit[k].kPipe; // nothing to transform
	ks = Conduit[k].kSoil; // nothing to transform
	penDepth = Conduit[k].penDepth;
	//flow = Link[i].newFlow * UCF(FLOW) / 1000; // m3/s
	volume = Link[i].oldVolume * UCF(VOLUME); // m3
	radius = Link[i].xsect.yFull * 0.50;
	//area = Link[i].xsect.aFull * length2;
	humidity = TempModel.humidity;
	dryPerimeter = (6.28319 * radius - wetp) ;
	widthLength = width * length * length2;
	windVel = 0.397 * powl(width * velocity * UCF(LENGTH) / dryPerimeter, 0.7234);
	//double prwat = 50000.0 / (oldTemp * (oldTemp + 155.0) + 3700.0);
	//double dynvisc = 0.00002414 * powl(10.0, 247.8 / (oldTemp + 133.15));
	//double hydradi = (Conduit[k].a1 + Conduit[k].a2) * UCF(LENGTH) / (2.0 * wetp);
	//double reywat = 4.0 * hydradi * TempModel.density * velocity * UCF(LENGTH) / dynvisc;

	// get insewer-air and soil temperature of the current month
	soilTemp = inflow_getPatternFactor((int)Conduit[k].soilPat, month, day, hour);
	airTemp = inflow_getPatternFactor((int)Conduit[k].airPat, month, day, hour);

	// calculate temperature difference
	deltaTa = airTemp - oldTemp;
	deltaTs = soilTemp - oldTemp;

	// calculate thermal resistivity for wastewater - air
	deltaV = sqrt(ABS(velocity * UCF(LENGTH) - windVel));

	if (deltaV > 0.001) // if the relative velocity is lower than 1 mm/s the thermal resistivity is 0 (prevent division by 0)
	{
		  // 	hwa = 5.85 * sqrt(deltaV);
		 //  	Rwa = 1.0 / (hwa * width * length);
		//   	Ewa = deltaTa / Rwa;
		Ewa = widthLength * deltaV * (5.85 * deltaTa -
	     	  8.75 * ps0 * (exp(-ts0 / (oldTemp + 273.15)) -
			  humidity * exp(-ts0 / (airTemp + 273.15))));
	}
	else
	{
		//	Rwa = 0.0;
		Ewa = 0.0;
	}

	// calculate thermal resistivity for wastewater - soil
	//Rws = thickness / (kp * wetp * length) + Conduit[k].penDepth / (ks * wetp * length);
	//Ews = deltaTs / Rws;
	radThick = radius + thickness;
	penThick = radThick + penDepth;
	//radThick = radius  - thickness;
	//penThick = radThick + radius;
	//double radi = 1.0 / radius;
	Ews = deltaTs * wetp * length * UCF(LENGTH) / (radius * (log(radThick / radius) / kp +
		log(penThick / radThick) / ks)); //+
		//hydradi / (0.023 * powl(reywat, 0.8) * powl(prwat, 0.3333) * 0.6));
	// calculate the change in temperature over the given time step
	//double denom = TempModel.density * TempModel.specHC * flow;
	denom = TempModel.density * TempModel.specHC * volume;
	deltaT = (Ewa + Ews) * tStep / denom;

	// finally calculate the new temperature - Conduit[k].thermalEnergy leads to the change in temperature by heat exchanger depending on TempModel.extUnit
	thermalExt = 0;
	if (TempModel.extUnit == 'P')
		thermalExt = (Conduit[k].thermalEnergy * 1000 * tStep / denom);
	else if (TempModel.extUnit == 'T')
		thermalExt = Conduit[k].thermalEnergy;
	oldTemp += deltaT + thermalExt;
	return oldTemp;
}

//=============================================================================

double getReactedTemps(double oldTemp, int i, double tStep, double airt, double soilt)
//
//  Input:   oldTemp = temperature of the previous timestep (C)
//           i = index of the current conduit
//           tStep = time step (sec)
//  Output:  none
//  Purpose: calculate the heat exchange by soil and air of the conduit
//
{
	// local variables
	int k = Link[i].subIndex;
	double  thickness, width, velocity, wetp, length, flow, volume, kp, ks, hwa, Rwa, Rws, Ewa, Ews, area;
	double  radius, penDepth, radThick, penThick, humidity;
	double dryPerimeter, widthLength, windVel;
	double deltaTa, deltaTs, deltaV;
	double denom, deltaT; 
	double  ps0 = 1730000000.0;
	double  ts0 = 5311.0;
	double length2 = UCF(LENGTH) * UCF(LENGTH);
	double soilTemp, airTemp;
	double thermalExt;
	// transform from FT to M
	thickness = Conduit[k].thickness;
	width = Conduit[k].oldwidth;
	//width = Conduit[k].width;
	velocity = Conduit[k].velocity;
	wetp = Conduit[k].oldwetp;
	//wetp = Conduit[k].wetp;
	length = Conduit[k].length;
	kp = Conduit[k].kPipe; // nothing to transform
	ks = Conduit[k].kSoil; // nothing to transform
	penDepth = Conduit[k].penDepth;
	//flow = Link[i].newFlow * UCF(FLOW) / 1000; // m3/s
//	flow = Link[i].oldFlow * UCF(FLOW);
	volume = Link[i].oldVolume * UCF(VOLUME); // m3
	radius = Link[i].xsect.yFull * 0.50;
	//area = xsect_getAofY(&Link[i].xsect,Link[i].oldDepth) * length2;
	humidity = TempModel.humidity;
	dryPerimeter = (6.28319 * radius - wetp);
	widthLength = width * length * length2;
	windVel = 0.397 * powl(width * velocity * UCF(LENGTH) / dryPerimeter, 0.7234);
	//double prwat = 50000.0 / (oldTemp * (oldTemp + 155.0) + 3700.0);
	//double dynvisc = 0.00002414 * powl(10.0, 247.8 / (oldTemp + 133.15));
	//double hydradi = (Conduit[k].a1 + Conduit[k].a2) * UCF(LENGTH) / (2.0 * wetp);
	//double reywat = 4.0 * hydradi * TempModel.density * velocity * UCF(LENGTH) / dynvisc;

	// get insewer-air and soil temperature of the current month
	soilTemp = soilt;
	airTemp = airt;

	// calculate temperature difference
	deltaTa = airTemp - oldTemp;
	deltaTs = soilTemp - oldTemp;

	// calculate thermal resistivity for wastewater - air
	deltaV = sqrt(ABS(velocity * UCF(LENGTH) - windVel));

	if (deltaV > 0.001) // if the relative velocity is lower than 1 mm/s the thermal resistivity is 0 (prevent division by 0)
	{
	//	   	hwa = 5.85 * sqrt(deltaV);
	//	   	Rwa = 1.0 / (hwa * width * length * length2);
	//	   	Ewa = deltaTa / Rwa;
		Ewa = widthLength * deltaV * (5.85 * deltaTa -
			8.75 * ps0 * (exp(-ts0 / (oldTemp + 273.15)) -
				humidity * exp(-ts0 / (airTemp + 273.15))));
	}
	else
	{
		//	Rwa = 0.0;
		Ewa = 0.0;
	}

	// calculate thermal resistivity for wastewater - soil
	//Rws = thickness / (kp * wetp * length * UCF(LENGTH) ) + Conduit[k].penDepth / (ks * wetp * length * UCF(LENGTH));
	//Ews = deltaTs / Rws;
	radThick = radius + thickness;
	penThick = radThick + penDepth;
	Ews = deltaTs * wetp * length * UCF(LENGTH) / (radius * (log(radThick / radius) / kp +
		log(penThick / radThick) / ks)); //+
	//hydradi / (0.023 * powl(reywat, 0.8) * powl(prwat, 0.3333) * 0.6 ));
	
	// calculate the change in temperature over the given time step
	denom = TempModel.density * TempModel.specHC * volume;
	deltaT = (Ewa + Ews)* tStep / denom;	
	// finally calculate the new temperature - Conduit[k].thermalEnergy leads to the change in temperature by heat exchanger depending on TempModel.extUnit
	thermalExt = 0;
	if (TempModel.extUnit == 'P')
		thermalExt = (Conduit[k].thermalEnergy * 1000 * tStep/ denom);
	else if (TempModel.extUnit == 'T')
		thermalExt = Conduit[k].thermalEnergy;
	oldTemp += deltaT + thermalExt;
	return oldTemp;
}

//=============================================================================

double getReactedTempStNode(double oldTemp, int j, double tStep, int month, int day, int hour)
//
//  Input:   oldTemp = temperature of the previous timestep (C)
//           i = index of the current conduit
//           tStep = time step (sec)
//  Output:  none
//  Purpose: calculate the heat exchange by soil and air of the storage unit
//
{
	// local variables
	double thickness, kw, ks, volume, Qin, Qout, wetA, hwa, Rwa, Rws, Ewa, Ews, pend;
	double soilTemp, surfaceArea, deltaTs;
	double Tin, deltaT;
	int i;
	double  ps0 = 0.00000000173;
	double  ts0 = 5311.0;
	double humidity = TempModel.humidity;

	// get storage node
	int k = Node[j].subIndex;
	thickness = Storage[k].thickness * UCF(LENGTH);
	kw = Storage[k].kWall; // nothing to transform
	ks = Storage[k].kSoil; // nothing to transform
	pend = Storage[k].penDepth * UCF(LENGTH);
	volume = Node[j].oldVolume * UCF(VOLUME);
	Qin = Node[j].inflow * UCF(FLOW) / 1000; // m3/s
	Qout = Node[j].outflow * UCF(FLOW) / 1000; // m3/s

	// get insewer-air and soil temperature of the current month
	soilTemp = inflow_getPatternFactor((int)Storage[k].soilPat, month, day, hour);
	//double airTemp = inflow_getPatternFactor((int)Storage[k].airPat, month, day, hour);

	// transform from FT to M
	surfaceArea = Storage[k].area * UCF(LENGTH) * UCF(LENGTH); //m2

	// get the wetted area of the storage unit by given wastewater depth
	i = Storage[k].aCurve; // < 0 if funcional - >= 0 if tabular
	if (i >= 0)
		wetA = getWettedArea(&Curve[Storage[k].aCurve], Node[j].newDepth * UCF(LENGTH));
	else
		wetA = 2 * PI * sqrt(surfaceArea / PI) * Node[j].newDepth * UCF(LENGTH) + surfaceArea;
	// calculate temperature difference
	//double deltaTa = airTemp - oldTemp;
	deltaTs = soilTemp - oldTemp;

	// calculate thermal resistivity for wastewater - air		
	//double deltaV = sqrt(ABS(TempModel.ua));
	//if (deltaV > 0.001) // if the in-sewer air velocity is lower than 1 mm/s the thermal resistivity is 0 (prevent division by 0)
	//{
		//hwa = 5.85 * sqrt(deltaV);
		//Rwa = 1.0 / (hwa * surfaceArea);
		//Ewa = deltaTa / Rwa;
	//    Ewa = deltaTa * 5.85 * deltaV * surfaceArea;
	//}
	//else
	//{
		//Rwa = 0.0;
	//	Ewa = 0.0;
	//Ewa = surfaceArea \
        8.75 * ps0 * (exp(-ts0 / (oldTemp + 273.15)) - \
            humidity * exp(-ts0 / (airTemp + 273.15))));
	//}

	// calculate thermal resistivity for wastewater - soil
	//Rws = thickness / (kw * wetA) + pend / (ks * wetA);
	Rws = thickness / (kw) +pend / (ks);
	Ews = deltaTs * wetA / Rws;

	// get the the temperatur of the inflows
	Tin = Node[j].newTemp / Node[j].inflow; //+ 273.15;

	// calculate the change in temperature over a given time step
	//double deltaT = (volume * (oldTemp + 273.15) + Qin * Tin * tStep) / (volume + Qin * tStep);
	deltaT = (volume * (oldTemp)+Qin * Tin * tStep) / (volume + Qin * tStep);
	//deltaT += (Ewa + Ews) * tStep / (TempModel.density* TempModel.specHC * (volume + Qout * tStep));
	deltaT += (Ews)*tStep / (TempModel.density * TempModel.specHC * (volume + Qout * tStep));

	oldTemp = deltaT;// - 273.15;

	return oldTemp;
}

//=============================================================================

double getReactedTempStNodes(double oldTemp, int j, double tStep, double airt, double soilt)
//
//  Input:   oldTemp = temperature of the previous timestep (C)
//           i = index of the current conduit
//           tStep = time step (sec)
//  Output:  none
//  Purpose: calculate the heat exchange by soil and air of the storage unit
//
{
	// local variables
	double thickness, kw, ks, volume, Qin, Qout, wetA, hwa, Rwa, Rws, Ewa, Ews, pend;
	double soilTemp, surfaceArea, deltaTs;
	double Tin, deltaT;
	int i;
	double  ps0 = 0.00000000173;
	double  ts0 = 5311.0;
	double humidity = TempModel.humidity;

	// get storage node
	int k = Node[j].subIndex;
	thickness = Storage[k].thickness * UCF(LENGTH);
	kw = Storage[k].kWall; // nothing to transform
	ks = Storage[k].kSoil; // nothing to transform
	pend = Storage[k].penDepth * UCF(LENGTH);
	volume = Node[j].oldVolume * UCF(VOLUME);
	Qin = Node[j].inflow * UCF(FLOW) / 1000; // m3/s
	Qout = Node[j].outflow * UCF(FLOW) / 1000; // m3/s

	soilTemp = soilt;
	//airTemp = airt;
	// transform from FT to M
	surfaceArea = Storage[k].area * UCF(LENGTH) * UCF(LENGTH); //m2

	// get the wetted area of the storage unit by given wastewater depth
	i = Storage[k].aCurve; // < 0 if funcional - >= 0 if tabular
	if (i >= 0)
		wetA = getWettedArea(&Curve[Storage[k].aCurve], Node[j].newDepth * UCF(LENGTH));
	else
		wetA = 2 * PI * sqrt((Storage[k].aConst + surfaceArea) / 2. * PI) * Node[j].newDepth * UCF(LENGTH) + Storage[k].aConst;
	// calculate temperature difference
	//double deltaTa = airTemp - oldTemp;
	deltaTs = soilTemp - oldTemp;

	// calculate thermal resistivity for wastewater - air		
	//double deltaV = sqrt(ABS(TempModel.ua));
	//if (deltaV > 0.001) // if the in-sewer air velocity is lower than 1 mm/s the thermal resistivity is 0 (prevent division by 0)
	//{
		//hwa = 5.85 * sqrt(deltaV);
		//Rwa = 1.0 / (hwa * surfaceArea);
		//Ewa = deltaTa / Rwa;
	//    Ewa = deltaTa * 5.85 * deltaV * surfaceArea;
	//}
	//else
	//{
		//Rwa = 0.0;
	//	Ewa = 0.0;
	//Ewa = surfaceArea \
        8.75 * ps0 * (exp(-ts0 / (oldTemp + 273.15)) - \
            humidity * exp(-ts0 / (airTemp + 273.15))));
	//}

	// calculate thermal resistivity for wastewater - soil
	//Rws = thickness / (kw * wetA) + pend / (ks * wetA);
	Rws = thickness / (kw)+pend / (ks);
	Ews = deltaTs * wetA / Rws;

	// get the the temperatur of the inflows
	Tin = Node[j].newTemp / Node[j].inflow; //+ 273.15;

	// calculate the change in temperature over a given time step
	//double deltaT = (volume * (oldTemp + 273.15) + Qin * Tin * tStep) / (volume + Qin * tStep);
	deltaT = (volume * (oldTemp)+Qin * Tin * tStep) / (volume + Qin * tStep);
	//deltaT += (Ewa + Ews) * tStep / (TempModel.density* TempModel.specHC * (volume + Qout * tStep));
	deltaT += (Ews)*tStep / (TempModel.density * TempModel.specHC * (volume + Qout * tStep));

	oldTemp = deltaT;// - 273.15;

	return oldTemp;
}

//=============================================================================

double getWettedArea(TTable* table, double x)
//
//  Input:   table = geometry of the storage unit
//           x = current wastewater depth
//  Output:  none
//  Purpose: calculate the wetted area of the storage unit by given wastewater depth
//
{
	double x1, y1, x2, y2;
	double s = 0.0;
	double area = 0.0;
	TTableEntry* entry;

	entry = table->firstEntry;
	if (entry == NULL) return 0.0;
	x1 = entry->x;
	y1 = entry->y;

	// get base area
	area = y1;

	if (x <= x1)
		return area;

	// calculate the lateral surface
	while (entry->next)
	{
		entry = entry->next;
		x2 = entry->x;
		y2 = entry->y;
		if (x <= x2) {
			y2 = y1 + (y2 - y1) / (x2 - x1) * (x - x1);
			x2 = x;
			area = area + (sqrt(((y2 + y1) / (2. * PI))) * 2. * PI * (x2 - x1));
			return area;
		}
		else
			area = area + (sqrt(((y2 + y1) / (2. * PI))) * 2. * PI * (x2 - x1));
		x1 = x2;
		y1 = y2;
	}

	return area;
}