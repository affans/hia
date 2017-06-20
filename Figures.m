clear;
clc;

%%
load 'latent.dat'
load 'carriage.dat'
load 'symptomatic.dat'
load 'invasive.dat'
load 'recovered.dat'
load 'deadinvasive.dat'

TimeYears=30;

AveD=mean(deadinvasive');
for i=1:TimeYears
        YCumD(i)=sum(AveD(1,(i-1)*365+1:(i-1)*365+365));
end
figure(1)
plot(YCumD,'-o');
title('Death due to Invasive','fontsize',14)

Avelatent=mean(latent');
for i=1:TimeYears
        YCumlatent(i)=sum(Avelatent(1,(i-1)*365+1:(i-1)*365+365));
end

AveC=mean(carriage');
for i=1:TimeYears
        YCumC(i)=sum(AveC(1,(i-1)*365+1:(i-1)*365+365));
end

AveSymp=mean(symptomatic');
for i=1:TimeYears
        YCumsymp(i)=sum(AveSymp(1,(i-1)*365+1:(i-1)*365+365));
end

AveInv=mean(invasive');
for i=1:TimeYears
        YCumInv(i)=sum(AveInv(1,(i-1)*365+1:(i-1)*365+365));
end
%% averaging over years
figure(2)
subplot(2,2,1);
plot(YCumlatent,'-o');
title('Latent','fontsize',14)
subplot(2,2,2);
plot(YCumC,'-o');
title('Carriage','fontsize',14)
subplot(2,2,3);
plot(YCumsymp,'-o');
title('Symptomatic','fontsize',14)
subplot(2,2,4);
plot(YCumInv,'-o');
title('Invasive','fontsize',14)

%% incidence
figure(3)
subplot(2,2,1);
plot(mean(latent'));
title('Latent','fontsize',14)
subplot(2,2,2);
plot(mean(carriage'));
title('Carriage','fontsize',14)
subplot(2,2,3);
plot(mean(symptomatic'));
title('Symptomatic','fontsize',14)
subplot(2,2,4);
plot(mean(invasive'));
title('Invasive','fontsize',14)

%% cumulative incidence
figure(4)
subplot(2,2,1);
plot(cumsum(mean(latent')));
title('Cumulative Latent','fontsize',14)
subplot(2,2,2);
plot(cumsum(mean(carriage')));
title('Cumulative Carriage','fontsize',14)
subplot(2,2,3);
plot(cumsum(mean(symptomatic')));
title('Cumulative Symptomatic','fontsize',14)
subplot(2,2,4);
plot(cumsum(mean(invasive')));
title('Cumulative Invasive','fontsize',14)

%% cumulative invasive per year
TimeYears=30;
AveInc=mean(invasive');
for i=1:TimeYears
        YCumInv(i)=sum(AveInc(1,(i-1)*365+1:(i-1)*365+365));
end

figure(5)
plot(YCumInv,'-o')
title('Average Annual Invasive','fontsize',14)

%% All invasive curves
% nsims=50;
% for j=1:nsims
% for i=1:TimeYears
%         Invas(j,i)=sum(invasive((i-1)*365+1:(i-1)*365+365,j));
% end
% end
% plot(Invas','color',[0.75 0.75 0.75])
% hold on

% nsims=200;
% for jj=1:nsims
%     Avedeath(jj)=sum(deadinvasive(:,jj));
% end
% 
