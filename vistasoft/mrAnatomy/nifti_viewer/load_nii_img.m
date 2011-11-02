%  Load NIFTI dataset body after its header is loaded using load_nii_hdr.
%  
%  Usage: [img,hdr] = ...
%       load_nii_img(hdr,filetype,fileprefix,machine,[img_idx],[old_RGB]);
%  
%  Where: [hdr,filetype,fileprefix,machine] = load_nii_hdr(filename);
%  
%  img_idx    - a numerical array of image indices. Only the specified images
%	will be loaded. If there is no img_idx, all images will be loaded. The
%       number of images scans can be obtained from hdr.dime.dim(5)
%
%  old_RGB    - an optional boolean variable to handle special RGB data 
%       sequence [R1 R2 ... G1 G2 ... B1 B2 ...] that is used only by 
%       AnalyzeDirect (Analyze Software). Since both NIfTI and Analyze
%       file format use RGB triple [R1 G1 B1 R2 G2 B2 ...] sequentially
%       for each voxel, this variable is set to FALSE by default. If the 
%       image that you displayed is garbled, try to set old_RGB variable
%       to TRUE (or 1) and load the image again, because it could be using
%       AnalyzeDirect RGB data sequence.
%
%  Returned values:
%  
%  img - 3D (or 4D) matrix of NIFTI data.
%  
%  Part of this file is copied and modified under GNU license from
%  MRI_TOOLBOX developed by CNSP in Flinders University, Australia
%  
%  NIFTI data format can be found on: http://nifti.nimh.nih.gov
%  
%  - Jimmy Shen (pls@rotman-baycrest.on.ca)
%
function [img,hdr] = load_nii_img(hdr,filetype,fileprefix,machine,img_idx,old_RGB)
   
   if ~exist('hdr','var') || ~exist('filetype','var') || ~exist('fileprefix','var') || ~exist('machine','var')
      error('Usage: [img,hdr] = load_nii_img(hdr,filetype,fileprefix,machine,[img_idx]);');
   end
   
   if ~exist('img_idx','var') || hdr.dime.dim(5)<1, img_idx = []; end %#ok<OR2>
   if ~exist('old_RGB','var'), old_RGB = 0; end
   
   %  check img_idx
   %
   if ~isempty(img_idx) && ~isnumeric(img_idx)
      error('"img_idx" should be a numerical array.');
   end
   
   if length(unique(img_idx)) ~= length(img_idx)
      error('Duplicate image index in "img_idx"');
   end
   
   if ~isempty(img_idx) && (min(img_idx) < 1 || max(img_idx) > hdr.dime.dim(5))
      max_range = hdr.dime.dim(5);

      if max_range == 1
         error(['"img_idx" should be 1.']);
      else
         range = ['1 ' num2str(max_range)];
         error(['"img_idx" should be an integer within the range of [' range '].']);
      end
   end
   
   [img,hdr] = read_image(hdr,filetype,fileprefix,machine,img_idx,old_RGB);
   
   return					% load_nii_img


%---------------------------------------------------------------------
function [img,hdr] = read_image(hdr, filetype,fileprefix,machine,img_idx,old_RGB)

   switch filetype
   case {0, 1}
      fn = [fileprefix '.img'];
   case 2
      fn = [fileprefix '.nii'];
   end

   fid = fopen(fn,'r',machine);

   if fid < 0,
      msg = sprintf('Cannot open file %s.',fn);
      error(msg);
   end

   %  Set bitpix according to datatype
   %
   %  /*Acceptable values for datatype are*/ 
   %
   %     0 None                     (Unknown bit per voxel) % DT_NONE, DT_UNKNOWN 
   %     1 Binary                         (ubit1, bitpix=1) % DT_BINARY 
   %     2 Unsigned char         (uchar or uint8, bitpix=8) % DT_UINT8, NIFTI_TYPE_UINT8 
   %     4 Signed short                  (int16, bitpix=16) % DT_INT16, NIFTI_TYPE_INT16 
   %     8 Signed integer                (int32, bitpix=32) % DT_INT32, NIFTI_TYPE_INT32 
   %    16 Floating point    (single or float32, bitpix=32) % DT_FLOAT32, NIFTI_TYPE_FLOAT32 
   %    32 Complex, 2 float32      (Use float32, bitpix=64) % DT_COMPLEX64, NIFTI_TYPE_COMPLEX64
   %    64 Double precision  (double or float64, bitpix=64) % DT_FLOAT64, NIFTI_TYPE_FLOAT64 
   %   128 uint8 RGB                 (Use uint8, bitpix=24) % DT_RGB24, NIFTI_TYPE_RGB24 
   %   256 Signed char            (schar or int8, bitpix=8) % DT_INT8, NIFTI_TYPE_INT8 
   %   511 Single RGB              (Use float32, bitpix=96) % DT_RGB96, NIFTI_TYPE_RGB96
   %   512 Unsigned short               (uint16, bitpix=16) % DT_UNINT16, NIFTI_TYPE_UNINT16 
   %   768 Unsigned integer             (uint32, bitpix=32) % DT_UNINT32, NIFTI_TYPE_UNINT32 
   %  1024 Signed long long              (int64, bitpix=64) % DT_INT64, NIFTI_TYPE_INT64
   %  1280 Unsigned long long           (uint64, bitpix=64) % DT_UINT64, NIFTI_TYPE_UINT64 
   %  1536 Long double, float128  (Unsupported, bitpix=128) % DT_FLOAT128, NIFTI_TYPE_FLOAT128 
   %  1792 Complex128, 2 float64  (Use float64, bitpix=128) % DT_COMPLEX128, NIFTI_TYPE_COMPLEX128 
   %  2048 Complex256, 2 float128 (Unsupported, bitpix=256) % DT_COMPLEX128, NIFTI_TYPE_COMPLEX128 
   %
   switch hdr.dime.datatype
   case   1,
      hdr.dime.bitpix = 1;  precision = 'ubit1';
   case   2,
      hdr.dime.bitpix = 8;  precision = 'uint8';
   case   4,
      hdr.dime.bitpix = 16; precision = 'int16';
   case   8,
      hdr.dime.bitpix = 32; precision = 'int32';
   case  16,
      hdr.dime.bitpix = 32; precision = 'float32';
   case  32,
      hdr.dime.bitpix = 64; precision = 'float32';
   case  64,
      hdr.dime.bitpix = 64; precision = 'float64';
   case 128,
      hdr.dime.bitpix = 24; precision = 'uint8';
   case 256 
      hdr.dime.bitpix = 8;  precision = 'int8';
   case 511 
      hdr.dime.bitpix = 96; precision = 'float32';
   case 512 
      hdr.dime.bitpix = 16; precision = 'uint16';
   case 768 
      hdr.dime.bitpix = 32; precision = 'uint32';
   case 1024
      hdr.dime.bitpix = 64; precision = 'int64';
   case 1280
      hdr.dime.bitpix = 64; precision = 'uint64';
   case 1792,
      hdr.dime.bitpix = 128; precision = 'float64';
   otherwise
      error('This datatype is not supported'); 
   end

   hdr.dime.dim(hdr.dime.dim < 1) = 1;

   %  move pointer to the start of image block
   %
   switch filetype
   case {0, 1}
      fseek(fid, 0, 'bof');
   case 2
      fseek(fid, hdr.dime.vox_offset, 'bof');
   end

   %  Load whole image block for old Analyze format, or binary image,
   %  or img_idx is empty; otherwise, load images that are specified
   %  in img_idx
   %
   %  For binary image, we have to read all because pos can not be
   %  seeked in bit and can not be calculated the way below.
   %
   if filetype == 0 || hdr.dime.datatype == 1 || isempty(img_idx)

      %  For each frame, precision of value will be read 
      %  in img_siz times, where img_siz is only the 
      %  dimension size of an image, not the byte storage
      %  size of an image.
      %
      img_siz = prod(hdr.dime.dim(2:8));

      %  For complex float32 or complex float64, voxel values
      %  include [real, imag]
      %
      if hdr.dime.datatype == 32 || hdr.dime.datatype == 1792
         img_siz = img_siz * 2;
      end
	 
      %MPH: For RGB24, voxel values include 3 separate color planes
      %
      if hdr.dime.datatype == 128 || hdr.dime.datatype == 511
	 img_siz = img_siz * 3;
      end

      img = fread(fid, img_siz, sprintf('*%s',precision));

   else
      img = [];
      
      for i=1:length(img_idx)
         
         %  For each frame, precision of value will be read 
         %  in img_siz times, where img_siz is only the 
         %  dimension size of an image, not the byte storage
         %  size of an image.
         %
         img_siz = prod(hdr.dime.dim(2:4));

	 %  Position is seeked in bytes. To convert dimension size
         %  to byte storage size, hdr.dime.bitpix/8 will be
         %  applied.
         %
         %  (MPH: This offset must be calculated BEFORE altering img_siz
	 %  for the datatypes for which 'bitpix' and 'precision' do not
         %  "match").
         %
         pos = (img_idx(i) - 1) * img_siz * hdr.dime.bitpix/8;

         %  For complex float32 or complex float64, voxel values
         %  include [real, imag]
         %
         if hdr.dime.datatype == 32 || hdr.dime.datatype == 1792
            img_siz = img_siz * 2;
         end

         %MPH: For RGB24, voxel values include 3 separate color planes
         %
         if hdr.dime.datatype == 128 || hdr.dime.datatype == 511
	    img_siz = img_siz * 3;
         end
         
         if filetype == 2
            fseek(fid, pos + hdr.dime.vox_offset, 'bof');
         else
            fseek(fid, pos, 'bof');
         end

         %  For each frame, fread will read precision of value
         %  in img_siz times
         %
         img = [img fread(fid, img_siz, sprintf('*%s',precision))];
      end
   end

   %  For complex float32 or complex float64, voxel values
   %  include [real, imag]
   %
   if hdr.dime.datatype == 32 || hdr.dime.datatype == 1792
      img = reshape(img, [2, length(img)/2]);
      img = complex(img(1,:)', img(2,:)');
   end

   fclose(fid);

   %  Update the global min and max values 
   %
   hdr.dime.glmax = max(double(img(:)));
   hdr.dime.glmin = min(double(img(:)));

   if isempty(img_idx)
      img_idx = 1:hdr.dime.dim(5);
   end

   if old_RGB && hdr.dime.datatype == 128 && hdr.dime.bitpix == 24
      img = reshape(img, [hdr.dime.dim(2:3) 3 hdr.dime.dim(4) length(img_idx) hdr.dime.dim(6:8)]);
      img = permute(img, [1 2 4 3 5 6 7 8]);
   elseif hdr.dime.datatype == 128 && hdr.dime.bitpix == 24
      img = reshape(img, [3 hdr.dime.dim(2:4) length(img_idx) hdr.dime.dim(6:8)]);
      img = permute(img, [2 3 4 1 5 6 7 8]);
   elseif hdr.dime.datatype == 511 && hdr.dime.bitpix == 96
      img = double(img);
      img = (img - min(img))/(max(img) - min(img));
      img = reshape(img, [3 hdr.dime.dim(2:4) length(img_idx) hdr.dime.dim(6:8)]);
      img = permute(img, [2 3 4 1 5 6 7 8]);
   else
      img = reshape(img, [hdr.dime.dim(2:4) length(img_idx) hdr.dime.dim(6:8)]);
   end

   if ~isempty(img_idx)
      hdr.dime.dim(5) = length(img_idx);
   end

   return						% read_image

