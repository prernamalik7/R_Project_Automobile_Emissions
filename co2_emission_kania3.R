co2_emi_sample <- read.csv("C:/Users/galz_/Desktop/DANA 4801/project/CO2_emission_vehicle/data/Sample_CO2Emission.csv")
attach(co2_emi_sample)
library(ggplot2)
library(ggrepel)

#create data frame
df<- data.frame(co2_emi_sample)

#rename columns to be used
library(dplyr)
df<- df %>% rename(co2.emissions = CO2.Emissions..g.km., engine.size = Engine.Size..L.,
                   fuel.consumption.comb = Fuel.Consuption..Comb..L.100.km.,
                   fuel.consumption.city = Fuel.Consumption..City..L.100.km., 
                   fuel.consumption.hwy = Fuel.Consumption..Hwy..L.100.km.)


#plot each variables with co2 emissions (y) to see relationship of variables with co2.emissions
for (i in 1:length(colnames(df)))
{
  if (colnames(df)[i] != "co2.emissions")
  {
    plot<- ggplot(data = df) + geom_point(mapping = aes(x = df[,i], y = co2.emissions)) 
    print(plot + labs(y="CO2 Emissions", x = colnames(df)[i], title = paste("CO2 Emissions VS",colnames(df[i]))))
    
  }
}


#investigate transmission: 
ggplot(data = df, aes(x = fuel.consumption.comb, y = co2.emissions, color = Transmission)) + 
  geom_point() +
  labs(x = "Fuel Consumption Comb (L/100km)", y = "CO2 Emissions (g/km)", title = "Transmission") 
  

#investigate vehicle class:  
ggplot(data = df, aes(x = fuel.consumption.comb, y = co2.emissions, color = Vehicle.Class)) + 
  geom_point() +
  labs(x = "Fuel Consumption Comb (L/100km)", y = "CO2 Emissions (g/km)", title = "Vehicle Class")
  

#vehicle class categorized into cars and trucks, 2 levels, 1 dummy variable
#cars: two-seater, minicompact, subcompact, compact, mid-size, full-size, station wagon (small & mid-size)
#trucks: pick-up truck(small & standard), SUV (small& standard), minivan, passenger van, special purpose vehicle 
df$car.vehicle <- rep(0, length(df$Vehicle.Class))
for (i in 1:length(df$Vehicle.Class))
{
  if (df$Vehicle.Class[i] == "Two-seater" | 
      df$Vehicle.Class[i] == "Minicompact" | 
      df$Vehicle.Class[i] == "Subcompact" | 
      df$Vehicle.Class[i] == "Compact" | 
      df$Vehicle.Class[i] == "Mid-size" | 
      df$Vehicle.Class[i] == "Full-size" | 
      df$Vehicle.Class[i] == "Station wagon: Small" | 
      df$Vehicle.Class[i] == "Station wagon: Mid-size")
  {
    df$car.vehicle[i] <-1
  }
}

ggplot(data = df, aes(x = fuel.consumption.comb, y = co2.emissions, color = car.vehicle)) +
  geom_point() + 
  labs(x = "Fuel Consumption Comb (L/100km)", y = "CO2 Emissions (g/km)", title = "Cars (1) & Trucks (0)")

#investigate engine size:
ggplot(data = df, aes(x = fuel.consumption.comb, y = co2.emissions, color = engine.size)) + 
  geom_point() + 
  labs(x = "Fuel Consumption Comb (L/100km)", y = "CO2 Emissions (g/km)", title = "Engine Size") 


#investigate fuel type:
ggplot(data = df, aes(x = fuel.consumption.comb, y = co2.emissions, color = Fuel.Type)) + 
  geom_point() +
  labs(x = "Fuel Consumption Comb (L/100km)", y = "CO2 Emissions (g/km)", title = "Fuel Type") +
  scale_color_manual("Fuel Type",
                     values = c('coral2', 'springgreen3', 'lightskyblue', 'plum4'),
                     breaks = c('D', 'E', 'X', 'Z'),
                     labels = c('Diesel', 'Ethanol', 'Regular Gasoline', 'Premium Gasoline'))

#investigate cylinders
ggplot(data = df, aes(x = fuel.consumption.comb, y = co2.emissions, color = Cylinders)) + 
  geom_point() +
  labs(x = "Fuel Consumption Comb (L/100km)", y = "CO2 Emissions (g/km)", title = "Number of Cylinders") 


#fuel type, 4 levels; 3 dummy variable
#premium gasoline,Z, as baseline
df$ethanol <- rep(0,length(df$Fuel.Type)) #E
df$ethanol[df$Fuel.Type == "E"]<-1

df$reg.gas<- rep(0,length(df$Fuel.Type)) #X
df$reg.gas[df$Fuel.Type == "X"]<-1

df$diesel<- rep(0,length(df$Fuel.Type)) #D
df$diesel[df$Fuel.Type == "D"]<-1


#initial fitting of model- fuel consumption comb, fuel type, vehicle class (linear 1st order r/s, no interaction)
fit.first <- lm(co2.emissions~ fuel.consumption.comb + ethanol + reg.gas + diesel + Cylinders + engine.size, data = df)
summary(fit.first)
car::vif(fit.first)

#fit model with interaction terms: fuel consumption, fuel type, cylinder, engine size
fit.inter1 <- lm(co2.emissions~ fuel.consumption.comb + ethanol + reg.gas + diesel + Cylinders + engine.size +
                   fuel.consumption.comb*ethanol + fuel.consumption.comb*reg.gas + fuel.consumption.comb*diesel +
                   fuel.consumption.comb*Cylinders + fuel.consumption.comb*engine.size + 
                   Cylinders*ethanol + Cylinders*reg.gas + Cylinders*diesel +
                   engine.size*ethanol + engine.size*reg.gas + engine.size*diesel +
                   Cylinders*engine.size +
                   fuel.consumption.comb*Cylinders*ethanol +
                   fuel.consumption.comb*Cylinders*reg.gas +
                   fuel.consumption.comb*Cylinders*diesel +
                   fuel.consumption.comb*engine.size*ethanol +
                   fuel.consumption.comb*engine.size*reg.gas + 
                   fuel.consumption.comb*engine.size*diesel +
                   fuel.consumption.comb*Cylinders*engine.size +
                   fuel.consumption.comb*ethanol*Cylinders*engine.size +
                   fuel.consumption.comb*reg.gas*Cylinders*engine.size +
                   fuel.consumption.comb*diesel*Cylinders*engine.size, data = df)
summary(fit.inter1)
#muticolinearity present

#check if cylinder is significant
fit.inter2 <- lm(co2.emissions~ fuel.consumption.comb + ethanol + reg.gas + diesel + engine.size +
                   fuel.consumption.comb*ethanol + fuel.consumption.comb*reg.gas + fuel.consumption.comb*diesel +
                   fuel.consumption.comb*engine.size + 
                   engine.size*ethanol + engine.size*reg.gas + engine.size*diesel +
                   fuel.consumption.comb*engine.size*ethanol +
                   fuel.consumption.comb*engine.size*reg.gas + 
                   fuel.consumption.comb*engine.size*diesel, data = df)

summary(fit.inter2)
anova(fit.inter1, fit.inter2)
#Partial F-test p-value >0.05, fail to reject Ho. 
#cylinder not significant


#check if engine size is significant
fit.inter3 <- lm(co2.emissions~ fuel.consumption.comb + ethanol + reg.gas + diesel +
                   fuel.consumption.comb*ethanol + fuel.consumption.comb*reg.gas + 
                   fuel.consumption.comb*diesel,  data = df)

summary(fit.inter3)
anova(fit.inter2, fit.inter3)
#Partial F-test p-value >0.05, fail to reject Ho. 
#engine size not significant

#check significant of interaction terms
fit.inter4 <- lm(co2.emissions~ fuel.consumption.comb + ethanol + reg.gas + diesel, data = df)

summary(fit.inter4)
anova(fit.inter3, fit.inter4)
#Partial F-test p-value < 0.05, reject Ho. 
#interaction term is significant


###Checking assumptions:
### 1. Lack of fit
### 2. Equal variances
### 3. Outliers

##detecting lack of fit
#residual plot: residuals vs fuel consumption 
#no trend in plot, ~95% residuals within 2s of 0
#sd=1.442
df$res <- residuals(fit.inter3)
df$res[(df$res >2.884) | (df$res < -2.884)] #outside of 2s -> 44,46,78,83,93,106,119,136,147,197

#filter points outside of 2s from df
highlight.df <- df %>% 
  filter((df$res >2.884) | (df$res < -2.884))

#plot residuals, highlight outliers, draw abline to outline regions of outliers, 
#create x&y labels and title, remove legend, add in outlier values
ggplot(data = df, aes(x = fuel.consumption.comb, y = res)) + 
  geom_point() +
  geom_point(data = highlight.df, aes(x = fuel.consumption.comb, y = res), color = 'red') +
  geom_abline(aes(intercept = 2.884, slope = 0), color = 'red') +
  geom_abline(aes(intercept = -2.884, slope = 0, color = 'red')) +
  labs(x = "Fuel Consumption Comb (L/100km)", y = "Residuals", title = "Residuals VS Fuel Consumption (Comb)") +
  theme(legend.position = 'none') +
  geom_text_repel(aes(label=ifelse((res > 2.884 |res < -2.884),round(res,4),"")), hjust=1.1)


##detecting lack of fit and unequal variances
#residual plot: residuals vs predicted y
#no trend in plot, ~95% residuals within 2s of 0, no transformation needed
df$pred <- predict(fit.inter3)

#filter points outside of 2s from df which has pred variable
highlight.df <- df %>% 
  filter((df$res >2.884) | (df$res < -2.884))

#plot residuals, highlight outliers, draw abline to outline regions of outliers, 
#create x&y labels and title, remove legend, add in outlier values
ggplot(data = df, aes(x = pred, y = res)) + 
  geom_point() +
  geom_point(data = highlight.df, aes(x = pred, y = res), color = 'red') +
  geom_abline(aes(intercept = 2.884, slope = 0), color = 'red') +
  geom_abline(aes(intercept = -2.884, slope = 0, color = 'red')) +
  labs(x = "Predicted CO2 Emissions (g/km)", y = "Residuals", title = "Residuals VS CO2 Emissions") +
  theme(legend.position = 'none') +
  geom_text_repel(aes(label=ifelse((res > 2.884 |res < -2.884),round(res,4),"")), hjust=1.1)


##double-checked order of fuel consumption and goodnes of fit
#straight line; statistically good fit
termplot(fit.inter3, partial.resid = TRUE, 
         ylab = "Partial Residuals", xlab = "Fuel Consumption Comb (L/100km)", 
         main = "Partial Residual Plot of Fuel Consumption (Comb)")


##check normality
ggplot(data = df) +
  aes(sample = res) +
  stat_qq() +
  stat_qq_line(color = 'blue') +
  labs(x = "Normal Scores", y = "Residuals", title = "Normal Probability Plot (Q-Q Plot)")
#some outliers observed


##identify outliers
df$stan.resid <- rstandard(fit.inter3)
df$stan.resid[(df$stan.resid >3) | (df$stan.resid < -3)]
#44,46,93,119,136,197

#filter points outside of 2s from df which has pred variable
highlight.stan.resid.df <- df %>% 
  filter((df$stan.resid >3) | (df$stan.resid < -3))

#plot residuals, highlight outliers, draw abline to outline regions of outliers, 
#create x&y labels and title, remove legend, add in outlier values
ggplot(data = df, aes(x = fuel.consumption.comb, y = stan.resid)) + 
  geom_point() +
  geom_point(data = highlight.stan.resid.df, aes(x = fuel.consumption.comb, y = stan.resid), color = 'red') +
  geom_abline(aes(intercept = 3, slope = 0), color = 'red') +
  geom_abline(aes(intercept = -3, slope = 0, color = 'red')) +
  labs(x = "Fuel Consumption Comb (L/100km)", y = "Standardized Residuals", title = "Standardized Residuals VS Fuel Consumption (Comb)") +
  theme(legend.position = 'none') +
  geom_text_repel(aes(label=ifelse((stan.resid > 3 |stan.resid < -3),round(res,4),"")), hjust=1.1)


#remove outliers; 10 points if use 2s from residual plot; 6 points if use 3 from stand. residual plot
df.removed <- df[-c(44, 46, 78, 83, 93, 106, 119, 136, 147, 197),]
df.removed <- df[-c(44, 46, 78, 93, 119, 136, 197),]

#double check if really removed
length(df$fuel.consumption.comb)
length(df.removed$fuel.consumption.comb)

###--------------------------------------------------Re-fit models etc; don't know if redundant------------------------------------###

#initial fitting of model- fuel consumption comb, fuel type, vehicle class (linear 1st order r/s, no interaction)
fit.first.removed <- lm(co2.emissions~ fuel.consumption.comb + ethanol + prem.gas + reg.gas + car.vehicle, data = df.removed)
summary(fit.first.removed)


#fit model with interaction terms: fuel consumption comb, fuel type and vehicle class
fit.inter.removed <- lm(co2.emissions~ fuel.consumption.comb + ethanol + prem.gas + reg.gas + car.vehicle +
                  fuel.consumption.comb*ethanol + fuel.consumption.comb*prem.gas + fuel.consumption.comb*reg.gas + 
                  fuel.consumption.comb*car.vehicle + car.vehicle*ethanol + car.vehicle*prem.gas + car.vehicle*reg.gas +
                  fuel.consumption.comb*ethanol*car.vehicle + fuel.consumption.comb*prem.gas*car.vehicle + 
                  fuel.consumption.comb*reg.gas*car.vehicle, data = df.removed)

summary(fit.inter.removed)
#colinearity present; check car.vehicle and fuel type


#use stepwise regression to decide which corelated independent variable(s) to drop
#results: drop car.vehicle
ols_step_both_p(fit.first.removed)


#fit model w/ interaction terms: fuel consumption and fuel type, fuel consumption and vehicle class
#no interaction b/wn fuel type and vehicle class
#goal: remove colinearity
fit.inter.reduced.removed <- lm(co2.emissions~ fuel.consumption.comb + ethanol+prem.gas + reg.gas + car.vehicle +
                          fuel.consumption.comb*ethanol + fuel.consumption.comb*prem.gas + fuel.consumption.comb*reg.gas + 
                          fuel.consumption.comb*car.vehicle, data = df.removed)

summary(fit.inter.reduced.removed)


#fit model w/ interaction terms: fuel consumption and fuel type
fit.inter.reduced2.removed <- lm(co2.emissions~ fuel.consumption.comb + ethanol + prem.gas + reg.gas +
                           fuel.consumption.comb*ethanol + fuel.consumption.comb*prem.gas + fuel.consumption.comb*reg.gas, 
                           data = df.removed)

summary(fit.inter.reduced2.removed)


#partial F-test w/ fit.inter.reduced gives p-value>0.05. Fail to reject Ho 
#car.vehicle not significant; 
anova(fit.inter.reduced.removed, fit.inter.reduced2.removed)


#check significance of interaction term
fit.simple.removed <- lm(co2.emissions~ fuel.consumption.comb+ethanol+prem.gas+reg.gas, data = df.removed) 
summary(fit.simple.removed)
anova(fit.inter.reduced2.removed,fit.simple.removed)
#p-value < 0.05, reject Ho. Interaction term is useful in model.
#final model: fit.inter.reduced2


###Checking assumptions:
### 1. Lack of fit
### 2. Equal variances
### 3. Outliers

##detecting lack of fit
#residual plot: residuals vs fuel consumption 
#no trend in plot, ~95% residuals within 2s of 0
#sd=1.103
df.removed$res <- residuals(fit.inter.reduced2.removed)
df.removed$res[(df.removed$res >2.206) | (df.removed$res < -2.206)] #outside of 2s -> 44,46,78,83,93,106,119,136,147,197

#filter points outside of 2s from df
highlight.df.removed <- df.removed %>% 
  filter((df.removed$res >2.206) | (df.removed$res < -2.206))

#plot residuals, highlight outliers, draw abline to outline regions of outliers, 
#create x&y labels and title, remove legend, add in outlier values
ggplot(data = df.removed, aes(x = fuel.consumption.comb, y = res)) + 
  geom_point() +
  geom_point(data = highlight.df.removed, aes(x = fuel.consumption.comb, y = res), color = 'red') +
  geom_abline(aes(intercept = 2.206, slope = 0), color = 'red') +
  geom_abline(aes(intercept = -2.206, slope = 0, color = 'red')) +
  labs(x = "Fuel Consumption Comb (L/100km)", y = "Residuals", title = "Residuals VS Fuel Consumption (Comb) Without Outliers") +
  theme(legend.position = 'none') +
  geom_text_repel(aes(label=ifelse((res > 2.206 |res < -2.206),round(res,4),"")), hjust=1.1)


##detecting lack of fit and unequal variances
#residual plot: residuals vs predicted y
#no trend in plot, ~95% residuals within 2s of 0, no transformation needed
df.removed$pred <- predict(fit.inter.reduced2.removed)

#filter points outside of 2s from df
highlight.df.removed <- df.removed %>% 
  filter((df.removed$res >2.206) | (df.removed$res < -2.206))

#plot residuals, highlight outliers, draw abline to outline regions of outliers, 
#create x&y labels and title, remove legend, add in outlier values
ggplot(data = df.removed, aes(x = pred, y = res)) + 
  geom_point() +
  geom_point(data = highlight.df.removed, aes(x = pred, y = res), color = 'red') +
  geom_abline(aes(intercept = 2.206, slope = 0), color = 'red') +
  geom_abline(aes(intercept = -2.206, slope = 0, color = 'red')) +
  labs(x = "Predicted CO2 Emissions (g/km)", y = "Residuals", title = "Residuals VS Predicted CO2 Emissions Without Outliers") +
  theme(legend.position = 'none') +
  geom_text_repel(aes(label=ifelse((res > 2.206 |res < -2.206),round(res,4),"")), hjust=1.1)


##double-checked order of fuel consumption and goodnes of fit
#straight line; statistically good fit
termplot(fit.inter.reduced2.removed, partial.resid = TRUE, 
         ylab="Partial Residuals", xlab="Fuel Consumption Comb (L/100km)", 
         main="Partial Residual Plot of Fuel Consumption (Comb) Without Outliers")


##check normality
ggplot(data = df.removed) +
  aes(sample = res) +
  stat_qq() +
  stat_qq_line(color = 'blue') +
  labs(x = "Normal Scores", y = "Residuals", title = "Normal Probability Plot (Q-Q Plot) Without Outliers")
#lies close to the straight line


##identify outliers
df.removed$stan.resid <- rstandard(fit.inter.reduced2.removed)
df.removed$stan.resid[(df.removed$stan.resid >3) | (df.removed$stan.resid < -3)]

#filter points outside of 2s from df which has pred variable
highlight.stan.resid.df.removed <- df.removed %>% 
  filter((df.removed$stan.resid >3) | (df.removed$stan.resid < -3))

#plot residuals, highlight outliers, draw abline to outline regions of outliers, 
#create x&y labels and title, remove legend, add in outlier values
ggplot(data = df.removed, aes(x = fuel.consumption.comb, y = stan.resid)) + 
  geom_point() +
  geom_point(data = highlight.stan.resid.df.removed, aes(x = fuel.consumption.comb, y = stan.resid), color = 'red') +
  geom_abline(aes(intercept = 3, slope = 0), color = 'red') +
  geom_abline(aes(intercept = -3, slope = 0, color = 'red')) +
  labs(x = "Fuel Consumption Comb (L/100km)", y = "Standardized Residuals", title = "Standardized Residuals VS Fuel Consumption (Comb) Without Outliers") +
  theme(legend.position = 'none') +
  geom_text_repel(aes(label=ifelse((stan.resid > 3 |stan.resid < -3),round(res,4),"")), hjust=1.1)


###------------------------------------------------------------------------------------------------------------------------------------------------##    

## if no need to re-fit model to deleted data, just run this line           
#replot 
plot(df.removed$fuel.consumption.comb, stan.resid.removed, ylab="Standardized Residuals", xlab="Fuel Consumption Comb", main="Standardized Residual Plot of Fuel Consumption Comb")
abline(0,0)
abline(3,0) #show regions w/ outliers
abline(-3,0) #show regions w/ outliers
stan.resid.removed[(stan.resid.removed >3) | (stan.resid.removed < -3)]


