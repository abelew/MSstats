% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/DataProcess.R
\name{dataProcess}
\alias{dataProcess}
\title{dataProcess() is a large function which does what it says on the tin.}
\usage{
dataProcess(raw, logTrans = 2, normalization = "equalizeMedians",
  nameStandards = NULL, betweenRunInterferenceScore = FALSE, address = "",
  fillIncompleteRows = TRUE, featureSubset = "all",
  remove_proteins_with_interference = FALSE, n_top_feature = 3,
  summaryMethod = "TMP", equalFeatureVar = TRUE, censoredInt = "NA",
  cutoffCensored = "minFeature", MBimpute = TRUE, original_scale = FALSE,
  remove50missing = FALSE, maxQuantileforCensored = 0.999, clusters = 1)
}
\arguments{
\item{raw}{A Raw msnset to analyze, in my hands, this is provided by
SWATH2stats.}

\item{logTrans}{Transform the data on a log2 scale?}

\item{normalization}{Normalization method to perform.  (Wow this feels like
rnaseq now)}

\item{nameStandards}{Global standards to help normalization.}

\item{address}{the only place this exists is in a paste0() call, I have no
clue.}

\item{fillIncompleteRows}{If experimental design is missing, fill it in.}

\item{featureSubset}{Subset the data by feature (topn or 3 likely, or all)}

\item{remove_proteins_with_interference}{Do we?}

\item{n_top_feature}{How many features to subset? This should be used by
featuresubset}

\item{summaryMethod}{Which summary method to use?}

\item{equalFeatureVar}{Calculate variance for equal features (I guess?)}

\item{censoredInt}{What value for censored rows?}

\item{cutoffCensored}{How to decide a censored row}

\item{MBimpute}{Impute Impute damned spot!}

\item{original_scale}{Return the results on the same scale as the input data (I assume)?}

\item{remove50missing}{wtf?}

\item{maxQuantileforCensored}{yeah, whatever}

\item{clusters}{The size of a SNOW cluster to speak up the calculations.}

\item{betweenRunInterferenceSCore}{That variable name is too long, I forgot
what it does while typing it out.}
}
\description{
Ideally, this function should perform a series of normalizations on a msnset
and figure out how much stuff is missing among other operations, then perform
comparisons across the experimental conditions.
}
