function ctrConnectMultipleROIs(dt6, blobfile, numSamples)
%CONTRACK alternative to dtiConnectMultipleROIs

%ER wrote it 11/2009
%%%%%%

if ~exist('numSamples', 'var') || isempty(numSamples)
numSamples=5000; 
end

binDir=fileparts(dt6.files.b0); 
outputDir=fullfile(fileparts(fileparts(dt6.dataFile)), 'fibers', 'conTrack'); 
[pathstr, filename, ext]=fileparts(blobfile); 

%Make sure that blob file is in the same space as dt0

%Prepare your ROIs: intersect them with GM mask !!!!!
%GM mask
[wm, gm, csf] = mrAnatSpmSegment(dt6.b0, dt6.xformToAcpc, 'mniepi');
b0=readFileNifti(dt6.files.b0); 
bb=mrAnatXformCoords(b0.qto_xyz, [1 1 1; b0.dim]); 
b0.data=zeros(size(b0.data)); b0.data(gm>127)=gm(gm>127); 
b0.fname=fullfile(fileparts(b0.fname), 'gm.nii.gz'); 
writeFileNifti(b0); 

blobBrick=readFileNifti(blobfile);
blobBrick.data(isnan(blobBrick.data))=0;

blobs=unique(blobBrick.data(:));

%Set up a loop. For each pair of ROIs
for blobIDi=2:length(blobs) %Skip the first one --- zero
 for blobIDj=blobIDi+1:length(blobs)

	%output as bricks with values=[0, 1, 2]
        newblobBrick=b0; 
        blob1mask=blobBrick.data*0;
        blob1mask(blobBrick.data==blobs(blobIDi))=1; 
        blob2mask=blobBrick.data*0;
        blob2mask(blobBrick.data==blobs(blobIDj))=1; 
        
        blob1maskR=mrAnatResliceSpm(blob1mask, blobBrick.qto_ijk, bb, [2 2 2]);
        blob2maskR=mrAnatResliceSpm(blob2mask, blobBrick.qto_ijk, bb, [2 2 2]);
        newblobBrick.data=round(blob1maskR)+round(blob2maskR)*2; 
        newblobBrick.data(gm<=0)=0; 

        newblobBrick.fname=fullfile(binDir, [filename(1:end-4) '_blobs' num2str(blobs(blobIDi)) '_' num2str(blobs(blobIDj)) '.nii.gz']); 

        writeFileNifti(newblobBrick); 

	%create ctrSampler
        ctrparamsFile=fullfile(outputDir, ['ctrScript_' filename(1:end-4) '_blobs' num2str(blobs(blobIDi)) '_' num2str(blobs(blobIDj)) '.txt']); 
	    nfgWriteConTrackParams(ctrparamsFile, binDir, 'wmProb.nii.gz', [filename(1:end-4) '_blobs' num2str(blobs(blobIDi)) '_' num2str(blobs(blobIDj)) '.nii.gz'], 'pdf.nii.gz', 3, 240, 1, numSamples);

	%run tracker sh command
    CMD=['contrack_gen.glxa64 -i ' ctrparamsFile ' -p ' outputDir filesep filename(1:end-4) '_blobs' num2str(blobs(blobIDi)) '_' num2str(blobs(blobIDj)) '.pdb'];
	system(CMD); 
    %Save output as a pdb file -- all in the same directory
	
end
end

%All the results and ROIs will be saved in one directory under fibers/conTrack
%You will need to score them afterwards. E.g., 
%   contrack_score.glxa64 -i ctrSampler.txt -p scoredFgOut_top50.pdb --thresh 50 --sort fgIn.pdb 

return

%Connectome data: perform this tractography for four networks
%1. DMNs (4 nodes) of RB and WS
%2. SALIENCE (3) nodes
%Note: because we are also interested in the interactions between DMN and
%SALIENCE, we combine the two blob files into one (thereby obtaining 7 ROIs and searching (7*7-7)/2=24 pairs of ROIs). 

%XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx
%Run on DMN
wsdmn='/biac3/wandell5/data/Connectome/ws090912/fmri/Resting/ica_unnormalized_corrected/melodic_IC_acpc_IC10_DMN/melodic_IC_acpc_IC10_DMNthr5cluster2000.nii.gz'
cd('/biac3/wandell5/data/Connectome/ws090930/dti150/'); 
dt6=dtiLoadDt6('dt6.mat'); 
ctrConnectMultipleROIs(dt6, wsdmn); %Cuz rbblob now has both salience and DMN

rbdmn='/biac3/wandell5/data/Connectome/rb090930/fmri/Resting/ica_unnormalized_corrected/melodic_IC_acpc_IC6_corticalDMN/melodic_IC_acpc_IC6_corticalDMNthr5cluster2000.nii.gz'
cd('/biac3/wandell5/data/Connectome/rb090930/dti150/'); 
dt6=dtiLoadDt6('dt6.mat'); 
ctrConnectMultipleROIs(dt6, rbdmn)


%SCORE DMN
thresh=50; %Of 5000
%contrackOut='/biac3/wandell5/data/Connectome/ws090930/fibers/conTrack'; 
contrackOut='/biac3/wandell5/data/Connectome/rb090930/fibers/conTrack'; 
%dmn='/biac3/wandell5/data/Connectome/ws090912/fmri/Resting/ica_unnormalized_corrected/melodic_IC_acpc_IC10_DMN/melodic_IC_acpc_IC10_DMNthr5cluster2000.nii.gz'
dmn='/biac3/wandell5/data/Connectome/rb090930/fmri/Resting/ica_unnormalized_corrected/melodic_IC_acpc_IC6_corticalDMN/melodic_IC_acpc_IC6_corticalDMNthr5cluster2000.nii.gz'

[pathstr, file, ext]=fileparts(dmn); 
here=pwd; 
cd(contrackOut); 
k=dir([file(1:end-4) '*']);
for fileID=1:length(k)
inputPdb=k(fileID).name;
ctrFile=['ctrScript_' inputPdb(1:end-4) '.txt'];
scoredFgOut_top1percentpdb=[inputPdb(1:end-4) 'top' num2str(thresh) '.pdb']; 
CMD=['contrack_score.glxa64 -i ' ctrFile ' -p '  scoredFgOut_top1percentpdb ' --thresh ' num2str(thresh) ' --sort ' inputPdb];
system(CMD); 
end


%XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx
%Run on Salience network
%rbsalience=('/biac3/wandell5/data/Connectome/rb090930/fmri/Resting/ica_unnormalized_corrected/melodic_IC_acpc_IC27_salience/melodic_IC_acpc_IC27_saliencethr4cluster1000.nii.gz'); 
%cd('/biac3/wandell5/data/Connectome/rb090930/dti150/'); 
%dt6=dtiLoadDt6('dt6.mat'); 
%ctrConnectMultipleROIs(dt6, rbsalience)

%wssalience=('/biac3/wandell5/data/Connectome/ws090912/fmri/Resting/ica_unnormalized_corrected/melodic_IC_acpc_IC26_salience/melodic_IC_acpc_IC26_saliencethr3cluster1000.nii.gz');
%cd('/biac3/wandell5/data/Connectome/ws090930/dti150/'); 
%dt6=dtiLoadDt6('dt6.mat'); 
%ctrConnectMultipleROIs(dt6, wssalience); %Cuz rbblob now has both salience and DMN
