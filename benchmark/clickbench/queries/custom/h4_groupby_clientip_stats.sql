SELECT "ClientIP", COUNT(*), AVG("ResolutionWidth"), SUM("IsRefresh") FROM hits GROUP BY "ClientIP" ORDER BY COUNT(*) DESC LIMIT 50;
