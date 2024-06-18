# Function to load all packages from a list silently and install all packages that aren't already installed

get_packages<-function(plist){
  # Install packages not yet installed
  installed_packages <- plist %in% rownames(installed.packages())
  if (any(installed_packages == FALSE)) {
    install.packages(plist[!installed_packages])
  }
  # Packages loading
  invisible(lapply(plist, library, character.only = TRUE))}

load_cats<-function(copy=F){
  if(copy!=F){
    cats=read.delim(pipe('pbpaste'),na.strings="N/A")
  }
  else{
  file=file.choose()
  cats=read_excel(file)
  }
  cats<<-cats
}

process_cats<-function(df){
  df %>% 
    pivot_longer(.,as.character(seq(5))) %>% 
    mutate(Score=as.numeric(name)) %>% 
    uncount(weight=value) %>% 
    select(-name) %>%
  mutate(across(ends_with("Avg")|matches('[[:digit:]]'),~as.numeric(.x)))->res
  return(res)}

plot_bycourse<-function(cats){
  cats %>% 
    mutate(TermDate=my(paste0("0",MonthCode,Year)),Term=paste0(Semester,Year),RT_Category=str_replace_all(RT_Category,"_"," "),Course=str_replace_all(Course,"_"," ")) %>% 
    arrange(TermDate,Course) %>% {. ->> temp} %>%
    ggplot(.,aes(x=RT_Category,y=Score,color=RT_Category))+
      stat_summary(fun.data='mean_cl_boot',shape='triangle',size=1)+geom_point(alpha=0.3,position=position_jitterdodge(0.2,0.2))+
      facet_wrap(~Course)+
      scale_color_brewer(palette='Set2',name="Question")+
      scale_y_continuous(breaks=seq(1,5,by=0.5))+
      coord_flip(ylim=c(2,5))+geom_hline(yintercept=4,linetype='dashed')+
      geom_label(data=temp %>% 
                 group_by(Course,RT_Category) %>% 
                 tally(),aes(label=paste0("n = ",n)),x=1,y=2.25,color='black',fill='lightblue')+
      labs(x="R&T Question",y="Score")
}

plot_bysemester<-function(cats,dept=F,college=F){
  cats %>% 
    mutate(TermDate=my(paste0("0",MonthCode,Year)),Term=paste0(Semester,Year),NewSem=fct_relevel(Semester,c("SP","SU","FA")), RT_Category=str_replace_all(RT_Category,"_"," "),Course=str_replace_all(Course,"_"," ")) %>% 
    arrange(TermDate,Course) %>% {. ->> temp} %>%
    ggplot(.,aes(x=interaction(NewSem,Year),y=Score,color=RT_Category,fill=RT_Category,group=RT_Category))+
    stat_summary(fun.data='mean_cl_boot',shape='triangle',size=1)+geom_point(alpha=0.3,position=position_jitterdodge(0.2,0.2))+
    geom_smooth(method='gam',formula=y~s(x,k=4,m=2),alpha=0.3,color='black')+
    facet_grid(.~RT_Category)+
    scale_color_brewer(palette='Set2',name="Question")+
    scale_fill_brewer(palette='Set2',name="Question")+
    geom_hline(yintercept=4,linetype='dashed')+
    labs(x="Term",y="Score")+
    theme(axis.text.x=element_text(angle=30,size=12,vjust=1,hjust=1))->p
  if(dept!=F & college!=F){
    res<-p+stat_summary(shape='square',color='firebrick',aes(y=DeptAvg),fun.data='mean_cl_boot')+
      geom_errorbar(aes(ymin=Dept_25,ymax=Dept_75),color='black',linetype='dotted',width=0.5)+
      geom_line(aes(y=DeptAvg),color='firebrick',linetype='dotted')+
      stat_summary(shape='circle',color='darkblue',aes(y=College_Avg),fun.data='mean_cl_boot')+
      geom_errorbar(aes(ymin=College_25,ymax=College_75),color='black',linetype='dotted',width=0.5)+
      geom_line(aes(y=College_Avg),color='darkblue',linetype='dotted')
       }
  else if(dept!=F){
    res<-p+stat_summary(shape='square',color='firebrick',aes(y=DeptAvg),fun.data='mean_cl_boot')+
      geom_errorbar(aes(ymin=Dept_25,ymax=Dept_75),color='black',linetype='dotted',width=0.5)+
      geom_line(aes(y=DeptAvg),color='firebrick',linetype='dotted')
  }
   else if(college!=F){
     res<-p+stat_summary(shape='circle',color='darkblue',aes(y=College_Avg),fun.data='mean_cl_boot')+
       geom_errorbar(aes(ymin=College_25,ymax=College_75),color='black',linetype='dotted',width=0.5)+
       geom_line(aes(y=College_Avg),color='darkblue',linetype='dotted')
   }
  else{res<-p}
  print(res)
}

# Implement
plist=list('stringr','dplyr','tidyr','lubridate','ggplot2','forcats','readxl','gridExtra')
get_packages(plist)

# Set visualization theme based on theme_minimal()
mytheme<-theme_minimal()+theme(legend.position='bottom',panel.background=element_rect(color='black'),strip.text=element_text(size=15),axis.title=element_text(size=15),axis.text=element_text(size=12))
theme_set(mytheme)

# Load and process survey data (called CATS)
cats<-load_cats() %>% process_cats()

# Default plots by course and semester
cats %>% plot_bycourse()
cats %>% plot_bysemester()

# Plots divided by course type (Cognitive Science [CGS] or Spanish [SPA])
cats %>% filter(Prefix=="CGS") %>% plot_bysemester()+ggtitle("Cognitive Science Courses")->cgs
cats %>% filter(Prefix=="SPA") %>% plot_bysemester()+ggtitle("Spanish Courses")->spa
grid.arrange(cgs,spa)
