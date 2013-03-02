function PM_groupsetcontrasts(subpar, tsk, cnd)
% parSetContrasts(subpar)
% Sets contrasts.
% 
% subpar refers to either the subject number (in string notation) or
% the par struct generated by par = par_params(subject)
% 
% made from av_setContrasts  1/28/08 jbh
% modified to subpar format, etc, 7/24/08 jbh



origdir = pwd;


% ---load par params if need be---
if isstruct(subpar) % if it is par_params struct
    par = subpar;
else % assume subject string
    par = AG1GroupParams(subpar);
end

STAT = par.constat;

cd(par.task{tsk}.cons{cnd}.dir{1})


fprintf('\nLoading SPM...');
load SPM
fprintf('Done');

Xsize = size(SPM.xX.xKXs.X,2);

padCon = @padConWithZeros;

if par.nCovs>0
    %cnames = {[par.task{tsk}.cons{cnd}.name]; ['inv_' par.task{tsk}.cons{cnd}.name]; [par.task{tsk}.cons{cnd}.name '_byERP']; ['inv_' par.task{tsk}.cons{cnd}.name '_byERP']};
    %cvals = {[1]; [-1]; [0 1]; [0 -1]};
    cnames = {[par.task{tsk}.cons{cnd}.name '_byERP']; ['inv_' par.task{tsk}.cons{cnd}.name '_byERP']};
    cvals = {[0 1]; [0 -1]};
else
    cvals = par.task{tsk}.cons{cnd}.groupContrast;
    cnames = {[par.task{tsk}.cons{cnd}.name] ['inv_' par.task{tsk}.cons{cnd}.name]};
    %cvals = {[1]; [-1]};
end

% T-contrasts
%---------------------------------------------------------------------------



% preallocate
con_name(1:length(cnames)) = {''};
con_vals = cell(1, length(cnames));


for Tt = 1:length(cnames)

    % make names
    con_name{Tt} = cnames{Tt};

    con_vals{Tt} = cvals{Tt};

end


% put contrasts into SPM/write to file

fprintf('\nBeginning contrasts on task %s contrast %s\n', par.tasks{tsk}, par.task{tsk}.cons{cnd}.name);


cfid = fopen('conlist','wt');
%fprintf(cfid, 'Contrasts for Sub %s\nLast run on %s\n', par.substr, date);

% Loop over created contrasts
%-------------------------------------------------------------------
for k=1:length(con_vals)

    % Basic checking of contrast
    %-------------------------------------------------------------------
    [c,I,emsg,imsg] = spm_conman('ParseCon',con_vals{k},SPM.xX.xKXs,STAT);
    if ~isempty(emsg)
        disp(emsg);
        error('Error in contrast specification');
    else
        disp(imsg);
    end;

    % Fill-in the contrast structure
    %-------------------------------------------------------------------
    if all(I)
        DxCon = spm_FcUtil('Set',con_name{k},STAT,'c',c,SPM.xX.xKXs);
    else
        DxCon = [];
    end

    % Append to SPM.xCon. SPM will automatically save any contrasts that
    % evaluate successfully.
    %-------------------------------------------------------------------
    if isempty(SPM.xCon)
        SPM.xCon = DxCon;
    elseif ~isempty(DxCon)
        SPM.xCon(end+1) = DxCon;
    end
    SPM = spm_contrasts(SPM,length(SPM.xCon));
        
    fprintf(fopen('conlist','at'),'%d: %s\n%s\n\n',k, con_name{k},num2str(con_vals{k}));
end

fclose(cfid);
%copyfile('conlist',[par.logdir filesep 'conlist-' date]);

% Change back directory
cd(origdir);
fclose('all');
return;

% put in here, so I don't have to add it to path or go back to scripts dir
% to execute...
function con = padConWithZeros( cIn, Xsize )

conLength = length(cIn);
nZeros = Xsize - conLength;
con = [cIn zeros(1,nZeros)];

