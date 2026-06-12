function [Tfirst, Tsecond, T0] = XYZ(Ts, u_alpha, u_beta, Vdc, N)
% calcTimings 计算图中 Tfirst、Tsecond 和 T0（T7）
% 输入:
%   Ts      - 开关周期
%   u_alpha - α 轴参考电压
%   u_beta  - β 轴参考电压
%   Vdc     - 直流母线电压
%   N       - 4C+2B+A
%
% 输出:
%   Tfirst  - 非零向量第一个持续时间
%   Tsecond - 非零向量第二个持续时间
%   T0      - 零向量时间 T0（等价于 T7）

X = sqrt(3) * Ts * u_beta / Vdc;
Y = sqrt(3) * Ts / Vdc * (sqrt(3)/2 * u_alpha + 1/2 * u_beta);
Z = sqrt(3) * Ts / Vdc * (-sqrt(3)/2 * u_alpha + 1/2 * u_beta);

Tfirst_table  = [ Z,  Y, -Z, -X,  X, -Y ];
Tsecond_table = [ Y, -X,  X,  Z, -Y, -Z ];

if N < 1 || N > 6
    error('Sector N must be an integer from 1 to 6.');
end

Tfirst  = Tfirst_table(N);
Tsecond = Tsecond_table(N);

if Tfirst + Tsecond > Ts
    % 过调制处理：当两个非零向量时间之和超过一个开关周期时，按比例压缩
    % 使 Tfirst + Tsecond = Ts，并将 T0 设为零。这样可避免出现负的零矢量时间。
    scale  = Ts / (Tfirst + Tsecond);
    Tfirst = Tfirst * scale;
    Tsecond = Tsecond * scale;
    T0 = 0;
else
    T0 = (Ts - Tfirst - Tsecond) / 2;
end
end