Isq <- function(y,s)
{
	k <- length(y)
	w <- 1/s^2
	sum.w <- sum(w)
	mu.hat <- sum(y*w)/sum.w
	Q <- sum(w*(y-mu.hat)^2)
	Isq <- (Q - (k-1))/Q
	Isq <- max(0,Isq)
	return(Isq)
}

# mr_ivw_fe <- function (b_exp, b_out, se_exp, se_out)
# {
# 	lapply(x, function(x){
# 		wj <- x$wj
# 		bj <- x$bj
# 		b <- sum(wj * bj) / sum(wj)
# 		se <- sqrt(1 / sum(wj))
# 		pval <- 2 * pnorm(abs(b/se), low = FALSE)
# 		Q <- sum(wj * (bj - b)^2)
# 		Q_df <- length(b_exp) - 1
# 		Q_pval <- pchisq(Q, Q_df, low = FALSE)
# 		data.frame(
# 			b1=b, se1=se, pval1=pval,
# 		)
# 		return(list(b = b, se = se, pval = pval, nsnp = length(b_exp), Q = Q, Q_df = Q_df, Q_pval = Q_pval))
# 	})
# }


PM <- function(y = y, s = s, Alpha = 0.1)
{
	k = length(y)
	df = k - 1
	sig = qnorm(1-Alpha/2)
	low = qchisq((Alpha/2), df)
	up = qchisq(1-(Alpha/2), df)
	med = qchisq(0.5, df)
	mn = df
	mode = df-1
	Quant = c(low, mode, mn, med, up)
	L = length(Quant)
	Tausq = NULL
	Isq = NULL
	CI = matrix(nrow = L, ncol = 2)
	MU = NULL
	v = 1/s^2
	sum.v = sum(v)
	typS = sum(v*(k-1))/(sum.v^2 - sum(v^2))
	for(j in 1:L)
	{
		tausq = 0 ; F = 1 ;TAUsq = NULL
		while(F>0)
		{
			TAUsq = c(TAUsq, tausq)
			w = 1/(s^2+tausq)
			sum.w = sum(w)
			w2 = w^2
			yW = sum(y*w)/sum.w
			Q1 = sum(w*(y-yW)^2)
			Q2 = sum(w2*(y-yW)^2)
			F = Q1-Quant[j]
			Ftau = max(F,0)
			delta = F/Q2
			tausq = tausq + delta
		}
		MU[j] = yW
		V = 1/sum(w)
		Tausq[j] = max(tausq,0)
		Isq[j] = Tausq[j]/(Tausq[j]+typS)
		CI[j,] = yW + sig*c(-1,1) *sqrt(V)
	}
	return(list(tausq = Tausq, muhat = MU, Isq = Isq, CI = CI, quant = Quant))
}


#' MR Rucker framework
#'
#' <full description>
#'
#' @param dat <what param does>
#' @param parameters List of Qthresh for determing transition between models, and alpha values for calculating confidence intervals. Defaults to 0.05 for both in default_parameters() 
#'
#' @export
#' @return list
mr_rucker <- function(dat, parameters=default_parameters())
{
	Qthresh <- parameters$Qthresh
	alpha <- parameters$alpha

	nsnp <- nrow(dat)
	b_exp <- dat$beta.exposure
	b_out <- dat$beta.outcome
	se_exp <- dat$se.exposure
	se_out <- dat$se.outcome
	w <- b_exp^2 / se_out^2
	y <- b_out / se_out
	x <- b_exp / se_out
	i <- 1 / se_out


	# IVW FE
	mod_ivw <- summary(lm(y ~ 0 + x))
	b_ivw_fe <- coefficients(mod_ivw)[1,1]

	Q_ivw <- sum((y - x*b_ivw_fe)^2)
	Q_df_ivw <- length(b_exp) - 1
	Q_pval_ivw <- pchisq(Q_ivw, Q_df_ivw, low = FALSE)
	phi_ivw <- Q_ivw / (nsnp - 1)

	se_ivw_fe <- coefficients(mod_ivw)[1,2] / phi_ivw
	pval_ivw_fe <- pt(abs(b_ivw_fe/se_ivw_fe), nsnp-1, lower.tail=FALSE) * 2


	# IVW MRE
	b_ivw_re <- b_ivw_fe
	# se_ivw_re <- sqrt(phi_ivw / sum(w))
	se_ivw_re <- coefficients(mod_ivw)[1,2]
	# pval_ivw_re <- pt(abs(b_ivw_re/se_ivw_re), nsnp-1, lower.tail=FALSE) * 2
	pval_ivw_re <- coefficients(mod_ivw)[1,4]


	# Egger FE
	mod_egger <- summary(lm(y ~ 0 + i + x))

	b1_egger_fe <- coefficients(mod_egger)[2,1]
	b0_egger_fe <- coefficients(mod_egger)[1,1]

	# This is equivalent to mod$sigma^2
	# Q_egger <- sum(
	# 	1 / se_out^2 * (b_out - (b0_egger_fe + b1_egger_fe * b_exp))^2
	# )
	Q_egger <- mod_egger$sigma^2 * (nsnp - 2)
	Q_df_egger <- nsnp - 2
	Q_pval_egger <- pchisq(Q_egger, Q_df_egger, low=FALSE)
	phi_egger <- Q_egger / (nsnp - 2)

	se1_egger_fe <- coefficients(mod_egger)[2,2] / phi_egger
	pval1_egger_fe <- pt(abs(b1_egger_fe/se1_egger_fe), nsnp-2, lower.tail=FALSE) * 2
	se0_egger_fe <- coefficients(mod_egger)[1,2] / phi_egger
	pval0_egger_fe <- pt(abs(b0_egger_fe/se0_egger_fe), nsnp-2, lower.tail=FALSE) * 2

	# Egger RE
	b1_egger_re <- coefficients(mod_egger)[2,1]
	se1_egger_re <- coefficients(mod_egger)[2,2]
	pval1_egger_re <- coefficients(mod_egger)[2,4]
	b0_egger_re <- coefficients(mod_egger)[1,1]
	se0_egger_re <- coefficients(mod_egger)[1,2]
	pval0_egger_re <- coefficients(mod_egger)[1,4]


	results <- data.frame(
		Method = c("IVW fixed effects", "IVW random effects", "Egger fixed effects", "Egger random effects"),
		Estimate = c(b_ivw_fe, b_ivw_re, b1_egger_fe, b1_egger_re),
		SE = c(se_ivw_fe, se_ivw_re, se1_egger_fe, se1_egger_re)
	)
	results$CI_low <- results$Estimate - qnorm(1-alpha/2) * results$SE
	results$CI_upp <- results$Estimate + qnorm(1-alpha/2) * results$SE
	results$P <- c(pval_ivw_fe, pval_ivw_re, pval1_egger_fe, pval1_egger_re)

	Qdiff <- max(0, Q_ivw - Q_egger)
	Qdiff_p <- pchisq(Qdiff, 1, lower.tail=FALSE)


	Q <- data.frame(
		Method=c("Q_ivw", "Q_egger", "Q_diff"),
		Q=c(Q_ivw, Q_egger, Qdiff),
		df=c(Q_df_ivw, Q_df_egger, 1),
		P=c(Q_pval_ivw, Q_pval_egger, Qdiff_p)
	)

	intercept <- data.frame(
		Method=c("Egger fixed effects", "Egger random effects"),
		Estimate = c(b0_egger_fe, b0_egger_fe),
		SE = c(se0_egger_fe, se0_egger_re)
	)
	intercept$CI_low <- intercept$Estimate - qnorm(1-alpha/2) * intercept$SE
	intercept$CI_upp <- intercept$Estimate + qnorm(1-alpha/2) * intercept$SE
	intercept$P <- c(pval0_egger_fe, pval0_egger_re)

	if(Q_pval_ivw <= Qthresh)
	{
		if(Qdiff_p <= Qthresh)
		{
			if(Q_pval_egger <= Qthresh)
			{
				res <- "D"
			} else {
				res <- "C"
			}
		} else {
			res <- "B"
		}
	} else {
		res <- "A"
	}

	selected <- results[c("A", "B", "C", "D") %in% res, ]
	selected$Method <- "Rucker"

	return(list(rucker=results, intercept=intercept, Q=Q, res=res, selected=selected))
}



#' Run rucker with bootstrap estimates
#'
#' <full description>
#'
#' @param dat <what param does>
#' @param parameters=default_parameters() <what param does>
#'
#' @export
#' @return List
rucker_bootstrap <- function(dat, parameters=default_parameters())
{
	library(ggplot2)

	nboot <- parameters$nboot
	nboot <- 1000
	nsnp <- nrow(dat)
	Qthresh <- parameters$Qthresh

	# Main result
	rucker <- mr_rucker(dat, parameters)
	dat2 <- dat
	l <- list()
	for(i in 1:nboot)
	{
		dat2$beta.exposure <- rnorm(nsnp, mean=dat$beta.exposure, sd=dat$se.exposure)
		dat2$beta.outcome <- rnorm(nsnp, mean=dat$beta.outcome, sd=dat$se.outcome)
		l[[i]] <- mr_rucker(dat2, parameters)
	}

	modsel <- plyr::rbind.fill(lapply(l, function(x) x$selected))
	modsel$model <- sapply(l, function(x) x$res)

	bootstrap <- data.frame(
		Q = c(rucker$Q$Q[1], sapply(l, function(x) x$Q$Q[1])),
		Qdash = c(rucker$Q$Q[2], sapply(l, function(x) x$Q$Q[2])),
		model = c(rucker$res, sapply(l, function(x) x$res)),
		i = c("Full", rep("Bootstrap", nboot))
	)

	# Get the median estimate
	rucker_point <- rucker$selected
	rucker_point$Method <- "Rucker point estimate"

	rucker_median <- data.frame(
		Method = "Rucker median",
		Estimate = median(modsel$Estimate),
		SE = mad(modsel$Estimate),
		CI_low = quantile(modsel$Estimate, 0.025),
		CI_upp = quantile(modsel$Estimate, 0.975)
	)
	rucker_median$P <- 2 * pt(abs(rucker_median$Estimate/rucker_median$SE), nsnp-1, lower.tail=FALSE)

	rucker_mean <- data.frame(
		Method = "Rucker mean",
		Estimate = mean(modsel$Estimate),
		SE = sd(modsel$Estimate)
	)
	rucker_mean$CI_low <- rucker_mean$Estimate - qnorm(Qthresh/2, lower.tail=TRUE) * rucker_mean$SE
	rucker_mean$CI_upp <- rucker_mean$Estimate + qnorm(Qthresh/2, lower.tail=TRUE) * rucker_mean$SE
	rucker_mean$P <- 2 * pt(abs(rucker_mean$Estimate/rucker_mean$SE), nsnp-1, lower.tail=FALSE)


	res <- rbind(rucker$rucker, rucker_point, rucker_mean, rucker_median)
	rownames(res) <- NULL

	p1 <- ggplot2::ggplot(bootstrap, ggplot2::aes_string(x="Q", y="Qdash")) +
		ggplot2::geom_point(ggplot2::aes_string(colour="model")) +
		ggplot2::geom_point(data=subset(bootstrap, i=="Full")) +
		ggplot2::scale_colour_brewer(type="qual") +
		ggplot2::xlim(0, max(bootstrap$Q, bootstrap$Qdash)) +
		ggplot2::ylim(0, max(bootstrap$Q, bootstrap$Qdash)) +
		ggplot2::geom_abline(slope=1, colour="grey") +
		ggplot2::geom_abline(slope=1, intercept=-qchisq(Qthresh, 1, low=FALSE), linetype="dotted") +
		ggplot2::geom_hline(yintercept = qchisq(Qthresh, nsnp - 2, lower.tail=FALSE), linetype="dotted") +
		ggplot2::geom_vline(xintercept = qchisq(Qthresh, nsnp - 1, lower.tail=FALSE), linetype="dotted") +
		ggplot2::labs(x="Q", y="Q'")

	modsel$model_name <- "IVW"
	modsel$model_name[modsel$model %in% c("C", "D")] <- "Egger"

	p2 <- ggplot2::ggplot(modsel, ggplot2::aes_string(x="Estimate")) +
		ggplot2::geom_density(ggplot2::aes_string(fill="model_name"), alpha=0.4) +
		ggplot2::geom_vline(data=res, ggplot2::aes_string(xintercept="Estimate", colour="Method")) +
		ggplot2::scale_colour_brewer(type="qual") +
		ggplot2::scale_fill_brewer(type="qual") + 
		ggplot2::labs(fill="Bootstrap estimates", colour="")

	return(list(rucker=rucker, res=res, bootstrap_estimates=modsel, boostrap_q=bootstrap, q_plot=p1, e_plot=p2))
}