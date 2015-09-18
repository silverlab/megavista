import os
import sys

path='/Volumes/Plata2/MRS_amblyopia/DATA/'
dir_list = sys.argv[1:]

for file in dir_list:
 	print (file + ' BEGIN SEGMENTATION') 
 	this_path= path + file + '/nifti/mprage.nii.gz'
  	new_path= path + file + '/nifti/mprage_backup.nii.gz'
  	os.system('cp ' + this_path + ' ' + new_path)
  	os.system('recon-all -i ' + this_path + ' -subjid ' + file + ' -all')
	print (file + ' COMPLETED')
  