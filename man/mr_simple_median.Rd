% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mr.R
\name{mr_simple_median}
\alias{mr_simple_median}
\title{Simple median method}
\usage{
mr_simple_median(b_exp, b_out, se_exp, se_out,
  parameters = default_parameters())
}
\arguments{
\item{b_exp}{Vector of genetic effects on exposure}

\item{b_out}{Vector of genetic effects on outcome}

\item{se_exp}{Standard errors of genetic effects on exposure}

\item{se_out}{Standard errors of genetic effects on outcome}

\item{nboot}{Number of bootstraps to calculate se. Default 1000}
}
\value{
List with the following elements:
        b: MR estimate
        se: Standard error
        pval: p-value
}
\description{
Perform MR using summary statistics. Bootstraps used to calculate standard error.
}
