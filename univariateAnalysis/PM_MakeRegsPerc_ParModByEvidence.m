function PM_MakeRegsPerc_ParModByEvidence(par)


cd (par.behavdir);

dFN = dir('*Perc*');
fileNames = {dFN.name}';

countdown = 12; %length of countdown period (in secs) at the beginning of each run 
         
         
par.classmat

load (par.classmat);
subNo = strmatch(par.substr, qqq.subj{1}.S.subj_array, 'exact');


idx.actsPerson = (qqq.subj{subNo}.penalty.nVox.weights.iter{1}.iterations(1).perfmet.desireds==1);
idx.actsHouse = (qqq.subj{subNo}.penalty.nVox.weights.iter{1}.iterations(1).perfmet.desireds==2);

actDiffs = abs(diff(qqq.subj{subNo}.penalty.nVox.weights.iter{1}.iterations(1).acts));

idx.corGuess = qqq.subj{subNo}.penalty.nVox.weights.iter{1}.iterations(1).perfmet.corrects;


idx.incGuess = ~idx.corGuess;





%********************** XXXXXXXXXXXXXXX
%load behavioral data files and generate
trial_data = combineDataFile(fileNames, par.behavdir);
trial_num = length(trial_data);


%extract stim presentation and behavioral variables
if isfield(trial_data,'response')
    resp = cat(1, trial_data.response);
    
    if strcmp(par.substr, 'pm_031711')
        resp(isnan(resp))=9; %'5' button presses were not recorded for this subject.  Assume that Nans reflect '9' button presses.
        resp(resp>4) = resp(resp>4)-1; %change '6 7 8 9' to '5 6 7 8';
    end

    resp_ = 3-ceil(resp/4);
    cresp_ = mod(resp-1, 4) + 1;
end

if all(isnan(resp_))
        %accept all the trials if we did not collect response
    valid_trials = 1 : trial_num;
elseif ~all(isnan(resp_)) && all(isnan(cresp_))
        %if we collected direction choices but not certainty responses
    valid_trials = find(~isnan(resp_));
else
        %if we collected both direction choices and certainty responses 
    valid_trials = find(~isnan(resp_) & ~isnan(cresp_));
end
resp_ = resp_(valid_trials);
cresp_ = cresp_(valid_trials);
trial_data = trial_data(valid_trials);
time0 = cat(1, trial_data.time0);
start_t = cat(1, trial_data.start_t);
event_name = cat(1, trial_data.event_name);
event_time = cat(1, trial_data.event_time);
event_time = event_time + repmat( start_t-time0-countdown ,[1 size(event_time,2)]);
stim_on = event_time(strmatch('stim_on',event_name));
stim_off = event_time(strmatch('stim_off',event_name));
dur_ = stim_off - stim_on;
stim_ = cat(1, trial_data.stim_group);
coh_ = cat(1, trial_data.stim_coh_seq);
scan_ = cat(1, trial_data.ownership);       %which scan each trial belongs to
coh_set = unique(coh_);


alltrials =  (scan_-1).*par.numvols(scan_)' * par.TR + stim_on; 
coh_set_pct = coh_set*100;


% idx.cor = (resp_ == stim_ );
% idx.inc = ~(resp_ == stim_ );

idx.face = stim_==1;
idx.house = stim_==2;

idx.respFace = resp_ == 1;
idx.respHouse = resp_ == 2;

idx.cor = idx.face .* idx.respFace + idx.house .* idx.respHouse;
idx.inc = idx.face .* idx.respHouse + idx.house .* idx.respFace;

perf_set = {'cor' 'inc'};
class_set = {'face' 'house'};
resp_set = {'respFace' 'respHouse'};


% i = 0;
% %for c=1:length(cresp_)
%     for l=1:length(class_set)
%         for p=1:length(perf_set)
%             
%             idx.thisOns = idx.(perf_set{p}) .* idx.(class_set{l});
%             
%             if ~isempty(alltrials(find(idx.thisOns)))
%                 
%                 i = i+1;
%                 fName = sprintf('%s_%s', class_set{l}, perf_set{p});
%                 
%                 
%                 stimOnsets{i}= alltrials(find(idx.thisOns));
%                 stimNames{i} = fName;
%                 stimDurations{i} = 0;
%                 
%                 pmod(i).param{1} = cresp_(idx.thisOns==1);
%                 pmod(i).param{2} = coh_(idx.thisOns==1);
%                 
%                 pmod(i).name{1} = [fName '_conf'];
%                 pmod(i).name{2} = [fName '_coh'];
%                 
%                 pmod(i).poly = {1 1};
%             end
%         end
%     end
% %end
idx.actsPersonCorGuess = idx.actsPerson.*idx.corGuess .* idx.cor';
idx.actsHouseCorGuess = idx.actsHouse.*idx.corGuess .* idx.cor';

%actDiffsPerson = actDiffs(idx.actsPerson);
%actDiffsHouse = actDiffs(idx.actsHouse);
 

actDiffsPersonCorGuess = actDiffs(find(idx.actsPerson.*idx.corGuess .* idx.cor'));
actDiffsHouseCorGuess = actDiffs(find(idx.actsHouse.*idx.corGuess .* idx.cor'));

%actDiffsPersonIncGuess = actDiffs(find(idx.actsPerson.*idx.incGuess));
%actDiffsHouseIncGuess = actDiffs(find(idx.actsHouse.*idx.incGuess));

subIDXPersonCorGuess = idx.actsPersonCorGuess(find(idx.actsPerson.* idx.cor'));
subIDXHouseCorGuess = idx.actsHouseCorGuess(find(idx.actsHouse .* idx.cor'));
subIDXPersonIncGuess = 1 - subIDXPersonCorGuess;
subIDXHouseIncGuess = 1 - subIDXHouseCorGuess;



helper.AD.PersonCor = alltrials(find(idx.respFace .* idx.cor));
helper.AD.HouseCor = alltrials(find(idx.respHouse .* idx.cor));




ons.AD.PersonCor_GuessCor = helper.AD.PersonCor(find(subIDXPersonCorGuess));
ons.AD.HouseCor_GuessCor = helper.AD.HouseCor(find(subIDXHouseCorGuess));

ons.AD.PersonCor_GuessInc = helper.AD.PersonCor(find(subIDXPersonIncGuess));
ons.AD.HouseCor_GuessInc = helper.AD.HouseCor(find(subIDXHouseIncGuess));

ons.AD.PersonCor_GuessInc = helper.AD.PersonCor(find(subIDXPersonIncGuess))';
ons.AD.HouseCor_GuessInc = helper.AD.HouseCor(find(subIDXHouseIncGuess))';


ons.AD.Junk = alltrials(find(~idx.cor));



pmod(1).param = {actDiffsPersonCorGuess};
pmod(1).name = {'GreaterEvPersonCorGuess'};
pmod(1).poly = {1};

pmod(2).param = {actDiffsHouseCorGuess};
pmod(2).name = {'GreaterEvSceneCorGuess'};
pmod(2).poly = {1};

fn = fieldnames(ons.AD);

for f = 1:length(fn);
    onsets{f} = ons.AD.(fn{f});
    durations{f} = 0;
    names{f} = fn{f};
end


% 
% onsets = stimOnsets;
% names = stimNames;
% durations = stimDurations;

if ~exist(par.analysisdir)
    mkdir (par.analysisdir);
end



sessReg = zeros(sum(par.numvols),par.numscans-1);
for i = 1:(par.numscans - 1)
    sessReg((i-1)*par.numvols(i)+1:i*par.numvols(i),i) = ones(par.numvols(i),1);
end


% for i = 1:par.numscans
%     cd(fullfile(par.subdir, 'functional', ['scan' (prepend(num2str(par.scans_to_include(i)),2))]   ));
%     motTxt = dir('rp*');
%     motRegs_h{i} = textread(motTxt.name);
% end
% 
% motRegs = vertcat(motRegs_h{:});

R = horzcat(sessReg);




cd (par.analysisdir);
save ons.mat onsets durations names pmod;
save regs.mat R