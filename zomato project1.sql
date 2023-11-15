select * from goldusers_signup;
select * from users;
select * from sales;
-- 1.what is total amount each customer spent on zomato ?
select userid,sum(price) Total_amount from sales s join product p on s.product_id=p.product_id
group by userid 
order by userid;
-- 2.How many days has each customer visited zomato?
select userid,count(distinct created_date) no_of_days from sales 
group by userid;
-- 3.what was the first product purchased by each customer?
select * from
(select userid,product_id,created_date,
dense_rank() over(partition by userid order by created_date) as RN
from sales) T
 order by RN 
 limit 3;
 #The first product purchased by userid 1 =1,userid 2=2,userid 3=1

-- 4.what is most purchased item on menu & how many times was it purchased by all customers ?
select userid,product_id,count(product_id) from sales 
 where product_id=(select product_id from sales limit 1)
 group by userid,product_id;
 #  Therefore most purchased product_id=2 total of 3 times by userid 1,3 times by userid 3 and 1 time by userid 2 i,e total 7
-- 5.which item was most popular for each customer?
with cte
as
(
select userid,product_id,count(product_id) over(partition by userid,product_id ) as cnt 
from sales
 ),
 cte1
 As
 (
 select *,row_number() over(partition by userid order by cnt desc) as rn1
 from cte
 )
 select * from cte1 where rn1=1;
 -- 6.which item was purchased first by customer after they become a member ?
select p.* from (select t.*, rank () over(partition by userid order by created_date) rnk from 
(select g.userid,s.product_id,s.created_date,g.gold_signup_date from sales s join goldusers_signup g on s.userid=g.userid
 and created_date>=gold_signup_date)t)p where rnk=1;
-- 7. which item was purchased just before the customer became a member?
select p.* from (select t.*, rank () over(partition by userid order by created_date desc) rnk from 
(select g.userid,s.product_id,s.created_date,g.gold_signup_date from sales s join goldusers_signup g on s.userid=g.userid
 and created_date<gold_signup_date)t)p where rnk=1; 
 -- 8. what is total orders and amount spent for each member before they become a member?
select userid,count(created_date) orders_purchased,sum(price) total_amount from (select s.userid,s.product_id,created_date,price from product p join sales s 
on s.product_id=p.product_id 
join goldusers_signup g on s.userid=g.userid
and created_date <gold_signup_date)t
group by userid 
order by userid;
-- 9. If buying each product generates points for eg 5rs=2 zomato point 
  -- and each product has different purchasing points for eg for p1 5rs=1 zomato point,
  -- for p2 10rs= 5 zomato point and p3 5rs=1 zomato point  2rs =1zomato point, 
  # First_part
select Z.userid, sum(Zomato_Points) * 2.5 AS Total_Cashback 
FROM
           (Select S.userid, P.product_name, P.price,
           Round(
           case 
           when product_name = "P1" then 1/5 * Price
           when product_name = "P2" then 5/10 * Price
           when product_name = "P3" then 1/5 * Price
           else 0
           end,2) as Zomato_Points
from sales S
join  product P
on S.product_id = P.product_id) Z
group by Z.userid 
order by Total_Cashback desc;
#second_part

SELECT Z.product_name, sum(Zomato_Points)  AS Total_Cashback 
FROM
           (SELECT S.userid, P.product_name, P.price,
     Round(
           CASE 
           WHEN product_name = "P1" THEN 1/5 * Price
           WHEN product_name = "P2" THEN 5/10 * Price
           WHEN product_name = "P3" THEN 1/5 * Price
           ELSE 0
           END,2) AS Zomato_Points
FROM sales S
JOIN product P
ON S.product_id = P.product_id) Z
GROUP BY Z.product_name 
ORDER BY Total_Cashback desc;
# Q10. In the First one year after a customer joins the gold program (including their joining date) irrespective of what the customer has purchased, 
# they earn 5 Zomato points for every 10 Rs spent, which user earned more (1 or 3) and what was their points earning?
SELECT userid, Round(Sum(Price) * 5/10,2) AS Zomato_Points 
FROM
        (SELECT S.userid, S.created_date, S.product_id, G.gold_signup_date, P.price
        FROM sales S
        JOIN goldusers_signup G 
        ON S.userid = G.userid
        JOIN product P 
        ON S.product_id = P.product_id
WHERE S.created_date >= G.gold_signup_date ) X
GROUP BY userid;
#Q11. Rank all the transactions of the customers ?
SELECT *,
RANK() OVER (Partition by userid Order by created_date) AS RNK
FROM SALES;
#Q12. Rank all the transactions for each member whenever they are a Zomato gold member and for every non gold member, mark transaction as NA?
SELECT X.*,
CASE WHEN gold_signup_date IS NULL THEN "NA" ELSE
RANK() OVER (partition by userid order by created_date desc) END AS RNK
FROM
          (SELECT S.userid, S.created_date, S.product_id, G.gold_signup_date
          FROM sales S
          LEFT JOIN goldusers_signup G 
          ON S.userid = G.userid
          AND S.created_date >= G.gold_signup_date) X