function out = mtrMatchImages2D(imgFilenameB0,imgFilenameT1)

imgFilenameB0 = 'B0.nii.gz';
imgFilenameT1 = 't1/comb_anat.nii.gz';


% Load images
niB0 = readFileNifti(imgFilenameB0);
niT1 = readFileNifti(imgFilenameT1);

if(size(niB0.data,3)~= size(niT1.data,3))
    error('Must have same number of z slices.');
end
if(size(niB0.data,1)~= size(niB0.data,2))
    error('Must have same length along x and y axes.');
end

% Apply cannonical xform to B0
cannonical = diag([-1 -1 -1 1]);
tmp = cannonical(1,:);
cannonical(1,:) = cannonical(2,:);
cannonical(2,:) = tmp;
cannonical(1:2,4) = 128;
[niB0.data, junk] = applyCannonicalXform(niB0.data, cannonical, niB0.pixdim);

for zz = size(niT1.data,3)
    imgB0 = double(niB0.data(:,:,zz));
    imgT1 = double(niT1.data(:,:,zz));
    % Zoom lower B0 up, assume x and y equal dimensions
    factor = size(imgT1,1)/size(imgB0,1);
    imgB0 = warpAffine2(imgB0,diag([factor, factor, 1]),'spline');
    % Easy zeropad because we are already going to

    [M,w2d] = estMotion2(img1,img2,1,1);
end

% Lets first line up the slices that should agree
match_img_top = double(top_img(:,:,1));
match_img_bottom = double(bottom_img(:,:,end-num_overlap-1));

[M,w2d] = estMotion2(match_img_top,match_img_bottom,1,1);
