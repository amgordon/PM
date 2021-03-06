function par_makespec(subpar)
% function par_makespec(subpar)
% makes spec mask
% 
% subpar refers to either the subject number (in string notation) or 
% the par struct generated by par = par_params(subject)
% 
% jbh 7/23/08

%NOTE:  This Curre
origdir = pwd;

% ---load par params if need be---

if isstruct(subpar) % if it is par_params struct
    par = subpar;
else % assume subject string
    par = par_params(subpar);
end

% make specmask...
fprintf('---Specmask for %s---\n',par.substr);

graywrimg = par.graywrimg;
grwrflags = par.specwrflags;
[grpth,grnm] = fileparts(graywrimg);
grmatname        = fullfile(grpth,[grnm '_sn.mat']);

grsegs = par.grsegs;
maskimg = par.maskimg;
wmaskimg = par.wmaskimg;
smaskimg = par.smaskimg;
tswmaskimg = par.tswmaskimg;
tsmaskimg = par.tsmaskimg;
twmaskimg = par.twmaskimg;
addsegs = par.addsegs;
maskthresh = par.maskthresh;
% add segmented stuff
%spm_imcalc_ui(grsegs,maskimg,addsegs);
spm_imcalc_ui(par.graywrimg,maskimg,'i1')

% norm mask
%spm_write_sn(maskimg, grmatname,grwrflags);

% smooth mask
spm_smooth(maskimg,smaskimg,par.specsmooth);

% use threshold (truncate)
spm_imcalc_ui(smaskimg,tsmaskimg,maskthresh);


fprintf('---Specmask COMPLETED for %s---\n',par.substr);



cd(origdir);