% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/straightness.R
\name{TrajPlotDirectionAutocorrelations}
\alias{TrajPlotDirectionAutocorrelations}
\title{Plot direction autocorrelation function}
\usage{
TrajPlotDirectionAutocorrelations(trj, deltaSMax = round(nrow(trj)/4),
  firstMinWindowSize = 10, type = "l", ylab = expression("C(" * Delta * s
  * ")"), xlab = expression(Delta * s), ...)
}
\arguments{
\item{trj}{Trajectory to be plotted.}

\item{deltaSMax}{Maximum delta s to be calculated, see
\code{\link{TrajDirectionAutocorrelations}} for details.}

\item{firstMinWindowSize}{If not NULL, specifies a window size used to
calculate the first local minimum, which is then plotted as a point.}

\item{type, xlab, ylab}{Defaults for plotting.}

\item{...}{Additional arguments passed to \code{\link{plot}}.}
}
\description{
Calculate the direction autocorrelation for a trajectory, then plot the
result, with a dot at the first local minimum. \code{trj} must have a
constant step length (see \code{\link{TrajDirectionAutocorrelations}} for
further details).
}
