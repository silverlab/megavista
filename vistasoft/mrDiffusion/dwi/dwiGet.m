function val = dwiGet(dwi, param, varargin)
% Get data from the dwi structure
%
%   val = dwiGet(dwi, param, varargin)
%
% Retrieve data from a dwi structure (see dwiCreate).
%
% Parameters
%   General
%    {'name'}
%    {'type'}
%
%   Data values
%    {'diffusion data acpc'}
%    {'diffusion data image'}
%    {'b0 acpc' }
%    {'n images'}
%    {'n diffusion images'}
%    {'n nondiffusion images'}
%    {'b0 image nums'}
%
%   Measurement parameters
%    {'bvals'}
%    {'bvecs'}
%    {'n diffusion bvecs'}
%    {'n diffusion bvals'}
%
% Examples:
%   To get diffusion data from a fiber
%
% dwi = ...
%   dwiCreate('raw/DTI__aligned_trilin.nii.gz','raw/DTI__aligned_trilin.bvecs','raw/DTI_aligned_trilin.bvals');
%
% fg = dtiReadFibers('fibers/arcuate.mat');
% coords = fg.fibers{1};
% val = dwiGet(dwi,coords,'diffusion data acpc');
%
% See also:  dwiCreate, dwiSet, dtiGet, dtiSet, dtiCreate
%
% (c) Stanford VISTA Team

% TODO:
%   Keep adjusting the diffusion data gets
%
if notDefined('dwi'), error('dwi structure required'); end
if notDefined('param'), help('dwiGet'); end

val = [];

switch(mrvParamFormat(param))

    case {'name'}
        val = dwi.name;
    case {'type'}
        val = dwi.type;
    % bval and bvec properties
    case {'size','dim'}
        val = dwi.nifti.dim;
    case {'nimages'}
        % Number of diffusion and b=0 images
        % dwiGet(dwi,'n images')
        val = dwi.nifti.dim(4);
    case {'ndiffusionimages','numdiffusionimages'}
        % Number of images with diffusion gradient on (b > 0)
        % dwiGet(dwi,'n diffusion images')
        n = dwiGet(dwi,'nimages');
        m = dwiGet(dwi,'n nondiffusion images');
        val = n - m;
    case {'nnondiffusionimages','numnondiffusionimages'}
        % Number of non-diffusion images (b=0)
        val = sum(dwi.bvals == 0);
    case {'bvecs'}
        if isfield(dwi,'bvecs'), val = dwi.bvecs; end
    case {'bvals'}
        if isfield(dwi,'bvals'), val = dwi.bvals(:); end
    case {'b0imagenums'}
        val = find(dwi.bvals == 0);
    case {'diffusionimagenums','dimagenums'}
        val = find(dwi.bvals ~= 0);
    case {'diffusionbvecs'}
        % bvecs in the diffusion gradient on case (the others don't matter)
        % dbvecs = dwiGet(dwi,'diffusion bvecs');
        bvals = dwiGet(dwi,'bvals');
        b0 = (bvals == 0);
        val = dwi.bvecs(~b0,:);
    case {'diffusionbvals'}
        % bvals when the diffusion gradient is on
        % dbvals = dwiGet(dwi,'diffusion bvals');
        dBvals = (dwi.bvals ~= 0);
        val = dwi.bvals(dBvals,:);
    case {'ndiffusionbvals'}
        val = size(dwiGet(dwi,'diffusion bvals'),1);
    case {'ndiffusionbvecs'}
        val = size(dwiGet(dwi,'diffusion bvecs'),1);
    case{'diffusionsignalimage','dimage','dwimage','diffusiondataimage'}
        % Diffusion-weighted data from image coords
        % The coordinates need to be rounded to integers
        % dSig = dwiGet(dwi,'diffusion data image',coords)
        if ~isempty(varargin), coords = varargin{1};
        else error('coords required');
        end
        coords = coordCheck(coords);
        coords = round(coords);

        % val will be a 3D matrix with dimensions (N coords,N vols) where
        % N coords is the number of coordinates passed in and N vols is the
        % number of volumes in the nifti image
        indx = sub2ind(dwi.nifti.dim(1:3),coords(:,1),coords(:,2),coords(:,3));
        dimg = dwiGet(dwi,'dimagenums');
        val = zeros(length(indx),length(dimg));
        for ii = 1:length(dimg)
            tmp = squeeze(dwi.nifti.data(:,:,:,dimg(ii)));
            val(:,ii) = tmp(indx);
        end

        % get dwi data from a set of coordinates in ac-pc apce
    case{'diffusionsignalacpc','dacpc','dwacpc','diffusiondataacpc'}
        %Returns the diffusion data, excluding b=0, at a set of
        %coordinates
        % dSig = dwiGet(dwi,'diffusion signal acpc',coords);

        % transform ac-pc coordinates which have units of millimeters from
        % the anterior commisure to image indices.  By iimage indices we
        % mean integer locations within the dwi volume that correspond to
        % the ac-pc coordinates. At some point we may want to interpolate
        % these as oppose to rounding them to integers but for the time
        % being it seems to make more sense to grab data from a full voxel
        if ~isempty(varargin), coords = varargin{1};
        else error('coords required');
        end
        coords = coordCheck(coords);
        
        % Convert coordinates to image space
        coords = round(mrAnatXformCoords(dwi.nifti.qto_ijk,coords));
        val = dwiGet(dwi,'diffusion data image',coords);
        
        % val will be a 3D matrix with dimensions (N coords,N vols) where
        % N coords is the number of coordinates passed in and N vols is the
        % number of volumes in the nifti image
        %         indx=sub2ind(dwi.nifti.dim(1:3),coords(:,1),coords(:,2),coords(:,3));
        %         dimg = dwiGet(dwi,'dimagenums');
        %         val = zeros(length(indx),length(dimg));
        %         ii = 1;
        %         for dd = dimg
        %             tmp = squeeze(dwi.nifti.data(:,:,:,dd));
        %             val(:,ii) = tmp(indx);
        %             ii = ii + 1;
        %         end


    case{'b0acpc','s0acpc'}
        % get B0 data from a set of coordinates in ac-pc space
        % Please fix to be consistent with the next b0 code that BW added.
        if ~isempty(varargin), coords = varargin{1};
        else error('coords required');
        end
        coords = coordCheck(coords);

        % transform ac-pc coordinates which have units of millimeters from
        % the anterior commisure to image indices.  By iimage indices we
        % mean integer locations within the dwi volume that correspond to
        % the ac-pc coordinates. At some point we may want to interpolate
        % these as oppose to rounding them to integers but for the time
        % being it seems to make more sense to grab data from a full voxel
        coords = round(mrAnatXformCoords(dwi.nifti.qto_ijk,coords));


        % val will be a 1xN vector where N is the number of coordinates
        % passed in.  The measurements across b0 volumes are averaged
        indx=sub2ind(dwi.nifti.dim(1:3),coords(:,1),coords(:,2),coords(:,3));
        b0 = find(dwi.bvals==0);

        for ii = 1:length(b0)
            tmp=squeeze(dwi.nifti.data(:,:,:,b0(ii)));
            val(:,ii) = tmp(indx);
        end
        val = nanmean(val,1);

    case{'b0image','s0image'}
        % S0 = dwiGet(dwi,'b0 image',coords);
        % Return an S0 estimate for each voxel in coords
        % Coords are in the rows (i.e., nCoords x 3)%
        if ~isempty(varargin), coords = varargin{1};
        else error('coords required');
        end
        coords = coordCheck(coords);

        % Indices of the coords in the 3D volume.
        indx = sub2ind(dwi.nifti.dim(1:3),coords(:,1),coords(:,2),coords(:,3));
        b0 = dwiGet(dwi,'b0 image nums');
        val = zeros(size(coords,1),length(b0));
        for ii = 1:length(b0)
            tmp = squeeze(dwi.nifti.data(:,:,:,b0(ii)));
            val(:,ii) = tmp(indx);
        end
        val = nanmean(val,2);


    otherwise
        error('Unknown parameter: "%s"\n',param);
end


return

% ----
function coords = coordCheck(coords)
%
% Make sure the coordinates are in columns rather than rows
if size(coords,2) ~= 3
    if size(coords,1) == 3
        disp('Transposing coordinates to rows.')
        coords = coords';
    else
        error('Bad size of coords matrix');
    end
end

return

