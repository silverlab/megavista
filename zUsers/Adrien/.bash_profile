test -e /etc/profile && echo "/etc/profile is sourced" || echo "/etc/profile not found"
export PATH=/etc/bin:/usr/X11/bin:${PATH}

#Avoiding language specific issues
LC_NUMERIC=en_GB.UTF-8 
export LC_NUMERIC

# Setting PATH for Python 3.4# The orginal version is saved in .bash_profile.pysave
pythonLib=/Library/Frameworks/Python.framework/Versions/3.4/bin
test -e $pythonLib && echo "python libraries are in path" || echo "python libraries not found"
PATH=${pythonLib}:${PATH}
export PATH

# Add FSL - Double check that FSL path is defined correctly
FSLDIR=/usr/local/fsl 
test -e $FSLDIR && echo "FSL is in path" || echo "FSL not found"
PATH=${FSLDIR}/bin:${FSLDIR}/etc/fslconf/:${FSLDIR}:${PATH} 
export FSLDIR PATH

# Add Mricron path for dcn2nii 
pathMRIcron=~/Desktop/mricron
# pathMRIcron =/usr/local/mricron
test -e $pathMRIcron && echo "MRIcron is in path" || echo "MRIcron not found"
PATH=${pathMRIcron}:${PATH}
export PATH

# Add freesurfer path (necessary in order to run itkGray and white segmentation 
# scripts from matlab later)
fspath=/Applications/freesurfer
test -e $fspath && echo "Freesurfer is in path" || echo "Freesurfer not found"
PATH=${fspath}/bin:${fspath}/mni/bin:${PATH}
export PATH

# export freesurfer home env variable
export fspath
SUBJECTS_DIR=${fspath}/subjects
test -e $SUBJECTS_DIR && echo "Freesurfer path and subject folder are exported" || echo "Freesurfer subject folder not found"
export SUBJECTS_DIR
export FREESURFER_HOME=${fspath}
FUNCTIONALS_DIR=${fspath}/sessions
test -e $SUBJECTS_DIR && echo "Freesurfer session folder is exported" || echo "Freesurfer session folder not found"
export FUNCTIONALS_DIR

# Add path to segmentation files - change that to yours
segm=~/Desktop/Segmentation
test -e $segm && echo "Segmentation is in path" || echo "Segmentation not found"
PATH=${segm}:${PATH}
export PATH
echo "PATH is defined to ${PATH}"

source ${fspath}/FreeSurferEnv.sh








