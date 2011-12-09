#!/Library/Frameworks/Python.framework/Versions/Current/bin/python
#spmDirectorySetup.py

"""This script sets up a file directory structure for use with SPM.

Rachel Denison
2011-Oct-18
"""

import os

if __name__ == "__main__":
    dirList = ('analysis','discarded_scans','epis','gems','jobs',
               'QualityControl','ROIAnalysis','rois','structurals',
               'orig_niftis')

    for dir in dirList:
        os.mkdir(dir)
        print dir

    os.system('mv *.nii.gz epis')

    #Then convert to 3D hdr/img pairs

    #Move nii.gz files into the orig_niftis folder

    #Discard extra scans
#    scansToDiscard = np.array([1,2,3,4])
#    for scan in scansToDiscard:
#        print 'epis/*%(s)04d.img' % {'s':scan}
#        os.system('mv epis/*%(s)04d.img' % {'s':scan} + ' discarded_scans')
    



