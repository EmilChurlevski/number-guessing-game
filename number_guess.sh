#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess --tuples-only -c"
RANDOM_NUMBER=$(( $RANDOM % 1000 + 1 ))
echo "Enter your username:"
read USERNAME
GET_USER_DATA=$($PSQL "select username from users where username='$USERNAME'")
if [[ -z $GET_USER_DATA ]]
then
  SAVE_NEW_USER=$($PSQL "insert into users(username) VALUES('$USERNAME')")
  USER_ID=$($PSQL "select user_id from users where username='$USERNAME'")
  SAVE_START_GAME_DATA=$($PSQL "insert into games(games_played, best_game, user_id) values(0, 1000, '$USER_ID')")
  echo  "Welcome, $USERNAME! It looks like this is your first time here."
else
  GET_DATA=$($PSQL "select * from users inner join games using(user_id) where username='$USERNAME'")
  echo "$GET_DATA" | while IFS=" |" read USER_ID USERNAME GAMES_PLAYED BEST_GAME
  do
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi
echo "Guess the secret number between 1 and 1000:"
GUESSES=0
GUESS_NUMBER() {
  let GUESSES++
  read USER_GUESS
  if ! [[ $USER_GUESS =~ ^[0-9]+$ ]]
  then
    echo  "That is not an integer, guess again:"
    GUESS_NUMBER
    let GUESSES--
  fi
  if [[ $USER_GUESS -lt $RANDOM_NUMBER ]]
  then
    echo  "It's higher than that, guess again:"
    GUESS_NUMBER
  fi
  if [[ $USER_GUESS -gt $RANDOM_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
    GUESS_NUMBER
  fi
}
GUESS_NUMBER
if [[ $USER_GUESS -eq $RANDOM_NUMBER ]]
then
  GET_USER_DATA=$($PSQL "select * from users inner join games using(user_id) where username='$USERNAME'")
  echo "$GET_USER_DATA" | while IFS=" |" read USER_ID USERNAME GAMES_PLAYED BEST_GAME
  do
    if [[ $GUESSES -lt $BEST_GAME ]]
    then
      NEW_BEST_GAME=$($PSQL "update games set games_played=$GAMES_PLAYED + 1, best_game=$GUESSES where user_id=$USER_ID")
    fi
  done
  echo "You guessed it in $GUESSES tries. The secret number was $RANDOM_NUMBER. Nice job!"
fi
