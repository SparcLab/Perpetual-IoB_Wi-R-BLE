%Controllable Parameters

eta= 0.4;                 %Overall System Efficiency, Minimum - 0.1, Maximum - 1
E_Eff_Saturation_value = 0.7E-9;    %Saturation point for sensing energy efficiency, Minimum - 5E-12, Maximum - 5E-6
BLE = 10*1E-9;            %Bluetooth energy efficiency
WiRC = 100*1E-12;         %WiR energy efficiency
Battery = 1000;           %Battery capacity in mAh
Voltage = 3.3;            %Battery Voltage
Harvested_Power_upper_limit = 400e-6;       %Maximum Power Harvested in indoor environment
Harvested_Power_lower_limit = 50e-6;        %Minimum Power Harvested in indoor environment
Sensing_survey_enable = 0; %Make this variable 1 to view the sensing energy efficiency vs data rate graph

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Data from sensing survey

if E_Eff_Saturation_value > 5e-6
    E_Eff_Saturation_value = 5e-6;
end
if E_Eff_Saturation_value < 5e-12
    E_Eff_Saturation_value = 5e-12;
end

%Data collected from past studies and commercial analog front ends for
%biopotential signal sensing applications is used to benchmark sensing
%energy.

data1 = readtable('E_Eff_Survey_Sensing.xlsx'); %Sensing Energy Efficiency Survey
data1 = data1{:,:};
DR_complete_1 = 1:1:1e3;                        
DR_complete_2 = 1e3:100:20e6;
DR_complete = [DR_complete_1 DR_complete_2];    %Data Rate for calculations - 1bps to 20Mbps
k = fit(data1(:,4), data1(:,5),'power1');       %Fit sensing survey data to a curve
y_BE_complete = DR_complete.^(k.b) * (k.a);     %Sensing survey data fit to a straight line in Log-Log domain
Index_Find = find(y_BE_complete<=E_Eff_Saturation_value);   %Find index where the curve goes below saturation value
ind_actual = Index_Find(1)-1;                   %Index after which the curve dives below saturation point

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Sensing Energy Efficiency Estimation from Survey and Saturation value

y_BE_1 = DR_complete(1:ind_actual).^(k.b) * (k.a);                  %Calculation of sensing energy efficiency for Bluetooth specific case
temp = size(DR_complete);
temp = temp-ind_actual;
y_BE_2 = zeros(1,temp(2));
y_BE_2 = y_BE_2+y_BE_1(ind_actual);
y_BE = [y_BE_1 y_BE_2];

y_WiR_1 = DR_complete(1:ind_actual).^(k.b) * (k.a);                 %Calculation of sensing energy efficiency for WiR specific case
y_WiR_2 = zeros(1,temp(2));
y_WiR_2 = y_WiR_2+y_WiR_1(ind_actual);
y_WiR = [y_WiR_1 y_WiR_2];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%FIGURE 1: Sensing Energy Efficiency vs Data Rate
if Sensing_survey_enable == 1                                           %If graph is enabled
    figure;                             
    loglog(data1(:,4),data1(:,5),'o','MarkerFaceColor',[1 1 0],...      %Energy Efficiency numbers for previous biopotential sensing papers
        'MarkerEdgeColor',[0 0 0],...
        'MarkerSize',10,...
        'LineWidth',3.5);          
    hold on;
    loglog(DR_complete,y_BE,'-','MarkerFaceColor',[1 1 0],...           %Plotting Sensing Energy Efficiency fitted curve vs Data rate 
        'MarkerEdgeColor',[0 0 0],...
        'MarkerSize',10,...
        'LineWidth',3.5, 'Color','r');
    grid on;
    hold off;
    legend('Sensing Energy Efficiency Survey','Fitted Sensing Energy Efficiency');
    title('Sensing Energy Efficiency vs Data Rate');
    ylabel('Sensing Energy Efficiency (J/bit)');
    xlabel('Data Rate (bps)');
    beautify;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%FIGURE 2: Power Consumption vs Data Rate for BLE and Wi-R

figure;
WiRC_DR_1 = WiRC*DR_complete(1:ind_actual) + y_WiR_1.*DR_complete(1:ind_actual);            %WiR total power consumption - Communication and Sensing
WiRC_DR_2 = WiRC*DR_complete(ind_actual+1:end) + y_WiR_2.*DR_complete(ind_actual+1:end);
WiRC_DR = [WiRC_DR_1 WiRC_DR_2];

BLE_DR_1 = BLE*DR_complete(1:ind_actual) + y_BE_1.*DR_complete(1:ind_actual);               %Bluetooth total power consumption - Communication and Sensing
BLE_DR_2 = BLE*DR_complete(ind_actual+1:end) + y_BE_2.*DR_complete(ind_actual+1:end);
BLE_DR = [BLE_DR_1 BLE_DR_2];

if eta <= 0
    eta = 0.1;
end
if eta >1
    eta = 1;
end

eta = 1/eta;

WiRC_DR = eta*WiRC_DR;      %WiR power after additional system losses                                                  
BLE_DR = eta*BLE_DR;        %BLE power after additional system losses

sz = size(DR_complete);     
harvest_array_1 = zeros(1,sz(2));
Harvested_Power_1 = Harvested_Power_lower_limit;            %Harvested Power in an indoor environment: Upper and Lower limits
harvest_array_1 = harvest_array_1 + Harvested_Power_1;

harvest_array_2 = zeros(1,sz(2));
Harvested_Power_2 = Harvested_Power_upper_limit;
harvest_array_2 = harvest_array_2 + Harvested_Power_2;

harvest_array = [harvest_array_1; harvest_array_2];

loglog(DR_complete,WiRC_DR,'-','MarkerFaceColor',[1 1 0],...        %WiR total power consumption plot
    'MarkerEdgeColor',[0 0 0],...
    'MarkerSize',10,...
    'LineWidth',3.5,'Color','g');   
hold on;
loglog(DR_complete,BLE_DR,'-','MarkerFaceColor',[1 1 0],...         %BLE total power consumption plot
    'MarkerEdgeColor',[0 0 0],...
    'MarkerSize',10,...
    'LineWidth',3.5,'Color','b');   
hold on;
loglog(DR_complete,harvest_array,'-','MarkerFaceColor',[1 1 0],...  %Total Harvested Power
    'MarkerEdgeColor',[0 0 0],...
    'MarkerSize',10,...
    'LineWidth',3.5,'Color','black'); 
grid on;
hold off;
legend('Wi-R','Bluetooth','Max. and Min. Harvested Power');
title('Total Power Consumption vs Data Rate');
ylabel('Power Consumption (W)');
xlabel('Data Rate (bps)');
beautify;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%FIGURE 3: Battery Lifetime vs Data Rate plots

figure;

E = Battery*1e-3*Voltage*60*60;                                 %Energy Stored in Battery
P = E/(3600*24);                                               

t_BLE_DR = P./BLE_DR;                                           %Battery Life Time vs Data Rate for BLE
t_WiR_DR = P./WiRC_DR;                                          %Battery Life Time vs Data Rate for BLE
loglog(DR_complete,t_BLE_DR,'-','MarkerFaceColor',[1 1 0],...
    'MarkerEdgeColor',[0 0 0],...
    'MarkerSize',10,...
    'LineWidth',3.5,'Color','b');   
hold on;
loglog(DR_complete,t_WiR_DR,'-','MarkerFaceColor',[1 1 0],...
    'MarkerEdgeColor',[0 0 0],...
    'MarkerSize',10,...
    'LineWidth',3.5,'Color','g');
grid on;
hold off;
legend('Bluetooth','Wi-R');
title('Battery Lifetime vs Data Rate');
ylabel('Battery Life (Days)');
xlabel('Data Rate (bps)');
beautify;