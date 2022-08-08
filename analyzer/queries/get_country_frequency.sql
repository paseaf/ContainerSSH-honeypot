SELECT country, COUNT(*) AS frequency
FROM audit_log
GROUP BY country
ORDER BY frequency DESC;