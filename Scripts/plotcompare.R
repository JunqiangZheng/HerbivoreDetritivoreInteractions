# A function for plotting the comparison between model simulations.

# This function is used in the script: complex_model_direct_model_multiple_model.R

plotcompare <- function(OUTPUTALL, typevar){
  outdataCOMP = datatomodel2a %>% 
    left_join(as_tibble(OUTPUTALL) %>% filter(Type == typevar) %>% select(-P1, -P2, -Type, - Treatment2, -Treatment3) %>% gather(-time, -Treatment, key = StateVar, value = Model))
  
  SVorder = unique(outdataCOMP$StateVar)
  
  vec = rep(NA, length(SVorder))
  for(i in 1:length(SVorder)){
    ms =lm(Biomass~Model + 0, data=outdataCOMP %>% filter(StateVar==SVorder[i]))
    mss = ifelse(ms$coefficients[1]>=0, "", "-")
    vec[i] = paste0("R[Full]^2 == ",mss,round(summary(ms)$adj.r.squared,2))
  }
  rm(ms, mss)
  vec2 = rep(NA, length(SVorder))
  for(i in 1:length(SVorder)){
    ms =lm(Biomass~Model + 0, data=outdataCOMP %>% 
             filter(StateVar==SVorder[i] & Treatment %in% c("N","H","W","HW")))
    mss = ifelse(ms$coefficients[1]>=0, "", "")
    vec2[i] = paste0("R[Expt]^2 == ",mss, round(summary(ms)$adj.r.squared,2))
  }
  
  
  maxes = outdataCOMP %>% 
    group_by(StateVar) %>%
    summarize(BMmax = max(max(upper), max(Model)))
  
  ann_text <- tibble(SVorder, vec, vec2) %>%
    gather(-SVorder, key = type, value = R2) %>%
    rename(StateVar = SVorder) %>%
    left_join(maxes) %>%
    mutate(Model = ifelse(StateVar == "P", BMmax*0.7,BMmax*0.3)) %>%
    mutate(Biomass = ifelse(StateVar == "P",
                            ifelse(type == "vec", BMmax*0.35, BMmax*0.2),
                            ifelse(type == "vec", BMmax*0.9, BMmax*0.75)))
  
  rm(vec, vec2)
  
  XLAB = ifelse(typevar == "Single", "Model", 
                ifelse(typevar == "Direct"| typevar == "Direct2", "Direct effect model (One plant species)", "Model (Two plant species)"))
  
  NNNNN <- c(
    "H" = "Herbivore (Grasshopper)" ,
    "M" = "Microbial",
    "N" = "Inorganic",
    "P" = "Plant",
    "W" = "Detritivore (Earthworm)",
    "L" = "Litter"
  )
  
  pppppp = ggplot(outdataCOMP, aes(x=Model, y=Biomass, color=Treatment)) + geom_abline(intercept=0, slope=1, lty=2) + geom_point() + geom_errorbar(data = outdataCOMP, aes(ymin = lower, ymax = upper, color=Treatment)) +  facet_wrap(c("StateVar"), scales="free", labeller=labeller(StateVar =NNNNN)) + theme_classic() + scale_color_manual(values=c("purple", "brown", "green", "blue", "pink", "red"),labels=c("None (Expt)", "Worm (Expt)", "Hopper (Expt)", "Both (Expt)", "Removal", "Addition")) + 
    geom_text(data = ann_text,label = ann_text$R2, color="black", parse=T) + 
    geom_blank(data = maxes %>% mutate(Model = BMmax, Biomass = BMmax, Treatment = "N") %>% bind_rows(maxes %>%  mutate(Model = 0, Biomass = 0, Treatment = "N"))) + xlab(XLAB)  +
    theme(legend.position = c(1, 0),
          legend.justification = c(1, 0),
          legend.box = "horizontal") + 
    xlab("Model Biomass") + 
    ylab("Field Biomass")
  
  return(pppppp)
}
