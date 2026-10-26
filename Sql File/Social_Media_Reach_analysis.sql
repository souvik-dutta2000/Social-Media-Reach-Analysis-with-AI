--1 Count Total rows:- 
SELECT COUNT(*) AS instagram_rows FROM dbo.Instagram_Posts_raw;   
SELECT COUNT(*) AS linkedin_rows  FROM dbo.LinkedIn_Posts_raw;

--STEP 2 - Profile the raw data (find the problems BEFORE fixing them)
-- 2a. Duplicate Post_IDs:-

SELECT Post_ID, COUNT(*) AS times_seen
FROM (SELECT Post_ID FROM dbo.Instagram_Posts_raw
      UNION ALL
      SELECT Post_ID FROM dbo.LinkedIn_Posts_raw) x
GROUP BY Post_ID
HAVING COUNT(*) > 1;  

-- 2b. Missing values

-- 2c. Messy Post_Type spellings (you will see 'reel ', 'CAROUSEL', etc.)
SELECT Post_Type, COUNT(*) AS n
FROM (SELECT Post_Type FROM dbo.Instagram_Posts_raw
      UNION ALL
      SELECT Post_Type FROM dbo.LinkedIn_Posts_raw) x
GROUP BY Post_Type
ORDER BY Post_Type;

-- 2c. Messy Post_Type spellings (you will see 'reel ', 'CAROUSEL', etc.)
SELECT Post_Type, COUNT(*) AS n
FROM (SELECT Post_Type FROM dbo.Instagram_Posts_raw
      UNION ALL
      SELECT Post_Type FROM dbo.LinkedIn_Posts_raw) x
GROUP BY Post_Type
ORDER BY Post_Type;

 --STEP 3 - Build ONE clean table (Posts_Clean)
--- UNION ALL stacks both platforms (same columns in both files)
    --ROW_NUMBER() keeps only the first copy of each duplicate Post_ID
    --LTRIM/RTRIM + UPPER/LOWER fixes spelling and case in Post_Type
    --Missing values are filled with the platform average (rounded down)
  -- WHY average here: only ~1% is missing, so it barely changes results.


IF OBJECT_ID('dbo.Posts_Clean') IS NOT NULL DROP TABLE dbo.Posts_Clean;

WITH all_raw AS (
    SELECT * FROM dbo.Instagram_Posts_raw
    UNION ALL
    SELECT * FROM dbo.LinkedIn_Posts_raw
),
dedup AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Post_ID ORDER BY Post_Date, Post_Time) AS rn
    FROM all_raw
),
unique_posts AS (
    SELECT * FROM dedup WHERE rn = 1
)
SELECT
    Post_ID,
    Platform,
    CAST(Post_Date AS DATE)  AS Post_Date,
    CAST(Post_Time AS TIME(0)) AS Post_Time,
    UPPER(LEFT(LTRIM(RTRIM(Post_Type)), 1)) + LOWER(SUBSTRING(LTRIM(RTRIM(Post_Type)), 2, 50)) AS Post_Type,
    Content_Category,
    Followers_At_Post,
    ISNULL(Hashtag_Count,  AVG(Hashtag_Count)  OVER (PARTITION BY Platform)) AS Hashtag_Count,
    ISNULL(Caption_Length, AVG(Caption_Length) OVER (PARTITION BY Platform)) AS Caption_Length,
    Impressions, Reach, Likes, Comments, Shares, Saves,
    Link_Clicks, Profile_Visits, Followers_Gained, Paid_Promotion
INTO dbo.Posts_Clean
FROM unique_posts;
-- Validation: must be exactly 5,000 per platform
SELECT Platform, COUNT(*) AS posts FROM dbo.Posts_Clean GROUP BY Platform;
-- Post_Type should now be clean (Reel, Carousel, Image, Story, Text, Document, Video, Poll, Article)
SELECT DISTINCT Post_Type FROM dbo.Posts_Clean ORDER BY Post_Type;

/* STEP 4 - The analysis view Power BI will connect to (vw_posts)
   Adds: Engagements, Engagement_Rate, hour, day, month, bands, AI flag.
   WHY a view: all calculations live in ONE place; Power BI just reads it.
--------------------------------------------------------------------- */
GO
CREATE OR ALTER VIEW dbo.vw_posts AS
WITH b AS (
    SELECT
        p.*,
        Likes + Comments + Shares + Saves                              AS Engagements,
        CAST(Likes + Comments + Shares + Saves AS FLOAT) / NULLIF(Reach, 0) AS Engagement_Rate,
        CAST(Reach AS FLOAT) / NULLIF(Followers_At_Post, 0)            AS Reach_Rate,
        DATEPART(HOUR, Post_Time)                                      AS Post_Hour,
        DATENAME(WEEKDAY, Post_Date)                                   AS Day_Name,
        (DATEDIFF(DAY, '19000101', Post_Date) % 7) + 1                 AS Day_No,        -- Monday = 1
        MONTH(Post_Date)                                               AS Month_No,
        LEFT(DATENAME(MONTH, Post_Date), 3)                            AS Month_Name,
        CASE WHEN Hashtag_Count <= 2  THEN '0-2'
             WHEN Hashtag_Count <= 5  THEN '3-5'
             WHEN Hashtag_Count <= 10 THEN '6-10'
             ELSE '11+' END                                            AS Hashtag_Band,
        CASE WHEN Hashtag_Count <= 2  THEN 1
             WHEN Hashtag_Count <= 5  THEN 2
             WHEN Hashtag_Count <= 10 THEN 3
             ELSE 4 END                                                AS Hashtag_Band_Order,
        CASE WHEN DATEPART(HOUR, Post_Time) BETWEEN 5  AND 11 THEN 'Morning'
             WHEN DATEPART(HOUR, Post_Time) BETWEEN 12 AND 16 THEN 'Afternoon'
             WHEN DATEPART(HOUR, Post_Time) BETWEEN 17 AND 21 THEN 'Evening'
             ELSE 'Night' END                                          AS Time_Band
    FROM dbo.Posts_Clean p
)

SELECT
    b.*,
    -- Flag used by Power BI "Key Influencers" (AI visual): is this post above its platform's average engagement rate?
    CASE WHEN Engagement_Rate > AVG(Engagement_Rate) OVER (PARTITION BY Platform)
         THEN 'Yes' ELSE 'No' END                                      AS Above_Avg_ER
FROM b;
GO

SELECT TOP 10 * FROM dbo.vw_posts;

/* =====================================================================
   ANALYSIS QUERIES  (each one answers a business question)
   NOTE: Engagement rate = SUM(engagements) / SUM(reach).
   Never AVERAGE the per-post rates - big posts and small posts would
   count equally, which is misleading. (A great interview point!)
   ===================================================================== */

-- Q1. Platform scorecard: which platform performs better overall?
SELECT Platform,
       COUNT(*)                                             AS posts,
       SUM(Reach)                                           AS total_reach,
       SUM(Impressions)                                     AS total_impressions,
       SUM(Engagements)                                     AS total_engagements,
       CAST(100.0 * SUM(Engagements) / SUM(Reach) AS DECIMAL(5,2)) AS engagement_rate_pct,
       AVG(Reach)                                           AS avg_reach_per_post,
       SUM(Followers_Gained)                                AS followers_gained
FROM dbo.vw_posts
GROUP BY Platform;

-- Q2. Which post type wins on reach and on engagement? (+ index vs platform average)
SELECT Platform, Post_Type,
       COUNT(*)                                             AS posts,
       AVG(Reach)                                           AS avg_reach,
       CAST(100.0 * SUM(Engagements) / SUM(Reach) AS DECIMAL(5,2)) AS engagement_rate_pct,
       SUM(Followers_Gained)                                AS followers_gained,
       CAST(1.0 * AVG(Reach) / AVG(AVG(Reach)) OVER (PARTITION BY Platform) AS DECIMAL(4,2)) AS reach_index
FROM dbo.vw_posts
GROUP BY Platform, Post_Type
ORDER BY Platform, avg_reach DESC;

-- Q3. Rank content categories inside each platform (window function RANK)
SELECT Platform, Content_Category, avg_reach, engagement_rate_pct,
       RANK() OVER (PARTITION BY Platform ORDER BY engagement_rate_pct DESC) AS er_rank
FROM (
    SELECT Platform, Content_Category,
           AVG(Reach) AS avg_reach,
           CAST(100.0 * SUM(Engagements) / SUM(Reach) AS DECIMAL(5,2)) AS engagement_rate_pct
    FROM dbo.vw_posts
    GROUP BY Platform, Content_Category
) t
ORDER BY Platform, er_rank;

-- Q4. Best posting hours (top 5 per platform by average reach)
SELECT * FROM (
    SELECT Platform, Post_Hour, COUNT(*) AS posts, AVG(Reach) AS avg_reach,
           ROW_NUMBER() OVER (PARTITION BY Platform ORDER BY AVG(Reach) DESC) AS rn
    FROM dbo.vw_posts
    GROUP BY Platform, Post_Hour
) t
WHERE rn <= 5
ORDER BY Platform, rn;

-- Q5. Best day of week (Day_No keeps Monday-Sunday order)
SELECT Platform, Day_No, Day_Name, COUNT(*) AS posts, AVG(Reach) AS avg_reach
FROM dbo.vw_posts
GROUP BY Platform, Day_No, Day_Name
ORDER BY Platform, Day_No;

-- Q6. Monthly reach trend with month-over-month growth (LAG)
SELECT Platform, Month_No, Month_Name, total_reach,
       CAST(100.0 * (total_reach - LAG(total_reach) OVER (PARTITION BY Platform ORDER BY Month_No))
            / NULLIF(LAG(total_reach) OVER (PARTITION BY Platform ORDER BY Month_No), 0) AS DECIMAL(6,1)) AS mom_growth_pct
FROM (
    SELECT Platform, Month_No, Month_Name, SUM(Reach) AS total_reach
    FROM dbo.vw_posts
    GROUP BY Platform, Month_No, Month_Name
) m
ORDER BY Platform, Month_No;

-- Q7. Running total of followers gained across the year
SELECT Platform, Month_No, Month_Name, followers_gained,
       SUM(followers_gained) OVER (PARTITION BY Platform ORDER BY Month_No) AS running_followers_gained
FROM (
    SELECT Platform, Month_No, Month_Name, SUM(Followers_Gained) AS followers_gained
    FROM dbo.vw_posts
    GROUP BY Platform, Month_No, Month_Name
) m
ORDER BY Platform, Month_No;

-- Q8. How many hashtags are ideal?
SELECT Platform, Hashtag_Band, Hashtag_Band_Order, COUNT(*) AS posts, AVG(Reach) AS avg_reach,
       CAST(100.0 * SUM(Engagements) / SUM(Reach) AS DECIMAL(5,2)) AS engagement_rate_pct
FROM dbo.vw_posts
GROUP BY Platform, Hashtag_Band, Hashtag_Band_Order
ORDER BY Platform, Hashtag_Band_Order;

-- Q9. Is paid promotion worth it? (reach lift vs engagement)
SELECT Platform, Paid_Promotion, COUNT(*) AS posts, AVG(Reach) AS avg_reach,
       CAST(100.0 * SUM(Engagements) / SUM(Reach) AS DECIMAL(5,2)) AS engagement_rate_pct
FROM dbo.vw_posts
GROUP BY Platform, Paid_Promotion
ORDER BY Platform, Paid_Promotion;

-- Q10. Top 5 posts by reach on each platform
SELECT * FROM (
    SELECT Platform, Post_ID, Post_Type, Content_Category, Post_Date, Reach, Engagements,
           ROW_NUMBER() OVER (PARTITION BY Platform ORDER BY Reach DESC) AS rn
    FROM dbo.vw_posts
) t
WHERE rn <= 5
ORDER BY Platform, rn;

-- Q11. Cross-platform comparison: same month, both platforms side by side (CASE pivot)
SELECT Month_No, Month_Name,
       SUM(CASE WHEN Platform = 'Instagram' THEN Reach END) AS instagram_reach,
       SUM(CASE WHEN Platform = 'LinkedIn'  THEN Reach END) AS linkedin_reach
FROM dbo.vw_posts
GROUP BY Month_No, Month_Name
ORDER BY Month_No;

-- Q12. KPI summary for the AI step (copy this result into the AI prompt - see the guide)
SELECT Platform, Post_Type,
       COUNT(*) AS posts,
       AVG(Reach) AS avg_reach,
       CAST(100.0 * SUM(Engagements) / SUM(Reach) AS DECIMAL(5,2)) AS engagement_rate_pct,
       SUM(Followers_Gained) AS followers_gained
FROM dbo.vw_posts
GROUP BY Platform, Post_Type
ORDER BY Platform, avg_reach DESC;