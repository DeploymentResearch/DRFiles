USE SUSDB
-- SELECT UpdateID FROM vwMinimalUpdate WHERE IsSuperseded = 1 AND Declined = 0
SELECT COUNT(*) FROM vwMinimalUpdate WHERE IsSuperseded = 1 AND Declined = 0