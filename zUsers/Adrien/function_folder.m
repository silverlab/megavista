function function_folder(folder, basename)
%move to folder and apply a function on all files in there and rename
%output with base name basename (if possible, if not, edit)

cd(folder)
a = dir;
fileList ={a.name};
j=0;
for i=1:4; 
    if strcmp(fileList{i},'.')~=1 && strcmp(fileList{i},'..')~=1 && strcmp(fileList{i},'.DS_Store')~=1
        disp(['Doing something to ',fileList{i}])
        j=j+1;
        %for a python function applied to each file of the directory
        system(['yourFunction ', fileList{i},' ', basename,sprintf('%03.f',j),'.nii']); %rename output (if there is an output) to basename plus a number
        if success==0;             disp('Success');         else              disp('Failure');         end
    else
        disp(['Skip ',fileList{i}])
    end
end