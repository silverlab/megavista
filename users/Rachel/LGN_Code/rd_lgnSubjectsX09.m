function [subjectDirs3T subjectDirs7T] = rd_lgnSubjectsX09
%
% [subjectDirs3T subjectDirs7T] = rd_lgnSubjectsX09
%
% gets subject directory info for all the subjects

subjectDirs3T = {'AV_20111117_session', 'AV_20111117_n', 'ROIX09';
                'AV_20111128_session', 'AV_20111128_n', 'ROIX09'; 
                'CG_20120130_session', 'CG_20120130_n_LOW', 'ROIX09'; % not making
                'CG_20120130_session', 'CG_20120130_n_HIGH', 'ROIX09';
                'RD_20120205_session', 'RD_20120205_n', 'ROIX09'};
            
subjectDirs7T = {'KS_20111212_Session', 'KS_20111212_15mm', 'ROIX09';
                'AV_20111213_Session', 'AV_20111213', 'ROIX09';
                'KS_20111214_Session', 'KS_20111214', 'ROIX09'; 
                'RD_20111214_Session', 'RD_20111214', 'ROIX09';
                'KS_20111212_Session', 'KS_20111212_125mm', 'ROIX09';
                'MN_20120806_Session', 'MN_20120806', 'ROIX09'; % not making
                'SB_20120807_Session', 'SB_20120807', 'ROIX09';
                'JN_20120808_Session', 'JN_20120808', 'ROIX09'; % GLM-defined ROI
                'RD_20120809_Session', 'RD_20120809_axial', 'ROIX09'; % not making
                'MN_20120806_Session', 'MN_20120806_recon2_flipLR', 'ROIX09'}; % not making