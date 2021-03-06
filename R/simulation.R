
#' @title Simulate databases based in models
#'
#' @description
#' \code{sim_model} simulate a database based on common models. The structure
#' used to create the data is similar as the \code{bamlss.formula}.
#'
#' @param formula List of the parameters, indicating how they should be computed.
#' similar to formula for \code{lm}, \code{glm}, \code{bamlss}, with the difference
#' that it included the coefficients and link function explicitly.
#'
#' @param generator Function to generate the response variables given the parameters
#'
#' @param n Number of observations to be simulated
#'
#' @param init_data Initial data including some variables to not been simulated.
#'
#' @param seed Seed to be defined with function \code{set.seed} to obtain reproducible
#' results
#'
#' @param extent Spatial extent for the simulation of coordinates when a spatial effect
#' is included.
#'
#' @return a \code{tibble} containing the simulated predictors, parameters and response
#' variable
#'
#' @author Erick Albacharro Chacon-Montalvan
#'
#' @examples
#'f <- list(
#'  mean ~ 5 + 0.5 * x1 + 0.1 * x2 + 0.7 * id1,
#'  sd ~ exp(x1)
#')
#'data <- sim_model(f, rnorm, 100)
#'
#' @importFrom purrr map map_chr reduce
#' @importFrom dplyr bind_cols
#' @importFrom tibble as_tibble
#'
#' @export

sim_model <- function (formula = list(mean ~ 1 + 2 * x1, sd ~ 1), generator = rnorm,
                       n = 1000, init_data = NULL, seed = NULL, extent = 1) {

  if (!is.null(seed))
    set.seed(seed)

  params <- purrr::map_chr(formula, ~ all.vars(.)[1])
  predictors <- purrr::map(formula, ~ all.vars(.)[-1]) %>%
    purrr::reduce(c) %>% unique()
  p <- length(predictors)

  # Identify predictors that need to be simulated
  init_pred <- names(init_data)
  pred2sim <- setdiff(predictors, init_pred)
  pred_sp <- grep("^s[0-9]+$", pred2sim, value = TRUE)
  pred2sim <- setdiff(pred2sim, pred_sp)
  p2 <- length(pred2sim)
  p_sp <- length(pred_sp)

  # Simulate only required predictors
  if (p2 > 0) {
    data <- matrix(rnorm(n * p2), nrow = n) %>%
      tibble::as_tibble() %>%
      setNames(pred2sim)
    init_data <- dplyr::bind_cols(init_data, data)
  }
  if (p_sp > 0) {
    data <- matrix(runif(n * p_sp) * extent, nrow = n) %>%
      tibble::as_tibble() %>%
      setNames(pred_sp)
    init_data <- dplyr::bind_cols(init_data, data)
  }

  init_data[params] <- purrr::map(formula, ~ .[[3]]) %>%
    purrr::map(~ eval(., init_data))

  init_data$y <- do.call(generator, c(n = n, init_data[params]))

  return(init_data)
}

exp_cor <- function (dis, phi) {
  exp(-dis/phi)
}
exp_cov <- function (dis, phi, sigma2) {
  sigma2 * exp(-dis/phi)
}

#' @title Simulate a Gaussian process
#'
#' @description
#' \code{gp} Simulate a spatial Gaussian process given a certain covariance function.
#'
#' @details
#' details.
#'
#' @param s1 First coordinate
#'
#' @param s2 Second coordinate
#'
#' @param cov.model A character or function indicating the covariance function that
#' Should be used to compute the variance-covariance matrix
#'
#' @param cov.params A list of the parameters required by the \code{cov.model} function.
#'
#' @return A vector of the realization of the Gaussian Process
#'
#' @author Erick A. Chacon-Montalvan
#'
#' @examples
#' # Generate coordinates
#' N <- 1000
#' s1 <- 2 * runif(N)
#' s2 <- 2 * runif(N)
#' # Simulate and plot the realization of a Gaussian process
#' y <- gp(s1, s2, "exp_cov", list(phi = 0.05, sigma2 = 1))
#' plot(s1, s2, cex = y)
#' # Plot with ggplot
#' # ggplot(data.frame(s1, s2, y), aes(s1, s2, col = y)) +
#' #  geom_point(size = 3)
#'
#' @importFrom stats dist rnorm
#'
#' @export
gp <- function (s1, s2, cov.model = NULL, cov.params = NULL) {
  coords <- cbind(s1, s2)
  n <- nrow(coords)
  distance <- as.matrix(dist(coords))
  varcov <- do.call(cov.model, c(list(dis = distance), cov.params))
  right <- chol(varcov)
  output <- as.numeric(crossprod(right, rnorm(n)))
}

#' @title Simulate a Multivariate Gaussian process
#'
#' @description
#' \code{mgp} Simulate a Multivariate spatial Gaussian process known as linear model
#' of coregionalization Y(h) = AS(h), where S(h) is a vector of q independent Gaussian
#' processes.
#'
#' @details
#' details.
#'
#' @param s1 First coordinate
#'
#' @param s2 Second coordinate
#'
#' @param cov.model A character or function indicating the covariance function that
#' Should be used to compute the variance-covariance matrix
#'
#' @param variance A qxq matrix of non-spatial covariance.
#' @param nugget A qxq diagonal matrix of non-spatial noise.
#' @param phi A q-length vector of decay parameters.
#' @param kappa A q-length vector of kappa parameters if Matern spatial correlation
#' function is used.
#'
#' @return A vector of the realization of the Gaussian Process
#'
#' @author Erick A. Chacon-Montalvan
#'
#' @examples
#'
#' # Generate coordinates
#' N <- 100
#' s1 <- 2 * runif(N)
#' s2 <- 2 * runif(N)
#'
#' # Covariance parameters
#' q <- 2
#' var <- sqrt(diag(c(4, 4)))
#' A <- matrix(c(1, - 0.8, 0, 0.6), nrow = 2)
#' variance <- var %*% tcrossprod(A) %*% var
#' nugget <- diag(0, q)
#' phi <- rep(1 / 0.08, q)
#'
#' # Generate the multivariate Gaussian process
#' y <- mgp(s1, s2, "exponential", variance, nugget, phi)
#' y1 <- y[1:N]
#' y2 <- y[(N + 1):(2 * N)]
#'
#' # Check correlation
#' cor(y1, y2)
#' plot(y1, y2)
#'
#' # Visualize the spatial
#' plot(s1, s2, cex = y1, col = 2)
#' points(s1, s2, cex = y2, col = 3)
#'
#' @importFrom spBayes mkSpCov
#'
#' @export

mgp <- function (s1, s2, cov.model = NULL, variance = NULL, nugget = NULL, phi = NULL, kappa = NULL) {

  coords <- cbind(s1, s2)
  n <- nrow(coords)
  q <- nrow(variance)

  if (is.null(kappa)) {
    theta <- phi
  } else {
    theta <- c(phi, kappa)
  }

  varcov <- spBayes::mkSpCov(coords, variance, nugget, theta, cov.model)
  right <- chol(varcov)
  output <- as.numeric(crossprod(right, rnorm(n * q)))
  as.numeric(matrix(output, nrow = n, byrow = TRUE))

}


#' @title Multivariate Fixed Effect
#'
#' @description
#' \code{mfe} compute the multivariate fixed effect. Generally used with
#' \code{msim_model}.
#'
#' @details
#' details.
#'
#' @param x A vector of length n for which the fixed effect will be evaluated.
#' @param beta A vector of length q, this is the fixed effect for each response
#' variable.
#'
#' @return A matrix of dimension n x q.
#'
#' @author Erick A. Chacon-Montalvan
#'
#' @examples
#'
#' mfe(x = rnorm(10), beta = c(0.1, 0, 1))
#'
#' @export
mfe <- function (x, beta) {
  as.numeric(matrix(x) %*% matrix(beta, nrow = 1))
}



#' @title Simulate Databases Based in Multivariate Models
#'
#' @description
#' \code{msim_model} simulate a database based on common multivariate models. The
#' structure used to create the data is similar as the \code{bamlss.formula}.
#'
#' @param formula List of the parameters, indicating how they should be computed.
#' similar to formula for \code{lm}, \code{glm}, \code{bamlss}, with the difference
#' that it included the coefficients and link function explicitly.
#'
#' @param generator Function to generate the response variables given the parameters
#'
#' @param n Number of observations to be simulated
#'
#' @param init_data Initial data including some variables to not been simulated.
#'
#' @param seed Seed to be defined with function \code{set.seed} to obtain reproducible
#' results
#'
#' @param extent Spatial extent for the simulation of coordinates when a spatial effect
#' is included.
#'
#' @return a \code{tibble} containing the simulated predictors, parameters and response
#' variable
#'
#' @author Erick Albacharro Chacon-Montalvan
#'
#' @examples
#'
#' # Covariance parameters
#' n <- 100
#' q <- 2
#' var <- sqrt(diag(c(4, 4)))
#' A <- matrix(c(1, - 0.8, 0, 0.6), nrow = 2)
#' variance <- var %*% tcrossprod(A) %*% var
#' nugget <- diag(0, q)
#' phi <- rep(1 / 0.08, q)
#'
#' # Structure of the model
#' formula <- list(
#'   mean ~ psych::logistic(
#'     mgp(s1, s2, "exponential", get("variance"), get("nugget"), get("phi"))),
#'   sd ~ 1
#' )
#'
#' # Simulate data based on formula
#' library(tidyr)
#' library(dplyr)
#' data <- msim_model(formula, generator = rnorm, n = n, extent = 2, seed = 1)
#' data_long <- gather(data, yname, yval, matches("^y[0-9]+"))
#'
#' # Plot the observed realization
#' library(ggplot2)
#' spgg <- ggplot(data_long, aes(s1, s2, size = yval, col = yval)) +
#'   geom_point() +
#'   scale_colour_gradientn(colours = terrain.colors(10)) +
#'   facet_wrap(~ yname)
#' print(spgg)
#'
#'
#' @importFrom purrr map map_chr reduce
#' @importFrom dplyr bind_cols mutate select left_join
#' @importFrom tibble as_tibble
#' @importFrom tidyr gather spread
#'
#' @export
#'

msim_model <- function (formula, generator = rnorm, n = 100, init_data = NULL,
                        seed = NULL, extent = 1) {

  if (!is.null(seed))
    set.seed(seed)

  params <- purrr::map_chr(formula, ~ all.vars(.)[1])
  predictors <- purrr::map(formula, ~ all.vars(.)[-1]) %>%
    purrr::reduce(c) %>% unique()
  p <- length(predictors)

  # Identify predictors that need to be simulated
  init_pred <- names(init_data)
  pred2sim <- setdiff(predictors, init_pred)
  pred_sp <- grep("^s[0-9]+$", pred2sim, value = TRUE)
  pred2sim <- setdiff(pred2sim, pred_sp)
  p2 <- length(pred2sim)
  p_sp <- length(pred_sp)

  # Simulate only required predictors
  if (p2 > 0) {
    data <- matrix(rnorm(n * p2), nrow = n) %>%
      tibble::as_tibble() %>%
      setNames(pred2sim)
    init_data <- dplyr::bind_cols(init_data, data)
  }
  if (p_sp > 0) {
    data <- matrix(runif(n * p_sp) * extent, nrow = n) %>%
      tibble::as_tibble() %>%
      setNames(pred_sp)
    init_data <- dplyr::bind_cols(init_data, data)
  }

  init_data$id <- 1:nrow(init_data)

  # Evaluate parameters in a tibble
  params_ls <- list()
  params_ls[params] <- purrr::map(formula, ~ .[[3]]) %>%
    purrr::map(~ eval(., init_data))
  params_ls <- tibble::as_tibble(params_ls)

  # Obtain dimensions
  nq <- max(purrr::map_int(params_ls, length))
  q <- round(nq / n)

  # Simulate multivariate process and reshape
  params_ls$y <- do.call(generator, c(n = nq, params_ls[params]))
  params_ls$number <- rep(1:q, each = n)
  params_ls$id <- rep(1:n, q)
  # varname <- value <- number <- id <- NULL
  params_ls <- params_ls %>%
    tidyr::gather("varname", "value", - number, - id) %>%
    dplyr::mutate(varname = paste0(varname, number)) %>%
    dplyr::select(- number) %>%
    tidyr::spread(varname, value)

  # Organize and joint final simulated dataset
  init_data <- dplyr::left_join(init_data, params_ls, by = "id")

  return(init_data)
}

