

for i = 1:length(subjArray)
    par = PM_Params(subjArray(i), 'mnem', 0);
    
    cd(par.analysisdir);
    
    
    delete('spmT*')
    delete('con*')
    
    load('SPM');
    SPM.xCon = [];
    
    save SPM SPM
    
end


