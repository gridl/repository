% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sample.R
\name{simulations}
\alias{simulations}
\alias{generate_simple}
\alias{simulate_london_meters}
\title{Simulations.}
\usage{
generate_simple(repo)

simulate_london_meters(repo, .silent = TRUE)
}
\arguments{
\item{repo}{Repository to write to.}

\item{.silent}{Do not print output.}
}
\description{
\code{simulate_london_meters} loads and examines a subset
of \strong{London meters} data; see the \href{https://www.kaggle.com/jeanmidev/smart-meters-in-london}{Kaggle website}
for this data set and the introductory vignette.
}
\details{
These functions populate sessions' history cache with a complete
history of data exploration.
}
