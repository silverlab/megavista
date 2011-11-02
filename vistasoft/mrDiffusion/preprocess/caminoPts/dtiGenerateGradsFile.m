function dtiGenerateGradsFile(nDirs, outFileName)
%
%
%
% HISTORY:
% 2007.08.10 RFD: wrote it.

caminoPtsDir = fileparts(which(mfilename));
% 11.3 comes from Jones et. al. MRM 1999.
numNonDwPerDw = 11.3;

ptsFile = fullfile(caminoPtsDir,sprintf('Elec%03d.txt',nDirs));

if(~exist(ptsFile,'file'))
    error('No points file for %d directions.',nDirs);
end

pts = dlmread(ptsFile);
if(pts(1)~=nDirs)
    error('pts file %s is invalid.',ptsFile);
end
pts = reshape(pts(2:end),3,nDirs);
pts = [pts -pts]';

% 11.3 comes from Jones et. al. MRM 1999.
nNonDw = round(max(1,2*nDirs/numNonDwPerDw));

totalNumMeasurements = nDirs*2+nNonDw;

dirs = zeros(totalNumMeasurements,3);
s = totalNumMeasurements/nNonDw;
nonDwInds = round([0:nNonDw-1]*s+1);
dwInds = ~ismember([1:totalNumMeasurements],nonDwInds);
dirs(dwInds,:) = pts;

%plot3(dirs(:,1),dirs(:,2),dirs(:,3),'k.'); axis square; 

if(~exist('outFileName','var')||isempty(outFileName))
    outFileName = sprintf('dwepi.%d.grads',totalNumMeasurements);
    if(isunix)
        outFileName = fullfile('/usr','local','dti','diffusion_grads',outFileName);
    end
    [f,p] = uiputfile({'*.grads';'*.*'},'Save grads file as...',outFileName);
    if(isequal(f,0) || isequal(p,0)), disp('User cancelled.'); return; end
    outFileName = fullfile(p,f);
end

dlmwrite(outFileName,dirs,'delimiter',' ','newline','unix','precision',6);

return;