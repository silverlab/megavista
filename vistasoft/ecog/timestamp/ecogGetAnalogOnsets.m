
% Plots the analog channel and allows user to select the first spike
% corresponding to the first experimental event (flash). Returns the onset
% times (in seconds) of all spikes in the channel, using selected spike as
% t=0. firstEvent is the duration (in analog samples) from the beginning of the
% analog recording to the selected first event. This will be used later
% when aligning events to the channel data.
% JC & AR 09/16/08 Wrote it

function [onsets firstEvent] = ecogGetAnalogOnsets(analog,samplerate,firstIndex)
% note that the samplerate here should be the analog channel sample rate

% params
if ~exist('samplerate','var')
    samplerate = 3051.76;
end
if ~exist('firstIndex','var')
    % if you used flinitseq, firstIndex is 13 because there are 12 % init flashes.
    firstIndex = 13;
end

thresh = 0.5 * max(analog); % find half the height of tallest spike
trigindex = find(analog>thresh); % find all points that are > thresh (in samples)
                                 % multiple points per spike are returned

figure(10); clf;
set(10,'Position',[4 840 1339 353]);
hold on
plot(analog,'r'); % show spikes
% plot(trigindex,thresh,'gx'); % This step takes way too long

% find the first trig point per spike (in samples)
trigvector = zeros(1,length(analog));
trigvector(trigindex) = 1;
temp = [0 trigvector(1:end-1)];
events = find((trigvector-temp)>0); % (in samples)


% firstIndex sets the initial placement of firstEvent, which user then adjusts.
firstEvent = events(firstIndex);

% Allow the user to select first event. This will be the new zero point.
while 1
    plot(firstEvent,thresh+0.05,'bp');
        i = find(trigindex==firstEvent); % plot just the trigindex values near firstEvent
        %plot(trigindex(1:i+1000),thresh,'gx');
    plot(trigindex(i-500:i+500),thresh,'gx');
%     plot(trigindex(i:1+100),thresh,'gx');
        nextEvent = events(firstIndex+1);
    dispwindow = 10*(nextEvent-firstEvent);
    axis([firstEvent-(dispwindow/2) firstEvent+(dispwindow/2) thresh-0.1 thresh+0.1]);
    foo = input('Step forward (f) or back (b) or ok (enter)? ','s');
    plot(firstEvent,thresh+0.05,'yp');
    if strcmp(foo,'f')
        firstIndex = firstIndex + 1;
    elseif strcmp(foo,'b')
        firstIndex = firstIndex - 1;
    else
        plot(firstEvent,thresh+0.05,'bp');
        break
    end
    firstEvent = events(firstIndex);
end

% Initial flash events/times, which are optional (in samples)
% initevents = events(1:firstIndex-1);

% Drop everything before first event
events = events(firstIndex:end);

% Realign onsets to first event
onsets = events-events(1);

% Change onsets from samples to seconds
onsets = onsets ./ samplerate;


    
    
    
    
    
    