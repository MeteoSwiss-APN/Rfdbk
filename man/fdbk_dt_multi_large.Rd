% Generated by roxygen2 (4.0.2): do not edit by hand
\name{fdbk_dt_multi_large}
\alias{fdbk_dt_multi_large}
\title{Function to load one or many fdbk Files and transform them to a data.table.
Faster than fdbk_dt_multi and able to handle very large files, however,
be as restrictive as possible, use the cond/columnnames argument select only the data you need for your problem.
Note: Using conditions on veri_data in the cond argument is not possible and may cause an error!!!
Solution: filter veri_data in the returned data.table}
\usage{
fdbk_dt_multi_large(fnames, condition = "", vars = "", cores = 1)
}
\arguments{
\item{fnames}{vector of feedback filename(s)}

\item{cores}{use multiple cores for parallel file loading}

\item{cond}{list of strings of conditions (all of the list entries are connected with the "&" operator!)}

\item{columnnames}{attribute names to keep in the data table}
}
\value{
a data.table of merged feedback file contents
}
\description{
Function to load one or many fdbk Files and transform them to a data.table.
Faster than fdbk_dt_multi and able to handle very large files, however,
be as restrictive as possible, use the cond/columnnames argument select only the data you need for your problem.
Note: Using conditions on veri_data in the cond argument is not possible and may cause an error!!!
Solution: filter veri_data in the returned data.table
}
\examples{
#EXAMPLE 1 (1x1 deg.) bias of satellite data (channel 921 from METOP-1)
require(ggplot2)
fnames      = system("/bin/ls ~/examplesRfdbk/example_monRad/monRAD_*.nc",intern=T)
condition   = list(obs="!is.na(obs)",
                   level="level\%in\%c(921)",
                   statid="statid=='METOP-1   '",
                   veri_forecast_time="veri_forecast_time==0",
                   veri_run_type="veri_run_type==3",
                   veri_ens_member="veri_ens_member==-1")
columnnames = c("obs","veri_data","lon","lat","veri_initial_date")
DT          = fdbk_dt_multi_large(fnames,condition,columnnames,cores=1)
DT
DT[,lon:=round(lon)]
DT[,lat:=round(lat)]
scores = DT[,list(ME=mean(obs-veri_data)),by=c("lon","lat")]
outlines = as.data.table(map("world", plot = FALSE)[c("x","y")])
worldmap = geom_path(aes(x, y), inherit.aes = FALSE, data = outlines, alpha = 0.8, show_guide = FALSE,size = .2)
p = ggplot(scores,aes(x=lon,y=lat,fill=cut(ME,seq(-100,100,20))))+geom_raster()+
    scale_fill_manual("ME",values=tim.colors(10),drop = FALSE)+
    worldmap
p

 #EXAMPLE 2 TEMP EPS plot for one station on reversed-log-y scale
require(ggplot2)
require(scales)
fname="~/examplesRfdbk/eps/2013111112/verTEMP.nc"
condition           = list(veri_description="grepl('first guess vv',veri_description)",
                           veri_description="grepl('member',veri_description)",
                           state="state\%in\%c(0,1)",
                           statid="statid=='01028     '")
columns             = c("obs","veri_data","varno","level","veri_description","veri_forecast_time","statid")
DT                  = fdbk_dt_multi_large(fname,condition,columns,1)
DT$veri_description = as.numeric(substr(DT$veri_description,29,32))
setnames(DT,"veri_description","member")
DT[,varno:=varno_to_name(varno,F)]
reverselog_trans <- function(base = exp(1)) {
     trans <- function(x) -log(x, base)
     inv <- function(x) base^(-x)
     trans_new(paste0("reverselog-", format(base)), trans, inv,
               log_breaks(base = base),
               domain = c(1e-100, Inf))
}

# plot only even members for clearness+ obs as black line
ggplot(DT[DT$member\%\%2==0,],aes(x=veri_data,y=level,color=factor(member)))+geom_path()+geom_point()+facet_wrap(~varno,scale="free_x")+
      scale_y_continuous(trans=reverselog_trans(10))+
      geom_point(data =DT[member==1], aes(x=obs,y=level), colour = "black")+
      geom_path(data =DT[member==1], aes(x=obs,y=level), colour = "black")+
      ggtitle(paste("EPS TEMP for station",unique(DT$statid)))

 #EXAMPLE 3 SATELLITE RADIATION plot verification scores as function of channel and staellite
require(ggplot2)
fnames      = system("ls ~/examplesRfdbk/example_monRad/monRAD_*.nc",intern=T)
condition   = list(obs="!is.na(obs)",
                   level="level>100 & level<6000",
                   veri_forecast_time="veri_forecast_time==0",
                   veri_run_type="veri_run_type==3",
                   veri_ens_member="veri_ens_member==-1")
DT         = fdbk_dt_multi_large(fnames,condition,c("obs","veri_data","level","statid"),1)
scores     = fdbk_dt_verif_continuous(DT,c("level","statid"))
ggplot(scores,aes(x=level,y=scores,color=statid,group=statid))+geom_line()+geom_point()+facet_wrap(~scorename,scale="free")
}
\author{
Felix <felix.fundel@dwd.de>
}

