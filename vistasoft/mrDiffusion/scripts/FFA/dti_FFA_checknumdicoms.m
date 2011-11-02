% Check number of dicoms

if ispc
    dtiDir = 'W:\projects\Kids\dti\';
else
    dtiDir = '/biac1/kgs/projects/Kids/dti/';
end
ageDirs = {'adolescents', 'adults','kids',...
    fullfile('adolescents','3T_AP'),...
    fullfile('adults','3T_AP'),...
    fullfile('kids','3T_AP')};

for ii=1:length(ageDirs)
    thisDir = fullfile(dtiDir,ageDirs{ii}); cd(thisDir);
    subs = dir('*0*');
    
    fprintf('\n\n ********************** \n');
    fprintf('DIRECTORY: %s\n\n',ageDirs{ii});
    
    for jj=1:length(subs)
        dicomDir = fullfile(thisDir,subs(jj).name,'raw','dti_g865_b900');
        if ~isdir(dicomDir)
            fprintf('No dti_g865_b900 dir found for %s \n',subs(jj).name);
        else
            cd(dicomDir);
            d=dir('*.dcm*');
            numdicoms = length(d);
            fprintf('%d dicoms found in dti_g865_b900 dir for %s \n',numdicoms, subs(jj).name);
        end
    end
end