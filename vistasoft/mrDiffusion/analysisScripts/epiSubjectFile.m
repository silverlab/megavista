function subjectFile = epiSubjectFile(dataDir,sNumber,iStatus,varargin)%%  This script is a little database about the different subjects in the%  epilepsy scans.%%  We have post-ictal and inter-ictal scans on four subjects.  The subject%  is identified as sNumber.  The ictal status is identified by iStatus.%%Example:%  epiSubjectFile([], 1,'postictal')%  epiSubjectFile([], 2,'postictal',1)%  epiSubjectFile([], 3,'postictal')%if ieNotDefined('dataDir'), dataDir = '/biac2/wandell2/data/Epilepsy' ; endswitch lower(iStatus)    case 'postictal'        if sNumber == 1            % Patient, AH            % epiSubjectFile([],1,'postictal');            subjectFile = fullfile(dataDir, '1-ah','ahPI060114','ahPI060114_dt6');        elseif sNumber == 2            % Patient, HP            % epiSubjectFile([], 2,'postictal',1);            % This subject had two postictal scans.            if varargin{1} == 1                subjectFile = fullfile(dataDir,'2-hp','hpPI060304','hpPI060304-dti1','hpPI060304_dti1_dt6');            elseif varargin{2} == 2                % second dti - s/p seizure in scanner                subjectFile = fullfile(dataDir,'2-hp','hpPI060304','hpPI060304-dti2','hpPI060304_dti2_dt6');            end        elseif sNumber == 3            % Patient, SK            subjectFile = fullfile(dataDir,'3-sk','skPI072706','skPI072706_dt6');        elseif sNumber == 4            % Patient, JW            subjectFile = fullfile(dataDir,'4-jw','jwPI073006','jwPI073006_dt6');        else            error('Unknown subject')        end    case 'interictal'        if sNumber == 1            %Patient, AH            subjectFile = fullfile(dataDir,'1-ah','ahII060116','ahII060116_dt6');        elseif sNumber == 2            if varargin{1} == 1                subjectFile = fullfile(dataDir,'2-hp','hpII060307','hpII060307_dt6');            elseif varargin{2} == 2                subjectFile = fullfile(dataDir,'2-hp','hpII060307','hpII060307_axial_dt6');            end        elseif sNumber == 3            % Patient, SK - no interictal scan yet            % When ready, place it here ... subjectFile = '/biac2/wandell2/data/Epilepsy/3-sk/';            subjectFile = '';        elseif sNumber == 4            % Patient, JW            subjectFile = fullfile(dataDir,'4-jw','jwII080906','jwII080906_dt6');        else            error('Unknown subject')        end            case 'control'        if sNumber == 1            %control subject BW, not in template or atlas            subjectFile =  '/biac2/wandell2/data/reading_longitude/dti_adults/additional_runs/bw040806/bw040806_dt6';            %subjectFile =  '\\white.stanford.edu\biac2-wandell2\data\reading_longitude\dti_adults\additional_runs\bw040806\bw040806_dt6';        else            error('Unknown subject')        end            otherwise        error('Unknown ictal status')endreturn;