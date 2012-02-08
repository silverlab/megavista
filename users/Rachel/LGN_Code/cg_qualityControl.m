function quality_control(sub)
%quality control script

%directory structure
dataDir = '/home/despo/cgratton/data/FaceSpace_loc/';
subDir = [dataDir 'Data/' sub '/'];
tsDir = '/home/despo/cgratton/gitrepos/podNtools/';
addpath(tsDir);
scriptDir = '/home/despo/cgratton/gitrepos/studies/Study_FaceMapping/';

%types
types = {'faceattend_highRES', 'facescene_loc_highSNR','facespace_loc_highRES'};
%types = {'faceattend_highSNR', 'facescene_loc_highSNR','facespace_loc_highSNR'};

for i=1:length(types)
    
    disp(types{i});
    
    cd([subDir types{i} '/Analysis/'])
    if strcmp(types{i},'facescene_loc_highSNR')
        
        %tsdiffana([sub '-EPI-001.nii'; sub '-EPI-002.nii'],[],100)
        tsdiffana([sub '-EPI-001.nii'],[],100)

    else
        
        tsdiffana([sub '-EPI-001.nii';
            sub '-EPI-002.nii';
            sub '-EPI-003.nii';
            sub '-EPI-004.nii';
            sub '-EPI-005.nii';
            sub '-EPI-006.nii'],[],100)
            %sub '-EPI-007.nii'],[],100)
        
    end
    
    %save the output figure
    saveas(100,'tsdiffana_output.pdf')
    close(100)
    
    %make a directory to save tsdiffana output to
    if ~exist('tsdiffana','dir')
        mkdir('tsdiffana')
    end
    outDir = [subDir types{i} '/Analysis/tsdiffana/'];
    movefile('timediff.mat',outDir)
    movefile('v*nii',outDir)
    movefile('tsdiffana_output.pdf',outDir)
    
end

cd(scriptDir)