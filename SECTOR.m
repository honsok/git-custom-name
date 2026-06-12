function [sector,N] = SECTOR(V_alpha, V_beta)
%SECTOR  根据 αβ 分量判断 SVPWM 扇区（1..6）
%   输入: V_alpha, V_beta - 标量
%   输出: sector - 扇区编号，1 到 6。若无法判定返回 0

% 计算三相参考（逆 Clarke）
Va = V_alpha;
Vb = -0.5 * V_alpha + sqrt(3)/2 * V_beta;
Vc = -0.5 * V_alpha - sqrt(3)/2 * V_beta;

% 按符号判定 A,B,C（边界包括0）
A = (Va >= 0);
B = (Vb >= 0);
C = (Vc >= 0);

% 按图中公式 N = 4*C + 2*B + A 映射到扇区
N = 4 * C + 2 * B + A;

switch N
    case 3
        sector = 1; % A=1 B=1 C=0
    case 1
        sector = 2; % A=1 B=0 C=0
    case 5
        sector = 3; % A=1 B=0 C=1
    case 4
        sector = 4; % A=0 B=0 C=1
    case 6
        sector = 5; % A=0 B=1 C=1
    case 2
        sector = 6; % A=0 B=1 C=0
    otherwise
        sector = 0; % 不可达或数值误差
end

end


