% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/GroupComparison.R
\name{checkGroupComparisonAgreement}
\alias{checkGroupComparisonAgreement}
\title{Check if measurements are missing for entire group.}
\usage{
checkGroupComparisonAgreement(sub1, contrast.matrix)
}
\arguments{
\item{sub1}{I dunno}

\item{contrast.matrix}{The matrix to test.}
}
\value{
a list of the test.

ok, so why not use qr()?
}
\description{
If there is stuff missing from the experimental design, then it might be
problematic.
}
