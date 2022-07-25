%% MINUHET_master 
% script to read and write results from MINUHET as nodal temperature text files for SWMM HEAT
% 
% AF, 10/11/2021
%clear all; close all;
function Minuhet_master (inityear, initmonth, initday, inithour, initmin, initsec, ...
                         endyear, endmonth, endday, endhour, endmin, endsec, ...
                         binary,  abspath, auxpath1,auxpath2, swmminp, ...                     
                         soil1, soil2, soil3, soil4, soil5, soil6, ...
                         soil7, soil8, soil9, soil10, soil11, soil12) 
%addpath(genpath("C:\Users\figueral\Documents\Programing\Institution\2020_shx\04_workspace\test_framework"));

%abspath="C:\Users\figueral\Documents\Programing\Institution\2020_shx\04_workspace\test_framework";

%abspath="Q:/Abteilungsprojekte/eng/SWWData/SWMM-HEAT/Framework_template";
%auxpath1="ReferenceFullNetwork";
%auxpath2= "ReferenceMINUHET_ReferencePC_Reference_20190223-20190321";

%swmminp="210624_faf_css_apr20_v03_SCall_xs_gampt";
warning('off','all')
binary=str2num(binary);
if (binary==1)
    ascii=0;
else
    ascii=1;
end
inpfile=strcat(swmminp,".inp");
%auxpath="case1";
%TR = [datetime(2019,04,21,00,00,00);datetime(2019,05,15,00,00,00)];
%prompt='time init ';
%str=input(prompt)
%  inityear="2019";
%  initmonth="02";
%  initday="21";
%  inithour="01";
%  initmin="01";
%  initsec="00";
%  endyear="2019";
%  endmonth="03";
%  endday="20";
%  endhour="00";
%  endmin="00";
%  endsec="00";
timeinit=[str2num(inityear),str2num(initmonth), str2num(initday), ...
          str2num(inithour), str2num(initmin), str2num(initsec)];
%datetime(timeinit)
timeinit=datetime(timeinit);
%timeend=TR(2);
timeend=[str2num(endyear),str2num(endmonth), str2num(endday), ...
          str2num(endhour), str2num(endmin), str2num(endsec)];
%datetime(timeend)
timeend=datetime(timeend);

%soiltemp=[8.3;7.1;9.1;10.8;12.1;16.0;19.3;20.0;20.5;18.0;13.1;9.5];
soiltemp=[str2num(soil1); str2num(soil2); str2num(soil3); str2num(soil4); ...
         str2num(soil5); str2num(soil6); str2num(soil7); str2num(soil8); ...
         str2num(soil9); str2num(soil10); str2num(soil11); str2num(soil12)];

%read swmm input file (extract subcatchment information) and create input
%files for MINUHET
fprintf("files for MINUHET");
[subcatchlist] = MINUHET_SWMMH(inpfile, abspath, auxpath2, timeinit, timeend); 

%prepare minuhet weather data
fprintf("prepare weather files for MINUHET");
Input_2_MINUHET(abspath, auxpath2, timeinit, timeend);

%run minuhet simulation and aggregate outputs
fprintf("run minuhet simulation and aggregate outputs");
MINUHET_Read_output(subcatchlist, abspath, auxpath2);

%run runoff simulation with swmm
%abspath="Q:\Abteilungsprojekte\eng\SWWData\SWMM-HEAT\Framework_template";
%addpath(strcat(abspath,"\Codes\Matlab\Swmm"));
%addpath(strcat(abspath,"\Codes\Matlab\Swmm\code_old_swmm"));
fprintf("run runoff simulation with swmm");
swmm_rainfall(swmminp,abspath,auxpath2);

%perform mixing of runoff and temperature (final timeseries)
fprintf("perform mixing of runoff and temperature (final timeseries)");
SWMM_mix_time_series(subcatchlist,inpfile, abspath, auxpath1, auxpath2,  timeinit, timeend, ascii, soiltemp)
end