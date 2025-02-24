%clear all; close all;
%% Input_to_MINUHET
% Generate Time Series for MINUHET
% written 21.11.2019 Tobias Frey
% last edit 11.04.2020 Tobias Frey

%% FILE STRUCTURE in MINUHET
% dat.file with the following content (! for comments)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ! MINUHET observed design storm file
% ! Contains site run time parameters and weather data
% ! WSTART=start date/time for weather data in Excel format
% ! ASTART=start date/time for runoff analysis in Excel format
% ! TSTEP = weather time step (minutes), NWD = number of weather time steps,
% ! WDAT=weather data (air temp (C), RH (%), Solar (W/m^2, Wind (m/s), 
% ! Precipitation (cm), Cloud Cover Fraction (0=clear, 1= full cloud cover)
%   
% &WRUN
% WSTART=38510.00000
% WSTOP=38525.00000
% TSTEP=15.0/
%   
% &WDATA
% WDAT = 
% 18.9, 85.4, 0.0, 0.32, 0.00, 0.2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Input_2_MINUHET(abspath, auxpath, timeinit, timeend)
%% USER SETTING
% define if existing file is updated or new file is created
%scenario =1;
%if scenario ==1
% Season 1

%abspath="Q:\Abteilungsprojekte\eng\SWWData\SWMM-HEAT\Framework_template";
%timeinit=datetime('03/02/2019 00:00:00');
%timeend=datetime('03/16/2019 00:00:01');
%TRsim = timerange('03/02/2019 00:00:00','03/16/2019 00:00:01');

TRsim = timerange(timeinit,timeend);
%scenarioname='scenario1';
%season 2
%elseif scenario ==2
%TRsim = timerange('06/27/2019 00:00:00','07/18/2019 00:00:01');
%scenarioname='scenario2';
%season 3
%elseif scenario ==3
%TRsim = timerange('08/27/2019 00:00:00','09/15/2019 00:00:01');
%scenarioname='scenario3';
%end
newinputfile = 1; % change if new time range is chosen
dt = minutes(5); % time step of output
%% FETCH DATA
% query all rainfall intensities for a give time span
%ImportDatapoolConfig
% calibration summer
% from = '''2019-06-16 00:00:00''';
% to = '''2019-06-26 23:59:59''';
% validation summer
from = '''2019-01-01 00:00:00''';
to = '''2019-12-31 23:59:59''';

% winter summer
%from = '''2019-10-20 00:00:00''';
%to = '''2019-12-08 23:59:59''';
t_delta = 1;
% convert to datenum
t_start = datenum(from(2:end-1),'yyyy-mm-dd HH:MM:SS');
t_end = datenum(to(2:end-1),'yyyy-mm-dd HH:MM:SS');
%% DATA - RAINFALL
% sourceName = '''bn_r03_rub_morg''';
% parameterName = '''rainfall intensity''';
% rain = getBulkfromDatapool(sourceName,from,to,parameterName,t_delta);
% rain.time = datenum(rain.time,'yyyy-mm-dd HH:MM:SS');
% Initialize variables
%filename = 'C:\Users\figueral\Documents\Programing\Institution\2020_shx\04_workspace\_swmm_minu\_minu_simulation\_prepare_data_minu\_rain_data\r02_mm_utc0_1min_feb16_apr20.dat';
filename = strcat(abspath,'\MINUHET\Data\Rainfall\r02_mm_utc0_1min_feb16_apr20.dat');
startRow = 3;
formatSpec = '%*3s%5f%3f%3f%3f%3f%5f%[^\n\r]';
% Open the text file.
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'TextType', 'string', 'EmptyValue', NaN, 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
% Close the text file.
fclose(fileID);
% Post processing for unimportable data.
r02 = table(dataArray{1:end-1}, 'VariableNames', {'year','month','day','hour','minute','value'});
% Clear temporary variables
clearvars filename startRow formatSpec fileID dataArray ans;
% 
r02_M = table();
r02_M.time = datetime(r02.year,r02.month,r02.day,r02.hour,r02.minute,zeros(size(r02,1),1));
r02_M.value = r02.value;
r02_M = timetable(r02_M.time,r02_M.value/10);
r02_M.Properties.VariableNames = {'rain'};
% create new time vector at 5min resolution and with zeros 
dt = minutes(5);
r02 = retime(r02_M,'minutely','fillwithconstant','Constant',0,'TimeStep',dt); 
%r02 =retime(r02_M,'regular','sum','TimeStep',dt);
% r02 = retime(r02_M,'regular','nearest','TimeStep',dt);
r02.Properties.VariableNames = {'rain'};


%% DATA - AIR TEMPERATURE
%filename = 'C:\Users\figueral\Documents\Programing\Institution\2020_shx\04_workspace\_swmm_minu\_minu_simulation\_prepare_data_minu\_tair_TF\bx_ws702_rub_morg_Jan2019_Jan2020.mat';
filename = strcat(abspath,'\MINUHET\Data\Air_temp\bx_ws702_rub_morg_Jan2019_Jan2020.mat');
load(filename);
dt = minutes(1);
%airTemp.time = datenum(airTemp.time,'yyyy-mm-dd HH:MM:SS');
airTemp = timetable(datetime(airTemp.time,'ConvertFrom','datenum'),airTemp.value);
airTemp.Properties.VariableNames = {'airTemp'};
airTemp(isnan(airTemp.airTemp),:) = [];
airTemp = unique(airTemp,'rows');
airTemp = retime(airTemp,'regular','nearest','TimeStep',dt);
%aply hampel filter
airTemp.airTemp=hampel(airTemp.airTemp);
%irTemp_m = table2timetable(airTemp);



%startRow = 3;
%formatSpec = '%*3s%5f%3f%3f%3f%3f%5f%[^\n\r]';
% Open the text file.
%fileID = fopen(filename,'r');
%dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'TextType', 'string', 'EmptyValue', NaN, 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
% Close the text file.
%fclose(fileID);
% Post processing for unimportable data.
%r02 = table(dataArray{1:end-1}, 'VariableNames', {'year','month','day','hour','minute','value'});
% Clear temporary variables
%clearvars filename startRow formatSpec fileID dataArray ans;
% 
%r02_M = table();
%r02_M.time = datetime(r02.year,r02.month,r02.day,r02.hour,r02.minute,zeros(size(r02,1),1));
%r02_M.value = r02.value;
%r02_M = timetable(r02_M.time,r02_M.value);
%r02_M.Properties.VariableNames = {'rain'};
% create new time vector at 5min resolution and with zeros 
%dt = minutes(5);
%r02 = retime(r02_M,'minutely','fillwithconstant','Constant',0,'TimeStep',dt); 
%r02 =retime(r02_M,'regular','sum','TimeStep',dt);
% r02 = retime(r02_M,'regular','nearest','TimeStep',dt);
%r02.Properties.VariableNames = {'rain'};
%sourceName = '''bx_ws702_rub_morg''';
%parameterName = '''air temperature-ventilated''';
%t_delta = 1;
%airTemp = getBulkfromDatapool(sourceName,from,to,parameterName,t_delta);
%airTemp.time = datenum(airTemp.time,'yyyy-mm-dd HH:MM:SS');
%airTemp = timetable(datetime(airTemp.time,'ConvertFrom','datenum'),airTemp.value);
%airTemp.Properties.VariableNames = {'airTemp'};
%airTemp(isnan(airTemp.airTemp),:) = [];
%airTemp = unique(airTemp,'rows');
%airTemp = retime(airTemp,'minutely','fillwithmissing','TimeStep',dt);
%% DATA - AIR HUMIDITY
%sourceName = '''bx_ws702_rub_morg''';
%parameterName = '''relative humidity-ventilated''';
%t_delta = 1;
%relHum = getBulkfromDatapool(sourceName,from,to,parameterName,t_delta);
%relHum.time = datenum(relHum.time,'yyyy-mm-dd HH:MM');
%relHum = timetable(datetime(relHum.time,'ConvertFrom','datenum'),relHum.value);
%relHum.Properties.VariableNames = {'relHum'};
%relHum(isnan(relHum.relHum),:) = [];
%relHum = unique(relHum,'rows');
%relHum = retime(relHum,'minutely','nearest','TimeStep',dt);
%relHum.relHum(relHum.relHum<0) = 0;
%relHum = airTemp;
%relHum.Properties.VariableNames = {'relHum'};
%relHum.relHum(:)= 80.0;

%filename = 'C:\Users\figueral\Documents\Programing\Institution\2020_shx\04_workspace\_swmm_minu\_minu_simulation\_prepare_data_minu\_relative_humidity';
%filename=strcat(filename, '\ara_flatroof_relhum_012019_122019.mat');
filename = strcat(abspath,'\MINUHET\Data\Air_hum\ara_flatroof_relhum_012019_122019.mat');

load(filename);
relHum=array2timetable(g.value, 'RowTimes',datetime(g.time));
relHum=unique(relHum);
dupTimes = sort(relHum.Time);
tf = (diff(dupTimes) == 0);
dupTimes = dupTimes(tf);
dupTimes = unique(dupTimes);
if size(dupTimes,1) > 0 
uniqueTimes = unique(relHum.Time);
relHum = retime(relHum,uniqueTimes,'mean');
end
relHum = retime(relHum,'regular','linear','TimeStep',dt);
%relHum_orig=relHum;
 plot(relHum.Time,relHum.Var1,'.k')
 %xlim([datetime(t_start,'ConvertFrom','datenum'),datetime(t_end,'ConvertFrom','datenum')])
 % area(relHum_agg.time,relHum_agg.value,'FaceColor','r','FaceAlpha',0.6,'EdgeAlpha',0)
 %datetick('x')
 %ylabel('Relative Humidity \newline [%]')
 %legend('raw data')
 
%apply hampel filter
relHum.Var1=hampel(relHum.Var1,7,1);
 %box;
 hold on
 plot(relHum.Time,relHum.Var1)
 %xlim([datetime(t_start,'ConvertFrom','datenum'),datetime(t_end,'ConvertFrom','datenum')])
% % area(relHum_agg.time,relHum_agg.value,'FaceColor','r','FaceAlpha',0.6,'EdgeAlpha',0)
% datetick('x')
%% DATA - WIND DATA
%filename = 'C:\Users\figueral\Documents\Programing\Institution\2020_shx\04_workspace\_swmm_minu\_minu_simulation\_prepare_data_minu\_processed_winddata\200318_PROC_winddata_WS-702_rub_morg_Jan_Dec_2019.mat';
filename = strcat(abspath,'\MINUHET\Data\Wind\200318_PROC_winddata_WS-702_rub_morg_Jan_Dec_2019.mat');

load(filename);
%sourceName = '''bx_ws702_rub_morg''';
%parameterName = '''wind speed''';
dt = minutes(1);
%wind = getBulkfromDatapool(sourceName,from,to,parameterName,t_delta);
%wind.time = datenum(wind.time,'yyyy-mm-dd HH:MM:SS');
%wind = timetable(datetime(wind.time,'ConvertFrom','datenum'),wind.value);
%wind.Properties.VariableNames = {'wind'};
%wind(isnan(wind.wind),:) = [];
%wind = unique(wind,'rows');
winddata = retime(winddata,'regular','linear','TimeStep',dt);
winddata.windspeed(winddata.windspeed<0) = 0;
%% DATA - GLOBAL RADIATION

% here take data from meteo station Fluntern
%SwissMeteoStation = 'KLO'; %/ 'KLO'
%t_delta = 1./(24*60).*10; %10 min is default like data
%radiation = get_gradiation(from,to,SwissMeteoStation,t_delta);
%radiation(isnan(radiation.ods000z0),:) = [];
%radiation = timetable(datetime(radiation.time,'ConvertFrom','datenum'),radiation.ods000z0);
%radiation.Properties.VariableNames = {'globalradiation'};
%radiation = retime(radiation,'regular','linear','TimeStep',dt);

%filename = 'C:\Users\figueral\Documents\Programing\Institution\2020_shx\04_workspace\_swmm_minu\_minu_simulation\_prepare_data_minu\globalradiation\bx_ws700_ara_flatroof_solarRadiation.mat';
filename = strcat(abspath,'\MINUHET\Data\Radiation\bx_ws700_ara_flatroof_solarRadiation.mat');
load(filename);
radiation=timetable(datetime(g.time(:)),g.value(:));
radiation = unique(radiation);
radiation = retime(radiation,'regular','linear','TimeStep',dt);
%sourceName = '''bx_ws702_rub_morg''';
%parameterName = '''global radiation''';
%t_delta = 1;
%radiation = getBulkfromDatapool(sourceName,from,to,parameterName,t_delta);
%radiation.time = datenum(radiation.time,'yyyy-mm-dd HH:MM:SS');
%radiation = timetable(datetime(radiation.time,'ConvertFrom','datenum'),radiation.value);
%radiation.Properties.VariableNames = {'radiation'};
%radiation(isnan(radiation.radiation),:) = [];
%radiation = unique(radiation,'rows');
%radiation = retime(radiation,'minutely','linear','TimeStep',dt);
%radiation.radiation(radiation.radiation<0) = 0;
%% DATA - CLOUD COVER
% TO DO: see if any locally measured variable correlates
% sourceName = '''bx_ws702_rub_morg''';
% parameterName = '''CSQ''';
% csq = getBulkfromDatapool(sourceName,from,to,parameterName,t_delta);
% csq.time = datenum(csq.time,'yyyy-mm-dd HH:MM:SS');

% here take data from meteo station Fluntern
SwissMeteoStation = 'KLO'; %/ 'KLO'
t_delta = 1./(24*60).*10; %10 min is default like data
cloudcover = get_cloudcover(from,to,SwissMeteoStation,t_delta,abspath);
cloudcover(isnan(cloudcover.nto000sw),:) = [];
cloudcover = timetable(datetime(cloudcover.time,'ConvertFrom','datenum'),cloudcover.nto000sw);
cloudcover.Properties.VariableNames = {'cloudcover'};
cloudcover = retime(cloudcover,'regular','linear','TimeStep',dt);
cloudcover.cloudcover = cloudcover.cloudcover./8; % compute pecentage coverage
cloudcover.cloudcover(cloudcover.cloudcover>1) = 1;
cloudcover.cloudcover(cloudcover.cloudcover<0) = 0;

% %% PROCESSING
% t_start = datenum(from(2:end-1),'yyyy-mm-dd HH:MM:SS');
% t_end = datenum(to(2:end-1),'yyyy-mm-dd HH:MM:SS');
% t_delta = 1./(24*60)*5; % 15 minutes steps for MINUHET
% n = numel([t_start:t_delta:t_end]);
% 
% %% rain
% % % harmonizing to minute data
% % t_prev = t_start-t_delta;
% % t_delta = 1./(24*3600);
% % i = 1;
% % rain_min = table([NaN],[NaN]);
% % rain_min.Properties.VariableNames = rain.Properties.VariableNames(1:2);
% % for t=t_start:t_delta:t_end 
% %     idx = find((t_prev <= rain.time) & (rain.time <= (t+t_delta)));
% %     rain_min.time(i) = t;
% %     rain_min.value(i) = round(mean(table2array(rain(idx,2)),'omitnan'),1);
% %     rain_min.unit(i) = rain.unit(1);
% %     t_prev = t;
% %     i = i+1;
% % end
% 
% %%
% % rounding to 5min and one significant digit
% t_prev = t_start-t_delta;
% t_delta = 1./(24*60)*15; % 15 minutes steps for MINUHET
% i = 1;
% rain_agg = table([NaN],[NaN]);
% rain_agg.Properties.VariableNames = rain.Properties.VariableNames(1:2);
% for t=t_start:t_delta:t_end 
%     idx = find((t_prev <= rain.time) & (rain.time <= (t+t_delta)));
%     rain_agg.time(i) = t;
%     rain_agg.value(i) = round(sum(table2array(rain(idx,2))./2,'omitnan'),1);
%     rain_agg.unit(i) = rain.unit(1);
%     t_prev = t;
%     i = i+1;
% end
% 
% rain_agg.value(rain_agg.value<0) = 0;
% %% air temperature
% % rounding to 5min and one significant digit
% t_prev = t_start-t_delta;
% i = 1;
% airTemp_agg = table([NaN],[NaN]);
% airTemp_agg.Properties.VariableNames = airTemp.Properties.VariableNames(1:2);
% for t=t_start:t_delta:t_end 
%     idx = find((t_prev <= airTemp.time) & (airTemp.time <= (t+t_delta)));
%     airTemp_agg.time(i) = t;
%     airTemp_agg.value(i) = round(mean(table2array(airTemp(idx,2)),'omitnan'),1);
%     t_prev = t;
%     i = i+1;
% end
% 
% 
% %% relative humidity
% % rounding to 15min and one significant digit
% % NOTE TFR 04.12.19 somehow the date format from the datapool is wrong.
% 
% t_prev = t_start;
% i = 1;
% relHum_agg = table([NaN],[NaN]);
% relHum_agg.Properties.VariableNames = relHum.Properties.VariableNames(1:2);
% for t=t_start:t_delta:t_end 
%     idx = find((t_prev <= relHum.time) & (relHum.time <= (t+t_delta)));
%     
%     if numel(idx) > 1
%         if (relHum.time(idx(2)) - relHum.time(idx(1))) >= t_delta
%             % TO DO: interpolate
%         end
%     relHum_agg.time(i) = t;
%     relHum_agg.value(i) =  round(mean(table2array(relHum(idx,2)),'omitnan'),1);
%     x = round(mean(table2array(relHum(idx,2)),'omitnan'),1);
%     else
%     relHum_agg.time(i) = t;
%     relHum_agg.value(i) = x; 
%     end 
% %     relHum_agg.time(i) = t;
% %     x = round(mean(table2array(relHum(idx,2)),'omitnan'),1);
% %     if isempty(x)
% %     relHum_agg.value(i) = relHum_agg.value(i-1); % assumes first entry is not empty
% %     else
% %     relHum_agg.value(i) = x;
% %     end
%     t_prev = t;
%     i = i+1;
% end
% 
% relHum_agg.value(relHum_agg.value>100) = 100;
% relHum_agg.value(relHum_agg.value<0) = 0;
% %% wind speed
% % rounding to 5min and one significant digit
% t_prev = t_start-t_delta;
% i = 1;
% wind_agg = table([NaN],[NaN]);
% wind_agg.Properties.VariableNames = wind.Properties.VariableNames(1:2);
% for t=t_start:t_delta:t_end 
%     idx = find((t_prev <= wind.time) & (wind.time <= (t+t_delta)));
%     wind_agg.time(i) = t;
%     wind_agg.value(i) = round(mean(table2array(wind(idx,2)),'omitnan'),1);
%     t_prev = t;
%     i = i+1;
% end
% 
% %% solar radiation
% % rounding to 5min and one significant digit
% t_prev = t_start-t_delta;
% i = 1;
% radiation_agg = table([NaN],[NaN]);
% radiation_agg.Properties.VariableNames = radiation.Properties.VariableNames(1:2);
% for t=t_start:t_delta:t_end 
%     idx = find((t_prev <= radiation.time) & (radiation.time <= (t+t_delta)));
%     radiation_agg.time(i) = t;
%     radiation_agg.value(i) = round(mean(table2array(radiation(idx,2)),'omitnan'),1);
%     t_prev = t;
%     i = i+1;
% end
% radiation_agg.value(radiation_agg.value<0) = 0;
% %% cloud cover
% t_start = datenum(from(2:end-1),'yyyy-mm-dd HH:MM:SS');
% t_end = datenum(to(2:end-1),'yyyy-mm-dd HH:MM:SS');
% t_delta = 1./(24*60)*5; % 5 minutes steps for MINUHET
% n = numel([t_start:t_delta:t_end]);
% 
% t_prev = t_start-t_delta;
% i = 1;
% cloudcover_agg = table([NaN],[NaN]);
% cloudcover_agg.Properties.VariableNames = cloudcover.Properties.VariableNames(1:2);
% for t=t_start:t_delta:t_end 
%     idx = find((t_prev <= cloudcover.time) & (cloudcover.time <= (t+t_delta)));
%     cloudcover_agg.time(i) = t;
%     cloudcover_agg.value(i) = round(mean(table2array(cloudcover(idx,2)),'omitnan'),1);
%     t_prev = t;
%     i = i+1;
% end
% 
% cloudcover_agg.value = cloudcover_agg.value./100;
% cloudcover_agg.value(cloudcover_agg.value<0) = 0;
% cloudcover_agg.value(cloudcover_agg.value>1) = 1;
% 
% 
% %%
% t_start = datenum(from(2:end-1),'yyyy-mm-dd HH:MM:SS');
% t_end = datenum(to(2:end-1),'yyyy-mm-dd HH:MM:SS');
% t_delta = 1./(24*60)*5; % 5 minutes steps for MINUHET
% n = numel([t_start:t_delta:t_end]);
% 
% % cloudcover_clean = table([NaN],[NaN]);
% 
% % cloudcover_clean.time(:) = querypoints;
% cloudcover_clean = cloudcover;
% cloudcover_clean.Properties.VariableNames = {'time','value'};
% cloudcover_clean(isnan(cloudcover_clean.value),:) = [];
% cloudcover_clean.value = cloudcover_clean.value./8; % compute pecentage coverage
% cloudcover_clean.value(cloudcover_clean.value>1) = 1;
% cloudcover_clean.value(cloudcover_clean.value<0) = 0;
% querypoints = [t_start:t_delta:t_end].';
% 
% cloudcover_agg.value = interp1(cloudcover_clean.time,cloudcover_clean.value,querypoints,'nearest');
% 


%% PLOT
% 
%figure('name','validation')
%subplot(6,1,1)
%hold on
%yyaxis left
%plot(r02_M.Time,r02_M.rain,'.k')
%area(r02.Time,r02.rain,'FaceColor','r','FaceAlpha',0.6,'EdgeColor','b')
%ylabel('Rainfall intensity \newline [mm/min]')
%set(gca,'YColor','b');
%xlim([datetime(t_start,'ConvertFrom','datenum'),datetime(t_end,'ConvertFrom','datenum')])
%datetick('x')
% 
% 
% TR = timerange("2019","years");
% r02_rainanual=r02_5min(TR,:);
% %yyaxis right
% plot(r02_rainanual.Time,cumsum(r02_rainanual.rain),'-k')
% hold on
% r02_rainanual=r02(TR,:);
% plot(r02_rainanual.Time,cumsum(r02_rainanual.rain),'-r')
% %hold on
% datetick('x')
% ylabel('cumulative rainfall \newline intensity \newline [mm/min]')
% xlim([datetime(t_start,'ConvertFrom','datenum'),datetime(t_end,'ConvertFrom','datenum')])
% % subplot(3,1,2)
% % hold on
% % factor = size(rain,1)./size(rain_agg,1);
% % plot(rain.time,cumsum(rain.value)./factor,'.k')
% % plot(rain_agg.time,cumsum(rain_agg.value),'-r')
% % datetick('x')
% legend('raw data')
% box;
% set(gca,'YColor','r');
% 
% subplot(6,1,2)
% hold on
% plot(airTemp.Time,airTemp.airTemp,'.k')
% xlim([datetime(t_start,'ConvertFrom','datenum'),datetime(t_end,'ConvertFrom','datenum')])
% % area(airTemp_agg.time,airTemp_agg.value,'FaceColor','r','FaceAlpha',0.6,'EdgeAlpha',0)
% datetick('x')
% ylabel('Temperature [�C]')
% %legend('raw data')
% 
% % 
% subplot(6,1,3)
% hold on
% plot(relHum.Time,relHum.Var1,'.k')
 %xlim([datetime(t_start,'ConvertFrom','datenum'),datetime(t_end,'ConvertFrom','datenum')])
 % area(relHum_agg.time,relHum_agg.value,'FaceColor','r','FaceAlpha',0.6,'EdgeAlpha',0)
 %datetick('x')
 %ylabel('Relative Humidity \newline [%]')
 %legend('raw data')
 
 %box;
 %hold on
 %plot(relHum.Time,hampel(relHum.Var1,10,1),'.b')
 %xlim([datetime(t_start,'ConvertFrom','datenum'),datetime(t_end,'ConvertFrom','datenum')])
% % area(relHum_agg.time,relHum_agg.value,'FaceColor','r','FaceAlpha',0.6,'EdgeAlpha',0)
% datetick('x')
% ylabel('Relative Humidity \newline [%]')

% % 
% subplot(6,1,4)
% hold on
% plot(winddata.Time,winddata.windspeed,'.k')
% xlim([datetime(t_start,'ConvertFrom','datenum'),datetime(t_end,'ConvertFrom','datenum')])
% % area(wind_agg.time,wind_agg.value,'FaceColor','r','FaceAlpha',0.6,'EdgeAlpha',0)
% datetick('x')
% ylabel('Wind speed \newline [m/s]')
% %legend('raw data')
% box;
% % 
% subplot(6,1,5)
% hold on
% plot(radiation.Time,radiation.Var1,'.k')
% xlim([datetime(t_start,'ConvertFrom','datenum'),datetime(t_end,'ConvertFrom','datenum')])
% % area(radiation_agg.time,radiation_agg.value,'FaceColor','r','FaceAlpha',0.6,'EdgeAlpha',0)
% datetick('x')
% ylabel('Radiation \newline [W/m2]')
% %legend('raw data')
% box;
% % 
% subplot(6,1,6)
% hold on
% plot(cloudcover.Time,cloudcover.cloudcover,'.k')
% xlim([datetime(t_start,'ConvertFrom','datenum'),datetime(t_end,'ConvertFrom','datenum')])
% % area(cloudcover_agg.time,cloudcover_agg.value,'FaceColor','r','FaceAlpha',0.6,'EdgeAlpha',0)
% datetick('x')
% ylabel('Cloudcover \newline [-]')
% %legend('raw data')
% box;

%% Output data
% datatable_out = [airTemp_agg.value,relHum_agg.value,radiation_agg.value,...
%     wind_agg.value,rain_agg.value./10,cloudcover_agg.value];
% SWMM_rain_2_MINUHET;
dt = minutes(5);
% take the minutely rain data and aggregate to 5min steps, convert to cm
r02_5min = retime(r02,'regular','sum','TimeStep',dt);
% r02_M_5min.rain = r02_M_5min.rain./10;
datatable_out = synchronize(airTemp,relHum,radiation,winddata,r02_5min,cloudcover,'last','nearest');
datatable_out = retime(datatable_out,'regular','TimeStep',dt);
datatable_out_season=datatable_out(TRsim,:);

%TR = timerange('21/02/2019 00:00:00','22/03/2019 00:00:01');
%datatable_out = datatable_out(TR,:);
WSTART = num2str(m2xdate(datatable_out_season.Time(1),0),'%5.5f');
WSTOP = num2str(m2xdate(datatable_out_season.Time(end),0),'%5.5f');
datatable_out_season = timetable2table(datatable_out_season);
datatable_out_season = table2array(datatable_out_season(:,2:end));


%% NOTE TFR: input string error for winter data
% % no negative temperatures -> excluded
%    datatable_out(datatable_out(:,1)<=0,1)=0.1;

%% STORE FILE
% writes a comma seperated inputfile for MINUHET
%datapath_out = strcat('C:\Users\figueral\Documents\Programing\Institution\2020_shx\04_workspace\_swmm_minu\_minu_simulation\swmm_subcatch_sims\',scenarioname,'\');
if not(isfolder(strcat(abspath,"\MINUHET\Weather")))
    mkdir(strcat(abspath,"\MINUHET\Weather"))
end

if ~(auxpath == "")
    if not(isfolder(strcat(abspath,"\MINUHET\Weather\",auxpath)))
    mkdir(strcat(abspath,"\MINUHET\Weather\",auxpath))
    end
    datapath_out=strcat(abspath,"\MINUHET\Weather\",auxpath,"\");
else    
    datapath_out=strcat(abspath,"\MINUHET\Weather","\");
end

%datapath_out=strcat(abspath,'\Codes\Minuhet\');
% filename_out = [datapath_out,'MINUHET_Inputfile_',from(2:11),'_',to(2:11),'.dat'];
% writematrix(datatable_out,filename_out,'Delimiter',',')
[n,mfrom] = month(from(2:11));
[n,mto] = month(to(2:11));
dayear = year(from(2:11));
%filename_climatedata_out = [sourceName(2:end-1),'_',mfrom,'_',mto,'_',num2str(dayear),'.dat'];
%filename_climatedata_out = 'Jan_Dec_2019';
%filepath_out = [datapath_out,filename_climatedata_out];
filepath_out = strcat(datapath_out,'Synthetic01.dat');
% Creating file to be written to
fileID = fopen(filepath_out,'w+');
% Writing data to file
%%%%%%%%%%%%%%%%%%%%%%% HEADER
% ! MINUHET observed design storm file
% ! Contains site run time parameters and weather data
% ! WSTART=start date/time for weather data in Excel format
% ! ASTART=start date/time for runoff analysis in Excel format
% ! TSTEP = weather time step (minutes), NWD = number of weather time steps,
% ! WDAT=weather data (air temp (C), RH (%), Solar (W/m^2, Wind (m/s), 
% ! Precipitation (cm), Cloud Cover Fraction (0=clear, 1= full cloud cover)
%   
% &WRUN
% WSTART=38510.00000
% WSTOP=38525.00000
% TSTEP=15.0/
%   
% &WDATA
% WDAT = 
%%%%%%%%%%%%%%%%%%%%%%%
header = ['! MINUHET observed storm event from ',from(2:end-1),' to ',to(2:end-1),' at ','Jan_Dec_2019.dat'];%sourceName(2:end-1)];
fprintf(fileID, '%s\n', header);
header = ['! Contains site run time parameters and weather data'];
fprintf(fileID, '%s\n', header);
header = ['! WSTART=start date/time for weather data in Excel format'];
fprintf(fileID, '%s\n', header);
header = ['! ASTART=start date/time for runoff analysis in Excel format'];
fprintf(fileID, '%s\n', header);
header = ['! TSTEP = weather time step (minutes), NWD = number of weather time steps,'];
fprintf(fileID, '%s\n', header);
header = ['! WDAT=weather data (air temp (C), RH (%), Solar (W/m^2, Wind (m/s),'];
fprintf(fileID, '%s\n', header);
header = ['! Precipitation (cm), Cloud Cover Fraction (0=clear, 1= full cloud cover)'];
fprintf(fileID, '%s\n', header);
header = [''];
fprintf(fileID, '%s\n', header);
header = ['&WRUN'];
fprintf(fileID, '%s\n', header);
header = ['WSTART=',WSTART];
fprintf(fileID, '%s\n', header);
header = ['WSTOP=',WSTOP];
fprintf(fileID, '%s\n', header);
header = ['TSTEP=',num2str(minutes(dt),1),'.0/'];
fprintf(fileID, '%s\n', header);
header = [''];
fprintf(fileID, '%s\n', header);
header = ['&WDATA'];
fprintf(fileID, '%s\n', header);
header = ['WDAT ='];
fprintf(fileID, '%s\n', header);
for i=1:1:size(datatable_out_season,1)-1
fprintf(fileID, '%.1f, %.1f, %.1f, %.2f, %.2f, %2.1f\n', datatable_out_season(i,[1,2,3,4,6,7]));
end
fprintf(fileID, '%.1f, %.1f, %.1f, %.2f, %.2f, %2.1f%s', datatable_out_season(size(datatable_out_season,1),[1,2,3,4,6,7]),'/');
header = [''];
fprintf(fileID, '%s\n', header);
fclose(fileID);

end
%% Update Global file
%if newinputfile == 1
%datapath_in = 'C:\Users\freytobi\MINUHET\ToolSpace\'
%filename_in = 'global.dat';
%filepath_in = [datapath_in,filename_in];
%fileID2 = fopen(filepath_in,'r');
%i = 1;
%tline = fgetl(fileID2);
%global_header{i} = tline;
%read entire file in
%while ischar(tline)
%    i = i+1;
%    tline = fgetl(fileID2);
%    global_header{i} = tline;
%end
%fclose(fileID2);

%datapath_out = 'C:\Users\freytobi\MINUHET\ToolSpace\'
%filename_out = 'global.dat';
%filepath_out = [datapath_out,filename_out];
%fileID3 = fopen(filepath_out,'w');
%for i = 1:numel(global_header)
%    if global_header{i} == -1
%        n = i-1; %index for the last entry
%        break
%    end
%end

%for i = 1:n-1
%    fprintf(fileID3,'%s\n',global_header{i});
%end
%body = char(global_header{n})
%body = body(1:end-1); % get rid of backslash
%fprintf(fileID3, '%s,\n',body);
%body = ["'",filename_climatedata_out,"'"];
%fprintf(fileID3, '%s%s%s%s\n', body,'/');
%fclose(fileID3)
%else
%disp('no update of global file')
%end