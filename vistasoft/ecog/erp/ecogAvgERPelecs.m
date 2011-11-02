%
% ecogAvgERP
% Calculates average of ERPs over a group of elecs
% j.chen March 2010
%
function ecogAvgERPelecs(par,elecgroup,elecgroupname,condition,bef_win,aft_win,bprefix)

windur = bef_win+aft_win;
windurstr = strrep(num2str(windur),'.','p');

cd(par.Results)
cd ..
cd([bprefix 'avg'])
load(sprintf('ERP_%s_%s_%s_%s.mat',par.exptname,condition,windurstr,[bprefix 'avg']),'ERP');
cd ..
if ~exist([bprefix 'avg' elecgroupname],'dir')
    mkdir([bprefix 'avg' elecgroupname]);
end
cd([bprefix 'avg' elecgroupname]);

for i = 1:length(elecgroup)
    tERP.mean(i,:) = ERP.elecs(elecgroup(i)).mean;
    tERP.std(i,:) = ERP.elecs(elecgroup(i)).std;
    tERP.n(i) = ERP.elecs(elecgroup(i)).n;
end

clear ERP;
ERP.elecs(1).mean = mean(tERP.mean,1);
ERP.elecs(1).std = mean(tERP.std,1);
ERP.elecs(1).n = sum(tERP.n);
ERP.elecgroup = elecgroup;

save(sprintf('ERP_%s_%s_%s_%s.mat',par.exptname,condition,windurstr,[bprefix 'avg' elecgroupname]),'ERP');

