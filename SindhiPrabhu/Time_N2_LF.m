clear all;
close all;
clc;

display('Nth (2) order Reconstruction');

N = 2;                  % Nth order nonuniform sampling
TQ = 1;Fs = 1/TQ;                 % Nyquist Period    

T = [1.5*TQ 3*TQ];      % Decimation Periods
K = 0.5*lcm(2*T(1), 2*T(2))/TQ; capT = K*TQ; M = capT./T;
ML = 400; % number of slices
w_c = 0.85;
NS = 100;  % Number of Sinusoids

% LF = lcm(M(1),M(2))*2*K*(1:70)+1;      % length of LF should be Multiple of LCM{M(p)}*2*K
LF = 84*(1:10)+1;      % length of LF should be Multiple of LCM{M(p)}*2*K

std = 1e-1;
taus = [0 1+std*randn]*TQ;    
tausI = sort([taus(1) taus(2) T(1)+taus(1)]);
% display(tausI);

Frq = rand(1,NS)*w_c/2;
Amp = rand(1,NS)/(sqrt(NS)*2);
Phi = rand(1,NS)*2*pi;

input = zeros(1,ML*K);
for k = 1:NS
  input = input + Amp(k)*sin(2*pi*Frq(k)*(0:ML*K-1)*TQ+Phi(k));
end;

tauI = zeros(K,ML);
for p = 1:K
    tauI(p,:) = tausI(p)+(0:ML-1)*capT;
end;

x11 = zeros(K,ML);
for k = 1:NS
    x11 = x11 + Amp(k)*sin(2*pi*Frq(k)*tauI+Phi(k));
end;

tauPr = zeros(K,ML);
for p = 1:K
    tauPr(p,:) = -tausI(p)+(0:ML-1)*capT;
end;
x1p = zeros(K,ML);
for k = 1:NS
    x1p = x1p + Amp(k)*sin(2*pi*Frq(k)*tauPr+Phi(k));
end;

timeP = zeros(size(LF));
timeE = zeros(size(LF));
timeI = zeros(size(LF));
timeV = zeros(size(LF));
timePr = zeros(size(LF));
timeJ = zeros(size(LF));

MC_runs = 1;
for rrr = 1:length(LF)
display(rrr);
n = -(LF(rrr)-1)/2:1:(LF(rrr)-1)/2;
for tt = 1:MC_runs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A realization of Digital Filter Banks for Reconstruction of Uniformly
% sampled signals from nonuniform samples
% Authors: Itami, Watanabe, Nishihara
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
a = zeros(1,K);
for p = 1:K
    a(p) = 1;
    for q = 1:K
        if q ~= p
                a(p) = a(p)/sin(pi*(tausI(p)-tausI(q))/capT);
        end;
    end;
end;
% c = sin(pi*(tausI(0+1))/capT);
% s = cos(pi*(tausI(0+1))/capT);
% b(1,1) = 0.5*(c+1i*s);
% c = sin(pi*(tausI(1+1))/capT);
% s = cos(pi*(tausI(1+1))/capT);
% b(1,2) = 0.5*(c+1i*s);
% b(3,:) = conj(b(1,:));
% b(2,:) = 0;

b = zeros(2*K-1,K);
c = -0.5*cos(pi*(tausI(1+1)+tausI(2+1))/capT);
s = -0.5*sin(pi*(tausI(1+1)+tausI(2+1))/capT);
b(1,1) = 0.5*(c+1i*s);
c = -0.5*cos(pi*(tausI(0+1)+tausI(2+1))/capT);
s = -0.5*sin(pi*(tausI(0+1)+tausI(2+1))/capT);
b(1,2) = 0.5*(c+1i*s);
c = -0.5*cos(pi*(tausI(0+1)+tausI(1+1))/capT);
s = -0.5*sin(pi*(tausI(0+1)+tausI(1+1))/capT);
b(1,3) = 0.5*(c+1i*s);
b(5,:) = conj(b(1,:));
b(2,:) = 0;
b(4,:) = conj(b(2,:));
c = 0.5*cos(pi*(tausI(2+1)-tausI(1+1))/capT);
b(3,1) = c;
c = 0.5*cos(pi*(tausI(2+1)-tausI(0+1))/capT);
b(3,2) = c;
c = 0.5*cos(pi*(tausI(1+1)-tausI(0+1))/capT);
b(3,3) = c;

y1=upsample(x11.',K).';

k = -(K-1):1:(K-1);
m = (0:1:(2*K-1))';
F = exp(1i*(pi/K).*kron(m,k));

y = zeros(K,size(y1,2));
for r = 1:K
    tempI = a(r)*y1(r,:);
    tempI2 = F*b(:,r);
    y2 = tempI2*tempI;
%     h = sinc((n/K)-tausI(r)/capT).*knab(LF,4,-tausI(r)/TQ).';
    h = sinc((n/K)-tausI(r)/capT).*kaiser_mine1(LF(rrr),3,-tausI(r)/TQ);
    for i=1:2*K
            h1 = upsample(downsample(h,2*K,i-1),2*K);
            temp = filter([zeros(1,i-1),1],1,h1);
%             y = y + filter(temp,1,y2(i,:));
            y2(i,:) = filter(temp,1,y2(i,:));
%             y2(i,:) = filter(h1,1,y2(i,:));
%             y2(i,:) = filter([zeros(1,i-1),1],1,y2(i,:));%,zeros(1,2*K-i)
    end;
    y(r,:) = sum(y2,1);
end;
y = (sum(y,1));
timeI(rrr) = timeI(rrr)+toc;
delayI = (length(n)-1)/2;
x=input(1:end-delayI);
y=y(1+delayI:end);
% y = y(160:end);
% x = x(160:end);
serI = 20*log10(norm(x,2)/norm(y-x,2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reconstruction of Nonuniformly Sampled Band-Limited Signals
% Using a Differentiator-Multiplier Cascade
% Authors: Stefan Tertinek and Christian Vogel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
r = tausI-TQ*(0:K-1);
rr = r(mod((0:ML*K-1),K)+1);
x1 = reshape(x11,1,K*size(x11,2));
% x1 = x11;% LF = (0:11); Fs = 1;
% Differentiator Design
% figure();
% NFFT = 2^nextpow2(length(Hd)); % Next power of 2 from length of Hd
% HD = fftshift(fft(Hd,NFFT))/length(Hd);
% f = Fs*linspace(-1,1,NFFT);
% % Plot double-sided amplitude spectrum.
% plot(f,2*abs(HD(1:NFFT))) 
% title('Double-Sided Amplitude Spectrum of Hd(n)')
% xlabel('Frequency (Hz)')
% ylabel('|HD(f)|')
tic
Hd = firpm(LF(rrr)-1,[0 w_c],[0 w_c*pi],'differentiator');
delayV = (LF(rrr)-1)/2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
y1 = filter(Hd,1,x1);
x1 = filter([zeros(1,delayV),1],1,x1);
r2 = filter([zeros(1,delayV),1],1,rr);
e = y1.*r2;
y1 = x1-e;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
y2 = filter(Hd,1,y1);
temp = filter([zeros(1,delayV),1],1,y2);
x1 = filter([zeros(1,2*delayV),1],1,x1);
r2 = filter([zeros(1,2*delayV),1],1,r2);
e1 = temp.*r2;
y2 = filter(Hd,1,y2);
e2 = 0.5*y2.*r2.^2;
y2 = x1-e1-e2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
y3 = filter(Hd,1,y2);
temp = filter([zeros(1,2*delayV),1],1,y3);
x1 = filter([zeros(1,3*delayV),1],1,x1);
r2 = filter([zeros(1,3*delayV),1],1,r2);
e1 = temp.*r2;
y3 = filter(Hd,1,y3);
temp = filter([zeros(1,delayV),1],1,y3);
e2 = 0.5*temp.*r2.^2;
y3 = filter(Hd,1,y3);
e3 = (y3.*r2.^3)/6;
y3 = x1-e1-e2-e3;
timeV(rrr) = timeV(rrr)+toc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
y = real(y3(1+6*delayV:end));
x = input(1:end-6*delayV);
serV = 20*log10(norm(x,2)/norm(y-x,2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reconstruction of Band-Limited Periodic Nonuniformly Sampled Signals 
% Through Multirate Filter Banks
% Ryan S Prendergast, Bernard C Levy, Paul J Hurst
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
H = zeros(K,LF(rrr));
for i=1:K
%     H(i,:) = sinc(n-tausI(i)).*conv(sinc(n-tausI(i)),kaiser(LF,34).','same');
%     H(i,:) = sinc(n-tausI(i)).*knab(LF,34,-tausI(i)).';
    H(i,:) = sinc(n-tausI(i)).*kaiser_mine1(LF(rrr),18,-tausI(i));
end;
H = H(:,1:end-1);
EP = reshape(H.',K,length(H(1,:))/K,K);
capE = [];
for k=1:K
    temp = [];
    for i=1:K
        temp=[temp,toeplitz([EP(i,1,k),zeros(1,(length(H(1,:))/K)-1)],[EP(i,:,k),zeros(1,(length(H(1,:))/K)-1)])];
    end
    capE = [capE;temp];
end
d = ceil(size(capE,2)/(2*K));
P = kron(eye(K),[zeros(1,d),1,zeros(1,(size(capE,2)/K)-d-1)]);
R = P/capE;
% size(capE) 
% size(zeros(LF-1,2*LF-2-K))
% size(R)
% size(zeros(K,LF-1))
% size(P)
% size(zeros(K,2*LF-2-K))
R = upsample(R.',K).';
rt = size(R,2)/K;
FR = zeros(K,rt);
for j=1:K
    for i=1:K
        temp = filter([zeros(1,K-i),1],1,R(i,(j-1)*rt+1:j*rt));
        FR(j,:) = FR(j,:)+temp;
    end
end
yb = upsample(x1p.',K).';
for i = 1:K
    yb(i,:) = filter(FR(i,:),1,yb(i,:));
end;
y = sum(yb,1);
timePr(rrr) = timePr(rrr)+toc;
delayPr = (size(FR,2))/2+K-1;
x=input(1:end-delayPr);
y=y(1+delayPr:end);
serPr = 20*log10(norm(x,2)/norm(y-x,2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reconstruction of Periodically Nonuniformly Sampled Bandlimited Signals
% Using Time-Varying FIR Filters
% Authors: H. Johansson and Per Lowenborg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
r = r.';
x1 = reshape(x11,1,size(x11,2)*K);
tic
w_o = w_c*pi*TQ;
hJ = zeros(K,LF(rrr));
C = zeros(1,LF(rrr));
Nt = (LF(rrr)-1)/2;
for i = 1:K
    C = -2*sin(w_o*(n-r(1+(mod(i-1-n,K)))'))./(pi*(n-r(1+(mod(i-1-n,K)))'));
    C(isnan(C)==1)=-2*w_o/pi;
    C = C.';
    S = zeros(LF(rrr),LF(rrr));
    for k = 1:LF
        S(k,:) = sin(w_o*(-Nt+k-1-r(1+(mod(i-1-(-Nt+k-1),K)))-(n-r(1+(mod(i-1-n,K)))')))./(pi*(-Nt+k-1-r(1+(mod(i-1-(-Nt+k-1),K)))-(n-r(1+(mod(i-1-n,K)))')));
    end;
    S(isnan(S)==1)=w_o/pi;
    hJ(i,:) = -0.5*S\C;
end;

y1 = zeros(K,length(x1));
for j=1:K
    y1(j,:) = filter(hJ(j,:),1,x1);
    y1(j,:) = upsample(downsample(y1(j,:),K,j-1),K)/K;
    y1(j,:) = filter([zeros(1,j-1),1],1,y1(j,:));
end;
y = K*0.25*sum(y1,1);
timeJ(rrr) = timeJ(rrr)+toc;
delayJ = (size(hJ,2)-1)/2;
y = real(y(1+delayJ:end));
x = input(1:end-delayJ);
serJ = 20*log10(norm(x,2)/norm(y-x,2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filterbank Reconstruction of Bandlimited Signals from Nonuniform and
% Generalized Samples 
% Authors: Y C Eldar and A V Oppenheim
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

y = zeros(N,ML*K);
for p = 1:N
    tau = taus(p)+(0:ML*M(p)-1)*T(p);
    x1 = zeros(1,ML*M(p));
    for k = 1:NS
        x1 = x1 + Amp(k)*sin(2*pi*Frq(k)*tau+Phi(k));
    end;
    tic
    y1 = upsample(x1,K);
    
    LFE = M(p)*84*rrr+1;      % length of LF should be Multiple of LCM{M(p)}*2*K
    nE = -(LFE-1)/2:1:(LFE-1)/2;
    h = sinc((nE/K)-(taus(p)/T(p))).*kaiser_mine1(LFE,3,-K*(taus(p)/T(p)));

%%%%%%%%%%%%%%%%%%%%%%%%%%% Implementation 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%
%     bb = zeros(2*(K-M(p))+1,M(p));
%     aaa = ones(1,M(p));
%     bbvl = zeros(M(p),LFE);
%     for l = 1:M(p)
%         for q = 1:N
%             if q ~= p
%                 aaa(l) = aaa(l)*sin(pi*(taus(p)-taus(q)+(l-1)*T(p))/T(q));
%                 c = sin(pi*M(q)*(-taus(q)+(l-1)*T(p))/capT);
%                 s = cos(pi*M(q)*(taus(q)-(l-1)*T(p))/capT);
%                 bb(2*M(q)+1,l) = 0.5*(c-1i*s);
%                 bb(1,l) = conj(bb(2*M(q)+1,l));
%             end;
%         end;
%         bbv = zeros(2*(K-M(p))+1,LFE);
%         for v = -(K-M(p)):K-M(p)
%             bbv(K-M(p)+1+v,:) = bb(K-M(p)+1+v,l)*exp(1i*(pi/(K*M(p)))*v*nE);
%         end;
%         bbvl(l,:) = sum(bbv,1)/aaa(l);
%     end;
%     bbb = zeros(M(p),LFE);
%     bbn = zeros(M(p),LFE);
%     for m = 1:M(p)
%         for l = 1:M(p)
%             bbb(l,:) = bbvl(l,:)*exp(1i*(2*pi/M(p))*(m-1)*(l-1));
%         end
%         bbb = sum(bbb,1);
%         bbn(m,:) = bbb.*exp(1i*(2*pi/M(p))*(m-1)*nE);
%     end;
%     bbn = sum(bbn,1);
%     bbn = bbn.*h/M(p);

%%%%%%%%%%%%%%%%%%%%%%%%%%% Implementation 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%
%     bb = zeros(2*(K-M(p))+1,M(p));
%     aaa = ones(1,M(p));
%     for l = 1:M(p)
%         for q = 1:N
%             if q ~= p
%                 aaa(l) = aaa(l)/sin(pi*(taus(p)-taus(q)+(l-1)*T(p))/T(q));
%                 c = sin(pi*M(q)*(-taus(q)+(l-1)*T(p))/capT);
%                 s = cos(pi*M(q)*(taus(q)-(l-1)*T(p))/capT);
%                 bb(2*M(q)+1,l) = 0.5*(c-1i*s);
%                 bb(1,l) = conj(bb(2*M(q)+1,l));
%             end;
%         end;
%     end;
%     AE = diag(aaa);
%     BE = bb.';
%     
%     dim = K-M(p); w = -dim:1:dim;
%     FE = exp(1i*(pi/(K*M(p))).*kron(nE,w'));
% 
%     E1E = exp(1i*(2*pi/M(p)).*kron((0:M(p)-1),(0:M(p)-1)'))/M(p);
% 
%     E2E = exp(1i*(2*pi/M(p)).*kron(nE,(0:M(p)-1)'));
% 
%     temp = E1E*AE*BE*FE;
%     bbn = h.*sum(E2E.*temp,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%% Implementation 3 %%%%%%%%%%%%%%%%%%%%%%%%%%%
    aaa = ones(1,M(p));
    bb = ones(M(p),LFE);
    for l = 1:M(p)
        for q = 1:N
            if q ~= p
                aaa(l) = aaa(l)*sin(pi*(taus(p)-taus(q)+(l-1)*T(p))/T(q));
                bb(l,:) = bb(l,:).*sin(pi*((nE*TQ/M(p))-taus(q)+(l-1)*T(p))/T(q));
            end;
        end;
        bb(l,:) = bb(l,:)/aaa(l);
    end;

    bbb = zeros(M(p),LFE);
    bbn = zeros(M(p),LFE);
    for m = 1:M(p)
        for l = 1:M(p)
            bbb(l,:) = bb(l,:)*exp(1i*(2*pi/M(p))*(m-1)*(l-1));
        end
        bbb = sum(bbb,1);
        bbn(m,:) = bbb.*exp(1i*(2*pi/M(p))*(m-1)*nE);
    end;
    bbn = sum(bbn,1);
    bbn = bbn.*h/M(p);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    y1 = conv(y1,bbn);
    delayE = (length(h)-1)/2;
    y(p,:) = y1(1+delayE:M(p):end-delayE);
    timeE(rrr) = timeE(rrr)+toc;
end;
y = sum(real(y),1);
x = input;
% y = y(160:end);
% x = x(160:end);
serE = 20*log10(norm(x,2)/norm(y-x,2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reconstruction of N-th order nonuniformly sampled bandlimited signals
% using digital filter banks
% Authors: S. K. Sindhi, K. M. M. Prabhu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xp = zeros(N,ML*K);
for p = 1:N
    tau = taus(p)+(0:ML*M(p)-1)*T(p);
    x1 = zeros(1,ML*M(p));
    for k = 1:NS
        x1 = x1 + Amp(k)*sin(2*pi*Frq(k)*tau+Phi(k));
    end;
    
    tic
    m = (0:1:M(p)-1)'; lemda = 0:1:M(p)-1;
    W = exp(1i*(2*pi/M(p)).*kron(m,lemda)); % m*lemda
    
    bb = zeros(2*(K-M(p))+1,M(p));
    aaa = ones(1,M(p));
    for l = 1:M(p)
        for q = 1:N
            if q ~= p
                    aaa(l) = aaa(l)/sin(pi*M(q)*(taus(p)-taus(q)+(l-1)*T(p))/capT);
                    c = sin(pi*M(q)*(-taus(q)+(l-1)*T(p))/capT);
                    s = cos(pi*M(q)*(taus(q)-(l-1)*T(p))/capT);
                    bb(2*M(q)+1,l) = 0.5*(c-1i*s);
                    bb(1,l) = conj(bb(2*M(q)+1,l));                        
            end;
        end;
    end;
    A = diag(aaa); % display(A);
    B = bb; % display(B);
    
    y1 = upsample(x1,K);
    y1 = reshape(y1,M(p),length(y1)/M(p));

    if M(p)>1
        y1(2:end,:) = flipud(y1(2:end,:));
        for i = 1:M(p)-1
            y1(i+1,:) = filter([0,1],1,y1(i+1,:));
        end;
    end;

    dim = K-M(p); w = -dim:1:dim;

    xlemda = zeros(M(p),size(y1,2));
    for lemda = 0:M(p)-1

        rP = (lemda/M(p))+(0:1:(2*K-1))';
        Fshift = exp(1i*(pi/K).*kron(rP,w));   % r*w

%         h = sinc((n*TQ/T(p))+(lemda/K)-(taus(p)/T(p))).*knab(LF,4,(lemda/M(p))-(taus(p)/TQ)).';
        h = sinc((n*TQ/T(p))+(lemda/K)-(taus(p)/T(p))).*kaiser_mine1(LF(rrr),3,(lemda/M(p))-(taus(p)/TQ));
        mtemp = A*W;
        mtemp = B*mtemp;
        mtemp = Fshift*mtemp;
        mtemp = mtemp*W(:,lemda+1);
        y2 = mtemp*y1(lemda+1,:);
        for i=1:2*K
            h1 = upsample(downsample(h,2*K,i-1),2*K);
%             y2(i,:) = filter(h1,1,y2(i,:));
%             y2(i,:) = filter([zeros(1,i-1),1],1,y2(i,:));%,zeros(1,2*K-i)
            temp = filter([zeros(1,i-1),1],1,h1);
            y2(i,:) = filter(temp,1,y2(i,:));
        end;
        xlemda(lemda+1,:) = sum(y2,1);
    end;
    xp(p,:) = sum(xlemda,1)/M(p);
    clear bb;
    timeP(rrr) = timeP(rrr)+toc;
end;
y = real(sum(xp,1));
delayP = (length(h)-1)/2;
y = y(1+delayP:end);
x = input(1:end-delayP);
serP = 20*log10(norm(x,2)/norm(y-x,2));
end;
end;
timeP = timeP/MC_runs;
timeE = timeE/MC_runs;
timeI = timeI/MC_runs;
timeV = timeV/MC_runs;
timePr = timePr/MC_runs;
timeJ = timeJ/MC_runs;

figure();hold on;
plot(LF,timeJ,'kp-','LineWidth',2);
plot(LF,timePr,'ko-','LineWidth',2);
plot(LF,timeV,'ks-','LineWidth',2);
plot(LF,timeP,'kd-','LineWidth',2);
plot(LF,timeI,'k>-','LineWidth',2);
plot(LF,timeE,'k+-','LineWidth',2);
legend('Johansson','Prendergast','Tertinek','Proposed','Itami','Eldar');
xlabel('Filter length','fontsize',14,'fontweight','b');
ylabel('Time in seconds','fontsize',14,'fontweight','b');
grid on;box on;
set(gca,'fontsize',14,'fontweight','b')

% temp = (LF.^3);%+(K*LF*ML*K);
% temp = temp/max(temp);
% timePrI = timePr(rrr)*temp;
% 
% temp = (LF.^3);%+(K*(LF+1)*ML*K);
% temp = temp/max(temp);
% timeJI = timeJ(rrr)*temp;
% 
% temp = (LF.^2);%+(6*LF*ML*K);
% temp = temp/max(temp);
% timeVI = timeV(rrr)*temp;
% plot(LF,timePrI,'k--','LineWidth',2);
% plot(LF,timeJI,'k--','LineWidth',2);
% plot(LF,timeVI,'k--','LineWidth',2);

figure();hold on;
plot(LF,timeJ,'kp-','LineWidth',2);
temp = (LF.^3);%+(K*(LF+1)*ML*K);
temp = temp/max(temp);
timeJI = timeJ(rrr)*temp;
plot(LF,timeJI,'k--','LineWidth',2);
legend('Johansson','Ideal curve');
xlabel('Filter length','fontsize',14,'fontweight','b');
ylabel('Time in seconds','fontsize',14,'fontweight','b');
grid on;box on;
set(gca,'fontsize',14,'fontweight','b')

figure();hold on;
plot(LF,timePr,'ko-','LineWidth',2);
temp = (LF.^3);%+(K*LF*ML*K);
temp = temp/max(temp);
timePrI = timePr(rrr)*temp;
plot(LF,timePrI,'k--','LineWidth',2);
legend('Prendergast','Ideal curve');
xlabel('Filter length','fontsize',14,'fontweight','b');
ylabel('Time in seconds','fontsize',14,'fontweight','b');
grid on;box on;
set(gca,'fontsize',14,'fontweight','b')

figure();hold on;
plot(LF,timeV,'ks-','LineWidth',2);
temp = (LF.^2);%+(6*LF*ML*K);
temp = temp/max(temp);
timeVI = timeV(rrr)*temp;
plot(LF,timeVI,'k--','LineWidth',2);
legend('Tertinek','Ideal curve');
xlabel('Filter length','fontsize',14,'fontweight','b');
ylabel('Time in seconds','fontsize',14,'fontweight','b');
grid on;box on;
set(gca,'fontsize',14,'fontweight','b')

% hold on;
% temp = (2*3*(85:84:841)*400*3);
% temp = temp/max(temp);
% timeII = 0.01729*temp;
% plot((85:84:841),timeII,'g');

display(serI)
display(serV)
display(serPr)
display(serJ)
display(serP)
display(serE)

% LF = 84*(1:30)+1;      % length of LF should be Multiple of LCM{M(p)}*2*K
% timeJ = [timeJ,zeros(1,length(1:length(LF)-10))];
% for rrr = 11:length(LF)
% display(rrr);
% n = -(LF(rrr)-1)/2:1:(LF(rrr)-1)/2;
% for tt = 1:MC_runs
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Reconstruction of Periodically Nonuniformly Sampled Bandlimited Signals
% % Using Time-Varying FIR Filters
% % Authors: H. Johansson and Per Lowenborg
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% r = tausI-TQ*(0:K-1);
% r = r.';
% x1 = reshape(x11,1,size(x11,2)*K);
% tic
% w_o = w_c*pi*TQ;
% hJ = zeros(K,LF(rrr));
% C = zeros(1,LF(rrr));
% Nt = (LF(rrr)-1)/2;
% for i = 1:K
%     C = -2*sin(w_o*(n-r(1+(mod(i-1-n,K)))'))./(pi*(n-r(1+(mod(i-1-n,K)))'));
%     C(isnan(C)==1)=-2*w_o/pi;
%     C = C.';
%     S = zeros(LF(rrr),LF(rrr));
%     for k = 1:LF
%         S(k,:) = sin(w_o*(-Nt+k-1-r(1+(mod(i-1-(-Nt+k-1),K)))-(n-r(1+(mod(i-1-n,K)))')))./(pi*(-Nt+k-1-r(1+(mod(i-1-(-Nt+k-1),K)))-(n-r(1+(mod(i-1-n,K)))')));
%     end;
%     S(isnan(S)==1)=w_o/pi;
%     hJ(i,:) = -0.5*S\C;
% end;
% 
% y1 = zeros(K,length(x1));
% for j=1:K
%     y1(j,:) = filter(hJ(j,:),1,x1);
%     y1(j,:) = upsample(downsample(y1(j,:),K,j-1),K)/K;
%     y1(j,:) = filter([zeros(1,j-1),1],1,y1(j,:));
% end;
% y = K*0.25*sum(y1,1);
% timeJ(rrr) = timeJ(rrr)+toc;
% delayJ = (size(hJ,2)-1)/2;
% y = real(y(1+delayJ:end));
% x = input(1:end-delayJ);
% serJ = 20*log10(norm(x,2)/norm(y-x,2));
% end;
% end;
% timeJ(11:length(LF)) = timeJ(11:length(LF))/MC_runs;
% figure();hold on;
% plot(LF,timeJ,'kp-','LineWidth',2);
% temp = (LF.^3);%+(K*(LF+1)*ML*K);
% temp = temp/max(temp);
% timeJI = timeJ(rrr)*temp;
% plot(LF,timeJI,'k--','LineWidth',2);
% legend('Johansson','Prendergast','Tertinek','Proposed','Itami','Eldar');
% xlabel('Filter length','fontsize',14,'fontweight','b');
% ylabel('Time in seconds','fontsize',14,'fontweight','b');
% grid on;box on;
% set(gca,'fontsize',14,'fontweight','b')

% figure();
% subplot(2,1,1);
% plot(([x' y']));
% title('input / output signals');
% xlabel('sample');
% ylabel('signal value');
% grid on;
% subplot(2,1,2);
% plot((x'-y'));
% xlabel('time (sample)');
% ylabel('error value');
% grid on;