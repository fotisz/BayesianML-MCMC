function [muSamples, clusters] = collapsedGibbsBernoulliMixture(X,nComponents,nSamples,nBurnin,...
                                                    nThin,priorParams)
% Bayesian Bernoulli Mixture Model with collapsed Gibbs Sample
%
% Parameters
% ----------
% nComponents: integer
%     Number of components in mixture model
% 
% nSamples: integer, optional (DEFAULT = 10000)
%     Number of samples
%
% nBurnin: float, optional (DEFAULT = 0.25)
%    Proportion of samples that are discarded
% 
% nThin: int, optional (DEFAULT = 10)
%    Lag between samples (for thinnig)
% 
% priorParams: struct, optional
%    Parameters of latent variable distribution (after integrating out pr)
%    .latentPrior
%    .muBeta
%    .muGamma
% 
% Returns
% -------
% muSamples: 
%      Samples 
% logLike : 
%      Vector of loglikelihoods


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

[nDataSamples,nFeatures] = size(X);
if ~exist('priorParams','var')
    muBeta       = 2+2*rand(1);
    muGamma      = 2+2*rand(1);
    latentPrior  = 2+2*rand(1);    
else
    muBeta  = priorParams.muBeta;
    muGamma = priorParams.muGamma;
    latentPrior = priorParams.latentPrior;
end

% generate initial assignments of latent variables
latentVar = mnrnd(1,ones(1,nComponents)/nComponents,nDataSamples);
clusters  = zeros(nDataSamples,nSamples);
muSamples = zeros(nSamples,nFeatures);


for i = 1:(nSamples*nThin+nBurnin)
    
    Nk = sum(latentVar,1);
    Ck = latentVar'*X;
    % generate random permuatation 
    for j = 1:nDataSamples
        
        % remove sufficient stats for current point
        Nk_j = Nk - latentVar(j,:);
        Ck_j = Ck - kron(X(j,:),latentVar(j,:)');
        
        % compute log p(x | Z_{-i}, z_{i} = k) [not normalised]
        muBetaPost = muBeta + Ck_j;
        muGammaPost = muGamma + bsxfun(@minus,Nk_j',Ck_j);
        logSucces = bsxfun(@times,log(muBetaPost),X(j,:));
        logFail   = bsxfun(@times,log(muGammaPost),1 - X(j,:));
        logJoint  = log( bsxfun(@plus,Nk_j',muGamma + muBeta));
        logPx     = sum(logSucces + logFail,2)- nComponents*logJoint;
        
        % compute log p(z_{i} | Z_{-i}, X)
        logPz     = log(latentPrior + Nk_j) + logPx';
        Pz        = exp(bsxfun(@minus,logPz,logsumexp(logPz,2)));
        Pz        = bsxfun(@rdivide,Pz,sum(Pz,2));
        
        % sample from multinoulli distribution
        latentVar(j,:) = mnrnd(1,Pz,1);
        
        %update sufficient stats
        Nk = Nk_j + latentVar(j,:);
        Ck = Ck_j + kron(X(j,:),latentVar(j,:)');       
    end
        
    if i > nBurnin && mod(i-nBurnin,nThin)==0
       % accept sample after burnin & thinning
       idx = floor((i-nBurnin)/nThin);
       [Max,clusterIndex] = max(latentVar,[],2); 
       clusters(:,idx)    = clusterIndex
       
       % sample means from posterior
       
     
    end
    
    
end








