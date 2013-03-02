function par_makemoveanat(subpar)
% function parMakeMoveAnat(subpar)
% Makes anatomy from dicom and moves to anat dir
%
% Subpar refers to either the subject number (in string notation) or
% the par struct generated by par = par_params(subject)
%
% SPM5 tends to produce anatomies that are not aligned with the functional
% data for reasons unknown.  Coregistration later on seems to take care of
% this, although it would be nice to know why this is the case.
%
%  jbh 3/18/08
%  edited to use spm5 instead of dcm2nii-- 7/22/08

currDir = pwd;

% ---load par params if need be---

if isstruct(subpar) % if it is par_params struct
    par = subpar;
else % assume subject string
    par = par_params(subpar);
end

cd(par.anatdir);

% dcm dirs
dcmdirs = dir('0*'); % assumes directories named after slot they were in Rx.. no more than 99...
andir{1} = fullfile(par.anatdir,'003');  %ASSUMING '003' IS WHERE INPLANES ARE
andir{2} = fullfile(par.anatdir, dcmdirs(end).name);  %ASSUMING HI RES IS LAST SCAN IN DIRECTORY!!!!

if strcmp(andir{1},andir{2}) % no hi-res...
    error('No Hi-res found, create anat manually!');
    % this is a lame way of procrastinating using inplane instead of hi-res;
    % should be easy to implement, but want to think about it more
end

for ll = 1:length(andir)
    cd(andir{ll});
    dcmnames = dir('*dcm'); % uses all dcms in the directory
    %     built-in accuracy check
    if (ll == 1 && length(dcmnames) ~= par.numslice); error('Anat/Func mismatch!');end

    dcmptrs = horzcat(repmat([pwd '/'], length(dcmnames), 1), vertcat(dcmnames.name));
    hdr = spm_dicom_headers(dcmptrs);
    spm_dicom_convert(hdr,'all','flat','img');

    %     prepend/move anat files... leaves behind dicom_headers.mat, which is
    %     perhaps useless?
    if ll == 1
        mvtofile = par.inplaneimg;
    elseif ll == 2
        mvtofile = par.hiresimg;
    end
    system(['mv *1.img ' mvtofile]);
    system(['mv *1.hdr ' [mvtofile(1:end-3) 'hdr']]);
end

cd(currDir);