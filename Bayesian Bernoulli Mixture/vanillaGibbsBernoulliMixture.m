function [ muSamples, clusters, logLike ] = vanillaGibbsBernoulliMixture(X,nComponents,nSamples,nBurnin,...
                                                    nThin,priorParams)
% Bernoulli Mixture Model implemented with Vanilla Gibbs Sample
% 
% Parameters
% ----------
% nComponents: integer
%    Number of components in mixture model
%
% nSamples: integer, optional (DEFAULT = 10000)
%    Number of samples
%
% nBurnin: float, optional (DEFAULT = 0.25)
%    Proportion of samples that are discarded
% 
% nThin: int, optional (DEFAULT = 10)
%    Lag between samples (for thinnig)
% 
% priorParams: struct, optional
%    Parameters of prior distribution
%    .latentDist : prior for latent distribution [1,nComponents]
%    .muAlpha : shape parameter for mean prior [nComponents,nFeatures]
%    .muBeta : shape parameter for mean prior [nComponents,nFeatures]
%
% Returns
% -------
% muSamples: samples of success probability vectors
% logLike:   vector of log likelihoods
% 

% handle optional parameters
if ~exist('nSamples','var')
    nSamples = 10000;
end          
if ~exist('nBurnin','var')
    nBurnin  = 2500;
end
if ~exist('nThin','var')
    nThin    = 10;
end

% number of datapoints & dimensionality
[nDataSamples,nFeatures] = size(X);
if ~exist('priorParams','var')
    latentDist = 1 + rand(1,nComponents);
    muAlpha    = 1 + rand(nComponents,nFeatures);
    muBeta     = 1 + rand(nComponents,nFeatures);
else
    latentDist = priorParams.latentDist;
    muAlpha  = priorParams.muAlpha;
    muBeta   = priorParams.muBeta;
end

% start Gibbs Sampler & allocate memory
muSample   = betarnd(muAlpha,muBeta);
prSample   = dirchrnd(latentDist);
resps      = zeros(nDataSamples,nComponents);
muSamples  = zeros(nComponents,nFeatures,nSamples);
logLike    = zeros(nSamples*nThin + nBurnin);
clusters   = zeros(nDataSamples,nSamples);
            
for i = 1:(nSamples*nThin+nBurnin)
                
    % compute responsibilities for sampling from latent
    for k = 1:nComponents
        resps(:,k) = binologpdf(X,muSample(k,:));
        resps(:,k) = resps(:,k) + prSample(k);
    end
    resps = exp(bsxfun(@minus,resps,logsumexp(resps,2)));
    resps = bsxfun(@rdivide,resps,sum(resps,2));
                
    % sample p( z_i | X, Z_{-i}, mu, pr )
    latentSample = mnrnd(1,resps,nDataSamples);
    Nk = sum(latentSample,1);
    Xweighted = latentSample'*X;
    IXweighted = -bsxfun(@minus,Xweighted,Nk');

    % sample p( pr | X, Z, mu_{1:k} )
    prSample = dirchrnd( latentDist + Nk);
    
    % sample p( mu_k | X, Z, mu_{-k}, pr )
    muSample = betarnd(muAlpha + Xweighted,muBeta + IXweighted);
    
    % compute log-likelihood
    % logLike(i) = 
                
    if i > nBurnin && mod(i-nBurnin,nThin)==0
       % accept sample after burnin & thinning
       idx = floor((i-nBurnin)/nThin);
       muSamples(:,:,idx) = muSample;
       [Max,clusterIndex] = max(latentSamples,[],2); 
       clusters(:,idx)    = clusterIndex;
    end
end

end
