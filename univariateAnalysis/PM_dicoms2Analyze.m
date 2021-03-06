function PM_funcDicoms2Analyze(subpar)
%
% convert dicom functional images into analyze images, move them into
% appropriate directories, and name them something sensible
% 
% alan gordon, 3/21/11


origdir = pwd;
% ---load par params if need be---
if isstruct(subpar) % if it is par_params struct
    par = subpar;
else % assume subject string
    par = par_params(subpar);
end

% which directories contain functional dicoms of interest?
d = dir(fullfile(par.rawdir, '*EPItrig*'));


%dotFiles = cell2mat(cellfun(@(x) x(1)=='.', d, 'UniformOutput', false));
%d(find(dotFiles)) = []; %remove hidden files that are prepended with dots.

%for all dicom dirctories
for i = 1:length(d)
    
    
    cd (fullfile(par.rawdir, d(i).name));
    
    pdcms = dir('*.dcm');
    P = vertcat(pdcms.name);
    
    
    
    %read dicom headers
    display(sprintf ('reading dicom headers for run%s', num2str(i)));
    dcmhdrs = spm_dicom_headers(P);
    
    %convert dicoms to analyze format, write into current dir
    display(sprintf ('converting dicoms for run%s', num2str(i)));
    spm_dicom_convert(dcmhdrs);
    
    par.thisfuncdir = fullfile(par.funcdir, ['scan' prepend(num2str(i))]);
    
    if ~exist(par.thisfuncdir)
        mkdir(par.thisfuncdir);
    end
    
    %move newly-created analyze images to appropriate functional directory
    system(['mv *.hdr ' par.thisfuncdir]);
    system(['mv *.img ' par.thisfuncdir]);
    
    
    
    cd(par.thisfuncdir);
    
    d2 = dir('*.img');
    
    %rename each image 'scan##.V###' rather than their ponderous default
    %names
    display(sprintf ('renaming dicoms for run%s', num2str(i)));
    
    for j = 1:length(d2)
        v = spm_vol(d2(j).name);
        
        vol = spm_read_vols(v);
        
        v.fname = ['scan' prepend(num2str(i)) '.V' prepend(num2str(j),3) '.img'];
        
        spm_write_vol(v, vol);
        
    end
    
    %remove the default names
    system('rm sA*');
end