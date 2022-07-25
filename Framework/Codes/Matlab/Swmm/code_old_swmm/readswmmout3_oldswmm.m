function [e1,e2,e3]=readswmmout3_oldswmm(flag,p1,p2,p3,p4)
% readswmmout2   [e1,e2,e3]=readswmmout2(flag,p1,p2,p3,p4)
%           
%           Reads a SWMM5 binary output file (*.out). 
% [d] =  readswmmout2('open',filename,[Modelname])
%           read the file header and return the result in the Matlab
%           struct d. filname must be a valid swmm output file name
%           e.g. 'swmm1.out'). The optional argument Modelname must be
%           a FOX3 model and is used to get the sediment fractions names.
%
% [err,res]=  readswmmout2('get',d,[fromidx,toidx])
%           get a set of data from output file. 
%           d - Matlab struct desribing the file (created 
%               by readswmmout2('open',filename))
%           fromidx, toidx - Index of time steps, maximum value is
%               d.Nperiods
%
% [err,res]=  readswmmout2('getidx',d,[fromidx,toidx],itemidx)
%           get a set of selected data from output file. 
%           d - Matlab struct desribing the file (created 
%               by readswmmout2('open',filename))
%           fromidx, toidx - Index of time steps, maximum value is
%               d.Nperiods
%           itemidx - vector of colum index of result data
%
% [err,res,unitlist]=  readswmmout2('getitems',d,[fromidx,toidx],itemlist,[flowunit])
%           get a set of named selected data from output file. 
%           d - Matlab struct desribing the file (created 
%               by readswmmout2('open',filename))
%           fromidx, toidx - Index of time steps, maximum value is
%               d.Nperiods
%           itemlist - cell array of strings describing the data to select
%               in the format 'type id item' with 
%                   type=[catch|node|link|system]
%                   if type == catch: 
%                     item=[rainfall|snowdepth|losses|runoff|gwflow|gwelev|[PollutantId]]
%                   if type == node
%                     item=[depth|head|volume|latflow|inflow|overflow|[PollutantId]]
%                   if type == link
%                     item=[flow|depth|velocity|froude|capacacity|[PollutantId]]
%                   if type == system
%                     item=[temperature|rainfall|snowdepth|losses|runoff|
%                           dwflow|gwflow|rdiiflow|exflow|inflow|flooding|
%                           outflow|storage]
%                     for type ==system, obmit id, example:
%               itemlist={'link c1 depth'
%                         'node J1 depth'
%                         'system rainfall'}
%           flowunit - optional parameter defining the units of the
%               returned values (default =m3/d), possible values are
%               cfs, gpm, mgd, cms,    lps, mld, m3/d
%           unitlist - list of units for returned items

% i f a k   Institut fuer Automation und Kommunikation e.V. Magdeburg
%           Steinfeldstraﬂe (IGZ), 39179 Barleben
%
% Aenderungen  Autor, Datum, Version, Anlass
%
%           J. Alex;        19.12.2004, SIMBA 5.0, creation of file
%           J. Alex;        22.05.2006, SIMBA 5.0, adaption to SWMM 5006,
%                                                  small bugfix for hoild on and sediment
%           F.Blumensaat    04.05.2010, addresses 'Out of memory' problem. 
%           F.Blumensaat    22.05.2016, implement the option to read 'flooding' for nodes  

e1=[];e2=[];e3=[];
switch flag
case 'open'
    fname=p1;    
	fid=fopen(fname,'r');
	if fid<0
        error('Can''t open the file.');
	end;    
	nn=fread(fid,7,'int32');
	if nn(1)~=516114522
        error('Not a valid swmm5 output file.');
    end;
    switch nn(2)
        case 50003
            d.Version=50003;
        case 50006
            d.Version=50006;
        case 50009500
            d.Version=50006;
        case 50010
            d.Version=50006;
        case 51000
            d.Version=50006;
        case 51011
            d.Version=50006;
        case 51013
            d.Version=50006;
        case 51015
            d.Version=50006;
        otherwise
            error(['Unknown SWMM Version ',int2str(nn(2))]);
    end;
	d.FlowUnit=nn(3);
	d.nCatch=nn(4);
	d.nNode=nn(5);
	d.nLink=nn(6);
	d.nPollut=nn(7);
	d.idCatch=cell(d.nCatch,1);
	for i=1:d.nCatch
       nn=fread(fid,1,'int32');
       id=fread(fid,nn,'uchar');
       d.idCatch{i}=char(id');
	end 
	d.idNode=cell(d.nNode,1);
	for i=1:d.nNode
       nn=fread(fid,1,'int32');
       id=fread(fid,nn,'uchar');
       d.idNode{i}=char(id');
	end 
	d.idLink=cell(d.nLink,1);
	for i=1:d.nLink
       nn=fread(fid,1,'int32');
       id=fread(fid,nn,'uchar');
       d.idLink{i}=char(id');
	end 
	d.idPollut=cell(d.nPollut,1);
	for i=1:d.nPollut
       nn=fread(fid,1,'int32');
       id=fread(fid,nn,'uchar');
       d.idPollut{i}=char(id');
    end
    if d.Version==50006
        % codes of pollutant concentration units
      for i=1:d.nPollut
         nn=fread(fid,1,'int32');
      end
    end    
    
    d.NsubCatchArea=fread(fid,1,'int32'); % 1  
    d.subCatchArea=fread(fid,d.NsubCatchArea,'int32'); % 
    d.catchArea=zeros(d.nCatch,1);
    for i=1:d.nCatch
       d.catchArea(i)=fread(fid,1,'float'); 
    end;  
    
    d.Nnodetype1=fread(fid,1,'int32'); %
    d.nodetype1=fread(fid,d.Nnodetype1,'int32'); %

    d.nodetype=zeros(d.nNode,d.Nnodetype1); % type,invertelev,maxdepth
    for i=1:d.nNode
        d.nodeType(i,1)=fread(fid,1,'int32');
        d.nodeType(i,[2:d.Nnodetype1])=fread(fid,d.Nnodetype1-1,'float');
    end;           
    
    d.Nlinktype1=fread(fid,1,'int32'); %
    d.linktype1=fread(fid,d.Nlinktype1,'int32'); %
    d.linkType=zeros(d.nLink,d.Nlinktype1);
    for i=1:d.nLink
        d.linkType(i,1)=fread(fid,1,'int32');
        d.linkType(i,[2:d.Nlinktype1])=fread(fid,d.Nlinktype1-1,'float');
    end; 
    d.NcatchIdx=fread(fid,1,'int32');
    d.catchIdx=fread(fid,d.NcatchIdx,'int32'); % catch idx
    d.NnodeIdx=fread(fid,1,'int32');
    d.nodeIdx=fread(fid,d.NnodeIdx,'int32'); % node idx
    d.NlinkIdx=fread(fid,1,'int32');
    d.linkIdx=fread(fid,d.NlinkIdx,'int32'); % node idx
    d.NsysIdx=fread(fid,1,'int32');
    d.sysIdx=fread(fid,d.NsysIdx,'int32');   %sys idx
    
    d.starttime=fread(fid,1,'double');
    d.startstep=fread(fid,1,'int32');
    
    fseek(fid,-(6*4),'eof');
    d.IDstartPos=fread(fid,1,'int32');
    d.InputstartPos=fread(fid,1,'int32');
    d.OutputStartpos=fread(fid,1,'int32');
    d.Nperiods=fread(fid,1,'int32');
    d.ErrorCode=fread(fid,1,'int32');
    fclose(fid);    
    d.fname=fname;
    
    %check for .sedout file
    [pp,fn,ext]=fileparts(fname);
    fnamesed=strcat(pp, fn, '.sedout');
    if exist(fnamesed)==2
        fid=fopen(fnamesed,'r');
	    if fid<0
           error('Can''t open the file.');
	    end;    
	    nn=fread(fid,5,'int32');
	    if nn(1)~=516114522
           error('Not a valid simba sediment output file.');
	    end;
        if nn(3)~=d.nNode
            error('Number of nodes in sediment file incompatible');
        end;
        if nn(4)~=d.nLink
            error('Number of links in sediment file incompatible');
        end;
        d.nSedi=nn(5);
        fclose(fid);    
        d.fnamesed=fnamesed;
        d.idSedi={};
        if nargin>2
            foxname=p2;
            [calc,siz,pname,x0,ud]=readfox3(foxname);
            if isempty(calc)
              error(['FOX3 Model ',foxname,' not found.']);
            end;
	
            if ~strcmp(ud.ModelType,'SR')
                error(['Wrong model type of model',foxname,'. Type is ',ud.ModelType,' but should be SR.']);
            end;   
            d.idSedi=ud.Fractions.Name(ud.ModelSpec.numFrac1+1:end);
            if size(d.idSedi,1)~=d.nSedi
                error('Sediment output file and FOX model not consistent.');
            end;    
        end;    
    else
        d.nSedi=0;
        d.idSedi={};
    end;    
    e1=d;
    
case 'get'
    d=p1;
    idx1=p2(1);
    idx2=p2(2);
    e1=0;
    e2=[];
    if (idx1<1) || (idx2>d.Nperiods) || (idx2<idx1)
        disp('wrong index');
        e1=3;
        return;
    end;  
    fid=fopen(d.fname,'r');
	k=2+d.NcatchIdx*d.nCatch+d.NnodeIdx*d.nNode+d.NlinkIdx*d.nLink+d.NsysIdx;
    t=([idx1:idx2]'-1)*d.startstep/(60*60*24); %+d.starttime+datenum('1-Jan-1900')-2;
    fseek(fid,d.OutputStartpos+((idx1-1)*k)*4,'bof');   
    nsteps=idx2-idx1+1;  
    res=fread(fid,[k,nsteps],'float32'); 
    e2=[t,res(3:end,:)'];
    fclose(fid);
    
    if (d.nSedi>0)
        fid=fopen(d.fnamesed,'r');
	    k=1+d.nSedi*(d.nNode+d.nLink);
        fseek(fid,5*4+((idx1-1)*k)*8,'bof');   
        nsteps=idx2-idx1+1;  
        res=fread(fid,[k,nsteps],'double'); 
        e2=[e2,res(2:end,:)'];
        fclose(fid);
    end;    
    %e2=res;

case 'getidx'
    % [err,res]=  readswmmout2('getidx',d,[fromidx,toidx],itemidx)
    rowbuf=10000;
    
    d=p1;
    idx1=p2(1);
    idx2=p2(2);
    iidx=p3;
    
    e1=0;
    e2=[];
    if (idx1<1) || (idx2>d.Nperiods) || (idx2<idx1)
        disp('wrong index');
        e1=3;
        return;
    end;  
    t=([idx1:idx2]'-1)*d.startstep/(60*60*24); %+d.starttime+datenum('1-Jan-1900')-2;
    fid=fopen(d.fname,'r');    
	k=2+d.NcatchIdx*d.nCatch+d.NnodeIdx*d.nNode+d.NlinkIdx*d.nLink+d.NsysIdx;
    fseek(fid,d.OutputStartpos+((idx1-1)*k)*4,'bof');   
    nsteps=idx2-idx1+1;  
    if (d.nSedi>0)
        fidsed=fopen(d.fnamesed,'r');
	    ksed=1+d.nSedi*(d.nNode+d.nLink);
        fseek(fidsed,5*4+((idx1-1)*k)*8,'bof');
    end    
    i=0;
    e2=[];
    while 1
       nn=min(rowbuf,nsteps-i); 
       i=i+nn;
       res1=fread(fid,[k,nn],'float32');  
       if d.nSedi>0
          ressed=fread(fidsed,[ksed,nn],'double');
          res1=[res1(3:end,:);
                ressed(2:end,:)]';
          res1=res1(:,iidx);
       else
%           res1=[res1(iidx+3,:)]'; 
          res1=[res1(iidx+2,:)]';    
       end;          
       e2=[e2;res1];
       if i>=nsteps
           break;
       end;    
   end   
   fclose(fid);
   if d.nSedi>0
       fclose(fidsed);
   end;
   e2=[t,e2];

%--------------------------------------------------------------------------
% Auslesen der Simulationsergebnisse einzelner Elemente (in Liste) --------
%--------------------------------------------------------------------------
case 'getitems'
    % [err,res,unitlist]=  readswmmout3('getitems',d,[fromidx,toidx],itemlist,[flowunit])
    d=p1;               % file structure obtained through readswmmout3('open',fileName)
    idxt1 = p2(1);        % indexStartTime
    idxt2 = p2(2);        % indexEndTime
    items = p3;           % list of names of items to be read, e.g. itmelist = {'link 1 flow'};
    if nargin<5
        flowunit='m3/d'; % standard setting for SWMM unit
    else
        flowunit=p4;
    end;

    e1=0;
    e2=[];
    e3=[];
    types={'catch','node','link','system'};
    catchtypes={'rainfall';
            'snowdepth';
            'evap';
            'infil';
            'runoff';
            'gwflow';
            'gwelev';
            'soilm';
            'washoff'};
    linktypes={'flow';
          'depth';
          'velocity';
          'froude';
          'capacacity'};
    nodetypes={'depth'
          'head';
          'volume';
          'latflow';
          'inflow';
          'flooding'}; %... 'overflowflooding' 
    systemtypes={'temperature';
             'rainfall';
             'snowdepth';
             'losses';
             'runoff';
             'dwflow';
             'gwflow';
             'rdiiflow';
             'exflow';
             'inflow';
             'flooding';
             'outflow';
             'storage'};

    units=swmmunits_old('unitlist');
    idxu=strmatch(flowunit,units,'exact');
    if isempty(idxu)
        error(['Unknown unit ',flowunit]);
    end;    
    scal=swmmunits_old('scal',d.FlowUnit,idxu-1,d.nPollut);

    idx=zeros(1,size(items,1)); 
    sscal=ones(size(items,1),1);
    units=cell(size(items,1),1);
    for i=1:size(items)
        it=items{i};
        [typ,it]=strtok(it);
        [id,it]=strtok(it);
        [vali]=strtok(it);
        switch typ
        case 'catch'
            ididx=strmatch(id,d.idCatch,'exact');

            if isempty(ididx)
                error('Unknown catchment ',id,'.');
            end;
            validx=strmatch(vali,[catchtypes;d.idPollut],'exact');
          
            if isempty(validx)
                error('Unknown catchment property ',vali,'.');
            end;
            k=0; %d.NcatchIdx*d.nCatch; %+d.NnodeIdx*d.nNode; %+d.NlinkIdx*d.nLink+d.NsysIdx;
            idx(i)=k+(ididx-1)*d.NcatchIdx+validx; 
            sscal(i)=scal.cs(validx);
            units{i}=scal.cstag{validx};
            %%
        case 'node'
            ididx=strmatch(id,d.idNode,'exact');
            if isempty(ididx)
                error('Unknown node ',id,'.');
            end;
            validx=strmatch(vali,[nodetypes;d.idPollut],'exact');
            if isempty(validx)
                %try sedi
                if d.nSedi>0
                    validx=strmatch(vali,d.idSedi,'exact');
                    if isempty(validx)    
                       error('Unknown node property ',vali,'.');
                    else
                       k=d.NcatchIdx*d.nCatch+d.NnodeIdx*d.nNode+d.NlinkIdx*d.nLink+d.NsysIdx+d.nSedi*d.nLink; 
                       idx(i)=k+(ididx-1)*d.nSedi+validx;
                       sscal(i)=1;
                       units{i}='-';
                       continue;
                    end;  
                else
                    error('Unknown node property ',vali,'.');
                end;    
            end;
            k=d.NcatchIdx*d.nCatch; %+d.NnodeIdx*d.nNode; %+d.NlinkIdx*d.nLink+d.NsysIdx;
            idx(i)=k+(ididx-1)*d.NnodeIdx+validx;
            sscal(i)=scal.ns(validx);
            units{i}=scal.nstag{validx};
            %%
        case 'link'
            ididx = strmatch(id,d.idLink,'exact');
            if isempty(ididx)
                error('Unknown link ',id,'.');
            end;
            validx = strmatch(vali,[linktypes;d.idPollut],'exact');
            if isempty(validx)
                if d.nSedi>0
                    validx=strmatch(vali,d.idSedi,'exact');
                    if isempty(validx)    
                       error('Unknown link property ',vali,'.');
                    else
                       k=d.NcatchIdx*d.nCatch+d.NnodeIdx*d.nNode+d.NlinkIdx*d.nLink+d.NsysIdx; 
                       idx(i)=k+(ididx-1)*d.nSedi+validx;
                       sscal(i)=1;
                       units{i}='-';
                       continue;
                    end;  
                else
                    error('Unknown link property ',vali,'.');
                end;    
            end;
            
            % calculate the number of preceding indeces in the outfile
            k = d.NcatchIdx*d.nCatch + d.NnodeIdx*d.nNode; %+d.NlinkIdx*d.nLink+d.NsysIdx;
            idx(i) = k + (ididx-1)*d.NlinkIdx + validx;
            sscal(i) = scal.ls(validx);
            units{i} = scal.lstag{validx};
            %%
        case 'system'
            validx=strmatch(id,[systemtypes],'exact');
            if isempty(validx)
                error('Unknown system property ',id,'.');
            end;
            k=d.NcatchIdx*d.nCatch+d.NnodeIdx*d.nNode+d.NlinkIdx*d.nLink; %+d.NsysIdx;
            idx(i)=k+validx;    
            sscal(i)=scal.ss(validx);
            units{i}=scal.sstag{validx};
        otherwise
            error(['Unknown type ',typ,'.']);
        end;    
    end;
    %%
    timeIdxLimit = 1000;
    res = [];
%     res = NaN(d.Nperiods,2);
    if d.Nperiods > timeIdxLimit
        nReadingCycles = floor(d.Nperiods/timeIdxLimit);
        for w = 1:nReadingCycles
            IDstartTime = idxt1+(w-1)*timeIdxLimit;
            IDendTime = IDstartTime+timeIdxLimit;
            [err,yNeu]=  readswmmout3_oldswmm('getidx',d,[IDstartTime, IDstartTime+timeIdxLimit-1],idx);
            res = vertcat(res,yNeu);
        end %for
        %%read rest
        [err,yNeu]=  readswmmout3_oldswmm('getidx',d,[IDstartTime+timeIdxLimit,d.Nperiods],idx);
        res = vertcat(res,yNeu);
        y = res;
    else
        %[err,res]=readswmmout2('get',d,[1,d.Nperiods]);
        [err,y]=  readswmmout3_oldswmm('getidx',d,[idxt1,idxt2],idx);
    end %if
    
    e1=err;
    if e1==0
      e2=y*diag([1;sscal]);
      e3=units;
    end;
    %y=res(:,idx);
%     t=[0:d.Nperiods-1]'*d.startstep/(60*60*24); %in d
%     if t(end)<5
%         t=t*24;
%         xl='t [h]';
%     elseif t(end)<1
%         t=t*24*60;
%         xl='t [s]';
%     else
%         xl='t [d]';
%     end;    
% plot(t,y*diag(sscal));
% for i=1:size(items)
%     items{i}=[items{i},' [',units{i},']'];
% end;    
% xlabel(xl);
% legend(items);

otherwise
    error('unknown flag');
end;    
