SELECT "WatchID", "ClientIP", COUNT(*), SUM("IsRefresh"), AVG("ResolutionWidth") FROM hits WHERE "CounterID" > 0 AND "IsRefresh" = 0 GROUP BY "WatchID", "ClientIP" ORDER BY COUNT(*) DESC LIMIT 10;
