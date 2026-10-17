#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

teams_values=""
games_values=""

while IFS=, read -r year round winner opponent winner_goals opponent_goals
do
  if [[ $year == "year" || -z $year ]]
  then
    continue
  fi

  teams_values+="('$winner'),('$opponent'),"
  games_values+="($year, '$round', '$winner', '$opponent', $winner_goals, $opponent_goals),"
done < games.csv

teams_values=${teams_values%,}
games_values=${games_values%,}

$PSQL "TRUNCATE TABLE games, teams RESTART IDENTITY;
INSERT INTO teams(name) VALUES $teams_values ON CONFLICT (name) DO NOTHING;
INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals)
SELECT data.year, data.round, winner.team_id, opponent.team_id, data.winner_goals, data.opponent_goals
FROM (VALUES $games_values) AS data(year, round, winner, opponent, winner_goals, opponent_goals)
JOIN teams AS winner ON winner.name = data.winner
JOIN teams AS opponent ON opponent.name = data.opponent;"
