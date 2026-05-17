SELECT COUNT(*), AVG("ResolutionWidth"), SUM("AdvEngineID") FROM hits WHERE "IsRefresh" = 0 AND "DontCountHits" = 0 AND "CounterID" > 100 AND "CounterID" < 500;
