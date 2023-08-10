-- MID COURSE PROJECT

-- The situation: Maven fuzzy factory has been live for 8 months and our CEO has to present the company performance metrics to the board next week. 
-- We are asked to prepare relevant metrics to show the company's performance growth. 


USE mavenfuzzyfactory;


-- QUESTION 1: Gsearch seems to be the biggest driver of our business. Could you pull monthly trends for gsearch sessions and orders to showcase the growth there?

SELECT
	MONTH(website_sessions.created_at) AS _month_,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions
	LEFT JOIN orders
		ON orders.website_session_id=website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
	AND website_sessions.utm_source='gsearch'
GROUP BY _month_;
		



-- QUESTION 2: Next, it would be be great to see a similar monthly trend for Gsearch, but this time splitting out nonbrand and brand campaigns separately.
-- Basically, the company wants to know if they always have to rely on paid traffic or not. 
SELECT
	MONTH(website_sessions.created_at) AS _month_,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign='brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_sessions,
	COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign='brand' THEN orders.order_id ELSE NULL END) AS brand_orders,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign='nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS nonbrand_sessions,
	COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign='nonbrand' THEN orders.order_id ELSE NULL END) AS nonbrand_orders

FROM website_sessions
	LEFT JOIN orders
		ON orders.website_session_id=website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
	AND website_sessions.utm_source='gsearch'
GROUP BY _month_;

-- Brand campaigns represent someone going into the search engines and specifically looking for that particular business. Therefore, the fact that brand sessions and orders have increased
-- dramatically increased is a good sign. 



-- QUESTION 3: While we are on gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device type?
SELECT
	MONTH(website_sessions.created_at) AS _month_,
	COUNT(DISTINCT CASE WHEN website_sessions.device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END) AS desktop_sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mobile_sessions,
	COUNT(DISTINCT CASE WHEN website_sessions.device_type='desktop' THEN orders.order_id ELSE NULL END) AS desktop_orders,
	COUNT(DISTINCT CASE WHEN website_sessions.device_type='mobile' THEN orders.order_id ELSE NULL END) AS mobile_orders
FROM website_sessions
	LEFT JOIN orders
		ON orders.website_session_id=website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
	AND website_sessions.utm_source='gsearch'
    AND website_sessions.utm_campaign='nonbrand'
GROUP BY _month_;

-- We see there are a lot more of desktop sessions and desktop orders. 


-- QUESTION 4: Pull monthly trends for gsearch, alongside monthly trends for each of our other channels. 


-- With this statement we can see the other channels. In total, we have this channels: gsearch and bsearch.
SELECT DISTINCT utm_source
FROM website_sessions
WHERE website_sessions.created_at < '2012-11-27';

SELECT
	MONTH(website_sessions.created_at) AS _month_,
	COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'gsearch' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_paid_sessions,
	COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'bsearch' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_paid_sessions,
    
	COUNT(DISTINCT CASE WHEN website_sessions.utm_source IS NULL AND website_sessions.http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_search_sessions,
	COUNT(DISTINCT CASE WHEN website_sessions.utm_source IS NULL AND website_sessions.http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_type_in_search_sessions

FROM website_sessions
	LEFT JOIN orders
		ON orders.website_session_id=website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
    -- AND website_sessions.utm_campaign='nonbrand'
GROUP BY _month_;

  -- Organic and direct type in traffic is free (the compaby does not spend money on marketing, so the benefit is the 100% of the order). Therefore, is good to see that these sessions are growing.  



-- QUESTION 5: Pull session to order conversion rates, by month. 
SELECT
	MONTH(website_sessions.created_at) AS _month_,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,  -- The sessions that the users make in the business webpage
    COUNT(DISTINCT orders.order_id) AS orders,       -- The orders that that the customers really do
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_conv_rate
FROM website_sessions
	LEFT JOIN orders  -- the website_sessions table doesn't have orders data in it so we have to include it
		ON orders.website_session_id=website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY _month_;


-- QUESTION 6: For the gsearch lander test, please estimate the revenue that test earned us (you have to look at the increase of CVR from the test (Jun 19-Jul 28),
-- and use nonbrand sessions and revenue since then to calculate incremental value. 

-- First we have to look for the first instance of that test url "/lander-1"
SELECT
MIN(website_pageview_id) AS first_test_pv
FROM website_pageviews
WHERE pageview_url='/lander-1'; -- first_test_pv=23504

CREATE TEMPORARY TABLE first_test_pageviews
SELECT
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
	INNER JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id
        AND website_sessions.created_at < '2012-07-28' -- Prescribed by the assignment
        AND website_pageviews.website_pageview_id > 23504 -- First pageview id
        AND website_sessions.utm_source = 'gsearch'
        AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY
	website_pageviews.website_session_id;
    
-- Now we bring in the landing page to each session, but restricting to home or lander-1.
CREATE TEMPORARY TABLE nonbrand_test_sessions_w_landing_pages
SELECT
	first_test_pageviews.website_session_id,
    website_pageviews.pageview_url AS landing_page 
FROM first_test_pageviews
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id=first_test_pageviews.min_pageview_id -- The website pageview is the landing pageview
WHERE website_pageviews.pageview_url IN ('/home','/lander-1');

-- Then we make a table to bring in orders.

CREATE TEMPORARY TABLE nonbrand_test_sessions_w_orders
SELECT
	nonbrand_test_sessions_w_landing_pages.website_session_id,
    nonbrand_test_sessions_w_landing_pages.landing_page AS landing_page,
    orders.order_id AS order_id
FROM nonbrand_test_sessions_w_landing_pages
	LEFT JOIN orders
		ON orders.website_session_id=nonbrand_test_sessions_w_landing_pages.website_session_id;
	

-- Let's find the difference between conversion rates. 
SELECT
	landing_page,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) AS conv_rate
FROM nonbrand_test_sessions_w_orders
GROUP BY 1; -- The difference between the /lander-1 and the /home conversion rate is 0.0087
    

-- Find the most reent pageview for gsearch nonbrand where the traffic was sent to /home. 
SELECT
	MAX(website_sessions.website_session_id) AS most_recent_gsearch_nonbrand_home_pageview -- 17145
FROM website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id=website_pageviews.website_session_id
WHERE utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
    AND pageview_url='/home'
    AND website_sessions.created_at < '2012-11-27'; -- 22972 website sessions since the test
    
-- Quick math: 22972*0.0087=200 apox


SELECT
	COUNT(website_session_id) AS sessions_since_test
FROM website_sessions
WHERE created_at < '2012-11-27'
	AND website_session_id > '17145'
    AND utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
    