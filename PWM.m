function [Tcm1, Tcm2, Tcm3] = PWM(N, T_first, T_second, T_s)

Ta = (T_s-T_first - T_second)/4;
Tb = (T_s-T_first + T_second)/4;
Tc = (T_s+T_first + T_second)/4;
switch N
    case 1
        Tcm1 = Tb;
        Tcm2 = Ta;
        Tcm3 = Tc;
    case 2
        Tcm1 = Ta;
        Tcm2 = Tc;
        Tcm3 = Tb;
    case 3
        Tcm1 = Ta;
        Tcm2 = Tb;
        Tcm3 = Tc;
    case 4
        Tcm1 = Tc;
        Tcm2 = Tb;
        Tcm3 = Ta;
    case 5
        Tcm1 = Tc;
        Tcm2 = Ta;
        Tcm3 = Tb;
    case 6
        Tcm1 = Tb;
        Tcm2 = Tc;
        Tcm3 = Ta;
    otherwise
        error('PWM:InvalidSector', 'Sector N must be an integer from 1 to 6.');
end
end
