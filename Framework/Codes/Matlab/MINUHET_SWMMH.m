% _vizNetwRes1
% script to create minuhet files 
% input: *.INP, *.OUT
% output: MINUHET-SWMMHEAT Input files
% to do: **
% Alejandro Figueroa Eawag 7/23/2021, based on Frank Blumensaat, ETHZ, T. Frey

%% 0 - ini
%%clear all; close all;
%%cd('C:\Users\figueral\Documents\Programing\Institution\2020_shx\04_workspace\_swmm_minu\') %needs to be adapted | required!
function [subcatchlist] = MINUHET_SWMMH(inpfile, abspath, auxpath, timeinit, timeend)
%currentFolder = pwd;
%addpath(genpath(fullfile(pwd)));
%addpath(fullfile(['C:\Users\Blumensaat\Documents\MATLAB\MY_FUNCTIONS\_readINP']));
set(0,'DefaultFigureWindowStyle','docked');
set(0,'DefaultFigureWindowStyle','normal');
% datetime of simulation
%
TR = [timeinit; timeend];
%scenarioname=auxpath;
%% 1 - read node network structure from *.INP
% do this to get the nodes, coordinates and links
%mdlName = '210624_faf_css_apr20_v03_SCall_xs_gampt.inp';



% abspath="C:\Users\figueral\Documents\Programing\Institution\2020_shx\04_workspace\test_framework";
% inpfile="210624_faf_css_apr20_v03_SCall_xs_gampt.inp";
% auxpath="case1";


%if (auxpath == "")
%    mdlName = strcat(abspath,'\MINUHET\Scenarios\',inpfile);
%else
%    mdlName = strcat(abspath,'\MINUHET\Scenarios\',auxpath,'\',inpfile);
%end
mdlName = inpfile;
datapath_inpfile = fullfile(mdlName);

% // to be revised: integrate readINP to efficiently read INP file
% [n o s c xs w p co FileName PathName] = readINP;

% ~~~~~~
% Open input template model to read COORDINATES // revise
fid_inpfile = fopen(datapath_inpfile,'r'); 
coordinatelist = struct();
line_counter = 0;
startcopying = 0; 
j = 1;
for i=1:10000
  % get the current line
  tline = fgetl(fid_inpfile);
  % end copying
  if strcmp(tline,'[VERTICES]')
     break
  end
  % start copying file if 
  if strcmp(tline,'[COORDINATES]')
      startcopying = 1; 
      continue
  end
  % skip the next line
  if startcopying == 1 | startcopying == 2
      startcopying = startcopying+1;
      continue
  end
    % break if reaching end of file
  if ~ischar(tline)
     break 
  end
  % if startcopying true
  if startcopying == 3
       t_line_copy = split(tline);
       try
       coordinatelist.node(j) =  t_line_copy(1);
       coordinatelist.x(j) =  t_line_copy(3);
       coordinatelist.y(j) =  t_line_copy(2);
       catch ME
       end
       % increase the field idx
       j =j+1;
  end
end
status = fclose(fid_inpfile);

% ~~~~~~
% Open input template model to read CONDUITS // revise
fid_inpfile = fopen(datapath_inpfile,'r'); 
conduitslist = table(string(''),string(''),string(''),string(''));
line_counter = 0;
startcopying = 0; 
j = 1;
for i=1:10000
  % get the current line
  tline = fgetl(fid_inpfile);
  % end copying
  %if strcmp(tline,'[POLLUTANTS]')
  if strcmp(tline,'[PUMPS]')
     break
  end
  % start copying file if 
  if strcmp(tline,'[CONDUITS]')
      startcopying = 1; 
      continue
  end
  % skip the next line
  if startcopying == 1 | startcopying == 2
      startcopying = startcopying+1;
      continue
  end
    % break if reaching end of file
  if ~ischar(tline)
     break 
  end
  % if startcopying true
  if startcopying == 3
       t_line_copy = split(tline);
       try
%            if size(t_line_copy,1) == 3
       conduitslist(j,1) =  t_line_copy(1);
%        a = split(t_line_copy(1),'-');
       conduitslist(j,2) = t_line_copy(2);
       conduitslist(j,3) =  t_line_copy(3);
       conduitslist(j,4) =  t_line_copy(4);
%            else
               
%            end
       catch ME
       end
       % increase the field idx
       j =j+1;
       
  end
end
status = fclose(fid_inpfile);

% ~~~~~~
%Obtain isize
fid_inpfile = fopen(datapath_inpfile,'r'); 
line_counter = 0;
startcopying = 0; 
j = 1;
for i=1:10000
  % get the current line
  tline = fgetl(fid_inpfile);
  % end copying
  %if strcmp(tline,'[POLLUTANTS]')
  if strcmp(tline,'[SUBAREAS]')
     break
  end
  % start copying file if 
  if strcmp(tline,'[SUBCATCHMENTS]')
      startcopying = 1; 
      continue
  end
  % skip the next line
  if startcopying == 1 | startcopying == 2
      startcopying = startcopying+1;
      continue
  end
    % break if reaching end of file
  if ~ischar(tline)
     break 
  end
  % if startcopying true
  if startcopying == 3
       t_line_copy = split(tline);
       try
%            else
               
%            end
       catch ME
       end
       % increase the field idx
       j =j+1;
       
  end
end
sizecatchlist = j-1;
status = fclose(fid_inpfile);

% Open input template model to read Subcatchments // revise
fid_inpfile = fopen(datapath_inpfile,'r'); 
varNames = {'Name' 'Rain Gage' 'Outlet' 'Area' 'Imperv' 'Width' 'Slope' 'CurbLen'};
varTypes={'string' 'string' 'string' 'double' 'double' 'double' 'double' 'double'};
subcatchlist = table('Size',[sizecatchlist 8],'VariableTypes', varTypes,'VariableNames', varNames);
line_counter = 0;
startcopying = 0; 
j = 1;
for i=1:10000
  % get the current line
  tline = fgetl(fid_inpfile);
  % end copying
  %if strcmp(tline,'[POLLUTANTS]')
  if strcmp(tline,'[SUBAREAS]')
     break
  end
  % start copying file if 
  if strcmp(tline,'[SUBCATCHMENTS]')
      startcopying = 1; 
      continue
  end
  % skip the next line
  if startcopying == 1 | startcopying == 2
      startcopying = startcopying+1;
      continue
  end
    % break if reaching end of file
  if ~ischar(tline)
     break 
  end
  % if startcopying true
  if startcopying == 3
       t_line_copy = split(tline);
       try
%            if size(t_line_copy,1) == 3
       subcatchlist(j,1) =  t_line_copy(1);
%        a = split(t_line_copy(1),'-');
       subcatchlist(j,2) = t_line_copy(2);
       subcatchlist(j,3) =  t_line_copy(3);
       subcatchlist.Area(j) =  str2double(t_line_copy(4));
       subcatchlist.Imperv(j) =  str2double(t_line_copy(5));
       subcatchlist.Width(j) = str2double(t_line_copy(6));
       subcatchlist.Slope(j) =  str2double(t_line_copy(7));
       subcatchlist.CurbLen(j) =  str2double(t_line_copy(8));
%            else
               
%            end
       catch ME
       end
       % increase the field idx
       j =j+1;
       
  end
end
status = fclose(fid_inpfile);

% ~~~~~~
% Open input template model to read SUBAREAS // revise
fid_inpfile = fopen(datapath_inpfile,'r'); 
varNames = {'Subcatchment' 'NImperv' 'NPerv' 'SImperv' 'SPerv' 'PctZero' 'RouteTo'};
varTypes={'string' 'double' 'double' 'double' 'double' 'double' 'string'};
subareaslist = table('Size',[sizecatchlist 7],'VariableTypes', varTypes, 'VariableNames', varNames);
line_counter = 0;
startcopying = 0; 
j = 1;
for i=1:10000
  % get the current line
  tline = fgetl(fid_inpfile);
  % end copying
  %if strcmp(tline,'[POLLUTANTS]')
  if strcmp(tline,'[INFILTRATION]')
     break
  end
  % start copying file if 
  if strcmp(tline,'[SUBAREAS]')
      startcopying = 1; 
      continue
  end
  % skip the next line
  if startcopying == 1 | startcopying == 2
      startcopying = startcopying+1;
      continue
  end
    % break if reaching end of file
  if ~ischar(tline)
     break 
  end
  % if startcopying true
  if startcopying == 3
       t_line_copy = split(tline);
       try
%            if size(t_line_copy,1) == 3
       subareaslist(j,1) =  t_line_copy(1);
%        a = split(t_line_copy(1),'-');
       subareaslist.NImperv(j) = str2double(t_line_copy(2));
       subareaslist.NPerv(j) =  str2double(t_line_copy(3));
       subareaslist.SImperv(j) =  str2double(t_line_copy(4));
       subareaslist.SPerv(j) =  str2double(t_line_copy(5));
       subareaslist.PctZero(j) = str2double(t_line_copy(6));
       subareaslist.RouteTo(j) =  t_line_copy(7);
       catch ME
       end
       % increase the field idx
       j =j+1;
       
  end
end
status = fclose(fid_inpfile);

% ~~~~~~
% Open input template model to read INFILTRATION MODEL
fid_inpfile = fopen(datapath_inpfile,'r'); 
line_counter = 0;
startcopying = 0; 
for i=1:20
  % get the current line
  tline = deblank(fgetl(fid_inpfile));
  % end copying
  %if strcmp(tline,'[POLLUTANTS]')
   if startsWith(tline,'INFILTRATION')
          if endsWith(tline,'HORTON')
              infilt=1;
          end
          if endsWith(tline,'GREEN_AMPT')
              infilt=2;
          end
   end
    % break if reaching end of file
  if ~ischar(tline)
     break 
  end
end
status = fclose(fid_inpfile);

% ~~~~~
% Open input template model to read INFILTRATION (HORTON) // revise
if infilt == 1
fid_inpfile = fopen(datapath_inpfile,'r'); 
varNames = {'Subcatchment' 'MaxRate' 'MinRate' 'Decay' 'DryTime' 'MaxInfil'};
varTypes={'string' 'double' 'double' 'double' 'double' 'double'};
infillist = table('Size',[sizecatchlist 6],'VariableTypes', varTypes, 'VariableNames', varNames);
line_counter = 0;
startcopying = 0; 
j = 1;
for i=1:10000
  % get the current line
  tline = fgetl(fid_inpfile);
  % end copying
  %if strcmp(tline,'[POLLUTANTS]')
  if strcmp(tline,'[JUNCTIONS]')
     break
  end
  % start copying file if 
  if strcmp(tline,'[INFILTRATION]')
      startcopying = 1; 
      continue
  end
  % skip the next line
  if startcopying == 1 | startcopying == 2
      startcopying = startcopying+1;
      continue
  end
    % break if reaching end of file
  if ~ischar(tline)
     break 
  end
  % if startcopying true
  if startcopying == 3
       t_line_copy = split(tline);
       try
%            if size(t_line_copy,1) == 3
       infillist(j,1) =  t_line_copy(1);
       infillist.MaxRate(j) = str2double(t_line_copy(2));
       infillist.MinRate(j) =  str2double(t_line_copy(3));
       infillist.Decay(j) =  str2double(t_line_copy(4));
       infillist.DryTime(j) =  str2double(t_line_copy(5));
       infillist.MaxInfil(j) = str2double(t_line_copy(6));
       catch ME
       end
       % increase the field idx
       j =j+1;
       
  end
end
status = fclose(fid_inpfile);
end



% ~~~~~
% Open input template model to read INFILTRATION (GREEN-AMPT) // revise
if infilt == 2
fid_inpfile = fopen(datapath_inpfile,'r'); 
varNames = {'Subcatchment' 'PSI' 'Ksat' 'IMD'};
varTypes={'string' 'double' 'double' 'double'};
infillist = table('Size',[sizecatchlist 4],'VariableTypes', varTypes, 'VariableNames', varNames);
line_counter = 0;
startcopying = 0; 
j = 1;
for i=1:10000
  % get the current line
  tline = fgetl(fid_inpfile);
  % end copying
  %if strcmp(tline,'[POLLUTANTS]')
  if strcmp(tline,'[JUNCTIONS]')
     break
  end
  % start copying file if 
  if strcmp(tline,'[INFILTRATION]')
      startcopying = 1; 
      continue
  end
  % skip the next line
  if startcopying == 1 | startcopying == 2
      startcopying = startcopying+1;
      continue
  end
    % break if reaching end of file
  if ~ischar(tline)
     break 
  end
  % if startcopying true
  if startcopying == 3
       t_line_copy = split(tline);
       try
%            if size(t_line_copy,1) == 3
       infillist(j,1) =  t_line_copy(1);
       infillist.PSI(j) = str2double(t_line_copy(2));
       infillist.Ksat(j) =  str2double(t_line_copy(3));
       infillist.IMD(j) =  str2double(t_line_copy(4));
       catch ME
       end
       % increase the field idx
       j =j+1;
       
  end
end
status = fclose(fid_inpfile);
end
%% 2 - Create MINUHET files
%% Create file name
%datestr(x2mdate(36358.00000))
%datestr(x2mdate(36373.00000))

%create folder and subfolders
%
if not(isfolder(strcat(abspath,"\MINUHET")))
    mkdir(strcat(abspath,"\MINUHET"))
end

if not(isfolder(strcat(abspath,"\MINUHET\Minu_sim")))
    mkdir(strcat(abspath,"\MINUHET\Minu_sim"))
end

if ~(auxpath == "")
    if not(isfolder(strcat(abspath,"\MINUHET\Minu_sim\",auxpath)))
    mkdir(strcat(abspath,"\MINUHET\Minu_sim\",auxpath))
    end
    outpath=strcat(abspath,"\MINUHET\Minu_sim\",auxpath);
else    
    outpath=strcat(abspath,"\MINUHET\Minu_sim");
end

%Define t_start and t_out

WSTART = num2str(m2xdate(TR(1),0),'%10.5f');
WSTOP = num2str(m2xdate(TR(2),0),'%10.5f');
%impervious file

for i=1:sizecatchlist
subcatchlist.Imperv(i)=subcatchlist.Imperv(i)/100;
if extractBetween(subcatchlist.Name(i),2,2) == '0'
subcatchlist.Name(i)=eraseBetween(subcatchlist.Name(i),2,2);
end
if (strlength(subcatchlist.Name(i))) > 10
subcatchlist.Name(i)=eraseBetween(subcatchlist.Name(i),7,strlength(subcatchlist.Name(i)));
end
%datapath_outfile = fullfile('_minu_simulation','swmm_subcatch_sims',scenarioname,append(subcatchlist.Name(i),'_imp.dat'));
datapath_outfile = fullfile(outpath,append(subcatchlist.Name(i),'_imp.dat'));
outfile=fopen(datapath_outfile,'w');
fprintf(outfile,'&LAND\n');
fprintf(outfile,'SOIL=''C''\n');
fprintf(outfile,'MOIST=''DRY''\n');
fprintf(outfile,'USE=''AS''\n');
fprintf(outfile,'SLOPE=%g\n',subcatchlist.Slope(i)/100.0);
fprintf(outfile,'LENGTH=%g\n',subcatchlist.Area(i)*10000*subcatchlist.Imperv(i)/subcatchlist.Width(i));
fprintf(outfile,'AREA=%g\n',subcatchlist.Area(i)*10000*subcatchlist.Imperv(i));
fprintf(outfile,'SF=0.0\n');
fprintf(outfile,'SHELT=0.0\n');
fprintf(outfile,'SHAD=0.0\n');
fprintf(outfile,'ADAR=0.0\n');%connected rooftop area
fprintf(outfile,'RGAREA=0.0\n');
fprintf(outfile,'RGVOL=0.0\n');
fprintf(outfile,'TREF=20/\n');
fprintf(outfile,'\n');
fprintf(outfile,'&FILE\n');
fprintf(outfile,'ENAME=''%s''\n',subcatchlist.Name(i));
fprintf(outfile,'REG=1\n');
fprintf(outfile,'DSN=3/\n');
fprintf(outfile,'\n');
fprintf(outfile,'&SSTIMES\n');
fprintf(outfile,'ASTART=%s\n',WSTART);
fprintf(outfile,'ASTOP=%s/\n',WSTOP);
status = fclose(outfile);
%pervious file
%datapath_outfile = fullfile('_minu_simulation','swmm_subcatch_sims', scenarioname,append(subcatchlist.Name(i),'_prv.dat'));
datapath_outfile = fullfile(outpath,append(subcatchlist.Name(i),'_prv.dat'));
outfile=fopen(datapath_outfile,'w');
fprintf(outfile,'&LAND\n');
fprintf(outfile,'SOIL=''C''\n');
fprintf(outfile,'MOIST=''DRY''\n');
%row_crop=AG,bare_soil=BS, forest=FR, short_grass=SG, tall_grass=TG
fprintf(outfile,'USE=''SG''\n');
fprintf(outfile,'SLOPE=%g\n',subcatchlist.Slope(i)/100.0);
fprintf(outfile,'LENGTH=%g\n',subcatchlist.Area(i)*10000*(1-subcatchlist.Imperv(i))/subcatchlist.Width(i));
fprintf(outfile,'AREA=%g\n',subcatchlist.Area(i)*10000*(1-subcatchlist.Imperv(i)));
fprintf(outfile,'SF=0.0\n');
fprintf(outfile,'SHELT=0.0\n');
fprintf(outfile,'SHAD=0.0\n');
fprintf(outfile,'ADAR=0.0\n');%connected rooftop area
fprintf(outfile,'RGAREA=0.0\n');
fprintf(outfile,'RGVOL=0.0\n');
fprintf(outfile,'TREF=20/\n');
fprintf(outfile,'\n');
fprintf(outfile,'&FILE\n');
fprintf(outfile,'ENAME=''%s''\n',subcatchlist.Name(i));
fprintf(outfile,'REG=1\n');
fprintf(outfile,'DSN=3/\n');
fprintf(outfile,'\n');
fprintf(outfile,'&SSTIMES\n');
fprintf(outfile,'ASTART=%s\n',WSTART);
fprintf(outfile,'ASTOP=%s/\n',WSTOP);
status = fclose(outfile);
end


%% 3 - Create BAT file for simulation of results
%datapath_outfile = fullfile('_minu_simulation','swmm_subcatch_sims', scenarioname,'minuhet_sim.bat');
datapath_outfile = fullfile(outpath,'minuhet_sim.bat');
outfile=fopen(datapath_outfile,'w');
for i=1:sizecatchlist
prvcsv = append(subcatchlist.Name(i),'_prv.csv');
impcsv = append(subcatchlist.Name(i),'_imp.csv');
fprintf(outfile,'runoff.exe %s %s\n',append(subcatchlist.Name(i),'_prv.dat'),prvcsv);
fprintf(outfile,'runoff.exe %s %s\n',append(subcatchlist.Name(i),'_imp.dat'),impcsv);
%fprintf(outfile,'if EXIST "%s" (\n',prvcsv);
if subcatchlist.Area(i)*10000*subcatchlist.Imperv(i) == 0
fprintf(outfile,'mix.exe %s %s\n',prvcsv,append(subcatchlist.Name(i),'.csv'));
else
    fprintf(outfile,'mix.exe %s %s %s\n',prvcsv,impcsv,append(subcatchlist.Name(i),'.csv'));
end
%fprintf(outfile,') ELSE (\n');
%fprintf(outfile,'mix.exe %s %s %s\n',impcsv,prvcsv,append(subcatchlist.Name(i),'.csv'));
%fprintf(outfile,')\n');
fprintf(outfile,'::\n');
end
status = fclose(outfile);
%write txt for checking
%datapath_outfile = fullfile('_minu_simulation','swmm_subcatch_sims', scenarioname,'minuhet_sim.txt');
datapath_outfile = fullfile(outpath,'minuhet_sim.txt');
outfile=fopen(datapath_outfile,'w');
for i=1:sizecatchlist
prvcsv = append(subcatchlist.Name(i),'_prv.csv');
impcsv = append(subcatchlist.Name(i),'_imp.csv');
fprintf(outfile,'runoff.exe %s %s\n',append(subcatchlist.Name(i),'_prv.dat'),prvcsv);
fprintf(outfile,'runoff.exe %s %s\n',append(subcatchlist.Name(i),'_imp.dat'),impcsv);
%fprintf(outfile,'if EXIST "%s" (\n',prvcsv);
if subcatchlist.Area(i)*10000*subcatchlist.Imperv(i) == 0
    fprintf(outfile,'mix.exe %s %s\n',prvcsv,append(subcatchlist.Name(i),'.csv'));
else
    fprintf(outfile,'mix.exe %s %s %s\n',prvcsv,impcsv,append(subcatchlist.Name(i),'.csv'));
end
%fprintf(outfile,') ELSE (\n');
%fprintf(outfile,'mix.exe %s %s %s\n',impcsv,prvcsv,append(subcatchlist.Name(i),'.csv'));
%fprintf(outfile,')\n');
fprintf(outfile,'::\n');
end
status = fclose(outfile);
save(strcat(abspath,"\MINUHET\",'subcatchlist.mat'),'subcatchlist');
end
%% % 3 - From Synthetic event to swmm time series (RAIN)
% %read synthetic parameters
% mdlName = 'Jan_Dec_2019';
% datapath_inpfile = fullfile(mdlName);
% % ~~~~~~
% fid_inpfile = fopen(datapath_inpfile,'r'); 
% rainlist = struct();
% line_counter = 0;
% startcopying = 0; 
% j = 1;
% for i=1:20
%   % get the current line
%   tline = fgetl(fid_inpfile);
%   % start copying file if 
%   if strcmp(tline,'&WRUN')
%       startcopying = 1;
%       continue
%   end
%   % skip the next line
%   %if startcopying == 1 %| startcopying == 2
%   %    startcopying = startcopying+1;
%    %   continue
%  % end
%     % break if reaching end of file
%   if ~ischar(tline) | j == 4
%      break 
%   end
%   % if startcopying true
%   if startcopying == 1
%        t_line_copy = split(tline);
%        try
%            %read start time
%            if j == 1
%                startime=str2double(eraseBetween(string(t_line_copy(1)),1,7));
%            end
%            %read end time
%            if j == 2
%                endtime=str2double(eraseBetween(string(t_line_copy(1)),1,6));
%            end
%            %read timestep
%            if j == 3
%                timestep=str2double(eraseBetween(eraseBetween(string(t_line_copy(1)),1,6),5,5));
%            end
%              
%        catch ME
%        end
%        % increase the field idx
%        j =j+1;
%   end
% end
% status = fclose(fid_inpfile);
% 
% 
% %read synthetic data
% mdlName = 'Synthetic01.dat';
% datapath_inpfile = fullfile(mdlName);
% % ~~~~~~
% fid_inpfile = fopen(datapath_inpfile,'r'); 
% rainlist = struct();
% line_counter = 0;
% startcopying = 0; 
% j = 1;
% for i=1:10000
%   % get the current line
%   tline = fgetl(fid_inpfile);
%   % start copying file if 
%   if strcmp(tline,'&WDATA')
%       startcopying = 1;
%       continue
%   end
%   % skip the next line
%   if startcopying == 1 %| startcopying == 2
%       startcopying = startcopying+1;
%      continue
%   end
%     % break if reaching end of file
%   if ~ischar(tline) 
%      break 
%   end
%   % if startcopying true
%   if startcopying == 2
%        t_line_copy = split(tline);
%        try
%           lasts=strlength(t_line_copy(5));
%        precipitation(j) =  str2double(eraseBetween(string(t_line_copy(5)),lasts,lasts));        
%        catch ME
%        end
%        % increase the field idx
%        j =j+1;
%   end
% end
% status = fclose(fid_inpfile);
% 
% %create table with timeseries
% startime=datetime(startime,'ConvertFrom','excel');
% endtime=datetime(endtime,'ConvertFrom','excel');
% 
% timev = startime:minutes(timestep):endtime;
% 
% 
% %write txt for swmm simulation
% datapath_outfile = fullfile('synthetic_swmm.dat');
% outfile=fopen(datapath_outfile,'w');
% fprintf(outfile,'EPASWMM Time Series Data\n');
% fprintf(outfile,'rain in [mm]\n');
% for i=1:size(timev,2)-1
% fprintf(outfile,'r02 %g %g %g %g %g %g\n',year(timev(i)),month(timev(i)),day(timev(i)),hour(timev(i)),minute(timev(i)),precipitation(i)*10);
% end
% status = fclose(outfile);
% 
% 
% 
% %% 3 - From SWMM event to MINUHET time series (RAIN)
% %read synthetic parameters
% mdlName = 'Synthetic01.dat';
% datapath_inpfile = fullfile(mdlName);
% % ~~~~~~
% fid_inpfile = fopen(datapath_inpfile,'r'); 
% rainlist = struct();    
% line_counter = 0;
% startcopying = 0; 
% j = 1;
% for i=1:20
%   % get the current line
%   tline = fgetl(fid_inpfile);
%   % start copying file if 
%   if strcmp(tline,'&WRUN')
%       startcopying = 1;
%       continue
%   end
%   % skip the next line
%   %if startcopying == 1 %| startcopying == 2
%   %    startcopying = startcopying+1;
%    %   continue
%  % end
%     % break if reaching end of file
%   if ~ischar(tline) | j == 4
%      break 
%   end
%   % if startcopying true
%   if startcopying == 1
%        t_line_copy = split(tline);
%        try
%            %read start time
%            if j == 1
%                startime=str2double(eraseBetween(string(t_line_copy(1)),1,7));
%            end
%            %read end time
%            if j == 2
%                endtime=str2double(eraseBetween(string(t_line_copy(1)),1,6));
%            end
%            %read timestep
%            if j == 3
%                timestep=str2double(eraseBetween(eraseBetween(string(t_line_copy(1)),1,6),5,5));
%            end
%              
%        catch ME
%        end
%        % increase the field idx
%        j =j+1;
%   end
% end
% status = fclose(fid_inpfile);
% 
% 
% %read synthetic data
% mdlName = 'Synthetic01.dat';
% datapath_inpfile = fullfile(mdlName);
% % ~~~~~~
% fid_inpfile = fopen(datapath_inpfile,'r'); 
% rainlist = struct();
% line_counter = 0;
% startcopying = 0; 
% j = 1;
% for i=1:10000
%   % get the current line
%   tline = fgetl(fid_inpfile);
%   % start copying file if 
%   if strcmp(tline,'&WDATA')
%       startcopying = 1;
%       continue
%   end
%   % skip the next line
%   if startcopying == 1 %| startcopying == 2
%       startcopying = startcopying+1;
%      continue
%   end
%     % break if reaching end of file
%   if ~ischar(tline) 
%      break 
%   end
%   % if startcopying true
%   if startcopying == 2
%        t_line_copy = split(tline);
%        try
%           lasts=strlength(t_line_copy(5));
%        precipitation(j) =  str2double(eraseBetween(string(t_line_copy(5)),lasts,lasts));        
%        catch ME
%        end
%        % increase the field idx
%        j =j+1;
%   end
% end
% status = fclose(fid_inpfile);
% 
% %create table with timeseries
% startime=datetime(startime,'ConvertFrom','excel');
% endtime=datetime(endtime,'ConvertFrom','excel');
% 
% timev = startime:minutes(timestep):endtime;
% 
% 
% %write txt for swmm simulation
% datapath_outfile = fullfile('synthetic_swmm.dat');
% outfile=fopen(datapath_outfile,'w');
% fprintf(outfile,'EPASWMM Time Series Data\n');
% fprintf(outfile,'rain in [mm]\n');
% for i=1:size(timev,2)-1
% fprintf(outfile,'r02 %g %g %g %g %g %g\n',year(timev(i)),month(timev(i)),day(timev(i)),hour(timev(i)),minute(timev(i)),precipitation(i)*10);
% end
% status = fclose(outfile);