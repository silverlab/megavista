%Script purpose: calculate range of motion across all three functional for
% each of the primary axes for translation and rotation. Each subject has
% file name: motionparams.txt which has 6 columns of numbers. the first
% three are translation movements (x,y,z) and last three are rotation
% (pitch, roll, yaw) for each column find range of rotation (min, max and
% difference between min and max). At end of script, save the values/results,
% don't print. run on each subject. save to a read/write to excel or text
% file or matlab structure. flag those with big ranges of motion.

clear all;
clc;
close all;
final=zeros(30,6); %makes 30 row by 6 column matrix of zeros
 
% user-defined parameters:
subj= ['AC_081714'; 'AI_032814'; 'AM_052214'; 'AS_071814'; 'BI_050514'; 'CH_072314'; 'CR_060414'; 'CS_072714'; 'CT_032514'; 'DL_082214'; 'EI_030214'; 'EM_060714'; 'GD_052014'; 'GM_051914'; 'JD_090414'; 'JM_092914'; 'JV_050514'; 'KS_072014'; 'KW_051814'; 'LI_081514'; 'LS_032214'; 'MG_050414'; 'MK_032214'; 'MS_082214'; 'NL_060814'; 'PS_090314'; 'RN_081414'; 'SD_061214'; 'TT_080614'; 'YL_032714']; %add all 30 subjects here

for j = 1:30 %all 30 subjects
filename = strcat(subj(j,:),'/nifti/mc_results/motionparams.txt'); %path of folders
%save j (first row, first column) through all columns (:)
%first puts path in one place
load(filename);

for i=1:6; %for i of columns 1 through 6
    x(1,i)=max(motionparams(:,i)); %store this info in variable x: for the
    % all rows, first column (ith column), find max of the motionparams
    
    % file that is loaded above for all the rows of the 1st (ith) column
    x(2,i)=min(motionparams(:,i)); % store in x: for the second row, ith 
  
    % column, find the min of motion params for all rows, ith column
    x(3,i)=x(1,i)-x(2,i); % store in x: for the 3rd row, ith column: store 
    %the max minus the min
end

final(j,:)=x(3,:); %jth row, all columns = 3 row all corresponding columns
%filename is path, storing results in xls
%saves the variable x in a file with a filename 
%which can be found in the variable in subj at index j 

%look at each cell, and if any cell is > 3, then display the name
 if x(3,i) > 2.5000 %set threshold here (ex. 2.5)
    disp (subj) %shows subjects above this threshold in command window
 end

end
%make giant excel with all subjects having one line (of six columns
%(difference) i.e. the range
xlswrite ('results.xls',cellstr(subj),'A1:A30'); %saves to excel sheet
xlswrite ('results.xls',final,'B1:G30');
[row,col]=find(final>2.5);
subj(unique(row),:) %prevents redundancy

%graphing portion (use matlab website)
 for j=1:30
     figure('Name',subj(j,:),'NumberTitle','off')
     subplot(1,2,1)
     bar(final(j,1:3));
     ylim([0 5.5]);
     set(gca,'XTickLabel',{'x', 'y', 'z'})
     graphfilename = strcat('graphs/',subj(j,:),'.fig');
     %title(subj(j,:));
     xlabel('Translational Movements');
     ylabel('mm');
     
     subplot(1,2,2)
     bar(final(j,4:6));
     ylim([0 0.1]);
     set(gca,'XTickLabel',{'roll', 'pitch', 'yaw'})
     xlabel('Rotational Movements');
     ylabel('radians')
     
     ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');

     text(0.5, 1,strcat('\bf', subj(j,1:2),'\_',subj(j,4:9)),'HorizontalAlignment','center','VerticalAlignment', 'top')

     saveas(gcf,graphfilename);
  
 end

