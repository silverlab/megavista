function ERP= ecogERPmultblocks(par,elecs,blocknames,eventtimes,bef_win,aft_win,condnames)
% Function: making ERP by combining multiple blocks of data as if they were
% run in a single block. Similar to calculating a simple weighted mean of
% block avgERPs, but a better way of estimating the variance.
% j.chen 07/23/10
%
% Modified from ecogERSPmultblocks
% Writen by Mohammad Dastjerdi, Parvizi Lab, Stanford
%
%  par is a cell array of par structs, 1 for each block.
%
%  elecs are the electrodes that you want to process
%
%  blocknames is a cell array of names of blocks that you want to include
%  in your processing e.g. {'ANP055'    'ANP056'    'ANP062'}
%
%  eventtimes is a cell array of blocks and conditions, with a list of
%  onsets of a condition for that block.  e.g. eventtime{1,2} would refer
%  to all the onset times of the second condition (in condnames) in the
%  first block
%
%  bef_win is the time in seconds before stimulus onset to start
%  calculating the ERP
%
%  aft_win is the time in seconds after stimulus onset to start calculating
%  the ERP
%
%  condnames is a cell array of strings with the names of all the
%  conditions to process
%


%% number of blocks
numBlocks= length(blocknames);
fprintf('\nNumber of blocks: %d\n',numBlocks)

numConds = length(condnames);
fprintf('\nNumber of conditions:  %d\n',numConds)

for condnum = 1:numConds

    %% Event points
    % bef_win= par.winInfo.bef_win;
    % aft_win= par.winInfo.aft_win;
    bef_point= floor(bef_win * par{1}.ieegrate);
    aft_point= ceil(aft_win * par{1}.ieegrate);
    Npoints= bef_point + aft_point+1; %reading Npoints data point

    ERP=[];
    ERP.general.parInfo = par;

    EVP= [];
    for blocknum=1:numBlocks
        event_time= eventtimes{blocknum,condnum};
        event_point= floor(event_time * par{blocknum}.ieegrate);
        id= event_point - bef_point;
        event_point(id<0)=[];
        jd= (event_point + aft_point);
        event_point(jd>par{blocknum}.chanlength)=[];
        EVP{blocknum}= event_point;
        ERP.block(blocknum).Nevents= length(event_point);
    end

    %% Generating ERP
    for ci= elecs
        erp_tmp = [];
        for blocknum = 1:numBlocks
            % Reading EEG of channel ci
            load(sprintf('%s/CARiEEG%s_%.2d',par{blocknum}.CARData,par{blocknum}.block,ci)); % wave
            % Averaging ERP segments
            event_point = EVP{blocknum};
            for eni = 1:length(event_point);
                erp_tmp = [erp_tmp; wave(event_point(eni)-bef_point:event_point(eni)+aft_point)];
                % removing mean of the base line
                erp_tmp(end,:) = erp_tmp(end,:) - mean(wave(event_point(eni)-bef_point:event_point(eni)));
            end
            clear wave
            fprintf('\n channel number %.2d  block number %d', ci,blocknum)
        end
        
        ERP.elecs(ci).mean = mean(erp_tmp,1);
        ERP.elecs(ci).std = std(erp_tmp,0,1);
        ERP.elecs(ci).n = size(erp_tmp,1);
    end


    windur = bef_win+aft_win;
    windurstr = strrep(num2str(windur),'.','p');
    
    fprintf(['\nSaving ERP for condition ' condnames{condnum} '\n']);
    ERP.bef_point = bef_point;
    ERP.aft_point = aft_point;
    ERP.general.freq = par{1}.freq;
    ERP.general.ieegrate = par{1}.ieegrate;
    ERP.general.Npoints = Npoints;
    fn= sprintf('%s',par{1}.Results);
    
    cd(fn)
    cd ..
    multname = [blocknames{1}(1:3) 'mult'];
    if ~exist(multname,'dir')
        mkdir(multname);
    end

    save(sprintf('%s/%s/ERP_%s_%s_%s_%s.mat',fileparts(fn),multname,par{1}.exptname,condnames{condnum},windurstr,multname),'ERP');

end

end
