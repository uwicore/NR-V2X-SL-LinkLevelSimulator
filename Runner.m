% Runner script used to sequentially run the NRV2XSL-LinkLevelSimulator.m script
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

DopplerValues = [10 383 765 1530];
MCSindex = 0:27;             % 0 to 27 for Table 5.1.3.1-2. 0 to 28 for Table 5.1.3.1-1 and Table 5.1.3.1-3
SubcarrierSpacings = [15 30 60];       % 15, 30 or 60 kHz 
DMRSvalues = [2 3 4];                % 2, 3 or 4
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
                    fprintf('Simulating %d Hz Doppler shift with MCS index %d, %d kHz SCS, %d DMRS and %d Subchannels \n',DopplerShift,MCSindexValue,SCS,DMRSnum,SUBCHnum);                
                    NRV2XSL-LinkLevelSimulator(DopplerShift,MCSindexValue,SCS,DMRSnum,ChannelModel,SUBCHnum)                
                    fprintf("Done. ");
                    toc
                    fprintf("\n");
                end                          
            end
        end    
    end
end
