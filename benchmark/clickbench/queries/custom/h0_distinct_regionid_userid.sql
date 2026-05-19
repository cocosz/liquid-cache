SELECT "RegionID", COUNT(*), SUM("AdvEngineID"), AVG("ResolutionWidth"), COUNT(DISTINCT "UserID") FROM hits WHERE "IsRefresh" = 0 GROUP BY "RegionID" ORDER BY COUNT(*) DESC LIMIT 20;
