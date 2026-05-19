SELECT "RegionID", "CounterID", COUNT(*), SUM("ResolutionWidth"), AVG("ClientIP") FROM hits WHERE "DontCountHits" = 0 GROUP BY "RegionID", "CounterID" ORDER BY COUNT(*) DESC LIMIT 100;
