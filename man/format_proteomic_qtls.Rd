% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read_data.R
\name{format_proteomic_qtls}
\alias{format_proteomic_qtls}
\title{Get data from proteomic QTL results}
\usage{
format_proteomic_qtls(proteomic_qtls_subset, type = "exposure")
}
\arguments{
\item{proteomic_qtls_subset}{Selected rows from \code{proteomic_qtls} data loaded from \code{MRInstruments} package.}

\item{type}{Are these data used as \code{"exposure"} or \code{"outcome"}? Default is \code{"exposure"}.}
}
\value{
Data frame
}
\description{
See \code{\link[=format_data]{format_data()}}.
}
