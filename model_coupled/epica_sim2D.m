function [sim_x, sim_n1, sim_n2] = epica_sim2D(obj1,obj2,Y,M,abN,br_win,plotting)
%
% FUNCTION: epica_sim(obj,Y,M,m)
%
% PURPOSE: use simple Euler's method to simulate data based on 1D
% stochastic ODE model
%
% INPUT: 
% - obj: DataSet object for the data you want to use
% - Y: number of "years" (sectors) to divide data into
% - M: number of "months" (subsections) to divide "years" into
% - m: offset in "years" for autocorrelation of f
%
% OUTPUT: 
% - sim_x: x-values for the resulting simulated data
% - sim_y: y-values generated by the simulation
%
%%

    % set default values
    if nargin == 5
        br_win = 0;
        plotting = 0;
    elseif nargin == 6
        plotting = 0;
    end

    
    % unpack model parameters
    a1 = abN(1,:);
    a2 = abN(2,:);
    b12 = abN(3,:);
    b21 = abN(4,:);
    N1 = abN(5,:);
    N2 = abN(6,:);
    

    % get timestep and white noise
    global xx;
    delt = range(xx) / (Y*M);
    wx1 = randn(Y*M);
    wx2 = randn(Y*M);


    % initialize simulation arrays
    sim_n1 = zeros(1,Y*M);
    sim_n2 = zeros(1,Y*M);
    if br_win == 0
        sim_n1(1) = obj1.Y(1) - obj1.data_mean;
        sim_n2(1) = obj2.Y(1) - obj2.data_mean;
    else
        sim_n1(1) = 0;
        sim_n2(1) = 0;
    end
    
    % initialize counter
    i = 1;
    
    %% Euler's Method simulation
    for j=1:Y
        for k=1:M
            sim_n1(i+1) = sim_n1(i) + a1(k)*sim_n1(i)*delt + N1(k)*wx1(i)*sqrt(delt) + b12(k)*(sim_n2(i) - sim_n1(i))*delt;
            sim_n2(i+1) = sim_n2(i) + a2(k)*sim_n2(i)*delt + N2(k)*wx2(i)*sqrt(delt) + b21(k)*(sim_n1(i) - sim_n2(i))*delt;
            i = i + 1;
        end
    end
    
    
    %fprintf("i=%d:\tsim_n1=%.3e, a1=%.3e, N1=%.3e, wx1=%.3e, b12=%.3e \n", i, sim_n1(i), a1(k), N1(k), wx1(i), b12(k));
    %fprintf("\t\tsim_n1=%.3e, a1=%.3e, N1=%.3e, wx1=%.3e, b12=%.3e\nn\n", sim_n2(i), a2(k), N2(k), wx2(i), b21(k));
            

    

    %% RK4 simulation
    %{
    for j=1:Y
        for k=1:M
            
            kp1 = mod_1n(k+1,M);
            
            
            
            %% first time series (sim_n1)

            % [ (k) + (k+1) ] / 2
            a1_kph = mean([a1(k),a1(kp1)]);
            N1_kph = mean([N1(k),N1(kp1)]);
            b12_kph = mean([b12(k),b12(kp1)]);
            wx1_kph = mean([wx1(i),wx1(i+1)]);
            

            % find k1, k2, k3, k4
            k1_1 = a1(k)*sim_n1(i)*delt + N1(k)*wx1(i)*sqrt(delt) + b12(k)*(sim_n2(i) - sim_n1(i))*delt;
            k2_1 = a1_kph * (sim_n1(i)+delt/2*k1_1) * delt + N1_kph*wx1_kph*sqrt(delt) + b12_kph*(sim_n2(i) - sim_n1(i))*delt;
            k3_1 = a1_kph * (sim_n1(i)+delt/2*k2_1) * delt + N1_kph*wx1_kph*sqrt(delt) + b12_kph*(sim_n2(i) - sim_n1(i))*delt;
            k4_1 = a1(kp1)* (sim_n1(i)+delt*k3_1) *delt + N1(kp1)*wx1(kp1)*sqrt(delt) + b12(kp1)*(sim_n2(i) - sim_n1(i))*delt;
            
            % put together to get next simulated point
            sim_n1(i+1) = sim_n1(i) + delt/6 * (k1_1 + 2*k2_1 + 2*k3_1 + k4_1);

            
            
            
            %% second time series (sim_n2)
            
            % [ (k) + (k+1) ] / 2
            a2_kph = mean([a2(k),a2(kp1)]);
            N2_kph = mean([N2(k),N2(kp1)]);
            b21_kph = mean([b21(k),b21(kp1)]);
            wx2_kph = mean([wx2(i),wx2(i+1)]);
            
            % find k1, k2, k3, k4
            k1_2 = a2(k)*sim_n2(i)*delt + N2(k)*wx2(i)*sqrt(delt) + b21(k)*(sim_n1(i) - sim_n2(i))*delt;
            k2_2 = a2_kph * (sim_n2(i)+delt/2*k1_2) * delt + N2_kph*wx2_kph*sqrt(delt) + b21_kph*(sim_n1(i) - sim_n2(i))*delt;
            k3_2 = a2_kph * (sim_n2(i)+delt/2*k2_2) * delt + N2_kph*wx2_kph*sqrt(delt) + b21_kph*(sim_n1(i) - sim_n2(i))*delt;
            k4_2 = a2(kp1) * (sim_n2(i)+delt*k3_2) * delt + N2(kp1)*wx2(kp1)*sqrt(delt) + b21(kp1)*(sim_n1(i) - sim_n2(i))*delt;
            
            % put together to get next simulated point
            sim_n2(i+1) = sim_n2(i) + delt/6 * (k1_2 + 2*k2_2 + 2*k3_2 + k4_2);
            
            
            % increment counter
            i = i + 1;
         
            
        end
    end
    %}
    
    
    %% create array of x-values to go with simulated y-values
    sim_x = ( linspace(1,length(sim_n1)+1,length(sim_n1)) - length(sim_n1) ) * range(obj1.X) / length(sim_n1);
    
    
    
    
    %% plot results and data
    
    if plotting
    
        [matrix_x1,matrix_y1,~] = data2matrix(obj1,Y,M,br_win);
        data_x1 = reshape(matrix_x1',[],1);
        data_y1 = reshape(matrix_y1',[],1);

        [matrix_x2,matrix_y2,~] = data2matrix(obj2,Y,M,br_win);
        data_x2 = reshape(matrix_x2',[],1);
        data_y2 = reshape(matrix_y2',[],1);

        ymax = 1.1 * max([max(abs(data_y1)),max(abs(data_y2))]);


        tiledlayout("flow");

        nexttile
        plot(data_x1,data_y1,'Color','blue');
        xlim([-8*10^5,0]);
        ylim([-ymax, ymax]);
        title(sprintf("%s data",obj1.data_name));

        nexttile
        plot(sim_x,sim_n1,'Color','red');   
        xlim([-8*10^5,0]);
        ylim([-ymax, ymax]);
        title(sprintf("%s simulation",obj1.data_name));
        
        nexttile
        plot(data_x2,data_y2,'Color','blue');
        xlim([-8*10^5,0]);
        ylim([-ymax, ymax]);
        title(sprintf("%s data",obj2.data_name));
        
        nexttile
        plot(sim_x,sim_n2,'Color','red'); 
        xlim([-8*10^5,0]);
        ylim([-ymax, ymax]);
        title(sprintf("%s simulation",obj2.data_name));
    
    end
    

end
