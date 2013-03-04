function PM_MakeRegs(par)


cd (par.behavdir);

dFN = dir('*Perc*');
fileNames = {dFN.name}';

countdown = 12; %length of countdown period (in secs) at the beginning of each run 

if strcmp(par.task, 'mnem')
    [~, ~, idx] = Mnemonic_fMRIBehAnalysis_Retrieval(par);
elseif strcmp(par.task, 'perc')
    [~, ~, idx] = Perceptual_fMRIBehAnalysis(par);
end

qqq = load(par.classmat);
[res] = PM_classificationPostProcessingMnemonicImproved(qqq.res);

perf_set = {'cor' 'inc'};
class_set = {'face' 'house'};
resp_set = {'resp_face' 'resp_house'};

i = 0;

[~, thisAnalysis] = fileparts(par.analysisdir);
idx.inClassifier = res.resS.idxOnsets_test_in_classifier;

if strcmp(thisAnalysis, 'AnalysisRetByRREv')
    for l=1:length(class_set)
        for p=1:length(perf_set)
            
            idx.thisOns = logical(idx.(perf_set{p}) .* idx.(class_set{l}) .* idx.inClassifier);
            
            if ~isempty(idx.alltrials(find(idx.thisOns)))
                
                i = i+1;
                fName = sprintf('%s_%s', class_set{l}, perf_set{p});
                
                stimOnsets{i}= idx.alltrials(find(idx.thisOns));
                stimNames{i} = fName;
                stimDurations{i} = 0;
                
                idxThisOnsInClassifierOnsSpace = idx.thisOns(idx.inClassifier);
                thisEv = res.actsVecLogitUnsigned(idxThisOnsInClassifierOnsSpace);
                
                pmod(i).name{1} = 'Ev';
                pmod(i).poly{1} = 1;
                pmod(i).param{1} = thisEv;
            end
        end
    end
        
else
    error('no regressor scheme establipshed for this analysis')
end

otherTrials = setdiff(idx.alltrials, [stimOnsets{:}]);

if ~isempty(otherTrials)
    i = i+1;
    stimOnsets{i} = otherTrials;
    stimNames{i} = 'junk';
    stimDurations{i} = 0;
end

onsets = stimOnsets;
names = stimNames;
durations = stimDurations;


if ~exist(par.analysisdir)
    mkdir (par.analysisdir);
end

sessReg = zeros(sum(par.numvols),length(par.numvols)-1);
for i = 1:(length(par.numvols)-1)
    if (i==1)
        sessReg(1:par.numvols(i),i) = ones(par.numvols(i),1);
    else
        sessIdx = (1+sum(par.numvols(1:(i-1)))):sum(par.numvols(1:i));
        sessReg(sessIdx,i) = ones(par.numvols(i),1);
    end
end

R = horzcat(sessReg);

cd (par.analysisdir);

save ons.mat onsets durations names pmod;
save regs.mat R