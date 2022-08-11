SELECT COUNT(*) AS totalFrequency, MIN(lastModified) AS rangeStart, MAX(lastModified) AS rangeEnd
FROM audit_log;