function [Sa, Sb, Sc, info] = FOC_all(u_alpha, u_beta, Ts, Vdc, t, align)
%FOC_all  整合 SECTOR, XYZ, PWM, signal 四个功能于一处
%
%   [Sa,Sb,Sc,info] = FOC_all(u_alpha,u_beta,Ts,Vdc,t,align)
%
% Inputs:
%   u_alpha, u_beta  - αβ 参考电压
%   Ts               - 开关周期 (秒)
%   Vdc              - 直流母线电压
%   t                - 时间向量（用于采样 Sa/Sb/Sc）
%   align            - 'edge' (默认) 或 'center'，决定脉宽对齐方式
%
% Outputs:
%   Sa,Sb,Sc - 开关状态向量（0/1），与 t 同尺寸
%   info     - 结构体，包含中间量: sector, N, Tfirst, Tsecond, T0, Ta,Tb,Tc, Tcm1,Tcm2,Tcm3
%
% 说明：该函数按以下顺序计算：
%  1) 由 u_alpha,u_beta 计算三相 Va,Vb,Vc，并得到位编码 N = 4*C+2*B+A
%  2) 根据 N 和 (u_alpha,u_beta,Ts,Vdc) 计算 Tfirst,Tsecond,T0（参照 XYZ）
%  3) 计算 Ta,Tb,Tc（参照 PWM 中间量）
%  4) 根据 N 排布得 Tcm1,Tcm2,Tcm3
%  5) 使用时间向量 t 和对齐方式生成 Sa,Sb,Sc

if nargin < 5
    error('FOC_all:NotEnoughInputs','Usage: [Sa,Sb,Sc,info]=FOC_all(u_alpha,u_beta,Ts,Vdc,t,align)');
end
if nargin < 6 || isempty(align)
    align = 'edge';
end

% 1) 逆 Clarke 得三相参考
Va = u_alpha;
Vb = -0.5 * u_alpha + sqrt(3)/2 * u_beta;
Vc = -0.5 * u_alpha - sqrt(3)/2 * u_beta;

A = (Va >= 0);
B = (Vb >= 0);
C = (Vc >= 0);

N = 4 * C + 2 * B + A;  % 1..6 (二进制编码)

% sector（可选，按常见映射）
switch N
    case 3, sector = 1;
    case 1, sector = 2;
    case 5, sector = 3;
    case 4, sector = 4;
    case 6, sector = 5;
    case 2, sector = 6;
    otherwise, sector = 0;
end

% 2) 计算 Tfirst, Tsecond, T0（来自 XYZ）
if Vdc == 0
    error('FOC_all:BadVdc','Vdc must be nonzero');
end

X = sqrt(3) * Ts * u_beta / Vdc;
Y = sqrt(3) * Ts / Vdc * (sqrt(3)/2 * u_alpha + 1/2 * u_beta);
Z = sqrt(3) * Ts / Vdc * (-sqrt(3)/2 * u_alpha + 1/2 * u_beta);

Tfirst_table  = [ Z,  Y, -Z, -X,  X, -Y ];
Tsecond_table = [ Y, -X,  X,  Z, -Y, -Z ];

if N < 1 || N > 6
    error('FOC_all:BadN','Computed N must be in 1..6');
end

Tfirst  = Tfirst_table(N);
Tsecond = Tsecond_table(N);

if Tfirst + Tsecond > Ts
    scale  = Ts / (Tfirst + Tsecond);
    Tfirst = Tfirst * scale;
    Tsecond = Tsecond * scale;
    T0 = 0;
else
    T0 = (Ts - Tfirst - Tsecond) / 2;
end

% 3) 计算 Ta,Tb,Tc（与原 PWM 一致的中间量）
Ta = (Ts - Tfirst - Tsecond)/4;
Tb = (Ts - Tfirst + Tsecond)/4;
Tc = (Ts + Tfirst + Tsecond)/4;

% 4) 根据 N 排布 Tcm1/Tcm2/Tcm3（对应原 PWM）
switch N
    case 1
        Tcm1 = Tb; Tcm2 = Tc; Tcm3 = Ta;
    case 2
        Tcm1 = Ta; Tcm2 = Tc; Tcm3 = Tb;
    case 3
        Tcm1 = Ta; Tcm2 = Tb; Tcm3 = Tc;
    case 4
        Tcm1 = Tc; Tcm2 = Tb; Tcm3 = Ta;
    case 5
        Tcm1 = Tc; Tcm2 = Ta; Tcm3 = Tb;
    case 6
        Tcm1 = Tb; Tcm2 = Ta; Tcm3 = Tc;
    otherwise
        error('FOC_all:BadN2','Unexpected N');
end

% 5) 生成 Sa,Sb,Sc。支持 'edge'（从周期起始高电平）和 'center'（在 Ts/2 居中）对齐
tmod = mod(t, Ts);

switch lower(align)
    case {'edge','leading'}
        Sa = double(tmod < Tcm1);
        Sb = double(tmod < Tcm2);
        Sc = double(tmod < Tcm3);
    case {'center','centred'}
        mid = Ts/2;
        Sa = double(abs(tmod - mid) < (Tcm1/2));
        Sb = double(abs(tmod - mid) < (Tcm2/2));
        Sc = double(abs(tmod - mid) < (Tcm3/2));
    otherwise
        error('FOC_all:BadAlign','align must be ''edge'' or ''center''.');
end

% pack info
info = struct();
info.sector = sector;
info.N = N;
info.Tfirst = Tfirst;
info.Tsecond = Tsecond;
info.T0 = T0;
info.Ta = Ta; info.Tb = Tb; info.Tc = Tc;
info.Tcm1 = Tcm1; info.Tcm2 = Tcm2; info.Tcm3 = Tcm3;

end
