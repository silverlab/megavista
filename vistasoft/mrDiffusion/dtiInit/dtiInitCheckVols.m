function [doResamp bvecs bvals dwRaw] = dtiInitCheckVols(bvecs,bvals,dwRaw,dwParams)
%  
%   [doResamp bvecs bvals dwRaw] = dtiInitCheckVols(bvecs,bvals,dwRaw)
%  
%  Check for missing data volumes and remove exclude volumes if requested.
%   *** TODO: allow arbitrary volumes to be skipped downstream to avoid
%             needing to touch the raw data here.
% 
% INPUTS
%       (bvecs,bvals,dwRaw,dwParams) - passed in from dtiInit
% RETURNS
%       [doResamp bvecs bvals dwRaw] - without bad / removed volumes
%
% Web Resources
%       mrvBrowseSVN('dtiInitCheckVols');
%
%
% (C) Stanford VISTA, 2011

%% Check for missing data volumes 

% Assume that we're not resampling the data
doResamp = false;

goodVols = squeeze(max(max(max(dwRaw.data))))~=0;

% Negative bvals are used to indicate bad volumes that should be skipped
if any(bvals < 0)
    goodVols = goodVols & bvals > 0;
    fprintf('Found bad volumes that will be removed from the data...\n');
end

% If the user passed in dwParams.excludeVols we will remove them
if ~isempty(dwParams.excludeVols)
    goodVols(dwParams.excludeVols) = false;
    fprintf('Will remove Volumes [%d %d] from the data...\n',...
             min(dwParams.excludeVols),max(dwParams.excludeVols));
end

% Remove bad volumes from dw.raw and signal to resample
if ~all(goodVols)
    fprintf('Removing %d volumes from analysis...\n',sum(~goodVols));
    dwRaw.data = dwRaw.data(:,:,:,goodVols);
    bvecs      = bvecs(:,goodVols);
    bvals      = bvals(goodVols);
    doResamp   = true;
else
    % Check that the number of volumes is equal to the number of BVs - if
    % not then ignore some of the BVs. 
    if length(goodVols) < size(bvecs,2) 
        warning('mrDiffusion:dimMismatch', 'More bvecs than vols- ignoring some bvecs...');
        bvecs = bvecs(:,goodVols);
    end
    if length(goodVols) < size(bvals,2) 
        warning('mrDiffusion:dimMismatch', 'More bvals than vols- ignoring some bvals...');
        bvals = bvals(goodVols);
    end
end

return
