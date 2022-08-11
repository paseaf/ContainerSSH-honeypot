-- username frequency
SELECT username, COUNT(*) AS frequency
FROM audit_log
WHERE isAuthenticated = TRUE
GROUP BY username
ORDER BY frequency DESC;
