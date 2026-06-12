function [Sa, Sb, Sc] = signal(Tcm1, Tcm2, Tcm3, triangular_waveform)

    Sa = (triangular_waveform < Tcm1);
    Sb = (triangular_waveform < Tcm2);
    Sc = (triangular_waveform < Tcm3);

end