function [cloudcover_clip] = get_cloudcover(from,to,SwissMeteoStation,t_delta,abspath) 
%% get_cloudcover
% returns cloud cover data from SwissMeteo
% use KLO for Kloten or SMA for Zurich Flunterns
% needs fields
% from = '''2018-01-01 00:00:00''';
% to = '''2019-01-01 00:00:00''';
% SwissMeteoStation = 'SMA' %/ 'KLO'
% t_delta = 1./(24*60).*10; %10 min is default like data
% 
% written Tobias Frey, 12.12.19
% edited Tobias Frey, 12.12.19

%datapath = 'C:\Users\figueral\Documents\Programing\Institution\2020_shx\04_workspace\_swmm_minu\_minu_simulation\_prepare_data_minu\_cloud_cover_data\';
datapath=strcat(abspath,'\MINUHET\Data\Cloud\');
%addpath(datapath)
%% User Definitions
t_start = datenum(from(2:end-1),'yyyy-mm-dd HH:MM:SS');
t_end = datenum(to(2:end-1),'yyyy-mm-dd HH:MM:SS');
%

%% Read-in file
filepath = strcat(datapath,'SwissMeteo_',SwissMeteoStation,'_RAW_Gesamtbewoelkung_170101_191211.txt');
% reads file with 10min data recordings
opts = delimitedTextImportOptions("NumVariables", 8);
opts.DataLines = [4, Inf];
opts.Delimiter = ";";
opts.VariableNames = ["Var1", "time", "Var3", "Var4", "Var5", "nto000sw", "Var7", "Var8"];
opts.SelectedVariableNames = ["time", "nto000sw"];
opts.VariableTypes = ["string", "double", "string", "string", "string", "double", "string", "string"];
opts = setvaropts(opts, [1, 3, 4, 5, 7, 8], "WhitespaceRule", "preserve");
opts = setvaropts(opts, [1, 3, 4, 5, 6, 7, 8], "EmptyFieldRule", "auto");
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
cloudcover = readtable(filepath, opts);
clear opts
%% Processing
% clip data if other time step than 10min is desired
if t_delta ~= 1./(24*60).*10
idx = isnan(cloudcover.nto000sw);
cloudcover(idx,:) = [];
else
end

%% 
t = string(table2array(cloudcover(:,1)));
cloudcover.time = datenum(t,'yyyymmddHHMM');
disp(['time series start ',datestr(cloudcover.time(1))])
disp(['time series end ',datestr(cloudcover.time(end))])
% time clip
idx = find((t_start <= cloudcover.time) & (cloudcover.time <= t_end));
cloudcover_clip = cloudcover(idx,:);
disp(['clipped time series start ',datestr(cloudcover_clip.time(1))])
disp(['clipped time series end ',datestr(cloudcover_clip.time(end))])
disp(['number of entries ',num2str(numel(cloudcover_clip))])

end