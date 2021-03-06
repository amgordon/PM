function gpar = PM_GroupParams(subjArray, leftOutPar)

if nargin<2
   leftOutPar = []; 
end

[~, SA] = PM_SA;
gpar.subjArray = subjArray;

gpar.conGroup = {'analysisPercByConf'};

if ~isempty(leftOutPar)
    gpar.tasks = {'analysisPercByAllConf_LeftOut'};
else
    gpar.tasks = {'analysisPercByConf'};
end

gpar.expt_dir = '/biac4/wagner/biac3/wagner5/alan/perceptMnemonic/fmri_data/';
gpar.modelTemplate = '/biac4/wagner/biac3/wagner5/alan/perceptMnemonic/scripts/analysis/univariateAnalysis/GroupTemplate.mat';
gpar.constat = 'T';
gpar.exMask = '/biac4/wagner/biac3/wagner5/alan/perceptMnemonic/fmri_data/groupMask/inclusive_mask.img';
gpar.stat = 't1';
gpar.behTask = 'perc';

for t = 1:length(gpar.tasks)
    
    %gpar.task{t}.conTemplate =     fullfile(gpar.expt_dir, 'pm_052311_2', gpar.conGroup{t}, 'SPM');
    gpar.task{t}.conTemplate =  fullfile(gpar.expt_dir, subjArray{1}, gpar.conGroup{t}, 'SPM');
    
    ldTemp = load(gpar.task{t}.conTemplate);
    
    gpar.task{t}.SPMcons = ldTemp.SPM.xCon;
   
    %covVec = [1 1 1 1 2 2 2 2 2 1 2 2 2 2 1 2];
    %covName = 'handMapping';
    gpar.nCovs = 0;
     
    gpar.covVec = [];
    gpar.covName = [];
     
    for c= 1:length(gpar.task{t}.SPMcons);
        gpar.exMask = '/biac4/wagner/biac3/wagner5/alan/perceptMnemonic/fmri_data/groupMask/inclusive_mask.img';
        
        if ~isempty(leftOutPar)
            gpar.task{t}.cons{c}.dir = {fullfile(leftOutPar.subdir, gpar.tasks{t}, [gpar.task{t}.SPMcons(c).name])};
        else
            gpar.task{t}.cons{c}.dir = {fullfile(gpar.expt_dir, 'group_analyses', gpar.tasks{t},gpar.task{t}.SPMcons(c).name)};
        end
        gpar.task{t}.cons{c}.name = gpar.task{t}.SPMcons(c).name;
        
        if strcmp(gpar.behTask,'mnem');
            if (~isempty(strfind(gpar.task{t}.cons{c}.name, 'Conf')) || ~isempty(strfind(gpar.task{t}.cons{c}.name, 'conf')))
                if ~isempty(strfind(gpar.task{t}.cons{c}.name, 'face_conf1'))
                    thisSubSet = SA.(gpar.behTask).sa16_mnemFaceConf1;
                else
                    thisSubSet = SA.(gpar.behTask).sa16_Conf;
                end
            elseif (~isempty(strfind(gpar.task{t}.cons{c}.name, 'Inc')) || ~isempty(strfind(gpar.task{t}.cons{c}.name, 'acc')))
                thisSubSet = SA.(gpar.behTask).sa16_CorVsInc;
            else
                thisSubSet = gpar.subjArray;
            end
        elseif strcmp(gpar.behTask, 'perc')
            if (~isempty(cell2mat(strfind(gpar.tasks, 'signedByHand'))))
                thisSubSet = SA.perc.sa16_percHandMappingBalanced;
            else
                thisSubSet = gpar.subjArray;
            end
        end
        
        idxThisSubSet = ismember(gpar.subjArray,thisSubSet);
        subsToInclude = gpar.subjArray(idxThisSubSet);
        
%         gpar.covVec{c} = covVec(idxThisSubSet);
%         gpar.covName{c} = covName;
        
        nSubs = length(subsToInclude);
        sCI = 0;
        for s = 1:length(subsToInclude)
            thisAnalysisDir = fullfile(gpar.expt_dir, subsToInclude{s}, gpar.conGroup{t});
            thisConStruct = load(fullfile(thisAnalysisDir, 'conStruct'));
            thisConIdx = find(strcmp(thisConStruct.conStruct.con_name,  gpar.task{t}.cons{c}.name));
            
            if ~isempty(thisConIdx)
                sCI = sCI + 1;
                gpar.task{t}.cons{c}.scans{sCI} = fullfile(thisAnalysisDir,  thisConStruct.conStruct.con_fileName{thisConIdx});
            end
        end
        gpar.task{t}.cons{c}.groupContrast = {[1] [-1]};

    end
end