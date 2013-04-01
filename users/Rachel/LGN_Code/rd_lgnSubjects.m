function [subjectDirs3T subjectDirs7T] = rd_lgnSubjects
%
% [subjectDirs3T subjectDirs7T] = rd_lgnSubjects
%
% gets subject directory info for all the subjects

subjectDirs3T = {'AV_20111117_session', 'AV_20111117_n', 'ROIX01';
                'AV_20111128_session', 'AV_20111128_n', 'ROIX01/Runs1-9'; % all runs
                'CG_20120130_session', 'CG_20120130_n_LOW', 'ROIX01';
                'CG_20120130_session', 'CG_20120130_n_HIGH', 'ROIX01';
                'RD_20120205_session', 'RD_20120205_n', 'ROIX01'};
            
subjectDirs7T = {'KS_20111212_Session', 'KS_20111212_15mm', 'ROIX01';
                'AV_20111213_Session', 'AV_20111213', 'ROIX01';
                'KS_20111214_Session', 'KS_20111214', 'ROIX02';
                'RD_20111214_Session', 'RD_20111214', 'ROIX01';
                'KS_20111212_Session', 'KS_20111212_125mm', 'ROIX01';
                'MN_20120806_Session', 'MN_20120806', 'Runs1-5/ROIX02'; % all runs, GLM-defined ROI
                'SB_20120807_Session', 'SB_20120807', 'ROIX01';
                'JN_20120808_Session', 'JN_20120808', 'ROIX01'; % GLM-defined ROI
                'RD_20120809_Session', 'RD_20120809_axial', 'ROIX01';
                'MN_20120806_Session', 'MN_20120806_recon2_flipLR', 'ROIX01'}; % GLM-defined ROI