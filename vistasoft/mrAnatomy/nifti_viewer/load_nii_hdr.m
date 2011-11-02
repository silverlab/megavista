%  Load NIFTI dataset header. Support both *.nii and *.hdr/*.img file
%  extension. If file extension is not provided, *.hdr/*.img will be 
%  used as default.
%  
%  Usage: [hdr, filetype, fileprefix, machine] = load_nii_hdr(filename)
%  
%  filename - NIFTI file name.
%  
%  Returned values:
%  
%  hdr - struct with NIFTI header fields.
%  
%  filetype	- 0 for Analyze format (*.hdr/*.img);
%		  1 for NIFTI format in 2 files (*.hdr/*.img);
%		  2 for NIFTI format in 1 file (*.nii).
%  
%  fileprefix - NIFTI file name without extension.
%  
%  machine    - a string, see below for details. The default here is 'ieee-le'.
%
%    'native'      or 'n' - local machine format - the default
%    'ieee-le'     or 'l' - IEEE floating point with little-endian
%                           byte ordering
%    'ieee-be'     or 'b' - IEEE floating point with big-endian
%                           byte ordering
%    'vaxd'        or 'd' - VAX D floating point and VAX ordering
%    'vaxg'        or 'g' - VAX G floating point and VAX ordering
%    'cray'        or 'c' - Cray floating point with big-endian
%                           byte ordering
%    'ieee-le.l64' or 'a' - IEEE floating point with little-endian
%                           byte ordering and 64 bit long data type
%    'ieee-be.l64' or 's' - IEEE floating point with big-endian byte
%                           ordering and 64 bit long data type.
%  
%  Number of scanned images in the file can be obtained by:
%  num_scan = hdr.dime.dim(5)
%
%  Part of this file is copied and modified under GNU license from
%  MRI_TOOLBOX developed by CNSP in Flinders University, Australia
%
%  NIFTI data format can be found on: http://nifti.nimh.nih.gov
%
%  - Jimmy Shen (pls@rotman-baycrest.on.ca)
%
function [hdr, filetype, fileprefix, machine] = load_nii_hdr(fileprefix)

   if ~exist('fileprefix','var'),
      error('Usage: [hdr, filetype, fileprefix, machine] = load_nii_hdr(filename)');
   end

   if ~exist('machine','var'), machine = 'ieee-le'; end

   new_ext = 0;

   if findstr('.nii',fileprefix)
      new_ext = 1;
      fileprefix = strrep(fileprefix,'.nii','');
   end

   if findstr('.hdr',fileprefix)
      fileprefix = strrep(fileprefix,'.hdr','');
   end

   if findstr('.img',fileprefix)
      fileprefix = strrep(fileprefix,'.img','');
   end

   if new_ext
      fn = sprintf('%s.nii',fileprefix);

      if ~exist(fn)
         msg = sprintf('Cannot find file "%s.nii".', fileprefix);
         error(msg);
      end
   else
      fn = sprintf('%s.hdr',fileprefix);

      if ~exist(fn)
         msg = sprintf('Cannot find file "%s.hdr".', fileprefix);
         error(msg);
      end
   end

   fid = fopen(fn,'r',machine);
    
   if fid < 0,
      msg = sprintf('Cannot open file %s.',fn);
      error(msg);
   else
      hdr = read_header(fid);
      fclose(fid);
   end
    
   if hdr.hk.sizeof_hdr ~= 348
      % first try reading the opposite endian to 'machine'
      switch machine,
      case 'ieee-le', machine = 'ieee-be';
      case 'ieee-be', machine = 'ieee-le';
      end
        
      fid = fopen(fn,'r',machine);
        
      if fid < 0,
         msg = sprintf('Cannot open file %s.',fn);
         error(msg);
      else
         hdr = read_header(fid);
         fclose(fid);
      end
   end

   if hdr.hk.sizeof_hdr ~= 348
      % Now throw an error
      msg = sprintf('File "%s" is corrupted.',fn);
      error(msg);
   end

   if strcmp(hdr.hist.magic, 'n+1')
      filetype = 2;
   elseif strcmp(hdr.hist.magic, 'ni1')
      filetype = 1;
   else
      filetype = 0;
   end

   return					% load_nii_hdr


%---------------------------------------------------------------------
function [ dsr ] = read_header(fid)

        %  Original header structures
	%  struct dsr
	%       { 
	%       struct header_key hk;            /*   0 +  40       */
	%       struct image_dimension dime;     /*  40 + 108       */
	%       struct data_history hist;        /* 148 + 200       */
	%       };                               /* total= 348 bytes*/

    dsr.hk   = header_key(fid);
    dsr.dime = image_dimension(fid);
    dsr.hist = data_history(fid);

    %  For Analyze data format
    %
    if ~strcmp(dsr.hist.magic, 'n+1') & ~strcmp(dsr.hist.magic, 'ni1')
        dsr.hist.qform_code = 0;
        dsr.hist.sform_code = 0;
    end

    return					% read_header


%---------------------------------------------------------------------
function [ hk ] = header_key(fid)

    fseek(fid,0,'bof');
    
	%  Original header structures	
	%  struct header_key                     /* header key      */ 
	%       {                                /* off + size      */
	%       int sizeof_hdr                   /*  0 +  4         */
	%       char data_type[10];              /*  4 + 10         */
	%       char db_name[18];                /* 14 + 18         */
	%       int extents;                     /* 32 +  4         */
	%       short int session_error;         /* 36 +  2         */
	%       char regular;                    /* 38 +  1         */
	%       char dim_info;   % char hkey_un0;        /* 39 +  1 */
	%       };                               /* total=40 bytes  */
	%
	% int sizeof_header   Should be 348.
	% char regular        Must be 'r' to indicate that all images and 
	%                     volumes are the same size. 
	
    hk.sizeof_hdr    = fread(fid, 1,'int32')';	% should be 348!
    hk.data_type     = deblank(fread(fid,10,'*char')');
    hk.db_name       = deblank(fread(fid,18,'*char')');
    hk.extents       = fread(fid, 1,'int32')';
    hk.session_error = fread(fid, 1,'int16')';
    hk.regular       = fread(fid, 1,'*char')';
    hk.dim_info      = fread(fid, 1,'char')';
    
    return					% header_key


%---------------------------------------------------------------------
function [ dime ] = image_dimension(fid)

	%  Original header structures    
	%  struct image_dimension
	%       {                                /* off + size      */
	%       short int dim[8];                /* 0 + 16          */
        %       /*
        %           dim[0]      Number of dimensions in database; usually 4. 
        %           dim[1]      Image X dimension;  number of *pixels* in an image row. 
        %           dim[2]      Image Y dimension;  number of *pixel rows* in slice. 
        %           dim[3]      Volume Z dimension; number of *slices* in a volume. 
        %           dim[4]      Time points; number of volumes in database
        %       */
	%       float intent_p1;   % char vox_units[4];   /* 16 + 4       */
	%       float intent_p2;   % char cal_units[8];   /* 20 + 4       */
	%       float intent_p3;   % char cal_units[8];   /* 24 + 4       */
	%       short int intent_code;   % short int unused1;   /* 28 + 2 */
	%       short int datatype;              /* 30 + 2          */
	%       short int bitpix;                /* 32 + 2          */
	%       short int slice_start;   % short int dim_un0;   /* 34 + 2 */
	%       float pixdim[8];                 /* 36 + 32         */
	%	/*
	%		pixdim[] specifies the voxel dimensions:
	%		pixdim[1] - voxel width, mm
	%		pixdim[2] - voxel height, mm
	%		pixdim[3] - slice thickness, mm
	%		pixdim[4] - volume timing, in msec
	%					..etc
	%	*/
	%       float vox_offset;                /* 68 + 4          */
	%       float scl_slope;   % float roi_scale;     /* 72 + 4 */
	%       float scl_inter;   % float funused1;      /* 76 + 4 */
	%       short slice_end;   % float funused2;      /* 80 + 2 */
	%       char slice_code;   % float funused2;      /* 82 + 1 */
	%       char xyzt_units;   % float funused2;      /* 83 + 1 */
	%       float cal_max;                   /* 84 + 4          */
	%       float cal_min;                   /* 88 + 4          */
	%       float slice_duration;   % int compressed; /* 92 + 4 */
	%       float toffset;   % int verified;          /* 96 + 4 */
	%       int glmax;                       /* 100 + 4         */
	%       int glmin;                       /* 104 + 4         */
	%       };                               /* total=108 bytes */
	
    dime.dim        = fread(fid,8,'int16')';
    dime.intent_p1  = fread(fid,1,'float32')';
    dime.intent_p2  = fread(fid,1,'float32')';
    dime.intent_p3  = fread(fid,1,'float32')';
    dime.intent_code = fread(fid,1,'int16')';
    dime.datatype   = fread(fid,1,'int16')';
    dime.bitpix     = fread(fid,1,'int16')';
    dime.slice_start = fread(fid,1,'int16')';
    dime.pixdim     = fread(fid,8,'float32')';
    dime.vox_offset = fread(fid,1,'float32')';
    dime.scl_slope  = fread(fid,1,'float32')';
    dime.scl_inter  = fread(fid,1,'float32')';
    dime.slice_end  = fread(fid,1,'int16')';
    dime.slice_code = fread(fid,1,'char')';
    dime.xyzt_units = fread(fid,1,'char')';
    dime.cal_max    = fread(fid,1,'float32')';
    dime.cal_min    = fread(fid,1,'float32')';
    dime.slice_duration = fread(fid,1,'float32')';
    dime.toffset    = fread(fid,1,'float32')';
    dime.glmax      = fread(fid,1,'int32')';
    dime.glmin      = fread(fid,1,'int32')';
        
    return					% image_dimension


%---------------------------------------------------------------------
function [ hist ] = data_history(fid)
        
	%  Original header structures
	%  struct data_history       
	%       {                                /* off + size      */
	%       char descrip[80];                /* 0 + 80          */
	%       char aux_file[24];               /* 80 + 24         */
	%       short int qform_code;            /* 104 + 2         */
	%       short int sform_code;            /* 106 + 2         */
	%       float quatern_b;                 /* 108 + 4         */
	%       float quatern_c;                 /* 112 + 4         */
	%       float quatern_d;                 /* 116 + 4         */
	%       float qoffset_x;                 /* 120 + 4         */
	%       float qoffset_y;                 /* 124 + 4         */
	%       float qoffset_z;                 /* 128 + 4         */
	%       float srow_x[4];                 /* 132 + 16        */
	%       float srow_y[4];                 /* 148 + 16        */
	%       float srow_z[4];                 /* 164 + 16        */
	%       char intent_name[16];            /* 180 + 16        */
	%       char magic[4];   % int smin;     /* 196 + 4         */
	%       };                               /* total=200 bytes */
    
    hist.descrip     = deblank(fread(fid,80,'*char')');
    hist.aux_file    = deblank(fread(fid,24,'*char')');
    hist.qform_code  = fread(fid,1,'int16')';
    hist.sform_code  = fread(fid,1,'int16')';
    hist.quatern_b   = fread(fid,1,'float32')';
    hist.quatern_c   = fread(fid,1,'float32')';
    hist.quatern_d   = fread(fid,1,'float32')';
    hist.qoffset_x   = fread(fid,1,'float32')';
    hist.qoffset_y   = fread(fid,1,'float32')';
    hist.qoffset_z   = fread(fid,1,'float32')';
    hist.srow_x      = fread(fid,4,'float32')';
    hist.srow_y      = fread(fid,4,'float32')';
    hist.srow_z      = fread(fid,4,'float32')';
    hist.intent_name = deblank(fread(fid,16,'*char')');
    hist.magic       = deblank(fread(fid,4,'*char')');

    fseek(fid,253,'bof');
    hist.originator  = fread(fid, 5,'int16')';
    
    return					% data_history

