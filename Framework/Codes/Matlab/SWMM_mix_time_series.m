% _SWMMH_mix_time_series
% script to mix WaterHub and Minuhet/SWMM flow and temperature
% output: SWMMHEAT Input files
% to do: **
% Alejandro Figueroa Eawag 7/28/2021, based on Frank Blumensaat, ETHZ, T. Frey
%%
% clear all; close all;
% cd('C:\Users\figueral\Documents\Programing\Institution\2020_shx\04_workspace\_swmm_minu\') %needs to be adapted | required!
% currentFolder = pwd;
% addpath(genpath(fullfile(pwd)));
% %addpath(fullfile(['C:\Users\Blumensaat\Documents\MATLAB\MY_FUNCTIONS\_readINP']));
% set(0,'DefaultFigureWindowStyle','docked');
% set(0,'DefaultFigureWindowStyle','normal');
function SWMM_mix_time_series(subcatchlist,inpfile, abspath, auxpath1, auxpath2, timeinit, timeend,ascii,soiltemp)
%% read inflow nodes
%mdlName = '210624_faf_css_apr20_v03_SCall_xs_gampt_SH.inp';
%if (auxpath == "")
%    mdlName = strcat(abspath,'\Scenarios\',inpfile,'.inp');
%else
%    mdlName = strcat(abspath,'\Scenarios\',auxpath,'\',inpfile,'.inp');
%end

mdlName = inpfile;
datapath_inpfile = fullfile(mdlName);
%datapath_inpfile=strcat("Q:\Abteilungsprojekte\eng\SWWData\SWMM-HEAT\Framework_template\Data\",datapath_inpfile);
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

% Open input template model to read Inflows // revise
fid_inpfile = fopen(datapath_inpfile,'r'); 
varNames = {'NODE' 'CONSTITUENT' 'TIME SERIES' 'Type' 'Mfactor' 'Sfactor'};
varTypes={'string' 'string' 'string' 'string' 'double' 'double'};
inflows = table('Size',[sizecatchlist 6],'VariableTypes', varTypes,'VariableNames', varNames);
line_counter = 0;
startcopying = 0; 
j = 1;
for i=1:10000
  % get the current line
  tline = fgetl(fid_inpfile);
  % end copying
  %if strcmp(tline,'[POLLUTANTS]')
  if strcmp(tline,'[DWF]')
     break
  end
  % start copying file if 
  if strcmp(tline,'[INFLOWS]')
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
           if(strcmp(t_line_copy(2),'FLOW'))
%            if size(t_line_copy,1) == 3
       inflows(j,1) =  t_line_copy(1);
%        a = split(t_line_copy(1),'-');
       inflows(j,2) = t_line_copy(2);
       inflows(j,3) =  t_line_copy(3);
       inflows(j,4) =  t_line_copy(4);
       inflows.Mfactor(j) =  str2double(t_line_copy(5));
       inflows.Sfactor(j) = str2double(t_line_copy(6));
           end
%            else
               
%            end
       catch ME
       end
       % increase the field idx
       j =j+1;
       
  end
end
status = fclose(fid_inpfile);
%% Read subcatchlist and Minuhet temperature outputs
%load('subcatchlist.mat')
sublist_unique=unique(subcatchlist.Outlet);
%TR = [timeinit; timeend];
TR=timerange(timeinit,timeend);
%time range for simulations
%scenario =1;
% season 1
%if scenario ==1
%TR = timerange('04/21/2019 00:00:00','05/15/2019 00:00:01');
%TR = [datetime(2019,04,21,00,00,00);datetime(2019,05,15,00,00,00)];
%nstart_date=datetime("04/20/2019 00:00:00",'InputFormat','MM/dd/yyyy HH:mm:ss');
%scenarioname='scenario1';
%seasonname='first';
%soil_temp=11;
% season 2
%elseif scenario ==2
%TR = timerange('06/27/2019 00:00:00','07/18/2019 00:00:01');
%TR = [datetime(2019,06,27,00,00,00);datetime(2019,07,18,00,00,00)];
%nstart_date=datetime("06/26/2019 00:00:00",'InputFormat','MM/dd/yyyy HH:mm:ss');
%scenarioname='scenario2';
%seasonname='second';
%soil_temp=18;
% season 3
%elseif scenario ==3
%time range for simulations
%TR = timerange('08/27/2019 00:00:00','09/15/2019 00:00:01');
%TR = [datetime(2019,08,27,00,00,00);datetime(2019,09,15,00,00,00)];
%nstart_date=datetime("08/26/2019 00:00:00",'InputFormat','MM/dd/yyyy HH:mm:ss');
%scenarioname='scenario3';
%seasonname='third';
%soil_temp=20;
%end

finalflow=table();
finaltemp=table();

%identify number of files from WH
allFiles = dir(strcat(abspath,"\MINUHET\Scenarios\stitched\",auxpath2,"\INPUT\"));


allNames = { allFiles(~[allFiles.isdir]).name };
allNames = erase(allNames,["residential_","_flow.txt", "_temp.txt","_flow.bin", "_temp.bin"]);
allNames_unique=string(unique(allNames))';
%create array with all the nodes (WH+MINUHET)
node_array=union(allNames_unique,sublist_unique);
node_array(strcmp(node_array, 'change_dates.m')) = [];
% for  all the files to mix

%    size(sublist_unique,1), 
for ifile = 1:size(node_array,1)
    %ifile=1
    currentFolder = pwd;
    %temp from minu
    %datapath= join([currentFolder,'\_minu_simulation\_out_minu\',scenarioname,'\'],'');
    if (auxpath2 == "")
    %mdlName = strcat(abspath,'/Scenarios/',inpfile);
        datapath=strcat(abspath,'\MINUHET\Minu_out\');
    else
        datapath=strcat(abspath,'\MINUHET\Minu_out\',auxpath2,'\');
    end
    fileID_MH = fopen(join([datapath,node_array(ifile),"_temp.txt"],''),'r');
    %join([datapath,sublist_unique(ifile),"_temp.txt"],'')
    
    % read runoff from swmm 
    if ~(auxpath2 == "")
    datapath=strcat(abspath,"\MINUHET\SWMM_rainfall\",auxpath2,'\');
    else    
    datapath=strcat(abspath,"\MINUHET\SWMM_rainfall\");
    end
    %datapath= join([currentFolder,'\_swmm_sc_out\_',seasonname,'_season\'],'');
    % Open the text file.
    fileID_swmm = fopen(join([datapath,node_array(ifile),"_flow.txt"],''),'r');
    
    % read information from WH
    % Open the text file. first flow
    
if ascii==1
    datapath=strcat(abspath,"\MINUHET\Scenarios\stitched\",auxpath2,"\INPUT\");
    fileID_whf = fopen(join([datapath,node_array(ifile),"_flow.txt"],''),'r');
   % % then temperature
    fileID_wht = fopen(join([datapath,node_array(ifile),"_temp.txt"],''),'r');
elseif ascii==0 
    datapath=strcat(abspath,"\MINUHET\Scenarios\stitched\",auxpath2,"\INPUT\");
    fileID_whf = fopen(join([datapath,node_array(ifile),"_flow.bin"],''),'r');
    % then temperature
    fileID_wht = fopen(join([datapath,node_array(ifile),"_temp.bin"],''),'r');
end
    %if file is in WH and MINUHET do the mixing
    
    %check if all files exists
    if (fileID_MH ~= -1) && (fileID_swmm ~= -1) && ...
       (fileID_whf ~= -1) && (fileID_wht ~= -1)
        case_read = 1;
    elseif (fileID_MH ~= -1) && (fileID_swmm ~= -1) && ...
       (fileID_whf == -1) && (fileID_wht == -1)
        case_read = 2;
    elseif (fileID_MH == -1) && (fileID_swmm == -1) && ...
       (fileID_whf ~= -1) && (fileID_wht ~= -1)
        case_read = 3;
    else
        disp([' There is a problem at ',ifile, node_array(ifile)])
        case_read = 4;
    end
    %ifile, node_array(ifile)%,case_read, [fileID_MH,fileID_swmm,fileID_whf,fileID_wht]
    %
    %read and load timeseries
    % Open the text file.
    if (case_read == 1)
formatSpec = '%{MM/dd/yyyy}D %{HH:mm}D \t%f\r\n';
dataArray = textscan(fileID_MH, formatSpec);
% Close the text file.
fclose(fileID_MH);
% Post processing for unimportable data.
temp_minu = table(dataArray{1:end}, 'VariableNames', {'date','time','value'});
% 
temp_minu.date.Format = 'MM/dd/yyyy HH:mm';
temp_minu.time.Format = 'MM/dd/yyyy HH:mm';
temp_minu_M = table();
temp_minu_M.time = datetime([temp_minu.date+timeofday(temp_minu.time)],'InputFormat','MM/dd/yyyy HH:mm');
temp_minu_M.temp = temp_minu.value;
%generate timetable
temp_minu_M = timetable(temp_minu_M.time,temp_minu_M.temp);
temp_minu_M.Properties.VariableNames = {'temp'};
% create new time vector at 10secs resolution  
dt = seconds(5);
temp_minu_M_5sec = retime(temp_minu_M,'regular','linear','TimeStep',dt);
temp_minu_M_5sec.Time.Format = 'MM/dd/yyyy HH:mm:ss';

% read runoff from swmm and resample
formatSpec = '%{MM/dd/yyyy}D %{HH:mm}D \t%f\r\n';
dataArray = textscan(fileID_swmm, formatSpec);
% Close the text file.
%fclose(fileID_swmm);
% Post processing for unimportable data.
flow_swmm = table(dataArray{:}, 'VariableNames', {'date','time','value'});
% Clear temporary variables
%clearvars filename startRow formatSpec fileID dataArray ans;
% 
flow_swmm.date.Format = 'MM/dd/yyyy HH:mm';
flow_swmm.time.Format = 'MM/dd/yyyy HH:mm';
flow_swmm_M = table();
flow_swmm_M.time = datetime([flow_swmm.date+timeofday(flow_swmm.time)],'InputFormat','MM/dd/yyyy HH:mm');
flow_swmm_M.flow = flow_swmm.value;
%generate timetable
flow_swmm_M = timetable(flow_swmm_M.time,flow_swmm_M.flow);
flow_swmm_M.Properties.VariableNames = {'flow'};
% create new time vector at 10secs resolution  
dt = seconds(5);
flow_swmm_M_5sec = retime(flow_swmm_M,'regular','linear','TimeStep',dt);
flow_swmm_M_5sec.Time.Format = 'MM/dd/yyyy HH:mm:ss';

% read flows and temperature from Bruno WaterHub (same format as previous)
    if ascii==1
    %first flow
    formatSpec = '%{MM/dd/yyyy}D %{HH:mm:ss}D \t%f\r\n';
    dataArray = textscan(fileID_whf, formatSpec);
    % Post processing for unimportable data.
    flow_wh = table(dataArray{1:end}, 'VariableNames', {'date','time','value'});
    % Clear temporary variables
    %clearvars filename startRow formatSpec fileID dataArray ans;
    % 
    flow_wh.date.Format = 'MM/dd/yyyy HH:mm:ss';
    flow_wh.time.Format = 'MM/dd/yyyy HH:mm:ss';
    flow_wh_M = table();
    flow_wh_M.time = datetime([flow_wh.date+timeofday(flow_wh.time)],'InputFormat','MM/dd/yyyy HH:mm:ss');
    flow_wh_M.flow = flow_wh.value;
    elseif ascii==0 
    frewind(fileID_whf);
    m=fread(fileID_whf, 'uint8');
    size(m);
    B = uint8(reshape(m,[12,size(m,1)/12]))';
    year= typecast(reshape(B(:,4:5)',[],1)','uint16');
    date=datetime(year',typecast(B(:,2),'uint8'),typecast(B(:,3),'uint8'), ...
        typecast(B(:,6),'uint8'),typecast(B(:,7),'uint8'),typecast(B(:,8),'uint8'),'Format','MM/dd/yyyy HH:mm:ss');
    flowval= typecast(reshape(B(:,9:12)',[],1)','single')';
    
    flow_wh_M = table();
    flow_wh_M.time= date;
    flow_wh_M.flow= flowval;         
    end
% Close the text file.
fclose(fileID_whf);
%generate timetable
flow_wh_M = timetable(flow_wh_M.time,flow_wh_M.flow);
flow_wh_M.Properties.VariableNames = {'flow'};
% create new time vector at 10secs resolution  
dt = seconds(5);
flow_wh_M_5sec = retime(flow_wh_M,'regular','linear','TimeStep',dt);
flow_wh_M_5sec.Time.Format = 'MM/dd/yyyy HH:mm:ss';

% second temperature
if ascii==1
    %first flow
formatSpec = '%{MM/dd/yyyy}D %{HH:mm:ss}D \t%f\r\n';
dataArray = textscan(fileID_wht, formatSpec);
% Post processing for unimportable data.
temp_wh = table(dataArray{1:end}, 'VariableNames', {'date','time','value'});
% Clear temporary variables
%clearvars filename startRow formatSpec fileID dataArray ans;
% 
temp_wh.date.Format = 'MM/dd/yyyy HH:mm:ss';
temp_wh.time.Format = 'MM/dd/yyyy HH:mm:ss';
temp_wh_M = table();
temp_wh_M.time = datetime([temp_wh.date+timeofday(temp_wh.time)],'InputFormat','MM/dd/yyyy HH:mm:ss');
temp_wh_M.temp = temp_wh.value;
    elseif ascii==0 
    frewind(fileID_wht);
    m=fread(fileID_wht, 'uint8');
    size(m);
    B = uint8(reshape(m,[12,size(m,1)/12]))';
    year= typecast(reshape(B(:,4:5)',[],1)','uint16');
    date=datetime(year',typecast(B(:,2),'uint8'),typecast(B(:,3),'uint8'), ...
        typecast(B(:,6),'uint8'),typecast(B(:,7),'uint8'),typecast(B(:,8),'uint8'),'Format','MM/dd/yyyy HH:mm:ss');
    tempval= typecast(reshape(B(:,9:12)',[],1)','single')';
    
    temp_wh_M = table();
    temp_wh_M.time= date;
    temp_wh_M.temp= tempval;         
    end
% Close the text file.
fclose(fileID_wht);
%generate timetable
temp_wh_M = timetable(temp_wh_M.time,temp_wh_M.temp);
temp_wh_M.Properties.VariableNames = {'temp'};
% create new time vector at 10secs resolution  
dt = seconds(5);
temp_wh_M_5sec = retime(temp_wh_M,'regular','linear','TimeStep',dt);
temp_wh_M_5sec.Time.Format = 'MM/dd/yyyy HH:mm:ss';
% Combine all time series (First FLOW, then temperature)

%sublist_unique=unique(subcatchlist.Outlet);
%table_size = [size(flow_swmm_M_5sec,1) size(sublist_unique,1)];
%vartyp = strings([size(sublist_unique,1) 1]) + "double";
%final_flow = table('Size', table_size, 'VariableTypes', vartyp);

%dt = seconds(5);
%totalflow=retime([flow_swmm_M_5sec; flow_wh_M_5sec],'regular',@sum,'TimeStep',dt);
TT = synchronize(flow_wh_M_5sec,flow_swmm_M_5sec,temp_wh_M_5sec,temp_minu_M_5sec,'union','linear');
TT = timetable2table(TT(TR,:));
soiltemparray=soiltemp(month(TT.Time));
totalflow = table(sum([(table2array(TT(:,2))  + table2array(TT(:,3)))],2,'omitnan'));
finalflow(:,ifile)=totalflow;
%temperature
%
totaltemp=table( ... 
                      sum([table2array(TT(:,2)) .* table2array(TT(:,4))          ...
                       table2array(TT(:,3))         .* table2array(TT(:,5))],2,'omitnan')   ./   ...
                      sum([(table2array(TT(:,2))  + table2array(TT(:,3)))],2,'omitnan')  ...
);
%totaltemp.Var1(isnan(totaltemp.Var1)) = soil_temp;
totaltemp.Var1(isnan(totaltemp.Var1)) = soiltemparray(isnan(totaltemp.Var1));
finaltemp(:,ifile)=totaltemp;
%%%%%%%%%%%%%SECOND CASE
    elseif (case_read == 2)
        formatSpec = '%{MM/dd/yyyy}D %{HH:mm}D \t%f\r\n';
dataArray = textscan(fileID_MH, formatSpec);
% Close the text file.
fclose(fileID_MH);
% Post processing for unimportable data.
temp_minu = table(dataArray{1:end}, 'VariableNames', {'date','time','value'});
% 
temp_minu.date.Format = 'MM/dd/yyyy HH:mm';
temp_minu.time.Format = 'MM/dd/yyyy HH:mm';
temp_minu_M = table();
temp_minu_M.time = datetime([temp_minu.date+timeofday(temp_minu.time)],'InputFormat','MM/dd/yyyy HH:mm');
temp_minu_M.temp = temp_minu.value;
%generate timetable
temp_minu_M = timetable(temp_minu_M.time,temp_minu_M.temp);
temp_minu_M.Properties.VariableNames = {'temp'};
% create new time vector at 10secs resolution  
dt = seconds(5);
temp_minu_M_5sec = retime(temp_minu_M,'regular','linear','TimeStep',dt);
temp_minu_M_5sec.Time.Format = 'MM/dd/yyyy HH:mm:ss';

% read runoff from swmm and resample
formatSpec = '%{MM/dd/yyyy}D %{HH:mm}D \t%f\r\n';
dataArray = textscan(fileID_swmm, formatSpec);
% Close the text file.
fclose(fileID_swmm);
% Post processing for unimportable data.
flow_swmm = table(dataArray{1:end}, 'VariableNames', {'date','time','value'});
% Clear temporary variables
%clearvars filename startRow formatSpec fileID dataArray ans;
% 
flow_swmm.date.Format = 'MM/dd/yyyy HH:mm';
flow_swmm.time.Format = 'MM/dd/yyyy HH:mm';
flow_swmm_M = table();
flow_swmm_M.time = datetime([flow_swmm.date+timeofday(flow_swmm.time)],'InputFormat','MM/dd/yyyy HH:mm');
flow_swmm_M.flow = flow_swmm.value;
%generate timetable
flow_swmm_M = timetable(flow_swmm_M.time,flow_swmm_M.flow);
flow_swmm_M.Properties.VariableNames = {'flow'};
% create new time vector at 10secs resolution  
dt = seconds(5);
flow_swmm_M_5sec = retime(flow_swmm_M,'regular','linear','TimeStep',dt);
flow_swmm_M_5sec.Time.Format = 'MM/dd/yyyy HH:mm:ss';
% add to final table
TT = synchronize(flow_swmm_M_5sec,temp_minu_M_5sec,'union','linear');
TT = timetable2table(TT(TR,:));
soiltemparray=soiltemp(month(TT.Time));
totalflow = TT(:,2);
finalflow(:,ifile)=totalflow;
%temperature
%
totaltemp=TT(:,3);
totaltemp.temp(isnan(totaltemp.temp)) = soiltemparray(isnan(totaltemp.temp));
finaltemp(:,ifile)=totaltemp;
%%%%%%%%%%%%%THIRD CASE
    elseif (case_read == 3)
%first flow

    if ascii==1
    %first flow
    formatSpec = '%{MM/dd/yyyy}D %{HH:mm:ss}D \t%f\r\n';
    dataArray = textscan(fileID_whf, formatSpec);
    % Post processing for unimportable data.
    flow_wh = table(dataArray{1:end}, 'VariableNames', {'date','time','value'});
    % Clear temporary variables
    %clearvars filename startRow formatSpec fileID dataArray ans;
    % 
    flow_wh.date.Format = 'MM/dd/yyyy HH:mm:ss';
    flow_wh.time.Format = 'MM/dd/yyyy HH:mm:ss';
    flow_wh_M = table();
    flow_wh_M.time = datetime([flow_wh.date+timeofday(flow_wh.time)],'InputFormat','MM/dd/yyyy HH:mm:ss');
    flow_wh_M.flow = flow_wh.value;
    elseif ascii==0 
    frewind(fileID_whf);
    m=fread(fileID_whf, 'uint8');
    size(m);
    B = uint8(reshape(m,[12,size(m,1)/12]))';
    year= typecast(reshape(B(:,4:5)',[],1)','uint16');
    date=datetime(year',typecast(B(:,2),'uint8'),typecast(B(:,3),'uint8'), ...
        typecast(B(:,6),'uint8'),typecast(B(:,7),'uint8'),typecast(B(:,8),'uint8'),'Format','MM/dd/yyyy HH:mm:ss');
    flowval= typecast(reshape(B(:,9:12)',[],1)','single')';
    
    flow_wh_M = table();
    flow_wh_M.time= date;
    flow_wh_M.flow= flowval;         
    end
%generate timetable
flow_wh_M = timetable(flow_wh_M.time,flow_wh_M.flow);
flow_wh_M.Properties.VariableNames = {'flow'};
% create new time vector at 10secs resolution  
dt = seconds(5);
flow_wh_M_5sec = retime(flow_wh_M,'regular','linear','TimeStep',dt);
flow_wh_M_5sec.Time.Format = 'MM/dd/yyyy HH:mm:ss';

% second temperature

if ascii==1
    %first flow
formatSpec = '%{MM/dd/yyyy}D %{HH:mm:ss}D \t%f\r\n';
dataArray = textscan(fileID_wht, formatSpec);
% Post processing for unimportable data.
temp_wh = table(dataArray{1:end}, 'VariableNames', {'date','time','value'});
% Clear temporary variables
%clearvars filename startRow formatSpec fileID dataArray ans;
% 
temp_wh.date.Format = 'MM/dd/yyyy HH:mm:ss';
temp_wh.time.Format = 'MM/dd/yyyy HH:mm:ss';
temp_wh_M = table();
temp_wh_M.time = datetime([temp_wh.date+timeofday(temp_wh.time)],'InputFormat','MM/dd/yyyy HH:mm:ss');
temp_wh_M.temp = temp_wh.value;
    elseif ascii==0 
    frewind(fileID_wht);
    m=fread(fileID_wht, 'uint8');
    size(m);
    B = uint8(reshape(m,[12,size(m,1)/12]))';
    year= typecast(reshape(B(:,4:5)',[],1)','uint16');
    date=datetime(year',typecast(B(:,2),'uint8'),typecast(B(:,3),'uint8'), ...
        typecast(B(:,6),'uint8'),typecast(B(:,7),'uint8'),typecast(B(:,8),'uint8'),'Format','MM/dd/yyyy HH:mm:ss');
    tempval= typecast(reshape(B(:,9:12)',[],1)','single')';
    
    temp_wh_M = table();
    temp_wh_M.time= date;
    temp_wh_M.temp= tempval;         
    end
%generate timetable
temp_wh_M = timetable(temp_wh_M.time,temp_wh_M.temp);
temp_wh_M.Properties.VariableNames = {'temp'};
% create new time vector at 10secs resolution  
dt = seconds(5);
temp_wh_M_5sec = retime(temp_wh_M,'regular','linear','TimeStep',dt);
temp_wh_M_5sec.Time.Format = 'MM/dd/yyyy HH:mm:ss';
% Combine all time series (First FLOW, then temperature)

%sublist_unique=unique(subcatchlist.Outlet);
%table_size = [size(flow_swmm_M_5sec,1) size(sublist_unique,1)];
%vartyp = strings([size(sublist_unique,1) 1]) + "double";
%final_flow = table('Size', table_size, 'VariableTypes', vartyp);

%dt = seconds(5);
%totalflow=retime([flow_swmm_M_5sec; flow_wh_M_5sec],'regular',@sum,'TimeStep',dt);
TT = synchronize(flow_wh_M_5sec,temp_wh_M_5sec,'union','linear');
TT = timetable2table(TT(TR,:));
soiltemparray=soiltemp(month(TT.Time));
totalflow = TT(:,2);
finalflow(:,ifile)=totalflow;
%temperature
%
totaltemp=TT(:,3);
totaltemp.temp(isnan(totaltemp.temp)) = soiltemparray(isnan(totaltemp.temp));
finaltemp(:,ifile)=totaltemp;    
    end
    end


%% Write Files
if ascii == 1
    date = datestr(TT.Time(:),'mm/dd/yyyy');
    date_cell=cellstr(date);
    time = datestr(TT.Time(:),'HH:MM:ss');
    time_cell=cellstr(time);
    %flow=table2array(finalflow);
    %temp=table2array(finaltemp);
    %flowcell=num2cell(flow);
    flowcell=table2cell(finalflow);
    tempcell=table2cell(finaltemp);
    formatSpec = '%s %s\t%f\r\n';
    for ifile = 1:size(node_array,1)
        ifile
    %currentFolder = pwd;
    %save final flow
    %datapath= join([currentFolder,'\_time_series\'],'');
    datapath=join(abspath,"\Scenarios\",auxpath2,"\INPUT\");
    fileID = fopen(join([datapath,node_array(ifile),"_flow.txt"],''),'w+');
    finalcell = [date_cell, time_cell,flowcell(:,ifile) ].';
    fprintf(fileID,formatSpec, finalcell{:});
    %for j = 1:size(time,1)
    %fprintf(fileID,formatSpec, date(j,:),time(j,:),flow(j,ifile));
    %end
    fclose(fileID);
    %save final temp
   % datapath= join([currentFolder,'\_time_series\'],'');
    fileID = fopen(join([datapath,node_array(ifile),"_temp.txt"],''),'w+');
    %for j = 1:size(time,1)
    %fprintf(fileID,formatSpec, date(j,:),time(j,:),temp(j,ifile));
    %end    
    finalcell = [date_cell, time_cell,tempcell(:,ifile) ].';
    fprintf(fileID,formatSpec, finalcell{:});
    fclose(fileID);
    end    
else
%% Write binary files
%ifile=1;
timea=table2timetable(TT);%table2timetable(a);
timea.Time.Format='MM/dd/yyyy HH:mm:ss';
timefina=timetable2table(timea);
nint = zeros(size(timefina.Time.Month,1),1)+3;
time_table_fin_int=[nint timefina.Time.Month];
time_table_fin_int=[time_table_fin_int timefina.Time.Day];
time_table_fin_intd=timefina.Time.Year;
time_table_fin_int=[time_table_fin_int timefina.Time.Hour];
time_table_fin_int=[time_table_fin_int timefina.Time.Minute];
time_table_fin_int=[time_table_fin_int timefina.Time.Second];
time_table_fin_int=uint8(time_table_fin_int);
time_table_fin_intd=uint16(time_table_fin_intd);

tabledouble1 = single(table2array(finalflow));
nsize1=size(tabledouble1,1);
tabledouble2 = single(table2array(finaltemp));
nsize2=size(tabledouble2,1);
nn=size(node_array,1);
   % datapath= join([currentFolder,'\_time_series_bin\',scenarioname,'\'],'');
    datapath=join([abspath,"\Scenarios\stitched\",strcat(auxpath1,'_',auxpath2),"\INPUT\"],'');
    mkdir(datapath);
    for ifile = 1:nn
        %node_array(1)= "102a";
    fid1= fopen(join([datapath,node_array(ifile),"_flow.bin"],''),'w+');
    fid2= fopen(join([datapath,node_array(ifile),"_temp.bin"],''),'w+');
for i=1:nsize1
  fwrite(fid1, time_table_fin_int(i,1:3), 'uint8');
  fwrite(fid1, time_table_fin_intd(i), 'uint16');
  fwrite(fid1, time_table_fin_int(i,4:6), 'uint8');  
  fwrite(fid1, tabledouble1(i,ifile), 'single');
end
fclose( fid1 ) ;
   % end    


   % for ifile = 1:nn
 %   datapath2= join([currentFolder,'\_time_series_bin\'],'');
%fid = fopen( outfile , 'w' ) ;
for i=1:nsize2
  fwrite(fid2, time_table_fin_int(i,1:3), 'uint8');
  fwrite(fid2, time_table_fin_intd(i), 'uint16');
  fwrite(fid2, time_table_fin_int(i,4:6), 'uint8');  
  fwrite(fid2, tabledouble2(i,ifile), 'single');
end
fclose( fid2 ) ;
    end 
end
end
%%PLOT TIMESERIES (CHECKING)

