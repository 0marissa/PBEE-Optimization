function [c_vec1,c_vec2] = SBXcrossover(p_vec1,p_vec2, nVar)
% SBXcrossover - real-coded crossover method 

pcross_real  =  1;
eta_c        =  0.5;
min_realvar  =  0 * ones(1, nVar);
max_realvar  =  1 * ones(1, nVar);

% Testing SBX: Simulated binary crossover

nreal = length(p_vec1);

epsilon = 1.0e-14 ;
% ncross = 0 ;

c_vec1 = zeros(1,nreal);
c_vec2 = zeros(1,nreal);

if(rand(1) <= pcross_real) 

    for i = 1:nreal
        
       if (rand(1) <= 0.5)
           
           if (abs(p_vec1(i) - p_vec2(i)) > epsilon)
                if (p_vec1(i) < p_vec2(i))
                    y1 = p_vec1(i) ;
                    y2 = p_vec2(i) ;
                else
                    y1 = p_vec2(i) ;
                    y2 = p_vec1(i) ;
                end
                
                yl = min_realvar(i); % y "lower"
                yu = max_realvar(i); % y "upper"
                
                r = rand(1) ; 
                
                % spread factor beta
                beta_ = 1.0 + (2.0 * (y1 - yl) / (y2 - y1)); 
                alpha_ = 2.0 - (beta_ ^ (-1.0 * (eta_c + 1.0))); 
                
                if (r <= (1.0 / alpha_))
                        betaq = (r * alpha_) ^ (1.0/(eta_c + 1.0));
                else
                        betaq = (1.0 / (2.0 - r * alpha_)) ^ (1.0 / (eta_c + 1.0));
                end
                
                c1 = 0.5 * ((y1 + y2) - (betaq * (y2 - y1)));

                % spread factor beta
                beta_ = 1.0 + (2.0 * (yu - y2)/(y2 - y1));
                alpha_ = 2.0 - (beta_ ^ (-1.0 * (eta_c + 1.0)));
                
                if (r <= (1.0 / alpha_))
                        betaq = (r * alpha_) ^ (1.0 / (eta_c + 1.0));
                else
                        betaq = (1.0 / (2.0 - r * alpha_)) ^ (1.0 / (eta_c + 1.0));
                end
                
                c2 = 0.5 * ((y1 + y2) + (betaq * (y2 - y1)));
                
                if (c1 < yl)
                    c1 = yl;
                end
                
                if (c2 < yl)
                    c2 = yl;
                end	
                
                if (c1 > yu)
                    c1 = yu;
                end		
                
                if (c2 > yu)
                    c2 = yu;
                end				
                
                if (rand(1) <= 0.5)
                    c_vec1(i) = c2;
                    c_vec2(i) = c1;
                else
                    c_vec1(i) = c1;
                    c_vec2(i) = c2;
                end
                
            else
                c_vec1(i) = p_vec1(i) ;
                c_vec2(i) = p_vec2(i) ;
            end
            
        else
            c_vec1(i) = p_vec1(i) ;
            c_vec2(i) = p_vec2(i) ;
        end
    end
    
else
    c_vec1 = p_vec1 ;
    c_vec2 = p_vec2 ;    
end
end




