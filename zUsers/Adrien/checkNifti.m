function checkNifti(thisPath)
%---------------------------------------------------------------------------------------------
% This script checks the compressed nifti or nifti file (.nii / .nii.gz) at thisPath and
% returns an error if the nifti header is uncorrect 
%---------------------------------------------------------------------------------------------
% If thisPath is a directory, it checks all files and stops with an error
% if one is incorrect / NOT SUPPORTED YET
% If mode is provided:
%   mode = 1 - (forced) stops and gives an error whenever one issue is found with the file
%   mode = 2 - (not supported anymore) does not give an error but a diagnostic for the file
%---------------------------------------------------------------------------------------------
% It checks a few common problems that occur when converting a Siemens DICOM file to nifti: 
%       - check that freq_dim is not 0
%       - check that phase_dim is not 0
%       - check that slice_dim is not 0
%       - check the method relating ijk and xyz (see http://nifti.nimh.nih.gov/nifti-1/documentation/nifti1fields/nifti1fields_pages/qsform.html)
%               method 1 if qform_code = 0 and sform_code = 0
%                    - check that qto_xyz is equal to sto_xyz
%                    -%check that pixdim is correct
%               method 2 if qform_code > 1 and sform_code = 0
%                   -  % check that qto_xyz is not 0
%                    -  %check that qfac is 1 or -1
%                    - check that qto_xyz is equal to sto_xyz
%                    -%check that pixdim is correct
%                   -  % check that qto_xyz is not 0
%                   -% check that qoffset are not 0
%                   %check that the qto_xyz matrix is well formed with qoffset values
%                    %check that qto xyz matrix is formed correctly according to the pixdim values
%               method 3 if sform_code > 1
%                    - check that sto_xyz is not 0
%                   - check that qto_xyz is equal to sto_xyz
%       - check that slice_end is not 0 (it should be nb of slices -1)
%       - check that slice_duration is not 0
%---------------------------------------------------------------------------------------------
%   Adrien Chopin - 2015
%---------------------------------------------------------------------------------------------

%if exist('mode','var')==0; mode = 1; end
mode=1;

    %single file
    if exist(thisPath,'file')==2
        checkThisFile(thisPath, mode)
    %directory
    elseif exist(thisPath,'file')==7 
        error('checkNifti function: directory checks are not yet supported - please input only a file')
    else 
        error('checkNifti function: No file or directory found here.') 
    end
end

function checkThisFile(thisPath, mode)
    ni = readFileNifti(thisPath)
    [dummy,file]=fileparts(thisPath);
%     if mode == 1
%         if ni.freq_dim==0
%             error('checkNifti: incorrect nifti header - freq_dim = 0')
%         elseif ni.phase_dim==0
%             error('checkNifti: incorrect nifti header - phase_dim = 0')        
%         elseif ni.slice_dim==0
%             error('checkNifti: incorrect nifti header - slice_dim = 0')
%         elseif sum(ni.qto_xyz)==0
%             error('checkNifti: incorrect nifti header - qto_xyz = 0')
%         elseif (ni.sto_xyz==ni.qto_xyz)==0
%            error('checkNifti: incorrect nifti header - unequal sto_xyz and qto_xyz')
%         elseif ni.slice_end==0
%            error('checkNifti: incorrect nifti header - slice_end = 0')
%         elseif ni.slice_duration==0
%            error('checkNifti: incorrect nifti header - slice_duration = 0')
%         else
%             disp('The nifti file seems correct regarding freq_dim, phase_dim, slice_dim, sto_xyz, qto_xyz, slice_end.') 
%         end
%     else
        disp(['checkNifti checks the nifti header of the file : ',file])
%       - check that freq_dim is not 0
        if ni.freq_dim==0
             disp('NOT OK - incorrect freq_dim')
        else
             disp('OK - freq_dim is not null')
        end
%       - check that phase_dim is not 0
        if ni.phase_dim==0
             disp('NOT OK - incorrect phase_dim')
        else
             disp('OK - phase_dim is not null')
        end
%       - check that slice_dim is not 0
        if ni.slice_dim==0
            disp('NOT OK - incorrect slice_dim')
        else
            disp('OK - slice_dim is not null')
        end
%       - check the method relating ijk and xyz (see http://nifti.nimh.nih.gov/nifti-1/documentation/nifti1fields/nifti1fields_pages/qsform.html)
%               method 1 if qform_code = 0 and sform_code = 0
%               method 2 if qform_code = 1 and sform_code = 0
%               method 3 if sform_code = 1
        if (ni.qform_code == 0) && (ni.sform_code == 0)
            disp('ijk to xyz relation is using method 1')
        end
        if (ni.qform_code > 0) && (ni.sform_code == 0)
            disp('ijk to xyz relation is using method 2')
        end
        if ni.sform_code > 0
            disp('ijk to xyz relation is using method 3')
        end
            %check that pixdim is correct
            if sum(ni.pixdim)==0 || numel(ni.pixdim)~=ni.ndim
                disp('NOT OK - incorrect pixdim (or ndim) parameters')
            else
                disp('OK - pixdim and ndim are coherent')
            end
            %- check that sto_xyz is not 0
            if sum(ni.sto_xyz)==0
                disp('NOT OK - sto_xyz is null')
            else
                disp('OK - sto_xyz is not null')
            end 
            
      %  end
        
            
%             %check that pixdim is correct
%             if sum(ni.pixdim)==0 || numel(ni.pixdim)~=ni.ndim
%                 disp('incorrect pixdim (or ndim) parameters - NOT OK but fine if you can check that qto_xyz is correct')
%             else
%                 disp('pixdim and ndim - OK')
%             end
            %check that qfac is 1 or -1
            if ni.qfac~=1 && ni.qfac~=-1
                disp('NOT OK - qfac - fine if you can check that qto_xyz is correct')
            else
                disp('OK - qfac is 1 or -1')
            end
            % check that qoffset are not 0
            if ni.qoffset_x==0 || ni.qoffset_y==0 || ni.qoffset_z==0
                disp('NOT OK - One of the qoffset_* is null - check that - fine if you can check that qto_xyz is correct')
            else
                disp('OK - qoffset_* are not null')
            end
            %       - check that qto_xyz is equal to sto_xyz
%             if (ni.sto_xyz==ni.qto_xyz)>0.0001
%                disp('unequal sto_xyz and qto_xyz - NOT OK')
%             else
%                disp('sto_xyz = qto_xyz - OK')
%             end
            % check that qto_xyz is not 0
            if sum(ni.qto_xyz)==0
                disp('NOT OK - incorrect qto_xyz')
            else
                disp('OK - qto_xyz is not null')
            end
            %check that the qto_xyz matrix is well formed with qoffset values
            if ni.qto_xyz(1,4)~=ni.qoffset_x || ni.qto_xyz(2,4)~=ni.qoffset_y || ni.qto_xyz(3,4)~=ni.qoffset_z
                disp('NOT OK - qto_xyz is well ill-formed or qoffset_* are wrong')    
            else
               disp('OK - qto_xyz is well formed regarding qoffset_* values')    
            end
            %check that qto xyz matrix is formed correctly according to the pixdim values
            R = ni.qto_xyz;
            dx = sqrt( R(1,1)*R(1,1) + R(2,1)*R(2,1) + R(3,1)*R(3,1) );
            dy = sqrt( R(1,2)*R(1,2) + R(2,2)*R(2,2) + R(3,2)*R(3,2) );
            dz = sqrt( R(1,3)*R(1,3) + R(2,3)*R(2,3) + R(3,3)*R(3,3) ); 
            if any(([dx, dy, dz] - ni.pixdim(1:3))>0.0001)
                disp('NOT OK - qto_xyz is well ill-formed or pixdim are wrong')   
            else
               disp(['OK - qto_xyz is well formed regarding pixdim - with precision ', num2str(max([dx, dy, dz] - ni.pixdim(1:3)))])    
            end
        %end
        
            %       - check that qto_xyz is equal to sto_xyz
            if sum(sum(ni.sto_xyz-ni.qto_xyz))>0.001
               disp('NOT OK - unequal sto_xyz and qto_xyz')
            else
               disp('OK - sto_xyz = qto_xyz')
            end
%             if (ni.sto_xyz==ni.qto_xyz)>0.0001
%                disp('unequal sto_xyz and qto_xyz - NOT OK')
%             else
%                disp('sto_xyz = qto_xyz - OK')
%             end
        %end
%- check that slice_end is not 0 (it should be nb of slices -1)   
        if ni.slice_end==0
            disp('NOT OK - incorrect slice_end')
        else
            disp('OK - slice_end is not null')
        end
%       - check that slice_duration is not 0     
        if ni.slice_duration==0
            disp('NOT OK - incorrect slice_duration')
        else
            disp('OK - slice_duration is not null')
        end
        
        disp(['qoffset_* values are ', num2str([ni.qoffset_x, ni.qoffset_y, ni.qoffset_z])])
        disp('************************************************')
%    end
end
