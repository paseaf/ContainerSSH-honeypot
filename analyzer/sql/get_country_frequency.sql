SELECT 
	country AS "country/region", 
	COUNT(*) AS frequency
FROM audit_log
WHERE isAuthenticated is TRUE
GROUP BY country
ORDER BY frequency DESC;
