function cadf(y ,x ,p ,nlag)
# ##################################################################
# Original comments and function signature from spatial-econometrics
# ##################################################################
# function results = cadf(y ,x ,p ,nlag)
# PURPOSE: compute augmented Dickey-Fuller statistic for residuals
#          from a cointegrating regression, allowing for deterministic
#          polynomial trends
# ------------------------------------------------------------
# USAGE:	results = cadf(y,x,p,nlag)
#
# where:	y = dependent variable time-series vector
#			x = explanatory variables matrix
#			p = order of time polynomial in the null-hypothesis
#				p = -1, no deterministic part
#				p =  0, for constant term
#				p =  1, for constant plus time-trend
#				p >  1, for higher order polynomial
#			nlag = # of lagged changes of the residuals to include in regression
#
# ------------------------------------------------------------
# RETURNS:	results structure
#			results.meth  = 'cadf'
#			results.alpha = autoregressive parameter estimate
#			results.adf   = ADF t-statistic
#			results.crit  = (6 x 1) vector of critical values
#			                [1% 5% 10% 90% 95% 99%] quintiles   
#			results.nvar  = cols(x)
#			results.nlag  = nlag
#---------------------------------------------------
# SEE ALSO: prt_coint()
#--------------------------------------------------- 
# References: Said and Dickey (1984) 'Testing for Unit Roots in
# Autoregressive Moving Average Models of Unknown Order', 
# Biometrika, Volume 71, pp. 599-607.

# written by:
# James P. LeSage, Dept of Economics
# University of Toledo
# 2801 W. Bancroft St,
# Toledo, OH 43606
# jlesage@spatial-econometrics.com

# Modeled after a similar Gauss routine by
# Sam Ouliaris, in a package called COINT

# ####################################################
# Porting to Julia information
# ####################################################

# Author:	Adrian Torrie
# Email:	adriantorrie at google's online mail dot com
# Linkedin:	www.linkedin.com/in/adriantorrie/

# ####################################################

# Validate incoming data
if (p < -1)
	error("p cannot be < -1 in cadf")
end

nobs = rows(x)
if (nobs - (2 * nlag) + 1 < 1)
	error("nlags is too large in cadf negative degrees of freedom")
end

# Assign locals
y   = detrend(y ,p)
x	= detrend(x ,p)
b   = inv(x' * x) * x' * y
r   = y - x * b
dep = tdiff(r ,1)
dep = trimr(dep ,1 ,0)
k   = 0     
z   = trimr(lag(r ,1) ,1 ,0) 
k   = k + 1 

while (k <= nlag)
	z = [z lag(dep,k)]
	k = k + 1 
end  

 z    = trimr(z ,nlag ,0) 
 dep  = trimr(dep ,nlag ,0) 
 beta = detrend(z ,0) \ detrend(dep ,0) 

 # BUG fix suggested by 
 # Nick Firoozye
 # Sanford C. Bernstein, Inc
 # 767 Fifth Avenue, #21-49
 # New York, NY 10153
 # res     = dep - z*beta 
 res  = detrend(dep ,0) - detrend(z ,0) * beta 

 so   = (res' * res) / (rows(dep) - cols(z))
 var_cov = so * inv(z' * z) 
 
 return
	beta(1 ,1)							# results.alpha
	,beta(1 ,1) / sqrt(var_cov(1 ,1))	# results.adf
	,rztcrit(nobs ,cols(x) ,p)			# results.crit
	,nlag 								# results.nlag
	,cols(x)							# results.nvar
	,"cadf"								# results.meth