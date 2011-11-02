
function [truestamps conds bad_stamps bad_conds] = ...
    ecogCleanStamps(par,truestamps,conds,otl_bef_win,otl_aft_win)
% Finds event windows in truestamps that overlap with outlier periods identified
% by ecogArtReplace, and removes them. For each truestamp, a window is
% defined as [truestamps(n)-otl_bef_win truestamps(n)+otl_bef_win].
% jc 04/05/11

for ei = par.rejelecs
    fname = sprintf('%s/aiEEG%s_%.2d.mat',par.ArtData,par.block,ei);
    art = load(fname);
    outliers = art.outliers;
    bad_stamps_i = [];
    outlier_secs = find(outliers)/par.ieegrate;
    outlier_secs = unique(round(outlier_secs*100)/100);
    for t = 1:length(truestamps)
        mintime = truestamps(t) - otl_bef_win;
        maxtime = truestamps(t) + otl_aft_win;
        ovr = intersect(find(outlier_secs > mintime),find(outlier_secs < maxtime));
        if ~isempty(ovr)
            bad_stamps_i = [bad_stamps_i t];
        end
    end
    bad_stamps_list{ei} = bad_stamps_i;
end
bad_index = unique(cat(2,bad_stamps_list{par.rejelecs}));
good_index = setdiff([1:length(truestamps)],bad_index);
orig_truestamps = truestamps;
orig_conds = conds;
truestamps = truestamps(good_index);
conds = conds(good_index);
bad_stamps = orig_truestamps(bad_index);
bad_count = length(bad_index);
bad_conds = orig_conds(bad_index);
fprintf(['Outlier rejection: ' num2str(bad_count) ' of ' num2str(length(orig_conds)) ' events rejected.\n']);

if 0
    % plot wave, outliers, and events. note that this uses the selected channel
    % in par.rejelecs. the outlier points may be different from other channels
    % in rejelecs, but all rejelecs channels contribute to bad_index.
    ei = par.rejelecs(1);
    art = load(fullfile(par.ArtData,['aiEEG' par.block '_' num2str(ei) '.mat']));
    outlier_secs = find(art.outliers)/par.ieegrate;
    outlier_secs = unique(round(outlier_secs*100)/100);
    clf
    plot(art.wave); hold on
    % all outlier points:
    plot(find(art.outliers),art.wave(find(art.outliers)),'r.')
    % outlier points used for event rejection (rounded to nearest 0.1):
    otl_eventpts = outlier_secs*par.ieegrate;
    plot(otl_eventpts,art.wave(round(otl_eventpts)),'co');
    % events retained after outliers dropped:
    good_eventpts = orig_truestamps(good_index)*par.ieegrate;
    plot(good_eventpts,zeros(length(good_eventpts),1),'gx');
    % events dropped due to outlier status:
    bad_eventpts = orig_truestamps(bad_index)*par.ieegrate;
    plot(bad_eventpts,zeros(length(bad_eventpts),1),'rx');
    title(['Channel ' num2str(ei)]);
end

