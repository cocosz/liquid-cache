SELECT "UserID", SUM("ResolutionWidth"), COUNT(*) FROM hits WHERE "ResolutionWidth" > 0 GROUP BY "UserID" HAVING COUNT(*) > 3 ORDER BY SUM("ResolutionWidth") DESC LIMIT 20;
