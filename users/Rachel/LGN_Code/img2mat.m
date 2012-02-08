function [vol]=img2mat(input)

str=[input '.nii'];
hdr=spm_vol(str);
vol=spm_read_vols(hdr);

save vol