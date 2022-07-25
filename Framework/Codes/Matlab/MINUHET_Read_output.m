%% MINUHET_read output
% script to read and write results from MINUHET as nodal temperature text files for SWMM HEAT
% 
% Modified by AF, 7/23/2021
% written Tobias Frey, 08.03.2020
% last edit Tobias Frey, 11.04.2020

%% READ LIST OF SUBCATCHMENTS
%clear all; close all;
%cd('C:\Users\figueral\Documents\Programing\Institution\2020_shx\04_workspace\_swmm_minu\_minu_simulation\') %needs to be adapted | required!
%currentFolder = pwd;
%addpath(genpath(fullfile(pwd)));
%load('subcatchlist.mat');
%Select scenario
%scenario =1;
% season 1
%if scenario ==1
%TR = [datetime(2019,04,21,00,00,00);datetime(2019,05,15,00,00,00)];
%scenarioname='scenario1';
% season 2
%elseif scenario ==2
%TR = [datetime(2019,06,27,00,00,00);datetime(2019,07,18,00,00,00)];
%scenarioname='scenario2';
% season 3
%elseif scenario ==3
%TR = [datetime(2019,08,27,00,00,00);datetime(2019,09,15,00,00,00)];
%scenarioname='scenario3';
%end
function MINUHET_Read_output(subcatchlist, abspath, auxpath)
%% RUN MINUHET Simulations
%create synthetic folder, move files, weather file and executable files
%then run simulation
if ~(auxpath == "")
    outpath=strcat(abspath,"\MINUHET\Minu_sim\",auxpath);
else    
    outpath=strcat(abspath,"\MINUHET\Minu_sim");
end

if not(isfolder(strcat(abspath,"\MINUHET\Minu_sim","\testcase_0")))
    mkdir(strcat(abspath,"\MINUHET\Minu_sim","\testcase_0"))
end

synpath=strcat(abspath,"\MINUHET\Minu_sim","\testcase_0\Synthetic01");
if not(isfolder(synpath))
    mkdir(synpath)
end
%copy files
status=copyfile(strcat(outpath,'\*'),strcat(synpath,'\'));
%copy executable files
status=copyfile(strcat(abspath,'\Codes\Minuhet\mix.exe'),strcat(synpath,'\'));
status=copyfile(strcat(abspath,'\Codes\Minuhet\runoff.exe'),strcat(synpath,'\'));
%copy weather data
if ~(auxpath == "")
    status=copyfile(strcat(abspath,'\MINUHET\Weather\',auxpath,'\Synthetic01.dat'),strcat(synpath,'\'));
else    
    status=copyfile(strcat(abspath,'\MINUHET\Weather\Synthetic01.dat'),strcat(synpath,'\'));
end
%copy global data
status=copyfile(strcat(abspath,'\Codes\Minuhet\global.dat'),strcat(synpath,'\'));

%run batch file
oldFolder = cd(synpath)

command=strcat("minuhet_sim.bat")
[status,cmdout] = system(command)

cd(oldFolder)
%command=strcat('minuhet_sim.bat');

%move files back to previous folder
status=movefile(strcat(synpath,'\*'),strcat(outpath,'\') );

%% READ IN SIMULATION RESULTS MINUHET
%pathsimres = strcat('C:\Users\figueral\Documents\Programing\Institution\2020_shx\04_workspace\_swmm_minu\_minu_simulation\swmm_subcatch_sims\',scenarioname,'\');
%cd(pathsimres)
%MINUHET_model = 'imberg_V2_sims';
%cd(MINUHET_model);
%d = dir;
%dd = zeros(length(d));
% for j = 1:length(d)
% dd(j) =datenum(d(j).date);
% end
%[tmp i]=max(dd);
%newestfolder = d(j).name;
%cd(newestfolder);
% define the rain series used
% here r03 stands for a file with time series from r02 but Jul2-aug25'19
%rainseries = 'r02';
%cd(rainseries);

%%% READ FLOWS FROM MINUHET
% definitions must be read out from case file in MINUHET
% to Do: o write a procedure that does read out definitions from case file
% automatically
if (auxpath == "")
    %mdlName = strcat(abspath,'/Scenarios/',inpfile);
    pathsimres=strcat(abspath,'\MINUHET\Minu_sim\');
else
    %mdlName = strcat(abspath,'/Scenarios/',auxpath,'/',inpfile);
    pathsimres=strcat(abspath,'\MINUHET\Minu_sim\',auxpath,'\');
end
opts = delimitedTextImportOptions("NumVariables", 11);
% Specify range and delimiter
opts.DataLines = [1, Inf];
opts.Delimiter = ",";
% Specify column names and types
%opts.VariableNames = ["TIME","sws06","sws09","sws10","sws11","sws12","sws13","pip07","pip04","pip02","pip01"];
%opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double","double"];
%opts.ExtraColumnsRule = "ignore";
%opts.EmptyLineRule = "read";
% Import the data and create table
varNames = {'FLOW' 'TEMPERATURE' 'HEAT_EXPORT' 'PRECIP'};
Flow_sim_M1 = readtable(string([strcat(pathsimres,subcatchlist.Name(1),'.csv')]));
Flow_sim_M1([end-4,end-3,end-2,end-1,end],:) = [];
Flow_sim_M1 = timetable(datetime(datestr(x2mdate(Flow_sim_M1.TIME))),Flow_sim_M1.FLOW,Flow_sim_M1.TEMPERATURE,Flow_sim_M1.HEAT_EXPORT, Flow_sim_M1.PRECIP,'VariableNames', varNames);
dt = minutes(5);
Flow_sim_M1 = retime(Flow_sim_M1,'regular','linear','TimeStep',dt);

flow_tab = timetable2table(Flow_sim_M1(:,1),'ConvertRowTimes',false );
temp_tab= timetable2table(Flow_sim_M1(:,2),'ConvertRowTimes',false );
heat_tab = timetable2table(Flow_sim_M1(:,3),'ConvertRowTimes',false );
precip_tab= timetable2table(Flow_sim_M1(:,4),'ConvertRowTimes',false );
flow_tab = renamevars(flow_tab,['FLOW'],[subcatchlist.Name(1)]);
temp_tab = renamevars(temp_tab,['TEMPERATURE'],[subcatchlist.Name(1)]);
heat_tab = renamevars(heat_tab,['HEAT_EXPORT'],[subcatchlist.Name(1)]);
precip_tab = renamevars(precip_tab,['PRECIP'],[subcatchlist.Name(1)]);
             
%do loop for adding more subcatchments
nsize=size(subcatchlist,1);
for i=2:nsize
    fprintf('reading subcatchment number = %d\n',i);
    %string([strcat(subcatchlist.Name(i))]);
Flow_sim_M2 = readtable(string([strcat(pathsimres,subcatchlist.Name(i),'.csv')]));
Flow_sim_M2([end-4,end-3,end-2,end-1,end],:) = [];
Flow_sim_M2 = timetable(datetime(datestr(x2mdate(Flow_sim_M2.TIME))),Flow_sim_M2.FLOW,Flow_sim_M2.TEMPERATURE,Flow_sim_M2.HEAT_EXPORT, Flow_sim_M2.PRECIP,'VariableNames', varNames);
Flow_sim_M2 = retime(Flow_sim_M2,'regular','linear','TimeStep',dt);

flow_tab   = [flow_tab timetable2table(Flow_sim_M2(:,1),'ConvertRowTimes',false )];
flow_tab   = renamevars(flow_tab,['FLOW'],[subcatchlist.Name(i)]);
temp_tab   = [temp_tab timetable2table(Flow_sim_M2(:,2),'ConvertRowTimes',false )];
temp_tab   = renamevars(temp_tab,['TEMPERATURE'],[subcatchlist.Name(i)]);
heat_tab   = [heat_tab timetable2table(Flow_sim_M2(:,3),'ConvertRowTimes',false )];
heat_tab   = renamevars(heat_tab,['HEAT_EXPORT'],[subcatchlist.Name(i)]);
precip_tab = [precip_tab timetable2table(Flow_sim_M2(:,4),'ConvertRowTimes',false )];
precip_tab = renamevars(precip_tab,['PRECIP'],[subcatchlist.Name(i)]);

end
%%


%Flow_sim_M=[table2timetable(Flow_sim_M1) Flow_sim_M2]
%size(Flow_sim_M)
%datestr(x2mdate(Flow_sim_M1.TIME))
%timet = Flow_sim_M1.Time;
%tabnames = {subcatchlist.Name(1), subcatchlist.Name(2)};
%Flow_sim_M=table(Flow_sim_M1(1:10,1:4),Flow_sim_M2(1:10,1:4),'VariableNames', tabnames );



%Flow_sim_M3 = readtable(string([strcat(subcatchlist.Name(3),'.csv')]));
%Flow_sim_M3([end-4,end-3,end-2,end-1,end],:) = [];
%Flow_sim_M3 = timetable(datetime(datestr(x2mdate(Flow_sim_M3.TIME))),Flow_sim_M3.FLOW,Flow_sim_M3.TEMPERATURE,Flow_sim_M3.HEAT_EXPORT, Flow_sim_M3.PRECIP,'VariableNames', varNames)
%Flow_sim_M=[table2timetable(Flow_sim_M1) Flow_sim_M2]


%Flow_sim_M=[Flow_sim_M table(Flow_sim_M3(1:10,1:4))]




%Flow_sim_M1 = timetable(datetime(datestr(x2mdate(Flow_sim_M1.TIME))),Flow_sim_M1.FLOW,Flow_sim_M1.TEMPERATURE,Flow_sim_M1.HEAT_EXPORT, Flow_sim_M1.PRECIP)
%Flow_sim_M = [Flow_sim_M1 timetable(datetime(datestr(x2mdate(Flow_sim_M2.TIME))),Flow_sim_M2.FLOW,Flow_sim_M2.TEMPERATURE,Flow_sim_M2.HEAT_EXPORT, Flow_sim_M2.PRECIP)]
% Clear temporary variables
%clear opts
%Flow_sim_M(isnan(table2array(Flow_sim_M(:,1))),:) = [];

%Flow_sim_M = timetable(datetime(Flow_sim_M.TIME,'ConvertFrom','excel'),...
%    Flow_sim_M.sws06,Flow_sim_M.sws09,Flow_sim_M.sws10,Flow_sim_M.sws11,Flow_sim_M.sws12,Flow_sim_M.sws13,Flow_sim_M.pip01);
%Flow_sim_M.Properties.VariableNames = {'fD0035T','fD0071T','fD0040RT','fD0045RT','fD0050RT','fD0030T','f581a_sim_M'};

% Conversion
%Flow_sim_M.fD0035T = Flow_sim_M.fD0035T.*1000; % [l/s]
%Flow_sim_M.fD0071T = Flow_sim_M.fD0071T.*1000; % [l/s]
%Flow_sim_M.fD0040RT = Flow_sim_M.fD0040RT.*1000; % [l/s]
%Flow_sim_M.fD0045RT = Flow_sim_M.fD0045RT.*1000; % [l/s]
%Flow_sim_M.fD0050RT = Flow_sim_M.fD0050RT.*1000; % [l/s]
%Flow_sim_M.fD0030T = Flow_sim_M.fD0030T.*1000; % [l/s]
%Flow_sim_M.f581a_sim_M = Flow_sim_M.f581a_sim_M.*1000; % [l/s]

%% READ TEMPERATURES FROM MINUHET
% definitions must be read out from case file in MINUHET
% to Do: o write a procedure that does read out definitions from case file
% automatically
%opts = delimitedTextImportOptions("NumVariables", 11);
% Specify range and delimiter
%opts.DataLines = [1, Inf];
%opts.Delimiter = ",";
% Specify column names and types
%opts.VariableNames = ["TIME","sws06","sws09","sws10","sws11","sws12","sws13","pip07","pip04","pip02","pip01"];
%opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double","double"];
%opts.ExtraColumnsRule = "ignore";
%opts.EmptyLineRule = "read";
% Import the data
%Temp_sim_M = readtable(string(['pip01Temp.csv']), opts);
% Clear temporary variables
%clear opts
%Temp_sim_M(isnan(table2array(Temp_sim_M(:,1))),:) = [];
%Temp_sim_M = timetable(datetime(Temp_sim_M.TIME,'ConvertFrom','excel'),...
%    Temp_sim_M.sws06,Temp_sim_M.sws09,Temp_sim_M.sws10,Temp_sim_M.sws11,Temp_sim_M.sws12,Temp_sim_M.sws13,Temp_sim_M.pip01);
%Temp_sim_M.Properties.VariableNames = {'tD0035T','tD0071T','tD0040RT','tD0045RT','tD0050RT','tD0030T','t581a_sim_M'};

%% READ HEAT EXPORT FROM MINUHET
% opts = delimitedTextImportOptions("NumVariables", 11);
% % Specify range and delimiter
% opts.DataLines = [1, Inf];
% opts.Delimiter = ",";
% % Specify column names and types
% opts.VariableNames = ["TIME","sws06","sws09","sws10","sws11","sws12","sws13","pip07","pip04","pip02","pip01"];
% opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double","double"];
% opts.ExtraColumnsRule = "ignore";
% opts.EmptyLineRule = "read";
% % Import the data
% Heat_sim_M = readtable(string(['pip01Heat.csv']), opts);
% % Clear temporary variables
% clear opts
% Heat_sim_M(isnan(table2array(Temp_sim_M(:,1))),:) = [];
% Heat_sim_M = timetable(datetime(Heat_sim_M.TIME,'ConvertFrom','excel'),Heat_sim_M.pip01);
% Heat_sim_M.Properties.VariableNames = {'P581a_sim_M'};
% 
% disp('MINUHET simulation data load complete')


%%
% assign MINUHET outputs to nodal inflows
% D0030T	579c
% D0035T	579b
% D0040RT	572
% D0045RT   575
% D0050RT   56a 
% D0071T	576
%% Prepare OUT flows MINUHET
%Flow_sim_M1=timetable2table(Flow_sim_M1);
%date = datestr(Flow_sim_M1.Time(:),'MM/dd/yyyy');
%time = datestr(Flow_sim_M1.Time(:),'hh:mm');
%
sublist_unique=unique(subcatchlist.Outlet);
%agregate flow at nodes
table_size = [ size(flow_tab,1) size(sublist_unique,1)];
vartyp = strings([size(sublist_unique,1) 1]) + "double";
out_nodef = table('Size', table_size, 'VariableTypes', vartyp);
nsize=size(subcatchlist,1);
for i=1:nsize

node_pos=find(strcmp(sublist_unique,subcatchlist.Outlet(i)));
out_nodef(:,node_pos)=table(table2array(out_nodef(:,node_pos))+table2array(flow_tab(:,i)));

end

%% OUT Flows MINUHET
% writes a tab seperated inflow file for SWMM-TEMP
%datapath_out = strcat('C:\Users\figueral\Documents\Programing\Institution\2020_shx\04_workspace\_swmm_minu\_minu_simulation\_out_minu\',scenarioname,'\');

if not(isfolder(strcat(abspath,"\MINUHET\Minu_out")))
    mkdir(strcat(abspath,"\MINUHET\Minu_out"))
end
if (auxpath == "")
    %mdlName = strcat(abspath,'/Scenarios/',inpfile);
    datapath_out=strcat(abspath,'\MINUHET\Minu_out\');
else
    %mdlName = strcat(abspath,'/Scenarios/',auxpath,'/',inpfile);
if not(isfolder(strcat(abspath,"\MINUHET\Minu_out\",auxpath)))
    mkdir(strcat(abspath,"\MINUHET\Minu_out\"',auxpath))
end
    datapath_out=strcat(abspath,'\MINUHET\Minu_out\',auxpath,'\');
end
%[n,mfrom] = month(from(2:11));
%dfrom = num2str(day(from(2:11)));
%[n,mto] = month(to(2:11));
%dto = num2str(day(to(2:11)));
%dayear = year(from(2:11));
%k = 0;
%N = numel(Flow_sim_M.Properties.VariableNames);
%tic;
Flow_sim_M1=timetable2table(Flow_sim_M1);
date = datestr(Flow_sim_M1.Time(:),'mm/dd/yyyy');
time = datestr(Flow_sim_M1.Time(:),'HH:MM');
nsize=size(sublist_unique,1);
for i=1:nsize
    clc;
%    k = showTimeToCompletion(j./N,k);
nodename = sublist_unique(i);%Flow_sim_M.Properties.VariableNames(j);
filename_flow_out = strcat(nodename,'_flow','.txt');
filepath_out = strcat(datapath_out,filename_flow_out);
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
flow=table2array(out_nodef(:,i))*1000.; %flowtab from m3/s to l/s

for j = 1:size(time,1)
fprintf(fileID,formatSpec, date(j,:),time(j,:),flow(j));
end
fclose(fileID);

end
%elapsedtime = tic-toc;
%disp('all flow files written')

%% Prepare OUT temperature from MINUHET
%Flow_sim_M1=timetable2table(Flow_sim_M1);
%date = datestr(Flow_sim_M1.Time(:),'MM/dd/yyyy');
%time = datestr(Flow_sim_M1.Time(:),'hh:mm');
%
sublist_unique=unique(subcatchlist.Outlet);
%agregate flow at nodes
table_size = [size(flow_tab,1) size(sublist_unique,1)];
vartyp = strings([size(sublist_unique,1) 1]) + "double";
out_nodef = table('Size', table_size, 'VariableTypes', vartyp);
out_nodet = table('Size', table_size, 'VariableTypes', vartyp);
nsize=size(subcatchlist,1);

for i=1:nsize
%
node_pos=find(strcmp(sublist_unique,subcatchlist.Outlet(i)));
out_nodet(:,node_pos)=table( ... 
                      sum([table2array(out_nodef(:,node_pos)) .* table2array(out_nodet(:,node_pos))          ...
                       table2array(flow_tab(:,i))         .* table2array(temp_tab(:,i))],2,'omitnan')   ./   ...
                      sum([(table2array(out_nodef(:,node_pos))  + table2array(flow_tab(:,i)))],2,'omitnan')  ...
);
out_nodef(:,node_pos)=table(table2array(out_nodef(:,node_pos))+table2array(flow_tab(:,i)));
end

 %replace NAN values

fout_nodet=out_nodet;
%soil_temp=10;
nsize=size(sublist_unique,1);

for i=1:nsize
%
%i=1
node_pos=find(strcmp(subcatchlist.Outlet,sublist_unique(i)));
idx=isnan(table2array(fout_nodet(:,i)));
fout_nodet(idx,i)=temp_tab(idx,node_pos(1));
end
%% Temperature MINUHET
% writes a tab seperated inputfile for SWMM-TEMP
%datapath_out = strcat('C:\Users\figueral\Documents\Programing\Institution\2020_shx\04_workspace\_swmm_minu\_minu_simulation\_out_minu\',scenarioname,'\');
%[n,mfrom] = month(from(2:11));
%dfrom = num2str(day(from(2:11)));
%[n,mto] = month(to(2:11));
%dto = num2str(day(to(2:11)));
%dayear = year(from(2:11));
%k = 0;
%N = numel(Flow_sim_M.Properties.VariableNames);
%tic;
%Flow_sim_M1=timetable2table(Flow_sim_M1);
date = datestr(Flow_sim_M1.Time(:),'mm/dd/yyyy');
time = datestr(Flow_sim_M1.Time(:),'HH:MM');
nsize=size(sublist_unique,1);
for i=1:nsize
    clc;
%    k = showTimeToCompletion(j./N,k);
nodename = sublist_unique(i);%Flow_sim_M.Properties.VariableNames(j);
filename_temp_out = strcat(nodename,'_temp','.txt');
filepath_out = strcat(datapath_out,filename_temp_out);
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
temp=table2array(fout_nodet(:,i));
for j = 1:size(time,1)
fprintf(fileID,formatSpec, date(j,:),time(j,:),temp(j));
end
fclose(fileID);

end
end