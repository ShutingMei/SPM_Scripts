function matlabbatch = Batch_1stLevel(Funcpath,Savepath, SPMpath, Design)
%% 1st Level                                          Shuting Mei
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
run = length(Funcpath);
matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_cd.dir = {Savepath};
%% Prepare files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% functional data %%%%%%%%%%%%%%%%%%%%%%%%%%%
matlabbatch{2}.cfg_basicio.file_dir.file_ops.cfg_named_file.name = 'FunctionalData';
for r = 1:run
    filt = '^swa.*nii$';
    frames = inf;
    volumes = spm_select('ExtList',Funcpath{r},filt,frames);
    volumes_files = fullfile(Funcpath{r},cellstr(volumes));
    matlabbatch{2}.cfg_basicio.file_dir.file_ops.cfg_named_file.files(r) = {volumes_files}';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%% multicondtion (onset) data %%%%%%%%%%%%%%%%%%%%
for r = 1:run
    filt = '^onset.*mat$';
    multiconditions =  spm_select('List',Funcpath{r},filt);
    multiconditions_files{r} = fullfile(Funcpath{r},cellstr(multiconditions));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%% head motion data (rp*.txt) %%%%%%%%%%%%%%%%%%%%	
for r = 1:run
    filt = '^rp.*txt$';
    rp = spm_select('List',Funcpath{r},filt);
    headmotion_file{r} = fullfile(Funcpath{r},cellstr(rp));
end

%% fMRI model specification
matlabbatch{3}.spm.stats.fmri_spec.dir = {Savepath};
matlabbatch{3}.spm.stats.fmri_spec.timing.units = 'secs'; % or 'scans'
matlabbatch{3}.spm.stats.fmri_spec.timing.RT = 2; % TR
matlabbatch{3}.spm.stats.fmri_spec.timing.fmri_t = 62; 	% slice number
matlabbatch{3}.spm.stats.fmri_spec.timing.fmri_t0 = 31; % acquisition order of reference slice, not the number of reference slice

for r = 1:run
    matlabbatch{3}.spm.stats.fmri_spec.sess(r).scans = cfg_dep(['Named File Selector: FunctionalData(',num2str(r),') - Files'], substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{r}));
    matlabbatch{3}.spm.stats.fmri_spec.sess(r).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
    matlabbatch{3}.spm.stats.fmri_spec.sess(r).multi = cellstr(multiconditions_files{r});
    matlabbatch{3}.spm.stats.fmri_spec.sess(r).regress = struct('name', {}, 'val', {});
    matlabbatch{3}.spm.stats.fmri_spec.sess(r).multi_reg = cellstr(headmotion_file{r});
    matlabbatch{3}.spm.stats.fmri_spec.sess(r).hpf = 128;
end

matlabbatch{3}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
matlabbatch{3}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0]; % time derivatives
matlabbatch{3}.spm.stats.fmri_spec.volt = 1;
matlabbatch{3}.spm.stats.fmri_spec.global = 'Scaling';
matlabbatch{3}.spm.stats.fmri_spec.mthresh = 0.8;
matlabbatch{3}.spm.stats.fmri_spec.mask = {[SPMpath,'\tpm\mask_ICV.nii,1']};
matlabbatch{3}.spm.stats.fmri_spec.cvi = 'AR(1)';
	
%% Model estimation
matlabbatch{4}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{4}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{4}.spm.stats.fmri_est.method.Classical = 1;

%% Contrast management
matlabbatch{5}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
for ci = 1:length(Design.name)
    matlabbatch{5}.spm.stats.con.consess{ci}.tcon.name = Design.name{ci};
    matlabbatch{5}.spm.stats.con.consess{ci}.tcon.weights = Design.weights{ci};
    matlabbatch{5}.spm.stats.con.consess{ci}.tcon.sessrep = 'replsc';    
end
matlabbatch{5}.spm.stats.con.delete = 1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author:
%
%   (c) 21-Aug-2021 Shuting Mei
%   contact: Meishuting@stu.pku.edu.cn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
