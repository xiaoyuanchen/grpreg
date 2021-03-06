predict.grpsurv <- function(object, X,
                            type=c("link", "response", "survival", "median", "norm", 
                                   "coefficients", "vars", "nvars", "groups", "ngroups"),
                            lambda, which=1:length(object$lambda), ...) {
  type <- match.arg(type)
  if (type %in% c("norm", "coefficients", "vars", "nvars", "groups", "ngroups")) {
    return(predict.grpreg(object=object, X=X, type=type, lambda=lambda, which=which, ...))
  }
  if (!missing(lambda)) {
    ind <- approx(object$lambda,seq(object$lambda),lambda)$y
    l <- floor(ind)
    r <- ceiling(ind)
    x <- ind %% 1
    beta <- (1-x)*object$beta[,l,drop=FALSE] + x*object$beta[,r,drop=FALSE]
    colnames(beta) <- round(lambda,4)
  } else {
    beta <- object$beta[,which,drop=FALSE]
  }
  
  eta <- X %*% beta
  if (type=='link') return(drop(eta))
  if (type=='response') return(drop(exp(eta)))
  
  if (!missing(lambda)) {
    W <- (1-x)*object$W[,l,drop=FALSE] + x*object$W[,r,drop=FALSE]
  } else {
    W <- object$W[,which,drop=FALSE]
  }
  if (type == 'survival' & ncol(W) > 1) stop('Can only return type="survival" for a single lambda value')
  if (type == 'survival') val <- vector('list', length(eta))
  if (type == 'median') val <- matrix(NA, nrow(eta), ncol(eta))
  for (j in 1:ncol(eta)) {
    # Estimate baseline hazard
    w <- W[,j]
    r <- rev(cumsum(rev(w)))
    a <- ifelse(object$fail, (1-w/r)^(1/w), 1)
    S0 <- c(1, cumprod(a))
    x <- c(0, object$time)
    for (i in 1:nrow(eta)) {
      S <- S0^exp(eta[i,j])
      if (type == 'survival') val[[i]] <- approxfun(x, S, method='constant')
      if (type == 'median') {
        if (any(S < 0.5)) {
          val[i,j] <- x[min(which(S < .5))]
        }
      }
    }
  }
  if (type == 'survival') {
    if (nrow(eta)==1) val <- val[[1]]
    class(val) <- c('grpsurv.func', class(val))
    attr(val, 'time') <- object$time
  }
  if (type == 'median') val <- drop(val)
  val
}
