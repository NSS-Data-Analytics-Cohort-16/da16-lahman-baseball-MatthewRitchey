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

-- SELECT
-- 	((yearid / 10) * 10)::text || 's' AS decade,
-- 	SUM(so) AS total_so,
-- 	SUM(hr) AS total_hr,
-- 	SUM(g) AS total_games,
-- 	ROUND(SUM(so) * 1 / NULLIF(SUM(g), 0), 2) AS strikeouts_per_game,
-- 	ROUND(sum(hr) * 1 / NULLIF(SUM(g), 0), 2) AS homeruns_per_game
-- FROM pitchingpost
-- WHERE yearid >= 1920
-- GROUP BY (yearid/10) * 10
-- ORDER BY decade -- something is wrong or off here

-----------Sub Query version------------
SELECT 
	decade,
	ROUND(total_so * 1.0 / total_games, 2) AS avg_so_per_game,
	ROUND(total_hr * 1.0 / total_games, 2) AS avg_hr_per_game
FROM (
	SELECT
		((yearid / 10) * 10)::text || 's' AS decade,
		SUM(so) AS total_so,
		SUM(hr) AS total_hr,
		SUM(gs) AS total_games --using gs instead of g gives us the total games started, where g returns the games 
		--each pitcher played, which multiplies the games count and throws off the math
		COUNT
	FROM pitching
	WHERE yearid >= 1920
	GROUP BY (yearid / 10) * 10
	) AS decade_stats
ORDER BY decade; -- As the pitching got better, so did the power hitting, higher strikeouts led to a slow rise
	-- in hr numbers, in the 1970's we likely see a dip due to the current ball taking over the league in 1977

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured
-- as the percentage of stolen base attempts which are successful. (A stolen base attempt results either
-- in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

SELECT
p.namefirst,
p.namelast,
--(b.sb + b.cs) AS sb_attempts,
b.sb,
ROUND((b.sb * 100.0) / (b.sb + b.cs), 2) AS sb_pct
FROM batting AS b
LEFT JOIN people AS p
	ON p.playerid = b.playerid
WHERE b.yearid = '2016'
	AND b.sb >= 20
ORDER BY sb_pct DESC; -- CHRIS Owings (91.3%)


-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series?
-- What is the smallest number of wins for a team that did win the world series? Doing this will probably
-- result in an unusually small number of wins for a world series champion – determine why this is the case.
-- Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team
-- with the most wins also won the world series? What percentage of the time?

-- From 1970 – 2016, what is the largest number of wins for a team that did not win the world series?
SELECT
	name, 
	yearid,
	w,
	wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
AND wswin = 'Y'
ORDER BY w DESC
LIMIT 5; -- NY Yankees in 1998 with 114 regular season wins

-- What is the smallest number of wins for a team that did win the world series? Doing this will probably
-- result in an unusually small number of wins for a world series champion – determine why this is the case.
-- Then redo your query, excluding the problem year.
----------------------------------------------------------
SELECT 
	name, 
	yearid, 
	W,
	wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
  AND wswin = 'Y'
ORDER BY W ASC
LIMIT 5; -- 63 games by the LA Dodgers in 1981 due to a mid season strike canceling almost 1/3 of the games)
----------------------------------------------------------
SELECT 
	name,
	yearid,
	W, 
	wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
  AND wswin = 'Y'
  AND yearid != 1981
ORDER BY W ASC
LIMIT 5; -- STL Cardinals in 2006 with 83 regular season wins
-----------------------------------------------------------
-- How often from 1970 – 2016 was it the case that a team with the most wins also won the world series?
-- What percentage of the time?
WITH most_wins AS (
	SELECT
		yearid,
		MAX(w) AS w
	FROM teams
	WHERE yearid >= 1970
	GROUP BY yearid
	ORDER BY yearid
	),
most_win_teams AS (
	SELECT 
		yearid,
		name,
		wswin
	FROM teams
	INNER JOIN most_wins
	USING(yearid, w)
)
SELECT 
	(SELECT COUNT(*)
	 FROM most_win_teams
	 WHERE wswin = 'N'
	) * 100.0 /
	(SELECT COUNT(*)
	 FROM most_win_teams
	); --75.471% of the time

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5
-- average attendance per game in 2016 (where average attendance is defined as total attendance divided by
-- number of games). Only consider parks where there were at least 10 games played. Report the park name,
-- team name, and average attendance. Repeat for the lowest 5 average attendance.

-- SELECT
-- 	park,
-- 	team,
-- 	 ROUND(SUM(attendance) * 1.0 / COUNT(*), 0) AS avg_attendance
-- FROM homegames
-- WHERE year = 2016
-- 	AND attendance IS NOT NULL
-- 	AND games >= 10
-- GROUP BY park, team
-- ORDER BY avg_attendance ASC
-- LIMIT 5; -- close but unable to stack so far

----------homegames table version----------
WITH ranked_attendance AS (
  SELECT
    p.park_name,
    h.team,
	SUM(h.attendance) / SUM(h.games) AS attendance_per_game,
    ROUND(SUM(h.attendance) * 1.0 / COUNT(*), 0) AS attendance,
    ROW_NUMBER() OVER (ORDER BY SUM(h.attendance) * 1.0 / COUNT(*) DESC) AS rank_desc,
    ROW_NUMBER() OVER (ORDER BY SUM(h.attendance) * 1.0 / COUNT(*) ASC) AS rank_asc
  FROM homegames AS h
  INNER JOIN parks AS p
  	ON p.park = h.park
  WHERE year = 2016
    AND h.attendance IS NOT NULL
    AND h.games >= 10
  GROUP BY p.park_name, h.team
)
SELECT 
	park_name, 
	team,
	attendance_per_game,
	attendance
FROM ranked_attendance
WHERE rank_desc <= 5 OR rank_asc <= 5
ORDER BY attendance DESC;

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the
-- American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- show the names, teams, and leagues
WITH tsn_awards AS (
  SELECT
    m.playerid,
    m.teamid,
    m.lgid,
    p.namefirst,
    p.namelast
  FROM managers AS m
  INNER JOIN awardsmanagers AS a ON a.playerid = m.playerid
  INNER JOIN people AS p ON p.playerid = m.playerid
  WHERE a.awardid = 'TSN Manager of the Year'
)
-- Find managers who won in both leagues
SELECT 
  playerid,
  namefirst,
  namelast,
  STRING_AGG(DISTINCT teamid, ', ') AS teams,
  STRING_AGG(DISTINCT lgid, ', ') AS leagues
FROM tsn_awards
GROUP BY playerid, namefirst, namelast
HAVING COUNT(DISTINCT lgid) = 2
ORDER BY namelast, namefirst;


-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who
-- have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the
-- players' first and last names and the number of home runs they hit in 2016.

WITH career_hr AS ( --finding the career home runs per player
  SELECT
    playerid,
    MAX(hr) AS max_hr --finds their max hr total per row/year
  FROM batting
  GROUP BY playerid
),
season_count AS ( --for filtering for players with at least 10 years experience
  SELECT
    playerid,
    COUNT(DISTINCT yearid) AS seasons_played
  FROM batting
  GROUP BY playerid
),
hr_2016 AS (--finding the 2016 results
  SELECT
    b.playerid,
    b.hr,
    p.namefirst || ' ' || p.namelast AS fullname
  FROM batting AS b
  JOIN people AS p ON p.playerid = b.playerid
  WHERE b.yearid = 2016
    AND b.hr >= 1
)
SELECT --final query
  h.fullname,
  h.hr AS hr_2016
FROM hr_2016 AS h
JOIN career_hr AS c ON h.playerid = c.playerid AND h.hr = c.max_hr --takes the rows where the max hr was from 2016
JOIN season_count AS s ON h.playerid = s.playerid AND s.seasons_played >= 10 --filters for 10 years of experience
ORDER BY hr_2016 DESC;

-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to
-- answer this question. As you do this analysis, keep in mind that salaries across the whole league tend
-- to increase together, so you may want to look on a year-by-year basis.

SELECT --most money spent per win
  t.yearid,
  t.name,
  SUM(s.salary) AS total_salary,
  MAX(t.W) AS wins,
  ROUND((SUM(s.salary) * 1.0 / NULLIF(MAX(t.W), 0))::numeric, 0) AS salary_per_win
FROM salaries AS s
JOIN teams AS t ON s.teamid = t.teamid AND s.yearid = t.yearid
WHERE t.yearid >= 2000
GROUP BY t.yearid, t.name
ORDER BY salary_per_win DESC
LIMIT 10;


SELECT --least money spent per win
  t.yearid,
  t.name,
  SUM(s.salary) AS total_salary,
  MAX(t.W) AS wins,
  ROUND((SUM(s.salary) * 1.0 / NULLIF(MAX(t.W), 0))::numeric, 0) AS salary_per_win
FROM salaries AS s
JOIN teams AS t ON s.teamid = t.teamid AND s.yearid = t.yearid
WHERE t.yearid >= 2000
GROUP BY t.yearid, t.name
ORDER BY salary_per_win ASC
LIMIT 10;

-- 12. In this question, you will explore the connection between number of wins and attendance.
--   *  Does there appear to be any correlation between attendance at home games and number of wins? </li>
--   *  Do teams that win the world series see a boost in attendance the following year? What about teams
-- that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

WITH team_stats AS (
  SELECT
    yearid,
    teamid,
    SUM(attendance) AS total_attendance,
    MAX(W) AS wins,
    MAX(divwin) = 'Y' OR MAX(wcwin) = 'Y' AS made_playoffs,
    MAX(wswin) = 'Y' AS won_ws
  FROM teams
  WHERE yearid >= 2000
  GROUP BY yearid, teamid
),
attendance_change AS (
  SELECT
    curr.teamid,
    curr.yearid,
    curr.total_attendance AS curr_attendance,
    prev.total_attendance AS prev_attendance,
    ROUND((curr.total_attendance - prev.total_attendance) * 100.0 / NULLIF(prev.total_attendance, 0), 2) AS pct_change,
    prev.made_playoffs AS made_playoffs_prev_year,
    prev.won_ws AS won_ws_prev_year,
    curr.wins
  FROM team_stats curr
  JOIN team_stats prev ON curr.teamid = prev.teamid AND curr.yearid = prev.yearid + 1
)
SELECT 
  yearid,
  teamid,
  wins,
  curr_attendance,
  prev_attendance,
  pct_change,
  made_playoffs_prev_year,
  won_ws_prev_year
FROM attendance_change
ORDER BY pct_change DESC;


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often,
-- that they are more effective. Investigate this claim and present evidence to either support or dispute
-- this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers.
-- Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the
-- hall of fame?

--pull all pitchers from the MLB level
WITH pitcher_pool AS (
  SELECT playerid, throws
  FROM people
  WHERE playerid IN (SELECT DISTINCT playerid FROM pitching)
),
--pulls the Cy Young winners
cy_young_winners AS (
  SELECT playerid
  FROM awardsplayers
  WHERE awardid = 'Cy Young Award'
),
--pulls pitchers inducted into the HOF
hof_pitchers AS (
  SELECT playerid
  FROM halloffame
  WHERE inducted = 'Y' AND category IN ('Pitcher', 'Player')
),
--Counts the pitchers and sorts them by left and right handed
handedness_counts AS (
  SELECT 
    throws,
    COUNT(DISTINCT playerid) AS total_pitchers
  FROM pitcher_pool
  WHERE throws IN ('L', 'R')
  GROUP BY throws
),
--here is where we count the Cy Young winners by their handedness
cy_young_counts AS (
  SELECT 
    p.throws,
    COUNT(DISTINCT a.playerid) AS cy_young_winners
  FROM cy_young_winners a
  JOIN people p ON a.playerid = p.playerid
  WHERE p.throws IN ('L', 'R')
  GROUP BY p.throws
),
--joins the HOF counts to their handedness
hof_counts AS (
  SELECT 
    p.throws,
    COUNT(DISTINCT h.playerid) AS hof_inductees
  FROM hof_pitchers h
  JOIN people p ON h.playerid = p.playerid
  WHERE p.throws IN ('L', 'R')
  GROUP BY p.throws
),

combined AS (
  SELECT 
    hc.throws,
    hc.total_pitchers,
    COALESCE(cyc.cy_young_winners, 0) AS cy_young_winners,
    COALESCE(hof.hof_inductees, 0) AS hof_inductees
  FROM handedness_counts hc
  LEFT JOIN cy_young_counts cyc ON hc.throws = cyc.throws
  LEFT JOIN hof_counts hof ON hc.throws = hof.throws
),
--Combines all three metrics by handedness.
totals AS (
  SELECT 
    SUM(total_pitchers) AS total_pitchers_all,
    SUM(cy_young_winners) AS total_cy_young_all,
    SUM(hof_inductees) AS total_hof_all
  FROM combined
)
--Overall totals
SELECT 
  CASE WHEN c.throws = 'L' THEN 'Left-Handed' ELSE 'Right-Handed' END AS throwing_hand,
  c.total_pitchers,
  ROUND(c.total_pitchers * 100.0 / NULLIF(t.total_pitchers_all, 0), 2) AS pct_of_pitchers,
  c.cy_young_winners,
  ROUND(c.cy_young_winners * 100.0 / NULLIF(t.total_cy_young_all, 0), 2) AS pct_of_cy_young,
  c.hof_inductees,
  ROUND(c.hof_inductees * 100.0 / NULLIF(t.total_hof_all, 0), 2) AS pct_of_hof
FROM combined c, totals t
ORDER BY throwing_hand;
