function writeFileNifti(ni)
% function writeFileNifti(ni)
%
%  v = niftiWrite(ni)
%
%
% INPUTS:
% a nifti file structure (.nii or .nii.gz)
%
% RETURNS
% no output variables
%
% Web Resources
% mrvBrowseSVN('writeFileNifti')
%
% Example:
%
% ni = 
% 
%               data: [256x256x21 double]
%              fname: 'nifti_filename.nii.gz'
%               ndim: 3
%                dim: [256 256 21]
%             pixdim: [0.5000 0.5000 1.9999]
%          scl_slope: 1
%          scl_inter: 0
%            cal_min: 0
%            cal_max: 0
%         qform_code: 0
%         sform_code: 1
%           freq_dim: 0
%          phase_dim: 0
%          slice_dim: 0
%         slice_code: 0
%        slice_start: 0
%          slice_end: 0
%     slice_duration: 0
%          quatern_b: 0
%          quatern_c: 0
%          quatern_d: 0
%          qoffset_x: 0
%          qoffset_y: 0
%          qoffset_z: 0
%               qfac: 0
%            qto_xyz: [4x4 double]
%            qto_ijk: [4x4 double]
%            sto_xyz: [4x4 double]
%            sto_ijk: [4x4 double]
%            toffset: 0
%          xyz_units: 'mm'
%         time_units: 'sec'
%         nifti_type: 1
%        intent_code: 0
%          intent_p1: 0
%          intent_p2: 0
%          intent_p3: 0
%        intent_name: ''
%            descrip: ''
%           aux_file: ''
%            num_ext: 0
% 
% writeFileNifti(ni);
%
% Copyright Stanford team, mrVista, 2011