%% Read gdat files
function dat = readgdat(blockpath,chanlist,samplerate);
%
% dat = readgdat(truestamps,firstEvent,conds,blockpath,chanlist,...
%     samplerate,savename,savepath)
% Produces:
%  dat - a channels x samples matrix concatenating all channels from gdat_#.mat
%  estruct - condition info for use with EEGlab struct
%
% Originally part of chanstruct.m
%
% jc 09/22/09
%

cd(blockpath);
dat = [];
for n = 1:length(chanlist)
    chan = chanlist(n);
    gname = ['gdat_' num2str(chan) '.mat'];
    try
        fprintf(['Reading ' gname '\n']);
        load(gname);
        eval(['dat = [dat; ' gname(1:end-4) '];']);
        eval(['clear ' gname(1:end-4)]);
    catch
        fprintf(['Could not read ' gname '\n']);
        dat = [dat; zeros(1,size(dat,2))];
    end
end

end