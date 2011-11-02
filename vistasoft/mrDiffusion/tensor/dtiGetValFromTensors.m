function [val1,val2,val3,val4,val5,val6] = dtiGetValFromTensors(dt6, coords, xform, valName, interpMethod)
% Interpolates dt6 tensor field and computes stats 
%
%  val = dtiGetValFromTensors(dt6, coords, [xform], [valName], [interpMethod])
%
% This  also works for a scalar image in place of the dt6. In that case,
% 'valName' is ignored. 
%
% Input parameters:
% xform: the transform that converts coords to dt6 indices. Default is
%        eye(4) (ie. no xform)
% coords: a Nx3 list of coords for which you want values (val will be of
%         length N)
% valName (default = 'fa'):
%         - 'fa' (fractional anisotropy)
%         - 'md' (mean diffusivity)
%         - 'eigvals' (triplet of values for 1st, 2nd and 3rd eigenvalues)
%         - 'shapes' (triplet of values indicating linearity, planarity and
%              spherisity)
%         - 'dt6' (the full tensor in [Dxx Dyy Dzz Dxy Dxz Dyz] format
%         - 'pdd' (principal diffusion direction)
%         - 'linearity',  'famdpdd', 'famdadrd', 'famdpdddt6'
% interpMethod: 'nearest', 'trilin' (default), 'spline'
%
% HISTORY:
% 2005.03.18 RFD (bob@white.stanford.edu) wrote it.
% 2006.08.07 RFD: we no longer set NaNs to 0. If there are missing
% data, the caller should know about it and deal with as they wish.
%
% (c) Stanford VISTA Team

if(~exist('xform','var') || isempty(xform))
    xform = eye(4);
end
if(~exist('valName','var') || isempty(valName))
    valName = 'fa';
end
if(~exist('interpMethod','var') || isempty(interpMethod))
    interpMethod = 'trilin';
end
if(size(coords,2)~=3), coords = coords'; end
if(size(coords,2)~=3), error('coords must be an Nx3 array!'); end

if(~all(all(xform==eye(4))))
    coords = mrAnatXformCoords(xform, coords);
end

switch lower(interpMethod)
    case 'nearest'
        interpParams = [0 0 0 0 0 0];  
    case 'trilin'
        interpParams = [1 1 1 0 0 0];
    case 'spline'
        interpParams = [7 7 7 0 0 0];
    otherwise
        error(['Unknown interpMethod "' interpMethod '".']);
end

val_dt6 = zeros(size(coords,1), size(dt6,4));
for(ii=1:size(dt6,4))
    bsplineCoefs = spm_bsplinc(dt6(:,:,:,ii), interpParams);
    val_dt6(:,ii) = spm_bsplins(bsplineCoefs, coords(:,1), coords(:,2), coords(:,3), interpParams);
end
clear dt6 coords;

val1 = []; val2 = []; val3 = []; val4 = []; val5 = []; val6 = [];
if(size(val_dt6,2)~=6)
    val1 = val_dt6(:,1);
    return;	
end

% mrvParamFormat('FA ma ad rd')
valName = mrvParamFormat(valName);

switch lower(valName)
    case 'dt6'
        val1 = val_dt6(:,1);
        val2 = val_dt6(:,2);
        val3 = val_dt6(:,3);
        val4 = val_dt6(:,4);
        val5 = val_dt6(:,5);
        val6 = val_dt6(:,6);       
    case 'eigvals'
        val_dt6 = reshape(val_dt6, [size(val_dt6,1) 1 1 6]);
        [eigVec, eigVal] = dtiSplitTensor(val_dt6);
        val1 = squeeze(eigVal(:,:,:,1));
        val2 = squeeze(eigVal(:,:,:,2));
        val3 = squeeze(eigVal(:,:,:,3));
    case 'fa'
        val_dt6 = reshape(val_dt6, [size(val_dt6,1) 1 1 6]);
        [eigVec, eigVal] = dtiSplitTensor(val_dt6);
        val1 = dtiComputeFA(eigVal);
        %val(isnan(val)) = 0;
    case 'md'
        % mean diffusivity: trace/3, where trace is the sum of the diagonal
        % elements (ie. the first three dt6 values)
        val1 = sum(val_dt6(:,1:3),2)./3;
    case {'shapes','linearity'}
        val_dt6 = reshape(val_dt6, [size(val_dt6,1) 1 1 6]);
        [eigVec, eigVal] = dtiSplitTensor(val_dt6);
        [val1, val2, val3] = dtiComputeWestinShapes(eigVal);
    case 'pdd'
        % principal diffusion direction
        val_dt6 = reshape(val_dt6, [size(val_dt6,1) 1 1 6]);
        [eigVec, eigVal] = dtiSplitTensor(val_dt6);
        val1 = squeeze(eigVec(:,:,:,[1 2 3],1)); % Should be [1 3 2]?
        %val(isnan(val)) = 0;
    case 'famdpdd'
        % FA, Mean diffusivity, PDD
        val_dt6 = reshape(val_dt6, [size(val_dt6,1) 1 1 6]);
        [eigVec, eigVal] = dtiSplitTensor(val_dt6);
        val1 = dtiComputeFA(eigVal);
        %val(isnan(val)) = 0;
        val2 = sum(val_dt6(:,1:3),2)./3;
        val3 = squeeze(eigVec(:,:,:,[1 2 3],1)); % Should be [1 3 2]?
        %val3(isnan(val3)) = 0;
    case 'famdadrd'
        % FA, mean diffusivity, axial diffusivity, radial diffusivity
        val_dt6 = reshape(val_dt6, [size(val_dt6,1) 1 1 6]);
        [eigVec, eigVal] = dtiSplitTensor(val_dt6);
        val1 = dtiComputeFA(eigVal);  % FA
        %val(isnan(val)) = 0;
        val2 = sum(val_dt6(:,1:3),2)./3;  % Mean diffusivity
        val3 = squeeze(eigVal(:,:,:,1));  % Axial diffusivity
        val4 = squeeze(eigVal(:,:,:,2)+eigVal(:,:,:,3))./2; % Radial
    case 'famdpdddt6'
        val_dt6 = reshape(val_dt6, [size(val_dt6,1) 1 1 6]);
        [eigVec, eigVal] = dtiSplitTensor(val_dt6);
        val1 = dtiComputeFA(eigVal);
        %val(isnan(val)) = 0;
        val2 = sum(val_dt6(:,1:3),2)./3;
        val3 = squeeze(eigVec(:,:,:,[1 2 3],1)); % Should be [1 3 2]?
        %val3(isnan(val3)) = 0;
        val4 = val_dt6;
      case 'famdadrdshape'
        val_dt6 = reshape(val_dt6, [size(val_dt6,1) 1 1 6]);
        [eigVec, eigVal] = dtiSplitTensor(val_dt6);
        val1 = dtiComputeFA(eigVal);
        %val(isnan(val)) = 0;
        val2 = sum(val_dt6(:,1:3),2)./3;
        val3 = squeeze(eigVal(:,:,:,1));
        val4 = squeeze(eigVal(:,:,:,2)+eigVal(:,:,:,3))./2;   
        
        
        [val5, val6, val7] = dtiComputeWestinShapes(eigVal);
        
        
    otherwise
        error(['Unknown tensor value "' valName '".']);
end
return;
