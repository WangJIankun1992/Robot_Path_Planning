% Satellite examples,
% 1.First Construct a scenario 15 satellites and 5,000 satellites
% 2. Do linear all exclusive mutual information --> over
% time,sensors,targets ----->  Take in all the covariances and solve for
% the assignment variables
% 2. Exhaustive Search: Greedy time, Greedy Sensor, Greedy Target ----->  Take in all the covariances and solve for
% the assignment variables

%% Simulation options
close all
clear all
clc

redoSATTRAJ=1;
filename='SavedData/SATELLIIETASKING_MAIN_sat_1__greedysensor_15sats.mat';



%% Constants

Nsat=10;
Nrad=2;
dt=5*60; % in seconds
Tf=(24)*60*60; % in seconds
Tvec=0:dt:Tf;
plotTvec=0:5*60:Tf;
Ntimesteps=length(Tvec);
Re=6378.1;

SensTaskHorizon=5;

%% Simulation Structures

Constants.Nsat=Nsat;
Constants.Nrad=Nrad;
Constants.dt=dt;
Constants.Tf=Tf;
Constants.Tvec=Tvec;
Constants.plotTvec=plotTvec;
Constants.Ntimesteps=Ntimesteps;
Constants.Re=Re;
Constants.SensTaskHorizon=SensTaskHorizon;

Radars=cell(Nrad,1);
Satellites=cell(Nsat,1);


MeasPairs=cell(Constants.Ntimesteps ,1);
for i=1:1:Constants.Ntimesteps
    MeasPairs{i}=-1*ones(Constants.Nsat,Constants.Nrad);
end
% MeasPairs{1}(i,j)
%               j=1,rad1  j=2,rad2   j=3,rad3  j=4,rad4   ...
% i=1 sat1
% i=2 sat2
% i=3 sat3
% .
% .
% .



%% radars (lat,long, altitude) in geod+edic
close all
nsens_out=3;
% (th,phi,ConeAngle,MaxRange) --> (perp to equaltor, along equator)
Ang=[100*pi/180    0  pi/3 4500
    60*pi/180    60*pi/180 pi/3 3500
    -80*pi/180    -20*pi/180 pi/3 2500
    
    115*pi/180    90*pi/180 pi/3 2500
    110*pi/180    0*pi/180 pi/3 2500
    80*pi/180    0*pi/180 pi/3 2500
    75*pi/180    90*pi/180 pi/3 2500
    
    0.1437   -0.0168 pi/3 1500
    -0.1357   -0.0114 pi/3 1500
    
    0.1663   -3.0993 pi/3 3000
    -0.1549   -3.0988 pi/3 3000];

RadPos=zeros(size(Ang,1),3);
k=1;

for i=1:1:Constants.Nrad
    %     Radars{i}.PolarPositions=[];
    %     Radars{i}.R =[];
    Radars{i}.hn=nsens_out;
    Radars{i}.penalty=1000;
    Radars{i}.G=@(x,RadPosPolar,hn,ConeAngle,MaxDepth,pen)radar_sens_penalty(x,RadPosPolar,hn,ConeAngle,MaxDepth,pen);
    Radars{i}.h=@(x,RadPosPolar,hn)radar_sens_cart(x,RadPosPolar,hn);
    
    %
    Radars{i}.PolarPositions=[Ang(i,1),Ang(i,2),Constants.Re];
    Radars{i}.ConeAngle=Ang(i,3);
    Radars{i}.MaxRange=Ang(i,4);
    
    %     R=blkdiag((0.2*pi/180)^2,(0.2*pi/180)^2);
    R=blkdiag( (0.1)^2, (2*pi/180)^2, (2*pi/180)^2 );
    %     Radars{i}.R=vertcat(Radars{i}.R, reshape(R,1,Radars{i}.hn^2) );
    Radars{i}.R=R;
end


% plot_radar_system2(Radars,Constants,yplottruth)
% plot_sat_radar_system2(Satellites,Radars,Constants,yplottruth)

%% Set Sattelite Properties
% figure
% hold on
P0=blkdiag(0.01,0.01,0.01,1e-8,1e-8,1e-8);

for i=1:1:Constants.Nsat
    Satellites{i}.HighlightPlotTraj=0 ;
    Satellites{i}.Q=P0/10000000;
    Satellites{i}.f=@(t,x)twoBody(t,x);
    Satellites{i}.StateDynamics='continuous';
    Satellites{i}.fn=6;
    
end

if redoSATTRAJ==1
    Xsat0=getInitialrv_3D_2(Constants.Nsat);
    opt = odeset('reltol',1e-12,'abstol',1e-12);
    ytruth=cell(Nsat,1);
    ytruth_orb=cell(Nsat,1);
    yplottruth=cell(Nsat,1);
    
    
    parfor i=1:Nsat
        
        [X,w]=conjugate_dir_gausspts_till_8moment(Xsat0(i,:)',P0);
        [a,b]=max(sqrt(sum((X(:,4:6)-repmat(Xsat0(i,4:6),length(w),1)).^2,2)));
        pprr=X(b,:);
        
        [~,xx]=ode45(@twoBody,Tvec,pprr',opt);
        ytruth{i}=xx;
        %         Satellites{i}.ytruth=xx;
        
        [~,xx]=ode45(@twoBody,plotTvec,pprr',opt);
        yplottruth{i}=xx;
        %         Satellites{i}.yplottruth=xx;
        
        %     ytruth_orb{i} = XYZ2OE_multiple(ytruth{i});
        i
        % plot3(xx(:,1),xx(:,2),xx(:,3))
        % keyboard
    end
    
    save(filename,'Xsat0','ytruth','yplottruth','-v7.3')
else
    M=load(filename);
    
    Xsat0=M.Xsat0;
    ytruth=M.ytruth;
    yplottruth=M.yplottruth;
    
    %     for i=1:Constants.Nsat
    %         Satellites{i}.ytruth=ytruth{i};
    %         Satellites{i}.yplottruth=yplottruth{i};
    %     end
    
end




disp('print done sat prop')

%% Plot trajectories to verify
figure
plot_sat_radar_system2(Satellites,Radars,Constants,yplottruth)

pause(1)
%% checking if all the orbits are observable
Satobserve=zeros(Constants.Nsat,1);
parfor i=1:Constants.Nsat
    i
    for j=1:1:Constants.Nrad
        for k=1:1:length(Constants.Tvec)
%             yy=Radars{j}.h( ytruth{i,1}(k,:), Radars{j}.PolarPositions,Radars{j}.hn )+sqrtm(Radars{j}.R )*randn(Radars{j}.hn,1);
            [gg,hh]=Radars{j}.G( ytruth{i,1}(k,:)', Radars{j}.PolarPositions, Radars{j}.hn, Radars{j}.ConeAngle,Radars{j}.MaxRange,Radars{j}.penalty);
            if isnan(hh)==0
                Satobserve(i)=Satobserve(i)+1;

            end
        end
    end
end
Satobserve


% keyboard
%% Generating measurements
if redoSATTRAJ==1
    ymeas=cell(1,Constants.Nsat);
    parfor i=1:Constants.Nsat
        ymeas{i}=cell(Constants.Nrad,Constants.Ntimesteps);
        for j=1:1:Constants.Nrad
            for k=1:1:Constants.Ntimesteps
                ymeas{i}{j,k}=Radars{j}.h( ytruth{i,1}(k,:), Radars{j}.PolarPositions,Radars{j}.hn )+sqrtm(Radars{j}.R )*randn(Radars{j}.hn,1);
            end
        end
    end
    save(filename,'ymeas','-append','-v7.3')
    
else
    M=load(filename);
    ymeas=M.ymeas;
end
disp('done ymeas')


%% Set filter initial conditions

for i=1:1:Constants.Nsat
    Satellites{i}.mu=zeros(Constants.Ntimesteps, Satellites{i}.fn) ;
    Satellites{i}.P=zeros(Constants.Ntimesteps, Satellites{i}.fn * Satellites{i}.fn );
    
    Satellites{i}.Qmeas=0.0000001*blkdiag(0.01,0.01,0.01,1e-8,1e-8,1e-8);
    
    Satellites{i}.mu(1,:)=Xsat0(i,:);
    Satellites{i}.P(1,:)=reshape(P0,1, Satellites{i}.fn * Satellites{i}.fn);
end

%% Running Simmulation
NextSensTaskTimeStep=5;

for k=2:1:Constants.Ntimesteps
    disp(strcat('at time step : ',num2str(k), ' : of : ',num2str(Constants.Ntimesteps)))
    disp('---------------------------------------------------------------------')
    tic
    % propagate
    Satellites=Propagate_sattask(Satellites,Constants,k-1,k,'ut');
    
    %Generate the MeasPairs
    if k==NextSensTaskTimeStep
        %dummy
        %MeasPairs=SensorTask_dummy(MeasPairs,Satellites,Radars,Constants,k,k+Constants.SensTaskHorizon,'ut');
        
        %Greedy time, all ind, NO JOINT COV
        
%         MeasPairs=SensorTask_GreedyTime_AllInd_prevconditoned(MeasPairs,Satellites,Radars,Constants,k,min([k+Constants.SensTaskHorizon,Constants.Ntimesteps]),'ut');
        MeasPairs=SensorTask_GreedySensor_exhaust_jointcov(MeasPairs,Satellites,Radars,Constants,k,min([k+Constants.SensTaskHorizon,Constants.Ntimesteps]),'ut');
        NextSensTaskTimeStep=min([k+Constants.SensTaskHorizon,Constants.Ntimesteps]);
        
    end
%     keyboard
    
    % Measurement update only for the MeasPairs{k}
    Satellites=MeasUpdate_sattask(MeasPairs,Satellites,Radars,Constants,k,ymeas,'ut','trueupdate');
    
    toc
    
    [CovMaxTrace,RMSEpos,CovFrob]=GetSatMetric(Satellites,Constants,ytruth,k);
    figure(2)
    plot(Constants.Tvec(1:k),CovMaxTrace(:,3))
    
    pause(0.5)
end



%%

[CovMaxTrace,RMSEpos,CovFrob]=GetSatMetric(Satellites,Constants,ytruth,Constants.Ntimesteps);
%%

figure
plot(Constants.Tvec,CovFrob(:,1),'r--',Constants.Tvec,CovFrob(:,2),'k',Constants.Tvec,CovFrob(:,3),'b--','lineWidth',2)
legend('min','mean','max')
xlabel('time')
ylabel('Frobenious norm of all Object Covariances ')
plot_prop_paper
saveas(gcf,strcat(strrep(filename,'.mat',''),'_Frob'),'epsc')

figure
plot(Constants.Tvec,RMSEpos(:,1),'r--',Constants.Tvec,RMSEpos(:,2),'k',Constants.Tvec,RMSEpos(:,3),'b--','lineWidth',2)
legend('min','mean','max')
xlabel('time')
ylabel('Position error for all Objects ')
plot_prop_paper
saveas(gcf,strcat(strrep(filename,'.mat',''),'_PosError'),'epsc')


%% Heat map of covariance


M=zeros(Constants.Nsat,Constants.Ntimesteps);
for i=1:Constants.Nsat
    for j=1:Constants.Ntimesteps
        M(i,j)=trace( sqrtm( reshape(Satellites{i}.P(j,:),Satellites{i}.fn,Satellites{i}.fn) ) );
    end
end

hm = HeatMap(M,'RowLabels',1:1:Constants.Nsat,'ColumnLabels',1:1:Constants.Ntimesteps,'Colormap',gray(256),'Symmetric',0,'ColumnLabelsRotate',1);
addXLabel(hm, 'time steps --> ', 'FontSize', 26, 'FontAngle', 'Italic')
addYLabel(hm, 'Object Id ', 'FontSize', 26, 'FontAngle', 'Italic')
addTitle(hm, 'Trace of Covariance ', 'FontSize', 26, 'FontAngle', 'Italic')

% saveas(gcf,strcat(strrep(filename,'.mat',''),'_CovHeat'),'epsc')

%% Heat map of tasking


M=zeros(Constants.Nsat,Constants.Ntimesteps-1);
for i=1:Constants.Nsat
    for j=2:Constants.Ntimesteps
        M(i,j-1)=sum(MeasPairs{j}(i,:) );
    end
end

hm = HeatMap(M,'RowLabels',1:1:Constants.Nsat,'ColumnLabels',2:1:Constants.Ntimesteps,'Colormap',gray(256),'Symmetric',0,'ColumnLabelsRotate',1);
addXLabel(hm, 'time steps --> ', 'FontSize', 26, 'FontAngle', 'Italic')
addYLabel(hm, 'Object Id ', 'FontSize', 26, 'FontAngle', 'Italic')
addTitle(hm, 'Tasking Pairs ', 'FontSize', 26, 'FontAngle', 'Italic')
colorbar('southoutside')
% saveas(gcf,strcat(strrep(filename,'.mat',''),'_SatTaskHeat'))

%% Heat map of tasking 2


M=zeros(Constants.Nrad,Constants.Ntimesteps-1);
for i=1:Constants.Nrad
    for j=2:Constants.Ntimesteps
        M(i,j-1)=sum(MeasPairs{j}(:,i) );
    end
end

hm = HeatMap(M,'RowLabels',1:1:Constants.Nrad,'ColumnLabels',2:1:Constants.Ntimesteps,'Colormap',gray(256),'Symmetric',0,'ColumnLabelsRotate',1);
addXLabel(hm, 'time steps --> ', 'FontSize', 26, 'FontAngle', 'Italic')
addYLabel(hm, 'Sensor Id ', 'FontSize', 26, 'FontAngle', 'Italic')
addTitle(hm, 'Tasking Pairs ', 'FontSize', 26, 'FontAngle', 'Italic')
% colorbar('southoutside')
% saveas(gcf,strcat(strrep(filename,'.mat',''),'_RadTaskHeat'))


%%

save(filename)

%% Make animation

% parfor k=1:Constants.Ntimesteps
%     figure
%     plot_sat_radar_system2_anime(Satellites,Radars,MeasPairs,Constants,yplottruth,k)
%     % set(gcf,'renderer','opengl')
% %     set(gcf,'renderer','painters');
%     view([-14,20])
%     
%     pause(0.2)
%     saveas(gcf,strcat('Anime/',sprintf('%6.6d', k)),'jpg')
%     pause(0.1)
%     close
% end