#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --no-align --tuples-only -c"


echo -e "\nWelcome to FCC salon\n"

# Create main menu 
MAIN_MENU() {
  echo -e "\nAvailable Services:"
  SERVICES=$($PSQL "SELECT service_id, name FROM services")
  echo "$SERVICES" | while IFS='|' read -r SERVICE_ID SERVICE_NAME; do
      echo "$SERVICE_ID) $SERVICE_NAME"
  done
}

MAKE_APPOINTMENT() {
  # Display main menu
  MAIN_MENU
  # Read input service id
  while true; do 
    echo -n "Enter the service number: "  # Print prompt without using -p
    read SERVICE_ID_SELECTED
    
    # Check if the input is a number
    if ! [[ $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]; then
      echo "Please enter a numeric number."
      MAIN_MENU
    else
      # Check if the selected service ID is valid
      VALID_SERVICE_ID=$($PSQL "SELECT service_id FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
      
      # If the service ID is not valid
      if [[ -z $VALID_SERVICE_ID ]]; then
        echo "Please select a valid available service number."
        MAIN_MENU
      else
        # Get the service name for confirmation later
        SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
        break  # Exit the loop if a valid service ID is selected
      fi
    fi
  done
}

CUSTOMER_INFO() {
  # Verify new or existing customer through phone number 
  echo -n "Please enter your phone number for appointment (format: 555-555-5555): "  # Print prompt without using -p
  read CUSTOMER_PHONE
  
  # Validate phone number format
  if ! [[ $CUSTOMER_PHONE =~ ^[0-9]{3}-[0-9]{3}-[0-9]{4}$ ]]; then
    echo "Please enter a valid phone number in the format 555-555-5555."
    CUSTOMER_INFO  # Call the function again to re-prompt
  else
    EX_CUST_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")
    
    if [[ -z $EX_CUST_NAME ]]; then
      # It's a new customer, ask for name
      echo -e "\nWhat's your name?"
      read CUSTOMER_NAME
      INSERT_PHONE_RES=$($PSQL "INSERT INTO customers(name, phone) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
      echo -e "\nWelcome $CUSTOMER_NAME, let's get your appointment set!"
    else
      CUSTOMER_NAME=$EX_CUST_NAME  # Use the existing customer's name
      echo -e "\nWelcome back $CUSTOMER_NAME, let's get your appointment set!"
    fi
  fi
}

FINALIZE_APPOINTMENT() {
  echo -e "\nWhat time works best for you?"
  echo -n "Your appointment time is (HH:MM or HH AM/PM): "  # Print prompt without using -p
  read SERVICE_TIME

  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
  INSERT_APT_RES=$($PSQL "INSERT INTO appointments(time, customer_id, service_id) VALUES ('$SERVICE_TIME', '$CUSTOMER_ID', '$SERVICE_ID_SELECTED')")
    
    # Confirm the appointment
    if [[ $INSERT_APT_RES ]]; then
      echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
    else
      echo -e "\nThere was an error scheduling your appointment. Please try again."
    fi
  
}

THANK_YOU(){
    while true; do  # Loop until a valid response is received
    echo "Thank you for making an appointment with us! Do you need to make another appointment? (Y/N)"
    read CUST_RESP

    # Check for valid input
    if [[ $CUST_RESP =~ ^[Yy]$ ]]; then
      MAKE_APPOINTMENT
      break  # Exit the loop after making an appointment
    elif [[ $CUST_RESP =~ ^[Nn]$ ]]; then
      echo "We're looking forward to your visit!"
      break  # Exit the loop
    else
      echo "Please only key in Y/N for the response."
    fi
  done
}
# Start the customer information process
MAKE_APPOINTMENT
CUSTOMER_INFO
FINALIZE_APPOINTMENT
THANK_YOU