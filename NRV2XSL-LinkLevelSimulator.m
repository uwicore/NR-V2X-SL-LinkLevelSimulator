%% UMH-UNIMORE Link-Level simulator
function LinkLevelSimulator_V8(InputDopplerShift,MCSIndex,SCS,DMRS,InputChannelModel,NumSubchannels)
close all

simParameters = struct();       % Clear simParameters variable to contain all key simulation parameters
simParameters.NFrames = 1;      % Number of 10 ms frames
%simParameters.SNRIn = [-5 0 5]; % SNR range (dB)
%simParameters.SNRIn = (-15:1:25);


simParameters.PerfectChannelEstimator = false;   % If false, practical channel estimation is used

simParameters.DisplaySimulationInformation = false;

simParameters.DebugSimulation = false;  % Run the simulation in debug mode (NOT available when parallel computing is used) 

% Set waveform type and PSSCH numerology (SCS and CP type)
simParameters.Carrier = nrCarrierConfig;
simParameters.Carrier.SubcarrierSpacing = SCS; % 15, 30, 60, 120 (kHz)
simParameters.Carrier.CyclicPrefix = 'Normal';  % 'Normal' or 'Extended' (Extended CP is relevant for 60 kHz SCS only)
simParameters.Carrier.NCellID = 0;       % Cell identity

% PSSCH configuration 
simParameters.PSSCH.SubchannelSize = 10; % (ETSI v1.1.13) Size of a subchannel expressed in PRBs: 10, 12, 15, 20, 25, 50, 75 or 100, see TS 38.331
simParameters.PSSCH.BandwidthMHz = 20;  % (ETSI v1.1.13) Maximum transmission bandwidth in MHz, see Table 5.3.2-1 TS 38.101-1
simParameters.PSSCH.TotalNumSubchannels = ...
    getTotalNumSubchannels(simParameters.PSSCH.BandwidthMHz,simParameters.PSSCH.SubchannelSize,simParameters.Carrier.SubcarrierSpacing);   % Total number of available subchannels in the resource pool
simParameters.PSSCH.NumSubchannels = NumSubchannels;  % Smaller than the total number of available subchannels%simParameters.PSSCH.DMRSLength = 2;               
simParameters.PSSCH.DMRSLength = DMRS;  % Number of DMRS symbols, see Table 8.4.1.1.2-1 TS 38.211
% Set grid size
simParameters.Carrier.NSizeGrid = simParameters.PSSCH.NumSubchannels*simParameters.PSSCH.SubchannelSize;   % Bandwidth in number of resource blocks 

% MCS configuration
simParameters.PSSCH.MCSindex = MCSIndex;  % Modulation and coding scheme index
simParameters.PSSCH.AdditionalMCSTable = 1;   % (ETSI v1.1.13) Additional MCS Table indicator, can be set to 0 or 1
[TargetCodeRate, Modulation, ModulationOrder] = ...
    getMCSinformation(simParameters.PSSCH.MCSindex, simParameters.PSSCH.AdditionalMCSTable);  % Based on the selected MCS table, return the CR and Modulation
simParameters.PSSCH.TargetCodeRate = TargetCodeRate;   % Target code rate used to calculate transport block size
simParameters.PSSCH.Modulation = Modulation;   % 'pi/2-BPSK', 'QPSK', '16QAM', '64QAM', '256QAM'
simParameters.PSSCH.ModulationOrder = ModulationOrder;   % 2 for 'QPSK', 4 for '16QAM', 6 for '64QAM', 8 for '256QAM'

% Scrambling identifiers (not used, Uu legacy)
simParameters.PSSCH.NID = simParameters.Carrier.NCellID;
simParameters.PSSCH.RNTI = 1;

% Define the transform precoding enabling, layering and transmission scheme
simParameters.PSSCH.TransformPrecoding = false; % Enable/disable transform precoding
simParameters.PSSCH.NumLayers = 1;   % Number of PSSCH transmission layers
simParameters.PSSCH.TransmissionScheme = 'nonCodebook'; % Transmission scheme ('nonCodebook','codebook')

% 1st-stage SCI configuration
simParameters.SCI1.TimeResourcePSCCH = 3;    % (ETSI v1.1.13) Number of PSCCH symbols in a slot: 2 or 3, see TS 38.331
simParameters.SCI1.FreqResourcePSCCH = 10;   % (ETSI v1.1.13) Number of PSCCH PRBs: 10, 12, 15, 20 or 25, see TS 38.331
%Must be fix %V6 showed 12*NumSubchannel becasue we tested what happen if we have a common setting along the NumSuchannel  

% 2nd-stage SCI configuration
simParameters.SCI2.Enable = true;   % Flag to enable/disable the 2nd-stage SCI
simParameters.SCI2.Format = "2A";   % Format of the 2nd-stage SCI: "2A" or "2B"

% HARQ process and rate matching/TBS parameters
simParameters.PSSCH.XOverhead = 0;       % Set PUSCH rate matching overhead for TBS (Xoh)
simParameters.PSSCH.NHARQProcesses = 16; % Number of parallel HARQ processes to use
simParameters.PSSCH.EnableHARQ = false;   % Enable retransmissions for each process, using RV sequence [0,2,3,1]

% LDPC decoder parameters
% Available algorithms: 'Belief propagation', 'Layered belief propagation', 'Normalized min-sum', 'Offset min-sum'
simParameters.PSSCH.LDPCDecodingAlgorithm = 'Normalized min-sum';
simParameters.PSSCH.MaximumLDPCIterationCount = 6;

% Define the overall transmission antenna geometry at end-points
% If using a CDL propagation channel then the integer number of antenna elements is
% turned into an antenna panel configured when the channel model object is created
simParameters.NTxAnts = 2; % Number of transmit antennas
simParameters.NRxAnts = 4; % Number of receive antennas

% Define the general CDL/TDL propagation channel parameters
%simParameters.DelayProfile = 'CDL-A'; % Use TDL-A model (Indoor hotspot model)
simParameters.DelayProfile = InputChannelModel; 

simParameters.DelaySpread = 30e-9;
simParameters.MaximumDopplerShift = InputDopplerShift;

% Define the general CDL propagation channel parameters
%simParameters.DelayProfile = 'CDL-A'; % The available delay profiles are CDL-A, CDL-B, CDL-C, CDL-D, CDL-E
% simParameters.ChannelType = 'CDL';
% simParameters.DelayProfile = 'Custom'; 
% simParameters.DelaySpread = 30e-9;
% simParameters.MaximumDopplerShift = DopplerShift;

% Cross-check the PUSCH layering against the channel geometry 
validateNumLayers(simParameters);

% Validate Sidelink parameters
validateSidelinkInputs(simParameters);

%Select the SNR range based on the Modulation order
switch ModulationOrder
    case 2
%        simParameters.SNRIn = (-30:1:0);
        %simParameters.SNRIn = (-20:1:10);
        simParameters.SNRIn = (-13:20);        
    case 4
        simParameters.SNRIn = (-13:25);
    case 6
        simParameters.SNRIn = (-13:25);
    case 8
        simParameters.SNRIn = (-13:30);       
    otherwise
        simParameters.SNRIn = (-15:1:25);
end

if simParameters.DebugSimulation
    simParameters.SNRIn = (0:0);        
end

%%
% The simulation relies on various pieces of information about the baseband 
% waveform, such as sample rate.
waveformInfo = nrOFDMInfo(simParameters.Carrier); % Get information about the baseband waveform after OFDM modulation step

%% Propagation Channel Model Construction
% Create the channel model object for the simulation. Both CDL and TDL channel 
% models are supported [ <#12 5> ].

% Constructed the CDL channel model object
if contains(simParameters.DelayProfile,'CDL','IgnoreCase',true)
    channel = nrCDLChannel; % CDL channel object
    channel.DelayProfile = simParameters.DelayProfile;

    % Turn the overall number of antennas into a specific antenna panel
    % array geometry. The number of antennas configured is updated when
    % nTxAnts is not one of (1,2,4,8,16,32,64,128,256,512,1024) or nRxAnts
    % is not 1 or even.
    [channel.TransmitAntennaArray.Size,channel.ReceiveAntennaArray.Size] = ...
        SL_hArrayGeometry(simParameters.NTxAnts,simParameters.NRxAnts,'uplink');
    nTxAnts = prod(channel.TransmitAntennaArray.Size);
    nRxAnts = prod(channel.ReceiveAntennaArray.Size);
    simParameters.NTxAnts = nTxAnts;
    simParameters.NRxAnts = nRxAnts;
    % Configure antenna elements
%     channel.TransmitAntennaArray.Element = 'isotropic';
%     channel.ReceiveAntennaArray.Element = 'isotropic';
%    channel.ReceiveAntennaArray.Element = '38.901';
else  
    channel = nrCDLChannel; % CDL channel object
    channel.DelayProfile = 'Custom';
    channel.CarrierFrequency = 5.9e9; 

    switch InputChannelModel
        case 'Highway-LOS'                
            channel.PathDelays = [0.0 2.1109e-9 2.9528e-9 17.0328e-9 31.1128e-9 9.1629e-9 10.6761e-9 ...
                11.0257e-9 18.5723e-9 19.8875e-9 33.9675e-9 48.0475e-9 25.7370e-9 36.2683e-9 ...
                66.7093e-9 139.9695e-9];
            channel.AveragePathGains = [-0.001945 -19.9 -13.9 -16.2 -17.9 -14.5 -21.3 -18.7 -14.9 -16.2 -18.5 -20.2 ...
                -17.1 -13.8 -28.4 -27.4];
            channel.AnglesAoA = [-180 -80.2 98.6 98.6 98.6 73.1 -64.3 65.7 -90.9 84.5 84.5 84.5 71.3 ...
                -81.5 41.4 -42.6];
            channel.AnglesAoD = [0.0 63.4 50.0 50.0 50.0 55.2 -62.6 56.0 53.3 -51.1 -51.1 -51.1 -56.1 58.4 ...
                 74.7 -71.5];
            channel.AnglesZoA = [90.0 75.0 98.4 98.4 98.4 78.1 73.7 105.4 79.1 79.4 79.4 79.4 77.4 80.4 ...
                 68.1 111.8];
            channel.AnglesZoD = [90.0 83.8 86.9 86.9 86.9 85.1 97.3 96.3 85.3 94.4 94.4 94.4 95.5 86.2 81.1 99.4];
            channel.HasLOSCluster = true; % If false: not caring about the k-factor value for the first cluster
            channel.KFactorFirstCluster = 18.01;
            channel.AngleSpreads = [3.0 17.0 7.0 7.0];
            channel.XPR = 9.0;

        case 'Highway-NLOSv'
            channel.PathDelays = [0.0 5.5956e-9 19.6756e-9 33.7556e-9 21.7591e-9 21.8113e-9 27.2207e-9 ...
                39.3242e-9 51.0232e-9 51.4828e-9 53.3659e-9 65.1775e-9 79.2575e-9 93.3375e-9 ...
                67.9841e-9 70.7561e-9 73.9980e-9 75.8665e-9 84.3678e-9 90.1654e-9 91.6154e-9 142.9312e-9 158.4339e-9];
            channel.AveragePathGains = [-0.000016687 -12.5090 -14.7274 -16.4884 -11.8681 -11.3289 -17.8834 -9.9943 -12.7302 -13.9120 ...
                -16.8781 -12.9647 -15.1832 -16.9441 -10.7858 -12.3875 -17.3827 -14.7254 -13.5863 -20.9080 ...
                -15.5653 -19.7098 -24.7824];
            channel.AnglesAoA = [-180 -120 -120 -120 -114.6 96.5 77 -124.7 93.1 88.2 80.7 94.4 94.4 94.4 ...
                98.1 -99.3 66.8 91.5 -108.4 -89.6 84.4 -81.8 -69.6];
            channel.AnglesAoD = [0.0 -52.3 -52.3 -52.3 66.4 -46.7 89.8 -56.8 75.9 85.4 88.9 -46.2 -46.2 -46.2 ...
                -50.9 -54.3 88.3 78.0 73.5 -69.7 -62.1 -70.3 -84.5];
            channel.AnglesZoA = [90.0 61.5 61.5 61.5 54.8 56.1 34.8 120.7 119.9 48.7 136.9 56.9 56.9 56.9 121.1 121.6 ...
                141.6 131.1 51.1 147.1 46.7 32.2 157.3];
            channel.AnglesZoD = [90.0 99.2 99.2 99.2 77.2 78.6 106.8 81.2 102.1 103.7 74.0 100.0 100.0 100.0 100.2 77.7 ...
                73.8 103.8 104.8 69.4 103.2 109.1 113.8];
            channel.HasLOSCluster = true; % If false: not caring about the k-factor value for the first cluster
            channel.KFactorFirstCluster = 11.5667;
            channel.AngleSpreads = [10.0 22.0 7.0 7.0];
            channel.XPR = 8.0;

        case 'Urban-NLOS'
            channel.PathDelays = [0.0 6.466311e-9 11.6926e-9 16.91889e-9 19.49782e-9 20.64838e-9 38.74579e-9 48.75469e-9 53.98099e-9 ...
                59.20728e-9 62.18983e-9 68.71579e-9 70.33887e-9 74.461e-9 105.954e-9 117.9043e-9 137.072e-9 210.5223e-9 ...
                218.8232e-9 232.2158e-9 289.6542e-9 357.7905e-9 380.2389e-9];
            channel.AveragePathGains = [-4.8 -0.8 -3 -4.8 0 -0.8 -0.9 -0.8 -3 -4.8 -6.3 -4 -8.1 -8 -7 -8.3 -1.7 -7.6 -16.2 ...
                -4.2 -18.2 -21.8 -19.9];
            channel.AnglesAoA = [-36 -162.5 -162.5 -162.5 -87 -79.7 -88.6 143.6 143.6 143.6 6.3 -58.2 -19.9 23 -28.7 -5.4 ...
                -82.8 -22.4 56.2 32.9 -57 -103.3 68.4];
            channel.AnglesAoD = [-53 -2.7 -2.7 -2.7 -30.3 -28 28.3 0.5 0.5 0.5 -80 60 -75.7 -76.8 59.4 72.6 42.3 57.3 -93.9 ...
                -37.8 106.7 107.5 -95];
            channel.AnglesZoA = [12.5 73.3 73.3 73.3 73.7 121.2 119.6 92.9 92.9 92.9 175.1 29.4 159 168.3 6.9 168 134.6 ...
                21.4 84.2 171 110.2 39.6 127.9];
            channel.AnglesZoD = [79.7 89.3 89.3 89.3 93.6 85.3 96 91.3 91.3 91.3 79.8 81.1 102.9 103.2 77.5 77.2 95.5 ...
                100.5 111.2 80 64.3 119.9 117];
            channel.HasLOSCluster = false; % If false: not caring about the k-factor value for the first cluster
            channel.AngleSpreads = [10.0 22.0 7.0 7.0];
            channel.XPR = 8.0;

        case 'Urban-LOS'
            channel.PathDelays = [0.0 6.4e-9 12.8e-9 11.0793e-9 21.9085e-9 29.6768e-9 36.0768e-9 42.4768e-9 ...
                68.4085e-9 82.2944e-9 115.4173e-9 143.2963e-9 146.4136e-9 183.1925e-9 214.1501e-9 326.7825e-9];
            channel.AveragePathGains = [0.00347973 -17.7 -19.5 -15.9 -14.6 -9.1 -11.3 -13.1 -19.3 -20.0 -16.3 -17.9 ...
                -25.4 -26.9 -22.9 -25.3];
            channel.AnglesAoA = [-180 -180 -180 -51.8 -51.9 96.8 96.8 96.8 -37.5 -45.7 57.3 -42.1 -17.6 18.6 ...
                20.6 -19.1];
            channel.AnglesAoD = [0.0 0.0 0.0 93.2 85.4 -49.9 -49.9 -49.9 -97.1 108.5 -90.7 105.5 127.1 127.0 ...
                -101.5 125.2];
            channel.AnglesZoA = [90.0 90.0 90.0 57.8 119.7 100.0 100.0 100.0 130.3 130.3 58.1 52.5 36.9 145.1 ...
                42.8 141.6];
            channel.AnglesZoD = [90.0 90.0 90.0 75.1 76.6 84.8 84.8 84.8 107.3 107.7 104.0 107.0 68.4 67.2 ...
                69.4 112.0];
            channel.HasLOSCluster = true; % If false: not caring about the k-factor value for the first cluster
            channel.KFactorFirstCluster = 15.40;
            channel.AngleSpreads = [3.0 17.0 7.0 7.0];
            channel.XPR = 9.0;

        case 'Urban-NLOSv'
            channel.PathDelays = [0.0 20.1752e-9 34.2552e-9 48.3352e-9 34.3633e-9 37.1866e-9 52.1209e-9 52.7982e-9 ...
                66.8782e-9 80.9582e-9 53.2168e-9 53.2285e-9 55.2847e-9 65.8409e-9 79.0272e-9 90.9391e-9 91.0347e-9 ...
                105.4760e-9 118.7946e-9 166.1280e-9 253.7053e-9 293.5444e-9 471.3768e-9];
            channel.AveragePathGains = [0.0017996 -8.9 -11.2 -12.9 -17.9 -14.8 -11.9 -10.2 -12.5 -14.2 -11.1 -15.5 -13.8 ...
                -12.5 -20.2 -11.7 -19.0 -17.1 -17.5 -18.1 -22.2 -16.4 -19.8];
            channel.AnglesAoA = [-180 138.4 138.4 138.4 -79.9 -85.1 -100.6 -119.5 -119.5 -119.5 -103.5 92.5 ...
                80.7 100.7 -69.4 101.2 69 86.5 91.5 -76.6 -68.1 82.7 -61.8];
            channel.AnglesAoD = [0.0 36.0 36.0 36.0 -45.7 60.7 53.6 -34.5 -34.5 -34.5 48.4 -45.8 56.0 55.7 ...
                -48.9 51.1 62.7 -43.0 62.4 -50.6 -57.0 -43.1 -50.1];
            channel.AnglesZoA = [90.0 81.1 81.1 81.1 118.1 117.3 71.3 103.0 103.0 103.0 108.7 63.7 67.0 ...
                109.3 125.9 108.3 58.4 119.8 119.9 120.3 54.1 62.1 56.4];
            channel.AnglesZoD = [90.0 84.1 84.1 84.1 74.2 76.4 77.3 97.4 97.4 97.4 99.7 105.6 76.6 76.9 ...
                71.3 77.9 71.6 73.9 72.4 72.7 110.7 104.6 108.6];
            channel.HasLOSCluster = true; % If false: not caring about the k-factor value for the first cluster
            channel.KFactorFirstCluster = 14.79;
            channel.AngleSpreads = [10.0 22.0 7.0 7.0];
            channel.XPR = 8.0;
    end

    % Turn the overall number of antennas into a specific antenna panel
    % array geometry. The number of antennas configured is updated when
    % nTxAnts is not one of (1,2,4,8,16,32,64,128,256,512,1024) or nRxAnts
    % is not 1 or even.
    [channel.TransmitAntennaArray.Size,channel.ReceiveAntennaArray.Size] = ...
        SL_hArrayGeometry(simParameters.NTxAnts,simParameters.NRxAnts,'sidelink');
    nTxAnts = prod(channel.TransmitAntennaArray.Size);
    nRxAnts = prod(channel.ReceiveAntennaArray.Size);
    simParameters.NTxAnts = nTxAnts;
    simParameters.NRxAnts = nRxAnts;
    % Configure antenna elements
    channel.TransmitAntennaArray.Element = 'isotropic';
    channel.ReceiveAntennaArray.Element = 'isotropic';

end

% Assign simulation channel parameters and waveform sample rate to the object
channel.DelaySpread = simParameters.DelaySpread;
channel.MaximumDopplerShift = simParameters.MaximumDopplerShift;
channel.SampleRate = waveformInfo.SampleRate;

%%
% Get the maximum number of delayed samples by a channel multipath
% component. This is calculated from the channel path with the largest
% delay and the implementation delay of the channel filter. This is
% required later to flush the channel filter to obtain the received signal.

chInfo = info(channel);
maxChDelay = ceil(max(chInfo.PathDelays*channel.SampleRate)) + chInfo.ChannelFilterDelay;

%% Processing Loop

% Array to store the TB-BLER for all SNR points
TB_BLER = zeros(length(simParameters.SNRIn),1);
% Array to store the 2nd-stage SCI-BLER for all SNR points
SCI2_BLER = zeros(length(simParameters.SNRIn),1);
% Array to store the 1st-stage SCI-BLER for all SNR points
SCI1_BLER = zeros(length(simParameters.SNRIn),1);
% Array to store the TB size
TBS_out = zeros(length(simParameters.SNRIn),1);
% Array to store the 1st-stage SCI code rate
SCI1_CR_out = zeros(length(simParameters.SNRIn),1);
% Array to store the 2nd-stage SCI code rate
SCI2_CR_out = zeros(length(simParameters.SNRIn),1);

% Set up redundancy version (RV) sequence for all HARQ processes
if simParameters.PSSCH.EnableHARQ
    % From PUSCH demodulation requirements in RAN WG4 meeting #88bis (R4-1814062)
    rvSeq = [0 2 3 1];
else
    % HARQ disabled - single transmission with RV=0, no retransmissions
    rvSeq = 0;
end

% Create UL-SCH encoder System object to perform SL-SCH encoding
encodeSLSCH = nrULSCH;
encodeSLSCH.MultipleHARQProcesses = true;
encodeSLSCH.TargetCodeRate = simParameters.PSSCH.TargetCodeRate;
%encodeSLSCH.LimitedBufferRateMatching = false;  % False by default

% Create UL-SCH decoder System object to perform transport channel decoding
% Use layered belief propagation for LDPC decoding, with half the number of
% iterations as compared to the default for belief propagation decoding
decodeSLSCH = nrULSCHDecoder;
decodeSLSCH.MultipleHARQProcesses = true;
decodeSLSCH.TargetCodeRate = simParameters.PSSCH.TargetCodeRate;
% LDPC decoder parameters
% Available algorithms: 'Belief propagation', 'Layered belief propagation', 'Normalized min-sum', 'Offset min-sum'
decodeSLSCH.LDPCDecodingAlgorithm = simParameters.PSSCH.LDPCDecodingAlgorithm;   
decodeSLSCH.MaximumLDPCIterationCount = simParameters.PSSCH.MaximumLDPCIterationCount;                  

%for snrIdx = 1:numel(simParameters.SNRIn)    % comment out for parallel computing
parfor snrIdx = 1:numel(simParameters.SNRIn) % uncomment for parallel computing
    fprintf('\n\nSNR: %d\n', simParameters.SNRIn(snrIdx))
    % Reset the random number generator so that each SNR point will
    % experience the same noise realization
    rng('default');
    
    % Take full copies of the simulation-level parameter structures so that they are not 
    % PCT broadcast variables when using parfor 
    simLocal = simParameters;
    waveinfoLocal = waveformInfo;
    
    % Take copies of channel-level parameters to simplify subsequent parameter referencing 
    carrier = simLocal.Carrier;
    PSSCH = simLocal.PSSCH;
    SCI2 = simLocal.SCI2;
    SCI1 = simLocal.SCI1;

    decodeSLSCHLocal = decodeSLSCH;  % Copy of the decoder handle to help PCT classification of variable
    decodeSLSCHLocal.reset();        % Reset decoder at the start of each SNR point
    pathFilters = [];
    
    % Create PUSCH object configured for the non-codebook transmission
    % scheme, used for receiver operations that are performed with respect
    % to the PUSCH layers
    psschNonCodebook = PSSCH;
    psschNonCodebook.TransmissionScheme = 'nonCodebook';

    % Prepare simulation for new SNR point
    SNRdB = simLocal.SNRIn(snrIdx);

    if (simLocal.DisplaySimulationInformation)
        fprintf('\nSimulating transmission scheme 1 (%dx%d) and SCS=%dkHz with %s channel at %gdB SNR for %d 10ms frame(s)\n', ...
            simLocal.NTxAnts,simLocal.NRxAnts,carrier.SubcarrierSpacing, ...
            simLocal.DelayProfile,SNRdB,simLocal.NFrames);
    end
    
    % Specify the fixed order in which we cycle through the HARQ process IDs
    harqSequence = 0:PSSCH.NHARQProcesses-1;

    % Initialize the state of all HARQ processes
    harqEntity = HARQEntity(harqSequence,rvSeq);

    % Reset the channel so that each SNR point will experience the same
    % channel realization
    reset(channel);
    
    % Total number of slots in the simulation period (independent of the SCS)
    %NSlots = simLocal.NFrames * carrier.SlotsPerFrame
    NSlots = simLocal.NFrames * carrier.SlotsPerFrame / carrier.SlotsPerSubframe;   

    if simLocal.DebugSimulation
        NSlots = 1;
    end

    % Timing offset, updated in every slot for perfect synchronization and
    % when the correlation is strong for practical synchronization
    offset = 0;
    
    % Loop over the entire waveform length
    for nslot = 0:NSlots-1
        
        % Update the carrier slot numbers for new slot
        carrier.NSlot = nslot;

        % Create the time-frequency resources grid
        SidelinkGrid = nrResourceGrid(carrier,simLocal.NTxAnts);

        % Get the resource grid indices
        [PSSCHindices,PSSCH_DMRSindices,PSCCHindices,PSCCH_DMRSindices,AGCindices,GuardIndices,DMRSvector] = nrSidelinkIndices(SidelinkGrid,PSSCH,SCI1);

        if simLocal.DebugSimulation
            plotSLgrid(SidelinkGrid,PSSCHindices,PSSCH_DMRSindices,PSCCHindices,PSCCH_DMRSindices,AGCindices,GuardIndices);
        end         
        %plotSLgrid(SidelinkGrid,PSSCHindices,PSSCH_DMRSindices,PSCCHindices,PSCCH_DMRSindices,AGCindices,GuardIndices);

        totalNumIndices = length(PSSCHindices) + length(PSSCH_DMRSindices) + length(PSCCHindices) + length(PSCCH_DMRSindices) + length(AGCindices) + length(GuardIndices);
        assert (totalNumIndices == (carrier.SymbolsPerSlot*simLocal.PSSCH.SubchannelSize*simLocal.PSSCH.NumSubchannels*12), "Mismatch between indices number and total number of REs")           
        
        % Depending on the 2nd-stage SCI format, set the corresponding size
        if SCI2.Enable
            if strcmp(SCI2.Format,'2A')
                SCI2.size = 35;
            elseif strcmp(SCI2.Format,'2B')
                SCI2.size = 48;
            end     
            % Assign random information
            SCI2bits = randi([0 1],SCI2.size,1);
            % Encode the 2nd-stage SCI and get the output codeword (SCI2cw)
            [SCI2cw,SCI2.REs,SCI2.K,SCI2.N,SCI2.E] = nrSCI2Encode(SCI2bits,simLocal.PSSCH.TargetCodeRate,numel(PSSCHindices)); % Encode the 2nd-stage SCI
            % Change the data type (same as the TB)
            SCI2cw = int8(SCI2cw);  
            assert((SCI2.REs*2) == numel(SCI2cw), "Size of 2nd-stage SCI does not match the number of allocated REs");
        else
            SCI2.size = 0;   
            SCI2.REs = 0;
            SCI2.K = 1;
            SCI2.E = 1;
            SCI2.N = 1;
            SCI2cw = double.empty;
        end

        % Determine the TB size
        TBS = nrTBSSidelink(PSSCH,SCI1,numel(PSSCHindices),SCI2.REs);

        % HARQ processing
        % If new data for current process then create a new UL-SCH transport block
        if harqEntity.NewData 
            trBlk = randi([0 1],TBS,1);
            setTransportBlock(encodeSLSCH,trBlk,harqEntity.HARQProcessID);
            % If new data because of previous RV sequence time out then flush decoder soft buffer explicitly
            if harqEntity.SequenceTimeout
                resetSoftBuffer(decodeSLSCHLocal,harqEntity.HARQProcessID);
            end
        end

        % Encode the SL-SCH transport block
        trBlk_G = ( numel(PSSCHindices)-SCI2.REs )*PSSCH.ModulationOrder*PSSCH.NumLayers;
        % Encode the TB and get the output codeword (TBcw)
        TBcw = encodeSLSCH(PSSCH.Modulation,PSSCH.NumLayers,trBlk_G,harqEntity.RedundancyVersion,harqEntity.HARQProcessID);        
      
        assert(numel(TBcw) + numel(SCI2cw) == (numel(PSSCHindices) - SCI2.REs)*PSSCH.ModulationOrder + SCI2.REs*2, ...
            "PSSCH bits do not fit in the allocated PSSCH REs"); % 2nd-stage SCI employs QPSK, see clause 8.3.1.2 TS 38.211

        if SCI2.Enable
            % Multiplexing of 2nd-stage SCI and TB on the PSSCH
            SLSCHcw = DataControlMultiplexing(TBcw,SCI2cw,PSSCH.NumLayers); 
        else
            SLSCHcw = TBcw;
        end
        
        % Encode the 1st-stage SCI and get the output codeword (SCI1cw)
        [SCI1cw,SCI1.K,SCI1.N,SCI1.E,SCI1.CRCdec] = nrSCI1Encode(PSSCH.TotalNumSubchannels,PSCCHindices);
        % Change the data type (same as the TB)
        SCI1cw = int8(SCI1cw);  

        if simLocal.DebugSimulation
            fprintf('\n1-st stage SCI codeword length = %d bits, 2-nd stage SCI codeword length = %d bits, TB codeword length = %d bits',length(SCI1cw),length(SCI2cw),length(TBcw));
            fprintf('\n1-st stage SCI modulation = QPSK, 2-nd stage SCI modulation = QPSK, TB modulation = %s',simLocal.PSSCH.Modulation);
            fprintf('\nControl-CH REs = %d, Shared-CH REs = %d',length(PSCCHindices),length(PSSCHindices));
        end

        % Generate PSSCH symbols
        [PSSCHsymbols,TBtxSymbols,SCI2txSymbols] = nrPSSCH(PSSCH.NumLayers,PSSCH.Modulation,SLSCHcw,length(SCI2cw),SCI1.CRCdec,SCI2.Enable);
        % Generate PSCCH symbols
        PSCCHsymbols = nrPSCCH(SCI1cw);
        % Generate PSSCH-DMRS symbols
        PSSCH_DMRSsymbols = nrPSSCHDMRS(DMRSvector,carrier.SymbolsPerSlot,mod(nslot,carrier.SlotsPerFrame),SCI1.CRCdec,PSSCH,SCI1);
        % Generate PSCCH-DMRS symbols
        PSCCH_DMRSsymbols = nrPSCCHDMRS(carrier.SymbolsPerSlot,mod(nslot,carrier.SlotsPerFrame),SCI1,length(PSCCH_DMRSindices));

        % Non-codebook based MIMO precoding, F precodes between PSSCH layers and transmit antennas
        % Allocate PSSCH symbols on the grid
        F = eye(simLocal.PSSCH.NumLayers,simLocal.NTxAnts);
        [~,psschAntIndices] = nrExtractResources(PSSCHindices,SidelinkGrid);
        SidelinkGrid(psschAntIndices) = PSSCHsymbols * F;
        % Allocate PSSCH-DMRS symbols on the grid
        [~,psschDMRSAntIndices] = nrExtractResources(PSSCH_DMRSindices,SidelinkGrid);
        SidelinkGrid(psschDMRSAntIndices) = PSSCH_DMRSsymbols * F;

        % PSCCH is always transmitted on 1 layer: F precodes between PSCCH layers (1) and transmit antennas
        % Allocate PSCCH symbols on the grid
        F_CCH = eye(1,simLocal.NTxAnts);  
        [~,pscchAntIndices] = nrExtractResources(PSCCHindices,SidelinkGrid);
        SidelinkGrid(pscchAntIndices) = PSCCHsymbols * F_CCH;       
        % Allocate PSCCH-DMRS symbols on the grid
        [~,pscchDMRSAntIndices] = nrExtractResources(PSCCH_DMRSindices,SidelinkGrid);
        SidelinkGrid(pscchDMRSAntIndices) = PSCCH_DMRSsymbols * F_CCH;

        % Copy the content of the 2nd OFDM symbol into the AGC symbol (1st symbol)
        if simLocal.NTxAnts > 1
          gridSize = size(SidelinkGrid);
          Z = gridSize(3);
          for antennaIndex = 1:Z
            SidelinkGrid(:,1,antennaIndex) = SidelinkGrid(:,2,antennaIndex); 
            % Copy also the content of the last symbol (to be removed)
%            SidelinkGrid(:,14,antennaIndex) = SidelinkGrid(:,13,antennaIndex); 
          end
        else
          SidelinkGrid(:,1) = SidelinkGrid(:,2); 
          % Copy also the content of the last symbol (to be removed)
%          SidelinkGrid(:,14) = SidelinkGrid(:,13);           
        end

        % OFDM modulation
        txWaveform = nrOFDMModulate(carrier,SidelinkGrid);

        % Pass data through channel model. Append zeros at the end of the
        % transmitted waveform to flush channel content. These zeros take
        % into account any delay introduced in the channel. This is a mix
        % of multipath delay and implementation delay. This value may 
        % change depending on the sampling rate, delay profile and delay
        % spread
        txWaveform = [txWaveform; zeros(maxChDelay,size(txWaveform,2))]; %#ok<AGROW>
        [rxWaveform,pathGains,sampleTimes] = channel(txWaveform);

        % Add AWGN to the received time domain waveform 
        % Normalize noise power by the IFFT size used in OFDM modulation,
        % as the OFDM modulator applies this normalization to the
        % transmitted waveform. Also normalize by the number of receive
        % antennas, as the channel model applies this normalization to the
        % received waveform, by default
        SNR = 10^(SNRdB/10);
        N0 = 1/sqrt(2.0*simLocal.NRxAnts*double(waveinfoLocal.Nfft)*SNR);
        noise = N0*complex(randn(size(rxWaveform)),randn(size(rxWaveform)));
        rxWaveform = rxWaveform + noise;

        if (simLocal.PerfectChannelEstimator)
            % Perfect synchronization. Use information provided by the
            % channel to find the strongest multipath component
            pathFilters = getPathFilters(channel);
            [offset,mag] = nrPerfectTimingEstimate(pathGains,pathFilters);
        else
            % Practical synchronization. Correlate the received waveform 
            % with the PUSCH DM-RS to give timing offset estimate 't' and
            % correlation magnitude 'mag'. The function
            % hSkipWeakTimingOffset is used to update the receiver timing
            % offset. If the correlation peak in 'mag' is weak, the current
            % timing estimate 't' is ignored and the previous estimate
            % 'offset' is used
            [t,mag] = nrTimingEstimate(carrier,rxWaveform,PSSCH_DMRSindices,PSSCH_DMRSsymbols);
            offset = hSkipWeakTimingOffset(offset,t,mag);
            % Display a warning if the estimated timing offset exceeds the
            % maximum channel delay
%             if offset > maxChDelay
%                 warning(['Estimated timing offset (%d) is greater than the maximum channel delay (%d).' ...
%                     ' This will result in a decoding failure. This may be caused by low SNR,' ...
%                     ' or not enough DM-RS symbols to synchronize successfully.'],offset,maxChDelay);
%             end
        end
           
        rxWaveform = rxWaveform(1+offset:end,:);

        % Perform OFDM demodulation on the received data to recreate the
        % resource grid, including padding in the event that practical
        % synchronization results in an incomplete slot being demodulated
        rxGrid = nrOFDMDemodulate(carrier,rxWaveform);
        [K,L,R] = size(rxGrid);
        if (L < carrier.SymbolsPerSlot)
            rxGrid = cat(2,rxGrid,zeros(K,carrier.SymbolsPerSlot-L,R));
        end

        %% First, decode the 1st-stage SCI
        if (simLocal.PerfectChannelEstimator)
            % Perfect channel estimation, use the value of the path gains
            % provided by the channel
            estChannelGrid = nrPerfectChannelEstimate(carrier,pathGains,pathFilters,offset,sampleTimes);

            % Get perfect noise estimate (from the noise realization)
            noiseGrid = nrOFDMDemodulate(carrier,noise(1+offset:end,:));
            noiseEst = var(noiseGrid(:));
        
            % Apply MIMO deprecoding to estChannelGrid to give an estimate
            % per transmission layer
            K = size(estChannelGrid,1);
            estChannelGrid = reshape(estChannelGrid,K*carrier.SymbolsPerSlot*simLocal.NRxAnts,simLocal.NTxAnts);
            estChannelGrid = estChannelGrid * F.';
            estChannelGrid = reshape(estChannelGrid,K,carrier.SymbolsPerSlot,simLocal.NRxAnts,[]);
        else
              % Estimate the channel on the PSCCH using PSCCH-DMRS
            dmrsLayerIndices = PSCCH_DMRSindices;
            dmrsLayerSymbols = PSCCH_DMRSsymbols;  
              % Estimate the channel on the PSCCH using PSSCH-DMRS
%             dmrsLayerIndices = PSSCH_DMRSindices; 
%             dmrsLayerSymbols = PSSCH_DMRSsymbols;     
            [estChannelGrid,noiseEst] = nrChannelEstimate(carrier,rxGrid,dmrsLayerIndices,dmrsLayerSymbols,'CDMLengths',[1,1]);  % [1,1] means not employed
        end   

        % Get PSCCH resource elements from the received grid
        [pscchRx,pscchHest] = nrExtractResources(PSCCHindices,rxGrid,estChannelGrid);
        % PSCCH Equalization
        [pscchEq,CCHcsi] = nrEqualizeMMSE(pscchRx,pscchHest,noiseEst);   
        % PSCCH Decoding, soft bits output
        [SCI1LLRs, SCI1rxSymbols] = nrPSCCHDecode(pscchEq,noiseEst);

        % Apply channel state information (CSI) produced by the equalizer,
        SCI1csi = nrLayerDemap(CCHcsi);
        Qm = length(SCI1LLRs) / length(SCI1rxSymbols);  
        SCI1csi = reshape(repmat(SCI1csi{1}.',Qm,1),[],1);
        SCI1LLRs = SCI1LLRs .* SCI1csi;
        
        % Decode the 1st-stage SCI
        [SCI1rxBits,SCI1err,SCI1.CRCdecRx] = nrSCIDecode(SCI1LLRs,SCI1.K,SCI1.N,SCI1.E,1);

        %% Then, decode the TB and the 2nd-stage SCI
        if ~(simLocal.PerfectChannelEstimator)
            dmrsLayerIndices = PSSCH_DMRSindices;
            dmrsLayerSymbols = PSSCH_DMRSsymbols;

            [estChannelGrid,noiseEst] = nrChannelEstimate(carrier,rxGrid,dmrsLayerIndices,dmrsLayerSymbols,'CDMLengths',[1,1]);  %
        end

        % Get PSSCH resource elements from the received grid
        [psschRx,psschHest] = nrExtractResources(PSSCHindices,rxGrid,estChannelGrid);       
        % PSSCH Equalization
        [psschEq,SCHcsi] = nrEqualizeMMSE(psschRx,psschHest,noiseEst);    
        % PSSCH Decoding (CONDITIONED on the 1st-stage SCI decoding), soft bits output
       % [TBLLRs, SCI2LLRs, TBrxSymbols, SCI2rxSymbols] = nrPSSCHDecode(PSSCH.Modulation,psschEq,numel(SCI2cw),noiseEst,SCI1.CRCdecRx);
        % PSSCH Decoding (NOT CONDITIONED on the 1st-stage SCI decoding), soft bits output
        [TBLLRs, SCI2LLRs, TBrxSymbols, SCI2rxSymbols] = nrPSSCHDecode(PSSCH.Modulation,psschEq,numel(SCI2cw),noiseEst,SCI1.CRCdec,SCI2.Enable,PSSCH.NumLayers);

        % Apply channel state information (CSI) produced by the equalizer,
        if SCI2.Enable
            SCI2csi = nrLayerDemap(SCHcsi(1:numel(SCI2cw)/2));
            Qm = length(SCI2LLRs) / length(SCI2rxSymbols);  
            SCI2csi = reshape(repmat(SCI2csi{1}.',Qm,1),[],1);
            SCI2LLRs = SCI2LLRs .* SCI2csi;

            % Decode the 2nd-stage SCI
            [SCI2rxBits,SCI2err,CRCdecRx] = nrSCIDecode(SCI2LLRs,SCI2.K,SCI2.N,SCI2.E,2);
        else
            SCI2err = 0;
        end

        TBcsi = nrLayerDemap(SCHcsi(numel(SCI2cw)/2+1:end));
        Qm = length(TBLLRs) / length(TBrxSymbols);
        TBcsi = reshape(repmat(TBcsi{1}.',Qm,1),[],1);
        TBLLRs = TBLLRs .* TBcsi;

        % Decode the TB       
        decodeSLSCHLocal.TransportBlockLength = TBS;
        [TBrxBits,TBerr] = decodeSLSCHLocal(TBLLRs,PSSCH.Modulation,PSSCH.NumLayers,harqEntity.RedundancyVersion,harqEntity.HARQProcessID); 

        if simLocal.DebugSimulation
            fprintf('\nSCI1 error? %d, SCI2 error? %d, TB error? %d\n',SCI1err,SCI2err,TBerr);
        end

        SCI1_BLER(snrIdx) = SCI1_BLER(snrIdx) + SCI1err;
        SCI2_BLER(snrIdx) = SCI2_BLER(snrIdx) + SCI2err;
        TB_BLER(snrIdx) = TB_BLER(snrIdx) + TBerr;
        
        % Update current process with CRC error and advance to next process
        procstatus = updateAndAdvance(harqEntity,TBerr,TBS,trBlk_G);
        if (simLocal.DisplaySimulationInformation)
            fprintf('\n(%3.2f%%) NSlot=%d, %s',100*(nslot+1)/NSlots,nslot,procstatus);
        end

        if (simLocal.DisplaySimulationInformation)
            fprintf('\n(%3.2f%%) NSlot=%d, TB CR=%1.3f%',100*(nslot+1)/NSlots,nslot,simLocal.PSSCH.TargetCodeRate);
            fprintf(', SCI2 CR=%1.3f%',SCI2.K/SCI2.E);
            fprintf(', SCI1 CR=%1.3f%',SCI1.K/SCI1.E);           
            fprintf(', TBerr = %d',TBerr);
            fprintf(', SCI2err = %d',SCI2err);     
            fprintf(', SCI1err = %d',SCI1err);                
        end

    end

    SCI1_BLER(snrIdx) = SCI1_BLER(snrIdx) / NSlots;
    SCI2_BLER(snrIdx) = SCI2_BLER(snrIdx) / NSlots;
    TB_BLER(snrIdx) = TB_BLER(snrIdx) / NSlots;
    TBS_out(snrIdx) = TBS;
    SCI1_CR_out(snrIdx) = SCI1.K/SCI1.E;
    SCI2_CR_out(snrIdx) = SCI2.K/SCI2.E;

    % Display the results dynamically in the command window
    if (simLocal.DisplaySimulationInformation)
        fprintf('\n');
        fprintf('\n1st-stage SCI BLER for %d frame(s) = %.4f\n',simLocal.NFrames,SCI1_BLER(snrIdx));
        fprintf('2nd-stage SCI BLER for %d frame(s) = %.4f\n',simLocal.NFrames,SCI2_BLER(snrIdx));
        fprintf('TB BLER for %d frame(s) = %.4f\n',simLocal.NFrames,TB_BLER(snrIdx));

    end

end

    
%% Results
if ~simParameters.DebugSimulation
    FirstStageLegend = ['SCI1-QPSK/' num2str(round(SCI1_CR_out(1)*1024)) '-' num2str(simParameters.PSSCH.NumSubchannels) ' SCH'];
    SecondStageLegend = ['SCI2-QPSK/' num2str(round(SCI2_CR_out(1)*1024)) '-' num2str(simParameters.PSSCH.NumSubchannels) ' SCH'];
    TBLegend = ['TB-' simParameters.PSSCH.Modulation '/' num2str(round(simParameters.PSSCH.TargetCodeRate*1024)) '-' num2str(simParameters.PSSCH.NumSubchannels) ' SCH'];
    figure(); hold on;
    plot(simParameters.SNRIn,SCI1_BLER,'d--','DisplayName',FirstStageLegend)
    plot(simParameters.SNRIn,SCI2_BLER,'s-.','DisplayName',SecondStageLegend)
    plot(simParameters.SNRIn,TB_BLER,'o-','DisplayName',TBLegend)

    xlabel('SNR (dB)'); ylabel('BLER'); grid on;
    title(sprintf('SCS=%dkHz / %s %d/1024 / %dx%d / %s / %d Hz / %d SCH', ...
        simParameters.Carrier.SubcarrierSpacing, ...
        simParameters.PSSCH.Modulation, ...
        round(simParameters.PSSCH.TargetCodeRate*1024),simParameters.NTxAnts,simParameters.NRxAnts, ...
        InputChannelModel,simParameters.MaximumDopplerShift,simParameters.PSSCH.NumSubchannels));
    legend()

    outFileName = ['Results/V8_SL_BLER_' num2str(simParameters.Carrier.SubcarrierSpacing) 'kHz_' simParameters.PSSCH.Modulation '_' num2str(round(simParameters.PSSCH.TargetCodeRate*1024)) ...
        '_' num2str(simParameters.NTxAnts) 'T' num2str(simParameters.NRxAnts) 'R_' num2str(simParameters.PSSCH.DMRSLength) 'DMRS_' num2str(simParameters.MaximumDopplerShift) 'Hz_' num2str(TBS_out(1)) ...
        '_' num2str(round(SCI1_CR_out(1)*1024)) '_' num2str(round(SCI2_CR_out(1)*1024)) '_' InputChannelModel '_SCH' num2str(simParameters.PSSCH.NumSubchannels)];

    path = convertCharsToStrings(outFileName);
    savefig(path);
end

end

%% Local Functions
function validateNumLayers(simParameters)
% Validate the number of layers, relative to the antenna geometry

    numlayers = simParameters.PSSCH.NumLayers;
    ntxants = simParameters.NTxAnts;
    nrxants = simParameters.NRxAnts;
    antennaDescription = sprintf('min(NTxAnts,NRxAnts) = min(%d,%d) = %d',ntxants,nrxants,min(ntxants,nrxants));
    if numlayers > min(ntxants,nrxants)
        error('The number of layers (%d) must satisfy NumLayers <= %s', ...
            numlayers,antennaDescription);
    end
    
    % Display a warning if the maximum possible rank of the channel equals
    % the number of layers
    if (numlayers > 2) && (numlayers == min(ntxants,nrxants))
        warning(['The maximum possible rank of the channel, given by %s, is equal to NumLayers (%d).' ...
            ' This may result in a decoding failure under some channel conditions.' ...
            ' Try decreasing the number of layers or increasing the channel rank' ...
            ' (use more transmit or receive antennas).'],antennaDescription,numlayers); %#ok<SPWRN>
    end

end

