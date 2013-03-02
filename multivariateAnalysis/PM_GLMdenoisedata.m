function [results,denoiseddata] = PM_GLMdenoisedata(design,data,stimdur,tr,hrfmodel,hrfknobs,opt,figuredir)

% function [results,denoiseddata] = GLMdenoisedata(design,data,stimdur,tr,hrfmodel,hrfknobs,opt,figuredir)
%
% <design> is the experimental design with dimensions time x conditions.
%   Each column should be zeros except for ones indicating condition onsets.
%   Can be a cell vector whose elements correspond to different runs.
%   Different runs can have different numbers of time points.
%   Because this function involves cross-validation across runs, 
%   there must be at least two runs in <design>.
% <data> is the time-series data with dimensions X x Y x Z x time or a cell
%   vector of elements that are each X x Y x Z x time.  XYZ can be collapsed.
%   The dimensions of <data> should mirror that of <design>.  (For example, 
%   <design> and <data> should have the same number of runs, the same number 
%   of time points, etc.)  <data> should not contain any NaNs.
% <stimdur> is the duration of a trial in seconds
% <tr> is the sampling rate in seconds
% <hrfmodel> (optional) indicates the type of model to use for the HRF:
%   'fir' indicates a finite impulse response model (a separate timecourse
%     is estimated for every voxel and every condition)
%   'assume' indicates that the HRF is provided (see <hrfknobs>)
%   'optimize' indicates that we should estimate a global HRF from the data
%   Default: 'optimize'.
% <hrfknobs> (optional) is as follows:
%   if <hrfmodel> is 'fir', then <hrfknobs> should be the number of 
%     time points in the future to model (N >= 0).  For example, if N is 10, 
%     then timecourses will consist of 11 points, with the first point 
%     coinciding with condition onset.
%   if <hrfmodel> is 'assume', then <hrfknobs> should be time x 1 with
%     the HRF to assume.
%   if <hrfmodel> is 'optimize', then <hrfknobs> should be time x 1 with the 
%     initial seed for the HRF.  The length of this vector indicates the
%     number of time points that we will attempt to estimate in the HRF.
%   Note on normalization:  In the case that <hrfmodel> is 'assume' or
%   'optimize', we automatically divide <hrfknobs> by the maximum value
%   so that the peak is equal to 1.  And if <hrfmodel> is 'optimize',
%   then after fitting the HRF, we again normalize the HRF to peak at 1
%   (and adjust amplitudes accordingly).  Default in the case of 'fir' is
%   20.  Default in the case of 'assume' and 'optimize' is to use a 
%   canonical HRF that is calculated based on <stimdur> and <tr>.
% <opt> (optional) is a struct with the following fields:
%   <extraregressors> (optional) is time x regressors or a cell vector
%     of elements that are each time x regressors.  The dimensions of 
%     <extraregressors> should mirror that of <design> (i.e. same number of 
%     runs, same number of time points).  The number of extra regressors 
%     does not have to be the same across runs, and each run can have zero 
%     or more extra regressors.  If [] or not supplied, we do 
%     not use extra regressors in the model.
%   <maxpolydeg> (optional) is a non-negative integer with the maximum 
%     polynomial degree to use for polynomial nuisance functions, which
%     are used to capture low-frequency noise fluctuations in each run.
%     Can be a vector with length equal to the number of runs (this
%     allows you to specify different degrees for different runs).  
%     Default is to use round(L/2) for each run where L is the 
%     duration in minutes of a given run.
%   <seed> (optional) is the random number seed to use (this affects
%     the selection of bootstrap samples). Default: sum(100*clock).
%   <bootgroups> (optional) is a vector of positive integers indicating
%     the grouping of runs to use when bootstrapping.  For example, 
%     a grouping of [1 1 1 2 2 2] means that of the six samples that are
%     drawn, three samples will be drawn (with replacement) from the first
%     three runs and three samples will be drawn (with replacement) from
%     the second three runs.  This functionality is useful in situations
%     where different runs involve different conditions.  Default: ones(1,D) 
%     where D is the number of runs.
%   <numforhrf> (optional) is a positive integer indicating the number 
%     of voxels (with the best R^2 values) to consider in fitting the 
%     global HRF.  This input matters only when <hrfmodel> is 'optimize'.
%     Default: 50.  (If there are fewer than that number of voxels
%     available, we just use the voxels that are available.)
%   <hrffitmask> (optional) is X x Y x Z with 1s indicating all possible
%     voxels to consider for fitting the global HRF.  This input matters
%     only when <hrfmodel> is 'optimize'.  Special case is 1 which means
%     all voxels can be potentially chosen.  Default: 1.
%   <brainthresh> (optional) [A B] where A is a percentile for voxel intensity 
%     values and B is a fraction to apply to the percentile.  These parameters
%     are used in the selection of the noise pool.  Default: [99 0.5].
%   <brainR2> (optional) is an R^2 value (percentage).  Voxels whose 
%     cross-validation accuracy is below this value are allowed to enter 
%     the noise pool.  Default: 0.
%   <numpcstotry> (optional) is a non-negative integer indicating the maximum
%     number of PCs to enter into the model.  Default: 20.
%   <pcR2cutoff> (optional) is an R^2 value (percentage).  To decide the number
%     of PCs to include, we examine a subset of the available voxels.
%     Specifically, we examine voxels whose cross-validation accuracy is above 
%     <pcR2cutoff> for any of the numbers of PCs.  Default: 0.
%   <pcR2cutoffmask> (optional) is X x Y x Z with 1s indicating all possible
%     voxels to consider when selecting the subset of voxels.  Special case is
%     1 which means all voxels can be potentially selected.  Default: 1.
%   <pcstop> (optional) is
%     A: a number greater than or equal to 1 indicating when to stop adding PCs 
%        into the model.  For example, 1.05 means that if the cross-validation 
%        performance with the current number of PCs is within 5% of the maximum 
%        observed, then use that number of PCs.  (Performance is measured 
%        relative to the case of 0 PCs.)  When <pcstop> is 1, the selection 
%        strategy reduces to simply choosing the PC number that achieves
%        the maximum.  The advantage of stopping early is to achieve a selection
%        strategy that is robust to noise and shallow performance curves and 
%        that avoids overfitting.
%    -B: where B is the number of PCs to use for the final model (thus, the user
%        chooses).  B can be any integer between 0 and opt.numpcstotry.
%     Default: 1.05.
%   <numboots> (optional) is a positive integer indicating the number of 
%     bootstraps to perform for the final model.  Special case is 0 which
%     indicates that the final model should just be fit to the complete
%     set of data (and not bootstrapped). Default: 100.
%   <denoisespec> (optional) is a binary string or cell vector of binary strings
%     indicating the components of the data to return in <denoiseddata>.  The 
%     format of each string should be 'ABCDE' where A indicates whether to include 
%     the signal (estimated hemodynamic responses evoked by the experiment), B 
%     indicates whether to include the polynomial drift, C indicates whether
%     to include any extra regressors provided by the user, D indicates 
%     whether to include the global noise regressors, and E indicates whether
%     to include the residuals of the model.  If multiple strings are provided,
%     then separate copies of the data will be returned in the rows of 
%     <denoiseddata>.  Default: '11101' which indicates that all components of 
%     the data will be returned except for the component corresponding to the 
%     estimate of the contribution of the global noise regressors.
%   <wantpercentbold> (optional) is whether to convert the amplitude estimates
%     in 'models', 'modelmd', and 'modelse' to percent BOLD change.  This is
%     done as the very last step, and is accomplished by dividing by the 
%     absolute value of 'meanvol' and multiplying by 100.  (The absolute 
%     value prevents negative values in 'meanvol' from flipping the sign.)
%     Default: 1.
% <figuredir> (optional) is a directory to which to write figures.  (If the
%   directory does not exist, we create it; if the directory already exists,
%   we delete its contents so we can start afresh.)  If [], no figures are
%   written.  If not supplied, default to 'GLMdenoisefigures' (in the current 
%   directory).
%
% Based on the experimental design (<design>, <stimdur>, <tr>) and the 
% model specification (<hrfmodel>, <hrfknobs>), fit a GLM model to the 
% data (<data>, <xyzsize>) using a denoising strategy.  Figures 
% illustrating the results are written to <figuredir>.
%
% Return <results> as a struct containing the following fields:
% <models>, <modelmd>, <modelse>, <R2>, <R2run>, <signal>, <noise>, 
%   <SNR>, and <hrffitvoxels> are all like the output of GLMestimatemodel.m 
%   (please see that function for details).
% <hrffitvoxels> is X x Y x Z with logical values indicating the voxels that
%   were used to fit the global HRF.  (If <hrfmodel> is not 'optimize',
%   this is returned as [].)
% <meanvol> is X x Y x Z with the mean of all volumes
% <noisepool> is X x Y x Z with logical values indicating the voxels that
%   were selected for the noise pool.
% <pcregressors> indicates the global noise regressors that were used
%   to denoise the data.  The format is a cell vector of elements that 
%   are each time x regressors.  The number of regressors will be equal 
%   to opt.numpcstotry.
% <pcR2> is X x Y x Z x (1+opt.numpcstotry) with cross-validated R^2 values for
%   different numbers of PCs.  The first slice corresponds to 0 PCs, the
%   second slice corresponds to 1 PC, the third slice corresponds to
%   2 PCs, etc.
% <pcvoxels> is X x Y x Z with logical values indicating the voxels that
%   were used to select the number of PCs.
% <pcnum> is the number of PCs that were selected for the final model.
% <pcweights> is X x Y x Z x <pcnum> x R with the estimated weights on the 
%   PCs for each voxel and run.
% <inputs> is a struct containing all inputs used in the call to this
%   function, excluding <data>.  We additionally include a field called 
%   'datasize' which contains the size of each element of <data>.
% 
% Also return <denoiseddata>, which is just like <data> except that the 
% component of the data that is estimated to be due to global noise is
% subtracted off.  This may be useful in situations where one wishes to
% treat the denoising as a pre-processing step prior to other analyses 
% of the time-series data.  Further customization of the contents of
% <denoiseddata> is controlled by opt.denoisespec.
%
% Description of the denoising procedure:
% 1. Determine HRF.  If <hrfmodel> is 'assume', we just use the HRF
%    specified by the user.  If <hrfmodel> is 'optimize', we perform
%    a full fit of the GLM model to the data, optimizing the shape of
%    the HRF.  If <hrfmodel> is 'fir', we do nothing (since full 
%    flexibility in the HRF is allowed for each voxel and each condition).
% 2. Determine cross-validated R^2 values.  We fix the HRF to what is
%    obtained in step 1 and estimate the rest of the GLM model.  Leave-one-
%    run-out cross-validation is performed, and we obtain an estimate of the
%    amount of variance (R^2) that can be predicted by the deterministic 
%    portion of the GLM model (the HRF and the amplitudes).
% 3. Determine noise pool.  This is done by calculating a mean volume (the 
%    mean across all volumes) and then determining the voxels that
%    satisfy the following two criteria:
%    (1) The voxels must have sufficient MR signal, that is, the signal
%        intensity in the mean volume must be above a certain threshold
%        (see opt.brainthresh).
%    (2) The voxels must have cross-validated R^2 values that are 
%        below a certain threshold (see opt.brainR2).
% 4. Determine global noise regressors.  This is done by extracting the 
%    time-series data for the voxels in the noise pool, projecting out the
%    polynomial nuisance functions from each time-series, normalizing each
%    time-series to be unit length, and then performing PCA.  The top N
%    PCs from each run (where N is equal to opt.numpcstotry) are selected
%    as global noise regressors.  Each regressor is scaled to have a standard
%    deviation of 1; this makes it easier to interpret the weights estimated
%    for the regressors.
% 5. Evaluate different numbers of PCs using cross-validation.  We refit
%    the GLM model to the data (keeping the HRF fixed), systematically varying 
%    the number of PCs from 1 to N.  For each number of PCs, leave-one-run-out 
%    cross-validation is performed.  (Recall that only the deterministic
%    portion of the model is cross-validated; thus, any changes in R^2
%    directly reflect changes in the quality of the amplitude estimates.)
% 6. Choose optimal number of PCs.  To choose the optimal number of PCs,
%    we select a subset of voxels (namely, any voxel that has a cross-validated
%    R^2 value greater than opt.pcR2cutoff (default: 0%) in any of the cases
%    being considered) and then compute the median cross-validated R^2 for these 
%    voxels for different numbers of PCs.  Starting from 0 PCs, we select the 
%    number of PCs that achieves a cross-validation accuracy within opt.pcstop of 
%    the maximum.  (The default for opt.pcstop is 1.05, which means that the
%    chosen number of PCs will be within 5% of the maximum.)
% 7. Fit the final model.  We fit the final GLM model (with the HRF fixed to 
%    that obtained in step 1 and with the number of PCs selected in step 6) 
%    to the data.  Bootstrapping is used to estimate error bars on 
%    amplitude estimates.
% 8. Return the de-noised data.  We calculate the component of the data that 
%    is due to the global noise regressors and return the original time-series 
%    data with this component subtracted off.  Note that the other components of
%    the model (the hemodynamic responses evoked by the experiment, 
%    the polynomial drift, any extra regressors provided by the user, 
%    model residuals) remain in the de-noised data.  To change this behavior, 
%    please see the input opt.denoisespec.
%
% Figures:
% - "HRF.png" shows the initial assumed HRF (provided by <hrfknobs>) and the
%   final estimated HRF (as calculated in step 1).  If <hrfmodel> is 'assume',
%   the two plots will be identical.  If <hrfmodel> is 'fir', this figure
%   is not written.
% - "HRFfitmask.png" shows (in white) the mask restricting the voxels that
%   can be chosen for fitting the global HRF.  This figure is written only
%   if <hrfmodel> is 'optimize' and is not written if opt.hrffitmask is 1.
% - "HRFfitvoxels.png" shows (in white) the voxels used to fit the global HRF.
%   This figure is written only if <hrfmodel> is 'optimize'.
% - "PCselection.png" shows for different numbers of PCs, the median 
%   cross-validated R^2 across a subset of voxels (namely, those voxels that 
%   have greater than opt.pcR2cutoff (default: 0%) R^2 for at least one of 
%   the models considered).  The selected number of PCs is circled and 
%   indicated in the title of the figure.
% - "PCscatterN.png" shows a scatter plot of cross-validated R^2 values obtained
%   with no PCs against values obtained with N PCs.  The range of the plot
%   is set to the full range of all R^2 values (across all numbers of PCs).
%   Two different sets of points are plotted.  The first set is shown in green,
%   and this is a set of up to 20,000 voxels randomly selected from the
%   entire pool of voxels.  The second set is shown in red, and this is a set of
%   up to 20,000 voxels randomly selected from the set of voxels that
%   were used to select the number of PC regressors.
% - "MeanVolume.png" shows the mean volume (mean of all volumes).
% - "NoisePool.png" shows (in white) the voxels selected for the noise pool.
% - "PCcrossvalidationN.png" shows cross-validated R^2 values obtained with N PCs.
%   The range is 0% to 100%, and the colormap is nonlinearly scaled to enhance
%   visibility.
% - "PCmask.png" shows (in white) the mask restricting the voxels that
%   can be selected for determining the optimal number of PCs.  This figure is 
%   not written if opt.pcR2cutoffmask is 1.
% - "PCvoxels.png" shows (in white) the voxels used to determine the optimal
%   number of PCs.
% - "FinalModel.png" shows R^2 values for the final model (as estimated in
%   step 7).  Note that these R^2 values are not cross-validated.
% - "FinalModel_runN.png" shows R^2 values for the final model separated by 
%   runs.  For example, FinalModel_run01.png indicates R^2 values calculated
%   over the data in run 1.  This might be useful for deciding post-hoc to
%   exclude certain runs from the analysis.
% - "SNRsignal.png" shows the maximum absolute amplitude obtained (the signal).
%   The range is 0 to the 99th percentile of the values.
% - "SNRnoise.png" shows the average amplitude error (the noise).
%   The range is 0 to the 99th percentile of the values.
% - "SNR.png" shows the signal-to-noise ratio.  The range is 0 to 10.
% - "PCmap/PCmap_runN_numO.png" shows the estimated weights for the Oth PC
%   for run N.  The range is -A to A where A is the 99th percentile of the
%   absolute value of all weights across all runs.  The colormap proceeds
%   from blue (negative) to black (0) to red (positive).
%
% Additional information:
% - For additional details on model estimation and quantification of model
% accuracy (R^2), please see the documentation provided in GLMestimatemodel.m.
%
% History:
% - 2012/12/03: *** Tag: Version 1.02 ***. Use faster OLS computation (less
%   error-checking; program execution will halt if design matrix is singular);
%   documentation tweak; minor bug fix.
% - 2012/11/24:
%   - INPUTS: add opt.hrffitmask; opt.pcR2cutoff; opt.pcR2cutoffmask; opt.pcstop; opt.denoisespec; opt.wantpercentbold;
%   - OUTPUTS: add hrffitvoxels, pcvoxels, pcweights, inputs
%   - FIGURES: HRFfitmask.png, HRFfitvoxels.png, PCmask.png, PCvoxels.png, Signal.png, Noise.png, SNR.png, PCmap*.png
%   - hrfmodel can now be 'fir'!
%   - change default of opt.numpcstotry to 20
%   - PC regressors are now scaled to have standard deviation of 1
%   - xval scatter plots now are divided into red and green dots (and up to 20,000 each)
%   - pcselection figure uses a line now (not bar) and a selection circle is drawn
%   - no more skipping of the denoiseddata computation
% - 2012/11/03 - add a speed-up
% - 2012/11/02 - Initial version.
% - 2012/10/31 - add meanvol and change that it is the mean of all
% - 2012/10/30 - Automatic division of HRF!

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DEAL WITH INPUTS, ETC.

% input
if ~exist('hrfmodel','var') || isempty(hrfmodel)
  hrfmodel = 'optimize';
end
if ~exist('hrfknobs','var') || isempty(hrfknobs)
  if isequal(hrfmodel,'fir')
    hrfknobs = 20;
  else
    hrfknobs = normalizemax(getcanonicalhrf(stimdur,tr)');
  end
end
if ~exist('opt','var') || isempty(opt)
  opt = struct();
end
if ~exist('figuredir','var')
  figuredir = 'GLMdenoisefigures';
end

% massage input
if ~iscell(design)
  design = {design};
end
if ~iscell(data)
  data = {data};
end

% calc
numruns = length(design);
dataclass = class(data{1});
is3d = size(data{1},4) > 1;
if is3d
  dimdata = 3;
  dimtime = 4;
  xyzsize = sizefull(data{1},3);
else
  dimdata = 1;
  dimtime = 2;
  xyzsize = size(data{1},1);
end

% deal with defaults
if ~isfield(opt,'extraregressors') || isempty(opt.extraregressors)
  opt.extraregressors = cell(1,numruns);
end
if ~isfield(opt,'maxpolydeg') || isempty(opt.maxpolydeg)
  opt.maxpolydeg = zeros(1,numruns);
  for p=1:numruns
    opt.maxpolydeg(p) = round(((size(data{p},dimtime)*tr)/60)/2);
  end
end
if ~isfield(opt,'seed') || isempty(opt.seed)
  opt.seed = sum(100*clock);
end
if ~isfield(opt,'bootgroups') || isempty(opt.bootgroups)
  opt.bootgroups = ones(1,numruns);
end
if ~isfield(opt,'numforhrf') || isempty(opt.numforhrf)
  opt.numforhrf = 50;
end
if ~isfield(opt,'hrffitmask') || isempty(opt.hrffitmask)
  opt.hrffitmask = 1;
end
if ~isfield(opt,'brainthresh') || isempty(opt.brainthresh)
  opt.brainthresh = [99 0.5];
end
if ~isfield(opt,'brainR2') || isempty(opt.brainR2)
  opt.brainR2 = 0;
end
if ~isfield(opt,'numpcstotry') || isempty(opt.numpcstotry)
  opt.numpcstotry = 20;
end
if ~isfield(opt,'pcR2cutoff') || isempty(opt.pcR2cutoff)
  opt.pcR2cutoff = 0;
end
if ~isfield(opt,'pcR2cutoffmask') || isempty(opt.pcR2cutoffmask)
  opt.pcR2cutoffmask = 1;
end
if ~isfield(opt,'pcstop') || isempty(opt.pcstop)
  opt.pcstop = 1.05;
end
if ~isfield(opt,'numboots') || isempty(opt.numboots)
  opt.numboots = 100;
end
if ~isfield(opt,'denoisespec') || isempty(opt.denoisespec)
  opt.denoisespec = '11101';
end
if ~isfield(opt,'wantpercentbold') || isempty(opt.wantpercentbold)
  opt.wantpercentbold = 1;
end
if ~isfield(opt,'noiseWithinMask') || isempty(opt.noiseWithinMask)
  opt.noiseWithinMask = 0;
end
if ~isequal(hrfmodel,'fir')
  hrfknobs = normalizemax(hrfknobs);
end
if length(opt.maxpolydeg) == 1
  opt.maxpolydeg = repmat(opt.maxpolydeg,[1 numruns]);
end
if ~iscell(opt.extraregressors)
  opt.extraregressors = {opt.extraregressors};
end
if ~iscell(opt.denoisespec)
  opt.denoisespec = {opt.denoisespec};
end

% delete and/or make figuredir
if ~isempty(figuredir)
  if exist(figuredir,'dir')
    assert(rmdir(figuredir,'s'));
  end
  assert(mkdir(figuredir));
  assert(mkdir([figuredir '/PCmap']));
  figuredir = absolutepath(figuredir);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DETERMINE HRF

% if 'optimize', perform full-fit to determine HRF
switch hrfmodel
case 'optimize'
  fprintf('*** GLMdenoisedata: performing full fit to estimate global HRF. ***\n');
  fullfit = GLMestimatemodel(design,data,stimdur,tr,hrfmodel,hrfknobs,0,opt);
  hrf = fullfit.modelmd{1};
  hrffitvoxels = fullfit.hrffitvoxels;
  clear fullfit;

% if 'assume', the HRF is provided by the user
case 'assume'
  hrf = hrfknobs;
  hrffitvoxels = [];

% if 'fir', do nothing
case 'fir'
  hrffitvoxels = [];
  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CALCULATE CROSS-VALIDATED R^2 VALUES

% perform cross-validation to determine R^2 values
fprintf('*** GLMdenoisedata: performing cross-validation to determine R^2 values. ***\n');
switch hrfmodel
case {'optimize' 'assume'}
  xvalfit = GLMestimatemodel(design,data,stimdur,tr,'assume',hrf,-1,opt,1);
case 'fir'
  xvalfit = GLMestimatemodel(design,data,stimdur,tr,'fir',hrfknobs,-1,opt,1);
end
pcR2 = xvalfit.R2;
clear xvalfit;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DETERMINE NOISE POOL AND CALCULATE GLOBAL NOISE REGRESSORS

% determine noise pool
fprintf('*** GLMdenoisedata: determining noise pool. ***\n');
volcnt = cellfun(@(x) size(x,dimtime),data);
meanvol = reshape(catcell(2,cellfun(@(x) squish(mean(x,dimtime),dimdata),data,'UniformOutput',0)) ...
                  * (volcnt' / sum(volcnt)),[xyzsize 1]);
thresh = prctile(meanvol(:),opt.brainthresh(1))*opt.brainthresh(2);  % threshold for non-brain voxels 
bright = meanvol > thresh;                                           % logical indicating voxels that are bright (brain voxels)
badxval = pcR2 < opt.brainR2;                                        % logical indicating voxels with poor cross-validation accuracy
if opt.noiseWithinMask == 0
    noisepool = bright & badxval;                                        % logical indicating voxels that satisfy both criteria
else
    noisepool = bright & badxval & opt.noiseWithinMask; % logical indicating voxels that satisfy both criteria and are within specified noise voxels
end
% determine global noise regressors
fprintf('*** GLMdenoisedata: calculating global noise regressors. ***\n');
pcregressors = {};
for p=1:length(data)

  % extract the time-series data for the noise pool
  temp = subscript(squish(data{p},dimdata),{noisepool ':'})';  % time x voxels

  % project out polynomials from the data
  temp = projectionmatrix(constructpolynomialmatrix(size(temp,1),0:opt.maxpolydeg(p))) * temp;

  % unit-length normalize each time-series (ignoring any time-series that are all 0)
  [temp,len] = unitlengthfast(temp,1);
  temp = temp(:,len~=0);

  % perform SVD and select the top PCs
  [u,s,v] = svds(double(temp*temp'),opt.numpcstotry);
  u = bsxfun(@rdivide,u,std(u,[],1));  % scale so that std is 1
  pcregressors{p} = cast(u,dataclass);

end
clear temp len u s v;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ADD GLOBAL NOISE REGRESSORS INTO MODEL AND CHOOSE OPTIMAL NUMBER

% perform cross-validation with increasing number of global noise regressors
for p=1:opt.numpcstotry
  fprintf('*** GLMdenoisedata: performing cross-validation with %d PCs. ***\n',p);
  opt2 = opt;
  for q=1:numruns
    opt2.extraregressors{q} = cat(2,opt2.extraregressors{q},pcregressors{q}(:,1:p));
  end
  opt2.wantpercentbold = 0;  % no need to do this, so optimize for speed
  switch hrfmodel
  case {'optimize' 'assume'}
    xvalfit = GLMestimatemodel(design,data,stimdur,tr,'assume',hrf,-1,opt2,1);
  case 'fir'
    xvalfit = GLMestimatemodel(design,data,stimdur,tr,'fir',hrfknobs,-1,opt2,1);
  end
  pcR2 = cat(dimdata+1,pcR2,xvalfit.R2);
end
clear xvalfit;

% prepare to select optimal number of PCs
temp = squish(pcR2,dimdata);  % voxels x 1+pcs
pcvoxels = any(temp > opt.pcR2cutoff,2) & squish(opt.pcR2cutoffmask,dimdata);  % if pcR2cutoffmask is 1, this still works
xvaltrend = median(temp(pcvoxels,:),1);

% choose number of PCs
if opt.pcstop <= 0
  chosen = -opt.pcstop;  % in this case, the user decides
else
  curve = xvaltrend - xvaltrend(1);  % this is the performance curve that starts at 0 (corresponding to 0 PCs)
  mx = max(curve);                   % store the maximum of the curve
  best = -Inf;                       % initialize (this will hold the best performance observed thus far)
  for p=0:opt.numpcstotry
  
    % if better than best so far
    if curve(1+p) > best
    
      % record this number of PCs as the best
      chosen = p;
      best = curve(1+p);
      
      % if we are within opt.pcstop of the max, then we stop.
      if best*opt.pcstop >= mx
        break;
      end
      
    end
  
  end
end

% record the number of PCs
pcnum = chosen;
fprintf('*** GLMdenoisedata: selected number of PCs is %d. ***\n',pcnum);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FIT FINAL MODEL AND PREPARE OUTPUT

% fit final model
opt2 = opt;
for q=1:numruns
  opt2.extraregressors{q} = cat(2,opt2.extraregressors{q},pcregressors{q}(:,1:pcnum));
end
opt2.wantpercentbold = 0;  % do not do the conversion yet.  we will do it ourselves below.
fprintf('*** GLMdenoisedata: fitting final model. ***\n');
switch hrfmodel
case {'optimize' 'assume'}
  results = GLMestimatemodel(design,data,stimdur,tr,'assume',hrf,opt.numboots,opt2);
case 'fir'
  results = GLMestimatemodel(design,data,stimdur,tr,'fir',hrfknobs,opt.numboots,opt2);
end

% prepare additional outputs
results.hrffitvoxels = hrffitvoxels;  % note that this overrides the existing entry in results
results.meanvol = meanvol;
results.noisepool = noisepool;
results.pcregressors = pcregressors;
results.pcR2 = pcR2;
results.pcvoxels = reshape(pcvoxels,[xyzsize 1]);
results.pcnum = pcnum;
clear meanvol noisepool pcregressors pcR2 pcnum;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CALCULATE DENOISED DATA AND PCWEIGHTS

fprintf('*** GLMdenoisedata: calculating denoised data and PC weights. ***\n');

% for each run, perform regression to figure out the various contributions
denoiseddata = {};
results.pcweights = zeros([prod(xyzsize) results.pcnum numruns]);
for p=1:numruns

  % calc
  numtime = size(data{p},dimtime);

  % calculate signal contribution
  modelcomponent = GLMpredictresponses(results.modelmd,design{p},dimdata);  % X x Y x Z x T

  % prepare polynomial regressors
  polymatrix = constructpolynomialmatrix(numtime,0:opt.maxpolydeg(p));
  numpoly = size(polymatrix,2);

  % prepare other regressors
  exmatrix = opt.extraregressors{p};
  numex = size(exmatrix,2);

  % prepare global noise regressors
  pcmatrix = results.pcregressors{p}(:,1:results.pcnum);
  numpc = size(pcmatrix,2);

  % estimate weights
  h = olsmatrix2(cat(2,polymatrix,exmatrix,pcmatrix))*squish(data{p} - modelcomponent,dimdata)';  % parameters x voxels

  % record weights on global noise regressors
  results.pcweights(:,:,p) = h(numpoly+numex+(1:numpc),:)';
  
  % construct time-series
  polycomponent = reshape((polymatrix*h(1:numpoly,:))',[xyzsize numtime]);
  if numex == 0
    excomponent = zeros([xyzsize numtime],dataclass);
  else
    excomponent = reshape((exmatrix*h(numpoly+(1:numex),:))',[xyzsize numtime]);
  end
  if numpc == 0
    pccomponent = zeros([xyzsize numtime],dataclass);
  else
    pccomponent = reshape((pcmatrix*h(numpoly+numex+(1:numpc),:))',[xyzsize numtime]);
  end
  residcomponent = data{p} - (modelcomponent + polycomponent + excomponent + pccomponent);
  
  % construct denoised data
  for q=1:length(opt.denoisespec)
    denoiseddata{q,p} = bitget(bin2dec(opt.denoisespec{q}),5) * modelcomponent + ...
                       bitget(bin2dec(opt.denoisespec{q}),4) * polycomponent + ...
                       bitget(bin2dec(opt.denoisespec{q}),3) * excomponent + ...
                       bitget(bin2dec(opt.denoisespec{q}),2) * pccomponent + ...
                       bitget(bin2dec(opt.denoisespec{q}),1) * residcomponent;
  end

end

% clean up
clear modelcomponent h polycomponent excomponent pccomponent residcomponent;

% prepare for output
results.pcweights = reshape(results.pcweights,[xyzsize results.pcnum numruns]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PREPARE ADDITIONAL OUTPUTS

% return all the inputs (except for the data) in the output.
% also, include a new field 'datasize'.
results.inputs.design = design;
results.inputs.datasize = cellfun(@(x) size(x),data,'UniformOutput',0);
results.inputs.stimdur = stimdur;
results.inputs.tr = tr;
results.inputs.hrfmodel = hrfmodel;
results.inputs.hrfknobs = hrfknobs;
results.inputs.opt = opt;
results.inputs.figuredir = figuredir;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CONVERT TO % BOLD CHANGE

if opt.wantpercentbold
  fprintf('*** GLMdenoisedata: converting to percent BOLD change. ***\n');
  con = 1./abs(results.meanvol) * 100;
  switch hrfmodel
  case 'fir'
    results.models = bsxfun(@times,results.models,con);
    results.modelmd = bsxfun(@times,results.modelmd,con);
    results.modelse = bsxfun(@times,results.modelse,con);
  case {'assume' 'optimize'}
    results.models{2} = bsxfun(@times,results.models{2},con);
    results.modelmd{2} = bsxfun(@times,results.modelmd{2},con);
    results.modelse{2} = bsxfun(@times,results.modelse{2},con);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% GENERATE FIGURES

if ~isempty(figuredir)
  fprintf('*** GLMdenoisedata: generating figures. ***\n');

  % make figure showing HRF
  if ~isequal(hrfmodel,'fir')
    figureprep([100 100 450 250]); hold on;
    numinhrf = length(hrfknobs);
    h1 = plot(0:tr:(numinhrf-1)*tr,hrfknobs,'ro-');
    h2 = plot(0:tr:(numinhrf-1)*tr,results.modelmd{1},'bo-');
    ax = axis; axis([0 (numinhrf-1)*tr ax(3) 1.2]);
    straightline(0,'h','k-');
    legend([h1 h2],{'Initial HRF' 'Estimated HRF'});
    xlabel('Time from condition onset (s)');
    ylabel('Response');
    figurewrite('HRF',[],[],figuredir);
  end
  
  % write out image showing HRF fit voxels
  if isequal(hrfmodel,'optimize')
    imwrite(uint8(255*makeimagestack(results.hrffitvoxels,[0 1])),gray(256),[figuredir '/HRFfitvoxels.png']);
  end

  % make figure illustrating selection of number of PCs
  figureprep([100 100 400 400]); hold on;
  plot(0:opt.numpcstotry,xvaltrend,'r.-');
  set(scatter(results.pcnum,xvaltrend(1+results.pcnum),100,'ro'),'LineWidth',2);
  set(gca,'XTick',0:opt.numpcstotry);
  xlabel('Number of PCs');
  ylabel('Cross-validated R^2 (median across voxels)');
  title(sprintf('Selected PC number = %d',results.pcnum));
  figurewrite('PCselection',[],[],figuredir);
  
  % make figure showing scatter plots of cross-validated R^2
  rng = [min(results.pcR2(:)) max(results.pcR2(:))];
  for p=1:opt.numpcstotry
    temp = squish(results.pcR2,dimdata);  % voxels x 1+pcs
    figureprep([100 100 500 500]); hold on;
    scattersparse(temp(:,1),temp(:,1+p),20000,0,36,'g','.');
    scattersparse(temp(pcvoxels,1),temp(pcvoxels,1+p),20000,0,36,'r','.');
    axis([rng rng]); axissquarify; axis([rng rng]); 
    straightline(0,'h','y-');
    straightline(0,'v','y-');
    xlabel('Cross-validated R^2 (0 PCs)');
    ylabel(sprintf('Cross-validated R^2 (%d PCs)',p));
    title(sprintf('Number of PCs = %d',p));
    figurewrite(sprintf('PCscatter%02d',p),[],[],figuredir);
  end

  % write out image showing mean volume (of first run)
  imwrite(uint8(255*makeimagestack(results.meanvol,1)),gray(256),[figuredir '/MeanVolume.png']);

  % write out image showing noise pool
  imwrite(uint8(255*makeimagestack(results.noisepool,[0 1])),gray(256),[figuredir '/NoisePool.png']);

  % write out image showing voxel mask for HRF fitting
  if isequal(hrfmodel,'optimize') && ~isequal(opt.hrffitmask,1)
    imwrite(uint8(255*makeimagestack(opt.hrffitmask,[0 1])),gray(256),[figuredir '/HRFfitmask.png']);
  end

  % write out image showing voxel mask for PC selection
  if ~isequal(opt.pcR2cutoffmask,1)
    imwrite(uint8(255*makeimagestack(opt.pcR2cutoffmask,[0 1])),gray(256),[figuredir '/PCmask.png']);
  end
  
  % write out image showing the actual voxels used for PC selection
  imwrite(uint8(255*makeimagestack(results.pcvoxels,[0 1])),gray(256),[figuredir '/PCvoxels.png']);

  % define a function that will write out R^2 values to an image file
  imfun = @(results,filename) ...
    imwrite(uint8(255*makeimagestack(signedarraypower(results/100,0.5),[0 1])),hot(256),filename);

  % write out cross-validated R^2 for the various numbers of PCs
  for p=1:size(results.pcR2,dimdata+1)
    temp = subscript(results.pcR2,[repmat({':'},[1 dimdata]) {p}]);
    feval(imfun,temp,sprintf([figuredir '/PCcrossvalidation%02d.png'],p-1));
  end

  % write out overall R^2 for final model
  feval(imfun,results.R2,sprintf([figuredir '/FinalModel.png']));

  % write out R^2 separated by runs for final model
  for p=1:size(results.R2run,dimdata+1)
    temp = subscript(results.R2run,[repmat({':'},[1 dimdata]) {p}]);
    feval(imfun,temp,sprintf([figuredir '/FinalModel_run%02d.png'],p));
  end
  
  % write out signal, noise, and SNR
  imwrite(uint8(255*makeimagestack(results.signal,[0 prctile(results.signal(:),99)])),hot(256),[figuredir '/SNRsignal.png']);
  imwrite(uint8(255*makeimagestack(results.noise,[0 max(eps,prctile(results.noise(:),99))])),hot(256),[figuredir '/SNRnoise.png']);
  imwrite(uint8(255*makeimagestack(results.SNR,[0 10])),hot(256),[figuredir '/SNR.png']);
  
  % write out maps of pc weights
  thresh = prctile(abs(results.pcweights(:)),99);
  for p=1:size(results.pcweights,dimdata+1)
    for q=1:size(results.pcweights,dimdata+2)
      temp = subscript(results.pcweights,[repmat({':'},[1 dimdata]) {p} {q}]);
      imwrite(uint8(255*makeimagestack(temp,[-thresh thresh])),cmapsign(256), ...
              sprintf([figuredir '/PCmap/PCmap_run%02d_num%02d.png'],q,p));
    end
  end

end
