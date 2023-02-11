-- 1) Find all players in the database who played at Vanderbilt University. Create a list showing each player's first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
SELECT namefirst AS first_name, namelast AS last_name, SUM(salary) AS total_salary
FROM people
INNER JOIN salaries
USING(playerid)
INNER JOIN collegeplaying
USING(playerid) 
WHERE schoolid = 'vandy'
GROUP BY namefirst, namelast
ORDER BY total_salary DESC;
-- Gives wrong answer because years at Vandy are counted multiple times.
-- Better answer is:
WITH vandy_players AS (
						SELECT DISTINCT playerid
						FROM collegeplaying 
						LEFT JOIN schools
						USING(schoolid)
						WHERE schoolid = 'vandy'
)
SELECT namefirst, 
	   namelast, 
	   SUM(salary)::numeric::money AS total_salary, 
	   COUNT(DISTINCT yearid) AS years_played
FROM people
	 INNER JOIN vandy_players
	 USING(playerid)
	 INNER JOIN salaries
	 USING(playerid)
GROUP BY playerid, namefirst, namelast
ORDER BY total_salary DESC;
-- I show David Price earned the most money in the majors.

-- 2) Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT SUM(po) AS putouts, 
CASE WHEN pos = 'OF' THEN 'Outfield'
     WHEN pos IN('SS', '1B', '2B', '3B' ) THEN 'Infield'
     WHEN pos IN('P', 'C') THEN 'Battery' 
END AS group_position
FROM fielding
WHERE yearid = '2016'
GROUP BY group_position;

-- 3) Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends? (Hint: For this question, you might find it helpful to look at the generate_series function (https://www.postgresql.org/docs/9.1/functions-srf.html). If you want to see an example of this in action, check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6) 
SELECT 
	CASE WHEN yearid BETWEEN 1920 AND 1929 THEN '1920-1929'
		 WHEN yearid BETWEEN 1930 AND 1939 THEN '1930-1939'
		 WHEN yearid BETWEEN 1940 AND 1949 THEN '1940-1949'
		 WHEN yearid BETWEEN 1950 AND 1959 THEN '1950-1959'
		 WHEN yearid BETWEEN 1960 AND 1969 THEN '1960-1969'
		 WHEN yearid BETWEEN 1970 AND 1979 THEN '1970-1979'
		 WHEN yearid BETWEEN 1980 AND 1989 THEN '1980-1989'
		 WHEN yearid BETWEEN 1990 AND 1999 THEN '1990-1999'
		 WHEN yearid BETWEEN 2000 AND 2009 THEN '2000-2009'
		 WHEN yearid BETWEEN 2010 AND 2019 THEN '2010-2019'
		 END AS decade, ROUND(SUM(so)::decimal/SUM(g)::decimal,2) AS average_strikeouts_per_game
FROM teams 
WHERE yearid >= 1920
GROUP BY decade 
ORDER BY decade;
--
SELECT 
	CASE WHEN yearid BETWEEN 1920 AND 1929 THEN '1920-1929'
		 WHEN yearid BETWEEN 1930 AND 1939 THEN '1930-1939'
		 WHEN yearid BETWEEN 1940 AND 1949 THEN '1940-1949'
		 WHEN yearid BETWEEN 1950 AND 1959 THEN '1950-1959'
		 WHEN yearid BETWEEN 1960 AND 1969 THEN '1960-1969'
		 WHEN yearid BETWEEN 1970 AND 1979 THEN '1970-1979'
		 WHEN yearid BETWEEN 1980 AND 1989 THEN '1980-1989'
		 WHEN yearid BETWEEN 1990 AND 1999 THEN '1990-1999'
		 WHEN yearid BETWEEN 2000 AND 2009 THEN '2000-2009'
		 WHEN yearid BETWEEN 2010 AND 2019 THEN '2010-2019'
		 END AS decade, ROUND(SUM(hr)::decimal/SUM(g)::decimal,2) AS average_homeruns_per_game
FROM teams 
WHERE yearid >= 1920
GROUP BY decade 
ORDER BY decade;
--
WITH decade_cte AS (
	SELECT generate_series(1920, 2020, 10) AS beginning_of_decade
)
SELECT ROUND(SUM(hr) * 1.0 / (SUM(g) / 2), 2) AS hr_per_game,							   ROUND(SUM(so) * 1.0 / (SUM(g) / 2), 2) AS so_per_game, 							   beginning_of_decade::text || 's' AS decade
FROM teams
INNER JOIN decade_cte
ON yearid BETWEEN beginning_of_decade AND beginning_of_decade + 9
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;
-- It appears that both strikeouts/game and home runs/game increased over time up until the 1970's and 1980's, when they declined. Then starting in the 1990's they went back up and increased by decade.

-- 4) Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases. Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.
SELECT namefirst, namelast, SUM(sb) AS total_stolen_bases, (cs + sb ) AS attempts, 100 * SUM(sb)/(cs + sb) AS stolen_base_percentage
FROM people
INNER JOIN batting
USING(playerid)
WHERE yearid = 2016
AND cs + sb >= 20
GROUP BY namefirst, namelast, cs + sb
ORDER BY stolen_base_percentage DESC;
--
WITH full_batting AS (
					  SELECT playerid, SUM(sb) AS sb, SUM(cs) AS cs, SUM(sb) + SUM(cs) 						 AS attempts
					  FROM batting
					  WHERE yearid = 2016
	                  GROUP BY playerid)
SELECT namefirst || ' ' || namelast AS fullname, sb, attempts, ROUND(sb*1.0 / attempts, 2) AS sb_percentage
FROM full_batting
INNER JOIN people
USING(playerid)
WHERE attempts >= 20
ORDER BY sb_percentage DESC;

-- 5) From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
SELECT name, yearid, w AS max_wins, wswin as world_series_winner
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND wswin = 'N'
GROUP BY name, yearid, w, wswin
ORDER BY max_wins DESC
LIMIT 5;
-- The Seattle Mariners had 116 wins in 2001 but did not win the World Series.
SELECT name, yearid, w AS min_wins, wswin as world_series_winner
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND wswin = 'Y'
GROUP BY name, yearid, min_wins, wswin
ORDER BY min_wins
LIMIT 5;
-- The Los Angeles Dodgers had 63 wins in 1981 and did win the World Series. this was a strike year for MLB.
WITH wins_by_year AS (SELECT yearid, franchid, w AS wins, wswin as world_series_win,
					  RANK() OVER(PARTITION BY yearid ORDER BY w DESC) AS       						  Rank_by_Total_Wins
					  FROM teams
					  WHERE yearid BETWEEN 1970 AND 2016
					  AND yearid <> 1981
					  ORDER BY yearid)
SELECT yearid, franchid, world_series_win
FROM wins_by_year
WHERE wins_by_year.Rank_by_Total_Wins = 1 AND world_series_win = 'Y'
ORDER BY yearid;

-- 6) Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.
WITH tmoy_nl&al AS (
					SELECT playerid, awardid
					FROM awardsmanagers
					WHERE awardid = 'TSN Manager of the Year' AND lgid = 'NL' OR lgid = 					'AL') 				
SELECT namefirst, namelast, teams.name
FROM people
INNER JOIN teams
USING(playerid);
--
SELECT *
FROM awardsmanagers
LIMIT 5;
-- 7) Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? Only consider pitchers who started at least 10 games (across all teams). Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player.

-- 8) Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, and the year they were inducted into the hall of fame (If they were not inducted into the hall of fame, put a null in that column.) Note that a player being inducted into the hall of fame is indicated by a 'Y' in the inducted column of the halloffame table.

-- 9) Find all players who had at least 1,000 hits for two different teams. Report those players' full names.

-- 10) Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

-- After finishing the above questions, here are some open-ended questions to consider.

-- Open-ended questions

-- 11) Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12) In this question, you will explore the connection between number of wins and attendance.

-- a. Does there appear to be any correlation between attendance at home games and number of wins?
-- b. Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

-- 13) It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?