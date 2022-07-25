% _SWMM_subcatch_out
% script to obtain time series from from rainfall simulations from swmm to
% swmm-heat
% input: *.INP, *.OUT
% output: MINUHET-SWMMHEAT Input files
% to do: **
% Alejandro Figueroa Eawag 7/23/2021, based on Frank Blumensaat, ETHZ, T. Frey
function SWMM_subcatch_out(filename_in,filename_out,outpath)
%% 0 - ini
%clear all; close all;
%cd('C:\Users\figueral\Documents\Programing\Institution\2020_shx\04_workspace\_swmm_minu\') %needs to be adapted | required!
%currentFolder = pwd;
%addpath(genpath(fullfile(pwd)));
%addpath(fullfile(['C:\Users\Blumensaat\Documents\MATLAB\MY_FUNCTIONS\_readINP']));
set(0,'DefaultFigureWindowStyle','docked');
set(0,'DefaultFigureWindowStyle','normal');

%% 1 - read node network structure from *.INP
% do this to get the nodes, coordinates and links
%mdlName = '210624_faf_css_apr20_v03_SCall_xs_gampt.inp';
mdlName = filename_in;
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
%%
linktable = conduitslist;
idxdel = ismissing(linktable);
linktable(idxdel(:,3),:) = [];
linktable.Properties.VariableNames{1} = 'link';
linktable.link = char(linktable.link);
linktable.Properties.VariableNames{2} = 'donor';
linktable.donor = char(linktable.donor);
linktable.Properties.VariableNames{3} = 'acceptor';
linktable.acceptor = char(linktable.acceptor);
linktable.Properties.VariableNames{4} = 'length';
linktable.length = str2double(linktable.length);

% for wildbach do this
%linktable = linktable(1:26,:);


%% 3 - process conduit data for mesh (node-edge)
linktable = conduitslist;
idxdel = ismissing(linktable);
linktable(idxdel(:,3),:) = [];
linktable.Properties.VariableNames{1} = 'link';
linktable.link = char(linktable.link);
linktable.Properties.VariableNames{2} = 'donor';
linktable.donor = char(linktable.donor);
linktable.Properties.VariableNames{3} = 'acceptor';
linktable.acceptor = char(linktable.acceptor);
linktable.Properties.VariableNames{4} = 'length';
linktable.length = str2double(linktable.length);

% for wildbach do this
%linktable = linktable(1:26,:);
%% 4 - read simulation results from *.OUT file (flow subcatchments) using readswmmout3.m
%datapath_outfile = fullfile([mdlName(1:end-3),'out']);
%season="first";
%datapath_outfile = fullfile([append(season,'_faf_css_apr20_v03_SCall_xs_gampt.out')]);
datapath_outfile = filename_out;
[d] =  readswmmout3_oldswmm('open',datapath_outfile);
% pre-define i) period and ii) parameter for which data are relevant
fromidx = 1;
toidx = d.Nperiods; %d.Nperiods is the maxiumum number of periods that can be read
parameter = 'runoff';
% create an itemlist from all nodes and define the parameter to be red out
itemlist = convertStringsToChars(join([repmat("catch",d.nCatch,1),d.idCatch,repmat(parameter,d.nCatch,1)]));
ids  = d.idCatch; unit = 'lps';
% read data for elements and attributes as specified in 'itemlist'
[err,res,unitlist] =  readswmmout3_oldswmm('getitems',d,[fromidx,toidx],itemlist,unit);
% define startTimeOffset due to deviation in readswmmout3.m
%StartTimeOffset = datenum('30-Dec-1899')+d.starttime;
%simRes_Flow = [res(:,1)+StartTimeOffset res(:,2:end)];



datetime(d.starttime,'ConvertFrom','excel');
%StartTimeOffset = datenum('30-Dec-1899')+d.starttime;
%datetime(StartTimeOffset,'ConvertFrom','excel');
StartTimeOffset = d.starttime +  res(2,1) - res(1,1)+datenum('30-Dec-1899');
simRes = [res(:,1)+StartTimeOffset res(:,2:end)];
%simRes(:,1) =  datestr(simRes(:,1));
simres2pre=[table(datestr(simRes(:,1))), array2table(simRes)];




% simRes_Flow = table(simRes_Flow);
% 'VariableNames',join([repmat("n_",d.nNode,1),d.idNode]

%% 5 - Generate FLOW timeseries
% COORDINATES
%datapath_out = append('C:\Users\figueral\Documents\Programing\Institution\2020_shx\04_workspace\_swmm_minu\_swmm_sc_out\_',season,'_season\');
datapath_out = outpath;
%[n,mfrom] = month(from(2:11));
%dfrom = num2str(day(from(2:11)));
%[n,mto] = month(to(2:11));
%dto = num2str(day(to(2:11)));
%dayear = year(from(2:11));
%k = 0;
%N = numel(Flow_sim_M.Properties.VariableNames);
%tic;
%datestr(simRes_Flow(1:10,1))
%Flow_sim_M1=timetable2table(Flow_sim_M1);

%prepare output
sublist_unique=unique(subcatchlist.Outlet);
%agregate flow at nodes
table_size = [ size(simres2pre,1) size(sublist_unique,1)];
vartyp = strings([size(sublist_unique,1) 1]) + "double";
out_nodef = table('Size', table_size, 'VariableTypes', vartyp);
nsize=size(subcatchlist,1);
for i=1:nsize

node_pos=find(strcmp(sublist_unique,subcatchlist.Outlet(i)));

out_nodef(:,node_pos)=table(table2array(out_nodef(:,node_pos))+table2array(simres2pre(:,i+2)));

end

date = datestr(table2cell(simres2pre(:,1)),'mm/dd/yyyy');
time = datestr(table2cell(simres2pre(:,1)),'HH:MM');
nsize = size(sublist_unique,1);
for i=1:nsize
    clc;
%    k = showTimeToCompletion(j./N,k);
nodename = sublist_unique(i);%Flow_sim_M.Properties.VariableNames(j);
filename_flow_out = join([nodename,'_flow','.txt'],'');
filepath_out = join([datapath_out,filename_flow_out],'');
% Creating file to be written to
fileID = fopen(char(filepath_out),'w+');
%formatSpec = '%s\t%s\t%s\n';
formatSpec = '%s %s\t%f\r\n';
%y_out = timetable2table(Flow_sim_M(:,j));
%y_out(isnat(y_out.Time),:) = [];
%for i=1:size(y_out,1)
%    t_out =  table2array(y_out(i,1));
%    y_out2 = table2array(y_out(i,2));
%fprintf(fileID, formatSpec, datestr(t_out,'mm/dd/yyyy'),datestr(t_out,'HH:MM'),num2str(y_out2));
%end

%fprintf(fileID, formatSpec, datestr(Flow_sim_M1.Time(:),'mm/dd/yyyy'),datestr(Flow_sim_M1.Time(:),'HH:MM'))%,num2str(flow_tab(:,i)));
flow=table2array(out_nodef(:,i));
for j = 1:size(time,1)
fprintf(fileID,formatSpec, date(j,:),time(j,:),flow(j));
end
fclose(fileID);
end
end

