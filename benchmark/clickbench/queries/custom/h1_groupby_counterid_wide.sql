SELECT "CounterID", COUNT(*), SUM("ResolutionWidth"), AVG("ClientIP"), MIN("UserID"), MAX("UserID") FROM hits GROUP BY "CounterID" ORDER BY COUNT(*) DESC LIMIT 100;
