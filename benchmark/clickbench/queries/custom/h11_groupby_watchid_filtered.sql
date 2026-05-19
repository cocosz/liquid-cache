SELECT "WatchID", COUNT(*), SUM("IsRefresh"), AVG("ResolutionWidth") FROM hits WHERE "CounterID" > 100 GROUP BY "WatchID" ORDER BY COUNT(*) DESC LIMIT 50;
