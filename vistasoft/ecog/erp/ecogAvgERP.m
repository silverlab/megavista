%
% ecogAvgERP
% Calculates weighted average of ERPs and saves in Results/Average
% j.chen March 2010
%
function ecogAvgERP(par,elecs,blocklist,condition,bef_win,aft_win)

windur = bef_win+aft_win;
windurstr = strrep(num2str(windur),'.','p');

for b = 1:length(blocklist)
    block = blocklist{b};
    fn= sprintf(['%s' filesep '..' filesep block],par.Results); %hacky
    load(sprintf('%s/ERP_%s_%s_%s_%s.mat',fn,par.exptname,condition,windurstr,block));

    for ei = elecs
        tERP(ei).mean(b,:) = ERP.elecs(ei).mean;
        tERP(ei).std(b,:) = ERP.elecs(ei).std;
        tERP(ei).n(b) = ERP.elecs(ei).n;
    end
end

clear ERP;
for ei = elecs
    for b = 1:length(blocklist)
        ERP.elecs(ei).mean(b,:) = tERP(ei).mean(b,:) * tERP(ei).n(b);
        ERP.elecs(ei).std(b,:) = tERP(ei).std(b,:) * tERP(ei).n(b);
    end
    ERP.elecs(ei).mean = nansum(ERP.elecs(ei).mean)/sum(tERP(ei).n);
    ERP.elecs(ei).std = nansum(ERP.elecs(ei).std)/sum(tERP(ei).n);
    ERP.elecs(ei).n = sum(tERP(ei).n);
end
ERP.blocks = blocklist;

cd(par.Results)
cd ..
bprefix = [blocklist{1}(1:3)];
if ~exist([bprefix 'avg'],'dir')
    mkdir([bprefix 'avg']);
end
cd([bprefix 'avg'])
fn = sprintf('ERP_%s_%s_%s_%s.mat',par.exptname,condition,windurstr,[bprefix 'avg']);
fprintf('Saving:  %s\n',fn)
save(fn,'ERP');

