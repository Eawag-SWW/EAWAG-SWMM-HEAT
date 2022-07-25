%% swmm_rainfall 
% script to run runoff simulation with swmm, then create output files with
% flows
% 
% AF, 10/14/2021

function swmm_rainfall(swmminp,abspath,auxpath)

if not(isfolder(strcat(abspath,"\MINUHET\SWMM_rainfall")))
    mkdir(strcat(abspath,"\MINUHET\SWMM_rainfall"))
end
swmmpath=strcat(abspath,"\MINUHET\SWMM_rainfall\");
%copy executable files
status=copyfile(strcat(abspath,"\Codes\Swmm\swmm5.dll"),swmmpath);
status=copyfile(strcat(abspath,"\Codes\Swmm\swmm5.exe"),swmmpath);
%status=copyfile(strcat(abspath,"\MINUHET\Scenarios\",auxpath,"\",swmminp,".inp"),swmmpath);
status=copyfile(strcat(swmminp,".inp"),swmmpath);

%filename_in = strcat(swmmpath,sprintf("%s.inp",swmminp));
%filename_out = strcat(swmmpath,sprintf("%s.out",swmminp));
%filename_report = strcat(swmmpath,sprintf("%s.rpt",swmminp));

filename_in = sprintf("%s.inp",swmminp);
filename_out = sprintf("%s.out",swmminp);
filename_report = sprintf("%s.rpt",swmminp);

%run batch file
oldFolder = cd(swmmpath)
command=strcat(swmmpath,"swmm5.exe",{' '},filename_in,{' '},filename_report,{' '},filename_out)
[status,cmdout] = system(command)
%cmdout
cd(oldFolder)

if ~(auxpath == "")
    mkdir(strcat(abspath,"\MINUHET\SWMM_rainfall\",auxpath))
    outpath=strcat(abspath,"\MINUHET\SWMM_rainfall\",auxpath,'\');
else    
    outpath=strcat(abspath,"\MINUHET\SWMM_rainfall\");
end
    SWMM_subcatch_out(filename_in,filename_out,outpath)
end