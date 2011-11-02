function Y = surrogateDataFT(X)

% Generates one instance of surrogate data for a given multivariate time series data X
%Uses Fourier Transform to generate the surrogate data
%Inputs
%X - M * T time series data (M-# of channels, T - # of time samples)
%Output
% Y - Surrogate Data

% written by Srikanth Ryali, Vinod Menon lab 
% modified by Mohammad Dastjerdi, Parvizi lab 

Y = zeros(size(X,1),size(X,2));
N = size(X,2);             %Length of the time series
if mod(N,2)==1
    N= N-1;
    X(:,end)=[];
    Y(:,end)=[];
    for ch = 1:size(X,1)
        phi = unifrnd(0,2*pi,1,N/2-1);
        x = X(ch,:);
        Xf = fft(x);
        Yf = zeros(1,N);
        Yf(1) = Xf(1);
        Yf(N/2+1) = Xf(N/2+1);
        dR = exp(-i.*phi);
        Yf(2:N/2) = Xf(2:N/2).*dR;
        k = 0:N/2-2;
        lt = k(end);
        Yf(N:-1:N-lt) = conj(Yf(2:N/2));
        y = ifft(Yf);
        Y(ch,:) = y;
    end
    Y= [Y Y(:,end)];
else
    for ch = 1:size(X,1)
        phi = unifrnd(0,2*pi,1,N/2-1);
        x = X(ch,:);
        Xf = fft(x);
        Yf = zeros(1,N);
        Yf(1) = Xf(1);
        Yf(N/2+1) = Xf(N/2+1);
        dR = exp(-i.*phi);
        Yf(2:N/2) = Xf(2:N/2).*dR;
        k = 0:N/2-2;
        lt = k(end);
        Yf(N:-1:N-lt) = conj(Yf(2:N/2));
        y = ifft(Yf);
        Y(ch,:) = y;
    end
end
