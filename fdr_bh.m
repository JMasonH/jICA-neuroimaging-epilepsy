function [h, crit_p, adj_p] = fdr_bh(pvals, q, method)
% FDR_BH Implements the Benjamini-Hochberg procedure for controlling the false discovery rate.
% [h, crit_p, adj_p] = fdr_bh(pvals, q, method) controls the FDR.
%
% INPUT:
% pvals - A vector of p-values.
% q - The desired false discovery rate level.
% method - 'pdep' or 'dep' for independent or positively dependent tests.

if nargin < 3
    method = 'pdep';
end

pvals = pvals(:);
m = length(pvals);
[sorted_pvals, sort_idx] = sort(pvals);
[~, unsort_idx] = sort(sort_idx);

if strcmp(method, 'pdep')
    % Benjamini-Hochberg procedure for independent tests
    cVID = 1;
    cVN = sum(1./(1:m));
elseif strcmp(method, 'dep')
    % Benjamini-Hochberg procedure for dependent tests
    cVID = sum(1./(1:m));
    cVN = cVID;
else
    error('Invalid method specified. Use ''pdep'' or ''dep''.');
end

thresholds = (1:m)'/m*q/cVID;
h = sorted_pvals <= thresholds;
if any(h)
    crit_p = sorted_pvals(find(h, 1, 'last'));
    h = sorted_pvals <= crit_p;
else
    crit_p = NaN;
    h = zeros(m, 1);
end

adj_p = min(1, sorted_pvals*cVN);
adj_p = adj_p(unsort_idx);
h = h(unsort_idx);

end
