function fg = read_trk_to_fg( filename )

% fg = read_trk_to_fg( filename)
% read_trk reads fiber fg output from trackvis
% Input:
%       filename: Name of track file output from trackvis
%                 The extension of file is .trk
% Output:
%       fg is a mrDiffusion fiber group structure.
%       It contains the following additional field:
%           header: is a matlab structure. It contains all header information
%                   requires to visualize fiber fg in trackvis.
%
% For details about header fields and fileformat see:
% http://www.trackvis.org/docs/?subsect=fileformat
%
%
% Example;
%
% fg = read_trk_to_fg('hardiO10.trk');
%
% HISTORY:
% 2009.09.21 RFD wrote it, based on code by Sudhir K Pathak (read_trk).
%
% for PghBC2009 competition 2009 url:http://sfcweb.lrdc.pitt.edu/pbc/2009/
%


% NOTE: This program reads a binary fiber tracking file output from TrackVIS in native format
% If you reading .trk file on big endian machine change fopen function:
% fid = fopen(filename ,'r', 'ieee-le');

[p,f,e] = fileparts(filename);
fg = dtiNewFiberGroup(f);
try

    fid = fopen(filename ,'r');

    fg.header.id_string                  = fread(fid,6,'char=>char');
    fg.header.dim                        = fread(fid,3,'int16=>int16');
    fg.header.voxel_size                 = fread(fid,3,'float');
    fg.header.origin                     = fread(fid,3,'float');
    fg.header.n_scalars                  = fread(fid,1,'int16=>int16');
    fg.header.scalar_name                = fread(fid,200,'char=>char');
    fg.header.n_properties               = fread(fid,1,'int16=>int16');
    fg.header.property_name              = fread(fid,200,'char=>char');
    fg.header.reserved                   = fread(fid,508,'char=>char');
    fg.header.voxel_order                = fread(fid,4,'char=>char');
    fg.header.pad2                       = fread(fid,4,'char=>char');
    fg.header.image_orientation_patient  = fread(fid,6,'float');
    fg.header.pad1                       = fread(fid,2,'char=>char');
    fg.header.invert_x                   = fread(fid,1,'uchar');
    fg.header.invert_y                   = fread(fid,1,'uchar');
    fg.header.invert_z                   = fread(fid,1,'uchar');
    fg.header.swap_xy                    = fread(fid,1,'uchar');
    fg.header.swap_yz                    = fread(fid,1,'uchar');
    fg.header.swap_zx                    = fread(fid,1,'uchar');
    fg.header.n_count                    = fread(fid,1,'int');
    fg.header.version                    = fread(fid,1,'int');
    fg.header.hdr_size                   = fread(fid,1,'int');

    no_fibers = fg.header.n_count;
    fprintf(1,'Reading Fiber Data for %d fibers...\n',no_fibers);

    tmp = fread(fid,inf,'*float32')';
    fclose(fid);
catch
    fprintf('Unable to access file %s\n', filename);
end;

pct = 10;
n = 1;
for(ii=1:no_fibers)
    num_points = typecast(tmp(n),'int32');
    n = n+1;
    fg.fibers{ii} = reshape(tmp(n:num_points*3+n-1),3,num_points);
    n = n + num_points*3;
    if mod(ii,floor(no_fibers/10)) ==  0
        fprintf(1,'\n%3d percent fibers processed...', pct);
        pct = pct + 10;
    end
end
fprintf(1,'\n');

%     for i=1:no_fibers
%         fg.fiber{i}.num_points = fread(fid,1,'int');
%         fg.fiber{i}.points = fread(fid,[3,fg.fiber{i}.num_points],'float')';
%         %dummy = zeros(fg.fiber{i}.num_points, 3);
%         %for j=1:fg.fiber{i}.num_points
%         %    p = fread(fid,3,'float');
%         %    dummy(j,:) = p;
%         %end;
%         %fg.fiber{i}.points = dummy;
%
%         % progress report
%         if mod(i,floor(no_fibers/10)) ==  0
%             fprintf(1,'\n%3d percent fibers processed...', pct);
%             pct = pct + 10;
%         end;
%
%     end;
%     fprintf(1,'\n');


