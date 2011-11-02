function surrogate= ecogSurrogatePhaseShuffle(par,elecs,blocknames,eventtimes,bef_win,aft_win,condnames,nametag)
%
% Writen by Mohammad Dastjerdi, jerdi@stanford.edu
% Cognitive Neurology Lab, Dr. Parvizi Lab, Stanford
% Last revision date FEB,2010
%
% Dependencies: surrogateDataFT.m
% Application: 1)Combining mulitple blocks 2)Experiments with two blocks
%
% This code is a better way of producing surrogate data (to calculate Z
% scores).  It uses scrambling of the phase of the signal to produce the
% surrogate.  
%
%This code was adapted from Mohammad's original code by amr, June 2010.
%

%% number of blocks
numBlocks= length(blocknames);
fprintf('\nNumber of blocks: %d\n',numBlocks)

numConds = length(condnames);
fprintf('\nNumber of conditions:  %d\n',numConds)

for condnum = 1:numConds

    %% Event points
    bef_point= floor(bef_win * par{1}.fs_comp);
    aft_point= ceil(aft_win * par{1}.fs_comp);
    Npoints= bef_point + aft_point+1; %reading Npoints data point

    EVP= [];
    totalNumEv=0;
    for blocknum=1:numBlocks
        event_time= eventtimes{blocknum,condnum};
        event_point= floor(event_time * par{blocknum}.fs_comp);
        id= event_point - bef_point;
        event_point(id<0)=[];
        jd= (event_point + bef_point);
        event_point(jd>par{blocknum}.chanlength)=[];
        EVP{blocknum}= event_point;
        totalNumEv= totalNumEv + length(event_point);
    end

    surrogate=[];
    surrogate.info= par;
    surr_iter= 100;

    for ci= elecs
        input=[];
        for blocknum=1:numBlocks
            mp=[];
            block_name= par{blocknum}.block;
            % Reading amplitude of channel ci
            load(sprintf('%s/amplitude_%s_%.3d',par{blocknum}.SpecData,block_name,ci)); % 'amplitude'
            numFreq= size(amplitude,1);

            amplitude= amplitude.^2; % Signal Power
            mp= mean(amplitude,2);
            mp= mp*ones(1,size(amplitude,2));
            power_tmp= amplitude./mp; % normalized by mean of power 4 each freq
            clear amplitude

            % window around events
            event_point= EVP{blocknum};
            erp_tmp= zeros(numFreq,Npoints,length(event_point),'single');
            for eni=1:length(event_point);
                erp_tmp(:,:,eni)= power_tmp(:,event_point(eni)-bef_point:event_point(eni)+aft_point);
            end
            %size(erp_tmp)
            input= [input , reshape(erp_tmp,numFreq,length(event_point)*Npoints)];

            fprintf('\n block %.2d  channel %.2d\n',blocknum, ci)
        end

        surr_sum= zeros(numFreq,Npoints,'single');
        surr_sqr= zeros(numFreq,Npoints,'single');
        for si=1:surr_iter
            if mod(si,10)==1
                fprintf('\niteration %.3d  channel %.2d',si,ci)
            end
            % it takes at least 5 sec for 50 events on a 2.6 GH processor
            %tic
            input = ecogSurrogateDataFT(input); %Randomizing phase for all blocks
            %toc
            %size(input)
            % orig cmd: ERP_tmp= reshape(input, numFreq, Npoints,length(event_point)*numBlocks);
            % reshape to # of trials, which may not be
            % length(event_point)*numBlocks if nTrials per block is not
            % always same -jc 07/17/10
            ERP_tmp= reshape(input, numFreq, Npoints,size(input,2)/Npoints); 
            %size(ERP_tmp)
            ERP= mean(ERP_tmp,3);
            %size(ERP)
            surr_sum= surr_sum + ERP;
            surr_sqr= surr_sqr + ERP.^2;
        end
        surrogate.elecs(ci).MN= surr_sum./surr_iter;
        variance= (surr_sqr - (surr_sum).^2./surr_iter) ./ (surr_iter-1);
        if isreal(sqrt(variance))
            surrogate.elecs(ci).STD= sqrt(variance);
            surrogate.elecs(ci).SEM= sqrt(variance/surr_iter);
        else
            error('surr_iter is not big enough')
        end
    end

    % Save surrogate file
    windur = bef_win+aft_win;
    windurstr = strrep(num2str(windur),'.','p');
    fprintf(['\nSaving surrogate data for condition ' condnames{condnum} ' window duration ' windurstr '\n']);
    %surrogate = condstruct(cond).surrogate;
    surrogate.general.freq = par{1}.freq;
    surrogate.general.fs_comp = par{1}.fs_comp;
    fn= sprintf('%s',par{1}.Results);
    
    cd(fn)
    cd ..
    multname = [blocknames{1}(1:3) 'mult'];
    if ~exist(multname,'dir')
        mkdir(multname);
    end

    if exist('nametag','var')
        save(sprintf('%s/%s/surrogate_%s_%s_%s_%s_%s.mat',fileparts(fn),multname,par{1}.exptname,condnames{condnum},windurstr,multname,nametag),'surrogate');
    else
        save(sprintf('%s/%s/surrogate_%s_%s_%s_%s.mat',fileparts(fn),multname,par{1}.exptname,condnames{condnum},windurstr,multname),'surrogate');
    end
end
return

