function matlabbatch = Batch_PreProcess(Funcpath, T1path, SPMpath)
%% PreProcessing                                     Shuting Mei
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Coregister: ref = mean image of func data; source = T1; other = empty
% or you can try [other = reslice or realign data] to find a perfect model
%
% Normalise (func): resample = realign data
% or you can try [resample = coregister data] to find a perfect model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% determine the number of step:
run = length(Funcpath);
s = (run+1:run+6);
%% Slice timing:
for r = 1: run
    filt = '^4D.nii$';
    frames = inf;
    volumes = spm_select('ExtList',Funcpath{r},filt,frames);  %%%4d   list是3d
    volumesDir = fullfile(Funcpath{r},cellstr(volumes));
    matlabbatch{r}.spm.temporal.st.scans = {volumesDir};
    % multibands for Siemens
    % if the data were collected by GE, the slice order should be [1 3
    % 5...31 2 4 6 ...32]
    dcm_file='F:\3_Data\RIP_v4_Selfwords\Raw_post\RIP2001_ZhaoKe\2005-sms_bold_2mm_words1\RIP2001_ZhaoKe-2005-sms_bold_2mm_words1-00001';
    Slice0=dicominfo(dcm_file);
    SliceOrder=Slice0.Private_0019_1029;
    s0=sort(SliceOrder);
    refSlice =s0(31); % the middle one should be reference
    
    matlabbatch{r}.spm.temporal.st.nslices = 62;
    matlabbatch{r}.spm.temporal.st.tr = 2;
    matlabbatch{r}.spm.temporal.st.ta = 1.96774193548387;
    matlabbatch{r}.spm.temporal.st.so = SliceOrder;
    matlabbatch{r}.spm.temporal.st.refslice = refSlice;
    matlabbatch{r}.spm.temporal.st.prefix = 'a';
end

%% Realign: Estimate & Reslice
for r = 1:run
    matlabbatch{s(1)}.spm.spatial.realign.estwrite.data{r}(1) = cfg_dep('Slice Timing: Slice Timing Corr. Images (Sess 1)', substruct('.','val', '{}',{r}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
end
matlabbatch{s(1)}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
matlabbatch{s(1)}.spm.spatial.realign.estwrite.eoptions.sep = 4;
matlabbatch{s(1)}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
matlabbatch{s(1)}.spm.spatial.realign.estwrite.eoptions.rtm = 1;
matlabbatch{s(1)}.spm.spatial.realign.estwrite.eoptions.interp = 2;
matlabbatch{s(1)}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
matlabbatch{s(1)}.spm.spatial.realign.estwrite.eoptions.weight = '';
matlabbatch{s(1)}.spm.spatial.realign.estwrite.roptions.which = [2 1];
matlabbatch{s(1)}.spm.spatial.realign.estwrite.roptions.interp = 4;
matlabbatch{s(1)}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
matlabbatch{s(1)}.spm.spatial.realign.estwrite.roptions.mask = 1;
matlabbatch{s(1)}.spm.spatial.realign.estwrite.roptions.prefix = 'r';

%% Coregister: Estimate
folder=dir(fullfile(T1path,'s*.nii'));
matlabbatch{s(2)}.spm.spatial.coreg.estimate.ref(1) = cfg_dep('Realign: Estimate & Reslice: Mean Image', substruct('.','val', '{}',{s(1)}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','rmean'));
matlabbatch{s(2)}.spm.spatial.coreg.estimate.source = {strcat(fullfile(T1path,folder.name),',1')};
% matlabbatch{s(2)}.spm.spatial.coreg.estimate.other(1) = cfg_dep('Realign: Estimate & Reslice: Realigned Images (Sess 1)', substruct('.','val', '{}',{s(1)}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{1}, '.','cfiles'));
% matlabbatch{s(2)}.spm.spatial.coreg.estimate.other(2) = cfg_dep('Realign: Estimate & Reslice: Realigned Images (Sess 2)', substruct('.','val', '{}',{s(1)}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{2}, '.','cfiles'));
matlabbatch{s(2)}.spm.spatial.coreg.estimate.other(1) = {''};
matlabbatch{s(2)}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
matlabbatch{s(2)}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
matlabbatch{s(2)}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{s(2)}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];

%% Segment
folder=dir(fullfile(T1path,'s*.nii'));
matlabbatch{s(3)}.spm.spatial.preproc.channel.vols(1) = {strcat(fullfile(T1path,folder.name),',1')};
matlabbatch{s(3)}.spm.spatial.preproc.channel.biasreg = 0.001;
matlabbatch{s(3)}.spm.spatial.preproc.channel.biasfwhm = 60;
matlabbatch{s(3)}.spm.spatial.preproc.channel.write = [0 1];
matlabbatch{s(3)}.spm.spatial.preproc.tissue(1).tpm = {[SPMpath,'\tpm\TPM.nii,1']};
matlabbatch{s(3)}.spm.spatial.preproc.tissue(1).ngaus = 1;
matlabbatch{s(3)}.spm.spatial.preproc.tissue(1).native = [1 0];
matlabbatch{s(3)}.spm.spatial.preproc.tissue(1).warped = [0 0];
matlabbatch{s(3)}.spm.spatial.preproc.tissue(2).tpm = {[SPMpath,'\tpm\TPM.nii,2']};
matlabbatch{s(3)}.spm.spatial.preproc.tissue(2).ngaus = 1;
matlabbatch{s(3)}.spm.spatial.preproc.tissue(2).native = [1 0];
matlabbatch{s(3)}.spm.spatial.preproc.tissue(2).warped = [0 0];
matlabbatch{s(3)}.spm.spatial.preproc.tissue(3).tpm = {[SPMpath,'\tpm\TPM.nii,3']};
matlabbatch{s(3)}.spm.spatial.preproc.tissue(3).ngaus = 2;
matlabbatch{s(3)}.spm.spatial.preproc.tissue(3).native = [1 0];
matlabbatch{s(3)}.spm.spatial.preproc.tissue(3).warped = [0 0];
matlabbatch{s(3)}.spm.spatial.preproc.tissue(4).tpm = {[SPMpath,'\tpm\TPM.nii,4']};
matlabbatch{s(3)}.spm.spatial.preproc.tissue(4).ngaus = 3;
matlabbatch{s(3)}.spm.spatial.preproc.tissue(4).native = [1 0];
matlabbatch{s(3)}.spm.spatial.preproc.tissue(4).warped = [0 0];
matlabbatch{s(3)}.spm.spatial.preproc.tissue(5).tpm = {[SPMpath,'\tpm\TPM.nii,5']};
matlabbatch{s(3)}.spm.spatial.preproc.tissue(5).ngaus = 4;
matlabbatch{s(3)}.spm.spatial.preproc.tissue(5).native = [1 0];
matlabbatch{s(3)}.spm.spatial.preproc.tissue(5).warped = [0 0];
matlabbatch{s(3)}.spm.spatial.preproc.tissue(6).tpm = {[SPMpath,'\tpm\TPM.nii,6']};
matlabbatch{s(3)}.spm.spatial.preproc.tissue(6).ngaus = 2;
matlabbatch{s(3)}.spm.spatial.preproc.tissue(6).native = [0 0];
matlabbatch{s(3)}.spm.spatial.preproc.tissue(6).warped = [0 0];
matlabbatch{s(3)}.spm.spatial.preproc.warp.mrf = 1;
matlabbatch{s(3)}.spm.spatial.preproc.warp.cleanup = 1;
matlabbatch{s(3)}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
matlabbatch{s(3)}.spm.spatial.preproc.warp.affreg = 'mni';
matlabbatch{s(3)}.spm.spatial.preproc.warp.fwhm = 0;
matlabbatch{s(3)}.spm.spatial.preproc.warp.samp = 3;
matlabbatch{s(3)}.spm.spatial.preproc.warp.write = [0 1];

%% Normalise: Write (func)
matlabbatch{s(4)}.spm.spatial.normalise.write.subj.def(1) = cfg_dep('Segment: Forward Deformations', substruct('.','val', '{}',{s(3)}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','fordef', '()',{':'}));
for r = 1:run
matlabbatch{s(4)}.spm.spatial.normalise.write.subj.resample(r) = cfg_dep('Realign: Estimate & Reslice: Realigned Images (Sess 1)', substruct('.','val', '{}',{s(1)}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{r}, '.','cfiles'));
% matlabbatch{s(4)}.spm.spatial.normalise.write.subj.resample(1) = cfg_dep('Coregister: Estimate: Coregistered Images', substruct('.','val', '{}',{s(2)}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','cfiles'));
end
matlabbatch{s(4)}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                          78 76 85];
matlabbatch{s(4)}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
matlabbatch{s(4)}.spm.spatial.normalise.write.woptions.interp = 4;

%% Normalise: Write (anat)
matlabbatch{s(5)}.spm.spatial.normalise.write.subj.def(1) = cfg_dep('Segment: Forward Deformations', substruct('.','val', '{}',{s(3)}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','fordef', '()',{':'}));
matlabbatch{s(5)}.spm.spatial.normalise.write.subj.resample(1) = cfg_dep('Segment: Bias Corrected (1)', substruct('.','val', '{}',{s(3)}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','channel', '()',{1}, '.','biascorr', '()',{':'}));
matlabbatch{s(5)}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                          78 76 85];
matlabbatch{s(5)}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
matlabbatch{s(5)}.spm.spatial.normalise.write.woptions.interp = 4;

%% Smooth
matlabbatch{s(6)}.spm.spatial.smooth.data(1) = cfg_dep('Normalise: Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{s(4)}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
matlabbatch{s(6)}.spm.spatial.smooth.fwhm = [4 4 4]; % resolution*2
matlabbatch{s(6)}.spm.spatial.smooth.dtype = 0;
matlabbatch{s(6)}.spm.spatial.smooth.im = 0;
matlabbatch{s(6)}.spm.spatial.smooth.prefix = 's';

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author:
%
%   (c) 20-Aug-2021 Shuting Mei
%   contact: Meishuting@stu.pku.edu.cn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%