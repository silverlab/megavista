function []= ERSP(par,bef_win,aft_win,event_time,tag,elecs,eventNormtag,loadMeanpath)
% Function: making ERSP
% Input: Spectrogram and events
% Dependencies
% Writen by Mohammad Dastjerdi, Parvizi Lab, Stanford
% Last revision date SEP,2009
% Modified j.chen dec 2009
%
% event_time is a vector of onsets (in seconds) or a cell array of such vectors
% tag is a string (name of the condition) or a cell array of strings
% event_time and tag should be index-aligned and the same length!
% this mod was made in order to avoid loading amplitude files redundantly -jc
%
%
%inputs:
%eventNormtag -allow the user to define the tag number to normalize the
%data to. this will be the "no task" condition that  will be calculate from mean_power  (example: in the case off on
%off visual stimulus we will like to normalize to the off condition (number
%2). the input will be the number eventNormtag=2. if no eventNormtag is
%given then the defult is zeros and all data is used to make the mean_power
%values
%
%
%loadMeanpath: allow to load a mean_power to normalize the amplitudes from
%a different experiment. this could be useful if the  "no task" condition is
%not part of analysis experiment data. the input need to be the other experiment result path (char).
%A.M


if ~exist('elecs','var')
    elecs= [1:par.nchan];
end
elecs=elecs(~ismember(elecs,par.refchan));

if ~iscell(event_time)
    event_time = {event_time};
end
if ~iscell(tag)
    tag = {tag};
end

if ~exist('eventNormtag')
    eventNormtag=0;
end;

if eventNormtag>length(tag)
    eventNormtag=0;
    display( ['the event number ' num2str(eventNormtag) ' is not existenting. Normalize by the mean instad (defult)'])
end;





bef_point= floor(bef_win * par.fs_comp);
aft_point= ceil(aft_win * par.fs_comp);
Npoints= bef_point + aft_point+1; %reading Npoints data point
Wsize= bef_win+ aft_win;






%% Generating ERSP
for ci=elecs
    fprintf(['\nCalculating ERSP for ' par.block ' electrode ' num2str(ci) '\n']);

    % Reading amplitude of channel ci

    load(sprintf('%s/amplitude_%s_%.3d',par.SpecData,par.block,ci)); % 'amplitude'
    signal_power = amplitude.^2; % Signal Power

    if (eventNormtag~=0 & ~exist('loadMeanpath'))
        smpling=par.ieegrate/par.compression;
        tStepN=size(amplitude,2);
        endT=tStepN/smpling;
        t=linspace(0,endT,tStepN);
        st=event_time{eventNormtag};
        ed=st+aft_win;
        signal_powerEvent=[];
        for i=1:length(st);
            l=abs(t-st(i));
            stP(i)=find(l==min(l))+1;
            l=abs(t-ed(i));
            edP(i)=find(l==min(l))-1;
            signal_powerEvent=[signal_powerEvent signal_power(:,stP(i):edP(i))];
            % signal_powerEvent(:S:E,:=signal_powerEvent signal_power(stP(i),edP(i),:);
        end
        mean_power= mean(signal_powerEvent,2);
        clear signal_powerEvent stP edP ed st tStepN endT t smpling
    elseif exist('loadMeanpath')
        load(loadMeanpath); % load the mean from other experiment
        mean_power=ERSP.elecs(ci).meanPower;
    else

        mean_power= mean(signal_power,2);

    end;
    amplitude= signal_power./(mean_power*ones(1,size(signal_power,2))); % normalized by mean of power 4 each freq
    clear signal_power signal_powerEvent

    for cond = 1:length(tag)
        fprintf([tag{cond} ' '])
        condstruct(cond).ERSP.elecs(ci).meanPower= mean_power;
        % Event points- make sure events +/- bounding window fall within timecourse
        event_point= floor(event_time{cond} * par.fs_comp);
        id= (event_point - bef_point);  % to make sure your events didn't start before recording
        jd= (event_point + aft_point);  % changed bef_point to aft_point amr (to make sure event didn't end after recording)
        event_point(id<0)=[];
        event_point(jd>par.chanlength)=[];

        % Averaging ERSP segments
        erp_tmp= zeros(size(amplitude,1),Npoints,length(event_point),'single');
        % Pulling out each timepoint at which an event begins
        for eni=1:length(event_point);
            % Take window from before point to after point for each frequency
            % band for each event
            erp_tmp(:,:,eni)= amplitude(:,event_point(eni)-bef_point:event_point(eni)+aft_point);
        end
        condstruct(cond).ERSP.elecs(ci).value= single(mean(erp_tmp,3));  % Average your events together
        condstruct(cond).ERSP.ntrials = size(erp_tmp,3);
    end
    clear mean_power
    clear amplitude
end

windur = bef_win+aft_win;
windurstr = strrep(num2str(windur),'.','p');
for cond = 1:length(tag)
    fprintf(['\nSaving ERSP for condition ' tag{cond} '\n']);
    ERSP = condstruct(cond).ERSP;
    ERSP.bef_point = bef_point;
    ERSP.aft_point = aft_point;
    ERSP.general.freq= par.freq;
    ERSP.general.fs_comp= par.fs_comp;
    ERSP.general.Npoints=Npoints;
    fn= sprintf('%s',par.Results);
    save(sprintf('%s/ERSP_%s_%s_%s_%s.mat',fn,par.exptname,tag{cond},windurstr,par.block),'ERSP');
end


