
lc = '/biac3/wandell4/data/reading_longitude/dti_y1_old/mho040625/left/classprojects/20070120/left.Class';
rc = '/biac3/wandell4/data/reading_longitude/dti_y1_old/mho040625/right/classprojects/20070120/right.Class';
vAnat = '/biac3/wandell4/data/reading_longitude/dti_y1_old/mho040625/t1/vAnatomy.dat';

t1Ni = '/biac3/wandell4/data/reading_longitude/dti_y1234/mho040625/t1/t1.nii.gz';
mrGrayConvertClassToNifti(lc, rc, vAnat, t1Ni);

t1Ni = '/biac3/wandell4/data/reading_longitude/dti_y1234/mho050528/t1/t1.nii.gz';
mrGrayConvertClassToNifti(lc, rc, vAnat, t1Ni);

t1Ni = '/biac3/wandell4/data/reading_longitude/dti_y1234/mho060527/t1/t1.nii.gz';
mrGrayConvertClassToNifti(lc, rc, vAnat, t1Ni);

t1Ni = '/biac3/wandell4/data/reading_longitude/dti_y1234/mho070519/t1/t1.nii.gz';
mrGrayConvertClassToNifti(lc, rc, vAnat, t1Ni);


