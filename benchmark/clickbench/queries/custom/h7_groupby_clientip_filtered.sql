SELECT "ClientIP", COUNT(*), AVG("ResolutionWidth"), SUM("AdvEngineID") FROM hits WHERE "AdvEngineID" > 0 AND "IsRefresh" = 0 GROUP BY "ClientIP" ORDER BY COUNT(*) DESC LIMIT 50;
