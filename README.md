# BOMA-API

This project provides API endpoints for

1.  An admin API to handle requests from the boma-admin client
2.  A data API for external developers to send their via RESTfully
3.  A public facing API to handle requests from the boma-client-v2 apps
4.  A JSON feed for all festival data.  

It also handles all functionality for push notifications, converting media (audio/video), stats etc.   

[[_TOC_]]

## Building for Development

### Installing dependencies

#### rbenv

1.  Install rbenv following the instructions at https://github.com/rbenv/rbenv
2.  Install the appropriate version of ruby `rbenv install 3.1.2`

#### Postgres

3.  Install postgres with `brew install postgresql` or use postgresql.app

#### Redis

Redis is used for delayed jobs (sidekiq) (media conversion and creating/sending push notifications)

1.  Install redis with `brew install redis`
2.  Start the server with `redis-server --daemonize yes`
3.  Run sidekiq with `bundle exec sidekiq`

#### Building the bundle

4.  Run `bundle`
5.  Resolve symlink issue with 'eth' gem https://github.com/se3000/ruby-eth/issues/47#issuecomment-687779942

#### Set config

6.  Populate .env using .env.example.  

#### Install Heroku CLI and get and restore the latest production database

7.  Install Heroku cli and add the `boma-production` and `boma-staging` projects to allow for deployment
8.  Get and restore the latest production database 
	- `heroku pg:backups:capture -a boma-production`
	- `heroku pg:backups:download -a boma-production`
	- `pg_restore --verbose  --no-acl --no-owner -c  -h localhost -U pete -d boma_api latest.dump`

### Create couchdb records for a festival

The preferred method is to create a couchdb database using a backup of the production database.  For documentation on how to do this referr to https://gitlab.com/boma-hq/boma-core/-/blob/master/docker/couchdb/README.md#recreate-couchdb-from-data.  

Alternatively you can create couchdb records manually using the following rake command.  

`bundle exec rake couchdb:bootstrap\[FESTIVAL_ID\]`

### Create couchdb records for organisation articles

The preferred method is to create a couchdb database using a backup of the production database.  For documentation on how to do this referr to https://gitlab.com/boma-hq/boma-core/-/blob/master/docker/couchdb/README.md#recreate-couchdb-from-data.  

Alternatively you can create couchdb records manually using the following rake command.  

Run the following command from the rails console

> `rails c`
> `Organisation.find(organisation_id).articles.each {|a| a.couch_update_or_create}`

### Starting the server  

1.  run `rails s` to start the server

## Creating a new Organisation

### Create a Telegram Moderators Group

One telegram group, per organisation is used for notifications from the API which are relevant to that organisation.  They include:-

 - New Community Events
 - New People's Gallery Posts
 - Alerts regarding scheduled notifications due in one hour
 - Alerts regarding scheduled notifications which have just been sent
 - Feedback from the app

To create an configure a Telegram Moderators Group

1.  Create a new group on Telegram with an appropriate name for this Organisation and add the boma bot to the group
2.  Get your bot token by using searching for a contact called botFather in Telegram, then type `/mybots` in the contact's chat and choose the 'bomaCommunityBot' and then 'API Token'. 
3.  Head to https://api.telegram.org/bot`YourBOTToken`/getUpdates substituting `YourBOTToken` with the API Token you've just been given on Telegram.  In the JSON response find the chat_id for the group you have just created.  
4.  [Add a variable to the .env file for production](https://devcenter.heroku.com/articles/config-vars#using-the-heroku-cli) naming the variable as detailed below.  

| variable | purpose | example | required |
| ---       | ---  | ---     | ---      |
| TELEGRAM_CHAT_ID_#{org_name_parameterized} | The telegram chat_id for this organisation | https://push.boma.community | yes |

NB:  The staging API defaults to using 'Boma Moderators Staging' Telegram Group

### Setup a Push Notifications Server (Optional)

You may skip this step if the apps are being deployed using the Boma Digital LTD appstoreconnect and google play accounts.  

Otherwise, if an organisation's apps are being distributed via their own apple/google accounts then you'll need setup a go rush server to send the push notifications for this organisation's apps.  Follow the instructions in the [gorush readme](https://gitlab.com/boma-hq/gorush-with-basic-http-auth).  

Once the new push server has been provisioned you need add set the following environment variables replacing org_name_parameterized with the uppercase parametereized Organisation name*.  

| variable | purpose | example | required |
| ---       | ---  | ---     | ---      |
| GORUSH_API_ENDPOINT_#{org_name_parameterized} | The URL for the goRush server for this organisation | https://push.boma.community | yes |
| GORUSH_USERNAME_#{org_name_parameterized} | The username for the simple auth for the goRush server for this organisation | usernane | yes |
| GORUSH_PASSWORD_#{org_name_parameterized} | The password for the simple auth for the goRush server for this organisation | password | yes |

*To obtain the uppercased parametereized organisation name:-

1.  `heroku run rails c --app boma-production`
2.  `Organisation.find(ORG_ID).name.parameterize(separator: "_").upcase`

### Create an Organisation record

1.  Create a new organisation using rails console including the following attributes

| attribute | type | example | required |
| ---       | ---  | ---     | ---      |
| name | string | 'Kambe' | Yes |
| bundle_id | string | 'com.kambe.boma' | Yes |

```
org_args = {
	name: NAME,
	bundle_id: BUNDLE_ID,
}

organisation = Organisation.create! org_args

```

### Setup the couchdb replication service

Couchdb is split into a write and a read server.  The read server is populated and kept up to date by a couchdb replication job.  You must create one replication job per organisation.  

Full detail about how to setup replication for a couchdb can be found here. https://gitlab.com/boma-hq/boma-client-v2#styling-the-app

## Tokens

The Boma system allows users to collect ERC20 tokens in a crypto wallet held within the Boma apps.  Users can claim tokens either 
when they are in a set Time, Space and Place or by clicking a link to redeem a token.  

### Configue

The Boma system expects a wallet per Organisation to be created.  The private key for each organisatiobn should be stored in the .env for the 
project in the following format with `downcased_organisation_name` and `chain` replaced with real world values:

`{downcased_organisation_name}_{chain}_priv_key`

E.g the variable name for the Kambe Events Ethereum private key would be `kambe_events_ethereum_priv_key`

Add this variable with the private key value to the .env file for appropriate environment.  

### Time, Space and Place

To enable a token to be claimable in a time, space and place you must create a public TokenType.  Once the token type is published a couchdb record is created
for that token type and, when the client app pouchdb syncs the tokenType record (if before the event has taken place) a stub token is created ready for a user to 
begin the process of claiming the token.  

To create a TokenType:

1.  Deploy a new contract following the instructions at https://gitlab.com/boma-hq/boma-presence
2.  Create a **public** tokenType using the rails console substituting the variables in capital letters with real values.  is_public must be set to `true`.  Supply a base64 encoded image to be used as the image for the tokenType in the app.  
```
> heroku run rails c --app boma-production
> tt = TokenType.create! name: "TOKEN_TYPE_NAME", festival_id: FESTIVAL_ID, organisation_id: ORGANISATION_ID, contract_address: "CONTRACT_ADDRESS", image_base64: image_base64, is_public: true, chain: "gnosis"
```
IMPORTANT!  The TokenType uses the `start_date`, `end_date`, `center_lat`, `center_long` and `location_radius` from the Festival model, make sure these are correct before creating the TokenType to avoid confusion later.  

IMPORTANT!  Boma now uses the gnosis chain to avoid obtrusively high transactions fees on the main ethereum chain.  The system is theorietically compatible with any EVM based chain.    

### Redeemable Link

To enable users to claim a token using a redeemable link.  

1.  Deploy a new contract following the instructions at https://gitlab.com/boma-hq/boma-presence
2.  Create a tokenType using the rails console substituting the variables in capital letters for real values.  is_publis must be set to `false`.  Supply a base64 encoded image to be used as the image for the tokenType in the app.  
```
> heroku run rails c --app boma-production
> beta_tt = TokenType.create! name: "TOKE_TYPE_NAME", festival_id: FESTIVAL_ID, organisation_id: ORGANISATION_ID, contract_address: "CONTRACT_ADDRESS", image_base64: image_base64, is_public: false, chain: "gnosis"
```

3.  Create stub tokens with the state `initialized` - create as many as you need to distribute.  

> Token.create! token_type_id: TOKEN_TYPE_ID, festival_id: FESTIVAL_ID

4.  Collect the `token_hash` variable for all the tokens you want to distribute.  

5.  Mailmerge the following link substituting the query param `token` with the `token_hash` of the Tokens you've just created (one per link).  

> https://boma-api-production.boma.community/claim_token?token=TOKEN_HASH 

When clicking this link users are presented with a link which opens the app and completes the process of claiming the tokens.  Additionally the link includes
a failsafe fallback to allow users to copy the token_hash, open the app manually and redeem the token using the token_hash manually.  

### Checking Tokens have been mined

Tokens are mined using delayed jobs.  

You can check the status of the tokens being mined using an appropriate block explorer depending on the chain.  

| chain | block explorer |
| ----- | -------------- |
| gnosis | https://gnosisscan.io/ |
| ethereum | https://etherscan.io/ |

e.g https://gnosisscan.io/address/0xCFd081A65cb0ed5B2b2E3A1309d20c3a5A3267B4

You can also check the token has been presented to the chain by supplying the Token ActiveRecord object in question to:

> BomaTokenService.new.is_present(token)

## Data API

### Access

Access to the API uses the same password and user authentication as the other APIs in the project.  API access requires the Role `api_write`.  To give a user the `api_write` role run the following commands from the rails console.  
```
 > @user = User.find_by_email(EMAIL_ADDRESS) 
 > @organisation = Organisation.find(ORGANISATION_ID)
 > @user.add_role(:api_write, @organisation) 
 > @festival = Organisation.find(FESTIVAL_ID)
 > @user.add_role(:api_write, @festival)   
```

### Example App

See https://gitlab.com/boma-hq/boma-data-import-tool for an example integration with the Data API.  

## Scheduled Tasks

The following scheduled tasks are run by the heroku 'scheduler' Resource.  

### Push Notifications

A rake task to approve and send push notifications that are in the draft state and ready to be sent.  

This task is currently run at 10, 30 and 50 minutes past each hour.  

`rake approve_and_send_push_notifications`

### Stats Cache

#### Generating Stats Caches

A rake task to create the stats caches

This task should be run every 10 minutes.  

`rake stats:cache`

#### Rolling up stats

Rake tasks to rollup stats into larger time periods.  

This task should be run every hour at 0 minutes past the hour.  

`rake stats:create_hourly_stats`

This task should be run every day at midnight.  

`rake stats:create_daily_stats`

### Sending Scheduled Notifications

A rake task to send notifications which are scheduled to be sent at a specific time.  

This task should be run every hour at 0 minutes past the hour.  

`rake send_scheduled_notifications`

### Publishing Scheduled Articles

A rake task to publish articles which are scheduled to be published at a specific time.  

This task should be run every hour at 0 minutes past the hour.  

`rake publish_scheduled_articles`

## Testing

### Testing the app using a local copy of the API Project

Android requires all SSL for all requests.  To enable requests over SSL use ngrok (https://ngrok.com/).  

1.  Start the api normally with `rails s`, 
2.  In another window run `ngrok http 3000`.  
3.  Add the ngrok domain to the `config.hosts` in `/config/environments/development.rb` and restart the server.  e.g
``` 
config.hosts << "260a-2a00-23c7-e92-7201-980b-e901-e605-1538.ngrok-free.app"
```
4. Take the https URL that ngrok is served on and update the config in the app (`config/environment.js`) before building and flashing to a phone.  

### Automated Testing

A liminted number of tests are available for the public api, admin api and some models.  
Integration tests for the data_api are complete.  

Run tests using `bundle exec rspec`

### Testing Push Notifications

Test notifiations using the production enviroment before deploying apps.  

#### Create a push notification

1.  Login to jason (production or staging depending on your build)
2.  Navigate to the festival you are currently testing for (the bundle_id must match that of the app you've built)
3.  Create a push notification which targets a single address using the apps public key which you can find in the app
4.  Trigger the notification [as detailed below](#triggering-push-notifications).  

#### Triggering push notifications

You can either wait for the scheduled jobs to trigger sending the push notification or you can fire 
it manually using the rails console.  

1.  `heroku run rails c -app boma-staging`
2.  `address = Address.find_by_address(ADDRESS_HASH)`
3.  `PushNotificationsService.approve_all_drafts_for_address_and_send address.id`

**IMPORTANT!  If you are testing an iOS build which has been built locally with xcode and flashed onto a deivce using a development cert
then you must set the `production` flag on the iOS section of the `gorush-config.yml` to `false` otherwise the notifications will not 
be delivered**

#### Staging

1.  To test using the staging environemnet build a version of the App Client using the following config:

- Use the google-services.json config from the boma-staging firebase account
- The `id` attribute of the `<widget>` node should be com.rover.boma
- The `organisationId` in config/environment.js should be `7`
- The `festivalId` in config/enviroment.js should be `2`

2.  Flash the app to a device and copy the wallet address (public key).  

3.  Create a push notification at https://jason-staging.boma.community/#/organisations/7/festivals/2/messages [as detailed above](#create-a-push-notification).  

4.  Trigger the notification [as detailed above](#triggering-push-notifications).  

#### Logs

You can watch the logs on the push notification server by:

1.  ssh into the appropriate server
2.  run `docker logs gorush-with-basic-http-auth_gorush_1 --follow`

### Testing Tokens

1.  Create a TokenType [as detailed above](#tokens) but use a contract address that has been deployed to a testnet
2.  Set the RPC for chain used in the project .env to the testnet uri
3.  Test the time, space and place using an real device, spoofing the location and setting the time to be within the timeframe of the festival.  

## Deploying 

This project is currently hosted on heroku.  To deploy complete the following steps to setup the heroku 

1.  Install the heroku cli using the instructions at https://devcenter.heroku.com/articles/heroku-command-line
2.  Log in to your Heroku account and follow the prompts to create a new SSH public key.
		`heroku login`

### Deploying to Staging

1.  Add the heroku remote
		`git remote add boma-staging https://git.heroku.com/boma-staging.git`
2.  Commit your changes using the Convential Commits format https://www.conventionalcommits.org/en/v1.0.0/
		`git add [filename]`
		`git commit -m [commit message]`
3.  Deploy the changes.  
		`git push boma-staging staging:master`
4.  Run any neccesary migrations 
		`heroku run STATEMENT_TIMEOUT=0 rails db:migrate -a boma-staging`

### Deploying to Production

1.  Add the heroku remote
		`git remote add boma-production https://git.heroku.com/boma-production.git`
2.  Commit your changes using the Convential Commits format https://www.conventionalcommits.org/en/v1.0.0/
		`git add [filename]`
		`git commit -m [commit message]`
3.  Run the tests and make sure they pass
		`rspec spec`
4.  Do a full and extensive manual test of the public API (using the client app), the admin API (using the admin client) and all rake commands.  
5.  Read the diff to make sure you're publishing only changes you expect to see
		`git diff boma-production/master`
6.  Enable maintainance mode 
		`heroku maintenance:on -a boma-production`
7.  Take a database backup
		`heroku pg:backups:capture -a boma-production`
8.  Deploy the changes 
		`git push boma-production master`
9.  Run any neccesary migrations 
		`heroku run STATEMENT_TIMEOUT=0 rails db:migrate -a boma-production`
10.  Disable maintainance mode
		`heroku maintenance:off -a boma-production`

## Sync staging from production

1.  Make an up to date database dump and be sure to note the id of the database dump - it's provided by the cli output
		`heroku pg:backups:capture -a boma-production`
2.  Restore the dump to the staging project `heroku pg:backups:restore boma-production::{DATABASE_DUMP_ID} DATABASE_URL --app boma--staging`
3.  Bootstrap the festivals you are working on to ensure changes are applied by running this command for each relevant festival
		`heroku run rake couchdb:bootstrap\[FESTIVAL_ID\] --remote boma-staging`

NB:  Production images are automatically replicated into staging and development s3 buckets.  

# JSON Data Feed

A JSON feed is available for each festival's data - it can be found at the following URL.  Note only published data is included in the feed.  

https://boma-api-production.boma.community/feed/v1/festivals/FESTIVAL_ID/feed.json

# Upgrading Rails

Follow the instructions at https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#moving-between-versions to upgrade ruby and rails.  

# Notes

## Postgres Statement Timeout

To avoid lots of hanging postgres requests and the server not being able to respond when the server is under load by default postgres database requests which take longer than 15 seconds to complete are cancelled.  This can be configured using the env variable STATEMENT_TIMEOUT which in turn sets this config in the database.yml for production.  

To make postgres never timeout set this to 0.  

For rake commands that include database queries that will take a long time to complete you can use the following syntax to disable the timeout.  

`heroku run STATEMENT_TIMEOUT=100s rake REPLACE_WITH_RAKE_COMMAND`

More here:  https://www.postgresql.org/docs/current/runtime-config-client.html#GUC-STATEMENT-TIMEOUT

STATEMENT_TIMEOUT is set in the .env.  