% This script sorts by age and PA
%
% Modified from 'dtiMakeAverageBrainsSubgroups_20060818'
%
% By: Davie Yoon
% September 7, 2006

% Create a list (SUBCODELIST) of all subjects
inDir = 'Y:\data\reading_longitude\templates\child_new\SIRL54warp3';%This is for Windows!!!   check this is updated
cd(inDir); d = dir(fullfile(inDir, ['*_sn*' '.mat'])); files = {d.name};
nSubs = length(files); index = [1:nSubs]';
for(ii=1:nSubs)
    s = files{ii};
    if(~isempty([strfind(s,filesep) strfind(s,'\') strfind(s,'/') strfind(s,'0')]))
        [p,s,e] = fileparts(s);
        us = findstr('0',s);
    else
        us = findstr('_',s);
    end
    subCodeList{ii} = s(1:us(1)-1);
end

% Get behavioral data (BEHAVEDATA) for all subjects
[behaveData, colNames] = dtiGetBehavioralData(subCodeList);

% Matrices with age (ALLAGE) and PA scores (ALLPA)
allAge=behaveData(:,2);
allSex=behaveData(:,1);
allPA=behaveData(:,8);
allRaw=behaveData(:,22);

% Indexing by age, sex, PA
age7 = index(behaveData(:,2)<8);
age8 = index(behaveData(:,2)>8 & behaveData(:,2)<9);
age9 = index(behaveData(:,2)>9 & behaveData(:,2)<10);
age10 = index(behaveData(:,2)>10 & behaveData(:,2)<11);
age11 = index(behaveData(:,2)>11 & behaveData(:,2)<12);
age12 = index(behaveData(:,2)>12 & behaveData(:,2)<13);
female = index(behaveData(:,1)==0);
male = index(behaveData(:,1)==1);
PAlow = index(behaveData(:,8)<95);
PAhigh = index(behaveData(:,8)>105);
Raw_8 = index(behaveData(:,22)>4.5 & behaveData(:,22)<9); % n=12
Raw_12 = index(behaveData(:,22)>8.5 & behaveData(:,22)<13); % n=7
Raw_16 = index(behaveData(:,22)>12.5 & behaveData(:,22)<17); % n=12
Raw_20 = index(behaveData(:,22)>16.5 & behaveData(:,22)<21); % n=23

% Intersected subgroups
age7lowRaw = intersect(age7,Raw_8);
age7highRaw = intersect(age7,Raw_20);
age8highRaw = intersect(age8,Raw_20);

age7lowPA = intersect(age7,PAlow); % n=2
age7lowPA_f = intersect(age7lowPA,female); % 2F
age7highPA = intersect(age7,PAhigh); % n=4
age7highPA_f = intersect(age7highPA,female); % 2F
age7highPA_m = intersect(age7highPA,female); % 2M

age8lowPA = intersect(age8,PAlow); % n=3
age8lowPA_f = intersect(age8lowPA,female); % 1F
age8lowPA_m = intersect(age8lowPA,male); % 2M
age8highPA = intersect(age8,PAhigh); % n=1
age8highPA_f = intersect(age8highPA,female); % 1F

age9lowPA = intersect(age9,PAlow); % n=7
age9lowPA_f = intersect(age9lowPA,female); % 4F
age9lowPA_m = intersect(age9lowPA,male); % 3M
age9highPA = intersect(age9,PAhigh); % n=3
age9highPA_f = intersect(age9highPA,female); % 3F

age10lowPA = intersect(age10,PAlow); %n=8
age10lowPA_f = intersect(age10lowPA,female); % 2F
age10lowPA_m = intersect(age10lowPA,male); % 6M
age10highPA = intersect(age10,PAhigh); % n=3
age10highPA_f = intersect(age10highPA,female); % 2F
age10highPA_m = intersect(age10highPA,male); % 1M

age11lowPA = intersect(age11,PAlow); %n=4
age11lowPA_m = intersect(age11lowPA,male); % 4M
age11highPA = intersect(age11,PAhigh); % n=5
age11highPA_f = intersect(age11highPA,female); % 2F
age11highPA_m = intersect(age11highPA,male); % 3M

age12lowPA = intersect(age12,PAlow); %n=1
age12lowPA_f = intersect(age12lowPA,female); % 1F

% To get exact initials, ages and PAs in each GROUP (define this!)
group = Raw_8;

subInitials = subCodeList(group);
subAges = allAge(group);
subPA = allPA(group);
subRaw = allRaw(group);
subSex = allSex(group); % F=0; M=1;

group = Raw_20;

subInitials = subCodeList(group);
subAges = allAge(group);
subPA = allPA(group);
subRaw = allRaw(group);
subSex = allSex(group); % F=0; M=1;