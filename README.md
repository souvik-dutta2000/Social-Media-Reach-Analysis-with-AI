# Social Media Reach Analysis | Instagram + LinkedIn

Show Image Show Image Show Image Show Image Show Image

An end-to-end data analytics project that analyses 10,000 social media posts (5,000 Instagram + 5,000 LinkedIn) to answer one question: what actually drives reach and engagement, and where should the next content and ad budget go?

Dataset note: the data is simulated (synthetic) for learning and portfolio practice. It is modelled on typical Instagram and LinkedIn post metrics for one brand account in 2025. It is not real account data. The monthly reach targets used in the dashboard are also assumed examples.

Table of contents
Business problem
Dataset
Architecture
Workflow
Key findings
Recommendations
Dashboard
Repository structure
How to run
Skills demonstrated
Limitations
Future improvements
Author
1. Business problem

A brand posts on Instagram and LinkedIn. The marketing team wants to know:

Which platform performs better on reach and engagement?
Which post types and content categories work best on each platform?
When should we post (day and hour)?
How many hashtags should we use?
Is paid promotion worth it?
Are we on track against our reach targets?
2. Dataset
Item	Detail
Source	Simulated for practice (one brand account, 2025)
Size	5,000 Instagram posts + 5,000 LinkedIn posts after cleaning (5,025 raw rows each)
Columns	19 (Post_ID, Platform, Post_Date, Post_Time, Post_Type, Content_Category, Followers_At_Post, Hashtag_Count, Caption_Length, Impressions, Reach, Likes, Comments, Shares, Saves, Link_Clicks, Profile_Visits, Followers_Gained, Paid_Promotion)
Instagram post types	Reel, Carousel, Image, Story
LinkedIn post types	Text, Image, Document, Video, Poll, Article
Extra tables (Excel)	Dim_Platform (platform pictures), Targets (assumed monthly reach targets), AI_Recommendations

Deliberate data quality problems (cleaned in Excel and SQL):

25 duplicate rows per platform
About 50 blank Hashtag_Count and 40 blank Caption_Length values per platform
About 75 inconsistent Post_Type labels per platform (for example reel  and CAROUSEL)
3. Architecture
<p align="center"> <img src="images/Project_Architecture.png" alt="Project architecture: Excel, SQL Server, Power BI, AI" width="90%"> </p>

Each tool has one job:

Tool	Job
Excel	Explore and clean the data, build pivots and a forecast, keep small business tables (targets, platform pictures, AI notes)
SQL Server	Repeatable cleaning pipeline, analysis view vw_posts, 12 analysis queries
Power BI	Data model, DAX measures, 5-page dashboard
AI	Power BI AI visuals plus AI-drafted recommendations, validated against SQL
4. Workflow
Step 1: Excel (explore and clean)
Converted both sheets into Tables, removed duplicates, standardised Post_Type with PROPER(TRIM()), filled blanks with the median.
Added helper columns: Engagements, Engagement Rate, Reach Rate, Post Hour, Day Name, Month, Hashtag Band.
Built PivotTables (with a calculated field so engagement rate is SUM of engagements / SUM of reach), charts and an Excel Forecast Sheet.
Step 2: SQL Server (clean pipeline and analysis)
Imported both CSV files and profiled the raw data.
Built Posts_Clean using UNION ALL, a CTE with ROW_NUMBER() to remove duplicates, text fixing and NULL handling.
Created the view vw_posts (engagements, engagement rate, hour, day, month, hashtag band, time band and an Above_Avg_ER flag).
Wrote 12 analysis queries using GROUP BY, RANK, ROW_NUMBER, LAG (month-over-month growth), running totals with SUM() OVER, CASE and window averages.
Reconciled the totals with Excel and Power BI.
Step 3: Power BI (model, DAX, dashboard)
Data model: Posts (SQL view) + Dim_Date + Dim_Platform + Targets (Excel), connected with one-to-many relationships.
DAX measures: Total Reach, Impressions, Engagements, Engagement Rate, Avg Reach per Post, Reach MoM %, Paid Reach Lift, Target Reach, Reach vs Target %, and more.
Dark professional theme, Instagram in pink and LinkedIn in blue throughout, platform pictures inside the report, page navigation, bookmarks and drill-through.
Step 4: AI
Key Influencers (which factors raise the chance of above-average engagement), Decomposition Tree and Smart Narrative.
Used an AI assistant to draft insights and recommendations from the SQL results, then checked every number against SQL before using it (see the AI_Recommendations sheet).
5. Key findings
Area	Finding
Overall	Instagram reach 86.8M vs LinkedIn 56.7M. Engagement rate 5.51% vs 4.74%
Instagram content	Reels average about 27.3K reach, about 2.3x Images, and bring about 77% of follower gains. Carousels have the highest engagement rate (about 8.0%). Stories are weakest (about 2.1%)
LinkedIn content	Documents have the highest engagement rate (about 6.6%). Polls have the highest reach (about 17.7K). Articles are weakest (about 2.3%)
Timing	Instagram: evenings (7-9 PM), strongest on weekends. LinkedIn: Tue-Thu, 8-10 AM; weekends are weak
Seasonality	Instagram peaks Oct-Dec. LinkedIn peaks Sep-Nov and is weakest in December
Hashtags	Instagram: 6-10 works best. LinkedIn: 3-5 works best
Paid promotion	Adds about +61% reach on Instagram and +48% on LinkedIn, but lowers engagement rate (Instagram 4.9% vs 5.7%, LinkedIn 4.2% vs 4.8%)
Categories	Instagram: Education (about 6.9%) and Business (about 6.3%) engage best. LinkedIn: Career Tips (about 5.5%) best, Product Updates (about 3.4%) worst
Targets (assumed)	Instagram reached about 108% of its reach target, LinkedIn about 97%
6. Recommendations
Instagram: use Reels for growth and Carousels for engagement; post in the evening, especially on weekends; use 6-10 hashtags.
LinkedIn: lead with Documents and Polls; post Tuesday to Thursday, 8-10 AM; use 3-5 hashtags; avoid long Articles.
Use paid promotion for reach goals (launches), not for engagement goals.
Plan big campaigns for Oct-Dec on Instagram and Sep-Nov on LinkedIn; expect a slow December on LinkedIn.
7. Dashboard

The Power BI report has 5 pages: Home, Overview, Content, Timing, AI Insights.

<!-- Replace these paths with your OWN Power BI screenshots (Win + Shift + S) saved in the screenshots folder. -->
Home	Overview
Home	Overview
Content	Timing
Content	Timing
AI Insights
AI Insights
Page	What it answers
Home	Cover page with headline numbers and navigation cards
Overview	KPIs, monthly reach vs target, platform scoreboard, best time to post, top posts
Content	Which post types and categories reach and engage most; reach vs engagement; follower growth
Timing	Day and hour heatmaps, hashtags, paid vs organic
AI Insights	Key Influencers, Decomposition Tree, Smart Narrative, validated recommendations
8. Repository structure
Social-Media-Reach-Analysis/
├── README.md
├── data/
│   ├── Social_Media_Reach_Dataset.xlsx     # raw data (Excel)
│   ├── Instagram_Posts_raw.csv             # raw data for SQL import
│   ├── LinkedIn_Posts_raw.csv
│   └── Integration_Tables.xlsx             # Dim_Platform, Targets, AI_Recommendations
├── sql/
│   └── SocialMedia_Reach_Analysis.sql      # cleaning, view, 12 analysis queries
├── powerbi/
│   ├── SocialMedia_Reach_Dashboard.pbix
│   └── SocialMedia_Dark_Theme.json
├── images/                                 # logo, banner, architecture diagram
├── screenshots/                            # real dashboard screenshots
└── docs/                                   # optional guides
9. How to run

Requirements: Microsoft Excel, SQL Server (Express or Developer) with SSMS, Power BI Desktop.

Excel: open data/Social_Media_Reach_Dataset.xlsx to explore and clean the data.
SQL Server:
Create the database SocialMediaReach.
Import Instagram_Posts_raw.csv and LinkedIn_Posts_raw.csv with Import Flat File (table names Instagram_Posts_raw and LinkedIn_Posts_raw).
Run sql/SocialMedia_Reach_Analysis.sql block by block.
Check: 5,000 posts per platform in Posts_Clean.
Power BI:
Open powerbi/SocialMedia_Reach_Dashboard.pbix.
Change the data source to your SQL Server (Home > Transform data > Data source settings) and point the Excel source to data/Integration_Tables.xlsx.
Click Refresh.
Reconcile: Total Posts 10,000, Total Reach 143.5M, Engagement Rate 5.21%, Followers Gained 384.7K.
10. Skills demonstrated
Area	Skills
Excel	Tables, data cleaning, formulas (PROPER, TRIM, MEDIAN, HOUR, TEXT, IF), PivotTables with calculated fields, charts, Forecast Sheet
SQL	CTEs, ROW_NUMBER, RANK, LAG, running totals, CASE, UNION ALL, views, NULL handling, profiling
Power BI	Star schema, multi-source model (SQL + Excel), DAX, theme and layout, platform pictures, navigation, bookmarks, drill-through
AI	Key Influencers, Decomposition Tree, Smart Narrative, AI-drafted insights validated against SQL
Business	KPI design, reach vs engagement thinking, actionable recommendations
11. Limitations
The dataset is simulated, covers one account and one year, so results show patterns in this data, not proof for any real brand.
The monthly targets are assumptions.
Key Influencers shows association, not cause and effect.
No audience demographics or content quality information is included.
12. Future improvements
Repeat the analysis on a real account export (Instagram and LinkedIn analytics).
Add statistical tests to check whether differences between post types are significant.
Build a model to predict reach from post type, time and hashtags.
Schedule the refresh with a data gateway.
13. Author

Souvik Dutta | Data Analyst (Fresher) | Kolkata, India

LinkedIn: linkedin.com/in/souvik-dutta-6a4159257
Email: souvikduttaofficial29@gmail.com
