baseDir = '/biac2/wandell2/data/reading_longitude/dti';
outDir = '/teal/scr1/dti/MTProject';
[f,s] = findSubjects(fullfile(baseDir,'*0*'),'*_dt6_noMask',{});
%s = dir(fullfile(baseDir,'*0*'));
%s = s([s.isdir]); s = {s(:).name};
numPaths = 20000;
% Tried 2M, but it didn't help with the occasional convergence problem.
% 400K is also likely to be overkill- maybe 200K is enough?
burnIn = 400000;
skipSamps = 20;
showFigs = false;
roiNameList = {'LMT', 'RMT'};
logFile = fullfile(outDir,'MTproject_metrotrac_log.txt');
nRuns = 4;
for(runNum=1:nRuns)
    fid = fopen(fullfile(outDir,sprintf('run_%02d.sh',runNum)),'wt');
    fprintf(fid,'#!/bin/bash\necho "* * *" >> %s\necho "Begin run %d: `date`" >> %s\n',logFile,runNum,logFile);
    fclose(fid);
end
totalNumRuns = 0;
for(ii=1:length(f))
    mtDir = fullfile(fileparts(f{ii}),'ROIs','MTproject');
    if(~exist(mtDir,'dir'))
        disp([s{ii} ': No MTproject dir for this subject- skipping.']);
    else
        dt = load(f{ii},'xformToAcPc');
        ccRoiFile = fullfile(fileparts(f{ii}),'ROIs','CC_FA.mat');
        if(~exist(ccRoiFile,'file')), disp([s{ii} ': No CC_FA file']); continue; end
        roi = dtiReadRoi(ccRoiFile);
        % Do some processing to extract the splenium
        [skelXYZ, skelPerimDist, skelLinearDist, roiIm] = dtiCallosalSkeleton(roi.coords);
        % Splenium is assumed to be everything up to the thinnest point in
        % the posterior fifth of the CC. For now, we'll just take the
        % posterior fifth.
        posteriorSeg = skelLinearDist<=skelLinearDist(end)./5;
        %minPts = find(skelPerimDist(posteriorSeg)==min(skelPerimDist(posteriorSeg)) | skelPerimDist(posteriorSeg)<=2);
        minPts = max(find(posteriorSeg));
        cutPt = skelXYZ(minPts(1),:);
        if(showFigs)
            figure; set(gcf, 'name', s{ii});
            subplot(2,1,1); imagesc(roiIm.img'); axis image xy; 
            hold on; plot(cutPt(2)-roiIm.offset(1),cutPt(3)-roiIm.offset(2),'rx'); hold off;
            subplot(2,1,2); plot(skelLinearDist,skelPerimDist);
            xlabel('distance from posterior point (mm)'); ylabel('distance to perimeter (mm)');
        end
        roi.coords = roi.coords(roi.coords(:,2)<cutPt(2),:);
        [cc.center,cc.length] = mtrConvertRoiToBox(roi.coords,dt.xformToAcPc);
        for(jj=1:2)
            totalNumRuns = totalNumRuns+1;
            roiName = roiNameList{jj};
            mtParamsDir = fullfile(outDir,'params');
            subBinDir = fullfile(fileparts(f{ii}),'bin');
            mtParamsFile = fullfile(mtParamsDir,[s{ii} '_' roiName '.txt']);
            roi = dtiReadRoi(fullfile(mtDir,roiName));
            [mt.center,mt.length] = mtrConvertRoiToBox(roi.coords,dt.xformToAcPc);
            % Build the mtrParams file
            fid = fopen(mtParamsFile,'wt');
            fprintf(fid,'Tensor Filename: %s\n',fullfile(subBinDir,'tensors.nii.gz'));
            fprintf(fid,'FA Filename: %s\n',fullfile(subBinDir,'backgrounds','fa.nii.gz'));
            fprintf(fid,'Compute FA: false\n');
            fprintf(fid,'Sampler Type (SISR, MCMC): MCMC\n');
            fprintf(fid,'Desired Samples: %d\n', numPaths);
            fprintf(fid,'Burn-In: %d\n', burnIn);
            fprintf(fid,'Max Pathway Nodes: 90\n');
            fprintf(fid,'Min Pathway Nodes: 10\n');
            fprintf(fid,'Step Size (mm): 2\n');
            fprintf(fid,'Skip Samples: %d\n',skipSamps);
            fprintf(fid,'Start VOI Pos (ijk): %0.1f, %0.1f, %0.1f\n',mt.center);
            fprintf(fid,'Start VOI Size (ijk): %0.1f, %0.1f, %0.1f\n',mt.length);
            fprintf(fid,'Start Valid Cortex VOI: true\n');
            fprintf(fid,'End VOI Pos (ijk): %0.1f, %0.1f, %0.1f\n',cc.center);
            fprintf(fid,'End VOI Size (ijk): %0.1f, %0.1f, %0.1f\n', cc.length);
            fprintf(fid,'End Valid Cortex VOI: false\n');
            fprintf(fid,'translateMut: 2\n');
            fprintf(fid,'ISRMut: 0\n');
            fprintf(fid,'ESRMut: 7\n');
            fprintf(fid,'Temp Swap Prob: 1.000000e-001\n');
            fprintf(fid,'Inv Temp Vec: [ 1 ]\n');
            fprintf(fid,'Start Path Tries: 40\n');
            fprintf(fid,'Save Out Spacing: 100\n');
            fprintf(fid,'FA Absorption Threshold for WM/GM specification: 1.500000e-001\n');
            fprintf(fid,'Absorption Rate Normal: 9.000000e-001\n');
            fprintf(fid,'Absorption Rate Penalty for GM: 1.380000e-087\n');
            fprintf(fid,'Local Path Segment Smoothness Standard Deviation: 6.280000e-001\n');
            fclose(fid);

            % add this subject to the master metrotrack script list
            executable = which('dtiprecompute_met.glxa64');
            for(runNum=1:nRuns)
                fgFile = fullfile(outDir,'paths',sprintf('%s_%s_%02d.dat',s{ii},roiName,runNum));
                args = sprintf(' -i %s -p %s >> %s', mtParamsFile, fgFile, logFile);
                cmd = [executable args];
                fid = fopen(fullfile(outDir,sprintf('run_%02d.sh',runNum)),'at');
                fprintf(fid,'%s\n',cmd);
                fclose(fid);
            end
        end
    end
end
for(runNum=1:nRuns)
    fid = fopen(fullfile(outDir,sprintf('run_%02d.sh',runNum)),'at');
    fprintf(fid,'echo "* * *" >> %s\necho "End run %d (%d datasets): `date`" >> %s\n',logFile,runNum,totalNumRuns,logFile);
    fclose(fid);
end
