% test_FOC_all - Demo for FOC_all
% This script builds a PMSM model, derives αβ voltages from the simulated
% three-phase currents, and tests FOC_all with the reconstructed u_alpha/u_beta.

Ts = 1e-3;
Vdc = 48;

% PMSM model parameters
motor.Rs    = 0.35;       % Stator resistance (ohm)
motor.Ls    = 4e-3;       % Stator inductance (H)
motor.psi_f = 0.12;       % Permanent magnet flux linkage (Wb)
motor.p     = 4;          % Pole pairs

omega_m = 120 * 2*pi;      % Mechanical speed (rad/s)

% 输入电压命令，用于产生 PMSM 电流
u_alpha_cmd = 8;
u_beta_cmd  = 4;

t_sim = 0:Ts/200:5*Ts;
[i_a, i_b, i_c, i_alpha, i_beta, u_alpha_est, u_beta_est, pmsm_info] = ...
    PMSM_model(u_alpha_cmd, u_beta_cmd, omega_m, motor, t_sim);

% 从三相电流恢复 αβ 分量
i_alpha_from_abc = i_a;
i_beta_from_abc  = (i_a + 2 * i_b) / sqrt(3);

% 采用 PMSM 模型推算得到的电压参考作为 FOC 输入
u_alpha = u_alpha_est(end);
u_beta  = u_beta_est(end);

fprintf('PMSM u_alpha_cmd = %.4g, u_beta_cmd = %.4g\n', u_alpha_cmd, u_beta_cmd);
fprintf('Reconstructed u_alpha = %.4g, u_beta = %.4g\n', u_alpha, u_beta);
fprintf('Final currents: i_a = %.4g, i_b = %.4g, i_c = %.4g\n', i_a(end), i_b(end), i_c(end));

% 生成 FOC 开关信号
t = linspace(0, 3*Ts, 1000);
[Sa, Sb, Sc, info] = FOC_all(u_alpha, u_beta, Ts, Vdc, t, 'center');

fprintf('sector = %d, N = %d\n', info.sector, info.N);
fprintf('Tfirst = %.6g, Tsecond = %.6g, T0 = %.6g\n', info.Tfirst, info.Tsecond, info.T0);
fprintf('Tcm1 = %.6g, Tcm2 = %.6g, Tcm3 = %.6g\n', info.Tcm1, info.Tcm2, info.Tcm3);

figure;
subplot(2,1,1);
plot(t, Sa, 'r', t, Sb, 'g', t, Sc, 'b', 'LineWidth', 1.2);
ylim([-0.2 1.2]);
xlabel('time (s)');
ylabel('switch state');
legend('Sa','Sb','Sc');
title('FOC\\_all switching signals');
grid on;

subplot(2,1,2);
plot(t_sim, i_a, 'r', t_sim, i_b, 'g', t_sim, i_c, 'b', 'LineWidth', 1.2);
xlabel('time (s)');
ylabel('current (A)');
legend('i_a','i_b','i_c');
title('PMSM three-phase current response');
grid on;
