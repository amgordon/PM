function PM_setcontrastsPerc(subpar)
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

idx.face = ~cellfun('isempty', strfind(regNames,'face'));
idx.house = ~cellfun('isempty', strfind(regNames,'house'));

idx.bf1 = ~cellfun('isempty', strfind(regNames,'bf(1)'));
idx.ME = cellfun('isempty', strfind(regNames,'^'));

idx.inc = ~cellfun('isempty', strfind(regNames,'inc'));
idx.cor = ~cellfun('isempty', strfind(regNames,'cor'));

idx.high = ~cellfun('isempty', strfind(regNames,'high'));
idx.low = ~cellfun('isempty', strfind(regNames,'low'));

idx.rt = ~cellfun('isempty', strfind(regNames,'RT'));
idx.conf = ~cellfun('isempty', strfind(regNames,'conf')) + ~cellfun('isempty', strfind(regNames,'Conf'));

idx.class = ~cellfun('isempty', strfind(regNames,'class'));
idx.acc = ~cellfun('isempty', strfind(regNames,'acc'));

idx.one = ~cellfun('isempty', strfind(regNames,'1*bf'));
idx.two = ~cellfun('isempty', strfind(regNames,'2*bf'));
idx.three = ~cellfun('isempty', strfind(regNames,'3*bf'));
idx.four = ~cellfun('isempty', strfind(regNames,'4*bf'));



con.face_conf1 = idx.one .* idx.face;
con.face_conf2 = idx.two .* idx.face;
con.face_conf3 = idx.three .* idx.face;
con.face_conf4 = idx.four .* idx.face;

con.house_conf1 = idx.one .* idx.house;
con.house_conf2 = idx.two .* idx.house;
con.house_conf3 = idx.three .* idx.house;
con.house_conf4 = idx.four .* idx.house;

% con.conf_X_class = idx.conf .* idx.class;
% con.rt_X_class = idx.rt .* idx.class;
% con.acc_X_class = idx.acc .* idx.class;

% con.highVsLow_cor = (idx.high - idx.low) .* idx.cor;
% con.faceVsHouse_high = (idx.face - idx.house) .* idx.high .* idx.cor;

%con.conf_X_FaceVsHouse = idx.conf  .* (idx.face - idx.house);
%con.RT_X_FaceVsHouse = idx.rt  .* (idx.face - idx.house);
%con.corVsInc_X_FaceVsHouse = (idx.cor - idx.inc) .* (idx.face - idx.house) .*idx.ME;

%con.ConfFace = idx.conf .* idx.face;
%con.ConfHouse = idx.conf .* idx.house;

%con.RTFace = idx.rt .* idx.face;
%con.RTHouse = idx.rt .* idx.house;

% con.RTFaceVsHouse = idx.rt .* (idx.face - idx.house);
% con.ConfFaceVsHouse = idx.conf .* (idx.face - idx.house);

%  con.corConf = idx.conf .* idx.cor;
%  con.corRT = idx.rt .* idx.cor;
%  con.corVsInc = (idx.cor - idx.inc) .* idx.ME;
% % 
%  con.corConfFace = idx.conf .* idx.cor .* idx.face;
%  con.corConfHouse = idx.conf .* idx.cor .* idx.house;
% % 
%  con.corRTFace = idx.rt .* idx.cor .* idx.face;
%  con.corRTHouse = idx.rt .* idx.cor .* idx.house;
% 
%  con.corConf_X_FaceVsHouse = idx.conf .* idx.cor .* (idx.face - idx.house);
%  con.corRT_X_FaceVsHouse = idx.rt .* idx.cor .* (idx.face - idx.house);
%  con.corVsInc_X_FaceVsHouse = (idx.cor - idx.inc) .* (idx.face - idx.house) .*idx.ME;
% % 
%  con.corVsIncFace = (idx.cor - idx.inc) .* idx.face .* idx.ME;
%  con.corVsIncHouse = (idx.cor - idx.inc) .* idx.house .* idx.ME;
% % 
%  con.faceVsHouseCor = (idx.face - idx.house) .* idx.cor .* idx.ME;
% 
% con.corVsFix = idx.cor .* idx.ME;
% con.faceCorVsFix = idx.cor .* idx.face .* idx.ME;
% con.houseCorVsFix = idx.cor .* idx.house .* idx.ME;
% con.faceCorByRT = idx.cor .* idx.face .* idx.rt;
% con.houseCorByRT = idx.cor .* idx.house .* idx.rt;
% con.corByRT = idx.cor .*idx.rt;
% con.faceIncByRT = idx.inc .* idx.face .* idx.rt;
% con.houseIncByRT = idx.inc .* idx.house .* idx.rt;
% con.incByRT = idx.inc .*idx.rt;
% con.allByRT = idx.rt;
% con.faceCorVsInc = (idx.cor - idx.inc) .* idx.face .* ~idx.rt;
% con.houseCorVsInc = (idx.cor - idx.inc) .* idx.house .* ~idx.rt;
% con.corVsInc = (idx.cor - idx.inc)  .* ~idx.rt;
% con.faceVsHouseCor = idx.cor .* (idx.face - idx.house) .* ~idx.rt;
% con.faceVsHouse_X_RT = idx.cor .* (idx.face - idx.house) .* idx.rt;
% con.faceVsHouse_X_CorVsInc = (idx.cor - idx.inc) .* (idx.face - idx.house) .* ~idx.rt;
% con.faceVsHouseInc = idx.inc .* (idx.face - idx.house) .* ~idx.rt;

% fn = fieldnames(idx);
% for f = 1:length(fn)
%     thisConName = [ fn{f} '_vs_fix'];
%     con.(thisConName) = idx.(fn{f});
% end
% 


%con.all_vs_fix = double(idx.bf1);

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
        %disp(emsg);
        warning('Contrast Impossible To Specify. Dummy Contrast Used!');
        [c,I,emsg,imsg] = spm_conman('ParseCon',double(idx.ME),SPM.xX.xKXs,STAT);
        disp(imsg)
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
return;

% put in here, so I don't have to add it to path or go back to scripts dir
% to execute...
function con = padConWithZeros( cIn, Xsize )

conLength = length(cIn);
nZeros = Xsize - conLength;
con = [cIn zeros(1,nZeros)];

