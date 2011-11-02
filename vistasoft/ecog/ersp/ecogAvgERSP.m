function ecogAvgERSP(par,elecs,blocklist,condition,bef_win,aft_win)
% ecogAvgERSP(par,elecs,blocklist,condition,bef_win,aft_win)
%
% Calculates weighted average of ERSPs and saves in Results/Average
% modified from ecogAvgERP (j.chen) by jbh May '10
%




windur = bef_win+aft_win;
windurstr = strrep(num2str(windur),'.','p');

for b = 1:length(blocklist)
    block = blocklist{b};
%     fn= sprintf(['%s' filesep '..' filesep block],par.Results); %hacky
fn = fullfile(fileparts(par.Results),block); % fixed jc 07/11/10
    load(sprintf('%s/ERSP_%s_%s_%s_%s.mat',fn,par.exptname,condition,windurstr,block));

    for ei = elecs
        tERSP(ei).meanPower{b} = ERSP.elecs(ei).meanPower;
        tERSP(ei).value{b} = ERSP.elecs(ei).value;
        tERSP(ei).n(b) = ERSP.ntrials;
        
    end
%     tERSP(1).general.(block) = ERSP.general;
end

clear ERSP;
for ei = elecs
    for b = 1:length(blocklist)
        ERSP.elecs(ei).value(b,:,:) = tERSP(ei).value{b} * tERSP(ei).n(b);
        ERSP.elecs(ei).meanPower(b,:) = tERSP(ei).meanPower{b}' * tERSP(ei).n(b);
    end
    ERSP.elecs(ei).value = squeeze(nansum(ERSP.elecs(ei).value,1)/sum(tERSP(ei).n)); %weighted avg
    ERSP.elecs(ei).meanPower = nansum(ERSP.elecs(ei).meanPower)/sum(tERSP(ei).n);%weighted avg
    ERSP.elecs(ei).n = sum(tERSP(ei).n);
    
end
ERSP.blocks = blocklist;
% ERSP.general = tERSP(1).general;

cd(par.Results)
cd ..
bprefix = blocklist{1}(1:3);
if ~exist([bprefix 'avg'],'dir')
    mkdir([bprefix 'avg']);
end
cd([bprefix 'avg'])
fn = sprintf('ERSP_%s_%s_%s_%s.mat',par.exptname,condition,windurstr,[bprefix 'avg']);
fprintf('Saving:  %s\n',fn)
save(fn,'ERSP');

