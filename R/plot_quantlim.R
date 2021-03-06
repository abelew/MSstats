#' The goal of this function is to calculate the LOB/LOD of the data provided in the data frame.
#'
#' The function returns a new data frame containing the value of the LOB/LOD
#'
#' @param spikeindata  Data from our spiked-in proteins
#' @param quantlim_out  Output from the quantlim function
#' @param alpha damn smart people
#' @param dir_output  Presumably a place to put the output
#' @param Plot the xlim!?
#' @return something which I don't know what it is...
#' @export
plot_quantlim <- function(spikeindata, quantlim_out, alpha, dir_output, xlim_plot) {
  ## I am pretty strongly against having the function print the plots without returning them.
  ## What if I want to put them as svgs or pngs or whatever?
  if (is.null(quantlim_out)) {
    logging::logwarn("Assay fit was not calculated by linear_quantlim/nonlinear_quantlim and won't be plotted.")
    return(NULL)
  }

  ##percentile of the prediction interval considered
  if (missing(alpha)) {
    alpha <- 5 / 100
  }
  if (alpha >= 1 | alpha <= 0) {
    logging::logwarn("incorrect specified value for alpha, 0 < alpha < 1, setting it to 0.5!")
    alpha <- 0.5
  }

  expdata <- spikeindata
  datain <- quantlim_out
  ##Define some colors here for the plots:
  black1 <- "#000000"
  orange1 <- "#E69F00"
  blue1 <- "#56B4E9"
  green1 <- "#009E73"
  yellow1 <- "#F0E442"
  blue2 <- "#0072B2"
  red1 <- "#D55E00"
  pink1 <- "#CC79A7"
  cbbPalette <- c(black1, orange1, blue1, green1, yellow1, blue2, red1, pink1)

  ##Rename variables for the function:
  names(datain)[names(datain) == "CONCENTRATION"] <- "C"
  names(expdata)[names(expdata) == "CONCENTRATION"] <- "C"
  names(expdata)[names(expdata) == "INTENSITY"] <- "I"
  names(datain)[names(datain) == "MEAN"] <- "mean"
  names(datain)[names(datain) == "LOW"] <- "low"
  names(datain)[names(datain) == "UP"] <- "up"

  ##Remove NA and infinite numbers from spike in data:
  expdata <- expdata[!is.na(expdata[["I"]]) & !is.na(expdata[["C"]]), ]
  expdata <- expdata[!is.infinite(expdata[["I"]]) & !is.infinite(expdata[["C"]]), ]

  ##Extract actual data points for plotting:
  Cdata <- expdata[["C"]]
  Idata <- expdata[["I"]]

  tmp_blank <- expdata[expdata[["C"]] == 0, ]
  n_blank <- length(unique(tmp_blank[["I"]]))
  noise <- mean(tmp_blank[["I"]])
  var_noise <- var(tmp_blank[["I"]])

  fac <- qt(1 - alpha, n_blank - 1) * sqrt(1 + 1 / n_blank)

  ##upper bound of noise prediction interval
  up_noise <- noise + fac * sqrt(var_noise)
  rel_size <- 2.5
  rel_size_2 <- 1.8
  lw <- 1
  pw <- 2.5

  xaxis_orig_2 <- datain[["C"]]
  tmp_all <- datain
  LOQ_pred <- datain[["LOD"]][1]
  LOD_pred <- datain[["LOB"]][1]
  lower_Q_pred <- datain[["low"]]
  upper_Q_pred <- datain[["up"]]
  mean_bilinear <- datain[["mean"]]

  if (LOD_pred >= 0) {
    y_LOD_pred <- up_noise
  }
  if (LOQ_pred >= 0) {
    y_LOQ_pred <- up_noise
  }

  filename <- file.path(dir_output,
                        paste0(datain[["NAME"]][1], "_", datain[["METHOD"]][1], "_overall.pdf"))
  pdf(filename)
  if (LOQ_pred > xaxis_orig_2[3]) {
    C_max <- xaxis_orig_2[min(which(abs(LOQ_pred - xaxis_orig_2) ==
                                    min(abs(LOQ_pred - xaxis_orig_2))) + 1,
                              length(xaxis_orig_2))]
  } else {
    C_max <- xaxis_orig_2[which(abs(mean(xaxis_orig_2) - xaxis_orig_2) ==
                                min(abs(mean(xaxis_orig_2) - xaxis_orig_2)))]
  }

  low_p <- paste0(alpha * 100, "%")
  high_p <- paste0(100 - alpha * 100, "%")
  upp_noise <- paste(high_p, " upper bound of noise")
  low_pred <- paste(low_p, "percentile of predictions")

  p1 <- ggplot() +
    theme_complete_bw() +
    geom_point(data=data.frame(Cdata, Idata),
               aes(x=Cdata, y=Idata), size=pw * 1.5) +
    geom_line(data=data.frame(x=xaxis_orig_2, y=mean_bilinear, col="mean prediction", lt="mean"),
              aes(x=x, y=y, color=col),
              size=lw) + #, color = "black" #as.factor(c("mean bootstrap"))
    geom_ribbon(data=data.frame(x=xaxis_orig_2, ymin=lower_Q_pred, ymax=upper_Q_pred),
                aes(x=x, ymin=ymin, ymax=ymax),
                fill=red1,
                alpha=0.3) +
    geom_line(data=data.frame(x=xaxis_orig_2, ymin=lower_Q_pred, col=low_pred, lt="Int"),
              aes(x=x, y=ymin, color=col), size=lw) +
    geom_line(data=data.frame(x=xaxis_orig_2, ymax=rep(up_noise, length(xaxis_orig_2)),
                              col="95% upper bound of noise"),
              aes(x=x, y=ymax, color=col), size=lw) +
    scale_alpha_continuous(guide = "none") +
    xlab("Spiked Concentration") +
    ylab("Estimated Concentration") +
    theme(axis.text.x=element_text(size=rel(rel_size))) +
    theme(axis.text.y=element_text(size=rel(rel_size))) +
    theme(axis.title.x=element_text(size=rel(rel_size))) +
    theme(axis.title.y=element_text(size=rel(rel_size))) +
    theme(axis.title.y=element_text(vjust=0.7)) +
    scale_color_manual(values=c(orange1, blue1, red1),
                       labels=c(low_pred, upp_noise, "mean prediction"))

  ##p1 <- p1 + scale_colour_manual(values=c("mean prediction"= red1,"upper 95%
  ##prediction" = orange1, "5% percentile of predictions" = orange1, "95% upper
  ##bound of noise" = blue1)) + theme(legend.title = element_blank())
  ##colour_scales <- setNames(c("mean prediction", "upper 95% prediction", "5% percentile of
  ## predictions"), c("dasssta", "messssan", "rrrr"))

  ##p1 <- p1 + scale_colour_manual(values = colour_scales)
  p1 <- p1 + theme(legend.title=element_blank()) +
    theme(legend.position=c(0.05, 0.5),
          legend.justification=c(0, 0),
          legend.text=element_text(size=rel(rel_size_2)))

  LOD_y <- mean_bilinear[which(abs(xaxis_orig_2 - LOD_pred) ==
                               min(abs(xaxis_orig_2 - LOD_pred)))]
  p1 <- p1 + geom_point(data=data.frame(x=LOD_pred, y=y_LOD_pred, shape="LOD"),
                        aes(x=x, y=y, shape=shape, guide=FALSE),
                        colour="purple", size=5)

  LOQ_y <- lower_Q_pred[which(abs(up_noise - lower_Q_pred) ==
                              min(abs(up_noise - lower_Q_pred)))]
  p1 <- p1 + geom_point(data=data.frame(x=LOQ_pred, y=y_LOQ_pred, shape="LOQ"),
                        aes(x=x, y=y, shape=shape, guide=FALSE),
                        colour=orange1,
                        size=5)

  LOD_string <- paste0("LOB=", round(LOD_pred, digits=1))
  LOQ_string <- paste0("LOD=", round(LOQ_pred, digits=1))
  p1 <- p1 + guides(colour=guide_legend(order=1),
                    linetype=guide_legend(order = 1),
                    shape=guide_legend(order=2)) +
    guides(shape=FALSE) ## wait, wtf, you just set shape!?
  p1 <- p1 + ggtitle(paste0(datain$NAME, "\n", LOD_string, ", ", LOQ_string)) +
    theme(plot.title = element_text(size=20))
  print(p1)
  dev.off()

  ##produce a second plot showing a zoomed view:
  if (missing(xlim_plot)) {
    ##missing argument for the x limit in the function, pick a x limit that is close to the LOD/LOQ:
    if (LOQ_pred > 0) {
      xlim <- LOQ_pred * 3.0
    } else {
      xlim <- unique(Cdata)[4]
    }
  } else {
    xlim <- xlim_plot
  }

  filename <- file.path(dir_output,
                        paste0(datain[["NAME"]][1], "_", datain[["METHOD"]][1], "_zoom.pdf"))
  pdf(filename)

  Idata <- subset(Idata, Cdata < xlim)
  Cdata <- subset(Cdata, Cdata < xlim)
  lower_Q_pred <- subset(lower_Q_pred, xaxis_orig_2 < xlim)
  upper_Q_pred <- subset(upper_Q_pred, xaxis_orig_2 < xlim)
  mean_bilinear <- subset(mean_bilinear, xaxis_orig_2 < xlim)
  xaxis_orig_2 <- subset(xaxis_orig_2, xaxis_orig_2 < xlim)

  p2 <- ggplot() +
    theme_complete_bw() +
    geom_point(data=data.frame(Cdata, Idata),
               aes(x=Cdata, y=Idata), size=pw * 1.5) +
    geom_line(data=data.frame(x=xaxis_orig_2, y=mean_bilinear, col="mean prediction", lt="mean"),
              aes(x=x, y=y, color=col), size=lw) #, color = "black" #as.factor(c("mean bootstrap"))
  p2 <- p2 + geom_ribbon(data=data.frame(x=xaxis_orig_2, ymin=lower_Q_pred, ymax=upper_Q_pred),
                         aes(x=x, ymin=ymin, ymax=ymax), fill=red1, alpha=0.3) +
    geom_line(data=data.frame(x=xaxis_orig_2, ymin=lower_Q_pred,
                              col="lower 95% prediction", lt="Int"),
              aes(x=x, y=ymin, color=col), size=lw) +
    geom_line(data=data.frame(x=xaxis_orig_2, ymax=rep(up_noise, length(xaxis_orig_2)),
                              col="95% upper bound of noise"),
              aes(x=x, y=ymax, color=col), size=lw) +
    scale_alpha_continuous(guide = "none") +
    xlab("Spiked Concentration") +
    ylab("Estimated Concentration") +
    theme(axis.text.x=element_text(size=rel(rel_size))) +
    theme(axis.text.y=element_text(size=rel(rel_size))) +
    theme(axis.title.x=element_text(size=rel(rel_size))) +
    theme(axis.title.y=element_text(size=rel(rel_size))) +
    theme(axis.title.y=element_text(vjust=0.7)) +
    scale_color_manual(values=c(blue1, orange1, red1),
                       labels=c(upp_noise, low_pred, "mean prediction"))

  ##p1 <- p1 + scale_colour_manual(values=c("mean prediction"= red1, "upper 95% prediction" = orange1, "lower 95% prediction" = orange1, "95% upper bound of noise" = blue1)) + theme(legend.title = element_blank())
  ##p1 <- p1 + scale_linetype_manual(values=c("dashed", "dashed", "solid", "solid"))
  p2 <- p2 + theme(legend.title=element_blank()) +
    theme(legend.position=c(0.05, 0.5),
          legend.justification=c(0, 0),
          legend.text=element_text(size=rel(rel_size_2)))

  LOD_y <- mean_bilinear[which(abs(xaxis_orig_2 - LOD_pred) ==
                               min(abs(xaxis_orig_2 - LOD_pred)))]
  p2 <- p2 + geom_point(data=data.frame(x=LOD_pred, y=y_LOD_pred, shape="LOD"),
                        aes(x=x, y=y, shape=shape, guide=FALSE),
                        colour="purple",
                        size=5)

  LOQ_y <- lower_Q_pred[which(abs(up_noise - lower_Q_pred) == min(abs(up_noise - lower_Q_pred)))]
  p2 <- p2 + geom_point(data=data.frame(x=LOQ_pred, y=y_LOQ_pred, shape="LOQ"),
                        aes(x=x, y=y, shape=shape, guide=FALSE),
                        colour=orange1,
                        size=5)

  LOD_string <- paste0("LOB=", round(LOD_pred, digits=1))
  LOQ_string <- paste0("LOD=", round(LOQ_pred, digits=1))
  p2 <- p2 + guides(colour=guide_legend(order=1),
                    linetype=guide_legend(order=1),
                    shape=guide_legend(order=2)) +
    guides(shape=FALSE) + ## also,wtf?
    ggtitle(paste0(datain$NAME, "\n", LOD_string, ", ", LOQ_string)) +
    theme(plot.title=element_text(size=20))
  print(p1)
  dev.off()
  retlist <- list(
    "p1" = p1,
    "p2" = p2)
  return(retlist)
}
