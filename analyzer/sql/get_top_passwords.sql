SELECT 
	password,
	COUNT(*) AS frequency
FROM audit_log
WHERE isAuthenticated is TRUE
GROUP BY password
ORDER BY frequency DESC;
