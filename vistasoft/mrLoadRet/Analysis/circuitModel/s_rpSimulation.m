%
%
%
%
%

% Conditions on the weights so that the system converges
weights = zeros(5,5);

% Definition of values
1. Thalamus
2. Gaba
3. Glus
4. Glui
5. ES

% Forcing function - means the source of the input that causes the network
% to respond
% Thalamus in the case of healthy
% Extrastriate only lin the case of RP one-back
% Thalamus and extrastriate in the case of healthy and one-back

% updateRule:
v(ii,t) = v(ii,t-1) + v(:,t-1)*weights(ii,:);

% Predicted BOLD signal from circuit is
sum(v(:,t))



