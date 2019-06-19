
# Chapter - 2

[Repo Link](https://github.com/Sureya/data-engineering-101/tree/master/chapter2) 


# Tech Stack



*   Programming language: [Python3.6](https://www.tutorialspoint.com/python3/)
*   Source Code Management: [Git](https://product.hubspot.com/blog/git-and-github-tutorial-for-beginners)
*   SQL - [PostgreSQL 11.2](http://www.postgresqltutorial.com/)
*   IDE - [Pycharm](https://www.jetbrains.com/help/pycharm/installation-guide.html?section=macOS) + [DataGrip](https://www.jetbrains.com/help/datagrip/install-and-set-up-product.html?keymap=secondary_mac_os_x_10.5_) 

Reference Links



*   [Python - 1](https://www.learnpython.org/)
*   [Python - 2](https://codingbat.com/python)
*   [Psql - Mac](https://www.codementor.io/engineerapart/getting-started-with-postgresql-on-mac-osx-are8jcopb)


# Project - 1

Let’s imagine you work in a company where your company needs to collect basic weather data for London every day starting today. You are the engineer assigned to do this work, you think about the problem statement and you note that the requirement is not detailed, A requirement should always be precise and scoped, so you ask your manager for following details so that you can start working on it.  Rewrite this using fewer sentences 

Details required to start coding



*   Is there any specific data source that the company would like to or Can I use any data source?
*   What kind of weather data do you need to collect exactly?
*   How many times should the application run each day?
*   Where should the results be stored?

You get a response from the business saying, you can use any open source data source to get this data and they want a minimum of temperature in Celsius, sunrise time, sunset time, and clear description for each day. The business also mentions that any other data you see fit you can collect and they need to run the process once each day and the results should be stored in some sort of relational database for querying later.


## Step 1 Basic Python Application (v0)

	After doing some basic googling you find Open Weather Map (OMW) api that has all the data that you need. You also find out that you need to create an account and get an API key to make API calls. 


### API details



*   The home page can be found [here](https://openweathermap.org/)
*   API limits can be found [here](https://openweathermap.org/price)
*   The API documentation can be found [here](https://openweathermap.org/current)  
*   Python library for the API can be found [here](https://github.com/csparpa/pyowm) 

	

Once you have all the details, your initial local code would look something like this

[Repo Link](https://github.com/Sureya/data-engineering-101/blob/master/chapter2/version0.py)


```python
import pyowm
import time
import json

API_KEY = "<YOUR_API_KEY>"
weather = pyowm.OWM(API_KEY)
observation = weather.weather_at_place('London,GB')
response = observation.get_weather()

data = {
    "sunset": time.strftime('%Y-%m-%d %H:%M:%S',  time.gmtime(response.get_sunset_time())),
    "sunrise": time.strftime('%Y-%m-%d %H:%M:%S',  time.gmtime(response.get_sunrise_time())),
    "humidity": response.get_humidity(),
    "max_temperature": response.get_temperature('celsius')["temp_max"],
    "min_temperature": response.get_temperature('celsius')["temp_min"],
    "status": response.get_detailed_status()
}


print(json.dumps(data, indent=6))
```


If you execute the code with your API key, you can see that it fetches the data that you need to fetch. Now that you have the core functionality of the code working, we need to clean up the code and make sure its production ready. Definition of “Production code” is subjective to each company and teams. But overall, a production-ready code should have a minimum of following standards



*   Optimised data structures
*   Multiprocessing /Threading, if needed
*   Logging on multiple levels 
*   Simple Execution Strategy
*   Sensible unit tests


## So if we are to refactor our code to meet the above standards it would look like the following,

[Repo Link](https://github.com/Sureya/data-engineering-101/blob/master/chapter2/version1.py)


```python
# in-built
import time
import logging
import argparse

# 3rd party
import pyowm


def fetch_weather_data(api_key):
    """
        Taken in OMW api key and returns weather data for the execution day.
    :param api_key: string api key
    :return: dictionary with multiple weather data attributes.
    """
    logging.debug(f"API key received {api_key}")
    weather = pyowm.OWM(api_key)
    observation = weather.weather_at_place('London,GB')
    response = observation.get_weather()

    logging.debug(f"API response {response}")

    return {
        "sunset": time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime(response.get_sunset_time())),
        "sunrise": time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime(response.get_sunrise_time())),
        "humidity": response.get_humidity(),
        "max_temperature": response.get_temperature('celsius')["temp_max"],
        "min_temperature": response.get_temperature('celsius')["temp_min"],
        "status": response.get_detailed_status()
    }


if __name__ == '__main__':
    FORMAT = '%(asctime)s,%(msecs)d %(levelname)-8s [%(lineno)d] %(message)s'
    logging.basicConfig(format=FORMAT, datefmt='%d-%m-%Y:%H:%M:%S', level=logging.INFO)

    parser = argparse.ArgumentParser()
    parser.add_argument("--api_key", required=True, type=str, help="API key for OWM account")
    args = parser.parse_args()

    result_record = fetch_weather_data(args.api_key)

    logging.debug(result_record)
    logging.info("Process completed")
```


We can see that we have changed quite a few things, mainly we have 
*   Removed all print statements
*   Made the application modular
*   Gave all the inputs as command line arguments
*   Have different levels of logging
*   Added module comments 
*   This can also be a chart. Visuals look good 

For this application use case,  this would be an acceptable clean code to be considered as v1. But we still haven’t stored the data anywhere, hence the project is incomplete. In the next part of the chapter, we will analyze different types of database we can work with and will explore how to cleanly add that to our existing code and will be coming up with v2 of the code.


## Step 2 Python application with persistent storage

	When we execute the script, we can see we successfully fetch all the data we need. But we haven’t stored the data anywhere yet, we will be using PSQL to persist our data, for local development this chapter assumes that you have PSQL installed in your local machine.

	To get started we need to design a simple relational table. Very broadly speaking, the process of deciding how many tables we need, how many what are the columns in each table, and type of data each column is going to hold, is called Data Modeling. For this example, to keep things simple we will be storing our data in a single table as follows,



<p id="gdcalert1" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/Data-Engineer0.png). Store image on your image server and adjust path/filename if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert2">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/Data-Engineer0.png "image_tooltip")


SQL script to create this table would be as follows,

[Repo Link](https://github.com/Sureya/data-engineering-101/blob/master/chapter2/ddl.sql)


```sql
CREATE SCHEMA IF NOT EXISTS weather;

CREATE TABLE IF NOT EXISTS daily_weather
(
    sunset DATE NOT NULL,
    sunrise DATE NOT NULL,
    humidity INTEGER,
    max_temperature DOUBLE PRECISION NOT NULL,
    min_temperature DOUBLE PRECISION NOT NULL,
    status VARCHAR(35),
    extract_date DATE NOT NULL constraint daily_weather_pk primary key
);
```


We need to execute this DDL irrespective of the python application we have written, In other words, the python application assumes that _daily_weather _table is available to use when the application is executed. If for some reason the table is not available, the process will throw an error. In the later section, we will deal with how to ensure that these tables are always available and in case if it’s not how to handle that scenario.

Now that we have created a simple schema to store our data, we need to alter our python code to store the data into the table we created and that will be our v2 of the code.

[Repo Link](https://github.com/Sureya/data-engineering-101/blob/master/chapter2/version2.py)


```python
# in-built
import time
import logging
import argparse

# 3rd party
import pyowm
import psycopg2


def persist_single_row(sql_connection_parameters, record):
    """
        Takes in connection parameter and record to be inserted and updates the database with new records.
    :param sql_connection_parameters: dictionary with all connection parameters
    :param record: dictionary with one row of data
    :return:
    """
    sql = 'INSERT INTO daily_weather (extract_date, sunset, sunrise, humidity, max_temperature, min_temperature, ' \
          'status) VALUES (%s, %s, %s, %s, %s, %s, %s)'
    try:
        db_connection = psycopg2.connect(**sql_connection_parameters)
        cursor = db_connection.cursor()
        cursor.execute(sql, (record["extract_date"], record["sunset"], record["sunrise"], record["humidity"],
                             record["max_temperature"], record["min_temperature"], record["status"],))

        db_connection.commit()
        cursor.close()
        db_connection.close()
    except Exception as e:
        logging.error(e)


def fetch_weather_data(api_key):
    """
        Taken in OMW api key and returns weather data for the execution day.
    :param api_key: string api key
    :return: dictionary with multiple weather data attributes.
    """
    logging.debug(f"API key received {api_key}")
    weather = pyowm.OWM(api_key)
    observation = weather.weather_at_place('London,GB')
    response = observation.get_weather()

    logging.debug(f"API response {response}")

    return {
        "extract_date": time.strftime('%Y-%m-%d', time.gmtime(response.get_sunset_time())),
        "sunset": time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime(response.get_sunset_time())),
        "sunrise": time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime(response.get_sunrise_time())),
        "humidity": response.get_humidity(),
        "max_temperature": response.get_temperature('celsius')["temp_max"],
        "min_temperature": response.get_temperature('celsius')["temp_min"],
        "status": response.get_detailed_status()
    }


if __name__ == '__main__':
    FORMAT = '%(asctime)s,%(msecs)d %(levelname)-8s [%(lineno)d] %(message)s'
    logging.basicConfig(format=FORMAT, datefmt='%d-%m-%Y:%H:%M:%S', level=logging.INFO)

    parser = argparse.ArgumentParser()
    parser.add_argument("--api_key", required=True, type=str, help="API key for OWM account")
    parser.add_argument("--database", required=True, type=str, help="Database name to get connected to")
    parser.add_argument("--user", required=True, type=str, help="user name with appropriate privileges")
    parser.add_argument("--password", required=True, type=str, help="password for the username provided")
    parser.add_argument("--host", type=str,  default="localhost:5432", help="hostname where the database is hosted")
    args = parser.parse_args()

    connection_parameters = {
        'database': args.database,
        'user': args.user,
        'password': args.password,
        'host': args.host
    }

    result_record = fetch_weather_data(args.api_key)
    persist_single_row(sql_connection_parameters=connection_parameters, record=result_record)
    logging.debug(result_record)
    logging.info("Process completed")

```


Since our code is modular, all we had to do was to add another module to our code which would take the row we fetched extracted and would update the database. Another small change is that we have introduced a new attribute called extract_date, due to our data modelling decision dictated that our tables need that attribute. Some simple unit test cases are also included in the repository.

At this stage, it is safe to consider the project **done**, from an application development perspective. In further chapters, we will be learning how to deploy this batch application in AWS Cloud.


# Chapter - 3

	In this chapter, we will be exploring different ways to deploy our python application in AWS. For the ease of understanding, we will be splitting this chapter into 3 sections, 



*   **Section 1**: We will be deploying the application in AWS manually, by creating resource through AWS web console
*   **Section 2**: In this section, we will be writing a deployment script in Ansible
*   **Section 3**: In this section, we will be writing terraform scripts to create the AWS resource needed.

	By doing this in three steps it would become clear on why we are using each technology and how it would make our life easier. For the scope of this example, we will be initiating the deployment scripts from our local machine.

Assuming we have a working application ready to deploy, we need a minimum of 3 steps 



*   Create Infrastructure resource 
    *   In this example, the EC2 server and RDS database
*   Configure the instance to the desired state
    *   Like installing _Git, Python3 _etc.. and other system-level packages that are needed to execute the script
*   Package & Deploy the application 
    *   Install _Virtualenv, install python libraries, etc… _


# Tech Stack

*   Cloud - [AWS](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/) 
*   Application - Python3.6
*   OS - [ubuntu](https://www.cheatography.com/davechild/cheat-sheets/linux-command-line/) 
*   [Shell script](https://www.shellscript.sh/index.html)
*   [Ansible](https://scotch.io/tutorials/getting-started-with-ansible)
*   [Terraform](https://learn.hashicorp.com/terraform/#getting-started)


## Section-1 Deploy your application Manually in AWS 

	This is not the fanciest way to deploy an application, but if you never deployed an application end to end, it helps to try it manually then automating, it would give a clear idea of why we would want to automate it in the first place. If you are familiar with what deployment script is and why we need it, you can skip to section 2.


## 3.1: Creating Infrastructure

Reference Links

*   [RDS](https://aws.amazon.com/rds/postgresql/)
*   [EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html)
*   [Bash](https://www.howtoforge.com/tutorial/linux-shell-scripting-lessons/)


### 3.1.1 - Create RDS database

*   Select RDS service and click create a database
*   Select PostgreSQL from engine option
*   Select Dev/test from use case
*   Select t2.micro for DB instance class
*   Give any suitable name for DB instance identifier
*   Give a suitable username and password, which we will be using in the later steps.
*   Click Next & Click create a database
*   Detailed instructions can be found [here](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_GettingStarted.CreatingConnecting.PostgreSQL.html)
*   Remember to 
    *   Enable public accessibility 
    *   Create a security group called de-lab and use that for all the resources we create. 
*   Wait until the **status **value** **becomes Available.
*   Make note of host value from the database


### 3.1.2 - Create an EC2 instance

*   Proceed to EC2 dashboard 
*   Quick guide for launching EC2 instance
    *   Select Launch instance 
    *   Select: **Ubuntu Server 18.04 LTS (HVM), SSD Volume Type **
    *   Select**: t2.micro**
    *   Click: **Next: Configure Instance Details**
    *   Click: **Next: Add Storage**
    *   Click: **Review & Launch**
    *   When you press the launch button, you will be prompted to select the key pair if you already have one, otherwise you will be asked to create one, please secure the file in your local machine, we will be using that key pair for all our exercises.
*   Detailed instructions available [here](https://docs.aws.amazon.com/quickstarts/latest/vmlaunch/step-1-launch-instance.html)
*   Once the instance is created,  login into your server via SSH as described [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html)


## 3.2: Configuration Management

	Before we can begin to package our Python application we need to install system packages, to get our server to the desired configuration. Since we will be running Python application which is downloaded from Github, let's install the packages needed for that.


```bash
# Install required system-level packages
yes | sudo apt-get install git
yes | sudo add-apt-repository ppa:jonathonf/python-3.6
yes | sudo apt-get update
yes | sudo apt-get install python3.6
yes | sudo apt-get install python3-pip
yes | sudo apt-get install python3-venv
```



## 3.3: Packaging & Deploying the application

After installing system packages we can start packaging our application by creating virtualenv and installing python dependencies into the env.


```bash
#!/usr/bin/env bash

# Export all the constant values as environment variables
export APP_PATH="application_envs/weather_batch_app"
export REPO_NAME="data-engineering-101"
export REPO_URL="https://github.com/Sureya/data-engineering-101.git"
export FILES_DIRNAME="/home/ubuntu/code"
export EXECUTABLE="/home/ubuntu/application_envs/weather_batch_app/bin"
export EXECUTABLE_FILE_PATH="/home/ubuntu/code/data-engineering-101/chapter2/version2.py"

# All credentials needed to execute our python application
export API_KEY="<API_KEY_GOES_HERE>"
export DATABASE_NAME="<DB_NAME>"
export DB_USER_NAME="<USER>"
export DB_PASSWORD="<PWD>"
export DB_HOST="<HOST>"


# Create virtual environment
python3 -m venv ${APP_PATH}

# Clone the repo
(mkdir ${FILES_DIRNAME} && cd ${FILES_DIRNAME} &&  git clone ${REPO_URL})

# Install all the dependencies from requirements file
${EXECUTABLE}/pip install -r ${FILES_DIRNAME}/${REPO_NAME}/chapter2/requirements.txt

# Execute the code
${EXECUTABLE}/python ${EXECUTABLE_FILE_PATH} --api_key=${API_KEY} --database=${DATABASE_NAME} \
--user=${DB_USER_NAME} --password=${DB_PASSWORD} --host=${DB_HOST}
```


If the last command executes without any errors, we have successfully deployed our python application manually.


## 3.4 Automate configuration management & Application packaging

[Repo Link](https://github.com/Sureya/data-engineering-101/tree/master/chapter3/part2/deploy)

Reference Links



*   [Ansible](https://serversforhackers.com/c/an-ansible-tutorial) 
*   [Ansible - Video](https://www.youtube.com/watch?v=dCQpaTTTv98)

	If we look at Part 2 & 3 from the previous section, it is just installing bunch of things into a server so that we can execute our application. In this section, we will be automating those steps via **Ansible,  **So that after creating infrastructure all we need to do is execute ansible playbook.

If you’re completely new to ansible, please read up on it. In short, Ansible is a YAML based commands executed sequentially to all the specified remote host.


<!-- Docs to Markdown version 1.0β17 -->
