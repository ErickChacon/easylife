% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/labs-plot.R
\name{units_tx}
\alias{units_tx}
\title{Create labels with units.}
\usage{
units_tx(vec, unit = "weeks", singular = NULL)
}
\arguments{
\item{vec}{Vector of values.}

\item{unit}{Name of unit in plural}

\item{singular}{Name of the unit in singular.}
}
\value{
return.
}
\description{
\code{units_tx} creates labels for considering singular or plural values.
}
\details{
details.
}
\examples{

x <- sample(1:3, size = 10, replace = TRUE)
units_tx(x)
units_tx(x, unit = "grams", singular = "grams")

}
\author{
Erick A. Chacon-Montalvan
}
