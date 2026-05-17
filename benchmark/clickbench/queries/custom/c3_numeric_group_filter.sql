SELECT "RegionID", COUNT(*), AVG("ResolutionWidth") FROM hits WHERE "AdvEngineID" > 0 AND "IsRefresh" = 0 GROUP BY "RegionID" ORDER BY COUNT(*) DESC LIMIT 20;
