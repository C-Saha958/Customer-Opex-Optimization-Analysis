
## A. Revenue and Margin Analysis
# 1. Discount Impact on Margin: Calculate the percentage difference in Average Purchase Amount between transactions with a discount and those without.
SELECT
    (SELECT AVG(CASE WHEN Discount_Applied = 'No' THEN `Purchase_Amount_(USD)` END) FROM final_table) AS Undiscounted_AOV,
    
    (SELECT AVG(CASE WHEN Discount_Applied = 'Yes' THEN `Purchase_Amount_(USD)` END) FROM final_table) AS Discounted_AOV,

    ROUND(
        (
            (SELECT AVG(CASE WHEN Discount_Applied = 'No' THEN `Purchase_Amount_(USD)` END) FROM final_table) 
            - (SELECT AVG(CASE WHEN Discount_Applied = 'Yes' THEN `Purchase_Amount_(USD)` END) FROM final_table)
        ) 
        / (SELECT AVG(CASE WHEN Discount_Applied = 'No' THEN `Purchase_Amount_(USD)` END) FROM final_table)
        * 100, 
    2) AS Margin_Erosion_Pct;


# 2. Total Revenue Lost to Discounts: Estimate the total dollar amount lost to promotions (assuming items would have been bought at the average full price).
SELECT 
      (COUNT(CASE WHEN Discount_Applied = 'Yes' THEN 1 END) * (SELECT AVG(`Purchase_Amount_(USD)`) 
	  FROM final_table
      WHERE Discount_Applied = 'No')) - SUM(CASE WHEN Discount_Applied = 'Yes' THEN `Purchase_Amount_(USD)` END) 
AS Total_Revenue_Lost 
FROM final_table;

# 3. Revenue per Payment Method: Identify which methods generate the most revenue (relevant for payment processing Opex).
SELECT 
      Payment_Method, 
      SUM(`Purchase_Amount_(USD)`) 
AS total_revenue 
FROM final_table 
GROUP BY Payment_Method 
ORDER BY total_revenue DESC;


# 4. Highest Discount Dependency: 
# Find the top 5 product categories where discounts are most frequently used.
SELECT 
	  Category, 
	  COUNT(CASE WHEN Discount_Applied = 'Yes' THEN 1 END) 
AS total_discounted_purchases 
FROM final_table 
GROUP BY Category 
ORDER BY total_discounted_purchases DESC LIMIT 5;


# 5. AOV by Shipping Type: 
# Compare Average Order Value for different shipping types (informs shipping Opex decisions).
SELECT 
      Shipping_Type, 
	  ROUND(AVG(`Purchase_Amount_(USD)`), 2) 
AS average_order_value 
FROM final_table
GROUP BY Shipping_Type;


# B. Customer Segmentation & Value
# 6. Average CLV Proxy by Age Group: 
# Find the average Previous_Purchases (a CLV proxy) across 10-year age bands.
SELECT 
      FLOOR(Age / 10) * 10 AS age_group, 
      AVG(Previous_Purchases) AS avg_clv_proxy 
FROM final_table
GROUP BY age_group 
ORDER BY age_group;


# 7.	Customer Count by Frequency: 
# Count how many customers fall into each purchase frequency category.	
SELECT 
     Frequency_of_Purchases, 
     COUNT(Customer_ID) AS customer_count 
FROM final_table 
GROUP BY Frequency_of_Purchases 
ORDER BY customer_count DESC;



# 8. Retention Rate by Subscription: 
# Compare the average Previous_Purchases between subscribers and non-subscribers.	
SELECT 
Subscription_Status, 
AVG(Previous_Purchases) AS avg_retention_proxy 
FROM final_table
GROUP BY Subscription_Status;



# 9. Top Spending Customers: 
# List the 10 customers with the highest total spend.	
SELECT 
     Customer_ID, 
     SUM(`Purchase_Amount_(USD)`) AS total_spend 
FROM final_table
GROUP BY Customer_ID 
ORDER BY total_spend DESC LIMIT 10;



# 10. High-Value Item Sizing: 
# Find the most common size purchased for the highest revenue category (e.g., 'Clothing').
SELECT 
     Size, 
     COUNT(Customer_ID) AS 
     purchase_count 
FROM final_table
WHERE Category = 'Clothing' 
GROUP BY Size 
ORDER BY purchase_count DESC;



# C. Product Performance and Inventory
# 11	Top 5 Revenue-Generating Items:
# Identify the products driving the most sales.	
SELECT 
     Item_Purchased, 
     SUM(`Purchase_Amount_(USD)`) AS total_revenue 
FROM final_table
GROUP BY Item_Purchased 
ORDER BY total_revenue DESC LIMIT 5;


# 12. Lowest Rated Products: 
# Find the 5 products with the lowest average review rating.	
SELECT 
      Item_Purchased, 
      AVG(Review_Rating) AS avg_rating 
FROM final_table 
GROUP BY Item_Purchased 
ORDER BY avg_rating ASC LIMIT 5;

# 13. Seasonal Demand by Category: 
# Calculate the total revenue per season for a specific category (e.g., 'Footwear').
SELECT 
     Season, 
     SUM(`Purchase_Amount_(USD)`) 
AS footwear_revenue 
FROM final_table 
WHERE Category = 'Footwear' 
GROUP BY Season 
ORDER BY footwear_revenue DESC;



# 14. Rating Distribution: 
# Count the number of purchases for each discrete Review_Rating (1.0 to 5.0).	
SELECT 
     Review_Rating, 
     COUNT(*) AS rating_count 
FROM final_table 
GROUP BY Review_Rating 
ORDER BY Review_Rating DESC;      



# 15. Most Popular Item Color: 
# Find the color purchased most often across all items.
SELECT 
     Color, 
     COUNT(*) AS purchase_count 
FROM final_table
GROUP BY Color 
ORDER BY purchase_count DESC LIMIT 1; 



# D. Retention and Subscriptions
# 16. Subscriber vs. Non-Subscriber Demographics: 
# Find the average age and gender split for subscribers vs. non-subscribers.
SELECT 
      Subscription_Status, 
	  ROUND(AVG(Age), 1) AS avg_age, 
      COUNT(CASE WHEN Gender = 'Male' THEN 1 END) AS male_count, 
      COUNT(CASE WHEN Gender = 'Female' THEN 1 END) AS female_count 
FROM final_table
GROUP BY Subscription_Status;


# 17. Conversion by Location: 
# Find the top 5 locations with the highest percentage of subscribers.	
SELECT 
     Location, 
	 (COUNT(CASE WHEN Subscription_Status = 'Yes' THEN 1 END) * 100.0 / COUNT(Customer_ID)) 
           AS subscription_rate_pct 
FROM final_table 
GROUP BY Location 
ORDER BY subscription_rate_pct DESC LIMIT 5;



# 18. Average Rating for Subscribers: 
# Check if subscribers give better reviews (high satisfaction).
SELECT 
Subscription_Status, 
AVG(Review_Rating) AS avg_rating 
FROM final_table 
GROUP BY Subscription_Status;


# 19. Loyalty Level vs. Subscription: 
# Check if high-loyalty customers (Previous_Purchases > 15) are more likely to subscribe.
SELECT 
CASE 
   WHEN Previous_Purchases >= 15 THEN 'High Loyalty' 
   ELSE 'Low Loyalty' 
   END AS loyalty_level, 
COUNT(CASE WHEN Subscription_Status = 'Yes' THEN 1 END) AS subscriber_count 
FROM final_table
GROUP BY loyalty_level;


# 20. Average Age of High-Frequency Buyers: 
# Target marketing Opex towards these specific, active cohorts.
SELECT 
     Frequency_of_Purchases, 
     ROUND(AVG(Age), 1) AS avg_age 
FROM final_table 
WHERE 
     Frequency_of_Purchases IN ('Daily', 'Weekly') 
GROUP BY Frequency_of_Purchases;



# E. Demographic/Geographic Analysis
# 21. Top 5 Revenue-Generating States:
# Identify the core geographical areas driving total sales.
SELECT 
     Location, 
     SUM(`Purchase_Amount_(USD)`) AS total_revenue 
FROM final_table 
GROUP BY Location 
ORDER BY total_revenue DESC LIMIT 5;


# 22. Average Spend by Age Group:
# (Simple breakdown of total spend by decade).
SELECT 
     FLOOR(Age / 10) * 10 AS age_group, 
     ROUND(AVG(`Purchase_Amount_(USD)`), 2) AS avg_spend 
FROM your_data_table 
GROUP BY FLOOR(Age / 10) * 10 
ORDER BY age_group;


# 23. Gender Split of Discount Use: 
# Compare how often each gender uses a discount.
SELECT 
     Gender, 
     COUNT(CASE WHEN Discount_Applied = 'Yes' THEN 1 END) AS discount_user_count 
FROM your_data_table 
GROUP BY Gender;