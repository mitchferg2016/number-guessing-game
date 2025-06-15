#!/bin/bash
# This script was created for the freeCodeCamp Number Guessing Game project.

echo "Enter your username:"
read USERNAME

USER_ID=$(
  psql --username=freecodecamp --dbname=number_guess --tuples-only --no-align -c \
  "SELECT user_id FROM users WHERE username='$USERNAME';"
)

if [[ -z $USER_ID ]]; then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  psql --username=freecodecamp --dbname=number_guess --tuples-only --no-align -c \
  "INSERT INTO users(username) VALUES('$USERNAME');"
  USER_ID=$(
    psql --username=freecodecamp --dbname=number_guess --tuples-only --no-align -c \
    "SELECT user_id FROM users WHERE username='$USERNAME';"
  )
else
  GAMES_PLAYED=$(psql --username=freecodecamp --dbname=number_guess --tuples-only --no-align -c \
  "SELECT games_played FROM users WHERE username='$USERNAME';" | xargs)

  BEST_GAME=$(psql --username=freecodecamp --dbname=number_guess --tuples-only --no-align -c \
  "SELECT best_game FROM users WHERE username='$USERNAME';" | xargs)

  printf "Welcome back, %s! You have played %s games, and your best game took %s guesses.\n" "$USERNAME" "$GAMES_PLAYED" "$BEST_GAME"
fi

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0

echo "Guess the secret number between 1 and 1000:"

while true; do
  read GUESS

  if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  NUMBER_OF_GUESSES=$(( NUMBER_OF_GUESSES + 1 ))

  if (( GUESS < SECRET_NUMBER )); then
    echo "It's higher than that, guess again:"
  elif (( GUESS > SECRET_NUMBER )); then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

    psql --username=freecodecamp --dbname=number_guess -c \
    "INSERT INTO games(user_id, number_of_guesses, secret_number) VALUES($USER_ID, $NUMBER_OF_GUESSES, $SECRET_NUMBER);"

    psql --username=freecodecamp --dbname=number_guess -c \
    "UPDATE users SET games_played = games_played + 1 WHERE user_id = $USER_ID;"

    CURRENT_BEST=$(
      psql --username=freecodecamp --dbname=number_guess --tuples-only --no-align -c \
      "SELECT best_game FROM users WHERE user_id = $USER_ID;" | xargs
    )

    if [[ -z $CURRENT_BEST || $NUMBER_OF_GUESSES -lt $CURRENT_BEST ]]; then
      psql --username=freecodecamp --dbname=number_guess -c \
      "UPDATE users SET best_game = $NUMBER_OF_GUESSES WHERE user_id = $USER_ID;"
    fi

    break
  fi
done