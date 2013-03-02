function PM_setcontrasts_analysisPercByEvidence(subpar)
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
    par = par_params(subpar);
end

STAT = par.constat;

cd(par.analysisdir);
fprintf('\nLoading SPM...');
load SPM
fprintf('Done');

Xsize = size(SPM.xX.xKXs.X,2);

padCon = @padConWithZeros;

regNames = SPM.xX.name;

% T-contrasts
%---------------------------------------------------------------------------



% so you want to make a contrast...
% instead of manually typing out the contrast matrix, I'll create them
% based on contrast names.  Anything 'fancier' than simple contrasts (e.g.
% parametric contrasts) will be specified after this section.  This will
% also produce the inverse contrasts of anything specified.  Note that for
% balancing ease of interpretation with shorthand, all conditions must
% contain only one initial cap [A-Z]
% current conditions:

% idx.face = ~cellfun('isempty', strfind(regNames,'face'));
% idx.house = ~cellfun('isempty', strfind(regNames,'house'));
% 
% idx.bf1 = ~cellfun('isempty', strfind(regNames,'bf(1)'));
% 
% idx.high = ~cellfun('isempty', strfind(regNames,'high'));
% idx.low = ~cellfun('isempty', strfind(regNames,'low'));
% 
% 
% idx.inc = ~cellfun('isempty', strfind(regNames,'inc'));
% idx.cor = ~cellfun('isempty', strfind(regNames,'cor'));
% 

idx.coh = ~cellfun('isempty', strfind(regNames,'Ev'));

idx.person = ~cellfun('isempty', strfind(regNames,'Person'));
idx.house = ~cellfun('isempty', strfind(regNames,'House'));

idx.inc = ~cellfun('isempty', strfind(regNames,'Inc'));
idx.cor = ~cellfun('isempty', strfind(regNames,'Cor'));

idx.bf1 = ~cellfun('isempty', strfind(regNames,'bf(1)'));

con.conf = idx.ev;
%con.lessEv = -idx.ev;
con.greaterEvFace = idx.person .* idx.ev;
con.greaterEvHouse = idx.house .* idx.ev;
con.greaterEv_X_FaceVsHouse = idx.ev .* (idx.person - idx.house);
con.greaterEv_X_HouseVsFace = idx.ev .* (idx.house - idx.person);


% con.faceVsHouse_corOnly = (idx.face - idx.house) .* idx.cor .* idx.bf1 ;
% con.faceVsHouse_high_corOnly = (idx.face - idx.house) .* idx.high .* idx.cor .* idx.bf1 ;
% con.faceVsHouse_low_corOnly = (idx.face - idx.house) .* idx.low .* idx.cor .* idx.bf1 ;
% 
% con.high_vs_low = (idx.high - idx.low) .* idx.bf1;
% con.high_vs_low_corOnly = (idx.high - idx.low) .* idx.cor .* idx.bf1;
% 
% con.linearConf_FaceVsHouse_corOnly = (1.5*(idx.high .* idx.face) + .5 * (idx.low .* idx.face) - .5 * (idx.low .* idx.house) - 1.5*(idx.high .* idx.house)) .* idx.cor .* idx.bf1;
% 
% con.cor_vs_inc = (idx.cor - idx.inc) .* idx.bf1;
% 
% con.faceCorVsFaceInc = (idx.cor - idx.inc) .* idx.face .* idx.bf1;
% con.houseCorVsHouseInc = (idx.cor - idx.inc) .* idx.house .* idx.bf1;



    
% fn = fieldnames(idx);
% for f = 1:length(fn)
%     thisConName = [ fn{f} '_vs_fix'];
%     con.(thisConName) = idx.(fn{f});
% end



con.all_vs_fix = double(idx.bf1);

fn_con = fieldnames(con);


for f = 1:length(fn_con)
    cnames{f} = fn_con{f};
    cvals{f} = con.(fn_con{f});
end


    




% preallocate
con_name(1:length(cnames)) = {''};
con_vals = cell(1, length(cnames));

%con_vals(1:length(cnames)) = {zeros(1,length(cnames))};

for Tt = 1:length(cnames)

    % make names
    con_name{Tt} = cnames{Tt};

    con_vals{Tt} = double(cvals{Tt});
    
%     %puts two zeros between each element of cvals (to account for
%     %inclusion of time and dispersion derivatives).
%     val_processor_h = vertcat(cvals{Tt}, zeros(2, length(cvals{Tt})));
%     val_processor = horzcat(val_processor_h(:))';
% 
%     
%     con_vals{Tt} = val_processor;

    %     some peace of mind (math check)
%    if sum(con_vals{Tt}) ~= 0;
%        error('lopsided contrast!!!');
%    end

end

% any other fancy contrasts?
% 
% fnc = length(con_name);
% nCnds = length(SPM.Sess.U);
% 
% con_vals{fnc+1}         = repmat([1 0 0], 1, nCnds);
% con_name{fnc+1}         = 'allVsFix';
% con_vals{fnc+2}          = repmat([-1 0 0], 1, nCnds);
% con_name{fnc+2}         = 'fixVsAll';

% put contrasts into SPM/write to file

fprintf('\nBeginning contrasts on subject %s\n', par.substr);


cfid = fopen('conlist','wt');
fprintf(cfid, 'Contrasts for Sub %s\nLast run on %s\n', par.substr, date);

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
copyfile('conlist',[par.logdir filesep 'conlist-' date]);

% Change back directory
cd(origdir);
return;

% put in here, so I don't have to add it to path or go back to scripts dir
% to execute...
function con = padConWithZeros( cIn, Xsize )

conLength = length(cIn);
nZeros = Xsize - conLength;
con = [cIn zeros(1,nZeros)];

