function [SCI2cw,Qprime_SCI2,K,N,E] = nrSCI2Encode(SCI2bits,TargetCodeRate,numREs_SCI2)
% nrSCI2Encode 2nd-stage SCI encoding
% [sci2CW,Qprime_SCI2] = nrSCI2Encode(sci2Bits,TargetCodeRate,numREs_SCI2) encodes
% the input 2nd-stage SCI bits, sci2Bits, as per TS 38.212 Sections 8.4.2, 8.4.3 and 8.4.4


    O_SCI2 = numel(SCI2bits);              % Number of 2nd stage SCI bits
    L_SCI2 = 24;                           % 24 bits CRC
    Qm_SCI2 = 2;                           % 2nd-stage SCI employs QPSK, see clause 8.3.1.2 TS 38.211
    R = TargetCodeRate;
    slScaling = 1;                         % sl-Scaling allowed values: 0.5, 0.65, 0.8 and 1. See sl-Scaling in TS 38.331
    betaOffset_SCI2 = 1.125;               % see Table 9.3-2 TS 38.213

    Qprime_SCI2_firstTerm = ceil( ( (O_SCI2+L_SCI2)*betaOffset_SCI2 )/(Qm_SCI2*R) );
    Qprime_SCI2_secondTerm = ceil(slScaling * numREs_SCI2);
    Qprime_SCI2 = min([Qprime_SCI2_firstTerm, Qprime_SCI2_secondTerm]);   % Number of coded modulation symbols, see clause 8.4.4 TS 38.212
    G_SCI2 = Qprime_SCI2*Qm_SCI2;                                         % Output bit sequence length after encoding
    assert(G_SCI2 <= 4096, "2nd-stage SCI size after econding is too large");

    % CRC attachment, Section 8.4.2 TS 38.212
    bitscrcPad = nrCRCEncode([ones(24,1,class(SCI2bits));SCI2bits],"24C"); % prepend 1s
    cVec = bitscrcPad(25:end,1);            % remove 1s. cVec is the 2nd-stage SCI after CRC attachment

    % Channel coding, Section 8.4.3 TS 38.212
    K = length(cVec);
    nMAX = 9;
    iIL = true;
    E = G_SCI2;
    encOut = nrPolarEncode(cVec,E,nMAX,iIL);
    N = length(encOut);

    % Rate matching, Section 8.4.4 TS 38.212
    I_BIL = true;
    SCI2cw = nrRateMatchPolar(encOut,K,E,I_BIL);

    % Iterate over possible configurations and plot the results
%     betaOffset_values = [1.125 1.250 1.375 1.625 1.750 2.000 2.250 2.500 2.875 3.125 ... 
%         3.500 4.000 5.000 6.250 8.000 10.000 12.625 15.875 20.000];    % see Table 9.3-2 TS 38.213   
%     TargetCodeRates = [120 157 193 251 308 379 449 526 602 679];
%     scaling = [0.5 1];
% 
%     figure();
%     set(groot,'defaultAxesTickLabelInterpreter','latex');  
%     xlabel('$\beta_{\mathit{offset}}$','FontSize',28,'Interpreter','latex');
%     ylabel('2nd-stage SCI Code rate','FontSize',28,'Interpreter','latex');
%     box on; grid on; hold on;     
% 
%     SCI2_codeRates = zeros(numel(betaOffset_values),1);
%     X = 1:numel(betaOffset_values);
%     for k=1:numel(scaling)
%         slScaling = scaling(k);
%         for j=1:numel(TargetCodeRates)
%             R = TargetCodeRates(j)/1024;
%             for i=1:numel(betaOffset_values)
%                 betaOffset_SCI2 = betaOffset_values(i);
%                 Qprime_SCI2_firstTerm = ceil( ( (O_SCI2+L_SCI2)*betaOffset_SCI2 )/(Qm_SCI2*R) );
%                 Qprime_SCI2_secondTerm = ceil(slScaling * numREs_SCI2);
%                 Qprime_SCI2 = min([Qprime_SCI2_firstTerm, Qprime_SCI2_secondTerm]);
%                 SCI2_codeRates(i) = O_SCI2/(Qprime_SCI2*Qm_SCI2);
%             end
%             label = ['$\alpha = ' num2str(slScaling) '$, CR = ' num2str(R*1024)];
%             plot(X,SCI2_codeRates,'LineWidth',2,'DisplayName',label)
%         end
%     end
%     titleLabel = ['$N_{\mathit{symbol}}^{\mathit{PSCCH}}=' ...
%         num2str(simParams.SCI1.TimeResourcePSCCH) '$, $N_{\mathit{PRBs}}^{\mathit{PSCCH}}=' ...
%         num2str(simParams.SCI1.FreqResourcePSCCH) '$, $N_{\mathit{PRBs}}^{\mathit{PSSCH}}=' ...
%         num2str(simParams.PSSCH.SubchannelSize) '$'];
%     title(titleLabel,'Interpreter','latex');
%     set(gca,'FontSize',28);
%     legend('FontSize',28)
%     set(legend,'Interpreter','latex');
%     outFileName = ['Figures/NsymbolPSCCH_' ...
%         num2str(simParams.SCI1.TimeResourcePSCCH) '_NPRBsPSCCH_' ...
%         num2str(simParams.SCI1.FreqResourcePSCCH) '_NPRBsPSSCH_' ...
%         num2str(simParams.PSSCH.SubchannelSize) '.fig'];
%     path = convertCharsToStrings(outFileName);
%     savefig(path);


end


% function validateInputs(sciBits,rnti,E)
% % Check inputs
% 
%     fcnName = 'nrSCIEncode';
% 
%     % Validate input DCI message bits, length must be greater than or equal
%     % to 12 and less than or equal to 140
%     validateattributes(sciBits,{'int8','double'},{'binary','column'}, ...
%         fcnName,'SCIBITS');
%     Kin = length(sciBits);
%     coder.internal.errorIf( Kin<12 || Kin>140, ...
%         'nr5g:nrDCIEncode:InvalidInputLength',Kin);
% 
%     % Validate radio network temporary identifier RNTI (0...65535)
%     validateattributes(rnti,{'numeric'}, ...
%         {'scalar','nonnegative','integer','<=',2^16-1},fcnName,'RNTI');
% 
%     % Validate rate matched output length which must be greater than K+24
%     validateattributes(E,{'numeric'}, ...
%         {'scalar','integer','>',Kin+24},fcnName,'E');
% 
% end
