function [] = PM_conjoinWithinSubject(subNo)

analysisdir =  '/biac4/wagner/biac3/wagner5/alan/perceptMnemonic/fmri_data/group_analyses/';


par1 = PM_Params(subNo, 'perc', 0);
par2 = PM_Params(subNo, 'mnem', 0);

percdirConf = fullfile(par1.perc.analysisdir, 'AllConf', 'spmT_0001.img');
mnemdirConf = fullfile(par2.mnem.analysisdir, 'AllConf', 'spmT_0001.img');
percdirRT = fullfile(par1.perc.analysisdir, 'AllRT', 'spmT_0001.img');
mnemdirRT = fullfile(par2.mnem.analysisdir, 'AllRT', 'spmT_0001.img');

outputdir = fullfile(par2.mnem.analysisdir, 'percMnemConj_parModByConfAndRT_16Subs_1LeftOut');

if ~exist(outputdir,'dir')
    mkdir(outputdir)
end

%conds = {'corRT', 'corConf', 'corVsInc', 'corRTFace', 'corRTHouse', ...
%    'corConfFace', 'corConfHouse', 'corVsIncFace', 'corVsIncHouse', 'faceVsHouseCor'};
condsPerc = {'rt'	'acc'	'class' 'conf'};
condsMnem = {'RT'	'acc'	'class' 'conf'};
%conds = {{'corRTFace', 'corRTHouse'} {'corConfFace', 'corConfHouse'} {'corVsIncFace', 'corVsIncHouse'}};

%Pthresh = .05;
%Pthresh = .0036;
Pthresh = .005;
TthreshP = tinv(1-Pthresh,15);
TthreshR = tinv(1-Pthresh,13);
%for c = 1:length(condsPerc)


d{1} = percdirRT;
d{2} = mnemdirRT;

dirChar = char(d);

%imcalcText = sprintf('((i1>%g) .* (i2>%g) .* (i3>%g) .* (i4>%g)) - ((i1<-%g) .* (i2<-%g) .* (i3<-%g) .* (i4<-%g))',Tthresh,Tthresh, Tthresh, Tthresh,Tthresh,Tthresh, Tthresh, Tthresh);
%imcalcText = sprintf('100*((i1>%g) .* (i2>%g)) - ((i1<-%g) .* (i2<-%g))',Tthresh,Tthresh, Tthresh, Tthresh);
imcalcText = sprintf('100*((i1>%g) .* (i2>%g)) - ((i1<-%g) .* (i2<-%g))', TthreshP , TthreshP, TthreshR, TthreshR);
%outputfile = fullfile(outputdir, sprintf('conj_p%s_across_%s_and_%s.img', num2str(Pthresh), conds{c}{1}, conds{c}{2} ));
%outputfile = fullfile(outputdir, sprintf('conj_%s_p%s.img', condsPerc{c}, num2str(Pthresh)));
outputfile = fullfile(outputdir, 'conj_RTAll_p.005_acrossPercAndMnem_leftOut.img');
spm_imcalc_ui(dirChar,outputfile, imcalcText, {0,0,16,0})

%end

