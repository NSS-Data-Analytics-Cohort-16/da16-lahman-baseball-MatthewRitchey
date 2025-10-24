-- ## Lahman Baseball Database Exercise
-- - this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by 
-- Sean Lahman
-- - A data dictionary is included with the files for this project.

-- **Directions:**  
-- * Within your repository, create a directory named "scripts" which will hold your scripts.
-- * Create a branch to hold your work.
-- * For each question, write a query to answer.
-- * Complete the initial ten questions before working on the open-ended ones.
SELECT *
FROM teams
-- **Initial Questions**

-- 1. What range of years for baseball games played does the provided database cover? 
SELECT MIN (yearid) AS earliest_year,
	MAX(yearid) AS latest_year
FROM teams -- 1871/2016

-- 2. Find the name and height of the shortest player in the database. How many games did he play in?
-- What is the name of the team for which he played?
SELECT p.namefirst, 
	p.namelast,
	p.height,
	MAX(a.g_all) AS total_games_played,
	t.name
FROM people AS p
LEFT JOIN appearances AS a
	ON a.playerid = p.playerid
LEFT JOIN teams AS t
	ON t.teamid=a.teamid
GROUP BY p.namefirst, p.namelast, p.height, t.name
ORDER BY p.height ASC
LIMIT 5; -- Eddie Gaedel, 43" (3'7"), 1 game played for the St. Louis Browns

--------------------sub query version---------------------
SELECT p.namefirst,
	p.namelast,
	p.height,
		(
		SELECT a.g_all
		FROM appearances AS a
		WHERE a.playerid = p.playerid
	)AS games_played,
		(
		SELECT a.teamid
		FROM appearances AS a
		WHERE a.playerid = p.playerid
	) AS team
FROM people AS p
ORDER BY p.height ASC
LIMIT 1;

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each
-- player’s first and last names as well as the total salary they earned in the major leagues. Sort this
-- list in descending order by the total salary earned. Which Vanderbilt player earned the most money in
-- the majors?

-- SELECT DISTINCT ON (p.playerid)
-- 	p.namefirst,
-- 	p.namelast,
-- 	s.salary,
-- 	sc.schoolname
-- FROM people AS p
-- LEFT JOIN salaries AS s
-- 	ON s.playerid = p.playerid
-- LEFT JOIN collegeplaying AS c
-- 	ON c.playerid = p.playerid
-- LEFT JOIN schools AS sc
-- 	ON sc.schoolid = c.schoolid
-- WHERE sc.schoolname ILIKE '%vanderbilt%'
-- ORDER BY p.playerid, s.salary DESC -------(shows every row each player has)


-- SELECT
--   p.namefirst,
--   p.namelast,
--   MAX(s.salary) AS highest_salary,
--   STRING_AGG(DISTINCT sc.schoolname, ', ') AS schools
-- FROM people AS p
-- LEFT JOIN salaries AS s 
-- 	ON s.playerid = p.playerid
-- LEFT JOIN collegeplaying AS c 
-- 	ON c.playerid = p.playerid
-- LEFT JOIN schools AS sc 
-- 	ON sc.schoolid = c.schoolid
-- WHERE sc.schoolname ILIKE '%vanderbilt%'
-- GROUP BY p.playerid, p.namefirst, p.namelast
-- ORDER BY highest_salary DESC; ------ (stacks the rows by player but takes the max salary not total)

SELECT
  p.namefirst,
  p.namelast,
  SUM(s.salary) AS total_salary,
  STRING_AGG(DISTINCT sc.schoolname, ', ') AS schools
FROM people AS p
LEFT JOIN salaries AS s 
	ON s.playerid = p.playerid
LEFT JOIN collegeplaying AS c 
	ON c.playerid = p.playerid
LEFT JOIN schools AS sc 
	ON sc.schoolid = c.schoolid
WHERE sc.schoolname ILIKE '%vanderbilt%'
GROUP BY p.playerid, p.namefirst, p.namelast
ORDER BY total_salary DESC;	-- David Price, $245,553,888

-- 4. Using the fielding table, group players into three groups based on their position: label players with
-- position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with
-- position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT COUNT(po) AS putouts,
	CASE
	WHEN pos = 'OF' then 'outfield'
	WHEN pos IN ('1B', '2B', 'SS', '3B') THEN 'infield'
	WHEN pos IN ('P', 'C') THEN 'battery'
	ELSE 'other'
	END AS grouped_positions
FROM fielding
GROUP BY grouped_positions -- battery(56,195) / infield(52,186) / outfield (28,434)
   
-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to
-- 2 decimal places. Do the same for home runs per game. Do you see any trends?

SELECT
	(yearid / 10) * 10 AS decade,
	SUM(so) AS total_so,
	SUM(hr) AS total_hr,
	SUM(g) AS total_games,
	ROUND(SUM(so) * 1 / NULLIF(SUM(g), 0), 2) AS strikeouts_per_game,
	ROUND(sum(hr) * 1 / NULLIF(SUM(g), 0), 2) AS homeruns_per_game
FROM pitchingpost
WHERE yearid >= 1920
GROUP BY (yearid/10) * 10
ORDER BY decade -- something is wrong or off here

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured
-- as the percentage of stolen base attempts which are successful. (A stolen base attempt results either
-- in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.
	

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series?
-- What is the smallest number of wins for a team that did win the world series? Doing this will probably
-- result in an unusually small number of wins for a world series champion – determine why this is the case.
-- Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team
-- with the most wins also won the world series? What percentage of the time?


-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5
-- average attendance per game in 2016 (where average attendance is defined as total attendance divided by
-- number of games). Only consider parks where there were at least 10 games played. Report the park name,
-- team name, and average attendance. Repeat for the lowest 5 average attendance.


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the
-- American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who
-- have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the
-- players' first and last names and the number of home runs they hit in 2016.


-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to
-- answer this question. As you do this analysis, keep in mind that salaries across the whole league tend
-- to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.
--   *  Does there appear to be any correlation between attendance at home games and number of wins? </li>
--   *  Do teams that win the world series see a boost in attendance the following year? What about teams
-- that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often,
-- that they are more effective. Investigate this claim and present evidence to either support or dispute
-- this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers.
-- Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the
-- hall of fame?

  
