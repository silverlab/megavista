function ERSP= ecogERSPmultblocks(par,elecs,blocknames,eventtimes,bef_win,aft_win,condnames)
% Function: making ERSP by combining multiple blocks of data
% Input: Spectrogram and events
% Dependencies
% Writen by Mohammad Dastjerdi, Parvizi Lab, Stanford
% Last revision date Feb,2010
%
%  adapted by amr from Mohammad's ersp2 to fit in with Wandell/Wagner lab ecog
%  code
%
%  This way of getting the ERSP is intended to work with
%  ecogERSPsurrogatePhaseShuffle.m, which will create surrogate data in a
%  better way across multiple blocks.
%
%  par contains a lot of information about the experiment.  It is a cell
%  array, 1 entry per block
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
%  calculating the ERSP
%
%  aft_win is the time in seconds after stimulus onset to start calculating
%  the ERSP
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
    bef_point= floor(bef_win * par{1}.fs_comp);
    aft_point= ceil(aft_win * par{1}.fs_comp);
    Npoints= bef_point + aft_point+1; %reading Npoints data point

    ERSP=[];
    ERSP.general.parInfo = par;

    EVP= [];
    for blocknum=1:numBlocks
        event_time= eventtimes{blocknum,condnum};
        event_point= floor(event_time * par{blocknum}.fs_comp);
        id= event_point - bef_point;
        event_point(id<0)=[];
        jd= (event_point + bef_point);
        event_point(jd>par{blocknum}.chanlength)=[];
        EVP{blocknum}= event_point;
        ERSP.block(blocknum).Nevents= length(event_point);
    end

    %% Generating ERSP
    for ci= elecs
        mean_power=[];
        power=[];
        for blocknum=1:numBlocks
            block_name= par{blocknum}.block;
            % Reading amplitude of channel ci
            load(sprintf('%s/amplitude_%s_%.3d',par{blocknum}.SpecData,block_name,ci)); % 'amplitude'
            amplitude= amplitude.^2; % Signal Power
            numFreq= size(amplitude,1);
            mean_power= mean(amplitude,2);
            mp= mean_power*ones(1,size(amplitude,2));
            power{blocknum}= amplitude./mp; % normalized by mean of power 4 each freq
            ERSP.elec(ci).block(blocknum).meanPower= mean_power;
            clear amplitude
            fprintf('\n channel number %.2d  block number %d', ci,blocknum)
        end

        % Averaging ERSP segments
        %erp_tmp= zeros(numFreq,Npoints,totalNumEv,'single');
        %ent=0;
        for blocknum=1:numBlocks
            power_tmp=[];
            event_point= EVP{blocknum};
            power_tmp= power{blocknum};
            erp_tmp= zeros(numFreq,Npoints,length(event_point),'single');

            for eni=1:length(event_point);
                erp_tmp(:,:,eni)= power_tmp(:,event_point(eni)-bef_point:event_point(eni)+aft_point);
            end
            ERSP.elec(ci).block(blocknum).power= single(sum(erp_tmp,3));
        end

        clear amplitude
    end


    windur = bef_win+aft_win;
    windurstr = strrep(num2str(windur),'.','p');
    
    %for cond = 1:length(condnames)
    fprintf(['\nSaving ERSP for condition ' condnames{condnum} '\n']);
    %ERSP = condstruct(cond).ERSP;
    ERSP.bef_point = bef_point;
    ERSP.aft_point = aft_point;
    ERSP.general.freq= par{1}.freq;
    ERSP.general.fs_comp= par{1}.fs_comp;
    ERSP.general.Npoints=Npoints;
    fn= sprintf('%s',par{1}.Results);
    
    cd(fn)
    cd ..
    multname = [blocknames{1}(1:3) 'mult'];
    if ~exist(multname,'dir')
        mkdir(multname);
    end

    save(sprintf('%s/%s/ERSP_%s_%s_%s_%s.mat',fileparts(fn),multname,par{1}.exptname,condnames{condnum},windurstr,multname),'ERSP');
    %end

end


end
