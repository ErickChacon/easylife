// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <Rcpp.h>

using namespace Rcpp;

// runmean
NumericVector runmean(NumericVector a, int width);
RcppExport SEXP day2day_runmean(SEXP aSEXP, SEXP widthSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< NumericVector >::type a(aSEXP);
    Rcpp::traits::input_parameter< int >::type width(widthSEXP);
    rcpp_result_gen = Rcpp::wrap(runmean(a, width));
    return rcpp_result_gen;
END_RCPP
}