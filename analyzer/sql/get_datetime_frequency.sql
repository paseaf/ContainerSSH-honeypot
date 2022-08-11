-- frequency / date
SELECT date(lastModified) AS "date", COUNT(*) AS frequency
FROM audit_log
GROUP BY date
ORDER BY date ASC;

-- frequency / weekday
SELECT
	strftime('%w', lastModified) AS "weekDay(0=SUN)",
	COUNT(*) AS frequency
FROM audit_log
GROUP BY "weekDay(0=SUN)"
ORDER BY frequency DESC;

-- frequency / date from CN
SELECT date(lastModified) AS "date", COUNT(*) AS frequency, country
FROM audit_log
WHERE country != "CN" AND "date"="2022-08-06"
--GROUP BY date
GROUP BY country
ORDER BY date ASC;

