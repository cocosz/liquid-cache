SELECT "UserID", SUM("AdvEngineID"), COUNT(*) FROM hits WHERE "IsRefresh" = 0 AND "AdvEngineID" > 0 GROUP BY "UserID" HAVING COUNT(*) > 5 ORDER BY SUM("AdvEngineID") DESC LIMIT 20;
