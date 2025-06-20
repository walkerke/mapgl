% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/style_helpers.R
\name{format_numbers}
\alias{format_numbers}
\title{Format numbers for legend labels}
\usage{
format_numbers(x, format, currency_symbol, digits, big_mark, suffix, prefix)
}
\arguments{
\item{x}{Numeric vector to format.}

\item{format}{Format type.}

\item{currency_symbol}{Currency symbol for currency formatting.}

\item{digits}{Number of decimal places.}

\item{big_mark}{Thousands separator.}

\item{suffix}{Suffix to append.}

\item{prefix}{Prefix to prepend.}
}
\value{
Character vector of formatted numbers.
}
\description{
Internal helper function to format numeric values for display in legends.
}
\keyword{internal}
