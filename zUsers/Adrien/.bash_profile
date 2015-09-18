test -e /etc/profile && echo "/etc/profile is sourced" || echo "/etc/profile not found"
export PATH=/etc/bin:/usr/X11/bin:${PATH}

#Avoiding language specific issues
LC_NUMERIC=en_GB.UTF-8 
export LC_NUMERIC

# Setting PATH for Python 3.4# The orginal version is saved in .bash_profile.pysave
PATH=/Library/Frameworks/Python.framework/Versions/3.4/bin:${PATH}
export PATH

#Double check that FSL path is defined correctly
FSLDIR=/usr/local/fsl 
PATH=${FSLDIR}/bin:${FSLDIR}/etc/fslconf/:${FSLDIR}:${PATH} 
export FSLDIR PATH

#Add Mricron path for dcn2nii
PATH=/Users/adrienchopin/Desktop/mricron:${PATH}
export PATH

#Add path to segmentation files
PATH=/Users/adrienchopin/Desktop/Segmentation:${PATH}
export PATH
echo "PATH is defined to ${PATH}"








