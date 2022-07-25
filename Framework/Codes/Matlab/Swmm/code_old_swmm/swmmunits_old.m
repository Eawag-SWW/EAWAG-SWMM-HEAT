function res=swmmunits_old(flag,p1,p2,p3)
% scal=swmmunits('scal',fromunit,tounit,nPollut);
% units=swmmunits('unitlist')

switch flag      
case 'scal'
   [cs,cstag,ns,nstag,ls,lstag,ss,sstag]=scale2swmm(p1,p2,p3);
        scal.cs=cs;
        scal.cstag=cstag;
        scal.ns=ns;
        scal.nstag=nstag;
        scal.ls=ls;
        scal.lstag=lstag;
        scal.ss=ss;
        scal.sstag=sstag;
   res=scal;
   return;
case 'unitlist'
    %const float Qcf[6] =                   // Flow Conversion Factors:
bb=   {1.0    , 'cfs' 
       448.831, 'gpm' 
       0.64632, 'mgd'    %// cfs, gpm, mgd --> cfs
       0.02832, 'cms' 
       28.317,  'lps'    
       2.4466,  'mld' % };    // cms, lps, mld --> cfs
       2446.6,  'm3/d' };     % m3/d --> cfs      res=bb(:,2);
   res=bb(:,2);
otherwise
    error;
end;

function [scal,tag]=ucf2swmm(fromflow,item)
if fromflow<3
    col=1;
else
    col=2;
end;    
%       {//  US      SI
aa=     {43200.0   1097280.0    'RAINFALL'  'in/hr'   'mm/h'; %          // RAINFALL (in/hr, mm/hr --> ft/sec)
         12.0      304.8        'RAINDEPTH' 'in'      'mm';   %,         // RAINDEPTH (in, mm --> ft)
         1036800.0 26334720.0   'EVAPRATE'  'in/d'    'mm/d'  %,         // EVAPRATE (in/day, mm/day --> ft/sec)
         1.0       0.3048       'LENGTH'    'ft'      'm'     %,         // LENGTH (ft, m --> ft)
         2.2956e-5 0.92903e-5   'LANDAREA'  'ac'      'ha'    %,         // LANDAREA (ac, ha --> ft2)
         1.0       0.02832      'VOLUME'    'ft3'     'm3'    %,         // VOLUME (ft3, m3 --> ft3)
         1.0       1.608        'WINDSPEED' 'mph'     'km/h'  %},        // WINDSPEED (mph, km/hr --> mph)
         1.0       1.8          'TEMPERATURE' 'deg F' 'deg C' %,         // TEMPERATURE (deg F, deg C --> deg F)
         2.203e-6  1.0e-6       'MASS'      'lb'      'kg'};      %}         // MASS (lb, kg --> mg)
%const float Qcf[6] =                   // Flow Conversion Factors:
bb=   {1.0    , 'cfs' 
       448.831, 'gpm' 
       0.64632, 'mgd'    %// cfs, gpm, mgd --> cfs
       0.02832, 'cms' 
       28.317,  'lps'    
       2.4466,  'mld' % };    // cms, lps, mld --> cfs
       2446.6,  'm3/d' };     % m3/d --> cfs   
switch item 
case 'FLOW'
     scal=bb{fromflow+1,1};
     tag=bb{fromflow+1,2};
otherwise
     idx=strcmp(item,aa(:,3));
     if isempty(idx)
         error;
     end;    
     scal=aa{idx,col};
     tag=aa{idx,col+3};
end;

function [cs,cstag,ns,nstag,ls,lstag,ss,sstag]=scale2swmm(fromflow,tounit,nPollut)
% tounit =1 ..6
%fromflow=oo.FlowUnit;
cst={'RAINFALL'   % catchtypes={'rainfall';
     'RAINDEPTH'  %             'snowdepth';
     'RAINFALL'   %             'losses';
     'FLOW'       %             'runoff';
     'FLOW'       %             'gwflow';
     'LENGTH'};           %             'gwelev'
cstag=cell(6+nPollut,1);
cs=ones(6+nPollut,1);
for i=1:size(cst,1)
    [scal,tag]=ucf2swmm(fromflow,cst{i});    
    [scalto,tagto]=ucf2swmm(tounit,cst{i}); 
    cs(i)=scalto/scal;
    cstag{i}=tagto;
end; 
      
nst={'LENGTH'  %'depth'
     'LENGTH'    %'head';
     'VOLUME'    %  'volume';
     'FLOW'      %'latflow';
     'FLOW'      %'inflow';
     'FLOW'}; %     'overflow'};       
nstag=cell(6+nPollut,1);
ns=ones(6+nPollut,1);
for i=1:6
    [scal,tag]=ucf2swmm(fromflow,nst{i});    
    [scalto,tagto]=ucf2swmm(tounit,nst{i}); 
    ns(i)=scalto/scal;
    nstag{i}=tagto;
end;    
      
lst={'FLOW'  %flow
     'LENGTH'    %depth
     'LENGTH'};    %  velo      
lstag=cell(5+nPollut,1);
ls=ones(5+nPollut,1);
for i=1:3
    [scal,tag]=ucf2swmm(fromflow,lst{i});    
    [scalto,tagto]=ucf2swmm(tounit,lst{i}); 
    ls(i)=scalto/scal;
    lstag{i}=tagto;
end; 
 
sst={'TEMPERATURE'  %// air temperature
     'RAINFALL'    %// rainfall intensity
     'RAINDEPTH'   %// snow depth
     'RAINDEPTH'   %// evap + infil
     'FLOW'        %// runoff flow
     'FLOW'        %// dry weather inflow
     'FLOW'        %// ground water inflow
     'FLOW'        %// RDII inflow
     'FLOW'        %// external inflow
     'FLOW'        %// total lateral inflow
     'FLOW'        %// flooding outflow
     'FLOW'        %// outfall outflow
     'VOLUME'    %// storage volume  
     'EVAPRATE'}; %// Evaporation
sstag=cell(14,1);
ss=ones(14,1);
for i=1:14
    [scal,tag]=ucf2swmm(fromflow,sst{i});    
    [scalto,tagto]=ucf2swmm(tounit,sst{i}); 
    ss(i)=scalto/scal;
    sstag{i}=tagto;
end;    