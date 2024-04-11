%A_BSantenna BS antenna gain pattern, see TR 38.901 Table 7.3-1

% Copyright 2017-2018 The MathWorks, Inc.

%#codegen

function A = A_BSantenna(theta_prime,phi_prime)
    
%    SLA_V = 30.0;     % Side-Lobe Attenuation (dB) TR 38.901 Table 7.3-1
    SLA_V = 20.0;    % Side-Lobe Attenuation (dB) TR 37.885 Table 6.1.4-8

%    theta_3dB = 65.0; % Vertical Half-Power Beam-Width (degrees) TR 38.901 Table 7.3-1
    theta_3dB = 90.0; % Vertical Half-Power Beam-Width (degrees) TR 37.885 Table 6.1.4-8

%    A_m = 30.0;       % Front-to-back attenuation ratio (dB) TR 38.901 Table 7.3-1
    A_m = 20.0;       % Front-to-back attenuation ratio (dB) TR 37.885 Table 6.1.4-8

%    phi_3dB = 65.0;   % Horizontal Half-Power Beam-Width (degrees) TR 38.901 Table 7.3-1
    phi_3dB = 120.0;   % Horizontal Half-Power Beam-Width (degrees) TR 37.885 Table 6.1.4-8

%    G_max = 8.0;      % Maximum directional gain of an element (dBi) TR 38.901 Table 7.3-1
    G_max = 3.0;      % Maximum directional gain of an element (dBi) TR 37.885 Table 6.1.4-8

    % antenna element vertical radiation pattern (dB)
    A_EV = -min(12*((theta_prime-90)/theta_3dB).^2,SLA_V);
    
    % antenna element horizontal radiation pattern (dB)
    A_EH = -min(12*(phi_prime/phi_3dB).^2,A_m);
    
    % combining method for 3D antenna element pattern (dB)
    A = -min(-(A_EV + A_EH),A_m);
    
    % incorporate maximum gain and convert to linear power
    A = 10.^((A + G_max)/10);
    
end
