//-----------------------------------------------------------------------------
//   asciioutput.c
//
//   Project:  EPA SWMM5
//   Version:  5.1
//   Date:     03/20/14  (Build 5.1.001)
//             03/19/15  (Build 5.1.008)
//             08/05/15  (Build 5.1.010)
//             05/10/18  (Build 5.1.013)
//             03/01/20  (Build 5.1.014)
//   Author:   L. Rossman (EPA)
//
//   ASCII output file access functions.
//
//   Build 5.1.008:
//   - Possible divide by zero for reported system wide variables avoided.
//   - Updating of maximum node depth at reporting times added.
//
//   Build 5.1.010:
//   - Potentional ET added to list of system-wide variables saved to file.
//
//   Build 5.1.013:
//   - Names NsubcatchVars, NnodeVars & NlinkVars replaced with
//     NumSubcatchVars, NumNodeVars & NumLinkVars 
//   - Support added for saving average node & link routing results to
//     binary file in each reporting period.
//
//   Build 5.1.014:
//   - Incorrect loop limit fixed in function output_saveAvgResults.
//
//-----------------------------------------------------------------------------
#define _CRT_SECURE_NO_DEPRECATE

#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "headers.h"


// Definition of 4-byte integer, 4-byte real and 8-byte real types
#define INT4  int
#define REAL4 float
#define REAL8 double

enum InputDataType {INPUT_TYPE_CODE, INPUT_AREA, INPUT_INVERT, INPUT_MAX_DEPTH,
                    INPUT_OFFSET, INPUT_LENGTH};

typedef struct                                                                 //(5.1.013)
{                                                                              //
    REAL4* xAvg;                                                               //
}   TAvgResults;                                                               //

//-----------------------------------------------------------------------------
//  Shared variables    
//-----------------------------------------------------------------------------
static INT4      IDStartPos;           // starting file position of ID names
static INT4      InputStartPos;        // starting file position of input data
static INT4      OutputStartPos;       // starting file position of output data
static INT4      BytesPerPeriod;       // bytes saved per simulation time period
static INT4      NumSubcatchVars;      // number of subcatchment output variables
static INT4      NumNodeVars;          // number of node output variables
static INT4      NumLinkVars;          // number of link output variables
static INT4      NumSubcatch;          // number of subcatchments reported on
static INT4      NumNodes;             // number of nodes reported on
static INT4      NumLinks;             // number of links reported on
static INT4      NumPolluts;           // number of pollutants reported on
static REAL4     SysResults[MAX_SYS_RESULTS];    // values of system output vars.

static TAvgResults* AvgLinkResults;                                            //(5.1.013)
static TAvgResults* AvgNodeResults;                                            //
static int          Nsteps;                                                    //

//-----------------------------------------------------------------------------
//  Exportable variables (shared with report.c)
//-----------------------------------------------------------------------------
//REAL4*           SubcatchResults;
//REAL4*           NodeResults;
//REAL4*           LinkResults;
//-----------------------------------------------------------------------------
//  Imported variables
//-----------------------------------------------------------------------------
#define REAL4 float
extern REAL4* SubcatchResults;         // Results vectors defined in OUTPUT.C
extern REAL4* NodeResults;             //  "
extern REAL4* LinkResults;             //  "


//-----------------------------------------------------------------------------
//  Local functions
//-----------------------------------------------------------------------------
static void output_openOutFile_ascii(void);
static void output_openOutFile_asciih(void);
static void output_saveID_ascii(char* id, FILE* file);
static void output_saveSubcatchResults_ascii(double reportTime, FILE* file);
static void output_saveNodeResults_ascii(double reportTime, FILE* file);
static void output_saveLinkResults_ascii(double reportTime, FILE* file);
static void output_saveAvgResults_ascii(FILE* file);                                 //


//-----------------------------------------------------------------------------
//  External functions (declared in funcs.h)
//-----------------------------------------------------------------------------
//  output_open_ascii             (called by swmm_start in swmm5.c)
//  output_end_ascii              (called by swmm_end in swmm5.c)
//  output_saveResults_ascii      (called by swmm_step in swmm5.c)
//=============================================================================

int output_open_ascii()
//
//  Input:   none
//  Output:  returns an error code
//  Purpose: writes basic project data to ascii output file.
//
{
    int   j;
    int   m;
    INT4  k;
    REAL4 x;
    REAL8 z;

    // --- open ascii output file
    output_openOutFile_ascii();
    output_openOutFile_asciih();
    if (ErrorCode) return ErrorCode;

    // --- ignore pollutants if no water quality analsis performed
    if (IgnoreQuality) NumPolluts = 0;
    else NumPolluts = Nobjects[POLLUT];

    // --- subcatchment results consist of Rainfall, Snowdepth, Evap, 
    //     Infil, Runoff, GW Flow, GW Elev, GW Sat, and Washoff
    NumSubcatchVars = MAX_SUBCATCH_RESULTS - 1 + NumPolluts;

    // --- node results consist of Depth, Head, Volume, Lateral Inflow,
    //     Total Inflow, Overflow and Quality
    NumNodeVars = MAX_NODE_RESULTS - 2 + NumPolluts + TempModel.active;

    // --- link results consist of Depth, Flow, Velocity, Volume,              //(5.1.013)
    //     Capacity and Quality
    NumLinkVars = MAX_LINK_RESULTS - 2 + NumPolluts + TempModel.active;

    // --- get number of objects reported on
    NumSubcatch = 0;
    NumNodes = 0;
    NumLinks = 0;
    for (j = 0; j < Nobjects[SUBCATCH]; j++) if (Subcatch[j].rptFlag) NumSubcatch++;
    for (j = 0; j < Nobjects[NODE]; j++) if (Node[j].rptFlag) NumNodes++;
    for (j = 0; j < Nobjects[LINK]; j++) if (Link[j].rptFlag) NumLinks++;

    BytesPerPeriod = sizeof(REAL8)
        + NumSubcatch * NumSubcatchVars * sizeof(REAL4)
        + NumNodes * NumNodeVars * sizeof(REAL4)
        + NumLinks * NumLinkVars * sizeof(REAL4)
        + MAX_SYS_RESULTS * sizeof(REAL4);
    Nperiods = 0;


    fseek(Foutasciih.file, 0, SEEK_SET);
    fprintf(Foutasciih.file, "MAGICNUMBER, VERSION, FLOW_UNITS, NUMSUBCATCH, NUMNODES, NUMLINKS, NUMPOLLUTS\n");
    fprintf(Foutasciih.file, "%d %d %d %d %d %d %d\n", MAGICNUMBER, VERSION, FlowUnits, NumSubcatch, NumNodes, NumLinks, \
        NumPolluts, TempModel.active);

    // --- save ID names of subcatchments, nodes, links, & pollutants 
    IDStartPos = ftell(Foutasciih.file);
    for (j = 0; j < Nobjects[SUBCATCH]; j++)
    {
        if (Subcatch[j].rptFlag) {
            fprintf(Foutasciih.file, "LENGHT, SUBCATCH_ID\n");
            output_saveID_ascii(Subcatch[j].ID, Foutasciih.file);
        }
    }
    for (j = 0; j < Nobjects[NODE]; j++)
    {
        if (Node[j].rptFlag) {
            fprintf(Foutasciih.file, "LENGHT, NODE_ID\n");
            output_saveID_ascii(Node[j].ID, Foutasciih.file);
        }
    }
    for (j = 0; j < Nobjects[LINK]; j++)
    {
        if (Link[j].rptFlag) {
            fprintf(Foutasciih.file, "LENGHT, LINK_ID\n");
            output_saveID_ascii(Link[j].ID, Foutasciih.file);
        }
    }
    for (j = 0; j < NumPolluts; j++) {
        fprintf(Foutasciih.file, "LENGHT, POLLUTANT_ID\n");
        output_saveID_ascii(Pollut[j].ID, Foutasciih.file);
    }

    // --- save codes of pollutant concentration units
    fprintf(Foutasciih.file, "POLLUTANT_CONCENTRATION_UNITS\n");
    for (j = 0; j < NumPolluts; j++)
    {
        fprintf(Foutasciih.file, "%d ", Pollut[j].units);
    }

    if (TempModel.active == 1)
    {
        fprintf(Foutasciih.file, "LENGHT, WTEMPERATURE_ID\n");
    output_saveID_ascii(WTemperature.ID, Foutasciih.file);
    fprintf(Foutasciih.file, "WTEMPERATURE_UNITS\n");
    fprintf(Foutasciih.file, "%d ", WTemperature.units);

    }

    fprintf(Foutasciih.file, "\n");
    InputStartPos = ftell(Foutasciih.file);

    // --- save subcatchment area
    fprintf(Foutasciih.file, "SUBCATCHMENT, INPUT_AREA\n");
    fprintf(Foutasciih.file, "%d %d ", 1, INPUT_AREA);
    for (j = 0; j < Nobjects[SUBCATCH]; j++)
    {
        if (!Subcatch[j].rptFlag) continue;
        fprintf(Foutasciih.file, "%e ", (REAL4)(Subcatch[j].area * UCF(LANDAREA)));
    }
    fprintf(Foutascii.file, "\n");

    // --- save node type, invert, & max. depth
    fprintf(Foutasciih.file, "NODE, INPUT_TYPE_CODE, INPUT_INVERT, INPUT_MAX_DEPTH\n");
    fprintf(Foutasciih.file, "%d %d %d %d\n", 3, INPUT_TYPE_CODE, INPUT_INVERT, INPUT_MAX_DEPTH);
    for (j = 0; j < Nobjects[NODE]; j++)
    {
        if (!Node[j].rptFlag) continue;
        fprintf(Foutasciih.file, "%d %e %e\n", Node[j].type, (REAL4)(Node[j].invertElev * UCF(LENGTH)), \
            (REAL4)(Node[j].fullDepth * UCF(LENGTH)));
    }

    // --- save link type, offsets, max. depth, & length
    fprintf(Foutasciih.file, "LINK, INPUT_TYPE_CODE, INPUT_OFFSET, INPUT_OFFSET, INPUT_MAX_DEPTH, INPUT_LENGTH\n");
    fprintf(Foutasciih.file, "%d %d %d %d %d %d\n", 5, INPUT_TYPE_CODE, INPUT_OFFSET, INPUT_OFFSET, INPUT_MAX_DEPTH, \
        INPUT_LENGTH);

    for (j = 0; j < Nobjects[LINK]; j++)
    {
        if (!Link[j].rptFlag) continue;
        k = Link[j].type;
        if (k == PUMP)
        {
            for (m = 0; m < 4; m++) LinkResults[m] = 0.0f;
        }
        else
        {
            LinkResults[0] = (REAL4)(Link[j].offset1 * UCF(LENGTH));
            LinkResults[1] = (REAL4)(Link[j].offset2 * UCF(LENGTH));
            if (Link[j].direction < 0)
            {
                x = LinkResults[0];
                LinkResults[0] = LinkResults[1];
                LinkResults[1] = x;
            }
            if (k == OUTLET) LinkResults[2] = 0.0f;
            else LinkResults[2] = (REAL4)(Link[j].xsect.yFull * UCF(LENGTH));
            if (k == CONDUIT)
            {
                m = Link[j].subIndex;
                LinkResults[3] = (REAL4)(Conduit[m].length * UCF(LENGTH));
            }
            else LinkResults[3] = 0.0f;
        }
        fprintf(Foutasciih.file, "%d %e %e %e %e\n", k, LinkResults[0], LinkResults[1], LinkResults[2], LinkResults[3]);
    }

    // --- save number & codes of subcatchment result variables
    fprintf(Foutasciih.file, "NUMSUBCATCHVARS, SUBCATCH_RAINFALL, SUBCATCH_SNOWDEPTH, SUBCATCH_EVAP \
SUBCATCH_INFIL, SUBCATCH_RUNOFF, SUBCATCH_GW_FLOW, SUBCATCH_GW_ELEV, SUBCATCH_SOIL_MOIST\n");
    fprintf(Foutasciih.file, "%d %d %d %d %d %d %d %d %d\n", NumSubcatchVars, SUBCATCH_RAINFALL, SUBCATCH_SNOWDEPTH, SUBCATCH_EVAP, \
        SUBCATCH_INFIL, SUBCATCH_RUNOFF, SUBCATCH_GW_FLOW, SUBCATCH_GW_ELEV, SUBCATCH_SOIL_MOIST);
    fprintf(Foutasciih.file, "SUBCATCH_WASHOFF\n");
    for (j = 0; j < NumPolluts; j++)
    {
        fprintf(Foutasciih.file, " %d", SUBCATCH_WASHOFF + j);
    }
    fprintf(Foutasciih.file, "\n");

    // --- save number & codes of node result variables
    fprintf(Foutasciih.file, "NUMNODEVARS, NODE_DEPTH, NODE_HEAD, NODE_VOLUME, NODE_LATFLOW, NODE_INFLOW, \
NODE_OVERFLOW\n");
    fprintf(Foutasciih.file, "%d %d %d %d %d %d %d\n", NumNodeVars, NODE_DEPTH, NODE_HEAD, NODE_VOLUME, NODE_LATFLOW, NODE_INFLOW, \
        NODE_OVERFLOW);
    fprintf(Foutasciih.file, "NODE_QUAL\n");
    for (j = 0; j < NumPolluts; j++)
    {
        fprintf(Foutasciih.file, "%d ", NODE_QUAL + j);
    }
    fprintf(Foutasciih.file, "\n");
    fprintf(Foutasciih.file, "NODE_WTEMP\n");
    fprintf(Foutasciih.file, "%d ", TempModel.active + NODE_WTEMP - 1);

    fprintf(Foutasciih.file, "\n");

    // --- save number & codes of link result variables
    fprintf(Foutasciih.file, "NUMLINKVARS, LINK_FLOW, LINK_DEPTH, LINK_VELOCITY, LINK_VOLUME, LINK_CAPACITY, LINK_AIR_VELOCITY\n");
    fprintf(Foutasciih.file, "%d %d %d %d %d %d %d\n", NumLinkVars, LINK_FLOW, LINK_DEPTH, LINK_VELOCITY, LINK_VOLUME, LINK_CAPACITY, LINK_AIR_VELOCITY);
    fprintf(Foutasciih.file, "LINK_QUAL\n");
    for (j = 0; j < NumPolluts; j++)
    {
        fprintf(Foutasciih.file, "%d ", LINK_QUAL + j);
    }
    fprintf(Foutasciih.file, "\n");
    fprintf(Foutasciih.file, "LINK_WTEMP\n");
    fprintf(Foutasciih.file, "%d ", TempModel.active + LINK_WTEMP - 1);

    fprintf(Foutasciih.file, "\n");


    // --- save number & codes of system result variables
    fprintf(Foutasciih.file, "MAX_SYS_RESULTS\n");
    fprintf(Foutasciih.file, "%d\n", MAX_SYS_RESULTS);
    for (k = 0; k < MAX_SYS_RESULTS; k++)
    {
        fprintf(Foutasciih.file, "%d ", k);
    }
    fprintf(Foutasciih.file, "\n");
    // --- save starting report date & report step
    //     (if reporting start date > simulation start date then
    //      make saved starting report date one reporting period
    //      prior to the date of the first reported result)
    z = (double)ReportStep/86400.0;
    if ( StartDateTime + z > ReportStart ) z = StartDateTime;
    else
    {
        z = floor((ReportStart - StartDateTime)/z) - 1.0;
        z = StartDateTime + z*(double)ReportStep/86400.0;
    }
    fprintf(Foutasciih.file, "STARTING_REPORT_DATE, REPORT_STEP\n");
    fprintf(Foutasciih.file, "%e ", z);
    if ( fprintf(Foutasciih.file, "%d\n", ReportStep) < 0)
    {
        report_writeErrorMsg(ERR_OUT_WRITE, "");
        return ErrorCode;
    }
    return ErrorCode;
}

//=============================================================================

void output_openOutFile_ascii()
//
//  Input:   none
//  Output:  none
//  Purpose: opens a project's ascii output file.
//
{
    // --- close output file if already opened
    if (Foutascii.file != NULL) fclose(Foutascii.file);

    // --- else if file name supplied then set file mode to SAVE
    else if (strlen(Foutascii.name) != 0) Foutascii.mode = SAVE_FILE;

    // --- otherwise set file mode to SCRATCH & generate a name
    else
    {
        Foutascii.mode = SCRATCH_FILE;
        getTempFileNameAscii(Foutascii.name);
    }
    // --- try to open the file
    if ((Foutascii.file = fopen(Foutascii.name, "w+b")) == NULL)
    {
        writecon(FMT14);
        ErrorCode = ERR_OUT_FILE;
    }
}

//=============================================================================

void output_openOutFile_asciih()
//
//  Input:   none
//  Output:  none
//  Purpose: opens a project's ascii output file.
//
{
    // --- close output file if already opened
    if (Foutasciih.file != NULL) fclose(Foutasciih.file);

    // --- else if file name supplied then set file mode to SAVE
    else if (strlen(Foutasciih.name) != 0) Foutasciih.mode = SAVE_FILE;

    // --- otherwise set file mode to SCRATCH & generate a name
    else
    {
        Foutasciih.mode = SCRATCH_FILE;
        getTempFileNameAsciih(Foutasciih.name);
    }
    // --- try to open the file
    if ((Foutasciih.file = fopen(Foutasciih.name, "w+b")) == NULL)
    {
        writecon(FMT14);
        ErrorCode = ERR_OUT_FILE;
    }
}

//=============================================================================

void output_saveResults_ascii(double reportTime)
//
//  Input:   reportTime = elapsed simulation time (millisec)
//  Output:  none
//  Purpose: writes computed results for current report time to ascii file.
//
{
    int i;
    extern TRoutingTotals StepFlowTotals;  // defined in massbal.c             //(5.1.013)
    DateTime reportDate = getDateTime(reportTime);
    //REAL8 date;

    // --- initialize system-wide results
    if ( reportDate < ReportStart ) return;
    for (i=0; i<MAX_SYS_RESULTS; i++) SysResults[i] = 0.0f;

    // --- save date corresponding to this elapsed reporting time
    fprintf(Foutascii.file, "%21.16e ", reportDate);

    // --- save subcatchment results
    if (Nobjects[SUBCATCH] > 0)
        output_saveSubcatchResults_ascii(reportTime, Foutascii.file);

    // --- save average routing results over reporting period if called for    //(5.1.013)
    if ( RptFlags.averages ) output_saveAvgResults_ascii(Foutascii.file);                 //

    // --- otherwise save interpolated point routing results                   //(5.1.013)
    else                                                                       //
    {
        if (Nobjects[NODE] > 0)
            output_saveNodeResults_ascii(reportTime, Foutascii.file);
        if (Nobjects[LINK] > 0)
            output_saveLinkResults_ascii(reportTime, Foutascii.file);
    }
    fprintf(Foutascii.file, "\n");
}

//=============================================================================

void output_end_ascii()
//
//  Input:   none
//  Output:  none
//  Purpose: writes closing records to ascii file.
//
{
    //INT4 k;
    fprintf(Foutasciih.file, "ID_START_POS, INPUT_START_POS, OUTPUT_START_POS\n");
    fprintf(Foutasciih.file, "%d %d %d\n", IDStartPos, InputStartPos, OutputStartPos);
    fprintf(Foutasciih.file, "NPERIODS, EROR_GETCODE\n");
    fprintf(Foutasciih.file, "%d %d\n", Nperiods, (INT4)error_getCode(ErrorCode));
    if (fprintf(Foutasciih.file, "MAGICNUMBER %d\n", MAGICNUMBER) < 0)
    {
        report_writeErrorMsg(ERR_OUT_WRITE, "");
    }
}

//=============================================================================

void output_saveID_ascii(char* id, FILE* file)
//
//  Input:   id = name of an object
//           file = ptr. to ascii output file
//  Output:  none
//  Purpose: writes an object's name to the ascii output file.
//
{
    INT4 n = strlen(id);
    fprintf(file, "%d %s\n", n, id);
}

//=============================================================================

void output_saveSubcatchResults_ascii(double reportTime, FILE* file)
//
//  Input:   reportTime = elapsed simulation time (millisec)
//           file = ptr. to ascii output file
//  Output:  none
//  Purpose: writes computed subcatchment results to ascii file.
//
{
    int      j;
    int      k;
    double   f;
    //double   area;
    REAL4    totalArea = 0.0f; 
    DateTime reportDate = getDateTime(reportTime);

    // --- update reported rainfall at each rain gage
    for ( j=0; j<Nobjects[GAGE]; j++ )
    {
        gage_setReportRainfall(j, reportDate);
    }

    // --- find where current reporting time lies between latest runoff times
    f = (reportTime - OldRunoffTime) / (NewRunoffTime - OldRunoffTime);

    // --- write subcatchment results to file
    for ( j=0; j<Nobjects[SUBCATCH]; j++)
    {
        // --- retrieve interpolated results for reporting time & write to file
        subcatch_getResults(j, f, SubcatchResults);
        if ( Subcatch[j].rptFlag)
            for (k = 0; k < NumSubcatchVars; k++)
            {
                fprintf(file, "%g ", SubcatchResults[k]);
            }
            fprintf(file, "%s ", Subcatch[j].ID);
    }
}

//=============================================================================

////  This function was re-written for release 5.1.013.  ////                  //(5.1.013)

void output_saveNodeResults_ascii(double reportTime, FILE* file)
//
//  Input:   reportTime = elapsed simulation time (millisec)
//           file = ptr. to ascii output file
//  Output:  none
//  Purpose: writes computed node results to ascii file.
//
{
    int j;
    int k;
    // --- find where current reporting time lies between latest routing times
    double f = (reportTime - OldRoutingTime) /
               (NewRoutingTime - OldRoutingTime);

    // --- write node results to file
    for (j=0; j<Nobjects[NODE]; j++)
    {
        // --- retrieve interpolated results for reporting time & write to file
        node_getResults(j, f, NodeResults);
        if (Node[j].rptFlag)
        {
            for (k = 0; k < NumNodeVars; k++)
            {
                fprintf(file, "%g ", NodeResults[k]);
            }
            fprintf(file, "%s ", Node[j].ID);
          //  fprintf(file, "\n");
        }
    }
}

//=============================================================================

void output_saveLinkResults_ascii(double reportTime, FILE* file)
//
//  Input:   reportTime = elapsed simulation time (millisec)
//           file = ptr. to binary output file
//  Output:  none
//  Purpose: writes computed link results to binary file.
//
{
    int j;
    int k;
    double f;
    //double z;

    // --- find where current reporting time lies between latest routing times
    f = (reportTime - OldRoutingTime) / (NewRoutingTime - OldRoutingTime);

    // --- write link results to file
    for (j=0; j<Nobjects[LINK]; j++)
    {
        // --- retrieve interpolated results for reporting time & write to file
        if (Link[j].rptFlag)
        {
            link_getResults(j, f, LinkResults);
            for (k = 0; k < NumLinkVars; k++)
            {
                fprintf(file, "%g ", LinkResults[k]);
            }
            fprintf(file, "%s ", Link[j].ID);
        }
    }
}

//=============================================================================

void output_saveAvgResults_ascii(FILE* file)
{
    int i, j, k;

    // --- examine each reportable node
    for (i = 0; i < NumNodes; i++)
    {
        // --- determine the node's average results
        for (j = 0; j < NumNodeVars; j++)
        {
            NodeResults[j] = AvgNodeResults[i].xAvg[j] / Nsteps;
        }

        // --- save average results to file
        for (k = 0; k < NumNodeVars; k++)
        {
            fprintf(file, "%g ", NodeResults[k]);
        }
    }

    // --- examine each reportable link
    for (i = 0; i < NumLinks; i++)
    {
        // --- determine the link's average results
        for (j = 0; j < NumLinkVars; j++)
        {
            LinkResults[j] = AvgLinkResults[i].xAvg[j] / Nsteps;
        }

        // --- save average results to file
        for (k = 0; k < NumLinkVars; k++)
        {
            fprintf(file, "%g ", LinkResults[k]);
        }
    }
}
