SELECT username, COUNT(*) AS frequency
FROM audit_log
WHERE isAuthenticated = 1
GROUP BY username
ORDER BY frequency DESC;