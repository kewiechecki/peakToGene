% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getFeatures.R
\name{getOverlaps}
\alias{getOverlaps}
\title{Finds all overlaps between one of the genomic features returned by\code{getFeatures()} and a set of peaks, then returns a table of gene-to-peak associations.}
\usage{
getOverlaps(feat, peaks)
}
\arguments{
\item{feat}{One of the \code{GRangesList}s returned by \code{getFeatures()}}

\item{peaks}{A \code{GRanges} object from the same genome as \code{feat}. It should have a \code{names()} attribute from \code{\link{namePeaks}}.}
}
\value{
A \code{data.frame} of gene-to-peak mappings.
}
\description{
Finds all overlaps between one of the genomic features returned by\code{getFeatures()} and a set of peaks, then returns a table of gene-to-peak associations.
}
