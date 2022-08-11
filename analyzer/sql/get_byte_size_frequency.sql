SELECT byteSize, COUNT(*) AS frequency
FROM audit_log
GROUP BY byteSize
ORDER BY frequency DESC;
