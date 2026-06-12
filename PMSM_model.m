function [i_a, i_b, i_c, i_alpha, i_beta, u_alpha_est, u_beta_est, info] = PMSM_model(u_alpha_cmd, u_beta_cmd, omega_m, motor, t)
%PMSM_model  简化的 PMSM αβ 轨迹模型
%   [i_a, i_b, i_c, i_alpha, i_beta, u_alpha_est, u_beta_est, info] = ...
%       PMSM_model(u_alpha_cmd, u_beta_cmd, omega_m, motor, t)
%
% Inputs:
%   u_alpha_cmd, u_beta_cmd - 定子参考电压（αβ 静止坐标系）
%   omega_m                 - 电机机械角速度 (rad/s)
%   motor                   - 结构体，包含 Rs, Ls, psi_f, p
%   t                       - 时间向量
%
% Outputs:
%   i_a, i_b, i_c           - 三相电流轨迹
%   i_alpha, i_beta         - Clarke 变换后的 αβ 电流
%   u_alpha_est, u_beta_est - 由电机模型电流推算出的 αβ 电压
%   info                    - 结构体，包含模型状态

if nargin < 5
    error('PMSM_model:NotEnoughInputs','Usage: [i_a,i_b,i_c,...]=PMSM_model(u_alpha_cmd,u_beta_cmd,omega_m,motor,t)');
end

if ~isfield(motor,'Rs') || ~isfield(motor,'Ls') || ~isfield(motor,'psi_f') || ~isfield(motor,'p')
    error('PMSM_model:BadMotor','motor must contain fields Rs, Ls, psi_f, p');
end

if numel(t) < 2
    error('PMSM_model:BadTime','t must contain at least two points');
end

dt = t(2) - t(1);
omega_e = motor.p * omega_m;

theta_e = omega_e * t;

N = numel(t);
i_alpha = zeros(1, N);
i_beta  = zeros(1, N);

for k = 2:N
    e_alpha = -omega_e * motor.psi_f * sin(theta_e(k-1));
    e_beta  =  omega_e * motor.psi_f * cos(theta_e(k-1));

    di_alpha = (u_alpha_cmd - motor.Rs * i_alpha(k-1) + omega_e * motor.Ls * i_beta(k-1) - e_alpha) / motor.Ls;
    di_beta  = (u_beta_cmd  - motor.Rs * i_beta(k-1) - omega_e * motor.Ls * i_alpha(k-1) - e_beta) / motor.Ls;

    i_alpha(k) = i_alpha(k-1) + dt * di_alpha;
    i_beta(k)  = i_beta(k-1)  + dt * di_beta;
end

% 三相电流的逆 Clarke 变换（假设 i_a + i_b + i_c = 0）
i_a = i_alpha;
i_b = -0.5 * i_alpha + sqrt(3)/2 * i_beta;
i_c = -0.5 * i_alpha - sqrt(3)/2 * i_beta;

% 由电流和机电方程重构 αβ 电压
u_alpha_est = motor.Rs * i_alpha + motor.Ls * gradient(i_alpha, dt) - omega_e * motor.Ls .* i_beta + (-omega_e * motor.psi_f .* sin(theta_e));
u_beta_est  = motor.Rs * i_beta  + motor.Ls * gradient(i_beta, dt)  + omega_e * motor.Ls .* i_alpha + (omega_e * motor.psi_f .* cos(theta_e));

info = struct();
info.omega_m = omega_m;
info.omega_e = omega_e;
info.theta_e = theta_e;
info.motor = motor;
info.u_alpha_cmd = u_alpha_cmd;
info.u_beta_cmd = u_beta_cmd;
info.t = t;
info.i_alpha = i_alpha;
info.i_beta = i_beta;
end
