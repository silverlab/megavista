
function textfile = getSSevents(thePath,filename)

% Retrieves condition and onset information from the mat file for the stop
% signal task. Prints out a tab-delimited text file with columns: onset and
% condition. Onset is in seconds, in computer time (not zeroed to first
% event).
% JC & AR 09/16/08

cd(thePath.matfiles);
load(filename);

% cond 1 = stop2
% cond 2 = go1

sstamps = cat(1,flinf(:).stop2);
sstamps = sstamps(:,1);
gstamps = cat(1,flinf(:).go1);
gstamps = gstamps(:,1);
stamps = sstamps + gstamps;

cond = zeros(1,length(sstamps));
i = find(sstamps);
cond(i) = 1;
i = find(gstamps);
cond(i) = 2;

% remove all cells with no timestamp
i = find(stamps);
stamps = stamps(i);
cond = cond(i);

textfile = [filename '.txt'];
fid = fopen(textfile,'wt');
fprintf(fid,'%4f \t %d \n',[stamps';cond]);
fclose(fid);
