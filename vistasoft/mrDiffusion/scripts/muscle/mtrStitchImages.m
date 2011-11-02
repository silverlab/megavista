function mtrStitchImages(imgBottomFile,imgTopFile,num_overlap,imgCombFile)

% Get input images

% Load images
[bottom_img, mmPerVox, foo, ACPC] = loadNifti(imgBottomFile);
[top_img, mmPerVox, foo, ACPC] = loadNifti(imgTopFile);

% Assume z-axis overlap and just replace overlapping slices
zdim = size(bottom_img,3) + size(top_img,3) - num_overlap;
new_size = size(bottom_img);
new_size(3) = zdim;

num_rem_bottom = floor(num_overlap/2);
num_rem_top = ceil(num_overlap/2);
comb_img = zeros(new_size);
comb_img(:,:,1:size(bottom_img,3)-num_rem_bottom) = bottom_img(:,:,1:end-num_rem_bottom);
top_ind = (size(bottom_img,3)-num_rem_bottom+1):zdim;
comb_img(:,:,top_ind) = top_img(:,:,num_rem_top+1:end);

% Save output image
saveNifti(comb_img,imgCombFile,mmPerVox,foo,ACPC);

