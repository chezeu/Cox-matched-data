


library(survival)
library(rootSolve)
library(nleqslv)

setwd("C:/Users/fchezeut/Documents/GitHub/Cox-matched-data/Methods")

source("2_risk_function.R")
source("3_naive_method.R")
source("4_method_w_sum1.R")
source("5_method_w_sum2.R")
source("6_method_EM.R")
source("7_method_q_sum.R")

setwd("C:/Users/fchezeut/Documents/GitHub/Cox-matched-data/data_generation")
source("1_data_generate_Q_inconnu.R")
source("2_matrice_Q_inconnu.R")
source("3_scenarios_Q_inconnu.R")

################### nsim monte carlos
estimates_survival<- function(nsim,nA,nB,p,beta,K,prevalence,censor){
  
  
  
  coef_true_s = matrix(0,nrow = nsim, ncol = p)
  
  coef_naive_s = matrix(0,nrow = nsim, ncol = p)
  converge_naive = vector()
  
  coef_w_sum1_s = matrix(0,nrow = nsim, ncol = p)
  converge_w_sum1 = vector()
  
  coef_w_sum2_s = matrix(0,nrow = nsim, ncol = p)
  converge_w_sum2 = vector()
  
  coef_estimate_s = matrix(0,nrow = nsim, ncol = p)
  converge_estimate = vector()
  
  coef_Q_sum_s = matrix(0,nrow = nsim, ncol = p)
  converge_Q_sum = vector()
  
  for (i in 1:nsim){
    
    #data generation
    mf = Generate_data(K,nA,nB,prevalence,censor,min_prev = 0.01)
    surv_data = mf$surv_data
    XB = mf$XB
    data_true=surv_data
    idBA=mf$idBA
    
    databaseA=mf$databaseA
    databaseB =mf$ databaseB
    
    datA=mf$datA # matching variables
    datB= mf$datB
    #####
    #record linkage 
    comp_mat = compare_binary (datA, datB, K)
    linked = Matrix_Q(comp_mat,K,datA, datB)
    Q=linked$Q
   # apply(Q,1,sum)
    number=linked$number
    
    naive_id = linked$naive_id
    dif=linked$dif
    #####naive 
    naive_data = generate_naive_data(naive_id,XB , surv_data)
   
    Z = as.matrix(naive_data[,-c(1,2)])
    
    Ts = data_true$Time
    event = data_true$delta
    
    lambda0 =  rep(0.1,length(event))
    lambda0 [which(event == 0)] = 0
    beta0 = rep(0.1,p)
    
    # times of event
    # death_times= Ts[which(event==1)]
    
    
    # Theoretical estimating equation for true and naive data
    fit_true = coxph(Surv(Time,delta)~.,data = data_true)
    coef_true_s[i,] = as.vector(fit_true$coefficients)
    
    # naive method
    fit_naive = coxph_equa_naive(Ts,event, Z, maxiter = 20)
    coef_naive_s[i,] = fit_naive$coef
    converge_naive[i] = fit_naive$converge
    
    # method with weighted average
    fit_w_sum1 = coxph_w_sum1(Ts,event,XB, Q,maxiter = 20)
    coef_w_sum1_s[i,] = fit_w_sum1$coef
    converge_w_sum1[i] = fit_w_sum1$converge
    
    #method with the maximum of proba
    fit_w_sum2 = coxph_w_sum2(Ts,event,XB, Q, maxiter = 20)
    coef_w_sum2_s[i,] = fit_w_sum2$coef
    converge_w_sum2[i] = fit_w_sum2$converge
    
    # method with Q average
    fit_Q_sum = coxph_Q_sum(Ts,event,XB, Q,maxiter = 20)
    coef_Q_sum_s[i,] = fit_Q_sum$coef
    converge_Q_sum[i] = fit_Q_sum$converge
    
    # EM method
    fit_estimate = Func_itteration(beta0,lambda0,Ts,event,XB,Q,tol= 1e-6,maxits = 300)
    coef_estimate_s[i,] = fit_estimate$beta0
    it_EM = fit_estimate$it
    
    
  }
  
  return(list( coef_true_s1 = coef_true_s[,1], coef_true_s2 = coef_true_s[,2],coef_true_s3 = coef_true_s[,3],
               coef_naive_s1 = coef_naive_s[,1], coef_naive_s2 = coef_naive_s[,2], coef_naive_s3 = coef_naive_s[,3], 
               coef_w_sum1_s1 = coef_w_sum1_s[,1],coef_w_sum1_s2 = coef_w_sum1_s[,2],coef_w_sum1_s3 = coef_w_sum1_s[,3], 
               coef_w_sum2_s1 = coef_w_sum2_s[,1], coef_w_sum2_s2 = coef_w_sum2_s[,2],coef_w_sum2_s3 = coef_w_sum2_s[,3], 
               coef_Q_sum_s1 = coef_Q_sum_s[,1],coef_Q_sum_s2 = coef_Q_sum_s[,2], coef_Q_sum_s3= coef_Q_sum_s[,3], 
               coef_estimate_s1 = coef_estimate_s[,1], coef_estimate_s2 = coef_estimate_s[,2],  coef_estimate_s3 = coef_estimate_s[,3],
               converge_naive = converge_naive,  converge_w_sum1= converge_w_sum1,
               converge_w_sum2 = converge_w_sum2, converge_Q_sum= converge_Q_sum,converge_estimate = converge_estimate )) } 
######################################



setwd("C:/Users/fchezeut/Documents/GitHub/Cox-matched-data/Results/Results_Q_inconnu")

for (i in (1:nrow(scenarios))){
  nsim=scenarios[i,1]
  K=scenarios[i,2]
  nA=scenarios[i,3]
  nB= scenarios[i,4]
  censor= scenarios[i,5]
  prevalence = rep(prevalence_sample,K)
  
  results_sample = estimates_survival(nsim,nA,nB,p,beta,K,prevalence,censor) #monte carlos
  
  filename = paste0("C:/Users/fchezeut/Documents/GitHub/Cox-matched-data/Results/Results_Q_inconnu/","nsim=",nsim,
                    "_nA=",nA,"_nB=",nB, "_K=",K,"censor=",censor,".Rdata")
  
  save(results_sample,file = filename)
  
}

