% Runner script used to sequentially run the LinkLevelSimulator_V2.m script
clc
close all
clear all

% Doppler shift  | Relative speed 
%      10 Hz     |      3 km/h     
%     328 Hz     |     60 km/h      
%     383 Hz     |     70 km/h      
%     656 Hz     |    120 km/h      
%     765 Hz     |    140 km/h         
%    1530 Hz     |    280 km/h      
%    2733 Hz     |    500 km/h      

DopplerValues = [10]; %[10 1530];
%MCSindex = 6:27;             % 0 to 27 for Table 5.1.3.1-2. 0 to 28 for Table 5.1.3.1-1 and Table 5.1.3.1-3
MCSindex = [2 7 14 23];
SubcarrierSpacings = [30];       % 15, 30 or 60 kHz 
DMRSvalues = [2];                % 2, 3 or 4
%ChannelModel = 'CDL-A';  % 'CDL-D', 'Highway-LOS','Highway-NLOSv','Urban-LOS','Urban-NLOSv','Urban-NLOS'  
ChannelModel = 'Highway-LOS';  % 'Highway-LOS','Highway-NLOSv','Urban-LOS','Urban-NLOSv','Urban-NLOS'  
for SCSindex = 1:numel(SubcarrierSpacings)
    SCS = SubcarrierSpacings(SCSindex);
    for DMRSindex = 1:numel(DMRSvalues)
        DMRSnum = DMRSvalues(DMRSindex);
        for DopplerIndex = 1:numel(DopplerValues)
            DopplerShift = DopplerValues(DopplerIndex);        
            for ii = 1:numel(MCSindex)
                MCSindexValue = MCSindex(ii);
                
                for SUBCHnum = 1:4
                    tic
                    datetime

                    fprintf('Simulating %d Hz Doppler shift with MCS index %d, %d kHz SCS, %d DMRS and %d Subchannels \n',DopplerShift,MCSindexValue,SCS,DMRSnum,SUBCHnum);                
                    LinkLevelSimulator_V7(DopplerShift,MCSindexValue,SCS,DMRSnum,ChannelModel,SUBCHnum)                
                    fprintf("Done. ");

                    toc
                    datetime

                    fprintf("\n");
                end                          
            end
        end    
    end
end


%% Email notification
% User input
source = 'bcoll@winlab.rutgers.edu';              %from address (gmail)
destination = 'bcoll@umh.es';              %to address (any mail service)
myEmailPassword = 'winlab333';                  %the password to the 'from' account
subj = '[LLSim] 10.1.60.103 -> subchannel size 12 (must be changed to 10)';  % subject line
msg = 'Simulations are completed';     % main body of email.
%set up SMTP service for Gmail
setpref('Internet','E_mail',source);
setpref('Internet','SMTP_Server','smtp.gmail.com');
setpref('Internet','SMTP_Username',source);
setpref('Internet','SMTP_Password',myEmailPassword);
% Gmail server.
props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');
% Send the email
sendmail(destination,subj,msg);
% [Optional] Remove the preferences (for privacy reasons)
setpref('Internet','E_mail','');
setpref('Internet','SMTP_Server','''');
setpref('Internet','SMTP_Username','');
setpref('Internet','SMTP_Password','');