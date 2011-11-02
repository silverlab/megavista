function vals = dwiGet(dwi, coords,call);
% Get data from the dwi structure
%
% Pass in a dwi structure (see dwiCreate) and a set of coordinates and the
% desired data to be returned.  Right now the only data types are diffusion
% data acpc, diffusion data image and b0 acpc.  More to come
%
% Example: To get diffusion data from a fiber
% dwi=dwiGet(
% dwi =
% dwiCreate('raw/DTI__aligned_trilin.nii.gz','raw/DTI__aligned_trilin.bvecs','raw/DTI_a
% ligned_trilin.bvals');
% fg = dtiReadFibers('fibers/arcuate.mat');
% coords = fg.fibers{1};
% vals = dwiGet(dwi,coords,'diffusion data acpc');
%
call=mrvParamFormat(call);
switch(call)
    
    % get dwi data from a set of coordinates in ac-pc apce
    case{'diffusionsignalacpc' 'dacpc' 'dwacpc' 'diffusiondataacpc'}
        % transform ac-pc coordinates which have units of millimeters from
        % the anterior commisure to image indices.  By iimage indices we
        % mean integer locations within the dwi volume that correspond to
        % the ac-pc coordinates. At some point we may want to interpolate
        % these as oppose to rounding them to integers but for the time
        % being it seems to make more sense to grab data from a full voxel
        coords = round(mrAnatXformCoords(dwi.nifti.qto_ijk,coords))
        % make sure the coordinates are in columns rather than rows
        if size(coords,1) == 3, coords=coords',end;
        % vals will be a 3D matrix with dimensions (N coords,N vols) where 
        % N coords is the number of coordinates passed in and N vols is the
        % number of volumes in the nifti image
        indx=sub2ind(dwi.nifti.dim(1:3),coords(:,1),coords(:,2),coords(:,3))
        for ii = 1:size(dwi.nifti.data,4)
            tmp=squeeze(dwi.nifti.data(:,:,:,ii));
            vals(:,ii) = tmp(indx);
        end
        
        % get dwi data from a set of coordinates in image apce
    case{'diffusionsignalimage' 'dimage' 'dwimage' 'diffusiondataimage'}
        % The coordinates do not need to be transformed because they are
        % already in image space.  They just need to be rounded to integer
        % indices
        coords = round(coords)
        % make sure the coordinates are in columns rather than rows
        if size(coords,1) == 3, coords=coords',end;
        % vals will be a 3D matrix with dimensions (N coords,N vols) where 
        % N coords is the number of coordinates passed in and N vols is the
        % number of volumes in the nifti image
        indx=sub2ind(dwi.nifti.dim(1:3),coords(:,1),coords(:,2),coords(:,3))
        for ii = 1:size(dwi.nifti.data,4)
            tmp=squeeze(dwi.nifti.data(:,:,:,ii));
            vals(:,ii) = tmp(indx);
        end
        
         % get B0 data from a set of coordinates in ac-pc apce
    case{'b0acpc' 'B0acpc' 's0acpc' 'S0acpc'}
        % transform ac-pc coordinates which have units of millimeters from
        % the anterior commisure to image indices.  By iimage indices we
        % mean integer locations within the dwi volume that correspond to
        % the ac-pc coordinates. At some point we may want to interpolate
        % these as oppose to rounding them to integers but for the time
        % being it seems to make more sense to grab data from a full voxel
        coords = round(mrAnatXformCoords(dwi.nifti.qto_ijk,coords))
        % make sure the coordinates are in columns rather than rows
        if size(coords,1) == 3, coords=coords',end;
        % vals will be a 1xN vector where N is the number of coordinates
        % passed in.  The measurements across b0 volumes are averaged
        indx=sub2ind(dwi.nifti.dim(1:3),coords(:,1),coords(:,2),coords(:,3));
        b0 = dwi.bvals==0;
        b0 = find(b0);
        for ii = 1:length(b0)
            tmp=squeeze(dwi.nifti.data(:,:,:,b0(ii)));
            vals(:,ii) = tmp(indx);
        end
        vals = nanmean(vals,1);
end