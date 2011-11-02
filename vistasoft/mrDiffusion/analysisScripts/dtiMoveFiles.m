f = findSubjects;
newDir = '/snarp/u1/data/reading_longitude/dti/groupAnalysis';
for(ii=1:length(f))
    [junk,bn] = fileparts(f{ii});
    us = strfind(bn,'_'); bn = bn(1:us(1)-1);
    disp(['Processing ' num2str(ii) ': ' bn '...']);
    roiPath = fullfile(fileparts(f{ii}), 'ROIs');
    fiberPath = fullfile(fileparts(f{ii}), 'fibers');
    d = dir(fullfile(fiberPath,'*_MNI.mat'));
    for(jj=1:length(d))
        cmd = ['!mv ' fullfile(fiberPath, d(jj).name) ' ' fullfile(newDir, [bn '_' d(jj).name])];
        disp(cmd);
        eval(cmd);
    end
end