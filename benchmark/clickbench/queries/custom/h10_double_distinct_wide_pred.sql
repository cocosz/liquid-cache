SELECT COUNT(DISTINCT "CounterID"), COUNT(DISTINCT "ClientIP") FROM hits WHERE "IsRefresh" = 0 AND "DontCountHits" = 0;
