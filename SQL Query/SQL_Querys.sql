-- CREATE TABLES CHAPTER #1
-- CREATE TABLES CONTINENT,CONTINENTS,COUNTRIES AND PER_CAPITA

CREATE TABLE public. "continent"(
	country_code VARCHAR(100),
	continent_code VARCHAR(100)
	
)

CREATE TABLE public. "continents"(
	continent_code VARCHAR(50),
	continent_name VARCHAR(50)

)

CREATE TABLE public. "countries"(
	country_code VARCHAR(100),
	country_name VARCHAR (100)
	
)

CREATE TABLE public. "per_capita"(
	country_code VARCHAR(50),
	year	NUMERIC,
	gdp_per_capita NUMERIC
	
)



--CHAPTER #2
-- IMPORT CSV AND INSERT TO TABLES

COPY PUBLIC. "continent" FROM 'C:\Users\rodri\Documents\SQL\BrainTree_SQL_Coding_Challenge_Data_Analyst\data_csv\continent_map.csv' DELIMITER ',' CSV HEADER ENCODING 'windows-1251'
COPY PUBLIC. "continents" FROM 'C:\Users\rodri\Documents\SQL\BrainTree_SQL_Coding_Challenge_Data_Analyst\data_csv\continents.csv' DELIMITER ',' CSV HEADER ENCODING 'windows-1251'
COPY PUBLIC. "countries" FROM 'C:\Users\rodri\Documents\SQL\BrainTree_SQL_Coding_Challenge_Data_Analyst\data_csv\countries.csv' DELIMITER ',' CSV HEADER ENCODING 'windows-1251'
COPY PUBLIC. "per_capita" FROM 'C:\Users\rodri\Documents\SQL\BrainTree_SQL_Coding_Challenge_Data_Analyst\data_csv\per_capita.csv' DELIMITER ',' CSV HEADER ENCODING 'windows-1251'


--CONTINENT TABLE
SELECT *
FROM continent
ORDER BY Country_code

--QUESTION #1
-- find Null Values in table continent and replace NULL for string "FOO"
-- ORDER BY ASC

SELECT 
CASE 
	WHEN country_code IS NULL THEN 'FOO' 	
	ELSE country_code
END,
continent_code
INTO continent_new
FROM continent
ORDER BY country_code

--QUESTION #2
-- find duplicates values and filter unique values for position one

SELECT country_code, continent_code
FROM( SELECT *,COUNT(*) OVER (PARTITION BY country_code) N
	 FROM continent_new) AS A
WHERE N > 1


SELECT country_code, count(*)
FROM continent_new
GROUP BY country_code
HAVING COUNT(*)>1
ORDER BY country_code;

SELECT * 
INTO continent_distinc
FROM(
	SELECT *,
	ROW_NUMBER() OVER(PARTITION BY country_code,continent_code ORDER BY country_code) AS Row
	FROM continent_new
) dups
WHERE dups.Row = 1


--#QUESTION 2 CONTINENT

-- DELETE VALUES NULL
SELECT 
	country_code,
	year,
	gdp_per_capita
INTO percapita
FROM per_capita
WHERE gdp_per_capita IS NOT NULL



--Built to function



WITH gdp_2011 AS (
	SELECT country_code, gdp_per_capita AS gdp_2011
	FROM percapita
	WHERE year = 2011
),
gdp_2012 AS(
	SELECT country_code,gdp_per_capita AS gdp_2012
	FROM percapita
	WHERE year = 2012
),
table_gdp AS(
	SELECT g2012.country_code,
	CONCAT(ROUND(((g2012.gdp_2012 - g2011.gdp_2011)/g2011.gdp_2011)*100), '%') AS PBI
	FROM gdp_2012 as g2012
	INNER JOIN gdp_2011 as g2011
	ON g2012.country_code = g2011.country_code
),
table_f AS (
	SELECT g.country_code,g.pbi, c.country_name
	FROM table_gdp AS g
	INNER JOIN countries AS c
	ON g.country_code =  c.country_code
),
join_continen AS (
	SELECT cn.country_code,ct.continent_name
	FROM continent_new AS cn
	INNER JOIN continents AS ct
	ON cn.continent_code = ct.continent_code
)
SELECT tf.country_code,tf.pbi,tf.country_name,cj.continent_name
INTO join_table
FROM table_f AS tf
INNER JOIN join_continen AS cj
ON tf.country_code = cj.country_code
ORDER BY tf.pbi DESC

-- ORDER FOR CONTINENT RANK 15
SELECT * 
FROM(
	SELECT *,
	ROW_NUMBER() OVER (PARTITION BY continent_name ORDER BY pbi DESC) AS Rank
	FROM join_table
) dups
WHERE dups.Rank BETWEEN 10 AND 12


---#QUESTION 3

--Match continent code
WITH continents_2 AS (
	SELECT *
	FROM continents
), match_continent AS (
	SELECT cn.country_code, c2.continent_name
	FROM continent_new AS cn
	INNER JOIN continents_2 AS c2
	ON cn.continent_code = c2.continent_code
)
SELECT mc.continent_name, ROUND(SUM(pc.gdp_per_capita)) AS TOTAL
--INTO table_sum
FROM match_continent AS mc
INNER JOIN per_capita AS pc
ON mc.country_code =  pc.country_code
WHERE pc.year = 2012 AND pc.gdp_per_capita IS NOT NULL
GROUP BY mc.continent_name
ORDER BY total DESC;


--Table pivot

SELECT
CONCAT (ROUND(((SELECT
			   		SUM(total)
			   FROM
			   		table_sum
			   WHERE
			   		continent_name = 'Asia')/(SELECT SUM(total)
												FROM table_sum)) * 100,1), '%') AS Asia,
CONCAT (ROUND(((SELECT
			   		SUM(total)
			   FROM
			   		table_sum
			   WHERE
			   		continent_name = 'Europe') /(SELECT SUM(total)
												FROM table_sum)) * 100,1), '%') AS Europa,
												
CONCAT (ROUND(((SELECT
			   		SUM(total)
			   FROM
			   		table_sum
			   WHERE
			   		continent_name  != 'Asia' AND continent_name != 'Europe')
			   /(SELECT SUM(total)
												FROM table_sum)) * 100,1), '%') AS Res_of_the_worl



---#QUESTION 4

SELECT c.country_name, cn.country_code, cn.continent_code 
INTO table_country_continents
FROM countries AS c
INNER JOIN continent_new AS cn
ON c.country_code = cn.country_code


SELECT COUNT(*), CONCAT(ROUND(SUM (pc.gdp_per_capita)), '     USD')
FROM per_capita AS pc
INNER JOIN table_country_continents AS tcc
ON pc.country_code = tcc.country_code
WHERE pc.year = 2007 AND tcc.country_name LIKE '%an%'


--Question 4.1
SELECT COUNT(*), CONCAT(ROUND(SUM (pc.gdp_per_capita)), '     USD')
FROM per_capita AS pc
INNER JOIN table_country_continents AS tcc
ON pc.country_code = tcc.country_code
WHERE pc.year = 2007 AND tcc.country_name  ILIKE '%an%';



--QUESTION 5
WITH table_continent AS (
	
	SELECT pc.country_code, pc.year,pc.gdp_per_capita, tcc.continent_code
	FROM per_capita AS pc
	INNER JOIN table_country_continents AS tcc
	ON pc.country_code = tcc.country_code
) 
SELECT  year, SUM (gdp_per_capita) AS total_pbi, count(country_code) AS recount_country
FROM table_continent
WHERE year < 2012
GROUP BY year
ORDER BY year DESC


---QUESTION 6

SELECT *
FROM pg_catalog.pg_tables 
WHERE schemaname = 'public'

WITH country_continent AS (

		SELECT cn.country_code, c.continent_name
		FROM continent_new  AS cn
		INNER JOIN continents AS c
		ON cn.continent_code = c.continent_code
),
onion_country AS (
		SELECT  cc.country_code, c.country_name,cc.continent_name
		FROM country_continent AS cc
		INNER JOIN countries AS c
		ON cc.country_code = c.country_code

), countries_filter AS (
		SELECT pc.country_code, oc.country_name, oc.continent_name, pc.gdp_per_capita
		FROM onion_country AS oc
		INNER JOIN per_capita AS  pc
		ON pc.country_code = oc.country_code
		ORDER BY oc.continent_name ASC
), countries_acumulate AS(
	
	SELECT *
	FROM (
		SELECT *,
		ROW_NUMBER() OVER (PARTITION BY continent_name ORDER BY continent_name ASC) AS Rank
		FROM countries_filter
	)  dups
	WHERE dups.Rank BETWEEN 2 AND 4
) 
SELECT continent_name, CONCAT(ROUND(SUM (gdp_per_capita),1), '  USD') AS total_gdp
FROM countries_acumulate
GROUP BY continent_name
ORDER BY 1


--QUESTION 7

WITH country_continent AS (

		SELECT cn.country_code, c.continent_name
		FROM continent_new  AS cn
		INNER JOIN continents AS c
		ON cn.continent_code = c.continent_code
),
onion_country AS (
		SELECT  cc.country_code, c.country_name,cc.continent_name
		FROM country_continent AS cc
		INNER JOIN countries AS c
		ON cc.country_code = c.country_code

), countries_filter AS (
		SELECT pc.country_code, oc.country_name, oc.continent_name, pc.gdp_per_capita
		FROM onion_country AS oc
		INNER JOIN per_capita AS  pc
		ON pc.country_code = oc.country_code
		WHERE pc.gdp_per_capita IS NOT NULL
		ORDER BY oc.continent_name ASC
),
 continent_per_capita AS(
	
	SELECT *
	FROM (
		SELECT *,
		ROW_NUMBER() OVER (PARTITION BY continent_name ORDER BY gdp_per_capita DESC ) AS Rank
		FROM countries_filter
	)  dups
	 WHERE dups.Rank = 1
) 
SELECT rank, continent_name, country_name, country_code, gdp_per_capita
FROM  continent_per_capita






















