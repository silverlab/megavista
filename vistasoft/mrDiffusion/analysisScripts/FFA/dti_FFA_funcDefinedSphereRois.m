function dti_FFA_funcDefinedSphereRois

% Usage: dti_FFA_funcDefinedSphereRois
%
% By: DY 2008/03/31
%
% This script is based on dti_OTS_funcDefinedSphereRois. It will go through
% a list of subjects load their dt6 files, and call DTI_FFA_MAKESPHERES and
% DTI_FFA_SETROIVARIABLES.
%
% Current implementation is to generate these fibers for FFA, LOf, STSf
%
% Then, the script will restrict these fibers to those that also intersect
% other ROIs. 
%
% Modification: we should really track fibers for the entire hemisphere
% first (see DTI_FFA_TRACKHEMISPHERES), so now I load these fibers and
% perform all the intersections with various ROIs. Also, in the case that
% I'm running the script for the second time, the script checks to see if
% an ROI exists and if it does, loads it rather than creates it from
% scratch.
%
% DY 2008/04/10

% Set directories
if ispc
    dtiDir = 'W:\projects\Kids\dti\';
%     dtiDir = 'S:\reading_longitude'; % Use for wandell lab data
else
    dtiDir = '/biac1/kgs/projects/Kids/dti/';
end
todoDirs = {fullfile('adults','3T_AP','acg_38yo_010108'),...
    fullfile('adults','gg_37yo_091507_FreqDirLR'),...
    fullfile('adolescents','3T_AP','ar_12yo_121507'),...
    fullfile('adolescents','3T_AP','dw_14yo_102007'),...
    fullfile('adolescents','3T_AP','is_16yo_120907'),...
    fullfile('adolescents','3T_AP','kwl_14yo_010508'),...
    fullfile('adolescents','kll_18yo_011908_FreqDirLR')};

R_ROIs{1}={'R_FFA_MCvOJIO_p3d.mat','R_LOf_MCvOJIO_p3d.mat',''};
R_ROIs{2}={'rFFA_MCvOJIO_p3.mat','rLOf_MCvOJIO_p3.mat','rSTS_MCvOJIO_p3.mat'};
R_ROIs{3}={'RFFA_MCvOJIO_p3d.mat','RLO_MCvOJIO_p3d.mat','RSTS_MCvOJIO_p3d.mat'};
R_ROIs{4}={'RFFA_MCvOJIO_p3d.mat','RLO_MCvOJIO_p3d.mat','RSTS_MCvOJIO_p3d.mat'};    
R_ROIs{5}={'RFFA_MCvOJIO_p3d.mat','RLO_MCvOJIO_p3d.mat',''};
R_ROIs{6}={'RFFA_MCvOJIO_p3d.mat','RLO_MCvOJIO_p3d.mat','RSTS_MCvOJIO_p2d.mat'};
R_ROIs{7}={'RFFA_MCvOJIO_p3d.mat','RLO_MCvOJIO_p3d.mat',''};

L_ROIs{1}={'L_FFA_MCvOJIO_p3d.mat','L_LOf_MCvOJIO_p3d.mat','L_pSTSf_MCvOJIO_p3d.mat'};
L_ROIs{2}={'','',''};
L_ROIs{3}={'LFFA_MCvOJIO_p3d.mat','LLO_MCvOJIO_p2d.mat',''};
L_ROIs{4}={'LFFA_MCvOJIO_p3d.mat','LLO_MCvOJIO_p3d.mat','LSTS_MCvOJIO_p3d.mat'};
L_ROIs{5}={'LFFA_MCvOJIO_p3d.mat','LLO_MCvOJIO_p3d.mat','LSTS_MCvOJIO_p3d.mat'};
L_ROIs{6}={'LFFA_MCvOJIO_p3d.mat','LpFus_MCvOJIO_p2d.mat','LSTS_MCvOJIO_p2d.mat'};
L_ROIs{7}={'LFFA_MCvOJIO_p3d.mat','LLO_MCvOJIO_p3d.mat',''};


% Tracking parameters
trackr = 20; % for sphere
endptr = 10; % for endpoints
intersectr = 10; % for FFA+LO, or FFA+STS, etc. 

% Loops through each of the to-do directories
for ii=1:length(todoDirs)
    thisDir = fullfile(dtiDir,todoDirs{ii},'dti30');
    fname = fullfile(thisDir,'dt6.mat');
    disp(['Processing ' fname '...']); %displays a string on the screen
    dt = dtiLoadDt6(fname); % this will load the dt6 file
    roiDir = fullfile(thisDir,'ROIs','functional');
    
    % Create fiber directory if it doesn't exist
    fiberDir = fullfile(thisDir,'fibers','functional');
    if (~isdir(fiberDir))
        mkdir(fiberDir);
    end
    
    % Set ROI files to variables
    rffa=fullfile(roiDir,R_ROIs{ii}{1});
    rlo=fullfile(roiDir,R_ROIs{ii}{2});
    rsts=fullfile(roiDir,R_ROIs{ii}{3});
    lffa=fullfile(roiDir,L_ROIs{ii}{1});
    llo=fullfile(roiDir,L_ROIs{ii}{2});
    lsts=fullfile(roiDir,L_ROIs{ii}{3});
    
    % Process RFFA + intersections with RLO/RSTS
    [intersect,roiNames]=dti_FFA_setRoiVariables(rffa,'RFFA',rlo,'RLOf',rsts,'RSTSf');
    if(exist(rffa,'file') && strcmp(rffa(end-3:end),'.mat'))
        dti_FFA_makeSpheres(dt,rffa,roiNames,endptr,trackr,roiDir,fiberDir,intersect,intersectr);
    end
    clear roiNames intersect
    
    % Process RLO + intersections with RFFA/RSTS
    [intersect,roiNames]=dti_FFA_setRoiVariables(rlo,'RLOf',rffa,'RFFA',rsts,'RSTSf');
    if(exist(rlo,'file') && strcmp(rlo(end-3:end),'.mat'))
        dti_FFA_makeSpheres(dt,rlo,roiNames,endptr,trackr,roiDir,fiberDir,intersect,intersectr);
    end
    clear roiNames intersect
    
    % Process RSTS + intersections with RFFA/RLO
    [intersect,roiNames]=dti_FFA_setRoiVariables(rsts,'RSTSf',rffa,'RFFA',rlo,'RLOf');
    if(exist(rsts,'file') && strcmp(rsts(end-3:end),'.mat'))
        dti_FFA_makeSpheres(dt,rsts,roiNames,endptr,trackr,roiDir,fiberDir,intersect,intersectr);
    end
    clear roiNames intersect

    % Process LFFA + intersections with LLO/LSTS
    [intersect,roiNames]=dti_FFA_setRoiVariables(lffa,'LFFA',llo,'LLOf',lsts,'LSTSf');
    if(exist(lffa,'file') && strcmp(lffa(end-3:end),'.mat'))
        dti_FFA_makeSpheres(dt,lffa,roiNames,endptr,trackr,roiDir,fiberDir,intersect,intersectr);
    end
    clear roiNames intersect

    % Process LLO + intersections with LFFA/LSTS
    [intersect,roiNames]=dti_FFA_setRoiVariables(llo,'LLOf',lffa,'LFFA',lsts,'LSTSf');
    if(exist(llo,'file') && strcmp(llo(end-3:end),'.mat'))
        dti_FFA_makeSpheres(dt,llo,roiNames,endptr,trackr,roiDir,fiberDir,intersect,intersectr);
    end
    clear roiNames intersect

    % Process LSTS + intersections with LFFA/LSTS
    [intersect,roiNames]=dti_FFA_setRoiVariables(lsts,'LSTSf',lffa,'LFFA',llo,'LLOf');
    if(exist(lsts,'file') && strcmp(lsts(end-3:end),'.mat'))
        dti_FFA_makeSpheres(dt,lsts,roiNames,endptr,trackr,roiDir,fiberDir,intersect,intersectr);
    end
    clear roiNames intersect
    
end





    