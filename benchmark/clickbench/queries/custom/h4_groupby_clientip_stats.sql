SELECT "ClientIP", COUNT(*), AVG("ResolutionWidth"), SUM("IsRefresh") FROM hits WHERE "CounterID" > 0 AND "AdvEngineID" = 0 GROUP BY "ClientIP" ORDER BY COUNT(*) DESC LIMIT 50;
