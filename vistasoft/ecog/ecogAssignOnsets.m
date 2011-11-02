
function [truestamps conds] = assignOnsets(tfile,onsets,samplerate)
% 
% Compares onsets derived from analog channel ('onsets') to the onsets
% derived from the matlab expt output file ('monsets'). Retained timestamps
% are output as 'truestamps'. Requirement for truestamps is that each event 
% exists in both matfile and analog channel. truestamps is the same length 
% as monsets, but with -1 in any cell for which there was no corresponding 
% analog onset (within maxdist).
% Each event is plotted (different color for each condition) on top of the
% analog onsets (green) so you can see whether the event alignment was
% performed correctly. Dots represent events identified in the analog
% channel, while X represent events recorded in the matfile.
% Excluded events are in magenta -- dot indicates an analog event with no
% accompanying monset, X indicates a monset with no analog event.
% 
% Input params: event file and onsets from analog channel
% Output params: event conditions and corresponding timestamps from analog
% channel (in seconds)
%

if ~exist('samplerate','var')
    samplerate = 3051.76;
end

fid = fopen(tfile);
t = textscan(fid,'%f%d');
fclose(fid);
monsets = t{1}; % matlab onsets
monsets = monsets - monsets(1); % make first onset zero
conds = t{2};

labels = unique(conds); % find all cond types
i = find(labels); % use only labels>0
labels = labels(i);

[truestamps monseterror maxdist] = matchMonsets(onsets,monsets);
% Trials not recorded on analog channel are filled in as -1 in truestamps and monseterror

for n = 1:length(labels)
    i = find(conds==labels(n));
    monsetsxcond{n} = monsets(i);
    truestampsxcond{n} = truestamps(i);
end
        
figure(2); clf;
colors = 'rbkcyrbkcybbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
plot(onsets,1,'g.')
fprintf(['\ng: onsets (all timestamps from analog channel)\n']);
hold on

for n = 1:length(labels)
    plot(truestampsxcond{n},1+n*.01,[colors(n) '.']);
    fprintf([colors(n) ' dot: cond ' num2str(labels(n)) ' timestamps from analog channel\n']);
    plot(monsetsxcond{n},1+n*.01-0.0025,[colors(n) 'x']);
    fprintf([colors(n) ' x: cond ' num2str(labels(n)) ' timestamps from matlab\n']);
end

% Find and plot any onsets (analog timestamps) that did not have an
% accompanying monset event
% These are timestamps (flashes) from the analog channel that we threw out,
% because they are probably artifacts due to sensor motion
orejects=setxor(truestamps,onsets);
if ~isempty(orejects)
if orejects(1) == -1
    % 1st element of orejects will be -1 if truestamps contains some -1
    % values, which would happen if some matlab events are rejected fue to
    % there being no near enough analog event.
    orejects = orejects(2:end);
end
end
if ~isempty(orejects)
    plot(orejects,0.9975,'m.');
end
fprintf(['\nmagenta dot: timestamps rejected from analog channel\n']);
fprintf([num2str(length(orejects)) ' of ' num2str(length(onsets)) ' analog events rejected\n']);

% Find and plot any monsets that did not have an accompanying analog timestamp
% These are matlab-recorded events that we threw out probably because there
% was no sensor attached during presentation, so we don't have an analog
% timestamp
i = find(truestamps == -1);
mrejects = monsets(i);
if ~isempty(mrejects)
    plot(mrejects,0.9975,'mx');
end
fprintf(['magenta x: timestamps rejected from matlab events\n']);
fprintf([num2str(length(mrejects)) ' of ' num2str(length(monsets)) ' matlab events rejected\n']);

% legend('Analog','Stop','Go');
v=axis;
axis([-0.1 v(2) 0.97 1.05]);

% dif = getdif(flinit,initevents);

% keyboard

% function [flashstamps flasheventindices flashdist] =...
%     foo(datastamps,events,firstFlash,flinitTime)

function [truestamps monseterror maxdist] = matchMonsets(onsets,monsets)

% onsets: Onset of each event in analog channel (in seconds) where 1st
%         event is t=0. These are the timestamps we will carry forward in
%         the analysis.
% monsets: Onset of each event from the stim presentation file (in seconds).
%          These timestamps were set by the stim computer in matlab or eprime
% Onsets and monsets need to be mapped to each other. Some onsets may be
% missing (lost flashes in analog channel).
%
% For each monset, check analog onsets to find the nearest corresponding
% event (dist). Then check whether dist<maxdist. monsets that are too far
% off their nearest analog onset events are rejected.
%
% The returned onsets vector is the same length as monsets, but with -1 in
% any cell for which there was no corresponding monset (within maxdist).

n=1;
% maxdist = mean(onsets(2:end)-onsets(1:end-1))/10;
% maxdist is hardcoded for now, this may change based on the magnitude of
% monseterror we observe in the future. So far the largest error we've seen
% is ~0.020 seconds.
maxdist = 0.50;  %0.050;  %in seconds

for f = 1:length(monsets)
    dist = 100000000000;
    while 1
        if n<=length(onsets)
            newdist = monsets(f)-onsets(n);
        else
            break
        end

        if abs(newdist) < dist
            dist = abs(newdist);
            truestamps(f) = onsets(n); 
            monseterror(f) = newdist;
        else
            break
        end
        n = n + 1;
    end
    if dist > maxdist
        truestamps(f) = -1;
        monseterror(f) = -1;
        n = n - 2;
    end
end
truestamps = truestamps';




