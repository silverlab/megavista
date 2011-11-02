% DTI_OTS_FIBERSUMMARY
%
% Wrapper script that calls DTIFIBERSUMMARY
% Defines the two input arguments that are required
%
% Created by DY, 3/9/2007

baseDir1 = 'Y:\data\reading_longitude\dti'; % year 1 dti directory
baseDir2 = 'Y:\data\reading_longitude\dti_y2'; % year 2
f1 = {'ad040522','ajs040629','at040918','cp041009','crb040707',...
      'ctb040706','ctr040618','da040701','dh040607','dm040922','js040726',...
      'jt040717','lg041019','lj040527','mb041004','md040714','mh040630',...
      'mho040625','mm040925','pf040608','rh040630','sl040609','ss040804',...
      'sy040706','tv040928','vh040719'}; % y1 subject list
f2 = {'ad050604','ajs050621','at051008','cp051008','crb050603',...
      'ctb050603','ctr050528','da050623','dh050513','dm051009','js050611',...
      'jt050618','lg051008','lj050604','mb051014','md050621','mh050514',...
      'mho050528','mm051014','pf050514','rh050514','sl050516','ss081205',...
      'sy050604','tv051004','vh050624'}; % y2 subject list
  
% Create a subject cell array with all the subjects, y1 and y2
for hh=1:length(f1)
    fname = fullfile(baseDir1,f1{hh}, 'fibers', 'OTSproject');
    subjects{hh} = fname;
end
for hh=1:length(f2)
    fname = fullfile(baseDir2,f2{hh}, 'fibers', 'OTSproject');
    subjects{length(f2)+hh} = fname;
end

fibers = {'LOTS_RGB_CINCH.mat', 'ROTS_RGB_CINCH.mat'};

summary = dtiFiberSummary(subjects,fibers);