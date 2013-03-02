function PM_MakeRegsPerc_parModbyAccRTAndConf(par)


[~, ~, idx] = Perceptual_fMRIBehAnalysis(par);




i = 0;

        
idx.thisOns = ~isnan(idx.rt);

if ~isempty(idx.alltrials(find(idx.thisOns)))
    
    i = i+1;
    fName = sprintf('allTrials');
    
    thisIdx = find(idx.thisOns .* idx.cleanResp .* ~isnan(idx.rt) );
    stimOnsets{i}= idx.alltrials(thisIdx);
    stimNames{i} = fName;
    stimDurations{i} = 0;
    
    if length(stimOnsets{i})>1
        
        
        pmod(i).param{1} = double(idx.face(thisIdx) - idx.house(thisIdx));
        pmod(i).param{2} = idx.conf_unsigned(thisIdx);
        pmod(i).param{3} = idx.rt(thisIdx);
        
        pmod(i).name{1} = 'class';
        pmod(i).name{2} = 'conf';
        pmod(i).name{3} = 'RT';
        
        pmod(i).poly{1} = 1;
        pmod(i).poly{2} = 1;
        pmod(i).poly{3} = 1;
        
        pmod(i).param{4} = double(idx.coh_(thisIdx)==0);
        pmod(i).name{4} = 'zeroCohVsOthers';
        pmod(i).poly{4} = 1;
        
        pmod(i).param{5} =   pmod(i).param{1} .* pmod(i).param{2};
        pmod(i).name{5} = 'class_X_conf';
        pmod(i).poly{5} = 1;
        
        pmod(i).param{6} =   pmod(i).param{1} .* pmod(i).param{3};
        pmod(i).name{6} = 'class_X_RT';
        pmod(i).poly{6} = 1;
        
        if sum(~idx.cor(thisIdx)) > 1
            pmod(i).param{7} = idx.cor(thisIdx) - idx.inc(thisIdx);
            pmod(i).name{7} = 'acc';
            pmod(i).poly{7} = 1;
            
            pmod(i).param{8} =   pmod(i).param{1} .* pmod(i).param{7};
            pmod(i).name{8} = 'class_X_acc';
            pmod(i).poly{8} = 1;
        end
    end
end


if sum(idx.junk + isnan(idx.rt))>0
    stimOnsets{i+1} = idx.alltrials(find(idx.junk + isnan(idx.rt)));
    stimNames{i+1} = 'junk';
    stimDurations{i+1} = 0;
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


R = sessReg;

cd (par.analysisdir);
save ons.mat onsets durations names pmod;
save regs.mat R