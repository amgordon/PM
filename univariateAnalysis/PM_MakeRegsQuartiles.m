function AG4MakeRegs(par)



fileNames = {'09-29-2010_RoozbehPerc1.mat'
             '09-29-2010_RoozbehPerc2.mat'
             '09-29-2010_RoozbehPerc3.mat'
             '09-29-2010_RoozbehPerc4.mat'
             '09-29-2010_RoozbehPerc5.mat'
             '09-29-2010_RoozbehPerc6.mat'
             '09-29-2010_RoozbehPerc7.mat'
             '09-29-2010_RoozbehPerc8.mat'};

countdown = 12; %length of countdown period (in secs) at the beginning of each run 
         
         
% responses = {[4 4 4 3 3 4 4 4 4 4 3 3 4 3 4 4 3 3 4]
%              [4 3 4 4 3 3 3 4 3 3 3 4 3 4 3 3 4 3 4]
%              [4 4 4 3 3 3 3 3 3 4 3 3 4 3 3 4 3 3 4 4]
%              [4 3 4 3 4 4 3 4 4 4 4 4 4 3 4 4 4 3 3]
%              [4 3 4 3 3 3 4 3 3 3 3 4 4 4 4 4 4 4 4 4]
%              [4 4 4 4 4 4 3 4 4 3 4 4 4 3 4 4 3 4 4 4]
%              [3 3 3 3 4 3 3 3 3 3 4 4 4 3 3 4 3 4 3 3]
%              [3 4 4 4 3 3 3 3 4 3 4 3 4 3 3 3 4 3 3]
%              [3 3 4 4 4 3 3 4 3 3 4 4 3 4 4 4 3 4 4 3]
%              [4 4 4 3 3 4 4 4 4 3 4 4 3 4 3 4 3 4 3]};
% for i = 1 : length(fileNames)
%     load(fileNames{i});
%     for j = 1 : length(trial_data)
%         if (trial_data(j).stim_group==1 && responses{i}(j)==4) || ...
%            (trial_data(j).stim_group==2 && responses{i}(j)==3)
%             trial_data(j).result = {'CORRECT'}; 
%             trial_data(j).response = trial_data(j).stim_group;
%         else
%             trial_data(j).result = {'WRONG'};
%             trial_data(j).response = 3-trial_data(j).stim_group;
%         end
%     end
%     save(fileNames{i}, 'eyelink_struct', 'screen_struct', 'task_struct', 'trial_data');
% end



%********************** XXXXXXXXXXXXXXX    
        %load behavioral data files and generate 
trial_data = combineDataFile(fileNames, par.behavdir );
trial_num = length(trial_data);


    %extract stim presentation and behavioral variables
if isfield(trial_data,'response')
    resp_ = cat(1, trial_data.response);
else
    resp_ = nan(trial_num, 1);
end
if isfield(trial_data, 'cresponse')
    cresp_ = cat(1, trial_data.cresponse);
else
    cresp_ = nan(trial_num, 1);
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


alltrials =  (scan_-1)*318 + stim_on; 

for i = 1:4
    coh_set_quarts{i} = [coh_set(i*2-1) coh_set(i*2)];
end

idx.cor = (resp_ == stim_ );
idx.inc = ~(resp_ == stim_ );

idx.face = stim_==1;
idx.house = stim_==2;

perf_set = {'cor' 'inc'};
class_set = {'face' 'house'};



i = 0;
for c=1:length(coh_set_quarts)
    for p=1:length(perf_set)
        for l=1:length(class_set)
            
            idx.thisOns = ismember(coh_, coh_set_quarts{c}) .* idx.(perf_set{p}) .* idx.(class_set{l});
            
            if ~isempty(alltrials(find(idx.thisOns)))
                
                i = i+1;
                fName = sprintf('%s_cohQ%s_%s', class_set{l}, num2str(c), perf_set{p});
                
                
                
                
                stimOnsets{i}= alltrials(find(idx.thisOns));
                stimNames{i} = fName;
                stimDurations{i} = 0;
                
                
              
            end
            
            
        end
    end
end

onsets = stimOnsets;
names = stimNames;
durations = stimDurations;

if ~exist(par.analysisdir)
    mkdir (par.analysisdir);
end



sessReg = zeros(sum(par.numvols),par.numscans-1);
for i = 1:(par.numscans - 1)
    sessReg((i-1)*par.numvols(i)+1:i*par.numvols(i),i) = ones(par.numvols(i),1);
end


for i = 1:par.numscans
    cd(fullfile(par.subdir, 'functional', ['scan' (prepend(num2str(par.scans_to_include(i)),2))]   ));
    motTxt = dir('rp*');
    motRegs_h{i} = textread(motTxt.name);
end

motRegs = vertcat(motRegs_h{:});

R = horzcat(sessReg, motRegs);




cd (par.analysisdir);
save ons.mat onsets durations names;
save regs.mat R