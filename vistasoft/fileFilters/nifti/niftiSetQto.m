function ni = niftiSetQto(ni, xformXyz, setStoToo)
%  Set the qto transform fields in the nifti struct ni
% ni = niftiSetQto(ni, xformXyz, [setStoToo=false])
%
% HISTORY:
% 2007.05.16 RFD: wrote it.
% 2008.08.24 RFD: pixdim is now properly set if the scale factors change
%                 and/or the dims are permuted.

q = matToQuat(xformXyz);
ni.qform_code = 2;

ni.qto_xyz = xformXyz;
ni.qto_ijk = inv(xformXyz);
ni.quatern_b = q.quatern_b;
ni.quatern_c = q.quatern_c;
ni.quatern_d = q.quatern_d;
ni.qoffset_x = q.quatern_x;
ni.qoffset_y = q.quatern_y;
ni.qoffset_z = q.quatern_z;
ni.qfac = q.qfac;

ni.pixdim(1:3) = [q.dx q.dy q.dz];

if(exist('setStoToo','var')&&~isempty(setStoToo)&&setStoToo)
  ni.sto_xyz = ni.qto_xyz;
  ni.sto_ijk = ni.qto_ijk;
end

return;
